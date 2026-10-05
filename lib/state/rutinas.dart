// L3 — Rutina propia del usuario.
//
// Una rutina es una lista ordenada de [WorkoutExercise] con un descanso por
// defecto. Se convierte en un [WorkoutProgram] para reutilizar el reproductor
// existente **sin tocarlo**: `WorkoutPlayerScreen` no distingue entre un programa
// del catálogo y una rutina creada por el usuario.
//
// Honestidad de los datos (regla del proyecto):
// - `minutos`, `intensidad` y `kcalEstimadas` son **cálculos sobre lo que el
//   usuario eligió**, no datos medidos. La estimación de kcal usa la fórmula
//   documentada en [kcalPorMinutoEfectivo] y la UI la etiqueta como estimación.
// - Si la rutina está vacía, los valores derivados devuelven 0 en vez de un
//   número inventado.

import 'workout.dart';
import 'workout_exercise_catalog.dart';

/// Kcal por minuto de trabajo según el grupo del ejercicio.
///
/// No es una medición: es una **tabla openly documentada** para estimar el gasto
/// de una rutina a partir de lo que el usuario eligió. La app nunca la presenta
/// como dato real (ver `WorkoutSession.calorias`, que ya advierte de esto).
const _kcalPorMinuto = <String, double>{
  'Cardio': 11.0,
  'Piernas': 8.0,
  'Empuje': 7.0,
  'Tirón': 7.0,
  'Core': 6.0,
  'Movilidad': 3.5,
};

/// Grupo al que pertenece un ejercicio por nombre (del catálogo). Los nombres que
/// no están en el catálogo caen en 'Movilidad', el valor más bajo: si no
/// reconocemos el ejercicio, subestimamos en lugar de exagerar.
String _grupoDe(String nombreEjercicio) =>
    buscarEjercicio(nombreEjercicio)?.grupo ?? 'Movilidad';

/// Rutina de entrenamiento creada por el usuario (L3).
class Rutina {
  const Rutina({
    required this.id,
    required this.nombre,
    required this.ejercicios,
    this.descansoPorDefecto = const Duration(seconds: 60),
    this.creada = 0,
  });

  /// Identificador estable (se usa como clave al guardar por nombre).
  final String id;

  final String nombre;
  final List<WorkoutExercise> ejercicios;

  /// Descanso que se aplica entre ejercicios al reproducir la rutina.
  final Duration descansoPorDefecto;

  /// `DateTime.now().millisecondsSinceEpoch` de la creación (0 = desconocida).
  final int creada;

  bool get vacia => ejercicios.isEmpty;

  /// Minutos de trabajo real (sin descansos), redondeados hacia arriba.
  int get minutosTrabajo {
    if (vacia) return 0;
    final segundos =
        ejercicios.fold<int>(0, (suma, e) => suma + e.duracion.inSeconds);
    return (segundos / 60).ceil();
  }

  /// Descanso efectivo de cada ejercicio: los estiramientos no descansan.
  Duration get descansoDe => descansoPorDefecto;

  Duration _descansoEfectivo(WorkoutExercise e) =>
      esEstiramiento(e.nombre) ? Duration.zero : descansoPorDefecto;

  /// Minutos de descanso totales de la rutina.
  int get minutosDescanso {
    if (vacia) return 0;
    final segundos = ejercicios.fold<int>(
      0,
      (suma, e) => suma + _descansoEfectivo(e).inSeconds,
    );
    return (segundos / 60).ceil();
  }

  /// Duración total de la rutina: trabajo + descanso (lo que ve el usuario).
  int get duracionMin => minutosTrabajo + minutosDescanso;

  /// Etiqueta corta para chips y tarjetas: "35 min" o "1 h 05".
  String get duracionEtiqueta {
    if (vacia) return '0 min';
    if (duracionMin < 60) return '$duracionMin min';
    final h = duracionMin ~/ 60;
    final m = duracionMin % 60;
    return m == 0 ? '$h h' : '$h h $m';
  }

  /// Intensidad **derivada** del contenido de la rutina (nunca escrita a mano):
  /// promedio de kcal por minuto de trabajo de sus ejercicios.
  String get intensidad {
    if (vacia) return 'Baja';
    final porMinuto = kcalPorMinutoEfectivo;
    if (porMinuto >= 9) return 'Alta';
    if (porMinuto >= 6) return 'Media';
    return 'Baja';
  }

