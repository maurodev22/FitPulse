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
- **Fase 1 completada (código)**: pasos reales del teléfono ✅; **Health Connect ✅**
  (pulso, peso, grasa, sueño, agua, gasto activo y tiempo activo; solo lectura y con
  permisos por métrica); reinicio diario por fecha ✅; analytics local ✅.
- **Fase 2 completada (código)**: catálogo de 4 entrenamientos con **reproductor
  integrado** (temporizador trabajo→descanso), historial de sesiones real persistido,
  **racha real**, **retos 3/5/7 días**, **puntos/niveles (XP)** y **plan adaptativo**.
- **Fase 3 completada (código)**: anuncios de AdMob con **IDs de prueba** (banner en
  todas las pestañas + recompensado +25 PTs 1/día), consentimiento local, **Premium
  "Quitar anuncios"** (modo prueba local; el cobro real requiere Play fuera de Cuba) y
  **app ligera** (R8 + shrinkResources en release).
- **Fase 4 completada (código)**: **plan semanal de comidas** según el perfil (7 días,
  solo recetas reales del catálogo, totales calculados, cobertura honesta de la meta),
  **lista de la compra** agrupada e ingredientes en el catálogo, y **día libre 🍕 el
  domingo que no penaliza la racha**.
- **Prueba manual**: Fases 1-3 probadas en Pixel 6a (PASA en F1/F2/F3; recompensado
  pendiente por red — AdMob 403 en Cuba). Fase 4 pendiente de probar en
  `GUIA_TESTEO_FASE1.md`.
- El plan detallado por fases vive en **[`PLAN.md`](PLAN.md)**.

## Hoja de ruta por fases

| Fase | Estado | Descripción |
|---|---|---|
| 0 | ✅ | Cimientos: capa de servicios/repositorios y feature-flags; limpieza de datos ficticios; formulario con wheel pickers (edad 16-85, peso 45-300 kg paso 0.5, altura 1,20-2,10 m); IMC en vivo; campo "Tipo de cuerpo" informativo; validaciones; EULA con checkbox; i18n es/en |
| 0.5 | ✅ | Interfaz multi-dispositivo (anti-overflow en 360/393/411 dp) + pestaña "Ayuda" con manual local + identidad propia |
| Hotfix | ✅ | Sin "Explorar categorías" ni "Nutrición & Vitalidad"; "Evolución & Rendimiento" en 1 línea; sin coaches ni "Cerrar sesión"; `**` del manual limpiados |
| 1 | ✅ (código) | Datos reales del cuerpo: pasos reales (pedometer) + **Health Connect solo lectura** (pulso, peso, grasa, sueño, agua, gasto activo; permiso por métrica; minSdk 26), reset diario por fecha, analytics local anónimo. "Tiempo activo" se muestra "—" en Android (el tipo EXERCISE_TIME del plugin solo existe en iOS). Falta prueba manual |
| 2 | ✅ (código) | Catálogo de 4 entrenamientos + **reproductor con temporizador**; sesiones reales persistidas; **racha real**; **retos 3/5/7 días**; **XP/niveles**; **plan adaptativo** que recomienda el programa según tu semana. Falta prueba manual |
| 3 | ✅ (código) | Anuncios de AdMob con **IDs de prueba** (banner todas las pestañas + recompensado +25 PTs 1/día con consentimiento local) + **Premium "Quitar anuncios"** (modo prueba; el cobro real requiere entidad fuera de Cuba) + **app ligera** (R8 en release; **medido: 55.6 MB universal / 22.5 MB arm64** vs 178 MB debug). Falta prueba manual |
| 4 | ✅ (código) | Plan semanal de comidas según el perfil (7 días Lunes→Domingo, sin datos inventados: solo recetas reales del catálogo, totales por día = suma exacta, cobertura honesta de la meta) + **lista de la compra** agrupada por ingrediente + **día libre 🍕 el domingo que no penaliza la racha**. Pendiente prueba manual |
| 5 | ⏳ | Entrenador con cámara (ML Kit, corrección de postura on-device) |
| 6 | ⏳ | Widgets de home screen y notificaciones locales (permiso por tipo) |
| 7 | ⏳ | Modo oscuro, accesibilidad (EAA/WCAG), i18n es/en completo, microinteracciones |
| 8 | ⏳ | Privacidad (export cifrado, borrado), legal UE (EULA/Términos/Privacidad es/en, GDPR, edad 16), release firmado y lanzamiento |

