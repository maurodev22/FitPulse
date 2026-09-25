import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modo de tema de la app (Fase 7): sigue al sistema o fuerza claro/oscuro.
enum AppThemeMode { system, light, dark }

/// Versión de los Términos y EULA. Si cambia, se vuelve a pedir la
/// aceptación al usuario en el siguiente arranque.
const int kEulaVersion = 1;

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
}