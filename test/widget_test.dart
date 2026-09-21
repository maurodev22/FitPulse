import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/main.dart';

Future<void> _enterDashboard(WidgetTester tester) async {
  await tester.pumpWidget(const FitPulseApp());
  expect(find.text('Crea tu Perfil Atlético'), findsOneWidget);
  await tester.tap(find.text('Guardar y Entrar al Dashboard'));
  await tester.pumpAndSettle();
}

void main() {
  // Aisla la persistencia del dispositivo en cada test.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('FitPulse muestra el onboarding de registro', (WidgetTester tester) async {
    await tester.pumpWidget(const FitPulseApp());

    expect(find.text('Crea tu Perfil Atlético'), findsOneWidget);
    expect(find.text('PASO 1 DE 2'), findsOneWidget);
    expect(find.text('Sofía Martínez'), findsWidgets);
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

    expect(find.text('Recetas FitPulse'), findsOneWidget);
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
    expect(find.text('Comunidad Activa'), findsOneWidget);
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

  testWidgets('Cerrar sesión vuelve al onboarding', (WidgetTester tester) async {
    await _enterDashboard(tester);

    await tester.tap(find.byIcon(Icons.person).last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Cerrar sesión'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Crea tu Perfil Atlético'), findsOneWidget);
  });
}