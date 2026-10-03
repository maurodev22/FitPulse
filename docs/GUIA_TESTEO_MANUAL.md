# GUÍA DE TESTEO MANUAL — Errores de producción y de UI (FitPulse)

Guía pensada para detectar **errores de producción y defectos de interfaz** en el APK **release**
(no debug): coherencia visual, estados de error reales, honestidad de datos, persistencia,
accesibilidad y estabilidad. Se ejecuta en el dispositivo real, paso a paso, y deja el teléfono
**en el mismo estado en que lo encontró**.

Dispositivo de referencia: **Pixel 6a** (`2B181JEGR15535`) · Resolución 1080×2400 · Paquete
`com.fitpulse.app`. También aplicable al Xiaomi Redmi 8A (coordenadas distintas — releerlas con
dumps, no asumir las del Pixel).

---

## 0. Preparación

### 0.1 Entorno

```powershell
# Instalar el APK release preservando datos (no desinstalar)
adb -s 2B181JEGR15535 install -r build\app\outputs\flutter-apk\app-release.apk

# Relanzar la app desde cero (prueba de arranque en frío)
adb -s 2B181JEGR15535 shell am force-stop com.fitpulse.app
adb -s 2B181JEGR15535 shell monkey -p com.fitpulse.app -c android.intent.category.LAUNCHER 1

# Captura + árbol de accesibilidad (evidencia sin leer la pantalla)
adb -s 2B181JEGR15535 exec-out screencap -p > captura.png
adb -s 2B181JEGR15535 shell uiautomator dump /sdcard/ui.xml
adb -s 2B181JEGR15535 pull /sdcard/ui.xml ui.xml

# Logs: solo interesan FATAL/ANR/exception de la propia app
adb -s 2B181JEGR15535 logcat -c
adb -s 2B181JEGR15535 logcat -d | findstr /I "FATAL ANR AndroidRuntime flutter"
# NOTA: ruido de sistema (SntpClient, BestClock, uiautomator) se ignora.
```

### 0.2 Estado inicial recomendado

| Parámetro | Valor | Cómo |
|---|---|---|
| Tema de la app | **según preferencia del usuario** (este proyecto: OSCURO fijo) | Perfil → Tema de la app |
| Idioma | **Español** (app 100 % local en es) | Perfil → Idioma → Español |
| Sesión | iniciada con datos reales del usuario | no borrar datos de la prueba |
| Modo del teléfono | **oscuro** si el usuario así lo pidió; no moverlo salvo para probar tema y restaurar | — |

> **Regla de oro:** al terminar, **restaurar el estado** (tema del usuario, idioma, scroll de
> Perfil, tab activo). Usar siempre `install -r` (conserva datos) salvo que se pruebe expresamente
> la instalación limpia.

### 0.3 Evidencia sin leer la pantalla (muestreo por píxeles)

Guardar este script como `muestreo.ps1` y usarlo para confirmar colores sin depender de la vista:

```powershell
param([string]$Path)
Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap($Path)
foreach ($pt in @(@(540,400),@(540,800),@(540,1500))) {
  $p = $bmp.GetPixel($pt[0], $pt[1])
  Write-Output ("({0},{1}) #{2:X2}{3:X2}{4:X2}" -f $pt[0],$pt[1],$p.R,$p.G,$p.B)
}
$bmp.Dispose()
```

### 0.4 Coordenadas de referencia Pixel 6a (nav inferior — 6 pestañas)

| Pestaña | X (y≈2250…2316) |
|---|---|
| Inicio (Home) | 107 |
| Recetas (Recipes) | 207 |
| Progreso (Progress) | 401 |
| Consejos (Tips) | 601 |
| Perfil (Profile) | 746 |
| Ayuda (Help) | 923 |

Selector de tema en Perfil (tras 3 swipes arriba): segmentos en `[95,y][392,y+126]`,
`[392,y][689,y+126]`, `[689,y][986,y+126]` → centros x = 243 / 540 / 837. **Releer la `y` con
`uiautomator dump` en cada prueba** (el scroll resetea con cada remontaje).

