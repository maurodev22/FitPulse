import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/locale_service.dart';
import '../state/app_state.dart';
import '../state/workout.dart';
import '../services/ads_service.dart';
import '../services/config_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Progreso y Rendimiento: métricas REALES del dispositivo.
///
/// Regla del proyecto: nada de números inventados. Peso e IMC vienen del
/// perfil; grasa, gasto activo y tiempo activo vienen de Health Connect (o
/// "—" si no hay dato); sesiones, racha, retos e insignias se calculan del
/// historial real de entrenamiento.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final strings = context.watch<LocaleService>().strings;
    final profile = state.profile;
    final hayHistorial = state.historial.isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _ProgressHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        strings.prEvolucion,
                        maxLines: 1,
                        style: AppType.headlineLg.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hayHistorial
                        ? strings.prRachaNivel(state.rachaDias, state.nivel)
                        : strings.prRegistraPrimero,
                    style: AppType.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  const _PeriodTabs(),
                  const SizedBox(height: 16),
                  _buildPesoCard(profile.pesoKg, strings),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SmallStat(
                          icon: Icons.opacity,
                          label: strings.prGrasa,
                          value: state.grasaHoy?.toStringAsFixed(1) ?? '—',
                          unit: state.grasaHoy != null ? '%' : '',
                          trend: _textoTrend(
                            context,
                            strings,
                            conPermiso: state.grasaConPermiso,
                            valor: state.grasaHoy,
                          ),
                          trendColor: state.grasaHoy != null
                              ? AppColors.primary
                              : AppColors.outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SmallStat(
                          icon: Icons.insights,
                          label: strings.prImcIndex,
                          value: profile.imcFormateado,
                          unit: '',
                          trend: strings.deTuPerfil,
                          trendColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SmallStat(
                          icon: Icons.local_fire_department,
                          label: strings.prGastoActivo,
                          value: state.gastoActivoHoy?.round().toString() ?? '—',
                          unit: state.gastoActivoHoy != null ? 'kcal' : '',
                          trend: _textoTrend(
                            context,
                            strings,
                            conPermiso: state.gastoActivoConPermiso,
                            valor: state.gastoActivoHoy,
                          ),
                          trendColor: state.gastoActivoHoy != null
                              ? AppColors.primary
                              : AppColors.outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SmallStat(
                          icon: Icons.schedule,
                          label: strings.prTiempoActivo,
                          value: state.tiempoActivoMin?.toString() ?? '—',
                          unit: state.tiempoActivoMin != null ? 'min' : '',
                          trend: _textoActivo(
                            context,
                            strings,
                            valor: state.tiempoActivoMin,
                          ),
                          trendColor: state.tiempoActivoMin != null
                              ? AppColors.primary
                              : AppColors.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _textoFuenteMetrricas(context, strings),
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Inter',
                      color: AppColors.outline,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRetoCard(state, strings),
                  const SizedBox(height: 12),
                  _buildNivelCard(state, strings),
                  const SizedBox(height: 12),
                  _buildRecompensaAnuncio(context),
                  const SizedBox(height: 12),
                  _buildSemanaCard(state, profile.diasEntrenamiento.length, strings),
                  const SizedBox(height: 12),
                  _ConsistenciaBanner(
                    porcentaje: hayHistorial
                        ? (state.diasEntrenadosSemana /
                                (profile.diasEntrenamiento.isEmpty
                                    ? 5
                                    : profile.diasEntrenamiento.length))
                            .clamp(0.0, 1.0)
                        : 0.0,
                    hayHistorial: hayHistorial,
                  ),
                  const SizedBox(height: 20),
                  SectionHeader(
                    title: strings.prSesionesRecientes,
                    actionLabel: strings.prVerTodo,
                  ),
                  const SizedBox(height: 12),
                  _buildSesiones(state, strings),
                  const SizedBox(height: 20),
                  SectionHeader(title: strings.prInsignias),
                  const SizedBox(height: 12),
                  _buildInsignias(state, strings),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _textoTrend(
    BuildContext context,
    AppStrings strings, {
    required bool conPermiso,
    required Object? valor,
  }) {
    if (valor != null) return strings.healthConnect;
    if (conPermiso) return strings.prSinDatosHoy;
    if (context.read<AppState>().healthConnectDisponible) {
      return strings.prConcedePermiso;
    }
    return strings.requiereHealthConnect;
  }

  /// Nota honesta del "Tiempo Activo": el paquete `health` 13.3.2 solo expone
  /// EXERCISE_TIME en iOS, así que en Android nunca hay dato → siempre "—".
  String _textoActivo(BuildContext context, AppStrings strings, {required Object? valor}) {
    if (valor != null) return strings.healthConnect;
    return strings.prSoloIOS;
  }

  String _textoFuenteMetrricas(BuildContext context, AppStrings strings) {
    final state = context.read<AppState>();
    if (!state.healthConnectDisponible) {
      return strings.prFuente1;
    }
    final concedidas = [
      if (state.grasaConPermiso) strings.prMetricaGrasa,
      if (state.gastoActivoConPermiso) strings.prMetricaGastoActivo,
    ];
    if (concedidas.isEmpty) {
      return strings.prFuente2;
    }
    return strings.prFuente3(concedidas.join(', '));
  }

  /// Tarjeta principal de evolución de peso corporal con mini gráfico.
  Widget _buildPesoCard(double peso, AppStrings strings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_weight, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.prPesoCorporal,
                  style: AppType.labelMd.copyWith(
                    color: AppColors.outline,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  strings.deTuPerfil,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.labelMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                peso.toStringAsFixed(1),
                style: AppType.metricVal.copyWith(color: AppColors.onSurface),
              ),
              const SizedBox(width: 4),
              Text(
                'kg',
                style: AppType.labelMd.copyWith(color: AppColors.outline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MiniWeightChart(label: strings.prRegistraPeso),
        ],
      ),
    );
  }

  Widget _buildRetoCard(AppState state, AppStrings strings) {
    final objetivo = state.retoObjetivo;
    final progreso = state.retoProgreso;
    final completado = state.retoCompletado;
    final siguiente = objetivo == 3 ? 5 : (objetivo == 5 ? 7 : 7);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.prRetoActual,
                  style: AppType.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                completado
                    ? strings.prCompletado
                    : strings.prRetoDias(progreso, objetivo),
                style: AppType.labelMd.copyWith(
                  color: completado ? AppColors.primary : AppColors.outline,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            completado
                ? strings.prRetoCompletado(objetivo, siguiente)
                : strings.prRetoActivo(objetivo),
            style: AppType.bodySm.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (progreso / objetivo).clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: AppColors.surfaceContainer,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNivelCard(AppState state, AppStrings strings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.prNivel(state.nivel, state.nombreNivel),
                  style: AppType.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                strings.prPts(state.xp),
                style: AppType.labelMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            strings.prPtsParaNivel(300 - (state.xp % 300), state.nivel + 1),
            style: AppType.bodySm.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: state.progresoNivel,
              minHeight: 7,
              backgroundColor: AppColors.surfaceContainer,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta del anuncio recompensado (Fase 3): +25 PTs una vez por día.
  ///
  /// Se oculta si el usuario tiene Premium. Siempre usa el ID de prueba de
  /// AdMob; el cobro real requiere cuenta fuera de Cuba (ver PLAN.md).
  Widget _buildRecompensaAnuncio(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    final config = context.watch<ConfigService>();
    if (config.premiumEnabled) return const SizedBox.shrink();

    final state = context.watch<AppState>();
    final disponible = state.recompensaAnuncioDisponibleHoy;

    Future<void> verAnuncio() async {
      final messenger = ScaffoldMessenger.of(context);
      final appState = context.read<AppState>();
      await mostrarAnuncioRecompensado(
        context: context,
        onRecompensa: () async {
          final aplicada = await appState.aplicarRecompensaAnuncio();
          messenger.showSnackBar(SnackBar(
            content: Text(aplicada
                ? strings.prPTsGanados(AppState.ptsRecompensaAnuncio)
                : strings.prRecompensaYaRecibida),
          ));
        },
        onError: (mensaje) {
          messenger.showSnackBar(SnackBar(content: Text(mensaje)));
        },
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.play_circle_outline, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.prAnuncioRecompensado,
                  style: AppType.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                strings.prPTs(AppState.ptsRecompensaAnuncio),
                style: AppType.labelMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            disponible ? strings.prAnuncioGana : strings.prAnuncioRecibida,
            style: AppType.bodySm.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: disponible ? verAnuncio : null,
              child: Text(
                disponible ? strings.prVerAnuncio : strings.prRecibidoHoy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemanaCard(AppState state, int diasMeta, AppStrings strings) {
    final entrenados = state.diasSemanaEntrenados;
    final total = diasMeta > 0 ? diasMeta : 5;
    final dias = strings.diasIniciales;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.prSemana,
                  style: AppType.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                strings.prSemanaDias(state.diasEntrenadosSemana, total),
                style: AppType.labelMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < dias.length; i++)
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: entrenados.contains(i)
                              ? AppColors.primary
                              : AppColors.surfaceContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          entrenados.contains(i) ? Icons.check : Icons.remove,
                          size: 14,
                          color: entrenados.contains(i)
                              ? Colors.white
                              : AppColors.outline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dias[i],
                        textAlign: TextAlign.center,
                        style: AppType.labelSm.copyWith(color: AppColors.outline),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Icon(Icons.history, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  state.minutosEntrenadosSemana > 0
                      ? strings.prMinSemana(state.minutosEntrenadosSemana)
                      : strings.prSinSesionesSemana,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.labelMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSesiones(AppState state, AppStrings strings) {
    final recientes = state.historial.take(3).toList();
    if (recientes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(radius: 16),
        child: Column(
          children: [
            Icon(Icons.fitness_center, size: 28, color: AppColors.outline),
            const SizedBox(height: 8),
            Text(
              strings.prSinSesiones,
              style: AppType.labelMd.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              strings.prSinSesionesHint,
              textAlign: TextAlign.center,
              style: AppType.bodySm.copyWith(color: AppColors.outline),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (final s in recientes) _SesionRow.fromSesion(s, strings),
      ],
    );
  }

  Widget _buildInsignias(AppState state, AppStrings strings) {
    final insignias = <({IconData icono, String nombre, String detalle})>[
      if (state.historial.isNotEmpty)
        (
          icono: Icons.fitness_center,
          nombre: strings.prPrimeraSesion,
          detalle: strings.prCompletada
        ),
      if (state.rachaMaxima >= 3)
        (
          icono: Icons.local_fire_department,
          nombre: strings.prRacha3,
          detalle: strings.prConstancia
        ),
      if (state.rachaMaxima >= 7)
        (
          icono: Icons.whatshot,
          nombre: strings.prRacha7,
          detalle: strings.prDisciplina
        ),
      if (state.nivel >= 2)
        (
          icono: Icons.workspace_premium,
          nombre: strings.prInsigniaNivel(state.nivel),
          detalle: strings.nivelName(state.nombreNivel)
        ),
      if (state.retoCompletado)
        (
          icono: Icons.emoji_events,
          nombre: strings.prInsigniaReto(state.retoObjetivo),
          detalle: strings.prCompletado
        ),
    ];
    if (insignias.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(radius: 16),
        child: Column(
          children: [
            Icon(Icons.emoji_events_outlined, size: 28, color: AppColors.outline),
            const SizedBox(height: 8),
            Text(
              strings.prDesbloqueaInsignias,
              textAlign: TextAlign.center,
              style: AppType.bodySm.copyWith(color: AppColors.outline),
            ),
          ],
        ),
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final ins in insignias)
          Container(
            width: 105,
            padding: const EdgeInsets.all(12),
            decoration: _cardDecoration(radius: 16),
            child: Column(
              children: [
                Icon(ins.icono, size: 22, color: AppColors.primary),
                const SizedBox(height: 6),
                Text(
                  ins.nombre,
                  style: AppType.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  ins.detalle,
                  style: AppType.labelSm.copyWith(color: AppColors.outline),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final strings = context.watch<LocaleService>().strings;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(color: AppColors.surface),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.navProgress,
                  style: AppType.headlineSm.copyWith(fontWeight: FontWeight.w700, height: 1.1),
                ),
                const SizedBox(height: 2),
                Text(
                  state.entrenadoHoy ? strings.prDiaCompletado : strings.listoParaEntrenar,
                  style: AppType.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  strings.rachaDias(state.rachaDias),
                  style: AppType.labelMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.notifications_outlined, size: 22, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs();

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    final periodos = [
      strings.prPeriodoSemanal,
      strings.prPeriodoMensual,
      strings.prPeriodoAno,
    ];
    final seleccionado = strings.prPeriodoSemanal;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final p in periodos)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p == seleccionado ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  p,
                  style: AppType.labelMd.copyWith(
                    color: p == seleccionado ? Colors.white : AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.trend,
    this.trendColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final String trend;
  final Color? trendColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppType.labelSm.copyWith(
              color: AppColors.outline,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.headlineSm.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: AppType.labelSm.copyWith(color: AppColors.outline),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            trend,
            style: AppType.labelSm.copyWith(
              color: trendColor ?? AppColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniWeightChart extends StatelessWidget {
  const _MiniWeightChart({this.label});

  static const _valores = [3.0, 4.2, 3.6, 5.0, 4.0, 4.8, 3.2];
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 48,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final v in _valores)
                Container(
                  width: 22,
                  height: 48 * v / 5.0,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
            ],
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 6),
          Text(
            label!,
            style: AppType.labelSm.copyWith(color: AppColors.outline),
          ),
        ],
      ],
    );
  }
}

class _ConsistenciaBanner extends StatelessWidget {
  const _ConsistenciaBanner({required this.porcentaje, required this.hayHistorial});

  final double porcentaje;
  final bool hayHistorial;

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    final pct = (porcentaje * 100).round();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF003824), Color(0xFF005C41), Color(0xFF003D27)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium, color: AppColors.secondaryFixed, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hayHistorial
                      ? strings.prConsistenciaTitulo
                      : strings.prEmpiezaRacha,
                  style: AppType.headlineSm.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            hayHistorial
                ? strings.prConsistenciaPct(pct)
                : strings.prActivaRacha,
            style: AppType.bodySm.copyWith(color: Colors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: porcentaje.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white24,
              color: AppColors.secondaryFixed,
            ),
          ),
        ],
      ),
    );
  }
}

class _SesionRow extends StatelessWidget {
  const _SesionRow({required this.icon, required this.titulo, required this.detalle});

  factory _SesionRow.fromSesion(WorkoutSession s, AppStrings strings) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final dia = DateTime(s.fecha.year, s.fecha.month, s.fecha.day);
    final diff = hoy.difference(dia).inDays;
    final cuando = diff == 0
        ? strings.prHoy
        : diff == 1
            ? strings.prAyer
            : diff < 7
                ? strings.prHaceDias(diff)
                : '${s.fecha.day}/${s.fecha.month}';
    return _SesionRow(
      icon: Icons.fitness_center,
      titulo: s.nombre,
      detalle: '$cuando • ${s.duracionMin} min • ${s.calorias} kcal',
    );
  }

  final IconData icon;
  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(radius: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: AppType.labelLg.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detalle,
                  style: AppType.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, size: 20, color: AppColors.primary),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration({double radius = 20}) {
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
