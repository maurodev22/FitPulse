import 'dart:convert';

/// Modelo de datos del atleta (perfil registrado).
///
/// Es la fuente de verdad de la sesión del dispositivo: se serializa a JSON
/// para persistirse con `shared_preferences` y se comparte entre la pantalla
/// de registro, inicio, perfil, recetas y progreso.
/// Tipo de cuerpo del atleta (informativo; no participa en cálculos).
///
/// Si el usuario elige "No lo sé" se guarda [tipoCuerpoNormal].
abstract final class TipoCuerpo {
  static const ectomorfo = 'Ectomorfo';
  static const mesomorfo = 'Mesomorfo';
  static const endomorfo = 'Endomorfo';
  static const ectoMeso = 'Ecto-Meso';
  static const mesoEndo = 'Meso-Endo';
  static const ectoEndo = 'Ecto-Endo';
  static const noLoSe = 'No lo sé';

  /// Valor almacenado cuando el usuario no sabe su tipo de cuerpo.
  static const normal = 'Normal';

  static const opciones = [
    ectomorfo,
    mesomorfo,
    endomorfo,
    ectoMeso,
    mesoEndo,
    ectoEndo,
    noLoSe,
  ];

  /// Normaliza la selección; "No lo sé" se guarda como [normal].
  static String normalizar(String? seleccion) =>
      (seleccion == null || seleccion == noLoSe) ? normal : seleccion;
}

class AthleteProfile {
  const AthleteProfile({
    this.nombre = '',
    this.edad = 0,
    this.sexo = '',
    this.pesoKg = 0,
    this.alturaM = 0,
    this.metas = const [],
    this.tipoCuerpo = 'Normal',
    this.nivel = 'Intermedio',
    this.diasEntrenamiento = const ['L', 'M', 'X', 'J', 'V'],
    this.hidratacion = true,
    this.entrenamientoMatutino = true,
    this.healthKit = true,
    this.vibracion = true,
    this.compartirActividad = false,
    this.rachaDias = 0,
    this.caloriasMeta = 2100,
    this.pasosMeta = 10000,
  });

  /// Crea un perfil neutro (sin datos ficticios) para una nueva sesión.
  factory AthleteProfile.initial() => const AthleteProfile();

  /// Reconstruye un perfil desde un string JSON persistido.
  factory AthleteProfile.fromString(String raw) =>
      AthleteProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  /// Reconstruye un perfil desde un mapa decodificado de JSON.
  factory AthleteProfile.fromJson(Map<String, dynamic> json) {
    final metasList = (json['metas'] as List?)
        ?.cast<String>()
        .where((s) => s.isNotEmpty)
        .toList();
    // Compatibilidad con perfiles antiguos que guardaban una sola `meta`.
    final legacyMeta = json['meta'] as String?;
    final metas = (metasList != null && metasList.isNotEmpty)
        ? metasList
        : (legacyMeta != null && legacyMeta.isNotEmpty ? [legacyMeta] : <String>[]);
    return AthleteProfile(
      nombre: json['nombre'] as String? ?? '',
      edad: json['edad'] as int? ?? 0,
      sexo: json['sexo'] as String? ?? '',
      pesoKg: (json['pesoKg'] as num?)?.toDouble() ?? 0,
      alturaM: (json['alturaM'] as num?)?.toDouble() ?? 0,
      metas: metas,
      tipoCuerpo: json['tipoCuerpo'] as String? ?? 'Normal',
      nivel: json['nivel'] as String? ?? 'Intermedio',
      diasEntrenamiento:
          (json['diasEntrenamiento'] as List?)?.cast<String>() ?? ['L', 'M', 'X', 'J', 'V'],
      hidratacion: json['hidratacion'] as bool? ?? true,
      entrenamientoMatutino: json['entrenamientoMatutino'] as bool? ?? true,
      healthKit: json['healthKit'] as bool? ?? true,
      vibracion: json['vibracion'] as bool? ?? true,
      compartirActividad: json['compartirActividad'] as bool? ?? false,
      rachaDias: json['rachaDias'] as int? ?? 0,
      caloriasMeta: (json['caloriasMeta'] as num?)?.toDouble() ?? 2100,
      pasosMeta: json['pasosMeta'] as int? ?? 10000,
    );
  }

  final String nombre;
  final int edad;
  final String sexo;
  final double pesoKg;
  final double alturaM;

  /// Metas principales del atleta (1 o 2).
  final List<String> metas;

  /// Etiqueta principal de meta (primera de la lista).
  String get meta => metas.isEmpty ? '' : metas.first;

  /// Tipo de cuerpo informativo (ver [TipoCuerpo]).
  final String tipoCuerpo;
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
        'meta': metas.isEmpty ? '' : metas.first,
        'metas': metas,
        'tipoCuerpo': tipoCuerpo,
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