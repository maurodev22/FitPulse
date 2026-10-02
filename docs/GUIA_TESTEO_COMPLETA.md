# FitPulse — Guía completa de testeo (desde 0, barriendo todo lo desarrollado)

Guía única, auto-contenida y pensada en orden de ejecución: instalar el APK **release**,
recorrer la app desde el primer arranque hasta el último cambio implementado, y dejar el
teléfono exactamente como estaba. Consolida las guías previas
(`GUIA_TESTEO_INTEGRAL.md`, `GUIA_TESTEO_MANUAL.md`, `HOTFIX_UI.md`) e incorpora el lote
Hotfix UI **P1–P10** y los ajustes de sesión P8–P10.

> **Cómo usar este documento:** es una lista PASA/FALLA. Se recorre de arriba hacia abajo.
> Cada tabla tiene un paso y lo que se debe ver. Al final, el §14 resume todo en una sola
> tabla y el §15 es el registro histórico de resultados.

---

## 0. Estado de la app y del repositorio (referencia)

| Campo | Valor |
|---|---|
| Paquete | `com.fitpulse.app` |
| Build | `app-release.apk` (`build\app\outputs\flutter-apk\app-release.apk`) |
| Último lote implementado | Hotfix UI P1–P10 (código ✅) + L1 (✅ verificado en Pixel) |
| Commits (locales, sin push) | `fb8cdec` (L1) · `0bf3f15` (P1–P7) · `b9b91d1` (P8–P10) · `268b531` + `44a1081` (docs) |
| Tests | `flutter test` **116/116** ✅ · `flutter analyze` **0 issues** ✅ |
| Dispositivos | Pixel 6a (`2B181JEGR15535`) · Xiaomi Redmi 8A (`LZUSWG59AYBYW4ZD`) |
| Resolución de referencia | 1080×2400 (Pixel). Xiaomi: releer coordenadas con dump, no asumir |
| Reglas | 100 % local/offline · datos de salud reales nunca inventados · anuncios solo de prueba · verificación sin lectura visual (píxeles + `uiautomator dump`) · al terminar: tema **oscuro** + idioma **español** + datos intactos |

### 0.1 Reglas de oro

1. **Nunca desinstalar** la app: siempre `adb install -r` (preserva datos).
2. **No inventar datos de salud**: si no hay dato, la UI muestra "—" o estado vacío honesto.
3. **Solo anuncios de prueba** (IDs de prueba); los reales nunca deben verse.
4. **Verificación sin lectura visual**: muestreo de píxeles (`work/muestreo.ps1`) +
   `uiautomator dump`. (Si el usuario hace testeo manual, puede mirar la pantalla, pero la
   evidencia registrada debe poder justificarse con píxeles/dump.)
5. **Restaurar al terminar**: tema oscuro + español + tab activo + datos intactos.
6. **No commitear PNGs** de diagnóstico.

### 0.2 Limitación de accesibilidad (dump de Flutter)

Flutter dibuja toda la app en un lienzo y **solo publica su árbol de accesibilidad cuando
hay un servicio de accesibilidad activo** (p. ej. TalkBack). Para que `uiautomator dump`
muestre los textos de la app:

```powershell
# Activar temporalmente (se restaurará a 0 al terminar)
adb -s 2B181JEGR15535 shell settings put secure enabled_accessibility_services com.google.android.marvin.talkback/com.google.android.marvin.talkback.TalkBackService
adb -s 2B181JEGR15535 shell settings put secure accessibility_enabled 1
# ← puede aparecer el wizard de bienvenida de TalkBack / diálogo de permisos;
#   navegarlo con taps hasta cerrarlo (botones "Siguiente"/"Finalizar"/"No permitir").

# Restaurar al terminar
adb -s 2B181JEGR15535 shell settings put secure accessibility_enabled 0
adb -s 2B181JEGR15535 shell settings put secure enabled_accessibility_services null
```

> Si WhatsApp roba el foco al lanzar la app: `adb shell am force-stop com.whatsapp.w4b`
> durante la prueba y relanzarlo al final (dejar el teléfono como estaba).

---

## 1. Preparación

### 1.1 Construir e instalar

```powershell
cd C:\Users\mauro\mi_pantalla
flutter build apk --release
adb -s 2B181JEGR15535 install -r build\app\outputs\flutter-apk\app-release.apk
adb -s LZUSWG59AYBYW4ZD install -r build\app\outputs\flutter-apk\app-release.apk   # opcional
```

### 1.2 Arranque en frío (prueba de inicialización)

```powershell
adb -s <SERIAL> shell am force-stop com.fitpulse.app
adb -s <SERIAL> shell monkey -p com.fitpulse.app -c android.intent.category.LAUNCHER 1
Start-Sleep -Seconds 8
adb -s <SERIAL> shell "dumpsys window | grep mCurrentFocus"   # debe ser com.fitpulse.app
```

**Esperado:** abre en la pestaña guardada, sin pantalla negra, primera pantalla útil en
< ~5-8 s (mid-device).

### 1.3 Evidencia (sin leer la pantalla)

```powershell
# Captura de pantalla (SIEMPRE con cmd /c para no corromper el binario en PowerShell)
cmd /c "adb -s <SERIAL> exec-out screencap -p > work\cap_X.png"

# Muestreo de píxeles
powershell -ExecutionPolicy Bypass -File work\muestreo.ps1 -Path work\cap_X.png

# Árbol de accesibilidad (requiere servicio de accesibilidad activo, §0.2)
adb -s <SERIAL> shell uiautomator dump /sdcard/ui.xml
adb -s <SERIAL> pull /sdcard/ui.xml work\ui_X.xml
powershell -ExecutionPolicy Bypass -File work\leer_dump.ps1 -Path work\ui_X.xml

# Xiaomi (MIUI): si el dump falla (theme_compatibility.xml), probar --compressed,
# dump vía app_process o solo muestreo de píxeles.

# Logs — solo interesan FATAL/ANR/excepciones de la propia app
adb -s <SERIAL> logcat -d | findstr /I "FATAL ANR AndroidRuntime flutter"
# Ruido de sistema (SntpClient, BestClock, uiautomator) se ignora.
```

### 1.4 Coordenadas de referencia — Pixel 6a (nav inferior, 6 pestañas, y≈2250-2316)

| Pestaña | X | | Pestaña | X |
|---|---|---|---|---|
| Inicio (Home) | 107 | | Consejos (Tips) | 601 |
| Recetas | 207 | | Perfil | 746 |
| Progreso | 401 | | Ayuda | 923 |

