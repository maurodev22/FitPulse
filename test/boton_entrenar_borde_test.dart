import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/services/config_service.dart';
import 'package:fitpulse/services/locale_service.dart';
import 'package:fitpulse/state/app_state.dart';
import 'package:fitpulse/theme.dart';
import 'package:fitpulse/widgets/boton_entrenar.dart';

/// El botón flotante "Entrenar" lleva un marco de contraste que cambia con el
/// tema: blanco en oscuro, negro en claro.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpFab(WidgetTester tester, Brightness brightness) async {
    final palette =
        brightness == Brightness.dark ? darkFitPalette : lightFitPalette;
    AppColors.activate(palette);

    final state = AppState();
    await state.init();
    final locale = LocaleService();
    await locale.init();
    final config = ConfigService();
    await config.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: state),
          ChangeNotifierProvider<LocaleService>.value(value: locale),
          ChangeNotifierProvider<ConfigService>.value(value: config),
        ],
        child: MaterialApp(
          theme: buildFitPulseTheme(brightness: brightness),
          home: const Scaffold(floatingActionButton: BotonEntrenar()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  BorderSide bordeDe(WidgetTester tester) {
    final fab = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    final shape = fab.shape;
    expect(shape, isA<RoundedRectangleBorder>());
    return (shape as RoundedRectangleBorder).side;
  }

  testWidgets('tema claro: marco negro en el FAB', (tester) async {
    await pumpFab(tester, Brightness.light);

    final side = bordeDe(tester);
    expect(side.color, Colors.black);
    expect(side.width, 1.5);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tema oscuro: marco blanco en el FAB', (tester) async {
    await pumpFab(tester, Brightness.dark);

    final side = bordeDe(tester);
    expect(side.color, Colors.white);
    expect(side.width, 1.5);
    expect(tester.takeException(), isNull);
  });
}
