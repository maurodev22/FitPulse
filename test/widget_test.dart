import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/main.dart';
import 'package:fitpulse/widgets/fit_nav_bar.dart';

/// Acepta el EULA inicial y vuelca el flujo de registro hasta el dashboard.
Future<void> _enterDashboard(WidgetTester tester) async {
  await tester.pumpWidget(const FitPulseApp());

  // Pantalla de Términos/EULA: marcar la casilla y continuar.
  expect(find.text('Términos y Condiciones de Uso'), findsOneWidget);
  await tester.tap(find.byType(CheckboxListTile));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Continuar'));
  await tester.pumpAndSettle();

  // Onboarding: el formulario está vacío (sin datos ficticios).
  expect(find.text('Crea tu Perfil Atlético'), findsOneWidget);

  // Nombre completo (campo texto).
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Escribe tu nombre'),
    'Sofía Martínez',
  );
  await tester.pumpAndSettle();

  // El formulario es más largo que la pantalla de test: hay que llevar cada
  // control al área visible antes de interactuar.
  await tester.ensureVisible(find.text('Selecciona'));
  await tester.pumpAndSettle();

  // Sexo biológico por dropdown.
  await tester.tap(find.text('Selecciona'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Femenino').last);
  await tester.pumpAndSettle();

  // Meta principal por chip.
  await tester.ensureVisible(find.text('Definir'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Definir'));
  await tester.pumpAndSettle();

  // Guardar y entrar.
  await tester.tap(find.text('Guardar y Entrar al Dashboard'));
  await tester.pumpAndSettle();
}

void main() {
  // Aisla la persistencia del dispositivo en cada test.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('FitPulse muestra el flujo EULA y el onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(const FitPulseApp());

    expect(find.text('Términos y Condiciones de Uso'), findsOneWidget);

    // Sin marcar la casilla el botón continuar no avanza.
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Términos y Condiciones de Uso'), findsOneWidget);

    // Al aceptar, se llega al onboarding con el formulario vacío.
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Crea tu Perfil Atlético'), findsOneWidget);
    expect(find.text('Escribe tu nombre'), findsOneWidget);
  });

  testWidgets('FitPulse renderiza la pantalla de inicio', (WidgetTester tester) async {
    await _enterDashboard(tester);

    // Saludo personalizado con el nombre registrado en onboarding.
    expect(find.text('Hola, Sofía'), findsOneWidget);
    expect(find.text('Resumen de hoy'), findsOneWidget);
    expect(find.text('Entrenamiento de hoy'), findsOneWidget);
  });

  testWidgets('Navega a la pestaña de Recetas', (WidgetTester tester) async {
    await _enterDashboard(tester);

    await tester.tap(find.text('Recetas').first);
    await tester.pumpAndSettle();

    expect(find.text('Recetas'), findsWidgets);
    expect(find.text('BALANCE NUTRICIONAL DE HOY'), findsOneWidget);
  });

  testWidgets('Navega a la pestaña de Progreso', (WidgetTester tester) async {
    await _enterDashboard(tester);

    await tester.tap(find.text('Progreso').first);
    await tester.pumpAndSettle();

    expect(find.text('Evolución & Rendimiento'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Sesiones Recientes'), 200);
    await tester.pumpAndSettle();
    expect(find.text('Sesiones Recientes'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Insignias & Logros'), 200);
    await tester.pumpAndSettle();
    expect(find.text('Insignias & Logros'), findsOneWidget);
  });

  testWidgets('Navega a la pestaña de Consejos', (WidgetTester tester) async {
    await _enterDashboard(tester);

    await tester.tap(find.text('Consejos').first);
    await tester.pumpAndSettle();

    expect(find.text('Consejos & Bienestar'), findsOneWidget);

    // La ListView vertical es perezosa: se hace scroll desde un elemento
    // que está dentro de la lista para materializar el resto de secciones.
    await tester.drag(find.text('Consejos & Bienestar'), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('TIPS DE ALTO IMPACTO'), findsOneWidget);

    // Se sigue desplazando desde la zona central de la pantalla.
    await tester.dragFrom(const Offset(400, 300), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(
      find.text('Estos contenidos son orientativos y no sustituyen el consejo de un profesional de la salud.'),
      findsOneWidget,
    );
  });

  testWidgets('Navega a la pestaña de Perfil', (WidgetTester tester) async {
    await _enterDashboard(tester);

    await tester.tap(find.byIcon(Icons.person).last);
    await tester.pumpAndSettle();

    // El perfil vive en un ListView perezoso: los campos quedan bajo el pliegue.
    await tester.scrollUntilVisible(find.text('Datos Personales'), 200);
    await tester.pumpAndSettle();

    expect(find.text('Sofía Martínez'), findsNWidgets(2));
    expect(find.text('Datos Personales'), findsOneWidget);
  });

  testWidgets('Sin desbordes en pantalla pequeña (360x640)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _enterDashboard(tester);

    // Inicio sin la sección "Explorar categorías".
    expect(find.text('Explorar categorías'), findsNothing);
    expect(find.text('Hola, Sofía'), findsOneWidget);

    // Recetas con encabezado simplificado (sin meta ni "Nutrición & Vitalidad").
    await tester.tap(find.text('Recetas').first);
    await tester.pumpAndSettle();
    expect(find.text('BALANCE NUTRICIONAL DE HOY'), findsOneWidget);
    await tester.tap(find.text('Progreso').first);
    await tester.pumpAndSettle();
    expect(find.text('Evolución & Rendimiento'), findsOneWidget);
  });

  testWidgets('Navega a la pestaña de Ayuda (manual + FAQ)', (WidgetTester tester) async {
    await _enterDashboard(tester);

    await tester.tap(
      find.descendant(of: find.byType(FitNavBar), matching: find.text('Ayuda')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Manual de usuario'), findsOneWidget);
    expect(find.text('¿Dónde se guardan mis datos?'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('¿Funciona sin internet?'), 200);
    expect(find.text('Preguntas frecuentes'), findsOneWidget);
    expect(find.text('¿Funciona sin internet?'), findsOneWidget);
  });
}