### 1.5 Estado inicial recomendado

| Parámetro | Valor | Cómo |
|---|---|---|
| Tema de la app | **Oscuro** (preferencia del usuario) | Perfil → Tema de la app |
| Idioma | **Español** | Perfil → Idioma |
| Sesión | con datos reales del usuario | no borrar datos |
| Modo del teléfono | oscuro si el usuario lo pidió; no moverlo salvo prueba, y restaurar | — |

---

## 2. Onboarding y sesión

| # | Paso | Esperado |
|---|---|---|
| 1 | Instalar app nueva (sin sesión). | EULA si es primera vez. |
| 2 | Marcar casilla → **Continuar**. | Pasa al onboarding. |
| 3 | Nombre, género, objetivo → **Guardar y Entrar al Dashboard**. | Entra al Home. |
| 4 | Con sesión guardada, abrir de nuevo. | Entra directo al Home (sesión persistida). |
| 5 | Primer arranque: pantalla de permisos de Health Connect (una vez). | Se acepta/rechaza métrica por métrica, sin crash. |
| 6 | Force-stop → relanzar. | La sesión sigue iniciada (A1). |

> ⚠️ En este proyecto NO se borra la sesión del usuario salvo que se pruebe expresamente la
> instalación limpia (y al final se restaura del backup).

---

## 3. Fase 1 — Home: pasos reales y Health Connect

Antes: Ajustes → Privacidad → Actividad física → FitPulse → Permitir.

| # | Paso | Esperado |
|---|---|---|
| 1 | Tarjeta **Pasos de hoy**. | Número real ≥ 0 (sensor). |
| 2 | Caminar un poco y volver. | Sube (puede tardar segundos). |
| 3 | Reiniciar el teléfono y abrir. | Los pasos se rebasifican (no acumulan lo previo). |
| 4 | Permiso de actividad denegado. | "—" + "Activa el permiso…" honesto. |
| 5 | Permiso + lectura de hoy (reloj/app compatible). | Número real (bpm) + "Última lectura de hoy". |
| 6 | Permiso sí, sin lectura de hoy. | "—" + "Sin lectura de hoy". |
| 7 | Sin permiso de pulso. | "—" + "Conecta Health Connect". |
| 8 | Sin Health Connect instalado. | "—" + "Requiere Health Connect". |

Aviso médico visible en Home: *"Solo orientativo · consulta a un médico…"*.
Muestreo de la app en oscuro: fondo `#000000`, tarjetas `#171B18`-familia.

---

## 4. P1 — Home → "Ver detalles" abre el detalle real del día

> **Hotfix P1.** Antes: el "Ver detalles" del "Resumen de hoy" no hacía nada.

| # | Paso | Esperado |
|---|---|---|
| 1 | Home → **Resumen de hoy** → **Ver detalles**. | Abre un **bottom sheet** "Detalle del día de hoy" (borde superior redondeado). |
| 2 | Filas del detalle. | **Pasos** (vs meta `Meta: N pasos`), **Calorías** (vs `Meta: N kcal`), **Pulso** (si permiso), **Agua** (si permiso). Nunca un valor inventado: "—" si no hay dato. |
| 3 | Aviso dentro del sheet. | "Solo orientativo · consulta a un médico…" visible. |
| 4 | Botón **Cerrar** (o swipe abajo/back). | El sheet se cierra; el Home sigue igual. |
| 5 | Reabrir el sheet. | Mismos datos, sin duplicados ni cierre raro. |

**Evidencia:** dump con textos `Detalle del día de hoy`, `Pasos`, `Calorías`, `Pulso`,
`Agua`, `Cerrar`; muestreo del fondo del sheet ≈ `AppColors.surface` (oscuro).

---

## 5. Fase 2 — Día ideal, Progreso, reproductor, racha, retos y XP

### 5.1 Día ideal (con datos reales)

| # | Paso | Esperado |
|---|---|---|
| 1 | Completar un entrenamiento (§8). | Item **Entrenamiento** 0/3 → 1/3. |
| 2 | Registrar comidas hasta la meta de kcal. | Item **Macros** marcado (✓ verde, `progresoCalorias >= 1.0`). |
| 3 | Con permiso HC y ≥ 2,5 L. | Item **Agua** marcado, "X.X / 2.5 L" real. |
| 4 | Sin permiso de agua. | "Objetivo: 2.5 L" (sin número inventado). |
| 5 | Chip superior. | contador "N/3 completados" avanza con cada ítem. |
| 6 | Con los 3 completados. | "3/3 completados" + los tres ✓. (Sin mensaje de celebración: estado actual.) |

> ⚠️ La meta de agua 2,5 L es el estado ACTUAL; será reemplazada por la meta editable de L2
> (`docs/PROXIMAS_FASES.md`).

### 5.2 Balance diario (reinicio por fecha)

| # | Paso | Esperado |
|---|---|---|
| 1 | Registrar varias comidas. | Resumen y barra de calorías suben. |
| 2 | Cambiar fecha del teléfono al día anterior. | Balance vuelve a 0 (reinicio diario). |
| 3 | Devolver la fecha a automático. | — |
| 4 | Registrar comidas hoy. | Acumula desde la fecha actual. |

### 5.3 Progreso — métricas reales y motivación

| # | Paso | Esperado |
|---|---|---|
| 1 | Pestaña **Progreso**. | Grasa (HC), IMC (perfil), Gasto activo, Tiempo activo. |
| 2 | Métricas HC. | Real si hay dato; si no "—" + nota. **Tiempo activo siempre "—"** en Android (tipo solo iOS): comportamiento honesto esperado. |
| 3 | Tarjetas **Reto actual** y **Nivel**. | "0/3 días" · Nivel 1, "0 pts", "+50 pts por sesión". |
| 4 | **Semana de entrenamiento** y **Consistencia**. | "0/5 días" y texto motivacional (nada inventado). |
| 5 | **Sesiones Recientes** e **Insignias** vacías. | Textos honestos ("Aún no hay sesiones…"). |

### 5.4 Reproductor, sesiones, racha, retos y XP

| # | Paso | Esperado |
|---|---|---|
| 1 | Inicio → **Comenzar entrenamiento**. | Reproductor con programa recomendado. |
| 2 | Temporizador de trabajo. | Baja; al 0 pasa a **DESCANSO** y sigue (descanso default 15 s). |
| 3 | **Pausar / Reanudar**. | El temporizador se detiene y continúa. |
| 4 | **Saltar**. | Avanza al siguiente descanso/ejercicio. |
| 5 | Último ejercicio → saltar/terminar. | Vuelve al Inicio, "Sesión completada (+50 pts)", sesión registrada. |
| 6 | Progreso. | Sesiones Recientes = hoy; racha = 1; insignia "Primera Sesión"; Consistencia activa. |
| 7 | Entrenar 3 días seguidos. | Reto 3 días completo (+100 pts), avanza a 5. |
| 8 | Matar la app y reabrir. | Racha, XP, reto y sesiones persisten. |

