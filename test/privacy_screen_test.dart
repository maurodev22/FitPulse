import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/screens/privacy_screen.dart';
import 'package:fitpulse/services/locale_service.dart';
import 'package:fitpulse/theme.dart';

/// Fase 8: la política de privacidad (8.2) se renderiza completa, sin
/// overflows, en es (idioma por defecto que buscan los tests) y en en.
void main() {
  setUp(() {
    AppColors.activate(lightFitPalette);
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Política de privacidad se renderiza íntegra (es)',
      (WidgetTester tester) async {
    final locale = LocaleService();
    await locale.init();
    await tester.pumpWidget(
      ChangeNotifierProvider<LocaleService>.value(
        value: locale,
        child: const MaterialApp(home: PrivacyScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Política de privacidad'), findsWidgets);
    expect(find.textContaining('RGPD'), findsWidgets);
    expect(find.textContaining('art. 9'), findsWidgets);
    expect(find.textContaining('art. 8'), findsWidgets);

    // Recorre toda la lista para asegurar que no hay desbordes ni roturas.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(find.text('9. Contacto'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Política de privacidad se renderiza íntegra (en)',
      (WidgetTester tester) async {
    final locale = LocaleService();
    await locale.init();
    await locale.setLocale(AppLocale.en);
    await tester.pumpWidget(
      ChangeNotifierProvider<LocaleService>.value(
        value: locale,
        child: const MaterialApp(home: PrivacyScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Privacy policy'), findsWidgets);
    expect(find.textContaining('GDPR'), findsWidgets);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(find.text('9. Contact'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}