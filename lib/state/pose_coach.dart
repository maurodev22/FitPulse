import 'dart:math';

/// Fase 5: entrenador de postura con cámara.
///
/// Lógica pura (sin ML Kit ni cámara): cálculo de ángulos entre articulaciones,
/// mapa ejercicio→tipo de corrección, contador de repeticiones con histéresis y
/// feedback honesto. Todo se calcula de puntos reales del cuerpo; nada es
/// inventado.
///
/// Los puntos pueden venir en píxeles o normalizados: los ángulos NO dependen de
/// la escala, así que ambas formas funcionan igual.

/// Un punto 2D (articulación) en el plano de la imagen.
class PuntoPose {
  const PuntoPose(this.x, this.y);

  final double x;
  final double y;
}

/// Articulaciones que usa el analizador (mapeadas desde los landmarks de ML Kit).
enum Lm {
  hombroIzq,
  codoIzq,
  munecaIzq,
  caderaIzq,
  rodillaIzq,
  tobilloIzq,
  hombroDer,
  codoDer,
  munecaDer,
  caderaDer,
  rodillaDer,
  tobilloDer,
}

/// Tipo de corrección según el ejercicio.
enum TipoPostura {
  /// Sentadillas, zancadas, burpees → ángulo de rodilla.
  pierna,

  /// Flexiones, fondos → ángulo de codo.
  empuje,

  /// Plancha (y variantes) → alineación del tronco.
  plancha,

  /// Salto/skipping/mountain climbers → ritmo (contador suave de rodilla).
  cardio,

  /// Estiramientos y ejercicios sin ángulo primario: solo indica pose detectada.
  libre,
}

/// Mapa ejercicio → tipo de corrección (heurística por nombre del catálogo real).
TipoPostura tipoDeEjercicio(String nombre) {
  final n = nombre.toLowerCase();
  if (n.contains('sentadilla') || n.contains('zancada') || n.contains('burpee')) {
    return TipoPostura.pierna;
  }
  if (n.contains('flexion') || n.contains('fondo')) {
    return TipoPostura.empuje;
  }
  if (n.contains('plancha')) {
    return TipoPostura.plancha;
  }
  if (n.contains('skipping') ||
      n.contains('climber') ||
      n.contains('jumping') ||
      n.contains('jacks')) {
    return TipoPostura.cardio;
  }
  return TipoPostura.libre;
}

/// Ángulo en grados en el punto b (formado por a-b-c). 180° = recto.
double anguloGrados(PuntoPose a, PuntoPose b, PuntoPose c) {
  final abx = a.x - b.x;
  final aby = a.y - b.y;
  final cbx = c.x - b.x;
  final cby = c.y - b.y;
  final dot = abx * cbx + aby * cby;
  final ma = sqrt(abx * abx + aby * aby);
  final mb = sqrt(cbx * cbx + cby * cby);
  if (ma == 0 || mb == 0) return 180;
  final cos = (dot / (ma * mb)).clamp(-1.0, 1.0);
  return acos(cos) * 180 / pi;
}

/// Contador de repeticiones con histéresis (evita contar el ruido de la cámara).
///
/// Una repetición se completa cuando el ángulo baja de [umbralBajo] y luego
/// supera [umbralAlto].
class ContadorRepeticiones {
  ContadorRepeticiones({required this.umbralBajo, required this.umbralAlto});

  final double umbralBajo;
  final double umbralAlto;

  bool _abajo = false;
  int _reps = 0;

  int get reps => _reps;

  /// True si el ángulo actual está por debajo del umbral (fase de bajada).
  bool get abajo => _abajo;

  /// Devuelve true si este frame completó una repetición.
  bool actualizar(double angulo) {
    if (angulo < umbralBajo) {
      _abajo = true;
      return false;
    }
    if (_abajo && angulo > umbralAlto) {
      _abajo = false;
      _reps++;
      return true;
    }
    return false;
  }
}

