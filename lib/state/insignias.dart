/// FASE C — estructura de insignias (logros temáticos) de la gamificación.
///
/// Reglas del diseño (`docs/DISENO_GAMIFICACION.md`):
///  * cada insignia se otorga SOLO con su condición real verificada sobre
///    datos ya persistidos; nada se inventa;
///  * las conseguidas muestran la fecha REAL de desbloqueo, derivada del
///    propio historial; si la fecha no se puede verificar, no se muestra;
///  * las bloqueadas no muestran progreso ("te faltan 2 para…"): solo el
///    nombre y la condición, para no generar presión.
///
/// El módulo es puro (recibe `DatosInsignias` y devuelve evaluaciones), así
/// que se puede probar con datos fabricados en `test/insignias_test.dart`.
library;

/// Identidad estable de cada insignia del catálogo.
enum InsigniaId {
  primeraSesion,
  constancia,
  disciplina,
  hierro,
  veterano,
  marcaPersonal,
  tecnico,
  hidratado,
  primerReto,
}

/// Datos reales (y solo reales) sobre los que se evalúa el catálogo. Son
/// proyecciones de `AppState`; el módulo no sabe de dónde vienen.
class DatosInsignias {
  const DatosInsignias({
    required this.fechasSesiones,
    required this.semanasPeso,
    required this.primerasRepsPorEjercicio,
    required this.diasAguaCumplida,
  });

  /// Fechas de sesión completada, ASCENDENTES y con repetición (una por
  /// sesión real). Definen también los días con sesión y la racha máxima.
  final List<DateTime> fechasSesiones;

  /// Anchas de semana (lunes) con registro de peso, ASCENDENTES y sin
  /// repetir (un registro por semana de verdad).
  final List<DateTime> semanasPeso;

  /// Ejercicio → fecha de su PRIMER registro de repeticiones.
  final Map<String, DateTime> primerasRepsPorEjercicio;

  /// Días (medianoche) en los que se cumplió la meta de agua, ASCENDENTES
  /// y sin repetir.
  final List<DateTime> diasAguaCumplida;
}

/// Resultado de evaluar una insignia.
class InsigniaResultado {
  const InsigniaResultado({
    required this.id,
    required this.conseguida,
    this.fecha,
  });

  final InsigniaId id;

  /// `true` solo si la condición real se cumple sobre los datos.
  final bool conseguida;

  /// Fecha REAL de desbloqueo cuando se puede derivar del historial.
  final DateTime? fecha;
}

/// Días (medianoche) únicos y ascendentes a partir de las sesiones.
List<DateTime> _diasUnicos(List<DateTime> fechas) {
  final set = <DateTime>{};
  for (final f in fechas) {
    set.add(DateTime(f.year, f.month, f.day));
  }
  final list = set.toList()..sort();
  return list;
}

/// Mejor racha consecutiva de días con sesión (misma definición que
/// `AppState.rachaMaxima`).
int _rachaMaxima(List<DateTime> dias) {
  if (dias.isEmpty) return 0;
  var mejor = 1;
  var racha = 1;
  for (var i = 1; i < dias.length; i++) {
    if (dias[i].difference(dias[i - 1]).inDays == 1) {
      racha++;
      if (racha > mejor) mejor = racha;
    } else {
      racha = 1;
    }
  }
  return mejor;
}

/// Día en que la racha alcanzó por PRIMERA vez [objetivo] días seguidos
/// (o `null` si nunca la alcanzó).
DateTime? _fechaPrimeraRacha(List<DateTime> dias, int objetivo) {
  if (dias.length < objetivo) return null;
  var racha = 1;
  for (var i = 1; i < dias.length; i++) {
    if (dias[i].difference(dias[i - 1]).inDays == 1) {
      racha++;
    } else {
      racha = 1;
    }
    if (racha == objetivo) return dias[i];
  }
  return null;
}