## Entorno

- **Framework:** Flutter 3.47.3 / Dart 3.13.3
- **Plataforma:** Android (minSdk 26, requerido por Health Connect)
- **Gestión de datos:** local (`shared_preferences`), sin backend

## Estructura

```
lib/
  main.dart                    # Arranque, tema y shell de navegación (6 tabs)
  theme.dart                   # Tokens de diseño (colores y tipografías)
  state/
    app_state.dart             # ChangeNotifier con estado global + persistencia (Fase 2: historial/racha/XP/retos; Fase 3: recompensa 1/día)
    athlete_profile.dart       # Modelo del atleta / perfil (JSON persistido)
    recetas_catalog.dart       # Modelo y catálogo estático de recetas (+ ingredientes por ración, Fase 4)
    meal_plan.dart             # Plan semanal de comidas determinista + lista de la compra (Fase 4)
    workout.dart               # Modelos de sesión/programa de entrenamiento (Fase 2)
    workout_catalog.dart       # Catálogo de 4 programas con ejercicios (Fase 2)
  screens/
    eula_screen.dart           # Términos y EULA con casilla obligatoria
    registration_screen.dart   # Onboarding "Crea tu Perfil Atlético" (ruedas + IMC en vivo)
    home_screen.dart           # Inicio (Día ideal, pasos/pulso reales, resumen, hero entrenamiento)
    recipes_screen.dart        # Recetas Nutricionales + catálogo completo (+ acceso al plan, Fase 4)
    meal_plan_screen.dart      # Plan semanal + lista de la compra (pestañas, Fase 4)
    progress_screen.dart       # Progreso (métricas Health Connect + sesiones/reto/nivel/insignias reales)
    workout_player_screen.dart # Reproductor de entrenamiento con temporizador (Fase 2)
    tips_screen.dart           # Consejos y Bienestar
    profile_screen.dart        # Perfil y Ajustes (idioma + tarjeta Health Connect)
    help_screen.dart           # Ayuda: manual local + FAQ
    placeholder_screen.dart    # Pantalla genérica reutilizable (sin destinos aún)
  widgets/
    common.dart                # Widgets reutilizables (SectionHeader, MetricCard...)
    fit_nav_bar.dart           # Barra de navegación inferior (6 tabs)
    wheel_number_picker.dart   # Rueda drum-roll para edad/peso/altura (Fase 0)
  services/
    ads_service.dart           # AdMob con IDs de prueba: banner + recompensado (Fase 3)
    config_service.dart        # Feature-flags (ads, premium, mock) + versión EULA + consentimientos
    health_service.dart        # Pasos reales (pedometer) + HealthConnectService (solo lectura)
    locale_service.dart        # Idioma es/en en vivo + AppStrings
    usage_log_service.dart     # Registro de uso anónimo local (máx. 200 eventos)
  utils/
    validators.dart            # Reglas de validación oficiales (nombre, edad, peso, altura)

test/
  widget_test.dart             # Flujo EULA → registro → dashboard, pestañas y reproductor
  responsive_test.dart         # Anti-overflow en 360/393/411 dp
  state_test.dart              # Reinicio diario, baseline de pasos, usage log, Health Connect (mock),
                               # racha, retos, XP/niveles y plan adaptativo (Fases 1-2);
                               # recompensa 1/día y toggles ads/premium (Fase 3)

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
  (sensor del teléfono o Health Connect con permiso + dato), se muestra "—" con una
  nota honesta ("Requiere Health Connect", "Concede el permiso", etc.).
- **Health Connect solo lectura**: la app nunca escribe datos de salud; los permisos
  se conceden o rechazan métrica por métrica desde la pantalla de Google.
- **Cada fase se prueba** en Pixel 6a y Xiaomi antes de pasar a la siguiente.