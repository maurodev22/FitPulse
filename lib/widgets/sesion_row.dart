import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import '../state/workout.dart';
import '../theme.dart';

/// Fila de sesión real, reutilizada en Progreso (recientes) y en el
/// Historial completo (corrección L1: "Ver todo" ahora abre ese historial).
class SesionRow extends StatelessWidget {
  const SesionRow({
    super.key,
    required this.icon,
    required this.titulo,
    required this.detalle,
  });

  /// Construye la fila desde una sesión REAL del historial.
  factory SesionRow.fromSesion(WorkoutSession s, AppStrings strings) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final dia = DateTime(s.fecha.year, s.fecha.month, s.fecha.day);
    final diff = hoy.difference(dia).inDays;
    final cuando = diff == 0
        ? strings.prHoy
        : diff == 1
            ? strings.prAyer
            : diff < 7
                ? strings.prHaceDias(diff)
                : '${s.fecha.day}/${s.fecha.month}';
    return SesionRow(
      icon: Icons.fitness_center,
      titulo: s.nombre,
      detalle: '$cuando • ${s.duracionMin} min • ${s.calorias} kcal',
    );
  }

  final IconData icon;
  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
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
                  style: AppType.labelLg.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detalle,
                  style: AppType.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, size: 20, color: AppColors.primary),
        ],
      ),
    );
  }
}