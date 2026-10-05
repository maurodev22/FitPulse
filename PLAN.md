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
| Fase 3 (negocio: anuncios + Premium + app ligera) | ✅ código | AdMob IDs de prueba (banner + rewarded + app open) + consentimiento UMP local/UE + Premium + R8; falta prueba manual en ambos móviles |
| Fase 4 (comidas) | ✅ código | Plan semanal real (6 recetas) + lista de la compra + día libre; falta prueba manual |
| Fase 5 (entrenador con cámara) | ✅ código | ML Kit pose on-device + estados honestos; falta prueba manual |
| Fase 6 (extras de retención) | ✅ instalado/verificado | Widget de home (pasos/calorías/racha) + avisos locales por tipo; instalado y verificado en Pixel 6a y Xiaomi |
| Fase 7 (premium + accesibilidad) | ✅ código | Modo oscuro (sistema/claro/oscuro), contraste WCAG AA, tamaño accesible (0 desbordes a 2.0×), micro-animaciones, i18n es/en completo; `flutter analyze` 0 issues y 55 tests verdes. Pendiente PASA/FALLA manual del usuario |
| Fase 8 | ✅ código (falta verificación EEE + 8.5) | Privacidad GDPR: export/import legible + borrado total (8.1 ✅); política de privacidad + EULA v2 (8.2 ✅); UMP publicidad nativo + app open (8.3 ✅ código); aviso de IA (8.4 ✅); release firmado + Data Safety (8.5, bloqueado por cuenta Play desde Cuba) |
| Fase 9 (correcciones UI + plan aprobado) | 🚧 L1 en verificación | Plan aprobado 2026-09-29 (`docs/PLAN_AGREGAR_CORREGIR.md` + `docs/DISENO_GAMIFICACION.md`). L1 código ✅ (filtro recetas, pestañas de período, "Ver todo") con 108 tests; agua, constructor, recetas y gamificación ⏳ según orden del plan |

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
  - ✅ **Premium "Quitar anuncios"**: tarjeta en Perfil con estado, botón
  "Activar/Desactivar Premium (modo prueba)" (`ConfigService.setPremium`) y nota honesta
  de que el cobro real requiere Google Play con entidad fuera de Cuba (ver
  `docs/COBRO_PREMIUM.md`, el procedimiento de cobro). Con Premium activo
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

### 8.3 Consentimiento publicitario UE (UMP + ePrivacy) ✅ código (verificación EEE pendiente)
- Integrar **Google User Messaging Platform** (UMP) para EEE/Reino Unido: mensaje de
  consentimiento antes del primer anuncio; si se rechaza la personalización, AdMob usa
  anuncios no personalizados. Implementado SIN `google_ump` (pub.dev da 403 desde Cuba
  y el mirror no lo tiene): el SDK es `com.google.android.ump:user-messaging-platform:4.0.0`,
  que `google_mobile_ads` trae como dependencia `implementation` de su plugin; como
  así no llega al compilador de la app, también se declara en `android/app/build.gradle.kts`
  (misma versión, vía Aliyun). El puente es nativo por MethodChannel (`fitpulse/consent`
  en `MainActivity.kt`) usando la API de UMP **4.0.0** (todo pasa por
  `UserMessagingPlatform`: `getConsentInformation`, `requestConsentInfoUpdate`,
  `loadAndShowConsentFormIfRequired`): `request` (+ `consentStatus` + `canRequestAds`),
  `loadAndShowIfRequired`, `canRequestAds` y `reset`, servidos a
  `ConsentService` (`lib/services/consent_service.dart`).
- **Gating de todos los formatos por consentimiento** (`AdsPermiso` en
  `ads_service.dart`): banner, recompensado y app open solo cargan si
  `canRequestAds == true`. Degradado honesto: sin red a Google (Cuba) o sin soporte
  UMP → `ConsentEstado.error` → no se cargan anuncios reales; solo la zona de banner
  de desarrollo queda visible para testes.
- El toggle local "Anuncios habilitados" (Perfil) y Premium se mantienen como capas
  adicionales (`adsPermitidos(adsEnabled && !premium && consentimientoOk)`).