/// Resultado del análisis de un frame.
class ResultadoPostura {
  const ResultadoPostura({
    required this.mensaje,
    required this.poseDetectada,
    this.repeticionNueva = false,
    this.reps = 0,
  });

  final String mensaje;
  final bool poseDetectada;
  final bool repeticionNueva;
  final int reps;
}

/// Analiza cada frame del stream y devuelve feedback + actualiza el contador.
class AnalizadorPostura {
  AnalizadorPostura(this.tipo)
      : _contador = switch (tipo) {
          TipoPostura.pierna => ContadorRepeticiones(umbralBajo: 110, umbralAlto: 150),
          TipoPostura.empuje => ContadorRepeticiones(umbralBajo: 100, umbralAlto: 150),
          _ => null,
        };

  final TipoPostura tipo;
  final ContadorRepeticiones? _contador;

  int get reps => _contador?.reps ?? 0;

  /// Procesa las articulaciones de un frame y produce el feedback del momento.
  ResultadoPostura analizar(Map<Lm, PuntoPose> puntos) {
    if (puntos.isEmpty ||
        !tieneArticulacionesMinimas(tipo, puntos)) {
      return const ResultadoPostura(
        mensaje: 'Coloca tu cuerpo en el encuadre',
        poseDetectada: false,
      );
    }

    switch (tipo) {
      case TipoPostura.pierna:
        return _analizarPierna(puntos);
      case TipoPostura.empuje:
        return _analizarEmpuje(puntos);
      case TipoPostura.plancha:
        return _analizarPlancha(puntos);
      case TipoPostura.cardio:
        return _analizarCardio(puntos);
      case TipoPostura.libre:
        return const ResultadoPostura(
          mensaje: 'Pose detectada ✓ · mantén la posición',
          poseDetectada: true,
        );
    }
  }

  bool tieneArticulacionesMinimas(TipoPostura t, Map<Lm, PuntoPose> p) {
    switch (t) {
      case TipoPostura.pierna:
        return _ladoPierna(p) != null;
      case TipoPostura.empuje:
        return _ladoBrazo(p) != null;
      case TipoPostura.plancha:
        return _ladoTronco(p) != null;
      case TipoPostura.cardio:
        return _ladoPierna(p) != null;
      case TipoPostura.libre:
        return p.isNotEmpty;
    }
  }

  ResultadoPostura _analizarPierna(Map<Lm, PuntoPose> puntos) {
    final lado = _ladoPierna(puntos)!;
    final angulo = _anguloPierna(lado, puntos)!;
    return _feedbackAngulo(angulo, 'Flexiona las rodillas', 'Sube para completar');
  }

  ResultadoPostura _analizarEmpuje(Map<Lm, PuntoPose> puntos) {
    final lado = _ladoBrazo(puntos)!;
    final angulo = _anguloBrazo(lado, puntos)!;
    return _feedbackAngulo(angulo, 'Baja el pecho', 'Sube para completar');
  }

  ResultadoPostura _analizarPlancha(Map<Lm, PuntoPose> puntos) {
    final lado = _ladoTronco(puntos)!;
    final angulo = _anguloTronco(lado, puntos)!;
    if (angulo >= 158) {
      return const ResultadoPostura(
        mensaje: '✔ Cuerpo alineado · mantén la plancha',
        poseDetectada: true,
      );
    }
    return ResultadoPostura(
      mensaje: 'Eleva la cadera: tu cuerpo está doblado (${angulo.round()}°)',
      poseDetectada: true,
    );
  }

  ResultadoPostura _analizarCardio(Map<Lm, PuntoPose> puntos) {
    // Contador suave de rodilla: da ritmo sin ser estricto.
    final lado = _ladoPierna(puntos)!;
    final angulo = _anguloPierna(lado, puntos)!;
    final nueva = _contador?.actualizar(angulo) ?? false;
    return ResultadoPostura(
      mensaje: nueva ? 'Ritmo ✓ · síguelo 🎵' : 'Mantén el ritmo 🎵',
      poseDetectada: true,
      repeticionNueva: nueva,
      reps: _contador?.reps ?? 0,
    );
  }

