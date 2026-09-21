import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Consejos y Bienestar: recomendaciones personalizadas según la meta del atleta.
///
/// Los tips, artículos y comunidad son catálogo estático inspirado directamente
/// en el HTML de Stitch (e4951ca8).
class TipsScreen extends StatelessWidget {
  const TipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const _TipsHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PlanCard(),
                  const SizedBox(height: 20),
                  const _ArticuloDestacado(),
                  const SizedBox(height: 24),
                  const _TipsDeslizables(),
                  const SizedBox(height: 24),
                  const _ArticulosRecomendados(),
                  const SizedBox(height: 24),
                  const _ComunidadActiva(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipsHeader extends StatelessWidget {
  const _TipsHeader();

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
                  style: AppType.labelMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
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

/// Tarjeta del plan personalizado, con pills de categoría.
class _PlanCard extends StatelessWidget {
  const _PlanCard();

  @override
  Widget build(BuildContext context) {
    final meta = context.watch<AppState>().profile.meta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.secondaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.spa, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Plan Personalizado',
                style: AppType.labelMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Consejos & Bienestar',
          style: AppType.headlineLg.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Recomendaciones basadas en tu meta de $meta',
          style: AppType.bodyMd.copyWith(color: AppColors.onSurfaceVariant, height: 1.5),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 14),
                    Icon(Icons.search, size: 20, color: AppColors.outline),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Buscar consejos...',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: const Icon(Icons.tune, size: 18, color: AppColors.outline),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _CategoryPill(label: 'Todos', selected: true),
              SizedBox(width: 8),
              _CategoryPill(label: 'Nutrición'),
              SizedBox(width: 8),
              _CategoryPill(label: 'Recuperación'),
              SizedBox(width: 8),
              _CategoryPill(label: 'Técnica'),
              SizedBox(width: 8),
              _CategoryPill(label: 'Mentalidad'),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(999),
        border: selected ? null : Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected) ...[
            const Icon(Icons.check, size: 13, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppType.labelMd.copyWith(
              color: selected ? Colors.white : AppColors.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Artículo destacado del día.
class _ArticuloDestacado extends StatelessWidget {
  const _ArticuloDestacado();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'HOY • RECUPERACIÓN',
                  style: AppType.labelSm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: AppColors.outline),
              const SizedBox(width: 4),
              Text(
                '3 min',
                style: AppType.labelMd.copyWith(color: AppColors.outline),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'La importancia de los descansos activos para no perder masa muscular',
            style: AppType.bodyLg.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Caminar ligero o realizar estiramientos dinámicos en tus días libres promueve la eliminación de lactato y acelera la síntesis proteica sin fatiga adicional.',
            style: AppType.bodySm.copyWith(color: AppColors.outline, height: 1.5),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Leer artículo completo',
                style: AppType.labelMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
              const Spacer(),
              const Icon(Icons.bookmark_outline, size: 20, color: AppColors.onSurfaceVariant),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tips de alto impacto con scroll horizontal.
class _TipsDeslizables extends StatelessWidget {
  const _TipsDeslizables();

  static const _tips = [
    _Tip(
      icon: Icons.water_drop,
      titulo: 'Hidratación Óptima',
      subtitulo: 'Pre-entreno',
      descripcion: 'Bebe 500ml de agua 30 min antes de entrenar para mantener la volemia y potencia muscular.',
    ),
    _Tip(
      icon: Icons.restaurant,
      titulo: 'Ventana Anabólica',
      subtitulo: 'Post-HIIT',
      descripcion: 'Consume 25-30g de proteína de rápida asimilación tras tus sesiones HIIT para frenar el catabolismo.',
    ),
    _Tip(
      icon: Icons.bedtime,
      titulo: 'Sueño Profundo',
      subtitulo: 'Regeneración',
      descripcion: 'Garantiza 7-8 horas de reposo; la hormona de crecimiento nocturna maximiza la quema lipídica.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Tips de Alto Impacto', uppercase: true),
        const SizedBox(height: 6),
        Text(
          'Desliza para ver más',
          style: AppType.labelMd.copyWith(color: AppColors.outline),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _tips.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => SizedBox(
              width: 240,
              child: _TipCard(tip: _tips[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _Tip {
  const _Tip({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.descripcion,
  });

  final IconData icon;
  final String titulo;
  final String subtitulo;
  final String descripcion;
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});

  final _Tip tip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                child: Icon(tip.icon, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tip.titulo,
                      style: AppType.labelLg.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      tip.subtitulo,
                      style: AppType.labelSm.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.favorite_border, size: 18, color: AppColors.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              tip.descripcion,
              style: AppType.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Artículos recomendados (lista vertical).
class _ArticulosRecomendados extends StatelessWidget {
  const _ArticulosRecomendados();

  static const _articulos = [
    (Icons.restaurant_menu, 'Nutrición', '4 min', '5 Errores comunes al calcular tu déficit calórico', 'No pesas los aceites o subestimas las salsas.'),
    (Icons.fitness_center, 'Fuerza', '5 min', 'Cómo mejorar tu técnica de sentadilla profunda', 'Alineación del fémur, movilidad de tobillos.'),
    (Icons.spa, 'Bienestar', '3 min', 'Respiración diafragmática para bajar el cortisol', 'Técnica box-breathing de 4 tiempos.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Artículos Recomendados',
              style: AppType.headlineSm.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              'Ver todos (18)',
              style: AppType.labelMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final a in _articulos)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(a.$1, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            a.$2,
                            style: AppType.labelMd.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            ' • ',
                            style: AppType.labelSm.copyWith(color: AppColors.outline),
                          ),
                          Icon(Icons.timer, size: 12, color: AppColors.outline),
                          const SizedBox(width: 2),
                          Text(a.$3, style: AppType.labelSm.copyWith(color: AppColors.outline)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        a.$4,
                        style: AppType.labelLg.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        a.$5,
                        style: AppType.bodySm.copyWith(color: AppColors.outline),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 20, color: AppColors.outline),
              ],
            ),
          ),
      ],
    );
  }
}

/// Sección de comunidad con botón de consulta a coaches.
class _ComunidadActiva extends StatelessWidget {
  const _ComunidadActiva();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.forum, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Comunidad Activa',
                style: AppType.headlineSm.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '¿Dudas con tu rutina?',
            style: AppType.bodyLg.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Nuestros entrenadores certificados y atletas responden en menos de 2 horas.',
            style: AppType.bodySm.copyWith(color: AppColors.outline, height: 1.5),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat de coaches disponible próximamente')),
                  );
                },
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.chat_bubble_outline, size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Hacer una consulta a los Coaches',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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
    );
  }
}