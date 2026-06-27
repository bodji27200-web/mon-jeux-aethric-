extends Node
## Sauvegarde / chargement versionnés vers user://.
## - écrit une copie de secours (.bak) avant d'écraser la sauvegarde ;
## - en cas de sauvegarde principale corrompue, tente la copie de secours ;
## - applique des migrations successives via save_version.

const SAVE_PATH := "user://save.json"
const BACKUP_PATH := "user://save.bak.json"
const SAVE_VERSION := 2

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(BACKUP_PATH)

func save_game() -> bool:
	# Copie de secours de la sauvegarde précédente avant d'écraser.
	if FileAccess.file_exists(SAVE_PATH):
		var prev := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if prev != null:
			var old_text := prev.get_as_text()
			prev.close()
			var bak := FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
			if bak != null:
				bak.store_string(old_text)
				bak.close()

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
	# On essaie la sauvegarde principale, puis la copie de secours.
	if _try_load(SAVE_PATH):
		return true
	if _try_load(BACKUP_PATH):
		push_warning("SaveManager: sauvegarde principale illisible, repli sur la copie de secours.")
		return true
	return false

func _try_load(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var text := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("SaveManager: parse KO (%s)" % path)
		return false
	var payload: Variant = json.data
	if not (payload is Dictionary) or not payload.has("state"):
		push_error("SaveManager: save invalide (%s)" % path)
		return false
	payload = _migrate(payload)
	GameState.from_dict(payload["state"])
	return true

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	if FileAccess.file_exists(BACKUP_PATH):
		DirAccess.remove_absolute(BACKUP_PATH)

## Applique les migrations successives jusqu'à SAVE_VERSION.
func _migrate(payload: Dictionary) -> Dictionary:
	var v := int(payload.get("save_version", 1))
	if v < 2:
		payload = _migrate_v1_to_v2(payload)
		v = 2
	payload["save_version"] = SAVE_VERSION
	return payload

## v1 -> v2 : l'équipement (introduit au lot 7) peut manquer dans les anciennes saves.
func _migrate_v1_to_v2(payload: Dictionary) -> Dictionary:
	var state: Dictionary = payload.get("state", {})
	var player: Dictionary = state.get("player", {})
	if not player.has("equipment"):
		player["equipment"] = { "weapon": "", "armor": "", "trinket": "" }
	state["player"] = player
	payload["state"] = state
	return payload
