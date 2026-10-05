import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/screens/profile_screen.dart';
import 'package:fitpulse/services/config_service.dart';
import 'package:fitpulse/services/health_service.dart';
import 'package:fitpulse/services/locale_service.dart';
import 'package:fitpulse/state/app_state.dart';
import 'package:fitpulse/state/estado_salud.dart';
import 'package:fitpulse/theme.dart';
import 'package:fitpulse/utils/validators.dart';

/// L2 (cierre) — Meta diaria de agua editable y honesta.
///
/// - Unit: la meta se persiste, se ajusta al rango 0,5–10 L, viaja en el
///   backup y vuelve a 2,5 L tras un borrado total.
/// - `origenAguaHoy` dice si el agua es "marcada por ti", de Health Connect o
///   de ambos (nunca se cuenta dos veces el mismo vaso).
/// - El estado de salud (P20) puntúa el agua **contra la meta del usuario**.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('L2 · meta diaria de agua', () {
    test('sin nada guardado la meta es 2,5 L (comportamiento ya conocido)',
        () async {
      final state = AppState();
      await state.init();
      expect(state.metaAguaDiaria, 2.5);
    });

    test('se cambia, se persiste y sobrevive al reinicio de la app', () async {
      final state = AppState();
      await state.init();
      await state.setMetaAguaLitros(3.0);
      expect(state.metaAguaDiaria, 3.0);

      // Nueva instancia = nuevo arranque de la app.
      final state2 = AppState();
      await state2.init();
      expect(state2.metaAguaDiaria, 3.0);
    });

    test('se ajusta al rango honesto 0,5–10 L', () async {
      final state = AppState();
      await state.init();

      await state.setMetaAguaLitros(0.1);
      expect(state.metaAguaDiaria, Validators.minMetaAguaLitros);

      await state.setMetaAguaLitros(20);
      expect(state.metaAguaDiaria, Validators.maxMetaAguaLitros);

      expect(Validators.ajustarMetaAgua(0), 0.5);
      expect(Validators.ajustarMetaAgua(-3), 0.5);
      expect(Validators.ajustarMetaAgua(99), 10.0);
      expect(Validators.ajustarMetaAgua(2.0), 2.0);
    });

    test('viaja en el backup y se restaura al importar', () async {
      final state = AppState();
      await state.init();
      await state.setMetaAguaLitros(4.0);
      final snapshot = state.snapshotParaBackup();
      expect(snapshot['meta_agua'], 4.0);

      final otro = AppState();
      await otro.init();
      await otro.aplicarBackup(Map<String, dynamic>.from(snapshot));
      expect(otro.metaAguaDiaria, 4.0);
    });

    test('un backup antiguo (sin meta) conserva la meta vigente', () async {
      final state = AppState();
      await state.init();
      await state.setMetaAguaLitros(2.0);
      await state.aplicarBackup({'perfil': state.profile.encode()});
      expect(state.metaAguaDiaria, 2.0);
    });

    test('tras un borrado total vuelve a 2,5 L', () async {
      final state = AppState();
      await state.init();
      await state.setMetaAguaLitros(5.0);
      state.resetTrasBorrado();
      expect(state.metaAguaDiaria, 2.5);
    });
  });

  group('L2 · origen real del agua', () {
    test('sin dato no hay origen', () async {
      final state = AppState();
      await state.init();
      expect(state.origenAguaHoy, isNull);
    });

    test('solo registro manual → "manual"', () async {
      final state = AppState();
      await state.init();
      await state.registrarAgua(0.5);
      expect(state.origenAguaHoy, 'manual');
    });

    test('solo Health Connect → "health"', () async {
      final state = AppState();
      await state.init();
      state.setHealthConnect(_FakeHealthConnect(datos: const HealthToday(
        funciono: true,
        aguaLitros: 1.2,
        metricasConPermiso: {HealthMetricas.agua},
      )));
      await state.initHealthConnect();
      expect(state.origenAguaHoy, 'health');
    });

    test('los dos → "ambos" (sabiendo que el total es la suma)', () async {
      final state = AppState();
      await state.init();
      state.setHealthConnect(_FakeHealthConnect(datos: const HealthToday(
        funciono: true,
        aguaLitros: 1.0,
        metricasConPermiso: {HealthMetricas.agua},
      )));
      await state.initHealthConnect();
      await state.registrarAgua(0.5);
      expect(state.origenAguaHoy, 'ambos');
      expect(state.aguaHoy, closeTo(1.5, 0.001));
    });
  });

  group('L2 · el estado de salud puntúa contra TU meta', () {
    int puntosAgua(double litros, double meta) => clasificarEstadoSalud(
          imc: 22.0,
          edad: 30,
          pasos: 9000,
          aguaLitros: litros,
          metaAguaLitros: meta,
        ).metricas
            .firstWhere((m) => m.metrica == MetricaEstado.agua)
            .puntos;

    test('con meta 3,0 L se necesitan 3 L para el máximo', () {
      expect(puntosAgua(3.0, 3.0), 3);
      expect(puntosAgua(1.8, 3.0), 2); // 60 %
      expect(puntosAgua(0.9, 3.0), 1); // 30 %
      expect(puntosAgua(0.3, 3.0), 0);
    });

    test('con meta 2,5 L se mantienen los cortes ya verificados', () {
      expect(puntosAgua(3.0, 2.5), 3);
      expect(puntosAgua(1.5, 2.5), 2);
      expect(puntosAgua(1.0, 2.5), 1);
      expect(puntosAgua(0.2, 2.5), 0);
    });

    test('subir la meta sube el listón (no se regala el punto)', () {
      // 2,5 L con meta 3,0 L ya no es "cumplido": baja a 2 puntos.
      expect(puntosAgua(2.5, 3.0), 2);
    });
  });

  group('L2 · Perfil', () {
    Future<AppState> pumpPerfil(WidgetTester tester) async {
      final state = AppState();
      await state.init();
      final locale = LocaleService();
      await locale.init();
      final config = ConfigService();
      await config.init();
      AppColors.activate(lightFitPalette);
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: ChangeNotifierProvider<LocaleService>.value(
            value: locale,
            child: ChangeNotifierProvider<ConfigService>.value(
              value: config,
              child: const MaterialApp(home: ProfileScreen()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return state;
    }

    testWidgets('muestra la meta de agua con su valor y la deja editar',
        (tester) async {
      final state = await pumpPerfil(tester);

      expect(find.text('Meta diaria de agua'), findsOneWidget);
      expect(find.text('2.5 L'), findsOneWidget);

      // El botón lleva el tooltip "Meta de agua": lo-targeted, no el último
      // icono de editar (hay varios en Perfil).
      final boton = find.byTooltip('Meta de agua');
      await tester.ensureVisible(boton);
      await tester.pumpAndSettle();
      await tester.tap(boton);
      await tester.pumpAndSettle();

      // Diálogo con la rueda y el rango honesto explicado.
      expect(
        find.widgetWithText(AlertDialog, 'Meta de agua'),
        findsOneWidget,
      );
      expect(find.textContaining('0,5 – 10 L'), findsOneWidget);

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      // Sin mover la rueda el valor se mantiene: la meta es del usuario.
      expect(state.metaAguaDiaria, 2.5);
      expect(
        find.text('¡Ajustes guardados en tu dispositivo!'),
        findsOneWidget,
      );
    });
  });
}

/// Fuente de Health Connect simulada (mismo patrón que `state_test.dart`).
class _FakeHealthConnect extends HealthConnectService {
  _FakeHealthConnect({HealthToday? datos, Set<String>? permisos})
      : _datos = datos ?? HealthToday.vacio,
        _permisos = permisos ?? const {};

  final HealthToday _datos;
  final Set<String> _permisos;

  @override
  Future<bool> disponible() async => true;

  @override
  Future<bool> solicitarPermisos() async => true;

  @override
  Future<Set<String>> metricasConPermiso() async => _permisos;

  @override
  Future<HealthToday> leerHoy() async => _datos;
}