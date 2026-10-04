import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/locale_service.dart';
import '../state/app_state.dart';
import '../state/workout.dart';
import '../theme.dart';
import '../utils/validators.dart';
import '../widgets/common.dart';
import '../widgets/racha_chip.dart';
import 'workout_player_screen.dart';

/// Abre el diálogo para registrar MANUALMENTE el agua consumida hoy (P14):
/// botones rápidos (+250 ml, +500 ml, +1 L) y una cantidad libre aproximada.
/// Cada acción suma al total diario persistido y confirma con un snackbar.
Future<void> _mostrarDialogoRegistrarAgua(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _DialogoRegistrarAgua(),
  );
}

/// Diálogo de agua como StatefulWidget: posee su propio [TextEditingController]
/// y lo libera al salir del árbol (evita usarlo durante la animación de cierre).
class _DialogoRegistrarAgua extends StatefulWidget {
  const _DialogoRegistrarAgua();

  @override
  State<_DialogoRegistrarAgua> createState() => _DialogoRegistrarAguaState();
}

class _DialogoRegistrarAguaState extends State<_DialogoRegistrarAgua> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirmar(String mensaje,
      {Duration duracion = const Duration(seconds: 4)}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(mensaje), duration: duracion));
  }

  Future<void> _registrar(double litros) async {
    final state = context.read<AppState>();
    final strings = context.read<LocaleService>().strings;
    // P19: honestidad sobre los datos. Ningún humano declara más de 5 L de
    // agua al día; si el total (declarado + nuevo) se pasa, no se registra y
    // se avisa con un toast de 5 segundos SIN cerrar el diálogo.
    final total = (state.aguaHoy ?? 0) + litros;
    final aviso =
        Validators.validarAguaDiaria(total, strings.homeAguaSinceridad);
    if (aviso != null) {
      _confirmar(aviso, duracion: const Duration(seconds: 5));
      return;
    }
    await state.registrarAgua(litros);
    _confirmar(strings.homeAguaRegistrada(litros));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final strings = context.read<LocaleService>().strings;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(strings.homeTituloRegistrarAgua),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${strings.homeAguaTotal}: '
              '${(state.aguaHoy ?? 0).toStringAsFixed(2)} L',
              style: AppType.bodyMd.copyWith(color: AppColors.onSurface),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('+0,25 L'),
                  onPressed: () => _registrar(0.25),
                ),
                ActionChip(
                  label: const Text('+0,50 L'),
                  onPressed: () => _registrar(0.5),
                ),
                ActionChip(
                  label: const Text('+1 L'),
                  onPressed: () => _registrar(1.0),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: strings.homeAguaCantidad,
                hintText: '0,3',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.homeCerrar),
        ),
        FilledButton(
          onPressed: () {
            final texto = _controller.text.trim().replaceAll(',', '.');
            final litros = double.tryParse(texto);
            if (litros == null || litros <= 0) return;
            _registrar(litros);
          },
          child: Text(strings.homeAguaAnadir),
        ),
      ],
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _HomeHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _DiaIdealCard(),
                  const SizedBox(height: 24),
                  _buildResumenHoy(),
                  const SizedBox(height: 24),
                  _buildEntrenamientoHoy(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenHoy() {
    final state = context.watch<AppState>();
    final strings = context.watch<LocaleService>().strings;
    final pasosDisponible = state.healthDisponible;
    final pulso = state.pulsoHoy;
    final pulsoConPermiso = state.pulsoConPermiso;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: strings.homeResumenHoy,
          actionLabel: strings.homeVerDetalles,
          onAction: _mostrarDetalleHoy,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _PasosCard(
                steps: pasosDisponible ? state.pasosHoy : -1,
                goal: state.profile.pasosMeta,
                available: pasosDisponible,
                onTap: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: MetricCard(
                stat: MetricStat(
                  label: strings.homeCalorias,
                  value: state.caloriasConsumidas.round().toString(),
                  unit: 'kcal',
                  icon: Icons.local_fire_department,
                  iconColor: AppColors.primary,
                  iconBackground: AppColors.surfaceContainer,
                ),
                subtitle: strings.homeMetaKcal(state.caloriasMeta.round()),
                progress: state.progresoCalorias,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                stat: MetricStat(
                  label: strings.homePulso,
                  value: pulso?.toString() ?? '—',
                  unit: 'bpm',
                  icon: Icons.favorite,
                  iconColor: pulsoConPermiso ? AppColors.primary : AppColors.outline,
                  iconBackground: pulsoConPermiso
                      ? AppColors.surfaceContainer
                      : AppColors.surfaceContainerHighest,
                ),
                subtitle: pulso != null
                    ? strings.homeUltimaLectura
                    : (pulsoConPermiso
                        ? strings.homeSinLectura
                        : (state.healthConnectDisponible
                            ? strings.homeConectaHealth
                            : strings.requiereHealthConnect)),
                subtitleColor:
                    pulso != null ? AppColors.primary : AppColors.outline,
                radius: 24,
                progress: null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          strings.homeOrientativo,
          style: AppType.labelSm.copyWith(color: AppColors.outline),
        ),
      ],
    );
  }

  /// Abre el detalle del día de hoy con las métricas REALES del momento:
  /// pasos vs meta, kcal consumidas vs meta, pulso y agua (si hay permiso).
  /// Nunca inventa un valor: cada fila muestra '—' cuando no hay dato.
  Future<void> _mostrarDetalleHoy() async {
    final strings = context.read<LocaleService>().strings;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        final s = context.read<AppState>();
        final pasosDisponible = s.healthDisponible;
        final pulso = s.pulsoHoy;
        final agua = s.aguaHoy;
        // Hay dato de agua si HC tiene permiso, o si el usuario registró agua
        // manualmente (P14: se muestra aunque no exista permiso de HC).
        final tieneAgua = s.aguaConPermiso || s.aguaManualHoy > 0;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(sheetCtx).viewInsets.bottom > 0
                ? 16
                : MediaQuery.of(sheetCtx).padding.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  strings.homeDetalleHoy,
                  style: AppType.headlineSm.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _FilaDetalleHoy(
                  icon: Icons.directions_walk,
                  label: strings.homePasos,
                  valor: pasosDisponible
                      ? _groupThousands(s.pasosHoy)
                      : '—',
                  sub: pasosDisponible
                      ? strings.homePasosMeta(s.profile.pasosMeta)
                      : strings.homeActivaPermiso,
                ),
                _FilaDetalleHoy(
                  icon: Icons.local_fire_department,
                  label: strings.homeCalorias,
                  valor: '${s.caloriasConsumidas.round()}',
                  sub: strings.homeMetaKcal(s.caloriasMeta.round()),
                ),
                _FilaDetalleHoy(
                  icon: Icons.favorite,
                  label: strings.homePulso,
                  valor: pulso?.toString() ?? '—',
                  sub: pulso != null
                      ? strings.homeUltimaLectura
                      : (s.pulsoConPermiso
                          ? strings.homeSinLectura
                          : (s.healthConnectDisponible
                              ? strings.homeConectaHealth
                              : strings.requiereHealthConnect)),
                ),
                _FilaDetalleHoy(
                  icon: Icons.water_drop,
                  label: strings.homeAgua,
                  valor: tieneAgua && agua != null
                      ? agua.toStringAsFixed(1)
                      : '—',
                  sub: tieneAgua && agua != null
                      ? strings.homeAguaHoy
                      : strings.requiereHealthConnect,
                ),
                const SizedBox(height: 8),
                Text(
                  strings.homeOrientativo,
                  style: AppType.labelSm.copyWith(color: AppColors.outline),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () => Navigator.of(sheetCtx).pop(),
                    child: Text(strings.homeCerrar),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEntrenamientoHoy() {
    final strings = context.watch<LocaleService>().strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(strings.homeEntrenamientoHoy, style: AppType.headlineSm.copyWith(fontWeight: FontWeight.w700)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                strings.homeSugerido,
                style: AppType.labelSm.copyWith(
                  color: AppColors.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _WorkoutHeroCard(program: context.watch<AppState>().entrenamientoRecomendado),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    // Saludo personalizado con el nombre del atleta de la sesión.
    final state = context.watch<AppState>();
    final strings = context.watch<LocaleService>().strings;
    final nombre = state.profile.nombre.split(' ').first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(color: AppColors.surface),
      child: Row(
        children: [
          Stack(
            children: [
              FitAvatar(
                nombre: state.profile.nombre,
                fotoBase64: state.profile.fotoBase64,
                radius: 24,
                borde: AppColors.outlineVariant,
                bordeAncho: 2,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryFixed,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.homeHola(nombre),
                  style: AppType.headlineSm.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  strings.homeListo,
                  style: AppType.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          RachaChip(racha: state.rachaDias, borde: true),
          const SizedBox(width: 4),
          _IconButtonWithBadge(
            icon: Icons.notifications_outlined,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _IconButtonWithBadge extends StatelessWidget {
  const _IconButtonWithBadge({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: 22, color: AppColors.onSurfaceVariant),
            Positioned(
              right: 4,
              top: 3,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasosCard extends StatelessWidget {
  const _PasosCard({
    required this.steps,
    required this.goal,
    required this.available,
    required this.onTap,
  });

  final int steps;
  final int goal;
  final bool available;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    final percent = available && goal > 0 ? steps / goal : 0.0;
    return Material(
      color: AppColors.surfaceLowest,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryContainer.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 4),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.directions_walk, size: 18, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          strings.homePasos,
                          style: AppType.labelMd.copyWith(
                            color: AppColors.outline,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              available ? _groupThousands(steps) : '—',
                              style: AppType.metricVal.copyWith(
                                color: available ? AppColors.onSurface : AppColors.outline,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            available ? '/ ${_groupThousands(goal)}' : '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!available)
                      Text(
                        strings.homeActivaPermiso,
                        textAlign: TextAlign.left,
                        style: AppType.bodySm.copyWith(color: AppColors.outline),
                      ),
                  ],
                ),
              ),
              AppProgressRing(
                progress: percent,
                size: 80,
                strokeWidth: 5,
                center: Text(
                  available ? '${(percent * 100).round()}%' : '—',
                  style: AppType.labelLg.copyWith(
                    color: available ? AppColors.onSurface : AppColors.outline,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _groupThousands(int value) => value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );

class _WorkoutHeroCard extends StatelessWidget {
  const _WorkoutHeroCard({required this.program});

  final WorkoutProgram program;

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    final intensidad = program.intensidad.toUpperCase();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gradienteInicio,
            AppColors.gradienteIntermedio,
            AppColors.gradienteFin,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            bottom: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.onGradienteAcento.withValues(alpha: 0.15), width: 8),
              ),
            ),
          ),
          Positioned(
            right: 30,
            top: 10,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.onGradienteAcento.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.homeRecomendado(
                  program.duracionEtiqueta.toUpperCase(),
                  intensidad,
                ),
                style: AppType.labelSm.copyWith(
                  color: AppColors.onGradienteAcento,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                program.nombre,
                style: AppType.headlineLg.copyWith(
                  color: AppColors.onGradiente,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                program.descripcion,
                style: AppType.bodySm.copyWith(color: AppColors.onGradienteVariant),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroInfoChip(icon: Icons.schedule, label: program.duracionEtiqueta),
                  _HeroInfoChip(icon: Icons.local_fire_department, label: program.kcalEtiqueta),
                  _HeroInfoChip(icon: Icons.fitness_center, label: program.ejerciciosEtiqueta),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: AppColors.botonGradiente,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => WorkoutPlayerScreen(program: program),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded, size: 22, color: AppColors.onBotonGradiente),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              strings.homeComenzar,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.labelLg.copyWith(
                                color: AppColors.onBotonGradiente,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroInfoChip extends StatelessWidget {
  const _HeroInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.onGradienteAcento.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.onGradienteAcento.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.onGradienteAcento),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.labelMd.copyWith(color: AppColors.onGradiente, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaIdealCard extends StatefulWidget {
  const _DiaIdealCard();

  @override
  State<_DiaIdealCard> createState() => _DiaIdealCardState();
}

class _DiaIdealCardState extends State<_DiaIdealCard> {
  /// P18: la recompensa del Día ideal se dispara UNA vez por día, en el
  /// momento exacto en que el tercer objetivo se completa (3/3).
  bool _premioDisparado = false;
  bool _celebrando = false;

  /// Detección del 3/3: si hoy ya están los 3 objetivos y aún no se premió,
  /// agenda (tras el frame, para no mutar durante el build) la concesión del
  /// +25 XP y la celebración visual suave.
  void _vigilarPremioDiaIdeal(AppState state) {
    if (_premioDisparado || _celebrando) return;
    if (state.recompensaDiaIdealOtorgadaHoy) return;
    if (!state.diaIdealCompletadoHoy) return;
    _premioDisparado = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final otorgada = await state.aplicarRecompensaDiaIdeal();
      if (!mounted || !otorgada) return;
      setState(() => _celebrando = true);
      Future<void>.delayed(const Duration(milliseconds: 2800), () {
        if (mounted) setState(() => _celebrando = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final strings = context.watch<LocaleService>().strings;
    final entrenado = state.entrenadoHoy;
    final metaOk = state.progresoCalorias >= 1.0;
    final aguaOk = (state.aguaHoy ?? 0) >= AppState.metaAguaDiaria;
    final completados = [entrenado, metaOk, aguaOk].where((v) => v).length;
    final recomendado = state.entrenamientoRecomendado;

    _vigilarPremioDiaIdeal(state);

    final tarjeta = Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  strings.homeDiaIdeal,
                  style: AppType.labelLg.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    strings.homeCompletados(completados),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.labelSm.copyWith(
                      color: AppColors.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            strings.homeCompletaObjetivos,
            style: AppType.bodySm.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: 12),
          _DiaIdealItem(
            icon: Icons.fitness_center,
            title: strings.homeEntrenamiento,
            subtitle: '${recomendado.nombre} • ${recomendado.duracionEtiqueta}',
            done: entrenado,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => WorkoutPlayerScreen(program: recomendado),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _DiaIdealItem(
            icon: Icons.set_meal_outlined,
            title: strings.homeMacros,
            subtitle: '${state.caloriasConsumidas.round()} / ${state.caloriasMeta.round()} kcal',
            done: metaOk,
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _DiaIdealItem(
            icon: Icons.water_drop_outlined,
            title: strings.homeAgua,
            subtitle: state.aguaHoy != null
                ? '${state.aguaHoy!.toStringAsFixed(1)} / ${AppState.metaAguaDiaria} L'
                : strings.homeObjetivoAgua(AppState.metaAguaDiaria.toString()),
            done: aguaOk,
            onTap: () => _mostrarDialogoRegistrarAgua(context),
          ),
        ],
      ),
    );

    if (!_celebrando) return tarjeta;
    // P18: celebración NO bloqueante (no intercepta toques) sobre la tarjeta:
    // confeti + check + "+25 XP · ¡Día ideal completado!", se desvanece sola.
    return Stack(
      children: [
        tarjeta,
        Positioned.fill(
          child: IgnorePointer(
            child: _CelebracionDiaIdeal(strings: strings),
          ),
        ),
      ],
    );
  }
}

/// Celebración visual del Día ideal (P18): animación breve y sin sonido de
/// confeti + check + texto, que se desvanece sola. No bloquea la interacción.
class _CelebracionDiaIdeal extends StatefulWidget {
  const _CelebracionDiaIdeal({required this.strings});

  final AppStrings strings;

  @override
  State<_CelebracionDiaIdeal> createState() => _CelebracionDiaIdealState();
}

class _CelebracionDiaIdealState extends State<_CelebracionDiaIdeal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        final fade = t < 0.8 ? 1.0 : (1.0 - (t - 0.8) / 0.2).clamp(0.0, 1.0);
        final checkScale = Curves.easeOutBack.transform((t * 1.5).clamp(0.0, 1.0));
        return Opacity(
          opacity: fade,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _ConfettiPainter(t)),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scale: checkScale,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: AppColors.onPrimary,
                          size: 34,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            widget.strings.homeDiaIdealCelebracion,
                            style: AppType.labelLg.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.strings
                                .homeDiaIdealRecompensa(AppState.ptsDiaIdeal),
                            style: AppType.bodyMd.copyWith(
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Partículas de confeti deterministas (semilla fija) que caen y rotan con el
/// progreso de la animación. Solo colores de la paleta; sin assets externos.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    final colores = <Color>[
      AppColors.primary,
      AppColors.secondaryFixed,
      AppColors.tertiaryContainer,
      AppColors.gradienteIntermedio,
      AppColors.primaryContainer,
    ];
    const n = 26;
    for (var i = 0; i < n; i++) {
      final baseX = rng.nextDouble() * size.width;
      final velocidad = 0.5 + rng.nextDouble() * 0.6;
      final y = t * size.height * velocidad;
      if (y < -6 || y > size.height + 6) continue;
      final x = baseX + sin(t * 6 + i) * 14;
      final angle = t * 8 + i;
      final ancho = 6.0 + rng.nextDouble() * 5;
      final alto = 3.0 + rng.nextDouble() * 3;
      final paint = Paint()..color = colores[i % colores.length];
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: ancho, height: alto),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => oldDelegate.t != t;
}

class _DiaIdealItem extends StatelessWidget {
  const _DiaIdealItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    final fg = done ? AppColors.primary : AppColors.onSurfaceVariant;
    return Material(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: done
                      ? AppColors.primary
                      : AppColors.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  done ? Icons.check : icon,
                  size: 16,
                  color: done ? AppColors.onPrimary : fg,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.labelMd.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.bodySm.copyWith(color: AppColors.outline),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                done ? '✓' : strings.homePendiente,
                style: AppType.labelSm.copyWith(
                  color: done ? AppColors.primary : AppColors.outline,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration({double radius = 24}) {
  return BoxDecoration(
    color: AppColors.surfaceLowest,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
    boxShadow: [
      BoxShadow(
        color: AppColors.primaryContainer.withValues(alpha: 0.06),
        blurRadius: 20,
        offset: const Offset(0, 4),
        spreadRadius: -2,
      ),
    ],
  );
}

/// Fila de una métrica real del día dentro del bottom sheet "Detalle del día".
class _FilaDetalleHoy extends StatelessWidget {
  const _FilaDetalleHoy({
    required this.icon,
    required this.label,
    required this.valor,
    required this.sub,
  });

  final IconData icon;
  final String label;
  final String valor;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppType.labelMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.bodySm.copyWith(color: AppColors.outline),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            valor,
            style: AppType.headlineSm.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
