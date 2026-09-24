import 'athlete_profile.dart';
import 'recetas_catalog.dart';

/// Fase 4: plan semanal de comidas construido SOLO con recetas reales del
/// catálogo (`recetas_catalog.dart`) y los datos del perfil del atleta.
///
/// Sin datos inventados: los totales se calculan sumando las recetas asignadas
/// y la cobertura frente a la meta es honesta (el plan base puede requerir
/// ajustar el tamaño de las raciones).

/// Un día del plan con sus cuatro comidas (referencias al catálogo real).
class DiaPlan {
  const DiaPlan({
    required this.dia,
    required this.desayuno,
    required this.almuerzo,
    required this.cena,
    required this.extra,
    this.diaLibre = false,
  });

  final String dia;
  final Recipe desayuno;
  final Recipe almuerzo;
  final Recipe cena;

  /// Comida extra según el día: pre-entreno (entrena) o recarga (descansa).
  final Recipe extra;

  /// Día libre planificado (cheat meal): NO penaliza la racha de sesiones.
  final bool diaLibre;

  double get totalKcal =>
      desayuno.calorias + almuerzo.calorias + cena.calorias + extra.calorias;

  double get totalProteinas =>
      desayuno.proteinas + almuerzo.proteinas + cena.proteinas + extra.proteinas;

  double get totalCarbos =>
      desayuno.carbos + almuerzo.carbos + cena.carbos + extra.carbos;

  double get totalGrasas =>
      desayuno.grasas + almuerzo.grasas + cena.grasas + extra.grasas;

  /// Recetas usadas en el día (únicas, para la lista de la compra).
  Iterable<Recipe> get recetas => {desayuno, almuerzo, cena, extra};
}

/// Ingrediente agregado de toda la semana: cuántas veces aparece y en cuántos
/// días (las cantidades por ración están en cada receta del catálogo).
class GrupoIngrediente {
  const GrupoIngrediente({
    required this.nombre,
    required this.usos,
  });

  final String nombre;
  final int usos;
}

/// Plan de 7 días (lunes → domingo) y su lista de la compra.
class PlanSemanal {
  const PlanSemanal({required this.dias, required this.perfil});

  final List<DiaPlan> dias;
  final AthleteProfile perfil;

  /// Promedio de kcal por día calculado de las recetas asignadas.
  double get kcalPromedioDia =>
      dias.isEmpty ? 0 : dias.fold<double>(0, (s, d) => s + d.totalKcal) / dias.length;

  /// Cobertura honesta del plan base frente a la meta calórica del atleta (%).
  double get coberturaMetaPorcentaje =>
      perfil.caloriasMeta <= 0 ? 0 : kcalPromedioDia / perfil.caloriasMeta * 100;

  /// Lista de la compra semanal: agrupa ingredientes por nombre contando
  /// cuántos días/recetas los usan.
  List<GrupoIngrediente> get listaCompra {
    final conteo = <String, ({String nombre, int usos})>{};
    for (final dia in dias) {
      for (final receta in dia.recetas) {
        for (final ing in receta.ingredientes) {
          final clave = ing.nombre.trim().toLowerCase();
          if (clave.isEmpty) continue;
          final prev = conteo[clave];
          conteo[clave] = (
            nombre: prev?.nombre ?? ing.nombre.trim(),
            usos: (prev?.usos ?? 0) + 1,
          );
        }
      }
    }
    final lista = conteo.values
        .map((e) => GrupoIngrediente(nombre: e.nombre, usos: e.usos))
        .toList()
      ..sort((a, b) {
        final cmp = b.usos.compareTo(a.usos);
        return cmp != 0 ? cmp : a.nombre.compareTo(b.nombre);
      });
    return lista;
  }
}

/// Letras de la semana (formato guardado en el perfil) por índice de día.
const List<String> _letrasDias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

const List<String> _nombresDias = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

/// Genera el plan semanal determinista a partir del perfil del atleta.
///
/// Reglas (sin aleatoriedad, reproducible y testeable):
/// - Desayuno: Pancakes de Avena & Proteína (única receta tipo 'Desayuno').
/// - Almuerzo alterna Bowl de Salmón / Ensalada Griega; la cena alterna Avena
///   Nocturna / Wrap de Pollo.
/// - Extra: días de entrenamiento = Batido Verde (pre-entreno); días libres =
///   el plato principal alternativo (Ensalada o Bowl).
/// - Domingo (último día) = día libre planificado (cheat meal): no penaliza
///   la racha de sesiones, que solo depende de entrenamientos completados.
PlanSemanal generarPlanSemanal(AthleteProfile perfil) {
  final entrenos = perfil.diasEntrenamiento.toSet();
  final dias = <DiaPlan>[];

  final pancake = _r('Pancakes de Avena & Proteína');
  final bowl = _r('Bowl de Salmón, Aguacate y Quinoa');
  final ensalada = _r('Ensalada Griega con Pechuga');
  final batido = _r('Batido Verde Energético');
  final wrap = _r('Wrap de Pollo y Aguacate');
  final avenaNoche = _r('Avena Nocturna con Proteína');

  for (var i = 0; i < 7; i++) {
    final entrenando = entrenos.contains(_letrasDias[i]);
    dias.add(DiaPlan(
      dia: _nombresDias[i],
      desayuno: pancake,
      almuerzo: i.isEven ? bowl : ensalada,
      cena: i.isEven ? avenaNoche : wrap,
      extra: entrenando ? batido : (i.isEven ? ensalada : bowl),
      diaLibre: i == 6, // Domingo: día libre planificado.
    ));
  }
  return PlanSemanal(dias: dias, perfil: perfil);
}

/// Busca una receta del catálogo por nombre (siempre existe: catálogo cerrado).
Recipe _r(String nombre) => catalog.firstWhere((r) => r.nombre == nombre);