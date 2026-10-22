import 'dart:math';

/// Escala temporal con la que se agrupan los registros del gráfico.
///
/// - [diaria]: una barra por día (últimos 7 días).
/// - [semanal]: una barra por semana (últimos 30 días).
/// - [mensual]: una barra por mes (últimos 12 meses).
enum EscalaSerie { diaria, semanal, mensual }

/// Métrica que el usuario puede aislar en el gráfico.
enum MetricaSerie { todo, pasos, agua, calorias, entreno }

/// Metas diarias contra las que se mide el cumplimiento.
///
/// Son metas declaradas (perfil / ajustes), no datos de salud: la app nunca
/// inventa una meta ni un valor medido.
class MetasDia {
  const MetasDia({
    required this.pasos,
    required this.agua,
    required this.calorias,
  });

  /// Meta diaria de pasos (perfil, editable).
  final int pasos;

  /// Meta diaria de agua en litros (ajustes, editable).
  final double agua;

  /// Meta calórica diaria derivada del perfil.
  final double calorias;
}

/// Cierre real de un día en el histórico del usuario.
///
/// Regla del proyecto: **nunca se inventa un dato**. Si una métrica no se
/// conoce ese día, se queda en `null` y el gráfico la pinta como "sin dato"
/// (no como cero). Un cero real solo se guarda cuando el usuario declaró
/// explícitamente ese cero (p. ej. agua 0 no se guarda: se guarda `null`).
class RegistroDiario {
  const RegistroDiario({
    required this.dia,
    this.pasos,
    this.pasosParciales = false,
    this.pasosHealthConnect = false,
    this.agua,
    this.kcal,
    this.proteinas,
    this.entrenoMin,
    this.pesoKg,
  });

  /// Día natural (medianoche local).
  final DateTime dia;

  /// Pasos reales del día, o `null` si no hay dato.
  final int? pasos;

  /// `true` si [pasos] es el último valor conocido antes de cerrar el día
  /// (la app estaba cerrada y el contador siguió avanzando). Se pinta como
  /// dato parcial, nunca como total.
  final bool pasosParciales;

  /// `true` si [pasos] viene de Health Connect (total real del día, no una
  /// instantánea). Un día importado no se marca como parcial.
  final bool pasosHealthConnect;

  /// Agua del día (litros) o `null` si el usuario no registró nada.
  final double? agua;

  /// Calorías consumidas o `null` si no se registró comida.
  final double? kcal;

  /// Proteínas consumidas (g) o `null` si no se registró comida.
  final double? proteinas;

  /// Minutos entrenados ese día; `null` si el día queda fuera de la ventana
  /// conocida y no se puede afirmar nada.
  final int? entrenoMin;

  /// Peso corporal registrado ese día (kg) o `null`.
  final double? pesoKg;

  /// `true` si el registro tiene al menos un dato real. Un `entrenoMin` de 0
  /// significa "no entrenó", no "hay una medición": no convierte el día en
  /// un día con datos.
  bool get tieneDatos =>
      pasos != null ||
      agua != null ||
      kcal != null ||
      proteinas != null ||
      (entrenoMin ?? 0) > 0 ||
      pesoKg != null;

  /// `true` si los pasos son un total fiable del día.
  bool get pasosCompletos => pasos != null && !pasosParciales;

  Map<String, dynamic> toJson() => {
        'd': dia.toIso8601String(),
        if (pasos != null) 'p': pasos,
        if (pasosParciales) 'pp': true,
        if (pasosHealthConnect) 'ph': true,
        if (agua != null) 'a': agua,
        if (kcal != null) 'c': kcal,
        if (proteinas != null) 'r': proteinas,
        if (entrenoMin != null) 'e': entrenoMin,
        if (pesoKg != null) 'w': pesoKg,
      };

  /// Reconstruye un registro persistido. Un JSON corrupto no rompe la app: los
  /// campos ilegibles quedan en `null` (se trata como sin dato).
  factory RegistroDiario.fromJson(Map<String, dynamic> j) {
    double? d(String k) {
      final v = j[k];
      return v is num ? v.toDouble() : null;
    }

    int? i(String k) {
      final v = j[k];
      return v is num ? v.round() : null;
    }

    final fecha = DateTime.tryParse('${j['d'] ?? ''}');
    return RegistroDiario(
      dia: fecha == null
          ? DateTime(1970)
          : DateTime(fecha.year, fecha.month, fecha.day),
      pasos: i('p'),
      pasosParciales: j['pp'] == true,
      pasosHealthConnect: j['ph'] == true,
      agua: d('a'),
      kcal: d('c'),
      proteinas: d('r'),
      entrenoMin: i('e'),
      pesoKg: d('w'),
    );
  }

