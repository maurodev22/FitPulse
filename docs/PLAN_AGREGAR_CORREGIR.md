# FitPulse — Plan de correcciones y adiciones (V9)

> Plan de trabajo "qué agregar y qué corregir", auditado contra el código real
> (2026-09-29). Cada ítem indica evidencia, decisión de diseño, cambios concretos
> y criterios de aceptación. Cuando este plan se apruebe, sus ítems pasan al
> `PLAN.md` como **Fase 9** y se marcan con su estado.

**Reglas del proyecto que se mantienen:** 100 % local/offline, datos de salud
nunca inventados, anuncios solo con IDs de prueba, verificación **sin lectura
visual** (muestreo de píxeles + `uiautomator dump`, scripts `.ps1`), no commitear
PNGs de diagnóstico, `flutter test` y `flutter analyze` limpios al cerrar cada
lote, idioma español y tema oscuro del usuario intactos (o restaurados al final).

---

## 0. Índice del alcance

| # | Tipo | Ítem | Dónde (evidencia verificado) |
|---|---|---|---|
| 1 | 🔧 Corregir | El filtrado de recetas de la vista principal no filtra nada | `recipes_screen.dart:60-71` |
| 2 | 🔧 Corregir | Pestañas Semanal / Mensual / Año en Progreso son decorativas | `progress_screen.dart:980-1022` |
| 3 | 🔧 Corregir | "Ver todo" (sesiones recientes) no hace nada | `progress_screen.dart:170-173` |
| 4 | ➕ Agregar | Registro manual de vasos de agua + meta diaria por litros (mín. 3 L) | Sin soporte: `home_screen.dart:598` (objetivo hardcodeado 2.5) |
| 5 | ➕ Agregar | Constructor de entrenamientos a medida (elegir/ordenar ejercicios + descanso 1 min) | `workout_catalog.dart` (programas fijos), `workout_player_screen.dart` (ya soporta descanso) |
| 6 | ➕ Agregar | Catálogo de recetas original ampliado, agrupado por metas | `recetas_catalog.dart` (~10 recetas, sin dimensión "meta") |
| 7 | ➕ Agregar | Gamificación sutil (XP/nivel/insignias reforzados) | Plan propio en `docs/DISENO_GAMIFICACION.md` |

---

## 1. Correcciones (bugs confirmados en el código)

### 1.1 El filtrado de recetas de la vista principal no filtra nada

**Evidencia.** En `recipes_screen.dart` los pills de categoría cambian `_category`
(línea 99) y se resaltan, pero la sección destacada es `const _FeaturedRecipeSection()`
(línea 66) y `_openCatalog` se abre siempre con `categoria: 'Todas'` (líneas 69-71).
El filtrado real solo existe dentro del catálogo completo (`RecetasCatalogScreen`).

**Decisión de diseño.** El pill de la vista principal debe abrir el catálogo ya
filtrado por esa categoría (la misma acción que "Ver todas", pero pasando
`_category`). La lista destacada sigue siendo editorial y no se re-filtra en vivo
(evita reordenar contenido curado).

**Cambios.**
- `_openCatalog({categoria, recetas})` pasa a usar `_category` del estado en el
  tap de un pill (`onVerTodas` mantiene `'Todas'`).
- `RecetasCatalogScreen` ya filtra con `filtrarRecetas` (línea 861): verificar que
  los valores de `Recipe.categoria` (`'Alta Proteína'`, `'Low Carb'`,
  `'Pre-entreno'`, `'Smoothies'`) coinciden 1:1 con los `_categories` de ambas
  pantallas (hoy sí coinciden; añadir test que lo fije).

**Aceptación.** Tap en "Alta Proteína" → el catálogo abre ya filtrado; `Ver
todas` abre sin filtro; test de `filtrarRecetas` por categoría y búsqueda.

### 1.2 Pestañas Semanal / Mensual / Año en Progreso son decorativas

**Evidencia.** `_PeriodTabs` (`progress_screen.dart:980-1022`): `seleccionado` es
la constante `prPeriodoSemanal` y los pills son `Container` **sin `onTap`**. No
cambian ningún dato ni gráfico.