### 5.5 Racha real (P5)

| # | Paso | Esperado |
|---|---|---|
| 9 | Entrenar hoy y todos los días de la semana. | **RachaChip** más grande (fontSize 16), **🔥 solo si racha ≥ 7 días**; muestra días reales en Inicio, Progreso, Perfil y Consejos. |
| 10 | Con racha < 7. | Sin 🔥, solo el chip de días (legible, sin emoji). |
| 11 | No entrenar un día. | La racha se rompe (0 o cuenta desde ayer). |

---

## 6. P2 + L1.2 — Progreso: ventana visible y pestañas Semanal/Mensual/Año

> **Hotfix P2** (etiqueta de ventana) + **L1 §12.2** (pestañas funcionales).

| # | Paso | Esperado |
|---|---|---|
| 1 | Progreso → pestaña **Semanal**. | Etiqueta **"Últimos 7 días"** visible; sesiones/min/kcal y racha de los últimos 7 días; gráfico de peso con las últimas 7 semanas. |
| 2 | Pestaña **Mensual**. | Etiqueta "Últimos 30 días"; datos de 30 días; peso: últimas 13 semanas (3 meses). |
| 3 | Pestaña **Año**. | Etiqueta "Últimos 365 días"; datos de 365 días; peso: últimas 12 meses. |
| 4 | Cambiar de pestaña. | **La etiqueta y los números cambian** (antes imperceptible). Chip activo ~`#92D4A9`/primary, los demás `#171B18`. |
| 5 | Sin datos en la ventana. | Texto honesto "Sin datos en este período", nunca cero inventado. |
| 6 | Registrar peso/sesión y cambiar de pestaña. | Los datos reales aparecen en la ventana correspondiente. |

---

## 7. Fase 3 — Anuncios (IDs de prueba), Premium y app ligera

Requisito: Play Services + red para cargar anuncios de PRUEBA. Sin red/Play: placeholder honesto.

| # | Paso | Esperado |
|---|---|---|
| a1 | Inicio sobre la nav. | Banner AdMob de prueba **o** zona honesta "Zona de anuncio · sin conexión a AdMob (prueba)". |
| a2 | Cambiar de pestaña. | El banner se mantiene en todas (si está habilitado). |
| b1 | Progreso → tarjeta "Anuncio recompensado · +25 PTs". | Abre vídeo de prueba; al cerrar +25 pts; botón "Recibido hoy". |
| b2 | Repetir el mismo día. | No suma (aviso "Recompensa de hoy ya recibida"). |
| b3 | Reiniciar la app. | Los +25 persisten. |
| c1 | Perfil → Activar Premium (modo prueba). | Banner y recompensado desaparecen. |
| c2 | Desactivar Premium. | Vuelven. |
| c3 | Toggle "Anuncios habilitados" (Perfil). | Apaga el banner sin Premium. |
| d1 | `flutter build apk --release --target-platform android-arm64`. | Anotar tamaño (~22 MB arm64; universal ~55 MB). |

> **Nota Cuba (verificado):** AdMob responde HTTP 403 desde esa red (bloqueo geográfico). El
> banner de prueba jamás cargará ahí: es esperado y la app lo muestra honestamente
> (placeholder + `[FitPulse/Ads] banner falló: …403`). Los anuncios reales no deben verse nunca.

---

## 8. Fase 5 — Entrenador con cámara (ML Kit on-device)

| # | Paso | Esperado |
|---|---|---|
| 1 | Reproductor → ejercicio corregible (sentadilla, flexión, plancha…). | Botón **"Corregir postura con cámara"** (NO en estiramientos/trote). Pausa el temporizador. |
| 2 | Primer uso. | Permiso de cámara (solo análisis local). Si se deniega: estado honesto + "Abrir ajustes". |
| 3 | Cámara abierta. | Esqueleto en vivo + contador de reps + feedback inferior. |
| 4 | Correcciones. | Ángulos reales del esqueleto: rodilla (sentadillas/zancadas/burpees), codo (flexiones/fondos), alineación (plancha), ritmo (cardio). Estiramientos: solo "Pose detectada ✓". |
| 5 | Histéresis del contador. | Una repetición = bajar del umbral y volver; sin contar temblores. Sin pose → "Coloca tu cuerpo en el encuadre". |
| 6 | Sin Play/modelo. | "Entrenador con cámara no disponible ahora": no inventa correcciones y no crashea. |
| 7 | **Registrar repeticiones** (reproductor). | Diálogo 0-999 con clamp (±5/±1), etiqueta del ejercicio. Guardar → SnackBar "Registradas: N reps · <ejercicio>". |
| 8 | Progreso → "Repeticiones registradas". | "dd/mm · ejercicio \| N repeticiones"; persiste tras reinicio. |

---

## 9. Fase 4 — Comidas: plan semanal y lista de la compra

| # | Paso | Esperado |
|---|---|---|
| 1 | Recetas → tarjeta "Plan semanal de comidas". | Pantalla con 2 pestañas: Plan semanal y Lista de la compra. |
| 2 | Plan semanal. | 7 días (Lun→Dom) × 4 comidas (Desayuno, Almuerzo, Cena, Pre-entreno/Recarga), todas recetas **reales del catálogo**. |
| 3 | Resumen. | Meta del perfil + promedio real del plan (~66 %) con nota "ajustar raciones"; **ningún número inventado**. |
| 4 | Domingo. | Etiqueta "Día libre 🍕" + nota de que no penaliza la racha. |
| 5 | Totales por día. | = suma exacta de kcal de sus recetas. |
| 6 | Lista de la compra. | Ingredientes agrupados por nombre real con nº de usos (ej. "Pechuga de pollo ×7"), de más a menos usados. |
| 7 | Entrenar en domingo (día libre). | La racha suma normal (el día libre es solo informativo en comidas). |

---

## 10. L1.1 + L1.3 — Recetas: pills abren catálogo filtrado y "Ver todo" → historial

### 10.1 Pills de recetas abren el catálogo filtrado (L1 §12.1)

