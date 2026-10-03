import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/main.dart';
import 'package:fitpulse/screens/progress_screen.dart';
import 'package:fitpulse/state/workout.dart';

/// Acepta el EULA inicial y vuelca el flujo de registro hasta el dashboard
/// (mismo flujo que test/widget_test.dart).
Future<void> _enterDashboard(WidgetTester tester) async {
  await tester.pumpWidget(const FitPulseApp());

  expect(find.text('Términos y Condiciones de Uso'), findsOneWidget);
  await tester.tap(find.byType(CheckboxListTile));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Continuar'));
  await tester.pumpAndSettle();
  expect(find.text('Crea tu Perfil Atlético'), findsOneWidget);

  await tester.enterText(
    find.widgetWithText(TextFormField, 'Escribe tu nombre'),
    'Sofía Martínez',
  );
  await tester.pumpAndSettle();

  await tester.ensureVisible(find.text('Selecciona'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Selecciona'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Femenino').last);
  await tester.pumpAndSettle();

  await tester.ensureVisible(find.text('Definir'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Definir'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Guardar y Entrar al Dashboard'));
  await tester.pumpAndSettle();

  // P17: configuración inicial (tema + avisos) tras el registro; "Continuar"
  // entra al dashboard (misma rutina que widget_test.dart).
  expect(find.text('Personaliza FitPulse'), findsOneWidget);
  await tester.tap(find.text('Continuar'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('resumenPeriodo (ventanas reales del historial)', () {
    test('historial vacío → todo en cero', () {
      final r = resumenPeriodo(const [], 7);
      expect(r.sesiones, 0);
      expect(r.minutos, 0);
      expect(r.kcal, 0);
      expect(r.rachaMaxima, 0);
    });

    test('las ventanas filtran por días y suman sesiones/min/kcal', () {
      final hoy = DateTime.now();
      final historial = [
        WorkoutSession(
          fecha: hoy,
          nombre: 'A',
          duracionMin: 30,
          calorias: 300,
        ),
        WorkoutSession(
          fecha: hoy.subtract(const Duration(days: 1)),
          nombre: 'B',
          duracionMin: 20,
          calorias: 200,
        ),
        WorkoutSession(
          fecha: hoy.subtract(const Duration(days: 8)),
          nombre: 'C',
          duracionMin: 10,
          calorias: 100,
        ),
        WorkoutSession(
          fecha: hoy.subtract(const Duration(days: 400)),
          nombre: 'D',
          duracionMin: 5,
          calorias: 50,
        ),
      ];

      final semanal = resumenPeriodo(historial, 7);
      expect(semanal.sesiones, 2);
      expect(semanal.minutos, 50);
      expect(semanal.kcal, 500);
      expect(semanal.rachaMaxima, 2);

      final mensual = resumenPeriodo(historial, 30);
      expect(mensual.sesiones, 3); // hoy, ayer y hace 8 días
      expect(mensual.kcal, 600);
      expect(mensual.rachaMaxima, 2); // hace 8 días rompe la cadena

      final anual = resumenPeriodo(historial, 365);
      expect(anual.sesiones, 3); // hace 400 días queda fuera también del año
      expect(anual.kcal, 600);
    });

    test('la racha solo cuenta dentro de la ventana', () {
      final hoy = DateTime.now();
      final historial = [
        WorkoutSession(
          fecha: hoy.subtract(const Duration(days: 40)),
          nombre: 'A',
          duracionMin: 15,
          calorias: 150,
        ),
        WorkoutSession(
          fecha: hoy.subtract(const Duration(days: 39)),
          nombre: 'B',
          duracionMin: 15,
          calorias: 150,
        ),
      ];
      // En semanal (7 días) no entra ninguna sesión.
      expect(resumenPeriodo(historial, 7).sesiones, 0);
      // En anual entran las dos y forman racha de 2.
      final anual = resumenPeriodo(historial, 365);
      expect(anual.sesiones, 2);
      expect(anual.rachaMaxima, 2);
    });
  });

  testWidgets('Corrección 1.1: un pill de categoría abre el catálogo filtrado',
      (tester) async {
    await _enterDashboard(tester);
    await tester.tap(find.text('Recetas').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alta Proteína').first);
    await tester.pumpAndSettle();

    // El catálogo abre ya filtrado: recetas de alta proteína sí, low carb no.
    expect(find.text('Todos los platos'), findsOneWidget);
    expect(find.text('Bowl de Salmón, Aguacate y Quinoa'), findsWidgets);
    expect(find.text('Ensalada Griega con Pechuga'), findsNothing);
  });

  testWidgets('Corrección 1.2 y 1.3: pestañas de período + Ver todo',
      (tester) async {
    await _enterDashboard(tester);
    await tester.tap(find.text('Progreso').first);
    await tester.pumpAndSettle();

    expect(find.text('Evolución & Rendimiento'), findsOneWidget);
    expect(find.text('Semanal'), findsOneWidget);
    expect(find.text('Mensual'), findsOneWidget);
    expect(find.text('Año'), findsOneWidget);

    // Sin sesiones, el resumen del período es honesto (no inventa ceros).
    expect(find.text('Sin sesiones en este período'), findsOneWidget);

    // Cambiar de pestaña re-renderiza el panel sin romper nada.
    await tester.tap(find.text('Mensual'));
    await tester.pumpAndSettle();
    expect(find.text('Sin sesiones en este período'), findsOneWidget);

    // "Ver todo" abre el historial completo de sesiones.
    await tester.scrollUntilVisible(find.text('Ver todo'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver todo'));
    await tester.pumpAndSettle();
    expect(find.text('Historial de sesiones'), findsOneWidget);
    expect(find.text('Aún no hay sesiones registradas'), findsOneWidget);
  });
}