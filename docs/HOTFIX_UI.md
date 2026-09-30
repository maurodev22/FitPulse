# Hotfix UI — Correcciones percibidas tras la revisión del 30/09

Plan aprobado por el usuario el 30/09/2026 (opción "Sí, plan y código").
Cubre 7 puntos reportados + 1 bug latente encontrado en la auditoría.

---

## Evidencia por ítem

| # | Reporte del usuario | Evidencia en código |
|---|---|---|
| P1 | Home → "Resumen de hoy" → "Ver detalles" no hace nada | `home_screen.dart:58-61` — `SectionHeader(actionLabel: homeVerDetalles)` **sin `onAction`**; el `InkWell` de `common.dart:216` queda con `onTap: null`. |
| P2 | Progreso → Semanal/Mensual/Año "no filtran" | El filtro **sí existe** (`progress_screen.dart:74-79`, `resumenPeriodo` con `_diasPeriodo`, gráfico de peso con `_semanasPeso`). Con los 3 registros actuales (todos en los últimos 7 días) las cifras salen **idénticas** en las 3 ventanas → percepción de "no hace nada". |
| P3 | Insignias y logros → pasarlas a Perfil | `progress_screen.dart:197-199` + `_buildInsignias` (:924-1068). Perfil no tiene esa sección. |
| P4 | Consejos/Tips: nada tiene funcionalidad real | `tips_screen.dart`: buscador es `Container` decorativo (:159-182, ni `TextField`), `tune` decorativo (:184-193), `_CategoryPill` sin `onTap` (:219-256), "Leer artículo" y bookmark decorativos (:332-349), "Ver todos (18)" número falso (:539), `_TipCard`/artículos sin `onTap`. |
| P5 | Racha: agrandar + quitar 🔥 (mostrar solo desde el día 7) | 🔥 en 5 lugares: `home 234`, `profile 933` y `1067`, `progress 1046`, `tips 86`. Todos `fontSize: 14` con `rachaDias(n)` o `pfRachaEnRacha(n)`. |
| P6 | Perfil → editar "Metas de actividad" | `profile_screen.dart:148` — `_IconAction(icon: Icons.edit)` es un `Container` **sin `onTap`** (:1244-1261). `actualizarMetas({calorias, pasos})` ya existe en `app_state.dart:598`. |
| P7 | Perfil → engranaje "Configuración próximamente" | `profile_screen.dart:943-954` — solo SnackBar `pfConfiguracionProx`. Ya existen bloques funcionales: Preferencias (:512), Tema (:566), Idioma (:608), Privacidad y datos (:642), Conectar Salud (:280). |
| BUG | **Latente**: `_guardarCambios` resetea metas/foto | `profile_screen.dart:866-886` reconstruye `AthleteProfile` **sin `pasosMeta`, `caloriasMeta`, `fotoBase64`** → al guardar desde Perfil vuelven a `10000`/`2100`/`null`. `_copyProfile` (`app_state.dart:753`) sí los preserva. |

---

## Cambios por ítem

### P1 — "Ver detalles" abre el detalle real del día
- `home_screen.dart`: pasar `onAction` al `SectionHeader` que abre un **bottom sheet** con datos reales del día: pasos vs meta, kcal consumidas vs meta, pulso (si permiso HC) y aviso orientativo honesto (sin inventar valores).
- Reutilizar strings existentes (`homePasos`, `homeCalorias`, `homePulso`, `homeMetaKcal`, `homeOrientativo`).

### P2 — El período se muestra con contexto visible
- `progress_screen.dart`: añadir etiqueta de ventana al resumen del período (p. ej. "Últimos 7 días") con string nuevo `prVentana(int dias)`, para que el cambio de opción sea perceptible incluso cuando las cifras coinciden (datos reales, nunca inventados).
- Mantener la lógica real de `resumenPeriodo` y `_semanasPeso`.

