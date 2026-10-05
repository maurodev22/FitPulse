/// Catálogo único de ejercicios disponibles para construir rutinas propias (L3).
///
/// Un solo catálogo para los dos usos:
/// - Las rutinas que crea el usuario en "Mis rutinas" (aquí elige de esta lista).
/// - Los programas fijos de `workout_catalog.dart` (cuyos nombres de ejercicio
///   están todos incluidos aquí, para que no haya dos catálogos que divergan).
///
/// Los nombres coinciden **exactamente** con los de los programas fijos, porque
/// `pose_coach.dart` decide el tipo de corrección de postura por el nombre del
/// ejercicio: si el constructor usara otros nombres, el entrenador con cámara
/// dejaría de reconocer la mitad. Un test de este archivo lo comprueba.
library;

/// Grupo muscular de un ejercicio. Se usa para filtrar al montar la rutina.
class GrupoEjercicio {
  const GrupoEjercicio(this.nombre, this.icono);

  final String nombre;

  /// Material icon del grupo (evita un `switch` con strings en la UI).
  final String icono;
}

/// Grupos disponibles, en el orden en que se muestran los filtros.
const gruposEjercicio = <GrupoEjercicio>[
  GrupoEjercicio('Piernas', 'directions_walk'),
  GrupoEjercicio('Empuje', 'fitness_center'),
  GrupoEjercicio('Tirón', 'rowing'),
  GrupoEjercicio('Core', 'shield'),
  GrupoEjercicio('Cardio', 'directions_run'),
  GrupoEjercicio('Movilidad', 'self_improvement'),
];

/// Ejercicio del catálogo con los valores sugeridos por defecto.
class EjercicioCatalogo {
  const EjercicioCatalogo({
    required this.nombre,
    required this.grupo,
    required this.duracion,
    required this.repeticiones,
    this.descripcion = '',
    this.esEstiramiento = false,
  });

  final String nombre;
  final String grupo;
  final Duration duracion;
  final String repeticiones;
  final String descripcion;

  /// Los estiramientos no llevan descanso: son el final de la rutina.
  final bool esEstiramiento;

  /// `true` si pertenece al grupo indicado (búsqueda sin acentos ni mayúsculas).
  bool enGrupo(String grupo) =>
      this.grupo.toLowerCase() == grupo.trim().toLowerCase();
}

