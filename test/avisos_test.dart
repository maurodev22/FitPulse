import 'package:flutter_test/flutter_test.dart';

import 'package:fitpulse/state/avisos.dart';

void main() {
  group('Fase 6 · avisos locales y widget de home (lógica pura)', () {
    test('proximaHoraLocal: hoy si aún no pasó, mañana si ya pasó', () {
      final antes = DateTime(2026, 9, 25, 10, 0);
      expect(proximaHoraLocal(antes, 20, 0), DateTime(2026, 9, 25, 20, 0));

      final despues = DateTime(2026, 9, 25, 21, 30);
      expect(proximaHoraLocal(despues, 20, 0), DateTime(2026, 9, 26, 20, 0));

      // Justo a la hora programada → cuenta como pasada → mañana.
      final exacta = DateTime(2026, 9, 25, 20, 0);
      expect(proximaHoraLocal(exacta, 20, 0), DateTime(2026, 9, 26, 20, 0));

      // Cambio de mes.
      final finMes = DateTime(2026, 9, 30, 22, 0);
      expect(proximaHoraLocal(finMes, 20, 0), DateTime(2026, 10, 1, 20, 0));
    });

    test('comoInstantUtc conserva el instante absoluto', () {
      final local = DateTime(2026, 9, 25, 20, 0);
      final utc = comoInstantUtc(local);
      expect(utc.isUtc, isTrue);
      expect(utc.millisecondsSinceEpoch, local.millisecondsSinceEpoch);
    });

    test('textoAvisoRacha usa la racha real (0, 1, N)', () {
      expect(textoAvisoRacha(0), contains('empezar'));
      expect(textoAvisoRacha(1), contains('1 día'));
      expect(textoAvisoRacha(5), contains('5 días'));
      expect(textoAvisoRacha(5), contains('no cortarla'));
    });

    test('construirSnapshotWidget: JSON con valores reales', () {
      final json = construirSnapshotWidget(
        pasos: 4321,
        calorias: 187.6,
        racha: 3,
        fecha: '2026-09-25',
      );
      expect(json, contains('"pasos":4321'));
      expect(json, contains('"calorias":188'));
      expect(json, contains('"racha":3'));
      expect(json, contains('"fecha":"2026-09-25"'));
    });

    test('construirSnapshotWidget: calorias null → "—" nativo (null en JSON)',
        () {
      final json = construirSnapshotWidget(
        pasos: 100,
        calorias: null,
        racha: 0,
        fecha: '2026-09-25',
      );
      expect(json, contains('"calorias":null'));
    });
  });
}