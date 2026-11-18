extends Node
## Guardado en JSON con versión, escritura atómica (temporal + renombrar) y copia de seguridad.
## Contenido de diseño = Resources (.tres). JSON = solo partidas guardadas.

const SAVE_VERSION := 1
const SLOT_COUNT := 3

var save_dir := "user://saves"


func slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [save_dir, slot]


func save_game(slot: int, state: Dictionary) -> Error:
	var err := DirAccess.make_dir_recursive_absolute(save_dir)
	if err != OK:
		return err
	var path := slot_path(slot)
	var tmp := path + ".tmp"
	var payload := {
		"version": SAVE_VERSION,
		"saved_at": Time.get_datetime_string_from_system(true),
		"state": state,
	}
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(payload, "\t"))
	f.close()
	# Comprobamos que lo escrito se puede leer antes de sustituir nada.
	if _read_json(tmp).is_empty():
		DirAccess.remove_absolute(tmp)
		return ERR_FILE_CORRUPT
	if FileAccess.file_exists(path):
		var bak := path + ".bak"
		if FileAccess.file_exists(bak):
			DirAccess.remove_absolute(bak)
		DirAccess.rename_absolute(path, bak)
	return DirAccess.rename_absolute(tmp, path)


## Devuelve el "state" migrado a la versión actual, o {} si no hay partida válida.
## Si el archivo principal está corrupto, intenta la copia de seguridad.
func load_game(slot: int) -> Dictionary:
	var path := slot_path(slot)
	for candidate: String in [path, path + ".bak"]:
		var data := _read_json(candidate)
		if data.is_empty():
			continue
		var migrated := migrate(data)
		if not migrated.is_empty():
			return migrated.get("state", {})
	return {}


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot)) or FileAccess.file_exists(slot_path(slot) + ".bak")


func delete_save(slot: int) -> void:
	for p: String in [slot_path(slot), slot_path(slot) + ".bak", slot_path(slot) + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


## Migraciones encadenadas: añade un bloque "if v == N" por cada cambio de formato.
func migrate(data: Dictionary) -> Dictionary:
	var v := int(data.get("version", 0))
	if v > SAVE_VERSION or not data.has("state"):
		return {}
	# if v == 1: ...transformar data["state"]...; v = 2
	data["version"] = v
	return data


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	if json.parse(text) != OK:   # corrupto: sin push_error, se reintenta con el backup
		return {}
	if json.data is Dictionary:
		return json.data
	return {}
