# GUIA_PUBLICACION — Empaquetar, enviar y publicar FitPulse

> Guía de entrega, escrita para alguien **con conocimientos básicos de informática**
> (instalar apps, usar WhatsApp/Google Drive, etc.), no hace falta ser programador.
> Toda la parte técnica del código ya está hecha: esto es solo "logística" de
> cuentas, archivos y pruebas.

---

## 1. ¿Falta algo para empaquetar y publicar?

**La app YA se empaqueta** (se compila en un archivo instalable). Hoy mismo se
puede generar el `.apk` de prueba y mandarlo a cualquier móvil Android 8 o superior.

Lo que **sí falta** para *publicar en Google Play y ganar dinero con anuncios* no
es código, son **cuentas y trámites**, todos relacionados con que Google no opera
en Cuba:

| Qué falta | Por qué | Dónde se resuelve |
|---|---|---|
| **Cuenta AdMob real** (fuera de Cuba) | Con un país embargado no se abre | El receptor la crea en su país → consola AdMob |
| **IDs de anuncios reales** | Hoy la app usa solo anuncios de PRUEBA (no pagan) | Se copian de la cuenta AdMob a la app (5 min, queda documentado) |
| **Mensaje de consentimiento UE** | Europa exige pedir permiso antes de publicidad | Crear un "mensaje" en la consola AdMob (15 min) |
| **Cuenta de desarrollador Google Play** | Cuesta 25 USD una sola vez y no se abre desde Cuba | El receptor la crea desde su país con sus datos |
| **Firma de la app (keystore)** | Play pide que la app vaya firmada por su dueño | Se genera una vez con un programa gratuito (10 min, ver anexo) |
| **Ficha de Play: nombre, fotos, descripción** | Requisito de la tienda | El receptor la rellena (puedo preparar todos los textos) |
| **Ficha Data Safety (privacidad)** | Requisito de la tienda | Se responde un formulario declarando que los datos son locales (guion incluido) |

Además: el receptor debe **verificar antes de publicar** que todo funciona con sus
anuncios reales (sección 3 de esta guía) y devolverme los IDs nuevos para
activarlos en el código.

> Nota importante y honesta: con los IDs de prueba actuales, el receptor **sí podrá
> ver anuncios** mientras testea (Google sirve anuncios de prueba en cualquier país),
> pero esos anuncios **no generan dinero**. El dinero llega cuando se ponen los IDs
> reales de su cuenta AdMob.

---

## 2. Cómo enviar la app a esa persona

### Paso 0: el archivo que hay que mandar

Cada forma de salir al mundo usa un archivo distinto:

- **APK** → sirve para *probar en el móvil* primero (cualquier persona lo instala
  como quien instala un juego descargado). Es lo que mandamos ahora.
- **AAB** → es el archivo que se sube a *Google Play* (la tienda lo convierte sola
  en el APK de cada móvil). Se genera después, con la firma propia.

El APK de prueba se encuentra en la carpeta del proyecto en:

```
build\app\outputs\flutter-apk\app-release.apk
```

(Viene firmado con una clave temporal llamada "debug": sirve perfecto para probar.
Para publicar se usa la firma propia del anexo.)

### Paso 1: enviar el archivo

Cualquier método que acepte archivos de ~40-100 MB:

- **Google Drive / WeTransfer** (el más cómodo para PC).
- **Telegram / WhatsApp** (a veces comprimen o bloquean archivos grandes; Drive es
  más fiable).

Si el archivo resulta muy grande (@100 MB), puedo generar APKs más pequeños, uno
por familia de móvil (~35 MB), o subirlo desde aquí. Avisar y lo genero.

### Paso 2: instalarlo en el móvil (explicado sencillo)

1. Descargar el archivo `app-release.apk` en el móvil (abrir el enlace de Drive/Telegram).
2. Tocar el archivo descargado.
3. Android preguntará **"¿Permitir instalar apps desconocidas?"** → **Permitir**.
   (Esto solo se pide una vez; es normal porque la app no viene de la tienda aún.)
4. Aceptar e instalar.
5. Abrir FitPulse. Debe verse la pantalla del aviso legal (EULA) con botón "Aceptar".

> Requisitos del móvil: Android 8 o superior (casi todos). No necesita Play Store
> ni cuentas. La app no pide datos personales ni servidores.

### Paso 3: qué debe probar esa persona (lista PASA / FALLA)

> Con la app **tal cual** ahora mismo (anuncios de prueba) ya se puede probar todo
> el funcionamiento. Con los **IDs reales** (cuando el receptor cree su AdMob) se
> repite la misma lista para confirmar que cobra.

