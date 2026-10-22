import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/screens/tips_screen.dart';
import 'package:fitpulse/services/locale_service.dart';
import 'package:fitpulse/state/app_state.dart';
import 'package:fitpulse/theme.dart';

/// Consejos: cada artículo y cada tarjeta declara una fuente oficial real
/// (NHS, OMS o Sleep Foundation) y enlaza a la página original.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppColors.activate(lightFitPalette);
  });

  Future<LocaleService> pumpTips(WidgetTester tester) async {
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
        child: const MaterialApp(home: TipsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return locale;
  }

  testWidgets('el catálogo cita fuente y enlace https en los 4 artículos',
      (tester) async {
    final locale = await pumpTips(tester);
    final catalogo = catalogoArticulos(locale.strings);

    expect(catalogo, hasLength(4));
    for (final articulo in catalogo) {
      expect(articulo.fuente, isNotEmpty,
          reason: '${articulo.titulo} debe citar su fuente');
      expect(articulo.urlFuente, startsWith('https://'));
      // El tiempo de lectura sale del texto real, nunca es un número fijo.
      expect(articulo.min, greaterThanOrEqualTo(1));
    }

    // Las tres fuentes que usa el catálogo son las verificadas.
    final fuentes = catalogo.map((a) => a.fuente).toSet();
    expect(fuentes, containsAll(<String>['NHS', 'Sleep Foundation', 'OMS']));
  });

  testWidgets('las tarjetas de alto impacto muestran su fuente',
      (tester) async {
    await pumpTips(tester);

    expect(find.text('HOY • DESTACADO'), findsOneWidget);
    expect(find.text('Fuente: NHS'), findsNWidgets(2));
    expect(find.text('Fuente: Sleep Foundation'), findsOneWidget);
    // El corazón decorativo que no hacía nada ya no está.
    expect(find.byIcon(Icons.favorite_border), findsNothing);
  });

  testWidgets('el detalle muestra la fuente y el botón para abrirla',
      (tester) async {
    final locale = await pumpTips(tester);
    final destacado = catalogoArticulos(locale.strings).first;

    await tester.tap(find.text(destacado.titulo));
    await tester.pumpAndSettle();

    expect(find.text('Fuente: Sleep Foundation'), findsOneWidget);
    expect(find.text(destacado.urlFuente), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Ver fuente'), findsOneWidget);
  });
}
