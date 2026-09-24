import 'package:flutter/material.dart';

import '../state/meal_plan.dart';
import '../state/recetas_catalog.dart';
import '../theme.dart';

/// Fase 4: plan semanal de comidas (según el perfil del atleta) y la lista de
/// la compra agregada. Todo se construye con recetas reales del catálogo:
/// ningún dato nutricional es inventado.
class MealPlanScreen extends StatelessWidget {
  const MealPlanScreen({super.key, required this.plan});

  final PlanSemanal plan;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: Text(
            'Plan semanal de comidas',
            style: AppType.headlineSm.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.outline,
            labelStyle: AppType.labelMd,
            tabs: [
              Tab(text: 'Plan semanal'),
              Tab(text: 'Lista de la compra'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PlanView(plan: plan),
            _ListaCompraView(plan: plan),
          ],
        ),
      ),
    );
  }
}

/// Resumen honesto: meta vs. promedio real del plan base.
class _ResumenPlan extends StatelessWidget {
  const _ResumenPlan({required this.plan});

  final PlanSemanal plan;

  @override
  Widget build(BuildContext context) {
    final cobertura = plan.coberturaMetaPorcentaje.clamp(0, 100).toStringAsFixed(0);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_menu, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Tu meta: ${plan.perfil.caloriasMeta.round()} kcal/día',
                style: AppType.labelMd.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '~$cobertura%',
                style: AppType.labelMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'El plan base aporta ${plan.kcalPromedioDia.round()} kcal/día de '
            'promedio calculadas de las recetas reales. Ajusta el tamaño de las '
            'raciones para alcanzar tu meta.',
            style: AppType.bodySm.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: 10),
          Text(
            'Domingo = día libre planificado 🍕 · no penaliza tu racha de sesiones.',
            style: AppType.bodySm.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanView extends StatelessWidget {
  const _PlanView({required this.plan});

  final PlanSemanal plan;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _ResumenPlan(plan: plan),
        const SizedBox(height: 8),
        for (final dia in plan.dias) _DiaCard(dia: dia),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            'Todas las comidas son recetas reales del catálogo nutricional. '
            'Los totales son la suma exacta de sus valores; nada está inventado.',
            style: AppType.bodySm.copyWith(color: AppColors.outline),
          ),
        ),
      ],
    );
  }
}

class _DiaCard extends StatelessWidget {
  const _DiaCard({required this.dia});

  final DiaPlan dia;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                dia.dia,
                style: AppType.labelMd.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              if (dia.diaLibre)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Día libre 🍕',
                    style: AppType.labelSm.copyWith(
                      color: AppColors.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                '${dia.totalKcal.round()} kcal',
                style: AppType.labelMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ComidaFila(icon: Icons.wb_sunny_outlined, etiqueta: 'Desayuno', receta: dia.desayuno),
          _ComidaFila(icon: Icons.lunch_dining_outlined, etiqueta: 'Almuerzo', receta: dia.almuerzo),
          _ComidaFila(icon: Icons.dinner_dining_outlined, etiqueta: 'Cena', receta: dia.cena),
          _ComidaFila(
            icon: Icons.bolt_outlined,
            etiqueta: dia.extra.tipo == 'Pre-entreno' ? 'Pre-entreno' : 'Recarga',
            receta: dia.extra,
          ),
        ],
      ),
    );
  }
}

class _ComidaFila extends StatelessWidget {
  const _ComidaFila({
    required this.icon,
    required this.etiqueta,
    required this.receta,
  });

  final IconData icon;
  final String etiqueta;
  final Recipe receta;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.outline),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$etiqueta: ${receta.nombre}',
              style: AppType.bodySm.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${receta.calorias.round()} kcal',
            style: AppType.bodySm.copyWith(
              color: AppColors.outline,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListaCompraView extends StatelessWidget {
  const _ListaCompraView({required this.plan});

  final PlanSemanal plan;

  @override
  Widget build(BuildContext context) {
    final lista = plan.listaCompra;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Row(
            children: [
              const Icon(Icons.shopping_cart_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${lista.length} ingredientes para toda la semana '
                  '(cantidades por ración en cada receta).',
                  style: AppType.bodySm.copyWith(color: AppColors.outline),
                ),
              ),
            ],
          ),
        ),
        for (final grupo in lista)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 16, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _capitalizar(grupo.nombre),
                    style: AppType.bodyMd.copyWith(color: AppColors.onSurface),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '×${grupo.usos}',
                    style: AppType.labelSm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _capitalizar(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}