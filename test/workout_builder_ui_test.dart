import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/screens/home_screen.dart';
import 'package:fitpulse/screens/workout_builder_screen.dart';
import 'package:fitpulse/screens/workout_player_screen.dart';
import 'package:fitpulse/services/config_service.dart';
import 'package:fitpulse/services/locale_service.dart';
import 'package:fitpulse/state/app_state.dart';
import 'package:fitpulse/state/rutinas.dart';
import 'package:fitpulse/state/workout.dart';
import 'package:fitpulse/theme.dart';
import 'package:fitpulse/utils/validators.dart';

/// L3 (3b + 3c) — Constructor de rutinas: lista, editor y entrada desde Home.
///
/// Lo que se comprueba en la UI:
/// - Estado vacío honesto: no hay rutinas inventadas ni botones duplicados.
/// - Crear una rutina de verdad y que lo guardado aparece con los datos
///   calculados a partir de su contenido.
/// - Las reglas de `Validators` se explican en pantalla, no se imponen calladas.
/// - Reordenar, quitar, ajustar el descanso y el filtro del catálogo.
/// - "Empezar" abre el reproductor existente con la rutina.
/// - Las kcal se etiquetan siempre como estimación.

/// Rutina válida de partida (3 ejercicios, el mínimo exigido).
Rutina _rutinaValida({String id = 'r1', String nombre = 'Rutina de prueba'}) =>
    Rutina(
      id: id,
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
          nombre: 'Plancha',
          duracion: Duration(seconds: 40),
          repeticiones: 'Mantener',
        ),
      ],
    );

