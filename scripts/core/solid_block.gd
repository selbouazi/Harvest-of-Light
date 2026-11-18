@tool
class_name SolidBlock
extends StaticBody2D
## Bloque de geometría provisional (greybox). Crea su propia colisión a partir de `size`.
## Se sustituirá por TileMapLayer cuando exista el tileset de la R1.

@export var size := Vector2(64, 16):
	set(v):
		size = v
		_rebuild()
@export var color := Color(0.18, 0.2, 0.28)

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


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), color)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 2)), color.lightened(0.25))
