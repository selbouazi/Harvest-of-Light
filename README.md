# Harvest of Light

Metroidvania 2D sobre la luz que se cosecha. Proyecto en solitario con Godot 4.6.1.

**Hito actual:** prototipo gris del núcleo de combate (ver [docs/preproduccion.md](docs/preproduccion.md)).

## Abrir el proyecto
1. Instala [Godot 4.6.1](https://godotengine.org/download) (versión estándar, no .NET).
2. Abre Godot → *Importar* → selecciona `project.godot`.
3. Pulsa F5: se carga la arena de pruebas.

## Controles (teclado / mando)
| Acción | Teclado | Mando |
|---|---|---|
| Mover | A/D o flechas | stick izq. |
| Saltar (mantener = más alto) | Espacio / K | A |
| Atacar (+arriba/abajo en el aire) | J / X | X |
| Esquivar | L / Shift | B / RB |
| Curar (mantener, gasta 33 luz) | F / C | Y |
| Guardar / cargar (debug) | F5 / F9 | — |

## Arte
Ilustración pintada generada con FLUX.2 (Cloudflare Workers AI, cupo gratis) y procesada en local:
```bash
python3 tools/art/ai_gen.py --list      # qué imágenes hay y cuáles faltan
python3 tools/art/ai_gen.py             # genera las que falten (prompts y semillas en el script)
python3 tools/art/process_ai.py         # recorta, iguala color, escala → assets/art/hd/
```
Requiere `pip install pillow numpy requests rembg onnxruntime`. En local hace falta exportar
`CF_API_TOKEN` (token de Workers AI) y poner el Account ID en `tools/art/cf_account.txt`.
Las imágenes crudas (`tools/art/raw/`) no se suben a git.

## Documentación
- [docs/decisiones.md](docs/decisiones.md) — decisiones de diseño cerradas y abiertas.
- [docs/preproduccion.md](docs/preproduccion.md) — hitos, criterios de salida y checklist.
- [docs/registro-horas.md](docs/registro-horas.md) — horas reales (la base para fijar el alcance).
- [CLAUDE.md](CLAUDE.md) — convenciones técnicas.
