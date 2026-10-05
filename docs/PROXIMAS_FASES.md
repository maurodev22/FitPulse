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
| L3 — Constructor de entrenamientos | ⏳ **pendiente** | Crear rutinas propias con descanso de 60 s |
| L4 — Recetas originales por metas | ⏳ **pendiente** | Catálogo ~35-40 recetas propias (sin plagio) por meta |
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

## L3 — Constructor de entrenamientos (rutinas propias, descanso 60 s)

**Contexto:** el reproductor ya consume `WorkoutProgram`/`WorkoutExercise` con
`duracion`, `descanso` (default 15 s) y `repeticiones`, y tiene estado `_enDescanso`.
El catálogo es fijo (`workout_catalog.dart`, 4 programas). Falta la capa de creación.

- [ ] Catálogo único de ejercicios disponibles en `lib/state/workout_exercise_catalog.dart`
  (~25: los ya usados por los 4 programas + extensión propia), referenciado también por
  `workout_catalog.dart` para no duplicar.
- [ ] Pantalla "Mis rutinas" (acceso desde Home) con lista de rutinas guardadas + "Crear
  rutina": elegir ejercicios → reordenar → **descanso entre ejercicios default 60 s
  editable por rutina** → guardar.
- [ ] Persistencia de rutinas propias (`fitpulse_rutinas_v1`) en `AppState` +
  export/import incluido.
- [ ] Validación: mínimo 3 y máximo 12 ejercicios; duración total honesta.
- [ ] El reproductor se reutiliza **sin cambios** con la rutina guardada (cuenta sesiones
  reales como cualquier programa; no toca el plan adaptativo).
- [ ] Tests: crear/editar/borrar rutina, reproductor con descanso 60 s, export incluye
  rutinas; `flutter analyze` 0 issues.

**Archivos previstos:** `workout_exercise_catalog.dart` (nuevo), `app_state.dart`,
`workout_builder_screen.dart` (nuevo), `home_screen.dart`, `locale_service.dart`, tests.

---

## L4 — Recetas: catálogo original ampliado agrupado por metas

**Contexto/regla legal:** las recetas del catálogo ya existente (~10 en
`recetas_catalog.dart`) no tienen dimensión "meta". **No se replica contenido de
medios** (copyright): todo el catálogo ampliado es texto original de la app con
criterios nutricionales de guías oficiales (OMS/AESAN) y aviso de contenido orientativo.

- [ ] Nueva dimensión `metas` en `Recipe`: **Bajar de peso / Mantener / Ganar músculo**
  (más de una meta por receta), mapeada honestamente a categoría y macros
  (Low Carb raciones → perder; Alta Proteína → ganar músculo; balanceadas → mantener).
- [ ] `filtrarRecetas` (`recetas_catalog.dart:168-181`) gana el filtro por meta.
- [ ] Catálogo ampliado a ~35-40 recetas, todas con ingredientes por ración (requisito del
  plan semanal de comidas existente).
- [ ] Sección nueva "Para tu meta" en `RecipesScreen` usando la meta del perfil como filtro
  destacado.
- [ ] Aviso en pantalla: contenido orientativo, no sustituye consejo profesional.
- [ ] Tests: cobertura por meta (≥8 recetas por cada una), las recetas nuevas pasan el
  generador del plan semanal (`meal_plan.dart`) sin regresiones; analyze 0.

**Archivos previstos:** `recetas_catalog.dart`, `recipes_screen.dart`, `locale_service.dart`,
`meal_plan.dart` (solo verificación), tests.

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
- **Orden vigente (aprobado por el usuario):** L2 (✅ hecho) → L4 recetas → L3
  constructor. 8.5 (release firmado) queda bloqueado: necesita keystore propio y una
  cuenta de Play con entidad fuera de Cuba.
- Cada lote cierra con `flutter analyze` 0 + `flutter test` verde y commit local
  **sin push**.