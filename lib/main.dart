import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'screens/eula_screen.dart';
import 'screens/help_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/recipes_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/tips_screen.dart';
import 'services/ads_service.dart';
import 'services/avisos_service.dart';
import 'services/config_service.dart';
import 'services/health_service.dart';
import 'services/home_widget_service.dart';
import 'services/locale_service.dart';
import 'services/usage_log_service.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'widgets/fit_nav_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carga sesión, idioma y configuración antes de pintar la primera vista.
  final appState = AppState();
  await appState.init();
  // Registro de uso anónimo (local, sin identificar al usuario).
  final usageLog = UsageLogService();
  await usageLog.init();
  appState.setUsageLog(usageLog);
  // Conecta el sensor real de pasos del teléfono.
  appState.attachHealthSource(PhoneStepSource());
  // Health Connect (Fase 1): detecta, pide permisos una vez y lee métricas.
  // No bloquea el arranque: se completa en segundo plano.
  appState.setHealthConnect(HealthConnectService());
  unawaited(appState.initHealthConnect());
  final localeService = LocaleService();
  await localeService.init();
  final configService = ConfigService();
  await configService.init();
  usageLog.log('app', 'inicio');
  // AdMob (Fase 3): se inicializa en segundo plano si los anuncios están
  // activos y el usuario no tiene Premium. Nunca bloquea el arranque.
  if (configService.adsEnabled && !configService.premiumEnabled) {
    unawaited(initAds());
  }
  // Fase 6: avisos locales (hidratación + racha en riesgo) según los toggles
  // persistidos del perfil; un único flujo serializado pide el permiso una sola
  // vez y, si se deniega, no se programa nada (honesto, nunca se finge activo).
  unawaited(
    avisosService.sincronizar(
      hidratacion: appState.isLoggedIn && appState.profile.hidratacion,
      racha: appState.isLoggedIn && appState.profile.entrenamientoMatutino,
      rachaDias: appState.rachaDias,
    ),
  );
  // Fase 6: widget de home — snapshot con datos reales (pasos, calorías, racha).
  final widgetBridge = HomeWidgetBridge(appState);
  widgetBridge.sincronizarAhora();
  // Zona de anuncio visible cuando el banner de prueba no carga (sin red a
  // AdMob). Solo en la app real; los tests no llaman a main().
  FitBannerAd.mostrarPlaceholderCuandoFalla = true;

  runApp(FitPulseApp(
    appState: appState,
    localeService: localeService,
    configService: configService,
  ));
}

/// Raíz de FitPulse: provee el estado global y elige pantalla inicial
/// en función de la sesión, del idioma y del consentimiento EULA.
class FitPulseApp extends StatelessWidget {
  const FitPulseApp({super.key, this.appState, this.localeService, this.configService});

  /// Estados inyectables (útil en tests). Si no se pasan, se crean.
  final AppState? appState;
  final LocaleService? localeService;
  final ConfigService? configService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>(
          create: (_) => appState ?? (AppState()..init()),
        ),
        ChangeNotifierProvider<LocaleService>(
          create: (_) => localeService ?? (LocaleService()..init()),
        ),
        ChangeNotifierProvider<ConfigService>(
          create: (_) => configService ?? (ConfigService()..init()),
        ),
      ],
      child: Consumer<LocaleService>(
        builder: (context, locale, _) => MaterialApp(
          title: 'FitPulse',
          debugShowCheckedModeBanner: false,
          locale: locale.locale == AppLocale.en ? const Locale('en') : const Locale('es'),
          supportedLocales: const [Locale('es'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: buildFitPulseTheme(),
          scrollBehavior: const NoGlowScrollBehavior(),
          home: const _Bootstrap(),
        ),
      ),
    );
  }
}

/// Decide entre EULA, onboarding y shell principal según sesión y términos.
class _Bootstrap extends StatelessWidget {
  const _Bootstrap();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final config = context.watch<ConfigService>();
    if (!config.eulaAccepted) return const EulaScreen();
    return appState.isLoggedIn ? const AppShell() : const RegistrationScreen();
  }
}

/// Contenedor con barra de navegación inferior y las 5 secciones (IndexedStack).
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  FitTab _current = FitTab.home;

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigService>();
    // Fase 3: banner de anuncios solo si están activos y sin Premium.
    final mostrarBanner = config.adsEnabled && !config.premiumEnabled;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _current.index,
        children: [
          const HomeScreen(),
          const RecipesScreen(),
          const ProgressScreen(),
          const TipsScreen(),
          const ProfileScreen(),
          const HelpScreen(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mostrarBanner) const FitBannerAd(),
          FitNavBar(
            current: _current,
            onChanged: (tab) {
              context.read<AppState>().traceTab(tab.nombre);
              setState(() => _current = tab);
            },
          ),
        ],
      ),
    );
  }
}