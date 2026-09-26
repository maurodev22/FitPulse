import 'package:fitpulse/state/athlete_profile.dart';
import 'package:fitpulse/widgets/common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('inicialesDe (avatar sin foto, paso opcional)', () {
    test('devuelve la inicial de un nombre simple', () {
      expect(inicialesDe('Mauro'), 'M');
    });

    test('devuelve la primera y la última inicial de un nombre compuesto', () {
      expect(inicialesDe('Mario López'), 'ML');
    });

    test('ignora espacios duplicados', () {
      expect(inicialesDe('  Ana   María  '), 'AM');
    });

    test('sube a mayúsculas', () {
      expect(inicialesDe('pedro'), 'P');
    });

    test('devuelve "?" si no hay nombre', () {
      expect(inicialesDe(''), '?');
      expect(inicialesDe('   '), '?');
    });
  });

  group('fotoDecodificable (guard ante base64 corrupto)', () {
    test('acepta base64 válido', () {
      expect(fotoDecodificable('aG9sYQ=='), isTrue);
    });

    test('rechaza base64 inválido', () {
      expect(fotoDecodificable('!!!no-base64!!!'), isFalse);
    });
  });

  group('foto de perfil opcional en AthleteProfile', () {
    test('fotoBase64 sobrevive la serialización a JSON', () {
      const perfil = AthleteProfile(nombre: 'Ana', fotoBase64: 'aG9sYQ==');
      final restaurado = AthleteProfile.fromString(perfil.encode());
      expect(restaurado.fotoBase64, 'aG9sYQ==');
      expect(restaurado.nombre, 'Ana');
    });

    test('perfil sin foto se serializa con fotoBase64 null', () {
      const perfil = AthleteProfile(nombre: 'Ana');
      expect(perfil.encode().contains('"fotoBase64":null'), isTrue);
    });

    test('copiarConFoto cambia solo la foto', () {
      const base = AthleteProfile(nombre: 'Ana', pesoKg: 60);
      final conFoto = base.copiarConFoto('foto');
      expect(conFoto.fotoBase64, 'foto');
      expect(conFoto.nombre, 'Ana');
      expect(conFoto.pesoKg, 60);
    });
  });
}