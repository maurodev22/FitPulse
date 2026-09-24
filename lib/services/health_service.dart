import 'dart:async';
import 'dart:math';

import 'package:health/health.dart';
import 'package:pedometer/pedometer.dart';

/// Fuente de datos de salud del dispositivo.
///
/// Fase 1: pasos en tiempo real (sensor del teléfono) + Health Connect (Google)
/// para el resto de métricas. Regla del proyecto: NUNCA se muestra un número
/// inventado si no hay una fuente real conectada.
abstract class HealthDataSource {
  /// Cierre y limpieza de suscripciones nativas.
  void dispose();

  /// Si la fuente puede ofrecer datos en este dispositivo.
  bool get isAvailable;

  /// Emite el contador acumulado del sensor del teléfono (pasos).
  ///
  /// En Android el contador es "desde el último arranque del sistema", por lo
  /// que la capa de estado calcula los pasos del día con un baseline diario.
  Stream<int> get stepStream;
}

/// Fuente real usando el sensor interno de pasos del teléfono.
///
/// No requiere reloj inteligente ni Health Connect: usa el acelerómetro del
/// móvil (Android: `TYPE_STEP_COUNTER`).
class PhoneStepSource implements HealthDataSource {
  PhoneStepSource() {
    _sub = Pedometer.stepCountStream.listen(
      (step) => _controller.add(step.steps),
      onError: (_) {
        _available = false;
        _controller.close();
      },
      onDone: () => _controller.close(),
    );
  }

  StreamSubscription<StepCount>? _sub;
  final StreamController<int> _controller = StreamController<int>.broadcast();
  bool _available = true;

  @override
  bool get isAvailable => _available;

  @override
  Stream<int> get stepStream => _controller.stream;

  @override
  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}

/// Fuente simulada (solo desarrollo / respaldo en dispositivos sin sensor).
///
/// Genera pasos aleatorios crecientes para poder probar la interfaz cuando no
/// existe sensor real. Nunca se activa en producción.
class MockHealthSource implements HealthDataSource {
  MockHealthSource({Random? random}) : _random = random ?? Random();

  final Random _random;
  final StreamController<int> _controller = StreamController<int>.broadcast();
  Timer? _timer;
  final bool _available = true;
  int _steps = 0;

  @override
  bool get isAvailable => _available;

  @override
  Stream<int> get stepStream {
    // Arranca emitiendo una marca inicial y luego incrementos cada 3 s.
    _steps = 0;
    _timer ??= Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        _steps += _random.nextInt(12);
        _controller.add(_steps);
      },
    );
    return _controller.stream;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _controller.close();
  }
}

/// Nombres normalizados de las métricas de Health Connect (para UI y tests).
///
/// Evita importar el paquete `health` en la capa de estado/pantallas.
abstract final class HealthMetricas {
  static const pasos = 'STEPS';
  static const pulso = 'HEART_RATE';
  static const peso = 'WEIGHT';
  static const grasa = 'BODY_FAT_PERCENTAGE';
  static const suenio = 'SLEEP_ASLEEP';
  static const agua = 'WATER';
  static const gastoActivo = 'ACTIVE_ENERGY_BURNED';
  static const tiempoActivo = 'EXERCISE_TIME';
}

/// Métricas diarias leídas desde Health Connect (solo lectura, local).
///
/// [funciono] es `false` cuando no hay Health Connect o la consulta falla.
/// Los valores nulos significan "sin datos reales de hoy" (nunca inventados).
class HealthToday {
  const HealthToday({
    this.funciono = false,
    this.pasos = 0,
    this.pulsoBpm,
    this.pesoKg,
    this.grasaPct,
    this.suenioMin,
    this.aguaLitros,
    this.gastoActivoKcal,
    this.tiempoActivoMin,
    this.metricasConPermiso = const {},
  });

  static const vacio = HealthToday();

  /// `true` si la lectura de hoy se completó con éxito.
  final bool funciono;

  /// Pasos acumulados del día (suma de Health Connect).
  final int pasos;

  /// Última lectura de pulso del día, en latidos por minuto.
  final int? pulsoBpm;

  /// Último peso registrado, en kilogramos.
  final double? pesoKg;

  /// Último porcentaje de grasa corporal.
  final double? grasaPct;

  /// Sueño de hoy (Health Connect lo mide en minutos).
  final int? suenioMin;

  /// Agua del día, en litros.
  final double? aguaLitros;

  /// Calorías activas quemadas de hoy.
  final double? gastoActivoKcal;

  /// Tiempo activo de hoy, en minutos.
  final int? tiempoActivoMin;

  /// Nombres (`HealthDataType.name`) de las métricas con permiso concedido.
  final Set<String> metricasConPermiso;
}

