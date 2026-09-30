# FitPulse — Guía integral de testeo manual (de la primera fase al último cambio)

Guía única PASA/FALLA para el APK **release**, desde el primer arranque hasta el último
cambio cerrado (L1 — correcciones de UI). Consolida `GUIA_TESTEO_FASE1.md` (Fases 1-9b) y
`GUIA_TESTEO_MANUAL.md` (errores de producción/UI), y añade los pasos de L1.

| Campo | Valor |
|---|---|
| Paquete | `com.fitpulse.app` |
| Build | `app-release.apk` (`build\app\outputs\flutter-apk\app-release.apk`) |
| Dispositivos | Pixel 6a (`adb-2B181JEGR15535-eA2EZ5._adb-tls-connect._tcp`) · Xiaomi Redmi 8A (`LZUSWG59AYBYW4ZD`) |
| Reglas | 100 % local/offline · datos de salud reales nunca inventados · anuncios solo de prueba · verificación sin lectura visual (píxeles + `uiautomator dump`) · al terminar: tema **oscuro** + idioma **español** + datos intactos |

---

## 0. Preparación

### 0.1 Entorno

```powershell
# Instalar el APK release preservando datos (nunca desinstalar)
adb -s 2B181JEGR15535 install -r build\app\outputs\flutter-apk\app-release.apk
adb -s LZUSWG59AYBYW4ZD install -r build\app\outputs\flutter-apk\app-release.apk

# Relanzar desde cero (prueba de arranque en frío)
adb -s <SERIAL> shell am force-stop com.fitpulse.app
adb -s <SERIAL> shell monkey -p com.fitpulse.app -c android.intent.category.LAUNCHER 1

# Evidencia sin leer la pantalla
adb -s <SERIAL> exec-out screencap -p > captura.png
adb -s <SERIAL> shell uiautomator dump /sdcard/ui.xml
adb -s <SERIAL> pull /sdcard/ui.xml ui.xml
# SI el dump falla en Xiaomi (MIUI, theme_compatibility.xml): probar --compressed,
# dump vía app_process, o solo muestreo de píxeles (§0.3).

# Logs: solo interesan FATAL/ANR/excepciones de la propia app
adb -s <SERIAL> logcat -d | findstr /I "FATAL ANR AndroidRuntime flutter"
# Ruido de sistema (SntpClient, BestClock, uiautomator) se ignora.
```

> ⚠️ Xiaomi: se desconecta si se bloquea la pantalla. Mantenerla encendida y
> reconectar con `adb connect` si cae.

### 0.2 Estado inicial recomendado

| Parámetro | Valor | Cómo |
|---|---|---|
| Tema de la app | **Oscuro** (preferencia del usuario) | Perfil → Tema de la app |
| Idioma | **Español** | Perfil → Idioma |
| Sesión | iniciada con datos reales | no borrar datos |
| Modo del teléfono | oscuro si el usuario lo pidió; no moverlo salvo prueba y restaurar | — |

> Regla de oro: al terminar, restaurar estado (tema oscuro + español + scroll/tab) y usar
> siempre `install -r`. Si se tocaron datos reales, restaurarlos del backup del usuario.

### 0.3 Muestreo por píxeles (confirmar colores sin depender de la vista)

```powershell
# muestreo.ps1 — muestra colores de puntos del PNG
param([string]$Path)
Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap($Path)
$pts = @(@(540,400), @(540,800), @(540,1500))
foreach ($pt in $pts) {
  $p = $bmp.GetPixel($pt[0], $pt[1])
  Write-Output ("({0},{1}) #{2:X2}{3:X2}{4:X2}" -f $pt[0],$pt[1],$p.R,$p.G,$p.B)
}
$bmp.Dispose()
```

### 0.4 Coordenadas de referencia Pixel 6a (nav inferior — 6 pestañas, y≈2250-2316)

