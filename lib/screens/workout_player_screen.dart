import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../state/pose_coach.dart';
import '../state/workout.dart';
import 'pose_coach_screen.dart';
import '../services/ads_service.dart';
import '../services/avisos_service.dart';
import '../services/config_service.dart';
import '../services/locale_service.dart';
import '../theme.dart';

/// Reproductor de entrenamiento (Fase 2).
///
/// Guía al usuario ejercicio por ejercicio con temporizador integrado
/// (trabajo → descanso → siguiente). Al completar el último ejercicio se
/// registra una sesión REAL en [AppState.registrarSesionCompletada].
class WorkoutPlayerScreen extends StatefulWidget {
  const WorkoutPlayerScreen({super.key, required this.program});

  final WorkoutProgram program;

  @override
  State<WorkoutPlayerScreen> createState() => _WorkoutPlayerScreenState();
}

class _WorkoutPlayerScreenState extends State<WorkoutPlayerScreen> {
  int _indice = 0;
  bool _enDescanso = false;
  bool _pausado = false;
  bool _terminado = false;

  late Duration _restante =
      widget.program.ejercicios.first.duracion;
  Timer? _timer;
  final DateTime _inicio = DateTime.now();

  WorkoutExercise get _ejercicio => widget.program.ejercicios[_indice];

  /// Tipo de corrección de postura para el ejercicio actual (Fase 5).
  TipoPostura get _tipoCoachable => tipoDeEjercicio(_ejercicio.nombre);