| # | Paso | Esperado |
|---|---|---|
| 1 | Recetas → tocar pill **"Alta Proteína"**. | Abre el catálogo ya filtrado por Alta Proteína (solo esas recetas), chip activo marcado. |
| 2 | Tocar pill **"Low Carb"**. | Catálogo filtrado a Low Carb. |
| 3 | Volver y tocar **"Ver todas"**. | Catálogo sin filtro (todas las categorías). |
| 4 | Búsqueda dentro del catálogo. | Filtra por texto junto al filtro de categoría activo. |
| 5 | Tocar pill **"Smoothies"** y **"Pre-entreno"**. | Filtran correctamente (valores 1:1 con `Recipe.categoria`). |
| 6 | Favoritas (corazón). | Toggle real, persiste. |

### 10.2 "Ver todo" abre el historial de sesiones (L1 §12.3)

| # | Paso | Esperado |
|---|---|---|
| 1 | Progreso → "Sesiones Recientes" → **Ver todo**. | Abre `HistorialSesionesScreen` con TODAS las sesiones (fecha desc: fecha, nombre, duración, kcal). |
| 2 | Fila de sesión. | Mismos campos que "Sesiones Recientes" (widget `SesionRow` compartido). |
| 3 | Volver atrás. | Sin pérdida de estado en Progreso. |
| 4 | Lista larga (muchas sesiones). | `ListView.builder` fluida, sin paginación rota. |

---

## 11. P4 — Consejos/Tips funcionales (búsqueda, pills, artículos, "Ver todos")

> **Hotfix P4.** Antes: buscador decorativo, pills sin acción, "Ver todos (18)" falso.

| # | Paso | Esperado |
|---|---|---|
| 1 | Pestaña **Consejos**. | Lista real de artículos del catálogo (4) con categorías: Nutrición, Recuperación, **Fuerza**, **Bienestar** + "Todos". |
| 2 | Buscador (TextField real). | Escribir texto filtra por título/cuerpo al instante. Botón de limpiar (X). |
| 3 | Tocar pill de categoría. | Filtra la lista; chip activo con contraste (`primary`/`onPrimary`). |
| 4 | Tocar un artículo o **"Leer artículo completo"**. | Abre `ArticuloDetalleScreen` con el contenido real del artículo. Back → vuelve a la lista con el estado (búsqueda/categoría). |
| 5 | **"Ver todos (4)"**. | El número es la cantidad REAL del catálogo (4, no 18). Abre la lista completa filtrable con búsqueda + pills. |
| 6 | Marcar favorito (bookmark). | Toggle real; persiste. |

**Evidencia (dump):** textos de los 4 títulos de artículos + "Ver todos (4)"; tras tocar una
pill, solo quedan los artículos de esa categoría.

---

## 12. P6, P3, P7, P8, P9, P10 — Perfil (y Configuración)

### 12.1 Estructura actual de Perfil (de arriba a abajo)

1. **Header** (avatar, saludo, RachaChip P5, campana).
2. **Hero** (`_ProfileHero`): nombre, peso, altura, % grasa, IMC (QuickStats) — **lee el
   estado en vivo** (P8).
3. **Metas de actividad** (con ✏️ P6).
4. **Insignias & Logros** (P3 — movidas desde Progreso).
5. **Premium** (activar/desactivar + toggle anuncios).
6. **Nivel y preferencias** (P9 — reemplaza "Datos Personales" duplicada): nivel de
   condición física + tipo de entrenamiento preferido.
7. **Acciones** (Configuración, Guardar…).

### 12.2 P6 — Editar metas de actividad

| # | Paso | Esperado |
|---|---|---|
| 1 | Perfil → **Metas de actividad** → ✏️. | Abre diálogo con **pasos diarios** y **calorías diarias** precargados. |
| 2 | Cambiar valores y **Guardar**. | Persisten; la tarjeta se refresca; Home usa la nueva meta. |
| 3 | Valores inválidos. | Validación con mensaje; no guarda. |
| 4 | Force-stop → relanzar. | Las metas editadas siguen (fix bug latente `_guardarCambios`). |

### 12.3 P3 — Insignias & Logros en Perfil

| # | Paso | Esperado |
|---|---|---|
| 1 | Perfil → **Insignias & Logros**. | Catálogo real derivado del historial: insignia de **Nivel** (`prInsigniaNivel`) y de **Reto N días** (`prInsigniaReto`). |
| 2 | Sin entrenamientos aún. | Texto honesto "Completa tu primer entrenamiento para desbloquear insignias". |
| 3 | En Progreso. | Ya NO existe la sección duplicada allí. |

### 12.4 P7 — Configuración desde el engranaje

| # | Paso | Esperado |
|---|---|---|
| 1 | Perfil → engranaje **Configuración**. | Abre `ConfiguracionScreen` (antes "próximamente"). |
| 2 | Secciones. | **Preferencias** (recordatorios, vibración, compartir actividad), **Tema** (claro/oscuro/sistema), **Idioma** (es/en), **Permisos y datos de salud** (Health Connect), **Privacidad y datos** (exportar/importar/política/borrar), **Guardar cambios**. |
| 3 | Toggles de avisos. | 💧 hidratación cada hora; 🏃 aviso de racha 20:00; comportamiento honesto con permiso denegado. |
| 4 | Back. | Perfil intacto, sin pérdida de estado. |

### 12.5 P8 — Peso sincronizado Progreso → Perfil

| # | Paso | Esperado |
|---|---|---|
| 1 | Progreso → "Peso Corporal" → **Registrar peso** (dato real distinto al del Perfil). | Diálogo con pasos 0,1/1 kg y "Semana del dd/mm – dd/mm" (ancla lunes). Guardar. |
| 2 | Ir a **Perfil**. | El hero muestra el **peso nuevo actualizado** en vivo (antes quedaba la copia obsoleta). |
| 3 | Registrar dos veces la misma semana. | Se sustituye (1 por semana); el diálogo reabre pre-cargando. |
| 4 | Semanas distintas. | Historial ordenado; mini-gráfico solo barras reales (1 registro → etiqueta de semana, sin barras inventadas). |
| 5 | Force-stop → relanzar. | Peso persistido y coherente entre Progreso y Perfil. |

### 12.6 P9 — Sin duplicados en Perfil: "Nivel y preferencias"

| # | Paso | Esperado |
|---|---|---|
| 1 | Perfil completo. | **NO** existe tarjeta "Datos Personales" duplicando el hero. |
| 2 | Sección sustituida. | "Nivel y preferencias" con **nivel de condición física** + **tipo de entrenamiento preferido** — conservados. |
| 3 | Cambiar nivel/tipo → Guardar. | Persiste y se refleja donde corresponda (recomendaciones). |

