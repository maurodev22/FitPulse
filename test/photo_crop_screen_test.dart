import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/screens/photo_crop_screen.dart';
import 'package:fitpulse/services/locale_service.dart';
import 'package:fitpulse/theme.dart';
import 'package:fitpulse/utils/foto_avatar.dart';

/// Helper: imagen PNG en base64 (mismo patrón que el resto de tests).
String _png(int ancho, int alto, void Function(img.Image) dibujar) {
  final imagen = img.Image(width: ancho, height: alto);
  dibujar(imagen);
  return base64Encode(img.encodePng(imagen));
}

void main() {
  setUp(() {
    AppColors.activate(lightFitPalette);
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpEditor(WidgetTester tester, PreparacionFoto prep) async {
    final locale = LocaleService();
    await locale.init();
    await tester.pumpWidget(
      ChangeNotifierProvider<LocaleService>.value(
        value: locale,
        child: MaterialApp(home: PhotoCropScreen(preparacion: prep)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra el editor con el encuadre y las acciones', (tester) async {
    final foto = _png(200, 200, (im) => img.fill(im, color: img.ColorRgb8(10, 120, 40)));
    await pumpEditor(tester, prepararFotoParaEditar(foto)!);

    expect(find.text('Ajustar foto'), findsOneWidget);
    expect(find.byKey(const Key('croArea')), findsOneWidget);
    expect(find.byKey(const Key('croListo')), findsOneWidget);
    expect(find.byKey(const Key('croRestablecer')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el área de encuadre se recorta en círculo, no en cuadrado', (tester) async {
    final foto = _png(200, 200, (im) => img.fill(im, color: img.ColorRgb8(10, 120, 40)));
    await pumpEditor(tester, prepararFotoParaEditar(foto)!);

    final area = find.byKey(const Key('croArea'));
    expect(area, findsOneWidget);
    expect(
      find.descendant(of: area, matching: find.byType(ClipOval)),
      findsOneWidget,
      reason: 'el editor debe recortar la foto en círculo, igual que el avatar',
    );
    expect(
      find.descendant(of: area, matching: find.byType(ClipRect)),
      findsNothing,
      reason: 'no debe verse un encuadre cuadrado',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('arrastrar para posicionar y restablecer no rompe', (tester) async {
    // Mitad roja / mitad azul para que el arrastre tenga efecto visible.
    final foto = _png(240, 120, (im) {
      img.fillRect(im, x1: 0, y1: 0, x2: 120, y2: 120, color: img.ColorRgb8(220, 40, 40));
      img.fillRect(im, x1: 120, y1: 0, x2: 240, y2: 120, color: img.ColorRgb8(40, 40, 220));
    });
    await pumpEditor(tester, prepararFotoParaEditar(foto)!);

    // Gesto de arrastre (un dedo) sobre el área de encuadre.
    await tester.drag(find.byKey(const Key('croArea')), const Offset(-40, 0));
    await tester.pump();

    await tester.tap(find.byKey(const Key('croRestablecer')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelar cierra sin devolver ninguna foto', (tester) async {
    final foto = _png(100, 100, (im) => img.fill(im, color: img.ColorRgb8(10, 120, 40)));
    final prep = prepararFotoParaEditar(foto)!;

    String? resultado = 'sin-tocar';
    final locale = LocaleService();
    await locale.init();
    await tester.pumpWidget(
      ChangeNotifierProvider<LocaleService>.value(
        value: locale,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    resultado = await Navigator.of(context).push<String>(
                      MaterialPageRoute<String>(
                        builder: (_) => PhotoCropScreen(preparacion: prep),
                      ),
                    );
                  },
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('croArea')), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(resultado, isNull, reason: 'cancelar no debe devolver foto');
    expect(tester.takeException(), isNull);
  });
}
