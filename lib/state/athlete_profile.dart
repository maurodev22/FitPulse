import 'dart:convert';

/// Modelo de datos del atleta (perfil registrado).
///
/// Es la fuente de verdad de la sesión del dispositivo: se serializa a JSON
/// para persistirse con `shared_preferences` y se comparte entre la pantalla
/// de registro, inicio, perfil, recetas y progreso.
class AthleteProfile {
  const AthleteProfile({
    this.nombre = 'Sofía Martínez',
    this.edad = 26,
    this.sexo = 'Femenino',
    this.pesoKg = 64.5,
    this.alturaM = 1.72,
    this.meta = 'Definir',
    this.nivel = 'Intermedio',
    this.diasEntrenamiento = const ['L', 'M', 'X', 'J', 'V'],
    this.hidratacion = true,
    this.entrenamientoMatutino = true,
    this.healthKit = true,
    this.vibracion = true,
    this.compartirActividad = false,
    this.rachaDias = 14,
    this.caloriasMeta = 750,
    this.pasosMeta = 10000,
  });

  /// Crea un perfil por defecto usado como placeholder en entorno dev.
  factory AthleteProfile.initial() => const AthleteProfile();

  /// Reconstruye un perfil desde un string JSON persistido.
  factory AthleteProfile.fromString(String raw) =>
      AthleteProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  /// Reconstruye un perfil desde un mapa decodificado de JSON.
  factory AthleteProfile.fromJson(Map<String, dynamic> json) {
    return AthleteProfile(
      nombre: json['nombre'] as String? ?? 'Sofía Martínez',
      edad: json['edad'] as int? ?? 26,
      sexo: json['sexo'] as String? ?? 'Femenino',
      pesoKg: (json['pesoKg'] as num?)?.toDouble() ?? 64.5,
      alturaM: (json['alturaM'] as num?)?.toDouble() ?? 1.72,
      meta: json['meta'] as String? ?? 'Definir',
      nivel: json['nivel'] as String? ?? 'Intermedio',
      diasEntrenamiento:
          (json['diasEntrenamiento'] as List?)?.cast<String>() ?? ['L', 'M', 'X', 'J', 'V'],
      hidratacion: json['hidratacion'] as bool? ?? true,
      entrenamientoMatutino: json['entrenamientoMatutino'] as bool? ?? true,
      healthKit: json['healthKit'] as bool? ?? true,
      vibracion: json['vibracion'] as bool? ?? true,
      compartirActividad: json['compartirActividad'] as bool? ?? false,
      rachaDias: json['rachaDias'] as int? ?? 14,
      caloriasMeta: (json['caloriasMeta'] as num?)?.toDouble() ?? 750,
      pasosMeta: json['pasosMeta'] as int? ?? 10000,
    );
  }

  final String nombre;
  final int edad;
  final String sexo;
  final double pesoKg;
  final double alturaM;
  final String meta;
  final String nivel;
  final List<String> diasEntrenamiento;
  final bool hidratacion;
  final bool entrenamientoMatutino;
  final bool healthKit;
  final bool vibracion;
  final bool compartirActividad;
  final int rachaDias;
  final double caloriasMeta;
  final int pasosMeta;

  /// Índice de Masa Corporal calculado en vivo desde peso y altura.
  double get imc {
    if (alturaM <= 0) return 0;
    return pesoKg / (alturaM * alturaM);
  }

  /// Etiqueta cualitativa del IMC según la OMS.
  String get imcCategoria {
    if (imc < 18.5) return 'Bajo peso';
    if (imc < 25) return 'Rango normal y saludable';
    if (imc < 30) return 'Sobrepeso';
    return 'Obesidad';
  }

  /// IMC formateado con un decimal (p. ej. "21.8").
  String get imcFormateado => imc.toStringAsFixed(1);

  /// Serializa el perfil a JSON para su persistencia.
  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'edad': edad,
        'sexo': sexo,
        'pesoKg': pesoKg,
        'alturaM': alturaM,
        'meta': meta,
        'nivel': nivel,
        'diasEntrenamiento': diasEntrenamiento,
        'hidratacion': hidratacion,
        'entrenamientoMatutino': entrenamientoMatutino,
        'healthKit': healthKit,
        'vibracion': vibracion,
        'compartirActividad': compartirActividad,
        'rachaDias': rachaDias,
        'caloriasMeta': caloriasMeta,
        'pasosMeta': pasosMeta,
      };

  /// Versión en JSON string para `shared_preferences`.
  String encode() => jsonEncode(toJson());
}