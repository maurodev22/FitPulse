import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/locale_service.dart';
import '../state/registro_diario.dart';
import '../theme.dart';

/// Gráfico de barras de cumplimiento de metas (día a día / semana a semana /
/// mes a mes) con datos REALES del histórico diario.
///
/// Cada barra es el porcentaje medio de metas cumplidas en ese tramo (0–100 %).
/// Los tramos sin dato se pintan vacíos: nunca se dibuja un cero inventado.
class CumplimientoChart extends StatefulWidget {
  const CumplimientoChart({
    super.key,
    required this.registros,
    required this.metas,
    required this.diasEntreno,
    required this.escala,
    this.onImportar,
  });

  /// Histórico diario ascendente (incluye hoy en vivo).
  final List<RegistroDiario> registros;

  /// Metas diarias reales del usuario.
  final MetasDia metas;

  /// Días de la semana con entreno planificado (1 = lunes … 7 = domingo).
  final Set<int> diasEntreno;

  /// Agrupación activa de las barras.
  final EscalaSerie escala;

  /// Rellena el histórico con Health Connect. Si es `null`, no se muestra el
  /// botón (por ejemplo, sin Health Connect disponible).
  final Future<int> Function()? onImportar;

  @override
  State<CumplimientoChart> createState() => _CumplimientoChartState();
}

class _CumplimientoChartState extends State<CumplimientoChart> {
  MetricaSerie _metrica = MetricaSerie.todo;
  int? _seleccionado;
  bool _importando = false;

  @override
  void didUpdateWidget(covariant CumplimientoChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.escala != widget.escala ||
        oldWidget.registros.length != widget.registros.length) {
      _seleccionado = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    final hoy = DateTime.now();
    final puntos = _serie(strings, hoy);
    final previos = _serie(
      strings,
      hoy.subtract(Duration(days: diasDeEscala(widget.escala))),
    );

    final conDato = puntos.where((p) => p.valor != null).toList();
    final media = conDato.isEmpty
        ? null
        : conDato.map((p) => p.valor!).reduce((a, b) => a + b) / conDato.length;
    final previoConDato = previos.where((p) => p.valor != null).toList();
    final mediaPrevia = previoConDato.isEmpty
        ? null
        : previoConDato.map((p) => p.valor!).reduce((a, b) => a + b) /
            previoConDato.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.prCumplimiento,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (media == null)
            Text(
              strings.prHistoricoVacio,
              style: AppType.bodySm.copyWith(color: AppColors.onSurfaceVariant),
            )
          else
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  '${(media * 100).round()} %',
                  style: AppType.headlineSm.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  strings.prDiasConDato(conDato.length),
                  style: AppType.labelSm.copyWith(color: AppColors.outline),
                ),
                if (mediaPrevia != null)
                  _Variacion(pct: ((media - mediaPrevia) * 100).round()),
              ],
            ),
          const SizedBox(height: 14),
          _Chips(
            seleccionada: _metrica,
            onChanged: (m) => setState(() {
              _metrica = m;
              _seleccionado = null;
            }),
          ),
          const SizedBox(height: 14),
          _Barras(
            puntos: puntos,
            seleccionado: _seleccionado,
            onTap: (i) => setState(() {
              _seleccionado = _seleccionado == i ? null : i;
            }),
          ),
          if (_seleccionado != null && _seleccionado! < puntos.length) ...[
            const SizedBox(height: 12),
            _Detalle(
              punto: puntos[_seleccionado!],
              metas: widget.metas,
              strings: strings,
            ),
          ],
          if (widget.onImportar != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _importando ? null : _importar,
                icon: _importando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync, size: 18),
                label: Text(strings.prImportarHealthConnect),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _importar() async {
    final importar = widget.onImportar;
    if (importar == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final strings = context.read<LocaleService>().strings;
    setState(() => _importando = true);
    final dias = await importar();
    if (!mounted) return;
    setState(() => _importando = false);
    messenger.showSnackBar(SnackBar(
      content: Text(
        dias > 0 ? strings.prImportadoDias(dias) : strings.prImportadoNada,
      ),
    ));
  }

  List<PuntoSerie> _serie(
    AppStrings strings,
    DateTime hasta,
  ) {
    const diasEs = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return construirSerie(
      registros: widget.registros,
      escala: widget.escala,
      hoy: hasta,
      metas: widget.metas,
      diasEntreno: widget.diasEntreno,
      metrica: _metrica,
      etiquetaDia: (d) => strings.diasIniciales[d.weekday - 1],
      etiquetaSemana: (l) => strings.prSemanaCorta(_semanaDelAnio(l)),
      etiquetaMes: (m) => strings.mesCorto(m.month),
      etiquetaLargaDia: (d) =>
          '${strings.diaNombre(diasEs[d.weekday - 1])} ${d.day}',
    );
  }
}

/// Número de semana del año (ISO aproximada, suficiente para la etiqueta).
int _semanaDelAnio(DateTime lunes) {
  final jueves = lunes.add(Duration(days: 4 - lunes.weekday));
  final inicio = DateTime(jueves.year, 1, 1);
  return ((jueves.difference(inicio).inDays) / 7).floor() + 1;
}

class _Variacion extends StatelessWidget {
  const _Variacion({required this.pct});

  final int pct;

