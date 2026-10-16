# Decisiones pendientes — verificación física (Pixel 6a)

> Última actualización: 2026-10-16. Hecho: rediseño del widget (agua/BPM,
> sin nivel/calorías) + servicio en primer plano para pasos en tiempo real.
> Pendiente: re-verificar en el Pixel el fix de baseline (2004), suite
> PASA/FALLA, y declarar el servicio en Data Safety/políticas de Play.

## Decisiones tomadas (2026-10-15)

1. **Firma del Pixel → Opción 1 (desinstalar y reinstalar).** Autorizado un
   único `adb uninstall`; se instaló el release actual `versionCode 2002`
   firmado con el keystore oficial. ✅ Hecho: el Pixel corre el build actual.
2. **E3 → Corregir la guía** (no se implementa ficha de receta). ✅ Hecho:
   `GUIA_TESTEO_UNIFICADA.md` reescrito (E3 = ingredientes en la lista de la
   compra del plan + aviso orientativo de recetas). De paso se corrigió B9 y
   las referencias "widget 2×2" → "banda 4×1" en los demás docs.

Commit del lote de docs: `17b6db0` (push recuperado tras fallo de red puntual).

## Decisiones tomadas (2026-10-16)

3. **Rediseño del widget 4×1** (petición del usuario): agua de hoy + Pasos /
   BPM / Racha; `nivel` y `calorias` eliminados del snapshot. ✅ Hecho
   (`versionCode 2003`, verificado en el Pixel: "AGUA HOY / — / Pasos 0 /
   BPM — / Racha 0 d").
4. **Pasos en tiempo real — "Servicio en primer plano (realtime total)"**
   (elegido por el usuario entre las opciones): ✅ implementado con
   `StepWidgetService` (`versionCode 2004`). **Limitación conocida:** no
   arranca con BOOT_COMPLETED — tras un reinicio los pasos se recalibran al
   abrir la app. **Obligación Play:** declarar el servicio en primer plano
   tipo `health` en Data Safety/políticas.

---

## Estado actual de la verificación física

| Ítem | Estado |
|---|---|
| Build actual (2002, keystore oficial) en el Pixel | ✅ Instalado (2026-10-15) |
| Perfil / sesión iniciada | ✅ El usuario recreó el perfil en el dispositivo (IMC 19.5, meta 10,000 pasos) |
| Widget en pantalla 1 | ✅ Colocado y verificado (2026-10-15, layout nuevo) |
| Widget rediseñado (agua/BPM/pasos, v2004) | 🔄 Pendiente: verificar que app y widget muestran los MISMOS pasos (fix de baseline) |
| Suite PASA/FALLA (tab Ayuda / Fase H) | ⏳ Pendiente |
| Capturas de ficha | ⚠️ Revisar: los datos del perfil cambiaron (IMC 19.5, meta 10,000) → capturas previas de Perfil/Home pueden estar desfasadas |
| AdMob real / cuentas Play ($25) | 🔴 Bloqueo estructural (desde Cuba) |
| GitHub Pages para `docs/privacidad/` | 🟡 Sin decidir |

## Por qué quedó en pausa hoy

La pantalla del Pixel se **bloqueó con PIN** a mitad de la sesión (el teléfono
lo está usando su dueño). Sin desbloquearlo no se puede:
- Colocar el widget (pulsación larga en el launcher).
- Verificar el widget rediseñado (agua/BPM/pasos; la burbuja "Hoy · Lv N"
  ya no existe) y que app y widget muestran los mismos pasos.
- Recorrer el tab **Ayuda** (Fase H) y completar el PASA/FALLA.
- (Opcional) recapturar pantallas con los datos nuevos.

**Acción para retomar:** desbloquear el Pixel y dejarlo despierto; luego seguir
con el procedimiento de abajo.

---

## Procedimiento para re-colocar el widget (ya probado)

```powershell
$s = "adb-2B181JEGR15535-eA2EZ5._adb-tls-connect._tcp"   # serial TLS/WiFi
# 1) Ir a la pagina 1 del launcher (marcador: content-desc "Pantalla principal")
adb -s $s shell input keyevent KEYCODE_HOME
# 2) Pulsacion larga en zona vacia -> menu del launcher
adb -s $s shell input swipe 540 1500 540 1500 900
# 3) Tocar "Widgets" (ver bounds en el dump)
# 4) Tocar el campo Buscar (540,448) + input text "FitPulse"
# 5) Tocar el resultado (540,696) -> aparece widget_preview [37,843][1043,1094]
# 6) Arrastrar: DOWN 540 968 -> hold 2s -> MOVE -> UP 540 1500 (con motionevent)
# 7) BACK para cerrar el marco de redimensionar; re-dump y comprobar
#    w_titulo == "AGUA HOY", w_subtitulo == litros reales ("N.N L" o "—"),
#    w_pasos == pasos de la app y w_bpm == pulso real o "—"
#    (el widget ya NO muestra nivel ni calorias)
```

Notas:
- Dump fiable: `uiautomator dump` + `adb pull` + reformatear con
  `.Replace('<node', "`n<node")`. El texto de Flutter aparece en **content-desc**.
- Comprobar SIEMPRE `topResumedActivity` antes de tocar: las notificaciones
  (WhatsApp/Facebook/Instagram) se roban los taps.
- Capturar: `adb shell screencap -p /sdcard/x.png` + `adb pull`.

## Notas de la sesión (evidencia)

- Desinstalación: `adb uninstall com.fitpulse.app` → `Success`.
- Instalación: `adb install -r app-release.apk` → `Success`, `versionCode=2002`,
  `lastUpdateTime=2026-10-15 10:07:19`.
- Permisos re-concedidos: `POST_NOTIFICATIONS`, `ACTIVITY_RECOGNITION` y los
  `health.*` (READ_STEPS/HEART_RATE/WEIGHT/SLEEP/WATER/ACTIVE_CALORIES_BURNED/
  BODY_FAT).
- El snapshot del widget ya NO incluye `nivel` ni `calorias` (rediseño
  2026-10-16): lleva `{fecha, pasos, agua, bpm, racha}`; el layout pinta
  "AGUA HOY" + litros y las columnas Pasos/BPM/Racha. `versionCode 2004`
  instalado con `install -r` (firma oficial, sin desinstalar).

## Referencias

- Guía de testeo: `docs/GUIA_TESTEO_UNIFICADA.md` (B9 ~línea 163,
  checklist ~línea 562).
- Widget: `lib/services/home_widget_service.dart`, `lib/state/avisos.dart`,
  `android/.../HomeWidgetProvider.kt`, `home_widget_info.xml`.
