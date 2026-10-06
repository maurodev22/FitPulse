import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/locale_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/racha_chip.dart';

/// Un artículo real del catálogo de Consejos, con su texto traducido en vivo.
class TipArticulo {
  const TipArticulo({
    required this.titulo,
    required this.cuerpo,
    required this.categoria,
    required this.min,
  });

  final String titulo;
  final String cuerpo;
  final String categoria;
  final int min;
}

/// Catálogo REAL de artículos (4): cada título y cuerpo vive en AppStrings.
/// Nada se inventa: categoría y duración salen del propio contenido.
List<TipArticulo> catalogoArticulos(AppStrings strings) => [
      TipArticulo(
        titulo: strings.tipsArticulo1Titulo,
        cuerpo: strings.tipsArticulo1Cuerpo,
        categoria: 'Recuperación',
        min: 3,
      ),
      TipArticulo(
        titulo: strings.tipsArt1Titulo,
        cuerpo: strings.tipsArt1Cuerpo,
        categoria: 'Nutrición',
        min: 4,
      ),
      TipArticulo(
        titulo: strings.tipsArt2Titulo,
        cuerpo: strings.tipsArt2Cuerpo,
        categoria: 'Fuerza',
        min: 5,
      ),
      TipArticulo(
        titulo: strings.tipsArt3Titulo,
        cuerpo: strings.tipsArt3Cuerpo,
        categoria: 'Bienestar',
        min: 3,
      ),
    ];

/// Categorías reales del catálogo (+ "Todos"), traducidas por `tipsCategoria`.
const List<String> categoriasTips = [
  'Todos',
  'Nutrición',
  'Recuperación',
  'Fuerza',
  'Bienestar',
];

/// Consejos y Bienestar: recomendaciones personalizadas según la meta del atleta.
///
/// P4: la búsqueda filtra el catálogo real por título/cuerpo y las pills por
/// categoría. Cada artículo abre su detalle y "Ver todos (N)" usa el número
/// real de artículos (4), no uno inventado.
class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  final TextEditingController _buscarCtrl = TextEditingController();
  String _categoria = 'Todos';

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  List<TipArticulo> _filtrar(List<TipArticulo> catalogo) {
    final q = _buscarCtrl.text.trim().toLowerCase();
    return catalogo.where((a) {
      final okCat = _categoria == 'Todos' || a.categoria == _categoria;
      final okQ = q.isEmpty ||
          a.titulo.toLowerCase().contains(q) ||
          a.cuerpo.toLowerCase().contains(q);
      return okCat && okQ;
    }).toList();
  }

  void _abrirDetalle(TipArticulo articulo) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ArticuloDetalleScreen(articulo: articulo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    final catalogo = catalogoArticulos(strings);
    final filtrados = _filtrar(catalogo);
    final destacado = catalogo.first;
    final hayFiltro =
        _categoria != 'Todos' || _buscarCtrl.text.trim().isNotEmpty;
    final recomendados = hayFiltro ? filtrados : catalogo.skip(1).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _TipsHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PlanCard(
                    control: _buscarCtrl,
                    categoria: _categoria,
                    onCategoria: (c) => setState(() => _categoria = c),
                    onQueryChanged: () => setState(() {}),
                  ),
                  if (!hayFiltro) ...[
                    const SizedBox(height: 20),
                    _ArticuloDestacado(
                      articulo: destacado,
                      onLeer: () => _abrirDetalle(destacado),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const _TipsDeslizables(),
                  const SizedBox(height: 24),
                  _ArticulosRecomendados(
                    articulos: recomendados,
                    total: filtrados.length,
                    onVerTodos: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TodosArticulosScreen(catalogo: catalogo),
                        ),
                      );
                    },
                    onArticulo: _abrirDetalle,
                  ),
                  const SizedBox(height: 24),
                  const _AvisoSalud(),
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
                  strings.navTips,
                  style: AppType.headlineSm.copyWith(fontWeight: FontWeight.w700, height: 1.1),
                ),
                const SizedBox(height: 2),
                Text(
                  strings.listoParaEntrenar,
                  style: AppType.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          RachaChip(racha: context.watch<AppState>().rachaDias, borde: true),
        ],
      ),
    );
  }
}

