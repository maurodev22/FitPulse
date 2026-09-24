import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/services/health_service.dart';
import 'package:fitpulse/services/usage_log_service.dart';
import 'package:fitpulse/state/app_state.dart';

/// Fuente simulada de pasos para probar AppState sin tocar la plataforma.
class _TestHealthSource extends HealthDataSource {
  final StreamController<int> _ctrl = StreamController<int>.broadcast();
  bool _available = true;

  @override
  bool get isAvailable => _available;

  @override
  Stream<int> get stepStream => _ctrl.stream;

  @override
  void dispose() {
    _available = false;
    _ctrl.close();
  }

  void emit(int steps) => _ctrl.add(steps);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppState · reinicio diario', () {
    test('un balance de ayer se vacía al iniciar (reinicio por fecha)',
        () async {
      // Simula que ayer se registraron 500 kcal y hoy ya es otro día.
      final _ = await SharedPreferences.getInstance();
      SharedPreferences.setMockInitialValues({
        'fitpulse_calorias_v1': 500.0,
        'fitpulse_caloriasMeta_v1': 650.0,
        'fitpulse_balance_date_v1': '2000-01-01',
      });

      final state = AppState();
      await state.init();

      expect(state.caloriasConsumidas, 0);
    });

    test('un balance del mismo día se conserva al iniciar', () async {
      final today = _isoToday();
      SharedPreferences.setMockInitialValues({
        'fitpulse_calorias_v1': 500.0,
        'fitpulse_balance_date_v1': today,
      });

      final state = AppState();
      await state.init();

      expect(state.caloriasConsumidas, 500);
    });

    test('al rebasificar un día nuevo el contador de pasos vuelve a cero',
        () async {
      SharedPreferences.setMockInitialValues({
        'fitpulse_balance_date_v1': '2000-01-01',
      });

      final state = AppState();
      await state.init();
      final source = _TestHealthSource();
      state.attachHealthSource(source);

      // Primera marca del día: baseline 200, pasos de hoy 0.
      source.emit(200);
      await _pump();
      expect(state.healthDisponible, isTrue);
      expect(state.pasosHoy, 0);

      // El sensor avanza: pasos de hoy 350 (200 -> 550).
      source.emit(550);
      await _pump();
      expect(state.pasosHoy, 350);

      source.dispose();
    });
  });

  group('UsageLogService', () {
    test('registra eventos y los conserva en el orden correcto', () async {
      SharedPreferences.setMockInitialValues({});
      final log = UsageLogService();
      await log.init();

      await log.log('app', 'inicio');
      await log.log('navegacion', 'recetas', detail: 'Recetas');
      await log.log('perfil', 'guardar');

      final entries = await log.entries();
      expect(entries, hasLength(3));
      expect(entries[0]['c'], 'app');
      expect(entries[1]['d'], 'Recetas');
      expect(entries[2]['a'], 'guardar');
    });

    test('acota el tamaño del registro descartando lo más antiguo', () async {
      SharedPreferences.setMockInitialValues({});
      final log = UsageLogService();
      await log.init();

      for (var i = 0; i < 205; i++) {
        await log.log('navegacion', 'tab_$i');
      }
      final entries = await log.entries();
      expect(entries.length, lessThanOrEqualTo(200));
      // Los primeros quedaron fuera; el último se conserva.
      expect(entries.first['a'], 'tab_5');
      expect(entries.last['a'], 'tab_204');
    });

    test('clear() vacía el registro', () async {
      SharedPreferences.setMockInitialValues({});
      final log = UsageLogService();
      await log.init();
      await log.log('app', 'inicio');
      await log.clear();
      expect(await log.entries(), isEmpty);
    });
  });
}

String _isoToday() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

Future<void> _pump() => Future<void>.delayed(Duration.zero);