  ResultadoPostura _feedbackAngulo(double angulo, String bajaMsg, String subeMsg) {
    final contador = _contador;
    if (contador == null) {
      return ResultadoPostura(
        mensaje: 'Ángulo ${angulo.round()}°',
        poseDetectada: true,
      );
    }
    final nueva = contador.actualizar(angulo);
    final String mensaje;
    if (nueva) {
      mensaje = '✔ Repetición ${contador.reps}';
    } else if (contador.abajo) {
      mensaje = '$bajaMsg · ${angulo.round()}°';
    } else if (angulo < contador.umbralAlto) {
      mensaje = '$subeMsg · ${angulo.round()}°';
    } else {
      mensaje = 'Prepara la posición (${angulo.round()}°)';
    }
    return ResultadoPostura(
      mensaje: mensaje,
      poseDetectada: true,
      repeticionNueva: nueva,
      reps: contador.reps,
    );
  }

  // --- selección de lado y ángulos -----------------------------------------

  double? _anguloPierna(int lado, Map<Lm, PuntoPose> p) {
    final esIzq = lado == 0;
    final hip = p[esIzq ? Lm.caderaIzq : Lm.caderaDer];
    final knee = p[esIzq ? Lm.rodillaIzq : Lm.rodillaDer];
    final ankle = p[esIzq ? Lm.tobilloIzq : Lm.tobilloDer];
    if (hip == null || knee == null || ankle == null) return null;
    return anguloGrados(hip, knee, ankle);
  }

  double? _anguloBrazo(int lado, Map<Lm, PuntoPose> p) {
    final esIzq = lado == 0;
    final shoulder = p[esIzq ? Lm.hombroIzq : Lm.hombroDer];
    final elbow = p[esIzq ? Lm.codoIzq : Lm.codoDer];
    final wrist = p[esIzq ? Lm.munecaIzq : Lm.munecaDer];
    if (shoulder == null || elbow == null || wrist == null) return null;
    return anguloGrados(shoulder, elbow, wrist);
  }

  double? _anguloTronco(int lado, Map<Lm, PuntoPose> p) {
    final esIzq = lado == 0;
    final shoulder = p[esIzq ? Lm.hombroIzq : Lm.hombroDer];
    final hip = p[esIzq ? Lm.caderaIzq : Lm.caderaDer];
    final ankle = p[esIzq ? Lm.tobilloIzq : Lm.tobilloDer];
    if (shoulder == null || hip == null || ankle == null) return null;
    return anguloGrados(shoulder, hip, ankle);
  }

  /// Lado (0 = izquierdo, 1 = derecho) que tiene la tripleta completa.
  int? _ladoPierna(Map<Lm, PuntoPose> p) =>
      (p.containsKey(Lm.caderaIzq) &&
              p.containsKey(Lm.rodillaIzq) &&
              p.containsKey(Lm.tobilloIzq))
          ? 0
          : (p.containsKey(Lm.caderaDer) &&
                  p.containsKey(Lm.rodillaDer) &&
                  p.containsKey(Lm.tobilloDer))
              ? 1
              : null;

  int? _ladoBrazo(Map<Lm, PuntoPose> p) =>
      (p.containsKey(Lm.hombroIzq) && p.containsKey(Lm.codoIzq) && p.containsKey(Lm.munecaIzq))
          ? 0
          : (p.containsKey(Lm.hombroDer) && p.containsKey(Lm.codoDer) && p.containsKey(Lm.munecaDer))
              ? 1
              : null;

  int? _ladoTronco(Map<Lm, PuntoPose> p) =>
      (p.containsKey(Lm.hombroIzq) && p.containsKey(Lm.caderaIzq) && p.containsKey(Lm.tobilloIzq))
          ? 0
          : (p.containsKey(Lm.hombroDer) && p.containsKey(Lm.caderaDer) && p.containsKey(Lm.tobilloDer))
              ? 1
              : null;
}