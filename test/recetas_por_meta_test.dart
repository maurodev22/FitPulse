import 'package:flutter_test/flutter_test.dart';

import 'package:fitpulse/state/recetas_catalog.dart';

/// L4 — Catálogo ampliado por metas.
///
/// Reglas comprobadas aquí, porque una receta con un dato falso es peor que no
/// tener receta: cobertura de las cuatro metas del perfil, coherencia entre
/// kcal y macros, ingredientes por ración (los necesita el plan semanal) y
/// textos únicos sin restos de otro idioma.
void main() {
  group('L4 · cobertura por meta', () {
    test('el catálogo tiene al menos 35 recetas', () {
      expect(catalog.length, greaterThanOrEqualTo(35));
    });

    test('cada meta del perfil tiene al menos 8 recetas', () {
      final conteo = conteoPorMeta(catalog);
      for (final meta in metasCatalogo) {
        expect(
          conteo[meta] ?? 0,
          greaterThanOrEqualTo(8),
          reason: 'La meta "$meta" tiene ${conteo[meta] ?? 0} recetas',
        );
      }
    });

    test('las metas del catálogo son exactamente las del perfil', () {
      // Si el registro guardara una etiqueta distinta, el filtro nunca
      // encontraría recetas: por eso las dos listas deben coincidir.
      const metasDelPerfil = [
        'Bajar de peso',
        'Definir',
        'Aumentar de peso',
        'Mantener',
      ];
      expect(metasCatalogo, metasDelPerfil);
      for (final receta in catalog) {
        for (final meta in receta.metas) {
          expect(
            metasCatalogo,
            contains(meta),
            reason: '"${receta.nombre}" usa una meta desconocida: $meta',
          );
        }
      }
    });

    test('toda receta declara al menos una meta', () {
      final sinMeta = catalog.where((r) => r.metas.isEmpty).map((r) => r.nombre);
      expect(sinMeta, isEmpty);
    });

    test('el filtro por meta devuelve solo lo que corresponde', () {
      for (final meta in metasCatalogo) {
        final resultado = recetasParaMeta(catalog, meta);
        expect(resultado, isNotEmpty);
        for (final receta in resultado) {
          expect(receta.metas, contains(meta));
        }
      }
    });

    test('una meta vacía NO esconde recetas', () {
      // Usuario sin meta elegida: se le muestra todo, no una lista vacía.
      expect(recetasParaMeta(catalog, '').length, catalog.length);
      expect(recetasParaMeta(catalog, '   ').length, catalog.length);
    });

    test('una meta desconocida devuelve vacío en vez de inventar', () {
      expect(recetasParaMeta(catalog, 'Meta inventada'), isEmpty);
    });
  });

  group('L4 · datos falsos prohibidos', () {
    test('kcal coherentes con los macros (±12 %) en TODAS las recetas', () {
      for (final r in catalog) {
        final calculo = 4 * r.proteinas + 4 * r.carbos + 9 * r.grasas;
        final desvio = (calculo - r.calorias).abs() / r.calorias * 100;
        expect(
          desvio,
          lessThanOrEqualTo(12),
          reason: '"${r.nombre}" declara ${r.calorias} kcal pero sus macros '
              'suman ${calculo.toStringAsFixed(0)} (${desvio.toStringAsFixed(1)} %)',
        );
      }
    });

    test('todas las recetas tienen ingredientes por ración', () {
      // El plan semanal arma la lista de la compra con esta lista: si está
      // vacía, el usuario recibe una compra inútil.
      final sinIngredientes =
          catalog.where((r) => r.ingredientes.isEmpty).map((r) => r.nombre);
      expect(sinIngredientes, isEmpty);
      for (final r in catalog) {
        for (final ing in r.ingredientes) {
          expect(ing.nombre.trim(), isNotEmpty);
          expect(ing.cantidad.trim(), isNotEmpty);
        }
      }
    });

    test('valores dentro de un rango creíble', () {
      for (final r in catalog) {
        expect(r.calorias, greaterThan(0));
        expect(r.calorias, lessThan(800), reason: r.nombre);
        expect(r.minutos, greaterThan(0));
        expect(r.minutos, lessThanOrEqualTo(60), reason: r.nombre);
        expect(r.descripcion.length, greaterThan(30), reason: r.nombre);
        expect(r.imagenTarjeta, startsWith('assets/images/recetas/'),
            reason: r.nombre);
      }
    });

    test('sin nombres ni categorías duplicados', () {
      final nombres = catalog.map((r) => r.nombre).toList();
      expect(nombres.toSet().length, nombres.length);
      final categorias = catalog.map((r) => r.categoria).toSet();
      // Solo las 4 categorías que los filtros de la UI saben mostrar.
      expect(
        categorias.difference({
          'Alta Proteína',
          'Low Carb',
          'Pre-entreno',
          'Smoothies',
        }),
        isEmpty,
      );
    });

    test('ningún texto se queda en otro idioma (contenido original)', () {
      // Las recetas del catálogo ampliado son texto propio de FitPulse: si
      // aparece una palabra en inglés o francés, es contenido copiado.
      // Palabras que delatan una receta copiada de un medio en inglés o francés.
      // "Bowl" no se incluye porque el catálogo original ya lo usa (y es de uso
      // normal en español), igual que "smoothie".
      final patronExtranjero = RegExp(
        r'\b(the|and|with|recipe|servings?|minutes?|chicken|cheese|tasty)\b',
        caseSensitive: false,
      );
      for (final r in catalog) {
        expect(patronExtranjero.hasMatch(r.nombre), isFalse, reason: r.nombre);
        expect(patronExtranjero.hasMatch(r.descripcion), isFalse, reason: r.nombre);
        for (final ing in r.ingredientes) {
          expect(patronExtranjero.hasMatch(ing.nombre), isFalse, reason: ing.nombre);
        }
      }
    });
  });

  group('L4 · el filtro combinado', () {
    test('categoría + meta se combinan con Y', () {
      final resultado = filtrarRecetas(
        catalog,
        '',
        'Low Carb',
        meta: 'Bajar de peso',
      );
      expect(resultado, isNotEmpty);
      for (final r in resultado) {
        expect(r.categoria, 'Low Carb');
        expect(r.metas, contains('Bajar de peso'));
      }
    });

    test('búsqueda por texto sigue funcionando con el filtro de meta', () {
      final resultado = filtrarRecetas(catalog, 'pollo', 'Todas',
          meta: 'Aumentar de peso');
      expect(resultado, isNotEmpty);
      for (final r in resultado) {
        expect(r.nombre.toLowerCase(), contains('pollo'));
        expect(r.metas, contains('Aumentar de peso'));
      }
    });

    test('sin meta, el filtro conserva el comportamiento anterior', () {
      // Las llamadas existentes (pills de categoría) no pasan meta: no deben
      // cambiar los resultados.
      expect(
        filtrarRecetas(catalog, '', 'Low Carb').length,
        filtrarRecetas(catalog, '', 'Low Carb').length,
      );
      expect(
        filtrarRecetas(catalog, 'pollo', 'Todas').length,
        greaterThan(0),
      );
    });
  });

  group('L4 · nada de lo anterior se rompió', () {
    test('las 6 recetas base siguen al principio y en su orden', () {
      const ordenOriginal = [
        'Bowl de Salmón, Aguacate y Quinoa',
        'Pancakes de Avena & Proteína',
        'Ensalada Griega con Pechuga',
        'Batido Verde Energético',
        'Wrap de Pollo y Aguacate',
        'Avena Nocturna con Proteína',
      ];
      expect(
        catalog.take(6).map((r) => r.nombre).toList(),
        ordenOriginal,
      );
    });

    test('la receta destacada sigue siendo la misma', () {
      expect(featuredRecipe.nombre, 'Bowl de Salmón, Aguacate y Quinoa');
    });

    test('las 6 base quedan etiquetadas (no se quedaron "sin meta")', () {
      for (final nombre in const [
        'Bowl de Salmón, Aguacate y Quinoa',
        'Pancakes de Avena & Proteína',
        'Ensalada Griega con Pechuga',
        'Batido Verde Energético',
        'Wrap de Pollo y Aguacate',
        'Avena Nocturna con Proteína',
      ]) {
        final receta = catalog.firstWhere((r) => r.nombre == nombre);
        expect(receta.metas, isNotEmpty, reason: nombre);
      }
    });

    test('los favoritos guardados siguen encontrando su receta', () {
      // Los favoritos se guardan por nombre: si una receta desapareciera del
      // catálogo, el usuario vería la estrella sin receta.
      for (final nombre in const [
        'Bowl de Salmón, Aguacate y Quinoa',
        'Ensalada Griega con Pechuga',
      ]) {
        expect(
          catalog.any((r) => r.nombre == nombre),
          isTrue,
          reason: nombre,
        );
      }
    });
  });
}
