class_name CombatEngine
extends RefCounted
## Moteur de combat tour par tour, sans dépendance à l'UI (donc testable en headless).
## Lot 1 : 1 héros contre 1 monstre. Le héros agit, puis le monstre.

var rng: RNG

# Acteurs en combat (copies de travail, on ne modifie pas les données sources).
var hero := {}
var enemy := {}
var log_lines: Array[String] = []

func _init(rng_instance: RNG = null) -> void:
	rng = rng_instance if rng_instance != null else RNG.new()

## Prépare le combat à partir de l'état du héros et d'un id de monstre.
func setup(hero_state: Dictionary, monster_id: String) -> void:
	hero = {
		"name": "Héros",
		"hp": int(hero_state.get("current_hp", 1)),
		"max_hp": int(hero_state["stats"].get("hp", 1)),
		"mana": int(hero_state.get("current_mana", 0)),
		"attack": int(hero_state["stats"].get("attack", 1)),
		"defense": int(hero_state["stats"].get("defense", 0)),
		"speed": int(hero_state["stats"].get("speed", 0)),
		"skills": hero_state.get("skills", []),
	}
	var m := DataRegistry.get_monster(monster_id)
	enemy = {
		"id": monster_id,
		"name": m.get("display_name", "Ennemi"),
		"hp": int(m.get("stats", {}).get("hp", 1)),
		"max_hp": int(m.get("stats", {}).get("hp", 1)),
		"attack": int(m.get("stats", {}).get("attack", 1)),
		"defense": int(m.get("stats", {}).get("defense", 0)),
		"speed": int(m.get("stats", {}).get("speed", 0)),
		"xp_reward": int(m.get("xp_reward", 0)),
		"loot_table_id": m.get("loot_table_id", ""),
	}

## Formule de dégâts du projet (volontairement simple et originale).
## Dégâts = max(1, power + attaque - défense) avec une légère variance aléatoire.
func compute_damage(power: int, attacker: Dictionary, defender: Dictionary) -> int:
	var raw := power + int(attacker.get("attack", 0)) - int(defender.get("defense", 0))
	raw = max(1, raw)
	var variance := rng.randi_range(-1, 1)
	return max(1, raw + variance)

## Le héros utilise une compétence sur l'ennemi. Renvoie true si l'action a pu être jouée.
func hero_use_skill(skill_id: String) -> bool:
	if not is_ongoing():
		return false
	var skill := DataRegistry.get_skill(skill_id)
	if skill.is_empty():
		return false
	var cost := int(skill.get("resource_cost", {}).get("amount", 0))
	if hero["mana"] < cost:
		log_lines.append("Pas assez d'énergie pour %s." % skill.get("display_name", skill_id))
		return false
	hero["mana"] -= cost
	if skill.get("effect_type", "") == "damage":
		var dmg := compute_damage(int(skill.get("power", 0)), hero, enemy)
		enemy["hp"] = max(0, enemy["hp"] - dmg)
		log_lines.append("%s inflige %d dégâts." % [skill.get("display_name", skill_id), dmg])
	_enemy_turn_if_alive()
	return true

## Le monstre riposte s'il est encore en vie.
func _enemy_turn_if_alive() -> void:
	if enemy["hp"] <= 0:
		log_lines.append("%s est vaincu !" % enemy["name"])
		return
	var dmg := compute_damage(8, enemy, hero)
	hero["hp"] = max(0, hero["hp"] - dmg)
	log_lines.append("%s riposte : %d dégâts." % [enemy["name"], dmg])
	if hero["hp"] <= 0:
		log_lines.append("Héros est tombé...")

func is_ongoing() -> bool:
	return hero["hp"] > 0 and enemy["hp"] > 0

func hero_won() -> bool:
	return enemy["hp"] <= 0 and hero["hp"] > 0

func hero_lost() -> bool:
	return hero["hp"] <= 0

## Génère le butin de l'ennemi vaincu : [{ "item_id", "count" }].
func roll_loot() -> Array:
	var result: Array = []
	var table := DataRegistry.get_loot_table(enemy.get("loot_table_id", ""))
	if table.is_empty():
		return result
	var entries: Array = table.get("entries", [])
	var rolls := int(table.get("rolls", 1))
	for _i in rolls:
		var idx := rng.weighted_pick(entries)
		if idx >= 0:
			var e: Dictionary = entries[idx]
			var count := rng.randi_range(int(e.get("min", 1)), int(e.get("max", 1)))
			result.append({ "item_id": e.get("item_id", ""), "count": count })
	return result
