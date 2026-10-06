import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Recorte del avatar del perfil (Fase 9 — pulido de la foto).
///
/// El avatar se dibuja dentro de un círculo con `BoxFit.cover`. Por eso la
/// foto presentada se devuelve **siempre cuadrada**: un recorte rectangular
/// deja ver sus bordes rectos dentro del círculo. Dos problemas comunes se
/// corrigen aquí:
///
/// 1. Un encuadre casi uniforme alrededor de la persona (capturas, fondos
///    lisos) se percibe como un "borde cuadrado" dentro del círculo y se
///    recorta por márgenes.
/// 2. En fotos verticales donde la persona queda pequeña y descentrada (fondo
///    a los lados, techo gris arriba), se aplica un recorte cuadrado centrado
///    en el sujeto para que la persona llene el círculo.
///
/// `recuadrarFoto` devuelve una versión recortada (PNG, base64) o `null` si no
/// hay nada que recortar (o la imagen no se pudo decodificar); en ese caso el
/// llamador usa la foto original. Nunca inventa contenido: solo recorta la
/// propia foto del usuario.
String? recuadrarFoto(String fotoBase64) {
  final Uint8List bytes;
  try {
    bytes = base64Decode(fotoBase64);
  } catch (_) {
    return null; // Base64 corrupto: no hay foto que recuadrar.
  }
  final imagen = img.decodeImage(bytes);
  if (imagen == null) return null;
  // Normaliza la orientación EXIF para recortar lo que el usuario ve.
  img.bakeOrientation(imagen);

  // 1. Marco uniforme (borde cuadrado). 2. Sujeto pequeño en foto vertical.
  final recorte = _boundsDelContenido(imagen) ?? _recorteDeSujeto(imagen);
  if (recorte == null) return null; // Sin marco ni sujeto: nada que hacer.

  final ancho = imagen.width;
  final alto = imagen.height;
  // Si el recorte detectado es la imagen entera, no hay nada que arreglar.
  if (recorte.width >= ancho && recorte.height >= alto) return null;

  // El avatar se dibuja SIEMPRE dentro de un círculo, así que la foto
  // presentada tiene que ser cuadrada. Si se devuelve un rectángulo,
  // `BoxFit.cover` deja ver los bordes rectos de la foto dentro del círculo:
  // es el defecto de "un cuadrado dentro de un círculo". Cuadrar aquí (el lado
  // más corto del recorte, centrado) elimina esa clase de defecto de raíz y
  // además garantiza que el marco detectado desaparezca por completo.
  final ladoMax = math.min(recorte.width, recorte.height);
  final cx = recorte.x + (recorte.width / 2).round();
  final cy = recorte.y + (recorte.height / 2).round();

  // Pequeño respiro para que la persona no quede pegada al borde del círculo.
  // Se aplica HACIA DENTRO a propósito: hacia fuera volvería a exponer el
  // marco que el recorte acaba de quitar.
  final respiro = (ladoMax * 0.02).round().clamp(2, 12);
  final lado = ladoMax - respiro * 2;
  if (lado < 24) return null; // Recorte absurdo: mejor la foto original.

  final x = (cx - (lado / 2).round()).clamp(0, ancho - 1);
  final y = (cy - (lado / 2).round()).clamp(0, alto - 1);
  final w = lado.clamp(1, ancho - x);
  final h = lado.clamp(1, alto - y);

  final recortada = img.copyCrop(imagen, x: x, y: y, width: w, height: h);
  return base64Encode(img.encodePng(recortada));
}