### 12.7 P10 — Mínimo 2 días de entrenamiento

| # | Paso | Esperado |
|---|---|---|
| 1 | Perfil → "Nivel y preferencias" → días de entrenamiento (toggles). | Deseleccionar un día es posible mientras queden ≥ 3. |
| 2 | Intentar deseleccionar dejando **2 días**. | **Se bloquea** con aviso (`pfMinimoDias`): no se puede quitar un día si quedan ≤ 2 seleccionados. |
| 3 | Quedar con 2 días y Guardar. | Se guarda correctamente; el toggle sigue respetando el mínimo. |
| 4 | Force-stop → relanzar. | Los días elegidos persisten. |

---

## 13. Fase 6 — Widget de home y avisos locales

| # | Paso | Esperado |
|---|---|---|
| w1 | Añadir widget FitPulse (home del teléfono). | Banda oscura con **Pasos**, **Calorías** y **Racha** reales. |
| w2 | Calorías. | Gasto activo real solo con permiso + dato; si no "—". |
| w3 | Racha. | Días reales del historial (si no hay sesiones "0 d" o "—"). |
| w4 | Tocar el widget. | Abre FitPulse; valores se refrescan al volver/cada 30 min. |
| n1 | Perfil → Preferencias → **Recordatorios de hidratación**. | Notificación 💧 programada cada hora. |
| n2 | Perfil → Preferencias → **Aviso de racha en riesgo**. | Notificación 🏃 diaria 20:00 con la racha real. |
| n3 | Primer activado. | Permiso de notificaciones una sola vez, sin doble diálogo. Denegado → toggle con aviso honesto. |
| n4 | Bandeja. | 💧 a la hora siguiente; 🏃 a las 20:00. |
| n5 | Entrenar antes de las 20:00. | Cancela el aviso de racha de ese día y reprograma mañana. |

---

## 14. Fase 7/8/9/9b — Tema, idioma, accesibilidad, avatar, chip, bandas

### 14.1 Tema y modo claro/oscuro (Fases 7 y 8)

| # | Paso | Esperado |
|---|---|---|
| 1 | Perfil → Tema → Sistema/Claro/Oscuro. | Aplica al instante, sin reiniciar. |
| 2 | Tema **Sistema**. | Sigue al modo oscuro del teléfono. |
| 3 | Cerrar y reabrir. | El tema elegido persiste. |
| 4 | Modo **claro**. | App completa clara al instante (fondos `#FFFFFF`, tarjetas claras, texto negro). Sin pantallas negras. |
| 5 | Avatar en claro. | Borde gris neutro (`outlineVariant` ≈ `#BEC9C0`), nunca verde menta. |
| 6 | Volver a **Oscuro**. | Todo negro `#000000` al instante. Round-trip inmediato. |
| 7 | Back + force-stop. | El tema del usuario persiste (C6). |

### 14.2 Idioma es/en (Fase 7)

| # | Paso | Esperado |
|---|---|---|
| 1 | Perfil → Idioma → English. | Toda la app pasa a inglés al instante (todas las pantallas). |
| 2 | Volver a Español. | Textos originales regresan idénticos; persiste al reiniciar. |

### 14.3 Accesibilidad y texto máximo (Fase 7)

| # | Paso | Esperado |
|---|---|---|
| 1 | Accesibilidad → Texto máximo (~2.0×). | Recorrer las 6 pestañas: sin `RenderFlex overflowed`; "…" en líneas largas = OK. |
| 2 | Contraste WCAG AA (oscuro y claro). | Textos, hints y placeholders legibles (≥ 4.5:1 en texto normal). |
| 3 | Área táctil. | Chips/switches/tabs ≥ 48 dp. |

### 14.4 Avatar recortado (Fase 9)

| # | Paso | Esperado |
|---|---|---|
| 1 | Perfil → subir foto real. | Recorte v2 acerca la persona (cabeza+rostro grandes). Muestreo en el círculo (centro 539,473; radio ~125): las filas y≈400/450/500 tocan piel/pelo, no pared clara. |
| 2 | Foto casi cuadrada o sin sujeto. | No se recorta (protección ratio 0,80-1,25 o sin detección). |

### 14.5 Chip de Consejos con contraste (Fase 9)

| # | Paso | Esperado |
|---|---|---|
| 1 | Consejos → chip de categoría en **oscuro**. | Chip activo: fondo `primary` claro `#7DD6A6`-familia + texto/icono `onPrimary` `#00351F`. |
| 2 | Mismo chip en **claro**. | Fondo primary oscuro (`#205038`-familia) + texto blanco. |

### 14.6 Bandas invertidas tras cambio de tema en caliente (Fase 9b)

| # | Paso | Esperado |
|---|---|---|
| 1 | Frío en oscuro → Consejos. | Limpio (fondo `#000000`, búsqueda `#171B18`). |
| 2 | Frío en claro → Consejos. | Limpio (fondo `#FFFFFF`, búsqueda `#F2F4F2`). |
| 3 | Perfil → tema **claro→oscuro** en caliente → Consejos. | Sin bandas blancas. |
| 4 | Perfil → tema **oscuro→claro** en caliente → Consejos. | Sin bandas negras. |
| 5 | Desplazar la lista tras el cambio. | Contenido correcto. |
| 6 | Frío → caliente → frío repetido. | Siempre paleta vigente. |

> Causa raíz corregida: capas pintadas viejas del `IndexedStack` — fix con `KeyedSubtree` +
> `RepaintBoundary` con clave del tema en `_AppShellState.build` (`main.dart`).

---

## 15. Sección Ayuda (pestaña 6)

| # | Paso | Esperado |
|---|---|---|
| 1 | Pestaña **Ayuda**. | "Manual de usuario" + "Preguntas frecuentes" (local, funciona sin internet). |
| 2 | Abrir manual y FAQ. | Contenido legible en el tema vigente; back limpio. |
| 3 | Configuración → Privacidad y datos → **Política de privacidad**. | Pantalla de política (es/en), scroll ok. |

---

## 16. Áreas transversales de producción

### A. Arranque y coherencia de sesión
| # | Paso | Esperado |
|---|---|---|
| A1 | Force-stop → relanzar (frío). | Abre en la pestaña guardada; sin pantalla negra; < ~5-8 s. |
| A2 | Frío → Consejos. | Render correcto del tema (sin bandas). |
| A3 | Modo avión. | Todo local sigue funcionando; sin spinners infinitos. |
| A4 | Logcat tras A1-A3. | Sin FATAL/ANR del paquete. |

