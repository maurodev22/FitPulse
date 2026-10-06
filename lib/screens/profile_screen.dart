import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'dart:convert';

import '../services/config_service.dart';
import '../services/locale_service.dart';
import '../state/app_state.dart';
import '../state/athlete_profile.dart';
import '../state/insignias.dart';
import '../theme.dart';
import '../utils/foto_avatar.dart';
import '../utils/validators.dart';
import '../widgets/common.dart';
import '../widgets/estado_salud_card.dart';
import '../widgets/racha_chip.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/wheel_number_picker.dart';
import 'configuracion_screen.dart';

/// Perfil y Ajustes: muestra y edita los datos del atleta de la sesión.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late AthleteProfile _profile;
  late Set<String> _trainingDays;
  late String _fitnessLevel;

  @override
  void initState() {
    super.initState();
    // Copia local editable de la sesión persistida.
    _loadFromState();
  }

  void _loadFromState() {
    _profile = context.read<AppState>().profile;
    _trainingDays = _profile.diasEntrenamiento.toSet();
    _fitnessLevel = _profile.nivel;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _ProfileHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHero(profile: context.watch<AppState>().profile),
                  const SizedBox(height: 16),
                  const EstadoSaludCard(compact: true),
                  const SizedBox(height: 16),
                  _buildMetasActividad(),
                  const SizedBox(height: 16),
                  _buildInsignias(),
                  const SizedBox(height: 16),
                  _buildPremium(),
                  const SizedBox(height: 16),
                  _buildNivelPreferencias(),
                  const SizedBox(height: 20),
                  _buildAcciones(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tarjeta de anuncios.
///
/// Ya NO hay botón de "Activar Premium de prueba": la fase final está cerca y
/// un interruptor que regala lo de pago es exactamente lo que no debe verse en
/// una app que se va a publicar. Premium se comprará cuando exista el pago real.
/// El interruptor de anuncios se queda porque ese sí es un consentimiento
/// real del usuario y tiene que poder apagarse.
Widget _buildPremium() {
    final config = context.watch<ConfigService>();
    final strings = context.watch<LocaleService>().strings;
    return SettingsCard(
      children: [
        SettingsCardTitle(
          icon: Icons.campaign_outlined,
          title: strings.pfAnunciosHabilitados,
        ),
        const SizedBox(height: 8),
        // Consentimiento local de anuncios (Fase 3): el usuario puede apagarlos.
        ToggleRow(
          icon: Icons.campaign_outlined,
          title: strings.pfAnunciosHabilitados,
          subtitle: strings.pfAnunciosSub,
          value: config.adsEnabled,
          onChanged: (v) => config.setAds(v),
        ),
      ],
    );
  }

  Widget _buildMetasActividad() {
    final strings = context.watch<LocaleService>().strings;
    return SettingsCard(
      children: [
        SettingsCardTitle(
          icon: Icons.track_changes,
          title: strings.pfMetasActividad,
          action: IconActionButton(icon: Icons.edit, onTap: _editarMetas),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.directions_walk, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      strings.pfPasosDiarios,
                      style: AppType.labelMd.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                  Text(
                    _groupThousands(_profile.pasosMeta),
                    style: AppType.headlineSm.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const _PasosProgresoHoy(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.water_drop_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  strings.pfMetaAguaDiaria,
                  style: AppType.labelMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ),
              Builder(builder: (context) {
                final litros = context.watch<AppState>().metaAguaDiaria;
                return Text(
                  '${litros.toStringAsFixed(1)} L',
                  style: AppType.headlineSm.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }),
              IconButton(
                onPressed: _editarMetaAgua,
                icon: const Icon(Icons.edit, size: 18),
                color: AppColors.primary,
                visualDensity: VisualDensity.compact,
                tooltip: strings.pfMetaAguaTitulo,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Builder(builder: (context) {
                final gasto = context.watch<AppState>().gastoActivoHoy;
                return _MiniStat(
                  icon: Icons.local_fire_department,
                  iconColor: AppColors.error,
                  iconBackground: AppColors.errorContainer,
                  label: strings.pfCaloriasActivas,
                  value: gasto?.toStringAsFixed(0) ?? '—',
                  unit: 'kcal',
                );
              }),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Builder(builder: (context) {
                final minutos = context.watch<AppState>().minutosEntrenadosSemana;
                return _MiniStat(
                  icon: Icons.favorite,
                  iconColor: AppColors.outline,
                  iconBackground: AppColors.surfaceContainer,
                  label: strings.pfCardioSemanal,
                  value: minutos > 0 ? '$minutos' : '—',
                  unit: 'min',
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                strings.pfDiasEntrenamiento,
                style: AppType.labelMd.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
            Flexible(
              child: Text(
                strings.pfDiasSemana(_trainingDays.length),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.labelMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['L', 'M', 'X', 'J', 'V', 'S', 'D'].map((d) {
            final active = _trainingDays.contains(d);
            return GestureDetector(
              onTap: () {
                // Mínimo 2 días de entrenamiento obligatorios (plan de la
                // sesión): no se puede deseleccionar el penúltimo.
                if (active && _trainingDays.length <= 2) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(content: Text(strings.pfMinimoDias)),
                    );
                  return;
                }
                setState(() {
                  if (active) {
                    _trainingDays.remove(d);
                  } else {
                    _trainingDays.add(d);
                  }
                });
              },
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.surfaceContainer,
                  shape: BoxShape.circle,
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  // El valor sigue siendo la inicial en español; solo se
                  // traduce la letra pintada.
                  strings.diaInicial(d),
                  style: AppType.labelMd.copyWith(
                    color: active ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNivelPreferencias() {
    final strings = context.watch<LocaleService>().strings;
    return SettingsCard(
      children: [
        SettingsCardTitle(
          icon: Icons.fitness_center,
          title: strings.pfNivelPreferencias,
        ),
        const SizedBox(height: 12),
        Text(
          strings.pfNivelCondicion,
          style: AppType.labelMd.copyWith(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: ['Principiante', 'Intermedio', 'Avanzado'].map((level) {
              final selected = level == _fitnessLevel;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _fitnessLevel = level),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      // Se guarda/selecciona el valor en español; solo se
                      // traduce la etiqueta pintada.
                      strings.nivelName(level),
                      style: AppType.labelMd.copyWith(
                        color: selected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          strings.pfTipoEntrenamiento,
          style: AppType.labelMd.copyWith(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PreferenceTag(icon: Icons.bolt, label: strings.favoritoName('HIIT')),
            _PreferenceTag(
              icon: Icons.fitness_center,
              label: strings.favoritoName('Fuerza funcional'),
            ),
            _PreferenceTag(
              icon: Icons.directions_run,
              label: strings.favoritoName('Running'),
            ),
            _AddPreferenceTag(onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(strings.pfSeleccionaFavorito)),
              );
            }),
          ],
        ),
      ],
    );
  }

  /// FASE C (gamificación): insignias y logros del atleta.
  ///
  /// Catálogo completo y siempre visible, con dos estados:
  ///  * conseguida → icono a color + fecha REAL de desbloqueo (derivada del
  ///    propio historial, nunca inventada);
  ///  * bloqueada → silueta gris con candado y la condición escrita, sin
  ///    contadores de progreso ("te faltan 2 para…") para no generar presión.
  ///
  /// Cada insignia se otorga SOLO con su condición real verificada sobre datos
  /// ya persistidos (`evaluarInsignias`); si la fecha no se puede derivar no
  /// se muestra.
  Widget _buildInsignias() {
    final state = context.watch<AppState>();
    final strings = context.watch<LocaleService>().strings;
    final resultados = evaluarInsignias(state.datosInsignias);
    final conseguidas = resultados.where((r) => r.conseguida).length;
    // F1: la insignia bloqueada más cercana en orden de catálogo es el
    // "teaser" pasivo (su condición se realza; sin barra de progreso).
    final siguiente = resultados.indexWhere((r) => !r.conseguida);
    final localizador = MaterialLocalizations.of(context);

    return SettingsCard(
      children: [
        SettingsCardTitle(
          icon: Icons.emoji_events_outlined,
          title: strings.prInsignias,
        ),
        // C3: contador del catálogo. Va en su propia fila (no como `action`
        // del título) para que a escala de texto 2.0× no desborde el Row de
        // la cabecera.
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            strings.prInsigniasContador(conseguidas, resultados.length),
            style: AppType.labelSm.copyWith(color: AppColors.outline),
          ),
        ),
        const SizedBox(height: 12),
        if (conseguidas == 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              strings.prDesbloqueaInsignias,
              textAlign: TextAlign.center,
              style: AppType.bodySm.copyWith(color: AppColors.outline),
            ),
          ),
        if (conseguidas == 0) const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < resultados.length; i++)
              _insigniaTile(
                strings,
                localizador,
                resultados[i],
                esSiguiente: i == siguiente,
              ),
          ],
        ),
      ],
    );
  }

  /// Icono, nombre y condición de cada insignia del catálogo (Fase C).
  ({IconData icono, String nombre, String condicion}) _infoInsignia(
    AppStrings strings,
    InsigniaId id,
  ) {
    return switch (id) {
      InsigniaId.primeraSesion => (
          icono: Icons.fitness_center,
          nombre: strings.prInsPrimerPaso,
          condicion: strings.prInsCondPrimerPaso,
        ),
      InsigniaId.constancia => (
          icono: Icons.local_fire_department,
          nombre: strings.prInsConstancia,
          condicion: strings.prInsCondRacha3,
        ),
      InsigniaId.disciplina => (
          icono: Icons.whatshot,
          nombre: strings.prInsDisciplina,
          condicion: strings.prInsCondRacha7,
        ),
      InsigniaId.hierro => (
          icono: Icons.sports_martial_arts,
          nombre: strings.prInsHierro,
          condicion: strings.prInsCondHierro,
        ),
      InsigniaId.veterano => (
          icono: Icons.military_tech,
          nombre: strings.prInsVeterano,
          condicion: strings.prInsCondVeterano,
        ),
      InsigniaId.marcaPersonal => (
          icono: Icons.monitor_weight_outlined,
          nombre: strings.prInsMarcaPersonal,
          condicion: strings.prInsCondMarcaPersonal,
        ),
      InsigniaId.tecnico => (
          icono: Icons.repeat,
          nombre: strings.prInsTecnico,
          condicion: strings.prInsCondTecnico,
        ),
      InsigniaId.hidratado => (
          icono: Icons.water_drop_outlined,
          nombre: strings.prInsHidratado,
          condicion: strings.prInsCondHidratado,
        ),
      InsigniaId.primerReto => (
          icono: Icons.emoji_events,
          nombre: strings.prInsPrimerReto,
          condicion: strings.prInsCondPrimerReto,
        ),
    };
  }

  /// Tarjeta de una insignia: conseguida (icono a color + fecha real) o
  /// bloqueada (silueta gris con candado y condición).
  ///
  /// [esSiguiente] marca (F1, teaser) la insignia bloqueada más cercana en
  /// orden de catálogo: borde sutil y su condición en primario. Sigue siendo
  /// pasiva — sin barra de progreso numérica (evita presión).
  Widget _insigniaTile(
    AppStrings strings,
    MaterialLocalizations localizador,
    InsigniaResultado r, {
    required bool esSiguiente,
  }) {
    final info = _infoInsignia(strings, r.id);
    final techo = r.conseguida && r.fecha != null
        ? localizador.formatCompactDate(r.fecha!)
        : info.condicion;

    return Container(
      key: esSiguiente ? const Key('insignia_siguiente') : null,
      width: 105,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        // F1: teaser de la próxima insignia — borde sutil y pasivo.
        border: esSiguiente
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.45))
            : null,
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                info.icono,
                size: 22,
                color: r.conseguida
                    ? AppColors.primary
                    : AppColors.outlineVariant,
              ),
              if (!r.conseguida)
                Positioned(
                  right: -8,
                  bottom: -8,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock, size: 10, color: AppColors.outline),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            info.nombre,
            style: AppType.labelMd.copyWith(
              color: r.conseguida
                  ? AppColors.onSurface
                  : esSiguiente
                      ? AppColors.onSurface
                      : AppColors.outline,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            techo,
            style: AppType.labelSm.copyWith(
              color: r.conseguida
                  ? AppColors.primary
                  : esSiguiente
                      ? AppColors.primary
                      : AppColors.outline,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Persiste la sesión editada con los cambios locales del formulario.
  void _guardarCambios() {
    final actual = context.read<AppState>().profile;
    context.read<AppState>().guardarPerfil(
      actual.copyWith(
        nivel: _fitnessLevel,
        diasEntrenamiento: _trainingDays.toList(),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.read<LocaleService>().strings.pfAjustesGuardados)),
    );
  }

  /// L2: edita la meta diaria de agua con la rueda (0,5–10 L, paso 0,5 L).
  /// La meta es del usuario, pero `Validators` impide que sea imposible.
  Future<void> _editarMetaAgua() async {
    final strings = context.read<LocaleService>().strings;
    final state = context.read<AppState>();
    var valor = state.metaAguaDiaria;
    final guardado = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogo) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(strings.pfMetaAguaTitulo),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                strings.pfMetaAguaDesc,
                style:
                    AppType.bodySm.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              WheelNumberPicker(
                min: Validators.minMetaAguaLitros,
                max: Validators.maxMetaAguaLitros,
                step: 0.5,
                decimals: 1,
                semanticsUnit: 'L',
                initialValue: valor,
                onChanged: (v) => setDialogo(() => valor = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(strings.pfCancelar),
            ),
            FilledButton(
              onPressed: () {
                state.setMetaAguaLitros(valor);
                Navigator.of(ctx).pop(true);
              },
              child: Text(strings.prGuardar),
            ),
          ],
        ),
      ),
    );
    if (guardado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.pfAjustesGuardados)),
      );
    }
  }

  /// P6: edita las metas de actividad (pasos diarios y calorías diarias).
  /// Dialogo con validación real; persiste vía `actualizarMetas` sin perder
  /// el resto del perfil (nombre, foto, racha, etc.).
  Future<void> _editarMetas() async {
    final strings = context.read<LocaleService>().strings;
    final actual = context.read<AppState>().profile;
    final pasosCtrl = TextEditingController(text: '${actual.pasosMeta}');
    final kcalCtrl = TextEditingController(
      text: actual.caloriasMeta.toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();

    final guardar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.pfEditarMetas),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: pasosCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: strings.pfMetaPasos,
                  icon: const Icon(Icons.directions_walk, size: 20),
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return Validators.validarMetaPasos(
                    n,
                    strings.pfMetaPasosMin,
                  );
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: kcalCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: strings.pfMetaCalorias,
                  icon: const Icon(Icons.local_fire_department, size: 20),
                ),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  return Validators.validarMetaKcal(
                    n,
                    strings.pfMetaKcalMin,
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(strings.pfCancelar),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: Text(strings.pfGuardarCambios),
          ),
        ],
      ),
    );

    if (guardar != true || !mounted) return;
    await context.read<AppState>().actualizarMetas(
          calorias: double.tryParse(kcalCtrl.text),
          pasos: int.tryParse(pasosCtrl.text),
        );
    if (!mounted) return;
    setState(() => _profile = context.read<AppState>().profile);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.pfAjustesGuardados)),
    );
  }

  /// Botón principal de guardado + versión de la app.
  Widget _buildAcciones() {
    final strings = context.read<LocaleService>().strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: _guardarCambios,
            icon: const Icon(Icons.save_outlined, size: 20),
            label: Text(
              strings.pfGuardarCambios,
              style: AppType.labelLg.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          strings.pfVersion,
          textAlign: TextAlign.center,
          style: AppType.labelSm.copyWith(color: AppColors.outline),
        ),
      ],
    );
  }
}

