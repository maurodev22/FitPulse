import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

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
    final pasosDisponible = state.healthDisponible;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Resumen de hoy', actionLabel: 'Ver detalles'),
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
                  label: 'Calorías',
                  value: state.caloriasConsumidas.round().toString(),
                  unit: 'kcal',
                  icon: Icons.local_fire_department,
                  iconColor: AppColors.primary,
                  iconBackground: AppColors.surfaceContainer,
                ),
                subtitle: 'Meta: ${state.caloriasMeta.round()} kcal',
                progress: state.progresoCalorias,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                stat: const MetricStat(
                  label: 'Pulso',
                  value: '—',
                  unit: 'bpm',
                  icon: Icons.favorite,
                  iconColor: AppColors.outline,
                  iconBackground: AppColors.surfaceContainerHighest,
                ),
                subtitle: 'Requiere reloj inteligente',
                subtitleColor: AppColors.outline,
                radius: 24,
                progress: null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Solo orientativo · consulta a un médico antes de cambiar tu rutina',
          style: AppType.labelSm.copyWith(color: AppColors.outline),
        ),
      ],
    );
  }

  Widget _buildEntrenamientoHoy() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text('Entrenamiento de hoy', style: AppType.headlineSm.copyWith(fontWeight: FontWeight.w700)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Sugerido',
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
        const _WorkoutHeroCard(),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    // Saludo personalizado con el nombre del atleta de la sesión.
    final nombre = context.watch<AppState>().profile.nombre.split(' ').first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(color: AppColors.surface),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.secondaryFixed, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/avatar.webp',
                  fit: BoxFit.cover,
                ),
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
                  'Hola, $nombre',
                  style: AppType.headlineSm.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '¿Listo para superar tus límites hoy?',
                  style: AppType.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
                        const Icon(Icons.directions_walk, size: 18, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Pasos',
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
                    if (available)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.trending_up, size: 12, color: AppColors.onSecondaryContainer),
                                const SizedBox(width: 2),
                                Text(
                                  '+12%',
                                  style: AppType.labelSm.copyWith(
                                    color: AppColors.onSecondaryContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text('vs ayer', style: AppType.bodySm.copyWith(color: AppColors.outline)),
                        ],
                      )
                    else
                      Text(
                        'Activa el permiso de actividad en los ajustes del teléfono',
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
  const _WorkoutHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF003824), AppColors.primary, Color(0xFF003D27)],
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
                border: Border.all(color: AppColors.secondaryFixed.withValues(alpha: 0.15), width: 8),
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
                color: AppColors.secondaryFixed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RECOMENDADO PARA TI • 45 MIN • INTENSIDAD MEDIA',
                style: AppType.labelSm.copyWith(
                  color: AppColors.secondaryFixed,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'HIIT & Quema Total',
                style: AppType.headlineLg.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Aumenta tu resistencia aeróbica y tonifica con intervalos explosivos.',
                style: AppType.bodySm.copyWith(color: Colors.white.withValues(alpha: 0.85)),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _HeroInfoChip(icon: Icons.schedule, label: '45 min'),
                  _HeroInfoChip(icon: Icons.local_fire_department, label: '380 kcal'),
                  _HeroInfoChip(icon: Icons.fitness_center, label: '12 ejercicios'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: AppColors.secondaryFixed,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded, size: 22, color: AppColors.onSecondaryFixed),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Comenzar entrenamiento',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.labelLg.copyWith(
                                color: AppColors.onSecondaryFixed,
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
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.secondaryFixed),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppType.labelMd.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _DiaIdealCard extends StatelessWidget {
  const _DiaIdealCard();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final entrenado = state.caloriasConsumidas > 0;
    final metaOk = state.progresoCalorias >= 1.0;
    final aguaOk = false;
    final completados = [entrenado, metaOk, aguaOk].where((v) => v).length;

    return Container(
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
                  'DÍA IDEAL',
                  style: AppType.labelLg.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$completados/3 completados',
                  style: AppType.labelSm.copyWith(
                    color: AppColors.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Completa los 3 objetivos de hoy para un día perfecto.',
            style: AppType.bodySm.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: 12),
          _DiaIdealItem(
            icon: Icons.fitness_center,
            title: 'Entrenamiento',
            subtitle: 'HIIT & Quema Total • 45 min',
            done: entrenado,
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _DiaIdealItem(
            icon: Icons.set_meal_outlined,
            title: 'Macros',
            subtitle: '${state.caloriasConsumidas.round()} / ${state.caloriasMeta.round()} kcal',
            done: metaOk,
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _DiaIdealItem(
            icon: Icons.water_drop_outlined,
            title: 'Agua',
            subtitle: '2.0 / 2.5 L',
            done: aguaOk,
            onTap: () {},
          ),
        ],
      ),
    );
  }
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
                  color: done ? Colors.white : fg,
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
                done ? '✓' : 'Pendiente',
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