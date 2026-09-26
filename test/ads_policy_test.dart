import 'package:flutter_test/flutter_test.dart';

import 'package:fitpulse/services/ads_service.dart';

void main() {
  group('adsPermitidos', () {
    test('solo con ads activos, sin Premium y con consentimiento', () {
      expect(
        adsPermitidos(
          adsEnabled: true,
          premium: false,
          consentimientoOk: true,
        ),
        isTrue,
      );
    });

    test('sin consentimiento → sin anuncios', () {
      expect(
        adsPermitidos(
          adsEnabled: true,
          premium: false,
          consentimientoOk: false,
        ),
        isFalse,
      );
    });

    test('con ads desactivados → sin anuncios', () {
      expect(
        adsPermitidos(
          adsEnabled: false,
          premium: false,
          consentimientoOk: true,
        ),
        isFalse,
      );
    });

    test('con Premium → sin anuncios', () {
      expect(
        adsPermitidos(
          adsEnabled: true,
          premium: true,
          consentimientoOk: true,
        ),
        isFalse,
      );
    });
  });

  group('decisionAppOpen', () {
    final min = const Duration(seconds: 30);

    bool decide({
      bool consentimientoOk = true,
      bool anuncioALaVista = false,
      bool ejercicioActivo = false,
      int mostradosEnSesion = 0,
      Duration pausaPrevia = const Duration(seconds: 45),
      Duration? desdeUltimaVez,
    }) =>
        decisionAppOpen(
          consentimientoOk: consentimientoOk,
          anuncioALaVista: anuncioALaVista,
          ejercicioActivo: ejercicioActivo,
          mostradosEnSesion: mostradosEnSesion,
          pausaPrevia: pausaPrevia,
          desdeUltimaVez: desdeUltimaVez,
        );

    test('todo en orden → se muestra', () {
      expect(decide(), isTrue);
    });

    test('sin consentimiento → nunca', () {
      expect(decide(consentimientoOk: false), isFalse);
    });

    test('con otro anuncio a la vista → no', () {
      expect(decide(anuncioALaVista: true), isFalse);
    });

    test('con ejercicio en curso → no interrumpe', () {
      expect(decide(ejercicioActivo: true), isFalse);
    });

    test('límite de sesión alcanzado → no', () {
      expect(decide(mostradosEnSesion: 1), isFalse);
    });

    test('pausa previa corta (arranque frío/volver rápido) → no', () {
      expect(decide(pausaPrevia: const Duration(seconds: 29)), isFalse);
      expect(decide(pausaPrevia: min), isTrue);
    });

    test('cooldown aún no cumplido → no', () {
      expect(
        decide(desdeUltimaVez: const Duration(seconds: 59)),
        isFalse,
      );
      expect(
        decide(desdeUltimaVez: const Duration(seconds: 61)),
        isTrue,
      );
    });
  });

  group('AdsPermiso', () {
    test('resetAdsPermisoParaTests deja la puerta cerrada', () {
      AdsPermiso.consentimientoOk = true;
      AdsPermiso.consentimientoErrorSinRed = true;
      AdsPermiso.ejercicioActivo = true;
      AdsPermiso.anuncioALaVista = true;
      resetAdsPermisoParaTests();
      expect(AdsPermiso.consentimientoOk, isFalse);
      expect(AdsPermiso.consentimientoErrorSinRed, isFalse);
      expect(AdsPermiso.ejercicioActivo, isFalse);
      expect(AdsPermiso.anuncioALaVista, isFalse);
    });
  });
}