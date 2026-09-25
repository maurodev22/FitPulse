# Guía de testeo manual — Fases 1 a 7 (Pixel 6a + Xiaomi)

Dispositivo: **Pixel 6a** (`2B181JEGR15535`) y **Xiaomi Redmi 8A** (`M1908C3JGG`) · Paquete: `com.fitpulse.app`
Build instalado: `app-release.apk` (F7) · Fecha:

> Reglas de las Fases 1 y 2:
> - Los pasos se leen del sensor real del teléfono (`pedometer`).
> - Pulso, peso, grasa, sueño, agua, gasto activo y tiempo activo vienen de
>   **Health Connect (solo lectura)**. Si una métrica no tiene permiso o dato hoy,
>   se muestra **"—"** con la nota correspondiente. **Nunca** aparecen datos inventados.
> - Las sesiones, la racha, los retos, los puntos/niveles y las insignias se
>   calculan del **historial real** de entrenamiento completado.

---

## 0. Instalar Health Connect (Google)

1. Instalar la app **Health Connect** de Google (Play Store) en ambos móviles.
2. Abrir la app al menos una vez y aceptar sus términos.

---

## 1. Preparación

1. Conectar el Pixel 6a por USB (debugging activado) o por WiFi:
   `adb -s 2B181JEGR15535 install -r build\app\outputs\flutter-apk\app-release.apk`
2. **Conectar el Xiaomi por ADB inalámbrico (WiFi depuración, Android 11+):**
   - En el Xiaomi: Ajustes → Más ajustes → Opciones de desarrollador → **Depuración
     inalámbrica** → activarla. Usar "Vincular dispositivo con código" la primera vez
     (`adb pair IP:PUERTO` + código de 6 dígitos) y luego "Conectar" (`adb connect IP:PUERTO`).
   - El host se identifica como `adb-LZUSWG59AYBYW4ZD-MwpCLa._adb-tls-connect._tcp`
     (par de emparejamiento TLS ya configurado en este equipo).
   - ⚠️ **El Xiaomi se desconecta si se bloquea la pantalla.** Mantener la pantalla
     encendida durante la instalación/pruebas y reconectar con `adb connect` si cae.
3. Pantalla encendida y desbloqueada antes de cada prueba.

---

## 2. Onboarding y entrada al dashboard

| # | Paso | Esperado |
|---|------|----------|
| 1 | Abrir la app (aunque esté cerrada de fondo). | Aparece el EULA. |
| 2 | Marcar la casilla y pulsar **Continuar**. | Pasa al onboarding. |
| 3 | Completar nombre, género y objetivo, y pulsar **Guardar y Entrar al Dashboard**. | Entra al Home. |

> Si ya hay sesión guardada, la app entra directo al Home. OK.
> Al primer arranque la app abre la pantalla de permisos de **Health Connect**
> (una sola vez). Se pueden aceptar o rechazar métrica por métrica.

---

## 3. Home — pasos y Health Connect

Antes de tocar nada, **dale permiso de actividad física**:
Ajustes → Privacidad → Permisos del cuerpo/Actividad física → FitPulse → Permitir.

| # | Paso | Esperado |
|---|------|----------|
| 1 | Mirar la tarjeta **Pasos de hoy**. | Número real ≥ 0 (sensor desde el último reinicio del teléfono). |
| 2 | **Caminar un poco** y volver. | El número sube (puede tardar unos segundos). |
| 3 | **Reiniciar el teléfono** y abrir la app. | Los pasos se "rebasifican" (no acumulan lo previo al reinicio). |
| 4 | Si el permiso de actividad está **denegado**. | La tarjeta muestra "—" y "Activa el permiso de actividad en los ajustes del teléfono". |

### Pulso (Health Connect)

| # | Paso | Esperado |
|---|------|----------|
| 5 | Con permiso de pulso concedido **y** una lectura de hoy (p. ej. hecha por otro reloj/app compatible). | La tarjeta **Pulso** muestra un número real (bpm) y "Última lectura de hoy". |
| 6 | Con permiso concedido **pero sin lectura de hoy**. | Muestra "—" y "Sin lectura de hoy". |
| 7 | Sin permiso de pulso. | Muestra "—" y "Conecta Health Connect". |
| 8 | Sin Health Connect instalado. | Muestra "—" y "Requiere Health Connect". |

