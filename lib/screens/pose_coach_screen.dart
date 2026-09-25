import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/pose_coach_service.dart';
import '../state/pose_coach.dart';
import '../theme.dart';

/// Solicita el permiso de cámara a través del canal nativo (MainActivity).
/// Devuelve true/false, o null si el canal no está disponible en la plataforma.
Future<bool?> solicitarPermisoCamara() async {
  try {
    return await const MethodChannel('fitpulse/permissions')
        .invokeMethod<bool>('requestCameraPermission');
  } catch (_) {
    return null;
  }
}

/// Abre los ajustes del sistema para esta app (permisos).
Future<void> _abrirAjustes() async {
  try {
    await const MethodChannel('fitpulse/permissions')
        .invokeMethod('openAppSettings');
  } catch (_) {}
}

/// Fase 5: entrenador de postura con cámara.
///
/// Todo el análisis se hace EN EL MÓVIL (ML Kit on-device): la cámara nunca
/// graba ni sube nada. Si la cámara, el permiso o el modelo de IA no están
/// disponibles, se muestra un estado honesto (nunca se inventa una corrección).
class PoseCoachScreen extends StatefulWidget {
  const PoseCoachScreen({super.key, required this.ejercicio, required this.tipo});

  final String ejercicio;
  final TipoPostura tipo;

  @override
  State<PoseCoachScreen> createState() => _PoseCoachScreenState();
}

enum _EstadoCoach { cargando, sinPermiso, sinCamara, sinModelo, listo }

class _PoseCoachScreenState extends State<PoseCoachScreen> {
  final _servicio = PoseCoachService();
  late final AnalizadorPostura _analizador;