/// Rectángulo del contenido sin el marco casi uniforme, o `null` si no hay
/// marco que recortar.
({int x, int y, int width, int height})? _boundsDelContenido(img.Image imagen) {
  final ancho = imagen.width;
  final alto = imagen.height;
  if (ancho < 24 || alto < 24) return null;

  // 1) Estimar el color del marco con el anillo exterior (2 px).
  var r = 0, g = 0, b = 0, n = 0;
  void sumar(int x, int y) {
    if (x < 0 || y < 0 || x >= ancho || y >= alto) return;
    final p = imagen.getPixel(x, y);
    r += p.r.toInt();
    g += p.g.toInt();
    b += p.b.toInt();
    n++;
  }

  for (var x = 0; x < ancho; x++) {
    sumar(x, 0);
    sumar(x, 1);
    sumar(x, alto - 1);
    sumar(x, alto - 2);
  }
  for (var y = 0; y < alto; y++) {
    sumar(0, y);
    sumar(1, y);
    sumar(ancho - 1, y);
    sumar(ancho - 2, y);
  }
  if (n == 0) return null;
  final mr = r / n, mg = g / n, mb = b / n;

  // 2) Si el propio borde varía mucho, no es un marco uniforme.
  var varianza = 0.0;
  for (var x = 0; x < ancho; x += 3) {
    _desviacion(imagen, x, 0, mr, mg, mb, (d) => varianza += d);
    _desviacion(imagen, x, alto - 1, mr, mg, mb, (d) => varianza += d);
  }
  for (var y = 0; y < alto; y += 3) {
    _desviacion(imagen, 0, y, mr, mg, mb, (d) => varianza += d);
    _desviacion(imagen, ancho - 1, y, mr, mg, mb, (d) => varianza += d);
  }
  final desviacion = (varianza / (2 * ((ancho / 3).ceil() + (alto / 3).ceil()))).isFinite
      ? varianza / (2 * ((ancho / 3).ceil() + (alto / 3).ceil()))
      : 0.0;
  if (desviacion > 4200) return null; // borde texturizado: no es margen liso.

  // Tolerancia por canal al comparar con el color del marco.
  const tol = 26.0;

  // 3) Recorrer cada lado hasta encontrar la primera banda "no marco".
  bool esMarcoHorizontal(int y) {
    var dent = 0;
    for (var x = 0; x < ancho; x += 2) {
      if (!_cerca(imagen, x, y, mr, mg, mb, tol)) {
        dent++;
        if (dent >= 4) return false;
      }
    }
    return true;
  }

  bool esMarcoVertical(int x) {
    var dent = 0;
    for (var y = 0; y < alto; y += 2) {
      if (!_cerca(imagen, x, y, mr, mg, mb, tol)) {
        dent++;
        if (dent >= 4) return false;
      }
    }
    return true;
  }

  // Límites máximos de recorte por lado: no recortar más del 40 % de un lado.
  final maxTop = (alto * 0.40).round();
  final maxBottom = (alto * 0.40).round();
  final maxLeft = (ancho * 0.40).round();
  final maxRight = (ancho * 0.40).round();

  var top = 0;
  while (top < maxTop && esMarcoHorizontal(top)) {
    top++;
  }
  var bottom = alto;
  while (bottom > alto - maxBottom && esMarcoHorizontal(bottom - 1)) {
    bottom--;
  }
  var left = 0;
  while (left < maxLeft && esMarcoVertical(left)) {
    left++;
  }
  var right = ancho;
  while (right > ancho - maxRight && esMarcoVertical(right - 1)) {
    right--;
  }

  var contenidoW = right - left;
  var contenidoH = bottom - top;
  if (contenidoW < 16 || contenidoH < 16) return null; // recorte absurdo.
  // Exigir que la zona recortada sea significativa (>= 6 px en total).
  if ((top + (alto - bottom) + left + (ancho - right)) < 6) return null;

  return (x: left, y: top, width: contenidoW, height: contenidoH);
}

