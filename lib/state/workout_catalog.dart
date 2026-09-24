import 'workout.dart';

/// Catálogo reproducible de entrenamientos (Fase 2).
///
/// Los programas son estáticos (diseño del producto); las fechas reales de
/// entrenamiento viven en `AppState.historial`.
const List<WorkoutProgram> workoutCatalog = [
  WorkoutProgram(
    id: 'hiit_quema_total',
    nombre: 'HIIT & Quema Total',
    descripcion:
        'Aumenta tu resistencia aeróbica y tonifica con intervalos explosivos.',
    duracionMin: 45,
    kcalEstimadas: 380,
    intensidad: 'Media',
    ejercicios: [
      WorkoutExercise(nombre: 'Jumping Jacks', duracion: Duration(seconds: 40), repeticiones: '3 rondas'),
      WorkoutExercise(nombre: 'Sentadillas', duracion: Duration(seconds: 40), repeticiones: '12 reps'),
      WorkoutExercise(nombre: 'Burpees', duracion: Duration(seconds: 30), repeticiones: '10 reps'),
      WorkoutExercise(nombre: 'Plancha', duracion: Duration(seconds: 40), repeticiones: 'Mantener'),
      WorkoutExercise(nombre: 'Mountain Climbers', duracion: Duration(seconds: 40), repeticiones: '3 rondas'),
      WorkoutExercise(nombre: 'Zancadas alternas', duracion: Duration(seconds: 40), repeticiones: '10 por pierna'),
      WorkoutExercise(nombre: 'Fondos de tríceps', duracion: Duration(seconds: 30), repeticiones: '12 reps'),
      WorkoutExercise(nombre: 'Abdominales bicicleta', duracion: Duration(seconds: 40), repeticiones: '20 reps'),
      WorkoutExercise(nombre: 'Skipping', duracion: Duration(seconds: 40), repeticiones: '3 rondas'),
      WorkoutExercise(nombre: 'Flexiones', duracion: Duration(seconds: 30), repeticiones: '10 reps'),
      WorkoutExercise(nombre: 'Sentadilla con salto', duracion: Duration(seconds: 30), repeticiones: '10 reps'),
      WorkoutExercise(nombre: 'Estiramiento final', duracion: Duration(seconds: 60), descanso: Duration.zero, repeticiones: 'Respira'),
    ],
  ),
  WorkoutProgram(
    id: 'fuerza_superior_core',
    nombre: 'Fuerza Superior & Core',
    descripcion:
        'Fortalece pecho, espalda, hombros y abdomen con series controladas.',
    duracionMin: 50,
    kcalEstimadas: 320,
    intensidad: 'Alta',
    ejercicios: [
      WorkoutExercise(nombre: 'Flexiones', duracion: Duration(seconds: 40), repeticiones: '12 reps'),
      WorkoutExercise(nombre: 'Plancha lateral', duracion: Duration(seconds: 30), repeticiones: '30 s por lado'),
      WorkoutExercise(nombre: 'Fondos de tríceps', duracion: Duration(seconds: 40), repeticiones: '12 reps'),
      WorkoutExercise(nombre: 'Superman', duracion: Duration(seconds: 30), repeticiones: '10 reps'),
      WorkoutExercise(nombre: 'Remo con toalla', duracion: Duration(seconds: 40), repeticiones: '12 reps'),
      WorkoutExercise(nombre: 'Abdominales crunch', duracion: Duration(seconds: 40), repeticiones: '20 reps'),
      WorkoutExercise(nombre: 'Plancha', duracion: Duration(seconds: 40), repeticiones: 'Mantener'),
      WorkoutExercise(nombre: 'Puente de hombros', duracion: Duration(seconds: 40), repeticiones: '12 reps'),
      WorkoutExercise(nombre: 'Prensa de manos', duracion: Duration(seconds: 30), repeticiones: '10 reps'),
      WorkoutExercise(nombre: 'Estiramiento final', duracion: Duration(seconds: 60), descanso: Duration.zero, repeticiones: 'Respira'),
    ],
  ),
  WorkoutProgram(
    id: 'running_5k_matutino',
    nombre: 'Running 5K Matutino',
    descripcion:
        'Mejora tu capacidad cardiovascular con un plan progresivo de carrera.',
    duracionMin: 28,
    kcalEstimadas: 290,
    intensidad: 'Baja',
    ejercicios: [
      WorkoutExercise(nombre: 'Calentamiento dinámico', duracion: Duration(seconds: 120), repeticiones: 'Suave'),
      WorkoutExercise(nombre: 'Trote suave', duracion: Duration(minutes: 3), descanso: Duration(seconds: 20), repeticiones: 'Ritmo fácil'),
      WorkoutExercise(nombre: 'Marcha activa', duracion: Duration(seconds: 60), descanso: Duration(seconds: 10), repeticiones: 'Recupera'),
      WorkoutExercise(nombre: 'Trote medio', duracion: Duration(minutes: 3), descanso: Duration(seconds: 20), repeticiones: 'Ritmo cómodo'),
      WorkoutExercise(nombre: 'Marcha activa', duracion: Duration(seconds: 60), descanso: Duration(seconds: 10), repeticiones: 'Recupera'),
      WorkoutExercise(nombre: 'Trote medio', duracion: Duration(minutes: 4), descanso: Duration(seconds: 20), repeticiones: 'Ritmo cómodo'),
      WorkoutExercise(nombre: 'Trote suave', duracion: Duration(minutes: 2), descanso: Duration.zero, repeticiones: 'Vuelta a la calma'),
      WorkoutExercise(nombre: 'Estiramiento final', duracion: Duration(seconds: 90), descanso: Duration.zero, repeticiones: 'Respira'),
    ],
  ),
  WorkoutProgram(
    id: 'full_body_flexibilidad',
    nombre: 'Full Body & Flexibilidad',
    descripcion:
        'Movilidad y tono ligero para días de recuperación activa.',
    duracionMin: 30,
    kcalEstimadas: 180,
    intensidad: 'Baja',
    ejercicios: [
      WorkoutExercise(nombre: 'Estiramiento de cuello', duracion: Duration(seconds: 60), repeticiones: '2 rondas'),
      WorkoutExercise(nombre: 'Círculos de hombros', duracion: Duration(seconds: 60), repeticiones: '2 rondas'),
      WorkoutExercise(nombre: 'Torsión de tronco', duracion: Duration(seconds: 60), repeticiones: '2 rondas'),
      WorkoutExercise(nombre: 'Zancada baja estática', duracion: Duration(seconds: 60), repeticiones: '30 s por lado'),
      WorkoutExercise(nombre: 'Perro boca abajo', duracion: Duration(seconds: 60), repeticiones: 'Mantener'),
      WorkoutExercise(nombre: 'Gato-vaca', duracion: Duration(seconds: 60), repeticiones: 'Fluido'),
      WorkoutExercise(nombre: 'Sentadilla profunda', duracion: Duration(seconds: 60), repeticiones: 'Mantener'),
      WorkoutExercise(nombre: 'Estiramiento de isquios', duracion: Duration(seconds: 60), descanso: Duration.zero, repeticiones: '30 s por lado'),
    ],
  ),
];