  @override
  Widget build(BuildContext context) {
    final sube = pct >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (sube ? AppColors.primary : AppColors.error).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${sube ? '▲' : '▼'} ${pct.abs()} %',
        style: AppType.labelSm.copyWith(
          color: sube ? AppColors.primary : AppColors.error,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({required this.seleccionada, required this.onChanged});

  final MetricaSerie seleccionada;
  final ValueChanged<MetricaSerie> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    final nombres = <MetricaSerie, String>{
      MetricaSerie.todo: strings.prTodo,
      MetricaSerie.pasos: strings.prPasos,
      MetricaSerie.agua: strings.prAgua,
      MetricaSerie.calorias: strings.prCalorias,
      MetricaSerie.entreno: strings.prEntreno,
    };
    // Wrap (no scroll horizontal): con texto al 200 % los chips bajan de línea
    // en vez de desbordar, y no añade un Scrollable extra a la pantalla.
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final m in MetricaSerie.values)
          _Chip(
            texto: nombres[m]!,
            activo: m == seleccionada,
            onTap: () => onChanged(m),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.texto, required this.activo, required this.onTap});

  final String texto;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: activo,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: activo ? AppColors.primary : AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            texto,
            style: AppType.labelSm.copyWith(
              color: activo ? AppColors.onPrimary : AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _Barras extends StatelessWidget {
  const _Barras({
    required this.puntos,
    required this.seleccionado,
    required this.onTap,
  });

  final List<PuntoSerie> puntos;
  final int? seleccionado;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Stack(
        children: [
          // Línea de la meta (100 %).
          Positioned(
            left: 0,
            right: 0,
            top: 26,
            child: Container(height: 1, color: AppColors.outlineVariant),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < puntos.length; i++)
                Expanded(
                  child: _Barra(
                    punto: puntos[i],
                    activa: i == seleccionado,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra({
    required this.punto,
    required this.activa,
    required this.onTap,
  });

  final PuntoSerie punto;
  final bool activa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final valor = punto.valor;
    final pct = valor == null ? null : (valor * 100).round();
    const altoMax = 96.0;
    final alto = valor == null ? 6.0 : (altoMax * valor).clamp(6.0, altoMax);
    final color = valor == null
        ? AppColors.surfaceContainerHigh
        : Color.lerp(AppColors.primaryContainer, AppColors.primary, valor)!;

    return Semantics(
      button: true,
      selected: activa,
      label: pct == null
          ? '${punto.etiqueta}: sin dato'
          : '${punto.etiqueta}: $pct %',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                height: alto,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                    bottom: Radius.circular(2),
                  ),
                  border: activa
                      ? Border.all(color: AppColors.onSurface, width: 1.5)
                      : null,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 26,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    punto.etiqueta,
                    maxLines: 1,
                    style: AppType.labelSm.copyWith(
                      color: activa
                          ? AppColors.onSurface
                          : AppColors.outline,
                      fontWeight:
                          activa ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Detalle extends StatelessWidget {
  const _Detalle({
    required this.punto,
    required this.metas,
    required this.strings,
  });

  final PuntoSerie punto;
  final MetasDia metas;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final r = punto.detalle.length == 1 ? punto.detalle.first : null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            punto.etiquetaLarga,
            style: AppType.labelSm.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          if (punto.valor == null)
            Text(
              strings.prSinDato,
              style: AppType.bodySm.copyWith(color: AppColors.outline),
            )
          else if (r == null) ...[
            Text(
              strings.prMedia((punto.valor! * 100).round()),
              style: AppType.bodySm.copyWith(color: AppColors.onSurfaceVariant),
            ),
            Text(
              strings.prDiasConDato(punto.diasConDato),
              style: AppType.labelSm.copyWith(color: AppColors.outline),
            ),
          ],
          if (r != null) ...[
            const SizedBox(height: 8),
            _fila(
              strings.prPasos,
              r.pasos == null
                  ? strings.prSinDato
                  : strings.prDeMeta('${r.pasos}', '${metas.pasos}'),
              nota: r.pasosParciales ? strings.prDatoParcial : null,
            ),
            _fila(
              strings.prAgua,
              r.agua == null
                  ? strings.prSinDato
                  : strings.prDeMeta(
                      '${r.agua!.toStringAsFixed(1)} L',
                      '${metas.agua.toStringAsFixed(1)} L'),
            ),
            _fila(
              strings.prCalorias,
              r.kcal == null
                  ? strings.prSinDato
                  : strings.prDeMeta(
                      '${r.kcal!.round()}', '${metas.calorias.round()}'),
            ),
            _fila(
              strings.prEntreno,
              r.entrenoMin == null
                  ? strings.prSinDato
                  : (r.entrenoMin! > 0
                      ? strings.prMinEntreno(r.entrenoMin!)
                      : strings.prEntrenoNo),
            ),
            if (r.pesoKg != null)
              _fila(strings.prPesoCorporal,
                  '${r.pesoKg!.toStringAsFixed(1)} kg'),
          ],
        ],
      ),
    );
  }

  Widget _fila(String etiqueta, String valor, {String? nota}) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              etiqueta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.labelSm.copyWith(color: AppColors.outline),
            ),
          ),
          Flexible(
            child: Text(
              valor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: AppType.labelSm.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (nota != null) ...[
            const SizedBox(width: 6),
            Text(
              '· $nota',
              maxLines: 1,
              style: AppType.labelSm.copyWith(color: AppColors.secondaryFixedDim),
            ),
          ],
        ],
      ),
    );
  }
}
