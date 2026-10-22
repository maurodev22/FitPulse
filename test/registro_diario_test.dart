import 'package:flutter_test/flutter_test.dart';

import 'package:fitpulse/state/registro_diario.dart';

/// Histórico diario y gráfico de cumplimiento.
///
/// Regla del proyecto: nada se inventa. Un día sin dato no es un cero; el
/// entrenamiento solo cuenta en los días que el plan marca; y superar la meta
/// no sube el porcentaje por encima del 100 %.
void main() {
  const metas = MetasDia(pasos: 10000, agua: 2.5, calorias: 2000);
  const lunes = 1;

  DateTime dia(int y, int m, int d) => DateTime(y, m, d);

  String etiquetaDia(DateTime d) => 'd${d.day}';
  String etiquetaSemana(DateTime d) => 's${d.day}';
  String etiquetaMes(DateTime d) => 'm${d.month}';
  String etiquetaLarga(DateTime d) => 'Día ${d.day}';

  group('RegistroDiario · cumplimiento', () {
    test('sin ningún dato el cumplimiento es null (no 0 %)', () {
      final r = RegistroDiario(dia: dia(2026, 10, 20));
      expect(r.cumplimiento(metas, entrenoEsperado: false), isNull);
      expect(r.tieneDatos, isFalse);
    });

    test('suma solo las metas con dato y no penaliza las que faltan', () {
      // 50 % de pasos y 100 % de agua. Sin comidas registradas: no cuentan.
      final r = RegistroDiario(
        dia: dia(2026, 10, 20),
        pasos: 5000,
        agua: 2.5,
      );
      expect(r.cumplimiento(metas, entrenoEsperado: false), closeTo(0.75, 1e-9));
    });

    test('superar la meta no pasa del 100 %', () {
      final r = RegistroDiario(
        dia: dia(2026, 10, 20),
        pasos: 30000,
        agua: 5,
        kcal: 4000,
      );
      expect(r.cumplimiento(metas, entrenoEsperado: false), closeTo(1.0, 1e-9));
    });

    test('el entreno solo cuenta si ese día tocaba entrenar', () {
      final r = RegistroDiario(
        dia: dia(2026, 10, 21),
        pasos: 10000,
        entrenoMin: 0,
      );
      // Lunes (toca entrenar) y no entrenó: 50 %.
      expect(r.cumplimiento(metas, entrenoEsperado: true), closeTo(0.5, 1e-9));
      // Miércoles (descanso): el entreno no entra, queda 100 % de pasos.
      expect(r.cumplimiento(metas, entrenoEsperado: false), closeTo(1.0, 1e-9));
    });

    test('un día de entreno cumplido suma 100 % en su métrica', () {
      final r = RegistroDiario(
        dia: dia(2026, 10, 19),
        pasos: 5000,
        entrenoMin: 45,
      );
      expect(
        r.valorMetrica(MetricaSerie.entreno, metas, entrenoEsperado: true),
        1.0,
      );
      expect(
        r.valorMetrica(MetricaSerie.entreno, metas, entrenoEsperado: false),
        isNull,
      );
      expect(r.cumplimiento(metas, entrenoEsperado: true), closeTo(0.75, 1e-9));
    });

    test('los pasos parciales siguen siendo un dato real (no null)', () {
      final r = RegistroDiario(
        dia: dia(2026, 10, 18),
        pasos: 4000,
        pasosParciales: true,
      );
      expect(r.pasosCompletos, isFalse);
      expect(r.cumplimiento(metas, entrenoEsperado: false), closeTo(0.4, 1e-9));
    });
  });

  group('RegistroDiario · persistencia', () {
    test('ida y vuelta a JSON conserva todos los campos', () {
      final r = RegistroDiario(
        dia: dia(2026, 10, 17),
        pasos: 8123,
        pasosParciales: true,
        agua: 1.75,
        kcal: 1850,
        proteinas: 120,
        entrenoMin: 32,
        pesoKg: 78.4,
      );
      final copia = RegistroDiario.fromJson(r.toJson());
      expect(copia.dia, r.dia);
      expect(copia.pasos, 8123);
      expect(copia.pasosParciales, isTrue);
      expect(copia.agua, 1.75);
      expect(copia.kcal, 1850);
      expect(copia.proteinas, 120);
      expect(copia.entrenoMin, 32);
      expect(copia.pesoKg, 78.4);
    });

    test('un JSON incompleto no rompe: los campos son nulos', () {
      final r = RegistroDiario.fromJson({'d': '2026-10-16'});
      expect(r.pasos, isNull);
      expect(r.tieneDatos, isFalse);
      expect(RegistroDiario.fromJson({'sin': 'fecha'}).dia.year, 1970);
    });
  });

  group('construirSerie', () {
    final hoy = dia(2026, 10, 22); // jueves

    test('diaria: 7 barras, una por día, y los huecos son "sin dato"', () {
      final puntos = construirSerie(
        registros: [
          RegistroDiario(dia: dia(2026, 10, 22), pasos: 10000),
          RegistroDiario(dia: dia(2026, 10, 20), pasos: 5000),
        ],
        escala: EscalaSerie.diaria,
        hoy: hoy,
        metas: metas,
        diasEntreno: const {},
        etiquetaDia: etiquetaDia,
        etiquetaSemana: etiquetaSemana,
        etiquetaMes: etiquetaMes,
        etiquetaLargaDia: etiquetaLarga,
      );

      expect(puntos, hasLength(7));
      expect(puntos.first.desde, dia(2026, 10, 16));
      expect(puntos.last.desde, hoy);
      expect(puntos.last.valor, closeTo(1.0, 1e-9));
      // 20 de octubre: 5.000 de 10.000 pasos = 50 %.
      expect(puntos[4].valor, closeTo(0.5, 1e-9));
      // 19 de octubre no tiene registro: sin dato, no cero.
      expect(puntos[3].valor, isNull);
      expect(puntos[3].sinDato, isTrue);
      expect(puntos[3].diasConDato, 0);
    });

    test('diaria: la etiqueta y el detalle salen del día real', () {
      final puntos = construirSerie(
        registros: [
          RegistroDiario(dia: dia(2026, 10, 21), pasos: 7000),
        ],
        escala: EscalaSerie.diaria,
        hoy: hoy,
        metas: metas,
        diasEntreno: const {},
        etiquetaDia: etiquetaDia,
        etiquetaSemana: etiquetaSemana,
        etiquetaMes: etiquetaMes,
        etiquetaLargaDia: etiquetaLarga,
      );
      final martes = puntos[5];
      expect(martes.etiqueta, 'd21');
      expect(martes.etiquetaLarga, 'Día 21');
      expect(martes.detalle.single.pasos, 7000);
      expect(martes.diasConDato, 1);
    });

    test('semanal: agrupa por semanas que empiezan en lunes', () {
      final puntos = construirSerie(
        registros: [
          // Dos días de la misma semana, uno al 100 % y otro al 50 %.
          RegistroDiario(dia: dia(2026, 10, 19), pasos: 10000), // lunes
          RegistroDiario(dia: dia(2026, 10, 20), pasos: 5000), // martes
        ],
        escala: EscalaSerie.semanal,
        hoy: hoy,
        metas: metas,
        diasEntreno: const {},
        etiquetaDia: etiquetaDia,
        etiquetaSemana: etiquetaSemana,
        etiquetaMes: etiquetaMes,
        etiquetaLargaDia: etiquetaLarga,
      );

      // 30 días pueden tocar 5 o 6 semanas; cada tramo empieza en lunes (el
      // primero puede recortarse al inicio de la ventana).
      expect(puntos.length, inInclusiveRange(5, 6));
      expect(puntos.skip(1).every((p) => p.desde.weekday == 1), isTrue);
      final semana = puntos.firstWhere((p) => p.diasConDato == 2);
      expect(semana.valor, closeTo(0.75, 1e-9));
      expect(semana.detalle, hasLength(2));
    });

    test('semanal: un tramo sin registros no inventa valor', () {
      final puntos = construirSerie(
        registros: const [],
        escala: EscalaSerie.semanal,
        hoy: hoy,
        metas: metas,
        diasEntreno: const {},
        etiquetaDia: etiquetaDia,
        etiquetaSemana: etiquetaSemana,
        etiquetaMes: etiquetaMes,
        etiquetaLargaDia: etiquetaLarga,
      );
      expect(puntos.every((p) => p.valor == null), isTrue);
      expect(puntos.every((p) => p.diasConDato == 0), isTrue);
    });

    test('mensual: 12 barras (el mes actual el último)', () {
      final puntos = construirSerie(
        registros: [
          RegistroDiario(dia: dia(2026, 10, 1), pasos: 10000),
          RegistroDiario(dia: dia(2026, 9, 15), pasos: 5000),
        ],
        escala: EscalaSerie.mensual,
        hoy: hoy,
        metas: metas,
        diasEntreno: const {},
        etiquetaDia: etiquetaDia,
        etiquetaSemana: etiquetaSemana,
        etiquetaMes: etiquetaMes,
        etiquetaLargaDia: etiquetaLarga,
      );
      expect(puntos, hasLength(12));
      expect(puntos.last.desde.month, 10);
      expect(puntos.last.diasConDato, 1);
      // Septiembre (penúltimo) tiene un día al 50 %.
      expect(puntos[10].etiqueta, 'm9');
      expect(puntos[10].valor, closeTo(0.5, 1e-9));
    });

    test('el filtro por métrica cambia lo que mide la barra', () {
      final registros = [
        RegistroDiario(dia: hoy, pasos: 5000, agua: 2.5),
      ];
      List<PuntoSerie> serie(MetricaSerie m) => construirSerie(
            registros: registros,
            escala: EscalaSerie.diaria,
            hoy: hoy,
            metas: metas,
            diasEntreno: const {},
            metrica: m,
            etiquetaDia: etiquetaDia,
            etiquetaSemana: etiquetaSemana,
            etiquetaMes: etiquetaMes,
            etiquetaLargaDia: etiquetaLarga,
          );

      expect(serie(MetricaSerie.todo).last.valor, closeTo(0.75, 1e-9));
      expect(serie(MetricaSerie.pasos).last.valor, closeTo(0.5, 1e-9));
      expect(serie(MetricaSerie.agua).last.valor, closeTo(1.0, 1e-9));
      // Sin comidas registradas, la métrica de calorías no tiene dato.
      expect(serie(MetricaSerie.calorias).last.valor, isNull);
    });

    test('la ventana no incluye días futuros ni anteriores al corte', () {
      final puntos = construirSerie(
        registros: [
          RegistroDiario(dia: dia(2026, 10, 23), pasos: 10000), // futuro
          RegistroDiario(dia: dia(2026, 10, 1), pasos: 10000), // fuera
        ],
        escala: EscalaSerie.diaria,
        hoy: hoy,
        metas: metas,
        diasEntreno: const {},
        etiquetaDia: etiquetaDia,
        etiquetaSemana: etiquetaSemana,
        etiquetaMes: etiquetaMes,
        etiquetaLargaDia: etiquetaLarga,
      );
      expect(puntos.every((p) => p.valor == null), isTrue);
    });

    test('el entreno se mide con los días del plan', () {
      final registros = [
        RegistroDiario(dia: dia(2026, 10, 19), pasos: 10000, entrenoMin: 30),
      ];
      final puntos = construirSerie(
        registros: registros,
        escala: EscalaSerie.diaria,
        hoy: hoy,
        metas: metas,
        diasEntreno: const {lunes},
        metrica: MetricaSerie.entreno,
        etiquetaDia: etiquetaDia,
        etiquetaSemana: etiquetaSemana,
        etiquetaMes: etiquetaMes,
        etiquetaLargaDia: etiquetaLarga,
      );
      final lunes19 =
          puntos.firstWhere((p) => p.desde == dia(2026, 10, 19));
      expect(lunes19.valor, 1.0);
      // Un día que no toca entrenar no tiene valor de entreno.
      final martes20 =
          puntos.firstWhere((p) => p.desde == dia(2026, 10, 20));
      expect(martes20.valor, isNull);
    });
  });
}
