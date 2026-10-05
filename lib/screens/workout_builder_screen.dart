import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/locale_service.dart';
import '../state/app_state.dart';
import '../state/rutinas.dart';
import '../state/workout.dart';
import '../state/workout_exercise_catalog.dart';
import '../theme.dart';
import '../utils/validators.dart';
import '../widgets/common.dart';
import 'workout_player_screen.dart';

// L3 — Constructor de rutinas propias.
//
// Dos pantallas en este archivo:
// - [MisRutinasScreen]: lista de las rutinas del usuario (con estado vacío
//   honesto: no hay rutinas de ejemplo inventadas).
// - [RutinaEditorScreen]: crear o editar una rutina eligiendo ejercicios del
//   catálogo, ordenarlos y ajustar el descanso.
//
// Al empezar, la rutina se convierte en un [WorkoutProgram] y se abre el
// [WorkoutPlayerScreen] existente: el reproductor no distingue rutinas propias
// de programas del catálogo, así que no se duplica ese código.

// ============================ Mis rutinas ============================

/// Lista de rutinas propias del usuario.
class MisRutinasScreen extends StatelessWidget {
  const MisRutinasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    final state = context.watch<AppState>();
    final rutinas = state.rutinas;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          strings.rutTitulo,
          style: AppType.headlineSm.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: rutinas.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _abrirEditor(context, null),
              icon: const Icon(Icons.add),
              label: Text(strings.rutNueva),
            ),
      body: SafeArea(
        child: rutinas.isEmpty
            ? _VacioRutinas(alCrear: () => _abrirEditor(context, null))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                itemCount: rutinas.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (_, i) => _RutinaCard(rutina: rutinas[i]),
              ),
      ),
    );
  }

  static void _abrirEditor(BuildContext context, Rutina? rutina) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RutinaEditorScreen(rutina: rutina),
      ),
    );
  }
}

/// Estado vacío honesto: explica qué se puede hacer y no finge rutinas.
class _VacioRutinas extends StatelessWidget {
  const _VacioRutinas({required this.alCrear});

