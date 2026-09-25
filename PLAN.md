# FitPulse — Plan de Evolución por Fases (V6, auditado)

> Documento de gobierno del plan. Fusiona el **PLAN_FITPULSE_CLIENTE.txt (V5)** del
> escritorio con la **auditoría del código** (estado real en `lib/`, `test/` y `android/`,
> revisado el 2026-09-24). Cada fase indica su estado: ✅ completada, 🚧 en curso, ⏳ pendiente.

---

## 0. Estado actual (auditoría)

| Fase | Estado | Notas |
|---|---|---|
| Fase 0 (cimientos + datos premium) | ✅ | Servicios, feature-flags, validaciones, ruedas, IMC en vivo, tipo de cuerpo, EULA, i18n es/en |
| Fase 0.5 (multi-dispositivo + Ayuda + identidad) | ✅ | Anti-overflow 360-411 dp, tarjeta Día ideal, WebP propios, pestaña Ayuda con manual local |
| **Hotfix** (aprobado) | ✅ | Aplicado y verificado en código (sin "Explorar categorías", "Nutrición & Vitalidad", coaches ni "Cerrar sesión"; `**` del manual limpiados) |
| Fase 1 (datos reales del cuerpo) | ✅ código | Pasos reales ✅; **Health Connect ✅** (pulso, peso, grasa, sueño, agua, gasto activo, tiempo activo; solo lectura); reinicio diario ✅; analytics local ✅. Falta prueba manual en dispositivo |
| Fase 2 (entrenamientos + motivación) | ✅ código | Catálogo + reproductor ✅; historial real ✅; racha real ✅; retos 3/5/7 ✅; puntos/niveles ✅; plan adaptativo ✅. Falta prueba manual en dispositivo |
| Fase 3 (negocio: anuncios + Premium + app ligera) | ✅ código | AdMob IDs de prueba + consentimiento local + Premium + R8; falta prueba manual en ambos móviles |
| Fase 4 (comidas) | ✅ código | Plan semanal real (6 recetas) + lista de la compra + día libre; falta prueba manual |
| Fase 5 (entrenador con cámara) | ✅ código | ML Kit pose on-device + estados honestos; falta prueba manual |
| Fase 6 (extras de retención) | ✅ instalado/verificado | Widget de home (pasos/calorías/racha) + avisos locales por tipo; instalado y verificado en Pixel 6a y Xiaomi |
| Fase 7 (premium + accesibilidad) | ✅ código | Modo oscuro (sistema/claro/oscuro), contraste WCAG AA, tamaño accesible (0 desbordes a 2.0×), micro-animaciones, i18n es/en completo; `flutter analyze` 0 issues y 55 tests verdes. Pendiente PASA/FALLA manual del usuario |
| Fase 8 | ⏳ | Privacidad GDPR: export/import legible + borrado total (8.1 ✅); política de privacidad + EULA v2 (8.2 ✅); UMP publicidad (8.3 pendiente); aviso de IA (8.4 ✅); release firmado + Data Safety (8.5, bloqueado por cuenta Play desde Cuba) |

**Sesión** (`FUNCIONALIDADES.md`), **guía de prueba manual** (`GUIA_TESTEO_FASE1.md`) y
**README** están pendientes de actualización con el estado de Fases 1 y 2.

---

## 1. Fase 0 — Cimientos, limpieza y entrada de datos premium ✅

- ✅ Capa de servicios/repositorios y feature-flags (`lib/services/config_service.dart`).
- ✅ Limpieza de datos ficticios: balance 0 kcal/día; onboarding **vacío** sin perfil de
  relleno; pasos/racha desde el estado real.
- ✅ Validaciones: nombre 3-60 (solo letras/espacios), sexo y meta obligatorios,
  edad 16-85, peso 45-300 kg, altura 1,20-2,10 m (`lib/utils/validators.dart`).
