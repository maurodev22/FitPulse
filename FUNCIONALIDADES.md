# FitPulse — Funcionalidades: presentes vs. pendientes

Documento de control que contrasta el diseño de referencia (Google Stitch, 8 pantallas)
contra el estado real de la implementación Flutter. Actualizado tras las **Fases 1, 2, 3 y 4**
(datos reales del cuerpo + entrenamientos motivacionales + anuncios/Premium con IDs de prueba + comidas).

## Funcionalidades presentes (funcionales)

| # | Funcionalidad | Pantalla / Archivo | Detalle |
|---|---|---|---|
| 1 | Onboarding de registro | `RegistrationScreen` | Formulario completo (nombre, edad, sexo, peso, altura, meta). IMC calculado en vivo sobre el formulario. Guarda la sesión del atleta en el dispositivo. |
| 2 | Sesión persistente por dispositivo | `AppState` (`lib/state/app_state.dart`) | Perfil, balance nutricional, favoritos y metas se guardan con `shared_preferences`. Al reabrir la app el usuario vuelve directo al dashboard. |
| 3 | Dashboard / Home | `HomeScreen` | Saludo personalizado, tarjeta **Día ideal** (entrenamiento + macros + agua reales), **pasos reales** del sensor, **pulso real** de Health Connect, calorías y hero de entrenamiento conectado al reproductor. |
| 4 | Recetas nutricionales | `RecipesScreen` + `RecetasCatalogScreen` | **41 recetas originales** con **ilustración propia por receta** (`imagenDeReceta`), búsqueda por texto, filtros por categoría (Alta Proteína / Low Carb / Pre-entreno / Smoothies), **filtro por meta** con recuento real y sección "Para tu meta", receta destacada, opciones rápidas, favoritos y catálogo completo. |
| 5 | Registro de consumo | `registrarConsumo` (AppState) | Suma calorías y macros al balance del día con **reinicio diario por fecha**. |
| 6 | **Pasos reales del teléfono** | `PhoneStepSource` (`lib/services/health_service.dart`) | Sensor `pedometer` con baseline diario y re-basificado tras reinicio del equipo. |
| 7 | **Health Connect (solo lectura)** | `HealthConnectService` (`lib/services/health_service.dart`) | Permisos por métrica (pulso, peso, grasa, sueño, agua, gasto activo, tiempo activo). Solicitud automática 1 vez; botón "Abrir permisos" en Perfil para re-solicitar. Los números solo se muestran si hay permiso + dato real; si no, "—". |
| 8 | Progreso y Rendimiento | `ProgressScreen` | Peso e IMC del perfil; grasa, gasto activo y tiempo activo reales (Health Connect); **Sesiones Recientes reales**, **Reto 3/5/7 días** y **Nivel/XP** con micro-barra de nivel, calculados del historial real. |
| 9 | **Entrenamientos reproducibles** | `workout_catalog.dart` + `WorkoutPlayerScreen` | 4 programas (HIIT, Fuerza, Running, Full Body) con temporizador trabajo→descanso→siguiente, pausa/saltar; al completar registra sesión real. |
| 10 | **Racha real de días** | `AppState.historial` | Días consecutivos con sesión hasta hoy (o ayer) calculados por fechas; visible en Inicio, Progreso y Perfil. |
| 11 | **Plan adaptativo** | `AppState.intensidadPlan` | Intensidad Alta (≥5 días/semana), Media (3-4), Baja (≤2); el hero "RECOMENDADO PARA TI" elige el programa según esa intensidad. |
| 12 | Consejos y Bienestar | `TipsScreen` | Plan personalizado según la meta del atleta, tips de alto impacto y artículos recomendados (contenido orientativo, sin coaches). |
| 13 | Perfil y ajustes | `ProfileScreen` | Datos personales, IMC calculado, nivel, preferencias, días de entrenamiento editables, "Guardar cambios" (persiste) y tarjeta **Datos de salud** con estado de permisos Health Connect. |
| 14 | Navegación de 6 pestañas | `FitNavBar` (`lib/widgets/fit_nav_bar.dart`) | Inicio, Recetas, Progreso, Consejos, Perfil y Ayuda. |
| 15 | Pestaña Ayuda | `HelpScreen` + `assets/docs/manual_es.md` / `manual_en.md` | Manual de usuario local sin internet y preguntas frecuentes. |
| 16 | Registro de uso anónimo | `UsageLogService` | Máx. 200 eventos locales `{t, c, a, d}`, sin red ni identificadores. |
| 17 | Diseño y tema | `theme.dart` + `common.dart` | Sistema de colores Material 3 verde y tipografías Plus Jakarta Sans / Inter. `SectionHeader` unificado. |
| 18 | Android con identidad propia | `android/` | Namespace e ID de paquete `com.fitpulse.app`, `minSdk 26`, permisos `READ_*` de Health Connect en manifest, `INTERNET` solo para anuncios, R8 activado en release (app ligera). |
| 19 | Tests | `test/` (31 archivos) | Cubren onboarding, dashboard, pestañas, Health Connect (mock), racha, retos, niveles, plan adaptativo, reproductor (registro de sesión), recompensa 1/día, toggles de anuncios/premium, plan semanal de comidas, pose coach, avisos locales, **contraste WCAG AA**, **ausencia de desbordes a escala 2.0×**, **recetas por meta y sus 41 imágenes propias**, **rutinas propias**, **avatar recortado**, **insignias (Fase C) con fechas reales**, **"Tu semana" con datos reales (Fase D)** y **toques de contexto (Fase E): chip Nv N, mini-barra de XP y nivel en el snapshot del widget**. Responsividad 360-411 dp. **293 en verde** + `flutter analyze` 0 issues. |
| 20 | Documentación | `README.md`, `PLAN.md`, `FUNCIONALIDADES.md`, `GUIA_TESTEO_FASE1.md` | Plan por fases, estado real, funcionalidades y guía de prueba manual. |
| 21 | **Anuncios (IDs de prueba)** | `lib/services/ads_service.dart` + `google_mobile_ads` 9.1.0 | Banner inferior en todas las pestañas y en el reproductor; **recompensado** en Progreso: +25 PTs una vez al día (persistido por fecha). Degradación elegante si no hay Play Services/red (placeholder honesto). Toggle "Anuncios habilitados" en Perfil (consentimiento local). |
| 22 | **Premium "Quitar anuncios"** | `ProfileScreen` + `ConfigService` | Tarjeta con estado; **el botón de "modo prueba" se quitó de la UI** (solo existe en debug, en `WorkoutPlayerScreen`). Con Premium activo se ocultan banner y recompensado. El cobro real requiere Google Play con entidad fuera de Cuba (ver PLAN.md). |
| 23 | **Plan semanal de comidas** | `meal_plan.dart` + `MealPlanScreen` (+ `RecipesScreen`) | 7 días (Lunes→Domingo) construidos **solo con recetas reales del catálogo** (con ingredientes por ración); totales por día = suma exacta; cobertura honesta de la meta (ajuste de raciones). Domingo = **día libre 🍕 que no penaliza la racha**. Pestañas "Plan semanal" / "Lista de la compra" (ingredientes agrupados con nº de usos). |
| 24 | **Entrenador con cámara** | `pose_coach.dart` + `pose_coach_service.dart` + `PoseCoachScreen` (botón en `WorkoutPlayerScreen`) | ML Kit Pose Detection **on-device** (tras descarga única del modelo): esqueleto en vivo, feedback por ángulos reales (sentadillas/zancadas = rodilla; flexiones/fondos = codo; plancha = alineación; cardio = ritmo) y contador de reps con histéresis. **Nada se graba ni se sube.** Estados honestos sin crash: permiso denegado (→ "Abrir ajustes"), sin cámara y **modelo de IA no disponible** (sin Play Services/red → se explica, no se inventa ninguna corrección). Permiso `CAMERA` vía `MethodChannel` propio en `MainActivity.kt` (sin dependencias extra). |
| 25 | **Insignias (Fase C de gamificación)** | `lib/state/insignias.dart` + `ProfileScreen._buildInsignias` | Catálogo completo de **9 insignias** siempre visible: conseguidas (icono a color + **fecha real de desbloqueo** derivada del historial) y bloqueadas (silueta gris con candado + condición, sin presión). Contador "N / 9 insignias". Nueva persistencia `diasAguaCumplida` para la insignia "Hidratado" (días reales con la meta de agua cumplida). |
| 26 | **Tu semana (Fase D)** | `HomeScreen._buildTuSemana` + `AppState` (semana pasada) | Tarjeta informativa **en Home** (no push): aparece solo con actividad la semana pasada y muestra datos reales (días, sesiones y **XP por día** persistido en `fitpulse_xp_dias_v1`). Línea discreta del reto "Vas 3 de 5 días" solo con racha viva. Sin lenguaje negativo. |
| 27 | **Toques de contexto (Fase E)** | `NivelChip` + `HomeScreen` + `home_widget_service` + `HomeWidgetProvider.kt` | Chip pasivo **"Nv N · Nombre"** (sin ripple muerto) en el header de Progreso y Perfil; **mini-barra de XP** (10 px) bajo la racha en Home; el snapshot del **widget de home 2×2** lleva el nivel real y pinta "Hoy · Lv N" (mismo cálculo que la app). |

