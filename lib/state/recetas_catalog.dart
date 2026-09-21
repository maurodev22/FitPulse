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
    this.destacada = false,
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
  final bool destacada;

  String get etiquetaCategoria => tipo.toUpperCase().replaceAll(' ', '-');
}

/// Catálogo estático de recetas mostradas en la pestaña de nutrición.
const catalog = <Recipe>[
  Recipe(
    nombre: 'Bowl de Salmón, Aguacate y Quinoa',
    categoria: 'Alta Proteína',
    tipo: 'Almuerzo Pro',
    calorias: 490,
    proteinas: 38,
    carbos: 44,
    grasas: 16,
    minutos: 25,
    descripcion:
        'Rico en omega 3 y proteína magra. Diseñado para favorecer la recuperación muscular y mantener masa magra.',
    imagen: 'assets/images/workout.jpg',
    destacada: true,
  ),
  Recipe(
    nombre: 'Pancakes de Avena & Proteína',
    categoria: 'Alta Proteína',
    tipo: 'Desayuno',
    calorias: 310,
    proteinas: 26,
    carbos: 35,
    grasas: 8,
    minutos: 15,
    descripcion:
        'Tortitas esponjosas con avena integral y proteína whey para empiezar el día con energía sostenida.',
    imagen: 'assets/images/core.jpg',
  ),
  Recipe(
    nombre: 'Ensalada Griega con Pechuga',
    categoria: 'Low Carb',
    tipo: 'Almuerzo',
    calorias: 360,
    proteinas: 34,
    carbos: 12,
    grasas: 18,
    minutos: 10,
    descripcion:
        'Pechuga a la plancha con tomate, pepino, aceitunas y queso feta. Fresca, ligera y muy saciante.',
    imagen: 'assets/images/profile.jpg',
  ),
  Recipe(
    nombre: 'Batido Verde Energético',
    categoria: 'Smoothies',
    tipo: 'Pre-entreno',
    calorias: 220,
    proteinas: 15,
    carbos: 30,
    grasas: 3,
    minutos: 5,
    descripcion:
        'Espinaca, plátano, jengibre y proteína vegetal. Combustible listo 30 minutos antes de entrenar.',
    imagen: 'assets/images/workout.jpg',
  ),
  Recipe(
    nombre: 'Wrap de Pollo y Aguacate',
    categoria: 'Low Carb',
    tipo: 'Recuperación',
    calorias: 410,
    proteinas: 32,
    carbos: 28,
    grasas: 19,
    minutos: 20,
    descripcion:
        'Tortilla integral con pollo, aguacate y espinacas. Ideal para cerrar la ventana anabólica post-HIIT.',
    imagen: 'assets/images/core.jpg',
  ),
  Recipe(
    nombre: 'Avena Nocturna con Proteína',
    categoria: 'Alta Proteína',
    tipo: 'Cena',
    calorias: 330,
    proteinas: 28,
    carbos: 40,
    grasas: 7,
    minutos: 8,
    descripcion:
        'Avena remojada en yogur griego con semillas de chía. Reposición muscular mientras duermes.',
    imagen: 'assets/images/profile.jpg',
  ),
];

/// Receta destacada del día (la primera marcada como destacada en el catálogo).
Recipe get featuredRecipe => catalog.firstWhere((r) => r.destacada);

/// Aplica búsqueda por texto y filtro de categoría sobre el catálogo.
List<Recipe> filtrarRecetas(
  List<Recipe> origen,
  String query,
  String categoria,
) {
  final termino = query.trim().toLowerCase();
  return origen.where((r) {
    final matchCategoria = categoria == 'Todas' || r.categoria == categoria;
    final matchNombre = r.nombre.toLowerCase().contains(termino);
    final matchIngrediente =
        r.descripcion.toLowerCase().contains(termino);
    return matchCategoria && (termino.isEmpty || matchNombre || matchIngrediente);
  }).toList();
}