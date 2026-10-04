import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/locale_service.dart';
import '../state/app_state.dart';
import '../state/estado_salud.dart';
import '../theme.dart';

/// Colores semánticos de cada estado de salud, adaptados a claro/oscuro para
/// mantener contraste WCAG AA con el texto que se pinta encima.
Color colorEstadoSalud(EstadoSalud estado, Brightness brillo) {
  final oscuro = brillo == Brightness.dark;
  return switch (estado) {
    EstadoSalud.malo => oscuro ? const Color(0xFFFFB4AB) : const Color(0xFFB3261E),
    EstadoSalud.regular => oscuro ? const Color(0xFFFFC24B) : const Color(0xFF986100),
    EstadoSalud.bueno => oscuro ? const Color(0xFF6FFBBE) : const Color(0xFF0B7A4B),
    EstadoSalud.excelente => oscuro ? const Color(0xFF7FB3FF) : const Color(0xFF1D5FBF),
  };
}

/// Texto legible (blanco o negro) sobre [colorEstadoSalud] (WCAG AA).
Color onColorEstadoSalud(EstadoSalud estado, Brightness brillo) {
  final c = colorEstadoSalud(estado, brillo);
  return FitPalette.contraste(c, Colors.white) >= 4.5
      ? Colors.white
      : Colors.black;
}

/// Tarjeta "Estado de salud" (Home y Perfil).
///
/// Clasifica el día con las métricas REALES disponibles (IMC del perfil,
/// pasos del sensor, gasto activo/sueño/agua de Health Connect o manual).
/// Nunca inventa: con menos de 2 métricas con dato muestra "Sin datos
/// suficientes". Colores: malo rojo, regular amarillo, bueno verde,
/// excelente azul.
class EstadoSaludCard extends StatelessWidget {
  const EstadoSaludCard({super.key, this.compact = false});

  /// Versión reducida para Perfil (sin desglose por métrica).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    final state = context.watch<AppState>();
    final resultado = state.estadoSalud;
    final brillo = Theme.of(context).brightness;

    if (resultado.sinDatos) {
      return Container(
        padding: EdgeInsets.all(compact ? 12 : 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Icon(Icons.monitor_heart_outlined, size: 22, color: AppColors.outline),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.esSinDatos,
                    style: AppType.labelLg.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    strings.esSinDatosSub,
                    style: AppType.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final estado = resultado.estado!;
    final color = colorEstadoSalud(estado, brillo);
    final onColor = onColorEstadoSalud(estado, brillo);

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_heart_outlined, size: 22, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.esTitulo,
                      style: AppType.labelLg.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      strings.esSub,
                      style: AppType.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _labelEstado(strings, estado),
                  style: AppType.labelMd.copyWith(
                    color: onColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in resultado.metricas)
                  _MetricaChip(metrica: m, color: color),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${strings.esBasadoEn(resultado.metricas.length)} · '
              '${strings.esOrientativo}',
              style: AppType.labelSm.copyWith(color: AppColors.outline),
            ),
          ],
        ],
      ),
    );
  }

  String _labelEstado(AppStrings strings, EstadoSalud e) => switch (e) {
        EstadoSalud.malo => strings.esMalo,
        EstadoSalud.regular => strings.esRegular,
        EstadoSalud.bueno => strings.esBueno,
        EstadoSalud.excelente => strings.esExcelente,
      };
}

class _MetricaChip extends StatelessWidget {
  const _MetricaChip({required this.metrica, required this.color});

  final PuntuacionMetrica metrica;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    final nombre = switch (metrica.metrica) {
      MetricaEstado.imc => strings.esMetImc,
      MetricaEstado.pasos => strings.esMetPasos,
      MetricaEstado.gastoActivo => strings.esMetGasto,
      MetricaEstado.suenio => strings.esMetSuenio,
      MetricaEstado.agua => strings.esMetAgua,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            nombre,
            style: AppType.labelMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(width: 6),
          Text(
            metrica.detalle,
            style: AppType.labelMd.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          for (var i = 0; i < 3; i++)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < metrica.puntos
                    ? color
                    : AppColors.surfaceContainerHighest,
              ),
            ),
        ],
      ),
    );
  }
}