/// Modelo de datos del catálogo nutricional de FitPulse.
///
/// Vive en su propio archivo para que el catálogo base
/// (`recetas_catalog.dart`) y el ampliado por metas
/// (`recetas_por_meta.dart`) dependan de las mismas clases sin importarse
/// entre ellos. `recetas_catalog.dart` lo reexporta, así que el resto de la app
/// sigue importando todo desde ahí.
library;

/// Ingrediente de una receta con su cantidad (por ración).
class Ingrediente {
  const Ingrediente(this.nombre, this.cantidad);

  final String nombre;
  final String cantidad;
}

/// Modelo de una receta nutricional.
class Recipe {
  const Recipe({
    required this.nombre,
    required this.categoria,
    required this.tipo,
    required this.calorias,
    required this.proteinas,
    required this.carbos,
    required this.grasas,
    required this.minutos,
    required this.descripcion,
    this.imagen,
    this.ingredientes = const [],
    this.destacada = false,
    this.metas = const [],
  });

  final String nombre;
  final String categoria;
  final String tipo;
  final double calorias;
  final double proteinas;
  final double carbos;
  final double grasas;
  final int minutos;
  final String descripcion;

  /// Ilustración de la receta. Si no se pasa, se deriva del nombre con
  /// [imagenDeReceta]: por eso el catálogo no repite la ruta y es imposible
  /// que una receta acabe mostrando el dibujo de otra.
  final String? imagen;
  final List<Ingrediente> ingredientes;
  final bool destacada;

  /// Metas del perfil para las que esta receta es adecuada (L4). Admite **más
  /// de una**. Usa exactamente las etiquetas que guarda `AthleteProfile.metas`:
  /// 'Bajar de peso', 'Definir', 'Aumentar de peso' y 'Mantener'.
  ///
  /// Vacía significa "no se ha clasificado todavía": el filtro por meta la
  /// ignora en lugar de ocultarla, para no esconder recetas por un dato que no
  /// se rellenó.
  final List<String> metas;

  String get etiquetaCategoria => tipo.toUpperCase().replaceAll(' ', '-');

  /// Ruta de la imagen que se dibuja en la tarjeta. Deriva del nombre cuando el
  /// catálogo no pasa una explícita.
  String get imagenTarjeta => imagen ?? imagenDeReceta(nombre);

  /// `true` si la receta está etiquetada para esa meta.
  bool sirveParaMeta(String meta) => metas.contains(meta);
}

/// Ruta de la ilustración propia de una receta, derivada de su nombre.
///
/// Se calcula en vez de escribirse a mano en el catálogo: hasta ahora las 41
/// recetas compartían tres imágenes genéricas (`workout.webp`, `core.webp`,
/// `profile.webp`) que no tenían nada que ver con el plato. Con esta función
/// cada receta muestra su dibujo y añadir una receta nueva no puede olvidarse
/// de la imagen.
///
/// El nombre se normaliza igual que en el generador (`work/gen_recetas.py`):
/// sin acentos, minúsculas, `&` como "y" y guiones en los espacios.
String imagenDeReceta(String nombre) {
  var base = nombre.toLowerCase().replaceAll('&', ' y ');
  const conAcento = {
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
    'ñ': 'n',
    'ç': 'c',
  };
  final buffer = StringBuffer();
  for (final c in base.split('')) {
    buffer.write(conAcento[c] ?? c);
  }
  final slug = buffer
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+'), '')
      .replaceAll(RegExp(r'-+$'), '');
  return 'assets/images/recetas/$slug.webp';
}
