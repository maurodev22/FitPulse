import 'recipe_model.dart';
import 'recetas_por_meta.dart';

export 'recipe_model.dart';

/// Metas del perfil Reconocidas por el catálogo (L4).
///
/// Son **exactamente** los valores que guarda `AthleteProfile.metas` en el
/// registro, para que el filtro nunca tenga que traducir ni adivinar: si la app
/// escribe 'Bajar de peso', el catálogo busca 'Bajar de peso'.
const metasCatalogo = <String>[
  'Bajar de peso',
  'Definir',
  'Aumentar de peso',
  'Mantener',
];

/// Catálogo base: las recetas originales de las primeras fases.
///
/// Se mantienen intactas (mismo orden, misma receta destacada) y ahora cada
/// una declara sus metas con criterio nutricional: las raciones bajas en
/// hidrato de carbono van con 'Bajar de peso' y 'Definir', las de alta proteína
/// con 'Definir' y 'Aumentar de peso', y las de hidratos con 'Mantener' y
/// 'Aumentar de peso'.
const recetasBase = <Recipe>[
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
    ingredientes: [
      Ingrediente('Salmón', '150 g'),
      Ingrediente('Quinoa cocida', '120 g'),
      Ingrediente('Aguacate', '½ unidad'),
      Ingrediente('Espinacas', '1 puñado'),
      Ingrediente('Limón', '½ unidad'),
    ],
    destacada: true,
    metas: ['Definir', 'Aumentar de peso'],
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
    ingredientes: [
      Ingrediente('Avena integral', '80 g'),
      Ingrediente('Proteína whey', '1 scoop (30 g)'),
      Ingrediente('Huevo', '1 unidad'),
      Ingrediente('Plátano', '1 unidad'),
      Ingrediente('Canela', 'al gusto'),
    ],
    metas: ['Aumentar de peso', 'Mantener'],
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
    ingredientes: [
      Ingrediente('Pechuga de pollo', '150 g'),
      Ingrediente('Tomate', '1 unidad'),
      Ingrediente('Pepino', '½ unidad'),
      Ingrediente('Aceitunas', '50 g'),
      Ingrediente('Queso feta', '40 g'),
    ],
    metas: ['Bajar de peso', 'Definir'],
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
    ingredientes: [
      Ingrediente('Espinacas', '1 puñado'),
      Ingrediente('Plátano', '1 unidad'),
      Ingrediente('Jengibre', '1 trozo pequeño'),
      Ingrediente('Proteína vegetal', '1 scoop (30 g)'),
    ],
    metas: ['Mantener', 'Aumentar de peso'],
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
    ingredientes: [
      Ingrediente('Tortilla integral', '1 unidad'),
      Ingrediente('Pechuga de pollo', '120 g'),
      Ingrediente('Aguacate', '½ unidad'),
      Ingrediente('Espinacas', '1 puñado'),
    ],
    metas: ['Aumentar de peso', 'Definir'],
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
    ingredientes: [
      Ingrediente('Avena integral', '60 g'),
      Ingrediente('Yogur griego', '150 g'),
      Ingrediente('Proteína whey', '1 scoop (30 g)'),
      Ingrediente('Semillas de chía', '1 cda'),
    ],
    metas: ['Aumentar de peso', 'Mantener'],
  ),
];

/// Catálogo completo de recetas de la app: las recetas base seguidas del
/// catálogo ampliado por metas (L4).
///
/// El orden es intencionado: las primeras siguen siendo las mismas, así que
/// `featuredRecipe` y el generador del plan semanal (`meal_plan.dart`, que
/// busca por nombre) no cambian de comportamiento.
const catalog = <Recipe>[
  ...recetasBase,
  ...recetasPorMeta,
];

/// Receta destacada del día (la primera marcada como destacada en el catálogo).
Recipe get featuredRecipe => catalog.firstWhere((r) => r.destacada);

/// Recetas marcadas para una meta del perfil, en el orden del catálogo.
///
/// Una meta vacía o desconocida devuelve el catálogo entero en vez de una lista
/// vacía: si el usuario no ha elegido meta, no se le esconde la comida.
List<Recipe> recetasParaMeta(List<Recipe> origen, String meta) {
  if (meta.trim().isEmpty) return List<Recipe>.of(origen);
  return origen.where((r) => r.sirveParaMeta(meta)).toList();
}

/// Número de recetas etiquetadas para cada meta del catálogo.
Map<String, int> conteoPorMeta(List<Recipe> origen) {
  final conteo = <String, int>{for (final m in metasCatalogo) m: 0};
  for (final receta in origen) {
    for (final meta in receta.metas) {
      conteo[meta] = (conteo[meta] ?? 0) + 1;
    }
  }
  return conteo;
}

/// Aplica búsqueda por texto, filtro de categoría y filtro por meta sobre el
/// catálogo.
///
/// Los tres filtros se combinan con Y lógica: categoría vacía o 'Todas' y meta
/// vacía no restringen nada, de modo que las llamadas existentes siguen
/// funcionando igual.
List<Recipe> filtrarRecetas(
  List<Recipe> origen,
  String query,
  String categoria, {
  String meta = '',
}) {
  final termino = query.trim().toLowerCase();
  final porMeta = recetasParaMeta(origen, meta);
  return porMeta.where((r) {
    final matchCategoria = categoria == 'Todas' || r.categoria == categoria;
    final matchNombre = r.nombre.toLowerCase().contains(termino);
    final matchIngrediente = r.descripcion.toLowerCase().contains(termino);
    return matchCategoria && (termino.isEmpty || matchNombre || matchIngrediente);
  }).toList();
}