/// Fecha de la sesión N (1 = la más antigua). `null` si no hay N sesiones.
DateTime? _fechaSesionN(List<DateTime> fechas, int n) =>
    fechas.length >= n ? fechas[n - 1] : null;

/// Lunes de la 4ª semana de la primera racha de [n] semanas seguidas con
/// registro de peso (`null` si nunca hubo [n] semanas consecutivas).
DateTime? _fechaSemanasSeguida(List<DateTime> semanas, int n) {
  for (var i = 0; i + n <= semanas.length; i++) {
    var consecutivas = true;
    for (var k = 1; k < n; k++) {
      if (semanas[i + k].difference(semanas[i + k - 1]).inDays != 7) {
        consecutivas = false;
        break;
      }
    }
    if (consecutivas) return semanas[i + n - 1];
  }
  return null;
}

/// Fecha en la que se alcanzaron [n] ejercicios distintos con repeticiones:
/// la enésima fecha de primera aparición más antigua.
DateTime? _fechaEjerciciosDistintos(
  Map<String, DateTime> primeras,
  int n,
) {
  if (primeras.length < n) return null;
  final fechas = primeras.values.toList()..sort();
  return fechas[n - 1];
}

/// Día en que se cumplió la meta de agua por enésima vez.
DateTime? _fechaHidratado(List<DateTime> dias, int n) =>
    dias.length >= n ? dias[n - 1] : null;

/// Evalúa el catálogo completo de insignias en orden de catálogo.
///
/// Nota de diseño: "Constancia" (racha 3) y "1er Reto" (reto de 3 días)
/// comparten condición y fecha porque en la app el reto de 3 días se completa
/// exactamente cuando la racha llega a 3 (`AppState.retoCompletado` deriva de
/// la racha). Se mantienen como dos insignias porque son dos mecánicas que el
/// usuario ve por separado (racha vs reto) y la tabla de diseño las lista
/// ambas; si el usuario prefiere, se pueden fusionar en una sola.
List<InsigniaResultado> evaluarInsignias(DatosInsignias d) {
  final dias = _diasUnicos(d.fechasSesiones);
  final rachaMax = _rachaMaxima(dias);
  final fechaPrimerReto = _fechaPrimeraRacha(dias, 3);

  return [
    InsigniaResultado(
      id: InsigniaId.primeraSesion,
      conseguida: dias.isNotEmpty,
      fecha: dias.isEmpty ? null : dias.first,
    ),
    InsigniaResultado(
      id: InsigniaId.constancia,
      conseguida: rachaMax >= 3,
      fecha: fechaPrimerReto,
    ),
    InsigniaResultado(
      id: InsigniaId.disciplina,
      conseguida: rachaMax >= 7,
      fecha: _fechaPrimeraRacha(dias, 7),
    ),
    InsigniaResultado(
      id: InsigniaId.hierro,
      conseguida: d.fechasSesiones.length >= 25,
      fecha: _fechaSesionN(d.fechasSesiones, 25),
    ),
    InsigniaResultado(
      id: InsigniaId.veterano,
      conseguida: d.fechasSesiones.length >= 100,
      fecha: _fechaSesionN(d.fechasSesiones, 100),
    ),
    InsigniaResultado(
      id: InsigniaId.marcaPersonal,
      conseguida: _fechaSemanasSeguida(d.semanasPeso, 4) != null,
      fecha: _fechaSemanasSeguida(d.semanasPeso, 4),
    ),
    InsigniaResultado(
      id: InsigniaId.tecnico,
      conseguida: d.primerasRepsPorEjercicio.length >= 10,
      fecha: _fechaEjerciciosDistintos(d.primerasRepsPorEjercicio, 10),
    ),
    InsigniaResultado(
      id: InsigniaId.hidratado,
      conseguida: d.diasAguaCumplida.length >= 7,
      fecha: _fechaHidratado(d.diasAguaCumplida, 7),
    ),
    InsigniaResultado(
      id: InsigniaId.primerReto,
      conseguida: rachaMax >= 3,
      fecha: fechaPrimerReto,
    ),
  ];
}