| # | Prueba | Cómo | Resultado esperado |
|---|---|---|---|
| 1 | **Abrir la app** | Tocar el icono | Aparece el aviso legal (español/inglés según idioma del teléfono) |
| 2 | **Aceptar el aviso** | Botón "Aceptar" | Pasa a un registro corto (nombre, fecha) y luego a la pantalla de Inicio |
| 3 | **Espacio del banner** | Fijarse abajo de la pantalla de Inicio | Se ve una franja con publicidad o, si no hay red, una zona "de anuncio" discreta |
| 4 | **Anuncio recompensado** | Pestaña Progreso → tarjeta "+25 Puntos" | Se abre un anuncio en pantalla completa; al terminarlo suman 25 puntos (solo 1 vez al día) |
| 5 | **Anuncio al volver** | Salir al menú del teléfono, esperar 30 segundos, volver a FitPulse | A veces se muestra un anuncio de apertura; nunca durante un ejercicio ni al abrir la app fría |
| 6 | **Desactivar anuncios** | Perfil → "Anuncios habilitados" → apagar | Desaparece el banner y deja de ofrecer el recompensado |
| 7 | **Premium** | Perfil → desbloquear Premium | Desaparecen todos los anuncios |
| 8 | **Sin conexión** | Activar modo avión y abrir la app | La app funciona y no se muestran anuncios (sin cierres ni avisos raros) |

Si una prueba falla: **anotar el número**, cerrar y reabrir la app una vez, y si se
repite, hacer una **captura de pantalla** y mandarla con el número.

### Paso 4: qué debe crearse ANTES de publicar (cuentas del receptor)

1. **Cuenta AdMob** (admob.google.com) con datos reales de su país.
2. En AdMob: registrar la app → crear los bloques:
   - **Banner** → copiar el ID (`ca-app-pub-…/…`)
   - **Recompensado** → copiar el ID
   - **App abierta (App Open)** → copiar el ID
   - **ID de app** (también llamado APP_ID, `ca-app-pub-…~…`)
3. En AdMob → **Privacidad y mensajes** → crear el **mensaje de consentimiento**
   (idiomas: español e inglés; opciones: aceptar/no aceptar la personalización).
   La app ya sabe mostrarlo sola cuando se necesita (Europa/Reino Unido).
4. **Cuenta de desarrollador en Google Play Console** (play.google.com/console,
   pago único de 25 USD) desde su país, con sus datos fiscales/bancarios.
5. Enviarme los 4 códigos de AdMob (paso 2) → **yo los pongo en la app en unos
   minutos** y entrego el AAB final para subir.

### Paso 5: subir y publicar en Google Play (resumen)

1. Yo entrego el archivo **`.aab`** firmado (se genera en el anexo o lo genero yo
   con los datos del receptor).
2. En Google Play Console: **Crear app** → rellenar nombre, categoría ("Salud y
   forma física" o "Salud"), idiomas (español, inglés).
3. Subir el `.aab` en **Producción → Versión principal**.
4. Completar la **ficha de tienda**: descripción (texto que puedo preparar),
   capturas de pantalla (mínimo 2), icono, portada.
5. Cumplimentar **Data Safety** (declaración de privacidad). Guion honesto:
   - La app **no recopila ni comparte** datos personales (todo es en el móvil).
   - Los únicos datos que salen del dispositivo son los anuncios opcionales, que
     **no incluyen datos de salud**.
   - No usa cifrado en tránsito propio (no hay servidores propios).
   - No hay compras obligatorias; si se activan en el futuro se declaran.
6. **Revisión** → enviar a revisión de Google (suele tardar de horas a ~3 días).
   Puede pedir la **URL de la política de privacidad**: el texto ya está dentro de
   la app y en el proyecto; si no hay web, Google suele admitir un documento
   público (Drive) mientras tanto.

---

## 3. Anexo — Generar la firma propia (keystore) en 10 minutos

> Solo para quien quiera publicar (el receptor o el desarrollador). Con la firma
> "debug" la app **se prueba perfectamente**, pero para Play se recomienda firma
> propia. Puedo hacerlo yo mismo si me pasan "nombre de la organización + 2
> contraseñas que me dicen por privado", o seguir estos pasos en Windows:

1. Tener instalado **Java** (si ya compila Flutter, ya lo tiene).
2. Abrir una ventana de **Símbolo del sistema** (tecla Windows → escribir `cmd` → Enter).
3. Pegar este comando (cambiar `miusuario` por el usuario de la PC):

```
keytool -genkeypair -v -keystore C:\Users\miusuario\fitpulse.jks -keyalg RSA -keysize 2048 -validity 10000 -alias fitpulse
```

4. Responder las preguntas (nombre, organización, país…) y poner **dos contraseñas**
   (guardarlas en un lugar seguro: se necesitan también para actualizar la app en el futuro).
5. Mandarme el archivo `fitpulse.jks` **NO por chat público** (preferible correo o
   carpeta protegida) + las contraseñas → yo genero el `app-release.aab` final.

> ⚠️ Cuidado: perder el keystore o las contraseñas **bloquea** actualizaciones
> futuras (habría que publicar como app nueva). Guardarlas en 2 lugares.

---

## 4. Resumen en 3 frases

1. **Probamos YA** con el `app-release.apk` (anuncios de prueba) y rellenamos la
   tabla PASA/FALLA.
2. **El receptor crea** AdMob + mensaje de consentimiento + cuenta Play desde su
   país y me pasa los 4 códigos de AdMob.
3. **Yo activo los códigos**, genero el AAB firmado y la persona lo sube a Play con
   la ficha (textos que ya les entrego).

Con esto, FitPulse queda publicada y con publicidad real (banner + recompensado +
app open + consentimiento UE) sin depender de Cuba.