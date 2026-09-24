# FitPulse — Plan de Evolución por Fases (V6, auditado)

> Documento de gobierno del plan. Fusiona el **PLAN_FITPULSE_CLIENTE.txt (V5)** del
> escritorio con la **auditoría del código** (estado real en `lib/`, `test/` y `android/`,
> revisado el 2026-09-24). Cada fase indica su estado: ✅ completada, 🚧 en curso, ⏳ pendiente.

---

## 0. Estado actual (auditoría)

| Fase | Estado | Notas |
|---|---|---|
| Fase 0 (cimientos + datos premium) | ✅ | Servicios, feature-flags, validaciones, ruedas, IMC en vivo, tipo de cuerpo, EULA, i18n es/en |
| Fase 0.5 (multi-dispositivo + Ayuda + identidad) | ✅ | Anti-overflow 360-411 dp, tarjeta Día ideal, WebP propios, pestaña Ayuda con manual local |
| **Hotfix** (aprobado) | ✅ | Aplicado y verificado en código (sin "Explorar categorías", "Nutrición & Vitalidad", coaches ni "Cerrar sesión"; `**` del manual limpiados) |
| Fase 1 (datos reales del cuerpo) | 🚧 | Pasos reales ✅ (pedometer); pulso/sueño/grasa/hidratación vía **Health Connect** ⏳; reinicio diario ✅; analytics local ✅ |
| Fases 2–8 | ⏳ | Pendientes (ver detalle abajo) |

**Sesión** (`FUNCIONALIDADES.md`) y **guía de prueba manual** (`GUIA_TESTEO_FASE1.md`)
están alineadas con la Fase 1 de pasos. El README aún no refleja que Fases 0 y 0.5 están hechas.

---

## 1. Fase 0 — Cimientos, limpieza y entrada de datos premium ✅

- ✅ Capa de servicios/repositorios y feature-flags (`lib/services/config_service.dart`).
- ✅ Limpieza de datos ficticios: balance 0 kcal/día; onboarding **vacío** sin perfil de
  relleno; pasos/racha desde el estado real.
- ✅ Validaciones: nombre 3-60 (solo letras/espacios), sexo y meta obligatorios,
  edad 16-85, peso 45-300 kg, altura 1,20-2,10 m (`lib/utils/validators.dart`).
- ✅ Ruedas giratorias drum-roll para edad, peso (paso 0,5 kg) y altura
  (`lib/widgets/wheel_number_picker.dart`).
- ✅ IMC en vivo mientras giras las ruedas, con aviso por color por banda, sin bloquear
  la entrada (`_BmiBar` en `registration_screen.dart`).
- ✅ Campo "Tipo de cuerpo" (Ecto/Meso/Endo + combinadas + "No lo sé"→"Normal"),
  informativo y editable desde Perfil (`athlete_profile.dart` / `TipoCuerpo`).
- ✅ Aceptación de Términos y EULA con casilla obligatoria y versionado
  (`eula_screen.dart` + `kEulaVersion`).
- ✅ Idiomas oficiales es/en aplicados en vivo sin reiniciar (`locale_service.dart`).

## 2. Fase 0.5 — Interfaz para cualquier pantalla + Ayuda + identidad ✅

- ✅ Cero desbordes en 360/393/411 dp (tests `test/responsive_test.dart`).
- ✅ Tarjeta "Día ideal" en Inicio (entrenamiento + macros + agua) (`home_screen.dart`).
- ✅ Icono e imágenes de marca en WebP (`assets/images/*.webp`, mipmaps propios).
- ✅ Pestaña "Ayuda" con manual de usuario local sin internet y FAQ
  (`help_screen.dart` + `assets/docs/manual_es.md` / `manual_en.md`).

## 3. Hotfix (aprobado por el cliente) ✅

- ✅ Inicio: eliminada la sección "Explorar categorías".
- ✅ Recetas: encabezado limpio (sin meta ni "Nutrición & Vitalidad").
- ✅ Progreso: "Evolución & Rendimiento" en una línea (FittedBox).
- ✅ Responsividad auditada sin desbordes ni textos partidos (320-411 dp objetivo).
- ✅ Consejos: retirada toda referencia a coaches.
- ✅ Perfil: eliminado el botón "Cerrar sesión" (un único usuario por dispositivo).
- ✅ Ayuda: `**` del manual ya no se muestran como texto literal.
- ➡️ **Acción pendiente (manual):** reinstalar la app en el Pixel 6a desde cero
  (desinstalar + instalar) para asegurar la versión activa con todos los cambios.