---

## 1. Áreas de prueba

### A. Arranque y coherencia de la sesión

| # | Paso | Esperado | Error de producción a vigilar |
|---|------|----------|-------------------------------|
| A1 | Force-stop → relanzar (frío). | App abre en la pestaña de guardado, sin pantalla negra ni salto de tema. | Pantalla negra/blanca intermitente; arranque > ~5–8 s en mid-device; tema distinto al guardado. |
| A2 | Force-stop → relanzar → revisar **Consejos**. | Render correcto del tema activo (fondo `#000000` en oscuro / `#FFFFFF` en claro; sin bandas de color contrario). | **Bandas invertidas** (negras en claro, blancas en oscuro) en la zona del plan o artículos. |
| A3 | Abrir la app con modo de **avión** activo. | Todo local sigue funcionando (dieta, plan, progreso, consejos). | Pantallas que se quedan cargando infinito; errores *uncaught*; dependencia de red para contenido local. |
| A4 | Revisar `logcat` tras A1–A3. | Sin `FATAL EXCEPTION` ni `ANR` del paquete `com.fitpulse.app`. | Crash en cold start; ANR por trabajo en hilo principal (abrir Progress con muchos registros). |

### B. Recorrido visual de las 6 pestañas (en el tema del usuario)

| # | Paso | Esperado | Errores típicos de UI |
|---|------|----------|------------------------|
| B1 | Recorrer Inicio, Recetas, Progreso, Consejos, Perfil, Ayuda (tap a tap, con espera de 1–2 s). | Ningún salto, pantalla gris, ni cierre. Cada tab muestra su contenido. | Crashes al entrar a un tab; scroll que salta hasta el fondo; header duplicado. |
| B2 | En cada tab, **scroll completo** arriba y abajo. | Sin cortes de texto, sin espacios negros grandes, sin reflow raro. | Contenido que se pisa; texto cortado (overflow); secciones con altura fija rota. |
| B3 | En **Consejos**: tocar cada chip de categoría (consejos → cambios). | La lista de artículos cambia; el chip activo tiene contraste (fondo `primary` verde + `onPrimary` oscuro — texto legible). | Chip activo con texto blanco sobre verde claro (ilegible); chips que no cambian la lista. |
| B4 | En **Progreso** con pocos datos (o 1 registro). | El mini-gráfico **nunca inventa barras**: muestra etiqueta de semana, no barras falsas. | Barras dibujadas sin datos reales (defecto de honestidad de datos). |
| B5 | Abrir la **zona de anuncio** (banner prueba). | Texto "sin conexión a AdMob (prueba)" o anuncio de prueba; sin anuncios reales. | **Nunca** deben verse anuncios reales (IDs de prueba o nada). Si aparece anuncio real → frenar y reportar. |

### C. Cambio de tema en caliente (área de riesgo — bug ya corregido)

> Este es el punto donde históricamente apareció el defecto más grave de UI de este proyecto.

| # | Paso | Esperado | Cómo falla el defecto |
|---|------|----------|------------------------|
| C1 | Perfil → Tema de la app → **Oscuro⇄Claro** (en caliente, sin reiniciar). | Toda la app se repinta al instante (rebuild global). | Se queda a medio camino (mezcla claro/oscuro). |
| C2 | Tras el cambio, ir a **Consejos** y muestrear la zona del plan (y≈340–700) y los artículos (y≈1000, y≈1600–1780) en x=540. | En claro: `#FFFFFF`; en oscuro: `#000000` (salvo glifos de texto). | **Bandas del color opuesto** (negras en claro / blancas en oscuro) = capas pintadas viejas del IndexedStack. |
| C3 | Repetir C2 en **Recetas y Progreso** (tarjetas con ``surface*`` y gráficos). | Colores coherentes con el tema activo en todas las tarjetas. | Tarjetas con paleta mixta (una mitad del tema nuevo, otra del viejo). |
| C4 | **Cambios rápidos** Oscuro→Claro→Oscuro (taps seguidos con <1 s). | Estado final coherente (oscuro). | Estado "colgado" a medias; doble remontaje que deja una pantalla intermedia; tema que queda en System por error. |
| C5 | Tras C1–C4: `logcat` limpio de `FATAL` del paquete y **sin "skia/shader" o timeout de frame**. | Sin excepciones; sin mensajes de frame perdido durante el remontaje. | Lag/freeze > 1–2 s al cambiar de tema (remontaje pesado del árbol completo). |
| C6 | Volver al tema del usuario (**Oscuro**) y verificar que persiste tras force-stop. | Tema del usuario intacto. | El tema no persiste (vuelve a Sistema/claro). |

