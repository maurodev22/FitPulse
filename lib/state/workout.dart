// Modelos de datos de entrenamiento (Fase 2).
//
// - [WorkoutProgram]: plan reproducible con ejercicios y descansos.
// - [WorkoutSession]: sesión real completada, persistida por dispositivo.
//
// Regla del proyecto: solo se muestran números reales. Las `kcal` de un
// programa son una estimación del plan (no datos de salud inventados), y solo
// se muestran si el usuario completa el entrenamiento.

/// Ejercicio de un programa de entrenamiento.
class WorkoutExercise {
  const WorkoutExercise({
    required this.nombre,
    required this.duracion,
    this.descanso = const Duration(seconds: 15),
    this.repeticiones = '',
  });

  /// Nombre del ejercicio (p. ej. "Sentadillas").
  final String nombre;

  /// Duración de trabajo del ejercicio.
  final Duration duracion;

  /// Descanso después del ejercicio.
  final Duration descanso;

  /// Detalle opcional: "12 reps", "30 s por pierna", etc.
  final String repeticiones;
}

/// Programa de entrenamiento reproducible (catálogo estático).
class WorkoutProgram {
  const WorkoutProgram({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.duracionMin,
    required this.kcalEstimadas,
    required this.intensidad,
    required this.ejercicios,
  });

  final String id;
  final String nombre;
  final String descripcion;

  /// Duración total aproximada del plan en minutos.
  final int duracionMin;

  /// Kcal estimadas del plan (etiqueta del catálogo, no medición).
  final int kcalEstimadas;

  /// 'Baja' | 'Media' | 'Alta'
  final String intensidad;

  final List<WorkoutExercise> ejercicios;

  /// Etiqueta corta para chips: "45 min".
  String get duracionEtiqueta => '$duracionMin min';

  /// Etiqueta corta para chips: "380 kcal".
  String get kcalEtiqueta => '$kcalEstimadas kcal';

  /// Etiqueta corta para chips: "12 ejercicios".
  String get ejerciciosEtiqueta => '${ejercicios.length} ejercicios';
}

/// Sesión de entrenamiento completada de verdad por el usuario.
class WorkoutSession {
  const WorkoutSession({
    required this.fecha,
    required this.nombre,
    required this.duracionMin,
    required this.calorias,
  });

  /// Momento en que se completó la sesión.
  final DateTime fecha;
  final String nombre;

  /// Minutos reales de la sesión (redondeo hacia abajo, mínimo 1).
  final int duracionMin;

  /// Kcal reales registradas (a día de hoy: estimadas del plan; se mostrará
  /// la medición real cuando haya un reloj/Health Connect que las provea).
  final int calorias;

  Map<String, dynamic> toJson() => {
        'f': fecha.toIso8601String(),
        'n': nombre,
        'd': duracionMin,
        'c': calorias,
      };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
        fecha: DateTime.tryParse(json['f'] as String? ?? '') ?? DateTime.now(),
        nombre: json['n'] as String? ?? 'Entrenamiento',
        duracionMin: json['d'] as int? ?? 1,
        calorias: json['c'] as int? ?? 0,
      );
}