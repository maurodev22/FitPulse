import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/locale_service.dart';
import '../state/app_state.dart';
import '../state/meal_plan.dart';
import '../state/recetas_catalog.dart';
import 'meal_plan_screen.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Recetas Nutricionales: búsqueda, filtros por categoría, balance del día
/// y registro de consumo que actualiza el estado global persistido.
class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  String _category = 'Todas';
  final _searchController = TextEditingController();

  static const _categories = [
    'Todas',
    'Alta Proteína',
    'Low Carb',
    'Pre-entreno',
    'Smoothies',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const _RecipesHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SearchBar(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryPills(strings),
                  const SizedBox(height: 20),
                  const _MacroSummaryCard(),
                  const SizedBox(height: 16),
                  const _PlanSemanalCard(),
                  const SizedBox(height: 24),
                  const _FeaturedRecipeSection(),
                  const SizedBox(height: 24),
                  _QuickOptionsSection(
                    onVerTodas: () => _openCatalog(
                      categoria: 'Todas',
                      recetas: catalog,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPills(AppStrings strings) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final label = _categories[i];
          final selected = label == _category;
          final color = selected ? AppColors.primary : AppColors.surfaceLowest;
          final textColor = selected ? Colors.white : AppColors.onSurfaceVariant;
          return Material(
            color: color,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: () => setState(() => _category = label),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: selected ? null : Border.all(color: AppColors.outlineVariant),
                ),
                child: Text(
                  strings.recetaCategoria(label),
                  style: AppType.labelMd.copyWith(
                    color: textColor,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Abre el catálogo completo filtrado según la categoría activa y la búsqueda.
  void _openCatalog({required String categoria, required List<Recipe> recetas}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecetasCatalogScreen(
          categoriaInicial: categoria,
          recetasIniciales: recetas,
        ),
      ),
    );
  }
}

class _PlanSemanalCard extends StatelessWidget {
  const _PlanSemanalCard();

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    final perfil = context.watch<AppState>().profile;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MealPlanScreen(plan: generarPlanSemanal(perfil)),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.recPlanSemanal,
                      style: AppType.labelMd.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.recPlanSemanalDesc(perfil.caloriasMeta.round()),
                      style: AppType.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipesHeader extends StatelessWidget {
  const _RecipesHeader();

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.restaurant_menu, size: 22, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              strings.recHeader,
              style: AppType.headlineSm.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(Icons.search, size: 20, color: AppColors.outline),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppType.bodyMd.copyWith(color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: strings.recBuscar,
                hintStyle: AppType.bodySm.copyWith(color: Colors.grey),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: Icon(Icons.tune, size: 20, color: AppColors.outline),
          ),
        ],
      ),
    );
  }
}

class _MacroSummaryCard extends StatelessWidget {
  const _MacroSummaryCard();

  @override
  Widget build(BuildContext context) {
    // Balance del día proveniente del estado persistido.
    final strings = context.watch<LocaleService>().strings;
    final state = context.watch<AppState>();
    final kcal = state.caloriasConsumidas.round();
    final meta = state.caloriasMeta.round();
    final pct = (state.progresoCalorias * 100).round();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF006C49), Color(0xFF004E35)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.recBalanceHoy,
                    style: AppType.labelSm.copyWith(
                      color: AppColors.secondaryFixed,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$kcal / $meta kcal',
                    style: AppType.headlineSm.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  strings.recPorciento(pct),
                  style: AppType.labelSm.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MacroCell(
                  label: strings.recProteinas,
                  value: '${state.proteinasConsumidas.round()}g',
                  goal: '140g',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroCell(
                  label: strings.recCarbos,
                  value: '${state.carbosConsumidos.round()}g',
                  goal: '190g',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroCell(
                  label: strings.recGrasas,
                  value: '${state.grasasConsumidas.round()}g',
                  goal: '55g',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroCell extends StatelessWidget {
  const _MacroCell({required this.label, required this.value, required this.goal});

  final String label;
  final String value;
  final String goal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppType.bodySm.copyWith(
              color: const Color(0xFFE0E7E2),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: AppType.labelLg.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: ' / $goal',
                  style: AppType.labelSm.copyWith(
                    color: AppColors.secondaryFixed,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedRecipeSection extends StatelessWidget {
  const _FeaturedRecipeSection();

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    final recipe = featuredRecipe;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: strings.recRecomendadaDefinir,
          actionLabel: strings.recVerPlan,
          uppercase: true,
        ),
        const SizedBox(height: 12),
        _RecipeCard(recipe: recipe),
      ],
    );
  }
}

/// Tarjeta completa de receta (imagen, macros, favorito y registro de consumo).
class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    final state = context.watch<AppState>();
    final esFavorita = state.favoritas.contains(recipe.nombre);
    return Container(
      decoration: _recipeCardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 170,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(recipe.imagen, fit: BoxFit.cover),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      recipe.etiquetaCategoria,
                      style: AppType.labelSm.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => state.toggleFavorita(recipe.nombre),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        esFavorita ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: esFavorita ? AppColors.error : AppColors.onSurface,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer, size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          strings.recMin(recipe.minutos),
                          style: AppType.labelMd.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        recipe.nombre,
                        style: AppType.bodyLg.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF7F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        strings.recKcal(recipe.calorias.round()),
                        style: AppType.labelSm.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  recipe.descripcion,
                  style: AppType.bodySm.copyWith(color: AppColors.outline, height: 1.5),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _MacroTag(text: strings.recProtTag(recipe.proteinas)),
                    Text('  •  ', style: TextStyle(color: AppColors.outline, fontSize: 11)),
                    _MacroTag(text: strings.recGrasasTag(recipe.grasas)),
                    Text('  •  ', style: TextStyle(color: AppColors.outline, fontSize: 11)),
                    _MacroTag(text: strings.recCarbTag(recipe.carbos)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: () => _registrar(context),
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_circle_outline, size: 18, color: Colors.white),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                strings.recRegistrarBalance,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
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
          ),
        ],
      ),
    );
  }

  /// Suma los macros de la receta al balance diario persistido.
  void _registrar(BuildContext context) {
    final strings = context.read<LocaleService>().strings;
    context.read<AppState>().registrarConsumo(
          calorias: recipe.calorias,
          proteinas: recipe.proteinas,
          carbos: recipe.carbos,
          grasas: recipe.grasas,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.recRegistrada(recipe.nombre, recipe.calorias.round()))),
    );
  }
}