## 4. Fase 1 — Datos reales del cuerpo 🚧

**Completado:**
- ✅ Pasos reales del teléfono (`pedometer` + `PhoneStepSource`) con baseline diario y
  re-basificado tras reinicio del equipo.
- ✅ Reinicio diario del balance por fecha (`app_state.dart`).
- ✅ Registro de uso anónimo local (máx. 200 eventos, sin red ni identificadores).
- ✅ Regla "sin datos inventados": pulso/grasa/gasto activo/sueño muestran "—".

**Pendiente:**
- ⏳ Integrar **Health Connect** (`health_connect`): pulso, peso, sueño e hidratación.
  - Cada métrica pide permiso por separado y se puede rechazar.
  - minSdk sube a **26** en `android/app/build.gradle.kts`.
- ⏳ Conectar en UI: Home (pulso), Progreso (grasa, gasto activo, tiempo activo),
  Perfil (cardio semanal).
- ⏳ Criterio de aceptación: `flutter analyze` 0 issues, tests verdes, prueba manual en
  Pixel 6a y Xiaomi con `GUIA_TESTEO_FASE1.md` actualizada a Fase 1 completa.

## 5. Fase 2 — Entrenamientos + motivación adaptativa ⏳

- Entrenamientos reproducibles con reproductor integrado (hoy "Comenzar entrenamiento"
  y tarjetas de sesión no inician nada).
- Racha real de días (hoy el perfil guarda `rachaDias` pero no hay lógica de fechas).
- Retos cortos de 3/5/7 días y puntos/niveles.
- Plan adaptativo: baja intensidad si no cumples 3 días, la sube si cumples 5.

## 6. Fase 3 — Negocio: anuncios en vídeo + Premium + app ligera ⏳

- Anuncios en vídeo (recompensado y descansos) con consentimiento.
- Compra única "Quitar anuncios" de por vida (Premium).
- App ligera: de 148 MB debug a ~28-35 MB instalado.
- Nota: AdMob/Google Play no admiten cuentas con residencia en Cuba. Se dejará el
  código listo con IDs de prueba; cobro y listado requieren entidad fuera de Cuba.
- Ya existe el esqueleto de flags en `ConfigService` (`adsEnabled`, `premiumEnabled`).

## 7. Fase 4 — Comidas ⏳

- Plan semanal de comidas según objetivos y lista de la compra.
- Día "libre" / cheat meal planificado (no cuenta como fallo de racha).

## 8. Fase 5 — Entrenador con cámara ⏳

- La cámara corrige la postura al hacer ejercicio (ML Kit, on-device, sin conexión).

## 9. Fase 6 — Extras de retención ⏳

- Widgets de home screen (pasos, calorías, racha).
- Avisos locales (hidratación, racha en riesgo), cada uno activable/desactivable por
  separado (permiso por tipo).

## 10. Fase 7 — Experiencia premium y accesibilidad ⏳

- Modo oscuro, contraste y tamaño accesibles (EAA/WCAG), micro-animaciones.
- Todos los textos y documentos en es/en (hoy la mayoría del UI está hardcodeada en
  español; `LocaleService` solo cubre parte).

## 11. Fase 8 — Privacidad, legal UE y lanzamiento ⏳

- Exportar/importar datos del móvil con cifrado y borrado total (derecho GDPR).
- Términos, EULA y política de privacidad es/en con cláusulas UE: edad mínima 16
  (consentimiento parental si aplica), devolución 14 días en compras, aviso "app de
  bienestar, no asesoramiento médico", datos de comerciante (cuando exista entidad
  fuera de Cuba).
- Release firmado con clave propia (nunca debug) y publicación en Google Play con la
  ficha Data Safety cumplimentada.

---

## 12. Principios que se mantienen

- Todo funciona en el propio móvil: sin cuentas ni servidores.
- **Nunca** se muestran datos de salud inventados: si no hay fuente real → "—".
- Cada fase se entrega, se prueba en los dos móviles (Pixel 6a + Xiaomi) y se pide
  aprobación antes de continuar.

## 13. Próximos pasos recomendados

1. **Commitear el estado actual** (Fases 0, 0.5 y hotfix ya implementados en código pero
   sin commitear; hay ~20 archivos modificados + nuevos).
2. **Actualizar README** para reflejar el estado real (Fases 0/0.5 ✅, Fase 1 en curso).
3. **Probar la Fase 1 de pasos** siguiendo `GUIA_TESTEO_FASE1.md` (registrar PASA/FALLA
   por dispositivo) y, si acepta, continuar con **Health Connect** en el Pixel 6a.