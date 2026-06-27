extends Node
## Sauvegarde / chargement versionnés vers user://. Gère save_version + migrations.

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> bool:
	var payload := {
		"save_version": SAVE_VERSION,
		"state": GameState.to_dict(),
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: écriture impossible (%s)" % SAVE_PATH)
		return false
	f.store_string(JSON.stringify(payload, "\t"))
	f.close()
	return true

func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var text := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("SaveManager: save corrompue, parse KO")
		return false
	var payload: Variant = json.data
	if not (payload is Dictionary) or not payload.has("state"):
		push_error("SaveManager: save invalide")
		return false
	payload = _migrate(payload)
	GameState.from_dict(payload["state"])
	return true

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)

## Applique les migrations successives jusqu'à SAVE_VERSION.
func _migrate(payload: Dictionary) -> Dictionary:
	var v := int(payload.get("save_version", 0))
	# Aucune migration nécessaire pour l'instant (version 1 = format initial).
	# Exemple futur : if v == 1: payload = _v1_to_v2(payload)
	payload["save_version"] = SAVE_VERSION
	return payload