- **App Open** (`AppOpenAdManager`): 1×/sesión, cooldown 60 s, pausa en segundo plano
  ≥ 30 s, nunca en arranque en frío, nunca encima del reproductor de ejercicios
  (`AdsPermiso.ejercicioActivo`) ni de otro anuncio. ID de prueba
  `ca-app-pub-3940256099942544/9257395921`.
- **Pendiente real (cliente fuera de Cuba)**: cuenta AdMob real + unit IDs + crear el
  mensaje de consentimiento en la consola AdMob (privacy & messaging) + verificación
  en dispositivo EEE. Lista de sustitución: `docs/ADS_CLIENTE.md`.
- Nota de honor: en Cuba (sin red a Google) el UMP falla → la app no muestra anuncios
  reales, lo cual es el comportamiento honesto. **Vista previa de prueba**
  (`AdsPermiso.vistaPreviaTest`, activa en `main()` solo cuando el consentimiento falla
  por red): el banner muestra una pieza local "Anuncio de PRUEBA" con texto/imagen y el
  recompensado simula el video con una pieza de solo imagen (al cerrarla otorga el
  +25 PTs de prueba). Todo claramente marcado como PRUEBA; con IDs reales y cuenta
  fuera de Cuba el consentimiento se resuelve → vista previa desactivada → anuncios
  reales. No requiere tocar código (se ajusta sola según `consent.errorTecnico`).

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
| EU User Consent (UMP/ePrivacy) | Consentimiento publicitario | 🟢 ALTA (código; UMP nativo) | Medio: cuenta AdMob real + mensaje UMP (8.3 → docs/ADS_CLIENTE.md) |
| Directiva 2011/83/UE (14 días) | Devolución en compras | 🟢 ALTA | Cero (Play lo gestiona) |
| Ley de IA UE (art. 50) | Aviso de IA | 🟡 MEDIA-ALTA | Bajo: se formaliza en 8.4 |
| EAA/WCAG accesibilidad | Estándar | 🟢 ALTA | Bajo (mantenimiento) |
| ePrivacy notificaciones | Permiso único y honesto | 🟢 ALTA | Cero |
| Cuenta Play desde Cuba | Publicar | 🔴 BLOQUEADA | Negocio: entidad fuera de Cuba (8.5) |

**Orden de ejecución sugerido:** 8.1 (datos) → 8.2 (legal) → 8.4 (IA) → 8.3 (UMP) →
8.5 (release). Entregable: analyze 0, suite ampliada (tests export/import/borrado),
AAB firmado y política/privacy visibles en Perfil y en la ficha de Play.

---

## 11.5 Fase 9 — Correcciones L1 y plan aprobado (agregar/corregir) 🚧

Plan aprobado por el cliente el 2026-09-29. Documentos de diseño:
`docs/PLAN_AGREGAR_CORREGIR.md` (7 ítems) y `docs/DISENO_GAMIFICACION.md` (gamificación
sutil por fases A-F, construida sobre el XP/nivel/insignias existentes).

**L1 — las 3 correcciones de UI (código y tests ✅):**
- ✅ **1.1 Filtrado de recetas**: los pills de la vista principal ya no son decorativos;
  tocan un pill y abre el catálogo filtrado por esa categoría (la lista destacada sigue
  siendo editorial). (`recipes_screen.dart`)
- ✅ **1.2 Pestañas Semanal / Mensual / Año en Progreso**: ahora son funcionales
  (`_PeriodTabs` controlado). Cada ventana (7/30/365 días) recalcula un resumen REAL de
  sesiones, minutos, kcal y racha máx. (`resumenPeriodo` en `progress_screen.dart`,
  testeada con fechas simuladas) y abre la ventana del gráfico de peso (7/13/52 semanas).
- ✅ **1.3 "Ver todo" de sesiones recientes**: abre el historial completo
  (`HistorialSesionesScreen`); la fila de sesión se extrajo a un widget compartido
  (`widgets/sesion_row.dart`).

