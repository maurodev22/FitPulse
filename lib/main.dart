import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/recipes_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/tips_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'widgets/fit_nav_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carga la sesión persistida del dispositivo antes de pintar cualquier vista.
  final appState = AppState();
  await appState.init();

  runApp(FitPulseApp(appState: appState));
}

/// Raíz de FitPulse: provee el estado global y elige pantalla inicial
/// en función de si existe una sesión guardada en el móvil.
class FitPulseApp extends StatelessWidget {
  const FitPulseApp({super.key, this.appState});

  /// Estado opcional inyectable (útil en tests). Si no se pasa, se crea uno.
  final AppState? appState;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>(
      create: (_) => appState ?? (AppState()..init()),
      child: MaterialApp(
        title: 'FitPulse',
        debugShowCheckedModeBanner: false,
        theme: buildFitPulseTheme(),
        home: _Bootstrap(),
      ),
    );
  }
}

/// Decide entre onboarding y shell principal según la sesión persistida.
class _Bootstrap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
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
        ],
      ),
      bottomNavigationBar: FitNavBar(
        current: _current,
        onChanged: (tab) => setState(() => _current = tab),
      ),
    );
  }
}