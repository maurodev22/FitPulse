import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/state/app_state.dart';
import 'package:fitpulse/state/pose_coach.dart';
import 'package:fitpulse/state/rutinas.dart';
import 'package:fitpulse/state/workout.dart';
import 'package:fitpulse/state/workout_catalog.dart';
import 'package:fitpulse/state/workout_exercise_catalog.dart';
import 'package:fitpulse/utils/validators.dart';

/// L3 — Constructor de rutinas.
///
/// Lo que se protege aquí:
/// - El catálogo de ejercicios es **uno solo** y cubre los nombres que ya usan
///   los 4 programas fijos, porque el entrenador con cámara (Fase 5) decide el
///   tipo de corrección de postura por el nombre del ejercicio.
/// - La rutina se convierte en un `WorkoutProgram` para reutilizar el
///   reproductor sin tocarlo, y todo valor derivado sale de lo que el usuario
///   eligió (nada inventado, nada en 0 cuando sí hay datos).
/// - Persistencia, borrado, renombrado, backup y borrado total.

/// Rutina de ejemplo: 4 ejercicios reales del catálogo.
Rutina _rutinaDemo({String nombre = 'Pecho y espalda', String? id}) => Rutina(
      id: id ?? 'demo',
      nombre: nombre,
      ejercicios: const [
        WorkoutExercise(
          nombre: 'Sentadillas',
          duracion: Duration(seconds: 40),
          repeticiones: '12 reps',
        ),
        WorkoutExercise(
          nombre: 'Flexiones',
          duracion: Duration(seconds: 40),
          repeticiones: '12 reps',
        ),
        WorkoutExercise(
          nombre: 'Remo con toalla',
          duracion: Duration(seconds: 40),
          repeticiones: '12 reps',
        ),
        WorkoutExercise(
          nombre: 'Plancha',
          duracion: Duration(seconds: 40),
          repeticiones: 'Mantener',
        ),
      ],
    );