- ✅ Ruedas giratorias drum-roll para edad, peso (paso 0,5 kg) y altura
  (`lib/widgets/wheel_number_picker.dart`).
- ✅ IMC en vivo mientras giras las ruedas, con aviso por color por banda, sin bloquear
  la entrada (`_BmiBar` en `registration_screen.dart`).
- ✅ Campo "Tipo de cuerpo" (Ecto/Meso/Endo + combinadas + "No lo sé"→"Normal"),
  informativo y editable desde Perfil (`athlete_profile.dart` / `TipoCuerpo`).
- ✅ Aceptación de Términos y EULA con casilla obligatoria y versionado
  (`eula_screen.dart` + `kEulaVersion`).
- ✅ Idiomas oficiales es/en aplicados en vivo sin reiniciar (`locale_service.dart`).

## 2. Fase 0.5 — Interfaz para cualquier pantalla + Ayuda + identidad ✅

- ✅ Cero desbordes en 360/393/411 dp (tests `test/responsive_test.dart`).
- ✅ Tarjeta "Día ideal" en Inicio (entrenamiento + macros + agua) (`home_screen.dart`).
- ✅ Icono e imágenes de marca en WebP (`assets/images/*.webp`, mipmaps propios).
- ✅ Pestaña "Ayuda" con manual de usuario local sin internet y FAQ
  (`help_screen.dart` + `assets/docs/manual_es.md` / `manual_en.md`).

## 3. Hotfix (aprobado por el cliente) ✅

- ✅ Inicio: eliminada la sección "Explorar categorías".
- ✅ Recetas: encabezado limpio (sin meta ni "Nutrición & Vitalidad").
- ✅ Progreso: "Evolución & Rendimiento" en una línea (FittedBox).
- ✅ Responsividad auditada sin desbordes ni textos partidos (320-411 dp objetivo).
- ✅ Consejos: retirada toda referencia a coaches.
- ✅ Perfil: eliminado el botón "Cerrar sesión" (un único usuario por dispositivo).
- ✅ Ayuda: `**` del manual ya no se muestran como texto literal.
- ➡️ **Acción pendiente (manual):** reinstalar la app en el Pixel 6a desde cero
  (desinstalar + instalar) para asegurar la versión activa con todos los cambios.

## 4. Fase 1 — Datos reales del cuerpo ✅ (código)

**Completado:**
- ✅ Pasos reales del teléfono (`pedometer` + `PhoneStepSource`) con baseline diario y
  re-basificado tras reinicio del equipo.
- ✅ Reinicio diario del balance por fecha (`app_state.dart`).
- ✅ Registro de uso anónimo local (máx. 200 eventos, sin red ni identificadores).
- ✅ Regla "sin datos inventados": pulso/grasa/gasto activo/sueño muestran "—" si no
  hay fuente real conectada.
