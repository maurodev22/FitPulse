import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/main.dart';
import 'package:fitpulse/services/config_service.dart';
import 'package:fitpulse/services/locale_service.dart';
import 'package:fitpulse/state/app_state.dart';
import 'package:fitpulse/state/athlete_profile.dart';

/// Capturas de la ficha de Play Store (no forma parte de `flutter test`).
///
/// Se ejecuta en un dispositivo o emulador real con:
///
///   flutter drive --driver test_driver/capturas_driver.dart `
///     --target integration_test/capturas_ficha_test.dart -d emulator-5554
///
/// Genera `docs/store_assets/capturas/cap_*.png` (1080 px de ancho en el
/// emulador). Los datos son de demostración y se generan con la propia API de
/// la app (historial, agua, peso), no se inyectan números a mano en la UI.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capturas de la ficha (claro)', (tester) async {
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

    // Semana real de actividad usando la API de la app (racha, XP, gráfico).
    final hoy = DateTime.now();
    for (var i = 6; i >= 0; i--) {
      final dia = DateTime(hoy.year, hoy.month, hoy.day - i);
      if (i == 2) continue; // un día de descanso: la racha se corta y se ve.
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
    await config.setAds(false); // ficha sin banner de prueba
    await config.setThemeMode(AppThemeMode.light);

    await tester.pumpWidget(
      FitPulseApp(
        appState: appState,
        localeService: locale,
        configService: config,
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('cap_home');

    Future<void> irA(String etiqueta) async {
      await tester.tap(find.text(etiqueta).last);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    await irA('Recetas');
    await binding.takeScreenshot('cap_recetas');

    await irA('Progreso');
    await binding.takeScreenshot('cap_progreso');

    await irA('Consejos');
    await binding.takeScreenshot('cap_consejos');

    await irA('Perfil');
    await binding.takeScreenshot('cap_perfil');
  });
}
