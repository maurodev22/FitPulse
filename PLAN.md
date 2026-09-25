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
| Fases 3–8 | ⏳ | Pendientes (ver detalle abajo) |

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

## 9. Fase 6 — Extras de retención ⏳

- Widgets de home screen (pasos, calorías, racha).
- Avisos locales (hidratación, racha en riesgo), cada uno activable/desactivable por
  separado (permiso por tipo).

## 10. Fase 7 — Experiencia premium y accesibilidad ⏳

- Modo oscuro, contraste y tamaño accesibles (EAA/WCAG), micro-animaciones.
- Todos los textos y documentos en es/en (hoy la mayoría del UI está hardcodeada en
  español; `LocaleService` solo cubre parte).

## 11. Fase 8 — Privacidad, legal UE y lanzamiento ⏳

- Exportar/importar datos del móvil con cifrado y borrado total (derecho GDPR).
- Términos, EULA y política de privacidad es/en con cláusulas UE: edad mínima 16
  (consentimiento parental si aplica), devolución 14 días en compras, aviso "app de
  bienestar, no asesoramiento médico", datos de comerciante (cuando exista entidad
  fuera de Cuba).
- Release firmado con clave propia (nunca debug) y publicación en Google Play con la
  ficha Data Safety cumplimentada.

---

## 12. Principios que se mantienen

- Todo funciona en el propio móvil: sin cuentas ni servidores.
- **Nunca** se muestran datos de salud inventados: si no hay fuente real → "—".
- Cada fase se entrega, se prueba en los dos móviles (Pixel 6a + Xiaomi) y se pide
  aprobación antes de continuar.

## 13. Próximos pasos recomendados

1. **Probar Fases 1-5 en los móviles** siguiendo `GUIA_TESTEO_FASE1.md`
   (registrar PASA/FALLA por dispositivo: Health Connect, entrenamientos, anuncios,
   Premium, comidas y entrenador con cámara).
2. **Actualizar README y FUNCIONALIDADES** para reflejar el estado real
   (Fases 0/0.5/1/2/3/4/5 ✅ en código).
3. Con la aprobación, abrir **Fase 6** (widgets de home + avisos locales).