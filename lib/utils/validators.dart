/// Reglas de validación oficiales de FitPulse.
abstract final class Validators {
  static const minEdad = 16;
  static const maxEdad = 85;
  static const minPesoKg = 45.0;
  static const maxPesoKg = 300.0;
  static const minAlturaM = 1.20;
  static const maxAlturaM = 2.10;

  /// Repeticiones mínimas honestas: nadie "completa" 0 repeticiones de un
  /// ejercicio. 0 se interpreta como "no pude" y se responde motivando.
  static const int minReps = 1;

  /// Límite diario plausible de agua (litros): ningún humano declara más de
  /// 5 L. Por encima se trata como un error de sinceridad, no como un dato.
  static const double maxAguaDiariaLitros = 5.0;

  /// Metas de actividad honestas (Perfil): el mínimo de pasos es 1000 (una
  /// meta de 0–999 pasos no es una meta de caminar) y el mínimo de calorías
  /// diarias es 1200 kcal (suelo nutricional seguro según guías médicas; por
  /// debajo hay riesgo de déficit sin supervisión profesional).
  static const int minPasosMeta = 1000;
  static const int maxPasosMeta = 100000;
  static const double minKcalMeta = 1200.0;
  static const double maxKcalMeta = 10000.0;

  /// Meta diaria de agua (L2): rango editable por el usuario. Por debajo de
  /// 0,5 L no es una meta de hidratación y por encima de 10 L ningún día
  /// normal lo justifica; el valor inicial es 2,5 L (≈35 ml/kg).
  static const double minMetaAguaLitros = 0.5;
  static const double maxMetaAguaLitros = 10.0;

  static final RegExp _nombreRe = RegExp(r"^[A-Za-zÁÉÍÓÚáéíóúÑñÜü' ]+$");

  /// Valida el nombre completo (3-60, solo letras/espacios/apóstrofes).
  static String? validarNombre(String? raw) {
    final name = raw?.trim() ?? '';
    if (name.isEmpty) return 'Escribe tu nombre completo';
    if (!_nombreRe.hasMatch(name)) return 'El nombre solo admite letras y espacios';
    if (name.length < 3) return 'El nombre debe tener al menos 3 caracteres';
    if (name.length > 60) return 'El nombre no puede superar 60 caracteres';
    return null;
  }

  /// Valida un entero (edad) dentro del rango oficial.
  static String? validarEdad(double value) {
    if (value < minEdad || value > maxEdad) {
      return 'La edad debe estar entre $minEdad y $maxEdad años';
    }
    return null;
  }

  /// Valida el peso en kg dentro del rango oficial (45-300).
  static String? validarPeso(double value) {
    if (value < minPesoKg || value > maxPesoKg) {
      return 'El peso debe estar entre $minPesoKg y $maxPesoKg kg';
    }
    return null;
  }

  /// Valida la altura en metros dentro del rango oficial (1.20-2.10).
  static String? validarAltura(double value) {
    if (value < minAlturaM || value > maxAlturaM) {
      return 'La altura debe estar entre ${minAlturaM.toStringAsFixed(2)} y ${maxAlturaM.toStringAsFixed(2)} m';
    }
    return null;
  }

  /// Valida las repeticiones completadas de un ejercicio. 0 no es una cuenta
  /// real: o fue un error, o la persona no pudo; en ambos casos se motiva a
  /// conseguir al menos 1 repetición más. `esfuerzate` es el mensaje
  /// localizado que el llamador quiera mostrar cuando la validación falle.
  static String? validarReps(int reps, String esfuerzate) {
    if (reps < minReps) return esfuerzate;
    return null;
  }

  /// Valida el agua declarada del día: la cantidad añadida no puede superar el
  /// tope diario plausible (5 L). Devuelve el mensaje de sinceridad `mensaje`
  /// si el total del día (lo ya registrado + lo nuevo) se pasa del límite.
  static String? validarAguaDiaria(double totalDelDia, String mensaje) {
    if (totalDelDia > maxAguaDiariaLitros) return mensaje;
    return null;
  }

  /// Valida la meta diaria de pasos (1000–100000). `mensaje` es el texto
  /// localizado que el llamador quiera mostrar si el valor queda fuera.
  static String? validarMetaPasos(int? pasos, String mensaje) {
    if (pasos == null || pasos < minPasosMeta || pasos > maxPasosMeta) {
      return mensaje;
    }
    return null;
  }

  /// Valida la meta diaria de calorías (1200–10000 kcal). `mensaje` es el
  /// texto localizado que el llamador quiera mostrar si el valor queda fuera.
  static String? validarMetaKcal(double? kcal, String mensaje) {
    if (kcal == null || kcal < minKcalMeta || kcal > maxKcalMeta) {
      return mensaje;
    }
    return null;
  }

  /// Ajusta la meta diaria de agua al rango plausible (0,5–10 L). Devuelve el
  /// valor corregido, para que la UI nunca pueda quedar fuera de rango.
  static double ajustarMetaAgua(double litros) =>
      litros.clamp(minMetaAguaLitros, maxMetaAguaLitros);
}