  CameraController? _camara;
  _EstadoCoach _estado = _EstadoCoach.cargando;
  Map<Lm, PuntoPose> _puntos = const {}; // normalizados 0..1 (marco erguido)
  String _mensaje = 'Encendiendo la cámara…';
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _analizador = AnalizadorPostura(widget.tipo);
    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciar());
  }

  @override
  void dispose() {
    _camara?.stopImageStream();
    _camara?.dispose();
    _servicio.cerrar();
    super.dispose();
  }

  Future<void> _iniciar() async {
    // 1) Permiso de cámara (solo cámara; nada de grabación).
    final status = await solicitarPermisoCamara();
    if (!mounted) return;
    if (status == false) {
      setState(() => _estado = _EstadoCoach.sinPermiso);
      return;
    }

    // 2) Cámara disponible (preferimos la trasera).
    List<CameraDescription> camaras;
    try {
      camaras = await availableCameras();
    } catch (_) {
      if (!mounted) return;
      setState(() => _estado = _EstadoCoach.sinCamara);
      return;
    }
    if (camaras.isEmpty) {
      if (!mounted) return;
      setState(() => _estado = _EstadoCoach.sinCamara);
      return;
    }
    final camara = camaras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => camaras.first,
    );

    // 3) Detector de pose (el modelo se descarga una vez vía Play Services).
    await _servicio.inicializar();
    if (!mounted) return;
    if (!_servicio.disponible) {
      setState(() {
        _estado = _EstadoCoach.sinModelo;
        _mensaje = _servicio.errorInicializacion ?? _noModeloMsg;
      });
      return;
    }

    // 4) Abrir cámara + stream de frames.
    try {
      final control = CameraController(
        camara,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      _camara = control;
      await control.initialize();
      if (!mounted) return;
      await control.startImageStream(_procesarMarco);
      setState(() {
        _estado = _EstadoCoach.listo;
        _mensaje = 'Coloca tu cuerpo en el encuadre';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _estado = _EstadoCoach.sinCamara);
    }
  }

  Future<void> _procesarMarco(CameraImage imagen) async {
    if (_procesando || !mounted) return;
    _procesando = true;
    try {
      final rot = _camara?.description.sensorOrientation ?? 0;
      final frame = await _servicio.procesar(imagen, rot);
      if (!mounted) return;
      if (frame == null) {
        // El modelo se cayó a mitad: estado honesto, se detiene el stream.
        await _camara?.stopImageStream();
        if (!mounted) return;
        setState(() {
          _estado = _EstadoCoach.sinModelo;
          _mensaje = _servicio.errorInicializacion ?? _noModeloMsg;
        });
        return;
      }
      final resultado = _analizador.analizar(frame.puntos);
      if (!mounted) return;
      setState(() {
        _puntos = frame.posicionVisible
            ? _normalizar(frame.puntos, rot, imagen.width, imagen.height)
            : const {};
        _mensaje = resultado.mensaje;
      });
    } finally {
      _procesando = false;
    }
  }

  static const _noModeloMsg =
      'El modelo de IA de Google no está disponible ahora (requiere Play '
      'Services y una descarga única). Sin él no se puede activar el '
      'entrenador con cámara.';

  /// Convierte coordenadas de píxel (marco original) a 0..1 en el marco erguido
  /// (ML Kit devuelve la pose ya rotada; por eso se intercambian ancho/alto en
  /// rotaciones de 90°/270°).
  Map<Lm, PuntoPose> _normalizar(
    Map<Lm, PuntoPose> px,
    int rot,
    int anchoFrame,
    int altoFrame,
  ) {
    final girado = rot % 180 != 0;
    final ancho = girado ? altoFrame : anchoFrame;
    final alto = girado ? anchoFrame : altoFrame;
    if (ancho == 0 || alto == 0) return const {};
    return px.map((lm, p) => MapEntry(lm, PuntoPose(p.x / ancho, p.y / alto)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Entrenador con cámara',
          style: AppType.headlineSm.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _estado == _EstadoCoach.listo || _estado == _EstadoCoach.cargando
                ? () => Navigator.of(context).pop()
                : null,
            child: const Text(
              'Terminar',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(child: _buildCuerpo()),
            _barraInferior(),
          ],
        ),
      ),
    );
  }

  Widget _buildCuerpo() {
    switch (_estado) {
      case _EstadoCoach.cargando:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text('Encendiendo la cámara…', style: AppType.bodyMd),
            ],
          ),
        );
      case _EstadoCoach.sinPermiso:
        return _EstadoHonesto(
          icon: Icons.no_photography_outlined,
          titulo: 'Permiso de cámara necesario',
          detalle:
              'La cámara se usa solo para analizar tu postura EN TU MÓVIL: '
              'nada se graba ni se sube. Concede el permiso y vuelve a intentarlo.',
          accion: 'Abrir ajustes',
          onAccion: _abrirAjustes,
        );
      case _EstadoCoach.sinCamara:
        return const _EstadoHonesto(
          icon: Icons.videocam_off_outlined,
          titulo: 'No se encontró la cámara',
          detalle: 'Revisa que el dispositivo tenga una cámara disponible.',
        );
      case _EstadoCoach.sinModelo:
        return _EstadoHonesto(
          icon: Icons.smart_toy_outlined,
          titulo: 'Entrenador con cámara no disponible ahora',
          detalle: _mensaje,
        );
      case _EstadoCoach.listo:
        return Stack(
          fit: StackFit.expand,
          children: [
            if (_camara != null) CameraPreview(_camara!),
            Positioned.fill(
              child: CustomPaint(
                painter: _EsqueletoPainter(_puntos),
              ),
            ),
          ],
        );
    }
  }

  Widget _barraInferior() {
    final tieneContador = _analizador.reps >= 0 &&
        (widget.tipo == TipoPostura.pierna ||
            widget.tipo == TipoPostura.empuje ||
            widget.tipo == TipoPostura.cardio);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.ejercicio.toUpperCase(),
                  style: AppType.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              if (tieneContador)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_analizador.reps} reps',
                    style: AppType.labelMd.copyWith(
                      color: AppColors.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _estado == _EstadoCoach.listo
                  ? AppColors.secondaryContainer.withValues(alpha: 0.35)
                  : AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _estado == _EstadoCoach.listo
                  ? _mensaje
                  : _estado == _EstadoCoach.cargando
                      ? 'Preparando el análisis de postura…'
                      : 'El entrenador con cámara no está activo.',
              style: AppType.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoHonesto extends StatelessWidget {
  const _EstadoHonesto({
    required this.icon,
    required this.titulo,
    required this.detalle,
    this.accion,
    this.onAccion,
  });

  final IconData icon;
  final String titulo;
  final String detalle;
  final String? accion;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: AppType.headlineSm.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              detalle,
              textAlign: TextAlign.center,
              style: AppType.bodyMd.copyWith(color: AppColors.outline),
            ),
            if (accion != null && onAccion != null) ...[
              const SizedBox(height: 18),
              FilledButton.tonal(
                onPressed: onAccion,
                child: Text(accion!, style: AppType.labelLg),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Dibuja el esqueleto (articulaciones normalizadas 0..1) sobre la preview.
class _EsqueletoPainter extends CustomPainter {
  const _EsqueletoPainter(this.puntos);

  final Map<Lm, PuntoPose> puntos;

  static const _segmentos = <(Lm, Lm)>[
    (Lm.hombroIzq, Lm.codoIzq),
    (Lm.codoIzq, Lm.munecaIzq),
    (Lm.hombroDer, Lm.codoDer),
    (Lm.codoDer, Lm.munecaDer),
    (Lm.caderaIzq, Lm.rodillaIzq),
    (Lm.rodillaIzq, Lm.tobilloIzq),
    (Lm.caderaDer, Lm.rodillaDer),
    (Lm.rodillaDer, Lm.tobilloDer),
    (Lm.hombroIzq, Lm.hombroDer),
    (Lm.caderaIzq, Lm.caderaDer),
    (Lm.hombroIzq, Lm.caderaIzq),
    (Lm.hombroDer, Lm.caderaDer),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (puntos.isEmpty) return;
    final linea = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final punto = Paint()..color = AppColors.onPrimary;

    Offset pos(Lm lm) {
      final p = puntos[lm]!;
      return Offset(p.x * size.width, p.y * size.height);
    }

    for (final (a, b) in _segmentos) {
      if (puntos.containsKey(a) && puntos.containsKey(b)) {
        canvas.drawLine(pos(a), pos(b), linea);
      }
    }
    for (final lm in puntos.keys) {
      canvas.drawCircle(pos(lm), 4, punto);
    }
  }

  @override
  bool shouldRepaint(_EsqueletoPainter oldDelegate) =>
      oldDelegate.puntos != puntos;
}