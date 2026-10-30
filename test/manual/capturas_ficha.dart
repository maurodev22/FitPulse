import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/main.dart';
import 'package:fitpulse/services/config_service.dart';
import 'package:fitpulse/services/locale_service.dart';
import 'package:fitpulse/state/app_state.dart';
import 'package:fitpulse/state/athlete_profile.dart';

/// Genera las capturas de la ficha de Play Store sin emulador.
///
/// No forma parte de `flutter test` (vive en `tool/`). Se ejecuta a mano:
///
///   flutter test tool/capturas_ficha_test.dart
///
/// Escribe `docs/store_assets/capturas/cap_*.png` a 1080x2400 con datos de
/// demostración creados con la propia API de la app (historial, agua, peso).
/// Los datos de salud que muestra la app en uso nunca se inventan: esto es
/// material de ficha, no un estado de la app real.
void main() {
  const anchoFisico = 1080.0;
  const altoFisico = 2400.0;
  const dpr = 2.625; // 1080x2400 a 411x914 lógicos (como el Pixel 6a)

  Future<void> cargarFuentes() async {
    Future<void> familia(String nombre, List<String> rutas) async {
      final loader = FontLoader(nombre);
      for (final ruta in rutas) {
        loader.addFont(rootBundle.load(ruta));
      }
      await loader.load();
    }

    await familia('Inter', const [
      'assets/fonts/Inter-400.ttf',
      'assets/fonts/Inter-500.ttf',
      'assets/fonts/Inter-600.ttf',
      'assets/fonts/Inter-700.ttf',
    ]);
    await familia('PlusJakartaSans', const [
      'assets/fonts/PlusJakartaSans-600.ttf',
      'assets/fonts/PlusJakartaSans-700.ttf',
      'assets/fonts/PlusJakartaSans-800.ttf',
    ]);
  }

  Future<void> bombear(WidgetTester tester) async {
    // pumpAndSettle puede colgarse con animaciones infinitas (shimmer).
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('capturas de ficha', timeout: const Timeout(Duration(seconds: 120)),
      (tester) async {
    await cargarFuentes();
    SharedPreferences.setMockInitialValues({});

    final appState = AppState();
    await appState.init();
    await appState.guardarPerfil(
      const AthleteProfile(
        nombre: 'Ana',
        edad: 29,
        sexo: 'Femenino',
        pesoKg: 64,
        alturaM: 1.68,
        metas: ['Definir', 'Mantener'],
        nivel: 'Intermedio',
        caloriasMeta: 2000,
        pasosMeta: 9000,
      ),
    );

    final hoy = DateTime.now();
    for (var i = 6; i >= 0; i--) {
      if (i == 2) continue; // un día de descanso real en el gráfico
      final dia = DateTime(hoy.year, hoy.month, hoy.day - i);
      await appState.registrarSesionCompletada(
        nombre: i.isEven ? 'Fuerza total' : 'Cardio HIIT',
        duracion: Duration(minutes: 25 + (i * 3) % 20),
        calorias: 180 + (i * 17) % 90,
        fecha: dia,
      );
      await appState.registrarAgua(1.6 + (i % 3) * 0.2);
    }
    await appState.registrarPeso(63.4);

    final locale = LocaleService();
    await locale.init();
    final config = ConfigService();
    await config.init();
    await config.aceptarEula();
    await config.setAds(false); // ficha limpia: sin banner de prueba
    await config.setThemeMode(AppThemeMode.light);

    tester.view.physicalSize = const Size(anchoFisico, altoFisico);
    tester.view.devicePixelRatio = dpr;
    addTearDown(tester.view.reset);

    final clave = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: clave,
        child: FitPulseApp(
          appState: appState,
          localeService: locale,
          configService: config,
        ),
      ),
    );
    await bombear(tester);

    Future<void> captura(String nombre, {bool soloTemp = false}) async {
      final boundary = clave.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      // toImage necesita el bucle real: sin runAsync la prueba se bloquea.
      final resultado = await tester.runAsync(() async {
        final imagen = await boundary.toImage(pixelRatio: dpr);
        final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
        final bytes = datos!.buffer.asUint8List();
        final directorio = soloTemp
            ? Directory.systemTemp.createTempSync('fitpulse_captura_')
            : (Directory('docs/store_assets/capturas')..createSync(recursive: true));
        final archivo = File('${directorio.path}/$nombre.png');
        archivo.writeAsBytesSync(bytes);
        final ancho = imagen.width;
        final alto = imagen.height;
        imagen.dispose();
        return '$nombre -> ${ancho}x$alto · ${bytes.length} B (${archivo.path})';
      });
      // ignore: avoid_print
      print(resultado);
    }

    await captura('cap_home');

    Future<void> irA(String etiqueta) async {
      // ignore: avoid_print
      print('-> tocar $etiqueta');
      await tester.tap(find.text(etiqueta).last, warnIfMissed: false);
      // ignore: avoid_print
      print('-> tocado $etiqueta');
      await bombear(tester);
      // ignore: avoid_print
      print('-> pintado $etiqueta');
    }

    await irA('Recetas');
    await captura('cap_recetas');

    await irA('Progreso');
    await captura('cap_progreso');

    await irA('Consejos');
    await captura('cap_consejos');

    await irA('Perfil');
    await captura('cap_perfil');

    // Comprobación del marco del FAB (no se publica): tema oscuro → anillo
    // blanco. Se guarda en la carpeta temporal para revisarlo por píxeles.
    await config.setThemeMode(AppThemeMode.dark);
    await bombear(tester);
    await irA('Inicio');
    await captura('fab_oscuro', soloTemp: true);

    expect(tester.takeException(), isNull);
  });
}
