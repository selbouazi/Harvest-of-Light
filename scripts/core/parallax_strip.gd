class_name ParallaxStrip
extends Parallax2D
## Capa de fondo en bucle a partir de una textura HD. Se coloca sola: `base_y` es la
## altura en pantalla (0–360) donde apoya la textura (o de donde cuelga si `hang_from_top`).

@export var texture: Texture2D
@export var texture_scale := 0.25
@export var base_y := 300.0
@export var gap := 0.0
@export var hang_from_top := false
@export var tint := Color.WHITE

var _sprite: Sprite2D


func _ready() -> void:
	if texture == null:
		return
	_sprite = Sprite2D.new()
	_sprite.texture = texture
	_sprite.centered = false
	_sprite.scale = Vector2.ONE * texture_scale
	_sprite.modulate = tint
	var size := texture.get_size() * texture_scale
	_sprite.position = Vector2(0, 0 if hang_from_top else base_y - size.y)
	if hang_from_top:
		_sprite.position.y = base_y
	add_child(_sprite)
	if gap >= 0.0:
		repeat_size = Vector2(size.x + gap, 0)
		repeat_times = 4