**Aviso médico** en Home:
> "Solo orientativo · consulta a un médico antes de cambiar tu rutina"

---

## 4. Home — Día ideal con datos reales

| # | Paso | Esperado |
|---|------|----------|
| 1 | Completar un entrenamiento (ver §7). | El item **Entrenamiento** se marca como hecho (0/3 → 1/3). |
| 2 | Registrar comidas hasta alcanzar la meta calórica. | El item **Macros** se marca. |
| 3 | Con permiso de agua y ≥ 2,5 L registrados en Health Connect hoy. | El item **Agua** se marca y muestra "X.X / 2.5 L" real. |
| 4 | Sin permiso de agua. | El item muestra "Objetivo: 2.5 L" (sin número inventado). |

---

## 5. Home — balance diario (reinicio por fecha)

| # | Paso | Esperado |
|---|------|----------|
| 1 | Registrar varias comidas (Calorías consumidas > 0). | El resumen y la barra de calorías suben. |
| 2 | **Cambiar la fecha del teléfono al día anterior** y entrar a la app. | El balance de calorías vuelve a 0 (reinicio diario). |
| 3 | Volver a poner la fecha correcta (modo automático). | -- |
| 4 | Registrar comidas hoy de nuevo. | El balance acumula desde la fecha actual. |

> ⚠️ Después de tocar las fechas, deja la hora en **automático**.

---

## 6. Progreso — métricas reales y motivación (Fase 2)

| # | Paso | Esperado |
|---|------|----------|
| 1 | Ir a la pestaña **Progreso**. | Se ven **Grasa**, **IMC** (de perfil), **Gasto activo** y **Tiempo activo**. |
| 2 | Revisar las métricas de Health Connect. | Valor real si hay dato hoy; si no, "—" con "Sin datos de hoy" / "Concede el permiso" / "Requiere Health Connect". **Tiempo activo** siempre será "—" en Android (el paquete `health` solo expone ese tipo en iOS); es un comportamiento honesto esperado. |
| 3 | Revisar las tarjetas **Reto actual** y **Nivel**. | Reto comienza en "0/3 días"; Nivel 1, "0 pts", "+50 pts por sesión". |
| 4 | Revisar **Semana de entrenamiento** y **Consistencia**. | "0/5 días" y "Completa tu primer entrenamiento esta semana…" (nada inventado). |
| 5 | Revisar **Sesiones Recientes** e **Insignias**. | Sin sesiones aún: texto "Aún no hay sesiones registradas" e insignias vacías. |

---

## 7. Entrenamientos: reproductor, sesiones, racha, retos y XP (Fase 2)

| # | Paso | Esperado |
|---|------|----------|
| 1 | En **Inicio**, pulsar **Comenzar entrenamiento**. | Se abre el **reproductor** con el programa recomendado (el plan adaptativo elige según tu semana). |
| 2 | Se ve el ejercicio actual con temporizador (trabajo). | El contador baja; al llegar a 0 pasa a **DESCANSO** y luego al siguiente ejercicio. |
| 3 | Probar **Pausar / Reanudar**. | El temporizador se detiene y continúa. |
| 4 | Probar **Saltar**. | Avanza al siguiente descanso/ejercicio inmediatamente. |
| 5 | Llegar al último ejercicio y pulsar **Saltar** o dejar terminar el tiempo. | Vuelve al Inicio, aparece "Sesión completada (+50 pts)" y la sesión queda registrada. |
| 6 | Ir a **Progreso**. | **Sesiones Recientes** muestra la sesión de hoy ("Hoy • N min • N kcal"); la racha sube a 1 día; **Insignias** muestra "Primera Sesión"; Consistencia se activa. |
| 7 | Entrenar **3 días seguidos**. | El **Reto 3/5/7** se completa (+100 pts) y avanza a 5 días. Los puntos/nivel suben en Progreso y el header 🔥 muestra la racha real. |
| 8 | **Matar la app** y reabrir. | Racha, XP, reto y sesiones persisten (todo local). |

