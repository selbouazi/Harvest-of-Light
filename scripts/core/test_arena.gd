extends Node2D
## Arena de pruebas del núcleo (objetivo del prototipo gris: que pelear aquí se sienta bien).

const RESPAWN_DELAY_S := 1.2

@export var room_id: StringName = &"test_arena"

@onready var _player: Player = $Player
@onready var _spawn: Marker2D = $Spawn


func _ready() -> void:
	_player.died.connect(_on_player_died)
	var cam: Camera2D = _player.get_node("Camera2D")
	cam.limit_left = -192
	cam.limit_right = 1152
	cam.limit_bottom = 240
	_add_atmosphere(cam)
	EventBus.room_entered.emit(room_id)


## Motas de luz flotando y viñeta: barato y da mucha profundidad.
func _add_atmosphere(cam: Camera2D) -> void:
	var motes := CPUParticles2D.new()
	motes.amount = 40
	motes.lifetime = 8.0
	motes.preprocess = 8.0
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = Vector2(360, 200)
	motes.direction = Vector2(0.3, -1)
	motes.spread = 60.0
	motes.gravity = Vector2.ZERO
	motes.initial_velocity_min = 3.0
	motes.initial_velocity_max = 9.0
	motes.scale_amount_min = 0.03
	motes.scale_amount_max = 0.07
	motes.texture = LightUtil.radial_texture(64)
	motes.color = Color(1.0, 0.85, 0.5, 0.8)
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	ramp.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	motes.color_ramp = ramp
	motes.local_coords = false
	motes.z_index = 15
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	motes.material = add
	cam.add_child(motes)

	var layer := CanvasLayer.new()
	layer.layer = 5
	var vignette := TextureRect.new()
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0.0, 0.01, 0.03, 0.7)])
	var t := GradientTexture2D.new()
	t.width = 512
	t.height = 512
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.05, 0.5)
	vignette.texture = t
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(vignette)
	add_child(layer)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_F5:
				SaveManager.save_game(0, GameState.to_dict())
				print("Guardado en ranura 0")
			KEY_F9:
				var data := SaveManager.load_game(0)
				if not data.is_empty():
					GameState.from_dict(data)
					print("Cargada ranura 0")


func _on_player_died() -> void:
	GameState.on_player_death(room_id, _player.global_position)
	await get_tree().create_timer(RESPAWN_DELAY_S).timeout
	_player.respawn(_spawn.global_position)