**Pendientes del plan (⏳):** 2.1 Agua (registro manual de vasos 250 ml + meta diaria
editable, def. 3 L), 2.2 Constructor de entrenamientos (rutinas propias con descanso
60 s, reutiliza el reproductor), 2.3 Recetas originales por metas (sin copiar medios,
por copyright; Bajar de peso / Mantener / Ganar músculo) y 2.4 Gamificación Fase A+B.

Estado: `flutter analyze` 0 issues y 108 tests verdes; verificación física pendiente en
Pixel 6a (muestreo de píxeles + `uiautomator dump`, tema oscuro y español intactos).

---

## 11.6 Fase 10 — Feedback del usuario P11–P16 (2026-10-02) 🚧

Feedback del usuario incorporado en la sesión del 2026-10-02. Registro detallado y
pasos de verificación en `docs/GUIA_TESTEO_COMPLETA.md` §21 (P11–P13) y §22 (P14–P16).

### P11–P13 — Reproductor rediseñado ✅ código (verificación física pendiente)

- ✅ **P11**: reproductor a **pantalla completa** (el hero y la ficha del ejercicio
  ocupan todo el ancho; controles y nombre a un solo nivel, sin la barra envolvente
  del shell).
- ✅ **P12**: **repeticiones al final** — el episodio activo del ejercicio se marca en
  rojo y el contador real de repeticiones/tiempo se muestra de forma destacada.
- ✅ **P13**: el **entrenador con cámara es Premium** ("Solo Premium"): sin Premium se
  muestra el aviso honesto con cómo activarlo (modo prueba); con Premium activo se abre.
- Estado: 116/116 tests, 0 issues en `flutter analyze`. APK release reconstruido e
  instalado. Reportes de testeo manual del usuario (P11–P13) pendientes.

### P14–P16 — Agua manual, hidratación 30 min e inactividad 2 días 🚧

- ✅ **P14 — Registro manual de agua 2,5 L/día**: en la tarjeta **Día ideal** del Home
  la fila **Agua** es pulsable → diálogo "Registra tu agua de hoy" (+0,25 L / +0,50 L /
  +1 L + cantidad libre). Suma al total diario real de Health Connect si existe (nunca
  inventa: solo cuenta lo que el usuario declara). Meta 2,5 L → "Agua · 2,5 / 2,5 L · ✓".
  **PASA** — verificado físicamente en el Pixel 6a el 2026-10-02 (DÍA IDEAL 2/3).
- ✅ **P15 — Hidratación cada 30 min**: el aviso pasa de "cada hora" a cada 30 minutos
  (`periodicallyShowWithDuration(30 min)`, ID 9001). Texto serio sin emojis: "Hidrátate /
  Ha pasado un tiempo desde que tomaste agua, por favor hidrátate."
- ✅ **P16 — Inactividad a los 2 días**: en cada arranque se (re)programa un aviso único
  a **+48 h** (ID 9004): si el usuario no abre la app en 2 días llega "FitPulse — Regresa
  y entrena, mantente en forma!" (seria, sin emojis). Si vuelve antes, se reprograma.
- 🔧 **FATAL del small icon corregido**: `isShrinkResources=true` (R8) eliminaba
  `ic_stat_fitpulse` del release (referenciado solo por nombre en Dart, no por
  `R.drawable`) → `getIdentifier()=0` → "Invalid notification (no valid small icon)" al
  mostrar un aviso. Fix: `android/app/src/main/res/raw/keep.xml` con
  `tools:keep="@drawable/ic_stat_fitpulse"`. Con el APK reconstruido las **3 alarmas**
  entran al AlarmManager: 9001 (próximo ciclo 30 min), 9002 (20:00) y **9004 (+48 h)** —
  confirmadas en `dumpsys alarm` el 2026-10-02 (el mismo fallo también impedía programar
  el one-shot 9004; con el icono vivo `sincronizar` completa todo el flujo).
- Estado: 122/122 tests, 0 issues. Verificación física de la cadena de avisos (P15/P16)
  en curso con el dispositivo re-conectado.

### P17 — Configuración inicial ligera (tema + avisos opt-in) ✅

- ✅ Nueva pantalla `SetupScreen` entre Registro y Home: aparece **una sola vez** tras
  registrarse (`registration_screen._goToDashboard` → `SetupScreen` → `AppShell`).
