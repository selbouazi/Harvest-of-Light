@tool
class_name SolidBlock
extends StaticBody2D
## Bloque de geometría provisional (greybox). Crea su propia colisión a partir de `size`.
## Se sustituirá por TileMapLayer cuando exista el tileset de la R1.

@export var size := Vector2(64, 16):
	set(v):
		size = v
		_rebuild()
@export var tiles: Texture2D = preload("res://assets/art/tiles.png")
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


## Atlas de 16 px: celda 0 = superficie, celda 1 = relleno. Recorta en los bordes.
func _draw() -> void:
	const T := 16.0
	var y := 0.0
	while y < size.y:
		var x := 0.0
		var h := minf(T, size.y - y)
		while x < size.x:
			var w := minf(T, size.x - x)
			var cell := 0 if (y == 0.0 and has_surface) else 1
			draw_texture_rect_region(tiles, Rect2(x, y, w, h), Rect2(cell * T, 0, w, h))
			x += T
		y += T
