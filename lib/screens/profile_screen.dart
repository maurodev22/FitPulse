import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/avisos_service.dart';
import '../services/config_service.dart';
import '../services/locale_service.dart';
import '../state/app_state.dart';
import '../state/athlete_profile.dart';
import '../theme.dart';

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
                  _buildIdioma(),
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
    final activo = config.premiumEnabled;
    return _SettingsCard(
      children: [
        const _CardTitle(icon: Icons.workspace_premium, title: 'FitPulse Premium'),
        const SizedBox(height: 8),
        Text(
          activo
              ? 'Premium activo: los anuncios están desactivados. 🎉'
              : 'Quita los anuncios de por vida con una compra única.',
          style: AppType.bodySm.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        // Consentimiento local de anuncios (Fase 3): el usuario puede apagarlos.
        _ToggleRow(
          icon: Icons.campaign_outlined,
          title: 'Anuncios habilitados',
          subtitle: 'Banners y recompensados con IDs de prueba de AdMob',
          value: config.adsEnabled,
          onChanged: (v) => config.setAds(v),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: () => config.setPremium(!activo),
            child: Text(
              activo
                  ? 'Desactivar Premium (modo prueba)'
                  : 'Activar Premium (modo prueba)',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'El cobro real requiere Google Play con una cuenta fuera de Cuba '
          '(ver PLAN.md, Fase 3). Este botón activa Premium localmente para '
          'probar que los anuncios se ocultan.',
          style: AppType.bodySm.copyWith(color: AppColors.outline),
        ),
      ],
    );
  }

  Widget _buildMetasActividad() {
    return _SettingsCard(
      children: [
        const _CardTitle(icon: Icons.track_changes, title: 'Metas de Actividad', action: _IconAction(icon: Icons.edit)),
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
                  const Icon(Icons.directions_walk, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Pasos diarios',
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
                  label: 'Calorías activas',
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
                  label: 'Cardio semanal',
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
                'Días de entrenamiento',
                style: AppType.labelMd.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
            Text(
              '${_trainingDays.length} días / semana',
              style: AppType.labelMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
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
                  d,
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
    return _SettingsCard(
      children: [
        const _CardTitle(icon: Icons.monitor_heart_outlined, title: 'Datos de salud'),
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
                  title: 'Health Connect',
                  subtitle: 'Instala la app Google Health Connect para sincronizar',
                  value: _healthKit,
                  onChanged: (v) => setState(() => _healthKit = v),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sin Health Connect, pulso, sueño y grasa se muestran como "—" (nunca inventados).',
                  style: AppType.bodySm.copyWith(color: AppColors.outline),
                ),
              ],
            );
          }
          if (pidiendo) {
            return const Padding(
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
                      'Concediendo permisos en la pantalla de Health Connect…',
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
                            conectado
                                ? 'Health Connect conectado'
                                : 'Health Connect disponible',
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
                        _PermisoChip(ok: pulsoOk, label: 'Pulso'),
                        _PermisoChip(ok: aguaOk, label: 'Agua'),
                        _PermisoChip(ok: grasaOk, label: 'Grasa'),
                        _PermisoChip(ok: suenioOk, label: 'Sueño'),
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
                  label: const Text('Abrir permisos de Health Connect'),
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
    return _SettingsCard(
      children: [
        const _CardTitle(icon: Icons.person_pin, title: 'Datos Personales'),
        const SizedBox(height: 12),
        _TextField(label: 'Nombre completo', icon: Icons.badge, value: _profile.nombre),
        const SizedBox(height: 12),
        _TextField(label: 'Peso', icon: Icons.scale, value: '${_profile.pesoKg} kg'),
        const SizedBox(height: 12),
        _TextField(label: 'Altura', icon: Icons.straighten, value: '${_profile.alturaM} m'),
        const SizedBox(height: 12),
        _TextField(
          label: 'IMC',
          icon: Icons.insights,
          value: '${_profile.imcFormateado} — ${_profile.imcCategoria}',
        ),
        const SizedBox(height: 16),
        Text(
          'Nivel de condición física',
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
                      level,
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
          'Tipo de entrenamiento preferido',
          style: AppType.labelMd.copyWith(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            const _PreferenceTag(icon: Icons.bolt, label: 'HIIT'),
            const _PreferenceTag(icon: Icons.fitness_center, label: 'Fuerza funcional'),
            const _PreferenceTag(icon: Icons.directions_run, label: 'Running'),
            _AddPreferenceTag(onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Selecciona tu próximo entrenamiento favorito')),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildPreferencias() {
    return _SettingsCard(
      children: [
        const _CardTitle(icon: Icons.tune, title: 'Preferencias & Sincronización'),
        const SizedBox(height: 8),
        _ToggleRow(
          icon: Icons.water_drop,
          title: 'Recordatorios de hidratación',
          subtitle: 'Cada hora · notificación local',
          value: _hydration,
          onChanged: (v) {
            setState(() => _hydration = v);
            _aplicarAvisoHidratacion(v);
          },
        ),
        _ToggleRow(
          icon: Icons.alarm,
          title: 'Aviso de racha en riesgo',
          subtitle: 'Diario a las 20:00 con tu racha real',
          value: _morningWorkout,
          onChanged: (v) {
            setState(() => _morningWorkout = v);
            _aplicarAvisoRacha(v);
          },
        ),
        _ToggleRow(
          icon: Icons.watch,
          title: 'HealthKit / Smartwatch',
          subtitle: 'Sincronización en segundo plano',
          value: _healthKit,
          onChanged: (v) => setState(() => _healthKit = v),
        ),
        _ToggleRow(
          icon: Icons.vibration,
          title: 'Vibración háptica',
          subtitle: 'Avisos de cambio de intervalo',
          value: _haptic,
          onChanged: (v) => setState(() => _haptic = v),
        ),
        _ToggleRow(
          icon: Icons.group,
          title: 'Compartir actividad',
          subtitle: 'Visible solo para amigos seguidos',
          value: _shareActivity,
          iconColor: AppColors.outline,
          onChanged: (v) => setState(() => _shareActivity = v),
        ),
      ],
    );
  }

  Widget _buildIdioma() {
    final localeService = context.watch<LocaleService>();
    return _SettingsCard(
      children: [
        _CardTitle(
          icon: Icons.language,
          title: 'Idioma / Language',
        ),
        const SizedBox(height: 8),
        SegmentedButton<AppLocale>(
          segments: const [
            ButtonSegment(value: AppLocale.es, label: Text('Español')),
            ButtonSegment(value: AppLocale.en, label: Text('English')),
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
          'El idioma se aplica al instante.',
          style: AppType.bodySm.copyWith(color: AppColors.outline),
        ),
      ],
    );
  }

  Widget _buildAcciones() {
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
                    const Icon(Icons.save, size: 20, color: AppColors.onPrimary),
                    const SizedBox(width: 8),
                    Text(
                      'Guardar cambios',
                      style: AppType.labelLg.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'FitPulse v1.0.0 (Build 1)',
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
      const SnackBar(content: Text('¡Ajustes guardados en tu dispositivo!')),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      decoration: const BoxDecoration(color: AppColors.surface),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mi Perfil',
                  style: AppType.headlineSm.copyWith(fontWeight: FontWeight.w700, height: 1.1),
                ),
                const SizedBox(height: 2),
                Text(
                  'Supera tus límites hoy',
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
                  '${context.watch<AppState>().rachaDias} días',
                  style: AppType.labelMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Configuración general disponible próximamente')),
              );
            },
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
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
        children: [
          Stack(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.secondaryFixed, width: 4),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset('assets/images/profile.webp', fit: BoxFit.cover),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edición de foto próximamente')),
                    );
                  },
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_camera, size: 16, color: AppColors.onPrimary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                profile.nombre,
                style: AppType.headlineMd.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.verified, size: 18, color: AppColors.primary),
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
                    '${context.watch<AppState>().rachaDias} días en racha',
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
                  decoration: const BoxDecoration(color: AppColors.outlineVariant, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Plan: ${profile.metas.isEmpty ? '—' : profile.metas.join(' · ')}',
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
                _QuickStat(label: 'Peso', value: profile.pesoKg.toStringAsFixed(1), unit: 'kg'),
                _QuickStat(label: 'Altura', value: profile.alturaM.toStringAsFixed(2), unit: 'm'),
                _QuickStat(
                  label: '% Grasa',
                  value: (() {
                    final grasa = context.watch<AppState>().grasaHoy;
                    return grasa?.toStringAsFixed(1) ?? '—';
                  })(),
                  unit: '%',
                  valueColor: AppColors.primary,
                ),
                _QuickStat(label: 'IMC', value: profile.imcFormateado, unit: profile.imc < 25 && profile.imc >= 18.5 ? 'Óptimo' : profile.imcCategoria),
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
    this.valueColor = AppColors.onSurface,
  });

  final String label;
  final String value;
  final String unit;
  final Color valueColor;

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
            style: AppType.headlineSm.copyWith(color: valueColor, fontWeight: FontWeight.w800),
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
          Text(
            label,
            style: AppType.labelMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.close, size: 14, color: AppColors.outline),
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
            const Icon(Icons.add, size: 14, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              'Añadir',
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
    this.iconColor = AppColors.primary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color iconColor;

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
            child: Icon(icon, size: 18, color: iconColor),
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
                    ? 'Progreso de hoy: ${_groupThousands(pasos)} pasos'
                    : 'Activa los datos de actividad para seguir tus pasos',
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