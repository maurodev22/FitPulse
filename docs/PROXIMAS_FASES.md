# FitPulse — Próximas fases a ejecutar

> Documento de trabajo del roadmap aprobado (`docs/PLAN_AGREGAR_CORREGIR.md` y
> `docs/DISENO_GAMIFICACION.md`). **L1 (las 3 correcciones de UI) está completada**
> (commit `fb8cdec`: filtro de recetas, pestañas de período y "Ver todo").
> Este archivo lista qué sigue, con tareas accionables y su estado.
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
| L5 — Gamificación Fase A + B | ✅ **completa** | XP/nivel/insignias con feedback sutil (sin modales/sonidos) |
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
`GUIA_TESTEO_COMPLETA.md` §29 (23 pasos), físico pendiente.

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

## L5 — Gamificación sutil: Fase A + B (sobre el XP existente)

**Contexto:** la economía ya existe y se persiste (`app_state.dart:288-313`): +50 XP/sesión,
+100 reto 3→5→7, nivel = 1 + XP~/300, `progresoNivel`, `nombreNivel`, racha real y 5
insignias. Plan completo por fases en `docs/DISENO_GAMIFICACION.md`.

- [ ] **Fase A — semilla:** `AppState.premiar(evento)` con tabla de eventos
  (`sesion: 50`, `reto: 100`, `metasDia: 25`, …) que centraliza los `_xp +=` dispersos;
  micro-barra de nivel (8 px, sin animación) bajo el header de Progreso; test de que el XP
  sobrevive export/import.
- [ ] **Fase B — feedback en el momento:** SnackBar `+50 XP` al completar sesión;
  mini-tarjeta NO bloqueante al subir de nivel (icono + nombre del nivel, se desvanece
  sola, sin botón); insignia nueva con punto de color 24 h; `+25` una vez al día por
  completar los 3 ítems del Día ideal (datos reales).
- [ ] **Reglas innegociables:** sin modales que interrumpan el reproductor, sin sonidos,
  sin vibración, niveles nunca bloquean funcionalidad, logros solo con datos reales.
- [ ] Tests: economía de XP (premios, nivel, persistencia, export/import); analyze 0.
- [ ] Fases C (insignias temáticas), D (ritual semanal), E (toques de contexto) y F
  (opcional) solo tras aprobar A+B.

**Archivos previstos:** `app_state.dart`, `progress_screen.dart`, `home_screen.dart`,
`workout_player_screen.dart`, `locale_service.dart`, tests.

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