  RegistroDiario copyWith({
    int? pasos,
    bool? pasosParciales,
    bool? pasosHealthConnect,
    double? agua,
    double? kcal,
    double? proteinas,
    int? entrenoMin,
    double? pesoKg,
  }) =>
      RegistroDiario(
        dia: dia,
        pasos: pasos ?? this.pasos,
        pasosParciales: pasosParciales ?? this.pasosParciales,
        pasosHealthConnect: pasosHealthConnect ?? this.pasosHealthConnect,
        agua: agua ?? this.agua,
        kcal: kcal ?? this.kcal,
        proteinas: proteinas ?? this.proteinas,
        entrenoMin: entrenoMin ?? this.entrenoMin,
        pesoKg: pesoKg ?? this.pesoKg,
      );

  /// Cumplimiento (0..1) de las metas de ese día, o `null` si no hay ningún
  /// dato con el que medirlo.
  ///
  /// Solo entran las métricas **con meta y con dato**; así un día sin comida
  /// registrada no cuenta como "0 % de calorías". El entrenamiento solo pesa
  /// los días que el plan del usuario marca como día de entreno
  /// ([entrenoEsperado]), de modo que un día de descanso no baja la media.
  double? cumplimiento(MetasDia metas, {required bool entrenoEsperado}) =>
      valorMetrica(MetricaSerie.todo, metas, entrenoEsperado: entrenoEsperado);

  /// Cumplimiento (0..1) de una métrica concreta, o `null` si no hay dato.
  double? valorMetrica(
    MetricaSerie metrica,
    MetasDia metas, {
    required bool entrenoEsperado,
  }) {
    switch (metrica) {
      case MetricaSerie.pasos:
        if (pasos == null || metas.pasos <= 0) return null;
        return min(1.0, pasos! / metas.pasos);
      case MetricaSerie.agua:
        if (agua == null || metas.agua <= 0) return null;
        return min(1.0, agua! / metas.agua);
      case MetricaSerie.calorias:
        if (kcal == null || metas.calorias <= 0) return null;
        return min(1.0, kcal! / metas.calorias);
      case MetricaSerie.entreno:
        if (!entrenoEsperado || entrenoMin == null) return null;
        return entrenoMin! > 0 ? 1.0 : 0.0;
      case MetricaSerie.todo:
        final partes = <double>[];
        if (pasos != null && metas.pasos > 0) {
          partes.add(min(1.0, pasos! / metas.pasos));
        }
        if (agua != null && metas.agua > 0) {
          partes.add(min(1.0, agua! / metas.agua));
        }
        if (kcal != null && metas.calorias > 0) {
          partes.add(min(1.0, kcal! / metas.calorias));
        }
        if (entrenoEsperado && entrenoMin != null) {
          partes.add(entrenoMin! > 0 ? 1.0 : 0.0);
        }
        if (partes.isEmpty) return null;
        return partes.reduce((a, b) => a + b) / partes.length;
    }
  }
}

/// Una barra del gráfico: un día, una semana o un mes ya agrupado.
class PuntoSerie {
  const PuntoSerie({
    required this.desde,
    required this.hasta,
    required this.valor,
    required this.diasConDato,
    required this.detalle,
    required this.etiqueta,
    required this.etiquetaLarga,
  });

  /// Primer día incluido (medianoche).
  final DateTime desde;

  /// Último día incluido (medianoche).
  final DateTime hasta;

  /// Cumplimiento medio 0..1, o `null` si en el tramo no hay ningún dato.
  final double? valor;

  /// Cuántos días del tramo tienen dato real.
  final int diasConDato;

  /// Días incluidos (para el panel de detalle al tocar la barra).
  final List<RegistroDiario> detalle;

  /// Etiqueta corta bajo la barra ("L", "S38", "sep").
  final String etiqueta;

  /// Etiqueta larga para el detalle ("lunes 21", "semana del 15/10"...).
  final String etiquetaLarga;

  bool get sinDato => valor == null;
}

/// Días que cubre cada escala, contando hoy.
int diasDeEscala(EscalaSerie escala) => switch (escala) {
      EscalaSerie.diaria => 7,
      EscalaSerie.semanal => 30,
      EscalaSerie.mensual => 365,
    };

