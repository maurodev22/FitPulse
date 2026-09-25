import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitpulse/main.dart';
import 'package:fitpulse/theme.dart';

/// Fase 7: verifica el contraste WCAG AA de ambas paletas (texto ≥ 4.5:1,
/// UI/iconos ≥ 3:1) y que la paleta activa sigue al tema resuelto.
void main() {
  group('Paletas WCAG AA', () {
    void verificarPaleta(FitPalette p, String nombre) {
      double contraste(Color a, Color b) => FitPalette.contraste(a, b);

      // Pares de TEXTO normal (≥ 4.5:1).
      final paresTexto = <(Color, Color)>[
        (p.onSurface, p.background),
        (p.onSurface, p.surface),
        (p.onSurfaceVariant, p.surface),
        (p.onSurfaceVariant, p.surfaceContainerHighest),
        (p.primary, p.background),
        (p.onPrimary, p.primary),
        (p.onPrimaryContainer, p.primaryContainer),
        (p.onSecondaryContainer, p.secondaryContainer),
        (p.onTertiaryContainer, p.tertiaryContainer),
        (p.onSecondaryFixed, p.secondaryFixed),
        (p.error, p.background),
        (p.error, p.surface),
        (p.onErrorContainer, p.errorContainer),
        (p.onInverseSurface, p.inverseSurface),
      ];
      for (final (fg, bg) in paresTexto) {
        expect(contraste(fg, bg), greaterThanOrEqualTo(4.5),
            reason: '$nombre: $fg sobre $bg = '
                '${contraste(fg, bg).toStringAsFixed(2)}:1 (mín. 4.5)');
      }

      // Pares de UI/iconos (≥ 3:1).
      final paresUi = <(Color, Color)>[
        (p.outline, p.background),
        (p.outline, p.surface),
        (p.primary, p.surfaceContainerLow),
        (p.error, p.surfaceContainerLow),
      ];
      for (final (fg, bg) in paresUi) {
        expect(contraste(fg, bg), greaterThanOrEqualTo(3.0),
            reason: '$nombre (UI): $fg sobre $bg = '
                '${contraste(fg, bg).toStringAsFixed(2)}:1 (mín. 3.0)');
      }
    }

    test('paleta clara cumple AA', () {
      verificarPaleta(lightFitPalette, 'clara');
    });

    test('paleta oscura cumple AA', () {
      verificarPaleta(darkFitPalette, 'oscura');
    });
  });

  test('AppColors activa sigue a la paleta elegida', () {
    AppColors.activate(lightFitPalette);
    expect(AppColors.background, lightFitPalette.background);
    expect(AppColors.primary, lightFitPalette.primary);
    expect(AppColors.onSurface, lightFitPalette.onSurface);

    AppColors.activate(darkFitPalette);
    expect(AppColors.background, darkFitPalette.background);
    expect(AppColors.surface, darkFitPalette.surface);
    expect(AppColors.onSurface, darkFitPalette.onSurface);
  });

  test('buildFitPulseTheme genera temas claro y oscuro', () {
    final claro = buildFitPulseTheme(brightness: Brightness.light);
    final oscuro = buildFitPulseTheme(brightness: Brightness.dark);

    expect(claro.brightness, Brightness.light);
    expect(claro.scaffoldBackgroundColor, lightFitPalette.background);
    expect(claro.colorScheme.primary, lightFitPalette.primary);

    expect(oscuro.brightness, Brightness.dark);
    expect(oscuro.scaffoldBackgroundColor, darkFitPalette.background);
    expect(oscuro.colorScheme.primary, darkFitPalette.primary);
    expect(oscuro.colorScheme.onSurface, darkFitPalette.onSurface);
    expect(oscuro.textTheme.bodyMedium?.color, darkFitPalette.onSurface);
  });

  testWidgets('la app activa la paleta oscura cuando el sistema es oscuro',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const FitPulseApp());
    await tester.pump();

    expect(AppColors.active, same(darkFitPalette));
  });

  test('contraste calculado: ratios conocidos', () {
    // Blanco sobre negro ≈ 21:1; negro sobre blanco idéntico.
    expect(FitPalette.contraste(Colors.white, Colors.black),
        closeTo(21, 1));
    expect(FitPalette.contraste(Colors.black, Colors.white),
        closeTo(21, 1));
    // Gris medio sobre blanco queda bajo 4.5 (no debe usarse como texto).
    expect(FitPalette.contraste(const Color(0xFF9E9E9E), Colors.white),
        lessThan(4.5));
  });
}