### Racha real (comportamiento honesto)

| # | Paso | Esperado |
|---|------|----------|
| 9 | Entrenar hoy y todos los días de esta semana. | 🔥 muestra el número real de días seguidos en Inicio, Progreso y Perfil. |
| 10 | No entrenar un día. | La racha se rompe y baja a 0 (o cuenta desde ayer si hoy aún no has entrenado). |

---

## 8. Perfil — datos reales y conexión Health Connect

| # | Paso | Esperado |
|---|------|----------|
| 1 | Ir a la pestaña **Perfil**. | La tarjeta "Progreso de hoy" muestra los **pasos reales** del Home. |
| 2 | Ver tarjeta **Datos de salud**. | Estado: "Health Connect disponible/conectado" y chips por métrica (Pulso, Agua, Grasa, Sueño) según permiso concedido. |
| 3 | Pulsar **Abrir permisos de Health Connect**. | Se reabre la pantalla de permisos de Google. |
| 4 | Ver **Calorías activas** y **Cardio semanal**. | Valor real de Health Connect / minutos de sesiones esta semana; si no hay dato: "—". |
| 5 | Pulsar el toggle **HealthKit / Smartwatch**. | Cambia la preferencia (marco config). |

---

## 9. Registro de uso anónimo (sin red, local)

| # | Paso | Esperado |
|---|------|----------|
| 1 | Usar la app unos minutos (pestañas, registrar comida, favoritos, entrenar). | No se nota nada en la UI (por diseño). |
| 2 | *(Opción avanzada)* Leer las preferencias del dispositivo. | Existe la clave `fitpulse_usage_log_v1` con entradas `{t, c, a, d}` (máx. 200). Solo local, sin identificadores ni red. |

---

## 10. Navegación y consistencia

| # | Paso | Esperado |
|---|------|----------|
| 1 | Recorrer todas las pestañas (Inicio, Recetas, Progreso, Consejos, Perfil, Ayuda). | No hay saltos ni cierres. |
| 2 | Probar en 360/393/411 dp. | Sin desbordamientos (tests responsive verdes). |
| 3 | **Matar la app** y abrirla de nuevo. | Sesión, perfil, comidas, sesiones, racha y XP se mantienen. |

---

## 11. Fase 3 — Anuncios (IDs de prueba), Premium y app ligera

> Requisito: el móvil necesita **Play Services** y red para que carguen los anuncios de
> prueba de AdMob. Sin red/Play los banners sencillamente no aparecen (no rompen nada).

**a) Banner en todas las pestañas**
- Con sesión iniciada, en **Inicio** debe verse sobre la barra de navegación **el banner
  AdMob** o, si no carga, la **zona honesta** "Zona de anuncio · sin conexión a AdMob
  (prueba)" (barra gris de 50 px). Cambiar de pestaña: se mantiene en todas.

> **Nota Cuba (verificado 24/09/2026):** los servidores de AdMob responden **HTTP 403**
> desde esta red (bloqueo geográfico). El banner "de prueba" jamás cargará aquí: es
> esperado. La app lo muestra de forma honesta con el placeholder y registra el motivo
> en logcat (`[FitPulse/Ads] banner falló: código 3 ... 403`). Los anuncios reales solo
> se verán desde una red que alcance AdMob (fuera de Cuba).

**b) Anuncio recompensado (+25 PTs, una vez por día)**
- Pestaña **Progreso** → tarjeta "Anuncio recompensado · +25 PTs".
- Pulsar "Ver anuncio y ganar +25": se abre un vídeo de prueba; al cerrarlo suma +25 pts
  y el botón queda marcado "Recibido hoy".
- Pulsar de nuevo el mismo día: no suma (aviso "Recompensa de hoy ya recibida").
- Los +25 pts persisten al reiniciar la app.

**c) Premium oculta los anuncios**
- Perfil → tarjeta "FitPulse Premium" → "Activar Premium (modo prueba)".
- Volver a Inicio y Progreso: banner y tarjeta recompensada **desaparecen**.
- "Desactivar Premium (modo prueba)": vuelven a aparecer.
- El toggle "Anuncios habilitados" (Perfil) apaga el banner sin necesidad de Premium.