### D. Navegación y flujos

| # | Paso | Esperado | Errores de producción |
|---|------|----------|------------------------|
| D1 | Cada diálogo modal (peso, reps, metas, export, entrenador): abrir → **back** → reabrir. | Se abre limpio, se cierra sin pérdida de estado; el valor anterior se pre-carga. | Diálogo que pierde datos al reabrir; doble instancia (dos diálogos apilados). |
| D2 | **Doble-tap rápido** en botones acción (Guardar, Registrar). | Un solo efecto (sin duplicar registro ni navegar dos veces). | Dobles registros/snackbars (falta debounce); doble navegación (push duplicado). |
| D3 | Reproductor de entrenos: avanzar, cerrar, reabrir en medio. | El progreso se retoma o se reinicia honestamente (texto explícito). | Progreso inventado; reloj que sigue en segundo plano. |
| D4 | **Registrar repeticiones**: probar límites (0 y 999+). | Clamp 0–999; los botones ± no pasan del rango. | Valor negativo, 1000+, o entrada libre inválida sin aviso. |
| D5 | Rotar el teléfono (si permite orientación) al final de un flujo. | Sin pérdida de estado del diálogo/formulario; layout se adapta. | Overflow en landscape; estado perdido al rotar. |

### E. Persistencia y honestidad de datos

| # | Paso | Esperado | Errores de producción |
|---|------|----------|------------------------|
| E1 | Registrar peso/reps → force-stop → relanzar → ver Progreso. | Los datos siguen (SharedPreferences). | Datos perdidos tras reinicio (persistencia rota). |
| E2 | **Una sola semana**: registrar peso dos veces. | Se **sustituye** (un registro por semana, anclado a lunes), nunca se duplica. | Dos filas para la misma semana; ancla distinta al lunes. |
| E3 | Exportar datos (JSON) → importar en otro estado. | El backup restaura lo exportado; sin duplicar. | Backup vacío o corrupto; import que pisa datos sin confirmar. |
| E4 | **Derecho al olvido**: borrar todos los datos. | Confirmación explícita y volver al onboarding. | Borrado sin confirmar; onboarding que no aparece después. |

### F. Estados de error de producción (no alcanzables en debug)

| # | Paso | Esperado | Errores de producción |
|---|------|----------|------------------------|
| F1 | Modelo del entrenador (ML Kit) con red cortada al primer uso. | Estado **honesto**: mensaje claro ("modelo no disponible"), sin crash. | Crash al fallar la descarga; spinner infinito. |
| F2 | Health Connect sin permisos / denegado. | Estado honesto + pantalla de permisos reutilizable. | Crash al pedir permisos; se queda bloqueado. |
| F3 | Consentimiento de anuncios (GDPR) con red cortada. | Flujo de consentimiento fallback explicado; sin anuncios reales. | Bloqueo de arranque por dependencia de red. |
| F4 | Comprobar que **no hay banner de debug** (`debugShowCheckedModeBanner: false`) y que los **iconos no aparecen vacíos** (tree-shaking de fuentes en release). | Sin banner "DEBUG"; todos los iconos se dibujan. | Iconos en blanco/cuadros (fuente de iconos arbolada por error). |
| F5 | Revisar `logcat` del ciclo completo. | Solo ruido de sistema (SntpClient/BestClock); **cero** `FATAL`/`ANR` del paquete. | Cualquier `FATAL EXCEPTION` o `ANR` → reproducir y adjuntar stack. |

