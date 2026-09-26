/// Consentimiento publicitario UE (Fase 8.3) sobre el SDK UMP de Google.
///
/// El SDK de UMP ya viene embebido en play-services-ads (25.4.0), que es lo
/// que usa `google_mobile_ads`, por lo que NO hace falta `google_ump` (que no
/// se puede descargar desde Cuba: pub.dev da 403 y el mirror no lo tiene).
/// El puente nativo vive en `MainActivity.kt` (canal `fitpulse/consent`).
///
/// Reglas de honestidad:
/// - Nunca lanza: cualquier fallo (sin red a Google, sin soporte del SDK en
///   el dispositivo, tests sin canal nativo) degrada a [ConsentEstado.error].
/// - Si el consentimiento no se puede resolver, NO se muestran anuncios reales
///   (ni banner, ni recompensado, ni app open).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Estado del consentimiento según el SDK UMP.
enum ConsentEstado {
  /// No se sabe todavía (o dispositivo fuera de la UE sin formulario).
  desconocido,

  /// Consentimiento obtenido (EEA) o región no-EEE con consentimiento.
  obtenido,

  /// El formulario de consentimiento está disponible y debe mostrarse (UE/EEE).
  requerido,

  /// El SDK UMP falló de forma técnica/red: no se puede pedir ningún anuncio.
  error,
}

class ConsentService {
  ConsentService();

  static const MethodChannel _canal = MethodChannel('fitpulse/consent');

  ConsentEstado estado = ConsentEstado.desconocido;

  /// El SDK UMP permite mostrar anuncios (canRequestAds == true).
  bool puedeMostrarAnuncios = false;

  /// true si el fallo fue técnico/red (p. ej. sin red a Google desde Cuba).
  /// En desarrollo esto permite reservar la zona de banner (placeholder
  /// honesto) aunque no se carguen anuncios reales.
  bool errorTecnico = false;

  /// Solicita la actualización de consentimiento UMP. Nunca lanza.
  Future<void> iniciar() async {
    try {
      final resp = await _canal.invokeMapMethod<String, dynamic>('request');
      if (resp == null) {
        estado = ConsentEstado.error;
        errorTecnico = true;
        return;
      }
      if (resp['ok'] == true) {
        puedeMostrarAnuncios = resp['canRequestAds'] == true;
        estado = switch (resp['status']) {
          'OBTAINED' => ConsentEstado.obtenido,
          'REQUIRED' => ConsentEstado.requerido,
          _ => ConsentEstado.desconocido,
        };
      } else {
        estado = ConsentEstado.error;
        errorTecnico = true;
        debugPrint('[FitPulse/Consent] UMP no resuelto: '
            'código ${resp['code']} ${resp['message']}');
      }
    } catch (e) {
      // Sin canal nativo (flutter test) o excepción de plataforma.
      estado = ConsentEstado.error;
      errorTecnico = true;
      debugPrint('[FitPulse/Consent] sin soporte UMP: $e');
    }
  }

  /// Muestra el formulario de consentimiento si la UE/EEE lo requiere.
  /// Solo se llama cuando [estado] == [ConsentEstado.requerido]. Nunca lanza.
  Future<void> mostrarFormularioSiRequiere() async {
    if (estado != ConsentEstado.requerido) return;
    try {
      await _canal.invokeMethod('loadAndShowIfRequired');
    } catch (e) {
      // No se pudo mostrar: la app sigue honesta (sin anuncios).
      debugPrint('[FitPulse/Consent] sin formulario UMP: $e');
    }
  }

  /// Relee `canRequestAds` tras cerrar el formulario. Nunca lanza.
  Future<void> actualizarTrasFormulario() async {
    try {
      puedeMostrarAnuncios =
          await _canal.invokeMethod<bool>('canRequestAds') ?? false;
    } catch (_) {
      puedeMostrarAnuncios = false;
    }
  }
}