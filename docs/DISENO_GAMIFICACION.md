# Diseño: Gamificación sutil de FitPulse

> Documento de diseño por fases. Objetivo: un proceso de gamificación **muy sutil**
> que refuerce hábitos sin ruido, sin presión y sin interrumpir el flujo de
> entrenamiento. 100 % local y offline, coherente con el resto de la app
> (todos los logros se otorgan sobre datos **reales y verificables** del usuario).

---

## 0. Qué existe hoy (punto de partida real, verificado en código)

La app YA tiene la semilla de una economía de puntos:

| Mecánica | Estado actual | Dónde |
|---|---|---|
| XP por sesión | `+50` en `registrarSesionCompletada` | `app_state.dart:444` |
| XP por reto 3→5→7 días | `+100` al completar | `app_state.dart:453` |
| XP por anuncio recompensado | `+ptsRecompensaAnuncio` (valor del anuncio) | `app_state.dart:473` |
| Nivel | `1 + xp ~/ 300` (300 XP por nivel) | `app_state.dart:293` |
| Progreso de nivel | `(xp % 300) / 300` (0..1) | `app_state.dart:296` |
| Nombre de nivel | Principiante (<4) / Intermedio (<8) / Avanzado | `app_state.dart:299` |
| Racha real | Días consecutivos con sesión, desde hoy o ayer | `app_state.dart:410` |
| Reto activo | 3 → 5 → 7 días seguidos | `app_state.dart:306` |
| Insignias | Primera sesión · Racha 3 · Racha 7 · Nivel 2+ · Reto | `progress_screen.dart:835` |

**Diagnóstico:** la economía está construida pero **invisible en el momento de la
acción**. El XP se acumula en silencio y solo se ve (parcialmente) en la pantalla
de Progreso. No hay ningún feedback al completar una sesión, subir de nivel u
obtener insignia. Ese es exactamente el hueco que cubre este diseño.

---

## Principios no negociables (para que sea *sutil*)

1. **Refuerzo en el momento, nunca antes.** El feedback llega al terminar una
   acción (sesión, metas del día, reto). Nunca un modal que interrumpa antes de
   entrenar.
2. **Sin sonidos, sin vibración, sin modales.** Celebración visual pequeña que
   no bloquea y desaparece sola.
3. **Los niveles y puntos nunca bloquean funcionalidad.** No son moneda ni
   requisito; son reconocimiento.
4. **Todo verificable.** Nunca inventar logros: se otorgan con los mismos
   registros que ya se persisten (historial, reps, peso, agua).
5. **Cero presión negativa.** No penalizar al perder racha, no mostrar
   "perdiste tu racha". Solo celebrar logros conseguidos.
6. **Un solo feed coherente.** XP / Nivel / Insignias siempre provienen de
   `AppState`; nunca se duplica cálculo en pantalla.

---

## FASE A — Semilla silenciosa (fundamentos únicos)

> Objetivo: dejar la economía impecable e invisible. Cero cambios visuales
> llamativos; solo corrección y medición.

- **A1. Eventos de XP centralizados.** Refactor: `AppState.premiar(evento)` con
  una tabla `EventoXp {sesion: 50, reto: 100, metasDia: 25, ...}` en lugar de
  `_xp +=` dispersos por el código. Registro de auditoría en memoria.
- **A2. Persistencia verificada.** Confirmar que `xp` y `nivel` ya viajan en el
  snapshot de export/import (`app_state.dart:667`) y añadir test.
- **A3. Base de datos de insignias en un solo sitio.** Nueva tabla declarativa
  (id, icono, titulo, descripción, condición sobre datos reales, fecha de logro).
  Las insignias actuales de `progress_screen` pasan a esta tabla.
- **A4. Micro-barra de nivel en Progreso.** Barra discreta (8 px) bajo el header
  con `Nivel N · X / 300 pts` reutilizando `progresoNivel`. Sin animación.
- **Criterio de aceptación:** `flutter test` pasa; la barra de nivel muestra el
  mismo valor que `AppState.nivel`; el XP sobrevive export/import.

> **Qué NO hacer en esta fase:** notificaciones, sonidos, animaciones, modales,
> confetti, nada visible fuera de Progreso.

---

## FASE B — Feedback en el momento (micro-celebraciones)

> Objetivo: que el usuario *sienta* que el sistema responde, con el menor ruido
> visual posible.

- **B1. SnackBar al completar sesión.** Al cerrar el reproductor tras terminar:
  `+50 XP · Nivel 3 de 17` (o "¡Subiste a Nivel 3!"). Un SnackBar estándar, 2 s,
  sin icono animado.
- **B2. Chip/Tarjeta de subida de nivel NO bloqueante.** Si se cruza un nivel:
  mini-tarjeta superior (no modal) con icono `workspace_premium`, nombre del
  nivel ("Nivel 3 · Intermedio"), que se desvanece sola. No tiene botón.
- **B3. Insignia nueva → misma tarjeta.** Al desbloquear, aparece en la misma
  mini-tarjeta; la Insignia recién obtenida se marca con un punto de color en la
  cuadrícula de Progreso durante 24 h.
