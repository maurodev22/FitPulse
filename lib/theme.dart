import 'dart:math';

import 'package:flutter/material.dart';

/// Desactiva el glow/overscroll blanco del sistema: al hacer scroll hasta el
/// borde, Android pinta una línea o brillo blancuzco que distorsiona la vista.
class NoGlowScrollBehavior extends MaterialScrollBehavior {
  const NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

/// Paleta semántica concreta (clara u oscura).
///
/// Cada rol tiene un significado fijo; solo cambian los valores según el
/// brillo. El contraste de los pares críticos se verifica por test (WCAG AA).
class FitPalette {
  const FitPalette({
    required this.background,
    required this.surface,
    required this.surfaceLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.inversePrimary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.secondaryFixed,
    required this.secondaryFixedDim,
    required this.onSecondaryFixed,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.inverseSurface,
    required this.onInverseSurface,
  });

  final Color background;
  final Color surface;
  final Color surfaceLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color inversePrimary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color secondaryFixed;
  final Color secondaryFixedDim;
  final Color onSecondaryFixed;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color inverseSurface;
  final Color onInverseSurface;

  /// Contraste de [a] sobre [b] según WCAG 2.x (ratio, ≥ 4.5 texto normal,
  /// ≥ 3.0 UI/iconos). Público para el test de accesibilidad.
  static double contraste(Color a, Color b) {
    final la = _luminancia(a);
    final lb = _luminancia(b);
    final clara = la > lb ? la : lb;
    final oscura = la > lb ? lb : la;
    return (clara + 0.05) / (oscura + 0.05);
  }

  static double _luminancia(Color c) {
    double lin(double v) {
      if (v <= 0.04045) return v / 12.92;
      return pow((v + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
  }
}

/// Paleta clara (idéntica a la histórica de FitPulse: ningún cambio visual).
const FitPalette lightFitPalette = FitPalette(
  background: Color(0xFFF8FAF8),
  surface: Color(0xFFF8FAF8),
  surfaceLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFF2F4F2),
  surfaceContainer: Color(0xFFECEEEC),
  surfaceContainerHigh: Color(0xFFE6E9E7),
  surfaceContainerHighest: Color(0xFFE1E3E1),
  onSurface: Color(0xFF191C1B),
  onSurfaceVariant: Color(0xFF3F4943),
  outline: Color(0xFF5F6B62),
  outlineVariant: Color(0xFFBEC9C0),
  primary: Color(0xFF005136),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFF006C49),
  onPrimaryContainer: Color(0xFF93EABE),
  inversePrimary: Color(0xFF81D8AD),
  secondaryContainer: Color(0xFF6CF8BB),
  onSecondaryContainer: Color(0xFF00714D),
  secondaryFixed: Color(0xFF6FFBBE),
  secondaryFixedDim: Color(0xFF4EDEA3),
  onSecondaryFixed: Color(0xFF002113),
  tertiaryContainer: Color(0xFF006C4A),
  onTertiaryContainer: Color(0xFF64F1B5),
  error: Color(0xFFBA1A1A),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFFDAD6),
  onErrorContainer: Color(0xFF93000A),
  inverseSurface: Color(0xFF2E3130),
  onInverseSurface: Color(0xFFEFF1EF),
);

/// Paleta oscura (contraste WCAG AA verificado por test de accesibilidad).
///
/// Espeja los roles semánticos de la paleta clara con luminancias invertidas:
/// superficies muy oscuras y textos/acentos claros.
const FitPalette darkFitPalette = FitPalette(
  background: Color(0xFF101412),
  surface: Color(0xFF101412),
  surfaceLowest: Color(0xFF0A0D0B),
  surfaceContainerLow: Color(0xFF161B18),
  surfaceContainer: Color(0xFF1B211D),
  surfaceContainerHigh: Color(0xFF202623),
  surfaceContainerHighest: Color(0xFF252C28),
  onSurface: Color(0xFFE1E7E1),
  onSurfaceVariant: Color(0xFFBDC7BF),
  outline: Color(0xFF87958B),
  outlineVariant: Color(0xFF3F4A43),
  primary: Color(0xFF7DD6A6),
  onPrimary: Color(0xFF00351F),
  primaryContainer: Color(0xFF005C3E),
  onPrimaryContainer: Color(0xFF9AF3C4),
  inversePrimary: Color(0xFF006C49),
  secondaryContainer: Color(0xFF005C41),
  onSecondaryContainer: Color(0xFF7DE8B5),
  secondaryFixed: Color(0xFF6FFBBE),
  secondaryFixedDim: Color(0xFF4EDEA3),
  onSecondaryFixed: Color(0xFF002113),
  tertiaryContainer: Color(0xFF006C4A),
  onTertiaryContainer: Color(0xFFA0F0C6),
  error: Color(0xFFFFB4AB),
  onError: Color(0xFF330000),
  errorContainer: Color(0xFF93000A),
  onErrorContainer: Color(0xFFFFDAD6),
  inverseSurface: Color(0xFFE1E7E1),
  onInverseSurface: Color(0xFF101412),
);

/// Colores de marca: delegan en la paleta activa (clara u oscura).
///
/// El `MaterialApp` (Fase 7) fija [`AppColors.active`] según el brillo del
/// tema resuelto; así todas las pantallas se adaptan sin tocar cada sitio.
abstract final class AppColors {
  static FitPalette _active = lightFitPalette;

  /// Paleta vigente (clara por defecto, oscura en modo oscuro).
  static FitPalette get active => _active;

  /// Cambia la paleta activa. Lo llama el tema raíz en cada rebuild.
  static void activate(FitPalette palette) {
    _active = palette;
  }

