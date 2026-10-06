# Guía de revisión UI/UX — FitPulse 1.0.0+1

Guía **complementaria** a `docs/GUIA_TESTEO_UNIFICADA.md`. Úsalas en la **misma sesión**:

| Documento | Qué se responde |
|---|---|
| `GUIA_TESTEO_UNIFICADA.md` | ¿La app **funciona**? (61 pasos, 70 líneas PASA/FALLA) |
| **Esta guía** | ¿La app **se ve y se siente bien**? (12 pantallas, 7 dimensiones, scorecard) |

El build bajo prueba es **release arm64-v8a (AOT, sin banner de debug)**: las animaciones, el desplazamiento y el renderizado reflejan el comportamiento real.

> **Regla de oro de esta revisión:** si algo te parece "un poco raro" pero no sabes explicar por qué, **anótalo como defecto** con la palabra que usaste ("se ve apretado", "no sé dónde mirar primero"). El equipo decide qué hacer con ello; tu visión es el input. No descartes nada por "ser un detalle".

---

## 1. Referencia de diseño (para que "está bien" sea objetivo)

Estos son los tokens reales del código (`lib/theme.dart`). Sirven de vara de medir: cuando dudes, compara contra esto.

### 1.1 Escala tipográfica

| Token | Tamaño | Interlineado | Peso | Tracking | Uso esperado |
|---|---|---|---|---|---|
| `displayLg` | 44 | 52 | w800 | −1.3 | Cifra grande de Inicio |
| `displayLgMobile` | 36 | 44 | w800 | −0.7 | Cifra grande en móvil |
| `headlineLg` | 32 | 40 | w700 | −0.6 | Título de pantalla |
| `headlineMd` | 24 | 32 | w700 | −0.2 | Título de tarjeta importante |
| `headlineSm` | 20 | 28 | w600 | — | Título de tarjeta |
| `bodyLg` | 16 | 24 | w400 | — | Texto principal, contenido |
| `bodyMd` | 14 | 20 | w400 | — | Texto secundario, descripciones |
| `bodySm` | 12 | 16 | w400 | — | Metadatos, etiquetas |
| `labelLg` | 14 | 20 | w600 | +0.1 | Botón, campo, chip |
| `labelMd` | 12 | 16 | w600 | +0.2 | Chip, etiqueta pequena |
| `labelSm` | 10 | 14 | w700 | +0.4 | Contador, "NUEVO", badge |

Dos familias tipográficas: **PlusJakartaSans** para los titulares, **Inter** para el cuerpo de texto.

**FALLA tipográfica si:** un título de tarjeta usa el mismo tamaño que el cuerpo (no hay jerarquía); el interlineado se apelmaza (las líneas se tocan) o se abre en exceso (el bloque queda desmadejo); un número grande no usa el token de display; hay texto de 10 pt que carga información importante.

### 1.2 Color

**Modo claro**

| Rol | Hex |
|---|---|
| Fondo / superficie | `#FFFFFF` |
| Superficie baja / container / alta / máxima | `#F2F4F2` · `#ECEEEC` · `#E6E9E7` · `#E1E3E1` |
| Texto principal | `#000000` |
| Texto secundario | `#3F4943` |
| Contorno / variante | `#5F6B62` · `#BEC9C0` |
| Primario | `#005136` (verde oscuro) |
| Contenedor primario | `#006C49` |
| Acento menta | `#6CF8BB` |
| Degradado | `#F3FBF7` → `#E1F3E9` → `#EAF7F0` |
| Botón sobre degradado | `#005136` con texto blanco |
| Error | `#BA1A1A` |

**Modo oscuro**

| Rol | Hex |
|---|---|
| Fondo / superficie | `#000000` (negro puro, no gris) |
| Superficie container | `#1B211D` |
| Texto principal | `#FFFFFF` |
| Texto secundario | `#BDC7BF` |
| Primario | `#7DD6A6` (menta) |
| Degradado | `#003824` → `#005C41` → `#003D27` |
| Botón sobre degradado | `#6FFBBE` con texto **oscuro** `#002113` |

**FALLA de color si:** texto que no se lee sin forzar la vista; dos superficies contiguas indistinguibles; el botón principal no es el elemento más llamativo de la pantalla; en oscuro queda superficie del tema claro; el botón sobre degradado usa texto blanco sobre menta (contraste insuficiente — debe ser oscuro).

### 1.3 Radios, márgenes, elevación

