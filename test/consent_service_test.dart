import 'package:flutter_test/flutter_test.dart';

import 'package:fitpulse/services/consent_service.dart';

void main() {
  group('ConsentService (sin canal nativo)', () {
    test('degradado honesto: sin soporte UMP no lanza y bloquea anuncios',
        () async {
      final consent = ConsentService();
      await consent.iniciar();

      expect(consent.estado, ConsentEstado.error);
      expect(consent.puedeMostrarAnuncios, isFalse);
      expect(consent.errorTecnico, isTrue);
    });

    test('mostrarFormularioSiRequiere no lanza en estado no requerido',
        () async {
      final consent = ConsentService();
      await consent.mostrarFormularioSiRequiere();
      expect(consent.estado, ConsentEstado.desconocido);
    });

    test('actualizarTrasFormulario sin canal → puedeMostrarAnuncios en false',
        () async {
      final consent = ConsentService();
      await consent.actualizarTrasFormulario();
      expect(consent.puedeMostrarAnuncios, isFalse);
    });
  });
}