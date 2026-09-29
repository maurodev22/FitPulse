import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:fitpulse/utils/foto_avatar.dart';

/// Helper: imagen PNG en base64.
String _png(int ancho, int alto, void Function(img.Image) dibujar) {
  final imagen = img.Image(width: ancho, height: alto);
  dibujar(imagen);
  return base64Encode(img.encodePng(imagen));
}

void main() {
  group('recuadrarFoto', () {
    test('recorta el marco blanco uniforme alrededor del contenido', () {
      // 400x300 blanco con un rectángulo azul centrado (márgenes 40/30 px).
      final foto = _png(400, 300, (im) {
        img.fill(im, color: img.ColorRgb8(255, 255, 255));
        img.fillRect(im, x1: 40, y1: 30, x2: 360, y2: 270, color: img.ColorRgb8(20, 60, 200));
      });

      final recortada = recuadrarFoto(foto);

      expect(recortada, isNotNull, reason: 'debe detectar y recortar el marco');
      final resultado = img.decodeImage(base64Decode(recortada!));
      expect(resultado, isNotNull);
      // Con el respiro del 2 % (8 px) a cada lado.
      expect(resultado!.width, inInclusiveRange(320, 340));
      expect(resultado.height, inInclusiveRange(240, 260));

      // La persona (azul) debe estar presente tras el recorte.
      var azules = 0;
      for (var y = 0; y < resultado.height; y += 4) {
        for (var x = 0; x < resultado.width; x += 4) {
          final p = resultado.getPixel(x, y);
          if (p.b.toInt() > 150 && p.r.toInt() < 120) azules++;
        }
      }
      expect(azules, greaterThan(0));
    });

    test('tolera márgenes casi blancos (gris claro)', () {
      final foto = _png(300, 300, (im) {
        img.fill(im, color: img.ColorRgb8(243, 243, 241));
        img.fillRect(im, x1: 60, y1: 60, x2: 240, y2: 240, color: img.ColorRgb8(10, 80, 30));
      });

      final recortada = recuadrarFoto(foto);
      expect(recortada, isNotNull);
      final resultado = img.decodeImage(base64Decode(recortada!));
      expect(resultado!.width, lessThan(300));
    });

    test('no toca fotos sin marco uniforme (borde con textura)', () {
      // Damero en el borde exterior: el borde no es un margen liso.
      final foto = _png(200, 200, (im) {
        img.fill(im, color: img.ColorRgb8(255, 255, 255));
        for (var y = 0; y < 10; y++) {
          for (var x = 0; x < 200; x++) {
            if ((x ~/ 8 + y) % 2 == 0) {
              im.setPixel(x, y, img.ColorRgb8(20, 20, 20));
              im.setPixel(x, 200 - 1 - y, img.ColorRgb8(20, 20, 20));
            }
          }
        }
      });

      expect(recuadrarFoto(foto), isNull);
    });

    test('devuelve null si el base64 no es una imagen', () {
      expect(recuadrarFoto(base64Encode(utf8.encode('no soy una imagen'))), isNull);
    });

    test('devuelve null para base64 inválido', () {
      expect(recuadrarFoto('!!!no-base64!!!'), isNull);
    });

    test('acerca a la persona en fotos verticales (recorte de sujeto)', () {
      // Retrato 90x160: fondo partido en dos tonos (anula el margen uniforme,
      // por lo que debe actuar el recorte de sujeto), pelo oscuro y piel.
      final foto = _png(90, 160, (im) {
        img.fillRect(im, x1: 0, y1: 0, x2: 44, y2: 160, color: img.ColorRgb8(232, 234, 228));
        img.fillRect(im, x1: 44, y1: 0, x2: 90, y2: 160, color: img.ColorRgb8(200, 205, 196));
        img.fillRect(im, x1: 40, y1: 45, x2: 60, y2: 75, color: img.ColorRgb8(16, 19, 16)); // pelo
        img.fillRect(im, x1: 35, y1: 75, x2: 65, y2: 105, color: img.ColorRgb8(208, 154, 110)); // piel
      });

      final recortada = recuadrarFoto(foto);

      expect(recortada, isNotNull, reason: 'debe detectar y acercar al sujeto');
      final resultado = img.decodeImage(base64Decode(recortada!));
      expect(resultado, isNotNull);
      // Zoom moderado: cuadrado ~68 % del ancho original (90 → 61 + respiro 4).
      expect(resultado!.width, inInclusiveRange(55, 75));
      expect(resultado.height, resultado.width, reason: 'recorte cuadrado para el círculo');

      // El pelo (oscuro) debe seguir presente y bien arriba en el recorte.
      var oscuros = 0;
      for (var y = 0; y < resultado.height; y += 2) {
        for (var x = 0; x < resultado.width; x += 2) {
          final p = resultado.getPixel(x, y);
          if (0.2126 * p.r + 0.7152 * p.g + 0.0722 * p.b < 70) oscuros++;
        }
      }
      expect(oscuros, greaterThan(10));
    });

    test('no recorta por sujeto imágenes casi cuadradas', () {
      // 100x100 con borde texturizado (para que el margen no aplique) y sujeto.
      final foto = _png(100, 100, (im) {
        img.fill(im, color: img.ColorRgb8(255, 255, 255));
        for (var y = 0; y < 6; y++) {
          for (var x = 0; x < 100; x++) {
            if ((x ~/ 8 + y) % 2 == 0) {
              im.setPixel(x, y, img.ColorRgb8(25, 25, 25));
              im.setPixel(x, 100 - 1 - y, img.ColorRgb8(25, 25, 25));
            }
          }
        }
        img.fillRect(im, x1: 40, y1: 40, x2: 60, y2: 70, color: img.ColorRgb8(16, 19, 16));
      });

      expect(recuadrarFoto(foto), isNull);
    });

    test('no recorta si no hay sujeto detectable', () {
      // Fondo repartido en dos mitades (anula el margen uniforme), sin persona.
      final foto = _png(90, 160, (im) {
        img.fillRect(im, x1: 0, y1: 0, x2: 45, y2: 160, color: img.ColorRgb8(250, 250, 250));
        img.fillRect(im, x1: 45, y1: 0, x2: 90, y2: 160, color: img.ColorRgb8(160, 160, 160));
      });

      expect(recuadrarFoto(foto), isNull);
    });
  });
}