import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/main.dart';
import 'package:fitpulse/screens/workout_builder_screen.dart';
import 'package:fitpulse/screens/workout_player_screen.dart';
import 'package:fitpulse/services/config_service.dart';
import 'package:fitpulse/services/locale_service.dart';
import 'package:fitpulse/state/app_state.dart';
import 'package:fitpulse/theme.dart';
import 'package:fitpulse/widgets/fit_nav_bar.dart';
import 'package:fitpulse/widgets/boton_entrenar.dart';

/// Botón flotante "Entrenar": abre una hoja con tres salidas reales y no
/// arranca ninguna sesión con un solo toque.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppColors.activate(lightFitPalette);
  });

  Future<(AppState, LocaleService, ConfigService)> servicios() async {
    final state = AppState();
    await state.init();
    final locale = LocaleService();
    await locale.init();
    final config = ConfigService();
    await config.init();
    return (state, locale, config);
  }

  Widget envolver(
    Widget child, {
    required AppState state,
    required LocaleService locale,
    required ConfigService config,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: state),
        ChangeNotifierProvider<LocaleService>.value(value: locale),
        ChangeNotifierProvider<ConfigService>.value(value: config),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('el FAB abre la hoja con el plan real, rutinas y crear rutina',
      (tester) async {
    final (state, locale, config) = await servicios();
    final recomendado = state.entrenamientoRecomendado;

    await tester.pumpWidget(envolver(
      const Scaffold(floatingActionButton: BotonEntrenar()),
      state: state,
      locale: locale,
      config: config,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Entrenar'), findsOneWidget);
    await tester.tap(find.byType(BotonEntrenar));
    await tester.pumpAndSettle();

    expect(find.text('¿Qué entrenamos hoy?'), findsOneWidget);
    // El plan de hoy es el real del estado, nunca uno inventado.
    expect(find.textContaining(recomendado.nombre), findsOneWidget);
    expect(find.text('Entrenamiento de hoy'), findsOneWidget);
    expect(find.text('Mis rutinas'), findsOneWidget);
    expect(find.text('Nueva rutina'), findsOneWidget);
    // Sin rutinas guardadas, el detalle es honesto (no "0 rutinas").
    expect(find.text('Todavía no has creado ninguna rutina.'), findsOneWidget);
    expect(find.textContaining('0 rutinas'), findsNothing);
  });

  testWidgets('"Mis rutinas" abre la lista de rutinas', (tester) async {
    final (state, locale, config) = await servicios();

    await tester.pumpWidget(envolver(
      const Scaffold(floatingActionButton: BotonEntrenar()),
      state: state,
      locale: locale,
      config: config,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BotonEntrenar));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mis rutinas'));
    await tester.pumpAndSettle();

    expect(find.byType(MisRutinasScreen), findsOneWidget);
  });

  testWidgets('"Nueva rutina" abre el editor vacío', (tester) async {
    final (state, locale, config) = await servicios();

    await tester.pumpWidget(envolver(
      const Scaffold(floatingActionButton: BotonEntrenar()),
      state: state,
      locale: locale,
      config: config,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BotonEntrenar));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nueva rutina'));
    await tester.pumpAndSettle();

    expect(find.byType(RutinaEditorScreen), findsOneWidget);
    // Editor en modo creación: no trae una rutina existente cargada.
    final editor =
        tester.widget<RutinaEditorScreen>(find.byType(RutinaEditorScreen));
    expect(editor.rutina, isNull);
  });

  testWidgets('"Entrenamiento de hoy" abre el reproductor', (tester) async {
    final (state, locale, config) = await servicios();

    await tester.pumpWidget(envolver(
      const Scaffold(floatingActionButton: BotonEntrenar()),
      state: state,
      locale: locale,
      config: config,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BotonEntrenar));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrenamiento de hoy'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(WorkoutPlayerScreen), findsOneWidget);

    // Desmonta el árbol para cancelar el temporizador del reproductor.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('el FAB está en el shell y se oculta en Ayuda', (tester) async {
    final (state, locale, config) = await servicios();

    await tester.pumpWidget(envolver(
      const AppShell(),
      state: state,
      locale: locale,
      config: config,
    ));
    await tester.pumpAndSettle();

    expect(find.byType(BotonEntrenar), findsOneWidget);

    Finder enNav(String texto) => find.descendant(
          of: find.byType(FitNavBar),
          matching: find.text(texto),
        );

    await tester.tap(enNav('Ayuda'));
    await tester.pumpAndSettle();
    expect(find.byType(BotonEntrenar), findsNothing);

    await tester.tap(enNav('Inicio'));
    await tester.pumpAndSettle();
    expect(find.byType(BotonEntrenar), findsOneWidget);
  });
}
