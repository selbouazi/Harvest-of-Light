extends TestCase
## Usa el autoload GameState real (los autoloads se cargan también con -s).

var gs: Node


func before_each() -> void:
	gs = Engine.get_main_loop().root.get_node("GameState")
	gs.reset()


func after_each() -> void:
	gs.reset()


func test_muerte_deja_sombra_con_el_100_por_ciento() -> void:
	gs.brasas = 120
	gs.on_player_death(&"r1_05", Vector2(10, 20))
	assert_eq(gs.brasas, 0)
	gs.recover_shadow()
	assert_eq(gs.brasas, 120)
	assert_true(gs.shadow.is_empty())


func test_morir_otra_vez_pierde_la_sombra_anterior() -> void:
	gs.brasas = 100
	gs.on_player_death(&"r1_05", Vector2.ZERO)
	gs.brasas = 30
	gs.on_player_death(&"r1_06", Vector2.ZERO)
	gs.recover_shadow()
	assert_eq(gs.brasas, 30)


func test_modo_asistido_sin_perdida() -> void:
	gs.assist_mode = true
	gs.brasas = 50
	gs.on_player_death(&"r1_05", Vector2.ZERO)
	assert_eq(gs.brasas, 50)


func test_serializacion_conserva_tipos_tras_json() -> void:
	gs.brasas = 7
	gs.level = 3
	gs.set_flag(&"seal/r1_a", true)
	gs.on_player_death(&"r1_02", Vector2(5, 6))
	var json := JSON.stringify(gs.to_dict())
	gs.reset()
	gs.from_dict(JSON.parse_string(json))
	assert_eq(gs.level, 3)
	assert_true(gs.level is int)
	assert_eq(gs.get_flag(&"seal/r1_a"), true)
	assert_eq(gs.shadow["pos"], Vector2(5, 6))
	assert_eq(gs.shadow["brasas"], 7)
