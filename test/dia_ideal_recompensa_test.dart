import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/screens/home_screen.dart';
import 'package:fitpulse/services/locale_service.dart';
import 'package:fitpulse/state/app_state.dart';
import 'package:fitpulse/theme.dart';

/// P18: recompensa visual del Día ideal (+25 XP, una vez por día).
/// - Unit: la recompensa SOLO se otorga con los 3 objetivos completos y
///   una sola vez por día (nunca premia un día a medias ni se repite).
/// - Widget: al completar 3/3 aparece la celebración suave (+25 XP · ¡Día
///   ideal completado!) que se desvanece sola y no vuelve a aparecer hoy.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> completarDiaIdeal(AppState state) async {
    await state.init();
    await state.registrarSesionCompletada(
      nombre: 'Entrenamiento de prueba',
      duracion: const Duration(minutes: 30),
      calorias: 250,
    );
    await state.registrarConsumo(
      calorias: 2100, // iguala la meta por defecto del perfil (2100 kcal)
      proteinas: 0,
      carbos: 0,
      grasas: 0,
    );
    await state.registrarAgua(2.5);
  }

  Future<void> pumpHome(WidgetTester tester, AppState state) async {
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
  }

  group('P18 · AppState (la recompensa es honesta y única por día)', () {
    test('no premia si el día NO está completo (falta agua)', () async {
      final state = AppState();
      await state.init();
      await state.registrarSesionCompletada(
        nombre: 'Entrenamiento de prueba',
        duracion: const Duration(minutes: 30),
        calorias: 250,
      );
      await state.registrarConsumo(
        calorias: 2100,
        proteinas: 0,
        carbos: 0,
        grasas: 0,
      );
      // Sin agua: solo 2/3 → nada.
      expect(state.diaIdealCompletadoHoy, isFalse);
      final otorgada = await state.aplicarRecompensaDiaIdeal();
      expect(otorgada, isFalse);
      expect(state.xp, 50); // solo el +50 de la sesión, sin recompensa.
    });

    test('3/3 completos otorga +25 XP una sola vez por día', () async {
      final state = AppState();
      await completarDiaIdeal(state);

      expect(state.diaIdealCompletadoHoy, isTrue);
      expect(state.recompensaDiaIdealOtorgadaHoy, isFalse);

      final otorgada = await state.aplicarRecompensaDiaIdeal();
      expect(otorgada, isTrue);
      expect(state.xp, 50 + AppState.ptsDiaIdeal);
      expect(state.recompensaDiaIdealOtorgadaHoy, isTrue);

      // Segundo intento el mismo día → no vuelve a premiar.
      final segunda = await state.aplicarRecompensaDiaIdeal();
      expect(segunda, isFalse);
      expect(state.xp, 50 + AppState.ptsDiaIdeal);
    });
  });

  group('P18 · Home (celebración visual una vez al día)', () {
    testWidgets('3/3 muestra confeti + "+25 XP · ¡Día ideal completado!"',
        (tester) async {
      final state = AppState();
      await completarDiaIdeal(state);

      await pumpHome(tester, state);

      // Detección tras el primer frame + animación de la celebración.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('¡Día ideal completado!'), findsOneWidget);
      expect(find.text('+25 XP · ¡Sigue así!'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsWidgets);
      // El premio se concedió de verdad.
      expect(state.recompensaDiaIdealOtorgadaHoy, isTrue);
      expect(state.xp, 50 + AppState.ptsDiaIdeal);

      // Espera a que el auto-ocultado (2,8 s) termine: sin timers pendientes.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('¡Día ideal completado!'), findsNothing);
    });

    testWidgets('la celebración se desvanece sola y NO reaparece hoy',
        (tester) async {
      final state = AppState();
      await completarDiaIdeal(state);

      await pumpHome(tester, state);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('¡Día ideal completado!'), findsOneWidget);

      // Espera a que termine la animación y el auto-ocultado (2,8 s).
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('¡Día ideal completado!'), findsNothing);
      expect(find.text('+25 XP · ¡Sigue así!'), findsNothing);

      // Rebuild/notificación posterior: la recompensa ya está otorgada hoy,
      // así que la celebración NO vuelve a dispararse.
      await state.registrarConsumo(
        calorias: 100,
        proteinas: 0,
        carbos: 0,
        grasas: 0,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('¡Día ideal completado!'), findsNothing);
      expect(state.recompensaDiaIdealOtorgadaHoy, isTrue);
    });
  });
}