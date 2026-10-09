# Decisiones pendientes — verificación física (Pixel 6a)

> Guardado el 2026-10-09 (usuario tuvo que salir). Punto de partida para
> retomar mañana. Nada del Pixel se ha desinstalado ni modificado más allá de
> colocar el widget (ver Hallazgo 1).

## Estado resumido

| Ítem | Estado |
|---|---|
| Widget "Hoy · Lv N" colocado en pantalla 1 | ✅ Colocado (ver Hallazgo 1) |
| Verificación física de la burbuja "· Lv N" | 🔴 BLOQUEADO por firma (Hallazgo 3) |
| B9 de `GUIA_TESTEO_UNIFICADA.md` (widget 2×2) | ⚠️ Desfase: el widget real es 4×1 (Hallazgo 2) |
| E3 de `GUIA_TESTEO_UNIFICADA.md` (detalle de receta) | ⚠️ Desfase previo, aún sin decidir (Hallazgo 4) |
| Suite PASA/FALLA del resto de pantallas | 🟡 Parcial (quedó incompleta hasta resolver la firma) |

---

## Hallazgo 1 — Widget colocado en la pantalla 1 ✅

- Se creó automáticamente vía adb: pulsación larga → "Widgets" → búsqueda
  "FitPulse" → drag de la vista previa a la zona libre de la página 1.
- Posición final: banda horizontal `[50,1561][1030,1812]` en el launcher
  (`com.google.android.apps.nexuslauncher`), contenido de `com.fitpulse.app`:
  - `w_titulo` = **FITPULSE**
  - `w_subtitulo` = **Hoy** (sin "· Lv N": el build instalado es anterior, ver H.3)
  - Pasos = 0 · Calorías = **—** · Racha = **0 d**
- Captura provisional: `docs/store_assets/capturas/cap_widget_launcher.png`
  (muestra "Hoy" sin nivel porque el APK del Pixel es del 5-oct; si mañana se
  reinstala el build actual, recapturar con "Hoy · Lv 1").
- El marco de redimensionar se cerró con BACK; el widget quedó fijo.

## Hallazgo 2 — Desfase B9: el widget es una banda 4×1, no 2×2 ⚠️

`GUIA_TESTEO_UNIFICADA.md` (línea ~167) describe "widget de home 2×2 … subtítulo
'Hoy · Lv N'". La realidad:

- `android/app/src/main/res/xml/home_widget_info.xml`:
  `targetCellWidth="4" targetCellHeight="1"`, `minWidth=250dp`, `minHeight=40dp`,
  `resizeMode="horizontal|vertical"`.
- El launcher lo confirma: "4 de ancho por 1 de alto".

**Decisión pendiente (baja):** corregir la guía (banda 4×1) en la próxima
edición de documentación. No requiere cambios de código.

## Hallazgo 3 — 🔴 BLOQUEANTE: firma del APK instalado (build 2001)

Antecedentes verificados:

- APK instalado en el Pixel: `versionName=1.0.0`, `versionCode=2001`,
  `minSdk=26`, `targetSdk=36`, `firstInstallTime=2026-09-25`,
  `lastUpdateTime=2026-10-05 13:08:26`, firma `206a548f` (SHA-256 prefix).
- La burbuja "Lv N" del widget se añadió en `74e4aa9` (2026-10-06) →
  **no está en el build instalado** (5-oct) → imposible verificarla en físico
  sin actualizar la app.
- Se compiló el release actual (`1.0.0+2002`, keystore oficial
  `C:\Users\mauro\fitpulse-keys\fitpulse-release.jks`, creado el 2026-10-06,
  SHA-256 `30c5a58d…`) e `install -r` falla:
  `INSTALL_FAILED_UPDATE_INCOMPATIBLE: signatures do not match`.
- La firma instalada (`206a548f`) no coincide con el keystore oficial
  (`30c5a58d`) ni con `~/.android/debug.keystore` (`2bf10214`). Barrido de
  Desktop/Documents/Downloads/`~/.android`/`~/fitpulse-keys`: no existe copia
  de la clave original en esta máquina.

**Opciones (decisión del usuario, pendiente):**

1. **Desinstalar y reinstalar el build actual (recomendada)** — Autorizar un
   único `adb uninstall` para instalar el release 2002 firmado con el keystore
   oficial (el mismo del AAB de Play). Se pierden en el Pixel: perfil de prueba
   "Mauricio" (75 kg, XP 75, metas, racha 0 d del dev) — datos recargables
   desde la app; **Health Connect no se toca** (lectura independiente). Luego
   se verifica la burbuja "Hoy · Lv 1" en físico y se recoloca el widget en la
   pantalla 1 (ya sabemos el procedimiento).
2. **No tocar el Pixel; verificar por código y tests** — La burbuja se
   sustenta en: snapshot `construirSnapshotWidget` incluye `"nivel"`
   (`lib/state/avisos.dart:84-86`), el bridge envía `nivel: _appState.nivel`
   (`lib/services/home_widget_service.dart:57`), y el provider pinta
   `if (nv > 0) w_subtitulo = "Hoy · Lv $nv"` (`HomeWidgetProvider.kt:52-55`).
   La verificación física de la burbuja queda pendiente hasta un dispositivo
   con build actual.
3. **Seguir buscando la clave original** — USB/otras máquinas/nube, por si
   existe el keystore que firmó el build 2001. Probable (no: el barrido local
   no encontró nada).

## Hallazgo 4 — Desfase E3 (previo, sigue pendiente)

`GUIA_TESTEO_UNIFICADA.md` (líneas ~273-277) describe un "detalle de receta"
(ingredientes + pasos + tiempo + aviso) que **no existe** en la app:

- `lib/screens/recipes_screen.dart`: las tarjetas solo abren favorito y
  "Registrar balance". Ningún `Navigator.push` va a detalle de receta.
- `lib/state/recipe_model.dart`: `Recipe` no tiene campo `pasos`;
  `ingredientes` solo se usa en `lib/state/meal_plan.dart` (lista de la compra).

**Decisión pendiente:** corregir la guía (E3 = "Lista de la compra del plan
semanal") o implementar la pantalla de detalle de receta.

---

## Comandos útiles para retomar mañana

```powershell
$s = "adb-2B181JEGR15535-eA2EZ5._adb-tls-connect._tcp"   # serial TLS/WiFi
# Verificar foreground ANTES de tocar (Facebook suele robarse los taps):
adb -s $s shell "dumpsys activity activities | grep topResumedActivity"
# Dump fiable del UI:
adb -s $s shell "uiautomator dump /sdcard/window_dump.xml >/dev/null 2>&1"
adb -s $s pull /sdcard/window_dump.xml C:\Users\mauro\AppData\Local\Temp\opencode\w.xml
# (reformatear con .Replace('<node', "`n<node") antes de leer)
# Captura: adb -s $s shell screencap -p /sdcard/x.png  +  adb pull
```

## Enlace rápido

- Guía de testeo: `docs/GUIA_TESTEO_UNIFICADA.md` (B9 ~línea 167, E3 ~273).
- Widget nativo: `lib/services/home_widget_service.dart`,
  `lib/state/avisos.dart` (`construirSnapshotWidget`),
  `android/.../HomeWidgetProvider.kt`, `home_widget_info.xml`.