## Funcionalidades pendientes / ausentes

| # | Funcionalidad | Estado | Sugerencia |
|---|---|---|---|
| 1 | Subida real de foto de perfil | Ornamental | Integrar `image_picker` y persistir el path en `AthleteProfile`. |
| 2 | Registro/Inicio con backend | Ausente | No hay cuenta ni servidor; la sesión es 100% local como se acordó. |
| 3 | Consulta a coaches | Eliminada | Se retiró toda referencia a coaches en el hotfix aprobado. |
| 4 | Lectura de artículos de consejos | Placeholder | Los artículos/tips son orientativos; falta persistencia de favoritos de consejos. |
| 5 | Alertas reales de hidratación | ✅ (Fase 6) | Aviso local periódico (cada hora) programado por el toggle "Recordatorios de hidratación"; permiso de notificaciones requerido (Android 13+). |
| 6 | Sincronización de "Tiempo Activo" completa | Parcial | El paquete `health` 13.3.2 solo expone `EXERCISE_TIME` en iOS; en Android se muestra "—" (honesto, nunca inventado). |
| 7 | Compartir actividad | Placeholder | Solo un toggle visual. |
| 8 | Pantalla "Ver detalles"/gráficos | Sin navegación | Enlaces tipo "Ver detalles", "Ver plan", "Ver todo" no implementan destinos. |
| 9 | Modo oscuro, contraste/tamaño accesibles e i18n | ✅ (Fase 7) | Selector de tema (Sistema/Claro/Oscuro) persistido + paleta oscura verde propia; contraste WCAG AA verificado por test; sin desbordes a escala de texto 2.0×; textos completos es/en en las 11 pantallas con cambio en vivo desde Perfil → Idioma. |
| 10 | Widgets y avisos locales | ✅ (Fase 6) | Widget de home con pasos/calorías/racha reales + avisos locales por tipo (hidratación y racha en riesgo 20:00). |
| 11 | Exportar/importar y borrado total (GDPR) | Ausente | Fase 8. |

