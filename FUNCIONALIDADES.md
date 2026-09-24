# FitPulse — Funcionalidades: presentes vs. pendientes

Documento de control que contrasta el diseño de referencia (Google Stitch, 8 pantallas)
contra el estado real de la implementación Flutter. Actualizado tras la revisión del
funcionamiento de sesión persistida, Recetas, Progreso y Consejos.

## Funcionalidades presentes (funcionales)

| # | Funcionalidad | Pantalla / Archivo | Detalle |
|---|---|---|---|
| 1 | Onboarding de registro | `RegistrationScreen` | Formulario completo (nombre, edad, sexo, peso, altura, meta). IMC calculado en vivo sobre el formulario. Guarda la sesión del atleta en el dispositivo. |
| 2 | Sesión persistente por dispositivo | `AppState` (`lib/state/app_state.dart`) | Perfil, balance nutricional, favoritos y metas se guardan con `shared_preferences`. Al reabrir la app el usuario vuelve directo al dashboard. Al cerrar sesión se borran todos los datos del dispositivo. |
| 3 | Dashboard / Home | `HomeScreen` | Saludo personalizado ("Hola, {nombre}"), tarjetas de pasos (formato 8,450 con separador de miles corregido), calorías, pulso, entrenamiento recomendado y categorías filtrables. |
| 4 | Recetas nutricionales | `RecipesScreen` + `RecetasCatalogScreen` | Búsqueda por texto, filtros por categoría (Alta Proteína / Low Carb / Pre-entreno / Smoothies), receta destacada, opciones rápidas, favoritos y catálogo completo. |
| 5 | Registro de consumo | `registrarConsumo` (AppState) | Al pulsar "Registrar en mi balance" se suman calorías y macros al balance del día persistido. |
| 6 | Progreso y Rendimiento | `ProgressScreen` | Peso corporal (dinámico según el perfil), IMC en vivo, gasto activo, gráfico semanal, sesiones recientes e insignias. Responde a las métricas del atleta guardado. |
| 7 | Consejos y Bienestar | `TipsScreen` | Plan personalizado según la meta del atleta, tips de alto impacto, artículos recomendados y comunidad activa. |
| 8 | Perfil y ajustes | `ProfileScreen` | Datos personales, IMC calculado, nivel, preferencias, días de entrenamiento editables, "Guardar cambios" (persiste) y "Cerrar sesión" (vuelve al onboarding **sin borrar** datos: un solo usuario por dispositivo). |
| 9 | Navegación de 6 pestañas | `FitNavBar` (`lib/widgets/fit_nav_bar.dart`) | Inicio, Recetas, Progreso, Consejos, Perfil y Ayuda. |
| 10 | Diseño y tema | `theme.dart` + `common.dart` | Sistema de colores Material 3 verde y tipografías Plus Jakarta Sans / Inter. `SectionHeader` unificado con parámetro `uppercase`. |
| 11 | Android con identidad propia | `android/` | Namespace e ID de paquete `com.fitpulse.app`, `MainActivity` movido a `kotlin/com/fitpulse/app/`. |
| 12 | Tests de widget | `test/widget_test.dart` | Cubren onboarding, dashboard, cada pestaña, perfil y cierre de sesión (con `shared_preferences` simulado). |
| 13 | Documentación | `README.md` | Guía del proyecto con estructura, arquitectura y decisiones. |

## Funcionalidades pendientes / ausentes

| # | Funcionalidad | Estado | Sugerencia |
|---|---|---|---|
| 1 | Subida real de foto de perfil | Ornamental | Integrar `image_picker` y persistir el path en `AthleteProfile`. |
| 2 | Registro/Inicio con backend | Ausente | No hay cuenta ni servidor; la sesión es 100% local como se acordó (entorno dev por dispositivo móvil). |
| 3 | Datos de pulso/HealthKit reales | Placeholder | Los valores de pulso, oximetría y HealthKit son estáticos; integrar sensores/HealthKit. |
| 4 | Seguimiento real de pasos | Placeholder | `8450/10000` es fijo; usar pedómetro nativo para alimentar `pasos`. |
| 5 | Entrenamientos reproducibles | Botones sin acción | "Comenzar entrenamiento" y tarjetas de sesión no inician nada aún. |
| 6 | Volumen de sesiones e insignias | Estático | Sesiones recientes e insignias son catálogo fijo en `ProgressScreen`; falta lógica de fechas/recompensas. |
| 7 | Consulta a coaches | SnackBar informativo | El botón "Hacer una consulta" solo muestra un aviso; falta pantalla de chat. |
| 8 | Lectura de artículos de consejos | Placeholder | Los artículos/tips son decorativos; falta contenido real y persistencia de favoritos de consejos. |
| 9 | Cambio de foto / avatar | Placeholder | Edición de foto muestra SnackBar "próximamente". |
| 10 | Alertas reales de hidratación | Placeholder | Los toggles de preferencias son visuales; no programan notificaciones. |
| 11 | sincronización con smartwatch | Placeholder | El toggle HealthKit no conecta con el sistema. |
| 12 | Compartir actividad | Placeholder | Solo un toggle visual. |
| 13 | Pantalla "Ver detalles"/gráficos | Sin navegación | Enlaces tipo "Ver detalles", "Ver plan", "Ver todo (18)" no implementan destinos. |
| 14 | Cambio de idioma / localización | Ausente | Todo el texto está hardcodeado en español. |
| 15 | Modo oscuro | Ausente | El tema sólo define modo claro. |
| 16 | Persistencia diaria del balance | Parcial | El balance se acumula sin reinicio por día calendario. |

## Decisiones registradas

- **Sesión local por dispositivo**: en línea con la petición de mantener los datos de
  inicio de sesión de forma persistente en el móvil (entorno de producción dev), se usa
  `shared_preferences` (almacenamiento seguro por app en el dispositivo).
- **Estructura comentada**: los archivos de `lib/` llevan documentación en español por
  archivo, clase y método clave.
- **Nombre de paquete**: `com.fitpulse.app` (build 1, versión 1.0.0).