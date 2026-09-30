import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/screens/profile_screen.dart';
import 'package:fitpulse/services/config_service.dart';
import 'package:fitpulse/services/locale_service.dart';
import 'package:fitpulse/state/app_state.dart';
import 'package:fitpulse/theme.dart';

/// Ajustes de la sesión (Perfil) tras la verificación en Pixel:
/// - El Perfil refleja el peso real registrado en Progreso (hero en vivo).
/// - "Datos Personales" ya no se repite: quedan solo nivel + preferencias.
/// - Mínimo 2 días de entrenamiento obligatorios.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpPerfil(
    WidgetTester tester, {
    required AppState state,
    required LocaleService locale,
    required ConfigService config,
  }) async {
    AppColors.activate(darkFitPalette);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: state),
          ChangeNotifierProvider<LocaleService>.value(value: locale),
          ChangeNotifierProvider<ConfigService>.value(value: config),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
      'P9: el hero del Perfil muestra el peso en vivo del estado (Progreso → Perfil)',
      (tester) async {
    final state = AppState();
    await state.init();
    await state.guardarPerfil(
      state.profile.copyWith(pesoKg: 72.5, alturaM: 1.70),
    );
    final locale = LocaleService();
    await locale.init();
    final config = ConfigService();
    await config.init();

    await pumpPerfil(tester, state: state, locale: locale, config: config);

    // El hero pinta el peso una sola vez (la info personal ya no se duplica).
    expect(find.text('72.5'), findsOneWidget);

    // Un registro nuevo de peso (p. ej. desde la vista Progreso) se refleja
    // al instante en el hero sin re-guardar nada en Perfil.
    await state.registrarPeso(74.2, fecha: DateTime(2026, 9, 30));
    await tester.pumpAndSettle();
    expect(find.text('74.2'), findsOneWidget);
    expect(find.text('72.5'), findsNothing);
  });

  testWidgets('P9: el Perfil ya no repite "Datos Personales"', (tester) async {
    final state = AppState();
    await state.init();
    final locale = LocaleService();
    await locale.init();
    final config = ConfigService();
    await config.init();

    await pumpPerfil(tester, state: state, locale: locale, config: config);

    // Nivel y preferencias se conservan; la tarjeta duplicada desaparece.
    expect(find.text('Nivel y preferencias'), findsOneWidget);
    expect(find.text('Datos Personales'), findsNothing);
  });

  testWidgets('P10: no se puede bajar de 2 días de entrenamiento',
      (tester) async {
    final state = AppState();
    await state.init(); // default 5 días: L M X J V
    final locale = LocaleService();
    await locale.init();
    final config = ConfigService();
    await config.init();

    await pumpPerfil(tester, state: state, locale: locale, config: config);

    // La tarjeta de días vive bajo el pliegue del ListView.
    await tester.scrollUntilVisible(find.text('Días de entrenamiento'), 200);
    await tester.pumpAndSettle();

    // Quitar 3 días (L, M, X) → quedan J y V (2).
    await tester.tap(find.text('L'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('M'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    expect(find.text('2 días / semana'), findsOneWidget);

    // Intentar quitar el penúltimo día se bloquea con aviso honesto.
    await tester.tap(find.text('J'));
    await tester.pumpAndSettle();

    expect(find.text('Selecciona al menos 2 días de entrenamiento'),
        findsOneWidget);
    expect(find.text('2 días / semana'), findsOneWidget);
    expect(find.text('1 día / semana'), findsNothing);
  });
}