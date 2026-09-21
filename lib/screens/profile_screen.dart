import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../state/athlete_profile.dart';
import '../theme.dart';
import 'registration_screen.dart';

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
                  _buildDatosPersonales(),
                  const SizedBox(height: 16),
                  _buildPreferencias(),
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
                  Text(
                    'Pasos diarios',
                    style: AppType.labelMd.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const Spacer(),
                  Text(
                    _groupThousands(_profile.pasosMeta),
                    style: AppType.headlineSm.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: 0.82,
                  minHeight: 7,
                  backgroundColor: AppColors.surfaceContainerHighest,
                  color: AppColors.primaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Progreso de hoy: 8,240 pasos',
                    style: AppType.labelSm.copyWith(color: AppColors.outline),
                  ),
                  const Spacer(),
                  Text(
                    '82%',
                    style: AppType.labelSm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                icon: Icons.local_fire_department,
                iconColor: AppColors.error,
                iconBackground: AppColors.errorContainer,
                label: 'Calorías activas',
                value: _profile.caloriasMeta.toStringAsFixed(0),
                unit: 'kcal',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStat(
                icon: Icons.favorite,
                iconColor: AppColors.primary,
                iconBackground: AppColors.secondaryFixed,
                label: 'Cardio semanal',
                value: '180',
                unit: 'min',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              'Días de entrenamiento',
              style: AppType.labelMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const Spacer(),
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
          subtitle: 'Cada 90 minutos de actividad',
          value: _hydration,
          onChanged: (v) => setState(() => _hydration = v),
        ),
        _ToggleRow(
          icon: Icons.alarm,
          title: 'Entrenamiento matutino',
          subtitle: 'Programado para las 07:00 AM',
          value: _morningWorkout,
          onChanged: (v) => setState(() => _morningWorkout = v),
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
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _cerrarSesion,
          icon: const Icon(Icons.logout, size: 18, color: AppColors.error),
          label: Text(
            'Cerrar sesión',
            style: AppType.labelMd.copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'FitPulse v1.0.0 (Build 1)',
          style: AppType.bodySm.copyWith(color: AppColors.outline),
        ),
      ],
    );
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
        meta: actual.meta,
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

  /// Cierra la sesión, borra la persistencia y vuelve al onboarding.
  void _cerrarSesion() {
    context.read<AppState>().cerrarSesion();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const RegistrationScreen()),
      (route) => false,
    );
  }

  String _groupThousands(int value) => value.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      decoration: const BoxDecoration(color: AppColors.surface),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.secondaryFixed, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset('assets/images/avatar.jpg', fit: BoxFit.cover),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryFixed,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, Atleta',
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
                  '14 días',
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
                child: Image.asset('assets/images/profile.jpg', fit: BoxFit.cover),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.fitness_center, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  'Atleta ${profile.nivel}',
                  style: AppType.labelMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '${profile.rachaDias} días en racha',
                  style: AppType.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(color: AppColors.outlineVariant, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  'Plan: ${profile.meta}',
                  style: AppType.labelMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w500),
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
                _QuickStat(label: '% Grasa', value: '21.4', unit: '%', valueColor: AppColors.primary),
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