  final VoidCallback alCrear;

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_note, size: 56, color: AppColors.outline),
            const SizedBox(height: 16),
            Text(
              strings.rutVacio,
              textAlign: TextAlign.center,
              style: AppType.headlineSm
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              strings.rutVacioDesc(catalogoEjercicios.length),
              textAlign: TextAlign.center,
              style: AppType.bodySm.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: alCrear,
              icon: const Icon(Icons.add),
              label: Text(strings.rutNueva),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de una rutina con **datos reales** calculados de su contenido.
class _RutinaCard extends StatelessWidget {
  const _RutinaCard({required this.rutina});

  final Rutina rutina;

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    final state = context.watch<AppState>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rutina.nombre,
            style: AppType.headlineSm.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            rutina.resumen,
            style: AppType.bodySm.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _Tag(texto: rutina.intensidad),
              _Tag(texto: rutina.duracionEtiqueta),
              // La estimación se etiqueta como estimación, nunca como medida.
              _Tag(texto: '≈${rutina.kcalEstimadas} kcal'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            strings.rutKcalEstimadas(rutina.kcalEstimadas),
            style: AppType.labelSm.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _empezar(context),
                  icon: const Icon(Icons.play_arrow, size: 20),
                  label: Text(strings.rutEmpezar),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                onPressed: () => _editar(context),
                tooltip: strings.rutEditar,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton.outlined(
                onPressed: () => _menu(context, state),
                tooltip: strings.rutEliminar,
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Abre el reproductor existente con la rutina convertida en programa.
  void _empezar(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WorkoutPlayerScreen(program: rutina.aPrograma()),
      ),
    );
  }

  void _editar(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RutinaEditorScreen(rutina: rutina),
      ),
    );
  }

  void _menu(BuildContext context, AppState state) {
    final strings = context.read<LocaleService>().strings;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(strings.rutRenombrar),
              onTap: () {
                Navigator.pop(ctx);
                _editar(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(strings.rutEliminar),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await _confirmar(context, state);
                if (ok == true && context.mounted) {
                  await state.borrarRutina(rutina.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(content: Text(strings.rutEliminada)),
                      );
                  }
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmar(BuildContext context, AppState state) {
    final strings = context.read<LocaleService>().strings;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.rutEliminar),
        content: Text(strings.rutConfirmarEliminar(rutina.nombre)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings.rutCancelar),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.rutEliminar),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta pequeña de la tarjeta.
class _Tag extends StatelessWidget {
  const _Tag({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    if (texto.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        style: AppType.labelSm.copyWith(color: AppColors.onSurfaceVariant),
      ),
    );
  }
}

// ============================ Editor de rutina ============================

/// Crea una rutina nueva o edita una existente.
///
/// La rutina se guarda solo si cumple las reglas de `Validators` (3-12
/// ejercicios, 60 min como maximo, nombre de 3-40 caracteres). Los problemas se
/// explican en pantalla con el texto localizado; no se guarda una rutina
/// imposible ni se corrige en silencio lo que el usuario escribio.
class RutinaEditorScreen extends StatefulWidget {
  const RutinaEditorScreen({super.key, this.rutina});

  /// Rutina a editar. `null` = crear una nueva.
  final Rutina? rutina;

  @override
  State<RutinaEditorScreen> createState() => _RutinaEditorScreenState();
}

class _RutinaEditorScreenState extends State<RutinaEditorScreen> {
  late final TextEditingController _nombre;
  final List<WorkoutExercise> _ejercicios = [];
  late int _descanso;
  String? _error;

  /// Id estable: al editar se conserva; al crear se genera una sola vez.
  late final String _id;

  @override
  void initState() {
    super.initState();
    final r = widget.rutina;
    _id = r?.id ?? 'rutina_${DateTime.now().millisecondsSinceEpoch}';
    _nombre = TextEditingController(text: r?.nombre ?? '');
    _descanso =
        r?.descansoPorDefecto.inSeconds ?? Validators.descansoRutinaPorDefecto;
    if (r != null) _ejercicios.addAll(r.ejercicios);
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  /// Primer problema encontrado, o `null` si la rutina se puede guardar.
  String? get _errorActual {
    final s = context.read<LocaleService>().strings;
    final nombre = _nombre.text.trim();
    if (nombre.length < Validators.minNombreRutina) {
      return s.rutNombreCorto(Validators.minNombreRutina);
    }
    if (nombre.length > Validators.maxNombreRutina) {
      return s.rutNombreLargo(Validators.maxNombreRutina);
    }
    if (_ejercicios.length < Validators.minEjerciciosRutina) {
      return s.rutMinEjercicios(Validators.minEjerciciosRutina);
    }
    if (_ejercicios.length > Validators.maxEjerciciosRutina) {
      return s.rutMaxEjercicios(Validators.maxEjerciciosRutina);
    }
    return Validators.validarDuracionRutina(
      _rutinaActual.duracionMin,
      s.rutDemasiadoLarga(Validators.maxMinutosRutina),
    );
  }

  /// Rutina tal como esta en el editor (sin guardar), para calcular en vivo.
  Rutina get _rutinaActual => Rutina(
        id: _id,
        nombre: _nombre.text.trim(),
        ejercicios: List.of(_ejercicios),
        descansoPorDefecto: Duration(
          seconds: Validators.ajustarDescansoRutina(_descanso),
        ),
        creada: widget.rutina?.creada ?? 0,
      );

  Future<void> _guardar() async {
    final s = context.read<LocaleService>().strings;
    final problema = _errorActual;
    setState(() => _error = problema);
    if (problema != null) return;

    await context.read<AppState>().guardarRutina(_rutinaActual);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(s.rutGuardada)));
  }

  void _anadir(EjercicioCatalogo e) {
    if (_ejercicios.length >= Validators.maxEjerciciosRutina) {
      final s = context.read<LocaleService>().strings;
      setState(() => _error = s.rutMaxEjercicios(Validators.maxEjerciciosRutina));
      return;
    }
    setState(() {
      _ejercicios.add(
        WorkoutExercise(
          nombre: e.nombre,
          duracion: Duration(
            seconds: Validators.ajustarSegundosEjercicio(e.duracion.inSeconds),
          ),
          repeticiones: e.repeticiones,
        ),
      );
      _error = null;
    });
  }

  void _mover(int indice, int delta) {
    final destino = indice + delta;
    if (destino < 0 || destino >= _ejercicios.length) return;
    setState(() {
      final e = _ejercicios.removeAt(indice);
      _ejercicios.insert(destino, e);
    });
  }

  void _quitar(int indice) {
    setState(() {
      _ejercicios.removeAt(indice);
      _error = null;
    });
  }

  Widget _fieldLabel(String texto) => Text(
        texto,
        style: AppType.labelLg.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w700,
        ),
      );

  /// Hoja inferior con el catalogo (filtro por grupo + busqueda por texto).
  void _abrirCatalogo() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CatalogoEjercicios(
        onElegir: (e) {
          Navigator.pop(context);
          _anadir(e);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleService>().strings;
    final r = _rutinaActual;
    final esNueva = widget.rutina == null;
    final vacia = _ejercicios.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          esNueva ? s.rutNueva : s.rutEditar,
          style: AppType.headlineSm.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: _guardar,
            child: Text(
              s.rutGuardar,
              style: AppType.labelLg.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _fieldLabel(s.rutNombre),
            const SizedBox(height: 6),
            TextField(
              controller: _nombre,
              onChanged: (_) => setState(() => _error = null),
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: s.rutNombreHint,
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _DescansoStepper(
              segundos: _descanso,
              onChanged: (v) => setState(() {
                _descanso = v;
                _error = null;
              }),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: _fieldLabel(s.rutEjercicios)),
                const SizedBox(width: 8),
                Text(
                  '${_ejercicios.length} / ${Validators.maxEjerciciosRutina}',
                  style: AppType.labelMd.copyWith(color: AppColors.outline),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              vacia
                  ? s.rutEditorVacio
                  : '${s.rutNEjercicios(_ejercicios.length)} · '
                      '${r.duracionEtiqueta} · ${r.intensidad}',
              style: AppType.labelSm.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            if (vacia)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  s.rutEditorVacio,
                  textAlign: TextAlign.center,
                  style: AppType.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              )
            else
              for (var i = 0; i < _ejercicios.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _EjercicioRow(
                    indice: i,
                    total: _ejercicios.length,
                    ejercicio: _ejercicios[i],
                    onSubir: () => _mover(i, -1),
                    onBajar: () => _mover(i, 1),
                    onQuitar: () => _quitar(i),
                  ),
                ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _abrirCatalogo,
              icon: const Icon(Icons.add),
              label: Text(s.rutAnadir),
            ),
            // Aviso de estimacion: los datos nunca se presentan como medidos.
            if (!vacia) ...[
              const SizedBox(height: 14),
              Text(
                s.rutKcalEstimadas(r.kcalEstimadas),
                style: AppType.labelSm.copyWith(color: AppColors.outline),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.error),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: AppType.bodySm.copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _guardar,
              child: Text(s.rutGuardar),
            ),
          ],
        ),
      ),
    );
  }
}
/// Fila de un ejercicio ya anadido, con reordenar y quitar.
class _EjercicioRow extends StatelessWidget {
  const _EjercicioRow({
    required this.indice,
    required this.total,
    required this.ejercicio,
    required this.onSubir,
    required this.onBajar,
    required this.onQuitar,
  });

