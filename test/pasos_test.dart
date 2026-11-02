import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/services/health_service.dart';
import 'package:fitpulse/state/app_state.dart';

/// Contador de pasos falso: emite el valor crudo del sensor cuando el test
/// quiere (como haría `TYPE_STEP_COUNTER`).
class _FuenteFalsa implements HealthDataSource {
  final StreamController<int> _controller = StreamController<int>.broadcast();

  @override
  bool get isAvailable => true;

  @override
  Stream<int> get stepStream => _controller.stream;

  void emitir(int raw) => _controller.add(raw);

  @override
  void dispose() {
    _controller.close();
  }
}

String _clave(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Conteo de pasos: reglas que evitan los dos fallos clásicos.
///
/// - La base guardada solo vale si es de HOY (una base de ayer suma pasos de
///   más o de menos, porque el contador del sistema no se reinicia a medianoche).
/// - Al reabrir la app no se muestra 0: se restauran los pasos ya contados hoy.
/// - Health Connect manda cuando tiene más pasos que el sensor local.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('pasosVisiblesDelDia', () {
    test('usa Health Connect cuando supera al sensor', () {
      expect(pasosVisiblesDelDia(sensor: 300, healthConnect: 5000), 5000);
    });

    test('mantiene el sensor si ya superó a Health Connect', () {
      expect(pasosVisiblesDelDia(sensor: 5200, healthConnect: 5000), 5200);
    });

    test('sin dato de Health Connect (0) usa el sensor', () {
      expect(pasosVisiblesDelDia(sensor: 742, healthConnect: 0), 742);
    });

    test('nunca devuelve negativos', () {
      expect(pasosVisiblesDelDia(sensor: -10, healthConnect: -5), 0);
    });
  });

  group('AppState · pasos del día', () {
    test('restaura los pasos de hoy al reabrir la app (no 0)', () async {
      final hoy = _clave(DateTime.now());
      SharedPreferences.setMockInitialValues({
        'fitpulse_balance_date_v1': hoy,
        'fitpulse_pasos_base_v1': 1000,
        'fitpulse_pasos_base_date_v1': hoy,
        'fitpulse_pasos_hoy_v1': 540,
        'fitpulse_pasos_hoy_date_v1': hoy,
      });

      final state = AppState();
      await state.init();

      expect(state.pasosHoy, 540);
    });

    test('descarta la base de ayer y cuenta desde el primer paso de hoy',
        () async {
      final hoy = _clave(DateTime.now());
      final ayer = _clave(DateTime.now().subtract(const Duration(days: 1)));
      SharedPreferences.setMockInitialValues({
        'fitpulse_balance_date_v1': hoy,
        // Base de ayer: si se usara, el contador arrastraría pasos de ayer.
        'fitpulse_pasos_base_v1': 1000,
        'fitpulse_pasos_base_date_v1': ayer,
        'fitpulse_pasos_hoy_v1': 540,
        'fitpulse_pasos_hoy_date_v1': ayer,
      });

      final state = AppState();
      await state.init();
      final fuente = _FuenteFalsa();
      state.attachHealthSource(fuente);
      addTearDown(fuente.dispose);

      expect(state.pasosHoy, 0);

      // El contador del sistema vale 12000 (viene de días anteriores): la base
      // de hoy arranca aquí, no en 1000.
      fuente.emitir(12000);
      await Future<void>.delayed(Duration.zero);
      expect(state.pasosHoy, 0);

      fuente.emitir(12050);
      await Future<void>.delayed(Duration.zero);
      expect(state.pasosHoy, 50);
    });

    test('persiste los pasos para la siguiente apertura', () async {
      final hoy = _clave(DateTime.now());
      SharedPreferences.setMockInitialValues({
        'fitpulse_balance_date_v1': hoy,
      });

      final state = AppState();
      await state.init();
      final fuente = _FuenteFalsa();
      state.attachHealthSource(fuente);

      fuente.emitir(2000); // Primera lectura: base de hoy.
      await Future<void>.delayed(Duration.zero);

      fuente.emitir(2100); // 100 pasos → se guardan.
      await Future<void>.delayed(Duration.zero);
      expect(state.pasosHoy, 100);

      final state2 = AppState();
      await state2.init();
      expect(state2.pasosHoy, 100);

      fuente.dispose();
    });

    test('el registro de hoy no marca 0 pasos si aún no hay dato', () async {
      SharedPreferences.setMockInitialValues({});
      final state = AppState();
      await state.init();

      expect(state.pasosHoy, 0);
      expect(state.registroHoy.pasos, isNull, reason: 'sin dato no es 0');
      expect(state.registroHoy.pasosParciales, isFalse);
    });
  });
}