/// Tarjeta del plan personalizado, con buscador real y pills de categoría.
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.control,
    required this.categoria,
    required this.onCategoria,
    required this.onQueryChanged,
  });

  final TextEditingController control;
  final String categoria;
  final ValueChanged<String> onCategoria;
  final VoidCallback onQueryChanged;

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    final metas = context.watch<AppState>().profile.metas;
    final metasVisibles = metas.map(strings.metaName).join(' · ');
    final metasLabel =
        metas.isEmpty ? '' : strings.tipsTuMetaDe(metasVisibles);
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
              Icon(Icons.spa, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  strings.tipsPlanPersonalizado,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.labelMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          strings.tipsConsejosBienestar,
          style: AppType.headlineLg.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          strings.tipsRecomendaciones(
            metas.isEmpty ? '' : '${strings.tipsBasadasEn} $metasLabel',
          ),
          style: AppType.bodyMd.copyWith(color: AppColors.onSurfaceVariant, height: 1.5),
        ),
        const SizedBox(height: 16),
        // P4: buscador real que filtra el catálogo por título/cuerpo.
        TextField(
          controller: control,
          onChanged: (_) => onQueryChanged(),
          textInputAction: TextInputAction.search,
          style: TextStyle(fontSize: 14, color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: strings.tipsBuscar,
            hintStyle: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
            prefixIcon: Icon(Icons.search, size: 20, color: AppColors.outline),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: control,
              builder: (_, v, _) => v.text.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      icon: Icon(Icons.close, size: 18, color: AppColors.outline),
                      onPressed: () {
                        control.clear();
                        onQueryChanged();
                      },
                    ),
            ),
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final cat in categoriasTips) ...[
                _CategoryPill(
                  label: strings.tipsCategoria(cat),
                  selected: categoria == cat,
                  onTap: () => onCategoria(cat),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
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
              Icon(Icons.check, size: 13, color: AppColors.onPrimary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppType.labelMd.copyWith(
                // F8: en el tema oscuro `primary` es verde claro, así que el
                // texto del chip seleccionado debe usar `onPrimary` (verde
                // oscuro) en vez de blanco fijo para cumplir contraste WCAG.
                color: selected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Artículo destacado del día (Recuperación). Tappable → detalle completo.
class _ArticuloDestacado extends StatelessWidget {
  const _ArticuloDestacado({required this.articulo, required this.onLeer});

  final TipArticulo articulo;
  final VoidCallback onLeer;

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    return InkWell(
      onTap: onLeer,
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                strings.tipsHoyRecuperacion,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.labelSm.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: AppColors.outline),
                const SizedBox(width: 4),
                Text(
                  strings.tipsMin(articulo.min),
                  style: AppType.labelMd.copyWith(color: AppColors.outline),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              articulo.titulo,
              style: AppType.bodyLg.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              articulo.cuerpo,
              style: AppType.bodySm.copyWith(color: AppColors.outline, height: 1.5),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Flexible(
                  child: Text(
                    strings.tipsLeerArticulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.labelMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tips de alto impacto con scroll horizontal.
class _TipsDeslizables extends StatelessWidget {
  const _TipsDeslizables();

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    // Catálogo traducido en vivo (el texto vive en AppStrings).
    final tips = [
      _Tip(
        icon: Icons.water_drop,
        titulo: strings.tipsTip1Titulo,
        subtitulo: strings.tipsTip1Sub,
        descripcion: strings.tipsTip1Desc,
      ),
      _Tip(
        icon: Icons.restaurant,
        titulo: strings.tipsTip2Titulo,
        subtitulo: strings.tipsTip2Sub,
        descripcion: strings.tipsTip2Desc,
      ),
      _Tip(
        icon: Icons.bedtime,
        titulo: strings.tipsTip3Titulo,
        subtitulo: strings.tipsTip3Sub,
        descripcion: strings.tipsTip3Desc,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: strings.tipsAltoImpacto, uppercase: true),
        const SizedBox(height: 6),
        Text(
          strings.tipsDesliza,
          style: AppType.labelMd.copyWith(color: AppColors.outline),
        ),
        const SizedBox(height: 12),
        SizedBox(
          // F7: la altura de los tips escala con el tamaño de texto para no
          // recortar el contenido cuando el usuario sube la escala (accesible).
          height: 200 * MediaQuery.textScalerOf(context).scale(1.0),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tips.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => SizedBox(
              width: 240,
              child: _TipCard(tip: tips[i]),
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
              Icon(Icons.favorite_border, size: 18, color: AppColors.onSurfaceVariant),
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

/// Artículos recomendados (lista vertical) filtrados por búsqueda/categoría.
class _ArticulosRecomendados extends StatelessWidget {
  const _ArticulosRecomendados({
    required this.articulos,
    required this.total,
    required this.onVerTodos,
    required this.onArticulo,
  });

  final List<TipArticulo> articulos;
  final int total;
  final VoidCallback onVerTodos;
  final ValueChanged<TipArticulo> onArticulo;

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                strings.tipsArticulosRecomendados,
                style: AppType.headlineSm.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: InkWell(
                onTap: onVerTodos,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    // P4: "Ver todos (N)" con el número REAL de artículos.
                    strings.tipsVerTodos(total),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.labelMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (articulos.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Icon(Icons.search_off, size: 26, color: AppColors.outline),
                const SizedBox(height: 8),
                Text(
                  strings.tipsSinResultados,
                  textAlign: TextAlign.center,
                  style: AppType.bodySm.copyWith(color: AppColors.outline),
                ),
              ],
            ),
          )
        else
          for (final a in articulos)
            InkWell(
              onTap: () => onArticulo(a),
              borderRadius: BorderRadius.circular(16),
              child: Container(
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
                      child: Icon(_iconoCategoria(a.categoria), size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  strings.tipsCategoria(a.categoria),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppType.labelMd.copyWith(
                                    color: AppColors.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                ' • ',
                                style: AppType.labelSm.copyWith(color: AppColors.outline),
                              ),
                              Icon(Icons.timer, size: 12, color: AppColors.outline),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  strings.tipsMin(a.min),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppType.labelSm.copyWith(color: AppColors.outline),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            a.titulo,
                            style: AppType.labelLg.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            a.cuerpo,
                            style: AppType.bodySm.copyWith(color: AppColors.outline),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 20, color: AppColors.outline),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  IconData _iconoCategoria(String categoria) => switch (categoria) {
        'Nutrición' => Icons.restaurant_menu,
        'Fuerza' => Icons.fitness_center,
        'Bienestar' => Icons.spa,
        'Recuperación' => Icons.self_improvement,
        _ => Icons.article_outlined,
      };
}

/// Pantalla con TODOS los artículos del catálogo, filtrables (P4).
class TodosArticulosScreen extends StatefulWidget {
  const TodosArticulosScreen({super.key, required this.catalogo});

  final List<TipArticulo> catalogo;

  @override
  State<TodosArticulosScreen> createState() => _TodosArticulosScreenState();
}

class _TodosArticulosScreenState extends State<TodosArticulosScreen> {
  final TextEditingController _buscarCtrl = TextEditingController();
  String _categoria = 'Todos';

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  List<TipArticulo> get _filtrados {
    final q = _buscarCtrl.text.trim().toLowerCase();
    return widget.catalogo.where((a) {
      final okCat = _categoria == 'Todos' || a.categoria == _categoria;
      final okQ = q.isEmpty ||
          a.titulo.toLowerCase().contains(q) ||
          a.cuerpo.toLowerCase().contains(q);
      return okCat && okQ;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    final filtrados = _filtrados;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          strings.tipsTodosArticulos,
          style: AppType.headlineSm.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            TextField(
              controller: _buscarCtrl,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              style: TextStyle(fontSize: 14, color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: strings.tipsBuscar,
                hintStyle: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
                prefixIcon: Icon(Icons.search, size: 20, color: AppColors.outline),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _buscarCtrl,
                  builder: (_, v, _) => v.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          icon: Icon(Icons.close, size: 18, color: AppColors.outline),
                          onPressed: () {
                            _buscarCtrl.clear();
                            setState(() {});
                          },
                        ),
                ),
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final cat in categoriasTips) ...[
                    _CategoryPill(
                      label: strings.tipsCategoria(cat),
                      selected: _categoria == cat,
                      onTap: () => setState(() => _categoria = cat),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (filtrados.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 32, color: AppColors.outline),
                      const SizedBox(height: 8),
                      Text(
                        strings.tipsSinResultados,
                        textAlign: TextAlign.center,
                        style: AppType.bodyMd.copyWith(color: AppColors.outline),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final a in filtrados)
                _FilaArticulo(articulo: a),
          ],
        ),
      ),
    );
  }
}

class _FilaArticulo extends StatelessWidget {
  const _FilaArticulo({required this.articulo});

  final TipArticulo articulo;

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ArticuloDetalleScreen(articulo: articulo),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
              child: Icon(Icons.article_outlined, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          strings.tipsCategoria(articulo.categoria),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.labelMd.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        ' • ',
                        style: AppType.labelSm.copyWith(color: AppColors.outline),
                      ),
                      Icon(Icons.timer, size: 12, color: AppColors.outline),
                      const SizedBox(width: 2),
                      Text(
                        strings.tipsMin(articulo.min),
                        style: AppType.labelSm.copyWith(color: AppColors.outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    articulo.titulo,
                    style: AppType.labelLg.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}

/// Detalle completo de un artículo real del catálogo (P4).
class ArticuloDetalleScreen extends StatelessWidget {
  const ArticuloDetalleScreen({super.key, required this.articulo});

  final TipArticulo articulo;

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          strings.tipsDetalleArticulo,
          style: AppType.headlineSm.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    strings.tipsCategoria(articulo.categoria),
                    style: AppType.labelSm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    Icon(Icons.timer, size: 14, color: AppColors.outline),
                    const SizedBox(width: 4),
                    Text(
                      strings.tipsMin(articulo.min),
                      style: AppType.labelMd.copyWith(color: AppColors.outline),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              articulo.titulo,
              style: AppType.headlineMd.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              articulo.cuerpo,
              style: AppType.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            const _AvisoSalud(),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta informativa: la app es orientativa y no sustituye a un
/// profesional de la salud.
class _AvisoSalud extends StatelessWidget {
  const _AvisoSalud();

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.health_and_safety_outlined, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              strings.tipsAvisoSalud,
              style: AppType.bodySm.copyWith(color: AppColors.outline, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}