### B. Recorrido visual de las 6 pestañas
| # | Paso | Esperado |
|---|---|---|
| B1 | Recorrer las 6 pestañas con 1-2 s de espera. | Sin saltos, grises ni cierres. |
| B2 | Scroll completo en cada una. | Sin cortes, espacios negros ni reflow raro. |
| B3 | Consejos → tocar cada chip. | La lista cambia; chip activo con contraste. |
| B4 | Progreso con pocos datos. | El mini-gráfico no inventa barras (solo etiqueta). |
| B5 | Zona de anuncio. | Solo prueba/placeholder; nunca anuncios reales. |

### C. Cambio de tema en caliente
| # | Paso | Esperado |
|---|---|---|
| C1 | Perfil → Tema → Oscuro⇄Claro en caliente. | Repintado global instantáneo. |
| C2 | Tras el cambio, Consejos (zonas plan y≈340-700, artículos y≈1000/1600-1780, x=540). | Claro `#FFFFFF` / oscuro `#000000`; sin bandas del color opuesto. |
| C3 | Mismo chequeo en Recetas y Progreso. | Tarjetas coherentes con el tema. |
| C4 | Cambios rápidos Oscuro→Claro→Oscuro (<1 s). | Estado final coherente. |
| C5 | Logcat tras C1-C4. | Sin FATAL ni frame timeouts. |
| C6 | Volver a Oscuro + force-stop. | El tema del usuario persiste. |

### D. Navegación y flujos
| # | Paso | Esperado |
|---|---|---|
| D1 | Cada diálogo modal: abrir → back → reabrir. | Se abre limpio; el valor anterior se pre-carga. |
| D2 | Doble-tap rápido en botones acción. | Un solo efecto (sin duplicados). |
| D3 | Reproductor: avanzar, cerrar, reabrir. | Progreso retomado o reiniciado honestamente (texto explícito). |
| D4 | Registrar reps: límites 0 y 999+. | Clamp 0-999; botones ± no salen del rango. |
| D5 | Rotar el teléfono al final de un flujo. | Sin pérdida de estado; layout se adapta. |

### E. Persistencia y honestidad de datos
| # | Paso | Esperado |
|---|---|---|
| E1 | Registrar peso/reps → force-stop → relanzar. | Los datos siguen. |
| E2 | Una misma semana: registrar peso dos veces. | Se sustituye (1 por semana, ancla lunes). |
| E3 | Exportar JSON → importar en otro estado. | Restaura sin duplicar (Perfil → Configuración → Privacidad y datos). |
| E4 | Borrar todos los datos. | Confirmación explícita → onboarding. |

### F. Estados de error de producción
| # | Paso | Esperado |
|---|---|---|
| F1 | Modelo ML Kit con red cortada al primer uso. | Mensaje honesto, sin crash ni spinner infinito. |
| F2 | Health Connect sin permisos / denegado. | Estado honesto. |
| F3 | Consentimiento de anuncios con red cortada. | Fallback explicado; sin anuncios reales. |
| F4 | `debugShowCheckedModeBanner: false` + iconos. | Sin banner DEBUG; sin iconos en blanco/cuadros. |
| F5 | Logcat del ciclo completo. | Cero FATAL/ANR del paquete. |

### G. Accesibilidad
| # | Paso | Esperado |
|---|---|---|
| G1 | Fuente 2.0× → recorrer 6 pestañas. | Sin `RenderFlex overflowed`; texto se ajusta o hay scroll. |
| G2 | Contraste WCAG AA en claro y oscuro. | ≥ 4.5:1 en texto normal. |
| G3 | TalkBack en un flujo completo. | Todos los controles con `content-desc`; foco lógico. |
| G4 | Tocar chips/switches/tabs. | Área táctil ≥ 48 dp. |

### H. Rendimiento y estabilidad
| # | Paso | Esperado |
|---|---|---|
| H1 | Arranque en frío cronometrado. | Primera pantalla útil rápida; sin bloqueo total. |
| H2 | Cambio de tema + navegación rápida. | Sin bloqueos > 1-2 s. |
| H3 | Scroll largo en Progreso. | Fluido; sin pérdida de frames sostenida ni GC excesivos. |

---

## 17. Checklist final PASA/FALLA

| Área | Resultado | Notas / evidencia |
|---|---|---|
| Onboarding + sesión (§2) | ☐ PASA / ☐ FALLA | |
| Fase 1 — Pasos + Health Connect (§3) | ☑ PASA | Testeo manual 2026-10-02 (ítem 2). |
| **P1** — Detalle del día (§4) | ☑ PASA | Testeo manual 2026-10-02 (ítem 1). |
| Fase 2 — Día ideal, reproductor, racha, retos, XP (§5) | ☑ PASA | Testeo manual 2026-10-02: Día ideal y racha OK (ítems 2 y 5). *Reproductor → P11–P13 (nuevo lote, §21).* |
| **P2 + L1.2** — Ventana y pestañas Progreso (§6) | ☑ PASA | Testeo manual 2026-10-02 (ítem 3). |
| Fase 3 — Anuncios de prueba + Premium (§7) | ☑ PASA | Testeo manual 2026-10-02 (ítem 6: Configuración). |
| Fase 4 — Plan semanal + lista de la compra (§9) | ☐ PASA / ☐ FALLA | |
| **L1.1/L1.3** — Pills recetas + "Ver todo" historial (§10) | ☑ PASA | L1 ✅ Pixel 2026-09-30 + testeo manual 2026-10-02 (ítem 8). |
| Fase 5 — Entrenador con cámara + reps (§8) | ☑ PASA / ⚠ | Cámara→ **P13** (solo Premium). Reps→ **P12** (al final). Ver §21. |
| **P4** — Consejos funcionales (§11) | ☑ PASA | Testeo manual 2026-10-02 (ítem 7). |
| **P6/P3/P7** — Metas editables, Insignias, Configuración (§12.2-12.4) | ☑ PASA | Testeo manual 2026-10-02 (ítems 5 y 6). |
| **P8** — Peso Progreso→Perfil (§12.5) | ☑ PASA | Testeo manual 2026-10-02 (ítem 4). |
| **P9** — Sin duplicados, Nivel y preferencias (§12.6) | ☑ PASA | Testeo manual 2026-10-02 (ítem 5). |
| **P10** — Mínimo 2 días de entrenamiento (§12.7) | ☑ PASA | Testeo manual 2026-10-02 (ítem 5). |
| Fase 6 — Widget + avisos (§13) | ☐ PASA / ☐ FALLA | |
| Fase 7/8/9/9b — Tema, idioma, avatar, chip, bandas (§14) | ☐ PASA / ☐ FALLA | |
| Ayuda (§15) | ☐ PASA / ☐ FALLA | ⚠ Sin veredicto en el testeo manual 2026-10-02 (ítem 9 sin respuesta). |
| **P11** — Reproductor: reloj a pantalla completa sin scroll (§21) | ☐ PASA / ☐ FALLA | Nuevo APK (build en curso 2026-10-02). |
| **P12** — Registrar reps al final del entrenamiento (§21) | ☐ PASA / ☐ FALLA | Ídem. |
| **P13** — Coach de cámara solo Premium (§21) | ☐ PASA / ☐ FALLA | Ídem. |
| **P14** — Registro manual de agua, meta 2,5 L/día (§22) | ☐ PASA / ☐ FALLA | Nuevo pedido del usuario (2026-10-02). APK (build en curso). |
| **P15** — Hidratación cada 30 min sin emojis (§22) | ☐ PASA / ☐ FALLA | Ídem. |
| **P16** — Inactividad a los 2 días (§22) | ☐ PASA / ☐ FALLA | Ídem. |
| Transversales A-H (§16) | ☐ PASA / ☐ FALLA | |
| Logcat final | ☐ Sin FATAL/ANR | *FATAL pre-existente de avisos (§20) se registra aparte.* |
| `flutter test` + `flutter analyze` | ✅ 122/122 · 0 issues (código actual) | |

