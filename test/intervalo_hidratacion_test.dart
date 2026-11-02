import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/screens/configuracion_screen.dart';
import 'package:fitpulse/services/config_service.dart';
import 'package:fitpulse/services/locale_service.dart';
import 'package:fitpulse/state/app_state.dart';
import 'package:fitpulse/theme.dart';

/// Intervalo configurable del aviso de hidratación (Ajustes → Preferencias).
///
/// Reglas:
/// - Por defecto 1 hora (la app ya lo hacía así).
/// - Solo se aceptan los valores ofrecidos (30 min – 4 h); otro valor cae en 1 h.
/// - Se persiste en el dispositivo y viaja en el backup.
/// - El submenú de Ajustes cambia el intervalo y reprograma el aviso.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ConfigService · intervalo de hidratación', () {
    test('por defecto es 1 hora', () async {
      final config = ConfigService();
      await config.init();

      expect(config.aguaIntervaloMinutos, 60);
      expect(config.aguaIntervalo, const Duration(hours: 1));
    });

    test('persiste el intervalo elegido', () async {
      final config = ConfigService();
      await config.init();
      await config.setAguaIntervaloMinutos(120);

      expect(config.aguaIntervaloMinutos, 120);
      expect(config.aguaIntervalo, const Duration(hours: 2));

      final config2 = ConfigService();
      await config2.init();
      expect(config2.aguaIntervaloMinutos, 120);
    });

    test('un valor no permitido cae en 1 hora', () async {
      final config = ConfigService();
      await config.init();
      await config.setAguaIntervaloMinutos(7);

      expect(config.aguaIntervaloMinutos, 60);
      expect(ConfigService.intervalosAguaMinutos, contains(30));
      expect(ConfigService.intervalosAguaMinutos, contains(240));
    });

    test('el backup guarda y restaura el intervalo', () async {
      final config = ConfigService();
      await config.init();
      await config.setAguaIntervaloMinutos(180);
      final snap = config.snapshotParaBackup();

      expect(snap['agua_intervalo_min'], 180);

      final config2 = ConfigService();
      await config2.init();
      await config2.aplicarBackup(snap);
      expect(config2.aguaIntervaloMinutos, 180);

      config2.resetTrasBorrado();
      expect(config2.aguaIntervaloMinutos, 60);
    });
  });

  group('Ajustes · submenú "cada cuánto"', () {
    Future<void> pumpAjustes(
      WidgetTester tester, {
      required AppState state,
      required LocaleService locale,
      required ConfigService config,
    }) async {
      AppColors.activate(darkFitPalette);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: state),
            ChangeNotifierProvider<LocaleService>.value(value: locale),
            ChangeNotifierProvider<ConfigService>.value(value: config),
          ],
          child: MaterialApp(
            theme: buildFitPulseTheme(brightness: Brightness.light),
            home: const ConfiguracionScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('muestra el intervalo actual y permite cambiarlo',
        (tester) async {
      final state = AppState();
      await state.init();
      final locale = LocaleService();
      await locale.init();
      final config = ConfigService();
      await config.init();

      await pumpAjustes(
        tester,
        state: state,
        locale: locale,
        config: config,
      );

      // Fila del submenú con el valor real (1 hora por defecto).
      expect(find.text('Intervalo de hidratación'), findsOneWidget);
      expect(find.text('1 hora'), findsOneWidget);

      await tester.tap(find.text('Intervalo de hidratación'));
      await tester.pumpAndSettle();

      // Opciones ofrecidas.
      expect(find.text('30 minutos'), findsOneWidget);
      expect(find.text('2 horas'), findsOneWidget);
      expect(find.text('4 horas'), findsOneWidget);

      await tester.tap(find.text('2 horas'));
      await tester.pumpAndSettle();

      expect(config.aguaIntervaloMinutos, 120);
      expect(find.text('2 horas'), findsOneWidget);
      expect(find.text('Cada 2 horas · notificación local'), findsOneWidget);
    });

    testWidgets('con el aviso apagado el submenú no se muestra',
        (tester) async {
      final state = AppState();
      await state.init();
      // Perfil con la hidratación apagada.
      state.guardarPerfil(state.profile.copyWith(hidratacion: false));
      final locale = LocaleService();
      await locale.init();
      final config = ConfigService();
      await config.init();

      await pumpAjustes(
        tester,
        state: state,
        locale: locale,
        config: config,
      );

      expect(find.text('Recordatorios de hidratación'), findsOneWidget);
      expect(find.text('Intervalo de hidratación'), findsNothing);
    });
  });
}
