extends Node
## Pausa breve al golpear. Desactivable (accesibilidad, I9) con `enabled`.

var enabled := true
var _until_ms := 0


func request(duration_s: float) -> void:
	if not enabled or duration_s <= 0.0:
		return
	_until_ms = maxi(_until_ms, Time.get_ticks_msec() + int(duration_s * 1000.0))
	Engine.time_scale = 0.05


func _process(_delta: float) -> void:
	if Engine.time_scale < 1.0 and Time.get_ticks_msec() >= _until_ms:
		Engine.time_scale = 1.0
