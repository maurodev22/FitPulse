import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/state/app_state.dart';
import 'package:fitpulse/state/insignias.dart';

/// FASE C — estructura de insignias (logros temáticos).
///
/// Cubre:
///  1. la evaluación pura `evaluarInsignias` con datos fabricados (fechas
///     reales de desbloqueo derivadas del historial, nunca inventadas);
///  2. la integración con `AppState`: `datosInsignias` proyecta el historial
///     y los días con la meta de agua cumplida se persisten de verdad.
void main() {
  group('evaluarInsignias · sin datos (todo bloqueado)', () {
    test('catálogo completo de 9, ninguna conseguida', () {
      final r = evaluarInsignias(const DatosInsignias(
        fechasSesiones: [],
        semanasPeso: [],
        primerasRepsPorEjercicio: {},
        diasAguaCumplida: [],
      ));
      expect(r.length, 9);
      expect(r.where((e) => e.conseguida), isEmpty);
      expect(r.map((e) => e.id),
          containsAll(InsigniaId.values));
    });
  });

  group('fechas reales de desbloqueo', () {
    DatosInsignias datos({
      List<DateTime> sesiones = const [],
      List<DateTime> semanas = const [],
      Map<String, DateTime> reps = const {},
      List<DateTime> agua = const [],
    }) {
      return DatosInsignias(
        fechasSesiones: sesiones,
        semanasPeso: semanas,
        primerasRepsPorEjercicio: reps,
        diasAguaCumplida: agua,
      );
    }

    test('primera sesión: fecha = día de la sesión más antigua', () {
      final r = evaluarInsignias(datos(sesiones: [
        DateTime(2026, 9, 8, 18),
        DateTime(2026, 9, 2, 8),
      ]));
      final p = r.firstWhere((e) => e.id == InsigniaId.primeraSesion);
      expect(p.conseguida, isTrue);
      expect(p.fecha, DateTime(2026, 9, 2));
    });

    test('constancia y 1er reto: primer día en que la racha llega a 3', () {
      final r = evaluarInsignias(datos(sesiones: [
        DateTime(2026, 10, 1),
        DateTime(2026, 10, 2),
        DateTime(2026, 10, 3),
        DateTime(2026, 10, 7),
        DateTime(2026, 10, 8),
      ]));
      final c = r.firstWhere((e) => e.id == InsigniaId.constancia);
      final reto = r.firstWhere((e) => e.id == InsigniaId.primerReto);
      expect(c.conseguida, isTrue);
      expect(c.fecha, DateTime(2026, 10, 3));
      expect(reto.conseguida, isTrue);
      expect(reto.fecha, DateTime(2026, 10, 3));
      final d = r.firstWhere((e) => e.id == InsigniaId.disciplina);
      expect(d.conseguida, isFalse);
    });

    test('disciplina: primer día en que la racha llega a 7', () {
      final sesiones = [
        for (var i = 1; i <= 9; i++) DateTime(2026, 10, i),
      ];
      final r = evaluarInsignias(datos(sesiones: sesiones));
      final d = r.firstWhere((e) => e.id == InsigniaId.disciplina);
      expect(d.conseguida, isTrue);
      expect(d.fecha, DateTime(2026, 10, 7));
    });

    test('hierro: fecha de la sesión 25 (25 sesiones reales)', () {
      final sesiones = [
        for (var i = 0; i < 25; i++) DateTime(2026, 1, 1).add(Duration(days: i * 3)),
      ];
      final r = evaluarInsignias(datos(sesiones: sesiones));
      final h = r.firstWhere((e) => e.id == InsigniaId.hierro);
      expect(h.conseguida, isTrue);
      expect(h.fecha, sesiones[24]);
    });

    test('veterano: fecha de la sesión 100 (100 sesiones reales)', () {
      final sesiones = [
        for (var i = 0; i < 100; i++)
          DateTime(2026, 1, 1).add(Duration(days: i * 2)),
      ];
      final r = evaluarInsignias(datos(sesiones: sesiones));
      final v = r.firstWhere((e) => e.id == InsigniaId.veterano);
      expect(v.conseguida, isTrue);
      expect(v.fecha, sesiones[99]);
      // Con 24 sesiones sigue bloqueada.
      final r2 = evaluarInsignias(datos(sesiones: sesiones.sublist(0, 24)));
      final h2 = r2.firstWhere((e) => e.id == InsigniaId.hierro);
      expect(h2.conseguida, isFalse);
    });

    test('marca personal: peso en 4 semanas SEGUIDAS', () {
      final lunes = DateTime(2026, 9, 7);
      final semanas = [
        for (var i = 0; i < 4; i++)
          lunes.add(Duration(days: i * 7)),
      ];
      final r = evaluarInsignias(datos(semanas: semanas));
      final m = r.firstWhere((e) => e.id == InsigniaId.marcaPersonal);
      expect(m.conseguida, isTrue);
      expect(m.fecha, semanas.last);

      // Tres semanas seguidas no alcanzan.
      final r2 = evaluarInsignias(datos(semanas: semanas.sublist(0, 3)));
      final m2 = r2.firstWhere((e) => e.id == InsigniaId.marcaPersonal);
      expect(m2.conseguida, isFalse);

      // Con un hueco, tampoco (aunque haya 4 registros).
      final conHueco = [
        lunes,
        lunes.add(const Duration(days: 7)),
        lunes.add(const Duration(days: 21)),
        lunes.add(const Duration(days: 35)),
      ];
      final r3 = evaluarInsignias(datos(semanas: conHueco));
      final m3 = r3.firstWhere((e) => e.id == InsigniaId.marcaPersonal);
      expect(m3.conseguida, isFalse);
    });

    test('técnico: reps en 10 ejercicios distintos', () {
      final reps = <String, DateTime>{
        for (var i = 0; i < 9; i++)
          'Ejercicio ${i + 1}': DateTime(2026, 1, 1).add(Duration(days: i)),
      };
      final r9 = evaluarInsignias(datos(reps: reps));
      final t9 = r9.firstWhere((e) => e.id == InsigniaId.tecnico);
      expect(t9.conseguida, isFalse);

      reps['Ejercicio 10'] = DateTime(2026, 2, 1);
      final r10 = evaluarInsignias(datos(reps: reps));
      final t10 = r10.firstWhere((e) => e.id == InsigniaId.tecnico);
      expect(t10.conseguida, isTrue);
      // Fecha = el 10º distinto en aparecer (los 9 primeros aparecieron antes).
      expect(t10.fecha, DateTime(2026, 2, 1));
    });

    test('hidratado: 7 días distintos con la meta de agua cumplida', () {
      final dias = [
        for (var i = 0; i < 6; i++) DateTime(2026, 10, i + 1),
      ];
      final r6 = evaluarInsignias(datos(agua: dias));
      final h6 = r6.firstWhere((e) => e.id == InsigniaId.hidratado);
      expect(h6.conseguida, isFalse);

      dias.add(DateTime(2026, 10, 7));
      final r7 = evaluarInsignias(datos(agua: dias));
      final h7 = r7.firstWhere((e) => e.id == InsigniaId.hidratado);
      expect(h7.conseguida, isTrue);
      expect(h7.fecha, DateTime(2026, 10, 7));
    });
  });

  group('AppState · datosInsignias y días de agua', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('datosInsignias proyecta el historial real (orden ascendente)', () async {
      final state = AppState();
      await state.init();

      await state.registrarSesionCompletada(
        nombre: 'Full Body',
        duracion: const Duration(minutes: 30),
        calorias: 180,
        fecha: DateTime(2026, 10, 3),
      );
      await state.registrarSesionCompletada(
        nombre: 'HIIT',
        duracion: const Duration(minutes: 20),
        calorias: 150,
        fecha: DateTime(2026, 10, 1),
      );
      await state.registrarRepeticiones('Press banca', 12,
          fecha: DateTime(2026, 10, 2));

      final d = state.datosInsignias;
      expect(d.fechasSesiones, [
        DateTime(2026, 10, 1),
        DateTime(2026, 10, 3),
      ]);
      expect(d.primerasRepsPorEjercicio['Press banca'], DateTime(2026, 10, 2));

      final r = evaluarInsignias(d);
      expect(r.map((e) => e.id).toList(), InsigniaId.values);
      expect(
        r.firstWhere((e) => e.id == InsigniaId.primeraSesion).fecha,
        DateTime(2026, 10, 1),
      );
    });

    test('registrarAgua anota HOY solo si el total real llega a la meta',
        () async {
      final state = AppState();
      await state.init();
      // Meta por defecto = 2,5 L. Con 2,4 L no se anota el día.
      await state.registrarAgua(2.4);
      expect(state.diasAguaCumplida, isEmpty);

      await state.registrarAgua(0.1); // 2,5 L totales reales.
      final hoy = DateTime.now();
      expect(state.diasAguaCumplida, [DateTime(hoy.year, hoy.month, hoy.day)]);
      await state.registrarAgua(0.5); // sin duplicar el día
      expect(state.diasAguaCumplida.length, 1);

      // Persistencia real: un estado nuevo con el mismo almacenamiento lo lee.
      final state2 = AppState();
      await state2.init();
      expect(state2.diasAguaCumplida.length, 1);
    });

    test('el backup lleva los días de agua y resetTrasBorrado los limpia',
        () async {
      final state = AppState();
      await state.init();
      await state.registrarAgua(2.5);

      final snapshot = state.snapshotParaBackup();
      expect(snapshot['dias_agua'], isA<List>());
      expect((snapshot['dias_agua'] as List), isNotEmpty);

      final state2 = AppState();
      await state2.init();
      await state2.aplicarBackup(snapshot);
      expect(state2.diasAguaCumplida.length, 1);

      state2.resetTrasBorrado();
      expect(state2.diasAguaCumplida, isEmpty);
    });
  });
}