/// Ventana cuadrada centrada en la persona, para fotos verticales donde el
/// sujeto queda pequeño dentro del círculo del avatar. Devuelve `null` si no
/// se detecta un sujeto fiable o si no merece la pena recortar.
///
/// Detecta el sujeto con dos señales simples (sin ML):
///  * **pelo/ropa oscuros** — pixels con luminancia muy baja y poca saturación
///    en la banda central superior;
///  * **piel** — pixels cálidos (rojo > verde > azul) en la banda media.
///
/// Con esos centroides se centra un cuadrado de lado `≈ 0.68 × min(ancho,alto)`
/// (zoom moderado, nunca agresivo) y se recorta. La ventana resultante, al
/// verse con `BoxFit.cover` en el círculo, ocupa exactamente el círculo.
({int x, int y, int width, int height})? _recorteDeSujeto(img.Image imagen) {
  final ancho = imagen.width;
  final alto = imagen.height;
  if (ancho < 24 || alto < 24) return null;

  // Fotos casi cuadradas ya se ven bien con cover: no recortar.
  if (ancho >= alto * 0.80 && ancho <= alto * 1.25) return null;

  const step = 2;
  final xLo = ancho * 0.10, xHi = ancho * 0.90;
  final pelosYLo = alto * 0.20, pelosYHi = alto * 0.60;
  final pielYLo = alto * 0.15, pielYHi = alto * 0.70;

  var pelosSX = 0.0, pelosSY = 0.0;
  var pelosN = 0, pielN = 0, pielSX = 0.0;

  for (var y = 0; y < alto; y += step) {
    for (var x = 0; x < ancho; x += step) {
      final p = imagen.getPixel(x, y);
      final r = p.r.toInt(), g = p.g.toInt(), b = p.b.toInt();
      final max_ = math.max(r, math.max(g, b));
      final min_ = math.min(r, math.min(g, b));
      final esPiel = r > 110 && (r - g) > 12 && (r - b) > 20;
      final esOscuro = !esPiel && (0.2126 * r + 0.7152 * g + 0.0722 * b) < 70 && (max_ - min_) < 45;

      if (esPiel && y >= pielYLo && y <= pielYHi && x >= xLo && x <= xHi) {
        pielSX += x;
        pielN++;
      } else if (esOscuro && y >= pelosYLo && y <= pelosYHi && x >= xLo && x <= xHi) {
        pelosSX += x;
        pelosSY += y;
        pelosN++;
      }
    }
  }

  final total = pelosN + pielN;
  if (total < (ancho ~/ step) * (alto ~/ step) ~/ 200) return null; // sin sujeto.

  // Centro horizontal: mezcla cuerpo (piel) y cabeza (oscuro), con más peso en
  // la piel porque suele ser la zona más fiable.
  final cx = pielN > 0 && pelosN > 0
      ? (2 * pielSX / pielN + pelosSX / pelosN) / 3
      : pielN > 0
          ? pielSX / pielN
          : pelosN > 0
              ? pelosSX / pelosN
              : ancho / 2.0;

  final minDim = math.min(ancho, alto);
  final s = (minDim * 0.68).round().clamp((minDim * 0.50).round(), (minDim * 0.85).round());

  // Centro vertical sobre la cabeza, desplazado un poco hacia abajo para que
  // el rostro quede en el tercio superior del círculo (no el pelo en el borde).
  final cy = pelosN > 0 ? pelosSY / pelosN + s * 0.16 : alto * 0.40;

  final x0 = (cx - s / 2).round().clamp(0, ancho - s);
  final y0 = (cy - s / 2).round().clamp(0, alto - s);
  return (x: x0, y: y0, width: s, height: s);
}

void _desviacion(
  img.Image imagen,
  int x,
  int y,
  double mr,
  double mg,
  double mb,
  void Function(double) acumula,
) {
  final p = imagen.getPixel(x, y);
  final dr = p.r.toInt() - mr;
  final dg = p.g.toInt() - mg;
  final db = p.b.toInt() - mb;
  acumula(dr * dr + dg * dg + db * db);
}

bool _cerca(img.Image imagen, int x, int y, double mr, double mg, double mb, double tol) {
  final p = imagen.getPixel(x, y);
  final dr = p.r.toInt() - mr;
  final dg = p.g.toInt() - mg;
  final db = p.b.toInt() - mb;
  return dr * dr + dg * dg + db * db <= tol * tol;
}