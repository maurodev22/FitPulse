import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'athlete_profile.dart';

/// Estado global de la aplicación (patrón ChangeNotifier + Provider).
///
/// Centraliza el perfil del atleta y el balance nutricional diario, y los
/// persiste por dispositivo mediante `shared_preferences`. De este modo, al
/// reabrir la app en el mismo móvil se conserva la sesión de usuario.
class AppState extends ChangeNotifier {
  static const _profileKey = 'fitpulse_profile_v1';
  static const _caloriasKey = 'fitpulse_calorias_v1';
  static const _proteinasKey = 'fitpulse_proteinas_v1';
  static const _carbosKey = 'fitpulse_carbos_v1';
  static const _grasasKey = 'fitpulse_grasas_v1';
  static const _favRecetasKey = 'fitpulse_fav_recetas_v1';

  SharedPreferences? _prefs;

  /// Perfil del atleta. Por defecto un placeholder de desarrollo.
  AthleteProfile profile = AthleteProfile.initial();

  /// Si ya existe una sesión guardada en el dispositivo.
  bool get isLoggedIn => _prefs?.getString(_profileKey) != null;

  // ---- Balance nutricional de hoy ----
  double caloriasConsumidas = 1480;
  double proteinasConsumidas = 112;
  double carbosConsumidos = 145;
  double grasasConsumidas = 42;
  static const caloriasMeta = 2100.0;

  /// Recetas marcadas como favoritas (por nombre).
  final Set<String> favoritas = <String>{};

  /// Inicializa el estado cargando la sesión persistida del dispositivo.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    final rawProfile = _prefs!.getString(_profileKey);
    if (rawProfile != null) {
      profile = AthleteProfile.fromString(rawProfile);
    }
    caloriasConsumidas = _prefs!.getDouble(_caloriasKey) ?? caloriasConsumidas;
    proteinasConsumidas = _prefs!.getDouble(_proteinasKey) ?? proteinasConsumidas;
    carbosConsumidos = _prefs!.getDouble(_carbosKey) ?? carbosConsumidos;
    grasasConsumidas = _prefs!.getDouble(_grasasKey) ?? grasasConsumidas;
    favoritas
      ..clear()
      ..addAll(_prefs!.getStringList(_favRecetasKey) ?? const []);
    notifyListeners();
  }

  /// Guarda el perfil del atleta en el dispositivo (inicio de sesión/edición).
  Future<void> guardarPerfil(AthleteProfile nuevo) async {
    profile = nuevo;
    notifyListeners();
    await _prefs?.setString(_profileKey, nuevo.encode());
  }

  /// Actualiza la meta calórica y objetivos dentro del perfil.
  Future<void> actualizarMetas({double? calorias, int? pasos}) async {
    final next = _copyProfile(
      caloriasMeta: calorias ?? profile.caloriasMeta,
      pasosMeta: pasos ?? profile.pasosMeta,
    );
    profile = next;
    notifyListeners();
    await _prefs?.setString(_profileKey, next.encode());
  }

  /// Guarda el balance nutricional acumulado del día.
  Future<void> registrarConsumo({
    required double calorias,
    required double proteinas,
    required double carbos,
    required double grasas,
  }) async {
    caloriasConsumidas += calorias;
    proteinasConsumidas += proteinas;
    carbosConsumidos += carbos;
    grasasConsumidas += grasas;
    notifyListeners();
    await _prefs?.setDouble(_caloriasKey, caloriasConsumidas);
    await _prefs?.setDouble(_proteinasKey, proteinasConsumidas);
    await _prefs?.setDouble(_carbosKey, carbosConsumidos);
    await _prefs?.setDouble(_grasasKey, grasasConsumidas);
  }

  /// Alterna el favorito de una receta.
  Future<void> toggleFavorita(String nombre) async {
    if (!favoritas.remove(nombre)) {
      favoritas.add(nombre);
    }
    notifyListeners();
    await _prefs?.setStringList(_favRecetasKey, favoritas.toList());
  }

  /// Porcentaje del balance calórico completado (0..1).
  double get progresoCalorias =>
      (caloriasConsumidas / caloriasMeta).clamp(0.0, 1.0);

  /// Cierra la sesión: borra el perfil y el balance guardados del dispositivo.
  Future<void> cerrarSesion() async {
    profile = AthleteProfile.initial();
    caloriasConsumidas = 0;
    proteinasConsumidas = 0;
    carbosConsumidos = 0;
    grasasConsumidas = 0;
    favoritas.clear();
    await _prefs?.remove(_profileKey);
    await _prefs?.remove(_caloriasKey);
    await _prefs?.remove(_proteinasKey);
    await _prefs?.remove(_carbosKey);
    await _prefs?.remove(_grasasKey);
    await _prefs?.remove(_favRecetasKey);
    notifyListeners();
  }

  /// Crea una copia del perfil aplicando campos opcionales.
  AthleteProfile _copyProfile({double? caloriasMeta, int? pasosMeta}) {
    final p = AthleteProfile(
      nombre: profile.nombre,
      edad: profile.edad,
      sexo: profile.sexo,
      pesoKg: profile.pesoKg,
      alturaM: profile.alturaM,
      meta: profile.meta,
      nivel: profile.nivel,
      diasEntrenamiento: profile.diasEntrenamiento,
      hidratacion: profile.hidratacion,
      entrenamientoMatutino: profile.entrenamientoMatutino,
      healthKit: profile.healthKit,
      vibracion: profile.vibracion,
      compartirActividad: profile.compartirActividad,
      rachaDias: profile.rachaDias,
      caloriasMeta: caloriasMeta ?? profile.caloriasMeta,
      pasosMeta: pasosMeta ?? profile.pasosMeta,
    );
    return p;
  }
}