import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/locale_service.dart';
import '../theme.dart';

/// Chip de racha compartido.
///
/// Muestra "N días" con un tamaño un poco mayor al original. El emoji 🔥 solo
/// se pinta cuando la racha alcanza o supera los 7 días (decisión del usuario);
/// por debajo de 7 el chip queda limpio, sin fueguito.
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
    return Container(
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
    );
  }
}