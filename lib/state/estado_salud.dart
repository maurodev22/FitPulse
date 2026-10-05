/// Clasificación honesta del estado de salud diario de FitPulse.
///
/// Se calcula SOLO con métricas reales que el usuario aporta cada día
/// (IMC del perfil, pasos del sensor, gasto activo y sueño de Health
/// Connect, agua manual o de Health Connect). Nunca se inventa un estado:
/// con menos de 2 métricas con dato se responde "sin datos suficientes".
///
/// Puntuación por métrica (0–3, fuentes documentadas):
/// - IMC: 18,5–24,9 → 3 · 25–29,9 → 2 · 16,5–18,4 o 30–39,9 → 1 ·
///   <16,5 o ≥40 → 0 (categorías de la OMS/NHLBI).
/// - Pasos (Paluch et al., *Lancet Public Health* 2022): <60 años:
///   ≥8000 → 3, ≥4000 → 2, ≥2000 → 1, resto → 0; ≥60 años: ≥6000 → 3,
///   ≥3500 → 2, ≥1500 → 1, resto → 0.
/// - Gasto activo (OMS: 150–300 min/sem moderada ≈ 150–250 kcal/día):
///   ≥300 → 3, ≥150 → 2, ≥50 → 1, resto → 0.
/// - Sueño (adultos 7–9 h): 7–9 → 3; 6–7 o 9–10 → 2; 5–6 o 10–12 → 1;
///   <5 o >12 → 0.
/// - Agua: se puntúa **respecto a la meta diaria del usuario** (L2): ≥100 % de
///   la meta → 3 · ≥60 % → 2 · ≥30 % → 1 · menos → 0. Así el estado de salud
///   no miente si el usuario cambia su meta de agua en Perfil.
///
/// Estado final por promedio de las métricas con dato:
/// ≥2,5 → excelente · 1,75–2,49 → bueno · 1,0–1,74 → regular · <1,0 → malo.
library;

/// Estados de salud honestos, de peor a mejor.
enum EstadoSalud { malo, regular, bueno, excelente }

/// Métricas que pueden participar en el estado de salud.
enum MetricaEstado { imc, pasos, gastoActivo, suenio, agua }

/// Puntuación (0–3) de una métrica con dato real.
class PuntuacionMetrica {
  const PuntuacionMetrica({
    required this.metrica,
    required this.puntos,
    required this.detalle,
  });

  final MetricaEstado metrica;

  /// Puntos obtenidos (0–3).
  final int puntos;

  /// Valor real formateado para mostrar (p. ej. '21.8', '6542',
  /// '312 kcal', '7h 30m', '2.0 L'). Nunca inventado.
  final String detalle;
}

/// Resultado de la clasificación diaria del estado de salud.
class ResultadoEstadoSalud {
  const ResultadoEstadoSalud._({
    required this.estado,
    required this.promedio,
    required this.metricas,
  });

  /// Estado final; `null` cuando no hay datos suficientes.
  final EstadoSalud? estado;

  /// Promedio de las métricas con dato (0 si no hay datos).
  final double promedio;

  /// Métricas reales utilizadas (nunca se inventan).
  final List<PuntuacionMetrica> metricas;

  /// `true` cuando se necesitan más métricas reales para opinar.
  bool get sinDatos => estado == null;
}

/// Clasifica el estado de salud con los datos reales disponibles.
///
/// Cada parámetro es `null` si no hay dato real de esa métrica (sin permiso,
/// sin sensor, o sin valor registrado hoy); esas métricas se ignoran por
/// honestidad. Con menos de 2 métricas con dato no hay estado.
ResultadoEstadoSalud clasificarEstadoSalud({
  double? imc,
  int? edad,
  int? pasos,
  double? gastoActivoKcal,
  Duration? suenio,
  double? aguaLitros,
  double metaAguaLitros = 2.5,
}) {
  final metricas = <PuntuacionMetrica>[
    if (imc != null && imc > 0)
      PuntuacionMetrica(
        metrica: MetricaEstado.imc,
        puntos: _puntosImc(imc),
        detalle: imc.toStringAsFixed(1),
      ),
    if (pasos != null && pasos >= 0)
      PuntuacionMetrica(
        metrica: MetricaEstado.pasos,
        puntos: _puntosPasos(pasos, edad),
        detalle: '$pasos',
      ),
    if (gastoActivoKcal != null)
      PuntuacionMetrica(
        metrica: MetricaEstado.gastoActivo,
        puntos: _puntosGastoActivo(gastoActivoKcal),
        detalle: '${gastoActivoKcal.round()} kcal',
      ),
    if (suenio != null)
      PuntuacionMetrica(
        metrica: MetricaEstado.suenio,
        puntos: _puntosSuenio(suenio),
        detalle: _formatoSuenio(suenio),
      ),
    if (aguaLitros != null && aguaLitros >= 0)
      PuntuacionMetrica(
        metrica: MetricaEstado.agua,
        puntos: _puntosAgua(aguaLitros, metaAguaLitros),
        detalle: '${aguaLitros.toStringAsFixed(1)} L',
      ),
  ];

  if (metricas.length < 2) {
    return ResultadoEstadoSalud._(
      estado: null,
      promedio: 0,
      metricas: metricas,
    );
  }

  final promedio =
      metricas.map((m) => m.puntos).reduce((a, b) => a + b) / metricas.length;
  final estado = promedio >= 2.5
      ? EstadoSalud.excelente
      : promedio >= 1.75
          ? EstadoSalud.bueno
          : promedio >= 1.0
              ? EstadoSalud.regular
              : EstadoSalud.malo;
  return ResultadoEstadoSalud._(
    estado: estado,
    promedio: promedio,
    metricas: metricas,
  );
}

int _puntosImc(double imc) {
  if (imc < 16.5 || imc >= 40) return 0;
  if (imc < 18.5 || imc >= 30) return 1;
  if (imc >= 25) return 2;
  return 3;
}

int _puntosPasos(int pasos, int? edad) {
  final umbral = (edad != null && edad >= 60) ? 6000 : 8000;
  if (pasos >= umbral) return 3;
  final segundo = (edad != null && edad >= 60) ? 3500 : 4000;
  if (pasos >= segundo) return 2;
  final tercero = (edad != null && edad >= 60) ? 1500 : 2000;
  if (pasos >= tercero) return 1;
  return 0;
}

int _puntosGastoActivo(double kcal) {
  if (kcal >= 300) return 3;
  if (kcal >= 150) return 2;
  if (kcal >= 50) return 1;
  return 0;
}

int _puntosSuenio(Duration duracion) {
  final h = duracion.inMinutes / 60.0;
  if (h >= 7 && h <= 9) return 3;
  if ((h >= 6 && h < 7) || (h > 9 && h <= 10)) return 2;
  if ((h >= 5 && h < 6) || (h > 10 && h <= 12)) return 1;
  return 0;
}

/// Agua medida contra la meta del usuario (no contra un número fijo): 100 %
/// de la meta = 3 puntos; 60 % = 2; 30 % = 1; por debajo = 0.
int _puntosAgua(double litros, double metaLitros) {
  if (litros <= 0 || metaLitros <= 0) return 0;
  final r = litros / metaLitros;
  if (r >= 1.0) return 3;
  if (r >= 0.6) return 2;
  if (r >= 0.3) return 1;
  return 0;
}

String _formatoSuenio(Duration duracion) {
  final h = duracion.inHours;
  final m = duracion.inMinutes.remainder(60);
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}