  /// Abre el entrenador con cámara pausando antes el temporizador para que el
  /// ejercicio no avance mientras se corrige la postura.
  void _abrirEntrenadorCamara() {
    if (!_pausado) _togglePausa();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PoseCoachScreen(
          ejercicio: _ejercicio.nombre,
          tipo: _tipoCoachable,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Fase 8.3: un entrenamiento en curso nunca se interrumpe con un anuncio
    // de apertura (app open). El reproductor es pantalla de alta atención.
    AdsPermiso.ejercicioActivo = true;
    _arrancarTimer();
  }

  @override
  void dispose() {
    AdsPermiso.ejercicioActivo = false;
    _timer?.cancel();
    super.dispose();
  }

  void _arrancarTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_pausado || _terminado) return;
      setState(() {
        _restante -= const Duration(seconds: 1);
        if (_restante <= Duration.zero) {
          _avanzarFase();
        }
      });
    });
  }

  /// Registra las repeticiones reales hechas al terminar el ejercicio actual.
  Future<void> _registrarReps() async {
    final strings = context.read<LocaleService>().strings;
    final ejercicio = _ejercicio.nombre;
    final reps = await _dialogoReps(context, strings);
    if (reps == null || !mounted) return;
    await context.read<AppState>().registrarRepeticiones(ejercicio, reps);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.wpRepsGuardadas(ejercicio, reps))),
    );
  }

  /// Diálogo honesto: el usuario introduce su cuenta real (0–999).
  Future<int?> _dialogoReps(BuildContext context, AppStrings strings) {
    final control = ValueNotifier<int>(0);
    final definidas = _ejercicio.repeticiones;
    return showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceLowest,
        title: Text(
          strings.wpRepsDialogTitulo,
          style: AppType.headlineSm.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _ejercicio.nombre.toUpperCase(),
              style: AppType.labelMd.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
            if (definidas.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                strings.wpRepsDefinidas + strings.wpRepeticiones(definidas),
                style: AppType.bodySm.copyWith(color: AppColors.outline),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              strings.wpRepsDialogHint,
              style: AppType.bodySm.copyWith(color: AppColors.outline),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<int>(
              valueListenable: control,
              builder: (_, valor, _) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _RepsStepBtn(
                    icon: Icons.remove_circle_outline,
                    onTap: () => control.value = math.max(0, valor - 5),
                  ),
                  _RepsStepBtn(
                    icon: Icons.remove,
                    onTap: () => control.value = math.max(0, valor - 1),
                  ),
                  Text(
                    '$valor',
                    style: AppType.metricVal.copyWith(color: AppColors.onSurface),
                  ),
                  _RepsStepBtn(
                    icon: Icons.add,
                    onTap: () => control.value = math.min(999, valor + 1),
                  ),
                  _RepsStepBtn(
                    icon: Icons.add_circle_outline,
                    onTap: () => control.value = math.min(999, valor + 5),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              strings.prCancelar,
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(control.value),
            child: Text(
              strings.prGuardar,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  /// Salta a la fase siguiente (sin esperar al temporizador).
  void _avanzarFase() {
    if (_terminado) return;
    if (_enDescanso) {
      // Descanso terminado → siguiente ejercicio (si existe).
      if (_indice + 1 < widget.program.ejercicios.length) {
        _indice++;
        _enDescanso = false;
        _restante = _ejercicio.duracion;
      } else {
        _finalizar(ofrecerReps: true);
      }
    } else {
      // Trabajo terminado → descanso, o siguiente ejercicio sin descanso.
      if (_ejercicio.descanso.inSeconds > 0) {
        _enDescanso = true;
        _restante = _ejercicio.descanso;
      } else if (_indice + 1 < widget.program.ejercicios.length) {
        _indice++;
        _restante = _ejercicio.duracion;
      } else {
        _finalizar(ofrecerReps: true);
      }
    }
  }

  /// P13: el entrenador con cámara es Premium. Sin Premium se muestra el
  /// candado y al tocarlo se explica cómo activarlo (modo prueba).
  Future<void> _mostrarAvisoPremium() async {
    final strings = context.read<LocaleService>().strings;
    final config = context.read<ConfigService>();
    final activar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceLowest,
        title: Text(
          strings.wpPremiumCoachTitulo,
          style: AppType.headlineSm.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          strings.wpPremiumCoachMensaje,
          style: AppType.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              strings.prCancelar,
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              strings.pfActivarPremium,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (activar == true && mounted) {
      await config.setPremium(true);
      if (!mounted) return;
      _abrirEntrenadorCamara();
    }
  }

  Future<void> _finalizar({bool ofrecerReps = false}) async {
    _terminado = true;
    _timer?.cancel();
    final strings = context.read<LocaleService>().strings;
    final state = context.read<AppState>();
    state.registrarSesionCompletada(
      nombre: widget.program.nombre,
      duracion: DateTime.now().difference(_inicio),
      calorias: widget.program.kcalEstimadas,
    );
    // Fase 6: aviso de racha — hoy ya quedó cubierto; se reprograma mañana
    // con la racha actualizada (texto con datos reales), salvo que el usuario
    // tenga el aviso apagado (entonces solo se cancela el de hoy).
    avisosService.sesionCompletada(
      state.rachaDias,
      reprogramar: state.profile.entrenamientoMatutino,
    );
    // P12: al completar el último ejercicio se ofrece registrar la cuenta real
    // del ejercicio final (no interrumpe el flujo de trabajo).
    if (ofrecerReps && mounted) {
      await _registrarReps();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(strings.wpSesionCompletada(widget.program.nombre)),
      ),
    );
    Navigator.of(context).pop();
  }

  void _saltar() {
    if (_terminado) return;
    setState(() => _avanzarFase());
  }

  void _togglePausa() {
    if (_terminado) return;
    setState(() => _pausado = !_pausado);
  }

  String _mmss(Duration d) {
    final s = d.inSeconds < 0 ? 0 : d.inSeconds;
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    final config = context.watch<ConfigService>();
    final total = widget.program.ejercicios.length;
    final progreso = (total == 0) ? 0.0 : (_indice + (_enDescanso ? 0 : 1)) / total;
    final intensidad = strings.wpIntensidad(widget.program.intensidad);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            _timer?.cancel();
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.close, color: AppColors.onSurfaceVariant),
        ),
        title: Text(
          widget.program.nombre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppType.headlineSm.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              // Barra de progreso global (ejercicio n / total).
              Row(
                children: [
                  Text(
                    '${_indice + 1} / $total',
                    style: AppType.labelMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progreso.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceContainer,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$intensidad · ${strings.wpMin(widget.program.duracionMin)}',
                    style: AppType.labelSm.copyWith(color: AppColors.outline),
                  ),
                ],
              ),
              // P11: reloj protagonista — ocupa la zona central a pantalla
              // completa sin scroll. FittedBox escala hacia abajo si la
              // pantalla es pequeña o la fuente es 2.0× (sin desbordar).
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _enDescanso ? strings.wpDescanso : strings.wpEjercicio,
                        style: AppType.labelMd.copyWith(
                          color: _enDescanso
                              ? AppColors.secondaryFixed
                              : AppColors.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _enDescanso
                              ? AppColors.secondaryContainer
                              : AppColors.primaryContainer,
                          border: Border.all(
                            color: _enDescanso
                                ? AppColors.secondaryFixed
                                    .withValues(alpha: 0.5)
                                : AppColors.primary.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _mmss(_restante),
                          style: AppType.metricVal.copyWith(
                            color: AppColors.onSurface,
                            fontSize: 64,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 340),
                        child: Text(
                          _ejercicio.nombre.toUpperCase(),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.headlineMd.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      if (_ejercicio.repeticiones.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          strings.wpRepeticiones(_ejercicio.repeticiones),
                          style: AppType.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                      // P13: coach de cámara = Premium (candado sin Premium).
                      if (!_enDescanso &&
                          _tipoCoachable != TipoPostura.libre) ...[
                        const SizedBox(height: 14),
                        if (config.premiumEnabled)
                          TextButton.icon(
                            onPressed: _abrirEntrenadorCamara,
                            icon: Icon(
                              Icons.videocam_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            label: Text(
                              strings.wpCorregirPostura,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: _mostrarAvisoPremium,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(color: AppColors.outlineVariant),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            icon: const Icon(Icons.lock_outline, size: 18),
                            label: Text(
                              strings.wpCorregirPosturaPremium,
                              style: AppType.labelMd.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
          // Controles.
          Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saltar,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.onSurfaceVariant,
                        side: BorderSide(color: AppColors.outlineVariant),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(strings.wpSaltar, style: AppType.labelLg),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _togglePausa,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      icon: Icon(
                        _pausado ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        size: 22,
                      ),
                      label: Text(
                        _pausado ? strings.wpReanudar : strings.wpPausar,
                        style: AppType.labelLg.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _terminado ? null : _finalizar,
                child: Text(
                  strings.wpTerminar,
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Fase 3: banner de anuncios en los descansos del reproductor.
      // Se oculta con Premium (el widget degrada a nada sin Play/red).
      bottomNavigationBar: const _PlayerBanner(),
    );
  }
}

/// Banner del reproductor: solo si los anuncios están habilitados y sin Premium.
class _PlayerBanner extends StatelessWidget {
  const _PlayerBanner();

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigService>();
    if (config.premiumEnabled) return const SizedBox.shrink();
    return const FitBannerAd();
  }
}

/// Botón redondo del selector de repeticiones (−5 / −1 / +1 / +5).
class _RepsStepBtn extends StatelessWidget {
  const _RepsStepBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 22, color: AppColors.primary),
      ),
    );
  }
}
