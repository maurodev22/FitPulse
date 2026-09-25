import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../state/app_state.dart';
import 'config_service.dart';
import 'locale_service.dart';

/// Resultado de una operación de import/export de datos (Fase 8).
///
/// `mensaje` es una clave máquina ('ok'/'invalido') que la UI traduce al
/// idioma activo; así el servicio permanece ajeno a la localización.
class BackupResultado {
  const BackupResultado({required this.ok, required this.mensaje});

  final bool ok;
  final String mensaje;
}

/// Servicio de backup y privacidad (Fase 8).
///
/// - **Export**: genera un JSON legible, estructurado e interoperable con
///   todos los datos del usuario (portabilidad, GDPR art. 20). Nada de
///   inventado: solo lo que realmente existe en el dispositivo.
/// - **Import**: valida el formato del backup y restaura el estado, previa
///   confirmación del usuario en la UI (nunca sobreescribe sin avisar).
/// - **Borrado total**: limpia `shared_preferences` y restablece el estado en
///   memoria (derecho al olvido, GDPR art. 17). El almacén de preferencias es
///   exclusivo de FitPulse, así que `clear()` no toca datos de otras apps.
class DataBackupService {
  DataBackupService({
    required this.appState,
    required this.config,
    required this.locale,
  });

  final AppState appState;
  final ConfigService config;
  final LocaleService locale;

  /// Versión del formato de backup. El import rechaza versiones distintas
  /// para no aplicar un formato mal interpretado.
  static const int version = 1;

  /// Prefijo de los ficheros de backup dentro del directorio de documentos.
  static const String prefijoFichero = 'fitpulse_backup_';

  /// Construye el JSON legible del backup con todos los datos del usuario.
  String exportarJson({String? creado}) {
    final datos = <String, dynamic>{
      'fitpulse_backup': version,
      'app': 'FitPulse',
      'creado': creado ?? DateTime.now().toIso8601String(),
      'idioma': locale.locale.name,
      'config': config.snapshotParaBackup(),
      'estado': appState.snapshotParaBackup(),
    };
    return const JsonEncoder.withIndent('  ').convert(datos);
  }

  /// Valida un JSON y lo devuelve como mapa si es un backup FitPulse de la
  /// versión vigente; `null` si el formato no es válido (evita corromper el
  /// estado con ficheros ajenos o malformados).
  static Map<String, dynamic>? validar(String json) {
    if (json.trim().isEmpty) return null;
    try {
      final decodificado = jsonDecode(json);
      if (decodificado is! Map<String, dynamic>) return null;
      if (decodificado['fitpulse_backup'] != version) return null;
      if (decodificado['estado'] is! Map<String, dynamic>) return null;
      return decodificado;
    } on FormatException {
      return null;
    }
  }

  /// Importa un backup desde un string JSON.
  Future<BackupResultado> importarJson(String json) async {
    final datos = validar(json);
    if (datos == null) {
      return const BackupResultado(ok: false, mensaje: 'invalido');
    }
    await appState.aplicarBackup(
      Map<String, dynamic>.from(datos['estado'] as Map),
    );
    final cfg = datos['config'];
    if (cfg is Map<String, dynamic>) {
      await config.aplicarBackup(cfg);
    }
    return const BackupResultado(ok: true, mensaje: 'ok');
  }

  /// Nombre de fichero por defecto para un backup (con marca de tiempo).
  static String nombreArchivo(DateTime fecha) {
    final ts = '${fecha.year.toString().padLeft(4, '0')}'
        '${fecha.month.toString().padLeft(2, '0')}'
        '${fecha.day.toString().padLeft(2, '0')}'
        '_'
        '${fecha.hour.toString().padLeft(2, '0')}'
        '${fecha.minute.toString().padLeft(2, '0')}';
    return '$prefijoFichero$ts.json';
  }

  /// Escribe el backup en disco (por defecto en los documentos de la app) y
  /// devuelve el fichero creado.
  Future<File> exportarArchivo({DateTime? fecha, Directory? directorio}) async {
    final dir = directorio ?? await getApplicationDocumentsDirectory();
    final momento = fecha ?? DateTime.now();
    final fichero = File(
      '${dir.path}${Platform.pathSeparator}${nombreArchivo(momento)}',
    );
    await fichero.writeAsString(
      exportarJson(creado: momento.toIso8601String()),
    );
    return fichero;
  }

  /// Ficheros de backup disponibles en el directorio (más reciente primero).
  Future<List<File>> listarBackups({Directory? directorio}) async {
    final dir = directorio ?? await getApplicationDocumentsDirectory();
    if (!dir.existsSync()) return <File>[];
    final ficheros = dir
        .listSync()
        .whereType<File>()
        .where((f) {
          final nombre = f.path.split(RegExp(r'[/\\]')).last;
          return nombre.startsWith(prefijoFichero) && nombre.endsWith('.json');
        })
        .toList();
    ficheros.sort((a, b) => b.path.compareTo(a.path));
    return ficheros;
  }

  /// Importa un fichero de backup desde disco.
  Future<BackupResultado> importarArchivo(File fichero) async {
    try {
      return await importarJson(await fichero.readAsString());
    } catch (_) {
      return const BackupResultado(ok: false, mensaje: 'invalido');
    }
  }

  /// Derecho al olvido (GDPR art. 17): borra todos los datos del dispositivo
  /// — `shared_preferences` (exclusivo de la app) y el estado en memoria.
  Future<void> borrarTodo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    appState.resetTrasBorrado();
    config.resetTrasBorrado();
    locale.resetTrasBorrado();
  }
}