## Decisiones registradas

- **Sesión local por dispositivo**: en línea con la petición de mantener los datos de
  inicio de sesión de forma persistente en el móvil (entorno de producción dev), se usa
  `shared_preferences` (almacenamiento seguro por app en el dispositivo).
- **Datos de salud nunca inventados**: si una métrica (pulso, grasa, agua, gasto activo,
  tiempo activo, sueño) no tiene permiso o dato real de Health Connect, se muestra "—"
  con la nota correspondiente.
- **Health Connect solo lectura**: nunca se escribe ningún dato de salud del usuario.
- **Historial de entrenamiento local**: las sesiones completadas, la racha, los puntos y
  los retos se persisten por dispositivo y se calculan de ese historial real.
- **Estructura comentada**: los archivos de `lib/` llevan documentación en español por
  archivo, clase y método clave.
- **Nombre de paquete**: `com.fitpulse.app` (build 1, versión 1.0.0).
- **Cámara 100 % local y honesta (Fase 5)**: el entrenador con cámara analiza la postura
  con ML Kit en el propio móvil (nada se graba ni se sube). Si el permiso, la cámara o el
  modelo de IA no están disponibles (p. ej. descarga única bloqueada por red), se muestra
  un estado honesto — **nunca se inventa una corrección**.
- **Permiso de cámara sin dependencias extra (Fase 5)**: en lugar de un plugin de
  permisos (que fijaba una versión de AGP no descargable en Cuba), `MainActivity.kt` expone
  un `MethodChannel` mínimo con las APIs de framework (minSdk 26).
- **Mirrors Maven Aliyun (Fase 5)**: `google()`/`mavenCentral()` están bloqueados en Cuba;
  `settings.gradle.kts`/`build.gradle.kts` usan primero los mirrors de Aliyun (accesibles,
  igual que el mirror de pub) y dejan los repos oficiales como respaldo.
- **Widget y avisos con datos reales (Fase 6)**: el widget de home muestra pasos del
  sensor, calorías (gasto activo real de Health Connect; "—" sin permiso+dato) y racha del
  historial — nunca valores inventados. Los avisos locales son notificaciones del propio
  móvil, cada una con su toggle (permiso por tipo).
- **Permiso de notificaciones pedido una sola vez (Fase 6)**: la sincronización al
  arrancar es un único flujo serializado (`AvisosService.sincronizar`); un doble
  `requestNotificationsPermission` en paralelo dejaba un aviso sin programar esperando el
  diálogo del sistema. Si el permiso se deniega, no se programa nada (honesto).
- **Desugaring + mirrors para plugins (Fase 6)**: `flutter_local_notifications` 22.x exige
  core library desugaring (`desugar_jdk_libs 2.1.5`) y sus `buildscript` de Gradle no
  heredan los mirrors del root; se añadió `~/.gradle/init.gradle` que antepone Aliyun en
  los repositorios de todos los buildscripts.