  final int indice;
  final int total;
  final WorkoutExercise ejercicio;
  final VoidCallback onSubir;
  final VoidCallback onBajar;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleService>().strings;
    final detalle = ejercicio.repeticiones.isEmpty
        ? '${ejercicio.duracion.inSeconds} s'
        : '${ejercicio.duracion.inSeconds} s · ${ejercicio.repeticiones}';
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary,
            child: Text(
              '${indice + 1}',
              style: AppType.labelSm.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ejercicio.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.bodyMd.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  detalle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.labelSm.copyWith(color: AppColors.outline),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: indice == 0 ? null : onSubir,
            tooltip: s.rutSubir,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.arrow_upward, size: 18),
          ),
          IconButton(
            onPressed: indice == total - 1 ? null : onBajar,
            tooltip: s.rutBajar,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.arrow_downward, size: 18),
          ),
          IconButton(
            onPressed: onQuitar,
            tooltip: s.rutQuitar,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }
}

/// Selector del descanso entre ejercicios, con topes honestos y explicados.
class _DescansoStepper extends StatelessWidget {
  const _DescansoStepper({required this.segundos, required this.onChanged});

  final int segundos;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleService>().strings;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.rutDescansoTitulo,
                  style: AppType.labelLg.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  // El tope se explica, no se impone en silencio.
                  '${Validators.minDescansoRutina}-${Validators.maxDescansoRutina} s',
                  style: AppType.labelSm.copyWith(color: AppColors.outline),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: segundos <= Validators.minDescansoRutina
                ? null
                : () => onChanged(
                      Validators.ajustarDescansoRutina(segundos - 15),
                    ),
            icon: const Icon(Icons.remove),
            tooltip: '-15 s',
          ),
          SizedBox(
            width: 46,
            child: Text(
              '${segundos}s',
              textAlign: TextAlign.center,
              style: AppType.labelLg.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            onPressed: segundos >= Validators.maxDescansoRutina
                ? null
                : () => onChanged(
                      Validators.ajustarDescansoRutina(segundos + 15),
                    ),
            icon: const Icon(Icons.add),
            tooltip: '+15 s',
          ),
        ],
      ),
    );
  }
}

