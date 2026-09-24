import 'dart:io';
import 'package:image/image.dart' as img;

/// Genera los assets de marca de FitPulse:
/// 1. Convierte las imágenes JPG de la app a WebP (identidad propia).
/// 2. Genera el launcher icon adaptativo (fondo verde + trazado ECG blanco).
void main() {
  _convertImages();
  _generateLauncherIcons();
  stdout.writeln('Assets de marca generados.');
}

void _convertImages() {
  final dir = Directory('assets/images');
  for (final jpg in dir.listSync().whereType<File>().where((f) => f.path.endsWith('.jpg'))) {
    final decoded = img.decodeJpg(jpg.readAsBytesSync());
    if (decoded == null) {
      stdout.writeln('AVISO: no se pudo decodificar ${jpg.path}');
      continue;
    }
    final webpPath = jpg.path.replaceAll('.jpg', '.webp');
    File(webpPath).writeAsBytesSync(
      img.encodeWebP(decoded, lossless: false, quality: 75, method: 6),
      flush: true,
    );
    final before = jpg.lengthSync();
    final after = File(webpPath).lengthSync();
    stdout.writeln('${jpg.path} -> $webpPath ($before -> $after bytes)');
  }
}

// Paleta de marca FitPulse.
final _bg = img.ColorRgb8(0, 81, 54); // AppColors.primary
final _pulse = img.ColorRgb8(255, 255, 255);

void _generateLauncherIcons() {
  final resDir = Directory('android/app/src/main/res');
  final anydpi = Directory('${resDir.path}/mipmap-anydpi-v26');
  final drawable = Directory('${resDir.path}/drawable');
  anydpi.createSync(recursive: true);
  drawable.createSync(recursive: true);

  // Fondo adaptativo = color plano (evita PNG enorme).
  final colorsPath = '${resDir.path}/values/colors.xml';
  final colorsFile = File(colorsPath);
  var colorsXml = colorsFile.existsSync() ? colorsFile.readAsStringSync() : '';
  if (!colorsXml.contains('ic_launcher_background')) {
    colorsXml = colorsXml.replaceFirst(
      '</resources>',
      '    <color name="ic_launcher_background">#005136</color>\n</resources>',
    );
    colorsFile.writeAsStringSync(colorsXml, flush: true);
  }

  // Foreground adaptativo (contenido dentro de la zona segura ~66% central).
  const fgSize = 432;
  final fg = img.Image(width: fgSize, height: fgSize);
  img.fill(fg, color: img.ColorRgba8(0, 0, 0, 0));
  _drawPulse(fg, size: fgSize, inset: fgSize * 0.17, thickness: fgSize * 0.055);
  File('${drawable.path}/ic_launcher_foreground.png')
      .writeAsBytesSync(img.encodePng(fg), flush: true);

  // Icono heredado (API < 26) en todas las densidades con fondo de marca.
  const legacy = [
    (density: 'mdpi', px: 48),
    (density: 'hdpi', px: 72),
    (density: 'xhdpi', px: 96),
    (density: 'xxhdpi', px: 144),
    (density: 'xxxhdpi', px: 192),
  ];
  for (final item in legacy) {
    final icon = img.Image(width: item.px, height: item.px);
    img.fill(icon, color: _bg);
    _drawPulse(icon, size: item.px, inset: item.px * 0.10, thickness: item.px * 0.075);
    final dir = '${resDir.path}/mipmap-${item.density}';
    File('$dir/ic_launcher.png').writeAsBytesSync(img.encodePng(icon), flush: true);
  }

  // XML adaptativo para API 26+.
  const xmlish =
      '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
      '    <background android:drawable="@color/ic_launcher_background"/>\n'
      '    <foreground android:drawable="@drawable/ic_launcher_foreground"/>\n'
      '    <monochrome android:drawable="@drawable/ic_launcher_foreground"/>\n'
      '</adaptive-icon>\n';
  File('${anydpi.path}/ic_launcher.xml').writeAsStringSync(xmlish, flush: true);
}

/// Dibuja un trazado ECG estilizado horizontal dentro de la zona segura.
void _drawPulse(img.Image dest, {required int size, required double inset, required double thickness}) {
  final w = size - inset * 2;
  final x0 = inset;
  final baseY = size / 2;
  final amp = size * 0.16;

  double fx(double t) => x0 + w * t;
  double fy(double v) => baseY + (v - 0.5) * 2 * amp;

  final pts = <(double, double)>[
    (0.04, 0.5),
    (0.42, 0.5),
    (0.50, 0.28),
    (0.56, 0.72),
    (0.64, 0.5),
    (0.96, 0.5),
  ];
  for (var i = 0; i < pts.length - 1; i++) {
    img.drawLine(
      dest,
      x1: fx(pts[i].$1).toInt(),
      y1: fy(pts[i].$2).toInt(),
      x2: fx(pts[i + 1].$1).toInt(),
      y2: fy(pts[i + 1].$2).toInt(),
      color: _pulse,
      thickness: thickness,
      antialias: true,
    );
  }
  // Punto final del pulso (peak indicador de latido).
  img.fillCircle(
    dest,
    x: fx(0.64).toInt(),
    y: fy(0.5).toInt(),
    radius: (thickness * 0.8).toInt(),
    color: _pulse,
  );
}