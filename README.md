# FitPulse

FitPulse - Tu compañero de rendimiento y bienestar.

App Flutter que replica las pantallas del proyecto "FitPulse" de Google Stitch
(design system *Kinetic Vitality*), orientada a registrarse como atleta, seguir
entrenamientos, recetas nutricionales y consejos de bienestar.

## Entorno

- **Framework:** Flutter 3.47.3 / Dart 3.13.3
- **Plataforma:** Android (development, USB debugging en Pixel 6a)
- **Diseño de referencia:** Google Stitch (`projects/7104873432163098849`)

## Estructura

```
lib/
  main.dart                    # Arranque, tema y shell de navegación (5 tabs)
  theme.dart                   # Tokens de diseño (colores y tipografías)
  state/
    app_state.dart             # CambiaNotifier con estado global + persistencia
    athlete_profile.dart       # Modelo del atleta / perfil
    recipes_catalog.dart       # Datos estáticos de recetas
  screens/
    registration_screen.dart   # Onboarding "Crea tu Perfil Atlético" (paso 1 de 2)
    home_screen.dart           # Inicio (resumen, entrenamiento, categorías)
    recipes_screen.dart        # Recetas Nutricionales
    progress_screen.dart       # Progreso y Rendimiento
    tips_screen.dart           # Consejos y Bienestar
    profile_screen.dart        # Perfil y Ajustes
  widgets/
    common.dart                # Widgets reutilizables (SectionHeader, MetricCard...)
    fit_nav_bar.dart           # Barra de navegación inferior
```

## Scripts

- `flutter run -d <device>` — lanzar en modo debug
- `flutter analyze` — análisis estático
- `flutter test` — tests de widgets