@tool
class_name SolidBlock
extends StaticBody2D
## Bloque de geometría provisional (greybox). Crea su propia colisión a partir de `size`.
## Se sustituirá por TileMapLayer cuando exista el tileset de la R1.

@export var size := Vector2(64, 16):
	set(v):
		size = v
		_rebuild()
@export var tiles: Texture2D = preload("res://assets/art/hd/ground.png")
## px de textura por px de mundo (ver tools/art/process_ai.py).
@export var texture_scale := 0.25
@export var fill_color := Color(0.07, 0.08, 0.12)
## Si es false, todas las celdas usan el tile de relleno (paredes).
@export var has_surface := true

var _shape: CollisionShape2D


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _shape == null:
		_shape = CollisionShape2D.new()
		add_child(_shape)
	var rect := RectangleShape2D.new()
	rect.size = size
	_shape.shape = rect
	_shape.position = size * 0.5
	queue_redraw()


## Superficie pintada en bucle horizontal; debajo, relleno oscuro con degradado.
## El borde de musgo sobresale 6 px por encima de la colisión (los pies "se hunden" un poco).
func _draw() -> void:
	const LIP := 6.0
	var tex_size := tiles.get_size() * texture_scale
	if not has_surface:
		draw_rect(Rect2(Vector2.ZERO, size), fill_color)
		draw_rect(Rect2(Vector2.ZERO, Vector2(3, size.y)), fill_color.lightened(0.08))
		draw_rect(Rect2(Vector2(size.x - 3, 0), Vector2(3, size.y)), fill_color.lightened(0.08))
		return
	var band := minf(tex_size.y, size.y + LIP)
	draw_rect(Rect2(Vector2(0, band - LIP), Vector2(size.x, maxf(0.0, size.y - band + LIP))), fill_color)
	var x := 0.0
	while x < size.x:
		var w := minf(tex_size.x, size.x - x)
		var src := Rect2(Vector2.ZERO, Vector2(w, band) / texture_scale)
		draw_texture_rect_region(tiles, Rect2(x, -LIP, w, band), src)
		x += tex_size.x
	# sombra suave bajo la superficie para dar volumen
	for i in 6:
		draw_rect(Rect2(0, band - LIP + i * 3, size.x, 3), Color(0, 0, 0, 0.18 - i * 0.03))
