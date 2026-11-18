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
	EventBus.room_entered.emit(room_id)


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