| Token | Valor | Dónde |
|---|---|---|
| Radio dominante de tarjeta | **16 dp** | casi todas las tarjetas |
| Radio de chip / píldora | **999** | chips, badges, píldoras de filtro |
| Radios secundarios | 20, 18, 14, 12, 10, 8, 6 | contenedores mayores, campos, menús |
| Margen horizontal de pantalla | **20 dp** | todas las pantallas |
| Separación entre tarjetas | 12–16 dp | listas |
| Elevación de barra superior | **0** | diseño plano, sin sombra |

**El diseño es plano**: las tarjetas **no** tienen sombra; se separan por tono de superficie (`#F2F4F2` vs `#FFFFFF`). Si dos tarjetas se confunden, es defecto.

**FALLA si:** un radio se cuela donde debería haber 16 (mezcla de estilos); el margen lateral no es 20 y hace "dientes" al pasar de pantalla en pantalla; aparece una sombra dura que el resto de la app no usa.

### 1.4 Objetivo táctil

Mínimo **48 dp** de alto y ancho en cualquier elemento pulsable. En el Pixel 6a (420 dpi, pantalla 1080×2400 → **411 dp de ancho lógico**) todo debe caber sin recorte.

---

## 2. Las 7 dimensiones del criterio

Puntúa cada pantalla que revises en estas 7 dimensiones. Es lo que convierte "está feo" en algo accionable y priorizable.

### D1 · Jerarquía visual
¿Se sabe dónde mirar primero? En menos de 2 segundos deberías identificar la acción o el dato principal.
- **FALLA:** todos los elementos del mismo peso; el dato más importante es el más pequeño; hay tres cosas compitiendo por la atención.

### D2 · Legibilidad
- **FALLA:** texto < 12 dp para contenido; interlineado apretado; palabras pegadas al borde de la tarjeta; mayúsculas/minúsculas raras; truncado con "…" donde cabría más texto.

### D3 · Contraste y color
- **FALLA:** texto que exige esfuerzo para leerlo; estados de chip indistinguibles entre sí; un mismo color significando cosas distintas.

### D4 · Espaciado y alineación
- **FALLA:** elementos que no alinean a la rejilla de 20 dp; separaciones inconsistentes entre tarjetas equivalentes; padding asimétrico (un lado más gordo que otro).

### D5 · Objetivo táctil y alcance
- **FALLA:** botón más pequeño que un dedo; acciones críticas al borde de la pantalla (difícil con una mano); dos acciones peligrosas muy cerca (tocar la equivocada).

### D6 · Estados
Toda pantalla interactiva debe tener: **normal · pressed · vacío · cargando · error**.
- **FALLA:** pantalla vacía sin explicación; spinner infinito si no hay red; error sin acción de reintento; nada cambia al pulsar.

### D7 · Consistencia
Que lo que se ve en Inicio se vea igual en Progreso.
- **FALLA:** el mismo concepto con dos estilos; radios mezclados; un botón "principal" con forma distinta en cada pantalla.

---

## 3. Revisión pantalla por pantalla

Recorre la app en el orden de las pestañas. Para cada una, mira **las 7 dimensiones** y anota los defectos con la plantilla del §6.

### U1 · EULA (primer arranque)

**Lo más difícil:** el texto largo de los términos es el hostil. 

- ¿El texto se puede leer cómodamente sin forzar la vista? (ancho de columna, interlineado)
- ¿El botón de aceptación está **al alcance del pulgar** (parte baja) y no escondido tras scroll?
- ¿Se distingue el botón de acción principal de "rechazar"? Si solo hay un botón, ¿el usuario puede deducir que al continuar acepta?
- ¿El degradado de fondo sube demasiado y resta legibilidad al texto? 
- **FALLA:** hay que hacer scroll largo para encontrar el botón; el texto de los términos es ilegible; la acción principal no está destacada.

### U2 · Registro (7 pasos)

**Lo más difícil:** los formularios largos son la mayor fuente de fricción.

- ¿El **indicador de paso** se ve sin tener que hacer scroll? ¿Se entiende en qué paso vas?
- ¿El **IMC en vivo** tiene jerarquía adecuada o compite con los campos?
- ¿Los campos de rueda (edad, peso, altura) se ven como un control reconocible, o parecen texto plano que no sabes que puedes girar?
- ¿El botón "Continuar" / "Guardar" está siempre en la misma posición y mismo tamaño?
- Si falta algo, ¿el aviso es un **SnackBar flotante** que nombra el campo concreto ("Falta por llenar: metas") y no se come la mitad de la pantalla?
- **FALLA:** el usuario no sabe si el campo es editable o si es una etiqueta; el botón cambia de posición entre pasos; el progreso no es visible; la validación muestra el error sin explicar cómo corregirlo; falta el aviso o no dice qué campo falta.

