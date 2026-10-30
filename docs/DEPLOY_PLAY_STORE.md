# Despliegue en Google Play (Europa) — estado y pasos

**Estado:** 2026-10-26 · versión `1.1.0+2010` · `flutter analyze` 0 issues ·
363 tests en verde · `main` al día con `origin/main`.

Este documento sustituye al checklist del 2026-10-06. Separa lo que ya está en
el repo de lo que **solo se puede hacer desde una cuenta** (Play Console, AdMob,
GitHub Pages) y deja los textos listos para pegar en los formularios.

---

## 0. Resumen de lo que falta

| # | Ítem | Estado | Quién |
|---|---|---|---|
| 1 | Cuenta de desarrollador Play Console ($25) | 🔴 falta | tú |
| 2 | Verificación de identidad/dirección y datos fiscales | 🔴 falta | tú |
| 3 | Cuenta AdMob + medio de pago + 3 unidades de anuncio | 🔴 falta | tú |
| 4 | Mensaje de consentimiento UMP (EEE/Reino Unido) | 🔴 falta | tú |
| 5 | Estado de comerciante (DSA) en la consola | 🔴 falta | tú |
| 6 | Política de privacidad pública (Pages) | 🔴 404 | tú (2 clics) |
| 7 | Capturas de ficha | 🟢 5 regeneradas a 1080×2400 (sin emulador) | yo |
| 8 | AAB firmado de la versión final | 🟡 se regenera al cerrar la versión | yo |
| 9 | Declaraciones de App content (salud, FGS, anuncios, datos) | 🟢 textos listos (§4) | yo + tú |
| 10 | Test cerrado 12 testers × 14 días | ⏳ 2 semanas | tú |
| 11 | Decisión de monetización (A/B/C) | 🟡 recomendada A | tú |
| 12 | Suite manual final en dispositivo | 🟡 pendiente de desbloqueo | yo |

**Ruta crítica:** cuenta (1–2) → Pages (6) → test cerrado (10) → producción.
El resto se puede preparar en paralelo.

---

## 1. Bloqueantes que dependen de tu cuenta

### 1.1 Cuenta Play Console
- Coste único 25 USD, país soportado. Cuba no está soportada: hace falta entidad
  legal (autónomo/empresa) y datos fiscales de un país soportado.
- Verificación de identidad (documento) y, si es empresa, de la organización.
- Cuenta personal creada desde 2023 → **test cerrado obligatorio** antes de
  producción (§3).

### 1.2 AdMob
- Cuenta AdMob vinculada a la de Play, perfil de pagos con medio internacional.
- Crear **3 unidades**: banner, recompensado y app open → 3 IDs `ca-app-pub-…`.
- Sustituir los IDs de prueba: `tools/activar_ids_ads.ps1` (valida que cada ID
  aparezca una sola vez) o a mano según `docs/ADS_CLIENTE.md`.
  - `android/app/src/main/AndroidManifest.xml` (app ID `~…`)
  - `lib/services/ads_service.dart` (`kAdmobBannerTestId`, `kAdmobRewardedTestId`,
    `kAdmobAppOpenTestId`)
- Con IDs reales, la app deja de mostrar las piezas locales «PRUEBA».

### 1.3 Consentimiento UMP (obligatorio en la UE)
- AdMob → *Privacy & messaging* → mensaje **europeo** (EEE + Reino Unido) en
  español e inglés, con opción de anuncios no personalizados.
- El código ya lo invoca al arrancar (`ConsentService`): sin consentimiento
  resuelto no se cargan anuncios.
- Probar en un dispositivo con IP europea: aceptar, rechazar y cambiar la
  elección desde el enlace de privacidad del propio formulario.

### 1.4 Comerciante (DSA)
- En Play Console → *Configuración → Estado de comerciante*: si publicas como
  empresa/autónomo, tus datos de contacto serán públicos en la ficha. Si no,
  declara «no comerciante» (limita funciones de pago; con anuncios conviene
  declararte comerciante).

### 1.5 Política de privacidad pública (GitHub Pages)
La ficha exige una URL que responda 200. Hoy
`https://maurodev22.github.io/FitPulse/privacidad/` devuelve **404** porque
Pages no está activado:
1. Repo → **Settings → Pages**.
2. *Source*: `Deploy from a branch` · *Branch*: `main` · *Folder*: `/docs`.
3. Guardar y esperar 1–3 min. Comprobar en el navegador que abre la política
   (versión del documento: **2026-10-26**).

