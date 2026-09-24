import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/health_service.dart';
import '../services/usage_log_service.dart';
import 'athlete_profile.dart';
import 'workout.dart';
import 'workout_catalog.dart';

/// Estado global de la aplicación (patrón ChangeNotifier + Provider).
///
/// Centraliza el perfil del atleta, el balance nutricional diario, las métricas
/// reales del dispositivo (pasos + Health Connect) y el progreso de
/// entrenamiento (sesiones, racha, puntos/niveles y retos). Todo se persiste
/// por dispositivo mediante `shared_preferences`.
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

  // Fase 2: historial de sesiones, puntos y retos.
  static const _historyKey = 'fitpulse_workout_history_v1';
  static const _xpKey = 'fitpulse_xp_v1';
  static const _retoKey = 'fitpulse_reto_v1';

  // Fase 3: recompensa del anuncio (una vez por día, guardada por fecha).
  static const _recompensaAnuncioKey = 'fitpulse_recompensa_anuncio_v1';
  static const int ptsRecompensaAnuncio = 25;

  // Health Connect: flag de "permisos ya solicitados al arrancar".
  static const _hcRequestedKey = 'fitpulse_hc_requested_v1';

  SharedPreferences? _prefs;
  StreamSubscription<int>? _pasosSub;
  HealthDataSource? _healthSource;
  UsageLogService? _log;
  HealthConnectService? _healthConnect;
  HealthToday _healthToday = HealthToday.vacio;
  bool _healthConnectDisponible = false;
  bool _healthConnectPidiendo = false;

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

    // Fase 2: historial de sesiones, puntos y reto actual.
    _cargarHistorial();

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

  // =====================================================================
  //  Health Connect (Fase 1): métricas reales por permiso individual
  // =====================================================================

  /// Inyecta el servicio de Health Connect (desde main o tests).
  void setHealthConnect(HealthConnectService service) {
    _healthConnect = service;
  }

  /// `true` si la app Health Connect está instalada en el dispositivo.
  bool get healthConnectDisponible => _healthConnectDisponible;

  /// `true` mientras se está mostrando la pantalla de permisos de Google.
  bool get healthConnectPidiendo => _healthConnectPidiendo;

  /// `true` la primera vez que se consigue leer algo desde Health Connect
  /// (independientemente de cuántas métricas estén concedidas).
  bool get healthConnectConectado => _healthToday.funciono;

  // --- Métricas de hoy (solo números reales; null = sin dato) ---
  int? get pulsoHoy => _healthToday.pulsoBpm;
  double? get pesoMedidoKg => _healthToday.pesoKg;
  double? get grasaHoy => _healthToday.grasaPct;
  Duration? get suenioHoy => _healthToday.suenioMin != null
      ? Duration(minutes: _healthToday.suenioMin!)
      : null;
  double? get aguaHoy => _healthToday.aguaLitros;
  double? get gastoActivoHoy => _healthToday.gastoActivoKcal;
  int? get tiempoActivoMin => _healthToday.tiempoActivoMin;

  // --- Permisos concedidos por métrica (para textos honestos) ---
  bool get pulsoConPermiso =>
      _healthToday.metricasConPermiso.contains(HealthMetricas.pulso);
  bool get pesoConPermiso =>
      _healthToday.metricasConPermiso.contains(HealthMetricas.peso);
  bool get grasaConPermiso =>
      _healthToday.metricasConPermiso.contains(HealthMetricas.grasa);
  bool get suenioConPermiso =>
      _healthToday.metricasConPermiso.contains(HealthMetricas.suenio);
  bool get aguaConPermiso =>
      _healthToday.metricasConPermiso.contains(HealthMetricas.agua);
  bool get gastoActivoConPermiso =>
      _healthToday.metricasConPermiso.contains(HealthMetricas.gastoActivo);
  bool get tiempoActivoConPermiso =>
      _healthToday.metricasConPermiso.contains(HealthMetricas.tiempoActivo);

  /// Pide los permisos de lectura de todas las métricas (una sola pantalla de
  /// Health Connect donde se aceptan o rechazan por separado) y refresca.
  Future<void> solicitarPermisosHealthConnect() async {
    final hc = _healthConnect;
    if (hc == null) return;
    _healthConnectPidiendo = true;
    notifyListeners();
    await hc.solicitarPermisos();
    _healthConnectPidiendo = false;
    await _prefs?.setBool(_hcRequestedKey, true);
    await refreshHealthConnect();
  }

  /// Detecta Health Connect, pide permisos una sola vez por instalación y
  /// lee las métricas del día. Se llama una vez al arrancar (asíncrono).
  Future<void> initHealthConnect() async {
    final hc = _healthConnect;
    if (hc == null) return;
    _healthConnectDisponible = await hc.disponible();
    final yaPedido = _prefs?.getBool(_hcRequestedKey) ?? false;
    if (_healthConnectDisponible && !yaPedido) {
      _healthConnectPidiendo = true;
      notifyListeners();
      final ok = await hc.solicitarPermisos();
      _healthConnectPidiendo = false;
      await _prefs?.setBool(_hcRequestedKey, true);
      if (!ok) return;
    }
    await refreshHealthConnect();
  }

  /// Relee las métricas de hoy desde Health Connect y actualiza la UI.
  Future<void> refreshHealthConnect() async {
    final hc = _healthConnect;
    if (hc == null) return;
    _healthToday = await hc.leerHoy();
    // Si el sensor del teléfono no está disponible pero Health Connect sí
    // concede pasos, usamos el total del día de Health Connect.
    if (!healthDisponible && _healthToday.pasos > 0) {
      pasosHoy = _healthToday.pasos;
    }
    notifyListeners();
  }

  // =====================================================================
  //  Fase 2: historial real de entrenamiento
  // =====================================================================

  /// Sesiones completadas de verdad (ordenadas, más reciente primero).
  List<WorkoutSession> historial = [];

  /// Puntos totales ganados con sesiones y retos.
  int get xp => _xp;
  int _xp = 0;

  /// Nivel actual: sube cada 300 puntos.
  int get nivel => 1 + _xp ~/ 300;

  /// Progreso dentro del nivel actual (0..1).
  double get progresoNivel => (_xp % 300) / 300.0;

  /// Etiqueta de nivel según puntos acumulados.
  String get nombreNivel {
    if (nivel >= 8) return 'Avanzado';
    if (nivel >= 4) return 'Intermedio';
    return 'Principiante';
  }

  /// Objetivo del reto actual: 3 → 5 → 7 días seguidos entrenando.
  int get retoObjetivo => _retoObjetivo;
  int _retoObjetivo = 3;

  /// Días seguidos entrenando hasta hoy (o hasta ayer si hoy aún no entrena).
  int get retoProgreso => _rachaActual();

  /// `true` si ya se completó el reto actual.
  bool get retoCompletado => retoProgreso >= _retoObjetivo;

  /// Mejor racha consecutiva de la historia completa.
  int get rachaMaxima {
    final dias = _diasConSesion();
    if (dias.isEmpty) return 0;
    var mejor = 1;
    var actual = 1;
    for (var i = 1; i < dias.length; i++) {
      if (dias[i].difference(dias[i - 1]).inDays == 1) {
        actual++;
        if (actual > mejor) mejor = actual;
      } else {
        actual = 1;
      }
    }
    return mejor;
  }

  /// `true` si hoy hay al menos una sesión completada.
  bool get entrenadoHoy {
    final hoy = _dayKey(DateTime.now());
    return historial.any((s) => _dayKey(s.fecha) == hoy);
  }

  /// Minutos reales de entrenamiento esta semana (lunes a domingo actual).
  int get minutosEntrenadosSemana {
    final ahora = DateTime.now();
    final lunes = ahora.subtract(Duration(days: ahora.weekday - 1));
    final inicio = DateTime(lunes.year, lunes.month, lunes.day);
    var total = 0;
    for (final s in historial) {
      if (!s.fecha.isBefore(inicio)) total += s.duracionMin;
    }
    return total;
  }

  /// Días distintos con al menos una sesión esta semana.
  int get diasEntrenadosSemana {
    final ahora = DateTime.now();
    final lunes = ahora.subtract(Duration(days: ahora.weekday - 1));
    final inicio = DateTime(lunes.year, lunes.month, lunes.day);
    final dias = <String>{};
    for (final s in historial) {
      if (!s.fecha.isBefore(inicio)) dias.add(_dayKey(s.fecha));
    }
    return dias.length;
  }

  /// Días (L..D) de la semana actual con al menos una sesión, para la UI.
  Set<int> get diasSemanaEntrenados {
    final ahora = DateTime.now();
    final lunes = DateTime(ahora.year, ahora.month, ahora.day);
    final lunesInicio = lunes.subtract(Duration(days: lunes.weekday - 1));
    final entrenados = <int>{};
    for (final s in historial) {
      final d = DateTime(s.fecha.year, s.fecha.month, s.fecha.day);
      final diff = d.difference(lunesInicio).inDays;
      if (diff >= 0 && diff <= 6) entrenados.add(diff);
    }
    return entrenados;
  }

  /// Días consecutivos de entrenamiento actuales (racha viva).
  int get rachaDias => _rachaActual();

  /// Intensidad del plan adaptativo según el cumplimiento de esta semana:
  /// 5+ días → Alta, 3-4 → Media, 0-2 → Baja.
  String get intensidadPlan {
    final d = diasEntrenadosSemana;
    if (d >= 5) return 'Alta';
    if (d >= 3) return 'Media';
    return 'Baja';
  }

  /// Programa recomendado según la intensidad del plan adaptativo.
  WorkoutProgram get entrenamientoRecomendado {
    final buscado = switch (intensidadPlan) {
      'Alta' => 'fuerza_superior_core',
      'Baja' => 'full_body_flexibilidad',
      _ => 'hiit_quema_total',
    };
    return workoutCatalog.firstWhere(
      (p) => p.id == buscado,
      orElse: () => workoutCatalog.first,
    );
  }

  List<DateTime> _diasConSesion() {
    final set = <DateTime>{};
    for (final s in historial) {
      set.add(DateTime(s.fecha.year, s.fecha.month, s.fecha.day));
    }
    final list = set.toList()..sort();
    return list;
  }

  int _rachaActual() {
    final dias = _diasConSesion();
    if (dias.isEmpty) return 0;
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    // Si hoy aún no entreno, la racha se cuenta desde ayer.
    var cursor = dias.contains(hoy) ? hoy : hoy.subtract(const Duration(days: 1));
    var count = 0;
    while (dias.contains(cursor)) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  /// Registra una sesión completada de verdad: la guarda en el historial,
  /// otorga puntos y comprueba el reto (3 → 5 → 7 días).
  ///
  /// [fecha] solo se usa en pruebas para simular días distintos; en producción
  /// siempre es `DateTime.now()`.
  Future<void> registrarSesionCompletada({
    required String nombre,
    required Duration duracion,
    required int calorias,
    DateTime? fecha,
  }) async {
    final duracionMin = max(1, duracion.inMinutes);
    historial.add(WorkoutSession(
      fecha: fecha ?? DateTime.now(),
      nombre: nombre,
      duracionMin: duracionMin,
      calorias: calorias,
    ));
    historial.sort((a, b) => b.fecha.compareTo(a.fecha));
    _xp += 50;
    _trace('entrenamiento', 'sesion', detail: nombre);
    notifyListeners();
    await _persistHistorial();
    await _persistXp();

    // Reto completado → premio y avance al siguiente objetivo (hasta 7).
    if (_retoObjetivo < 7 && _rachaActual() >= _retoObjetivo) {
      _retoObjetivo = _retoObjetivo == 3 ? 5 : 7;
      _xp += 100;
      _trace('entrenamiento', 'reto', detail: '$_retoObjetivo días');
      notifyListeners();
      await _prefs?.setInt(_retoKey, _retoObjetivo);
      await _persistXp();
    }
  }

  /// Si hoy ya se usó el anuncio recompensado (se otorga una vez por día).
  bool get recompensaAnuncioDisponibleHoy {
    final usado = _prefs?.getString(_recompensaAnuncioKey);
    return usado != _dayKey(DateTime.now());
  }

  /// Aplica la recompensa del anuncio visto: +[ptsRecompensaAnuncio] XP, una
  /// sola vez por día. Devuelve `false` si hoy ya se recibió.
  Future<bool> aplicarRecompensaAnuncio() async {
    final hoy = _dayKey(DateTime.now());
    if ((_prefs?.getString(_recompensaAnuncioKey)) == hoy) return false;
    await _prefs?.setString(_recompensaAnuncioKey, hoy);
    _xp += ptsRecompensaAnuncio;
    notifyListeners();
    await _persistXp();
    _trace('recompensa', 'anuncio', detail: '+$ptsRecompensaAnuncio XP');
    return true;
  }

  void _cargarHistorial() {
    final raw = _prefs?.getString(_historyKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        historial = (jsonDecode(raw) as List)
            .map((e) => WorkoutSession.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.fecha.compareTo(a.fecha));
      } catch (_) {
        historial = [];
      }
    }
    _xp = _prefs?.getInt(_xpKey) ?? 0;
    _retoObjetivo = _prefs?.getInt(_retoKey) ?? 3;
  }

  Future<void> _persistHistorial() async {
    await _prefs?.setString(
      _historyKey,
      jsonEncode(historial.map((s) => s.toJson()).toList()),
    );
  }

  Future<void> _persistXp() async {
    await _prefs?.setInt(_xpKey, _xp);
  }

  // =====================================================================
  //  Perfil y balance
  // =====================================================================

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