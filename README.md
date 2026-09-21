# FitPulse

FitPulse - Tu compañero de rendimiento y bienestar.

App Flutter orientada a registrarse como atleta, seguir entrenamientos,
recetas nutricionales y consejos de bienestar.

## Estado actual

- **MVP funcional** instalado y probado en Android (Pixel 6a y Xiaomi M1908C3JGG).
- **Sesión 100% local por dispositivo**: perfil, balance nutricional, favoritos y
  metas se guardan con `shared_preferences` (sin cuentas ni servidores).
- **5 secciones**: Inicio, Recetas, Progreso, Consejos y Perfil.
- **Siguiente prioridad**: Fase 0.5 (interfaz multi-dispositivo, sin overflows en
  cualquier tamaño de pantalla).

## Hoja de ruta por fases

| Fase | Descripción |
|---|---|
| 0 | Cimientos: capa de servicios/repositorios y feature-flags |
| 0.5 | Interfaz multi-dispositivo (anti-overflow en cualquier Android) |
| 1 | Datos reales del cuerpo (pasos, pulso, sueño, hidratación vía Health Connect) |
| 2 | Entrenamientos reproducibles, racha real, retos y gamificación |
| 3 | Anuncios en vídeo (AdMob) + Premium "Quitar anuncios" (pago único) |
| 4 | Meal planner y lista de la compra |
| 5 | Entrenador con cámara (ML Kit, corrección de postura on-device) |
| 6 | Widgets de home screen y notificaciones locales |
| 7 | Modo oscuro, accesibilidad, multiidioma (es/en), microinteracciones |
| 8 | Privacidad (export/borrado de datos), release firmado y lanzamiento |

## Entorno

- **Framework:** Flutter 3.47.3 / Dart 3.13.3
- **Plataforma:** Android (minSdk 24; subirá a 26 con Health Connect en Fase 1)
- **Gestión de datos:** local (`shared_preferences`), sin backend

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
- `flutter build apk --debug` — generar APK debug
- `adb install -r build\app\outputs\flutter-apk\app-debug.apk` — instalar en dispositivo