---

## 18. Restauración del estado tras la prueba

```powershell
# 1) TalkBack (si se activó para el dump):
adb -s <SERIAL> shell settings put secure accessibility_enabled 0
adb -s <SERIAL> shell settings put secure enabled_accessibility_services null

# 2) Tema según preferencia del usuario (este proyecto: OSCURO):
#    Perfil → Tema de la app → Oscuro
# 3) Idioma español:
#    Perfil → Idioma → Español
# 4) Cerrar y reabrir (verificar persistencia de ambos):
adb -s <SERIAL> shell am force-stop com.fitpulse.app
adb -s <SERIAL> shell monkey -p com.fitpulse.app -c android.intent.category.LAUNCHER 1
adb -s <SERIAL> shell uiautomator dump /sdcard/restaurado.xml
```

> Si durante las pruebas se tocaron datos reales (peso, reps, export/import), restaurarlos
> desde el backup del usuario antes de entregar el dispositivo. Nunca dejar datos de prueba
> como si fueran reales.
>
> WhatsApp, si fue force-stopeado durante la prueba: relanzarlo al final.

---

## 19. Registro de la prueba (histórico)

| Fecha | Dispositivo | Fases | Resultado | Observaciones |
|---|---|---|---|---|
| 2026-09-24 | Pixel 6a | F1-F3 | ☑ PASA | HC, reproductor, racha, retos ✅. AdMob 403 en Cuba (recompensado pendiente fuera de Cuba). |
| 2026-09-24 | Pixel 6a | F4-F6 | ☑ PASA | Plan semanal, cámara, widget+avisos ✅. |
| 2026-09-24 | Xiaomi Redmi 8A | F4-F6 | ☑ PASA | ADB inalámbrico; pantalla encendida. |
| 2026-09-25/28 | Pixel 6a / Xiaomi | F7-F8 | ☑ PASA | Oscuro/claro, texto máximo, idioma en vivo; Xiaomi F8 claro global + avatar ✅. |
| 2026-09-29 | Pixel 6a | F9, F9b | ☑ PASA | Píxeles + dump (avatar CROP 9/12, chip onPrimary, peso 70.5 semanal, reps 10, bandas invertidas corregidas). *F9b en Xiaomi pendiente.* |
| 2026-09-30 | Pixel 6a | **L1 (§10)** | ✅ PASA | Verificado físicamente (píxeles + dump): pill "Alta Proteína" abre catálogo filtrado, tabs Semanal/Mensual/Año cambian estado, "Ver todo" → Historial de sesiones (3 sesiones). Tema oscuro + español + datos intactos. |
| 2026-10-02 | Pixel 6a | **Hotfix P1–P10 (testeo manual del usuario)** | ☑ PASA (1–8) | Ítems 1–8 ✅ (P1, Fase1, P2, P8, P3/P6/P9/P10, P7, P4, L1). Ítem 9 (Ayuda) sin veredicto. Reproductor (ítem 10) → rediseño pedido: reloj a pantalla completa, reps al final, coach Premium → **P11–P13**. |
| 2026-10-02 | Pixel 6a | **P11–P13 (§21)** | ☐ PASA / ☐ FALLA | Nuevo lote desde feedback del usuario (reloj fullscreen, reps al final, coach Premium). APK release reconstruido + código ✅ (116/116, 0 issues). Verificación física en curso. |
| 2026-10-02 | Pixel 6a | **P14–P16 (§22)** | ☐ PASA / ☐ FALLA | Pedido directo del usuario: registro manual de agua (meta 2,5 L/día), hidratación cada 30 min y aviso de inactividad a los 2 días. Código ✅ (122/122, 0 issues). Verificación física en curso. |
|  | Xiaomi Redmi 8A | **L1** | ☐ PASA / ☐ FALLA | Pendiente (workaround dump MIUI o muestreo). |
|  | Pixel 6a | A-H (§16) | ☐ PASA / ☐ FALLA | Ciclo transversal completo. |

---

## 20. Conocido / no aplica (no probar como bug)

- **FATAL pre-existente** (documentado, ajeno al hotfix): 
  `com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver` —
  `Invalid notification (no valid small icon)` — se repite al amanecer; se investiga aparte.
  No forma parte del lote P1–P10.
- **Roadmap L2–L5** (NO implementadas, no probar): constructor de rutinas (L3),
  catálogo de recetas por metas (L4), gamificación con feedback (L5). El registro
  **manual de agua** (antiguo L2) ya se implementó como **P14 (§22)**. Detalles:
  `docs/PROXIMAS_FASES.md`.
- **AdMob 403 en Cuba**: esperado (bloqueo geográfico), la app muestra placeholder honesto.

---

## 21. P11–P13 — Reproductor rediseñado (feedback del usuario, 2026-10-02)

Nuevo lote derivado del **ítem 10** del testeo manual del usuario:

> *"existe un scroll, como que el reloj no se pone a pantalla entera, lo de registrar
> repeticiones lo dejamos para el final del entrenamiento para no interrumpir el flujo
> de ejercicios, además el entrenador asistido por IA local con la cámara no funciona,
> lo ponemos como un feature premium solamente para fomentar"*

