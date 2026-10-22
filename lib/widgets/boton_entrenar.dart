import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/workout_builder_screen.dart';
import '../screens/workout_player_screen.dart';
import '../services/locale_service.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// Acceso rápido a entrenar (botón flotante global).
///
/// Abre una hoja con tres salidas reales: el entrenamiento recomendado de hoy,
/// las rutinas guardadas y el editor para crear una nueva. No inicia nada con
/// un solo toque a propósito: el reproductor arranca el cronómetro al abrirse,
/// así que empezar una sesión debe ser una decisión explícita (dos toques).
class BotonEntrenar extends StatelessWidget {
  const BotonEntrenar({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    return FloatingActionButton.extended(
      onPressed: () => _abrirHoja(context),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      icon: const Icon(Icons.play_arrow_rounded),
      label: Text(
        strings.fabEntrenar,
        style: AppType.labelLg.copyWith(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Future<void> _abrirHoja(BuildContext context) async {
    final state = context.read<AppState>();
    final strings = context.read<LocaleService>().strings;
    final recomendado = state.entrenamientoRecomendado;
    final totalRutinas = state.rutinas.length;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        void abrir(Widget destino) {
          Navigator.of(sheetCtx).pop();
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => destino),
          );
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(sheetCtx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                strings.fabEntrenarTitulo,
                style: AppType.headlineSm.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                strings.fabEntrenarDesc,
                style: AppType.bodySm.copyWith(color: AppColors.outline),
              ),
              const SizedBox(height: 16),
              _Opcion(
                icon: Icons.play_arrow_rounded,
                titulo: strings.homeEntrenamientoHoy,
                // Dato real del plan: nunca un entrenamiento inventado.
                detalle: '${recomendado.nombre} · '
                    '${recomendado.duracionEtiqueta}',
                onTap: () => abrir(WorkoutPlayerScreen(program: recomendado)),
              ),
              const SizedBox(height: 10),
              _Opcion(
                icon: Icons.edit_note,
                titulo: strings.rutTitulo,
                detalle: totalRutinas == 0
                    ? strings.rutVacio
                    : (totalRutinas == 1
                        ? strings.rutNRutinas
                        : strings.rutNRutinasN(totalRutinas)),
                onTap: () => abrir(const MisRutinasScreen()),
              ),
              const SizedBox(height: 10),
              _Opcion(
                icon: Icons.add,
                titulo: strings.rutNueva,
                detalle: strings.fabCrearRutinaDesc,
                onTap: () => abrir(const RutinaEditorScreen()),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Fila de la hoja: icono, título, detalle real y toda la fila tocable.
class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.icon,
    required this.titulo,
    required this.detalle,
    required this.onTap,
  });

  final IconData icon;
  final String titulo;
  final String detalle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.labelLg.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detalle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: AppColors.outline),
            ],
          ),
        ),
      ),
    );
  }
}