/// Servicio de Health Connect de solo lectura.
///
/// Cada métrica pide permiso por separado en la pantalla de Health Connect y
/// el usuario puede aceptarlas o rechazarlas individualmente.
///
/// REQUISITO Android: minSdk 26 y permisos `android.permission.health.READ_*`
/// declarados en el AndroidManifest. En dispositivos sin la app de Health
/// Connect instalada, [disponible] devuelve `false` sin lanzar errores.
class HealthConnectService {
  HealthConnectService({Health? health}) : _health = health ?? Health();

  final Health _health;
  bool _configurado = false;

  /// Tipos diarios que pedimos leer (solo lectura).
  ///
  /// IMPORTANTE: NO incluir [HealthDataType.EXERCISE_TIME]. En esta versión del
  /// paquete `health` ese tipo es exclusivo de iOS/HealthKit: en Android no está
  /// en el mapa del plugin y, si se incluye en la petición, `requestAuthorization`
  /// devuelve `false` sin abrir la pantalla de permisos (rompe TODA la solicitud).
  /// Por eso "Tiempo Activo" se muestra honestamente como "—" en Android.
  static const _tiposDiarios = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.WATER,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  Future<void> _ensureConfigurado() async {
    if (!_configurado) {
      await _health.configure();
      _configurado = true;
    }
  }

  /// `true` si la app Health Connect está instalada y disponible.
  Future<bool> disponible() async {
    try {
      await _ensureConfigurado();
      return await _health.isHealthConnectAvailable();
    } catch (_) {
      return false;
    }
  }

  /// Pide permiso de LECTURA de todas las métricas. Google muestra una sola
  /// pantalla donde se puede conceder o rechazar cada métrica por separado.
  Future<bool> solicitarPermisos() async {
    try {
      await _ensureConfigurado();
      return await _health.requestAuthorization(_tiposDiarios);
    } catch (_) {
      return false;
    }
  }

  /// Nombres de las métricas cuyo permiso de lectura ya está concedido.
  Future<Set<String>> metricasConPermiso() async {
    try {
      await _ensureConfigurado();
      if (!await _health.isHealthConnectAvailable()) return {};
      final concedidas = <String>{};
      for (final tipo in _tiposDiarios) {
        final ok = await _health.hasPermissions([tipo]);
        if (ok == true) concedidas.add(tipo.name);
      }
      return concedidas;
    } catch (_) {
      return {};
    }
  }

  /// Lee todas las métricas del día. Nunca lanza: si no hay Health Connect o
  /// falla la consulta devuelve [HealthToday.vacio] (`funciono == false`).
  Future<HealthToday> leerHoy() async {
    try {
      await _ensureConfigurado();
      if (!await _health.isHealthConnectAvailable()) return HealthToday.vacio;

      final ahora = DateTime.now();
      final inicio = DateTime(ahora.year, ahora.month, ahora.day);
      final puntos = await _health.getHealthDataFromTypes(
        startTime: inicio,
        endTime: ahora,
        types: _tiposDiarios,
      );

      var pasos = 0;
      int? pulso;
      double? peso;
      double? grasa;
      var suenioMin = 0;
      var agua = 0.0;
      var gastoActivo = 0.0;
      var tiempoActivo = 0;

      for (final p in puntos) {
        // En esta versión del paquete `health` el valor viene envuelto en
        // HealthValue; las métricas numéricas usan NumericHealthValue.
        final hv = p.value;
        final num v = hv is NumericHealthValue ? hv.numericValue : 0;
        switch (p.type) {
          case HealthDataType.STEPS:
            pasos += v.round();
          case HealthDataType.HEART_RATE:
            if (v > 0) pulso = v.round();
          case HealthDataType.WEIGHT:
            if (v > 0) peso = v.toDouble();
          case HealthDataType.BODY_FAT_PERCENTAGE:
            if (v > 0) grasa = v.toDouble();
          case HealthDataType.SLEEP_ASLEEP:
            suenioMin += v.round();
          case HealthDataType.WATER:
            agua += v.toDouble();
          case HealthDataType.ACTIVE_ENERGY_BURNED:
            gastoActivo += v.toDouble();
          case HealthDataType.EXERCISE_TIME:
            tiempoActivo += v.round();
          default:
            break;
        }
      }

      final concedidas = await metricasConPermiso();
      return HealthToday(
        funciono: true,
        pasos: pasos,
        pulsoBpm: pulso,
        pesoKg: peso,
        grasaPct: grasa,
        suenioMin: suenioMin > 0 ? suenioMin : null,
        aguaLitros: agua > 0 ? agua : null,
        gastoActivoKcal: gastoActivo > 0 ? gastoActivo : null,
        tiempoActivoMin: tiempoActivo > 0 ? tiempoActivo : null,
        metricasConPermiso: concedidas,
      );
    } catch (_) {
      return HealthToday.vacio;
    }
  }
}