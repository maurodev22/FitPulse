import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/screens/progress_screen.dart';
import 'package:fitpulse/services/config_service.dart';
import 'package:fitpulse/services/locale_service.dart';
import 'package:fitpulse/state/app_state.dart';
import 'package:fitpulse/state/registro_diario.dart';
import 'package:fitpulse/theme.dart';

/// El gráfico de cumplimiento está realmente montado en Progreso y sale de los
/// datos reales del histórico diario.
void main() {
  setUp(() {
    AppColors.activate(lightFitPalette);
  });

  Future<Widget> pantalla(AppState state) async {
    final locale = LocaleService();
    await locale.init();
    final config = ConfigService();
    await config.init();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: state),
        ChangeNotifierProvider<LocaleService>.value(value: locale),
        ChangeNotifierProvider<ConfigService>.value(value: config),
      ],
      child: const MaterialApp(home: ProgressScreen()),
    );
  }

  testWidgets('Progreso muestra el gráfico de metas con el histórico real',
      (tester) async {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    String clave(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

    SharedPreferences.setMockInitialValues({
      'fitpulse_registro_diario_v1': [
        jsonEncode(RegistroDiario(
          dia: hoy,
          pasos: 10000, // meta por defecto = 10.000
        ).toJson()),
        jsonEncode(RegistroDiario(
          dia: hoy.subtract(const Duration(days: 1)),
          pasos: 5000,
        ).toJson()),
      ],
      'fitpulse_balance_date_v1': clave(hoy),
    });

    final state = AppState();
    await state.init();
    expect(state.registroDelDia(hoy.subtract(const Duration(days: 1)))!.pasos,
        5000);

    await tester.pumpWidget(await pantalla(state));
    await tester.pumpAndSettle();

    // La tarjeta del gráfico y sus filtros están en la pantalla.
    expect(find.text('Cumplimiento de metas'), findsOneWidget);
    expect(find.text('Todo'), findsOneWidget);
    expect(find.text('Pasos'), findsWidgets);
    expect(find.text('Agua'), findsWidgets);
    expect(find.text('Calorías'), findsWidgets);
    expect(find.text('Entreno'), findsWidgets);

    // Media real: hoy 100 % y ayer 50 % → 75 %.
    expect(find.text('75 %'), findsOneWidget);
    expect(find.textContaining('2 días con dato'), findsOneWidget);

    // Toque en una barra: abre el detalle con los valores reales del día.
    final barra = find.byWidgetPredicate((w) =>
        w is Semantics && (w.properties.label ?? '').startsWith('J: 100'));
    expect(barra, findsOneWidget, reason: 'la barra de hoy debe existir');
    await tester.tap(barra);
    await tester.pumpAndSettle();

    expect(find.text('10000 / 10000'), findsOneWidget);
    expect(find.textContaining('días con dato'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Progreso sin histórico no inventa barras y no desborda',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.init();

    tester.view.physicalSize = const Size(360 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(await pantalla(state));
    await tester.pumpAndSettle();

    expect(find.text('Cumplimiento de metas'), findsOneWidget);
    expect(find.textContaining('Aún no hay historial'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
