import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/state/app_state.dart';

/// FASE D — Ritual semanal sin presión.
///
/// Cubre:
///  1. el registro honesto de XP por día (`_otorgarXp` → `xpPorDia`) y su
///     persistencia/backup;
///  2. los getters de la semana pasada (días, sesiones, XP reales);
///
/// La tarjeta "Tu semana" se retiró de Home (2026-11-02); los datos de la
/// semana pasada siguen calculándose y se cubren aquí.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  DateTime lunesDe(DateTime d) {
    final dia = DateTime(d.year, d.month, d.day);
    return dia.subtract(Duration(days: dia.weekday - 1));
  }

  String keyDe(DateTime d) => d.toIso8601String().substring(0, 10);

  group('AppState · semana pasada con datos reales', () {
    test('sin historial: 0 días, 0 sesiones, 0 XP', () async {
      final state = AppState();
      await state.init();
      expect(state.diasActivosSemanaPasada, 0);
      expect(state.sesionesSemanaPasada, 0);
      expect(state.xpSemanaPasada, 0);
    });

    test('solo cuenta sesiones de la semana pasada (lunes a domingo anterior)',
        () async {
      final state = AppState();
      await state.init();
      final lunesPasado = lunesDe(DateTime.now()).subtract(const Duration(days: 7));

      await state.registrarSesionCompletada(
        nombre: 'A',
        duracion: const Duration(minutes: 20),
        calorias: 100,
        fecha: lunesPasado,
      );
      await state.registrarSesionCompletada(
        nombre: 'B',
        duracion: const Duration(minutes: 20),
        calorias: 100,
        fecha: lunesPasado.add(const Duration(days: 3)),
      );
      // Fuera de rango: hace dos semanas → no cuenta.
      await state.registrarSesionCompletada(
        nombre: 'C',
        duracion: const Duration(minutes: 20),
        calorias: 100,
        fecha: lunesPasado.subtract(const Duration(days: 1)),
      );
      // Fuera de rango: hoy → no cuenta.
      await state.registrarSesionCompletada(
        nombre: 'D',
        duracion: const Duration(minutes: 20),
        calorias: 100,
      );

      expect(state.diasActivosSemanaPasada, 2);
      expect(state.sesionesSemanaPasada, 2);
    });

    test('xpSemanaPasada suma SOLO el XP real otorgado en ese rango', () async {
      final state = AppState();
      await state.init();
      final lunesPasado = lunesDe(DateTime.now()).subtract(const Duration(days: 7));
      final lunesHaceDos = lunesPasado.subtract(const Duration(days: 7));
      final hoy = DateTime.now();

      // Ledger honesto: XP que se concedió de verdad en cada día.
      state.xpPorDia[keyDe(lunesPasado)] = 350;
      state.xpPorDia[keyDe(lunesPasado.add(const Duration(days: 1)))] = 50;
      state.xpPorDia[keyDe(lunesHaceDos)] = 999; // fuera de rango
      state.xpPorDia[keyDe(hoy)] = 100; // fuera de rango (semana actual)

      expect(state.xpSemanaPasada, 400);
    });

    test('registrarSesionCompletada anota el XP real del día y persiste',
        () async {
      final state = AppState();
      await state.init();
      await state.registrarSesionCompletada(
        nombre: 'Full Body',
        duracion: const Duration(minutes: 30),
        calorias: 180,
      );

      final hoy = DateTime.now();
      expect(state.xp, 50);
      expect(state.xpPorDia[keyDe(hoy)], 50);

      // La persistencia es real: un estado nuevo con el mismo almacenamiento.
      final state2 = AppState();
      await state2.init();
      expect(state2.xpPorDia[keyDe(hoy)], 50);
    });

    test('el backup lleva xp_por_dia y resetTrasBorrado lo limpia', () async {
      final state = AppState();
      await state.init();
      await state.registrarSesionCompletada(
        nombre: 'A',
        duracion: const Duration(minutes: 20),
        calorias: 100,
      );

      final snapshot = state.snapshotParaBackup();
      expect(snapshot['xp_por_dia'], isA<Map>());
      expect((snapshot['xp_por_dia'] as Map).isNotEmpty, isTrue);

      final state2 = AppState();
      await state2.init();
      await state2.aplicarBackup(snapshot);
      expect(state2.xpPorDia, state.xpPorDia);

      state2.resetTrasBorrado();
      expect(state2.xpPorDia, isEmpty);
    });
  });
}
