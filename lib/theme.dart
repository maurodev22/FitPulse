import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFFF8FAF8);
  static const surface = Color(0xFFF8FAF8);
  static const surfaceLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF2F4F2);
  static const surfaceContainer = Color(0xFFECEEEC);
  static const surfaceContainerHigh = Color(0xFFE6E9E7);
  static const surfaceContainerHighest = Color(0xFFE1E3E1);
  static const onSurface = Color(0xFF191C1B);
  static const onSurfaceVariant = Color(0xFF3F4943);
  static const outline = Color(0xFF6F7A72);
  static const outlineVariant = Color(0xFFBEC9C0);

  static const primary = Color(0xFF005136);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF006C49);
  static const onPrimaryContainer = Color(0xFF93EABE);
  static const inversePrimary = Color(0xFF81D8AD);

  static const secondaryContainer = Color(0xFF6CF8BB);
  static const onSecondaryContainer = Color(0xFF00714D);
  static const secondaryFixed = Color(0xFF6FFBBE);
  static const secondaryFixedDim = Color(0xFF4EDEA3);
  static const onSecondaryFixed = Color(0xFF002113);

  static const tertiaryContainer = Color(0xFF006C4A);
  static const onTertiaryContainer = Color(0xFF64F1B5);

  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);
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

ThemeData buildFitPulseTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    inversePrimary: AppColors.inversePrimary,
    secondary: AppColors.primary,
    onSecondary: AppColors.onPrimary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.primary,
    onTertiary: AppColors.onPrimary,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    error: AppColors.error,
    onError: Colors.white,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceContainerLowest: AppColors.surfaceLowest,
    surfaceContainerLow: AppColors.surfaceContainerLow,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerHigh: AppColors.surfaceContainerHigh,
    surfaceContainerHighest: AppColors.surfaceContainerHighest,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    inverseSurface: Color(0xFF2E3130),
    onInverseSurface: Color(0xFFEFF1EF),
    surfaceTint: AppColors.primary,
    shadow: AppColors.primaryContainer,
    scrim: Colors.black,
  );

  final baseTextTheme = Typography.material2021().black.apply(
        fontFamily: AppType.body,
        bodyColor: AppColors.onSurface,
        displayColor: AppColors.onSurface,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
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
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    iconTheme: const IconThemeData(color: AppColors.onSurfaceVariant),
    dividerTheme: const DividerThemeData(
      color: AppColors.surfaceContainer,
      thickness: 1,
      space: 0,
    ),
  );
}