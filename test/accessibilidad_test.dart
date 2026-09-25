import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/main.dart';

/// Fase 7: accesibilidad de texto. Recorre todo el shell con una escala de
/// texto de 2.0× (equivalente a la opción "Más grande" de Android) y falla
/// si cualquier frame emite un overflow (RenderFlex/RenderViewport).
Future<void> _exploreConEscala(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = 2.0;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(const FitPulseApp());

  // Aceptar EULA.
  await tester.tap(find.byType(CheckboxListTile));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Continuar'));
  await tester.pumpAndSettle();

  // Llenar el onboarding y entrar.
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Escribe tu nombre'),
    'Ana Pérez',
  );
  await tester.pumpAndSettle();

  await tester.ensureVisible(find.text('Selecciona'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Selecciona'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Masculino').last);
  await tester.pumpAndSettle();

  await tester.ensureVisible(find.text('Definir'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Definir'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Guardar y Entrar al Dashboard'));
  await tester.pumpAndSettle();

  // Recorre cada pestaña y hace scroll de arriba a abajo.
  final tabs = <IconData>[
    Icons.home,
    Icons.restaurant_menu,
    Icons.insights,
    Icons.lightbulb_outline,
    Icons.person,
    Icons.help_outline,
  ];
  for (final icon in tabs) {
    if (icon != Icons.home) {
      await tester.tap(find.byIcon(icon).last);
      await tester.pumpAndSettle();
    }
    for (var i = 0; i < 12; i++) {
      await tester.drag(find.byType(Scaffold).first, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    for (var i = 0; i < 12; i++) {
      await tester.drag(find.byType(Scaffold).first, const Offset(0, 300));
      await tester.pumpAndSettle();
    }
    expect(find.byType(Scaffold), findsWidgets);
  }

  expect(tester.takeException(), isNull);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('texto 2.0× en 360 dp: sin overflows en ninguna sección',
      (WidgetTester tester) async {
    await _exploreConEscala(tester, const Size(360, 800));
  });
}