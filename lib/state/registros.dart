/// Registros reales de Fase 9: peso corporal semanal y repeticiones por
/// ejercicio. Solo se guarda lo que el usuario registra de verdad; nunca se
/// inventa un dato de salud.
library;

/// Lectura de peso de una semana concreta (1 registro por semana).
class RegistroPeso {
  const RegistroPeso({required this.fecha, required this.pesoKg});

  /// Momento en que se registró el peso.
  final DateTime fecha;

  /// Peso en kilogramos, tal como lo introdujo el usuario.
  final double pesoKg;

  /// Ancla de la semana (lunes) para limitar a un registro por semana.
  DateTime get lunes =>
      DateTime(fecha.year, fecha.month, fecha.day)
          .subtract(Duration(days: fecha.weekday - 1));

  Map<String, dynamic> toJson() => {'f': fecha.toIso8601String(), 'kg': pesoKg};

  factory RegistroPeso.fromJson(Map<String, dynamic> json) => RegistroPeso(
        fecha: DateTime.tryParse(json['f'] as String? ?? '') ?? DateTime.now(),
        pesoKg: (json['kg'] as num?)?.toDouble() ?? 0,
      );
}

/// Repeticiones hechas de verdad al terminar un ejercicio del reproductor.
class RegistroReps {
  const RegistroReps({
    required this.fecha,
    required this.ejercicio,
    required this.reps,
  });

  final DateTime fecha;
  final String ejercicio;

  /// Repeticiones reales que completó el usuario.
  final int reps;

  Map<String, dynamic> toJson() => {
        'f': fecha.toIso8601String(),
        'e': ejercicio,
        'r': reps,
      };

  factory RegistroReps.fromJson(Map<String, dynamic> json) => RegistroReps(
        fecha: DateTime.tryParse(json['f'] as String? ?? '') ?? DateTime.now(),
        ejercicio: json['e'] as String? ?? 'Ejercicio',
        reps: json['r'] as int? ?? 0,
      );
}