extends CanvasLayer
## HUD provisional: vida, luz, brasas y ayuda de controles.

var _player: Player
@onready var _label: Label = $Label


func _ready() -> void:
	_player = get_tree().get_first_node_in_group(&"player") as Player


func _process(_delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player") as Player
		return
	_label.text = "Vida %d/%d   Luz %d/%d   Brasas %d   XP %d\n%s\n%s" % [
		_player.hp, _player.max_hp, int(_player.light), int(_player.stats.light_max),
		GameState.brasas, GameState.xp, Player.State.keys()[_player.state],
		"A/D mover · Espacio saltar · J atacar (+W/S) · L esquivar · F curar (mantener) · F5 guardar · F9 cargar",
	]
