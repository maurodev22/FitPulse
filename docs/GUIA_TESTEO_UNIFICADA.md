# Guía unificada de testeo manual — FitPulse

Una sola guía para probar la app completa, de principio a fin, sin tener que consultar otros documentos.

- **App:** FitPulse 1.0.0+1 (`com.fitpulse.app`)
- **Plataforma:** Android (Pixel 6a como referencia)
- **Idiomas:** español e inglés
- **Estado del código en esta revisión:** `flutter analyze` 0 issues, `flutter test` 288/288 verdes
- **Último lote:** Fase C de insignias (9, con fecha real) + Fase D "Tu semana"; el
  cierre UI/UX de los 8 puntos previos (avatar cuadrado, toast de
  registro, "Guardar" fuera del AppBar, imágenes propias de las 41 recetas,
  estadísticas al pulsar la racha, sin campanas muertas, meta de pasos y sin
  Premium de prueba)

Esta guía es el recorrido principal. `GUIA_TESTEO_COMPLETA.md` conserva el detalle técnico por fases (P1…P21, L2–L4); `GUIA_TESTEO_INTEGRAL.md`, `GUIA_TESTEO_MANUAL.md` y `GUIA_TESTEO_FASE1.md` quedan como material histórico.

**Alcance:** 14 fases (A–N), 62 pasos de verificación (A1–N9) más 7 escenarios de datos límite, y 71 líneas de checklist PASA/FALLA. Cada paso dice **qué hacer**, **qué debes ver** y **qué cuenta como FALLA**.

---

## 0. Antes de empezar

### 0.1 Qué necesitas

| Elemento | Detalle |
|---|---|
| Móvil | Android 8.0 o superior (probado en Pixel 6a) |
| ADB | Para instalar el APK |
| APK de depuración | `build/app/outputs/flutter-apk/app-debug.apk` |
| Health Connect | Opcional; en Android 13+ lo instala la propia app si falta |
| Libreta | Para anotar PASA/FALLA de cada paso |

### 0.2 Instalación: nunca desinstalar

El estado de la app (perfil, agua, peso, XP, rutinas, favoritos) vive en el propio móvil. Si desinstalas, lo pierdes todo y las pruebas de datos reales dejan de tener sentido.

