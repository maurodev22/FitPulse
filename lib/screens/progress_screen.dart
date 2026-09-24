import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  static const _diasSemana = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
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
                        'Evolución & Rendimiento',
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
                        ? 'Racha actual: ${state.rachaDias} días · Nivel ${state.nivel}'
                        : 'Registra tu primer entrenamiento para ver datos reales',
                    style: AppType.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  const _PeriodTabs(),
                  const SizedBox(height: 16),
                  _buildPesoCard(profile.pesoKg),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SmallStat(
                          icon: Icons.opacity,
                          label: 'Grasa Corporal',
                          value: state.grasaHoy?.toStringAsFixed(1) ?? '—',
                          unit: state.grasaHoy != null ? '%' : '',
                          trend: _textoTrend(
                            context,
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
                          label: 'Índice IMC',
                          value: profile.imcFormateado,
                          unit: '',
                          trend: 'De tu perfil',
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
                          label: 'Gasto Activo',
                          value: state.gastoActivoHoy?.round().toString() ?? '—',
                          unit: state.gastoActivoHoy != null ? 'kcal' : '',
                          trend: _textoTrend(
                            context,
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
                          label: 'Tiempo Activo',
                          value: state.tiempoActivoMin?.toString() ?? '—',
                          unit: state.tiempoActivoMin != null ? 'min' : '',
                          trend: _textoActivo(
                            context,
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
                    _textoFuenteMetrricas(context),
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'Inter',
                      color: AppColors.outline,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRetoCard(state),
                  const SizedBox(height: 12),
                  _buildNivelCard(state),
                  const SizedBox(height: 12),
                  _buildRecompensaAnuncio(context),
                  const SizedBox(height: 12),
                  _buildSemanaCard(state, profile.diasEntrenamiento.length),
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
                  const SectionHeader(title: 'Sesiones Recientes', actionLabel: 'Ver todo'),
                  const SizedBox(height: 12),
                  _buildSesiones(state),
                  const SizedBox(height: 20),
                  const SectionHeader(title: 'Insignias & Logros'),
                  const SizedBox(height: 12),
                  _buildInsignias(state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _textoTrend(
    BuildContext context, {
    required bool conPermiso,
    required Object? valor,
  }) {
    if (valor != null) return 'Health Connect';
    if (conPermiso) return 'Sin datos de hoy';
    if (context.read<AppState>().healthConnectDisponible) {
      return 'Concede el permiso';
    }
    return 'Requiere Health Connect';
  }

  /// Nota honesta del "Tiempo Activo": el paquete `health` 13.3.2 solo expone
  /// EXERCISE_TIME en iOS, así que en Android nunca hay dato → siempre "—".
  String _textoActivo(BuildContext context, {required Object? valor}) {
    if (valor != null) return 'Health Connect';
    return 'Solo iOS · en Android no hay dato';
  }

  String _textoFuenteMetrricas(BuildContext context) {
    final state = context.read<AppState>();
    if (!state.healthConnectDisponible) {
      return 'Grasa y gasto activo vienen de Health Connect. Instala la app de '
          'Google para desbloquearlos (nunca mostramos datos inventados).';
    }
    final concedidas = [
      if (state.grasaConPermiso) 'grasa',
      if (state.gastoActivoConPermiso) 'gasto activo',
    ];
    if (concedidas.isEmpty) {
      return 'Concede los permisos en Health Connect para ver grasa y gasto '
          'activo reales.';
    }
    return 'Métricas de hoy vía Health Connect: ${concedidas.join(', ')}.';
  }

  /// Tarjeta principal de evolución de peso corporal con mini gráfico.
  Widget _buildPesoCard(double peso) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monitor_weight, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Peso Corporal',
                  style: AppType.labelMd.copyWith(
                    color: AppColors.outline,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Text(
                'De tu perfil',
                style: AppType.labelMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
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
          _MiniWeightChart(label: 'Registra tu peso cada semana'),
        ],
      ),
    );
  }

  Widget _buildRetoCard(AppState state) {
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
              const Icon(Icons.emoji_events, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reto actual',
                  style: AppType.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                completado ? '¡Completado!' : '$progreso/$objetivo días',
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
                ? 'Conseguiste $objetivo días seguidos. Sigue para el reto de '
                    '$siguiente días (+100 pts).'
                : 'Entrena $objetivo días seguidos y gana +100 pts extra.',
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

  Widget _buildNivelCard(AppState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nivel ${state.nivel} · ${state.nombreNivel}',
                  style: AppType.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${state.xp} pts',
                style: AppType.labelMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '+50 pts por sesión completada · ${300 - (state.xp % 300)} pts para nivel ${state.nivel + 1}',
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
    final config = context.watch<ConfigService>();
    if (config.premiumEnabled) return const SizedBox.shrink();

    final state = context.watch<AppState>();
    final disponible = state.recompensaAnuncioDisponibleHoy;

    Future<void> verAnuncio() async {
      final messenger = ScaffoldMessenger.of(context);
      final appState = context.read<AppState>();
      await mostrarAnuncioRecompensado(
        onRecompensa: () async {
          final aplicada = await appState.aplicarRecompensaAnuncio();
          messenger.showSnackBar(SnackBar(
            content: Text(aplicada
                ? '¡+${AppState.ptsRecompensaAnuncio} PTs ganados!'
                : 'Recompensa de hoy ya recibida.'),
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
              const Icon(Icons.play_circle_outline, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Anuncio recompensado',
                  style: AppType.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '+${AppState.ptsRecompensaAnuncio} PTs',
                style: AppType.labelMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            disponible
                ? 'Gana puntos extra viendo un anuncio (una vez por día).'
                : 'Recompensa de hoy recibida. Vuelve mañana por más. 👏',
            style: AppType.bodySm.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: disponible ? verAnuncio : null,
              child: Text(disponible ? 'Ver anuncio y ganar +25' : 'Recibido hoy'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemanaCard(AppState state, int diasMeta) {
    final entrenados = state.diasSemanaEntrenados;
    final total = diasMeta > 0 ? diasMeta : 5;
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
                  'Semana de entrenamiento',
                  style: AppType.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${state.diasEntrenadosSemana}/$total días',
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
              for (var i = 0; i < _diasSemana.length; i++)
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
                        _diasSemana[i],
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
              const Icon(Icons.history, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  state.minutosEntrenadosSemana > 0
                      ? '${state.minutosEntrenadosSemana} min entrenados esta semana'
                      : 'Sin sesiones registradas esta semana',
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

  Widget _buildSesiones(AppState state) {
    final recientes = state.historial.take(3).toList();
    if (recientes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(radius: 16),
        child: Column(
          children: [
            const Icon(Icons.fitness_center, size: 28, color: AppColors.outline),
            const SizedBox(height: 8),
            Text(
              'Aún no hay sesiones registradas',
              style: AppType.labelMd.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Completa tu primer entrenamiento desde Inicio para registrarlo aquí.',
              textAlign: TextAlign.center,
              style: AppType.bodySm.copyWith(color: AppColors.outline),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (final s in recientes) _SesionRow.fromSesion(s),
      ],
    );
  }

  Widget _buildInsignias(AppState state) {
    final insignias = <({IconData icono, String nombre, String detalle})>[
      if (state.historial.isNotEmpty)
        (icono: Icons.fitness_center, nombre: 'Primera Sesión', detalle: 'Completada'),
      if (state.rachaMaxima >= 3)
        (icono: Icons.local_fire_department, nombre: 'Racha 3 Días', detalle: 'Constancia'),
      if (state.rachaMaxima >= 7)
        (icono: Icons.whatshot, nombre: 'Racha 7 Días', detalle: 'Disciplina'),
      if (state.nivel >= 2)
        (icono: Icons.workspace_premium, nombre: 'Nivel ${state.nivel}', detalle: state.nombreNivel),
      if (state.retoCompletado)
        (icono: Icons.emoji_events, nombre: 'Reto ${state.retoObjetivo} Días', detalle: '¡Completado!'),
    ];
    if (insignias.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(radius: 16),
        child: Column(
          children: [
            const Icon(Icons.emoji_events_outlined, size: 28, color: AppColors.outline),
            const SizedBox(height: 8),
            Text(
              'Completa tu primer entrenamiento para desbloquear insignias',
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(color: AppColors.surface),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progreso',
                  style: AppType.headlineSm.copyWith(fontWeight: FontWeight.w700, height: 1.1),
                ),
                const SizedBox(height: 2),
                Text(
                  state.entrenadoHoy ? '¡Día completado!' : 'Listo para entrenar',
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
                  '${state.rachaDias} días',
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
            icon: const Icon(Icons.notifications_outlined, size: 22, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs();

  static const _periodos = ['Semanal', 'Mensual', 'Año'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final p in _periodos)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p == 'Semanal' ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  p,
                  style: AppType.labelMd.copyWith(
                    color: p == 'Semanal' ? Colors.white : AppColors.onSurfaceVariant,
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
    this.trendColor = AppColors.error,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final String trend;
  final Color trendColor;

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
              color: trendColor,
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
    final pct = (porcentaje * 100).round();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF003824), AppColors.primary, Color(0xFF003D27)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium, color: AppColors.secondaryFixed, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hayHistorial ? '¡Consistencia Imparable!' : 'Empieza tu racha',
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
                ? 'Completaste el $pct% de tu entrenamiento programado esta semana.'
                : 'Completa tu primer entrenamiento esta semana para activar tu racha.',
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

  factory _SesionRow.fromSesion(WorkoutSession s) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final dia = DateTime(s.fecha.year, s.fecha.month, s.fecha.day);
    final diff = hoy.difference(dia).inDays;
    final cuando = diff == 0
        ? 'Hoy'
        : diff == 1
            ? 'Ayer'
            : diff < 7
                ? 'Hace $diff días'
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
          const Icon(Icons.check_circle, size: 20, color: AppColors.primary),
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