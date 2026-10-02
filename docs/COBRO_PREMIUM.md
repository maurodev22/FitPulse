# COBRO_PREMIUM — Cómo vincular el cobro real de FitPulse Premium

> Guía de entrega escrita para alguien con **conocimientos básicos de informática**
> (instalar apps, usar WhatsApp/Drive, abrir webs). No hace falta ser programador:
> aquí se explica cómo se cobra el Premium y qué debe hacer cada persona.
> Toda la parte técnica del **código de cobro** está pendiente de implementar
> (se explica al final); este documento cubre el procedimiento de cuentas,
> banco y tienda para que el dinero llegue.

---

## 1. Qué es Premium HOY y qué falta para cobrarlo (honesto)

- **Hoy**, el botón "Activar Premium (modo prueba)" de Perfil **no cobra nada**:
  solo activa un flag local en el teléfono que oculta los anuncios, para probar
  que la app se comporta bien sin publicidad. Está marcado como "modo prueba"
  justamente para que nadie confunda eso con una compra real.
- **Para cobrar de verdad** hace falta que la compra de Premium pase por
  **Google Play Billing** (el sistema de compras dentro de las apps de Play):
  el usuario paga desde su cuenta de Google, y Google te transfiere el dinero
  (con su comisión, hoy ~15 % en apps pequeñas) a la **cuenta bancaria** que
  vincules en Google Play Console.
- **Cuba es un bloqueo real, no técnico**: Google Play y AdMob **no aceptan
  cuentas con residencia fiscal en Cuba** (país sujeto a sanciones de EE. UU.).
  Por eso la cuenta de desarrollador, los datos fiscales y el banco deben
  pertenecer a una **persona o empresa fuera de Cuba** (llamada aquí **el
  receptor**). El código de la app está preparado para no depender de Cuba.

**Resumen en una frase:** el Premium cobra cuando (1) se implementa el cobro en
el código, (2) el receptor crea su cuenta de desarrollador fuera de Cuba con sus
datos bancarios, y (3) el usuario paga desde Google Play.

---

## 2. Qué necesita cada persona

| Persona | Qué hace | Qué necesita tener |
|---|---|---|
| **El desarrollador** (aquí) | Implementa el cobro en el código + entrega los textos de la ficha | Nada de cuentas ni bancos (no depende de Cuba para programar) |
| **El receptor** (fuera de Cuba) | Crea la cuenta de Play, el producto Premium, vincula el banco y sube la app | Pasaporte/ID, datos fiscales, **cuenta bancaria** en su país, tarjeta emitida en su país |
| **El usuario final** | Paga desde su propia cuenta de Google Play | Cualquier método de pago de Google Play en su país (tarjeta, saldo, operador) |

> ⚠️ Punto importante: **el dinero no se recibe con una tarjeta de crédito**.
> Google Play y AdMob transfieren las ganancias a una **cuenta bancaria** (o,
> en algunos países, Payoneer). La tarjeta sirve para **pagar** la cuota de 25 USD
> de la cuenta de desarrollador, no para **recibir** los cobros.

---

## 3. Paso a paso para vincular el cobro (orden recomendado)

### Paso 0 — Decidir QUÉ se vende (1 minuto)