### Comportamiento esperado (código ✅, 116/116 tests, 0 issues)

| Ítem | Qué debe verse/hacerse |
|---|---|
| **P11** — Reloj a pantalla completa | El reloj ahora es protagonista: círculo grande (260 dp) centrado, sin scroll. En pantallas pequeñas o fuente 2.0× todo escala con `FittedBox` (sin desbordes ni scroll). Etiqueta EJERCICIO/DESCANSO arriba, nombre del ejercicio debajo, botones fijos abajo (Saltar/Pausar/Terminar). |
| **P12** — Reps al final | El botón "Registrar repeticiones" **desaparece de la tarjeta**. Al completar el último ejercicio (temporizador o Saltar), justo antes de cerrar la sesión se abre el diálogo de reps del ejercicio final (Guardar/Cancelar). Así no interrumpe el flujo de trabajo. |
| **P13** — Coach de cámara Premium | Sin Premium: el botón de cámara muestra candado + "Solo Premium"; al tocarlo abre un diálogo que explica la función y ofrece **Activar Premium (modo prueba)**. Con Premium activo: entra al entrenador con cámara como antes (si el modelo ML Kit no está disponible, estado honesto "no disponible" ya existente). |

### Pasos de verificación manual (P11–P13)

1. Inicio → **Comenzar entrenamiento** → reproductor.
   - **P11**: el reloj (min:seg) ocupa la zona central grande, no hay scroll vertical en la tarjeta, los botones Saltar/Pausar/Terminar quedan fijos abajo.
2. Con **Premium apagado** (Perfil → Desactivar Premium si está activo):
   - **P13**: en ejercicios con postura corregible debe verse el botón de cámara con **candado 🔒 + "Solo Premium"**. Tocarlo → diálogo "Entrenador con cámara · Solo Premium" con "Activar Premium (modo prueba)".
   - Pulsar "Activar Premium (modo prueba)" → el botón pasa a "Corregir postura con cámara" (desbloqueado) y abre el coach.
3. **P12**: volver al inicio y comenzar un entrenamiento corto. **No debe aparecer** "Registrar repeticiones" durante los ejercicios. Llegar al último ejercicio (o pulsar Saltar varias veces) → al completarse aparece el diálogo "¿Cuántas repeticiones completaste?" del ejercicio final → Guardar registra la sesión + reps; Cancelar cierra solo la sesión.
4. **Al terminar**: relanzar la app y confirmar que la sesión quedó en Progreso/Historial.

> Nota: tras este lote, la **Fase 5 (cámara + reps)** queda redistribuida: cámara = P13 (Premium),
> reps = P12 (al final del entrenamiento).

---

## 22. P14–P16 — Agua manual, hidratación cada 30 min e inactividad a los 2 días (feedback del usuario, 2026-10-02)

Nuevo lote derivado del pedido directo del usuario:

> *"pon en el plan la posibilidad de ingresar manualmente la cantidad de agua aproximada
> que se consumió, mínimo 2,5 L al día; cada 30 minutos envía una notificación que diga:
> 'ha pasado un tiempo desde que tomaste agua, por favor hidrátate', sin emojis, algo
> serio; al 2º día de no ingresar a la aplicación envía una notificación que diga:
> 'regresa y entrena, mantente en forma!'"*

### Comportamiento esperado (código ✅, 122/122 tests, 0 issues)

| Ítem | Qué debe verse/hacerse |
|---|---|
| **P14** — Registro manual de agua | En la tarjeta **Día ideal** del Home, la fila **Agua** ahora es pulsable y abre el diálogo **"Registra tu agua de hoy"** con: total del día, botones rápidos (+0,25 L, +0,50 L, +1 L) y campo de cantidad libre (L). Cada registro suma al total diario, persiste en el dispositivo y confirma con snackbar. La meta (2,5 L → ✔) se cumple aunque **no** haya permiso de Health Connect; y se **suma** a la lectura real de HC si la hay (nunca inventa: solo cuenta lo que el usuario declara). El panel **"Ver detalles"** (Agua de hoy) también muestra el total manual sin necesidad de permiso HC. |
| **P15** — Hidratación cada 30 min | El aviso de hidratación (toggle de Perfil/Configuración) pasa de "cada hora" a **cada 30 minutos** con `periodicallyShowWithDuration`. Texto serio, sin emojis: título **"Hidrátate"**, cuerpo **"Ha pasado un tiempo desde que tomaste agua, por favor hidrátate."** |
| **P16** — Inactividad a los 2 días | En cada arranque se (re)programa un aviso único a **+48 h**: si el usuario **no abre la app en 2 días**, llega la notificación **"FitPulse — Regresa y entrena, mantente en forma!"** (seria, sin emojis). Si vuelve antes, se reprograma desde esa apertura. |

### Pasos de verificación manual (P14–P16)

1. **P14**: Inicio → tarjeta **Día ideal** → tocar la fila **Agua**.
   - Debe abrirse "Registra tu agua de hoy" con el total actual (0,00 L) y los botones +0,25 / +0,50 / +1 L.
   - Pulsar **+0,25 L** dos veces y **+1 L** → snackbar de confirmación; el subtítulo de la fila pasa a `1,50 / 2,5 L` y **no** hace falta permiso de Health Connect.
   - Escribir una cantidad libre (p. ej. `0,5`) y pulsar **Añadir** → suma al total.
   - **Alcanzar 2,5 L** → el check del Día ideal se completa y el contador "N de 3" sube a 3.
   - "Ver detalles" → la fila **Agua** muestra el total aunque no haya permiso de HC.
2. **P15**: Perfil → Configuración → **Recordatorios de hidratación** activado. Con el teléfono en reposo, verificar que llega la notificación cada ~30 min con el texto serio sin emojis: *"Ha pasado un tiempo desde que tomaste agua, por favor hidrátate."*
3. **P16**: dejar la app **sin abrir 2 días** → debe llegar "FitPulse / Regresa y entrena, mantente en forma!". Si se abre antes, la cuenta vuelve a 48 h.

> Nota: P16 es a propósito un aviso **único reprogramable** (no se acumula); P15 sigue dependiendo
> del toggle de hidratación del perfil. Ambos textos sin emojis y en tono serio, como pidió el usuario.

---

*Documento de trabajo consolidado. Se actualiza con cada verificación física marcada en §17/§19.
Verificación automática siempre sin lectura visual (muestreo de píxeles + dump); el testeo
manual del usuario es complementario.*