/// Catálogo de ejercicios para rutinas propias (L3).
///
/// 26 ejercicios: todos los que ya usan los 4 programas fijos más una extensión
/// propia. Tiempo y repeticiones son **valores sugeridos** (el usuario puede
/// cambiarlos), no datos de salud.
const catalogoEjercicios = <EjercicioCatalogo>[
  // ---- Piernas ----
  EjercicioCatalogo(
    nombre: 'Sentadillas',
    grupo: 'Piernas',
    duracion: Duration(seconds: 40),
    repeticiones: '12 reps',
    descripcion: 'Cuello y pecho altos, rodillas alineadas con la punta del pie.',
  ),
  EjercicioCatalogo(
    nombre: 'Sentadilla profunda',
    grupo: 'Piernas',
    duracion: Duration(seconds: 60),
    repeticiones: 'Mantener',
    descripcion: 'Baja hasta donde el cuerpo lo permita, sin despegar los talones.',
    esEstiramiento: true,
  ),
  EjercicioCatalogo(
    nombre: 'Zancadas alternas',
    grupo: 'Piernas',
    duracion: Duration(seconds: 40),
    repeticiones: '10 por pierna',
  ),
  EjercicioCatalogo(
    nombre: 'Zancada baja estática',
    grupo: 'Piernas',
    duracion: Duration(seconds: 60),
    repeticiones: '30 s por lado',
    descripcion: 'Rodilla trasera casi tocando el suelo. Trabaja equilibrio.',
    esEstiramiento: true,
  ),
  EjercicioCatalogo(
    nombre: 'Puente de glúteos',
    grupo: 'Piernas',
    duracion: Duration(seconds: 40),
    repeticiones: '15 reps',
    descripcion: 'Empuja la cadera hacia arriba apretando los glúteos arriba.',
  ),
  EjercicioCatalogo(
    nombre: 'Sentadilla con salto',
    grupo: 'Piernas',
    duracion: Duration(seconds: 30),
    repeticiones: '10 reps',
  ),
  EjercicioCatalogo(
    nombre: 'Estiramiento de isquios',
    grupo: 'Piernas',
    duracion: Duration(seconds: 60),
    repeticiones: '30 s por lado',
    descripcion: 'Pierna extendida en el suelo, tira suave de la rodilla hacia el pecho.',
    esEstiramiento: true,
  ),

  // ---- Empuje ----
  EjercicioCatalogo(
    nombre: 'Flexiones',
    grupo: 'Empuje',
    duracion: Duration(seconds: 40),
    repeticiones: '12 reps',
    descripcion: 'Cuerpo recto de cabeza a talones; el pecho baja hasta el suelo.',
  ),
  EjercicioCatalogo(
    nombre: 'Fondos de tríceps',
    grupo: 'Empuje',
    duracion: Duration(seconds: 40),
    repeticiones: '12 reps',
    descripcion: 'Codos hacia atrás, 팔os pegados al cuerpo.',
  ),
  EjercicioCatalogo(
    nombre: 'Prensa de manos',
    grupo: 'Empuje',
    duracion: Duration(seconds: 30),
    repeticiones: '10 reps',
    descripcion: 'Baja el pecho hasta 90° de codo. Tono de brazos.',
  ),
  EjercicioCatalogo(
    nombre: 'Flexiones declinadas',
    grupo: 'Empuje',
    duracion: Duration(seconds: 40),
    repeticiones: '10 reps',
    descripcion: 'Apoya las manos en un banco o silla: mismo patrón, menos carga.',
  ),

  // ---- Tirón ----
  EjercicioCatalogo(
    nombre: 'Remo con toalla',
    grupo: 'Tirón',
    duracion: Duration(seconds: 40),
    repeticiones: '12 reps',
    descripcion:
        'Tirón con una toalla (sin material): espalda neutra y codos pegados al cuerpo.',
  ),
  EjercicioCatalogo(
    nombre: 'Superman',
    grupo: 'Tirón',
    duracion: Duration(seconds: 30),
    repeticiones: '10 reps',
    descripcion: 'Boca abajo, eleva brazos y pecho dos segundos y baja despacio.',
  ),
  EjercicioCatalogo(
    nombre: 'Encogimiento de hombros',
    grupo: 'Tirón',
    duracion: Duration(seconds: 30),
    repeticiones: '15 reps',
  ),
  EjercicioCatalogo(
    nombre: 'Puente de hombros',
    grupo: 'Tirón',
    duracion: Duration(seconds: 40),
    repeticiones: '12 reps',
    descripcion:
        'Tumbado boca arriba, empuja con los codos para despegar los omóplatos.',
  ),

  // ---- Core ----
  EjercicioCatalogo(
    nombre: 'Plancha',
    grupo: 'Core',
    duracion: Duration(seconds: 40),
    repeticiones: 'Mantener',
    descripcion: 'Codo bajo el hombro, cadera a la altura, aprieta el abdomen.',
  ),
  EjercicioCatalogo(
    nombre: 'Plancha lateral',
    grupo: 'Core',
    duracion: Duration(seconds: 30),
    repeticiones: '30 s por lado',
  ),
  EjercicioCatalogo(
    nombre: 'Abdominales bicicleta',
    grupo: 'Core',
    duracion: Duration(seconds: 40),
    repeticiones: '20 reps',
  ),
  EjercicioCatalogo(
    nombre: 'Abdominales crunch',
    grupo: 'Core',
    duracion: Duration(seconds: 40),
    repeticiones: '20 reps',
  ),
  EjercicioCatalogo(
    nombre: 'Mountain Climbers',
    grupo: 'Core',
    duracion: Duration(seconds: 40),
    repeticiones: '3 rondas',
    descripcion: 'A los cuatro: rodillas alternas hacia el pecho, ritmo constante.',
  ),
  EjercicioCatalogo(
    nombre: 'Hollow Hold',
    grupo: 'Core',
    duracion: Duration(seconds: 30),
    repeticiones: 'Mantener',
    descripcion: 'Espalda pegada al suelo y hombros despegados, piernas estiradas.',
  ),

  // ---- Cardio ----
  EjercicioCatalogo(
    nombre: 'Jumping Jacks',
    grupo: 'Cardio',
    duracion: Duration(seconds: 40),
    repeticiones: '3 rondas',
  ),
  EjercicioCatalogo(
    nombre: 'Skipping',
    grupo: 'Cardio',
    duracion: Duration(seconds: 40),
    repeticiones: '3 rondas',
    descripcion: 'Simula correr sin despegar los pies del suelo: baja impacto.',
  ),
  EjercicioCatalogo(
    nombre: 'Marcha activa',
    grupo: 'Cardio',
    duracion: Duration(seconds: 120),
    repeticiones: 'Ritmo cómodo',
    descripcion: 'Caminar marcando el paso y moviendo los brazos. Calentamiento real.',
  ),
  EjercicioCatalogo(
    nombre: 'Trote suave',
    grupo: 'Cardio',
    duracion: Duration(seconds: 180),
    repeticiones: 'Ritmo cómodo',
    descripcion: 'Trote que se puede mantener hablando: es la base aeróbica.',
  ),
  EjercicioCatalogo(
    nombre: 'Trote medio',
    grupo: 'Cardio',
    duracion: Duration(seconds: 180),
    repeticiones: 'A ritmo',
    descripcion: 'Ritmo por encima del trote suave, todavía controlado.',
  ),
  EjercicioCatalogo(
    nombre: 'Burpees',
    grupo: 'Cardio',
    duracion: Duration(seconds: 30),
    repeticiones: '10 reps',
    descripcion: 'El ejercicio más exigente del catálogo. Úsalo si ya tienes base.',
  ),

  // ---- Movilidad ----
  EjercicioCatalogo(
    nombre: 'Calentamiento dinámico',
    grupo: 'Movilidad',
    duracion: Duration(seconds: 120),
    repeticiones: 'Suave',
  ),
  EjercicioCatalogo(
    nombre: 'Estiramiento de cuello',
    grupo: 'Movilidad',
    duracion: Duration(seconds: 60),
    repeticiones: '2 rondas',
    esEstiramiento: true,
  ),
  EjercicioCatalogo(
    nombre: 'Círculos de hombros',
    grupo: 'Movilidad',
    duracion: Duration(seconds: 60),
    repeticiones: '2 rondas',
    esEstiramiento: true,
  ),
  EjercicioCatalogo(
    nombre: 'Torsión de tronco',
    grupo: 'Movilidad',
    duracion: Duration(seconds: 60),
    repeticiones: '2 rondas',
    esEstiramiento: true,
  ),
  EjercicioCatalogo(
    nombre: 'Perro boca abajo',
    grupo: 'Movilidad',
    duracion: Duration(seconds: 60),
    repeticiones: 'Mantener',
    esEstiramiento: true,
  ),
  EjercicioCatalogo(
    nombre: 'Gato-vaca',
    grupo: 'Movilidad',
    duracion: Duration(seconds: 60),
    repeticiones: 'Fluido',
    descripcion: 'Acompaña el ritmo de la respiración, sin forzar el rango.',
    esEstiramiento: true,
  ),
  EjercicioCatalogo(
    nombre: 'Estiramiento final',
    grupo: 'Movilidad',
    duracion: Duration(seconds: 60),
    repeticiones: 'Respira',
    esEstiramiento: true,
  ),
];

/// Busca un ejercicio del catálogo por nombre exacto.
EjercicioCatalogo? buscarEjercicio(String nombre) {
  for (final e in catalogoEjercicios) {
    if (e.nombre == nombre) return e;
  }
  return null;
}

/// `true` si el nombre corresponde a un estiramiento del catálogo.
bool esEstiramiento(String nombre) => buscarEjercicio(nombre)?.esEstiramiento ?? false;

/// Filtra el catálogo por grupo y texto libre (nombre o descripción).
List<EjercicioCatalogo> filtrarEjercicios({
  String grupo = '',
  String query = '',
}) {
  final t = query.trim().toLowerCase();
  return catalogoEjercicios.where((e) {
    final coincideGrupo = grupo.trim().isEmpty || e.enGrupo(grupo);
    final coincideTexto = t.isEmpty ||
        e.nombre.toLowerCase().contains(t) ||
        e.descripcion.toLowerCase().contains(t);
    return coincideGrupo && coincideTexto;
  }).toList();
}
