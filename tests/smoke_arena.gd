extends Node
## Prueba de humo: carga la arena, simula entrada durante 10 s y comprueba que nada revienta.
## Se ejecuta como escena (así los autoloads existen al compilar):
##   godot --headless --path . res://tests/smoke_arena.tscn

const FRAMES := 600

var _frame := 0
var _player: Player
var _kills := 0
var _damaged := 0


func _ready() -> void:
	var arena: Node = load("res://scenes/levels/test_arena.tscn").instantiate()
	add_child(arena)
	_player = arena.get_node("Player")
	EventBus.enemy_killed.connect(func(_id, _xp, _b): _kills += 1)
	EventBus.player_damaged.connect(func(_a, _hp): _damaged += 1)


func _physics_process(_delta: float) -> void:
	_frame += 1
	# Bot simple: ir hacia el enemigo más cercano y atacar al tenerlo a tiro.
	var target := _nearest_enemy()
	Input.action_release("move_left")
	Input.action_release("move_right")
	if target:
		var dx := target.global_position.x - _player.global_position.x
		if absf(dx) > 26.0:
			Input.action_press("move_right" if dx > 0.0 else "move_left")
		elif signf(dx) != _player.facing:
			Input.action_press("move_right" if dx > 0.0 else "move_left")
		_pulse("attack", 15, 0)
	else:
		Input.action_press("move_right")
	_pulse("jump", 90, 0, 12)
	_pulse("dodge", 120, 60)
	if _frame >= FRAMES:
		var ok := _player.global_position.x > 100.0 and _kills >= 1
		print("smoke: x=%.0f hp=%d/%d luz=%.0f kills=%d golpes_recibidos=%d brasas=%d → %s" % [
			_player.global_position.x, _player.hp, _player.max_hp, _player.light, _kills, _damaged,
			GameState.brasas, "OK" if ok else "FALLO"])
		get_tree().quit(0 if ok else 1)


func _nearest_enemy() -> Node2D:
	var best: Node2D = null
	for e in get_tree().get_nodes_in_group(&"enemy"):
		if e.state == HollowedBearer.State.DEAD:
			continue
		if best == null or absf(e.global_position.x - _player.global_position.x) < absf(best.global_position.x - _player.global_position.x):
			best = e
	return best


func _pulse(action: StringName, every: int, offset: int, hold := 1) -> void:
	var f := (_frame - offset) % every
	if f == 0:
		Input.action_press(action)
	elif f == hold:
		Input.action_release(action)
