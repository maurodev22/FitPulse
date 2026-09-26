import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/avisos_service.dart';
import '../services/config_service.dart';
import '../services/data_backup_service.dart';
import '../services/locale_service.dart';
import '../state/app_state.dart';
import '../state/athlete_profile.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'eula_screen.dart';
import 'privacy_screen.dart';

/// Perfil y Ajustes: muestra y edita los datos del atleta de la sesión.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AthleteProfile _profile;
  late Set<String> _trainingDays;
  late String _fitnessLevel;
  late bool _hydration;
  late bool _morningWorkout;
  late bool _healthKit;
  late bool _haptic;
  late bool _shareActivity;

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
    _hydration = _profile.hidratacion;
    _morningWorkout = _profile.entrenamientoMatutino;
    _healthKit = _profile.healthKit;
    _haptic = _profile.vibracion;
    _shareActivity = _profile.compartirActividad;
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
                  _ProfileHero(profile: _profile),
                  const SizedBox(height: 16),
                  _buildMetasActividad(),
                  const SizedBox(height: 16),
                  _buildPremium(),
                  const SizedBox(height: 16),
                  _buildConectarSalud(),
                  const SizedBox(height: 16),
                  _buildDatosPersonales(),
                  const SizedBox(height: 16),
                  _buildPreferencias(),
                  const SizedBox(height: 16),
                  _buildTema(),
                  _buildIdioma(),
                  const SizedBox(height: 16),
                  _buildPrivacidadDatos(),
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

  Widget _buildPremium() {
    final config = context.watch<ConfigService>();
    final strings = context.watch<LocaleService>().strings;
    final activo = config.premiumEnabled;
    return _SettingsCard(
      children: [
        _CardTitle(icon: Icons.workspace_premium, title: strings.pfPremium),
        const SizedBox(height: 8),
        Text(
          activo ? strings.pfPremiumActivo : strings.pfPremiumQuitar,
          style: AppType.bodySm.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        // Consentimiento local de anuncios (Fase 3): el usuario puede apagarlos.
        _ToggleRow(
          icon: Icons.campaign_outlined,
          title: strings.pfAnunciosHabilitados,
          subtitle: strings.pfAnunciosSub,
          value: config.adsEnabled,
          onChanged: (v) => config.setAds(v),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: () => config.setPremium(!activo),
            child: Text(
              activo ? strings.pfDesactivarPremium : strings.pfActivarPremium,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          strings.pfPremiumNota,
          style: AppType.bodySm.copyWith(color: AppColors.outline),
        ),
      ],
    );
  }

  Widget _buildMetasActividad() {
    final strings = context.watch<LocaleService>().strings;
    return _SettingsCard(
      children: [
        _CardTitle(
          icon: Icons.track_changes,
          title: strings.pfMetasActividad,
          action: _IconAction(icon: Icons.edit),
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

  Widget _buildConectarSalud() {
    final strings = context.watch<LocaleService>().strings;
    return _SettingsCard(
      children: [
        _CardTitle(icon: Icons.monitor_heart_outlined, title: strings.pfDatosSalud),
        const SizedBox(height: 8),
        Builder(builder: (context) {
          final state = context.watch<AppState>();
          final disponible = state.healthConnectDisponible;
          final conectado = state.healthConnectConectado;
          final pidiendo = state.healthConnectPidiendo;
          final pulsoOk = state.pulsoConPermiso;
          final aguaOk = state.aguaConPermiso;
          final grasaOk = state.grasaConPermiso;
          final suenioOk = state.suenioConPermiso;

          if (!disponible) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ToggleRow(
                  icon: Icons.watch,
                  title: strings.healthConnect,
                  subtitle: strings.pfInstalaHealth,
                  value: _healthKit,
                  onChanged: (v) => setState(() => _healthKit = v),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.pfSinHealth,
                  style: AppType.bodySm.copyWith(color: AppColors.outline),
                ),
              ],
            );
          }
          if (pidiendo) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      strings.pfConcediendoPermisos,
                      style: TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                        Icon(
                          conectado ? Icons.check_circle : Icons.monitor_heart_outlined,
                          size: 18,
                          color: conectado ? AppColors.primary : AppColors.outline,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            conectado ? strings.pfConectado : strings.pfDisponible,
                            style: AppType.labelMd.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _PermisoChip(ok: pulsoOk, label: strings.homePulso),
                        _PermisoChip(ok: aguaOk, label: strings.homeAgua),
                        _PermisoChip(ok: grasaOk, label: strings.pfGrasaPermiso),
                        _PermisoChip(ok: suenioOk, label: strings.pfSuenio),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.read<AppState>().solicitarPermisosHealthConnect(),
                  icon: const Icon(Icons.link, size: 18),
                  label: Text(strings.pfAbrirPermisos),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildDatosPersonales() {
    final strings = context.watch<LocaleService>().strings;
    return _SettingsCard(
      children: [
        _CardTitle(icon: Icons.person_pin, title: strings.profilePersonalData),
        const SizedBox(height: 12),
        _TextField(
          label: strings.pfNombreCompleto,
          icon: Icons.badge,
          value: _profile.nombre,
        ),
        const SizedBox(height: 12),
        _TextField(
          label: strings.regWeightLabel,
          icon: Icons.scale,
          value: '${_profile.pesoKg} kg',
        ),
        const SizedBox(height: 12),
        _TextField(
          label: strings.regHeightLabel,
          icon: Icons.straighten,
          value: '${_profile.alturaM} m',
        ),
        const SizedBox(height: 12),
        _TextField(
          label: strings.pfImc,
          icon: Icons.insights,
          value: '${_profile.imcFormateado} — ${strings.imcNombre(_profile.imcCategoria)}',
        ),
        const SizedBox(height: 16),
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

  Widget _buildPreferencias() {
    final strings = context.watch<LocaleService>().strings;
    return _SettingsCard(
      children: [
        _CardTitle(icon: Icons.tune, title: strings.pfPreferencias),
        const SizedBox(height: 8),
        _ToggleRow(
          icon: Icons.water_drop,
          title: strings.pfRecordatoriosHidratacion,
          subtitle: strings.pfCadaHora,
          value: _hydration,
          onChanged: (v) {
            setState(() => _hydration = v);
            _aplicarAvisoHidratacion(v);
          },
        ),
        _ToggleRow(
          icon: Icons.alarm,
          title: strings.pfAvisoRacha,
          subtitle: strings.pfDiario20,
          value: _morningWorkout,
          onChanged: (v) {
            setState(() => _morningWorkout = v);
            _aplicarAvisoRacha(v);
          },
        ),
        _ToggleRow(
          icon: Icons.watch,
          title: strings.pfHealthKit,
          subtitle: strings.pfSincronizacion,
          value: _healthKit,
          onChanged: (v) => setState(() => _healthKit = v),
        ),
        _ToggleRow(
          icon: Icons.vibration,
          title: strings.pfVibracion,
          subtitle: strings.pfAvisosIntervalo,
          value: _haptic,
          onChanged: (v) => setState(() => _haptic = v),
        ),
        _ToggleRow(
          icon: Icons.group,
          title: strings.pfCompartirActividad,
          subtitle: strings.pfVisibleAmigos,
          value: _shareActivity,
          iconColor: AppColors.outline,
          onChanged: (v) => setState(() => _shareActivity = v),
        ),
      ],
    );
  }

  /// Fase 7: selector de tema (sistema / claro / oscuro), persistido y de
  /// aplicación inmediata. La paleta activa la resuelve el MaterialApp.
  Widget _buildTema() {
    final config = context.watch<ConfigService>();
    final strings = context.watch<LocaleService>().strings;
    return _SettingsCard(
      children: [
        _CardTitle(
          icon: Icons.dark_mode_outlined,
          title: strings.pfTemaApp,
        ),
        const SizedBox(height: 8),
        SegmentedButton<AppThemeMode>(
          segments: const [
            ButtonSegment(
              value: AppThemeMode.system,
              icon: Icon(Icons.brightness_auto_outlined, size: 18),
            ),
            ButtonSegment(
              value: AppThemeMode.light,
              icon: Icon(Icons.light_mode_outlined, size: 18),
            ),
            ButtonSegment(
              value: AppThemeMode.dark,
              icon: Icon(Icons.dark_mode_outlined, size: 18),
            ),
          ],
          selected: {config.themeMode},
          onSelectionChanged: (selection) {
            if (selection.isNotEmpty) {
              context.read<ConfigService>().setThemeMode(selection.first);
            }
          },
          showSelectedIcon: false,
        ),
        const SizedBox(height: 8),
        Text(
          strings.pfSeAplicaTema,
          style: AppType.bodySm.copyWith(color: AppColors.outline),
        ),
      ],
    );
  }

  Widget _buildIdioma() {
    final localeService = context.watch<LocaleService>();
    final strings = localeService.strings;
    return _SettingsCard(
      children: [
        _CardTitle(
          icon: Icons.language,
          title: strings.pfIdioma,
        ),
        const SizedBox(height: 8),
        SegmentedButton<AppLocale>(
          segments: [
            ButtonSegment(value: AppLocale.es, label: Text(strings.pfIdiomaEs)),
            ButtonSegment(value: AppLocale.en, label: Text(strings.pfIdiomaEn)),
          ],
          selected: {localeService.locale},
          onSelectionChanged: (selection) {
            if (selection.isNotEmpty) {
              context.read<LocaleService>().setLocale(selection.first);
            }
          },
          showSelectedIcon: false,
        ),
        const SizedBox(height: 8),
        Text(
          strings.pfSeAplicaIdioma,
          style: AppType.bodySm.copyWith(color: AppColors.outline),
        ),
      ],
    );
  }

  /// Fase 8: sección "Privacidad y datos" — exportar, importar, política de
  /// privacidad y borrado total (derechos GDPR arts. 17 y 20).
  Widget _buildPrivacidadDatos() {
    final strings = context.watch<LocaleService>().strings;
    return _SettingsCard(
      children: [
        _CardTitle(icon: Icons.shield_outlined, title: strings.pfPrivacidadDatos),
        const SizedBox(height: 8),
        _FilaAccion(
          icon: Icons.upload_outlined,
          title: strings.pfExportarDatos,
          subtitle: strings.pfExportarDatosSub,
          onTap: _exportarDatos,
        ),
        _FilaAccion(
          icon: Icons.download_outlined,
          title: strings.pfImportarBackup,
          subtitle: strings.pfImportarBackupSub,
          onTap: _importarBackup,
        ),
        _FilaAccion(
          icon: Icons.privacy_tip_outlined,
          title: strings.pfPoliticaPrivacidad,
          subtitle: strings.pfPoliticaPrivacidadSub,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const PrivacyScreen()),
          ),
        ),
        Divider(height: 24, color: AppColors.outlineVariant.withValues(alpha: 0.4)),
        _FilaAccion(
          icon: Icons.delete_forever_outlined,
          title: strings.pfBorrarTodosLosDatos,
          subtitle: strings.pfBorrarSub,
          iconColor: AppColors.error,
          titleColor: AppColors.error,
          onTap: _confirmarBorrado,
        ),
      ],
    );
  }

  DataBackupService _servicioBackup() => DataBackupService(
        appState: context.read<AppState>(),
        config: context.read<ConfigService>(),
        locale: context.read<LocaleService>(),
      );

  /// Exporta un backup JSON a los documentos de la app y abre el share-sheet
  /// para que el usuario lo guarde donde quiera (portabilidad, art. 20).
  Future<void> _exportarDatos() async {
    final strings = context.read<LocaleService>().strings;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final servicio = _servicioBackup();
      final fichero = await servicio.exportarArchivo(directorio: dir);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(fichero.path, mimeType: 'application/json')]),
      );
    } on Exception {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(strings.pfBackupError)));
      }
    }
  }

  /// Importa un backup: elige fichero entre los guardados, confirma y restaura.
  Future<void> _importarBackup() async {
    final strings = context.read<LocaleService>().strings;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final servicio = _servicioBackup();
    final dir = await getApplicationDocumentsDirectory();
    final backups = await servicio.listarBackups(directorio: dir);
    if (backups.isEmpty || !mounted) {
      messenger.showSnackBar(SnackBar(content: Text(strings.pfSinBackups)));
      return;
    }
    final elegido = await showDialog<File>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(strings.pfElegirBackup),
        children: [
          for (final f in backups)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(f),
              child: Text(
                f.path.split(RegExp(r'[/\\]')).last,
                style: AppType.bodyMd.copyWith(color: AppColors.onSurface),
              ),
            ),
        ],
      ),
    );
    if (elegido == null || !mounted) return;
    final r = await servicio.importarArchivo(elegido);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(r.ok ? strings.pfImportOk : strings.pfImportError)),
    );
    if (r.ok) navigator.pop();
  }

  /// Derecho al olvido (art. 17): doble confirmación antes de borrar todo.
  Future<void> _confirmarBorrado() async {
    final strings = context.read<LocaleService>().strings;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final primero = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.pfConfirmarBorradoTitulo),
        content: Text(strings.pfConfirmarBorradoCuerpo),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(strings.pfCancelar),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(strings.pfBorrarAhora),
          ),
        ],
      ),
    );
    if (primero != true || !mounted) return;

    final segundo = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.pfConfirmarBorradoTitulo),
        content: Text(strings.pfConfirmarBorradoCuerpo2),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(strings.pfCancelar),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(strings.pfBorrarAhora),
          ),
        ],
      ),
    );
    if (segundo != true || !mounted) return;

    await _servicioBackup().borrarTodo();
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(strings.pfBorradoHecho)));
    // Vuelve al flujo inicial: como el EULA y la sesión están borrados, el
    // arranque mostrará los términos de nuevo.
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const EulaScreen()),
      (_) => false,
    );
  }

  Widget _buildAcciones() {
    final strings = context.watch<LocaleService>().strings;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: _guardarCambios,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save, size: 20, color: AppColors.onPrimary),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        strings.pfGuardarCambios,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.labelLg.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          strings.pfVersion,
          style: AppType.bodySm.copyWith(color: AppColors.outline),
        ),
      ],
    );
  }

  /// Fase 6: aplica el recordatorio de hidratación (programa/cancela la
  /// notificación periódica) mostrando un aviso honesto si no procede.
  Future<void> _aplicarAvisoHidratacion(bool activar) async {
    final r = await avisosService.setHidratacion(activar: activar);
    if (!r.ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(r.mensaje)));
    }
  }

  /// Fase 6: aplica el aviso diario de racha (20:00) con la racha real del
  /// historial; cancela/programa según el toggle.
  Future<void> _aplicarAvisoRacha(bool activar) async {
    final racha = context.read<AppState>().rachaDias;
    final r = await avisosService.setRacha(activar: activar, rachaDias: racha);
    if (!r.ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(r.mensaje)));
    }
  }

  /// Persiste la sesión editada con los cambios locales del formulario.
  void _guardarCambios() {
    final actual = context.read<AppState>().profile;
    context.read<AppState>().guardarPerfil(
      AthleteProfile(
        nombre: actual.nombre,
        edad: actual.edad,
        sexo: actual.sexo,
        pesoKg: actual.pesoKg,
        alturaM: actual.alturaM,
        metas: List.of(actual.metas),
        tipoCuerpo: actual.tipoCuerpo,
        nivel: _fitnessLevel,
        diasEntrenamiento: _trainingDays.toList(),
        hidratacion: _hydration,
        entrenamientoMatutino: _morningWorkout,
        healthKit: _healthKit,
        vibracion: _haptic,
        compartirActividad: _shareActivity,
        rachaDias: actual.rachaDias,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.read<LocaleService>().strings.pfAjustesGuardados)),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      decoration: BoxDecoration(color: AppColors.surface),
      child: Row(
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  strings.rachaDias(context.watch<AppState>().rachaDias),
                  style: AppType.labelMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(strings.pfConfiguracionProx)),
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
      await appState.guardarPerfil(profile.copiarConFoto(base64));
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
                borde: AppColors.secondaryFixed,
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
                const Text('🔥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
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

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.icon, required this.title, this.action});

  final IconData icon;
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.secondaryContainer.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: AppType.headlineSm.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w700),
          ),
        ),
        action ?? const SizedBox.shrink(),
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
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

class _TextField extends StatelessWidget {
  const _TextField({required this.label, required this.icon, required this.value});

  final String label;
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppType.labelMd.copyWith(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.outline),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: AppType.bodyMd.copyWith(color: AppColors.onSurface),
                ),
              ),
            ],
          ),
        ),
      ],
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

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor ?? AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppType.labelLg.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppType.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.onPrimary,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: AppColors.onPrimary,
            inactiveTrackColor: AppColors.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }
}

/// Fila de acción táctil con icono, título y subtítulo (sección privacidad).
class _FilaAccion extends StatelessWidget {
  const _FilaAccion({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: iconColor ?? AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppType.labelLg.copyWith(
                      color: titleColor ?? AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppType.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 20, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}

/// Chip de estado de un permiso de Health Connect (concedido o no).
class _PermisoChip extends StatelessWidget {
  const _PermisoChip({required this.ok, required this.label});

  final bool ok;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ok ? AppColors.secondaryContainer : AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.check : Icons.block,
            size: 12,
            color: ok ? AppColors.onSecondaryContainer : AppColors.outline,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppType.labelSm.copyWith(
              color: ok ? AppColors.onSecondaryContainer : AppColors.outline,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
