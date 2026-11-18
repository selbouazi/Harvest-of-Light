# Harvest of Light — guía para Claude Code

Metroidvania 2D en solitario. Idioma del proyecto: español (código en inglés, comentarios y docs en español).

## Versión fijada
- **Godot 4.6.1 stable, GDScript 2.0.** Nunca generar sintaxis de Godot 3
  (`onready var`, `export var`, `yield`, `KinematicBody2D`, `move_and_slide(vel)`...).
- Renderer: GL Compatibility. Mundo 640×360 con stretch `canvas_items`; texturas HD a 4× (nodos con scale 0.25), filtro lineal + mipmaps.

## Comandos
```bash
godot --headless --path . --import                           # primera vez / tras añadir assets
godot --headless --path . -s res://tests/run_tests.gd         # tests unitarios
godot --headless --path . --quit-after 2000 res://tests/smoke_arena.tscn   # humo
```
La CI (`.github/workflows/ci.yml`) ejecuta lo mismo en cada push.

## Arquitectura
- `autoload/`: `InputSetup` (acciones por código), `EventBus` (señales globales),
  `GameState` (estado + flags del mundo), `SaveManager` (JSON atómico + backup + migraciones), `Hitstop`.
- `scripts/core/`: fórmulas puras (`CombatMath`, `DamageTypes`) y piezas de escena.
- `scripts/data/`: Resources de diseño (`StatsConfig`, `BossTemplate`, `BossPhase`, `AttackData`).
- `data/`: instancias `.tres` — **los números se tunean aquí, no en el código.**
- Contenido = Resources `.tres`. JSON = solo partidas guardadas.
- Estado del mundo = flags por ID en `GameState.flags` (`chest/r1_03`, `seal/r1_a`, `kills/<enemy_id>`).
- Salas con ID estable (`r1_05`) desde el primer día.

## Arte
- Pipeline en `tools/art/` (ver README). El cupo gratis de FLUX.2 da ~25–30 imágenes al día: generar solo lo necesario.
- Personajes: añadir poses en `ASSETS` de `ai_gen.py` con `refs=["hero_ref"]` para mantener la consistencia.

## Reglas de diseño que el código debe respetar (ver docs/decisiones.md)
- Movimiento e hitbox del jugador **constantes** (constantes en `player.gd`). Ninguna stat ni casa los cambia.
- Esquiva de combate ≠ Dash de exploración.
- Resistencias siempre en [0.5, 1.5]. 3 tipos de daño: Físico, Luz, Sombra.
- Luz: reserva fija, ganancia con tope por segundo, curación canalizada y cancelable.
- Telegrafía de ataques ≥ `AttackData.MIN_TELEGRAPH_S` y con contraste fijo.
- Sin ulti, sin parry, sin estados alterados hasta que el núcleo esté validado.

## Al trabajar
- Añadir/actualizar tests en `tests/test_*.gd` (extienden `TestCase`) para fórmulas, stats, guardado y daño.
- Escenas `.tscn` y colisiones generadas a mano: mantenerlas simples; el humano las revisa en el editor.
- No añadir sistemas fuera del alcance del hito actual (docs/preproduccion.md). Ante la duda, preguntar.
- Explicar el código nuevo en el mensaje: el autor está aprendiendo y no debe aceptar código que no entiende.
