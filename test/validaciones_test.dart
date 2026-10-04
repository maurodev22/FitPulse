import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/screens/home_screen.dart';
import 'package:fitpulse/screens/workout_player_screen.dart';
import 'package:fitpulse/services/config_service.dart';
import 'package:fitpulse/services/locale_service.dart';
import 'package:fitpulse/state/app_state.dart';
import 'package:fitpulse/state/workout.dart';
import 'package:fitpulse/theme.dart';
import 'package:fitpulse/utils/validators.dart';

/// P19: validaciones por sinceridad (reps mínimas y tope diario de agua).
/// - Unit: `Validators.validarReps` (0 no es una cuenta real) y
///   `Validators.validarAguaDiaria` (>5 L/día se rechaza).
/// - Widget agua: escribir +6 L en el diálogo de Home muestra el aviso de
///   honestidad durante 5 s y NO registra ni cierra el diálogo.
/// - Widget reps: guardar 0 en el diálogo del reproductor muestra el aviso
///   motivador dentro del diálogo y no lo cierra; con ≥1 sí guarda.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('P19 · Validators', () {
    test('validarReps: 0 no es una cuenta real → aviso motivador', () {
      final aviso = 'Esfuérzate para conseguir 1 repetición más';
      expect(Validators.validarReps(0, aviso), aviso);
      expect(Validators.validarReps(1, aviso), isNull);
      expect(Validators.validarReps(12, aviso), isNull);
    });

    test('validarAguaDiaria: >5 L/día se rechaza; 5 L exactos pasan', () {
      const aviso = 'La sinceridad es lo que te ayuda a crecer';
      expect(Validators.validarAguaDiaria(5.5, aviso), aviso);
      expect(Validators.validarAguaDiaria(5.0, aviso), isNull);
      expect(Validators.validarAguaDiaria(2.5, aviso), isNull);
    });

    test('P20 validarMetaPasos: mínimo honesto 1000 (no 1)', () {
      const aviso = 'La meta de pasos debe estar entre 1000 y 100000';
      expect(Validators.validarMetaPasos(null, aviso), aviso);
      expect(Validators.validarMetaPasos(999, aviso), aviso);
      expect(Validators.validarMetaPasos(0, aviso), aviso);
      expect(Validators.validarMetaPasos(1000, aviso), isNull);
      expect(Validators.validarMetaPasos(10000, aviso), isNull);
      expect(Validators.validarMetaPasos(100000, aviso), isNull);
      expect(Validators.validarMetaPasos(100001, aviso), aviso);
    });

    test('P20 validarMetaKcal: mínimo investigado 1200 (no 500)', () {
      const aviso = 'La meta de calorías debe estar entre 1200 y 10000 kcal';
      expect(Validators.validarMetaKcal(null, aviso), aviso);
      expect(Validators.validarMetaKcal(500, aviso), aviso);
      expect(Validators.validarMetaKcal(1199.9, aviso), aviso);
      expect(Validators.validarMetaKcal(1200, aviso), isNull);
      expect(Validators.validarMetaKcal(2100, aviso), isNull);
      expect(Validators.validarMetaKcal(10000, aviso), isNull);
      expect(Validators.validarMetaKcal(10000.1, aviso), aviso);
    });
  });

  group('P19 · Dialogo de agua (Home)', () {
    Future<(AppState, LocaleService)> pumpHome(WidgetTester tester) async {
      final state = AppState();
      await state.init();
      final locale = LocaleService();
      await locale.init();
      AppColors.activate(darkFitPalette);
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: ChangeNotifierProvider<LocaleService>.value(
            value: locale,
            child: const MaterialApp(home: HomeScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return (state, locale);
    }

    Future<void> abrirDialogoAgua(WidgetTester tester) async {
      await tester.tap(find.text('Objetivo: 2.5 L'));
      await tester.pumpAndSettle();
    }

    testWidgets('+6 L muestra el aviso de honestidad 5 s, no registra ni cierra',
        (tester) async {
      final (state, _) = await pumpHome(tester);
      await abrirDialogoAgua(tester);

      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        '6',
      );
      await tester.tap(find.text('Añadir'));
      await tester.pump(const Duration(milliseconds: 300));

      // Aviso visible y el diálogo sigue abierto.
      expect(
        find.text('La sinceridad es lo que te ayuda a crecer: máximo 5 L de agua al día.'),
        findsOneWidget,
      );
      expect(find.text('Registra tu agua de hoy'), findsOneWidget);
      expect(state.aguaHoy, isNull);

      // El toast está configurado para durar 5 segundos (requisito P19).
      final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackbar.duration, const Duration(seconds: 5));

      // Avanza en pasos cortos hasta que se auto-oculte (tras sus 5 s).
      for (var i = 0;
          i < 40 && find.byType(SnackBar).evaluate().isNotEmpty;
          i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      await tester.pumpAndSettle();
      expect(
        find.text('La sinceridad es lo que te ayuda a crecer: máximo 5 L de agua al día.'),
        findsNothing,
      );
    });

    testWidgets('una cantidad plausible (0,5 L) sí registra y cierra',
        (tester) async {
      final (state, _) = await pumpHome(tester);
      await abrirDialogoAgua(tester);

      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        '0,5',
      );
      await tester.tap(find.text('Añadir'));
      await tester.pumpAndSettle();

      expect(find.text('Registra tu agua de hoy'), findsNothing);
      expect(state.aguaHoy, 0.5);
    });
  });

  group('P19 · Dialogo de reps (reproductor)', () {
    Future<AppState> pumpReproductor(WidgetTester tester) async {
      final state = AppState();
      await state.init();
      final locale = LocaleService();
      await locale.init();
      final config = ConfigService();
      await config.init();
      AppColors.activate(darkFitPalette);

      // Programa de un solo ejercicio muy corto: al agotarse el tiempo el
      // reproductor finaliza y ofrece registrar repeticiones (P12).
      final programa = WorkoutProgram(
        id: 'p19',
        nombre: 'Prueba',
        descripcion: 'd',
        duracionMin: 1,
        kcalEstimadas: 10,
        intensidad: 'Baja',
        ejercicios: [
          WorkoutExercise(
            nombre: 'Flexiones',
            duracion: const Duration(seconds: 1),
            descanso: Duration.zero,
            repeticiones: '10 reps',
          ),
        ],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: ChangeNotifierProvider<LocaleService>.value(
            value: locale,
            child: ChangeNotifierProvider<ConfigService>.value(
              value: config,
              child: MaterialApp(home: WorkoutPlayerScreen(program: programa)),
            ),
          ),
        ),
      );
      // Agota el temporizador de 1 s → _finalizar(ofrecerReps: true).
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      return state;
    }

    testWidgets('guardar 0 reps muestra el aviso y NO cierra el diálogo',
        (tester) async {
      await pumpReproductor(tester);

      expect(find.text('¿Cuántas repeticiones completaste?'), findsOneWidget);

      // Guardar con el valor inicial 0.
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(
        find.text('Esfuérzate para conseguir 1 repetición más'),
        findsOneWidget,
      );
      // El diálogo sigue abierto: el usuario aún puede corregir.
      expect(find.text('¿Cuántas repeticiones completaste?'), findsOneWidget);

      // Cerrar el diálogo (Cancelar) para limpiar el árbol.
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('¿Cuántas repeticiones completaste?'), findsNothing);

      // Drena los snackbars de cierre de sesión para no dejar timers.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('con 1 repetición sí guarda y cierra el diálogo',
        (tester) async {
      final state = await pumpReproductor(tester);

      expect(find.text('¿Cuántas repeticiones completaste?'), findsOneWidget);

      // +1 → valor 1 → Guardar.
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byIcon(Icons.add),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('¿Cuántas repeticiones completaste?'), findsNothing);
      expect(state.historialReps.last.reps, 1);

      // Drena los snackbars de cierre de sesión para no dejar timers.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });
}