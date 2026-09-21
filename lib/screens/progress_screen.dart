import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Progreso y Rendimiento: evolución de peso, IMC, sesiones e insignias.
///
/// Los valores provienen de la sesión persistida del atleta (peso, IMC,
/// meta). El resto son datos de ejemplo para la representación visual.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  static const _diasSemana = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AppState>().profile;
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
                  Text(
                    'Evolución & Rendimiento',
                    style: AppType.headlineLg.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Estás en tu mejor racha de consistencia',
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
                          value: '21.4%',
                          trend: '-0.6%',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SmallStat(
                          icon: Icons.insights,
                          label: 'Índice IMC',
                          value: profile.imcFormateado,
                          trend: 'Óptimo',
                          trendColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      Expanded(
                        child: _SmallStat(
                          icon: Icons.local_fire_department,
                          label: 'Gasto Activo',
                          value: '4,850 kcal',
                          trend: 'Semanal',
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _SmallStat(
                          icon: Icons.schedule,
                          label: 'Tiempo Activo',
                          value: '4h 20m',
                          trend: 'Semanal',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSemanaCard(),
                  const SizedBox(height: 12),
                  const _ConsistenciaBanner(),
                  const SizedBox(height: 20),
                  const SectionHeader(title: 'Sesiones Recientes', actionLabel: 'Ver todo'),
                  const SizedBox(height: 12),
                  const _SesionRow(
                    icon: Icons.fitness_center,
                    titulo: 'HIIT & Quema Total',
                    detalle: 'Ayer • 45 min • 380 kcal',
                  ),
                  const _SesionRow(
                    icon: Icons.sports_gymnastics,
                    titulo: 'Fuerza Superior & Core',
                    detalle: 'Hace 2 días • 50 min • 320 kcal',
                  ),
                  const _SesionRow(
                    icon: Icons.directions_run,
                    titulo: 'Running 5K Matutino',
                    detalle: 'Hace 4 días • 28 min • 290 kcal',
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader(title: 'Insignias & Logros', actionLabel: '12 Total'),
                  const SizedBox(height: 12),
                  const _InsigniasRow(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
              Text(
                'Peso Corporal',
                style: AppType.labelMd.copyWith(
                  color: AppColors.outline,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              const Icon(Icons.trending_down, size: 16, color: AppColors.error),
              const SizedBox(width: 4),
              Text(
                '-1.8 kg',
                style: AppType.labelMd.copyWith(
                  color: AppColors.error,
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
          _MiniWeightChart(),
        ],
      ),
    );
  }

  Widget _buildSemanaCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Meta superada (650 kcal)',
                style: AppType.labelMd.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '5/7 días',
                style: AppType.labelMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final dia in _diasSemana)
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        dia == 'D' ? Icons.check : Icons.bolt,
                        size: 14,
                        color: dia == 'D'
                            ? AppColors.onSurfaceVariant
                            : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dia,
                      style: AppType.labelSm.copyWith(color: AppColors.outline),
                    ),
                  ],
                ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.bolt, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                '+14% vs. semana previa',
                style: AppType.labelMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(color: AppColors.surface),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.secondaryFixed, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset('assets/images/avatar.jpg', fit: BoxFit.cover),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
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
                  'Hola, Atleta',
                  style: AppType.headlineSm.copyWith(fontWeight: FontWeight.w700, height: 1.1),
                ),
                const SizedBox(height: 2),
                Text(
                  'Listo para entrenar',
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
                  '14 días',
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
    required this.trend,
    this.trendColor = AppColors.error,
  });

  final IconData icon;
  final String label;
  final String value;
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
          Text(
            value,
            style: AppType.headlineSm.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w800,
            ),
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
  static const _valores = [3.0, 4.2, 3.6, 5.0, 4.0, 4.8, 3.2];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
    );
  }
}

class _ConsistenciaBanner extends StatelessWidget {
  const _ConsistenciaBanner();

  @override
  Widget build(BuildContext context) {
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
              Text(
                '¡Consistencia Imparable!',
                style: AppType.headlineSm.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Completaste el 92% de tu volumen de entrenamiento programado.',
            style: AppType.bodySm.copyWith(color: Colors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const LinearProgressIndicator(
              value: 0.92,
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

class _InsigniasRow extends StatelessWidget {
  const _InsigniasRow();

  @override
  Widget build(BuildContext context) {
    const insignias = [
      (Icons.local_fire_department, 'Racha 14 Días', 'Constancia'),
      (Icons.directions_run, 'Primera 5K', 'Resistencia'),
      (Icons.verified, 'Meta Calórica', 'Superada'),
    ];
    return Row(
      children: [
        for (var index = 0; index < insignias.length; index++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index < insignias.length - 1 ? 10 : 0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: _cardDecoration(radius: 16),
                child: Column(
                  children: [
                    Icon(insignias[index].$1, size: 22, color: AppColors.primary),
                    const SizedBox(height: 6),
                    Text(
                      insignias[index].$2,
                      style: AppType.labelMd.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      insignias[index].$3,
                      style: AppType.labelSm.copyWith(color: AppColors.outline),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
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