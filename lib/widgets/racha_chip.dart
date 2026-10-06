import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/locale_service.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// Chip de racha compartido.
///
/// Muestra "N días" con un tamaño un poco mayor al original. El emoji 🔥 solo
/// se pinta cuando la racha alcanza o supera los 7 días (decisión del usuario);
/// por debajo de 7 el chip queda limpio, sin fueguito.
///
/// Es pulsable: al tocarlo abre un diálogo pequeño con las estadísticas
/// generales reales, para que "3 días" no sea un número sin contexto.
class RachaChip extends StatelessWidget {
  const RachaChip({super.key, required this.racha, this.borde = false});

  /// Racha real de días consecutivos (nunca se inventa).
  final int racha;

  /// Pinta un borde suave cuando se quiere enmarcar en fondos claros.
  final bool borde;

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    final encendida = racha >= 7;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      // Semantics: el chip es un botón, y como tal debe anunciar que lo es.
      child: InkWell(
        onTap: () => mostrarEstadisticas(context),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(999),
            border: borde
                ? Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.3),
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (encendida) ...[
                const Text('🔥', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 5),
              ],
              Text(
                strings.rachaDias(racha),
                style: AppType.labelMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip pasivo "Nv 3 · Intermedio" (Fase E1): el nivel como parte de la
/// identidad en headers (Progreso y Perfil). NO es pulsable a propósito: no
/// hay acción detrás, así que no finge ser un botón (sin ripple muerto).
class NivelChip extends StatelessWidget {
  const NivelChip({super.key, required this.nivel, required this.nombre});

  /// Nivel real derivado del XP (`AppState.nivel`).
  final int nivel;

  /// Etiqueta del nivel en español ('Principiante' | 'Intermedio' |
  /// 'Avanzado'); el chip la traduce con LocaleService.
  final String nombre;

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.workspace_premium, size: 13, color: AppColors.primary),
              const SizedBox(width: 5),
              // Flexible + softWrap: a escala de texto 2.0× el texto se
              // envuelve en vez de desbordar (identidad pasiva, sin presión).
              Flexible(
                child: Text(
                  strings.prNivelChip(nivel, nombre),
                  softWrap: true,
                  style: AppType.labelMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
///
/// Todos los números salen del historial real: no se estima ni se rellena
/// nada. Cuando aún no hay sesiones, se dice explícitamente en lugar de
/// mostrar ceros que parecerían datos.
Future<void> mostrarEstadisticas(BuildContext context) {
  final state = context.read<AppState>();
  final racha = state.rachaDias;
  final desdeInstalacion = state.diasDesdeInstalacion;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final s = dialogContext.watch<LocaleService>().strings;
      return AlertDialog(
        backgroundColor: AppColors.surfaceLowest,
        // El diálogo se puede abrir con escala de texto grande: que desplace
        // en lugar de desbordar.
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.prEstadisticasGenerales,
                style: AppType.bodySm.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              _Fila(
                icono: Icons.local_fire_department,
                etiqueta: s.prRachaActual,
                valor: s.rachaDias(racha),
              ),
              const SizedBox(height: 8),
              _Fila(
                icono: Icons.emoji_events_outlined,
                etiqueta: s.prMejorRacha,
                valor: s.rachaDias(state.rachaMaxima),
              ),
              const SizedBox(height: 8),
              _Fila(
                icono: Icons.event_available_outlined,
                etiqueta: s.prDiasDesdeInstalacionCorto,
                valor: '$desdeInstalacion',
                destacado: true,
              ),
              const SizedBox(height: 8),
              _Fila(
                icono: Icons.fitness_center,
                etiqueta: s.prSesiones,
                valor: '${state.historial.length}',
              ),
              const SizedBox(height: 8),
              _Fila(
                icono: Icons.military_tech_outlined,
                etiqueta: s.prNivel(state.nivel, state.nombreNivel),
                valor: '${state.xp} XP',
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.outline,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      s.prDiasDesdeInstalacion,
                      style: AppType.bodySm.copyWith(color: AppColors.outline),
                    ),
                  ),
                ],
              ),
              if (state.historial.isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  s.prRegistraPrimero,
                  style: AppType.bodySm.copyWith(color: AppColors.outline),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(s.homeCerrar),
          ),
        ],
      );
    },
  );
}

/// Fila etiqueta + valor del diálogo. La etiqueta separte para que con escala
/// de texto 2.0× no choque con el número.
class _Fila extends StatelessWidget {
  const _Fila({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    this.destacado = false,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icono,
          size: 18,
          color: destacado ? AppColors.primary : AppColors.outline,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            etiqueta,
            style: AppType.bodySm.copyWith(
              color: destacado ? AppColors.onSurface : AppColors.onSurfaceVariant,
              fontWeight: destacado ? FontWeight.w700 : null,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          valor,
          style: AppType.labelLg.copyWith(
            color: destacado ? AppColors.primary : AppColors.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}