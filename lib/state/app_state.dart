import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/health_service.dart';
import '../services/usage_log_service.dart';
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

  // Fecha del día al que pertenece el balance persistido (clave "YYYY-MM-DD").
  static const _balanceDateKey = 'fitpulse_balance_date_v1';
  // Baseline de pasos: contador del sensor del teléfono al inicio del día.
  static const _pasosBaseKey = 'fitpulse_pasos_base_v1';
  static const _pasosBaseDateKey = 'fitpulse_pasos_base_date_v1';

  SharedPreferences? _prefs;
  StreamSubscription<int>? _pasosSub;
  HealthDataSource? _healthSource;
  UsageLogService? _log;

  /// Registro de uso anónimo (opcional, por defecto desactivado).
  void setUsageLog(UsageLogService log) => _log = log;

  void _trace(String category, String action, {String? detail}) =>
      _log?.log(category, action, detail: detail);

  /// Traza la navegación entre pestañas (usado por la barra inferior).
  void traceTab(String tab) => _trace('navegacion', tab);

  /// Perfil del atleta. Por defecto un placeholder de desarrollo.
  AthleteProfile profile = AthleteProfile.initial();

  /// Si ya existe una sesión guardada en el dispositivo.
  bool get isLoggedIn => _prefs?.getString(_profileKey) != null;

  // ---- Balance nutricional de hoy ----
  double caloriasConsumidas = 0;
  double proteinasConsumidas = 0;
  double carbosConsumidos = 0;
  double grasasConsumidas = 0;

  /// Meta calórica diaria, única fuente de verdad: se deriva del perfil.
  double get caloriasMeta => profile.caloriasMeta;

  /// Recetas marcadas como favoritas (por nombre).
  final Set<String> favoritas = <String>{};

  // ---- Salud real del dispositivo ----
  /// Pasos reales de hoy contados por el teléfono (0 si no hay fuente).
  int pasosHoy = 0;
  int? _pasosBase;

  /// Si el teléfono tiene sensor de pasos disponible y autorizado.
  bool get healthDisponible => _healthSource?.isAvailable ?? false;

  /// Clave del día actual (YYYY-MM-DD) para persistir el balance por fecha.
  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Conecta la fuente de datos real (sensor del teléfono).
  void attachHealthSource(HealthDataSource source) {
    _healthSource?.dispose();
    _pasosSub?.cancel();
    _healthSource = source;
    if (!source.isAvailable) {
      notifyListeners();
      return;
    }
    _pasosSub = source.stepStream.listen(
      _onPasos,
      onError: (Object _) => notifyListeners(),
    );
  }

  void _onPasos(int raw) {
    final today = _dayKey(DateTime.now());

    // Si cambió el día, reseteamos el balance y el baseline de pasos.
    if (_prefs?.getString(_balanceDateKey) != today) {
      _resetBalance();
      _pasosBase = null;
      _prefs?.setString(_balanceDateKey, today);
    }

    // El contador reserva como baseline el primer valor del día; si el
    // dispositivo reinicia (valor menor), se re-basifica automáticamente.
    if (_pasosBase == null || raw < _pasosBase!) {
      _pasosBase = raw;
      _prefs?.setInt(_pasosBaseKey, raw);
      _prefs?.setString(_pasosBaseDateKey, today);
    }
    pasosHoy = raw - _pasosBase!;
    notifyListeners();
  }

  /// Vuelve el balance diario a cero (no borra el perfil ni favoritos).
  void _resetBalance() {
    caloriasConsumidas = 0;
    proteinasConsumidas = 0;
    carbosConsumidos = 0;
    grasasConsumidas = 0;
    _prefs?.setDouble(_caloriasKey, 0);
    _prefs?.setDouble(_proteinasKey, 0);
    _prefs?.setDouble(_carbosKey, 0);
    _prefs?.setDouble(_grasasKey, 0);
  }

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

    // Reinicio diario: si el balance guardado pertenece a otro día, se vacía.
    final today = _dayKey(DateTime.now());
    if (_prefs!.getString(_balanceDateKey) != today) {
      _resetBalance();
      _prefs!.setString(_balanceDateKey, today);
    } else {
      // Mismo día: restauramos el baseline de pasos para continuar el conteo.
      _pasosBase = _prefs!.getInt(_pasosBaseKey);
      pasosHoy = 0;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _pasosSub?.cancel();
    _healthSource?.dispose();
    super.dispose();
  }

  /// Guarda el perfil del atleta en el dispositivo (inicio de sesión/edición).
  Future<void> guardarPerfil(AthleteProfile nuevo) async {
    profile = nuevo;
    notifyListeners();
    _trace('perfil', 'guardar');
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
    _trace('perfil', 'metas');
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
    _trace('balance', 'consumo');
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
    _trace('recetas', 'favorita', detail: nombre);
    await _prefs?.setStringList(_favRecetasKey, favoritas.toList());
  }

  /// Porcentaje del balance calórico completado (0..1).
  double get progresoCalorias =>
      (caloriasConsumidas / caloriasMeta).clamp(0.0, 1.0);

  /// Cierra la sesión: vuelve al onboarding SIN borrar los datos del
  /// dispositivo. Como cada dispositivo guarda un único usuario, el perfil y
  /// el balance persisten y se recargan al reabrir la app.
  Future<void> cerrarSesion() async {
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
      metas: List.of(profile.metas),
      tipoCuerpo: profile.tipoCuerpo,
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