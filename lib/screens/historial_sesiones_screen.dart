import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/locale_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/sesion_row.dart';

/// Historial COMPLETO de sesiones reales (más reciente primero).
///
/// Corrección L1: el "Ver todo" de Progreso ahora abre esta pantalla con todo
/// [AppState.historial], en lugar de no hacer nada.
class HistorialSesionesScreen extends StatelessWidget {
  const HistorialSesionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    final state = context.watch<AppState>();
    final historial = state.historial;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          strings.prHistorialTitulo,
          style: AppType.headlineSm.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: historial.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fitness_center, size: 28, color: AppColors.outline),
                      const SizedBox(height: 8),
                      Text(
                        strings.prSinSesiones,
                        style: AppType.labelMd.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.prSinSesionesHint,
                        textAlign: TextAlign.center,
                        style: AppType.bodySm.copyWith(color: AppColors.outline),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: historial.length,
                itemBuilder: (context, i) =>
                    SesionRow.fromSesion(historial[i], strings),
              ),
      ),
    );
  }
}