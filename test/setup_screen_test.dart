import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/screens/setup_screen.dart';
import 'package:fitpulse/services/config_service.dart';
import 'package:fitpulse/services/locale_service.dart';
import 'package:fitpulse/state/app_state.dart';
import 'package:fitpulse/theme.dart';

/// P17: la configuración inicial ligera (tema con vista previa + avisos
/// opt-in) que aparece una sola vez tras el registro.
///
/// Verifica que:
/// - Renderiza las tres opciones de tema y los dos toggles de avisos (en es).
/// - Elegir un tema lo persiste al instante en ConfigService.
/// - "Continuar" guarda los toggles en el perfil y entra al dashboard.
/// - "Ahora no" entra al dashboard sin pedir nada (no toca el perfil).
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpSetup(
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
          darkTheme: buildFitPulseTheme(brightness: Brightness.dark),
          home: const SetupScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('P17: muestra tema (3 opciones) y avisos opt-in', (tester) async {
    final state = AppState();
    await state.init();
    final locale = LocaleService();
    await locale.init();
    final config = ConfigService();
    await config.init();

    await pumpSetup(tester, state: state, locale: locale, config: config);

    expect(find.text('Personaliza FitPulse'), findsOneWidget);
    expect(find.text('Tema'), findsOneWidget);
    expect(find.text('Sistema'), findsOneWidget);
    expect(find.text('Claro'), findsOneWidget);
    expect(find.text('Oscuro'), findsOneWidget);
    expect(find.text('Avisos (opcional)'), findsOneWidget);
    // Los toggles opt-in salen con el estado real del perfil (activos).
    expect(find.text('Recordatorios de hidratación'), findsOneWidget);
    expect(find.text('Aviso de racha en riesgo'), findsOneWidget);
    // La nota es honesta: sin permiso no se programa nada.
    expect(find.textContaining('permiso de notificaciones'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
    expect(find.text('Ahora no'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('P17: elegir tema lo aplica y persiste al instante',
      (tester) async {
    final state = AppState();
    await state.init();
    final locale = LocaleService();
    await locale.init();
    final config = ConfigService();
    await config.init();

    await pumpSetup(tester, state: state, locale: locale, config: config);

    await tester.tap(find.text('Oscuro'));
    await tester.pumpAndSettle();

    expect(config.themeMode, AppThemeMode.dark);

    await tester.tap(find.text('Claro'));
    await tester.pumpAndSettle();
    expect(config.themeMode, AppThemeMode.light);
  });

  testWidgets('P17: Continuar guarda los toggles y entra al dashboard',
      (tester) async {
    final state = AppState();
    await state.init();
    final locale = LocaleService();
    await locale.init();
    final config = ConfigService();
    await config.init();

    await pumpSetup(tester, state: state, locale: locale, config: config);

    // Apaga los dos avisos opt-in (el perfil por defecto los trae activos).
    // Se hace scroll para que cada Switch quede dentro del viewport: un tap
    // fuera de él caería sobre el footer y navegaría por accidente.
    final primerSwitch = find.byType(Switch).first;
    await tester.ensureVisible(primerSwitch);
    await tester.pumpAndSettle();
    await tester.tap(primerSwitch);
    await tester.pumpAndSettle();
    final ultimoSwitch = find.byType(Switch).last;
    await tester.ensureVisible(ultimoSwitch);
    await tester.pumpAndSettle();
    await tester.tap(ultimoSwitch);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    // El perfil guardado refleja lo elegido (no lo que traía por defecto).
    expect(state.profile.hidratacion, isFalse);
    expect(state.profile.entrenamientoMatutino, isFalse);
    // Ya no está la configuración inicial: se entró al dashboard.
    expect(find.text('Personaliza FitPulse'), findsNothing);
  });

  testWidgets('P17: "Ahora no" entra al dashboard sin tocar el perfil',
      (tester) async {
    final state = AppState();
    await state.init();
    final locale = LocaleService();
    await locale.init();
    final config = ConfigService();
    await config.init();

    await pumpSetup(tester, state: state, locale: locale, config: config);

    final primerSwitch = find.byType(Switch).first;
    await tester.ensureVisible(primerSwitch);
    await tester.pumpAndSettle();
    await tester.tap(primerSwitch);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ahora no'));
    await tester.pumpAndSettle();

    // Los toggles no se guardan: el perfil sigue con sus valores previos.
    expect(state.profile.hidratacion, isTrue);
    expect(find.text('Personaliza FitPulse'), findsNothing);
  });
}