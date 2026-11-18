class_name Checkpoint
extends Area2D
## Checkpoint: al tocarlo fija el punto de reaparición y guarda progreso (no posición libre).

@export var room_id: StringName = &"test_arena"
@export var checkpoint_id: StringName = &"cp_0"


var _light: PointLight2D
@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_light = LightUtil.make_light(80.0, Color(1.0, 0.85, 0.45), 1.0)
	_light.position = Vector2(0, -26)
	add_child(_light)
	_refresh()


func _on_body_entered(body: Node) -> void:
	if not body is Player:
		return
	if GameState.checkpoint_id == checkpoint_id and GameState.checkpoint_room == room_id:
		return
	GameState.checkpoint_room = room_id
	GameState.checkpoint_id = checkpoint_id
	EventBus.checkpoint_reached.emit(room_id, checkpoint_id)
	SaveManager.save_game(0, GameState.to_dict())
	for cp in get_tree().get_nodes_in_group(&"checkpoint"):
		cp._refresh()


func _refresh() -> void:
	var on := GameState.checkpoint_id == checkpoint_id and GameState.checkpoint_room == room_id
	_sprite.frame = 1 if on else 0
	_light.enabled = on
