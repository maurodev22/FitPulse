import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/screens/home_screen.dart';
import 'package:fitpulse/screens/tips_screen.dart';
import 'package:fitpulse/services/locale_service.dart';
import 'package:fitpulse/state/app_state.dart';
import 'package:fitpulse/theme.dart';

/// Hotfix UI (30/09): cobertura de la funcionalidad nueva.
/// - P1: "Ver detalles" abre el bottom sheet con el detalle real del día.
/// - P4: la búsqueda y las pills filtran el catálogo real de Consejos, y
///   "Ver todos (N)" usa el número real de artículos (4).
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpApp(WidgetTester tester, Widget screen) async {
    final locale = LocaleService();
    await locale.init();
    AppColors.activate(darkFitPalette);
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: AppState(),
        child: ChangeNotifierProvider<LocaleService>.value(
          value: locale,
          child: MaterialApp(home: screen),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('P1: "Ver detalles" abre el bottom sheet del día (Home)',
      (tester) async {
    await pumpApp(tester, const HomeScreen());

    expect(find.text('Resumen de hoy'), findsOneWidget);

    await tester.tap(find.text('Ver detalles'));
    await tester.pumpAndSettle();

    // El bottom sheet muestra el detalle real del día con su aviso honesto.
    expect(find.text('Detalle del día de hoy'), findsOneWidget);
    expect(find.text('Pasos'), findsWidgets);
    expect(find.text('Calorías'), findsWidgets);
    expect(find.text('Pulso'), findsWidgets);
    expect(find.text('Agua'), findsWidgets);
    expect(find.text('Cerrar'), findsOneWidget);

    // Cerrar con el botón del sheet.
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle del día de hoy'), findsNothing);
  });

  testWidgets('P4: la búsqueda filtra el catálogo real de Consejos',
      (tester) async {
    await pumpApp(tester, const TipsScreen());

    // Catálogo real: 4 artículos (destacado + 3 recomendados).
    expect(find.text('Ver todos (4)'), findsOneWidget);

    // Búsqueda por cuerpo/título: solo queda el artículo de sentadilla.
    await tester.enterText(find.byType(TextField), 'sentadilla');
    await tester.pumpAndSettle();

    expect(find.text('Ver todos (1)'), findsOneWidget);
    expect(
      find.text('Cómo mejorar tu técnica de sentadilla profunda'),
      findsOneWidget,
    );

    // El destacado de Recuperación se oculta al filtrar por fuerza.
    expect(find.text('HOY • RECUPERACIÓN'), findsNothing);
  });

  testWidgets('P4: las pills de categoría filtran por categoría real',
      (tester) async {
    await pumpApp(tester, const TipsScreen());

    // Sin filtro: los 4 artículos.
    expect(find.text('Ver todos (4)'), findsOneWidget);

    // Pill "Nutrición" → solo el artículo de déficit calórico.
    await tester.tap(find.text('Nutrición').first);
    await tester.pumpAndSettle();

    expect(find.text('Ver todos (1)'), findsOneWidget);
    expect(
      find.text('5 Errores comunes al calcular tu déficit calórico'),
      findsOneWidget,
    );

    // Pill "Todos" vuelve al catálogo completo.
    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();
    expect(find.text('Ver todos (4)'), findsOneWidget);
  });

  testWidgets('P4: "Ver todos" navega a la lista completa filtrable',
      (tester) async {
    await pumpApp(tester, const TipsScreen());

    // El enlace vive bajo el pliegue: se asegura su visibilidad antes de tocar.
    await tester.ensureVisible(find.text('Ver todos (4)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver todos (4)'));
    await tester.pumpAndSettle();

    // Lista completa con su propio buscador y las 4 filas del catálogo.
    expect(find.text('Todos los artículos'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(
      find.text('La importancia de los descansos activos para no perder masa muscular'),
      findsOneWidget,
    );
    expect(
      find.text('5 Errores comunes al calcular tu déficit calórico'),
      findsOneWidget,
    );
  });

  testWidgets('P14: la fila Agua del Día ideal abre el registro manual',
      (tester) async {
    await pumpApp(tester, const HomeScreen());

    // El Home no muestra agua (sin permiso HC ni registro manual).
    expect(find.text('Objetivo: 2.5 L'), findsOneWidget);

    // Tocar la fila Agua abre el diálogo de registro manual (P14).
    await tester.tap(find.text('Objetivo: 2.5 L'));
    await tester.pumpAndSettle();

    expect(find.text('Registra tu agua de hoy'), findsOneWidget);
    expect(find.text('+0,25 L'), findsOneWidget);
    expect(find.text('+0,50 L'), findsOneWidget);
    expect(find.text('+1 L'), findsOneWidget);

    // +0,50 L registra, cierra el diálogo y confirma con snackbar.
    await tester.tap(find.text('+0,50 L'));
    await tester.pumpAndSettle();

    expect(find.text('Registra tu agua de hoy'), findsNothing);
    expect(find.text('Agua registrada: 0.50 L'), findsOneWidget);
    expect(find.text('0.5 / 2.5 L'), findsOneWidget);

    // +1 L más → 1.5 L total; la meta (2.5 L) aún no se cumple.
    await tester.tap(find.text('0.5 / 2.5 L'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+1 L'));
    await tester.pumpAndSettle();

    expect(find.text('Agua registrada: 1.00 L'), findsOneWidget);
    expect(find.text('1.5 / 2.5 L'), findsOneWidget);
  });
}