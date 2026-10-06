import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:fitpulse/state/recetas_catalog.dart';

/// Ilustraciones propias de las recetas.
///
/// Antes las 41 recetas compartían tres imágenes genéricas que no tenían nada
/// que ver con el plato. Estos tests son el guardián de que eso no vuelva:
/// cada receta debe tener SU archivo, el archivo debe existir de verdad y no
/// puede haber dos recetas apuntando al mismo dibujo.
void main() {
  group('imágenes de receta', () {
    test('cada receta deriva una ruta propia a partir de su nombre', () {
      final rutas = catalog.map((r) => r.imagenTarjeta).toList();
      expect(rutas.length, greaterThanOrEqualTo(35));
      for (final r in rutas) {
        expect(r, startsWith('assets/images/recetas/'), reason: r);
        expect(r, endsWith('.webp'), reason: r);
      }
      // Ninguna receta comparte dibujo con otra: si dos nombres se normalizan
      // igual, el dishes se ven igual y el test falla aquí.
      expect(rutas.toSet().length, rutas.length,
          reason: 'hay dos recetas con la misma imagen');
    });

    test('el archivo de cada imagen existe en el proyecto', () {
      final queFaltan = <String>[];
      for (final r in catalog) {
        final ruta = r.imagenTarjeta;
        if (!File(ruta).existsSync()) queFaltan.add('${r.nombre} -> $ruta');
      }
      expect(queFaltan, isEmpty,
          reason: 'faltan imágenes en assets/\n${queFaltan.join('\n')}');
    });

    test('sin sobras: ninguna imagen del catálogo está huérfana', () {
      final usadas = catalog.map((r) => r.imagenTarjeta).toSet().toList()
        ..sort();
      final enDisco = Directory('assets/images/recetas')
          .listSync()
          .whereType<File>()
          .map((f) => f.path.replaceAll('\\', '/'))
          .toList()
        ..sort();
      final sobrantes = enDisco.where((f) => !usadas.contains(f)).toList();
      expect(sobrantes, isEmpty,
          reason: 'imágenes sin receta asociada:\n${sobrantes.join('\n')}');
    });

    test('las ilustraciones pesan lo razonable para una app móvil', () {
      // 41 imágenes de WebP planas: si esto se dispara, es que se guardaron sin
      // comprimir o a una resolución que la app no usa.
      final total = catalog.fold<int>(
        0,
        (sum, r) => sum + File(r.imagenTarjeta).lengthSync(),
      );
      final mediaKB = total / catalog.length / 1024;
      expect(mediaKB, lessThan(40),
          reason: 'media de ${mediaKB.toStringAsFixed(1)} KB por imagen');
    });

    test('el nombre normalizado conserva lo que distingue una receta', () {
      // Regresión: una normalización demasiado agresiva colapsaría nombres
      // distintos en el mismo archivo.
      expect(imagenDeReceta('Batido Verde Energético'),
          'assets/images/recetas/batido-verde-energetico.webp');
      expect(imagenDeReceta('Pancakes de Avena & Proteína'),
          'assets/images/recetas/pancakes-de-avena-y-proteina.webp');
      expect(imagenDeReceta('Sopa de Lentejas con Espinacas'),
          'assets/images/recetas/sopa-de-lentejas-con-espinacas.webp');
      expect(imagenDeReceta('Bowl de Salmón, Aguacate y Quinoa'),
          'assets/images/recetas/bowl-de-salmon-aguacate-y-quinoa.webp');
    });

    test('pubspec declara la subcarpeta: si no, el bundle se queda sin ellas',
        () {
      // Trampa real encontrada una vez: `assets/images/` solo copia los
      // archivos DIRECTOS de la carpeta. Sin esta línea extra, las 41 imágenes
      // existían en disco pero no llegaban al bundle y las tarjetas salían
      // con una caja roja de "Unable to load asset".
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('- assets/images/recetas/'),
          reason: 'falta la entrada en pubspec.yaml > flutter > assets');
    });
  });
}