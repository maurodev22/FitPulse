import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/services/locale_service.dart';
import 'package:fitpulse/state/registro_diario.dart';
import 'package:fitpulse/theme.dart';
import 'package:fitpulse/widgets/cumplimiento_chart.dart';

/// El gráfico de cumplimiento muestra barras reales, marca los días sin dato y
/// abre el detalle al tocar una barra. Sin datos no inventa ceros.
void main() {
  setUp(() {
    AppColors.activate(lightFitPalette);
    SharedPreferences.setMockInitialValues({});
  });

  DateTime hoy() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  Widget envolver(Widget child) {
    final locale = LocaleService();
    return ChangeNotifierProvider<LocaleService>.value(
      value: locale,
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  const metas = MetasDia(pasos: 10000, agua: 2.5, calorias: 2000);

  testWidgets('sin historial no dibuja barras con ceros: avisa y deja importar',
      (tester) async {
    final locale = LocaleService();
    await locale.init();
    var importado = false;

    await tester.pumpWidget(
      ChangeNotifierProvider<LocaleService>.value(
        value: locale,
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CumplimientoChart(
                registros: const [],
                metas: metas,
                diasEntreno: const {1, 2, 3, 4, 5},
                escala: EscalaSerie.diaria,
                onImportar: () async {
                  importado = true;
                  return 3;
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Aún no hay historial'), findsOneWidget);
    expect(find.text('Rellenar con Health Connect'), findsOneWidget);
    expect(find.text('Cumplimiento de metas'), findsOneWidget);

    await tester.tap(find.text('Rellenar con Health Connect'));
    await tester.pumpAndSettle();
    expect(importado, isTrue);
    expect(find.textContaining('3 días importados'), findsOneWidget);
  });

  testWidgets('con datos muestra la media, los días con dato y las barras',
      (tester) async {
    final locale = LocaleService();
    await locale.init();
    final hoyDia = hoy();

    await tester.pumpWidget(envolver(CumplimientoChart(
      registros: [
        RegistroDiario(dia: hoyDia, pasos: 10000, agua: 2.5),
        RegistroDiario(
          dia: hoyDia.subtract(const Duration(days: 1)),
          pasos: 5000,
        ),
      ],
      metas: metas,
      diasEntreno: const {1, 2, 3, 4, 5},
      escala: EscalaSerie.diaria,
    )));
    await tester.pumpAndSettle();

    // Dos días con dato; la media de (100 % y 50 %) = 75 %.
    expect(find.text('75 %'), findsOneWidget);
    expect(find.textContaining('2 días con dato'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tocar una barra abre el detalle con los valores reales',
      (tester) async {
    final locale = LocaleService();
    await locale.init();
    final hoyDia = hoy();

    await tester.pumpWidget(envolver(CumplimientoChart(
      registros: [
        RegistroDiario(
          dia: hoyDia,
          pasos: 8000,
          agua: 1.5,
          kcal: 1800,
          entrenoMin: 30,
        ),
      ],
      metas: metas,
      diasEntreno: const {1, 2, 3, 4, 5, 6, 7},
      escala: EscalaSerie.diaria,
    )));
    await tester.pumpAndSettle();

    // El detalle arranca cerrado.
    expect(find.text('Detalle del día'), findsNothing);

    // Se toca la última barra (la de hoy).
    await tester.tap(find.byType(InkWell).last);
    await tester.pumpAndSettle();

    expect(find.text('8000 / 10000'), findsOneWidget);
    expect(find.text('1.5 L / 2.5 L'), findsOneWidget);
    expect(find.text('1800 / 2000'), findsOneWidget);
    expect(find.text('30 min'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('los filtros por métrica cambian la medida de las barras',
      (tester) async {
    final locale = LocaleService();
    await locale.init();
    final hoyDia = hoy();

    await tester.pumpWidget(envolver(CumplimientoChart(
      registros: [
        RegistroDiario(dia: hoyDia, pasos: 5000, agua: 2.5),
      ],
      metas: metas,
      diasEntreno: const {1, 2, 3, 4, 5},
      escala: EscalaSerie.diaria,
    )));
    await tester.pumpAndSettle();

    // "Todo": media de pasos (50 %) y agua (100 %) = 75 %.
    expect(find.text('75 %'), findsOneWidget);

    await tester.tap(find.text('Pasos').first);
    await tester.pumpAndSettle();
    expect(find.text('50 %'), findsOneWidget);

    await tester.tap(find.text('Agua').first);
    await tester.pumpAndSettle();
    expect(find.text('100 %'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('aguanta el texto al doble de tamaño sin desbordar',
      (tester) async {
    final locale = LocaleService();
    await locale.init();
    final hoyDia = hoy();

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: ChangeNotifierProvider<LocaleService>.value(
          value: locale,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CumplimientoChart(
                  registros: [
                    RegistroDiario(
                      dia: hoyDia,
                      pasos: 12000,
                      agua: 3,
                      kcal: 2200,
                      entrenoMin: 45,
                    ),
                  ],
                  metas: metas,
                  diasEntreno: const {1, 2, 3, 4, 5, 6, 7},
                  escala: EscalaSerie.mensual,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