/// Hoja con el catalogo de ejercicios: filtro por grupo y busqueda por texto.
///
/// Un solo origen de verdad (`catalogoEjercicios`): la hoja no mantiene su propia
/// lista, asi que no puede ofrecer ejercicios que el reproductor no conozca.
class _CatalogoEjercicios extends StatefulWidget {
  const _CatalogoEjercicios({required this.onElegir});

  final ValueChanged<EjercicioCatalogo> onElegir;

  @override
  State<_CatalogoEjercicios> createState() => _CatalogoEjerciciosState();
}

class _CatalogoEjerciciosState extends State<_CatalogoEjercicios> {
  String _grupo = '';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleService>().strings;
    final lista = filtrarEjercicios(grupo: _grupo, query: _query);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      builder: (context, controller) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.rutAnadir,
                  style: AppType.headlineSm.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: s.rutBuscar,
                    prefixIcon: Icon(Icons.search, color: AppColors.outline),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CategoryChip(
                          label: s.rutTodosGrupos,
                          selected: _grupo.isEmpty,
                          onTap: () => setState(() => _grupo = ''),
                        ),
                      ),
                      for (final g in gruposEjercicio)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: CategoryChip(
                            label: g.nombre,
                            selected: _grupo == g.nombre,
                            onTap: () => setState(() => _grupo = g.nombre),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: lista.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        s.rutSinResultados,
                        textAlign: TextAlign.center,
                        style: AppType.bodySm.copyWith(color: AppColors.outline),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: lista.length,
                    itemBuilder: (_, i) {
                      final e = lista[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(e.nombre),
                        subtitle: Text(
                          '${e.grupo} · ${e.duracion.inSeconds} s'
                          '${e.repeticiones.isEmpty ? '' : ' · ${e.repeticiones}'}',
                          style: AppType.labelSm.copyWith(color: AppColors.outline),
                        ),
                        trailing: const Icon(Icons.add_circle_outline),
                        onTap: () => widget.onElegir(e),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
