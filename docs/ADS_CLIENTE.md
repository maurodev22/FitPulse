# ADS_CLIENTE — Checklist para producción (cuenta AdMob fuera de Cuba)

> Documento de entrega. La app hoy usa **solo IDs de PRUEBA oficiales de Google**
> (residencia del desarrollador: Cuba → AdMob/Play no acepta cuentas). Cuando exista
> la cuenta AdMob del cliente (fuera de Cuba), sustituir los puntos de abajo y la app
> queda lista para anuncios reales con consentimiento UE (UMP) ya integrado.

## 1. Sustituir IDs de prueba → reales

| Formato | ID de prueba (actual) | Ubicación en el código |
|---|---|---|
| Banner | `ca-app-pub-3940256099942544/6300978111` | `lib/services/ads_service.dart` → `kAdmobBannerTestId` |
| Recompensado | `ca-app-pub-3940256099942544/5224354917` | `lib/services/ads_service.dart` → `kAdmobRewardedTestId` |
| App Open | `ca-app-pub-3940256099942544/9257395921` | `lib/services/ads_service.dart` → `kAdmobAppOpenTestId` |
| APP_ID | `ca-app-pub-3940256099942544~3347511713` | `android/app/src/main/AndroidManifest.xml` → `com.google.android.gms.ads.APPLICATION_ID` |

Pasos en la consola AdMob: Apps → +Nueva app → creador de bloques
(`Banner`, `Interstitial` — **no usado en FitPulse**, `Rewarded`, `App open`).
Copiar cada `ca-app-pub-…/…` sobre la constante correspondiente.

## 2. Mensaje de consentimiento UMP (obligatorio para UE/EEE/Reino Unido)

- Consola AdMob → **Privacidad y mensajes** → Configuración de consentimiento (GDPR).
- Crear mensaje. Configurar opciones **"Consentimiento"** (sí a personalizados +
  elegir no personalizados) — el SDK UMP ya integrado (`fitpulse/consent` nativo)
  mostrará el formulario automáticamente la primera vez en región EEE.
- En la app no hace falta nada más: `ConsentService.iniciar()` se llama en `main()`
  y, si el estado es `REQUIRED`, se muestra el formulario una única vez.

## 3. Firma y publicación (8.5)

- Keystore propio fuera del repo + `app-release.aab` con Play App Signing.
- Ficha **Data Safety**: datos 100 % locales (excepto anuncios opcionales, que no
  incluyen datos de salud), sin servidores, cifrado no aplicable fuera del
  dispositivo, compartición solo si el usuario exporta su backup manualmente.

## 4. Qué probar con IDs reales (verificación final)

- [ ] EULA → Perfil: banner inferior visible al habilitar anuncios (sin Premium).
- [ ] Progreso: tarjeta recompensada "+25 PTs" (1×/día) muestra el anuncio y suma.
- [ ] App Open: al volver de segundo plano tras ≥30 s (una vez por sesión, ninguno
      sobre el reproductor de ejercicios ni en arranque frío).
- [ ] UE/EEE: primer arranque muestra el formulario UMP; sin consentimiento no se
      cargan anuncios; con "no personalizados" se muestran posteriores.
- [ ] Eliminar Premium → vuelven los anuncios; activar Premium → desaparecen.
- [ ] Sin red a Google (p. ej. Cuba): la app no crashea y no muestra anuncios reales
      (degradado honesto; el banner y el recompensado muestran las piezas de prueba
      locales; desde el dispositivo del cliente con IDs reales se ven anuncios reales).

## 5. Vista previa de prueba automática (comportamiento acordado)

La app decide sola si mostrar **anuncios reales** o **piezas de prueba**:

- Si el consentimiento UMP **se resuelve** (cliente fuera de Cuba con IDs reales y
  red a Google) → `vistaPreviaTest = false` → **anuncios reales** (banner,
  recompensado y app open).
- Si el consentimiento **falla por red** (Cuba / sin Google) → `vistaPreviaTest =
  true` → el banner muestra una pieza local "Anuncio de PRUEBA" y el recompensado
  simula el video con una pieza de imagen/texto; al cerrarla se otorga el +25 PTs
  de prueba. Todo claramente marcado, nunca se confunde con publicidad real.

No hace falta tocar código: se ajusta solo en `main()` según `consent.errorTecnico`.
Si en algún test manual quieres ver siempre las piezas reales de AdMob, pon
`AdsPermiso.vistaPreviaTest = false` de forma forzada en `main()`.

## 6. Recordatorios regulatorios

- **CERO interstitials** en FitPulse (decisión de producto: no interrumpir).
- Nunca más de un banner a la vez (shell o reproductor, nunca ambos).
- El EULA v2 ya declara publicidad de terceros, consentimiento UE y datos del
  comerciante (8.2).