```
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

`-r` significa reinstalación conservando datos. `adb install` sin `-r` solo es correcto la primera vez, en un móvil limpio.

### 0.3 Estado previo recomendado

- **Continuar** con los datos que ya tienes (recomendado: es lo que hay que validar).
- **Empezar de cero** sin perder lo actual: exportar primero (Perfil → Ajustes → Privacidad y datos → Exportar datos). Si algo sale mal, se restaura importando el `.json`.

### 0.4 Cómo se marca cada paso

- **PASA** — se ve exactamente lo esperado.
- **FALLA** — se ve otra cosa. Anota paso, qué esperabas y qué pasó.
- **N/A** — la condición previa no existe en tu caso (por ejemplo, no hay cámara). Se registra como N/A, no como fallo.

No uses "parece que funciona" como PASA. Si dudas, es FALLA: se investiga.

---

## 1. Fase A — Primer arranque

Cubre EULA, registro y configuración inicial. Si la app ya tiene perfil, ve directo a la **Fase B**.

### A1. EULA

**Qué hacer:** abre la app en una instalación limpia.

**Qué debes ver:** pantalla de términos con el texto completo y el botón de aceptación.

**FALLA si:** el texto aparece cortado, con caracteres raros o mal codificados (por ejemplo "A" con tilde arriba, o el signo de interrogacion donde deberia ir una letra acentuada), o los botones se salen de la pantalla.

### A2. Registro

**Qué hacer:** acepta el EULA y completa el alta.

**Qué debes ver, paso a paso:**
1. **Nombre completo** — campo de texto libre.
2. **Foto (opcional)** — botón "Subir imagen"; se puede saltar.
3. **Edad** — rueda de números, rango adulto.
4. **Sexo biológico** — las opciones que muestre la app.
5. **Peso** — rueda de números, en kg.
6. **Altura y complexión** — altura en cm y complexión (delgada / media / robusta).
7. **Metas** — hay que elegir **al menos 1**. La app avisa si intentas continuar sin ninguna.

**En todo momento:** el **IMC en vivo** se actualiza al cambiar peso o altura, con etiqueta clara de que es una estimación orientativa y no un diagnóstico. Con el móvil girado, el texto del IMC no debe cortarse.

**FALLA si:** se puede crear el perfil sin metas; el IMC contradice peso/altura; aparece un valor de IMC sin etiqueta de estimación; los campos aceptan valores absurdos (0 años, 0 kg, altura 0).

### A3. Guardar el perfil

**Qué debes ver:** entras en Inicio con el saludo "Hola, {tu nombre}". Al reabrir la app, el perfil persiste sin volver a pedir nada.

**FALLA si:** al reabrir te pide el registro otra vez; falta el saludo; se pierden peso o altura.

### A4. Configuración inicial ligera (P17)

**Qué debes ver:**
- Vista previa del tema **antes** de confirmar: el cambio se ve antes de aceptarlo.
- Los avisos (hidratación, racha) aparecen **apagados**; hay que activarlos uno a uno. Nada se activa solo.
- Se puede saltar todo y seguir usando la app sin avisos.

**FALLA si:** un aviso queda activo sin haberlo tocado; el tema cambia antes de confirmarlo; no se puede saltar la pantalla inicial.

---

## 2. Fase B — Inicio (Home)

### B1. Saludo y balance del día

**Qué debes ver:** "Hola, {nombre}" y la tarjeta de **Balance de hoy** con agua, pasos y calorías, cada uno con su objetivo.

**FALLA si:** hay valores sin etiqueta de estimación; los números contradicen lo que registraste; la tarjeta se sale del ancho de pantalla.

### B2. Día ideal (P18)

**Qué debes ver:** tarjeta con los tres objetivos (agua, pasos, calorías) y botón para registrar. Al completar los tres por primera vez en el día, aparece la celebración con **+25 XP**, y **solo una vez por día**.

**FALLA si:** los XP se suman más de una vez el mismo día; la celebración aparece sin cumplir los tres; los +25 XP no cuadran con la suma real.

### B3. Detalle del día (P1)

**Qué hacer:** pulsa **"Ver detalles"**.

**Qué debes ver:** el detalle real del día, con lo registrado y lo que falta.

**FALLA si:** muestra datos genéricos en lugar de los reales del día.

### B4. Agua (P14–P16, P19, P21 / L2)

**Qué debes ver:** total de hoy, **meta** (por defecto 2,5 L) y **origen** (si viene de Hydration de Health Connect o de registro manual), con botón de añadir agua por cantidades habituales.

**Qué hacer:**
1. Registra agua manual y comprueba que el total sube.
2. En **Perfil**, pulsa "Editar meta de agua" y cambia el valor (rango válido: 0,5–10 L).
3. Cierra y reabre la app: la meta nueva debe seguir ahí.

**FALLA si:** el total manual no suma; la meta no se guarda; deja marcar valores fuera de 0,5–10 L; el agua de Health Connect se cuenta dos veces; el total diario puede pasar de 5 L sin aviso.

### B5. Entrenamiento de hoy

**Qué debes ver:** la tarjeta grande con el entrenamiento recomendado y el botón **Comenzar**.

### B6. Mis rutinas (L3)

**Qué debes ver:** la entrada **"Mis rutinas"** justo debajo de la tarjeta de entrenamiento, legible en pantallas de 360 dp.

**FALLA si:** no aparece o su texto se corta.

### B7. Racha, retos y XP

**Qué debes ver:** chip de racha con los días actuales, retos disponibles y el XP total.

**FALLA si:** la racha se reinicia sola; el XP no cuadra con la suma de premios.

### B8. Tu semana (Fase D)

**Qué hacer:** con actividad la semana pasada (sesión con fecha en el lunes→domingo anterior), baja en Home hasta el final.

**Qué debes ver:** la tarjeta **"Tu semana"** con datos reales de la semana pasada ("6 días · 4 sesiones · 350 XP"); con racha viva, la línea discreta **"Vas 3 de 5 días"**. Sin actividad la semana pasada, la tarjeta **no aparece**.

**FALLA si:** la tarjeta aparece sin actividad previa, los números no coinciden con las sesiones/XP reales de esa semana, o muestra lenguaje negativo ("te quedan…", "racha perdida").

---

## 3. Fase C — Progreso

### C1. Panel visible

**Qué debes ver:** el panel de evolución ocupa un espacio razonable y los datos del período actual están a la vista, sin scroll obligatorio.

### C2. Pestañas Semanal / Mensual / Año

**Qué hacer:** cambia entre las tres pestañas.

**Qué debes ver:** los datos cambian en cada una; en "Semana de entrenamiento" un contador del tipo "3/5 días".

**FALLA si:** las pestañas no cambian nada; los datos de un período aparecen en otro; queda contenido cortado.

### C3. Historial de sesiones

**Qué debes ver:** la lista de sesiones reales completadas, con fecha y contenido. Accesible desde Progreso.

### C4. Peso corporal

**Qué debes ver:** gráfico con los registros semanales reales y su historial. Si no hay registros, un aviso claro de que registres el primero — no un gráfico vacío sin explicación.

### C5. Repeticiones por ejercicio

**Qué debes ver:** el desglose de repeticiones o series por ejercicio.

---

## 4. Fase D — Entrenamientos

### D1. Programas fijos

**Qué hacer:** en Inicio, pulsa **Comenzar** sobre el entrenamiento de hoy.

**Qué debes ver:** el reproductor con los 4 programas fijos, sus ejercicios, duraciones y descansos.

### D2. Reproductor (P11–P13)

**Qué debes ver:** arranque de sesión, ejercicio actual con su imagen, temporizador, pausa y reanudación, avance al siguiente, y cierre con resumen y XP.

**FALLA si:** el temporizador no arranca o no se pausa; al terminar no se guarda la sesión ni el XP; el resumen muestra datos inventados.

### D3. Entrenador con cámara

**Qué hacer:** abre el entrenador con cámara y concede el permiso.

**Qué debes ver:** ML Kit on-device detecta la postura y da correcciones. Sin permiso, un aviso explicando por qué se pide.

**FALLA si:** la app usa la cámara sin permiso; la pantalla queda negra con permiso concedido; las correcciones no coinciden con la postura real.

### D4. Crear una rutina propia (L3)

**Qué hacer:** Inicio → **Mis rutinas** → nueva rutina.

**Qué debes ver:**
1. Campo **nombre de rutina**: 3–40 caracteres, obligatorio.
2. Selección de ejercicios del catálogo único: 34 ejercicios en 6 grupos.
3. **Descanso** entre ejercicios: 15–120 s, 60 s por defecto, pasos de 15 s. El rango se explica en pantalla ("15-120 s"), no se impone en silencio.
4. Mínimo 3 ejercicios, máximo 12; duración total de 60 min o menos.
5. Al guardar, la rutina aparece en la lista.

**FALLA si:** permite guardar con menos de 3 o más de 12 ejercicios; acepta un nombre de 1 o de 50 caracteres; deja un descanso fuera de 15–120 s; no avisa al superar 60 min.

### D5. Usar, editar y borrar rutinas propias

**Qué debes ver:**
- Abrir una rutina propia arranca **el mismo reproductor** de los programas fijos, sin pantallas nuevas.
- Editar cambia nombre, ejercicios y descanso.
- Borrar pide confirmación y la quita de la lista.
- Renombrar funciona igual.

**FALLA si:** una rutina propia no se puede ejecutar; el editor no guarda los cambios; borrar no pide confirmación.

### D6. Honestidad de las estimaciones (L3)

**Qué debes ver:**
- **Calorías** siempre con el prefijo **"Estimación: …"**.
- **Intensidad** derivada del contenido, nunca escrita a mano.
- Ejercicio desconocido cae al valor más bajo (subestima en vez de exagerar).
- Rutina vacía da 0 en todo.
- Los estiramientos no cuentan descanso.

**FALLA si:** aparece un número de calorías sin la palabra "Estimación"; la intensidad contradice el contenido de la rutina.

---

## 5. Fase E — Recetas (L4)

### E1. Pantalla de recetas

**Qué debes ver:** recetas destacadas y una sección **"Para tu meta"** con las recetas que coinciden con las metas de tu perfil (Bajar de peso, Definir, Aumentar de peso, Mantener), con el recuento real en cada chip.

**FALLA si:** "Para tu meta" aparece vacío sin explicación; el número del chip no coincide con las recetas listadas.

### E2. Filtro por meta y categoría

**Qué hacer:** toca los chips de meta y de categoría.

**Qué debes ver:** la lista se filtra; "Ver todo" lleva al catálogo completo.

### E3. Detalle de receta

**Qué debes ver:** ingredientes con cantidad, pasos, tiempo, y el aviso de que la información es orientativa.

**FALLA si:** faltan ingredientes o pasos; el tiempo no está; desaparece el aviso de orientación.

### E4. Favoritos e historial

**Qué debes ver:** marcar una receta como favorita y encontrarla después en su sección.

---

## 6. Fase F — Comidas

### F1. Plan semanal

**Qué debes ver:** plan semanal coherente con el perfil y las metas, con las comidas organizadas por día.

### F2. Lista de la compra

**Qué debes ver:** la lista de la compra se genera a partir del plan y agrupa los ingredientes.

---

## 7. Fase G — Consejos

### G1. Búsqueda

**Qué hacer:** escribe en el buscador.

**Qué debes ver:** resultados reales; si no hay, un aviso de "sin resultados" — nunca una pantalla vacía.

### G2. Pills y "Ver todos"

**Qué debes ver:** las pills filtran por categoría; "Ver todos" abre el listado completo.

### G3. Artículos

**Qué debes ver:** el artículo se abre completo, con acceso desde la tarjeta y desde el detalle.

### G4. Recomendaciones

**Qué debes ver:** recomendaciones basadas en tu perfil, con etiqueta clara de que son sugerencias. Las de salud llevan **aviso de salud**.

---

## 8. Fase H — Perfil

### H1. Cabecera y foto

**Qué debes ver:** foto o avatar, nombre y opción de subir una imagen propia. Al guardar, la foto persiste al reabrir.

### H2. Datos corporales

**Qué debes ver:** peso, altura, porcentaje de grasa e **IMC** coherentes entre sí, con la etiqueta de estimación.

### H3. Metas de actividad

**Qué debes ver:** tarjeta de metas de actividad con botón de edición; al guardar, se reflejan en Inicio y en las recetas.

### H4. Meta de agua (P21 / L2)

**Qué hacer:** edita la meta diaria de agua.

**Qué debes ver:** diálogo con rueda de números, rango 0,5–10 L, valor por defecto 2,5 L; al guardar, Inicio muestra la meta nueva.

### H5. Nivel y preferencias

**Qué debes ver:** nivel de condición y etiquetas de preferencias (HIIT, Fuerza funcional, Running…) que se pueden añadir y quitar.

### H6. Insignias completas (Fase C)

**Qué hacer:** entra en Perfil → **Insignias & Logros** y revisa la cuadrícula con y sin sesiones.

**Qué debes ver:** **catálogo completo de 9 insignias siempre visible** con dos estados: conseguidas (icono a color y **fecha real de desbloqueo**) y bloqueadas (silueta gris con candado y la **condición escrita**, sin contadores de "te faltan…"). Contador "N / 9 insignias" en la cabecera. Sin sesiones todavía, la nota "Completa tu primer entrenamiento para desbloquear insignias" y las 9 bloqueadas.

**FALLA si:** una insignia aparece conseguida sin haber cumplido su condición real, muestra una fecha inventada, o las bloqueadas muestran progreso tipo "te faltan 2".

### H7. Guardar cambios y cerrar sesión

**Qué debes ver:** los cambios persisten al reabrir. Al cerrar sesión se vuelve a la pantalla de acceso **sin borrar los datos locales**.

---

## 9. Fase I — Ajustes

### I1. Preferencias

**Qué debes ver:**
- **Recordatorios de hidratación** — cada hora.
- **Aviso de racha** — diario a las 20:00.
- **Health Connect** — estado de la sincronización.
- **Vibración** — avisos por intervalo.
- **Compartir actividad** — visible para amigos.

### I2. Tema

**Qué debes ver:** Claro / Oscuro / Sistema. El cambio se aplica de inmediato en toda la app, sin reiniciar y sin menús que se queden pintados del color anterior.

### I3. Idioma

**Qué hacer:** cambia a inglés y recorre la app.

**Qué debes ver:** todos los textos cambian, incluido el manual de Ayuda. Vuelve a español y comprueba que no queda nada en inglés.

**FALLA si:** quedan cadenas del idioma anterior; el manual de Ayuda no se recarga.

### I4. Datos de salud

**Qué debes ver:** estado de Health Connect y los 4 chips de permiso: **pulso**, **agua**, **grasa**, **sueño**.

**FALLA si:** un permiso aparece concedido cuando no lo está; falta alguno de los cuatro.

### I5. Privacidad y datos

**Qué debes ver:** exportar datos (genera un `.json`), importar backup, política de privacidad y **borrar todos los datos** con confirmación explícita.

**FALLA si:** exportar no genera archivo; importar no pregunta antes de sobrescribir; borrar todo no pide confirmación.

---

## 10. Fase J — Ayuda

**Qué debes ver:** la pestaña Ayuda ofrece el **manual** local (funciona sin internet) y las **preguntas frecuentes** en desplegables. El manual existe en español y en inglés, y cambia con el idioma de la app.

---

## 11. Fase K — Anuncios, Premium, widget y avisos

### K1. Anuncios con IDs de prueba

**Qué debes ver:** banner de AdMob con **IDs de prueba**. Si no hay red o no hay cuenta AdMob real, la ausencia de anuncios **no es un fallo**.

### K2. Premium

**Qué debes ver:** con Premium activo desaparece el banner.

### K3. Widget de home y avisos locales

**Qué debes ver:** el widget de home se actualiza con los datos del día; los avisos locales (hidratación, racha) llegan a su hora.

---

## 12. Fase L — Casos límite de datos

Prueba estos escenarios; todos deben avisar en vez de inventar o romperse:

1. **Perfil sin peso registrado** → los paneles que dependan del peso avisan, no inventan.
2. **Sin lecturas de Health Connect** → la app lo dice explícitamente; no rellena con ceros falsos.
3. **Sin historial** → Progreso vacío con explicación, no pantalla en blanco.
4. **Repeticiones de 1 o menos** → se rechazan (P19).
5. **Agua con tope de 5 L por día** → el tope se respeta.
6. **Backup editado a mano con datos raros** (la lista de ejercicios no es una lista, campos vacíos, rutas inexistentes) → la importación no revienta la app: descarta lo ilegible y avisa.
7. **Otro dispositivo** → importar un backup de otro móvil recupera agua, XP, peso, rutinas y recetas favoritas.

---

## 13. Fase M — Robustez

### M1. Texto al 2.0×

**Qué hacer:** sube el tamaño de fuente al máximo (2.0×) y recorre **toda** la app, con atención especial a las pantallas estrechas (360 dp).

**FALLA si:** aparece la franja negra de recorte en cualquier texto; alguna fila se sale de la pantalla; algún botón queda sin etiqueta.

### M2. Tema oscuro completo

**Qué hacer:** recorre la app en oscuro.

**Qué debes ver:** todas las superficies, tarjetas, banners y diálogos con contraste suficiente.

**FALLA si:** texto blanco sobre blanco; quedan superficies del tema claro; el banner de anuncios no se adapta.

### M3. Rotación

**Qué hacer:** gira el móvil en las pantallas con datos (registro, editor de rutina, filtros, ajustes).

**FALLA si:** se pierde lo que habías escrito; el layout se rompe.

### M4. Idioma y tema combinados

**Qué hacer:** prueba inglés + oscuro, y español + claro. Debe funcionar igual.

### M5. Navegación profunda

**Qué hacer:** entra y sale varias veces seguidas de las pantallas con listas largas (catálogo de recetas, artículos, catálogo de ejercicios, historial).

**FALLA si:** se acumulan pantallas en el botón atrás; la lista se queda pegada al llegar arriba al volver.

---

## 14. Fase N — Cierre UI/UX (8 puntos)

Comprueba los ocho cambios del último lote. Si uno falla, se anota aparte: son correcciones de interfaz, no de datos.

### N1. Avatar sin marco

**Qué hacer:** Perfil → toca la foto → elige una imagen que tenga fondo blanco o un marco.

**Qué debes ver:** el avatar recortado **cuadrado**, centrado en el círculo, sin ninguna banda blanca pegada al borde del círculo.

**FALLA si:** se ve un cuadrado blanco dentro del círculo; el recorte sale descentrado; la foto elegida no se refleja.

### N2. Aviso del registro

**Qué hacer:** en una instalación limpia, llega al paso de metas y pulsa **Continuar** sin rellenar nada.

**Qué debes ver:** un aviso flotante **"Falta por llenar: …"** con el nombre del primer campo que falta.

**FALLA si:** no aparece ningún aviso, la app avanza igual, o el mensaje sale en otro idioma.

### N3. Editor de rutinas sin "Guardar" arriba

**Qué hacer:** Perfil → Mis rutinas → crea o edita una rutina.

**Qué debes ver:** en la barra superior **no** hay botón "Guardar"; la única opción de guardar es la de abajo al final de la pantalla.

**FALLA si:** quedan dos botones de guardar, o desaparece también el de abajo.

### N4. Cada receta con su dibujo

**Qué hacer:** recorre el catálogo completo de recetas y abre varios detalles.

**Qué debes ver:** cada receta con **su propia** ilustración (plato distinto según el nombre), nunca repetida en dos recetas seguidas.

**FALLA si:** hay una caja roja o un icono roto de imagen; dos recetas distintas muestran el mismo dibujo; todas usan la misma foto genérica.

### N5. Estadísticas desde la racha

**Qué hacer:** en Inicio o Progreso, pulsa el chip de la racha.

**Qué debes ver:** un diálogo con racha actual, mejor racha, días desde la instalación, sesiones y nivel, con números coherentes con tu historial.

**FALLA si:** el chip no responde; el diálogo sale vacío; algún número es imposible (por ejemplo, más días de racha que días desde la instalación).

### N6. Sin campanas que no hacen nada

**Qué hacer:** recorre Inicio, Progreso y Consejos.

**Qué debes ver:** **no** debe quedar ningún icono de campana. Tampoco en Perfil hay botón de Premium de prueba.

**FALLA si:** queda una campana que no abre nada al tocarla, o un botón que active el "Premium de prueba".

### N7. Meta de pasos legible

**Qué hacer:** Perfil → Editar metas → busca la meta de pasos.

**Qué debes ver:** la etiqueta **"1000 pasos mínimo"**.

**FALLA si:** dice "1" o cualquier otro número.

### N8. Ajustes de anuncios sin Premium de prueba

**Qué hacer:** revisa la tarjeta de avisos/configuración de la app en Perfil → Ajustes.

**Qué debes ver:** solo el interruptor real de anuncios; no hay botón de "probar Premium".

**FALLA si:** aparece un botón de activación de Premium marcado como prueba.

### N9. Los enlaces con flecha sí navegan

**Qué hacer:** en Recetas toca **"Ver plan"** de la cabecera "Recomendada para Definir"; en Inicio toca la **tarjeta de pasos** y la fila **Macros** del Día ideal.

**Qué debes ver:** "Ver plan" abre el plan semanal; las dos filas de Inicio abren el detalle del día (pasos, kcal, agua, pulso).

**FALLA si:** alguno hace el efecto de pulsación y no abre nada, o queda una flecha verde de enlace que no responde.

---

## 15. Checklist final

Marca cada línea. **Cualquier FALLA bloquea la entrega.**

```
A1  EULA legible, sin caracteres raros .................... [ ]
A2  Registro: 7 pasos, IMC en vivo con etiqueta ........... [ ]
A2  Sin al menos 1 meta no se puede continuar ............. [ ]
A3  El perfil persiste al reabrir la app .................. [ ]
A4  Vista previa de tema; avisos apagados por defecto ..... [ ]
B1  Balance del día honesto y con objetivos ................ [ ]
B2  Día ideal: +25 XP una sola vez por día ................. [ ]
B3  "Ver detalles" muestra el detalle real del día .......... [ ]
B4  Agua: suma, origen visible, meta editable y persistente [ ]
B5  Entrenamiento de hoy visible con botón Comenzar ......... [ ]
B6  Entrada "Mis rutinas" visible y sin cortes ............. [ ]
B7  Racha, retos y XP cuadran .............................. [ ]
B8  "Tu semana" con datos reales de la semana pasada ...... [ ]
C1  Panel de evolución visible sin scroll obligatorio ...... [ ]
C2  Pestañas Semanal / Mensual / Año cambian datos ......... [ ]
C3  Historial de sesiones con datos reales .................. [ ]
C4  Peso con aviso claro si no hay registros ............... [ ]
C5  Repeticiones por ejercicio desglosadas ................ [ ]
D1  Los 4 programas fijos disponibles ....................... [ ]
D2  Reproductor: temporizador, pausa, resumen y XP ......... [ ]
D3  Entrenador con cámara con permiso concedido ........... [ ]
D4  Crear rutina: 3-12 ejercicios, 15-120 s, 60 min máx .... [ ]
D5  Ejecutar, editar, renombrar y borrar rutina propia ..... [ ]
D6  "Estimación:" en kcal; intensidad coherente ........... [ ]
E1  "Para tu meta" con recuento real en los chips ........... [ ]
E2  Filtros por meta y categoría; "Ver todo" .............. [ ]
E3  Detalle con ingredientes, pasos, tiempo y aviso ........ [ ]
E4  Favoritos persisten .................................... [ ]
F1  Plan semanal coherente con el perfil ................... [ ]
F2  Lista de la compra agrupada ............................ [ ]
G1  Búsqueda con resultados o aviso de "sin resultados" .... [ ]
G2  Pills filtran; "Ver todos" abre el listado .............. [ ]
G3  Artículos se abren completos ........................... [ ]
G4  Recomendaciones con etiqueta y aviso de salud .......... [ ]
H1  Foto / avatar persiste al guardar ...................... [ ]
H2  Peso, altura, grasa e IMC coherentes ................... [ ]
H3  Metas de actividad editables y reflejadas ............. [ ]
H4  Meta de agua editable (0,5-10 L) y persistente ......... [ ]
H5  Nivel y preferencias: añadir / quitar .................. [ ]
H6  Insignias completas: contador, fecha real, siluetas ... [ ]
H7  Guardar persiste; cerrar sesión no borra datos ......... [ ]
I1  Preferencias: 5 interruptores operativos ................ [ ]
I2  Tema claro / oscuro / sistema inmediato ................. [ ]
I3  Cambio de idioma completo, incluido el manual ............ [ ]
I4  4 chips de permiso de Health Connect .................... [ ]
I5  Exportar, importar, política y borrar todo ............. [ ]
J   Manual local + FAQ en los dos idiomas .................. [ ]
K1  Banner con IDs de prueba (o ausencia sin red) .......... [ ]
K2  Premium oculta el banner ................................ [ ]
K3  Widget de home y avisos locales en su hora .............. [ ]
L1  Perfil sin peso: avisa, no inventa ..................... [ ]
L2  Sin lecturas de Health Connect: avisa ................... [ ]
L3  Sin historial: vacío explicado .......................... [ ]
L4  Repeticiones de 1 o menos: rechazadas .................. [ ]
L5  Tope de 5 L/día de agua respetado ...................... [ ]
L6  Backup editado a mano no rompe la app .................. [ ]
L7  Backup de otro móvil restaura agua, XP, peso, rutinas ... [ ]
M1  Texto 2.0x sin recortes en toda la app ................. [ ]
M2  Tema oscuro sin textos invisibles ...................... [ ]
M3  Rotación sin perder datos escritos ..................... [ ]
M4  es/en x claro/oscuro combinados ....................... [ ]
M5  Sin acumulación de pantallas en el "atrás" ............ [ ]
N1  Avatar cuadrado, sin banda blanca en el círculo ....... [ ]
N2  Registro: aviso "Falta por llenar: ..." ............... [ ]
N3  Editor de rutinas: un solo botón Guardar (el de abajo)  [ ]
N4  41 recetas con ilustración propia y sin repetir ....... [ ]
N5  Chip de racha abre estadísticas coherentes ........... [ ]
N6  Ninguna campana muerta ni botón de Premium prueba .... [ ]
N7  Meta de pasos: "1000 pasos mínimo" ................... [ ]
N8  Ajustes de anuncios sin botón de Premium ............. [ ]
N9  "Ver plan", pasos y macros abren su destino .......... [ ]
```

---

## 16. Restaurar el estado

Al terminar, deja el móvil como estaba:

- Si exportaste un backup, consérvalo.
- Si probaste "Borrar todos los datos", restaura con el backup.
- **No desinstales la app.**

---

## 17. No es un bug

No abras incidencia por estos casos:

| Situación | Motivo |
|---|---|
| No aparecen anuncios | IDs de prueba; falta red o cuenta AdMob real |
| La cámara no corrige una postura compleja | ML Kit on-device, limitado a las posturas del catálogo |
| `uiautomator dump` falla en un Xiaomi MIUI | Tema del fabricante; la app funciona |
| No hay build firmado ni `.aab` | Requiere keystore propio y cuenta de Play |
| Sin verificación del banner de consentimiento (UMP) | Requiere cuenta AdMob real |
| iOS | Fuera de alcance: no existe carpeta `ios/` |
| Imprecisiones en las estimaciones | Todo número derivado lleva su etiqueta; no son mediciones |

---

## 18. Bloqueos que dependen de cuentas o del cliente

Estos no se prueban desde el móvil:

1. **8.5 — Release firmado:** keystore propio + `app-release.aab` + Data Safety. La cuenta de Play exige entidad fuera de Cuba.
2. **8.3 — UMP:** falta verificación EEE con una cuenta AdMob real y red hacia Google.
3. **Revisión de Play:** pendiente de la publicación.

---

## 19. Plantilla de reporte

Copia y rellena solo lo que falló.

```
Reporte de testeo manual — FitPulse 1.0.0+1
Fecha:
Tester:
Movil / version de Android:
Commit: 7d73db0

Pasos con FALLA:
1. Fase / Paso — descripcion corta
   Que esperaba:
   Que paso:
   Repite siempre (si/no):
   Captura adjunta (si/no):

Pasos con N/A y motivo:

Observaciones que no son fallos:
```