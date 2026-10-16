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
      // El avatar se dibuja en un círculo, así que la foto presentada es
      // CUADRADA: el lado corto del contenido (241 px) menos el respiro
      // interior, porque hacia fuera volvería a exponer el marco.
      expect(resultado!.width, inInclusiveRange(220, 245));
      expect(resultado.height, resultado.width,
          reason: 'recorte cuadrado: sin esto se ve un cuadrado dentro del círculo');

      // La persona (azul) debe estar presente tras el recorte.
      var azules = 0;
      for (var y = 0; y < resultado.height; y += 4) {
        for (var x = 0; x < resultado.width; x += 4) {
          final p = resultado.getPixel(x, y);
          if (p.b.toInt() > 150 && p.r.toInt() < 120) azules++;
        }
      }
      expect(azules, greaterThan(0));

      // Ni un solo pixel del marco blanco puede sobrevivir: si queda, el
      // usuario ve un borde claro dentro del círculo.
      var blancos = 0;
      for (var y = 0; y < resultado.height; y++) {
        for (var x = 0; x < resultado.width; x++) {
          final p = resultado.getPixel(x, y);
          if (p.r.toInt() > 235 && p.g.toInt() > 235 && p.b.toInt() > 235) blancos++;
        }
      }
      expect(blancos, 0, reason: 'el marco blanco debe eliminarse por completo');
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

  group('regionEncuadre (ventana que usa el editor)', () {
    test('devuelve una ventana cuadrada dentro del contenido (sin marco)', () {
      final foto = _png(400, 300, (im) {
        img.fill(im, color: img.ColorRgb8(255, 255, 255));
        img.fillRect(im, x1: 40, y1: 30, x2: 360, y2: 270, color: img.ColorRgb8(20, 60, 200));
      });

      final region = regionEncuadre(foto);

      expect(region, isNotNull);
      expect(region!.width, region.height, reason: 'la ventana es cuadrada');
      // La ventana queda DENTRO del contenido: ni un píxel del marco blanco.
      expect(region.x, greaterThanOrEqualTo(40));
      expect(region.y, greaterThanOrEqualTo(30));
      expect(region.x + region.width, lessThanOrEqualTo(360));
      expect(region.y + region.height, lessThanOrEqualTo(270));
    });

    test('devuelve null para base64 no válido o sin sujeto', () {
      expect(regionEncuadre('!!!no-base64!!!'), isNull);
      final foto = _png(200, 200, (im) {
        img.fill(im, color: img.ColorRgb8(255, 255, 255));
        for (var y = 0; y < 8; y++) {
          for (var x = 0; x < 200; x++) {
            if ((x ~/ 8 + y) % 2 == 0) {
              im.setPixel(x, y, img.ColorRgb8(20, 20, 20));
              im.setPixel(x, 200 - 1 - y, img.ColorRgb8(20, 20, 20));
            }
          }
        }
      });
      expect(regionEncuadre(foto), isNull);
    });
  });

  group('prepararFotoParaEditar', () {
    test('normaliza a PNG y devuelve medidas y ventana sugerida', () {
      final foto = _png(400, 300, (im) {
        img.fill(im, color: img.ColorRgb8(255, 255, 255));
        img.fillRect(im, x1: 40, y1: 30, x2: 360, y2: 270, color: img.ColorRgb8(20, 60, 200));
      });

      final prep = prepararFotoParaEditar(foto);
      expect(prep, isNotNull);
      expect(prep!.ancho, 400);
      expect(prep.alto, 300);
      expect(prep.sugerencia, isNotNull);

      final imagen = img.decodeImage(base64Decode(prep.fotoBase64));
      expect(imagen, isNotNull);
      expect(imagen!.width, 400);
      expect(imagen.height, 300);
    });

    test('devuelve null si el contenido no es una imagen', () {
      expect(prepararFotoParaEditar('!!!no-base64!!!'), isNull);
      expect(prepararFotoParaEditar(base64Encode(utf8.encode('no soy imagen'))), isNull);
    });
  });

  group('recortarRegionFoto (recorte manual)', () {
    test('recorta exactamente la región pedida', () {
      // Mitad izquierda roja, mitad derecha azul.
      final foto = _png(100, 100, (im) {
        img.fillRect(im, x1: 0, y1: 0, x2: 50, y2: 100, color: img.ColorRgb8(220, 30, 30));
        img.fillRect(im, x1: 50, y1: 0, x2: 100, y2: 100, color: img.ColorRgb8(30, 30, 220));
      });

      final out = recortarRegionFoto(
        (fotoBase64: foto, x: 50, y: 0, lado: 50, salida: 50),
      );
      expect(out, isNotNull);
      final res = img.decodeImage(base64Decode(out!))!;
      expect(res.width, 50);
      expect(res.height, 50);

      var rojos = 0;
      for (var y = 0; y < res.height; y++) {
        for (var x = 0; x < res.width; x++) {
          final p = res.getPixel(x, y);
          if (p.r.toInt() > 150 && p.b.toInt() < 120) rojos++;
        }
      }
      expect(rojos, 0, reason: 'la región pedida es la mitad azul');
    });

    test('reduce a la salida cuando la región es mayor', () {
      final foto = _png(200, 200, (im) => img.fill(im, color: img.ColorRgb8(10, 120, 40)));
      final out = recortarRegionFoto(
        (fotoBase64: foto, x: 0, y: 0, lado: 200, salida: 64),
      );
      final res = img.decodeImage(base64Decode(out!))!;
      expect(res.width, 64);
      expect(res.height, 64);
    });

    test('no amplía cuando la región es menor que la salida', () {
      final foto = _png(200, 200, (im) => img.fill(im, color: img.ColorRgb8(10, 120, 40)));
      final out = recortarRegionFoto(
        (fotoBase64: foto, x: 10, y: 10, lado: 30, salida: 512),
      );
      final res = img.decodeImage(base64Decode(out!))!;
      expect(res.width, 30);
      expect(res.height, 30);
    });

    test('satura las regiones que se salen de la imagen', () {
      final foto = _png(100, 100, (im) => img.fill(im, color: img.ColorRgb8(10, 120, 40)));
      final out = recortarRegionFoto(
        (fotoBase64: foto, x: 90, y: 90, lado: 50, salida: 512),
      );
      final res = img.decodeImage(base64Decode(out!))!;
      expect(res.width, 10);
      expect(res.height, 10);
    });
  });

  group('limitarCentro (sin huecos en los bordes)', () {
    test('con zoom 1 mantiene el centro dentro de la imagen 100x200', () {
      final esquina = limitarCentro(ancho: 100, alto: 200, zoom: 1, x: 0, y: 0);
      expect(esquina.x, 50);
      expect(esquina.y, 50);
      final opuesta = limitarCentro(ancho: 100, alto: 200, zoom: 1, x: 999, y: 999);
      expect(opuesta.x, 50);
      expect(opuesta.y, 150);
    });

    test('al acercar (zoom 2) el rango se ensancha', () {
      final c = limitarCentro(ancho: 100, alto: 200, zoom: 2, x: 0, y: 0);
      expect(c.x, 25);
      expect(c.y, 25);
    });
  });

  group('regionBajoEncuadre (región que se guardará)', () {
    test('zoom 1 sobre 200x100 cubre todo el alto y centra el ancho', () {
      final r = regionBajoEncuadre(
        ancho: 200, alto: 100, lado: 100, zoom: 1, centroX: 100, centroY: 50,
      );
      expect(r.lado, 100);
      expect(r.x, 50);
      expect(r.y, 0);
    });

    test('al doblar el zoom la región se reduce a la mitad', () {
      final r = regionBajoEncuadre(
        ancho: 200, alto: 100, lado: 100, zoom: 2, centroX: 100, centroY: 50,
      );
      expect(r.lado, 50);
      expect(r.x, 75);
      expect(r.y, 25);
    });
  });
}