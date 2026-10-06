import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/screens/profile_screen.dart';
import 'package:fitpulse/services/config_service.dart';
import 'package:fitpulse/services/locale_service.dart';
import 'package:fitpulse/state/app_state.dart';
import 'package:fitpulse/theme.dart';

/// FASE F — Profundización (F1 teaser "Próxima insignia" + F3 tests de
/// economía de XP). Nada de esto inventa datos: premios y condiciones vienen
/// de la tabla real del estado.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  String keyDe(DateTime d) => d.toIso8601String().substring(0, 10);

  /// n sesiones en días consecutivos terminando hoy → racha viva n.
  Future<void> sesionesConsecutivas(AppState state, int n) async {
    final hoy = DateTime.now();
    for (var i = n - 1; i >= 0; i--) {
      await state.registrarSesionCompletada(
        nombre: 'S$i',
        duracion: const Duration(minutes: 20),
        calorias: 100,
        fecha: hoy.subtract(Duration(days: i)),
      );
    }
  }

  group('F3 · economía de XP (tabla de premios real)', () {
    test('sesión 50 + reto 100: 7 días seguidos dan 550 XP y objetivo 7',
        () async {
      final state = AppState();
      await state.init();
      await sesionesConsecutivas(state, 7);

      // Tabla: 7 sesiones × 50 = 350; reto 3→5 = +100; reto 5→7 = +100.
      expect(state.xp, 550);
      expect(state.retoObjetivo, 7);
      // Todo el XP se anota en el DÍA REAL del otorgamiento (hoy): el ledger
      // nunca estima fechas de sesiones pasadas ni futuras.
      expect(state.xpPorDia[keyDe(DateTime.now())], 550);
    });

    test('reto 3→5→7 avanza sin premiar doble el día 7', () async {
      final state = AppState();
      await state.init();
      await sesionesConsecutivas(state, 5);
      expect(state.retoObjetivo, 7);
      expect(state.xp, 5 * 50 + 100 + 100);
      // Un día más (6º): solo +50, sin premio de reto (objetivo ya en 7).
      await state.registrarSesionCompletada(
        nombre: 'S6',
        duracion: const Duration(minutes: 20),
        calorias: 100,
        fecha: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(state.xp, 6 * 50 + 200);
    });

    test('anuncio recompensado: +pts una sola vez por día', () async {
      final state = AppState();
      await state.init();
      final primera = await state.aplicarRecompensaAnuncio();
      expect(primera, isTrue);
      expect(state.xp, AppState.ptsRecompensaAnuncio);
      // Mismo día: no vuelve a premiar.
      final segunda = await state.aplicarRecompensaAnuncio();
      expect(segunda, isFalse);
      expect(state.xp, AppState.ptsRecompensaAnuncio);
    });

    test('nivel inicial: 1 · Principiante · progreso 0.0', () async {
      final state = AppState();
      await state.init();
      expect(state.nivel, 1);
      expect(state.nombreNivel, 'Principiante');
      expect(state.progresoNivel, 0.0);
    });

    test('900 XP (18 sesiones) → nivel 4 · Intermedio', () async {
      final state = AppState();
      await state.init();
      for (var i = 0; i < 18; i++) {
        await state.registrarSesionCompletada(
          nombre: 'S$i',
          duracion: const Duration(minutes: 20),
          calorias: 100,
          fecha: DateTime.now().subtract(Duration(days: i * 2)),
        );
      }
      expect(state.xp, 900);
      expect(state.nivel, 4);
      expect(state.nombreNivel, 'Intermedio');
      expect(state.progresoNivel, 0.0);
    });

    test('2100 XP (42 sesiones) → nivel 8 · Avanzado', () async {
      final state = AppState();
      await state.init();
      for (var i = 0; i < 42; i++) {
        await state.registrarSesionCompletada(
          nombre: 'S$i',
          duracion: const Duration(minutes: 20),
          calorias: 100,
          fecha: DateTime.now().subtract(Duration(days: i * 2)),
        );
      }
      expect(state.xp, 2100);
      expect(state.nivel, 8);
      expect(state.nombreNivel, 'Avanzado');
      expect(state.progresoNivel, 0.0);
    });

    test('persistencia: XP, ledger diario y objetivo sobreviven al reinicio',
        () async {
      final state = AppState();
      await state.init();
      await sesionesConsecutivas(state, 5);
      final xpEsperado = state.xp;
      final ledgerEsperado = Map.of(state.xpPorDia);
      final objetivoEsperado = state.retoObjetivo;

      final state2 = AppState();
      await state2.init();
      expect(state2.xp, xpEsperado);
      expect(state2.xpPorDia, ledgerEsperado);
      expect(state2.retoObjetivo, objetivoEsperado);
    });

    test('export/import llevan la economía completa; reset la limpia',
        () async {
      final state = AppState();
      await state.init();
      await sesionesConsecutivas(state, 3);
      final snapshot = state.snapshotParaBackup();
      expect(snapshot['xp'], isA<int>());
      expect(snapshot['xp_por_dia'], isA<Map>());
      expect((snapshot['xp_por_dia'] as Map).isNotEmpty, isTrue);

      final state2 = AppState();
      await state2.init();
      await state2.aplicarBackup(snapshot);
      expect(state2.xp, state.xp);
      expect(state2.xpPorDia, state.xpPorDia);
      expect(state2.retoObjetivo, state.retoObjetivo);

      state2.resetTrasBorrado();
      expect(state2.xp, 0);
      expect(state2.xpPorDia, isEmpty);
      expect(state2.retoObjetivo, 3);
    });
  });

  group('F1 · teaser "Próxima insignia" en la cuadrícula', () {
    Future<void> pumpPerfil(
      WidgetTester tester,
      AppState state,
    ) async {
      final locale = LocaleService();
      await locale.init();
      final config = ConfigService();
      await config.init();
      AppColors.activate(darkFitPalette);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: state),
            ChangeNotifierProvider<LocaleService>.value(value: locale),
            ChangeNotifierProvider<ConfigService>.value(value: config),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('sin logros: el teaser es la primera insignia del catálogo',
        (tester) async {
      final state = AppState();
      await state.init();
      await pumpPerfil(tester, state);

      // La siguiente bloqueada (Primer paso) se realza de forma pasiva.
      expect(find.byKey(const Key('insignia_siguiente')), findsOneWidget);
      // El teaser es pasivo: sin barra de progreso numérica (cero presión).
      expect(
        find.descendant(
          of: find.byKey(const Key('insignia_siguiente')),
          matching: find.byType(LinearProgressIndicator),
        ),
        findsNothing,
      );
    });

    testWidgets('con 1 sesión: Primer paso conseguida, teaser = Constancia',
        (tester) async {
      final state = AppState();
      await state.init();
      await state.registrarSesionCompletada(
        nombre: 'Full Body',
        duracion: const Duration(minutes: 30),
        calorias: 180,
      );
      await pumpPerfil(tester, state);

      expect(find.text('1 / 9 insignias'), findsOneWidget);
      expect(find.text('Primer paso'), findsOneWidget);
      // La siguiente en orden de catálogo es Constancia (racha 3): su tile
      // lleva el teaser y no es un botón (sin InkWell).
      final teaser = find.byKey(const Key('insignia_siguiente'));
      expect(teaser, findsOneWidget);
      expect(
        find.descendant(
          of: teaser,
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: teaser,
          matching: find.byType(LinearProgressIndicator),
        ),
        findsNothing,
      );
    });
  });
}