import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modo de tema de la app (Fase 7): sigue al sistema o fuerza claro/oscuro.
enum AppThemeMode { system, light, dark }

/// Versión de los Términos y EULA. Si cambia, se vuelve a pedir la
/// aceptación al usuario en el siguiente arranque.
/// v2 (Fase 8): añade las cláusulas de datos de salud (art. 9 GDPR), edad
/// mínima 16, publicidad/consentimiento y datos del comerciante.
const int kEulaVersion = 2;

/// Versión global de la app (se muestra en Perfil).
const String kAppVersion = '1.0.0';
const int kAppBuild = 1;

/// Configuración y feature-flags de FitPulse.
///
/// Centraliza los interruptores de funcionalidad (sensores ficticios,
/// anuncios, premium) y el consentimiento del EULA. Todo se persiste por
/// dispositivo mediante `shared_preferences`, sin backend.
class ConfigService extends ChangeNotifier {
  static const _eulaVersionKey = 'fitpulse_eula_version_v1';
  static const _adsKey = 'fitpulse_config_ads_v1';
  static const _premiumKey = 'fitpulse_config_premium_v1';
  static const _mockSensorsKey = 'fitpulse_config_mock_sensors_v1';
  static const _themeKey = 'fitpulse_theme_v1';

  SharedPreferences? _prefs;

  /// Versión del EULA aceptada por el usuario (0 si aún no acepta).
  int eulaAcceptedVersion = 0;

  /// Modo de tema elegido (Fase 7). Por defecto sigue al sistema.
  AppThemeMode _themeMode = AppThemeMode.system;

  /// Feature-flags. Por defecto en modo simulado mientras no existan
  /// sensores reales ni monetización activa.
  bool adsEnabled = true;
  bool premiumEnabled = false;
  bool mockSensorsEnabled = true;

  /// Si el usuario ya aceptó la versión vigente de los Términos/EULA.
  bool get eulaAccepted => eulaAcceptedVersion >= kEulaVersion;

  /// Modo de tema persistido (sistema / claro / oscuro).
  AppThemeMode get themeMode => _themeMode;

  /// Carga la configuración persistida del dispositivo.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    eulaAcceptedVersion = _prefs!.getInt(_eulaVersionKey) ?? 0;
    adsEnabled = (_prefs!.getInt(_adsKey) ?? 1) == 1;
    premiumEnabled = (_prefs!.getInt(_premiumKey) ?? 0) == 1;
    mockSensorsEnabled = (_prefs!.getInt(_mockSensorsKey) ?? 1) == 1;
    _themeMode = _leerModoTema(_prefs!.getString(_themeKey));
    notifyListeners();
  }

  static AppThemeMode _leerModoTema(String? nombre) {
    for (final modo in AppThemeMode.values) {
      if (modo.name == nombre) return modo;
    }
    return AppThemeMode.system;
  }

  /// Cambia el modo de tema en vivo y lo persiste.
  Future<void> setThemeMode(AppThemeMode modo) async {
    if (modo == _themeMode) return;
    _themeMode = modo;
    notifyListeners();
    await _prefs?.setString(_themeKey, modo.name);
  }

  /// Registra la aceptación del EULA con la versión vigente.
  Future<void> aceptarEula() async {
    eulaAcceptedVersion = kEulaVersion;
    notifyListeners();
    await _prefs?.setInt(_eulaVersionKey, kEulaVersion);
  }

  /// Fuerza la activación del Premium (evalúa de nuevo la monetización).
  Future<void> setPremium(bool active) async {
    premiumEnabled = active;
    notifyListeners();
    await _prefs?.setInt(_premiumKey, active ? 1 : 0);
  }

  /// Activa/desactiva la visualización de anuncios (consentimiento local del
  /// usuario, Fase 3). No afecta al flag persistido si ya hay Premium.
  Future<void> setAds(bool habilitados) async {
    adsEnabled = habilitados;
    notifyListeners();
    await _prefs?.setInt(_adsKey, habilitados ? 1 : 0);
  }

  // =====================================================================
  //  Fase 8: portabilidad (GDPR art. 20) y derecho al olvido (art. 17)
  // =====================================================================

  /// Configuración exportable (se incluye en el backup de datos).
  Map<String, dynamic> snapshotParaBackup() => {
        'ads': adsEnabled,
        'premium': premiumEnabled,
        'mock_sensors': mockSensorsEnabled,
        'tema': _themeMode.name,
        'eula_version': eulaAcceptedVersion,
      };

  /// Restaura la configuración desde un snapshot de backup.
  Future<void> aplicarBackup(Map<String, dynamic> snapshot) async {
    adsEnabled = snapshot['ads'] as bool? ?? adsEnabled;
    premiumEnabled = snapshot['premium'] as bool? ?? premiumEnabled;
    mockSensorsEnabled =
        snapshot['mock_sensors'] as bool? ?? mockSensorsEnabled;
    _themeMode = _leerModoTema(snapshot['tema'] as String?);
    eulaAcceptedVersion = snapshot['eula_version'] as int? ?? eulaAcceptedVersion;
    await _prefs?.setInt(_adsKey, adsEnabled ? 1 : 0);
    await _prefs?.setInt(_premiumKey, premiumEnabled ? 1 : 0);
    await _prefs?.setInt(_mockSensorsKey, mockSensorsEnabled ? 1 : 0);
    await _prefs?.setString(_themeKey, _themeMode.name);
    await _prefs?.setInt(_eulaVersionKey, eulaAcceptedVersion);
    notifyListeners();
  }

  /// Restablece la configuración en memoria tras un borrado total.
  void resetTrasBorrado() {
    eulaAcceptedVersion = 0;
    _themeMode = AppThemeMode.system;
    adsEnabled = true;
    premiumEnabled = false;
    mockSensorsEnabled = true;
    notifyListeners();
  }
}