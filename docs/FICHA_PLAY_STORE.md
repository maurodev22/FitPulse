# Ficha de Google Play — FitPulse (copy listo para copiar/pegar)

**Versión de la app:** 1.0.0+1 · **Actualizado:** 2026-10-07 · Copy auditado
anti-claims (ver `docs/POLITICA_COPY_SALUD.md`): no promete resultados médicos
ni diagnósticos; describe solo funciones reales de la app.

---

## Datos básicos de la ficha

| Campo | Valor sugerido |
|---|---|
| Nombre de la app | **FitPulse** |
| Nombre corto (app label) | **FitPulse** |
| Categoría | Salud y bienestar (fitness) |
| Edad de contenido | **Mayores de 16** (la app bloquea onboarding a menores) |
| Publicidad | **Sí** (AdMob + consentimiento UMP en EEE/Reino Unido; desactivable desde Perfil) |
| Idiomas | Español (principal) · English |
| País/región | Publicar solo desde la entidad legal soportada (lanzamiento global cuando exista) |
| Cuenta de desarrollador | ⚠️ pendiente (entidad fuera de Cuba) |
| Enlace de privacidad | `https://maurodev22.github.io/FitPulse/privacidad/` (tras activar GitHub Pages) |
| Enlace de contacto | Completa cuando exista la entidad (correo de soporte) |

## Descripción corta (máx. 80 caracteres) — Español
> Entrena, come y descansa mejor con datos reales. Sin cuentas ni conexión.

(73 caracteres ✓)

## Descripción corta — English
> Train, eat and rest better with real data. No accounts, works offline.

(67 caracteres ✓)

---

## Descripción larga — Español

**Entrena, come y descansa mejor con datos reales.**

FitPulse es tu cuaderno de entrenamiento y nutrición en el bolsillo: funciona
**100 % en tu dispositivo, sin cuentas y sin conexión**. Nada de servidores, nada
de perfiles online: tus datos son tuyos y se quedan en tu móvil.

**Entrenamientos**
- Rutinas de HIIT, fuerza y movilidad con ejercicios guiados.
- Entrenador de cámara con IA local (ML Kit): corrige tu postura durante el
  ejercicio. El análisis ocurre en tu móvil; la cámara no graba ni sube nada.

**Alimentación**
- Plan diario de comidas con recetas originales (desayuno, comida, merienda y cena).
- Balance nutricional por día: proteínas, carbohidratos, grasas y agua.

**Hábitos y progreso**
- Registro de pasos, sueño y gasto activo (Health Connect opcional, permiso por
  métrica y revocable desde los ajustes del sistema).
- Economía propia de motivación: experiencia, niveles, rachas y retos.
- Widget de progreso y recordatorios que puedes personalizar.
- Accesibilidad cuidada: lectores de pantalla y texto ampliado a 2.0×.

**Privacidad (RGPD)**
- Sin servidores, sin anuncios obligatorios: la publicidad (si actúa) es opcional
  y desactivable desde Perfil.
- Exporta, importa o borra todos tus datos cuando quieras.
- Consentimiento explícito antes de cualquier uso de datos para publicidad en
  el EEE/Reino Unido.

**Aviso de salud:** estos contenidos son orientativos y no sustituyen el consejo
de un profesional de la salud.

## Descripción larga — English

**Train, eat and rest better with real data.**

FitPulse is your training & nutrition notebook in your pocket: it works
**100 % on your device, with no accounts and no connection**. No servers, no
online profiles: your data is yours and stays on your phone.

**Workouts**
- HIIT, strength and mobility routines with guided exercises.
- Camera coach with on-device AI (ML Kit): checks your posture during the
  exercise. The analysis happens on your phone; the camera records or uploads
  nothing.

**Nutrition**
- Daily meal plan with original recipes (breakfast, lunch, snack and dinner).
- Daily nutrition balance: protein, carbs, fat and water.

**Habits & progress**
- Step, sleep and active-burn tracking (optional Health Connect, per-metric
  permission, revocable from system settings).
- Built-in motivation economy: experience, levels, streaks and challenges.
- Progress widget and customizable reminders.
- Accessibility focus: screen readers and 2.0× text scaling.

**Privacy (GDPR)**
- No servers, no mandatory ads: advertising (when present) is optional and can
  be disabled from Profile.
- Export, import or delete all your data whenever you want.
- Explicit consent before any data use for advertising in the EEA/UK.

**Health notice:** these contents are for guidance only and do not replace the
advice of a health professional.

---

## Release notes — v1.0.0 (what's new) — Español

> Primera versión oficial de FitPulse.
> - Entrenamientos: rutinas HIIT/fuerza con ejercicios guiados y entrenador de
>   postura por cámara (IA local).
> - Alimentación: plan diario con recetas originales y balance nutricional.
> - Hábitos: pasos, sueño, agua y gasto activo con Health Connect opcional.
> - Motivación: experiencia, niveles, rachas y retos.
> - Widget de progreso y recordatorios personalizables.
> - Privacidad total: sin cuentas ni servidores; exporta o borra tus datos.

## Release notes — English

> First official release of FitPulse.
> - Workouts: guided HIIT/strength routines and camera posture coach (on-device AI).
> - Nutrition: daily plan with original recipes and nutrition balance.
> - Habits: steps, sleep, water and active burn with optional Health Connect.
> - Motivation: experience, levels, streaks and challenges.
> - Progress widget and customizable reminders.
> - Total privacy: no accounts, no servers; export or delete your data.

---

## Sugerencias al publicar

- **Assets ya generados** en `docs/store_assets/`: `icono_512.png` (512×512) y
  `feature_graphic.png` (1024×500). El icono es un upscale del launcher actual:
  si quieres una versión más nítida, sustituir por un diseño 512 nativo.
- **Capturas de pantalla** (2+ por teléfono y tablet): pendientes, se hacen en el
  Pixel 6a al desbloquear (ver `docs/GUIA_TESTEO_UNIFICADA.md`).
- **IDs de AdMob:** hoy la app usa solo IDs de prueba (ver `docs/ADS_CLIENTE.md`);
  activar los reales con `tools/activar_ids_ads.ps1` antes de publicar.
- **Monetización (decisión pendiente):** opción recomendada = gratis con anuncios
  + UMP. No promocionar "Premium" como compra (hoy es un flag local de prueba).