**Decisión de diseño.** El selector pasa a ser un segmentado real que filtra el
panel de evolución según ventana: **Semanal** (7 días), **Mensual** (30 días) y
**Anual** (365 días). Cada ventana recalcula con los datos reales ya disponibles:
sesiones, minutos, kcal, racha máxima dentro de la ventana y las últimas N barras
de peso (7 semanas / 3 meses / 12 meses). El gráfico de peso (hoy fijo en 7
semanas, línea 1113) usa la ventana del período.

**Cambios.**
- `_PeriodTabs` con estado (`_periodo`) y `onChanged`.
- Función pura `resumenPeriodo(historial, registros, dias)` nueva, testeable con
  fechas simuladas (patrón ya usado en `_rachaActual`).
- Manejar ventana sin datos: estado vacío honesto ("Sin datos en este período").

**Aceptación.** Cambiar de pestaña cambia números + ventana del gráfico; sin datos
en la ventana → mensaje honesto, nunca cero inventado; `rachaMaxima` de la ventana
se calcula sobre `historial` (ya existe `_diasConSesion`).

### 1.3 "Ver todo" (sesiones recientes) no hace nada

**Evidencia.** `SectionHeader(title: prSesionesRecientes, actionLabel:
prVerTodo)` se construye **sin `onAction:`** (`progress_screen.dart:170-173`) →
el `InkWell(onTap: onAction)` del `SectionHeader` (`common.dart:216`) recibe null.

**Decisión de diseño.** "Ver todo" abre una pantalla nueva `HistorialSessionsScreen`
(lista completa de `state.historial`, descendente: fecha, nombre, duración, kcal).
Es dato real ya persistido; sin paginación (máx. honrado por la lista larga con
`ListView.builder`).

**Cambios.**
- Nueva pantalla + `onAction` en el `SectionHeader` que la abre.
- Reutilizar `_SesionRow` (progreso) extraída a un widget compartido.

**Aceptación.** Tap en "Ver todo" abre la lista con todas las sesiones; cada fila
muestra los mismos campos que las recientes; vuelta atrás sin pérdida de estado.

---

## 2. Adiciones (funciones nuevas)

### 2.1 Agua: registro manual de vasos + meta diaria por litros

**Evidencia.** Hoy el objetivo está hardcodeado (`aguaObjetivo = 2.5;
home_screen.dart:598`), la fila "Agua" del Día ideal tiene `onTap` vacío, y el agua
solo se lee de Health Connect (`app_state.aguaHoy`). No existe registro manual ni
ajuste de meta.

**Decisión de diseño.**
- **Meta diaria:** ajuste nuevo en Perfil → "Objetivo de agua diario" con rueda
  paso 0,5 L entre 0,5 y 10 L, **valor inicial 3,0 L** (recomendación base de
  guías AESAN/OMS ~35 ml/kg), persistido en `ConfigService`
  (clave `fitpulse_objetivo_agua_v1`). Reemplaza la constante `2.5` del Home.
- **Registro manual:** botón "+1 vaso" (vaso = 250 ml) en la tarjeta Agua del Home
  y en el Perfil; guarda el acumulado del día en una clave nueva por fecha
  (`fitpulse_agua_YYYY-MM-DD_v1`) dentro del reinicio diario existente.
- **Total honesto e inmutable:** el total del día = **registro manual + lectura de
  Health Connect (si permiso y dato hay)**. El origen se indica en la UI
  ("marcado por ti" / "Health Connect") para no duplicar ni inventar.
- El toggle "Recordatorios de hidratación" (avisos 20:00 actuales) se mantiene tal
  cual; no se mezcla con la meta de litros.

**Cambios.**
- `AppState`: getter `aguaHoyTotal`, métodos `registrarVaso()` / `quitarVaso()`
  persistidos por fecha + getter `objetivoAgua` desde `ConfigService`.