### U3 · Configuración inicial (tema + avisos)

- ¿Se **previsualiza el tema antes de aplicar**? Si no, es la queja más típica.
- ¿Los interruptores de aviso muestran claramente su estado (encendido o apagado)?
- **FALLA:** se cambia el tema sin previsualizarlo; el estado del interruptor es ambiguo; se puede "saltar" pero no se explica qué pasa si se salta.

### U4 · Inicio (Home)

La pantalla más importante. Revisar como portada.

- ¿El **saludo** con el nombre da bienvenida o parece una etiqueta más?
- ¿La tarjeta de **Balance del día** resume los tres objetivos de un vistazo? ¿Se distinguen agua / pasos / kcal?
- ¿La tarjeta principal de entrenamiento (con "Comenzar") es el elemento más llamativo de la pantalla? Debería serlo.
- ¿La entrada **"Mis rutinas"** se distingue de "Comenzar"?
- ¿El chip de **racha** compite con el contenido principal?
- ¿El chip de racha es **pulsable** y abre un diálogo con las estadísticas (racha, mejor racha, días, sesiones, nivel)? Un chip que no responde parece roto.
- ¿Queda algún icono de **campana**? No debería: no hace nada y es un botón que miente.
- **Densidad:** ¿hay que hacer scroll para ver lo esencial? Cuánto scroll hasta "Comenzar".
- **FALLA:** la acción principal queda por debajo del pliegue (hay que hacer scroll para verla); los números no se leen de un vistazo; hay elementos igual de destacados sin jerarquía entre ellos; hay una campana decorativa; el chip de racha no abre nada.
- **Mide:** anota cuántos scrolls necesitas para llegar a "Comenzar" sin tocar nada.

### U5 · Progreso

- ¿Las pestañas **Semanal / Mensual / Año** se distinguen de las sub-secciones?
- ¿El gráfico de peso tiene ejes y unidades legibles?
- ¿El **estado vacío** (sin historial) explica la situación con claridad, en vez de dejar un hueco seco?
- ¿Desapareció la **campana decorativa** de esta pantalla?
- **FALLA:** el gráfico no se entiende sin explicación; las pestañas parecen contenido no interactivo; el vacío da sensación de fallo; queda una campana que no hace nada.

### U6 · Entrenamientos (programas + rutinas propias)

- ¿El reproductor muestra **claramente**: ejercicio actual, progreso de la sesión, y siguiente paso?
- ¿El temporizador es legible de un vistazo?
- ¿La lista de **ejercicios** es escaneable (icono + nombre + duración alineados)?
- El **catálogo de 34 ejercicios**: ¿se ve el grupo muscular? ¿el buscador es visible de inmediato o hay que buscarlo?
- En el editor de rutina, ¿hay **un solo** botón "Guardar" y está al final del formulario? Dos (arriba y abajo) es redundancia que confunde.
- En el reproductor, ¿queda algún botón de **"Premium de prueba"**? En release no debe existir ninguno.
- **FALLA:** en el reproductor no sabes qué toca ahora; el catálogo es una lista plana sin jerarquía; el buscador está escondido; hay dos botones "Guardar"; aparece un botón de Premium de prueba.

### U7 · Recetas

- ¿La **imagen de la receta** carga? Cada receta tiene **su propio dibujo**, derivado de su nombre: dos recetas seguidas nunca muestran el mismo plato.
- ¿Los **chips de meta** activos se distinguen de los inactivos?
- ¿El **"Para tu meta"** con recuento se entiende sin explicación?
- **FALLA:** chips activo e inactivo casi iguales; cualquier caja roja de imagen o hueco sin tratar; dos recetas distintas comparten ilustración; el recuento no cuadra con lo que aparece al pulsar.

### U8 · Perfil

- ¿Los datos corporales están **agrupados** de forma escaneable (peso/altura/grasa/IMC juntos)?
- ¿El **IMC** tiene su etiqueta de estimación visible sin tener que buscar?
- ¿Las tarjetas (metas, nivel, insignias) tienen títulos claros y separables?
- ¿El **avatar** sale cuadrado y centrado en el círculo, sin banda blanca del recorte asomando por el borde?
- ¿Queda algún botón de **"Premium de prueba"** en Perfil? No debe quedar ninguno.
- En "Editar metas", ¿la meta de pasos se lee **"1000 pasos mínimo"** (un número que se entiende sin preguntar)?
- **FALLA:** los datos numéricos no se alinean en columna; hay demasiadas tarjetas sin jerarquía; el botón Guardar se pierde al final; el avatar muestra un cuadrado blanco dentro del círculo; hay un botón de Premium de prueba.

