import 'package:flutter/material.dart';

import '../theme.dart';

/// Rueda giratoria de números estilo drum-roll para Edad, Peso y Altura.
///
/// Usa `ListWheelScrollView` con física de paso fijo: el usuario hace girar
/// el tambor sobre un rango finito y recibe el valor seleccionado mediante
/// `onChanged`.
class WheelNumberPicker extends StatelessWidget {
  const WheelNumberPicker({
    super.key,
    required this.min,
    required this.max,
    required this.step,
    required this.semanticsUnit,
    required this.initialValue,
    required this.onChanged,
    this.decimals = 0,
  });

  /// Límites y paso de la rueda.
  final double min;
  final double max;
  final double step;

  /// Unidad legible (edad, kg, m) para accesibilidad.
  final String semanticsUnit;

  /// Valor mostrado al abrir la rueda (debe pertenecer a la serie).
  final double initialValue;

  /// Callback con el valor seleccionado.
  final ValueChanged<double> onChanged;

  /// Decimales a mostrar (0 edad, 1 peso, 2 altura).
  final int decimals;

  @override
  Widget build(BuildContext context) {
    final count = ((max - min) / step).round() + 1;
    final initialIndex = ((initialValue - min) / step)
        .round()
        .clamp(0, count - 1)
        .toInt();
    final itemExtent = 44.0;

    return SizedBox(
      height: itemExtent * 4.5,
      child: ListWheelScrollView(
        itemExtent: itemExtent,
        // Sin lupa: el magnifier (useMagnifier) distorsiona el texto y deja
        // una línea blanca al hacer scroll/rotar la rueda.
        useMagnifier: false,
        magnification: 1.0,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) => onChanged(min + index * step),
        controller: FixedExtentScrollController(initialItem: initialIndex),
        children: List.generate(count, (i) {
          final value = (min + i * step);
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${value.toStringAsFixed(decimals)} $semanticsUnit',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.headlineSm.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }),
      ),
    );
  }
}