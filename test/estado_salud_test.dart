import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/services/locale_service.dart';
import 'package:fitpulse/state/app_state.dart';
import 'package:fitpulse/state/athlete_profile.dart';
import 'package:fitpulse/state/estado_salud.dart';
import 'package:fitpulse/theme.dart';
import 'package:fitpulse/widgets/estado_salud_card.dart';

/// P20: estado de salud honesto (Malo/Regular/Bueno/Excelente).
///
/// - Unit: `clasificarEstadoSalud` usa SOLO métricas con dato real; con menos
///   de 2 métricas responde "sin datos suficientes" (nunca inventa).
/// - Contraste: cada color de estado (claro y oscuro) cumple WCAG AA con el
///   texto que se pinta encima.
/// - Widget: con perfil + agua registrada muestra "Excelente" con su desglose;
///   con estado vacío muestra "Sin datos suficientes".
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('P20 · clasificador (honestidad)', () {
    test('con menos de 2 métricas con dato: sin datos suficientes', () {
      // Solo IMC: la app "no sabe" suficiente para opinar.
      final r = clasificarEstadoSalud(imc: 22.0, edad: 30);
      expect(r.sinDatos, isTrue);
      expect(r.estado, isNull);
      expect(r.metricas.length, 1);
    });

    test('sin ninguna métrica: sin datos suficientes', () {
      final r = clasificarEstadoSalud(
        imc: null,
        edad: null,
        pasos: null,
        gastoActivoKcal: null,
        suenio: null,
        aguaLitros: null,
      );
      expect(r.sinDatos, isTrue);
      expect(r.metricas, isEmpty);
    });

    test('IMC obeso + pocos pasos → malo (rojo)', () {
      final r = clasificarEstadoSalud(
        imc: 42.0, // ≥40 → 0 puntos
        edad: 30,
        pasos: 2500, // 2000–3999 → 1 punto → promedio 0.5
      );
      expect(r.sinDatos, isFalse);
      expect(r.estado, EstadoSalud.malo);
      expect(r.promedio, 0.5);
    });

    test('IMC obeso + pasos medios → regular (amarillo)', () {
      final r = clasificarEstadoSalud(
        imc: 42.0, // 0 puntos
        edad: 30,
        pasos: 5000, // 4000–7999 → 2 puntos → promedio 1.0
      );
      expect(r.estado, EstadoSalud.regular);
    });

    test('sobrepeso + pasos medios → bueno (verde)', () {
      final r = clasificarEstadoSalud(
        imc: 28.0, // 25–29,9 → 2 puntos
        edad: 30,
        pasos: 5000, // 2 puntos → promedio 2.0
      );
      expect(r.estado, EstadoSalud.bueno);
    });

    test('IMC normal + muchos pasos → excelente (azul)', () {
      final r = clasificarEstadoSalud(
        imc: 22.0, // 18,5–24,9 → 3 puntos
        edad: 30,
        pasos: 9000, // ≥8000 → 3 puntos → promedio 3.0
      );
      expect(r.estado, EstadoSalud.excelente);
      expect(r.promedio, 3.0);
    });

    test('umbral de pasos según edad (Paluch 2022)', () {
      // ≥60 años: el óptimo baja a 6000 pasos.
      final mayor = clasificarEstadoSalud(
        imc: 22.0,
        edad: 70,
        pasos: 7000, // ≥6000 → 3 puntos
      );
      expect(mayor.estado, EstadoSalud.excelente);

      final joven = clasificarEstadoSalud(
        imc: 22.0,
        edad: 30,
        pasos: 7000, // <8000 → 2 puntos → promedio 2.5
      );
      expect(joven.estado, EstadoSalud.excelente); // 2.5 sigue siendo excelente
    });

    test('gasto activo puntúa 3/2/1/0', () {
      int puntos(double kcal, {double? imc}) => clasificarEstadoSalud(
            imc: imc ?? 22.0,
            edad: 30,
            pasos: 9000,
            gastoActivoKcal: kcal,
          ).metricas
              .firstWhere((m) => m.metrica == MetricaEstado.gastoActivo)
              .puntos;
      expect(puntos(320), 3);
      expect(puntos(150), 2);
      expect(puntos(120), 1);
      expect(puntos(50), 1);
      expect(puntos(30), 0);
    });

    test('sueño puntúa 3/2/1/0 según horas', () {
      Duration h(int h) => Duration(hours: h);
      int puntos(Duration dur) => clasificarEstadoSalud(
            imc: 22.0,
            edad: 30,
            pasos: 9000,
            suenio: dur,
          ).metricas
              .firstWhere((m) => m.metrica == MetricaEstado.suenio)
              .puntos;
      expect(puntos(h(8)), 3);
      expect(puntos(h(6)), 2); // 6–7
      expect(puntos(Duration(hours: 5, minutes: 30)), 1); // 5–6
      expect(puntos(h(4)), 0); // <5
      expect(puntos(h(13)), 0); // >12
    });

    test('agua puntúa 3/2/1/0 según litros', () {
      int puntos(double litros) => clasificarEstadoSalud(
            imc: 22.0,
            edad: 30,
            pasos: 9000,
            aguaLitros: litros,
          ).metricas
              .firstWhere((m) => m.metrica == MetricaEstado.agua)
              .puntos;
      expect(puntos(3.0), 3);
      expect(puntos(1.5), 2);
      expect(puntos(1.0), 1);
      expect(puntos(0.2), 0);
    });

    test('los detalles son datos reales formateados, no inventados', () {
      final r = clasificarEstadoSalud(
        imc: 22.0,
        edad: 30,
        pasos: 9000,
        gastoActivoKcal: 312,
        suenio: const Duration(hours: 7, minutes: 30),
        aguaLitros: 2.0,
      );
      final det = {for (final m in r.metricas) m.metrica: m.detalle};
      expect(det[MetricaEstado.imc], '22.0');
      expect(det[MetricaEstado.pasos], '9000');
      expect(det[MetricaEstado.gastoActivo], '312 kcal');
      expect(det[MetricaEstado.suenio], '7h 30m');
      expect(det[MetricaEstado.agua], '2.0 L');
    });
  });

  group('P20 · color de cada estado (WCAG AA)', () {
    for (final estado in EstadoSalud.values) {
      for (final brillo in Brightness.values) {
        test('$estado en ${brillo.name}: texto ≥ 4.5:1 sobre su color', () {
          final c = colorEstadoSalud(estado, brillo);
          final on = onColorEstadoSalud(estado, brillo);
          final ratio = FitPalette.contraste(c, on);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason: '$ratio:1 para $estado (${brillo.name})',
          );
        });
      }
    }
  });

  group('P20 · tarjeta (Home/Perfil)', () {
    Future<void> pumpCard(WidgetTester tester, AppState state) async {
      final locale = LocaleService();
      await locale.init();
      AppColors.activate(lightFitPalette);
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: ChangeNotifierProvider<LocaleService>.value(
            value: locale,
            child: MaterialApp(
              home: Scaffold(body: Center(child: EstadoSaludCard())),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('estado vacío: "Sin datos suficientes" (no inventa)',
        (tester) async {
      final state = AppState();
      await state.init();
      await pumpCard(tester, state);

      expect(find.text('Sin datos suficientes'), findsOneWidget);
      expect(find.text('Excelente'), findsNothing);
      expect(find.text('Malo'), findsNothing);
    });

    testWidgets('perfil + agua real → "Excelente" con desglose',
        (tester) async {
      final state = AppState();
      await state.init();
      // IMC 22,9 (normal → 3 pts) + agua 2,5 L manual (3 pts) → promedio 3.
      await state.guardarPerfil(
        const AthleteProfile(pesoKg: 70, alturaM: 1.75),
      );
      await state.registrarAgua(2.5);
      await pumpCard(tester, state);

      expect(find.text('Excelente'), findsOneWidget);
      expect(find.text('IMC'), findsOneWidget);
      expect(find.text('Agua'), findsOneWidget);
      expect(find.textContaining('Basado en'), findsOneWidget);
      expect(find.text('Sin datos suficientes'), findsNothing);
    });
  });
}