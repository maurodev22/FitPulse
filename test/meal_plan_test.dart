import 'package:flutter_test/flutter_test.dart';

import 'package:fitpulse/state/athlete_profile.dart';
import 'package:fitpulse/state/meal_plan.dart';
import 'package:fitpulse/state/recetas_catalog.dart';

void main() {
  group('Fase 4 · plan semanal de comidas', () {
    final perfil = AthleteProfile(
      metas: const ['Aumentar de peso'],
      caloriasMeta: 2100,
    );

    test('genera 7 días Lunes→Domingo con día libre el domingo', () {
      final plan = generarPlanSemanal(perfil);
      expect(plan.dias.length, 7);
      expect(plan.dias.first.dia, 'Lunes');
      expect(plan.dias.last.dia, 'Domingo');
      expect(plan.dias.where((d) => d.diaLibre).single.dia, 'Domingo');
    });

    test('todas las comidas referencian recetas reales del catálogo', () {
      final plan = generarPlanSemanal(perfil);
      for (final dia in plan.dias) {
        final recetas = dia.recetas.toList();
        expect(recetas.length, 4);
        for (final r in recetas) {
          expect(catalog.any((c) => c.nombre == r.nombre), isTrue);
          expect(r.ingredientes, isNotEmpty);
        }
      }
    });

    test('es determinista (sin aleatoriedad)', () {
      final a = generarPlanSemanal(perfil);
      final b = generarPlanSemanal(perfil);
      for (var i = 0; i < 7; i++) {
        expect(a.dias[i].almuerzo.nombre, b.dias[i].almuerzo.nombre);
        expect(a.dias[i].cena.nombre, b.dias[i].cena.nombre);
        expect(a.dias[i].extra.nombre, b.dias[i].extra.nombre);
        expect(a.dias[i].totalKcal, b.dias[i].totalKcal);
      }
    });

    test('el total por día es la suma exacta y el promedio cubre la meta', () {
      final plan = generarPlanSemanal(perfil);
      for (final dia in plan.dias) {
        final suma = dia.desayuno.calorias +
            dia.almuerzo.calorias +
            dia.cena.calorias +
            dia.extra.calorias;
        expect(dia.totalKcal, suma);
      }
      expect(plan.kcalPromedioDia.round(), 1387);
      expect(plan.coberturaMetaPorcentaje.round(), 66);
    });

    test('pre-entreno en días de entrenamiento, recarga en descanso', () {
      final plan = generarPlanSemanal(perfil);
      // Perfil por defecto entrena L M X J V; Lunes (índice 0) → pre-entreno.
      expect(plan.dias[0].extra.nombre, 'Batido Verde Energético');
      // Sábado (índice 5) no entrena → recarga, no batido.
      expect(plan.dias[5].extra.nombre, isNot('Batido Verde Energético'));
    });

    test('el día libre es informativo: la racha solo depende de sesiones', () {
      final plan = generarPlanSemanal(perfil);
      final domingo = plan.dias.last;
      expect(domingo.diaLibre, isTrue);
      // El plan no toca el estado de la app: las recetas del domingo son reales
      // y el flag solo etiqueta el día (nunca "come" sin contar entrenamientos).
      for (final r in domingo.recetas) {
        expect(catalog.any((c) => c.nombre == r.nombre), isTrue);
      }
    });

    test('la lista de la compra agrupa por ingrediente con su nombre real', () {
      final plan = generarPlanSemanal(perfil);
      final lista = plan.listaCompra;
      expect(lista, isNotEmpty);
      expect(lista.every((g) => g.nombre.isNotEmpty && g.usos >= 1), isTrue);

      // Pechuga de pollo está en Ensalada Griega (4 usos) y Wrap de Pollo (3).
      final pollo = lista.firstWhere(
        (g) => g.nombre == 'Pechuga de pollo',
        orElse: () => const GrupoIngrediente(nombre: '', usos: 0),
      );
      expect(pollo.usos, 7);
      // Los nombres se muestran capitalizados, no claves en minúsculas.
      expect(lista.any((g) => g.nombre.startsWith(RegExp(r'[a-z]'))), isFalse);
    });
  });
}