| Pestaña | X | | Pestaña | X |
|---|---|---|---|---|
| Inicio (Home) | 107 | | Consejos (Tips) | 601 |
| Recetas | 207 | | Perfil | 746 |
| Progreso | 401 | | Ayuda | 923 |

> Xiaomi: releer coordenadas con dump (no asumir las del Pixel).

---

## 1. Onboarding y sesión

| # | Paso | Esperado |
|---|---|---|
| 1 | Abrir la app (cerrada de fondo). | EULA si es la primera vez. |
| 2 | Marcar casilla → **Continuar**. | Pasa al onboarding. |
| 3 | Nombre, género, objetivo → **Guardar y Entrar al Dashboard**. | Entra al Home. |
| 4 | Con sesión guardada, abrir de nuevo. | Entra directo al Home. |
| 5 | Primer arranque: pantalla de permisos de Health Connect (una vez). | Se acepta/rechaza métrica por métrica, sin crash. |

---

## 2. Fase 1 — Home: pasos reales y Health Connect

Antes: Ajustes → Privacidad → Actividad física → FitPulse → Permitir.

| # | Paso | Esperado |
|---|---|---|
| 1 | Tarjeta **Pasos de hoy**. | Número real ≥ 0 (sensor). |
| 2 | Caminar un poco y volver. | Sube (puede tardar segundos). |
| 3 | Reiniciar el teléfono y abrir. | Los pasos se rebasifican (no acumulan lo previo). |
| 4 | Permiso de actividad denegado. | "—" + "Activa el permiso…". |

### Pulso (Health Connect)

| # | Paso | Esperado |
|---|---|---|
| 5 | Permiso + lectura de hoy (reloj/app compatible). | Número real (bpm) + "Última lectura de hoy". |
| 6 | Permiso sí, sin lectura de hoy. | "—" + "Sin lectura de hoy". |
| 7 | Sin permiso de pulso. | "—" + "Conecta Health Connect". |
| 8 | Sin Health Connect instalado. | "—" + "Requiere Health Connect". |

Aviso médico visible en Home: *"Solo orientativo · consulta a un médico…"*.

---

## 3. Fase 2 — Día ideal, Progreso, reproductor, racha, retos y XP

### Día ideal (con datos reales)

| # | Paso | Esperado |
|---|---|---|
| 1 | Completar un entrenamiento (§4). | Item **Entrenamiento** 0/3 → 1/3. |
| 2 | Registrar comidas hasta la meta. | Item **Macros** marcado. |
| 3 | Con permiso y ≥ 2,5 L en Health Connect. | Item **Agua** marcado, "X.X / 2.5 L" real. |
| 4 | Sin permiso de agua. | "Objetivo: 2.5 L" (sin número inventado). |

> ⚠️ La meta de agua 2,5 L es el estado ACTUAL; será reemplazada por la meta editable de L2.

### Balance diario (reinicio por fecha)

| # | Paso | Esperado |
|---|---|---|
| 1 | Registrar varias comidas. | Resumen y barra de calorías suben. |
| 2 | Cambiar fecha del teléfono al día anterior. | Balance vuelve a 0 (reinicio diario). |
| 3 | Devolver la fecha a automático. | --- |
| 4 | Registrar comidas hoy. | Acumula desde la fecha actual. |

### Progreso — métricas reales y motivación

| # | Paso | Esperado |
|---|---|---|
| 1 | Pestaña **Progreso**. | Grasa (HC), IMC (perfil), Gasto activo, Tiempo activo. |
| 2 | Métricas HC. | Real si hay dato; si no "—" + nota. **Tiempo activo siempre "—"** en Android (tipo solo iOS): comportamiento honesto esperado. |
| 3 | Tarjetas **Reto actual** y **Nivel**. | "0/3 días" · Nivel 1, "0 pts", "+50 pts por sesión". |
| 4 | **Semana de entrenamiento** y **Consistencia**. | "0/5 días" y texto motivacional (nada inventado). |
| 5 | **Sesiones Recientes** e **Insignias** vacías. | Textos honestos ("Aún no hay sesiones…"). |