- `home_screen.dart`: sustituir `2.5`, `onTap` abierto con opciones
  (+1 vaso / −1 vaso / marca completa), subtítulo con barra de progreso real.
- `profile_screen.dart`: fila "Objetivo de agua" con rueda paso 0,5 L.

**Aceptación.** Marcar vasos persiste y sobrevive al reinicio; a medianoche el
acumulado se reinicia con el día (reinicio diario existente); la meta 3 L se edita
y refleja en Home; con HC conectado el total suma manual + HC y se etiqueta el
origen; export/import incluye la meta (ya va en `ConfigService`).

### 2.2 Constructor de entrenamientos a medida (descanso 1 min)

**Evidencia.** El reproductor ya consume `WorkoutProgram` con `WorkoutExercise`
(`duracion`, `descanso`, `repeticiones`) y tiene estado de descanso
(`_enDescanso`). El catálogo es fijo (`workout_catalog.dart`, 4 programas; los
descansos son de 10-20 s salvo el estiramiento). Falta la capa de creación.

**Decisión de diseño.**
- Nueva pantalla **"Mis rutinas"**: lista de rutinas guardadas + "Crear rutina".
  Acceso desde el Home (botón junto al hero) y, opcionalmente, desde Progreso.
- Flujo de creación: elegir ejercicios de un catálogo de ejercicios (los que ya
  usan los 4 programas + extensión propia, ~25 ejercicios con nombre, duración
  sugerida y reps orientativas) → ordenar (reordenar lista) → **descanso entre
  ejercicios por defecto 60 s, editable por rutina** → guardar como
  `WorkoutProgram` propio persistido (`fitpulse_rutinas_v1`).
- El reproductor se reutiliza **sin cambios**: recibe la rutina guardada como
  `WorkoutProgram`. El tab de duración total y la tarjeta "descanso" ya se
  renderizan del modelo.
- Validación: mínimo 3 ejercicios y máximo 12; duración total honesta.

**Cambios.**
- `workout_exercise_catalog.dart` nuevo (fuente única de ejercicios disponibles,
  referenciada también por `workout_catalog.dart` para no duplicar).
- `AppState`: `List<WorkoutProgram> rutinasPropias` + persistencia + export/import.
- Pantalla constructor (`workout_builder_screen.dart`) + entrada en Home.

**Aceptación.** Crear rutina → aparece en "Mis rutinas" → al abrir, el reproductor
hace trabajo → descanso 60 s → siguiente; reordenar y editar descanso se
persisten; export incluye las rutinas; las rutinas propias no alteran el plan
adaptativo (siguen contando sesiones de la misma forma).

### 2.3 Recetas: catálogo original ampliado agrupado por metas

**Evidencia.** `recetas_catalog.dart` tiene ~10 recetas con `categoria`
(Alta Proteína / Low Carb / Pre-entreno / Smoothies). No hay dimensión "meta".
Los filtros de la vista principal se corrigen en 1.1.

**Decisión de diseño (importante, límite legal).** **No se replica contenido de
medios**: copiar recetas/redacciones ajenas en la APK viola derechos de autor. Se
amplía con un catálogo **100 % original** (ingredientes genéricos + pasos
redactados en la app), con criterios nutricionales alineados a guías oficiales
(OMS/AESAN para raciones y grupos de alimentos) y se indica en la app que las
recetas son orientativas y no sustituyen consejo profesional. Esto también
protege la revisión MDR (COPY anti-claims) ya pendiente en `PLAN.md`.

- Nueva dimensión `meta` en `Recipe`: **Bajar de peso / Mantener / Ganar músculo**,
  mapeada honestamente con la categoría y los macros (Low Carb raciones → perder;
  Alta Proteína → ganar músculo; balanceadas → mantener). Puede asignarse más de
  una meta por receta.
- Catálogo ampliado a ~35-40 recetas repartidas por meta, todas con ingredientes
  por ración (requisito del plan semanal de comidas existente).
- En Recetas, nueva sección **"Para tu meta"** que muestra las recetas de la meta
  del perfil (Bajar de peso / Mantener / Ganar músculo) como filtro destacado.