- ✅ **Tema con vista previa**: tres tarjetas Sistema/Claro/Oscuro que muestran los
  colores reales de las paletas (`lightFitPalette`/`darkFitPalette`); tocar aplica y
  persiste al instante con `ConfigService.setThemeMode`.
- ✅ **Avisos opt-in**: toggles de "Recordatorios de hidratación" (cada 30 min) y "Aviso
  de racha en riesgo" (20:00) que guardan `hidratacion`/`entrenamientoMatutino` en el
  perfil. "Continuar" sincroniza los avisos en contexto; "Ahora no" entra al Home sin
  tocar nada.
- ✅ **Permiso de notificaciones en contexto, no en cascada**: la Setup NO pide el
  diálogo del sistema. `main.dart` ahora solo ejecuta `sincronizar()` cuando hay sesión
  (`isLoggedIn`), así el permiso se pide UNA sola vez cuando el usuario activa un aviso
  (flujo `AvisosService._permiso()` ya existente: pendiente/concedido/denegado,
  denegado → no se programa nada, honesto).
- ✅ 126/126 tests (nuevos `test/setup_screen_test.dart` con render, tema persistido,
  Continuar guarda toggles y "Ahora no" no toca el perfil), 0 issues en `flutter analyze`.
  Verificación física de la pantalla pendiente en el dispositivo.

### P18 — Recompensa visual del Día ideal (+25 XP, una vez por día) ✅ código

Feedback del usuario: *"que al completar el reto de Día ideal, le dé una recompensa
visual que estimule permanecer en la apk"*. Implementa la **Fase B4** de la gamificación
(`docs/DISENO_GAMIFICACION.md`): premiar el día completo con una celebración sutil.

- ✅ **Condición única y coherente**: `AppState.diaIdealCompletadoHoy` (entrenar hoy +
  meta calórica ≥ 100 % + agua ≥ 2,5 L sobre datos reales, nunca inventados) es la
  fuente única de verdad; la tarjeta de Home usa la misma constante `metaAguaDiaria`.
- ✅ **+25 XP honesto y único**: `AppState.aplicarRecompensaDiaIdeal()` otorga
  `ptsDiaIdeal` (+25) SOLO si el día está completo y **una sola vez por día**
  (persistido por fecha, mismo patrón que el anuncio recompensado). Un día a medias
  nunca premia y no se repite.
- ✅ **Celebración visual suave no bloqueante**: al llegar a 3/3 la tarjeta muestra
  confeti (CustomPainter, colores de la paleta) + check animado + "¡Día ideal
  completado! +25 XP · ¡Sigue así!" que se desvanece sola (~2,8 s). Sin sonido, sin
  modal, con `IgnorePointer` (no bloquea toques). No vuelve a aparecer en el día.
- ✅ 130/130 tests (nuevo `test/dia_ideal_recompensa_test.dart`: no premia 2/3,
  premia 3/3 solo una vez, celebración aparece y desaparece sin reaparecer hoy),
  0 issues en `flutter analyze`. Verificación física pendiente en el dispositivo.

### P19 — Validaciones honestas: reps mínimas y agua con tope diario ✅ código

Lote pedido por el usuario tras revisar el código: *"nadie hace 0 repeticiones de un
ejercicio"*, *"ningún humano toma +5 L de agua al día"* y listar **todos** los campos
con validaciones (ver inventario abajo).

- ✅ **Reps: el 0 no es una cuenta real.** En `_dialogoReps` (`workout_player_screen.dart`)
  el botón "Guardar" con 0 repeticiones NO cierra el diálogo y muestra el aviso
  motivador dentro del diálogo: *"Esfuérzate para conseguir 1 repetición más"*
  (`strings.wpRepsEsfuerzate`). Se interpreta como "error o no pude", tal como pidió
  el usuario. Con ≥ 1 guarda y cierra como antes.
- ✅ **Agua: tope diario de 5 L con aviso de sinceridad de 5 s.** En
  `_mostrarDialogoRegistrarAgua` (`home_screen.dart`) si el total del día
  (declarado + nuevo, botones rápidos y campo libre incluidos) supera 5 L, NO se
  registra, NO se cierra el diálogo y se muestra un SnackBar de 5 segundos:
  *"La sinceridad es lo que te ayuda a crecer: máximo 5 L de agua al día."*
  (`strings.homeAguaSinceridad`).