String _groupThousands(int value) => value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    final state = context.watch<AppState>();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      decoration: BoxDecoration(color: AppColors.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.pfMiPerfil,
                      style: AppType.headlineSm.copyWith(fontWeight: FontWeight.w700, height: 1.1),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.pfSuperaLimites,
                      style: AppType.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              RachaChip(racha: context.watch<AppState>().rachaDias),
              const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const ConfiguracionScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.settings_outlined, size: 22, color: AppColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // E1: el nivel como identidad, pasivo (sin acción detrás). Vive en
          // su propia línea: a 2.0× no compite con la racha por el ancho.
          NivelChip(nivel: state.nivel, nombre: state.nombreNivel),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile});

  final AthleteProfile profile;

  /// Sube una foto desde la galería y la guarda en el perfil de la sesión.
  /// Paso opcional: si falla o se cancela el perfil sigue sin foto (iniciales).
  Future<void> _subirFoto(BuildContext context) async {
    final strings = context.read<LocaleService>().strings;
    final messenger = ScaffoldMessenger.of(context);
    final appState = context.read<AppState>();
    try {
      final foto = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (foto == null) return; // Cancelado: sigue sin foto (iniciales).
      final bytes = await foto.readAsBytes();
      if (bytes.isEmpty) return;
      final base64 = base64Encode(bytes);
      // Fase 9: recortar el encuadre casi uniforme (marco blanco/gris) para
      // que la persona llene el círculo y no se vea un "borde cuadrado"
      // dentro del avatar.
      final recortada = await compute(recuadrarFoto, base64);
      await appState.guardarPerfil(profile.copiarConFoto(recortada ?? base64));
      messenger.showSnackBar(SnackBar(content: Text(strings.pfFotoGuardada)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(strings.pfErrorFoto)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              FitAvatar(
                nombre: profile.nombre,
                fotoBase64: profile.fotoBase64,
                radius: 48,
                borde: AppColors.outlineVariant,
                bordeAncho: 4,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: InkWell(
                  onTap: () => _subirFoto(context),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.photo_camera, size: 16, color: AppColors.onPrimary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  profile.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppType.headlineMd.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.verified, size: 18, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                if (context.watch<AppState>().rachaDias >= 7) ...[
                  const Text('🔥', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 5),
                ],
                Flexible(
                  child: Text(
                    strings.pfRachaEnRacha(context.watch<AppState>().rachaDias),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.labelMd.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.outlineVariant, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    // Las metas se guardan en español; solo se traduce el
                    // texto pintado.
                    '${strings.pfPlan}${profile.metas.isEmpty ? '—' : profile.metas.map(strings.metaName).join(' · ')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.labelMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _QuickStat(
                  label: strings.regWeightLabel,
                  value: profile.pesoKg.toStringAsFixed(1),
                  unit: 'kg',
                ),
                _QuickStat(
                  label: strings.regHeightLabel,
                  value: profile.alturaM.toStringAsFixed(2),
                  unit: 'm',
                ),
                _QuickStat(
                  label: strings.pfGrasaPct,
                  value: (() {
                    final grasa = context.watch<AppState>().grasaHoy;
                    return grasa?.toStringAsFixed(1) ?? '—';
                  })(),
                  unit: '%',
                  valueColor: AppColors.primary,
                ),
                _QuickStat(
                  label: strings.pfImc,
                  value: profile.imcFormateado,
                  unit: profile.imc < 25 && profile.imc >= 18.5
                      ? strings.pfOptimo
                      : strings.imcNombre(profile.imcCategoria),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({
    required this.label,
    required this.value,
    required this.unit,
    this.valueColor,
  });

  final String label;
  final String value;
  final String unit;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: AppType.labelSm.copyWith(color: AppColors.onSurfaceVariant, letterSpacing: 0.4),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppType.headlineSm.copyWith(color: valueColor ?? AppColors.onSurface, fontWeight: FontWeight.w800),
          ),
          Text(
            unit,
            style: AppType.labelSm.copyWith(color: AppColors.outline),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.value,
    required this.unit,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppType.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(
                  '$value $unit',
                  style: AppType.headlineSm
                      .copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w700)
                      .merge(AppType.labelSm.copyWith(color: AppColors.outline, fontWeight: FontWeight.w400)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceTag extends StatelessWidget {
  const _PreferenceTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.labelMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.close, size: 14, color: AppColors.outline),
        ],
      ),
    );
  }
}

class _AddPreferenceTag extends StatelessWidget {
  const _AddPreferenceTag({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              strings.pfAnadir,
              style: AppType.labelMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Progreso de pasos de hoy conectado al sensor real del teléfono.
class _PasosProgresoHoy extends StatelessWidget {
  const _PasosProgresoHoy();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final strings = context.watch<LocaleService>().strings;
    final meta = state.profile.pasosMeta;
    final pasos = state.pasosHoy;
    final hasMeta = meta > 0;
    final percent = hasMeta ? (pasos / meta).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: state.healthDisponible && hasMeta ? percent : 0,
            minHeight: 7,
            backgroundColor: AppColors.surfaceContainerHighest,
            color: AppColors.primaryContainer,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                state.healthDisponible
                    ? strings.pfProgresoPasos(_groupThousands(pasos))
                    : strings.pfActivaDatos,
                style: AppType.labelSm.copyWith(color: AppColors.outline),
              ),
            ),
            Text(
              state.healthDisponible ? '${(percent * 100).round()}%' : '—',
              style: AppType.labelSm.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
