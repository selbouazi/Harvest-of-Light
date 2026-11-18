extends TestCase

const SaveManagerScript := preload("res://autoload/save_manager.gd")

var sm: Node


func before_each() -> void:
	sm = SaveManagerScript.new()
	sm.save_dir = "user://test_saves"
	sm.delete_save(0)


func after_each() -> void:
	sm.delete_save(0)
	sm.free()


func test_guardar_y_cargar_ida_y_vuelta() -> void:
	var state := {"brasas": 42, "flags": {"chest/r1_03": true}}
	assert_eq(sm.save_game(0, state), OK)
	var loaded: Dictionary = sm.load_game(0)
	assert_eq(int(loaded["brasas"]), 42)
	assert_eq(loaded["flags"]["chest/r1_03"], true)


func test_segundo_guardado_crea_backup() -> void:
	sm.save_game(0, {"brasas": 1})
	sm.save_game(0, {"brasas": 2})
	assert_true(FileAccess.file_exists(sm.slot_path(0) + ".bak"))
	assert_false(FileAccess.file_exists(sm.slot_path(0) + ".tmp"))


func test_archivo_corrupto_recupera_el_backup() -> void:
	sm.save_game(0, {"brasas": 1})
	sm.save_game(0, {"brasas": 2})
	var f := FileAccess.open(sm.slot_path(0), FileAccess.WRITE)
	f.store_string("{esto no es json")
	f.close()
	assert_eq(int(sm.load_game(0).get("brasas", -1)), 1)


func test_version_futura_se_rechaza() -> void:
	assert_true(sm.migrate({"version": 999, "state": {}}).is_empty())


func test_sin_partida_devuelve_vacio() -> void:
	assert_true(sm.load_game(0).is_empty())
	assert_false(sm.has_save(0))
