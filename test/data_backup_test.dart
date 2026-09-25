import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/services/config_service.dart';
import 'package:fitpulse/services/data_backup_service.dart';
import 'package:fitpulse/services/locale_service.dart';
import 'package:fitpulse/state/app_state.dart';
import 'package:fitpulse/state/athlete_profile.dart';

/// Fase 8: cobertura de portabilidad (GDPR art. 20) y derecho al olvido
/// (art. 17): exportar JSON legible, importar con validación y borrado total.

/// Crea un estado con datos reales (perfil, balance, historial, favoritas).
Future<AppState> _estadoConDatos() async {
  final s = AppState();
  await s.init();
  await s.guardarPerfil(
    AthleteProfile(
      nombre: 'Ana Pérez',
      edad: 32,
      sexo: 'Femenino',
      pesoKg: 58.5,
      alturaM: 1.62,
      metas: const ['Bajar de peso'],
      nivel: 'Avanzado',
      diasEntrenamiento: const ['L', 'M', 'X', 'J', 'V', 'S'],
      hidratacion: true,
      entrenamientoMatutino: false,
      healthKit: true,
      vibracion: false,
      compartirActividad: true,
    ),
  );
  await s.registrarConsumo(
    calorias: 1234,
    proteinas: 87,
    carbos: 150,
    grasas: 40,
  );
  await s.registrarSesionCompletada(
    nombre: 'Sentadillas',
    duracion: const Duration(minutes: 32),
    calorias: 245,
  );
  await s.toggleFavorita('Batido de Avena');
  return s;
}

Future<ConfigService> _configInicializado() async {
  final c = ConfigService();
  await c.init();
  return c;
}

