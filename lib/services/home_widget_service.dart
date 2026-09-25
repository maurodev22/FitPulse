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
    if (forzar || (cambioSignificativo && desdeUltima >= 10)) {
      _ultimaEscritura = ahora;
      _ultimoSnapshot = snap;
      unawaited(HomeWidgetService.actualizar(snap));
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
      calorias: _appState.gastoActivoConPermiso
          ? _appState.gastoActivoHoy
          : null,
      racha: _appState.rachaDias,
      fecha: fecha,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
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
  static Future<bool> actualizar(String snapshot) async {
    try {
      final ok = await _canal.invokeMethod<bool>('actualizar', {
        'datos': snapshot,
      });
      return ok ?? false;
    } catch (_) {
      return false; // Sin canal (tests/escritorio): inofensivo.
    }
  }
}