### Reproductor, sesiones, racha, retos y XP

| # | Paso | Esperado |
|---|---|---|
| 1 | Inicio → **Comenzar entrenamiento**. | Reproductor con programa recomendado. |
| 2 | Temporizador de trabajo. | Baja; al 0 pasa a **DESCANSO** y sigue. |
| 3 | **Pausar / Reanudar**. | El temporizador se detiene y continúa. |
| 4 | **Saltar**. | Avanza al siguiente descanso/ejercicio. |
| 5 | Último ejercicio → saltar/terminar. | Vuelve al Inicio, "Sesión completada (+50 pts)", sesión registrada. |
| 6 | Progreso. | Sesiones Recientes = hoy; racha = 1; insignia "Primera Sesión"; Consistencia activa. |
| 7 | Entrenar 3 días seguidos. | Reto 3 días completo (+100 pts), avanza a 5. |
| 8 | Matar la app y reabrir. | Racha, XP, reto y sesiones persisten. |

### Racha real

| # | Paso | Esperado |
|---|---|---|
| 9 | Entrenar hoy y todos los días de la semana. | 🔥 muestra días reales en Inicio, Progreso y Perfil. |
| 10 | No entrenar un día. | La racha se rompe (0 o cuenta desde ayer). |

---

## 4. Fase 3 — Anuncios (IDs de prueba), Premium y app ligera

Requisito: Play Services + red para cargar anuncios de PRUEBA. Sin red/Play: placeholder honesto (no rompe nada).

| # | Paso | Esperado |
|---|---|---|
| a1 | Inicio sobre la nav. | Banner AdMob de prueba **o** zona honesta "Zona de anuncio · sin conexión a AdMob (prueba)". |
| a2 | Cambiar de pestaña. | El banner se mantiene en todas. |
| b1 | Progreso → tarjeta "Anuncio recompensado · +25 PTs". | Abre vídeo de prueba; al cerrar +25 pts; botón "Recibido hoy". |
| b2 | Repetir el mismo día. | No suma (aviso "Recompensa de hoy ya recibida"). |
| b3 | Reiniciar la app. | Los +25 persisten. |
| c1 | Perfil → Activar Premium (modo prueba). | Banner y recompensado desaparecen. |
| c2 | Desactivar Premium. | Vuelven. |
| c3 | Toggle "Anuncios habilitados" (Perfil). | Apaga el banner sin Premium. |
| d1 | `flutter build apk --release --target-platform android-arm64`. | Anotar tamaño (~22 MB arm64; universal ~55 MB). |

> **Nota Cuba (verificado):** AdMob responde HTTP 403 desde esta red (bloqueo geográfico).
> El banner de prueba jamás cargará aquí: es esperado. La app lo muestra honestamente
> (placeholder + `[FitPulse/Ads] banner falló: …403`). Los anuncios reales no deben verse nunca.

---

## 5. Fase 4 — Comidas: plan semanal y lista de la compra

| # | Paso | Esperado |
|---|---|---|
| 1 | Recetas → tarjeta "Plan semanal de comidas". | Pantalla con 2 pestañas: Plan semanal y Lista de la compra. |
| 2 | Plan semanal. | 7 días (Lun→Dom) × 4 comidas (Desayuno, Almuerzo, Cena, Pre-entreno/Recarga), todas recetas **reales del catálogo**. |
| 3 | Resumen. | Meta del perfil + promedio real del plan (~66 %) con nota "ajustar raciones"; **ningún número inventado**. |
| 4 | Dominica. | Etiqueta "Día libre 🍕" + nota de que no penaliza la racha. |
| 5 | Totales por día. | = suma exacta de kcal de sus recetas. |
| 6 | Lista de la compra. | Ingredientes agrupados por nombre real con nº de usos (ej. "Pechuga de pollo ×7"), de más a menos usados. |
| 7 | Entrenar en domingo (día libre). | La racha suma normal (el día libre es solo informativo en comidas). |