/// Construye las barras del gráfico agrupando [registros] según [escala].
///
/// Solo se usan días con registro real; los días sin dato no se rellenan con
/// ceros: el tramo queda `sinDato` y se pinta como tal. El día de hoy se
/// incluye si viene en [registros] (la app lo mantiene en vivo).
List<PuntoSerie> construirSerie({
  required List<RegistroDiario> registros,
  required EscalaSerie escala,
  required DateTime hoy,
  required MetasDia metas,
  required Set<int> diasEntreno,
  MetricaSerie metrica = MetricaSerie.todo,
  required String Function(DateTime) etiquetaDia,
  required String Function(DateTime) etiquetaSemana,
  required String Function(DateTime) etiquetaMes,
  required String Function(DateTime) etiquetaLargaDia,
}) {
  final h = DateTime(hoy.year, hoy.month, hoy.day);
  final inicio = h.subtract(Duration(days: diasDeEscala(escala) - 1));

  // Índice rápido por día (YYYY-MM-DD) para no recorrer la lista por barra.
  final porDia = <String, RegistroDiario>{};
  for (final r in registros) {
    porDia[_claveDia(r.dia)] = r;
  }

  /// Valor de un día concreto, o `null` si no hay dato.
  double? valorDe(DateTime d) {
    final r = porDia[_claveDia(d)];
    if (r == null) return null;
    // Hoy todavía no se puede "fallar" el entreno: si aún no se ha entrenado,
    // la métrica queda sin dato hasta que el día termine (o entrene).
    final sinEntrenarAun =
        d == h && (r.entrenoMin ?? 0) == 0;
    return r.valorMetrica(
      metrica,
      metas,
      entrenoEsperado:
          diasEntreno.contains(d.weekday) && !sinEntrenarAun,
    );
  }

  bool diaEntra(DateTime d) => !d.isBefore(inicio) && !d.isAfter(h);

  switch (escala) {
    case EscalaSerie.diaria:
      final puntos = <PuntoSerie>[];
      for (var i = 0; i < 7; i++) {
        final d = inicio.add(Duration(days: i));
        final r = porDia[_claveDia(d)];
        puntos.add(PuntoSerie(
          desde: d,
          hasta: d,
          valor: valorDe(d),
          diasConDato: r == null || valorDe(d) == null ? 0 : 1,
          detalle: r == null ? const [] : [r],
          etiqueta: etiquetaDia(d),
          etiquetaLarga: etiquetaLargaDia(d),
        ));
      }
      return puntos;

    case EscalaSerie.semanal:
      // Semanas que empiezan en lunes y contienen algún día de la ventana.
      final primerLunes = inicio.subtract(Duration(days: inicio.weekday - 1));
      final puntos = <PuntoSerie>[];
      var lunes = primerLunes;
      while (!lunes.isAfter(h)) {
        final domingo = lunes.add(const Duration(days: 6));
        final desde = lunes.isBefore(inicio) ? inicio : lunes;
        final hasta = domingo.isAfter(h) ? h : domingo;
        final valores = <double>[];
        final detalle = <RegistroDiario>[];
        for (var d = desde;
            !d.isAfter(hasta);
            d = d.add(const Duration(days: 1))) {
          if (!diaEntra(d)) continue;
          final v = valorDe(d);
          if (v != null) valores.add(v);
          final r = porDia[_claveDia(d)];
          if (r != null) detalle.add(r);
        }
        puntos.add(PuntoSerie(
          desde: desde,
          hasta: hasta,
          valor: valores.isEmpty
              ? null
              : valores.reduce((a, b) => a + b) / valores.length,
          diasConDato: valores.length,
          detalle: detalle,
          etiqueta: etiquetaSemana(lunes),
          etiquetaLarga: etiquetaSemana(lunes),
        ));
        lunes = lunes.add(const Duration(days: 7));
      }
      return puntos;

    case EscalaSerie.mensual:
      // 12 meses naturales (el actual incluido), aunque el primero quede
      // incompleto: es la lectura natural de "mes a mes".
      final puntos = <PuntoSerie>[];
      var mes = DateTime(h.year, h.month - 11);
      final ultimoMes = DateTime(h.year, h.month);
      while (!mes.isAfter(ultimoMes)) {
        final finMes = DateTime(mes.year, mes.month + 1, 0);
        final desde = mes;
        final hasta = finMes.isAfter(h) ? h : finMes;
        final valores = <double>[];
        final detalle = <RegistroDiario>[];
        for (var d = desde;
            !d.isAfter(hasta);
            d = d.add(const Duration(days: 1))) {
          final v = valorDe(d);
          if (v != null) valores.add(v);
          final r = porDia[_claveDia(d)];
          if (r != null) detalle.add(r);
        }
        puntos.add(PuntoSerie(
          desde: desde,
          hasta: hasta,
          valor: valores.isEmpty
              ? null
              : valores.reduce((a, b) => a + b) / valores.length,
          diasConDato: valores.length,
          detalle: detalle,
          etiqueta: etiquetaMes(mes),
          etiquetaLarga: etiquetaMes(mes),
        ));
        mes = DateTime(mes.year, mes.month + 1);
      }
      return puntos;
  }
}

String _claveDia(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Clave `YYYY-MM-DD` de un día (misma que usa el estado para el balance).
String claveDia(DateTime d) => _claveDia(d);
