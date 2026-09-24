/// Reglas de validación oficiales de FitPulse.
abstract final class Validators {
  static const minEdad = 16;
  static const maxEdad = 85;
  static const minPesoKg = 45.0;
  static const maxPesoKg = 300.0;
  static const minAlturaM = 1.20;
  static const maxAlturaM = 2.10;

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
}