import 'dart:async';
import 'dart:math';

import 'package:pedometer/pedometer.dart';

/// Fuente de datos de salud del dispositivo.
///
/// Fase 1: solo pasos. Cada métrica futura (pulso, sueño, peso) añadirá su
/// propio stream y estado de disponibilidad, siempre con la regla de que NUNCA
/// se muestra un número inventado si no hay una fuente real conectada.
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