FitPulse Premium hoy está planteado como **compra única** ("Quita los anuncios
de por vida con una compra única."). Eso es lo más simple: el usuario paga una
vez y el Premium queda para siempre. Alternativas (no recomendadas por ahora):
suscripción mensual/anual, o compra única + suscripción opcional. **Decisión
recomendada: una sola compra única.** Precio sugerido: decidirlo con el receptor
(por ejemplo 2,99 / 4,99 USD; se puede cambiar después).

### Paso 1 — Crear la cuenta de desarrollador de Google Play (receptor)

1. Entrar a **play.google.com/console** con una cuenta de Google **del receptor**
   (no compartir la contraseña de esta cuenta con nadie).
2. Pagar el registro único de **25 USD** con una tarjeta emitida **en su país**.
3. Rellenar los **datos del comerciante** (nombre, dirección, país, teléfono).
4. Completar el perfil fiscal (formulario W-8BEN para persona física /
   W-8BEN-E para empresa) — pide número fiscal y datos de la entidad.
5. Cumplimentar el **perfil de pagos** (pagos de Google): ahí se vincula la
   **cuenta bancaria** que recibirá las transferencias (IBAN, SWIFT, o cuenta
   local según país) y se verifica la identidad.

> El formulario fiscal y el banco pueden pedir documentación; normalmente tarda
> de días a ~2 semanas en quedar "activo". **No se puede publicar app de pago
> hasta que el perfil esté verificado** (las apps gratuitas sí se pueden).

### Paso 2 — Crear el producto Premium en Play Console (receptor, ~10 min)

1. En la consola, abrir la app de FitPulse (se crea en el paso 4 de la guía de
   publicación, o ahora mismo: **Crear app** → nombre "FitPulse", categoría
   "Salud y forma física").
2. Ir a **Monetización → Productos → Compra en la aplicación** (in-app products).
3. Botón **Crear producto**:
   - **ID del producto**: `fitpulse_premium_remover_anuncios` (este ID es el que
     se programa en el código; no cambiarlo luego).
   - **Nombre**: "FitPulse Premium".
   - **Descripción**: "Quita los anuncios de por vida." (texto visible al comprar).
   - **Precio**: el decidido en el Paso 0 (base + impuestos por país, Play lo
     calcula solo).
   - **Estado**: ACTIVO.
4. Guardar. En 1-2 horas el producto queda visible para pruebas y para la app.

### Paso 3 — Activar licencias y suscripciones en Play Console (receptor, 2 min)

En **Configuración → Integridad de la app → Licencias**: activar el
**"Comprobador de licencias"**. (Si en el futuro se hace suscripción, Play usa
el sistema de "compras desglosadas por suscripción" — no hace falta nada más hoy.)

### Paso 4 — Implementar el cobro en la app (desarrollador, tarea de código)

> Esto es la **parte de código que aún no existe**. Cuando el receptor tenga la
> cuenta lista y el ID del producto creado (`fitpulse_premium_remover_anuncios`),
> se implementa en FitPulse:
> - Añadir el plugin oficial **`in_app_purchase`** (o `google_play_billing` nativo).
> - Conectar el botón "Activar Premium" de Perfil a una **compra real** de Play
>   (mostrar la hoja de compra de Google, esperar confirmación).
> - **Verificar la compra con el comprobador de licencias / Play Billing** antes
>   de activar el flag `premiumEnabled` (nunca activar sin confirmación de Google).
> - Al **desinstalar/reinstalar o cambiar de teléfono**, restaurar el Premium
>   consultando las compras de la cuenta de Google (Play lo recuerda si la compra
>   está asociada a la cuenta).
> - Actualizar el botón "Desactivar Premium (modo prueba)" → será "Premium
>   activado ✓" sin botón de desactivar (el Premium comprado no se desactiva).
> - Actualizar textos y el EULA para reflejar la compra real.
>
> Entregable: lo implemento y queda probado con las **cajas de pruebas de Play**
> (se puede simular una compra sin pagar usando los "licencias de prueba" de la
> consola).

### Paso 5 — Subir la app con el cobro y publicar (receptor)

1. El desarrollador entrega el **`.aab`** firmado (ver `GUIA_PUBLICACION.md`).
2. Subirlo en **Producción → Versión principal**.
3. En la ficha de tienda, declarar en **Monetización**: compra en la aplicación
   (producto "FitPulse Premium, usa un ID de producto: fitpulse_premium...").
4. En **Data Safety**, actualizar la declaración de compras: "Se ofrecen compras
   dentro de la aplicación (opcional, solo para quitar anuncios; no recopila
   datos de salud)". El resto de la declaración (datos 100 % locales) no cambia.
5. Enviar a revisión. Google revisa la app + la oferta de compra (suele tardar
   de horas a ~3 días).

### Paso 6 — Probar el cobro de verdad antes de publicar (receptor, 10 min)

Con la app instalada desde la consola (los **usuarios de prueba** de Play, o
"licencias de prueba"), comprobar:

| Prueba | Resultado esperado |
|---|---|
| Pulsar "Activar Premium" | Se abre la hoja de compra de Google con el precio |
| Confirmar la compra (de prueba) | Aparca el diálogo de Google → Premium activo, desaparecen los anuncios |
| Volver a entrar a Perfil | Sigue "Premium activo" (compra recordada) |
| Desinstalar y reinstalar la app | Al volver, Premium restaurado desde la cuenta de Google (sin pagar 2 veces) |
| Sin cuenta de Google en el móvil | No se puede comprar; la app avisa con texto honesto y no se bloquea |

### Paso 7 — Recibir el dinero (automático, cada mes)

- Google **acumula** las ventas y paga **una vez al mes** (si superas el umbral
  mínimo de tu país, normalmente ~1 USD el primero; el calendario exacto aparece
  en **Play Console → Pagos → Resumen de pagos**).
- El dinero cae en la **cuenta bancaria** vinculada en el Paso 1, menos la
  comisión de Google (~15 %, hoy, para apps que facturan < 1 M USD/año con 30 %
  reducido a 15 % para los primeros 1 M USD, y 15 % → se mantiene en el modelo
  actual; verificar el porcentaje vigente en el momento del alta).
- Emisión de factura/retención según el país del receptor (lo gestiona la propia
  consola con los datos fiscales).

---

## 4. Relación con los anuncios de AdMob (dos fuentes de ingreso distintas)

| Fuente | Qué paga | Cómo se cobra |
|---|---|---|
| **AdMob** (anuncios) | Google paga por los anuncios mostrados | Cuenta o banco vinculado en AdMob (perfil de pagos AdMob, independiente de Play) |
| **Play Billing** (Premium) | El usuario paga para quitar anuncios | Cuenta bancaria vinculada en Play Console (perfil de pagos de Google) |

Las dos fuentes se pueden tener a la vez; son perfiles de pago **separados**.
El orden natural del producto: si vendes Premium, el usuario que compra deja de
ver anuncios (ya implementado: `adsEnabled && !premiumEnabled`). Los anuncios
siguen siendo de prueba al desarrollador en Cuba; los IDs reales los pone el
receptor (ver `docs/ADS_CLIENTE.md`) — y el cobro de AdMob va a su banco.

---

## 5. Checklist final (todo lo que hay que tener "sí")

- [ ] Cuenta de desarrollador de Play creada y pagada (25 USD) por **el receptor**.
- [ ] Perfil fiscal (W-8BEN / W-8BEN-E) completado.
- [ ] **Cuenta bancaria** vinculada y verificada en el perfil de pagos.
- [ ] Producto `fitpulse_premium_remover_anuncios` creado y ACTIVO.
- [ ] Comprobador de licencias activado.
- [ ] Código de cobro implementado (tarea del desarrollador) y probado con licencia de prueba.
- [ ] App subida con la compra declarada en Monetización y Data Safety.
- [ ] Prueba real de compra en dispositivo (Paso 6) con resultado PASA.
- [ ] Primer pago mensual recibido en el banco del receptor.

---

## 6. Resumen en 3 frases

1. **Hoy el Premium es de prueba** (no cobra); implementar el cobro real es una
   tarea de código que queda lista cuando exista la cuenta del receptor.
2. **El receptor** crea la cuenta de Play fuera de Cuba, hace el producto
   `fitpulse_premium_remover_anuncios` y vincula su **cuenta bancaria** (no se
   cobra con tarjeta: la tarjeta solo paga la cuota de 25 USD).
3. Con el cobro implementado y la app publicada, Google transfiere **cada mes**
   las ventas al banco del receptor menos la comisión; AdMob paga por otro perfil.

---

## 7. Notas de código (referencia para el desarrollador)

- Estado actual: `ConfigService.setPremium(bool)` persiste `premiumEnabled`
  (`lib/services/config_service.dart`); el botón está en `ProfileScreen._buildPremium`
  (`lib/screens/profile_screen.dart`); textos en `LocaleService` (`pfPremium*`:
  `lib/services/locale_service.dart`). Los anuncios se gatean con
  `adsEnabled && !premiumEnabled` en `lib/main.dart`.
- El EULA v2 ya declara "compras dentro de la aplicación" de forma genérica
  (`eulaSection6`), por lo que no hace falta re-pedir aceptación al activar la
  compra real, solo ajustar el texto si se quiere mencionar el precio exacto.
- Al implementar el cobro: verificar la compra con **Play Billing (skus detalles
  + acknowledge) o el comprobador de licencias**, y guardar el estado como
  "Premium por compra" separado del flag de prueba para no pisarlo.