### U9 · Ajustes

- ¿Los **interruptores** se ven claramente encendidos/apagados?
- ¿Los grupos (Preferencias, Tema/Idioma, Datos de salud, Privacidad) están separados visualmente?
- ¿"Borrar todos los datos" tiene el **tratamiento de peligro** (separado, no junto a "Exportar")?
- En el grupo de anuncios: ¿solo queda el **interruptor real** del usuario (es consentimiento), sin botón de "probar Premium"?
- **FALLA:** "Borrar todo" parece una opción más de la lista y no la acción destructiva; los interruptores dejan dudoso su estado; las secciones no están separadas visualmente; hay un botón de Premium marcado como prueba.

### U10 · Comidas (plan semanal + lista de la compra)

- ¿El plan semanal **se lee de un vistazo** (días × comidas) o es una lista interminable?
- ¿La lista de la compra **agrupa por ingrediente** de forma utilizable?
- **FALLA:** el plan es una lista sin columnas; la lista de la compra parece copia del plan.

### U11 · Consejos

- ¿Las pastillas (chips) de categoría se ven como **filtros**, no como botones sueltos?
- ¿Los artículos tienen **imagen + título + resumen** coherentes en tamaño?
- ¿Sigue ahí la **campana decorativa**? Debe seguir fuera.
- **FALLA:** títulos de longitudes muy distintas rompen la rejilla; imágenes con alturas inconsistentes; no se distingue el artículo destacado; queda una campana que no hace nada.

### U12 · Ayuda

- ¿El manual se lee bien en el móvil (ancho de columna, títulos, tablas)?
- ¿Los desplegables FAQ son **fáciles de abrir** (área de toque grande)?
- **FALLA:** el manual en pantalla estrecha se corta o las tablas desbordan; los FAQ son difíciles de expandir.

---

## 4. Revisiones globales

### G1 · Tema oscuro
Cambia a oscuro en Ajustes y **recorre la app entera**. El diseño es plano: las tarjetas se separan por tono, no por sombra. Sobre fondo negro puro, un container `#1B211D` es sutil.
- **FALLA:** superficie del tema claro sobrevive al cambio; texto invisible; el banner de anuncios no se adapta; los degradados se ven apagados o sucios.

### G2 · Texto al 2.0×
Sube el tamaño de fuente al máximo y recorre la app. Hay un test automático que vigila el texto a 2.0× en 360 dp, pero **el ojo humano ve cosas que el test no**: un 2.0× que se ve feo aunque no llegue a recortarse.
- **FALLA:** franja negra de recorte; fila que se sale de pantalla; botón sin etiqueta; el resultado se ve "encajonado" aunque no se corte.
- **FALLA:** el texto grande deja tan poco espacio que ya no se ve el contenido importante de la tarjeta.

### G3 · Una sola mano
Prueba las acciones principales (registro, añadir agua, guardar rutina, marcar receta) **solo con el pulgar**, sujetando el móvil como en la vida real.
- **FALLA:** acción importante fuera del alcance cómodo del pulgar; botón pequeño; elementos pulsables tan juntos que fallas al apuntar.

### G4 · Scroll y profundidad
Cuenta cuánto scroll hace falta para llegar a la acción principal en cada pestaña.
- **Referencia:** en Inicio, "Comenzar" debería estar visible sin scroll en un móvil normal. Si no, es defecto de jerarquía.

### G5 · Movimiento y respuesta
- ¿Cada pulsación da una respuesta inmediata (cambio de color, ripple, vibración)?
- ¿Las pantallas nuevas entran con una transición creíble?
- **FALLA:** un toque parece no hacer nada; la transición tarda tanto que parece un fallo; animaciones que mueven el texto bajo el dedo.

### G6 · Errores y honestidad
Cuando algo no se puede hacer (sin Health Connect, sin red, sin permiso), la app debe decirlo con claridad, no esconderlo ni inventar.
- **FALLA:** pantalla en blanco; spinner eterno; error sin decir qué hacer; un número estimado presentado como real.

---

## 5. Scorecard UI/UX

Al terminar, puntúa cada pantalla. **A = publicable · B = vale con retoques · C = molesta · D = bloquea.**

