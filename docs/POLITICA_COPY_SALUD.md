# Política de copy anti-claims (MDR / Play Health Apps)

**Fecha de la auditoría:** 2026-10-06 · **Resultado:** ✅ sin claims de
diagnóstico/tratamiento/prevención; se suavizaron 4 afirmaciones fisiológicas.

## La regla (para mantener)

> Ningún texto de la app (tips, artículos, coach, tarjetas, marcadores de progreso)
> afirma que FitPulse **diagnostique, trate, cure o prevenga** una enfermedad, ni
> promete resultados fisiológicos garantizados. El contenido es **orientativo** y
> siempre que se hable del cuerpo se usa lenguaje experiencial o de rendimiento,
> nunca médico-prescriptivo.

## Criterios de revisión

Un texto es **aceptable** si:
1. No nombra enfermedades ni síntomas como objeto de tratamiento.
2. No usa verbos de garantía ("garantiza", "elimina", "maximiza la quema", "frena el
   catabolismo", "cura", "previene").
3. No cita mecanismos fisiológicos no verificables (hormonas, volemia, cortisol)
   como promesa.
4. Incluye el descargo cuando aplica: `tipsAvisoSalud` ("Estos contenidos son
   orientativos y no sustituyen el consejo de un profesional de la salud") y
   `esOrientativo` ("Orientativo: no sustituye un diagnóstico profesional").

## Resultado de la auditoría (2026-10-06)

**Barrido:** `grep` sobre `lib/` con patrones médicos (diagno|trat|cur|previen|
quema|volemia|catabolismo|cortisol|hormona, etc.).

| Texto | Antes | Después |
|---|---|---|
| `tipsTip1Desc` (hidratación) | "…para mantener la **volemia** y potencia muscular" | "…para llegar hidratado y rendir mejor en tu sesión" |
| `tipsTip2Desc` (proteína post-HIIT) | "…para **frenar el catabolismo**" | "…para apoyar la recuperación muscular" |
| `tipsTip3Desc` (sueño) | "**Garantiza** 7-8 horas… la hormona de crecimiento nocturna **maximiza la quema lipídica**" | "Duerme 7-8 horas: el descanso nocturno es clave para la recuperación y el rendimiento" |
| `tipsArt3Titulo` | "…para **bajar el cortisol**" | "…para relajarte" |

**Descargos ya presentes (se mantienen):** `tipsAvisoSalud` y `esOrientativo`;
el coach de cámara es solo alineación postural con su aviso de IA (art. 50).

**Nota MDR (2017/745):** la app queda fuera del ámbito de producto sanitario
(sin claims médicos, sin finalidad médica). Esta política lo deja escrito.