- ✅ **Health Connect** con el paquete `health` 13.3.2, **solo lectura**:
  - Permisos por métrica (`READ_*` en manifest, `minSdk 26`): pasos, pulso, peso,
    grasa, sueño, agua, gasto activo y tiempo activo.
  - `HealthConnectService` (`lib/services/health_service.dart`): disponibilidad,
    solicitud de permisos (una sola pantalla de Google, concedibles/rechazables por
    separado), lectura diaria → `HealthToday`.
  - Solicitud automática al arrancar **una sola vez** (flag `fitpulse_hc_requested_v1`);
  luego botones "Conectar" permiten re-solicitar (Perfil → "Abrir permisos de Health
  Connect").
  - UI integrada: Inicio (pulso real + agua en Día ideal), Progreso (grasa, gasto
  activo, tiempo activo reales), Perfil (calorías activas reales + cardio semanal real
  + estado de permisos).

**Pendiente (manual):**
- ⏳ Prueba manual en Pixel 6a y Xiaomi con `GUIA_TESTEO_FASE1.md` actualizada a
  Fase 1 completa (Health Connect + pre-workout). Nota: "Tiempo Activo" se lee de
  `EXERCISE_TIME`, un tipo que el paquete `health` 13.3.2 solo expone en **iOS**
  (en Android no está en el mapa del plugin y no debe pedirse: rompería la pantalla
  de permisos). Por eso en Android se muestra "—" de forma honesta.

## 5. Fase 2 — Entrenamientos + motivación adaptativa ✅ (código)

**Completado:**
- ✅ Catálogo reproducible de 4 programas (`lib/state/workout_catalog.dart`): HIIT &
  Quema Total, Fuerza Superior & Core, Running 5K Matutino, Full Body & Flexibilidad.
- ✅ **Reproductor de entrenamiento** (`workout_player_screen.dart`): ejercicios con
  temporizador (trabajo → descanso → siguiente), pausa/reanudar, saltar y finalizar;
  el hero del Inicio y el Día ideal abren el reproductor de verdad.
- ✅ **Sesiones reales**: al completar se registra la sesión (fecha, nombre, duración,
  kcal del plan) en `fitpulse_workout_history_v1`; Progreso muestra las recientes.
- ✅ **Racha real**: días consecutivos con sesión hasta hoy (o ayer); header de Inicio,
  Progreso y Perfil usan `rachaDias` calculado, no el campo guardado del perfil.
- ✅ **Retos 3/5/7 días**: al cumplir N días seguidos se otorgan +100 pts y el reto
  avanza (→5, →7); progreso visible en Progreso.
- ✅ **Puntos y niveles**: +50 pts por sesión; nivel = 1 + XP~/300 con progreso por barra
  y etiquetas Principiante/Intermedio/Avanzado.
- ✅ **Plan adaptativo**: intensidad Alta si entrenas ≥5 días/semana, Media si 3-4,
  Baja si ≤2; el hero "RECOMENDADO PARA TI" selecciona el programa según esa intensidad.
- ✅ Insignias calculadas de datos reales (Primera Sesión, Racha 3/7, Nivel, Reto).
- ✅ Tests: racha, retos, niveles, plan adaptativo, Health Connect (mock) y flujo
  completo del reproductor.

**Pendiente (manual):**
- ⏳ Probar el reproductor y las recompensas en ambos móviles; confirmar que "Tiempo
  Activo" aparece cuando Health Connect lo registra.

## 6. Fase 3 — Negocio: anuncios en vídeo + Premium + app ligera ✅ (código)

**Completado:**
- ✅ **AdMob con IDs de PRUEBA oficiales de Google** (`google_mobile_ads` 5.3.1):
  - Banner inferior en todas las pestañas (sobre la barra de navegación) y descansos en
    el reproductor de entrenamiento (`lib/services/ads_service.dart` → `FitBannerAd`).
  - Anuncio **recompensado** desde Progreso: "Ver anuncio y ganar +25 PTs", **una vez por
    día** (persistido por fecha en `fitpulse_recompensa_anuncio_v1`).
  - Degradación elegante: sin Play Services o sin red no ocupa espacio ni rompe nada.
- ✅ **Consentimiento local**: toggle "Anuncios habilitados" en Perfil (guarda en
  `ConfigService.setAds`); los anuncios solo se cargan tras el EULA (la app entera lo
  requiere) y si el flag está activo.
- ✅ **Premium "Quitar anuncios"**: tarjeta en Perfil con estado, botón
  "Activar/Desactivar Premium (modo prueba)" (`ConfigService.setPremium`) y nota honesta
  de que el cobro real requiere Google Play con entidad fuera de Cuba. Con Premium activo
  se ocultan banner y recompensado.
- ✅ **App ligera**: `isMinifyEnabled` + `isShrinkResources` (R8) en el build de release;
  el APK debug sigue siendo grande a propósito (contiene símbolos de depuración).
  **Medido en 24/09/2026**: release universal (3 ABIs) = **55.6 MB**; release solo arm64
  (Pixel 6a, Xiaomi) = **22.5 MB** → objetivo ~28-35 MB instalado **cumplido**.
- ✅ Tests: recompensa 1/día y persistencia de toggles (27 en total, en verde) +
  `flutter analyze` sin issues.

**Nota:** AdMob/Google Play no admiten cuentas con residencia en Cuba. El código queda
listo: sustituir los IDs de prueba por los reales y el cobro/lista requieren una entidad
fuera de Cuba (se deja la puerta abierta sin bloquear la app).

**Pendiente (manual):**
- ⏳ Probar en Pixel 6a y Xiaomi: banner visible sin Premium, recompensado suma +25 una
  vez al día, y al activar Premium (modo prueba) desaparecen todos los anuncios.

## 7. Fase 4 — Comidas ✅ (código)

- Plan semanal de comidas según objetivos y lista de la compra.
  - `lib/state/meal_plan.dart`: generador determinista de 7 días (Lunes→Domingo) a partir
    del perfil (días de entrenamiento + meta calórica); todas las comidas referencian
    recetas **reales** del catálogo (`recetas_catalog.dart`, con ingredientes por ración
    añadidos). Totales por día = suma exacta de las recetas; la cobertura frente a la meta
    es honesta (el plan base ronda el ~66 % de 2100 kcal/día → se indica ajustar raciones).
  - `lib/screens/meal_plan_screen.dart`: pantalla con pestañas "Plan semanal" y "Lista de
    la compra" (ingredientes agrupados con su nombre real y nº de usos). Acceso desde una
    tarjeta nueva en Recetas (`recipes_screen.dart`).
- Día "libre" / cheat meal planificado: domingo marcado "Día libre 🍕" y NO penaliza la
  racha (que solo depende de sesiones de entrenamiento completadas); se aclara en la UI.
- 7 tests nuevos (`test/meal_plan_test.dart`): 34/34 en verde.

**Pendiente (manual):**
- ⏳ Probar en Pixel 6a y Xiaomi: abrir Plan semanal desde Recetas, ver 7 días + domingo día
  libre, lista de la compra agrupada.

## 8. Fase 5 — Entrenador con cámara ✅ (código)

- La cámara corrige la postura al hacer ejercicio (ML Kit Pose Detection, on-device,
  sin conexión tras la descarga única del modelo).
  - `lib/state/pose_coach.dart`: lógica pura y testeable — ángulos entre articulaciones,
    mapa ejercicio→corrección (sentadillas/zancadas=rodilla, flexiones/fondos=codo,
    plancha=alineación, cardio=ritmo, resto=libre), contador de repeticiones con
    histéresis y feedback honesto. **9 tests** (45/45 en verde con F1-F4).
  - `lib/services/pose_coach_service.dart`: puente cámara↔ML Kit (YUV-420→NV21,
    detector base en modo stream). Autorización: `MainActivity.kt` expone un
    `MethodChannel` mínimo para pedir el permiso de cámara (sin dependencias extra).
  - `lib/screens/pose_coach_screen.dart`: preview + esqueleto en vivo + contador de
    reps + feedback. Estados honestos sin crash: sin permiso (con "Abrir ajustes"),
    sin cámara, y **modelo de IA no disponible** (descarga única vía Play Services;
    si la red no alcanza Google, se explica y no se inventa ninguna corrección).
  - Entrada: botón "Corregir postura con cámara" en el reproductor
    (`workout_player_screen.dart`), visible solo en ejercicios corregibles.
- Nada se graba ni se sube: el análisis es 100 % local en el móvil.
- Android: permiso `CAMERA` en el manifest. Mirrors de Maven de Aliyun añadidos a
  `settings.gradle.kts`/`build.gradle.kts` (google()/mavenCentral() bloqueados en Cuba;
  las dependencias nuevas de AndroidX Camera + ML Kit se descargan por el mirror).

**Pendiente (manual):**
- ⏳ Probar en Pixel 6a y Xiaomi: abrir el entrenador con cámara desde un ejercicio,
  conceder permiso, ver el esqueleto y el contador, y el estado honesto si el modelo
  no descarga (red).

## 9. Fase 6 — Extras de retención ✅ (código)

- **Widget de home screen** (AppWidget nativo, sin plugin extra): banda horizontal con
  **pasos reales del sensor**, **calorías** (gasto activo real de Health Connect; "—" si
  no hay permiso + dato, nunca inventado) y **racha real** del historial.
  - `android/.../HomeWidgetProvider.kt` + `HomeWidgetRenderer`: RemoteViews que leen un
    snapshot JSON guardado en SharedPreferences propio; al tocar abre la app.
  - `lib/services/home_widget_service.dart`: `HomeWidgetBridge` escucha `AppState` y
    envía el snapshot por el canal `fitpulse/home_widget` (con throttle para no escribir
    en cada tick de pasos); refresco también al volver a la app y cada 30 min.
  - Layout/icono: `res/layout/home_widget_layout.xml`, `res/xml/home_widget_info.xml`,
    `res/drawable/ic_stat_fitpulse.xml` (icono de notificación), `widget_bg.xml`.
- **Avisos locales reales** (`flutter_local_notifications` 22.3.0, 100 % en el móvil),
  cada uno con su toggle en Perfil (permiso por tipo):
  - 💧 **Hidratación** cada hora (`periodicallyShow`), toggle "Recordatorios de hidratación".
  - 🏃 **Racha en riesgo** a las 20:00 (`zonedSchedule` + `matchDateTimeComponents.time`,
    repetible diario), con el texto de la racha REAL; se cancela el día en que se completa
    una sesión y se reprograma mañana con la racha actualizada. Toggle "Aviso de racha".
  - `lib/state/avisos.dart`: lógica pura testeable (próxima hora local sin librería tz,
    instante UTC equivalente, texto de racha, snapshot JSON del widget). **5 tests**.
  - Permiso de notificaciones (Android 13+) pedido UNA sola vez en una sincronización
    serializada al arrancar (`AvisosService.sincronizar`); si se deniega, no se programa
    nada (honesto). Reprogramación automática tras reinicio vía
    `ScheduledNotificationBootReceiver`.
- Construcción: **core library desugaring** activado (`desugar_jdk_libs 2.1.5`, requisito
  del plugin) e `init.gradle` global con los mirrors de Aliyun para los `buildscript` de
  los plugins (los repositorios de los plugins no heredan los del proyecto raíz).

**Pendiente (manual):**
- ⏳ Probar en Pixel 6a y Xiaomi: colocar el widget en Inicio y ver pasos/calorías/racha
  reales; activar ambos avisos, conceder el permiso y comprobar que aparecen en la
  bandeja a la hora indicada (hidratación cada hora, racha 20:00).

## 10. Fase 7 — Experiencia premium y accesibilidad ✅ (código)

- ✅ **Modo oscuro**: selector en Perfil (Sistema/Claro/Oscuro) con `AppThemeMode`
  persistido (`fitpulse_theme_v1`); el `builder` de `MaterialApp` activa la paleta
  correcta respondiendo también a `MediaQuery.platformBrightness`. Paleta oscura
  propia en `theme.dart` (verde sobre superficie oscura), gradientes del header con
  verdes estables.
- ✅ **Contraste WCAG AA**: verificado por test automático en `test/theme_test.dart`
  (ratios de la paleta clara y oscura, incl. `outline` #5F6B62 en hints/pasos).
- ✅ **Tamaño accesible**: `test/accessibilidad_test.dart` recorre toda la app a
  escala de texto 2.0× en 360 dp; 16 desbordes corregidos (patrón `Flexible` +
  `maxLines: 1` + `TextOverflow.ellipsis`).
- ✅ **Micro-animaciones**: anillo de `AppProgressRing` y barras de `MetricCard` con
  `TweenAnimationBuilder` (700-800 ms, easeOutCubic).
- ✅ **i18n es/en completo**: `AppStrings` con textos de las 11 pantallas (ES
  verbatim, EN nuevo); cambio en vivo desde Perfil → Idioma; los valores de datos
  (metas, sexo, nivel, categorías) se traducen solo en su visualización.
- ⏳ Pendiente: prueba PASA/FALLA manual en ambos móviles (Pixel 6a + Xiaomi) y
  revisión de la traducción EN por un hablante nativo.

## 11. Fase 8 — Privacidad, legal UE y lanzamiento ⏳

### 8.1 Datos: portabilidad y derecho al olvido (GDPR arts. 20 y 17) ✅
- **Export** (implementado): JSON legible e interoperable con todo el estado
  (perfil, balance, historial, XP, reto, favoritas, config, idioma) escrito en
  los documentos de la app y abierto con share-sheet (`share_plus`) para
  guardarlo en nube/PC. Nota de diseño: el export es **legible sin cifrar** a
  propósito — el cifrado local rompería la portabilidad (art. 20 exige formato
  estructurado e interoperable). Pantalla en Perfil → "Privacidad y datos".
- **Import** (implementado): lista los backups `fitpulse_backup_*.json` del
  dispositivo, valida formato/versión y restaura tras confirmar sobrescritura.
- **Borrado total** (implementado): "Borrar todos mis datos" con **doble
  confirmación** → `shared_preferences.clear()` (almacén exclusivo de la app)
  + reset en memoria → vuelve al EULA/onboarding.
- Tests: `test/data_backup_test.dart` (7) + `test/privacy_screen_test.dart` (2).

### 8.2 Legal UE (es/en) ✅
- **Política de privacidad** (implementada): nueva pantalla `PrivacyScreen` es/en
  (9 secciones: responsable/comerciante, qué se guarda, qué NO se transmite,
  datos de salud art. 9, edad 16+, derechos art. 17/20, publicidad, IA local,
  contacto), enlazada desde Perfil → "Política de privacidad".
- **EULA actualizado a v2** (implementado): cláusulas 5 (datos de salud art. 9 +
  edad mínima 16) y 6 (publicidad/consentimiento + devolución 14 días + datos
  de comerciante). `kEulaVersion = 2` → se vuelve a pedir aceptación.
- **Política de copy anti-claims (MDR)**: pendiente de auditar los textos de
  tips y fijarla por escrito (ningún texto afirma diagnosticar/tratar/prevenir).

### 8.3 Consentimiento publicitario UE (UMP + ePrivacy) ⏳ pendiente
- Integrar **Google User Messaging Platform** (UMP) para EEE/Reino Unido: mensaje de
  consentimiento antes del primer anuncio; si se rechaza la personalización, AdMob usa
  anuncios no personalizados. El toggle local "Anuncios habilitados" se mantiene como
  capa adicional. Sin UMP no se muestra recompensado en EEE. Depende de `google_ump`
  (red a Google, bloqueada en Cuba en runtime) → se dejará documentada la integración
  y el degradado honesto.

### 8.4 Ley de IA de la UE (art. 50, transparencia) ✅
- Aviso formal en el entrenador con cámara (implementado): "Este módulo usa un modelo
  de IA en tu dispositivo (ML Kit): el análisis es local y la cámara no graba ni sube
  nada." Visible de forma permanente bajo la barra inferior del coach.

### 8.5 Release firmado y publicación ⏳ parcial
- **Firma propia**: pendiente de generar keystore (fuera del repo) + `build.gradle.kts`
  con signing condicional y `app-release.aab` con Play App Signing.
- **Ficha Data Safety** cumplimentada con lo real (datos locales, cifrado, sin
  compartición) — pendiente de rellenar al publicar.
- **Bloqueo estructural**: la cuenta de desarrollador de Play no puede crearse desde
  Cuba (país no soportado; requiere entidad + datos fiscales fuera). Publicar solo
  cuando exista esa entidad; hasta entonces el AAB firmado queda listo para subir.

### Matriz de cumplimiento (auditoría 2026-09-25)

| Requisito | Nivel exigido para esta app | Cumplimiento | Brecha / esfuerzo |
|---|---|---|---|
| MDR 2017/745 (producto sanitario) | Fuera de scope (sin claims médicos) | 🟢 ALTA | Bajo: auditar copy tips + política escrita |
| GDPR art. 9 (datos de salud) | Consentimiento con base legal | 🟢 ALTA | Bajo: cláusula explícita en la política |
| GDPR art. 8 (edad mínima) | ≥ 16 | 🟢 ALTA | Cero (rueda empieza en 16) |
| GDPR art. 20 (portabilidad) | Export | 🔴 MÍNIMA | Medio: se implementa en 8.1 |
| GDPR art. 17 (borrado) | Derecho al olvido | 🔴 MÍNIMA | Bajo-medio: se implementa en 8.1 |
| GDPR política de privacidad | Transparencia | 🟡 MEDIA | Medio: se implementa en 8.2 |
| Google Play Data Safety | Ficha declarada | ⚪ N/A (sin publicar) | Medio: al publicar (8.5) |
| Google Health apps policy | Privacidad + claims veraces | 🟡 MEDIA | Medio: misma política (8.2) |
| EU User Consent (UMP/ePrivacy) | Consentimiento publicitario | 🔴 MÍNIMA | Medio: se implementa en 8.3 |
| Directiva 2011/83/UE (14 días) | Devolución en compras | 🟢 ALTA | Cero (Play lo gestiona) |
| Ley de IA UE (art. 50) | Aviso de IA | 🟡 MEDIA-ALTA | Bajo: se formaliza en 8.4 |
| EAA/WCAG accesibilidad | Estándar | 🟢 ALTA | Bajo (mantenimiento) |
| ePrivacy notificaciones | Permiso único y honesto | 🟢 ALTA | Cero |
| Cuenta Play desde Cuba | Publicar | 🔴 BLOQUEADA | Negocio: entidad fuera de Cuba (8.5) |

**Orden de ejecución sugerido:** 8.1 (datos) → 8.2 (legal) → 8.4 (IA) → 8.3 (UMP) →
8.5 (release). Entregable: analyze 0, suite ampliada (tests export/import/borrado),
AAB firmado y política/privacy visibles en Perfil y en la ficha de Play.

---

## 12. Principios que se mantienen

- Todo funciona en el propio móvil: sin cuentas ni servidores.
- **Nunca** se muestran datos de salud inventados: si no hay fuente real → "—".
- Cada fase se entrega, se prueba en los dos móviles (Pixel 6a + Xiaomi) y se pide
  aprobación antes de continuar.

## 13. Próximos pasos recomendados

1. **Cerrar Fase 8 (código)**: 8.3 UMP (necesita `google_ump` y red a Google) y
   8.5 firma propia (keystore fuera del repo + `app-release.aab`). Verificar
   `flutter analyze` 0 y la suite ampliada (~64 tests).
2. **Prueba PASA/FALLA de Fases 1-8 en los móviles** siguiendo `GUIA_TESTEO_FASE1.md`
   (tabla de registro por dispositivo: Health Connect, entrenamientos, anuncios,
   Premium, comidas, entrenador con cámara, widget/avisos, modo oscuro, tamaño de
   texto 2.0×, idioma en vivo y — Fase 8 — exportar/importar/borrar datos más
   política de privacidad es/en).
3. Con la aprobación manual de las Fases 1-8, decidir publicación (requiere entidad
   fuera de Cuba para la cuenta de desarrollador de Play).