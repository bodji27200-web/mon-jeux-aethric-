extends Node
## Source de vérité de la partie en cours. Pas de logique de rendu ici.

const STARTING_CLASS := "cls_sentinelle"
const STARTING_ZONE := "zone_clairiere"

var player := {}            # voir _new_player()
var inventory := {}         # item_id -> count
var current_zone := STARTING_ZONE

# Transitoire (non sauvegardé) : monstre à affronter lors d'une rencontre.
var battle_monster_id := ""

func _ready() -> void:
	if player.is_empty():
		new_game()

func new_game() -> void:
	player = _new_player(STARTING_CLASS)
	inventory = {}
	current_zone = STARTING_ZONE

func _new_player(class_id: String) -> Dictionary:
	var cls := DataRegistry.get_class_def(class_id)
	var base: Dictionary = cls.get("base_stats", {}).duplicate(true)
	return {
		"class_id": class_id,
		"level": 1,
		"xp": 0,
		"stats": base,
		"current_hp": int(base.get("hp", 1)),
		"current_mana": int(base.get("mana", 0)),
		"skills": cls.get("starting_skills", []).duplicate(),
	}

func add_item(item_id: String, count: int = 1) -> void:
	inventory[item_id] = int(inventory.get(item_id, 0)) + count

func grant_xp(amount: int) -> void:
	player["xp"] = int(player.get("xp", 0)) + amount

## Restaure le héros au max (après un combat gagné / repos).
func full_restore() -> void:
	player["current_hp"] = int(player["stats"].get("hp", 1))
	player["current_mana"] = int(player["stats"].get("mana", 0))

## Sérialise l'état pour la sauvegarde.
func to_dict() -> Dictionary:
	return {
		"player": player.duplicate(true),
		"inventory": inventory.duplicate(true),
		"current_zone": current_zone,
	}

## Restaure l'état depuis une sauvegarde déjà migrée.
func from_dict(d: Dictionary) -> void:
	player = d.get("player", {}).duplicate(true)
	inventory = d.get("inventory", {}).duplicate(true)
	current_zone = d.get("current_zone", STARTING_ZONE)
