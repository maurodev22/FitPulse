/// Fase 6: lógica pura de avisos locales y widget de home.
///
/// Nada de esto toca plugins nativos: son cálculos deterministas y testeables
/// (próxima hora local, textos con la racha real, snapshot JSON del widget).
/// Los valores que muestra el widget SIEMPRE vienen de datos reales de la app
/// (pasos del sensor, gasto activo de Health Connect si hay permiso + dato,
/// racha del historial real); si no hay dato → "—" (nunca inventado).
library;

/// IDs de notificación fijos por tipo de aviso (Fase 6).
///
/// - [hidratacionAvisoId]: recordatorio de hidratación (periódico).
/// - [rachaAvisoId]: aviso diario de racha en riesgo (20:00).
abstract final class AvisosIds {
  static const int hidratacion = 9001;
  static const int racha = 9002;
}

/// Devuelve la próxima ocurrencia local de [hora]:[minuto] a partir de [ahora]
/// (hoy si aún no ha pasado, mañana en caso contrario).
///
/// Se usa para programar el aviso diario de la racha a las 20:00 locales sin
/// depender de librerías de zona horaria: el instante absoluto resultante se
/// obtiene con `.millisecondsSinceEpoch`, que ya es correcto en hora local.
DateTime proximaHoraLocal(DateTime ahora, int hora, int minuto) {
  var d = DateTime(ahora.year, ahora.month, ahora.day, hora, minuto);
  if (!d.isAfter(ahora)) {
    d = d.add(const Duration(days: 1));
  }
  return d;
}

/// Convierte un [DateTime] local en un instante absoluto UTC (epoch).
///
/// `tz.TZDateTime.from(instanteUtc, tz.UTC)` conserva exactamente el mismo
/// instante; así se programa `zonedSchedule` sin librería de zona horaria.
DateTime comoInstantUtc(DateTime local) {
  return DateTime.fromMillisecondsSinceEpoch(
    local.millisecondsSinceEpoch,
    isUtc: true,
  );
}

/// Texto honesto del aviso diario de racha según los días reales de racha.
String textoAvisoRacha(int rachaDias) {
  if (rachaDias <= 0) {
    return 'Aún no tienes racha. Completa una sesión hoy para empezar 💪';
  }
  if (rachaDias == 1) {
    return 'Llevas 1 día de racha. Entrena hoy para no cortarla 🏃';
  }
  return 'Llevas $rachaDias días de racha. Entrena hoy para no cortarla 🏃';
}

/// Construye el snapshot JSON que se envía al widget nativo de home.
///
/// - [pasos]: pasos reales de hoy (sensor del teléfono).
/// - [calorias]: gasto activo real de Health Connect, o `null` si no hay
///   permiso + dato (el widget mostrará "—").
/// - [racha]: días de racha reales del historial.
/// - [fecha]: día en formato ISO (yyyy-MM-dd) para refresco del widget.
String construirSnapshotWidget({
  required int pasos,
  double? calorias,
  required int racha,
  required String fecha,
}) {
  return '{"fecha":"$fecha","pasos":$pasos,'
      '"calorias":${calorias == null ? 'null' : calorias.round()},'
      '"racha":$racha}';
}