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
    expect(find.textContaining('26 de octubre de 2026'), findsOneWidget);

    // El ListView con children: es perezoso: las secciones del final se crean
    // al desplazarse. Se recorre la lista en pasos para construirlas todas y
    // verificar el contenido íntegro sin depender del tamaño del viewport.
    await tester.scrollUntilVisible(find.textContaining('art. 9'), 200);
    expect(find.textContaining('art. 9'), findsWidgets);

    await tester.scrollUntilVisible(find.textContaining('art. 8'), 200);
    expect(find.textContaining('art. 8'), findsWidgets);

    // Publicidad: nombra a Google AdMob y su política (transparencia UE).
    await tester.scrollUntilVisible(find.text('7. Publicidad'), 200);
    expect(find.textContaining('AdMob'), findsWidgets);

    await tester.scrollUntilVisible(find.text('10. Enlaces a webs externas'), 200);
    expect(find.textContaining('NHS'), findsWidgets);

    await tester.scrollUntilVisible(find.text('11. Contacto'), 200);
    await tester.pumpAndSettle();
    expect(find.text('11. Contacto'), findsOneWidget);
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
    expect(find.textContaining('26 October 2026'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('10. External website links'), 200);
    expect(find.textContaining('NHS'), findsWidgets);

    await tester.scrollUntilVisible(find.text('11. Contact'), 200);
    await tester.pumpAndSettle();
    expect(find.text('11. Contact'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}