- **B4. Puntos por metas del día.** Completar los 3 ítems del "Día ideal" de
  Home (entrenamiento / macros / agua) otorga `+25` una vez al día. Datos reales
  (los registros ya existen); el premio es honesto porque los ítems ya se marcan.
- **Criterio de aceptación:** completar una sesión muestra +50 XP; subir de
  nivel muestra la tarjeta sin navegación forzada; sin sonido ni vibración.

> **Qué NO hacer:** ventana emergente que pida "compartir en redes", audio,
> consecución *fake*, premios por acciones triviales (abrir la app).

---

## FASE C — Estructura de insignias (logros temáticos)

> Objetivo: dar profundidad con insignias opcionales, siempre verificables.

Tabla propuesta (condiciones sobre datos ya persistidos):

| Insignia | Condición | Fuente |
|---|---|---|
| Primer paso | 1ª sesión (existe hoy) | `historial` |
| Constancia | Racha 3 (existe hoy) | `rachaMaxima` |
| Disciplina | Racha 7 (existe hoy) | `rachaMaxima` |
| Hierro | 25 sesiones | `historial.length` |
| Veterano | 100 sesiones | `historial.length` |
| Marca personal | registrar peso 4 semanas seguidas | `registros` de peso |
| Técnico | registrar reps en 10 ejercicios distintos | `historialReps` |
| Hidratado | cumplir meta de agua 7 días (requiere Fase de agua) | registro diario de agua |
| 1er Reto | completar reto 3 días (existe hoy) | `retoCompletado` |

- **C1. Estados visuales:** conseguida (color) / bloqueada (silueta gris con
  candado y descripción). La silueta comunica "existe y es alcanzable" sin ruido.
- **C2. Fecha y detalle:** cada insignia conseguida muestra la fecha real de
  desbloqueo.
- **C3. Contador:** "5 / 9 insignias" en el encabezado de la sección.
- **Criterio de aceptación:** cada insignia se otorga SOLO con su condición real
  verificada; las bloqueadas no muestran progreso (sin "te faltan 2 para…").

> **Qué NO hacer:** insignias temporales ("esta semana en la app"), logros de
> pago, condiciones que la app no pueda verificar con datos locales.

---

## FASE D — Ritual semanal sin presión

> Objetivo: una vista "a vuelo de pájaro" que motive sin meter prisa.

- **D1. Tarjeta "Tu semana" en Home (informativa, no push).** Aparece solo si
  hay actividad la semana anterior: "6 días · 4 sesiones · 350 XP". Sin botones
  de "compartir". Si no hay actividad, la tarjeta simplemente no aparece.
- **D2. Reto semanal opcional.** Exponer de forma discreta la mecánica existente
  (reto 3→5→7 días) en la tarjeta: "Vas 3 de 5 días". Sin penalización al fallar.
- **D3. Cero lenguaje negativo.** Sustituir cualquier copy de "racha perdida".
- **Criterio de aceptación:** la tarjeta semanal sale con datos reales de la
  semana pasada; sin notificaciones push nuevas (salvo el toggle local ya
  existente de avisos).

> **Qué NO hacer:** streaks con multas, "te quedan X horas", rankings contra
> otros usuarios, notificaciones automáticas de resumen.

---

## FASE E — Toques de contexto (identidad leve)

> Objetivo: que el nivel forme parte de la identidad del usuario, sin invadirlo.

- **E1. Chip "Nv 3 · Intermedio"** en el header de Progreso y en el Perfil.
- **E2. Mini-barra de XP en Home** (10 px, bajo la racha), información pasiva.
- **E3. Widget de home 2x2:** micro-burbuja "Lv N" opcional (extiende
  `home_widget_service` con el valor ya persistido).
- **Criterio de aceptación:** los tres puntos muestran el mismo valor que
  `AppState.nivel` tras reiniciar la app.

---

## FASE F — Profundización opcional (solo si el usuario la quiere)

- **F1. Teaser "Próxima insignia"**: en la cuadrícula, la insignia bloqueada más
  cercana muestra su condición de forma pasiva ("Constancia: 3 días seguidos").
  Sin barra de progreso numérica (evita presión).
- **F2. Refactor de tokens:** auditar que el sistema de avisos (20:00, racha en
  riesgo) no duplique lógica de niveles.
- **F3. Tests de economía:** tabla de premios, persistencia, import/export,
  condiciones de insignias — sin datos inventados.

---

## Métricas de éxito (cómo saber si es *sutil*)

- Ningún flujo de entrenamiento se interrumpe con modales ni sonidos.
- Todas las insignias/niveles asignados provienen de datos locales verificados.
- La app sigue 100 % offline; XP/nivel viajan en el backup.
- Sin pantalla nueva de "logros" obligatoria: todo vive en Progreso/Home.

## Orden de implementación sugerido

Fase A → Fase B → Fase C → Fase D → Fase E → (F opcional).

La Fase A y B son las de mayor valor con menor riesgo y se apoyan en la
economía que ya existe. Cada fase es autónoma y verificable con `flutter test`
+ inspección visual por muestreo de píxeles y `uiautomator dump`.