- ✅ **Reglas centralizadas**: `Validators.minReps = 1`,
  `Validators.maxAguaDiariaLitros = 5.0`, `Validators.validarReps(...)` y
  `Validators.validarAguaDiaria(...)`. El diálogo de agua pasó a `StatefulWidget`
  que posee su `TextEditingController` (evita usarlo tras la liberación durante la
  animación de cierre).
- ✅ 136/136 tests (nuevo `test/validaciones_test.dart`: reglas unitarias + diálogo de
  agua 6 L rechazado con snackbar de 5 s / 0,5 L registrado + diálogo de reps
  0 no cierra con aviso motivador / 1 sí guarda), 0 issues en `flutter analyze`.
  Verificación física pendiente en el dispositivo.

### P20 — Estado de salud honesto + metas mínimas investigadas ✅ código

Pedido del usuario (2026-10-03): *"pon meta mínima de pasos en 1000, en kcal algún
valor que busques en internet acorde"* y *"investiga qué es un estado de salud
malo/regular/bueno/excelente para establecer una opción basada en los datos de
salud de la app* (cada estado con su color). Se confirmó con el usuario: **excelente = azul**
(regular ya era amarillo), aparece **en Home y en Perfil**, y **kcal mín = 1200**.

**Investigación (fuentes accesibles + literatura establecida):** OMS/CDC/NHS
150–300 min/sem de actividad moderada; Paluch et al., *Lancet Public Health* 2022
(pasos óptimos: 8.000–10.000 <60 años, 6.000–8.000 ≥60); categorías IMC
OMS/NHLBI; suelo nutricional seguro de **1.200 kcal/día** (guías médicas) — la app
permitía 500.

- ✅ **Metas mínimas honestas**: `Validators.minPasosMeta = 1000` (antes 1) y
  `Validators.minKcalMeta = 1200` (antes 500), con `validarMetaPasos`/
  `validarMetaKcal` usados por `_editarMetas` (`profile_screen.dart`); mensajes
  localizados `pfMetaPasosMin`/`pfMetaKcalMin`.
- ✅ **Estado de salud** (`lib/state/estado_salud.dart`, puro Dart): cada métrica
  con dato REAL puntúa 0–3 (IMC, pasos por edad, gasto activo, sueño, agua) y el
  promedio decide **Malo / Regular / Bueno / Excelente**. Con **menos de 2 métricas
  con dato → "Sin datos suficientes"** (nunca inventa). El pulso queda FUERA: solo
  hay promedio del día, no pulso en reposo.
