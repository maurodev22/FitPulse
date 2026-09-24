# FitPulse

FitPulse - Tu compañero de rendimiento y bienestar.

App Flutter orientada a registrarse como atleta, seguir entrenamientos,
recetas nutricionales y consejos de bienestar. Sesión 100% local por
dispositivo (sin cuentas ni servidores).

## Estado actual (auditado 2026-09-24)

- **MVP funcional** instalado y probado en Android (Pixel 6a y Xiaomi M1908C3JGG).
- **6 secciones**: Inicio, Recetas, Progreso, Consejos, Perfil y Ayuda (6 tabs).
- **Fases 0, 0.5 y hotfix completadas** (cimientos, ruedas, validaciones, EULA,
  i18n es/en, anti-overflow, Ayuda con manual local, identidad WebP).
- **Fase 1 en curso**: pasos reales del teléfono ✅ (pedometer); pulso/sueño/grasa/
  hidratación vía Health Connect ⏳; reinicio diario por fecha ✅; analytics local ✅.
- **Próximo paso**: probar la Fase 1 de pasos en los dos móviles
  (`GUIA_TESTEO_FASE1.md`) y, tras aprobación, integrar Health Connect.
- El plan detallado por fases vive en **[`PLAN.md`](PLAN.md)**.

## Hoja de ruta por fases

| Fase | Estado | Descripción |
|---|---|---|
| 0 | ✅ | Cimientos: capa de servicios/repositorios y feature-flags; limpieza de datos ficticios; formulario con wheel pickers (edad 16-85, peso 45-300 kg paso 0.5, altura 1,20-2,10 m); IMC en vivo; campo "Tipo de cuerpo" informativo; validaciones; EULA con checkbox; i18n es/en |
| 0.5 | ✅ | Interfaz multi-dispositivo (anti-overflow en 360/393/411 dp) + pestaña "Ayuda" con manual local + identidad propia |
| Hotfix | ✅ | Sin "Explorar categorías" ni "Nutrición & Vitalidad"; "Evolución & Rendimiento" en 1 línea; sin coaches ni "Cerrar sesión"; `**` del manual limpiados |
| 1 | 🚧 | Datos reales del cuerpo: pasos reales ✅, pulso/sueño/hidratación vía Health Connect ⏳ (minSdk → 26), reset diario por fecha ✅, analytics local anónimo ✅ |
| 2 | ⏳ | Entrenamientos reproducibles, racha real, retos cortos y gamificación adaptativa |
| 3 | ⏳ | Anuncios en vídeo (AdMob, IDs de test) + Premium "Quitar anuncios" (pago único); optimización de peso (~28-35 MB instalado). Nota: la monetización/lista requieren entidad fuera de Cuba |
| 4 | ⏳ | Meal planner, lista de la compra y día libre / cheat meal |
| 5 | ⏳ | Entrenador con cámara (ML Kit, corrección de postura on-device) |
| 6 | ⏳ | Widgets de home screen y notificaciones locales (permiso por tipo) |
| 7 | ⏳ | Modo oscuro, accesibilidad (EAA/WCAG), i18n es/en completo, microinteracciones |
| 8 | ⏳ | Privacidad (export cifrado, borrado), legal UE (EULA/Términos/Privacidad es/en, GDPR, edad 16), release firmado y lanzamiento |

## Entorno

- **Framework:** Flutter 3.47.3 / Dart 3.13.3
- **Plataforma:** Android (minSdk 24; subirá a 26 con Health Connect en Fase 1)
- **Gestión de datos:** local (`shared_preferences`), sin backend

## Estructura

```
lib/
  main.dart                    # Arranque, tema y shell de navegación (6 tabs)
  theme.dart                   # Tokens de diseño (colores y tipografías)
  state/
    app_state.dart             # ChangeNotifier con estado global + persistencia
    athlete_profile.dart       # Modelo del atleta / perfil (JSON persistido)
    recetas_catalog.dart       # Modelo y catálogo estático de recetas
  screens/
    eula_screen.dart           # Términos y EULA con casilla obligatoria
    registration_screen.dart   # Onboarding "Crea tu Perfil Atlético" (ruedas + IMC en vivo)
    home_screen.dart           # Inicio (Día ideal, pasos reales, resumen, entrenamiento)
    recipes_screen.dart        # Recetas Nutricionales + catálogo completo
    progress_screen.dart       # Progreso y Rendimiento
    tips_screen.dart           # Consejos y Bienestar
    profile_screen.dart        # Perfil y Ajustes (incluye selector de idioma)
    help_screen.dart           # Ayuda: manual local + FAQ
    placeholder_screen.dart    # Pantalla genérica reutilizable (sin destinos aún)
  widgets/
    common.dart                # Widgets reutilizables (SectionHeader, MetricCard...)
    fit_nav_bar.dart           # Barra de navegación inferior (6 tabs)
    wheel_number_picker.dart   # Rueda drum-roll para edad/peso/altura (Fase 0)
  services/
    config_service.dart        # Feature-flags (ads, premium, mock) + versión EULA
    health_service.dart        # Fuente de pasos real (pedometer) + mock
    locale_service.dart        # Idioma es/en en vivo + AppStrings
    usage_log_service.dart     # Registro de uso anónimo local (máx. 200 eventos)
  utils/
    validators.dart            # Reglas de validación oficiales (nombre, edad, peso, altura)

test/
  widget_test.dart             # Flujo EULA → registro → dashboard + cada pestaña
  responsive_test.dart         # Anti-overflow en 360/393/411 dp
  state_test.dart              # Reinicio diario, baseline de pasos, usage log

assets/
  docs/                        # Manual de usuario es/en (markdown local)
  fonts/                       # Plus Jakarta Sans + Inter
  images/                      # Imágenes de marca (WebP)

tool/
  generate_assets.dart         # Script generador de assets
```

## Documentación

- [`PLAN.md`](PLAN.md) — plan de evolución por fases con estado auditado (fuente de verdad).
- [`FUNCIONALIDADES.md`](FUNCIONALIDADES.md) — control de funcionalidades presentes vs. pendientes.
- [`GUIA_TESTEO_FASE1.md`](GUIA_TESTEO_FASE1.md) — guía de prueba manual en dispositivo.
- `assets/docs/manual_es.md` / `manual_en.md` — manual de usuario que se muestra dentro de la pestaña Ayuda.

## Scripts

- `flutter run -d <device>` — lanzar en modo debug
- `flutter analyze` — análisis estático (objetivo: 0 issues)
- `flutter test` — suite completa (widgets, responsive y estado)
- `flutter build apk --debug` — generar APK debug
- `adb install -r build\app\outputs\flutter-apk\app-debug.apk` — instalar en dispositivo

## Reglas de diseño

- **100% local**: sin cuentas ni servidores; todo se guarda con `shared_preferences`.
- **Sin datos inventados**: si una métrica de salud no tiene fuente real conectada
  muestra "—" / "Requiere reloj inteligente"; nunca números ficticios.
- **Cada fase se prueba** en Pixel 6a y Xiaomi antes de pasar a la siguiente.