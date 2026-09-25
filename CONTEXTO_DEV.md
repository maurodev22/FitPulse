# Contexto de desarrollo — FitPulse

> Uso: si se pierde la sesión de chat o se abre una sesión nueva, leer este
> archivo + `PLAN.md` y `GUIA_TESTEO_FASE1.md` para retomar con todo el contexto.
> Última actualización: 2026-09-25 (commit `fd9d573`).

## Estado actual (resumen)

- **Fases 1–7 completadas y verificadas**: app 100 % local, i18n es/en, modo
  oscuro, contraste WCAG AA, texto 2.0× sin overflow. `flutter analyze` 0 issues;
  suite 55/55 aprobada (antes de Fase 8).
- **Fase 8 (en curso)**: 8.1 export/import/borrado GDPR ✅, 8.2 política de
  privacidad + EULA v2 ✅, 8.4 aviso de IA ✅. Pendiente: 8.3 UMP (publicidad UE)
  y 8.5 firma propia (keystore + `.aab`). Tests nuevos: 7 backup + 2 privacy
  (≈64 total esperados). **Pendiente: correr la suite completa tras el último
  commit.**
- **Pendientes de verificación en móvil**: instalación y PASA/FALLA manual del
  usuario (F4–F7 + F8) en `GUIA_TESTEO_FASE1.md`; Xiaomi Redmi 8A aún sin
  instalar la última build.

## Cómo retomar

1. Leer `PLAN.md` (roadmap + Fase 8 con matriz regulatoria UE y próximos pasos).
2. Leer este archivo para el contexto de entorno y reglas de código.
3. `GUIA_TESTEO_FASE1.md` para el plan de prueba manual (tabla PASA/FALLA).
4. Estado de las pantallas/docs: `FUNCIONALIDADES.md`, `README.md`.

## Reglas de código (importantes)

- **`AppColors`** son getters que delegan en `AppColors.active` (paleta mutable);
  el `builder` de `MaterialApp` fija la paleta. En contextos `const`, borrar
  `const` (legal y suficiente). Nunca usar AppColors en const.
- **i18n**: ES **verbatim** (los tests buscan ES por defecto); EN nuevo. Valores
  de datos (metas/sexo/nivel/categorías/días) se traducen SOLO en su
  visualización con mapeos (`metaName`, `sexoName`, `nivelName`, `imcNombre`,
  `recetaCategoria`, `tipsCategoria`, `diaNombre`, `favNombre`…).
- **Prohibido reescribir archivos con acentos vía consola**
  (`Set-Content -Encoding UTF8` corrompe). Usar las herramientas de edición.
- **Nunca mostrar datos de salud inventados**: si no hay fuente real, mostrar
  "—". Health Connect = métricas reales con permiso individual.
- **AdMob/Play**: solo IDs de prueba (residencia en Cuba). Sin cuenta de
  desarrollador de Play desde Cuba (bloqueo estructural → publicación requiere
  entidad/fiscal fuera de Cuba).
- EULA con versión (`kEulaVersion = 2`): si cambia, se vuelve a pedir aceptación.

## Entorno (Windows + PowerShell 5.1)

- PowerShell 5.1 **no acepta `&&`**. Encadenar con `;` o comandos separados.
- **Redirigir binarios con `>` corrompe** (p. ej. screencap). Para capturas:
  `adb shell screencap -p /sdcard/x.png` + `adb pull /sdcard/x.png .`.
- **stderr del mirror de China → exit code 1** aunque `flutter analyze`/`test`
  pasen ("No issues found!"). Leer la salida, no el exit code.
- Gradle: mirrors Maven Aliyun vía `C:\Users\mauro\.gradle\init.gradle`;
  `desugar_jdk_libs` solo disponible en `/repository/google`.
- `flutter pub get` tarda y a veces da socket errors transitorios → reintentar;
  `share_plus` quedó en **13.3.0** por conflicto de `win32` con `health`/`device_info_plus`.
- Build release Android: `flutter build apk --release` tarda ~540 s.

## ADB WiFi (los pares caen al bloquear la pantalla)

- Pixel 6a: `adb -s adb-2B181JEGR15535-eA2EZ5._adb-tls-connect._tcp ...`
- Xiaomi Redmi 8A: `adb -s adb-LZUSWG59AYBYW4ZD-MwpCLa._adb-tls-connect._tcp ...`
  (una vez resolvió a `192.168.1.106:33087`).
- Para re-conectar: desbloquear el móvil, rehacer `adb pair` + `adb connect` con
  el código que muestra la app **Wireless debugging** (Ajustes → Opciones de
  desarrollador).
- Instalación: `adb -s <serie> install -r build/app/outputs/flutter-apk/app-release.apk`.

## Qué probar manualmente (breve; ver GUIA para el detalle)

- F1–F3: sensor de pasos, Health Connect (permiso por métrica), anuncios de
  prueba + premium (nunca datos inventados).
- F4–F7: workouts + modo oscuro + contraste AA + i18n es/en + texto 2.0×.
- F8: Perfil → "Privacidad y datos": exportar (share-sheet), importar (lista de
  backups), política de privacidad es/en, y borrar todo (doble confirmación →
  vuelve al EULA/onboarding).

## Referencia

- Repo: https://github.com/maurodev22/FitPulse (rama `main`).
- Commit con la Fase 8 de privacidad: `fd9d573`.