class _MacroTag extends StatelessWidget {
  const _MacroTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppType.labelSm.copyWith(
        color: AppColors.onSurface,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _QuickOptionsSection extends StatelessWidget {
  const _QuickOptionsSection({required this.onVerTodas});

  final VoidCallback onVerTodas;

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: strings.recOpcionesRapidas,
          actionLabel: strings.recVerTodas,
          onAction: onVerTodas,
          uppercase: true,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _QuickRecipeCard(recipe: catalog[1]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickRecipeCard(recipe: catalog[2]),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickRecipeCard extends StatelessWidget {
  const _QuickRecipeCard({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _recipeCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  recipe.imagen,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 96,
                ),
              ),
              Positioned(
                left: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    strings.recMin(recipe.minutos),
                    style: AppType.labelSm.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recipe.nombre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.labelMd.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            strings.recKcalProt(recipe.calorias.round(), recipe.proteinas),
            style: AppType.labelSm.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 30,
            child: Material(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () {
                  context.read<AppState>().registrarConsumo(
                        calorias: recipe.calorias,
                        proteinas: recipe.proteinas,
                        carbos: recipe.carbos,
                        grasas: recipe.grasas,
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        strings.recRegistrada(recipe.nombre, recipe.calorias.round()),
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 15, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          strings.recRegistrar,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.labelSm.copyWith(
                            color: AppColors.primary,
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
    );
  }
}

/// Catálogo completo de recetas con búsqueda, filtros y favoritos.
class RecetasCatalogScreen extends StatefulWidget {
  const RecetasCatalogScreen({
    super.key,
    required this.categoriaInicial,
    required this.recetasIniciales,
  });

  final String categoriaInicial;
  final List<Recipe> recetasIniciales;

  @override
  State<RecetasCatalogScreen> createState() => _RecetasCatalogScreenState();
}

class _RecetasCatalogScreenState extends State<RecetasCatalogScreen> {
  late String _categoria;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _categoria = widget.categoriaInicial;
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    final recetas = filtrarRecetas(widget.recetasIniciales, _query, _categoria);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(strings.recTodosLosPlatos, style: AppType.headlineSm.copyWith(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: strings.recBuscarCatalogo,
                  prefixIcon: Icon(Icons.search, color: AppColors.outline),
                  filled: true,
                  fillColor: const Color(0xFFF0F4F1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  for (final c in const ['Todas', 'Alta Proteína', 'Low Carb', 'Pre-entreno', 'Smoothies'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _Chip(
                        label: strings.recetaCategoria(c),
                        selected: c == _categoria,
                        onTap: () => setState(() => _categoria = c),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: recetas.isEmpty
                  ? Center(
                      child: Text(
                        strings.recSinResultados,
                        style: TextStyle(color: AppColors.outline),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: recetas.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, i) => _RecipeCard(recipe: recetas[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: false,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surfaceLowest,
            borderRadius: BorderRadius.circular(999),
            border: selected ? null : Border.all(color: AppColors.outlineVariant),
          ),
          child: Text(
            label,
            style: AppType.labelMd.copyWith(
              color: selected ? Colors.white : AppColors.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

BoxDecoration _recipeCardDecoration() {
  return BoxDecoration(
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
  );
}
