# Guía de testeo manual — FASE 1 (pasos del teléfono)

Dispositivo: **Pixel 6a** (`2B181JEGR15535`) · Paquete: `com.fitpulse.app`
Build instalado: `app-debug.apk` · Fecha:

> Reglas de la FASE 1: los pasos se leen del sensor real del teléfono
> (`pedometer`). Pulso, sueño, grasa, gasto activo y tiempo activo NO se
> miden todavía → deben mostrar "—" / "Requiere reloj inteligente".
> **Nunca** deben aparecer datos inventados en esas métricas.

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

---

## 3. Home — pasos reales del teléfono

Antes de tocar nada, **dale permiso de actividad física**:
Ajustes → Privacidad → Permisos del cuerpo/Actividad física → FitPulse → Permitir (o pulsar sobre la tarjeta de Pasos; en la primera apertura Android pide el permiso).

| # | Paso | Esperado |
|---|------|----------|
| 1 | Mirar la tarjeta **Pasos de hoy**. | Muestra un número real ≥ 0 (el sensor cuenta desde el último reinicio del teléfono). |
| 2 | **Caminar un poco** y volver a la tarjeta. | El número sube (puede tardar unos segundos). |
| 3 | **Reiniciar el teléfono** y abrir la app. | Los pasos NO acumulan lo de antes del reinicio: se "rebasifica" y sigue desde 0 del nuevo arranque. |
| 4 | Si el permiso está **denegado** y se vuelve a abrir la app. | La tarjeta muestra "—" y el texto "Activa el permiso de actividad en los ajustes del teléfono". |

> Nota: el contador es por día útil, no por día calendario. El balance
> diario (calorías consumidas) se reinicia cada noche según la fecha del
> teléfono, pero los pasos se conservan mientras no se reinicie el equipo
> (limitación del plugin `pedometer`).

**Aviso médico** — en la sección de resumen del día debe verse:
> "Solo orientativo · consulta a un médico antes de cambiar tu rutina"

| # | Paso | Esperado |
|---|------|----------|
| 5 | Verificar el aviso en el Home. | Aparece el texto del aviso médico. |

---

## 4. Home — pulso desactivado (sin datos inventados)

| # | Paso | Esperado |
|---|------|----------|
| 1 | Localizar la tarjeta de **Pulso** en Home. | Valor "—" y nota "Requiere reloj inteligente". |
| 2 | Registar comida (añadir una comida para ver el anillo de calorías y que las tarjetas se actualicen). | La tarjeta de pulso SIGUE mostrando "—", nunca un número. |

---

## 5. Home — balance diario (reinicio por fecha)

| # | Paso | Esperado |
|---|------|----------|
| 1 | Registrar varias comidas (Calorías consumidas > 0). | El resumen y la barra de calorías suben. |
| 2 | **Cambiar la fecha del teléfono al día anterior/no siguiente** (o esperar al día siguiente) y entrar a la app. | El balance de calorías vuelve a 0 (reinicio diario por fecha). |
| 3 | Volver a poner la fecha correcta *(en modo automático)*. | -- |
| 4 | Comprobar que las comidas registradas **hoy** suman de nuevo. | El balance acumula desde la fecha actual. |

> ⚠️ Después de tocar las fechas, deja la hora en **automático** para que el
> reinicio diario se comporte bien.

---

## 6. Progreso — sin datos inventados en salud

| # | Paso | Esperado |
|---|------|----------|
| 1 | Ir a la pestaña **Progreso** (icono "insights"). | Se ve la fila de métricas. |
| 2 | Revisar **Grasa corporal**, **Gasto activo** y **Tiempo activo**. | Muestran "—" / "Requiere reloj inteligente" y el texto explicativo del reloj. |
| 3 | Completar el **IMC** en el perfil (peso y altura). | IMC muestra el valor real calculado, con "De tu perfil". |
| 4 | Ver la tarjeta de **Peso**. | Muestra el peso del perfil; NO aparece "-1.8 kg" ni ninguna tendencia inventada. |
| 5 | *(Opcional)* Cerrar sesión y entrar de nuevo. | El perfil y el IMC se conservan. |

---

## 7. Perfil — pasos reales y sin métricas falsas

| # | Paso | Esperado |
|---|------|----------|
| 1 | Ir a la pestaña **Perfil**. | La tarjeta "Progreso de hoy" muestra los **pasos reales** de hoy (igual o cercano al valor del Home). |
| 2 | Caminar unos pasos y volver. | El valor aumenta. |
| 3 | Buscar **Cardio semanal**. | Muestra "—" (desactivado, requiere reloj). |
| 4 | Pulsar el toggle **HealthKit / Smartwatch**. | Cambia la preferencia (marco config). No conecta nada todavía; así está definido para la FASE 1. |

---

## 8. Registro de uso anónimo (sin red, local)

| # | Paso | Esperado |
|---|------|----------|
| 1 | Usar la app unos minutos (pestañas, registrar comida, favoritos). | No se nota nada en la UI (por diseño). |
| 2 | *(Opción avanzada)* Abrir "Aplicaciones / Almacenamiento de FitPulse" o buscar el archivo de preferencias. | Existe la clave `fitpulse_usage_log_v1` con entradas `{t, c, a, d}` (máx. 200). Solo local, sin identificadores ni red. |

---

## 9. Navegación y consistencia

| # | Paso | Esperado |
|---|------|----------|
| 1 | Recorrer todas las pestañas (Inicio, Recetas, Progreso, Consejos, Perfil, Ayuda). | No hay saltos ni cierres. |
| 2 | Girar/redimensionar o probar en 360/393/411 dp. | Sin desbordamientos (los tests responsive pasan). |
| 3 | **Matar la app** (deslizar desde recientes) y abrirla de nuevo. | La sesión, el perfil y las comidas de hoy se mantienen; pasos siguen contando. |

---

## 10. Criterio de aprobación / fallo

**PASA si:**
- Los pasos siempre vienen del sensor real (número real, nunca ficticio).
- Pulso, grasa, gasto activo y tiempo activo muestran "—" + "Requiere reloj inteligente".
- El aviso médico se ve en Home.
- No aparecen tendencias inventadas (p. ej. "-1.8 kg").
- `flutter analyze` → 0 issues y todos los tests verdes.

**FALLA si:**
- Aparece cualquier dato de salud inventado en pulso/sueño/grasa/cardio.
- Los pasos no se actualizan estando el permiso activo y caminando.
- El balance diario no se reinicia al cambiar la fecha.
- Se ve un error/crash al entrar con el permiso de actividad denegado.

---

## Registro de la prueba

| Fecha | Dispositivo | Resultado | Observaciones |
|-------|-------------|-----------|---------------|
|  | Pixel 6a | ☐ PASA / ☐ FALLA |  |
|  | Xiaomi | ☐ PASA / ☐ FALLA |  |