**Cambios.**
- `Recipe.metas` + datos nuevos; `filtrarRecetas` gana filtro por meta.
- `RecipesScreen`: sección "Para tu meta" + pills de meta; verificación de que el
  plan semanal (`meal_plan.dart`) sigue generándose sin regresiones.

**Aceptación.** Test de cobertura: cada una de las 3 metas tiene ≥8 recetas; las
recetas nuevas tienen ingredientes por ración y pasan el generador del plan
semanal; la sección "Para tu meta" muestra las recetas de la meta del perfil; sin
texto copiado (política anti-claims redactada en la pantalla).

### 2.4 Gamificación sutil

Plan completo por fases en **`docs/DISENO_GAMIFICACION.md`**. Este plan lo
convoca como Fase 9 del roadmap, orden de ejecución:

1. **Fase A** (semilla): `AppState.premiar(evento)` + tabla de eventos + micro-barra
   de nivel en Progreso.
2. **Fase B** (feedback): SnackBar `+50 XP` al terminar sesión + mini-tarjeta de
   subida de nivel no bloqueante + `+25` por metas del día completas.
3. **Fase C** (insignias): tabla declarativa + siluetas bloqueadas + fechas reales.
4. **Fase D** (ritual semanal) y **E** (toques de contexto) — opcionales tras aprobar B.

**Aceptación de cada fase:** `flutter test` verde (economía de XP, persistencia,
export/import), sin modales que interrumpan el reproductor, sin sonidos.

---

## 3. Orden de ejecución sugerido

Cada lote termina con `flutter test` + `flutter analyze` limpios y verificación
en dispositivo (muestreo de píxeles + `uiautomator dump`, sin lectura visual):

| Lote | Ítems | Riesgo | Valor |
|---|---|---|---|
| **L1** | 1.1 + 1.2 + 1.3 (las 3 correcciones) | Bajo (UI local) | Alto (bugs reportados) |
| **L2** | 2.1 Agua (registro + meta) | Medio (persistencia diaria, nueva clave) | Alto |
| **L3** | 2.2 Constructor de rutinas | Medio-alto (nuevo flujo + persistencia) | Alto |
| **L4** | 2.3 Recetas (catálogo por metas) | Medio (contenido + generador plan semanal) | Medio |
| **L5** | 2.4 Gamificación Fase A (y B si se aprueba) | Bajo (ya existe la economía) | Medio |

**Verificación por lote (sin lectura visual):**
- `flutter test` + `flutter analyze` (0 issues).
- En dispositivo (tema oscuro, español): muestrear píxeles de las zonas cambiadas
  (`muestreo_fino.ps1` patrón ya usado) y `uiautomator dump` de textos/estados.
- Tras las pruebas, restaurar: tema **oscuro** y idioma **español** (preferencias
  del usuario, no se mueven).

**No se hace:** push automático de commits; nuevos PNGs de diagnóstico en el repo;
desinstalar la app; tocar la cuenta AdMob ni los IDs de anuncios.

---

## 4. Decisiones de producto registradas (para confirmación del usuario)

1. **Agua:** vaso = 250 ml; meta editable 0,5-10 L por rueda, por defecto 3,0 L;
   total del día = manual + Health Connect (si hay permiso) con origen etiquetado.
2. **Periodos en Progreso:** Semanal=7d / Mensual=30d / Anual=365d filtran sesiones,
   minutos, kcal, racha y ventana del gráfico de peso.
3. **"Ver todo":** pantalla de historial completo de sesiones (lista larga).
4. **Constructor:** mínimo 3 / máximo 12 ejercicios; descanso por defecto 60 s
   editable por rutina; reutiliza el reproductor actual sin cambios.
5. **Recetas:** ninguna receta copiada de medios; catálogo original con metas
   (Bajar de peso / Mantener / Ganar músculo) y aviso de contenido orientativo.
6. **Gamificación:** sin modales que interrumpan, sin sonidos, niveles nunca
   bloquean funcionalidad, logros solo con datos reales.