  static Color get background => _active.background;
  static Color get surface => _active.surface;
  static Color get surfaceLowest => _active.surfaceLowest;
  static Color get surfaceContainerLow => _active.surfaceContainerLow;
  static Color get surfaceContainer => _active.surfaceContainer;
  static Color get surfaceContainerHigh => _active.surfaceContainerHigh;
  static Color get surfaceContainerHighest => _active.surfaceContainerHighest;
  static Color get onSurface => _active.onSurface;
  static Color get onSurfaceVariant => _active.onSurfaceVariant;
  static Color get outline => _active.outline;
  static Color get outlineVariant => _active.outlineVariant;
  static Color get primary => _active.primary;
  static Color get onPrimary => _active.onPrimary;
  static Color get primaryContainer => _active.primaryContainer;
  static Color get onPrimaryContainer => _active.onPrimaryContainer;
  static Color get inversePrimary => _active.inversePrimary;
  static Color get secondaryContainer => _active.secondaryContainer;
  static Color get onSecondaryContainer => _active.onSecondaryContainer;
  static Color get secondaryFixed => _active.secondaryFixed;
  static Color get secondaryFixedDim => _active.secondaryFixedDim;
  static Color get onSecondaryFixed => _active.onSecondaryFixed;
  static Color get tertiaryContainer => _active.tertiaryContainer;
  static Color get onTertiaryContainer => _active.onTertiaryContainer;
  static Color get error => _active.error;
  static Color get onError => _active.onError;
  static Color get errorContainer => _active.errorContainer;
  static Color get onErrorContainer => _active.onErrorContainer;
  static Color get inverseSurface => _active.inverseSurface;
  static Color get onInverseSurface => _active.onInverseSurface;
}

abstract final class AppType {
  static const String headline = 'PlusJakartaSans';
  static const String body = 'Inter';

  static const displayLg = TextStyle(
    fontFamily: headline,
    fontSize: 44,
    height: 52 / 44,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.3,
  );

  static const displayLgMobile = TextStyle(
    fontFamily: headline,
    fontSize: 36,
    height: 44 / 36,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.7,
  );

  static const headlineLg = TextStyle(
    fontFamily: headline,
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
  );

  static const headlineMd = TextStyle(
    fontFamily: headline,
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  static const headlineSm = TextStyle(
    fontFamily: headline,
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
  );

  static const bodyLg = TextStyle(
    fontFamily: body,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
  );

  static const bodyMd = TextStyle(
    fontFamily: body,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
  );

  static const bodySm = TextStyle(
    fontFamily: body,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
  );

  static const labelLg = TextStyle(
    fontFamily: body,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static const labelMd = TextStyle(
    fontFamily: body,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static const labelSm = TextStyle(
    fontFamily: body,
    fontSize: 10,
    height: 14 / 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
  );

  static const metricVal = TextStyle(
    fontFamily: headline,
    fontSize: 28,
    height: 32 / 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.55,
  );
}

/// Tema de FitPulse (claro u oscuro). Al elegir `brightness` se emplea la
/// paleta correspondiente (ver [lightFitPalette] / [darkFitPalette]).
ThemeData buildFitPulseTheme({Brightness brightness = Brightness.light}) {
  final p = brightness == Brightness.dark ? darkFitPalette : lightFitPalette;
  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: p.primary,
    onPrimary: p.onPrimary,
    primaryContainer: p.primaryContainer,
    onPrimaryContainer: p.onPrimaryContainer,
    inversePrimary: p.inversePrimary,
    secondary: p.primary,
    onSecondary: p.onPrimary,
    secondaryContainer: p.secondaryContainer,
    onSecondaryContainer: p.onSecondaryContainer,
    tertiary: p.primary,
    onTertiary: p.onPrimary,
    tertiaryContainer: p.tertiaryContainer,
    onTertiaryContainer: p.onTertiaryContainer,
    error: p.error,
    onError: p.onError,
    errorContainer: p.errorContainer,
    onErrorContainer: p.onErrorContainer,
    surface: p.surface,
    onSurface: p.onSurface,
    surfaceContainerLowest: p.surfaceLowest,
    surfaceContainerLow: p.surfaceContainerLow,
    surfaceContainer: p.surfaceContainer,
    surfaceContainerHigh: p.surfaceContainerHigh,
    surfaceContainerHighest: p.surfaceContainerHighest,
    onSurfaceVariant: p.onSurfaceVariant,
    outline: p.outline,
    outlineVariant: p.outlineVariant,
    inverseSurface: p.inverseSurface,
    onInverseSurface: p.onInverseSurface,
    surfaceTint: p.primary,
    shadow: p.primaryContainer,
    scrim: Colors.black,
  );

  final baseTextTheme = (brightness == Brightness.dark
          ? Typography.material2021().white
          : Typography.material2021().black)
      .apply(
        fontFamily: AppType.body,
        bodyColor: p.onSurface,
        displayColor: p.onSurface,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: p.background,
    splashFactory: InkSparkle.splashFactory,
    textTheme: baseTextTheme.copyWith(
      displayLarge: AppType.displayLg,
      headlineLarge: AppType.headlineLg,
      headlineMedium: AppType.headlineMd,
      headlineSmall: AppType.headlineSm,
      bodyLarge: AppType.bodyLg,
      bodyMedium: AppType.bodyMd,
      bodySmall: AppType.bodySm,
      labelLarge: AppType.labelLg,
      labelMedium: AppType.labelMd,
      labelSmall: AppType.labelSm,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    iconTheme: IconThemeData(color: p.onSurfaceVariant),
    dividerTheme: DividerThemeData(
      color: p.surfaceContainer,
      thickness: 1,
      space: 0,
    ),
  );
}