  /// Kcal por minuto de trabajo, promedio ponderado por los segundos de cada
  /// ejercicio. `0` si la rutina está vacía.
  double get kcalPorMinutoEfectivo {
    if (vacia) return 0;
    final segundos = ejercicios.fold<int>(
      0,
      (suma, e) => suma + e.duracion.inSeconds,
    );
    if (segundos == 0) return 0;
    final ponderado = ejercicios.fold<double>(
      0,
      (suma, e) => suma + (_kcalPorMinuto[_grupoDe(e.nombre)] ?? 3.5) *
          e.duracion.inSeconds,
    );
    return ponderado / segundos;
  }

  /// Kcal estimadas de la rutina: minutos de trabajo × kcal por minuto del
  /// contenido. Es una **estimación**, no una medición.
  int get kcalEstimadas => (minutosTrabajo * kcalPorMinutoEfectivo).round();

  /// Descripción corta para la tarjeta de la rutina, construida con datos reales
  /// de la rutina (número de ejercicios y grupos), sin texto inventado.
  String get resumen =>'${ejercicios.length} ejercicios · $duracionEtiqueta';

  /// Convierte la rutina en un [WorkoutProgram] para el reproductor existente.
  ///
  /// El descanso por defecto se aplica a todos los ejercicios **salvo los
  /// estiramientos**, que en el catálogo propio llevan `Duration.zero`.
  WorkoutProgram aPrograma({String? descripcion}) => WorkoutProgram(
        id: id,
        nombre: nombre,
        descripcion: descripcion ?? resumen,
        duracionMin: duracionMin,
        kcalEstimadas: kcalEstimadas,
        intensidad: intensidad,
        ejercicios: ejercicios,
      );

  Rutina copyWith({
    String? nombre,
    List<WorkoutExercise>? ejercicios,
    Duration? descansoPorDefecto,
  }) =>
      Rutina(
        id: id,
        nombre: nombre ?? this.nombre,
        ejercicios: ejercicios ?? this.ejercicios,
        descansoPorDefecto: descansoPorDefecto ?? this.descansoPorDefecto,
        creada: creada,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'n': nombre,
        'd': descansoPorDefecto.inSeconds,
        'c': creada,
        'e': ejercicios
            .map((e) => {
                  'n': e.nombre,
                  's': e.duracion.inSeconds,
                  'r': e.repeticiones,
                  'x': e.descanso.inSeconds,
                })
            .toList(),
      };

  /// Reconstruye una rutina desde JSON, tolerando datos incompletos o raros
  /// (por ejemplo, un backup editado a mano): descarta lo que no se puede usar
  /// en lugar de fallar o inventar.
  factory Rutina.fromJson(Map<String, dynamic> json) {
    // Un backup editado a mano puede traer cualquier cosa donde se espera una
    // lista: `as List?` lanzaría. Se comprueba el tipo antes de usar.
    final lista = json['e'] is List ? json['e'] as List : const <Object?>[];
    final ejercicios = <WorkoutExercise>[];
    for (final bruto in lista) {
      if (bruto is! Map) continue;
      final m = Map<String, dynamic>.from(bruto);
      final nombre = (m['n'] as String?)?.trim() ?? '';
      if (nombre.isEmpty) continue;
      final segundos = (m['s'] as num?)?.toInt() ?? 0;
      if (segundos <= 0) continue;
      ejercicios.add(
        WorkoutExercise(
          nombre: nombre,
          duracion: Duration(seconds: segundos),
          descanso: Duration(seconds: (m['x'] as num?)?.toInt() ?? 0),
          repeticiones: (m['r'] as String?) ?? '',
        ),
      );
    }
    final segundosDescanso = (json['d'] as num?)?.toInt() ?? 60;
    return Rutina(
      id: (json['id'] as String?)?.trim().isNotEmpty == true
          ? (json['id'] as String).trim()
          : 'rutina_${DateTime.now().millisecondsSinceEpoch}',
      nombre: (json['n'] as String?)?.trim().isNotEmpty == true
          ? (json['n'] as String).trim()
          : 'Mi rutina',
      ejercicios: ejercicios,
      descansoPorDefecto: Duration(seconds: segundosDescanso > 0
          ? segundosDescanso
          : 60),
      creada: (json['c'] as num?)?.toInt() ?? 0,
    );
  }
}