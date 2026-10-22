import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/screens/home_screen.dart';
import 'package:fitpulse/services/locale_service.dart';
import 'package:fitpulse/state/app_state.dart';
import 'package:fitpulse/theme.dart';

/// El botón "Comenzar entrenamiento" lleva un borde de contraste que cambia
/// con el tema: blanco en oscuro, negro en claro.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpHome(WidgetTester tester, Brightness brightness) async {
    final palette =
        brightness == Brightness.dark ? darkFitPalette : lightFitPalette;
    AppColors.activate(palette);

    final state = AppState();
    await state.init();
    final locale = LocaleService();
    await locale.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: state),
          ChangeNotifierProvider<LocaleService>.value(value: locale),
        ],
        child: MaterialApp(
          theme: buildFitPulseTheme(brightness: brightness),
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  BorderSide bordeDe(WidgetTester tester) {
    final material = tester.widget<Material>(
      find
          .ancestor(
            of: find.text('Comenzar entrenamiento'),
            matching: find.byType(Material),
          )
          .first,
    );
    final shape = material.shape;
    expect(shape, isA<RoundedRectangleBorder>());
    return (shape as RoundedRectangleBorder).side;
  }

  testWidgets('tema claro: borde negro', (tester) async {
    await pumpHome(tester, Brightness.light);

    final side = bordeDe(tester);
    expect(side.color, Colors.black);
    expect(side.width, 1.5);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tema oscuro: borde blanco', (tester) async {
    await pumpHome(tester, Brightness.dark);

    final side = bordeDe(tester);
    expect(side.color, Colors.white);
    expect(side.width, 1.5);
    expect(tester.takeException(), isNull);
  });
}
