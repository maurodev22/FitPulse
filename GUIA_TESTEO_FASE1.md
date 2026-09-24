# Guía de testeo manual — FASE 1 (Health Connect) + FASE 2 (Entrenamientos) + FASE 3 (Anuncios/Premium)

Dispositivo: **Pixel 6a** (`2B181JEGR15535`) y **Xiaomi** · Paquete: `com.fitpulse.app`
Build instalado: `app-debug.apk` · Fecha:

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
   `adb -s 2B181JEGR15535 install -r build\app\outputs\flutter-apk\app-debug.apk`
2. Pantalla encendida y desbloqueada antes de cada prueba.

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
- Con sesión iniciada, en **Inicio** debe verse un banner de AdMob sobre la barra de
  navegación. Cambiar de pestaña: el banner se mantiene en todas.

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
  recursos: consultar el tamaño real (objetivo ~28-40 MB instalado) y anotarlo.

---

## 12. Criterio de aprobación / fallo

**PASA si:**
- Los pasos siempre vienen del sensor real (número real, nunca ficticio).
- Cada métrica de Health Connect muestra número real solo si hay permiso + dato;
  en cualquier otro caso muestra "—" y una nota honesta.
- Al completar un entrenamiento se registra la sesión, la racha sube, se suman pts,
  el reto avanza al cumplir días seguidos y todo persiste tras cerrar la app.
- Los anuncios de PRUEBA aparecen solo sin Premium, y el recompensado suma +25 una sola
  vez por día y persiste.
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

---

## Registro de la prueba

| Fecha | Dispositivo | Resultado | Observaciones |
|-------|-------------|-----------|---------------|
|  | Pixel 6a | ☐ PASA / ☐ FALLA |  |
|  | Xiaomi | ☐ PASA / ☐ FALLA |  |