class_name Checkpoint
extends Area2D
## Checkpoint: al tocarlo fija el punto de reaparición y guarda progreso (no posición libre).

@export var room_id: StringName = &"test_arena"
@export var checkpoint_id: StringName = &"cp_0"


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not body is Player:
		return
	if GameState.checkpoint_id == checkpoint_id and GameState.checkpoint_room == room_id:
		return
	GameState.checkpoint_room = room_id
	GameState.checkpoint_id = checkpoint_id
	EventBus.checkpoint_reached.emit(room_id, checkpoint_id)
	SaveManager.save_game(0, GameState.to_dict())
	queue_redraw()


func _draw() -> void:
	var on := GameState.checkpoint_id == checkpoint_id
	draw_rect(Rect2(Vector2(-4, -24), Vector2(8, 24)), Color(1.0, 0.85, 0.4) if on else Color(0.5, 0.45, 0.3))