---

## 6. Fase 5 — Entrenador con cámara (ML Kit on-device)

| # | Paso | Esperado |
|---|---|---|
| 1 | Reproductor → ejercicio corregible (sentadilla, flexión, plancha…). | Botón **"Corregir postura con cámara"** (NO en estiramientos/trote). Pausa el temporizador. |
| 2 | Primer uso. | Permiso de cámara (solo análisis local). Si se deniega: estado honesto + "Abrir ajustes". |
| 3 | Cámara abierta. | Esqueleto en vivo + contador de reps + feedback inferior. |
| 4 | Correcciones. | Ángulos reales del esqueleto: rodilla (sentadillas/zancadas/burpees), codo (flexiones/fondos), alineación (plancha), ritmo (cardio). Estiramientos: solo "Pose detectada ✓". |
| 5 | Histéresis del contador. | Una repetición = bajar del umbral y volver; sin contar temblores. Sin pose → "Coloca tu cuerpo en el encuadre". |
| 6 | Sin Play/modelo. | "Entrenador con cámara no disponible ahora": no inventa correcciones y no crashea. |

---

## 7. Fase 6 — Widget de home y avisos locales

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

## 8. Fase 7 — Modo oscuro, tamaño accesible e idioma es/en

| # | Paso | Esperado |
|---|---|---|
| 1 | Perfil → Tema de la app → Sistema/Claro/Oscuro. | Aplica al instante, sin reiniciar. |
| 2 | Tema **Sistema**. | Sigue al modo oscuro del teléfono. |
| 3 | Cerrar y reabrir. | El tema elegido persiste. |
| 4 | Contraste WCAG AA (oscuro y claro). | Textos, hints y placeholders legibles. |
| 5 | Accesibilidad → Texto máximo. | Recorrer todas las pestañas: sin desbordes ("…" en líneas largas = OK). |
| 6 | Perfil → Idioma → English. | Toda la app pasa a inglés al instante (todas las pantallas). |
| 7 | Volver a Español. | Textos originales regresan idénticos; persiste al reiniciar. |
| 8 | Micro-animaciones. | Barras/anillos crecen suave (~0,7-0,8 s) al completar objetivos. |

---

## 9. Fase 8 — Modo claro global + borde de avatar

| # | Paso | Esperado |
|---|---|---|
| 1 | Perfil → Tema → **Claro**. | App completa clara al instante (fondos `#FFFFFF`, tarjetas claras, texto negro). |
| 2 | Foto/avatar. | Borde gris neutro (`outlineVariant` ≈ `#BEC9C0`), nunca verde menta. |
| 3 | Recorrer 6 pestañas en claro. | Ninguna pantalla negra; gradientes verdes claros. |
| 4 | Volver a **Oscuro**. | Todo negro `#000000` al instante. |
| 5 | Repetir Claro. | Round-trip inmediato. |

---

## 10. Fase 9 — Avatar recortado, chip Consejos y seguimiento de peso + reps

### 10.1 Avatar: el sujeto llena el círculo

| # | Paso | Esperado |
|---|---|---|
| 1 | Perfil → subir foto real. | Recorte v2 acerca la persona (cabeza+rostro grandes). Muestreo en el círculo (centro 539,473; radio ~125): las filas y≈400/450/500 tocan piel/pelo, no pared clara. |
| 2 | Foto casi cuadrada o sin sujeto. | No se recorta (protección ratio 0,80-1,25 o sin detección). |

### 10.2 Consejos: chip seleccionado legible

| # | Paso | Esperado |
|---|---|---|
| 1 | Consejos → chip de categoría en **oscuro**. | Chip activo: fondo `primary` claro `#7DD6A6`-familia + texto/icono `onPrimary` `#00351F`. |
| 2 | Mismo chip en **claro**. | Fondo primary oscuro (`#205038`-familia) + texto blanco. |

