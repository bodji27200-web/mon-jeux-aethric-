extends Node
## Charge et indexe tous les contenus data-driven du dossier res://data/.
## Aucun contenu de jeu n'est codé en dur ailleurs : on passe toujours par ce registre.

var classes: Dictionary = {}
var skills: Dictionary = {}
var monsters: Dictionary = {}
var items: Dictionary = {}
var loot_tables: Dictionary = {}
var zones: Dictionary = {}

func _ready() -> void:
	_load_dir("res://data/classes", classes)
	_load_dir("res://data/skills", skills)
	_load_dir("res://data/monsters", monsters)
	_load_dir("res://data/items", items)
	_load_dir("res://data/loot_tables", loot_tables)
	_load_dir("res://data/zones", zones)

## Charge tous les .json d'un dossier et les indexe par leur champ "id".
func _load_dir(path: String, target: Dictionary) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("DataRegistry: dossier introuvable: %s" % path)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var data: Variant = _read_json(path + "/" + file_name)
			if data is Dictionary and data.has("id"):
				target[data["id"]] = data
			else:
				push_warning("DataRegistry: JSON invalide ou sans 'id': %s" % file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

func _read_json(file_path: String) -> Variant:
	var f := FileAccess.open(file_path, FileAccess.READ)
	if f == null:
		push_warning("DataRegistry: lecture impossible: %s" % file_path)
		return null
	var text := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		push_warning("DataRegistry: parse JSON KO (%s): %s" % [file_path, json.get_error_message()])
		return null
	return json.data

func get_class_def(id: String) -> Dictionary:
	return classes.get(id, {})

func get_skill(id: String) -> Dictionary:
	return skills.get(id, {})

func get_monster(id: String) -> Dictionary:
	return monsters.get(id, {})

func get_item(id: String) -> Dictionary:
	return items.get(id, {})

func get_loot_table(id: String) -> Dictionary:
	return loot_tables.get(id, {})

func get_zone(id: String) -> Dictionary:
	return zones.get(id, {})
