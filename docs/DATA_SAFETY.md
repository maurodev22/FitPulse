# Data Safety — Cumplimentación para Google Play Console

Respuestas exactas para el formulario **App content → Data safety** de Play Console,
según el comportamiento REAL de la app (auditado en código, 2026-10-06).
Las filas marcadas con ⚠️ dependen de la publicación real (IDs de AdMob) y se
confirman al crear la cuenta.

## 1. Tipo de datos recopilados

| Dato | ¿Se recopila? | ¿Se comparte? | Secreto |
|---|---|---|---|
| Ubicación aproximada | No | — | — |
| Ubicación exacta | No | — | — |
| Nombre | **Sí** (local: perfil del atleta) | No | No |
| Dirección de correo | No | — | — |
| Identificadores de usuario | No | — | — |
| ID de publicidad | **Sí** (solo si el usuario habilita anuncios y hay consentimiento) | Se comparte con Google AdMob | Sí |
| Datos de compra | No | — | — |
| Información financiera | No | — | — |
| Historial de salud | **Sí** (local: pasos, pulso, peso, sueño vía Health Connect, solo con permiso) | No | No |
| Mensajes | No | — | — |
| Fotos | No | — | — |
| Videos | No | — | — |
| Audio | No | — | — |
| Archivos | No | — | — |
| Actividad en la app | **Sí** (local: sesiones, rachas, XP; analytics local sin red) | No | — |
| Navegación web | No | — | — |
| Rendimiento de la app | No | — | — |
| Diagnóstico | No | — | — |
| Actividad física | **Sí** (local: sesiones de entrenamiento) | No | — |

> ⚠️ **ID de publicidad:** hoy la app usa solo IDs de prueba de AdMob y no muestra
> anuncios reales (sin cuenta AdMob). Al publicar con IDs reales, marcar
> **"ID de publicidad — compartido con Google AdMob"** como partícipe en la
> monetización. Si se publica la versión sin anuncios (Premium por defecto), marcar "No".

## 2. Transmisión / cifrado

- **Todas las respuestas del paso 1 se envían del dispositivo a otros
  servidores o empresas:** **No** (salvo el ID de publicidad → AdMob si hay anuncios).
- **Cifrado en tránsito:** Sí (HTTPS/TLS en la única conexión a red, AdMob).
- **Borrado programático:** Sí — "Borrar todos mis datos" (Perfil → Privacidad y
  datos) limpia todo el almacén local (`shared_preferences.clear()`).

## 3. Prácticas de datos

- **Minimización:** la app solo guarda lo que el usuario introduce o lo que Health
  Connect entrega bajo permiso explícito.
- **Sin venta de datos:** No se vende ninguna categoría de datos.
- **Sin finalidades de publicidad para datos de salud:** los datos de salud nunca se
  usan para publicidad. El consentimiento publicitario es independiente (UMP) y el
  usuario puede desactivar los anuncios desde Perfil.

## 4. Política de apps de salud de Google (Health apps policy)

Checklist para el formulario:
- [x] La app **no** pertenece a las categorías restringidas (no diagnóstica, no
      trata, no es un producto sanitario).
- [x] No contiene claims médicos de diagnóstico/tratamiento/prevención
      (ver `docs/POLITICA_COPY_SALUD.md`).
- [x] Acceso a Health Connect con permisos de **solo lectura**, por métrica
      individual, revocables desde los ajustes del sistema.
- [x] Los datos de salud se procesan **solo en el dispositivo**; no se usan en
      publicidad, no se venden ni se comparten.
- [ ] ⚠️ Rellenar la declaración de **Health Connect** en Play Console ("App
      puede acceder a datos de salud") al publicar, con la lista de permisos reales
      del manifest: STEPS, HEART_RATE, WEIGHT, SLEEP, WATER, ACTIVE_CALORIES_BURNED,
      BODY_FAT.

## 5. Contenido que Play puede pedir

- [ ] ⚠️ **Declaración de publicidad**: "contiene publicidad" → Sí (AdMob, con
      consentimiento UMP para EEE/UK); en la práctica hasta que haya IDs reales la
      app muestra solo piezas de PRUEBA sin red.
- [ ] ⚠️ **Edad del contenido**: "Mayores de 16" (la app bloquea onboarding a
      menores por diseño).
- [ ] ⚠️ **No dirigida a niños** → no aplica "Familias".