extends Node
## Estado de la partida en curso. Todo lo persistente vive aquí y SaveManager lo serializa.
## Regla: el estado del mundo (cofres, atajos, Sellos, NPC...) se guarda como flags por ID.

var flags: Dictionary = {}          # StringName/String -> bool/int/String
var brasas: int = 0                 # moneda (separada de la XP, ver docs/decisiones.md)
var xp: int = 0
var level: int = 1
var house: StringName = &"errante"
var assist_mode: bool = false
var checkpoint_room: StringName = &""
var checkpoint_id: StringName = &""
var shadow: Dictionary = {}         # {"room": id, "pos": Vector2, "brasas": int} o vacío
var play_time_s: float = 0.0


func _process(delta: float) -> void:
	play_time_s += delta


func set_flag(id: StringName, value: Variant = true) -> void:
	flags[String(id)] = value
	EventBus.flag_set.emit(id, value)


func get_flag(id: StringName, default: Variant = false) -> Variant:
	return flags.get(String(id), default)


func add_brasas(amount: int) -> void:
	brasas = maxi(0, brasas + amount)
	EventBus.brasas_changed.emit(brasas)


## Muerte: la sombra guarda el 100 % de las brasas una vez. Si ya había una sombra, esa se pierde.
## En modo asistido no hay pérdida.
func on_player_death(room_id: StringName, pos: Vector2) -> void:
	if assist_mode:
		return
	shadow = {"room": String(room_id), "pos": pos, "brasas": brasas}
	brasas = 0
	EventBus.brasas_changed.emit(brasas)


func recover_shadow() -> void:
	if shadow.is_empty():
		return
	add_brasas(int(shadow.get("brasas", 0)))
	shadow = {}


func to_dict() -> Dictionary:
	return {
		"flags": flags.duplicate(true),
		"brasas": brasas,
		"xp": xp,
		"level": level,
		"house": String(house),
		"assist_mode": assist_mode,
		"checkpoint_room": String(checkpoint_room),
		"checkpoint_id": String(checkpoint_id),
		"shadow": _shadow_to_json(),
		"play_time_s": play_time_s,
	}


## JSON solo conoce float/String/Array/Dictionary: convertimos tipos explícitamente al leer.
func from_dict(d: Dictionary) -> void:
	flags = d.get("flags", {})
	brasas = int(d.get("brasas", 0))
	xp = int(d.get("xp", 0))
	level = int(d.get("level", 1))
	house = StringName(str(d.get("house", "errante")))
	assist_mode = bool(d.get("assist_mode", false))
	checkpoint_room = StringName(str(d.get("checkpoint_room", "")))
	checkpoint_id = StringName(str(d.get("checkpoint_id", "")))
	play_time_s = float(d.get("play_time_s", 0.0))
	var s: Dictionary = d.get("shadow", {})
	if s.is_empty():
		shadow = {}
	else:
		shadow = {
			"room": str(s.get("room", "")),
			"pos": Vector2(float(s.get("x", 0.0)), float(s.get("y", 0.0))),
			"brasas": int(s.get("brasas", 0)),
		}


func reset() -> void:
	from_dict({})


func _shadow_to_json() -> Dictionary:
	if shadow.is_empty():
		return {}
	var p: Vector2 = shadow.get("pos", Vector2.ZERO)
	return {"room": shadow.get("room", ""), "x": p.x, "y": p.y, "brasas": shadow.get("brasas", 0)}
