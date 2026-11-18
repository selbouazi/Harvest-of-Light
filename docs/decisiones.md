# Decisiones de diseño

Fuente: *Evaluación unificada del GDD* (5-nov-2026) y revisión posterior. Una decisión cerrada solo
se reabre con datos de juego (playtest u horas medidas), no con otro documento.

## Cerradas

| # | Decisión | Dónde vive |
|---|---|---|
| D1 | Alcance publicable: 3 regiones (una por acto), 3 jefes, 9–12 minijefes, 35–40 objetos, 20–25 NPC. Resto = expansiones. | Este doc |
| D2 | Ningún paso a la R2 sin Primer Bioma validado y horas medidas. | preproduccion.md |
| D3 | Movimiento e hitbox constantes para todos. Agilidad eliminada como stat. | `player.gd` (constantes) |
| D4 | Moveset base: caminar, salto variable, ataque 4 direcciones (abajo solo en el aire, con pogo), esquiva corta con i-frames. El Dash de exploración es otra habilidad. | `player.gd` |
| D5 | Referencia de combate principal: compromiso (arranque + recuperación), no cancelaciones tipo Dead Cells. | `player.gd` |
| D6 | "Poder = suma de stats" sustituido por golpes aguantados: a nivel esperado 6–8 golpes; las stats no mueven eso más de ±40 %. | `CombatMath.hits_to_die`, tests |
| D7 | 3 tipos de daño (Físico, Luz, Sombra). Resistencias en [0,5–1,5]. Fuego/Rayo = propiedades de arma. | `DamageTypes`, `CombatMath` |
| D8 | Luz: reserva fija (no ligada a Magia), +luz por golpe con tope por segundo, curación ~33 % canalizada y cancelable. | `StatsConfig`, `player.gd` |
| D9 | Muerte: la sombra guarda el 100 % de las brasas una vez. Modo asistido sin pérdida. XP separada de brasas. | `GameState` |
| D10 | XP decae con la repetición. Sin puertas de nivel. | `CombatMath.xp_with_decay` |
| D11 | Slice con una casa (Errante). Publicable: 2–3 casas cuerpo a cuerpo con una ventaja mecánica persistente. Alba y Ascua para después. | — |
| D12 | Fuera de la v1: ulti, parry, estados extra, NG+, logros, perfil con foto, copiar partida. | — |
| D13 | Guardado: flags por ID, escritura atómica, backup, versión + migraciones. El autoguardado guarda progreso, no posición. | `SaveManager`, tests |
| D14 | Oscuridad solo de ambiente; telégrafos con contraste fijo. Hitstop/destellos/temblor desactivables. | `AttackData`, `Hitstop` |
| D15 | Texto en español con claves `tr()`; inglés con el texto congelado (Beta). | — |
| D16 | Enemigos comunes temáticos (guardias del diezmo, cosechadores, portadores vaciados, sombras). | `hollowed_bearer.gd` |
| D17 | Slice: incrementos fijos por nivel (Vida, Fuerza). Reparto libre solo si el slice demuestra que falta. | `StatsConfig` |
| D18 | Sin horas semanales fijas: se planifica por hitos y criterios de salida, no por fechas. Se apuntan las horas reales igualmente (sirven para medir coste por pieza). | registro-horas.md |
| D19 | Arte: ilustración pintada a mano generada con FLUX.2 (Cloudflare Workers AI, cupo gratis ~25–30 imágenes/día) + recorte con rembg, todo reproducible desde `tools/art/ai_gen.py` (prompts y semillas) y `tools/art/process_ai.py`. Personajes: poses clave con imagen de referencia para mantener la consistencia. | `tools/art/` |
| D20 | Audio: SFX sintetizados por script (estilo sfxr). Música: pistas CC0/CC-BY de OpenGameArt o itch.io, con créditos en `assets/CREDITOS.md`. Sin música por capas en la v1. | `assets/audio/` |
| D22 | Formato de arte HD: mundo de 640×360 unidades con stretch `canvas_items`; texturas a 4× (escala 0.25), filtrado lineal con mipmaps. Errante ≈ 40 u de alto (hitbox 12×28). | `project.godot`, `process_ai.py` |
| D23 | Luz: sin CanvasModulate. La oscuridad está en el fondo pintado (gradación nocturna); las luces son PointLight2D en modo add que solo afectan al escenario (los personajes conservan su color). Niebla, motas y viñeta para profundidad. | `LightUtil`, `test_arena.gd` |
| D21 | Magia fuera de la v1: no hay nada que escale (luz fija, sin hechizos). Vuelve con la primera arma o habilidad de Luz y escalará solo daño de Luz. Stats v1: Vida y Fuerza. | `StatsConfig` |

## Abiertas (bloquean estimaciones — resolver en preproducción)

| # | Pregunta | Notas |
|---|---|---|
| A4 | ¿Esquivar cuesta luz? | Si sí, compite con curarse. Hoy: no cuesta (cooldown 0,4 s). |
| A5 | Duración del juego. R1 = 45–75 min ⇒ 3 regiones ≈ 3–5 h, no 6–9 h. | Decidir si las regiones 2–3 son más grandes (más coste) o el juego es corto. |
| A6 | Habilidades de exploración: con 3 regiones hacen falta 5–7 puertas, no 3. | Matriz obstáculo × habilidad × región. |
| A7 | Sellos: lineal con atajos, o libre con poder/diálogo por "cuántos has roto". | — |
| A8 | Narrativa: definir la Corte, qué decide cada final, 4–6 compromisos en 3 ejes. | Solo escritura. |
