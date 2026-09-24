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
import 'services/config_service.dart';
import 'services/health_service.dart';
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
  final localeService = LocaleService();
  await localeService.init();
  final configService = ConfigService();
  await configService.init();
  usageLog.log('app', 'inicio');

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
      bottomNavigationBar: FitNavBar(
        current: _current,
        onChanged: (tab) {
          context.read<AppState>().traceTab(tab.nombre);
          setState(() => _current = tab);
        },
      ),
    );
  }
}