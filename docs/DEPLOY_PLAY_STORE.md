# Deployment oficial en Google Play — Checklist (Bloque B implementado)

**Estado:** 2026-10-06 · Los puntos ✅ ya están implementados en código/docs; los ⚠️
dependen de cuentas, negocio o verificación física.

## A. Cuentas y negocio (bloqueo estructural — entidad fuera de Cuba)

- [ ] ⚠️ **Cuenta de desarrollador de Play Console** ($25) desde un país soportado.
      Cuba no está soportada; se requiere entidad legal + datos fiscales fuera.
- [ ] ⚠️ **Cuenta AdMob** real + medio de pago internacional.
- [ ] ⚠️ **Mensaje de consentimiento UMP** creado en AdMob → *Privacy & messaging*
      (EEE/Reino Unido) y enlazado al SDK de la app (el código ya lo llama).
- [ ] ⚠️ **Verificación en dispositivo EEE** del flujo UMP con IDs reales.

## B. Código y configuración ✅ (implementado 2026-10-06)

- [x] **Keystore de release propio** generado **fuera del repo**:
      `C:\Users\mauro\fitpulse-keys\fitpulse-release.jks`
      (RSA 2048, 10000 días, alias `fitpulse`). Contraseñas solo en
      `android/key.properties` (gitignored). **Jamás** commitear el .jks ni el
      key.properties.
- [x] **Signing condicional** en `android/app/build.gradle.kts`: si existe
      `android/key.properties` se firma con el keystore de producción; si no
      (clon/CI sin secretos), degrada a firma debug y no rompe el build.
- [x] **AAB firmado** generado con `flutter build appbundle --release` (lista para
      subir a Play App Signing).
- [x] **Target SDK**: compileSdk 36 / targetSdk 36 (Flutter 3.47.3) → cumple el
      requisito de Play 2026 (≥ 35).
- [x] **URL de política de privacidad** lista: `docs/privacidad/index.html`
      (es/en, autocontenida). Publicarla con GitHub Pages:
      habilitar *Settings → Pages → Deploy from branch* (rama `main`, carpeta
      `/docs`) → la URL queda `https://maurodev22.github.io/FitPulse/privacidad/`.
- [x] **Data Safety** cumplimentada: `docs/DATA_SAFETY.md` (respuestas exactas).
- [x] **Auditoría anti-claims (MDR/Health Apps)** hecha: `docs/POLITICA_COPY_SALUD.md`
      (4 textos suavizados, descargos presentes).

## C. Al publicar (con cuenta creada)

- [ ] ⚠️ **IDs de AdMob reales** (hoy solo IDs de prueba):
      - `android/app/src/main/AndroidManifest.xml`: sustituir
        `ca-app-pub-3940256099942544~3347511713` por el ID de app real.
      - Unit IDs de banner/recompensado/app open en `lib/services/ads_service.dart`
        (app open test `ca-app-pub-3940256099942544/9257395921`).
      - Lista completa de sustitución: `docs/ADS_CLIENTE.md`.
- [ ] ⚠️ **Assets de ficha** (no existen hoy): icono 512×512, feature graphic
      1024×500, 2+ capturas de teléfono y tablet (capturas limpias, no las PNGs de
      verificación), vídeo corto opcional, descripción corta/larga es/en.
- [ ] ⚠️ **Decisión de monetización pendiente** (no implementada a propósito):
      - Opción A (recomendada): publicar **gratis con anuncios** y decir en la ficha
        "contiene anuncios" + consentimiento UMP. El toggle "Premium" es local de
        prueba y **no** debe promocionarse como compra.
      - Opción B: sin anuncios (quitar AdMob) y publicar gratis.
      - Opción C: IAP real "quitar anuncios" con **Google Play Billing** (a
        implementar antes de publicar; hoy Premium es un flag local sin cobro).
- [ ] ⚠️ **Ficha de Play**: nombre "FitPulse", categoría Salud y bienestar, edad
      de contenido "Mayores de 16", declaración de publicidad, contacto y país.
- [ ] ⚠️ **Release notes** de la primera versión (es/en) + subida del AAB con
      Play App Signing.
- [ ] ⚠️ **Data Safety final** en consola con los IDs reales (punto 1 ⚠️ de
      `docs/DATA_SAFETY.md`).

## D. Verificación física antes de subir (PASA/FALLA)

- [ ] ⚠️ Pixel 6a (pendiente desbloqueo PIN): suite manual final (`GUIA_TESTEO_UNIFICADA`)
      + verificar **E3** "Hoy · Lv N" del widget de home (cambio nativo).
- [ ] ⚠️ Xiaomi: `uiautomator dump` y flujo UMP.
- [ ] ⚠️ Prueba end-to-end EEE: consentimiento UMP → anuncios (no) personalizados
      con IDs reales; desactivar anuncios desde Perfil.

## E. Salud del proyecto (verde hoy)

- `flutter analyze` 0 issues · `flutter test` 303/303 · accesibilidad 2.0×
- Sin commits de PNGs/`work/`; `android/key.properties` y el .jks fuera del repo.