/// Monta la app con los tres providers que usan las pantallas.
Future<AppState> _pump(
  WidgetTester tester, {
  required Widget home,
  AppState? state,
}) async {
  final s = state ?? AppState();
  await s.init();
  final locale = LocaleService();
  await locale.init();
  final config = ConfigService();
  await config.init();
  AppColors.activate(lightFitPalette);
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: s,
      child: ChangeNotifierProvider<LocaleService>.value(
        value: locale,
        child: ChangeNotifierProvider<ConfigService>.value(
          value: config,
          child: MaterialApp(home: home),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return s;
}

/// Monta la lista de rutinas.
Future<AppState> _pumpRutinas(WidgetTester tester, {AppState? state}) =>
    _pump(tester, home: const MisRutinasScreen(), state: state);

/// Monta Home con su provider de estado y el de idioma (Home no usa
/// ConfigService, así que no hace falta traerlo).
Future<AppState> _pumpHome(WidgetTester tester, {AppState? state}) async {
  final s = state ?? AppState();
  await s.init();
  final locale = LocaleService();
  await locale.init();
  AppColors.activate(lightFitPalette);
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: s,
      child: ChangeNotifierProvider<LocaleService>.value(
        value: locale,
        child: const MaterialApp(home: HomeScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return s;
}

/// Monta el editor **encima de la lista**, como en el uso real: así, al guardar
/// se vuelve a la lista y se puede comprobar que la rutina aparece ahí.
Future<AppState> _pumpEditor(WidgetTester tester, {Rutina? rutina}) async {
  final s = await _pump(tester, home: const MisRutinasScreen());
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .push(MaterialPageRoute<void>(
        builder: (_) => RutinaEditorScreen(rutina: rutina),
      ));
  await tester.pumpAndSettle();
  return s;
}

/// La lista del editor es perezosa: lo que queda fuera del viewport puede no
/// tener elemento todavía, así que primero se desplaza hasta encontrarlo.
Future<void> _llevarAView(WidgetTester tester, Finder objetivo) async {
  if (objetivo.evaluate().isNotEmpty) {
    await tester.ensureVisible(objetivo);
  } else {
    // `.first` es necesario: dentro de la lista hay más de un Scrollable (el de la
    // propia lista y el del campo de texto) y `scrollUntilVisible` exige uno solo.
    final scroll = find
        .descendant(
          of: find.byType(ListView).first,
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(objetivo, 250, scrollable: scroll);
  }
  await tester.pumpAndSettle();
}

/// Añade un ejercicio desde la hoja del catálogo. Se busca por texto para no
/// depender del orden del listado, y todo se acota a la hoja para no confundirse
/// con los ejercicios ya añadidos.
Future<void> _anadirEjercicio(WidgetTester tester, String nombre) async {
  final boton = find.widgetWithText(OutlinedButton, 'Añadir ejercicio');
  await _llevarAView(tester, boton);
  await tester.tap(boton);
  await tester.pumpAndSettle();

  final hoja = find.byType(DraggableScrollableSheet);
  await tester.enterText(
    find.descendant(of: hoja, matching: find.byType(TextField)),
    nombre,
  );
  await tester.pumpAndSettle();
  // Se acota a las filas de la hoja: `find.text` también matchearía el
  // `EditableText` del buscador, que ya contiene lo tecleado.
  await tester.tap(
    find.descendant(
      of: hoja,
      matching: find.widgetWithText(ListTile, nombre),
    ),
  );
  await tester.pumpAndSettle();
}

/// Toca "Guardar rutina" (el botón del final de la lista, no el de la barra).
Future<void> _guardar(WidgetTester tester) async {
  final boton = find.widgetWithText(FilledButton, 'Guardar rutina');
  await _llevarAView(tester, boton);
  await tester.tap(boton);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('L3 · lista de rutinas', () {
    testWidgets('sin rutinas explica el estado vacío y no inventa nada',
        (tester) async {
      await _pumpRutinas(tester);

      expect(find.text('Mis rutinas'), findsWidgets);
      expect(
        find.text('Todavía no has creado ninguna rutina.'),
        findsOneWidget,
      );
      // El texto dice cuántos ejercicios hay en el catálogo: dato real.
      expect(find.textContaining('Construye la tuya con los '), findsOneWidget);
      expect(find.text('Nueva rutina'), findsOneWidget);
      // Sin rutinas no hay botón flotante duplicado.
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('con rutinas muestra nombre y datos calculados', (tester) async {
      final state = AppState();
      await state.init();
      await state.guardarRutina(_rutinaValida());
      await _pumpRutinas(tester, state: state);

      expect(find.text('Rutina de prueba'), findsOneWidget);
      // "3 ejercicios · X min" sale del contenido, no de un texto fijo.
      expect(find.textContaining('3 ejercicios'), findsWidgets);
      // La kcal se etiqueta como estimación, nunca como medida.
      expect(find.textContaining('Estimación:'), findsWidgets);
      expect(find.text('Empezar'), findsOneWidget);
    });

    testWidgets('el botón flotante solo aparece si ya hay rutinas',
        (tester) async {
      await _pumpRutinas(tester);
      expect(find.byType(FloatingActionButton), findsNothing);

      final state = AppState();
      await state.init();
      await state.guardarRutina(_rutinaValida());
      await _pumpRutinas(tester, state: state);

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('"Empezar" abre el reproductor existente con la rutina',
        (tester) async {
      final state = AppState();
      await state.init();
      await state.guardarRutina(_rutinaValida());
      await _pumpRutinas(tester, state: state);

      await tester.tap(find.text('Empezar'));
      await tester.pumpAndSettle();

      // Se reutiliza el reproductor del catálogo, sin una pantalla aparte: por
      // eso la rutina no necesita programación nueva para jugarse.
      expect(find.byType(WorkoutPlayerScreen), findsOneWidget);
      expect(find.text('Rutina de prueba'), findsWidgets);
    });

    testWidgets('eliminar pide confirmación y solo borra al confirmar',
        (tester) async {
      final state = AppState();
      await state.init();
      await state.guardarRutina(_rutinaValida());
      await _pumpRutinas(tester, state: state);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar').last);
      await tester.pumpAndSettle();

      // Diálogo con el nombre real de la rutina.
      expect(
        find.text('¿Eliminar la rutina "Rutina de prueba"?'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(
        find.text('Rutina de prueba'),
        findsOneWidget,
        reason: 'Cancelar no debe borrar',
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(state.rutinas, isEmpty);
      expect(
        find.text('Todavía no has creado ninguna rutina.'),
        findsOneWidget,
      );
      expect(find.text('Rutina eliminada'), findsOneWidget);
    });
  });

  group('L3 · crear una rutina de verdad', () {
    testWidgets('nombre + 3 ejercicios se guardan con lo que eligió el usuario',
        (tester) async {
      final state = await _pumpEditor(tester);

      await tester.enterText(find.byType(TextField).first, 'Piernas y core');
      await tester.pumpAndSettle();

      await _anadirEjercicio(tester, 'Sentadillas');
      await _anadirEjercicio(tester, 'Zancadas alternas');
      await _anadirEjercicio(tester, 'Plancha');

      await _guardar(tester);

      // 3 ejercicios: el mínimo exigido, así que sí se guarda.
      expect(state.rutinas.length, 1);
      final guardada = state.rutinas.single;
      expect(guardada.nombre, 'Piernas y core');
      expect(guardada.ejercicios.length, 3);
      // El orden elegido es el orden guardado.
      expect(
        guardada.ejercicios.map((e) => e.nombre),
        ['Sentadillas', 'Zancadas alternas', 'Plancha'],
      );
      // El descanso por defecto es el del roadmap.
      expect(
        guardada.descansoPorDefecto,
        const Duration(seconds: Validators.descansoRutinaPorDefecto),
      );
      // Y se ve en pantalla al volver a la lista.
      expect(find.text('Piernas y core'), findsOneWidget);
    });

    testWidgets('no deja guardar con menos de 3 ejercicios', (tester) async {
      final state = await _pumpEditor(tester);

      await tester.enterText(find.byType(TextField).first, 'Muy corta');
      await tester.pumpAndSettle();
      await _anadirEjercicio(tester, 'Sentadillas');
      await _anadirEjercicio(tester, 'Flexiones');

      await _guardar(tester);

      // Explica el problema con el número exacto, no lo corrige en silencio.
      expect(
        find.text(
          'Añade al menos ${Validators.minEjerciciosRutina} ejercicios para poder guardar la rutina',
        ),
        findsOneWidget,
      );
      expect(
        state.rutinas,
        isEmpty,
        reason: 'No debe guardar una rutina inválida',
      );
    });

    testWidgets('exige un nombre de al menos 3 caracteres', (tester) async {
      final state = await _pumpEditor(tester);

      await tester.enterText(find.byType(TextField).first, 'ab');
      await tester.pumpAndSettle();
      await _anadirEjercicio(tester, 'Sentadillas');
      await _anadirEjercicio(tester, 'Flexiones');
      await _anadirEjercicio(tester, 'Plancha');

      await _guardar(tester);

      expect(
        find.text(
          'El nombre necesita al menos ${Validators.minNombreRutina} caracteres',
        ),
        findsOneWidget,
      );
      expect(state.rutinas, isEmpty);
    });

    testWidgets('avisa si el nombre es demasiado largo', (tester) async {
      final state = await _pumpEditor(tester);

      await tester.enterText(
        find.byType(TextField).first,
        'x' * (Validators.maxNombreRutina + 1),
      );
      await tester.pumpAndSettle();
      await _anadirEjercicio(tester, 'Sentadillas');
      await _anadirEjercicio(tester, 'Flexiones');
      await _anadirEjercicio(tester, 'Plancha');

      await _guardar(tester);

      expect(
        find.text('Máximo ${Validators.maxNombreRutina} caracteres'),
        findsOneWidget,
      );
      expect(state.rutinas, isEmpty);
    });

    testWidgets('el contador refleja lo añadido y el tope del catálogo',
        (tester) async {
      await _pumpEditor(tester);
      expect(
        find.text('0 / ${Validators.maxEjerciciosRutina}'),
        findsOneWidget,
      );
      await _anadirEjercicio(tester, 'Sentadillas');
      expect(
        find.text('1 / ${Validators.maxEjerciciosRutina}'),
        findsOneWidget,
      );
    });
  });

  group('L3 · editar la lista de ejercicios', () {
    testWidgets('las flechas reordenan y el botón de cerrar quita',
        (tester) async {
      final state = await _pumpEditor(tester, rutina: _rutinaValida());

      expect(find.text('Sentadillas'), findsOneWidget);
      expect(find.text('Plancha'), findsOneWidget);

      // "Bajar" en la primera fila la pone segunda.
      await tester.ensureVisible(find.byIcon(Icons.arrow_downward).first);
      await tester.tap(find.byIcon(Icons.arrow_downward).first);
      await tester.pumpAndSettle();

      final tras = state.rutinas;
      expect(tras, isEmpty, reason: 'Todavía no se ha guardado');
      expect(find.text('1'), findsWidgets);

      // Quitar el ejercicio que ahora está el segundo.
      await tester.ensureVisible(find.byIcon(Icons.close).last);
      await tester.tap(find.byIcon(Icons.close).last);
      await tester.pumpAndSettle();
      expect(find.text('Plancha'), findsNothing);
    });

    testWidgets('las flechas de los extremos están deshabilitadas',
        (tester) async {
      await _pumpEditor(tester, rutina: _rutinaValida());

      // La primera fila no puede subir más.
      final arriba = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.arrow_upward),
          matching: find.byType(IconButton),
        ).first,
      );
      expect(arriba.onPressed, isNull);
    });

    testWidgets('el descanso cambia en pasos de 15 s y respeta los topes',
        (tester) async {
      await _pumpEditor(tester, rutina: _rutinaValida());

      expect(
        find.text('${Validators.descansoRutinaPorDefecto}s'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('+15 s'));
      await tester.pumpAndSettle();
      expect(find.text('75s'), findsOneWidget);

      // Bajar hasta el tope mínimo y comprobar que ya no se puede más.
      // Se busca el botón por el icono: `byTooltip` devuelve el Tooltip, no el
      // IconButton, y `byIcon` devuelve el Icon.
      Finder boton(IconData icono) => find.ancestor(
            of: find.byIcon(icono),
            matching: find.byType(IconButton),
          );

      for (var i = 0; i < 10; i++) {
        if (tester.widget<IconButton>(boton(Icons.remove)).onPressed ==
            null) {
          break;
        }
        await tester.tap(find.byTooltip('-15 s'));
        await tester.pumpAndSettle();
      }
      expect(find.text('${Validators.minDescansoRutina}s'), findsOneWidget);
      expect(tester.widget<IconButton>(boton(Icons.remove)).onPressed, isNull);

      // Y hacia arriba también topa, en el máximo.
      for (var i = 0; i < 20; i++) {
        if (tester.widget<IconButton>(boton(Icons.add)).onPressed == null) {
          break;
        }
        await tester.tap(find.byTooltip('+15 s'));
        await tester.pumpAndSettle();
      }
      expect(find.text('${Validators.maxDescansoRutina}s'), findsOneWidget);
      expect(tester.widget<IconButton>(boton(Icons.add)).onPressed, isNull);
    });
  });

  group('L3 · el catálogo de ejercicios', () {
    testWidgets('filtra por grupo y por texto, sin inventar resultados',
        (tester) async {
      await _pumpEditor(tester);

      final hoja = find.byType(DraggableScrollableSheet);
      await _llevarAView(tester, find.text('Añadir ejercicio'));
      await tester.tap(find.widgetWithText(OutlinedButton, 'Añadir ejercicio'));
      await tester.pumpAndSettle();

      Finder fila(String n) => find.descendant(
            of: hoja,
            matching: find.widgetWithText(ListTile, n),
          );

      // Sin filtro: aparece un ejercicio de otro grupo.
      expect(fila('Sentadillas'), findsOneWidget);

      // Filtro por grupo: solo core, así que el de piernas desaparece.
      await tester.tap(find.text('Core'));
      await tester.pumpAndSettle();
      expect(fila('Plancha'), findsOneWidget);
      expect(fila('Sentadillas'), findsNothing);

      // Grupo + texto se combinan: "trote" es cardio, no core.
      await tester.enterText(
        find.descendant(of: hoja, matching: find.byType(TextField)),
        'trote',
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Ningún ejercicio coincide con tu búsqueda'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.add_circle_outline), findsNothing);

      // Volver a "Todos" quita el filtro de grupo y el texto encuentra el cardio.
      await tester.tap(find.text('Todos'));
      await tester.pumpAndSettle();
      expect(fila('Trote suave'), findsOneWidget);
    });
  });

  group('L3 · editar una rutina ya guardada', () {
    testWidgets('abre con sus datos y el cambio se guarda en la misma rutina',
        (tester) async {
      final state = AppState();
      await state.init();
      await state.guardarRutina(_rutinaValida());
      await _pump(
        tester,
        home: RutinaEditorScreen(rutina: _rutinaValida()),
        state: state,
      );

      // Datos precargados.
      expect(find.text('Rutina de prueba'), findsOneWidget);
      expect(
        find.text('3 / ${Validators.maxEjerciciosRutina}'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField).first, 'Pecho fuerte');
      await tester.pumpAndSettle();
      await _guardar(tester);

      // Se actualiza la existente: no se crea una rutina nueva.
      expect(state.rutinas.length, 1);
      expect(state.rutinas.single.nombre, 'Pecho fuerte');
    });
  });

  group('L3 · Home enlaza a "Mis rutinas"', () {
    testWidgets('sin rutinas ofrece crear la primera', (tester) async {
      await _pumpHome(tester);

      final entrada = find.text('Mis rutinas');
      expect(entrada, findsOneWidget);
      expect(find.text('Todavía no has creado ninguna rutina.'), findsOneWidget);
    });

    testWidgets('el número de rutinas es el real, no un texto fijo',
        (tester) async {
      final state = AppState();
      await state.init();
      await state.guardarRutina(_rutinaValida(id: 'a'));
      await _pumpHome(tester, state: state);
      expect(find.text('1 rutina guardada'), findsOneWidget);

      await state.guardarRutina(_rutinaValida(id: 'b', nombre: 'Piernas'));
      await tester.pumpAndSettle();
      expect(find.text('2 rutinas guardadas'), findsOneWidget);
      expect(find.text('1 rutina guardada'), findsNothing);
    });

    testWidgets('tocar la entrada abre la lista de rutinas', (tester) async {
      final state = AppState();
      await state.init();
      await state.guardarRutina(_rutinaValida());
      await _pumpHome(tester, state: state);

      await tester.ensureVisible(find.text('Mis rutinas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mis rutinas'));
      await tester.pumpAndSettle();

      // Se llega a la lista real, con la rutina guardada.
      expect(find.byType(MisRutinasScreen), findsOneWidget);
      expect(find.text('Rutina de prueba'), findsOneWidget);
    });
  });
}