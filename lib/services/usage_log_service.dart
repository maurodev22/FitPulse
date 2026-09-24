import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Registro de uso local y anónimo de FitPulse.
///
/// Guarda eventos (navegación, pestañas, acciones) en el propio dispositivo
/// con `shared_preferences`. No envía nada a la red ni almacena identificadores
/// personales: solo etiquetas de acción y fecha/hora. Útil para diagnosticar
/// incidencias en la demo sin vulnerar la privacidad.
class UsageLogService {
  static const _logKey = 'fitpulse_usage_log_v1';
  static const int _maxEntries = 200;

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Registra una acción anónima. `category` (pestaña/área) y `action`
  /// (verbos como 'abrir', 'activar', 'toggle').
  Future<void> log(String category, String action, {String? detail}) async {
    final entry = {
      't': DateTime.now().millisecondsSinceEpoch,
      'c': category,
      'a': action,
      'd': ?detail,
    };
    final entries = await _read();
    entries.add(entry);
    // Mantiene el tamaño acotado descartando los eventos más antiguos.
    if (entries.length > _maxEntries) {
      entries.removeRange(0, entries.length - _maxEntries);
    }
    await _prefs?.setString(_logKey, jsonEncode(entries));
  }

  Future<List<Map<String, Object?>>> _read() async {
    final raw = _prefs?.getString(_logKey);
    if (raw == null || raw.isEmpty) return <Map<String, Object?>>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Map<String, Object?>.from(e as Map<dynamic, dynamic>))
          .toList();
    } on FormatException {
      return <Map<String, Object?>>[];
    }
  }

  /// Devuelve los eventos registrados (para depuración/verificación).
  Future<List<Map<String, Object?>>> entries() => _read();

  /// Vacía el registro (uso de pruebas).
  Future<void> clear() async {
    await _prefs?.remove(_logKey);
  }
}