- ✅ **Tarjeta** (`lib/widgets/estado_salud_card.dart`) en **Home** (debajo del Día
  ideal, con desglose por métrica y nota "no sustituye un diagnóstico
  profesional") y en **Perfil** (versión compacta bajo el hero). Aviso disclaimar
  obligatorio por integridad.
- ✅ **Colores** (claro/oscuro con contraste WCAG AA): malo rojo, regular amarillo,
  bueno verde, excelente azul (`colorEstadoSalud` + `onColorEstadoSalud`).
- ✅ **Getter central**: `AppState.estadoSalud` pasa SOLO datos con fuente real
  (`healthDisponible`, `gastoActivoConPermiso`, `suenioConPermiso`, `aguaHoy`,
  IMC del perfil).
- ✅ 159/159 tests (nuevo `test/estado_salud_test.dart`: 4 estados + umbral de
  pasos por edad + gasto/sueño/agua + detalles no inventados + contraste WCAG de
  los 4 colores en claro/oscuro + tarjeta con perfil/agua y con estado vacío;
  2 reglas más en `validaciones_test.dart`), 0 issues en `flutter analyze`.
  Verificación física pendiente en el dispositivo.

#### Resumen final entregado al usuario (2026-10-03)

**Investigación (con fuentes):**

| Dato | Valor recomendado | Fuente |
|---|---|---|
| Actividad semanal | 150–300 min/sem moderada | OMS (fact sheet), CDC, NHS |
| Pasos óptimos diarios | <60 años: 8.000–10.000 · ≥60 años: 6.000–8.000 (meseta de beneficio) | Paluch et al., *Lancet Public Health* 2022 |
| Categorías IMC | <18,5 bajo · 18,5–24,9 sano · 25–29,9 sobrepeso · ≥30 obesidad | NIH/NHLBI (OMS) |
| Mínimo calórico diario | 1.200 kcal/día (suelo seguro; la app permitía 500) | Guías de nutrición médica (Academia de Nutrición, Harvard, Mayo) |

**Lo implementado (confirmado con el usuario: excelente = azul, en Home y Perfil, kcal mín 1200):**

1. **Metas mínimas honestas (Perfil)**: pasos mínimo de 1 → **1000**; kcal mínimo de 500 → **1200** (valor investigado). Mensajes localizados y diálogo que no se cierra con valores fuera de rango.
2. **Estado de salud honesto** en **Home** (con desglose por métrica ●●●) y **Perfil** (compacta): puntúa 0–3 IMC, pasos por edad, gasto activo, sueño y agua — **solo datos reales**, nunca inventados. Con **menos de 2 métricas con dato → "Sin datos suficientes"**. El pulso queda **fuera** (solo hay promedio del día, no reposo).
3. **Colores**: malo **rojo** · regular **amarillo** · bueno **verde** · excelente **azul** (contraste WCAG AA en claro y oscuro). Nota en la tarjeta: "Orientativo: no sustituye un diagnóstico profesional".
4. **Calidad**: `flutter analyze` 0 issues · **159/159 tests** · docs: PLAN.md (P20 + inventario) y GUIA_TESTEO_COMPLETA.md (§26 con pasos manuales). Commit local `4f376dc` (sin push).

**⏳ Pendiente**: instalar el APK en el Pixel 6a con `install -r` y verificar físicamente juntos **P17 (§23) + P18 (§24) + P19 (§25) + P20 (§26)** de la guía. Nota aparte sin tocar: alineación del peso semanal (clamp 20–300 vs registro 45–300) quedó solo señalada en el inventario.

#### Inventario completo de validaciones (2026-10-03)

| Campo | Pantalla | Estado |
|---|---|---|
| Repeticiones (0–999) | Reproductor | ✅ P19: 0 bloqueado con aviso motivador |
| Agua manual (botones + campo libre) | Home | ✅ P19: tope 5 L/día con snackbar de 5 s |
| Peso semanal | Progreso | ✅ stepper clamp 20–300 kg (nota: registro inicial usa 45–300) |
| Metas: pasos 1000–100000, kcal 1200–10000 | Perfil | ✅ P20: `validarMetaPasos`/`validarMetaKcal` (mínimos investigados) |
| Registro inicial: nombre 3–60, edad 16–85, peso 45–300, altura 1,20–2,10 | Registro | ✅ `Validators` |
| Búsquedas (recetas / consejos) | Recetas / Consejos | ✅ texto libre sin validación numérica necesaria |
| Registrar consumo de receta | Recetas | ✅ usa datos del catálogo, sin entrada libre |
| Meta diaria de agua (0,5–10 L) | Perfil | ✅ P21: rueda 0,5 L, persistida, con origen del dato etiquetado |

---

### P21 — Meta diaria de agua editable + cierre de L2 ✅ código

Orden aprobado por el usuario (2026-10-05): **L2 → L4 → L3**, y **nada de iOS**
("no hagas nada para iphone"). Este es el cierre de L2; lo que faltaba era la meta
editable (el registro manual ya era P14 y su honestidad P19).

- ✅ **La meta dejó de ser constante**: `AppState.metaAguaDiaria` era
  `static const double 2.5`; ahora es un valor **persistido**
  (`fitpulse_meta_agua_v1`) con `setMetaAguaLitros()`, cargado en `init()`,
  incluido en `snapshotParaBackup()`/`aplicarBackup()` y devuelto a 2,5 L en
  `resetTrasBorrado()`.
- ✅ **Rango honesto**: `Validators.minMetaAguaLitros = 0.5`,
  `maxMetaAguaLitros = 10.0` y `Validators.ajustarMetaAgua()` — la meta es del
  usuario, pero no puede ser una cifra imposible (también protege un import de
  backup manipulado).
- ✅ **UI**: en Perfil, fila "Meta diaria de agua" con el valor y botón de edición;
  el diálogo usa el `WheelNumberPicker` existente con paso 0,5 L entre 0,5 y 10 L,
  explica el rango y confirma con SnackBar.
- ✅ **Origen del dato**: `AppState.origenAguaHoy` devuelve
  `manual` / `health` / `ambos` / `null`, y el diálogo de agua lo etiqueta
  ("marcado por ti" · "Health Connect" · "marcado por ti + Health Connect") junto
  a la meta. Así el usuario sabe qué cuenta y no suma dos veces el mismo vaso.
- ✅ **Coherencia con P20 (no estaba en el plan, pero era un fallo latente)**:
  `_puntosAgua` puntuaba contra 2,5 L fijos. Si subías la meta a 3 L, la tarjeta de
  estado de salud seguía diciendo "cumplido" con 2,5 L. Ahora puntúa **contra la meta
  del usuario**: ≥100 % → 3 · ≥60 % → 2 · ≥30 % → 1 · menos → 0. Con el default de
  2,5 L los cortes ya verificados no cambian (3,0→3 · 1,5→2 · 1,0→1 · 0,2→0).
- ✅ **Default 2,5 L, no 3,0 L como decía `PROXIMAS_FASES.md`**: subir el listón a
  3 L sin que el usuario lo elija endurecería el Día ideal ya verificado en el
  dispositivo. 2,5 L ≈ 35 ml/kg para ~70 kg. Quien quiera más, lo sube con la rueda.
- ✅ **En `AppState`, no en `ConfigService`** (el roadmap pedía `ConfigService`): la
  meta es dato del usuario y va con su balance; `ConfigService` es para
  interruptores, EULA y tema. Así no se crea acoplamiento entre servicios.
- ✅ **173/173 tests** (14 nuevos en `test/meta_agua_test.dart`: default, persistencia
  entre arranques, clamp, backup/restauración, backup antiguo, borrado total, los 4
  orígenes del agua, puntaje contra meta ajena y widget de Perfil), 0 issues en
  `flutter analyze`. Verificación física pendiente.

---

### L4 — Recetas originales por metas ✅ código

Segunda parte del orden aprobado (2026-10-05). El objetivo era que las recetas
dejaran de estar "sueltas" y pasaran a estar **clasificadas por la meta que el
usuario eligió en el registro**, sin copiar contenido de ningún medio.

- ✅ **Dimensión `metas` en `Recipe`** (`lib/state/recipe_model.dart`): admite
  **varias** metas por receta y usa **exactamente** las etiquetas que guarda
  `AthleteProfile.metas` ('Bajar de peso', 'Definir', 'Aumentar de peso',
  'Mantener'). Si el registro guardara otra etiqueta, el filtro no encontraría
  nada: por eso el test obliga a que las dos listas coincidan.
- ✅ **Catálogo ampliado de 6 a 41 recetas** (`recetas_por_meta.dart`): 35
  recetas nuevas originales —7 desayunos, 9 almuerzos, 9 cenas, 6 pre-entreno y
  4 de recuperación— y las 6 anteriores etiquetadas con criterio nutricional
  (bajo hidrato → Bajar/Definir · alta proteína → Definir/Aumentar · con
  hidratos → Mantener/Aumentar). Reparto: Bajar de peso 13 · Definir 14 ·
  Aumentar de peso 15 · Mantener 16.
- ✅ **Filtro por meta** (`recetasParaMeta`, `conteoPorMeta`) integrado en
  `filtrarRecetas` con parámetro opcional: las llamadas existentes siguen igual.
  Una meta vacía **no** esconde recetas; una meta desconocida devuelve vacío en
  vez de inventar.
- ✅ **UI**: sección "Para tu meta" en Recetas (las 3 primeras recetas de tu
  meta, o el aviso de que elijas una en el Perfil) y fila de chips por meta en
  el catálogo, cada uno **con su recuento real** ("Bajar de peso (19)").
- ✅ **Aviso de orientación** visible en ambas pantallas: los macros son
  estimaciones por ración y no sustituyen consejo profesional.
- ✅ **Modelo separado** en `recipe_model.dart` (reexportado por
  `recetas_catalog.dart`) para que el catálogo base y el ampliado no se
  importen entre sí.
- ✅ **200/200 tests** (`test/recetas_por_meta_test.dart` con 19 + 
  `test/recetas_ui_test.dart` con 8), 0 issues en `flutter analyze`.

**Validaciones que hacen de este lote "honesto" y no solo grande:**

| Regla | Por qué importa |
|---|---|
| kcal ≈ 4·proteína + 4·carbo + 9·grasa (±12 %) en **todas** | Una receta con macros que no cuadran es un dato falso |
| ≥8 recetas por meta | Un filtro que devuelve 2 resultados no sirve |
| Todo receta tiene ingredientes con cantidad por ración | El plan semanal arma la lista de la compra con eso |
| Sin nombres duplicados ni categorías fuera de las 4 de los filtros | Si no, filtros y favoritos se rompen |
| Ningún texto en inglés/francés (salvo "bowl" y "smoothie") | Delata contenido copiado de un medio |
| Las 6 recetas base conservan orden y destacada | `featuredRecipe` y el plan semanal (que busca por nombre) no cambian |

**Corrección durante el lote:** el primer diseño ponía `'Ver todas (19)'` como
acción del encabezado y **desbordaba 35 px a 2.0× de texto en 360 dp** (lo
detectó `accessibilidad_test.dart`). Se quitó el contador: el número exacto ya
está en cada chip, que además es donde el usuario decide.

---

## 12. Principios que se mantienen

- Todo funciona en el propio móvil: sin cuentas ni servidores.
- **Nunca** se muestran datos de salud inventados: si no hay fuente real → "—".
- Cada fase se entrega, se prueba en los dos móviles (Pixel 6a + Xiaomi) y se pide
  aprobación antes de continuar.

## 13. Próximos pasos recomendados

> Actualizado 2026-10-05 (orden aprobado por el usuario: **L2 → L4 → L3**; iOS
> descartado). El estado real del código es **173/173 tests y `flutter analyze` limpio**.

1. **L4 — Recetas por metas** (siguiente): dimensión `metas` en `Recipe`
   (bajar / mantener / ganar músculo), filtro por meta + sección "Para tu meta"
   usando la meta del perfil, y catálogo ampliado a ~35-40 recetas **originales**
   (nada copiado de medios) con criterios OMS/AESAN. Reglas y contexto legal en
   `docs/PROXIMAS_FASES.md §L4`.
2. **L3 — Constructor de rutinas** (el más grande, en 3 sub-lotes): catálogo único de
   ejercicios → pantalla "Mis rutinas" (crear/reordenar/descanso 60 s) → entrada
   desde Home reutilizando el reproductor sin cambios. Detalle en
   `docs/PROXIMAS_FASES.md §L3`.
3. **Verificación física acumulada en el Pixel 6a** (`install -r`, nunca desinstalar):
   P17 (§23) · P18 (§24) · P19 (§25) · P20 (§26) · **P21 (§27)**. Los reportes
   P11–P13 del usuario siguen sin llegar.
4. **8.3 UMP**: el código está listo pero no verificable sin red a Google y una cuenta
   AdMob real.
5. **8.5 Release firmado** (bloqueado): requiere keystore propio + `app-release.aab` +
   Data Safety, y la cuenta de Play exige entidad fuera de Cuba. Lo que sí puede
   quedar preparado desde aquí: firma por variables de entorno con el keystore
   **fuera del repo**, más el comando de build.
6. **Prueba PASA/FALLA de Fases 1-8 en los móviles** siguiendo `GUIA_TESTEO_FASE1.md`
   (Health Connect, entrenamientos, anuncios, Premium, comidas, entrenador con
   cámara, widget/avisos, modo oscuro, texto 2.0×, idioma en vivo y exportar/
   importar/borrar datos más política de privacidad es/en).
7. Con la aprobación manual, decidir publicación.