import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/services/config_service.dart';
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

  group('Fase 1 · Health Connect (métricas reales)', () {
    test('al conectar, el estado expone las métricas de hoy', () async {
      SharedPreferences.setMockInitialValues({});
      final state = AppState();
      await state.init();

      state.setHealthConnect(_FakeHealthConnect(
        datos: const HealthToday(
          funciono: true,
          pulsoBpm: 72,
          pesoKg: 70.5,
          grasaPct: 18.2,
          aguaLitros: 1.8,
          gastoActivoKcal: 420.0,
          tiempoActivoMin: 35,
          metricasConPermiso: {
            HealthMetricas.pulso,
            HealthMetricas.peso,
            HealthMetricas.grasa,
            HealthMetricas.agua,
            HealthMetricas.gastoActivo,
            HealthMetricas.tiempoActivo,
          },
        ),
      ));

      await state.initHealthConnect();

      expect(state.healthConnectDisponible, isTrue);
      expect(state.healthConnectConectado, isTrue);
      expect(state.pulsoHoy, 72);
      expect(state.pesoMedidoKg, 70.5);
      expect(state.grasaHoy, 18.2);
      expect(state.aguaHoy, 1.8);
      expect(state.gastoActivoHoy, 420.0);
      expect(state.tiempoActivoMin, 35);
      expect(state.pulsoConPermiso, isTrue);
      expect(state.aguaConPermiso, isTrue);
      expect(state.suenioConPermiso, isFalse);
    });

    test('sin permisos concedidos las métricas quedan "sin dato"', () async {
      SharedPreferences.setMockInitialValues({});
      final state = AppState();
      await state.init();

      state.setHealthConnect(_FakeHealthConnect(
        datos: const HealthToday(funciono: true, metricasConPermiso: {}),
      ));
      await state.initHealthConnect();

      expect(state.healthConnectConectado, isTrue);
      expect(state.pulsoHoy, isNull);
      expect(state.grasaHoy, isNull);
      expect(state.pulsoConPermiso, isFalse);
    });
  });

  group('Fase 2 · historial, racha, puntos y retos', () {
    test('registrar una sesión suma puntos y persiste', () async {
      SharedPreferences.setMockInitialValues({});
      final state = AppState();
      await state.init();

      await state.registrarSesionCompletada(
        nombre: 'HIIT & Quema Total',
        duracion: const Duration(minutes: 30),
        calorias: 380,
      );

      expect(state.historial, hasLength(1));
      expect(state.xp, 50);
      expect(state.entrenadoHoy, isTrue);
      expect(state.rachaDias, 1);

      // Reinstanciar: historial y puntos persisten en el dispositivo.
      final state2 = AppState();
      await state2.init();
      expect(state2.historial, hasLength(1));
      expect(state2.xp, 50);
      expect(state2.entrenadoHoy, isTrue);
    });

    test('la racha cuenta días consecutivos hasta hoy', () async {
      SharedPreferences.setMockInitialValues({});
      final state = AppState();
      await state.init();
      final hoy = DateTime.now();

      Future<void> entrenar(DateTime fecha) => state.registrarSesionCompletada(
            nombre: 'Sesión',
            duracion: const Duration(minutes: 20),
            calorias: 150,
            fecha: fecha,
          );

      await entrenar(hoy);
      await entrenar(hoy.subtract(const Duration(days: 1)));
      await entrenar(hoy.subtract(const Duration(days: 2)));

      expect(state.rachaDias, 3);
      expect(state.rachaMaxima, 3);

      // Un día saltado rompe la racha "viva" pero no la máxima histórica.
      await entrenar(hoy.subtract(const Duration(days: 4)));
      expect(state.rachaDias, 3);
      expect(state.rachaMaxima, 3);
    });

    test('el reto avanza 3 → 5 → 7 y premia con puntos', () async {
      SharedPreferences.setMockInitialValues({});
      final state = AppState();
      await state.init();
      final hoy = DateTime.now();

      for (var i = 0; i < 3; i++) {
        await state.registrarSesionCompletada(
          nombre: 'Sesión $i',
          duracion: const Duration(minutes: 25),
          calorias: 200,
          fecha: hoy.subtract(Duration(days: i)),
        );
      }

      // Con 3 días seguidos se cumple el reto de 3: +100 pts y avance a 5.
      expect(state.retoProgreso, 3);
      expect(state.retoObjetivo, 5);
      expect(state.xp, 3 * 50 + 100);

      // Dos días más (5 seguidos): avanza a 7 con otro premio.
      await state.registrarSesionCompletada(
        nombre: 'Sesión 4',
        duracion: const Duration(minutes: 25),
        calorias: 200,
        fecha: hoy.subtract(const Duration(days: 3)),
      );
      expect(state.retoObjetivo, 5); // 4 días seguidos < 5: aún no avanza.
      await state.registrarSesionCompletada(
        nombre: 'Sesión 5',
        duracion: const Duration(minutes: 25),
        calorias: 200,
        fecha: hoy.subtract(const Duration(days: 4)),
      );
      expect(state.retoObjetivo, 7);
      expect(state.xp, 5 * 50 + 100 + 100);
    });

    test('nivel y progreso se derivan de los puntos', () async {
      SharedPreferences.setMockInitialValues({});
      final state = AppState();
      await state.init();
      expect(state.nivel, 1);
      expect(state.progresoNivel, 0);

      final hoy = DateTime.now();
      // 6 días consecutivos: completa el reto de 3 (bonus) y el de 5 (bonus).
      for (var i = 0; i < 6; i++) {
        await state.registrarSesionCompletada(
          nombre: 'N$i',
          duracion: const Duration(minutes: 30),
          calorias: 200,
          fecha: hoy.subtract(Duration(days: i)),
        );
      }
      expect(state.xp, 6 * 50 + 100 + 100);
      expect(state.nivel, 2);
      expect(state.retoObjetivo, 7);
    });

    test('el plan adaptativo usa los días de esta semana', () async {
      SharedPreferences.setMockInitialValues({});
      final state = AppState();
      await state.init();
      final ahora = DateTime.now();
      final lunes = DateTime(ahora.year, ahora.month, ahora.day)
          .subtract(Duration(days: ahora.weekday - 1));

      expect(state.intensidadPlan, 'Baja');

      for (var i = 0; i < 6; i++) {
        await state.registrarSesionCompletada(
          nombre: 'Semana $i',
          duracion: const Duration(minutes: 30),
          calorias: 200,
          fecha: lunes.add(Duration(days: i)),
        );
      }
      expect(state.diasEntrenadosSemana, 6);
      expect(state.intensidadPlan, 'Alta');
    });
  });

  group('Fase 3 · anuncios recompensados y premium', () {
    test('la recompensa del anuncio se otorga una vez por día', () async {
      SharedPreferences.setMockInitialValues({});
      final state = AppState();
      await state.init();
      expect(state.recompensaAnuncioDisponibleHoy, isTrue);

      final ok = await state.aplicarRecompensaAnuncio();
      expect(ok, isTrue);
      expect(state.xp, AppState.ptsRecompensaAnuncio);
      expect(state.recompensaAnuncioDisponibleHoy, isFalse);

      // Segunda llamada el mismo día: no suma de nuevo.
      final ok2 = await state.aplicarRecompensaAnuncio();
      expect(ok2, isFalse);
      expect(state.xp, AppState.ptsRecompensaAnuncio);
    });

    test('ConfigService persiste los toggles de anuncios y premium', () async {
      SharedPreferences.setMockInitialValues({});
      final config = ConfigService();
      await config.init();
      expect(config.adsEnabled, isTrue);
      expect(config.premiumEnabled, isFalse);

      await config.setAds(false);
      await config.setPremium(true);

      final config2 = ConfigService();
      await config2.init();
      expect(config2.adsEnabled, isFalse);
      expect(config2.premiumEnabled, isTrue);
    });
  });
}

String _isoToday() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

/// Health Connect simulado para probar AppState sin tocar la plataforma.
class _FakeHealthConnect extends HealthConnectService {
  _FakeHealthConnect({HealthToday? datos, Set<String>? permisos})
      : _datos = datos ?? HealthToday.vacio,
        _permisos = permisos ?? const {};

  final HealthToday _datos;
  final Set<String> _permisos;

  @override
  Future<bool> disponible() async => true;

  @override
  Future<bool> solicitarPermisos() async => true;

  @override
  Future<Set<String>> metricasConPermiso() async => _permisos;

  @override
  Future<HealthToday> leerHoy() async => _datos;
}

Future<void> _pump() => Future<void>.delayed(Duration.zero);