### G. Accesibilidad

| # | Paso | Esperado | Errores de UI |
|---|------|----------|---------------|
| G1 | Ajustes → Pantalla → Tamaño de fuente **2.0x** → recorrer 6 pestañas. | Sin desbordes: textos se ajustan o hay scroll; nada se corta ni se pisa. | Texto cortado horizontalmente (desbordes `RenderFlex overflowed` en logcat). |
| G2 | **Contraste WCAG AA** en claro y oscuro (en áreas de texto clave: chips, headers, tarjetas). | Al menos 4.5:1 en texto normal. | Texto claro sobre fondo claro / oscuro sobre oscuro. |
| G3 | **TalkBack** en un flujo completo (o revisar que los nodos tengan `content-desc`). | Todos los controles con descripción útil; focos lógicos. | Controles sin `content-desc` ("unnamed"); orden de foco ilógico. |
| G4 | Tocar objetivos pequeños (chips, switches, tabs). | Área táctil ≥ 48 dp equivalente. | Taps que no aterrizan por áreas táctiles pequeñas (frecuente en SegmentedButton/custom). |

### H. Rendimiento y estabilidad

| # | Paso | Esperado | Errores de producción |
|---|------|----------|------------------------|
| H1 | Arranque en frío cronometrado. | < ~5 s en mid-device; primera pantalla útil aparece rápido (sin bloqueo total). | Pantalla blanca/negra prolongada (trabajo pesado en `main`/zonas sin lazy). |
| H2 | Cambio de tema + navegación rápida (A→Consejos→Perfil). | Sin bloqueos > 1–2 s. | Freeze por remontaje completo en cada switch. |
| H3 | Scroll largo en Progreso (muchos registros de años). | Fluido; sin pérdida de frames sostenida. | Jank persistente; memoria creciendo (revisar `logcat` por `GC` excesivos). |

---

## 2. Checklist final

| Área | Resultado | Notas / evidencia |
|------|-----------|-------------------|
| A. Arranque frío + sesión + offline | ☐ PASA / ☐ FALLA | |
| B. Recorrido 6 pestañas + chips + gráfico honesto | ☐ PASA / ☐ FALLA | |
| C. Cambio de tema en caliente (Oscuro⇄Claro) sin bandas | ☐ PASA / ☐ FALLA | |
| D. Diálogos, doble-tap, reproductor, reps 0–999 | ☐ PASA / ☐ FALLA | |
| E. Persistencia, peso semanal (1/semana), backup, borrado | ☐ PASA / ☐ FALLA | |
| F. Errores de producción (ML Kit, permisos, AdMob prueba, release) | ☐ PASA / ☐ FALLA | |
| G. Accesibilidad (texto 2.0x, contraste, TalkBack) | ☐ PASA / ☐ FALLA | |
| H. Rendimiento (arranque, jank, memoria) | ☐ PASA / ☐ FALLA | |
| Logcat final | ☐ Sin FATAL/ANR | |
| `flutter test` + `flutter analyze` (si se tocó código) | ☐ Verdes | |

---

## 3. Restauración del estado tras la prueba

```powershell
# 1) Tema según preferencia del usuario (este proyecto: OSCURO):
#    Perfil → Tema de la app → Oscuro
# 2) Idioma español:
#    Perfil → Idioma → Español
# 3) Cerrar y reabrir (verificar persistencia de ambos).
adb -s 2B181JEGR15535 shell am force-stop com.fitpulse.app
adb -s 2B181JEGR15535 shell monkey -p com.fitpulse.app -c android.intent.category.LAUNCHER 1
adb -s 2B181JEGR15535 shell uiautomator dump /sdcard/restaurado.xml   # confirmar estado
```

> **Importante:** si durante las pruebas se modificaron datos reales (peso, reps, export/import),
> restaurarlos desde el backup existente del usuario antes de entregar el dispositivo; nunca dejar
> datos de prueba como si fueran reales.