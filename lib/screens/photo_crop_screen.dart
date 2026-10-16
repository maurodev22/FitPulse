import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/locale_service.dart';
import '../theme.dart';
import '../utils/foto_avatar.dart';

/// Editor de encuadre de la foto de perfil.
///
/// Permite **arrastrar** (mover) y **pellizcar** (acercar/alejar) la foto dentro
/// de un círculo, y devuelve la foto cuadrada resultante (PNG base64) lista
/// para guardar. El círculo guía es exactamente lo que verá el avatar.
///
/// Recibe la foto ya preparada con [prepararFotoParaEditar] (orientación EXIF
/// normalizada, medidas y ventana sugerida) para no repetir trabajo pesado en
/// el hilo de UI; el llamador es quien hace ese paso con `compute`.
class PhotoCropScreen extends StatefulWidget {
  const PhotoCropScreen({super.key, required this.preparacion});

  final PreparacionFoto preparacion;

  /// Abre el editor y devuelve la foto recortada (base64) o `null` si se
  /// cancela. No procesa nada aquí: el llamador ya preparó [preparacion].
  static Future<String?> abrir(
    BuildContext context,
    PreparacionFoto preparacion,
  ) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        fullscreenDialog: true,
        builder: (_) => PhotoCropScreen(preparacion: preparacion),
      ),
    );
  }

  @override
  State<PhotoCropScreen> createState() => _PhotoCropScreenState();
}

class _PhotoCropScreenState extends State<PhotoCropScreen> {
  static const _zoomMin = 1.0;
  static const _zoomMax = 4.0;
  static const _salidaPx = 512;
  static const _pieAlto = 108.0;

  late final int _ancho = widget.preparacion.ancho;
  late final int _alto = widget.preparacion.alto;
  late final Uint8List _bytes = base64Decode(widget.preparacion.fotoBase64);

  /// Escala de zoom (1 = la foto cubre el círculo justo; >1 = acercada).
  double _zoom = 1;
  /// Punto de la imagen (en píxeles) que queda en el centro del círculo.
  double _centroX = 0;
  double _centroY = 0;

  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _aplicarInicial();
  }

  /// Encaje inicial: usa la ventana sugerida (sujeto detectado) si existe; si
  /// no, la foto completa centrada.
  void _aplicarInicial() {
    final sug = widget.preparacion.sugerencia;
    if (sug == null || sug.width <= 0) {
      _zoom = _zoomMin;
      _centroX = _ancho / 2;
      _centroY = _alto / 2;
      return;
    }
    // Un cuadrado de lado `sug.width` que llene el encuadre equivale al zoom
    // min(ancho, alto) / sug.width (independiente del tamaño en pantalla).
    final zoom = (math.min(_ancho, _alto) / sug.width).clamp(_zoomMin, _zoomMax);
    final centro = limitarCentro(
      ancho: _ancho,
      alto: _alto,
      zoom: zoom,
      x: sug.x + sug.width / 2,
      y: sug.y + sug.height / 2,
    );
    _zoom = zoom;
    _centroX = centro.x;
    _centroY = centro.y;
  }

  void _restablecer() {
    setState(() {
      _zoom = _zoomMin;
      _centroX = _ancho / 2;
      _centroY = _alto / 2;
    });
  }

  double _k(double lado) => (lado / math.min(_ancho, _alto)) * _zoom;

  void _onScaleStart(ScaleStartDetails d) {
    _zoomBase = _zoom;
    _centroXBase = _centroX;
    _centroYBase = _centroY;
    _focoBase = d.localFocalPoint;
  }

  double _zoomBase = 1;
  double _centroXBase = 0;
  double _centroYBase = 0;
  Offset _focoBase = Offset.zero;

  void _onScaleUpdate(ScaleUpdateDetails d, double lado) {
    final kBase = (lado / math.min(_ancho, _alto)) * _zoomBase;
    final offsetBase = Offset(
      lado / 2 - _centroXBase * kBase,
      lado / 2 - _centroYBase * kBase,
    );
    // Punto de la imagen que estaba bajo el foco al empezar el gesto.
    final imgX = (_focoBase.dx - offsetBase.dx) / kBase;
    final imgY = (_focoBase.dy - offsetBase.dy) / kBase;

    final zoom = (_zoomBase * d.scale).clamp(_zoomMin, _zoomMax);
    final kNuevo = (lado / math.min(_ancho, _alto)) * zoom;
    final foco = d.localFocalPoint;
    final centro = limitarCentro(
      ancho: _ancho,
      alto: _alto,
      zoom: zoom,
      x: (lado / 2 - (foco.dx - imgX * kNuevo)) / kNuevo,
      y: (lado / 2 - (foco.dy - imgY * kNuevo)) / kNuevo,
    );
    setState(() {
      _zoom = zoom;
      _centroX = centro.x;
      _centroY = centro.y;
    });
  }

  Future<void> _listo(double lado) async {
    final region = regionBajoEncuadre(
      ancho: _ancho,
      alto: _alto,
      lado: lado,
      zoom: _zoom,
      centroX: _centroX,
      centroY: _centroY,
    );
    setState(() => _procesando = true);
    final resultado = await compute(
      recortarRegionFoto,
      (
        fotoBase64: widget.preparacion.fotoBase64,
        x: region.x.round(),
        y: region.y.round(),
        lado: region.lado.round(),
        salida: _salidaPx,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(resultado);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: strings.croCancelar,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          strings.croTitulo,
          style: AppType.headlineSm.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, c) {
            final lado = math.max(
              0.0,
              math.min(c.maxWidth, c.maxHeight - _pieAlto),
            );
            return Column(
              children: [
                Expanded(child: Center(child: _area(lado))),
                _pie(lado, strings),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _area(double lado) {
    final k = _k(lado);
    final offX = lado / 2 - _centroX * k;
    final offY = lado / 2 - _centroY * k;
    return SizedBox(
      width: lado,
      height: lado,
      child: ClipRect(
        child: GestureDetector(
          key: const Key('croArea'),
          onScaleStart: _onScaleStart,
          onScaleUpdate: (d) => _onScaleUpdate(d, lado),
          onDoubleTap: _restablecer,
          child: Stack(
            children: [
              Positioned(
                left: offX,
                top: offY,
                width: _ancho * k,
                height: _alto * k,
                child: Image.memory(
                  _bytes,
                  fit: BoxFit.fill,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _GuiaEncuadre()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pie(double lado, AppStrings strings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            strings.croAyuda,
            textAlign: TextAlign.center,
            style: AppType.bodySm.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('croRestablecer'),
                  onPressed: _procesando ? null : _restablecer,
                  icon: const Icon(Icons.restart_alt, size: 18),
                  label: Text(strings.croRestablecer),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  key: const Key('croListo'),
                  onPressed: _procesando ? null : () => _listo(lado),
                  icon: _procesando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: Text(strings.croListo),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Oscurece lo que queda fuera del círculo del avatar y dibuja su borde.
class _GuiaEncuadre extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final circulo = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: math.min(size.width, size.height) / 2,
        ),
      );
    final fuera = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      circulo,
    );
    canvas.drawPath(fuera, Paint()..color = Colors.black.withValues(alpha: 0.55));
    canvas.drawPath(
      circulo,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _GuiaEncuadre oldDelegate) => false;
}
