import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart' show AppShell;
import '../services/avisos_service.dart';
import '../services/config_service.dart';
import '../services/locale_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/settings_widgets.dart';

/// P17: configuración inicial ligera, una sola pantalla tras el registro.
///
/// No es un asistente ni una cascada de permisos: solo permite elegir el tema
/// (con vista previa real) y decidir si se quieren los avisos opt-in. El
/// permiso de notificaciones NO se pide aquí en bloque: al pulsar
/// [Continuar] con algún aviso activo se llama a [AvisosService.sincronizar],
/// que pide el permiso UNA sola vez en contexto y, si se deniega, no programa
/// nada (honesto). "Ahora no" entra al Home sin tocar nada.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  AppThemeMode _tema = AppThemeMode.system;
  bool _hidratacion = true;
  bool _racha = true;

  @override
  void initState() {
    super.initState();
    final config = context.read<ConfigService>();
    final perfil = context.read<AppState>().profile;
    _tema = config.themeMode;
    _hidratacion = perfil.hidratacion;
    _racha = perfil.entrenamientoMatutino;
  }

  /// Persiste la selección (tema ya aplicado en vivo), sincroniza los avisos
  /// en contexto (permiso UNA vez si procede) y entra al Home.
  Future<void> _continuar() async {
    final appState = context.read<AppState>();
    appState.guardarPerfil(
      appState.profile.copyWith(
        hidratacion: _hidratacion,
        entrenamientoMatutino: _racha,
      ),
    );
    // Permiso en contexto: si está pendiente, el sistema lo pide aquí mismo
    // (el usuario acaba de elegir avisos). Si se deniega, no se programa nada.
    await avisosService.sincronizar(
      hidratacion: _hidratacion,
      racha: _racha,
      rachaDias: appState.rachaDias,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const AppShell()),
    );
  }

  /// "Ahora no": entra al Home sin modificar nada (el permiso nunca se pide
  /// aquí por sorpresa; si más adelante se activan avisos, se pide en contexto).
  void _ahoraNo() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const AppShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(strings),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTema(strings),
                    const SizedBox(height: 16),
                    _buildAvisos(strings),
                    const SizedBox(height: 10),
                    Text(
                      strings.setupNotaAvisos,
                      style: AppType.bodySm.copyWith(color: AppColors.outline),
                    ),
                  ],
                ),
              ),
            ),
            _buildFooter(strings),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppStrings strings) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gradienteInicio,
            AppColors.gradienteIntermedio,
            AppColors.gradienteFin,
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.workspace_premium, color: AppColors.onGradiente, size: 28),
          const SizedBox(height: 10),
          Text(
            strings.setupTitulo,
            style:
                AppType.headlineMd.copyWith(color: AppColors.onGradiente),
          ),
          const SizedBox(height: 6),
          Text(
            strings.setupSubtitulo,
            style: AppType.bodySm.copyWith(color: AppColors.onGradienteVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildTema(AppStrings strings) {
    return SettingsCard(
      children: [
        SettingsCardTitle(
          icon: Icons.dark_mode_outlined,
          title: strings.setupTema,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _opcionTema(
              strings.setupTemaSistema,
              AppThemeMode.system,
              Icons.brightness_auto_outlined,
              dividida: true,
            ),
            const SizedBox(width: 10),
            _opcionTema(
              strings.setupTemaClaro,
              AppThemeMode.light,
              Icons.light_mode_outlined,
            ),
            const SizedBox(width: 10),
            _opcionTema(
              strings.setupTemaOscuro,
              AppThemeMode.dark,
              Icons.dark_mode_outlined,
            ),
          ],
        ),
      ],
    );
  }

  /// Tarjeta de opción de tema con mini-vista previa real (paletas de la app).
  Widget _opcionTema(
    String etiqueta,
    AppThemeMode modo,
    IconData icono, {
    bool dividida = false,
  }) {
    final activo = _tema == modo;
    final paleta = modo == AppThemeMode.light
        ? lightFitPalette
        : modo == AppThemeMode.dark
            ? darkFitPalette
            : lightFitPalette;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() => _tema = modo);
          context.read<ConfigService>().setThemeMode(modo);
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: activo ? AppColors.primary : AppColors.outlineVariant,
              width: activo ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              // Mini vista previa usando los colores reales de la paleta.
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 44,
                  child: dividida
                      ? Column(
                          children: [
                            Expanded(
                              child: Container(
                                  color: lightFitPalette.background,
                                  width: double.infinity),
                            ),
                            Expanded(
                              child: Container(
                                  color: darkFitPalette.background,
                                  width: double.infinity),
                            ),
                          ],
                        )
                      : Container(
                          color: paleta.background,
                          width: double.infinity,
                          child: Center(
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: paleta.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icono,
                                  size: 14, color: paleta.onPrimary),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icono,
                      size: 15,
                      color: activo ? AppColors.primary : AppColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      etiqueta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.labelSm.copyWith(
                        color: activo ? AppColors.primary : AppColors.onSurface,
                        fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvisos(AppStrings strings) {
    return SettingsCard(
      children: [
        SettingsCardTitle(
          icon: Icons.notifications_outlined,
          title: strings.setupAvisos,
        ),
        const SizedBox(height: 4),
        ToggleRow(
          icon: Icons.water_drop_outlined,
          title: strings.pfRecordatoriosHidratacion,
          subtitle: strings.pfCadaMediaHora,
          value: _hidratacion,
          onChanged: (v) => setState(() => _hidratacion = v),
        ),
        ToggleRow(
          icon: Icons.local_fire_department_outlined,
          title: strings.pfAvisoRacha,
          subtitle: strings.pfDiario20,
          value: _racha,
          onChanged: (v) => setState(() => _racha = v),
        ),
      ],
    );
  }

  Widget _buildFooter(AppStrings strings) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        border: Border(
          top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: _continuar,
                borderRadius: BorderRadius.circular(18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        strings.setupContinuar,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward,
                        size: 18, color: AppColors.onPrimary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _ahoraNo,
            child: Text(strings.setupAhoraNo,
                style: AppType.labelLg.copyWith(color: AppColors.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}