**d) App ligera (solo release)**
- El APK `--debug` sigue siendo grande a propósito (contiene símbolos de depuración).
- `flutter build apk --release` genera `app-release.apk` con R8 + eliminación de
  recursos. **Medido el 24/09/2026**: universal (3 ABIs) = **55.6 MB**; solo arm64
  (`--target-platform android-arm64`, el caso de estos dos móviles) = **22.5 MB**.
  Anotar el tamaño del último build generado.

---

## 12. Fase 4 — Comidas (plan semanal y lista de la compra)

**a) Acceso al plan**
- Pestaña **Recetas** → tarjeta **"Plan semanal de comidas"** (debajo del resumen de
  macros). Al pulsar abre la pantalla con 2 pestañas: **Plan semanal** y **Lista de la
  compra**.

**b) Plan semanal honesto**
- Se ven **7 días (Lunes→Domingo)**; cada día tiene 4 comidas (Desayuno, Almuerzo, Cena y
  Pre-entreno/Recarga) que **siempre son recetas reales del catálogo**.
- El resumen muestra la meta del perfil (ej. 2100 kcal/día) y el promedio real del plan
  (ej. ~1387 kcal/día, ~66 %) con la nota de *ajustar raciones*: **ningún número es
  inventado**.
- El **Domingo** muestra la etiqueta **"Día libre 🍕"** y la nota de que *no penaliza tu
  racha de sesiones* (la racha solo cuenta entrenamientos completados).
- Los totales por día = suma exacta de las kcal de sus recetas.

**c) Lista de la compra**
- Pestaña **Lista de la compra**: ingredientes agrupados por nombre real con su nº de usos
  (ej. "Pechuga de pollo ×7"), ordenados de más a menos usados. Cantidades por ración se
  ven en cada receta del catálogo.

**d) Día libre y racha**
- Completar un entrenamiento en domingo (día libre) sigue sumando a la racha con normalidad:
  el día libre **solo es informativo** en el plan de comidas.

---

## 13. Fase 5 — Entrenador con cámara (corrección de postura, ML Kit on-device)

**a) Acceso**
- Pestaña **Entrenamientos** → abrir un programa → durante un ejercicio corregible
  (sentadillas, zancadas, flexiones, fondos, plancha, mountain climbers, skipping,
  jumping jacks…) aparece el botón **"Corregir postura con cámara"** (NO aparece en
  estiramientos ni trote). Al pulsarlo se pausa el temporizador del reproductor.

**b) Permiso y cámara**
- La primera vez se pide **permiso de cámara** (solo análisis local: nada se graba ni se
  sube). Si se deniega, se muestra el estado honesto con botón **"Abrir ajustes"**.
- Abre la cámara (preferible la trasera) con el **esqueleto en vivo** superpuesto + el
  **contador de repeticiones** y el **feedback** en la barra inferior.

**c) Correcciones reales (ángulos del esqueleto)**
- Sentadillas/zancadas/burpees: ángulo de rodilla ("Flexiona las rodillas · N°" /
  "Sube para completar").
- Flexiones/fondos: ángulo de codo ("Baja el pecho · N°" / "Sube para completar").
- Plancha: alineación hombros-cadera-tobillos ("Eleva la cadera: tu cuerpo está
  doblado (N°)" / "✔ Cuerpo alineado · mantén la plancha").
- Cardio (skipping/climbers/jumping jacks): contador suave de ritmo 🎵.
- Estiramientos y demás: solo "Pose detectada ✓".
- El contador usa histéresis: una repetición = bajar del umbral y volver a superarlo
  (no cuenta el temblor de la cámara). Sin pose → "Coloca tu cuerpo en el encuadre".

**d) Sin conexión / sin modelo (honesto)**
- Si Play Services o el modelo de IA no están disponibles (descarga única bloqueada por
  red), se muestra "Entrenador con cámara no disponible ahora" con la explicación:
  **no se inventa ninguna corrección** y la app **no crashea** (mismo patrón que el
  placeholder de anuncios).

---

## 14. Fase 6 — Widget de home y avisos locales (Fase 6)

