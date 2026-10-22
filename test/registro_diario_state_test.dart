import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/state/app_state.dart';
import 'package:fitpulse/state/registro_diario.dart';

/// Histórico diario dentro del estado real de la app.
///
/// Comprueba las dos reglas que importan: el día de hoy se mantiene en vivo y
/// un día pasado con pasos locales se cierra como **parcial** (la app pudo
/// estar cerrada y el contador siguió), salvo que venga de Health Connect.
void main() {
  String clave(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  DateTime soloDia(DateTime d) => DateTime(d.year, d.month, d.day);

  void sembrar({
    required List<RegistroDiario> registros,
    String? fechaBalance,
  }) {
    SharedPreferences.setMockInitialValues({
      'fitpulse_registro_diario_v1': registros
          .map((r) => jsonEncode(r.toJson()))
          .toList(growable: false),
      'fitpulse_balance_date_v1': ?fechaBalance,
    });
  }

  test('al arrancar sin datos no se inventa nada', () async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.init();

    final hoy = state.registroDelDia(state.hoyMediodia);
    expect(hoy, isNotNull);
    expect(hoy!.tieneDatos, isFalse);
    expect(hoy.pasos, isNull, reason: 'sin sensor no hay pasos, no un cero');
    expect(hoy.kcal, isNull);
  });

  test('el agua registrada entra en el histórico del día', () async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.init();

    await state.registrarAgua(0.5);
    final hoy = state.registroDelDia(state.hoyMediodia)!;
    expect(hoy.agua, closeTo(0.5, 1e-9));
  });

  test('una sesión completada deja los minutos reales del día', () async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.init();

    await state.registrarSesionCompletada(
      nombre: 'Fuerza',
      duracion: const Duration(minutes: 35),
      calorias: 210,
    );

    final hoy = state.registroDelDia(state.hoyMediodia)!;
    expect(hoy.entrenoMin, 35);
  });

  test('un día pasado con pasos locales se cierra como parcial', () async {
    final ayer = soloDia(DateTime.now()).subtract(const Duration(days: 1));
    sembrar(
      fechaBalance: clave(ayer),
      registros: [
        RegistroDiario(dia: ayer, pasos: 4200, entrenoMin: 20),
      ],
    );

    final state = AppState();
    await state.init();

    final r = state.registroDelDia(ayer)!;
    expect(r.pasos, 4200);
    expect(r.pasosParciales, isTrue);
    expect(r.entrenoMin, 20, reason: 'el entreno sí es un dato firme');
  });

  test('un día importado de Health Connect no se marca parcial', () async {
    final ayer = soloDia(DateTime.now()).subtract(const Duration(days: 1));
    sembrar(
      fechaBalance: clave(ayer),
      registros: [
        RegistroDiario(
          dia: ayer,
          pasos: 9000,
          pasosHealthConnect: true,
        ),
      ],
    );

    final state = AppState();
    await state.init();

    final r = state.registroDelDia(ayer)!;
    expect(r.pasos, 9000);
    expect(r.pasosParciales, isFalse);
    expect(r.pasosHealthConnect, isTrue);
  });

  test('la importación rellena días y no toca hoy ni rebaja datos', () async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.init();

    final hoy = soloDia(DateTime.now());
    final ayer = hoy.subtract(const Duration(days: 1));
    final anteayer = hoy.subtract(const Duration(days: 2));

    // Anteayer ya tiene un valor mayor: no se rebaja.
    await state.aplicarPasosHistoricos({
      clave(anteayer): 100,
      clave(hoy): 99999,
    });
    expect(state.registroDelDia(anteayer)!.pasos, 100);

    final aplicados = await state.aplicarPasosHistoricos({
      clave(ayer): 7400,
      clave(anteayer): 900,
      clave(hoy): 99999,
    });

    expect(aplicados, 2, reason: 'ayer y anteayer; hoy se lleva en vivo');
    expect(state.registroDelDia(ayer)!.pasos, 7400);
    expect(state.registroDelDia(ayer)!.pasosHealthConnect, isTrue);
    expect(state.registroDelDia(anteayer)!.pasos, 900);
    expect(
      state.registroDelDia(hoy)!.pasos,
      isNot(99999),
      reason: 'el día de hoy nunca se sobrescribe con la importación',
    );
  });

  test('el histórico sobrevive al reinicio de la app', () async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.init();
    final ayer = soloDia(DateTime.now()).subtract(const Duration(days: 1));
    await state.aplicarPasosHistoricos({clave(ayer): 6100});

    final state2 = AppState();
    await state2.init();
    expect(state2.registroDelDia(ayer)!.pasos, 6100);
    expect(state2.registroDelDia(ayer)!.pasosHealthConnect, isTrue);
  });

  test('las metas del gráfico salen del perfil y los ajustes', () async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.init();
    await state.setMetaAguaLitros(3.0);

    expect(state.metasDia.pasos, state.profile.pasosMeta);
    expect(state.metasDia.agua, 3.0);
    expect(state.metasDia.calorias, state.profile.caloriasMeta);
  });

  test('los días de entreno se traducen a día de la semana', () async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.init();

    // El perfil por defecto entrena de lunes a viernes: se traduce a 1..5.
    expect(state.diasEntrenoSemana, {1, 2, 3, 4, 5});
    expect(state.registroHoy.dia, state.hoyMediodia);
  });
}
