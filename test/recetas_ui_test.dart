import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/screens/recipes_screen.dart';
import 'package:fitpulse/services/config_service.dart';
import 'package:fitpulse/services/locale_service.dart';
import 'package:fitpulse/state/app_state.dart';
import 'package:fitpulse/state/athlete_profile.dart';
import 'package:fitpulse/state/recetas_catalog.dart';
import 'package:fitpulse/theme.dart';

/// L4 — UI de recetas por metas: la sección "Para tu meta" y los chips de
/// filtro del catálogo.
///
/// Lo importante aquí es el comportamiento honesto: si el usuario no ha
/// elegido meta, la app lo dice y NO esconde el catálogo.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<(AppState, LocaleService)> pumpRecetas(
    WidgetTester tester, {
    List<String> metas = const ['Bajar de peso'],
  }) async {
    // Viewport ancho: los chips de meta viven en una fila horizontal perezosa
    // y a 800 px los últimos no se construyen (no es que fallen, es que no
    // existen todavía en el árbol).
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final state = AppState();
    await state.init();
    await state.guardarPerfil(
      AthleteProfile.initial().copyWith(metas: metas),
    );
    final locale = LocaleService();
    await locale.init();
    final config = ConfigService();
    await config.init();
    AppColors.activate(lightFitPalette);
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: ChangeNotifierProvider<LocaleService>.value(
          value: locale,
          child: ChangeNotifierProvider<ConfigService>.value(
            value: config,
            child: const MaterialApp(home: RecipesScreen()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (state, locale);
  }

  group('L4 · sección "Para tu meta"', () {
    testWidgets('con meta elegida muestra recetas de esa meta y el aviso',
        (tester) async {
      await pumpRecetas(tester);

      expect(find.text('PARA TU META'), findsOneWidget);
      expect(
        find.textContaining('Mostrando recetas marcadas para tu meta'),
        findsOneWidget,
      );
      // Aviso de orientación: los macros son estimaciones.
      expect(
        find.textContaining('Contenido orientativo'),
        findsOneWidget,
      );
    });

    testWidgets('las recetas mostradas llevan esa meta', (tester) async {
      await pumpRecetas(tester, metas: const ['Aumentar de peso']);

      final meta = 'Aumentar de peso';
      final paraTuMeta = recetasParaMeta(catalog, meta).take(3).toList();
      // La sección muestra las 3 primeras de la lista filtrada.
      expect(find.text(paraTuMeta.first.nombre), findsWidgets);
    });

    testWidgets('sin meta elegida NO esconde el catálogo y lo explica',
        (tester) async {
      await pumpRecetas(tester, metas: const []);

      expect(find.text('PARA TU META'), findsOneWidget);
      expect(
        find.textContaining('No has elegido meta en el Perfil'),
        findsOneWidget,
      );
      // Sigue habiendo recetas accesibles.
      expect(find.text('Ver todas'), findsWidgets);
    });

    testWidgets('el nombre de la meta se traduce al idioma activo',
        (tester) async {
      await pumpRecetas(tester, metas: const ['Bajar de peso']);
      // En español la etiqueta se muestra tal cual.
      expect(find.textContaining('Bajar de peso'), findsWidgets);
    });
  });

  group('L4 · filtro por meta en el catálogo', () {
    testWidgets('los chips muestran el recuento real de cada meta',
        (tester) async {
      await pumpRecetas(tester, metas: const []);
      await abrirCatalogo(tester);

      expect(find.text('Todas las metas'), findsOneWidget);
      final conteo = conteoPorMeta(catalog);
      for (final meta in metasCatalogo) {
        expect(
          find.text('$meta (${conteo[meta]})'),
          findsOneWidget,
          reason: 'Falta el chip de "$meta"',
        );
      }
    });

    testWidgets('al elegir una meta el título y la lista se filtran',
        (tester) async {
      await pumpRecetas(tester, metas: const []);
      await abrirCatalogo(tester);

      final conteo = conteoPorMeta(catalog)['Bajar de peso']!;
      await tester.tap(find.text('Bajar de peso ($conteo)'));
      await tester.pumpAndSettle();

      expect(find.text('Recetas para "Bajar de peso"'), findsOneWidget);
      for (final receta in recetasParaMeta(catalog, 'Bajar de peso')) {
        expect(receta.metas, contains('Bajar de peso'));
      }
    });

    testWidgets('"Todas las metas" devuelve el catálogo completo',
        (tester) async {
      await pumpRecetas(tester, metas: const []);
      await abrirCatalogo(tester);

      await tester.tap(find.text('Todas las metas'));
      await tester.pumpAndSettle();

      expect(find.text('Todos los platos'), findsOneWidget);
    });

    testWidgets('el filtro por meta no rompe el filtro por categoría',
        (tester) async {
      await pumpRecetas(tester, metas: const []);
      await abrirCatalogo(tester);

      await tester.tap(find.text('Low Carb'));
      await tester.pumpAndSettle();

      final totalLowCarb =
          catalog.where((r) => r.categoria == 'Low Carb').length;
      expect(totalLowCarb, greaterThan(0));
      // Sigue apareciendo la fila de chips de meta.
      expect(find.text('Todas las metas'), findsOneWidget);
    });
  });
}

/// Abre el catálogo completo desde la acción "Ver todas" de la sección "Para tu
/// meta". El botón queda por debajo del pliegue en el viewport de prueba (800x600),
/// así que primero se trae a la vista: si no, el `tap()` falla sin llegar a pulsarlo.
Future<void> abrirCatalogo(WidgetTester tester) async {
  final boton = find.text('Ver todas').first;
  await tester.ensureVisible(boton);
  await tester.pumpAndSettle();
  await tester.tap(boton);
  await tester.pumpAndSettle();
}
