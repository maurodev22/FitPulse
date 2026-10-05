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
    required this.imagen,
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
  final String imagen;
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

  /// `true` si la receta está etiquetada para esa meta.
  bool sirveParaMeta(String meta) => metas.contains(meta);
}