### P3 — Insignias & Logros se mudan a Perfil
- Mover `_buildInsignias` (catálogo completo) de `progress_screen.dart` a `profile_screen.dart`, colocada bajo "Metas de actividad". Quitar de Progreso.
- Actualizar `test/widget_test.dart:108-110` (buscar "Insignias & Logros" en la pestaña Perfil, no en Progreso).

### P4 — Consejos/Tips funcionales (con catálogo real)
- `TipsScreen` pasa a `StatefulWidget` con estado de búsqueda + categoría.
- Búsqueda: `TextField` real que filtra por título/cuerpo del catálogo.
- Pills de categoría: tappables, con estado seleccionado; las categorías se derivan del catálogo real (Nutrición, Recuperación, Fuerza, Bienestar) + "Todos". Añadir `Fuerza`/`Bienestar` a `tipsCategoria`.
- "Leer artículo completo" y tarjetas abren una pantalla de detalle del artículo (nueva `ArticuloDetalleScreen`) con contenido real existente.
- "Ver todos (N)": N real = nº de artículos del catálogo (4), no 18. Navega a lista completa filtrable.
- `_TipCard` y `_CategoryPill`: se mantiene el estilo (test `tips_pill_test.dart` sigue verde: "Todos" usa `onPrimary`).

### P5 — Widget compartido de racha
- Nuevo `lib/widgets/racha_chip.dart`: `RachaChip` — muestra 🔥 **solo si `racha >= 7`**, con tamaño un poco mayor (padding + `fontSize` 16) y `rachaDias(n)`.
- Reemplazar los 5 usos: Home header, Perfil header, Perfil hero (`pfRachaEnRacha`), Progreso header, Consejos header.

### P6 — Editar metas de actividad
- `profile_screen.dart`: `_IconAction` gana `onTap` opcional; el ✏️ de "Metas de actividad" abre un diálogo para editar **pasos diarios y calorías diarias**, validando valores, persistido vía `actualizarMetas`.
- **Fix bug latente**: `_guardarCambios` debe incluir `pasosMeta`, `caloriasMeta` y `fotoBase64` del perfil actual.

### P7 — Configuración funcional
- Nueva `lib/screens/configuracion_screen.dart` accesible desde el engranaje de Perfil: Preferencias, Tema (modo claro/oscuro/sistema), Idioma, Permisos y datos de salud (Health Connect), Privacidad y datos, y botón "Guardar cambios".
- Extraer widgets compartidos a `lib/widgets/settings_widgets.dart` (`SettingsCard`, `SettingsCardTitle`, `IconActionButton`, `ToggleRow`, `FilaAccion`, `PermisoChip`) para no duplicar el código de Perfil.
- Perfil conserva: Hero, Metas de actividad (con edición P6), Premium, Datos personales, Insignias (P3) y Guardar.

---

## Criterios de aceptación
1. `flutter analyze` sin issues y `flutter test` 100 % verde (ajustando los tests tocados: P3, P4 si aplica).
2. Tema oscuro e idioma español intactos tras las pruebas (no mover preferencias).
3. Datos de salud reales: no se inventan valores (P1/P2 muestran lo que hay, con estados vacíos honestos).
4. 🔥 solo visible con racha ≥ 7 días (P5).
5. `_guardarCambios` y `actualizarMetas` persisten pasos/calorías/foto (fix bug latente).

## Registro de ejecución
- [x] P1 Ver detalles (bottom sheet)
- [x] P2 Ventana visible en Progreso
- [x] P3 Insignias a Perfil
- [x] P4 Consejos funcionales
- [x] P5 RachaChip
- [x] P6 Editar metas + fix `_guardarCambios`
- [x] P7 Configuración
- [x] Tests + analyze verdes

Resultado: `flutter analyze` 0 issues · `flutter test` 112/112 en verde
(incluye `test/hotfix_test.dart` nuevo con cobertura de P1 y P4).
- [x] Commit local (sin push)