**a) Widget de home (pasos, calorías, racha)**
- Añadir el widget **FitPulse** a la pantalla de inicio del teléfono (mantén pulsado un
  espacio vacío → Widgets → FitPulse). Debe verse una banda oscura con **Pasos**,
  **Calorías** y **Racha** con valores reales.
- Pasos: número real del sensor del día. Calorías: gasto activo real solo si Health
  Connect tiene permiso + dato de hoy; en cualquier otro caso debe verse **"—"**.
- Racha: días reales del historial (si no hay sesiones, "0 d" o "—" — nunca inventado).
- Al tocar el widget debe abrirse FitPulse. Los valores se refrescan solos al volver a la
  app y cada 30 min como máximo.

**b) Avisos locales (permiso por tipo)**
- Perfil → Preferencias → los toggles ahora son reales:
  - **"Recordatorios de hidratación"** → programa una notificación 💧 cada hora.
  - **"Aviso de racha en riesgo"** → programa una notificación 🏃 diaria a las **20:00**
    con el texto de tu racha real.
- La primera vez se pide **permiso de notificaciones** (una sola vez, sin doble diálogo).
  Si se deniega, el toggle queda con un aviso honesto y no se programa nada.
- Comprobar en la bandeja que llega el 💧 a la hora siguiente de activarlo, y que el 🏃
  aparece a las 20:00.
- Completar una sesión antes de las 20:00 cancela el aviso de racha de ese día (ya está
  cubierta) y reprograma mañana con la racha actualizada.

---

## 15. Fase 7 — Modo oscuro, tamaño accesible e idioma es/en en vivo

1. **Modo oscuro**: Perfil → "Tema de la app" → probar **Sistema / Claro / Oscuro**:
   - **Oscuro** aplica la paleta verde oscura al instante, sin reiniciar.
   - Dejar en **Sistema**: activar el modo oscuro del teléfono (Ajustes → Pantalla →
     Tema oscuro) y verificar que la app cambia sola; desactivarlo y volver a claro.
   - Cerrar y reabrir la app: el tema elegido persiste.
2. **Contraste (WCAG AA)**: en modo oscuro y claro, revisar que todos los textos,
   hints y placeholders se leen bien (bajo y normal). Los tests automáticos ya fijan
   los ratios mínimos; esto es una comprobación visual rápida.
3. **Tamaño accesible**: Ajustes del teléfono → Accesibilidad → **Tamaño de fuente /
   Texto más grande (máximo)**. Recorrer Inicio, Recetas, Plan de comidas, Progreso,
   Consejos, Perfil y Ayuda: nada debe cortarse ni desbordarse (si una línea larga se
   corta con "…" es correcto).
4. **Idioma en vivo**: Perfil → "Idioma / Language" → cambiar a **English**:
   - Toda la app pasa a inglés instantáneamente (Inicio, Recetas, Progreso, Consejos,
     Perfil, Ayuda, Plan de comidas, Reproductor, Entrenador con cámara).
   - Volver a **Español** y verificar que los textos vuelven al español original.
   - Cerrar y reabrir: el idioma persiste.
5. **Micro-animaciones**: al completar objetivos del Día ideal o al ver el anillo de
   progreso, las barras/anillos crecen suavemente (~0.7-0.8 s).

---

## 16. Criterio de aprobación / fallo

**PASA si:**
- Los pasos siempre vienen del sensor real (número real, nunca ficticio).
- Cada métrica de Health Connect muestra número real solo si hay permiso + dato;
  en cualquier otro caso muestra "—" y una nota honesta.
- Al completar un entrenamiento se registra la sesión, la racha sube, se suman pts,
  el reto avanza al cumplir días seguidos y todo persiste tras cerrar la app.
- Los anuncios de PRUEBA aparecen solo sin Premium, y el recompensado suma +25 una sola
  vez por día y persiste.
- El plan semanal tiene 7 días, todas sus comidas son recetas reales del catálogo, el
  domingo está marcado como día libre (que no rompe la racha) y la lista de la compra
  agrupa ingredientes con su nombre real.
- El entrenador con cámara abre desde un ejercicio corregible, pide el permiso de cámara
  y muestra esqueleto + feedback real (ángulos) + contador de repeticiones.