### 10.3 Peso corporal y repeticiones

| # | Paso | Esperado |
|---|---|---|
| 1 | Progreso → "Peso Corporal" → Registrar peso. | Diálogo con pasos 0,1/1 kg y "Semana del dd/mm – dd/mm" (ancla lunes). Guardar persiste. |
| 2 | Registrar dos veces la misma semana. | Se sustituye (uno por semana); el diálogo reabre pre-cargando el registro. |
| 3 | Semanas distintas. | Historial ordenado (fecha + kg); mini-gráfico solo barras reales (1 registro → etiqueta de semana, sin barras inventadas). |
| 4 | Reproductor → botón **Registrar repeticiones**. | Diálogo 0-999 con clamp (±5/±1), etiqueta del ejercicio. Guardar → SnackBar "Registradas: N reps · <ejercicio>". |
| 5 | Progreso → "Repeticiones registradas". | "dd/mm · ejercicio | N repeticiones"; persiste tras reinicio. |
| 6 | Texto 2.0× / pantalla pequeña. | Sin desbordes (el botón de reps se alcanza scrolleando la tarjeta del reproductor). |

---

## 11. Fase 9b — Bandas invertidas en Consejos tras cambio de tema en caliente

| # | Paso | Esperado |
|---|---|---|
| 1 | Frío en oscuro → Consejos. | Limpio (fondo `#000000`, búsqueda `#171B18`). |
| 2 | Frío en claro → Consejos. | Limpio (fondo `#FFFFFF`, búsqueda `#F2F4F2`). |
| 3 | Perfil → tema **claro→oscuro** en caliente → Consejos. | Sin bandas blancas. |
| 4 | Perfil → tema **oscuro→claro** en caliente → Consejos. | Sin bandas negras. |
| 5 | Desplazar la lista tras el cambio. | Contenido correcto. |
| 6 | Frío → caliente → frío repetido. | Siempre paleta vigente. |

> Causa raíz ya corregida: capas pintadas viejas del `IndexedStack` — fix con
> `KeyedSubtree` + `RepaintBoundary` con clave del tema en `_AppShellState.build`.

---

## 12. L1 (2026-09-29, commit `fb8cdec`) — Correcciones de UI

Último lote cerrado. Aceptado por código+tests; **verificación física pendiente** en ambos
móviles (esta sección es la que falta marcar PASA/FALLA).

### 12.1 Pills de recetas abren el catálogo filtrado

| # | Paso | Esperado |
|---|---|---|
| 1 | Recetas → tocar pill **"Alta Proteína"**. | Abre el catálogo ya filtrado por Alta Proteína (solo esas recetas). |
| 2 | Tocar pill **"Low Carb"**. | Catálogo filtrado a Low Carb. |
| 3 | Volver y tocar **"Ver todas"**. | Catálogo sin filtro (todas las categorías). |
| 4 | Búsqueda dentro del catálogo. | Filtra por texto junto al filtro de categoría activo. |
| 5 | Tocar pill **"Smoothies"** y **"Pre-entreno"**. | Filtran correctamente (valores 1:1 con `Recipe.categoria`). |

### 12.2 Pestañas Semanal / Mensual / Año en Progreso funcionales

| # | Paso | Esperado |
|---|---|---|
| 1 | Progreso → pestaña **Semanal**. | Sesiones/minutos/kcal y racha máxima de los últimos **7 días**; gráfico de peso con las últimas **7 semanas**. |
| 2 | Pestaña **Mensual**. | Datos de los últimos **30 días**; peso: últimas **13 semanas (3 meses)**. |
| 3 | Pestaña **Año**. | Datos de los últimos **365 días**; peso: últimas **12 meses**. |
| 4 | Cambiar de pestaña. | Los números y la ventana del gráfico cambian (antes eran decorativas). |
| 5 | Sin datos en la ventana. | Texto honesto "Sin datos en este período", nunca cero inventado. |
| 6 | Registrar peso/sesión y cambiar de pestaña. | Los datos reales aparecen en la ventana correspondiente. |

