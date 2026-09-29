import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/screens/tips_screen.dart';
import 'package:fitpulse/services/locale_service.dart';
import 'package:fitpulse/state/app_state.dart';
import 'package:fitpulse/theme.dart';

/// Fase 9: el chip de categoría seleccionado en Consejos usa `onPrimary`
/// (contraste WCAG correcto en claro Y oscuro), nunca blanco fijo.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('chip seleccionado de Consejos usa onPrimary (oscuro)', (tester) async {
    final locale = LocaleService();
    await locale.init();

    AppColors.activate(darkFitPalette);
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: AppState(),
        child: ChangeNotifierProvider<LocaleService>.value(
          value: locale,
          child: const MaterialApp(home: TipsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final texto = tester.widget<Text>(find.text('Todos'));
    expect(texto.style?.color, darkFitPalette.onPrimary,
        reason: 'en oscuro primary es verde claro: el texto del chip debe ser onPrimary');
  });

  testWidgets('chip seleccionado de Consejos usa onPrimary (claro)', (tester) async {
    final locale = LocaleService();
    await locale.init();

    AppColors.activate(lightFitPalette);
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: AppState(),
        child: ChangeNotifierProvider<LocaleService>.value(
          value: locale,
          child: const MaterialApp(home: TipsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final texto = tester.widget<Text>(find.text('Todos'));
    expect(texto.style?.color, lightFitPalette.onPrimary);
  });
}