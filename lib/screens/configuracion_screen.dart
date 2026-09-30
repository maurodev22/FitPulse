import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/avisos_service.dart';
import '../services/config_service.dart';
import '../services/data_backup_service.dart';
import '../services/locale_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/settings_widgets.dart';
import 'eula_screen.dart';
import 'privacy_screen.dart';

/// Pantalla de Configuración general: preferencias, tema, idioma, permisos de
/// salud, privacidad/datos y guardado persistente. Accesible desde el engranaje
/// del Perfil.
class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  bool _hydration = true;
  bool _morningWorkout = true;
  bool _healthKit = true;
  bool _haptic = true;
  bool _shareActivity = false;

  @override
  void initState() {
    super.initState();
    _loadFromState();
  }

  void _loadFromState() {
    final profile = context.read<AppState>().profile;
    _hydration = profile.hidratacion;
    _morningWorkout = profile.entrenamientoMatutino;
    _healthKit = profile.healthKit;
    _haptic = profile.vibracion;
    _shareActivity = profile.compartirActividad;
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          strings.pfConfiguracion,
          style: AppType.headlineSm.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.onSurfaceVariant),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _buildPreferencias(),
            const SizedBox(height: 16),
            _buildTema(),
            const SizedBox(height: 16),
            _buildIdioma(),
            const SizedBox(height: 16),
            _buildConectarSalud(),
            const SizedBox(height: 16),
            _buildPrivacidadDatos(),
            const SizedBox(height: 20),
            _buildAcciones(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencias() {
    final strings = context.watch<LocaleService>().strings;
    return SettingsCard(
      children: [
        SettingsCardTitle(icon: Icons.tune, title: strings.pfPreferencias),
        const SizedBox(height: 8),
        ToggleRow(
          icon: Icons.water_drop,
          title: strings.pfRecordatoriosHidratacion,
          subtitle: strings.pfCadaHora,
          value: _hydration,
          onChanged: (v) {
            setState(() => _hydration = v);
            _aplicarAvisoHidratacion(v);
          },
        ),
        ToggleRow(
          icon: Icons.alarm,
          title: strings.pfAvisoRacha,
          subtitle: strings.pfDiario20,
          value: _morningWorkout,
          onChanged: (v) {
            setState(() => _morningWorkout = v);
            _aplicarAvisoRacha(v);
          },
        ),
        ToggleRow(
          icon: Icons.watch,
          title: strings.pfHealthKit,
          subtitle: strings.pfSincronizacion,
          value: _healthKit,
          onChanged: (v) => setState(() => _healthKit = v),
        ),
        ToggleRow(
          icon: Icons.vibration,
          title: strings.pfVibracion,
          subtitle: strings.pfAvisosIntervalo,
          value: _haptic,
          onChanged: (v) => setState(() => _haptic = v),
        ),
        ToggleRow(
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

  /// Selector de tema (sistema / claro / oscuro), persistido y de aplicación
  /// inmediata. La paleta activa la resuelve el MaterialApp.
  Widget _buildTema() {
    final config = context.watch<ConfigService>();
    final strings = context.watch<LocaleService>().strings;
    return SettingsCard(
      children: [
        SettingsCardTitle(
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
    return SettingsCard(
      children: [
        SettingsCardTitle(
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

  Widget _buildConectarSalud() {
    final strings = context.watch<LocaleService>().strings;
    return SettingsCard(
      children: [
        SettingsCardTitle(icon: Icons.monitor_heart_outlined, title: strings.pfDatosSalud),
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
                ToggleRow(
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
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
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
                        PermisoChip(ok: pulsoOk, label: strings.homePulso),
                        PermisoChip(ok: aguaOk, label: strings.homeAgua),
                        PermisoChip(ok: grasaOk, label: strings.pfGrasaPermiso),
                        PermisoChip(ok: suenioOk, label: strings.pfSuenio),
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

  /// Sección "Privacidad y datos" — exportar, importar, política de privacidad
  /// y borrado total (derechos GDPR arts. 17 y 20).
  Widget _buildPrivacidadDatos() {
    final strings = context.watch<LocaleService>().strings;
    return SettingsCard(
      children: [
        SettingsCardTitle(icon: Icons.shield_outlined, title: strings.pfPrivacidadDatos),
        const SizedBox(height: 8),
        FilaAccion(
          icon: Icons.upload_outlined,
          title: strings.pfExportarDatos,
          subtitle: strings.pfExportarDatosSub,
          onTap: _exportarDatos,
        ),
        FilaAccion(
          icon: Icons.download_outlined,
          title: strings.pfImportarBackup,
          subtitle: strings.pfImportarBackupSub,
          onTap: _importarBackup,
        ),
        FilaAccion(
          icon: Icons.privacy_tip_outlined,
          title: strings.pfPoliticaPrivacidad,
          subtitle: strings.pfPoliticaPrivacidadSub,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const PrivacyScreen()),
          ),
        ),
        Divider(height: 24, color: AppColors.outlineVariant.withValues(alpha: 0.4)),
        FilaAccion(
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

  /// Persiste las preferencias editadas con los cambios locales del formulario.
  void _guardarCambios() {
    final actual = context.read<AppState>().profile;
    context.read<AppState>().guardarPerfil(
      actual.copyWith(
        hidratacion: _hydration,
        entrenamientoMatutino: _morningWorkout,
        healthKit: _healthKit,
        vibracion: _haptic,
        compartirActividad: _shareActivity,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.read<LocaleService>().strings.pfAjustesGuardados)),
    );
  }

  /// Aplica el recordatorio de hidratación (programa/cancela la notificación
  /// periódica) mostrando un aviso honesto si no procede.
  Future<void> _aplicarAvisoHidratacion(bool activar) async {
    final r = await avisosService.setHidratacion(activar: activar);
    if (!r.ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(r.mensaje)));
    }
  }

  /// Aplica el aviso diario de racha (20:00) con la racha real del historial;
  /// cancela/programa según el toggle.
  Future<void> _aplicarAvisoRacha(bool activar) async {
    final racha = context.read<AppState>().rachaDias;
    final r = await avisosService.setRacha(activar: activar, rachaDias: racha);
    if (!r.ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(r.mensaje)));
    }
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
}