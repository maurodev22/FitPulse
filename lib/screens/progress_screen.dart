import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/locale_service.dart';
import '../state/app_state.dart';
import '../state/registros.dart';
import '../state/workout.dart';
import '../services/ads_service.dart';
import '../services/config_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/racha_chip.dart';
import '../widgets/sesion_row.dart';
import 'historial_sesiones_screen.dart';

/// Progreso y Rendimiento: métricas REALES del dispositivo.
///
/// Regla del proyecto: nada de números inventados. Peso e IMC vienen del
/// perfil; grasa, gasto activo y tiempo activo vienen de Health Connect (o
/// "—" si no hay dato); sesiones, racha, retos e insignias se calculan del
/// historial real de entrenamiento.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  /// Ventana activa del panel de evolución (Semanal / Mensual / Año).
  PeriodoRecorte _periodo = PeriodoRecorte.semanal;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final strings = context.watch<LocaleService>().strings;
    final profile = state.profile;
    final hayHistorial = state.historial.isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _ProgressHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        strings.prEvolucion,
                        maxLines: 1,
                        style: AppType.headlineLg.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hayHistorial
                        ? strings.prRachaNivel(state.rachaDias, state.nivel)
                        : strings.prRegistraPrimero,
                    style: AppType.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  _PeriodTabs(
                    seleccionado: _periodo,
                    onChanged: (p) => setState(() => _periodo = p),
                  ),
                  const SizedBox(height: 12),
                  _buildResumenPeriodo(state, strings),
                  const SizedBox(height: 12),
                  _buildPesoSeccion(context, state, strings),
                  const SizedBox(height: 12),
                  _buildRepeticionesSeccion(state, strings),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SmallStat(
                          icon: Icons.opacity,
                          label: strings.prGrasa,
                          value: state.grasaHoy?.toStringAsFixed(1) ?? '—',
                          unit: state.grasaHoy != null ? '%' : '',
                          trend: _textoTrend(
                            context,
                            strings,
                            conPermiso: state.grasaConPermiso,
                            valor: state.grasaHoy,
                          ),
                          trendColor: state.grasaHoy != null
                              ? AppColors.primary
                              : AppColors.outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SmallStat(
                          icon: Icons.insights,
                          label: strings.prImcIndex,
                          value: profile.imcFormateado,
                          unit: '',
                          trend: strings.deTuPerfil,
                          trendColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SmallStat(
                          icon: Icons.local_fire_department,
                          label: strings.prGastoActivo,
                          value: state.gastoActivoHoy?.round().toString() ?? '—',
                          unit: state.gastoActivoHoy != null ? 'kcal' : '',
                          trend: _textoTrend(
                            context,
                            strings,
                            conPermiso: state.gastoActivoConPermiso,
                            valor: state.gastoActivoHoy,
                          ),
                          trendColor: state.gastoActivoHoy != null
                              ? AppColors.primary
                              : AppColors.outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SmallStat(
                          icon: Icons.schedule,
                          label: strings.prTiempoActivo,
                          value: state.tiempoActivoMin?.toString() ?? '—',
                          unit: state.tiempoActivoMin != null ? 'min' : '',
                          trend: _textoActivo(
                            context,
                            strings,
                            valor: state.tiempoActivoMin,
                          ),
                          trendColor: state.tiempoActivoMin != null
                              ? AppColors.primary
                              : AppColors.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _textoFuenteMetrricas(context, strings),
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Inter',
                      color: AppColors.outline,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRetoCard(state, strings),
                  const SizedBox(height: 12),
                  _buildNivelCard(state, strings),
                  const SizedBox(height: 12),
                  _buildRecompensaAnuncio(context),
                  const SizedBox(height: 12),
                  _buildSemanaCard(state, profile.diasEntrenamiento.length, strings),
                  const SizedBox(height: 12),
                  _ConsistenciaBanner(
                    porcentaje: hayHistorial
                        ? (state.diasEntrenadosSemana /
                                (profile.diasEntrenamiento.isEmpty
                                    ? 5
                                    : profile.diasEntrenamiento.length))
                            .clamp(0.0, 1.0)
                        : 0.0,
                    hayHistorial: hayHistorial,
                  ),
                  const SizedBox(height: 20),
                  SectionHeader(
                    title: strings.prSesionesRecientes,
                    actionLabel: strings.prVerTodo,
                    onAction: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const HistorialSesionesScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSesiones(state, strings),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _textoTrend(
    BuildContext context,
    AppStrings strings, {
    required bool conPermiso,
    required Object? valor,
  }) {
    if (valor != null) return strings.healthConnect;
    if (conPermiso) return strings.prSinDatosHoy;
    if (context.read<AppState>().healthConnectDisponible) {
      return strings.prConcedePermiso;
    }
    return strings.requiereHealthConnect;
  }

  /// Nota honesta del "Tiempo Activo": el paquete `health` 13.3.2 solo expone
  /// EXERCISE_TIME en iOS, así que en Android nunca hay dato → siempre "—".
  String _textoActivo(BuildContext context, AppStrings strings, {required Object? valor}) {
    if (valor != null) return strings.healthConnect;
    return strings.prSoloIOS;
  }

  String _textoFuenteMetrricas(BuildContext context, AppStrings strings) {
    final state = context.read<AppState>();
    if (!state.healthConnectDisponible) {
      return strings.prFuente1;
    }
    final concedidas = [
      if (state.grasaConPermiso) strings.prMetricaGrasa,
      if (state.gastoActivoConPermiso) strings.prMetricaGastoActivo,
    ];
    if (concedidas.isEmpty) {
      return strings.prFuente2;
    }
    return strings.prFuente3(concedidas.join(', '));
  }

  /// Sección Fase 9: peso corporal con registro semanal real e historial.
  Widget _buildPesoSeccion(BuildContext context, AppState state, AppStrings strings) {
    final registros = state.historialPeso;
    final ultimo = registros.isEmpty ? null : registros.first;
    final lunes = _lunesDe(DateTime.now());
    final deEstaSemana = registros.where((r) => r.lunes == lunes).toList();
    final valorInicial = deEstaSemana.isNotEmpty
        ? deEstaSemana.first.pesoKg
        : (state.profile.pesoKg > 0 ? state.profile.pesoKg : 70.0);

    Future<void> registrar() async {
      final messenger = ScaffoldMessenger.of(context);
      final appState = context.read<AppState>();
      final kg = await _dialogoRegistrarPeso(
        context,
        strings,
        inicial: valorInicial,
      );
      if (kg == null) return;
      await appState.registrarPeso(kg);
      messenger.showSnackBar(SnackBar(content: Text(strings.prPesoRegistrado(kg))));
    }

    String? delta;
    if (registros.length >= 2) {
      final anterior = registros[1].pesoKg;
      final diff = ultimo!.pesoKg - anterior;
      delta = diff > 0 ? '+${diff.toStringAsFixed(1)} kg' : '${diff.toStringAsFixed(1)} kg';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_weight, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.prPesoCorporal,
                  style: AppType.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: registrar,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: const Size(0, 32),
              ),
              child: Text(
                strings.prRegistrarPesoBtn,
                style: AppType.labelMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Text(
            strings.prRegistraPeso,
            style: AppType.bodySm.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                (ultimo?.pesoKg ?? state.profile.pesoKg).toStringAsFixed(1),
                style: AppType.metricVal.copyWith(color: AppColors.onSurface),
              ),
              const SizedBox(width: 4),
              Text(
                strings.prKg,
                style: AppType.labelMd.copyWith(color: AppColors.outline),
              ),
              if (delta != null) ...[
                const SizedBox(width: 10),
                Text(
                  delta,
                  style: AppType.labelMd.copyWith(
                    color: delta.startsWith('-') ? AppColors.primary : AppColors.outline,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          if (ultimo == null) ...[
            const SizedBox(height: 6),
            Text(
              strings.prPesoDePerfil,
              style: AppType.bodySm.copyWith(color: AppColors.outline),
            ),
            const SizedBox(height: 12),
            Text(
              strings.prSinPesoTodavia,
              style: AppType.bodySm.copyWith(color: AppColors.outline),
            ),
          ] else ...[
            const SizedBox(height: 12),
            _MiniWeightChart(
              historial: registros,
              label: _etiquetaSemana(lunes),
              semanas: _semanasPeso(_periodo),
            ),
            const SizedBox(height: 12),
            _buildHistorialPeso(registros, strings),
          ],
        ],
      ),
    );
  }

  Widget _buildHistorialPeso(List<RegistroPeso> registros, AppStrings strings) {
    final recientes = registros.take(4).toList();
    return Column(
      children: [
        for (final r in recientes) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 13, color: AppColors.outline),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${r.fecha.day}/${r.fecha.month}/${r.fecha.year}',
                    style: AppType.labelMd.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
                Text(
                  '${r.pesoKg.toStringAsFixed(1)} ${strings.prKg}',
                  style: AppType.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Diálogo de registro de peso con paso de 0,1 kg (rango 20–300 kg).
  Future<double?> _dialogoRegistrarPeso(
    BuildContext context,
    AppStrings strings, {
    required double inicial,
  }) {
    final lunes = _lunesDe(DateTime.now());
    final control = ValueNotifier<double>(inicial);
    return showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceLowest,
        title: Text(
          strings.prPesoDialogTitulo,
          style: AppType.headlineSm.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.prSemanaDel(_etiquetaSemana(lunes)),
              style: AppType.labelMd.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              strings.prPesoDialogSemana,
              style: AppType.bodySm.copyWith(color: AppColors.outline),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<double>(
              valueListenable: control,
              builder: (_, valor, _) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StepperBtn(icon: Icons.remove, onTap: () => control.value = (valor - 0.1).clamp(20.0, 300.0)),
                  _StepperBtn(icon: Icons.remove_circle_outline, onTap: () => control.value = (valor - 1).clamp(20.0, 300.0)),
                  Text(
                    '${valor.toStringAsFixed(1)} ${strings.prKg}',
                    style: AppType.metricVal.copyWith(color: AppColors.onSurface),
                  ),
                  _StepperBtn(icon: Icons.add_circle_outline, onTap: () => control.value = (valor + 1).clamp(20.0, 300.0)),
                  _StepperBtn(icon: Icons.add, onTap: () => control.value = (valor + 0.1).clamp(20.0, 300.0)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              strings.prCancelar,
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(control.value),
            child: Text(
              strings.prGuardar,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  /// Sección Fase 9: repeticiones reales registradas al terminar ejercicios.
  Widget _buildRepeticionesSeccion(AppState state, AppStrings strings) {
    final recientes = state.historialReps.take(5).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.onetwothree, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.prRepsRegistradas,
                  style: AppType.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (recientes.isEmpty)
            Text(
              strings.prSinRepsTodavia,
              style: AppType.bodySm.copyWith(color: AppColors.outline),
            )
          else
            for (final r in recientes) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${r.fecha.day}/${r.fecha.month} · ${r.ejercicio}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.labelMd.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                    Text(
                      '${r.reps} ${strings.prRepeticiones.toLowerCase()}',
                      style: AppType.labelMd.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }

  DateTime _lunesDe(DateTime d) => DateTime(d.year, d.month, d.day)
      .subtract(Duration(days: d.weekday - 1));

  String _etiquetaSemana(DateTime lunes) {
    final domingo = lunes.add(const Duration(days: 6));
    return '${lunes.day}/${lunes.month} – ${domingo.day}/${domingo.month}';
  }

  Widget _buildRetoCard(AppState state, AppStrings strings) {
    final objetivo = state.retoObjetivo;
    final progreso = state.retoProgreso;
    final completado = state.retoCompletado;
    final siguiente = objetivo == 3 ? 5 : (objetivo == 5 ? 7 : 7);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.prRetoActual,
                  style: AppType.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                completado
                    ? strings.prCompletado
                    : strings.prRetoDias(progreso, objetivo),
                style: AppType.labelMd.copyWith(
                  color: completado ? AppColors.primary : AppColors.outline,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            completado
                ? strings.prRetoCompletado(objetivo, siguiente)
                : strings.prRetoActivo(objetivo),
            style: AppType.bodySm.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (progreso / objetivo).clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: AppColors.surfaceContainer,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNivelCard(AppState state, AppStrings strings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.prNivel(state.nivel, state.nombreNivel),
                  style: AppType.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                strings.prPts(state.xp),
                style: AppType.labelMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            strings.prPtsParaNivel(300 - (state.xp % 300), state.nivel + 1),
            style: AppType.bodySm.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: state.progresoNivel,
              minHeight: 7,
              backgroundColor: AppColors.surfaceContainer,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta del anuncio recompensado (Fase 3): +25 PTs una vez por día.
  ///
  /// Se oculta si el usuario tiene Premium. Siempre usa el ID de prueba de
  /// AdMob; el cobro real requiere cuenta fuera de Cuba (ver PLAN.md).
  Widget _buildRecompensaAnuncio(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    final config = context.watch<ConfigService>();
    if (config.premiumEnabled) return const SizedBox.shrink();

    final state = context.watch<AppState>();
    final disponible = state.recompensaAnuncioDisponibleHoy;

    Future<void> verAnuncio() async {
      final messenger = ScaffoldMessenger.of(context);
      final appState = context.read<AppState>();
      await mostrarAnuncioRecompensado(
        context: context,
        onRecompensa: () async {
          final aplicada = await appState.aplicarRecompensaAnuncio();
          messenger.showSnackBar(SnackBar(
            content: Text(aplicada
                ? strings.prPTsGanados(AppState.ptsRecompensaAnuncio)
                : strings.prRecompensaYaRecibida),
          ));
        },
        onError: (mensaje) {
          messenger.showSnackBar(SnackBar(content: Text(mensaje)));
        },
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.play_circle_outline, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.prAnuncioRecompensado,
                  style: AppType.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                strings.prPTs(AppState.ptsRecompensaAnuncio),
                style: AppType.labelMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            disponible ? strings.prAnuncioGana : strings.prAnuncioRecibida,
            style: AppType.bodySm.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: disponible ? verAnuncio : null,
              child: Text(
                disponible ? strings.prVerAnuncio : strings.prRecibidoHoy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Resumen REAL de la ventana activa (sesiones, minutos, kcal y racha máx).
  Widget _buildResumenPeriodo(AppState state, AppStrings strings) {
    final r = resumenPeriodo(state.historial, _diasPeriodo(_periodo));
    // Etiqueta honesta de la ventana activa: hace perceptible el filtrado incluso
    // cuando las cifras coinciden en ventanas con pocos datos.
    final etiquetaVentana = strings.prVentana(_diasPeriodo(_periodo));
    if (r.sesiones == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(radius: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EtiquetaVentana(texto: etiquetaVentana),
            const SizedBox(height: 8),
            Text(
              strings.prSinSesionesPeriodo,
              style: AppType.labelMd.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              strings.prSinSesionesHint,
              style: AppType.bodySm.copyWith(color: AppColors.outline),
            ),
          ],
        ),
      );
    }
    final stats = <(IconData, String, String)>[
      (Icons.fitness_center, '${r.sesiones}', strings.prSesiones),
      (Icons.schedule, '${r.minutos}', strings.prMinutos),
      (Icons.local_fire_department, '${r.kcal}', 'kcal'),
      (Icons.whatshot, '${r.rachaMaxima}', strings.prRachaMax),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EtiquetaVentana(texto: etiquetaVentana),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final (icono, valor, etiqueta) in stats)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icono, size: 18, color: AppColors.primary),
                      const SizedBox(height: 6),
                      Text(
                        valor,
                        style: AppType.labelLg.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        etiqueta,
                        style: AppType.labelSm.copyWith(color: AppColors.outline),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSemanaCard(AppState state, int diasMeta, AppStrings strings) {
    final entrenados = state.diasSemanaEntrenados;
    final total = diasMeta > 0 ? diasMeta : 5;
    final dias = strings.diasIniciales;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.prSemana,
                  style: AppType.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                strings.prSemanaDias(state.diasEntrenadosSemana, total),
                style: AppType.labelMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < dias.length; i++)
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: entrenados.contains(i)
                              ? AppColors.primary
                              : AppColors.surfaceContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          entrenados.contains(i) ? Icons.check : Icons.remove,
                          size: 14,
                          color: entrenados.contains(i)
                              ? AppColors.onPrimary
                              : AppColors.outline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dias[i],
                        textAlign: TextAlign.center,
                        style: AppType.labelSm.copyWith(color: AppColors.outline),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Icon(Icons.history, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  state.minutosEntrenadosSemana > 0
                      ? strings.prMinSemana(state.minutosEntrenadosSemana)
                      : strings.prSinSesionesSemana,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.labelMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSesiones(AppState state, AppStrings strings) {
    final recientes = state.historial.take(3).toList();
    if (recientes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(radius: 16),
        child: Column(
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
      );
    }
    return Column(
      children: [
        for (final s in recientes) SesionRow.fromSesion(s, strings),
      ],
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final strings = context.watch<LocaleService>().strings;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(color: AppColors.surface),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.navProgress,
                  style: AppType.headlineSm.copyWith(fontWeight: FontWeight.w700, height: 1.1),
                ),
                const SizedBox(height: 2),
                Text(
                  state.entrenadoHoy ? strings.prDiaCompletado : strings.listoParaEntrenar,
                  style: AppType.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          RachaChip(racha: state.rachaDias, borde: true),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.notifications_outlined, size: 22, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({required this.seleccionado, required this.onChanged});

  final PeriodoRecorte seleccionado;
  final ValueChanged<PeriodoRecorte> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final p in PeriodoRecorte.values)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(p),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p == seleccionado ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _nombrePeriodo(p, strings),
                    style: AppType.labelMd.copyWith(
                      color: p == seleccionado ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.trend,
    this.trendColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final String trend;
  final Color? trendColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppType.labelSm.copyWith(
              color: AppColors.outline,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.headlineSm.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: AppType.labelSm.copyWith(color: AppColors.outline),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            trend,
            style: AppType.labelSm.copyWith(
              color: trendColor ?? AppColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniWeightChart extends StatelessWidget {
  const _MiniWeightChart({required this.historial, this.label, this.semanas = 7});

  /// Historial REAL de peso (más reciente primero en la lista de estado).
  final List<RegistroPeso> historial;
  final String? label;

  /// Ventana de barras según el período activo (7 / 13 / 52 semanas).
  final int semanas;

  @override
  Widget build(BuildContext context) {
    if (historial.length < 2) {
      return Text(
        label ?? '',
        style: AppType.labelSm.copyWith(color: AppColors.outline),
      );
    }
    // De más antigua a más reciente, últimas N semanas (ventana del período).
    final barras = historial.reversed.take(semanas).toList().reversed.toList();
    var min = barras.first.pesoKg, max = barras.first.pesoKg;
    for (final b in barras) {
      if (b.pesoKg < min) min = b.pesoKg;
      if (b.pesoKg > max) max = b.pesoKg;
    }
    final rango = (max - min).abs() < 1.0 ? 1.0 : (max - min);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 48,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < barras.length; i++)
                Container(
                  width: 22,
                  height: 8 + 40 * (barras[i].pesoKg - min) / rango,
                  decoration: BoxDecoration(
                    color: i == barras.length - 1
                        ? AppColors.primary
                        : AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
            ],
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 6),
          Text(
            label!,
            style: AppType.labelSm.copyWith(color: AppColors.outline),
          ),
        ],
      ],
    );
  }
}

/// Botón redondo del selector de peso (pasos de 0,1 / 1 kg).
class _StepperBtn extends StatelessWidget {
  const _StepperBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 22, color: AppColors.primary),
      ),
    );
  }
}

class _ConsistenciaBanner extends StatelessWidget {
  const _ConsistenciaBanner({required this.porcentaje, required this.hayHistorial});

  final double porcentaje;
  final bool hayHistorial;

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    final pct = (porcentaje * 100).round();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gradienteInicio,
            AppColors.gradienteIntermedio,
            AppColors.gradienteFin,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium, color: AppColors.onGradienteAcento, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hayHistorial
                      ? strings.prConsistenciaTitulo
                      : strings.prEmpiezaRacha,
                  style: AppType.headlineSm.copyWith(
                    color: AppColors.onGradiente,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            hayHistorial
                ? strings.prConsistenciaPct(pct)
                : strings.prActivaRacha,
            style: AppType.bodySm.copyWith(color: AppColors.onGradienteVariant),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: porcentaje.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.onGradienteAcento.withValues(alpha: 0.2),
              color: AppColors.onGradienteAcento,
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration({double radius = 20}) {
  return BoxDecoration(
    color: AppColors.surfaceLowest,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
    boxShadow: [
      BoxShadow(
        color: AppColors.primaryContainer.withValues(alpha: 0.06),
        blurRadius: 20,
        offset: const Offset(0, 4),
        spreadRadius: -2,
      ),
    ],
  );
}

/// Ventana de tiempo del panel de evolución de Progreso.
enum PeriodoRecorte { semanal, mensual, anual }

/// Días que cubre cada período (incluyendo hoy).
int _diasPeriodo(PeriodoRecorte p) => switch (p) {
      PeriodoRecorte.semanal => 7,
      PeriodoRecorte.mensual => 30,
      PeriodoRecorte.anual => 365,
    };

/// Semanas de barras de peso que muestra cada período (≈ trimestre/año).
int _semanasPeso(PeriodoRecorte p) => switch (p) {
      PeriodoRecorte.semanal => 7,
      PeriodoRecorte.mensual => 13,
      PeriodoRecorte.anual => 52,
    };

/// Etiqueta del período activo (Semanal / Mensual / Año).
String _nombrePeriodo(PeriodoRecorte p, AppStrings strings) => switch (p) {
      PeriodoRecorte.semanal => strings.prPeriodoSemanal,
      PeriodoRecorte.mensual => strings.prPeriodoMensual,
      PeriodoRecorte.anual => strings.prPeriodoAno,
    };

/// Resumen de actividad REAL dentro de los últimos [dias] días.
///
/// Fecha de corte = hoy - (dias - 1), de modo que "semanal" cubre 7 días
/// incluyendo hoy. Nada se inventa: todo sale del historial real.
({int sesiones, int minutos, int kcal, int rachaMaxima}) resumenPeriodo(
  List<WorkoutSession> historial,
  int dias,
) {
  final ahora = DateTime.now();
  final corte =
      DateTime(ahora.year, ahora.month, ahora.day).subtract(Duration(days: dias - 1));
  var sesiones = 0, minutos = 0, kcal = 0;
  final diasConSesion = <DateTime>{};
  for (final s in historial) {
    if (s.fecha.isBefore(corte)) continue;
    sesiones++;
    minutos += s.duracionMin;
    kcal += s.calorias;
    diasConSesion.add(DateTime(s.fecha.year, s.fecha.month, s.fecha.day));
  }
  final lista = diasConSesion.toList()..sort();
  var rachaMax = 0, actual = 0;
  DateTime? anterior;
  for (final d in lista) {
    actual = (anterior != null && d.difference(anterior).inDays == 1) ? actual + 1 : 1;
    if (actual > rachaMax) rachaMax = actual;
    anterior = d;
  }
  return (sesiones: sesiones, minutos: minutos, kcal: kcal, rachaMaxima: rachaMax);
}

/// Etiqueta compacta de la ventana activa (p. ej. "Últimos 7 días") que hace
/// perceptible el filtrado de período incluso con pocos datos.
class _EtiquetaVentana extends StatelessWidget {
  const _EtiquetaVentana({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.secondaryContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.date_range, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                texto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.labelMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
