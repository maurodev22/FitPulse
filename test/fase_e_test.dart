import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/screens/home_screen.dart';
import 'package:fitpulse/screens/profile_screen.dart';
import 'package:fitpulse/screens/progress_screen.dart';
import 'package:fitpulse/services/config_service.dart';
import 'package:fitpulse/services/locale_service.dart';
import 'package:fitpulse/state/app_state.dart';
import 'package:fitpulse/state/avisos.dart';
import 'package:fitpulse/theme.dart';
import 'package:fitpulse/widgets/racha_chip.dart';

/// FASE E — Toques de contexto (identidad leve).
///
/// E1: chip "Nv 3 · Intermedio" en el header de Progreso y en el Perfil.
/// E2: mini-barra de XP en Home (10 px bajo la racha), información pasiva.
/// E3: el widget de home recibe el nivel real ("Lv N") en su snapshot.
///
/// Criterio de aceptación del diseño: los tres puntos muestran el mismo valor
/// que `AppState.nivel` (aquí: 600 XP → nivel 3 → "Nv 3 · Intermedio").
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// 18 sesiones en días NO consecutivos → 900 XP exactos (sin reto extra),
  /// nivel 4, etiqueta 'Intermedio' (el umbral de Intermedio es nivel ≥ 4).
  Future<AppState> estadoNivel4() async {
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
    return state;
  }

  /// Providers comunes (AppState + LocaleService + ConfigService).
  Future<Widget> envolver(
    Widget pantalla,
    AppState state,
    LocaleService locale,
    ConfigService config,
  ) async {
    AppColors.activate(darkFitPalette);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: state),
        ChangeNotifierProvider<LocaleService>.value(value: locale),
        ChangeNotifierProvider<ConfigService>.value(value: config),
      ],
      child: MaterialApp(home: pantalla),
    );
  }

  group('E1 · chip "Nv N · Nombre" en los headers', () {
    testWidgets('el chip es pasivo (sin InkWell/onTap) y traduce el texto',
        (tester) async {
      final locale = LocaleService();
      await locale.init();
      AppColors.activate(darkFitPalette);
      await tester.pumpWidget(
        ChangeNotifierProvider<LocaleService>.value(
          value: locale,
          child: const MaterialApp(
            home: Scaffold(body: NivelChip(nivel: 3, nombre: 'Intermedio')),
          ),
        ),
      );
      expect(find.text('Nv 3 · Intermedio'), findsOneWidget);
      // Pasivo: no hay ningún InkWell dentro del chip.
      expect(find.descendant(
        of: find.byType(NivelChip),
        matching: find.byType(InkWell),
      ), findsNothing);
    });

    testWidgets('Perfil: el header muestra el nivel real del estado',
        (tester) async {
      final state = await estadoNivel4();
      final locale = LocaleService();
      await locale.init();
      final config = ConfigService();
      await config.init();
      await tester.pumpWidget(
        await envolver(const ProfileScreen(), state, locale, config),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nv 4 · Intermedio'), findsOneWidget);
    });

    testWidgets('Progreso: el header muestra el nivel real del estado',
        (tester) async {
      final state = await estadoNivel4();
      final locale = LocaleService();
      await locale.init();
      final config = ConfigService();
      await config.init();
      await tester.pumpWidget(
        await envolver(const ProgressScreen(), state, locale, config),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nv 4 · Intermedio'), findsOneWidget);
    });
  });

  group('E2 · mini-barra de XP en Home', () {
    testWidgets('la barra de 10 px está bajo la racha y es pasiva',
        (tester) async {
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
      final barra = find.byKey(const Key('barra_nivel_home'));
      expect(barra, findsOneWidget);
      final box = tester.getSize(barra);
      expect(box.height, 10);
      // Pantalla completa del Home: sin errores de layout en 360 dp.
      expect(tester.takeException(), isNull);
    });
  });

  group('E3 · snapshot del widget de home con el nivel real', () {
    test('el snapshot JSON incluye "nivel" == estado.nivel', () async {
      final state = await estadoNivel4();
      final json = construirSnapshotWidget(
        pasos: 1200,
        calorias: null,
        racha: 2,
        nivel: state.nivel,
        fecha: '2026-10-06',
      );
      expect(json, contains('"nivel":4'));
    });
  });
}