### 1.6 Test cerrado (cuentas personales nuevas)
- Track **Cerrado** con **12 testers** (correos de Gmail) durante **14 días
  seguidos**; Play lo exige antes de habilitar producción.
- Los testers deben instalar la app desde Play (no APK) y usarla unos minutos.

---

## 2. Ya hecho en el repo

- **Firma**: keystore propio fuera del repo (`C:\Users\mauro\fitpulse-keys\`),
  contraseñas en `android/key.properties` (ignorado). Firma condicional: sin
  secretos compila en debug.
- **SDK**: `compileSdk`/`targetSdk` 36 → cumple el mínimo de Play 2026.
- **Política de privacidad**: `docs/privacidad/index.html` (es/en). Actualizada
  el 2026-10-26: AdMob/ID de publicidad, consentimiento EEE/RU y sección nueva
  «Enlaces a webs externas» (NHS/OMS/Sleep Foundation). La versión en-app
  (`lib/services/locale_service.dart` → `pvSec*`) dice lo mismo.
- **Data Safety**: respuestas exactas en `docs/DATA_SAFETY.md`.
- **Copy de ficha**: `docs/FICHA_PLAY_STORE.md` (nombre, descripciones, notas).
- **Assets**: `docs/store_assets/icono_512.png` y `feature_graphic.png`.
- **Capturas**: `test/manual/capturas_ficha.dart` regenera
  `docs/store_assets/capturas/cap_{home,recetas,progreso,consejos,perfil}.png`
  a 1080×2400 **sin emulador ni dispositivo** (renderiza la app real en un test
  con datos de demostración creados por la propia API):
  ```
  flutter test test/manual/capturas_ficha.dart
  ```
  No se ejecuta en `flutter test` normal (no acaba en `_test.dart`).
  Alternativa con barra de estado real: `integration_test/capturas_ficha_test.dart`
  + `test_driver/capturas_driver.dart` en un emulador:
  ```
  flutter drive --driver test_driver/capturas_driver.dart `
    --target integration_test/capturas_ficha_test.dart -d emulator-5554
  ```
- **Auditoría de textos de salud** (MDR): `docs/POLITICA_COPY_SALUD.md`.

---

## 3. Secuencia exacta en Play Console

1. **Crear app**: nombre «FitPulse», idioma predeterminado español, app gratuita,
   declaración de políticas.
2. **Ficha**: descripción corta/larga, icono 512, gráfico 1024×500, 2–8 capturas
   de teléfono, correo de contacto, URL de privacidad (§1.5). Si hay anuncios,
   marcar «Contiene anuncios».
3. **App content** (todo obligatorio):
   - Privacidad → URL.
   - Anuncios → Sí (AdMob).
   - Acceso a apps → «Todas las funciones disponibles sin restricciones».
   - Clasificación de contenido → cuestionario IARC (salud y bienestar, sin
     violencia/sexo/drogas) → resultado esperado 12+/16+.
   - Público objetivo → **16+**, no dirigida a niños.
   - Seguridad de los datos → §4.4 (usa `docs/DATA_SAFETY.md`).
   - **Salud**: declaración de Health Connect (§4.2) + servicio en primer plano
     (§4.3).
   - Comerciante DSA (§1.4).
   - Permisos sensibles: cámara (entrenador) y actividad física → justificar.
4. **Subir AAB** a *Testing → Cerrado*, con notas de versión.
5. **Test cerrado** (§1.6) → solicitar producción → rollout gradual 20 % → 100 %.
6. **Países**: EEE (30) + Reino Unido y Suiza si se quiere; Cuba no está en Play.

Generar el AAB final:
```
flutter build appbundle --release
# build\app\outputs\bundle\release\app-release.aab
```

---

## 4. Textos listos para pegar

### 4.1 Descripción y contacto
Ver `docs/FICHA_PLAY_STORE.md`. Recordatorio: nada de claims médicos; la app es
de bienestar y los consejos citan fuentes (NHS, OMS, Sleep Foundation).

### 4.2 Health Connect (formulario «Salud»)
- ¿La app accede a datos de salud? **Sí**, solo lectura, con permiso explícito.
- Finalidad: mostrar en la app y en el widget las métricas del propio usuario
  (pasos, pulso, peso, sueño, agua, calorías activas, grasa corporal).
- ¿Se comparten? **No**. ¿Se usan para publicidad? **No**. Todo se procesa en el
  dispositivo; la app no tiene cuentas ni servidores.
- Permisos declarados: `READ_STEPS`, `READ_HEART_RATE`, `READ_WEIGHT`,
  `READ_SLEEP`, `READ_WATER`, `READ_ACTIVE_CALORIES_BURNED`, `READ_BODY_FAT`.
- Justificación por permiso (pegar uno por uno, mismo texto base): «Mostrar al
  usuario su propio dato de <métrica> en la pantalla de progreso y en el widget,
  solo en su dispositivo y solo si concede el permiso; se puede revocar en
  cualquier momento desde Health Connect».
- Enlace a la política de privacidad: el de §1.5.

### 4.3 Servicio en primer plano tipo `health`
- Descripción para Play: «Mantiene actualizado el widget de pasos mientras la
  app está cerrada. Solo se inicia si el usuario coloca el widget y concede el
  permiso de actividad física. Lee únicamente el contador de pasos del teléfono,
  lo guarda en el dispositivo y no transmite nada. Muestra una notificación
  permanente mientras está activo.»
- Guion del vídeo (30–60 s, grabación de pantalla del móvil):
  1. Añadir el widget de FitPulse a la pantalla de inicio.
  2. Abrir la app → aviso de permiso de actividad física → aceptar.
  3. Notificación permanente «Contando tus pasos para el widget».
  4. Cerrar la app, caminar unos pasos y ver el widget actualizado.
  5. Quitar el widget → el servicio y la notificación desaparecen.

### 4.4 Seguridad de los datos
Usar tal cual `docs/DATA_SAFETY.md`. Claves: no se recopila ni comparte nada
salvo el ID de publicidad con AdMob (si hay anuncios y consentimiento); cifrado
en tránsito HTTPS; borrado desde Perfil → Privacidad y datos.

### 4.5 Anuncios
- ¿Contiene anuncios? **Sí** (si se elige la opción A).
- Formato: banner, recompensado (opcional) y app open.
- Consentimiento UMP para EEE/RU; sin consentimiento no hay anuncios
  personalizados.

---

## 5. Monetización: decisión pendiente

| Opción | Qué implica | Recomendación |
|---|---|---|
| **A** | Gratis con anuncios + UMP + «contiene anuncios» | ✅ para el primer lanzamiento |
| **B** | Sin anuncios: `adsEnabled = false` por defecto o quitar AdMob | ✅ la más rápida y sin riesgos |
| **C** | Compra «quitar anuncios» con Play Billing | ❌ hoy «Premium» es un flag local: no se puede presentar como compra |

Hasta elegir, **no** promocionar el Premium como compra en la ficha ni en la app.

---

## 6. Capturas de ficha

- Requisitos: 2–8 por tipo, PNG/JPEG, lado corto ≥ 320 px, lado largo ≤ 3840 px,
  sin marcos de dispositivo ni texto añadido. Teléfono obligatorio; tablet solo si
  se declara compatibilidad (la app no está adaptada a tablet → no declararla).
- Generación: comando de §2 (sin emulador). Revisar que no aparezcan banners de
  prueba, el teclado ni notificaciones personales. El generador desactiva los
  anuncios y usa el perfil de demostración «Ana», así que no expone datos reales.
- Estado actual: las 5 capturas de `docs/store_assets/capturas/` ya incluyen el
  marco del FAB, Consejos con fuentes y la interfaz sin mini-barra de XP
  (regeneradas el 2026-10-30). `cap_lista.png` y `cap_widget_launcher.png` son
  material antiguo que la ficha no usa.

---

## 7. Verificación antes de producción

- [ ] Instalación limpia del AAB (borrar datos) y actualización desde la versión
      anterior conservando el historial.
- [ ] Avisos: agua cada hora, racha a las 20:00, inactividad a los 2 días; sin
      permiso no se programa nada.
- [ ] Health Connect: conceder/revocar permisos y comprobar que sin permiso la UI
      muestra «—», nunca 0 inventado.
- [ ] Widget de pasos y servicio en primer plano (vídeo de §4.3).
- [ ] UMP con IP europea: aceptar, rechazar y cambiar la elección.
- [ ] Accesibilidad: escalado de texto 2.0× sin overflow (tests ya lo cubren).
- [ ] Política de privacidad abre en el navegador desde la ficha y desde la app.

---

## 8. Después de publicar

- Vigilar *Android vitals* (crashes/ANR) y las reseñas.
- Responder reseñas y mantener la política de privacidad al día si cambian
  funciones (p. ej. si algún día hay cuentas o sincronización).
- Guardar el keystore y `key.properties` con copia de seguridad: sin ellos no se
  pueden publicar actualizaciones.
