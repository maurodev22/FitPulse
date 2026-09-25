import 'package:flutter_test/flutter_test.dart';

import 'package:fitpulse/state/pose_coach.dart';

void main() {
  group('Fase 5 · entrenador de postura (lógica pura)', () {
    test('ángulo recto = 90°, extendido = 180°, cerrado = 0°', () {
      expect(anguloGrados(const PuntoPose(5, 0), const PuntoPose(0, 0), const PuntoPose(0, 5)), closeTo(90, 0.001));
      expect(anguloGrados(const PuntoPose(0, 0), const PuntoPose(1, 0), const PuntoPose(2, 0)), closeTo(180, 0.001));
      expect(anguloGrados(const PuntoPose(0, -1), const PuntoPose(0, 0), const PuntoPose(0, 1)), closeTo(180, 0.001));
      expect(anguloGrados(const PuntoPose(0, 1), const PuntoPose(0, 0), const PuntoPose(1, 0)), closeTo(90, 0.001));
    });

    test('ángulo es independiente de la escala (mismo valor en píxeles)', () {
      final chico = anguloGrados(
        const PuntoPose(2, 0), const PuntoPose(0, 0), const PuntoPose(0, 1));
      final grande = anguloGrados(
        const PuntoPose(200, 0), const PuntoPose(0, 0), const PuntoPose(0, 100));
      expect(chico, closeTo(grande, 0.001));
    });

    test('mapa ejercicio → tipo de corrección', () {
      expect(tipoDeEjercicio('Sentadillas'), TipoPostura.pierna);
      expect(tipoDeEjercicio('Zancadas alternas'), TipoPostura.pierna);
      expect(tipoDeEjercicio('Sentadilla con salto'), TipoPostura.pierna);
      expect(tipoDeEjercicio('Burpees'), TipoPostura.pierna);
      expect(tipoDeEjercicio('Flexiones'), TipoPostura.empuje);
      expect(tipoDeEjercicio('Fondos de tríceps'), TipoPostura.empuje);
      expect(tipoDeEjercicio('Plancha'), TipoPostura.plancha);
      expect(tipoDeEjercicio('Plancha lateral'), TipoPostura.plancha);
      expect(tipoDeEjercicio('Mountain Climbers'), TipoPostura.cardio);
      expect(tipoDeEjercicio('Skipping'), TipoPostura.cardio);
      expect(tipoDeEjercicio('Jumping Jacks'), TipoPostura.cardio);
      expect(tipoDeEjercicio('Estiramiento final'), TipoPostura.libre);
      expect(tipoDeEjercicio('Trote suave'), TipoPostura.libre);
      expect(tipoDeEjercicio('Abdominales crunch'), TipoPostura.libre);
    });

    test('contador: una repetición necesita bajar y luego subir', () {
      final c = ContadorRepeticiones(umbralBajo: 110, umbralAlto: 150);
      expect(c.actualizar(175), isFalse); // de pie
      expect(c.actualizar(90), isFalse); // baja (se arma)
      expect(c.actualizar(80), isFalse); // sigue abajo
      expect(c.actualizar(160), isTrue); // sube → repetición
      expect(c.reps, 1);
    });

    test('contador: oscilar abajo del umbral no cuenta dos veces', () {
      final c = ContadorRepeticiones(umbralBajo: 110, umbralAlto: 150);
      c.actualizar(100); // baja
      c.actualizar(120); // sube un poco pero sin llegar al umbral alto
      c.actualizar(105); // vuelve a bajar
      expect(c.reps, 0);
      c.actualizar(160); // por fin sube del todo
      expect(c.reps, 1);
      c.actualizar(170);
      c.actualizar(95);
      c.actualizar(155);
      expect(c.reps, 2);
    });

    test('sentadilla: ángulo de rodilla flexado → bajar; extendido → repetición', () {
      final a = AnalizadorPostura(TipoPostura.pierna);
      final dePie = <Lm, PuntoPose>{
        Lm.caderaIzq: const PuntoPose(50, 100),
        Lm.rodillaIzq: const PuntoPose(50, 200),
        Lm.tobilloIzq: const PuntoPose(50, 300),
      };
      final r1 = a.analizar(dePie);
      expect(r1.poseDetectada, isTrue);
      expect(r1.reps, 0);

      // Rodilla flexionada: muslo casi perpendicular a la espinilla (~90°).
      final enCuclillas = <Lm, PuntoPose>{
        Lm.caderaIzq: const PuntoPose(100, 50),
        Lm.rodillaIzq: const PuntoPose(100, 200),
        Lm.tobilloIzq: const PuntoPose(150, 200),
      };
      final r2 = a.analizar(enCuclillas);
      expect(r2.poseDetectada, isTrue);
      expect(r2.mensaje, contains('Flexiona'));

      final r3 = a.analizar(dePie);
      expect(r3.repeticionNueva, isTrue);
      expect(r3.reps, 1);
    });

    test('flexión: usa el codo; precisa extremidades que faltan → no detectada', () {
      final a = AnalizadorPostura(TipoPostura.empuje);
      final sinBrazo = <Lm, PuntoPose>{
        Lm.hombroIzq: const PuntoPose(10, 10),
        Lm.codoIzq: const PuntoPose(10, 50),
        // falta la muñeca
      };
      final r = a.analizar(sinBrazo);
      expect(r.poseDetectada, isFalse);

      final completo = <Lm, PuntoPose>{
        Lm.hombroIzq: const PuntoPose(10, 0),
        Lm.codoIzq: const PuntoPose(10, 100),
        Lm.munecaIzq: const PuntoPose(0, 100),
      };
      final r2 = a.analizar(completo);
      expect(r2.poseDetectada, isTrue);
      expect(r2.mensaje, contains('Baja'));
    });

    test('plancha: cadera baja → aviso; alineada → ok', () {
      final a = AnalizadorPostura(TipoPostura.plancha);
      // Cuerpo doblado (cadera fuera de la línea hombros-tobillos).
      final doblada = <Lm, PuntoPose>{
        Lm.hombroIzq: const PuntoPose(0, 0),
        Lm.caderaIzq: const PuntoPose(50, 80),
        Lm.tobilloIzq: const PuntoPose(0, 160),
      };
      final r1 = a.analizar(doblada);
      expect(r1.poseDetectada, isTrue);
      expect(r1.mensaje, contains('Eleva la cadera'));

      // Recta: hombros, cadera y tobillos alineados (180°).
      final recta = <Lm, PuntoPose>{
        Lm.hombroIzq: const PuntoPose(0, 0),
        Lm.caderaIzq: const PuntoPose(0, 100),
        Lm.tobilloIzq: const PuntoPose(0, 200),
      };
      final r2 = a.analizar(recta);
      expect(r2.mensaje, contains('alineado'));
    });

    test('ejercicio libre: solo indica pose detectada sin métricas', () {
      final a = AnalizadorPostura(TipoPostura.libre);
      final r = a.analizar(const {Lm.hombroIzq: PuntoPose(1, 1)});
      expect(r.poseDetectada, isTrue);
      expect(r.mensaje, contains('Pose detectada'));
      final vacio = a.analizar(const {});
      expect(vacio.poseDetectada, isFalse);
    });
  });
}