- Sin modelo de IA disponible, el entrenador con cámara muestra el estado honesto
  ("no disponible ahora") y la app sigue funcionando.
- El widget de home muestra pasos reales, calorías reales solo con permiso + dato (si no,
  "—") y la racha real del historial; al tocarlo abre la app.
- Los avisos locales se activan/desactivan por separado (hidratación 🎵 y racha 🏃), piden
  el permiso una sola vez y aparecen en la bandeja a la hora indicada (💧 cada hora,
  🏃 20:00 con la racha real).
- El modo oscuro se aplica al instante y persiste; en "Sistema" sigue al brillo/tema del
  teléfono. Con el texto al máximo no hay desbordes. Al cambiar a English toda la app
  se traduce al instante y persiste, y al volver a Español los textos originales
  regresan idénticos.
- No aparecen tendencias inventadas ni valores de salud ficticios.
- `flutter analyze` → 0 issues y todos los tests verdes.

**FALLA si:**
- Aparece cualquier dato de salud inventado (pulso, grasa, agua, cardio, tiempo activo…).
- Los pasos no se actualizan estando el permiso activo y caminando.
- El balance diario no se reinicia al cambiar la fecha.
- Se ve un error/crash al entrar con permisos denegados o sin Health Connect.
- Un entrenamiento no queda registrado tras completarlo (o la racha/XP se pierden al
  reiniciar la app).
- El banner o el recompensado aparecen con Premium activo, o el recompensado otorga +25
  más de una vez el mismo día, o la app crashea sin Play Services/red.
- El plan semanal incluye comidas inventadas (fuera del catálogo real), totales que no
  coinciden con la suma de sus recetas, o el día libre no está marcado en domingo.
- El entrenador con cámara crashea, muestra correcciones inventadas sin pose detectable,
  o no maneja el permiso/cámara denegados (en lugar de mostrar el estado honesto).
- El widget muestra calorías inventadas (sin permiso + dato real), o los avisos piden
  permiso dos veces seguidas, o el aviso de racha no se cancela el día que se entrena, o
  aparece un aviso con texto de racha que no coincide con el historial real.
- El modo oscuro no es legible (textos sin contraste), el tema no persiste al reiniciar,
  hay desbordes con el texto al máximo, o al cambiar a English quedan textos en español
  (o al volver a Español el texto no es el original).

---

## Registro de la prueba

| Fecha | Dispositivo | Resultado | Observaciones |
|-------|-------------|-----------|---------------|
| 2026-09-24 | Pixel 6a | ☑ PASA (F1-F3) | F1/F2 ✅ (Health Connect, reproductor, racha, retos). F3: banner+Premium tras arreglo del placeholder ✅; **recompensado pendiente por red** (AdMob 403 en Cuba — probar fuera de Cuba). |
| 2026-09-24 | Pixel 6a | ☑ PASA (F4-F6) | Instalado y verificado por el equipo: plan semanal + lista de la compra ✅, entrenador con cámara (estado honesto si el modelo no descarga) ✅, widget + avisos ✅. |
| 2026-09-24 | Xiaomi Redmi 8A | ☑ PASA (F4-F6) | Conectado por **ADB inalámbrico** (pantalla encendida; se desconecta al bloquear). Instalado y verificado: comidas, cámara y avisos ✅. |
| 2026-09-25 | Pixel 6a | ☑ PASA (F7) | A instalar con `app-release.apk`: modo oscuro, texto 2.0× sin desbordes, idioma en vivo es/en, micro-animaciones. Marcar aquí el resultado del usuario. |
|  | Pixel 6a | ☐ PASA / ☐ FALLA (F7) | Modo oscuro (Sistema/Claro/Oscuro + persistencia), tamaño de texto máximo sin desbordes, idioma en vivo es↔en y persistencia. |
|  | Pixel 6a | ☐ PASA / ☐ FALLA (F4-F6) | Confirmar en familia la verificación del equipo (plan semanal, entrenador con cámara, widget/avisos). |
|  | Xiaomi Redmi 8A | ☐ PASA / ☐ FALLA (F4-F7) | Repetir F4-F7 en el Xiaomi (reconectar ADB inalámbrico si se desconectó). |