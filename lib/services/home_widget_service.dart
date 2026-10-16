import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../state/app_state.dart';
import '../state/avisos.dart';

/// Fase 6: puente entre el estado de la app y el widget nativo de home.
///
/// Cuando cambian datos reales (pasos del sensor, gasto activo, racha) se
/// envía un snapshot JSON al canal `fitpulse/home_widget`; el lado nativo lo
/// guarda y refresca el AppWidget. El envío está limitado para no escribir en
/// cada tick del sensor de pasos.
class HomeWidgetBridge with WidgetsBindingObserver {
  HomeWidgetBridge(this._appState) {
    WidgetsBinding.instance.addObserver(this);
    _appState.addListener(_onCambio);
  }

  final AppState _appState;

  DateTime _ultimaEscritura = DateTime.fromMillisecondsSinceEpoch(0);
  String? _ultimoSnapshot;

  /// Escribe el snapshot inmediatamente (al arrancar y al volver a la app).
  void sincronizarAhora() {
    _onCambio(forzar: true);
  }

  void _onCambio({bool forzar = false}) {
    final snap = _intentarSnapshot();
    if (snap == null) return;
    final ahora = DateTime.now();
    final cambioSignificativo = snap != _ultimoSnapshot;
    final desdeUltima = ahora.difference(_ultimaEscritura).inSeconds;
    // Refresco casi al instante: los cambios vienen de acciones del usuario
    // (un vaso de agua, un dato nuevo de Health Connect). Los pasos en vivo los
    // pinta el servicio nativo, así que aquí basta con no abusar del disco.
    if (forzar || (cambioSignificativo && desdeUltima >= 3)) {
      _ultimaEscritura = ahora;
      _ultimoSnapshot = snap;
      final baseDia = _appState.pasosBaseDia;
      unawaited(HomeWidgetService.actualizar(
        snap,
        base: baseDia?.base,
        baseFecha: baseDia?.fecha,
      ));
    }
  }

  /// Snapshot con datos REALES (o null si aún no hay sesión).
  String? _intentarSnapshot() {
    if (!_appState.isLoggedIn) return null;
    final ahora = DateTime.now();
    final fecha =
        '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}-'
        '${ahora.day.toString().padLeft(2, '0')}';
    return construirSnapshotWidget(
      pasos: _appState.pasosHoy,
      agua: _appState.aguaHoy,
      bpm: _appState.pulsoHoy,
      racha: _appState.rachaDias,
      fecha: fecha,
    );
  }

  /// Adopta la línea base de pasos del servicio nativo para que la app y el
  /// widget cuenten exactamente igual (mismo sensor, misma base).
  Future<void> sincronizarBaseNativa() async {
    final datos = await HomeWidgetService.leerBasePasos();
    if (datos == null) return;
    _appState.registrarBaseNativa(
      (datos['base'] as num?)?.toInt(),
      datos['fecha'] as String?,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(sincronizarBaseNativa());
      _onCambio(forzar: true);
    }
  }

  void cerrar() {
    WidgetsBinding.instance.removeObserver(this);
    _appState.removeListener(_onCambio);
  }
}

/// Canal nativo del widget de home.
class HomeWidgetService {
  static const MethodChannel _canal = MethodChannel('fitpulse/home_widget');

  /// Envía el [snapshot] JSON al lado nativo, que guarda y refresca el widget.
  /// Con [base]/[baseFecha] publica además la línea base de pasos del día para
  /// que el servicio en primer plano cuente exactamente igual que la app.
  static Future<bool> actualizar(
    String snapshot, {
    int? base,
    String? baseFecha,
  }) async {
    try {
      final ok = await _canal.invokeMethod<bool>('actualizar', {
        'datos': snapshot,
        'base': ?base,
        'baseFecha': ?baseFecha,
      });
      return ok ?? false;
    } catch (_) {
      return false; // Sin canal (tests/escritorio): inofensivo.
    }
  }

  /// Línea base de pasos del servicio nativo en primer plano: `{'base': int,
  /// 'fecha': 'yyyy-MM-dd'}` o `null` si el servicio aún no ha contado nada.
  /// La app la adopta para mostrar el mismo número real que el widget.
  static Future<Map<String, Object?>?> leerBasePasos() async {
    try {
      return await _canal.invokeMapMethod<String, Object?>('getPasosBase');
    } catch (_) {
      return null; // Sin canal (tests/escritorio): la app cuenta por su cuenta.
    }
  }
}