### 12.3 "Ver todo" abre el historial de sesiones

| # | Paso | Esperado |
|---|---|---|
| 1 | Progreso → "Sesiones Recientes" → **Ver todo**. | Abre `HistorialSesionesScreen` con TODAS las sesiones (fecha desc: fecha, nombre, duración, kcal). |
| 2 | Fila de sesión. | Mismos campos que "Sesiones Recientes" (widget `SesionRow` compartido). |
| 3 | Volver atrás. | Sin pérdida de estado en Progreso. |
| 4 | Lista larga (muchas sesiones). | `ListView.builder` fluida, sin paginación rota. |

### 12.4 Cierre de L1

| # | Verificación | Resultado |
|---|---|---|
| 1 | `flutter test` (108) + `flutter analyze`. | Pasados desde `fb8cdec` (tests nuevos: `resumenPeriodo` unidad + integración). |
| 2 | Tema oscuro + español intactos tras las pruebas. | ✅ PASA (verificado 2026-09-30 en Pixel: fondo `#000000`, UI en español). |
| 3 | Datos reales intactos. | ✅ PASA (racha 1 día, sesiones, peso 70.5 y reps persistieron tras arranque en frío). |

---

## 13. Áreas transversales de producción (siempre que haya dispositivo)

### A. Arranque y coherencia de sesión
| # | Paso | Esperado |
|---|---|---|
| A1 | Force-stop → relanzar (frío). | Abre en la pestaña guardada; sin pantalla negra; < ~5-8 s en mid-device. |
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
| E3 | Exportar JSON → importar en otro estado. | Restaura sin duplicar. |
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

## 14. Checklist final

| Área | Resultado | Notas / evidencia |
|---|---|---|
| Onboarding + sesión (§1) | ☐ PASA / ☐ FALLA | |
| Fase 1 — Pasos + Health Connect (§2) | ☐ PASA / ☐ FALLA | |
| Fase 2 — Reproductor, racha, retos, XP (§3) | ☐ PASA / ☐ FALLA | |
| Fase 3 — Anuncios de prueba + Premium (§4) | ☐ PASA / ☐ FALLA | |
| Fase 4 — Plan semanal + lista de la compra (§5) | ☐ PASA / ☐ FALLA | |
| Fase 5 — Entrenador con cámara (§6) | ☐ PASA / ☐ FALLA | |
| Fase 6 — Widget + avisos (§7) | ☐ PASA / ☐ FALLA | |
| Fase 7 — Oscuro, accesibilidad, idioma (§8) | ☐ PASA / ☐ FALLA | |
| Fase 8 — Claro global + avatar (§9) | ☐ PASA / ☐ FALLA | |
| Fase 9 — Avatar, chip, peso+reps (§10) | ☐ PASA / ☐ FALLA | |
| Fase 9b — Bandas invertidas (§11) | ☐ PASA / ☐ FALLA | |
| **L1 — Pills recetas, período, "Ver todo" (§12)** | ✅ PASA (Pixel, 2026-09-30) · ☐ Xiaomi | *verificado: catálogo filtrado, tabs activas, historial* |
| Transversales A-H (§13) | ☐ PASA / ☐ FALLA | |
| Logcat final | ☐ Sin FATAL/ANR | |
| `flutter test` + `flutter analyze` | ☐ Verdes (108 tests) | |

---

## 15. Registro de la prueba