```
Pantalla                  Jerarquía  Legible  Contraste  Espaciado  Táctil  Estados  Consistencia  Nota
U1  EULA                                    [  ]        [  ]       [  ]      [  ]     [  ]       [  ]
U2  Registro                                [  ]        [  ]       [  ]      [  ]     [  ]       [  ]
U3  Config inicial                          [  ]        [  ]       [  ]      [  ]     [  ]       [  ]
U4  Inicio                                  [  ]        [  ]       [  ]      [  ]     [  ]       [  ]
U5  Progreso                                [  ]        [  ]       [  ]      [  ]     [  ]       [  ]
U6  Entrenamientos                           [  ]        [  ]       [  ]      [  ]     [  ]       [  ]
U7  Recetas                                  [  ]        [  ]       [  ]      [  ]     [  ]       [  ]
U8  Perfil                                  [  ]        [  ]       [  ]      [  ]     [  ]       [  ]
U9  Ajustes                                 [  ]        [  ]       [  ]      [  ]     [  ]       [  ]
U10 Comidas                                 [  ]        [  ]       [  ]      [  ]     [  ]       [  ]
U11 Consejos                                [  ]        [  ]       [  ]      [  ]     [  ]       [  ]
U12 Ayuda                                   [  ]        [  ]       [  ]      [  ]     [  ]       [  ]
```

```Global
G1 Tema oscuro            [  ]
G2 Texto 2.0x            [  ]
G3 Una mano              [  ]
G4 Profundidad de scroll [  ]
G5 Movimiento            [  ]
G6 Errores y honestidad  [  ]
```

**Regla de salida a producción:** ninguna pantalla con **D**, y ninguna columna de estado (D6) en **C** o peor.

---

## 6. Severidad de cada defecto

Cuando anotes algo, clasifícalo. Así se prioriza sin discusiones.

| Nivel | Qué es | Ejemplo |
|---|---|---|
| **S1 · Bloqueante** | Impide usar la app o pierde datos | Texto recortado que oculta información; no se puede guardar; dato falso presentado como real |
| **S2 · Grave** | Rompe la experiencia en una tarea común | No sabes dónde tocar; lista ilegible; estado vacío que parece fallo |
| **S3 · Medio** | Se nota y molesta, hay forma de rodearlo | Desalineación; jerarquía débil; contraste justo |
| **S4 · Menor** | Cosmético | Un radio fuera de sitio; un espaciado 2 dp raro |

---

## 7. Plantilla de reporte UI/UX

Una entrada por defecto. Copia y rellena.

```
UI/UX-F<n>  Pantalla: U<n>
Severidad:  S1 | S2 | S3 | S4
Dimensión:  D1 jerarquía | D2 legible | D3 contraste | D4 espaciado |
            D5 táctil | D6 estados | D7 consistencia
Modo:       claro | oscuro | 2.0x
Qué vi:     (describe lo que pasa, no lo que sientes)
Por qué es problema: (qué tarea se dificulta o se rompe)
Frecuencia: siempre | a veces
```

**Ejemplo bien escrito:**

```
UI/UX-014  Pantalla: U4 (Inicio)
Severidad:  S2
Dimensión:  D1 jerarquía
Modo:       claro
Qué vi:     el chip de racha y "Mis rutinas" tienen el mismo peso visual que
            el botón "Comenzar"; los tres compiten por la atención
Por qué es problema: la acción principal del día (entrenarse) no es la que
            el ojo encuentra primero; cada mañana cuesta saber qué hacer
Frecuencia: siempre
```

---

## 8. Lo que esta revisión NO cubre

- **Que la app funcione:** eso es `GUIA_TESTEO_UNIFICADA.md`.
- **Que los datos sean correctos:** los valores de salud llevan su etiqueta de
  estimación; el diseño de la etiqueta está en D2/D3, la veracidad del dato es
  otro test.
- **Pruebas automáticas:** `flutter analyze` (0 issues) y `flutter test` (280/280)
  ya están en verde (incluyen la Fase C de insignias y su accesibilidad a 2.0×).
  Esta guía es para lo que el ojo y el dedo sí ven.

---

## Anexo · Datos del build bajo prueba

| Dato | Valor |
|---|---|
| Versión | FitPulse 1.0.0+1 |
| Package | `com.fitpulse.app` |
| Build | **release arm64-v8a, AOT, firmado con la clave de debug** (no hay keystore propio todavía) |
| Tamaño del APK | 50 073 007 B (47,8 MB) |
| minSdk / targetSdk | 26 / el de Flutter |
| Dispositivo de referencia | Pixel 6a, Android 17 (SDK 37), 1080×2400 @ 420 dpi → **411 dp de ancho** |
| Segundo dispositivo | Xiaomi Redmi 8A (Android 9) — `uiautomator dump` falla por tema MIUI, no por la app |
| Estado de datos | Borrado con `pm clear` (sin desinstalar): la app está en primer arranque |