# FitPulse — Próximas fases a ejecutar

> Documento de trabajo del roadmap aprobado (`docs/PLAN_AGREGAR_CORREGIR.md` y
> `docs/DISENO_GAMIFICACION.md`). **L1 (las 3 correcciones de UI) está completada**
> (commit `fb8cdec`: filtro de recetas, pestañas de período y "Ver todo").
> **L2, L4, L3 y L5 están completas** (A+B+C+D: las Fases C de insignias y D "Tu
> semana" están resueltas en las secciones de abajo), y el cierre UI/UX de los 8 puntos pedidos
> está en la sección de abajo (2026-10-06). Este archivo lista qué sigue, con
> tareas accionables y su estado.
> Reglas del proyecto que se mantienen: 100 % local/offline, datos de salud nunca
> inventados, verificación sin lectura visual (muestreo de píxeles + dump),
> no commitear PNGs de diagnóstico, `flutter test` + `flutter analyze` limpios al
> cerrar cada lote, tema oscuro y español del usuario intactos.

## Estado del roadmap

| Fase | Estado | Objetivo |
|---|---|---|
| L1 — Correcciones UI (recetas / período / "Ver todo") | ✅ `fb8cdec` + verificado en Pixel (2026-09-30) | Bugs de la lista del cliente corregidos |
| Hotfix UI P1–P10 (aprobado 30/09) | ✅ `0bf3f15` (P1–P7) + `b9b91d1` (P8–P10, sesión) | Detalle del día, ventana visible, insignias a Perfil, Consejos funcionales, racha ≥7, editar metas, Configuración, peso Progreso→Perfil, sin duplicados en Perfil, mínimo 2 días |
| Verificación física del hotfix en Pixel 6a | ⏳ **en curso** | `docs/HOTFIX_UI.md` + `docs/GUIA_TESTEO_INTEGRAL.md §12-13` |
| L2 — Agua (registro manual + meta diaria) | ✅ **completa** — registro manual P14, honestidad P19, meta editable P21 | Meta de agua real y persistida por el usuario |
| L3 — Constructor de entrenamientos | ✅ **completa** — catálogo único de 34 ejercicios, "Mis rutinas" con editor y entrada desde Home | Crear rutinas propias con descanso de 60 s |
| L4 — Recetas originales por metas | ✅ **completa** — 41 recetas (35 nuevas originales), filtro por meta y sección "Para tu meta" | Catálogo agrupado por meta, sin plagio |
| L5 — Gamificación Fase A + B + C + D + E | ✅ **completa** | XP/nivel/insignias con feedback sutil, **catálogo completo de 9 insignias** (siluetas bloqueadas + fecha real), **tarjeta "Tu semana"** con datos reales de la semana pasada y **toques de contexto**: chip "Nv N · Nombre" en Progreso y Perfil, mini-barra de XP (10 px) en Home y "Lv N" en el widget de home |
| Verificación física L1 | ✅ Pixel 6a (30/09, píxeles+dump) · ⏳ Xiaomi (dump MIUI) | Guía: `docs/GUIA_TESTEO_INTEGRAL.md §12` |

---

## L2 — Agua: registro manual de vasos + meta diaria — ✅ COMPLETA

**Cómo quedó resuelto (tres lotes, no uno):**

- **P14 — registro manual:** la fila "Agua" del Día ideal abre un diálogo donde el
  usuario declara los litros del día; se suman a lo leído de Health Connect y se
  reinician con el resto del balance al cambiar de día (`app_state.dart`).
- **P19 — honestidad del dato:** declarar más de 5 L/día muestra un SnackBar de 5 s y
  **no** registra ni cierra el diálogo (`Validators.maxAguaDiariaLitros`).
- **P21 (este lote) — meta diaria editable:** `AppState.metaAguaDiaria` pasó de
  `static const 2.5` a un valor persistido (`fitpulse_meta_agua_v1`), con
  rueda de 0,5–10 L en paso 0,5 en Perfil, default **2,5 L**, ajustado por
  `Validators.ajustarMetaAgua`, incluido en export/import y reiniciado a 2,5 L tras
  un borrado total.

**Diferencias con el plan original de esta tabla (y por qué):**

| Plan original | Realizado | Motivo |
|---|---|---|
| Default 3,0 L | **2,5 L** | 3,0 L subiría el listón del Día ideal sin que el usuario lo elija (≈35 ml/kg para ~70 kg ya da 2,5 L). Quien quiera más, lo sube con la rueda. |
| Persistir en `ConfigService` | En `AppState` | La meta es del usuario y va con su balance; `ConfigService` es para interruptores/EULA/tema. Así no se crea acoplamiento entre servicios. |
| Botones "+1/−1 vaso" | Diálogo con litros | El diálogo acepta cualquier cantidad (250 ml, 500 ml, 1 L); forzar un botón obligaría a sumarMany clicks. |

**Añadido por coherencia (no estaba en el plan):** `AppState.origenAguaHoy` etiqueta el
origen real del dato ("marcado por ti" / "Health Connect" / ambos) en el diálogo de agua,
y el estado de salud (P20) puntúa el agua **contra la meta del usuario**, no contra un
2,5 fijo: si subes la meta a 3 L, la tarjeta deja de dar el punto máximo por 2,5 L.

- [x] Meta diaria editable y persistida, con rango honesto 0,5–10 L
- [x] Total honesto del día = registro manual + Health Connect, con origen etiquetado
- [x] Export/import de la meta y reinicio a 2,5 L tras borrado total
- [x] Tests: 14 nuevos en `test/meta_agua_test.dart`; suite completa 173/173
- [ ] Verificación física (cuando haya ventana): muestreo de píxeles + dump de la fila
      "Meta diaria de agua" en Perfil y del diálogo con la rueda.

---

## L3 — Constructor de entrenamientos (rutinas propias, descanso 60 s) — ✅ COMPLETA

**Cómo quedó resuelto:**

- `workout_exercise_catalog.dart`: **34 ejercicios** en 6 grupos (Piernas,
  Empuje, Tirón, Core, Cardio, Movilidad) con tiempo y repeticiones sugeridos.
  Es el **catálogo único**: los 4 programas fijos usan exactamente estos nombres,
  porque `pose_coach.dart` decide la corrección de postura por el nombre (si el
  constructor usara otros, el entrenador con cámara dejaría de reconocerlos). Un
  test lo comprueba.
- `rutinas.dart`: modelo `Rutina` (id, nombre, ejercicios, `descansoPorDefecto`)
  con `aPrograma()` → `WorkoutProgram`. **El reproductor se reutiliza sin
  cambios**: `WorkoutPlayerScreen` no distingue rutinas propias de programas del
  catálogo, así que no se duplicó ese código.
- `workout_builder_screen.dart`: "Mis rutinas" (lista con estado vacío honesto,
  sin rutinas de ejemplo) + editor (nombre, descanso 15–120 s con 60 s por
  defecto, añadir del catálogo filtrable por grupo y texto, reordenar ↑↓,
  quitar, resumen en vivo). Entrada desde Home que dice cuántas rutinas hay.
- Persistencia `fitpulse_rutinas_v1` en `AppState`, incluida en el backup
  (export/import) y borrada en `resetTrasBorrado`.
- Validación en `Validators`: 3–12 ejercicios, nombre 3–40, descanso 15–120 s,
  ejercicio 10–180 s, rutina ≤ 60 min. `guardarRutina` pasa la rutina por
  `Rutina.fromJson` para aplicar los topes, así que un backup editado a mano no
  puede dejar una rutina imposible.

**Diferencias con el plan original de esta lista (y por qué):**

| Plan original | Realizado | Motivo |
|---|---|---|
| Catálogo de ~25 ejercicios | 34 | Tiene que cubrir los 38 nombres que usan los 4 programas fijos (hay nombres repetidos entre programas) más los nuevos. |
| "Duración total honesta" | Intensidad y kcal **derivadas** del contenido, siempre etiquetadas como "Estimación: …" | No hay medición real de gasto; el propio `WorkoutSession.calorias` ya lo advertía. Un número sin etiqueta habría sido inventar un dato de salud. |
| Descanso editable "por rutina" | 15–120 s, paso de 15 s | Con menos de 15 s la sesión no es un entrenamiento; con más de 120 s no se sostiene en un móvil. El tope se **explica** en pantalla, no se impone en silencio. |
| "Reutiliza el reproductor sin cambios" | Igual | `aPrograma()` convierte la rutina a `WorkoutProgram`; `WorkoutPlayerScreen` no se tocó. |

**Verificación:** 260/260 tests, `flutter analyze` 0 issues. Test manual en
`docs/GUIA_TESTEO_UNIFICADA.md` fase D (§D4–§D6) y detalle técnico en
`GUIA_TESTEO_COMPLETA.md` §29 (23 pasos); físico pendiente.

**Archivos:** `workout_exercise_catalog.dart` (nuevo), `rutinas.dart` (nuevo),
`workout_builder_screen.dart` (nuevo), `app_state.dart`, `validators.dart`,
`home_screen.dart`, `locale_service.dart`, `test/rutinas_test.dart`,
`test/workout_builder_ui_test.dart`.

---

## L4 — Recetas: catálogo original ampliado agrupado por metas — ✅ COMPLETA

**Cómo quedó resuelto:**

- Dimensión `metas` en `Recipe` (`recipe_model.dart`), con **varias metas por
  receta** y usando las etiquetas exactas del perfil ('Bajar de peso', 'Definir',
  'Aumentar de peso', 'Mantener').
- Catálogo de **41 recetas**: las 6 anteriores (mismo orden, misma destacada)
  más **35 nuevas originales** en `recetas_por_meta.dart` — 7 desayunos, 9
  almuerzos, 9 cenas, 6 pre-entreno y 4 de recuperación.
- `recetasParaMeta()` / `conteoPorMeta()` y filtro por meta opcional en
  `filtrarRecetas` (las llamadas antiguas siguen behaving igual).
- Sección "Para tu meta" en Recetas + fila de chips por meta con recuento real
  en el catálogo, y aviso de orientación en ambas pantallas.

**Diferencias con el plan original de esta tabla (y por qué):**

| Plan original | Realizado | Motivo |
|---|---|---|
| Metas: "Bajar de peso / Mantener / Ganar músculo" | Las 4 etiquetas reales del perfil: 'Bajar de peso', 'Definir', 'Aumentar de peso', 'Mantener' | Son los valores que el registro guarda. Inventar un "Ganar músculo" habría dejado el filtro siempre vacío. |
| Ampliar el mismo `recetas_catalog.dart` | Modelo en `recipe_model.dart` + catálogo ampliado en `recetas_por_meta.dart` | Evita una importación circular entre el catálogo base y el ampliado, y mantiene cada archivo revisable. |
| ~35-40 recetas | 41 | La diferencia son las 6 recetas base, que también hubo que etiquetar. |
| "Contenido original con criterios OMS/AESAN" | Igual, más un test que verifica coherencia kcal↔macros (±12 %) | Un test que exige que los números cuadren vale más que una cita a una guía: si una receta queda mal, falla el build. |

**Regla legal mantenida:** ninguna receta procede de un medio, cookbook o web. Un
test rejecta palabras en inglés/francés en los textos del catálogo (salvo "bowl"
y "smoothie", que el catálogo original ya usaba y son de uso normal en español).

- [x] Dimensión `metas` + filtro por meta
- [x] Catálogo ampliado con ingredientes por ración
- [x] Sección "Para tu meta" y chips con recuento
- [x] Aviso de contenido orientativo
- [x] Tests: 27 nuevos, suite 200/200, analyze 0
- [ ] Verificación física: abrir Recetas, comprobar los chips y que la receta
      cargue imagen y macros sin fallos

---

## L5 — Gamificación sutil (Fases A + B + C, sobre el XP existente)

**Contexto:** la economía ya existe y se persiste (`app_state.dart:288-313`): +50 XP/sesión,
+100 reto 3→5→7, nivel = 1 + XP~/300, `progresoNivel`, `nombreNivel`, racha real y 5
insignias. Plan completo por fases en `docs/DISENO_GAMIFICACION.md`.

- [x] **Fase A — semilla:** `AppState.premiar(evento)` con tabla de eventos
  (`sesion: 50`, `reto: 100`, `metasDia: 25`, …) que centraliza los `_xp +=` dispersos;
  micro-barra de nivel (8 px, sin animación) bajo el header de Progreso; test de que el XP
  sobrevive export/import.
- [x] **Fase B — feedback en el momento:** SnackBar `+50 XP` al completar sesión;
  mini-tarjeta NO bloqueante al subir de nivel (icono + nombre del nivel, se desvanece
  sola, sin botón); insignia nueva con punto de color 24 h; `+25` una vez al día por
  completar los 3 ítems del Día ideal (datos reales).
- [x] **Reglas innegociables:** sin modales que interrumpan el reproductor, sin sonidos,
  sin vibración, niveles nunca bloquean funcionalidad, logros solo con datos reales.
- [x] Tests: economía de XP (premios, nivel, persistencia, export/import); analyze 0.
- [x] **Fase C — insignias (2026-10-06):** detalle en la sección de abajo.
- [x] **Fase D — ritual semanal (2026-10-06):** detalle en la sección de abajo.
- [x] **Fase E — toques de contexto (2026-10-06):** detalle en la sección de abajo.
- [x] **Fase F (opcional, parcial):** F1 (teaser "Próxima insignia") y F3 (tests de
  economía) hechos en la sección de abajo; F2 (refactor de tokens de avisos)
  documentado como pendiente menor sin duplicación detectada.

**Archivos previstos:** `app_state.dart`, `progress_screen.dart`, `home_screen.dart`,
`workout_player_screen.dart`, `locale_service.dart`, tests.

---

## Fase C — Estructura de insignias (2026-10-06) ✅ código

**Objetivo (`docs/DISENO_GAMIFICACION.md`, FASE C):** catálogo completo y siempre visible
de **9 insignias** con dos estados: conseguida (icono a color + fecha REAL de desbloqueo) y
bloqueada (silueta gris con candado + condición escrita, sin contadores de progreso).

- [x] `lib/state/insignias.dart`: catálogo declarativo + `evaluarInsignias` puro. Cada
  insignia se otorga SOLO con su condición real sobre datos persistidos; las fechas se
  derivan del historial (nunca se inventan): primera sesión, racha 3/7 (primer día en que
  la racha alcanzó el objetivo), hierro (25ª sesión), veterano (100ª), marca personal
  (4ª semana seguida con peso), técnico (fecha en que se llegó a 10 ejercicios con reps),
  hidratado (7º día con la meta de agua) y 1er reto.
- [x] **Nuevo dato persistido:** días (medianoche) con la **meta de agua cumplida**
  (`fitpulse_agua_dias_v1`, máx. 90). Se anota un día solo si el agua real del día ≥ meta;
  hooks en `registrarAgua`, `refreshHealthConnect` e `init`. Viaja en export/import y se
  limpia con `resetTrasBorrado`.
- [x] **Perfil → Insignias & Logros:** contador **"N / 9 insignias"**, cuadrícula de 9,
  siluetas con candado y fecha real en las conseguidas (`MaterialLocalizations.formatCompactDate`).
- [x] **Nota de diseño:** "Constancia" (racha 3) y "1er Reto" comparten día de desbloqueo
  porque el reto de 3 días se completa exactamente cuando la racha llega a 3
  (`retoCompletado` deriva de la racha). La tabla del diseño las lista por separado y hoy
  ya eran dos insignias; se mantienen las dos (pendiente de que el usuario decida fusionar).
- [x] **Cambio frente al estado anterior:** se retira la insignia "Nivel" de la cuadrícula
  (la tabla del diseño tiene 9 y no la incluye; el nivel/XP sigue visible en Progreso y en
  "Nivel y preferencias" del Perfil).
- [x] Tests: `test/insignias_test.dart` (12) + 2 widget tests en `perfil_test.dart`;
  suite **280/280** y `flutter analyze` 0 issues.

---

## Fase D — Ritual semanal sin presión (2026-10-06) ✅ código

> Objetivo (`docs/DISENO_GAMIFICACION.md`, FASE D): una vista "a vuelo de
> pájaro" de la semana pasada que motive sin meter prisa. Ninguna notificación
> nueva: solo el toggle local de avisos ya existente.

- [x] **Nuevo dato honesto persistido: XP por día** (`xpPorDia`,
  `fitpulse_xp_dias_v1`, tope 90 días). Antes cada premio hacía `_xp +=`
  directo y el día perdía la traza; ahora `_otorgarXp(puntos)` (centraliza los
  4 puntos: sesión 50, reto 100, anuncio, día ideal 25) también anota el día.
  Viaja en export/import y se limpia con `resetTrasBorrado`.
- [x] **D1 — Tarjeta "Tu semana" en Home** (informativa, no push): aparece solo
  si hubo actividad la semana pasada y muestra datos REALES
  (`diasActivosSemanaPasada` · `sesionesSemanaPasada` · `xpSemanaPasada`,
  lunes→domingo anterior): "6 días · 4 sesiones · 350 XP". Sin botones de
  compartir. Si no hay actividad, no aparece (nada de "0 días").
- [x] **D2 — Reto semanal opcional:** línea discreta dentro de la tarjeta
  "Vas 3 de 5 días" (racha viva vs objetivo 3→5→7 de la mecánica existente),
  solo si hay racha viva. Sin penalización al fallar.
- [x] **D3 — Cero lenguaje negativo:** barrido en `lib/`: no existe copy de
  "racha perdida"/"te quedan X horas"; el único "penaliza" está en Copy: "el
  día libre NO penaliza tu racha" (afirmativo, se mantiene).
- [x] Tests: `test/tu_semana_test.dart` (8) → suite **288/288** verdes y
  `flutter analyze` 0 issues.

---

## Fase E — Toques de contexto (identidad leve) (2026-10-06) ✅ código

> Objetivo (`docs/DISENO_GAMIFICACION.md`, FASE E): que el nivel forme parte de
> la identidad del usuario, sin invadirlo, y que los tres puntos muestren el
> mismo valor que `AppState.nivel` tras reiniciar la app.

- [x] **E1 — Chip "Nv 3 · Intermedio"** en el header de **Progreso** y en el
  **Perfil**: `NivelChip` (pasivo, sin ripple muerto). Vive en su propia línea
  bajo el Row del header: a escala de texto 2.0× no compite con el chip de
  racha por el ancho (un LayoutBuilder + `Flexible` + `softWrap` garantiza que
  nunca desborde: compacto a 1.0×, envuelve si hace falta).
- [x] **E2 — Mini-barra de XP en Home** (10 px, bajo la racha, información
  pasiva): `LinearProgressIndicator` con `progresoNivel` real, sin interacción.
- [x] **E3 — Widget de home 2×2**: el snapshot JSON del widget ahora lleva el
  nivel real (`construirSnapshotWidget(..., nivel)`), `HomeWidgetBridge` lo
  envía y el lado nativo (`HomeWidgetProvider.kt`) pinta la micro-burbuja
  "Hoy · Lv N" en el subtítulo (mismo cálculo que la app: 1 + XP/300). El
  cambio nativo se verifica en la próxima instalación en móvil (no cubierta
  por `flutter test`).
- [x] Tests: `test/fase_e_test.dart` (5) + `avisos_test` actualizado → suite
  **293/293** verdes y `flutter analyze` 0 issues; accesibilidad/responsive
  re-verificadas con los chips nuevos (360/393/411 dp, 2.0×).

---

## Fase F — Profundización opcional, elegida (F1 + F3) (2026-10-06) ✅ código

> El usuario eligió "F1 + F3 (Recomendado)" de la Fase F opcional
> (`docs/DISENO_GAMIFICACION.md`, FASE F). F2 (refactor de tokens) queda
> documentado como pendiente menor: la auditoría no encontró duplicación de
> lógica de niveles en `avisos.dart` (los textos de avisos no calculan niveles).

- [x] **F1 — Teaser "Próxima insignia"**: en la cuadrícula de Perfil, la
  insignia bloqueada más cercana en orden de catálogo se realza de forma
  pasiva (borde sutil + nombre y condición en primario) mostrando su
  condición escrita ("Constancia: 3 días seguidos"). **Sin barra de progreso
  numérica** (cero presión) y sin ripple muerto (no es un botón).
- [x] **F3 — Tests de economía** (`test/fase_f_test.dart`): tabla de premios
  real (sesión 50, reto 100 en 3→5→7, anuncio una vez/día, día ideal 25 ya en
  su lote, 7 días seguidos = 550 XP + objetivo 7), umbrales de nivel
  (Princi/p./Intermedio ≥ 4/Avanzado ≥ 8), persistencia y export/import del
  XP + ledger + objetivo, reset. Nada inventado: todo sale de `AppState`.
- [x] Tests: `test/fase_f_test.dart` (10) → suite **303/303** verdes y
  `flutter analyze` 0 issues.

---

## Cierre UI/UX — 8 puntos pedidos (2026-10-06) ✅ código

Detalle de `PLAN.md §11.7`. Estado: **303/303 tests**, `flutter analyze` 0 issues.

- [x] **Avatar** siempre cuadrado (`lib/utils/foto_avatar.dart`): recorte del lado más
  corto centrado + respiro 2 % hacia **dentro**; `null` si no hay recorte fiable.
- [x] **Registro**: `SnackBar` "Falta por llenar: *campo*" con el primer campo vacío.
- [x] **Editor de rutinas**: fuera el "Guardar" del AppBar; sigue la del pie.
- [x] **Imágenes de receta**: 41 ilustraciones propias en `assets/images/recetas/`
  (generadas por `work/gen_recetas.py`, WebP 900×520, ~0,21 MB en total) resueltas por
  `imagenDeReceta(nombre)`; `Recipe.imagen` es nullable y el catálogo ya no guarda
  rutas a mano, con lo que dos recetas no pueden acabar con el mismo dibujo.
- [x] **Chip de racha pulsable** → `mostrarEstadisticas` (racha actual, mejor racha,
  días desde instalación, sesiones, nivel).
- [x] **Campanas muertas eliminadas** de Inicio, Progreso y Consejos (no hacían nada).
- [x] **`pfMetaPasos`** → "1000 pasos mínimo".
- [x] **Premium de prueba fuera de la UI** en release; el toggle de anuncios se queda
  porque es consentimiento real.
- [x] **Enlaces muertos del mismo lote:** "Ver plan" de Recetas (tenía chevron pero no
  `onAction`), la tarjeta de pasos y la fila de macros de Inicio (`onTap: () {}` que
  sí hacía ripple) ahora abren el plan semanal y el detalle del día. Hay una búsqueda
  activa de handlers vacíos en `lib/`.

**Guardián nuevo:** `assets/images/` solo empaqueta los archivos **directos**; hizo
falta declarar `assets/images/recetas/` aparte en `pubspec.yaml` y hay un test que lo
comprueba (`test/recetas_imagenes_test.dart`).

**Queda pendiente de este cierre:** la verificación física en el Pixel 6a
(`docs/GUIA_TESTEO_UNIFICADA.md`) y los reportes del usuario.

---

## Pendientes de verificación física (bloqueados por los móviles)

- [ ] **L1 en Pixel 6a** (aceptada sin físico por decisión del usuario 2026-09-29): el foco
  lo roba WhatsApp al lanzar la app. Opciones cuando haya ventana: pausar WhatsApp
  (`am force-stop com.whatsapp.w4b`) durante ~5 min y relanzarla al final, o pedir tener el
  teléfono libre. Verificar: pills de recetas abriendo el catálogo filtrado, pestañas de
  período cambiando el resumen/gráfico, "Ver todo" → historial. Tema oscuro + español
  intactos.
- [ ] **Xiaomi Redmi 8A (F9b + L1)**: `uiautomator dump` falla en MIUI
  (excepción `theme_compatibility.xml`). Workarounds a probar:
  1. `uiautomator dump --compressed`; 2. dump vía `app_process` (AccessibilityService);
  3. muestreo de píxeles de zonas clave sin depender del dump. Si ninguno funciona,
  documentar e intentar en otra revisión de MIUI.
- [ ] **Prueba PASA/FALLA de Fases 1-8** en ambos móviles siguiendo `GUIA_TESTEO_FASE1.md`
  (pendiente histórico del `PLAN.md`, punto 13.2).

## Notas de proceso

- `GUIA_TESTEO_MANUAL.md` (guía manual de testeo de la fase de bandas) sigue **sin
  commitear** a la espera de la aprobación del usuario.
- **Orden vigente (aprobado por el usuario):** L2 (✅ hecho) → L4 recetas (✅
  hecho) → L3 constructor (✅ hecho). Con esto queda **cerrado el roadmap de
  lotes L2–L5**. 8.5 (release firmado) queda bloqueado: necesita keystore propio
  y una cuenta de Play con entidad fuera de Cuba.
- Cada lote cierra con `flutter analyze` 0 + `flutter test` verde y commit local
  **sin push**.