| Fecha | Dispositivo | Fases | Resultado | Observaciones |
|---|---|---|---|---|
| 2026-09-24 | Pixel 6a | F1-F3 | ☑ PASA | HC, reproductor, racha, retos ✅. AdMob 403 en Cuba (recompensado pendiente fuera de Cuba). |
| 2026-09-24 | Pixel 6a | F4-F6 | ☑ PASA | Plan semanal, cámara, widget+avisos ✅. |
| 2026-09-24 | Xiaomi Redmi 8A | F4-F6 | ☑ PASA | ADB inalámbrico; pantalla encendida. |
| 2026-09-25/28 | Pixel 6a / Xiaomi | F7-F8 | ☑ PASA | Oscuro/claro, texto máximo, idioma en vivo; Xiaomi F8 claro global + avatar ✅. |
| 2026-09-29 | Pixel 6a | F9, F9b | ☑ PASA | Verificación por píxeles + dump (avatar CROP 9/12, chip onPrimary, peso 70.5 semanal, reps 10, bandas invertidas corregidas). *F9b en Xiaomi pendiente.* |
| 2026-09-30 | Pixel 6a | **L1 (§12)** | ✅ PASA | **Verificado físicamente** (píxeles + dump, sin lectura visual): pill "Alta Proteína" abre el catálogo ya filtrado (chip activo `#92D4A9`/onPrimary; solo recetas proteicas visibles; "Todas" restaura todas las categorías incl. Pre-entreno). Pestañas Semanal/Mensual/Año: tap cambia el estado (chip activo `#92D4A9`, uno a la vez en `#171B18` los demás); resumen real 3 sesiones/8 min/540 kcal/racha 1. "Ver todo" abre "Historial de sesiones" con 3 sesiones (mismo formato `SesionRow`), scroll estable y back sin pérdida de estado. Tema oscuro (`#000000`) + español + datos intactos tras arranque en frío. WhatsApp force-stopeado durante la prueba y relanzado al final. |
|  | Xiaomi Redmi 8A | **L1 (§12)** | ☐ PASA / ☐ FALLA | Pendiente: re-verificar en el Xiaomi (workaround dump MIUI o muestreo). |
|  | Pixel 6a | A-H (§13) | ☐ PASA / ☐ FALLA | Ciclo transversal completo. |

---

## 16. Restauración del estado tras la prueba

```powershell
# 1) Tema según preferencia del usuario (este proyecto: OSCURO):
#    Perfil → Tema de la app → Oscuro
# 2) Idioma español:
#    Perfil → Idioma → Español
# 3) Cerrar y reabrir (verificar persistencia de ambos):
adb -s <SERIAL> shell am force-stop com.fitpulse.app
adb -s <SERIAL> shell monkey -p com.fitpulse.app -c android.intent.category.LAUNCHER 1
adb -s <SERIAL> shell uiautomator dump /sdcard/restaurado.xml
```

> Si durante las pruebas se tocaron datos reales (peso, reps, export/import), restaurarlos
> desde el backup del usuario antes de entregar el dispositivo. Nunca dejar datos de prueba
> como si fueran reales.

---

## 17. Pendiente del roadmap (L2-L5 — aún NO implementadas)

Estas funciones **no existen todavía** en el APK y no deben probarse como si estuvieran:

| Fase | Qué será | Estado |
|---|---|---|
| L2 — Agua | Registro manual de vasos (250 ml) + meta diaria editable (def. 3 L) reemplazando el 2,5 fijo; total = manual + Health Connect con origen etiquetado | ⏳ no implementada |
| L3 — Constructor | Rutinas propias (3-12 ejercicios, descanso default 60 s), reutiliza el reproductor | ⏳ no implementada |
| L4 — Recetas | Catálogo original ~35-40 agrupado por metas (Bajar/Mantener/Ganar músculo) + "Para tu meta" | ⏳ no implementada |
| L5 — Gamificación | `premiar(evento)` + SnackBar +50 XP + mini-tarjeta de nivel (sin modales/sonidos) | ⏳ no implementada |

Detalles operativos: `docs/PROXIMAS_FASES.md` (roadmap con tareas accionables).

---

*Documento de trabajo. Se actualiza con cada lote cerrado y cada verificación física
marcada en §15. Verificación siempre sin lectura visual (muestreo de píxeles + dump).*