void main() {
  group('L3 · catálogo de ejercicios', () {
    test('tiene al menos 25 ejercicios y ningún nombre repetido', () {
      expect(catalogoEjercicios.length, greaterThanOrEqualTo(25));
      final nombres = catalogoEjercicios.map((e) => e.nombre).toList();
      expect(nombres.toSet().length, nombres.length, reason: 'Hay repetidos');
    });

    test('CUBRE todos los ejercicios de los 4 programas fijos', () {
      // Si faltara un nombre, el entrenador con cámara dejaría de reconocerlo
      // y la rutina propia se jugaría sin corrección de postura.
      final nombresCatalogo =
          catalogoEjercicios.map((e) => e.nombre).toSet();
      final usadosPorProgramas = workoutCatalog
          .expand((p) => p.ejercicios)
          .map((e) => e.nombre)
          .toSet();
      final faltan = usadosPorProgramas.difference(nombresCatalogo);
      expect(faltan, isEmpty, reason: 'Ejercicios fuera del catálogo: $faltan');
    });

    test('cada ejercicio del catálogo es reconocible por el entrenador', () {
      // No basta con que el nombre exista: debe caer en un tipo de corrección
      // real. `libre` es el valor por defecto (aceptable), pero si TODO el
      // catálogo fuera `libre`, la cámara no posturalía nada.
      final tipos = catalogoEjercicios
          .map((e) => tipoDeEjercicio(e.nombre))
          .toSet();
      expect(tipos.length, greaterThan(1),
          reason: 'Todo cae en el mismo tipo de corrección');
      expect(tipos.contains(TipoPostura.libre), isTrue);
    });

    test('todo ejercicio tiene grupo válido, tiempo y repeticiones', () {
      final gruposValidos = gruposEjercicio.map((g) => g.nombre).toSet();
      for (final e in catalogoEjercicios) {
        expect(gruposValidos, contains(e.grupo), reason: e.nombre);
        expect(e.duracion.inSeconds, greaterThan(0), reason: e.nombre);
        expect(e.duracion.inSeconds, lessThanOrEqualTo(600), reason: e.nombre);
        expect(e.repeticiones.trim(), isNotEmpty, reason: e.nombre);
      }
    });

    test('cada grupo tiene al menos un ejercicio (ningún filtro vacío)', () {
      for (final g in gruposEjercicio) {
        final delGrupo = filtrarEjercicios(grupo: g.nombre);
        expect(delGrupo, isNotEmpty, reason: 'Grupo "${g.nombre}" vacío');
      }
    });

    test('el filtro por grupo y texto libre se combina', () {
      final cardio = filtrarEjercicios(grupo: 'Cardio');
      expect(cardio.length, greaterThan(1));
      for (final e in cardio) {
        expect(e.enGrupo('Cardio'), isTrue);
      }
      // Texto que no existe -> lista vacía, nunca un "resultado inventado".
      expect(filtrarEjercicios(query: 'zzzz'), isEmpty);
      // Búsqueda por descripción también funciona.
      final porTexto = filtrarEjercicios(query: 'toalla');
      expect(porTexto.any((e) => e.nombre.contains('toalla')), isTrue);
    });

    test('el filtro de grupo no distingue mayúsculas ni espacios', () {
      expect(filtrarEjercicios(grupo: '  cardio ').length,
          filtrarEjercicios(grupo: 'Cardio').length);
    });

    test('buscarEjercicio distingue encontrado y no encontrado', () {
      expect(buscarEjercicio('Sentadillas')?.grupo, 'Piernas');
      expect(buscarEjercicio('Ejercicio inventado'), isNull);
      expect(esEstiramiento('Sentadilla profunda'), isTrue);
      expect(esEstiramiento('Sentadillas'), isFalse);
      // Un nombre desconocido NO se marca como estiramiento: no sabemos.
      expect(esEstiramiento('Movimiento raro'), isFalse);
    });
  });

  group('L3 · la rutina calcula sobre lo que eligió el usuario', () {
    test('minutos de trabajo = suma de los ejercicios', () {
      final r = _rutinaDemo();
      // 4 x 40 s = 160 s -> 3 min (redondeo hacia arriba).
      expect(r.minutosTrabajo, 3);
      // Descanso por defecto 60 s entre 4 ejercicios = 240 s -> 4 min.
      expect(r.minutosDescanso, 4);
      expect(r.duracionMin, 7);
    });

    test('los estiramientos NO cuentan descanso (son el final)', () {
      final r = Rutina(
        id: 'x',
        nombre: 'Estiramientos',
        ejercicios: const [
          WorkoutExercise(
            nombre: 'Plancha',
            duracion: Duration(seconds: 60),
          ),
          WorkoutExercise(
            nombre: 'Sentadilla profunda',
            duracion: Duration(seconds: 60),
          ),
          WorkoutExercise(
            nombre: 'Gato-vaca',
            duracion: Duration(seconds: 60),
          ),
        ],
      );
      expect(r.minutosTrabajo, 3);
      // Solo la plancha (no es estiramiento) genera descanso: 60 s -> 1 min.
      expect(r.minutosDescanso, 1);
    });

    test('una rutina VACÍA da 0 en todo, no valores inventados', () {
      const r = Rutina(id: 'v', nombre: 'Vacía', ejercicios: []);
      expect(r.vacia, isTrue);
      expect(r.minutosTrabajo, 0);
      expect(r.minutosDescanso, 0);
      expect(r.duracionMin, 0);
      expect(r.duracionEtiqueta, '0 min');
      expect(r.kcalEstimadas, 0);
    });

    test('la intensidad se DERIVA del contenido, no se escribe', () {
      final cardio = Rutina(
        id: 'c',
        nombre: 'Cardio',
        ejercicios: const [
          WorkoutExercise(
            nombre: 'Trote medio',
            duracion: Duration(seconds: 60),
          ),
          WorkoutExercise(
            nombre: 'Burpees',
            duracion: Duration(seconds: 60),
          ),
          WorkoutExercise(
            nombre: 'Skipping',
            duracion: Duration(seconds: 60),
          ),
        ],
      );
      expect(cardio.intensidad, 'Alta');

      final movilidad = Rutina(
        id: 'm',
        nombre: 'Movilidad',
        ejercicios: const [
          WorkoutExercise(
            nombre: 'Gato-vaca',
            duracion: Duration(seconds: 60),
          ),
          WorkoutExercise(
            nombre: 'Perro boca abajo',
            duracion: Duration(seconds: 60),
          ),
          WorkoutExercise(
            nombre: 'Círculos de hombros',
            duracion: Duration(seconds: 60),
          ),
        ],
      );
      expect(movilidad.intensidad, 'Baja');
    });

    test('un ejercicio desconocido NO infla la estimación', () {
      // El nombre que no está en el catálogo cae al valor más bajo: si no
      // reconocemos el ejercicio, subestimamos en lugar de exagerar.
      final raro = const Rutina(
        id: 'r',
        nombre: 'Raro',
        ejercicios: [
          WorkoutExercise(
            nombre: 'Movimiento no catalogado',
            duracion: Duration(seconds: 60),
          ),
        ],
      );
      final cardio = const Rutina(
        id: 'c',
        nombre: 'Cardio',
        ejercicios: [
          WorkoutExercise(
            nombre: 'Burpees',
            duracion: Duration(seconds: 60),
          ),
        ],
      );
      expect(raro.intensidad, 'Baja');
      expect(raro.kcalEstimadas, lessThan(cardio.kcalEstimadas));
    });

    test('la etiqueta de duración coincide siempre con los minutos reales', () {
      // 12 x 300 s de trabajo = 60 min, más el descanso de los que no son
      // estiramiento: la etiqueta tiene que reflejar esa suma, no solo el
      // trabajo.
      final larga = Rutina(
        id: 'x',
        nombre: 'Larga',
        ejercicios: List.generate(
          12,
          (i) => WorkoutExercise(
            nombre: catalogoEjercicios[i].nombre,
            duracion: Duration(seconds: 300),
          ),
        ),
      );
      expect(larga.minutosTrabajo, 60);
      expect(larga.duracionMin, larga.minutosTrabajo + larga.minutosDescanso);
      // Como ya pasa de 60 min, se etiqueta en horas.
      expect(larga.duracionEtiqueta, startsWith('1 h'));
      // Y una rutina corta se expresa en minutos.
      expect(_rutinaDemo().duracionEtiqueta, '7 min');
    });

    test('resumen describe la rutina con datos reales', () {
      final r = _rutinaDemo();
      expect(r.resumen, contains('4 ejercicios'));
      expect(r.resumen, contains('7 min'));
    });
  });

  group('L3 · se convierte en WorkoutProgram (reproductor sin cambios)', () {
    test('aPrograma() conserva los ejercicios y pasa los datos al player', () {
      final r = _rutinaDemo();
      final p = r.aPrograma();
      expect(p.id, 'demo');
      expect(p.nombre, 'Pecho y espalda');
      expect(p.ejercicios.length, 4);
      expect(p.ejercicios.first.nombre, 'Sentadillas');
      expect(p.duracionMin, r.duracionMin);
      expect(p.kcalEstimadas, r.kcalEstimadas);
      expect(p.intensidad, r.intensidad);
      expect(p.descripcion, isNotEmpty);
    });

    test('el programa resultante NO tiene ejercicios vacíos', () {
      // El reproductor arranca en `program.ejercicios.first`: un programa sin
      // ejercicios lo rompería.
      final p = _rutinaDemo().aPrograma();
      expect(p.ejercicios, isNotEmpty);
      for (final e in p.ejercicios) {
        expect(e.duracion.inSeconds, greaterThan(0), reason: e.nombre);
      }
    });

    test('una rutina propia tiene el mismo aspecto que un programa fijo', () {
      // Misma clase que los del catálogo: es lo que permite reutilizar la
      // pantalla sin duplicar código.
      expect(_rutinaDemo().aPrograma(), isA<WorkoutProgram>());
      expect(workoutCatalog.first, isA<WorkoutProgram>());
    });
  });

  group('L3 · JSON tolerante a datos malos', () {
    test('ida y vuelta conserva nombre, descanso y ejercicios', () {
      final r = _rutinaDemo();
      final vuelta = Rutina.fromJson(r.toJson());
      expect(vuelta.nombre, r.nombre);
      expect(vuelta.descansoPorDefecto, r.descansoPorDefecto);
      expect(vuelta.ejercicios.length, r.ejercicios.length);
      expect(vuelta.ejercicios[1].nombre, 'Flexiones');
      expect(vuelta.ejercicios[1].duracion, const Duration(seconds: 40));
      expect(vuelta.ejercicios[1].repeticiones, '12 reps');
    });

    test('un ejercicio sin nombre o sin tiempo se descarta', () {
      final r = Rutina.fromJson({
        'id': 'x',
        'n': 'Mixta',
        'e': [
          {'n': 'Sentadillas', 's': 40},
          {'n': '', 's': 40},
          {'n': 'Flexiones', 's': 0},
          'basura',
          {'s': 40},
        ],
      });
      expect(r.ejercicios.length, 1);
      expect(r.ejercicios.first.nombre, 'Sentadillas');
    });

    test('un JSON vacío o raro NO lanza: devuelve una rutina vacía usable', () {
      final r = Rutina.fromJson({'e': 'no es una lista'});
      expect(r.vacia, isTrue);
      expect(r.nombre, isNotEmpty);
      expect(r.ejercicios, isEmpty);
    });

    test('sin nombre o sin id no se rompe (valores por defecto honestos)', () {
      final sinNombre = Rutina.fromJson({'e': [
        {'n': 'Plancha', 's': 30},
      ]});
      expect(sinNombre.nombre, isNotEmpty);
      expect(sinNombre.id, isNotEmpty);
    });

    test('un descanso de 0 s en el JSON cae al valor por defecto (60 s)', () {
      final r = Rutina.fromJson({
        'id': 'x',
        'n': 'Y',
        'd': 0,
        'e': [
          {'n': 'Plancha', 's': 30},
        ],
      });
      expect(r.descansoPorDefecto, const Duration(seconds: 60));
    });
  });

  group('L3 · reglas de Validators', () {
    test('los topes de ejercicios son 3-12', () {
      expect(Validators.minEjerciciosRutina, 3);
      expect(Validators.maxEjerciciosRutina, 12);
    });

    test('el descanso se ajusta a 15-120 s', () {
      expect(Validators.ajustarDescansoRutina(5), 15);
      expect(Validators.ajustarDescansoRutina(60), 60);
      expect(Validators.ajustarDescansoRutina(999), 120);
    });

    test('el tiempo de ejercicio se ajusta a 10-180 s', () {
      expect(Validators.ajustarSegundosEjercicio(0), 10);
      expect(Validators.ajustarSegundosEjercicio(45), 45);
      expect(Validators.ajustarSegundosEjercicio(6000), 180);
    });

    test('una rutina de más de 60 min se avisa', () {
      expect(Validators.validarDuracionRutina(45, 'demasiado larga'), isNull);
      expect(
        Validators.validarDuracionRutina(75, 'demasiado larga'),
        'demasiado larga',
      );
    });
  });

  group('L3 · persistencia en AppState', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('sin nada guardado no hay rutinas', () async {
      final state = AppState();
      await state.init();
      expect(state.rutinas, isEmpty);
    });

    test('guarda, sobrevive al reinicio y se recupera por id', () async {
      final state = AppState();
      await state.init();
      await state.guardarRutina(_rutinaDemo());

      final otro = AppState();
      await otro.init();
      expect(otro.rutinas.length, 1);
      expect(otro.rutinas.first.nombre, 'Pecho y espalda');
      expect(otro.rutinas.first.ejercicios.length, 4);
      expect(otro.rutinaPorId('demo'), isNotNull);
      expect(otro.rutinaPorId('no-existe'), isNull);
    });

    test('guardar la misma id actualiza en vez de duplicar', () async {
      final state = AppState();
      await state.init();
      await state.guardarRutina(_rutinaDemo());
      await state.guardarRutina(
        _rutinaDemo(nombre: 'Pecho y espalda v2'),
      );
      expect(state.rutinas.length, 1);
      expect(state.rutinas.first.nombre, 'Pecho y espalda v2');
    });

    test('guarda varias rutinas separadas', () async {
      final state = AppState();
      await state.init();
      await state.guardarRutina(_rutinaDemo(id: 'a'));
      await state.guardarRutina(_rutinaDemo(id: 'b', nombre: 'Piernas'));
      await state.guardarRutina(_rutinaDemo(id: 'c', nombre: 'Core'));
      final otro = AppState();
      await otro.init();
      expect(otro.rutinas.length, 3);
      expect(otro.rutinas.map((r) => r.id), containsAll(['a', 'b', 'c']));
    });

    test('una rutina sin ejercicios NO se guarda', () async {
      final state = AppState();
      await state.init();
      await state.guardarRutina(
        const Rutina(id: 'vacia', nombre: 'Vacía', ejercicios: []),
      );
      expect(state.rutinas, isEmpty);
    });

    test('el descanso imposible se ajusta al guardar', () async {
      final state = AppState();
      await state.init();
      await state.guardarRutina(
        Rutina(
          id: 'd',
          nombre: 'Descanso raro',
          descansoPorDefecto: const Duration(seconds: 2),
          ejercicios: _rutinaDemo().ejercicios,
        ),
      );
      expect(state.rutinas.first.descansoPorDefecto,
          const Duration(seconds: Validators.minDescansoRutina));
    });

    test('un tiempo de ejercicio imposible se ajusta al guardar', () async {
      final state = AppState();
      await state.init();
      await state.guardarRutina(
        const Rutina(
          id: 'lenta',
          nombre: 'Ejercicio lento',
          ejercicios: [
            WorkoutExercise(
              nombre: 'Plancha',
              duracion: Duration(hours: 2),
            ),
          ],
        ),
      );
      expect(
        state.rutinas.first.ejercicios.first.duracion.inSeconds,
        Validators.maxSegundosEjercicio,
      );
    });

    test('borrar quita la rutina y devuelve si hizo algo', () async {
      final state = AppState();
      await state.init();
      await state.guardarRutina(_rutinaDemo(id: 'a'));
      expect(await state.borrarRutina('a'), isTrue);
      expect(state.rutinas, isEmpty);
      // Segunda vez ya no hay nada que borrar.
      expect(await state.borrarRutina('a'), isFalse);
    });

    test('renombrar cambia el nombre y persiste', () async {
      final state = AppState();
      await state.init();
      await state.guardarRutina(_rutinaDemo());
      expect(await state.renombrarRutina('demo', '  Pecho fuerte  '), isTrue);
      expect(state.rutinas.first.nombre, 'Pecho fuerte');
      final otro = AppState();
      await otro.init();
      expect(otro.rutinas.first.nombre, 'Pecho fuerte');
    });

    test('renombrar con nombre vacío o id inexistente NO cambia nada', () async {
      final state = AppState();
      await state.init();
      await state.guardarRutina(_rutinaDemo());
      expect(await state.renombrarRutina('demo', '   '), isFalse);
      expect(await state.renombrarRutina('no-existe', 'Otro'), isFalse);
      expect(state.rutinas.first.nombre, 'Pecho y espalda');
    });

    test('un dato corrupto no impide abrir la app', () async {
      SharedPreferences.setMockInitialValues({
        'fitpulse_rutinas_v1': 'esto no es json {{{',
      });
      final state = AppState();
      await state.init();
      expect(state.rutinas, isEmpty);
    });

    test('las rutinas viajan en el backup y vuelven al importar', () async {
      final state = AppState();
      await state.init();
      await state.guardarRutina(_rutinaDemo(id: 'a'));
      await state.guardarRutina(_rutinaDemo(id: 'b', nombre: 'Piernas y Core'));

      final snapshot = state.snapshotParaBackup();
      expect(snapshot.containsKey('rutinas'), isTrue);

      // Otro dispositivo: sin rutinas en el store antes de importar.
      await state.borrarRutina('a');
      await state.borrarRutina('b');
      expect(state.rutinas, isEmpty);

      await state.aplicarBackup(snapshot);

      expect(state.rutinas.length, 2);
      final a = state.rutinaPorId('a')!;
      expect(a.nombre, 'Pecho y espalda');
      expect(a.ejercicios.length, 4);
      expect(a.descansoPorDefecto, const Duration(seconds: 60));
      // Y siguen ahí tras reiniciar.
      final trasReinicio = AppState();
      await trasReinicio.init();
      expect(trasReinicio.rutinas.length, 2);
    });

    test('un backup antiguo (sin rutinas) conserva las del dispositivo', () async {
      final state = AppState();
      await state.init();
      await state.guardarRutina(_rutinaDemo());

      // Backup viejo: sin la clave 'rutinas'.
      final snapshot = state.snapshotParaBackup()..remove('rutinas');
      await state.aplicarBackup(snapshot);
      expect(state.rutinas.length, 1,
          reason: 'Un backup antiguo no debe borrar rutinas');
    });

    test('un backup con rutinasManipuladas no rompe el estado', () async {
      final state = AppState();
      await state.init();
      await state.aplicarBackup({
        'rutinas': [
          'basura',
          {'n': 'Sin ejercicios', 'e': []},
          {
            'id': 'ok',
            'n': 'Válida',
            'd': 60,
            'e': [
              {'n': 'Sentadillas', 's': 40},
            ],
          },
        ],
      });
      expect(state.rutinas.length, 1);
      expect(state.rutinas.first.nombre, 'Válida');
    });

    test('tras un borrado total no quedan rutinas', () async {
      final state = AppState();
      await state.init();
      await state.guardarRutina(_rutinaDemo());
      state.resetTrasBorrado();
      expect(state.rutinas, isEmpty);
    });
  });
}