Future<LocaleService> _localeInicializado() async {
  final l = LocaleService();
  await l.init();
  return l;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('exportarJson genera un JSON de portabilidad con todos los bloques',
      () async {
    final s = await _estadoConDatos();
    final servicio = DataBackupService(
      appState: s,
      config: await _configInicializado(),
      locale: await _localeInicializado(),
    );

    final json = servicio.exportarJson(creado: '2026-09-25T10:00:00.000');
    final datos = jsonDecode(json) as Map<String, dynamic>;

    expect(datos['fitpulse_backup'], 1);
    expect(datos['app'], 'FitPulse');
    expect(datos['creado'], '2026-09-25T10:00:00.000');
    expect(datos['idioma'], 'es');
    expect(datos['config'], isA<Map<String, dynamic>>());

    final estado = datos['estado'] as Map<String, dynamic>;
    expect(estado['perfil'], isA<String>());
    expect(estado['balance'], isA<Map<String, dynamic>>());
    expect(estado['historial'], isA<List<dynamic>>());
    expect(estado['xp'], 50);
    expect((estado['favoritas'] as List).contains('Batido de Avena'), isTrue);
  });

  test('round-trip export→import restaura exactamente el estado', () async {
    final a = await _estadoConDatos();
    final ca = await _configInicializado();
    final la = await _localeInicializado();
    final json = DataBackupService(appState: a, config: ca, locale: la)
        .exportarJson(creado: '2026-09-25T10:00:00.000');

    // Estado nuevo "limpio" que recibe el import.
    SharedPreferences.setMockInitialValues({});
    final b = AppState();
    await b.init();
    final servicio = DataBackupService(
      appState: b,
      config: await _configInicializado(),
      locale: await _localeInicializado(),
    );
    final r = await servicio.importarJson(json);
    expect(r.ok, isTrue);
    expect(r.mensaje, 'ok');

    expect(b.isLoggedIn, isTrue);
    expect(b.profile.nombre, 'Ana Pérez');
    expect(b.profile.edad, 32);
    expect(b.profile.pesoKg, 58.5);
    expect(b.profile.alturaM, 1.62);
    expect(b.profile.metas, contains('Bajar de peso'));
    expect(b.profile.nivel, 'Avanzado');
    expect(b.profile.diasEntrenamiento, ['L', 'M', 'X', 'J', 'V', 'S']);
    expect(b.profile.compartirActividad, isTrue);
    expect(b.caloriasConsumidas, 1234);
    expect(b.proteinasConsumidas, 87);
    expect(b.carbosConsumidos, 150);
    expect(b.grasasConsumidas, 40);
    expect(b.historial, hasLength(1));
    expect(b.historial.single.nombre, 'Sentadillas');
    expect(b.historial.single.duracionMin, 32);
    expect(b.historial.single.calorias, 245);
    expect(b.xp, a.xp);
    expect(b.favoritas, contains('Batido de Avena'));
  });

  test('el import restaura también la configuración exportada', () async {
    final c = await _configInicializado();
    await c.aceptarEula();
    await c.setPremium(true);
    await c.setAds(false);
    await c.setThemeMode(AppThemeMode.dark);
    final l = await _localeInicializado();
    final s = AppState();
    await s.init();
    final json = DataBackupService(appState: s, config: c, locale: l)
        .exportarJson();

    SharedPreferences.setMockInitialValues({});
    final c2 = await _configInicializado();
    final s2 = AppState();
    await s2.init();
    final servicio = DataBackupService(
      appState: s2,
      config: c2,
      locale: await _localeInicializado(),
    );
    expect((await servicio.importarJson(json)).ok, isTrue);
    expect(c2.premiumEnabled, isTrue);
    expect(c2.adsEnabled, isFalse);
    expect(c2.themeMode, AppThemeMode.dark);
    expect(c2.eulaAcceptedVersion, kEulaVersion);
    expect(c2.eulaAccepted, isTrue);
  });

  test('importarJson rechaza backups inválidos sin tocar el estado', () async {
    final s = AppState();
    await s.init();
    final servicio = DataBackupService(
      appState: s,
      config: await _configInicializado(),
      locale: await _localeInicializado(),
    );

    expect((await servicio.importarJson('esto no es json')).ok, isFalse);
    expect((await servicio.importarJson('')).ok, isFalse);
    final versionAntigua = jsonEncode(
      <String, dynamic>{'fitpulse_backup': 0, 'estado': <String, dynamic>{}},
    );
    expect((await servicio.importarJson(versionAntigua)).ok, isFalse);
    expect((await servicio.importarJson(jsonEncode({'foo': 1}))).ok, isFalse);
    final sinEstado = jsonEncode(<String, dynamic>{'fitpulse_backup': 1});
    expect((await servicio.importarJson(sinEstado)).ok, isFalse);

    // Ningún import inválido debe llegar a crear una sesión.
    expect(s.isLoggedIn, isFalse);
    expect(s.historial, isEmpty);
  });

  test('export a fichero y re-import por disco funcionan (round-trip)',
      () async {
    final dir = await Directory.systemTemp.createTemp('fitpulse_backup_test');
    addTearDown(() => dir.delete(recursive: true));
    // Un fichero ajeno no debe listarse como backup.
    await File('${dir.path}/notas.txt').writeAsString('hola');

    final a = await _estadoConDatos();
    final sa = DataBackupService(
      appState: a,
      config: await _configInicializado(),
      locale: await _localeInicializado(),
    );
    final fichero = await sa.exportarArchivo(
      directorio: dir,
      fecha: DateTime(2026, 9, 25, 10, 5),
    );
    expect(fichero.existsSync(), isTrue);

    final backups = await sa.listarBackups(directorio: dir);
    expect(backups, hasLength(1));
    expect(backups.single.path, fichero.path);

    SharedPreferences.setMockInitialValues({});
    final b = AppState();
    await b.init();
    final sb = DataBackupService(
      appState: b,
      config: await _configInicializado(),
      locale: await _localeInicializado(),
    );
    final r = await sb.importarArchivo(fichero);
    expect(r.ok, isTrue);
    expect(b.profile.nombre, 'Ana Pérez');
    expect(b.historial, hasLength(1));
    expect(b.favoritas, contains('Batido de Avena'));
  });

  test('nombreArchivo usa prefijo y marca de tiempo', () {
    expect(
      DataBackupService.nombreArchivo(DateTime(2026, 9, 25, 10, 5)),
      'fitpulse_backup_20260925_1005.json',
    );
    expect(
      DataBackupService.nombreArchivo(DateTime(2026, 1, 2, 3, 4)),
      'fitpulse_backup_20260102_0304.json',
    );
  });

  test('borrarTodo deja el dispositivo limpio (derecho al olvido, art. 17)',
      () async {
    final s = await _estadoConDatos();
    final c = await _configInicializado();
    await c.aceptarEula();
    final l = await _localeInicializado();
    await l.setLocale(AppLocale.en);
    final servicio = DataBackupService(appState: s, config: c, locale: l);
    expect(s.isLoggedIn, isTrue);

    await servicio.borrarTodo();

    expect(s.isLoggedIn, isFalse);
    expect(s.profile.nombre, isEmpty);
    expect(s.historial, isEmpty);
    expect(s.favoritas, isEmpty);
    expect(s.caloriasConsumidas, 0);
    expect(s.xp, 0);
    expect(c.eulaAcceptedVersion, 0);
    expect(c.eulaAccepted, isFalse);
    expect(l.locale, AppLocale.es);

    // El almacén de preferencias (exclusivo de la app) queda vacío.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isEmpty);
  });
}