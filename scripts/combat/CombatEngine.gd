class_name CombatEngine
extends RefCounted
## Combat tour par tour : 1 héros contre un groupe d'ennemis (1..n).
## Ordre des tours basé sur la vitesse (initiative recalculée à chaque manche).
## Logique pure, sans UI -> testable en headless.

var rng: RNG

var hero := {}
var enemies: Array = []          # chaque ennemi est un Dictionary (copie de travail)
var log_lines: Array[String] = []

var _order: Array = []           # éléments : -1 pour le héros, sinon index d'ennemi (>=0)
const HERO := -1
var _order_pos := 0
var round_num := 0

func _init(rng_instance: RNG = null) -> void:
	rng = rng_instance if rng_instance != null else RNG.new()

## Prépare le combat. monster_ids : liste d'identifiants de monstres.
func setup(hero_state: Dictionary, monster_ids: Array) -> void:
	hero = {
		"name": "Héros",
		"hp": int(hero_state.get("current_hp", 1)),
		"max_hp": int(hero_state["stats"].get("hp", 1)),
		"mana": int(hero_state.get("current_mana", 0)),
		"attack": int(hero_state["stats"].get("attack", 1)),
		"defense": int(hero_state["stats"].get("defense", 0)),
		"speed": int(hero_state["stats"].get("speed", 0)),
		"crit_chance": float(hero_state["stats"].get("crit_chance", 0)),
		"crit_mult": float(hero_state["stats"].get("crit_mult", 1.5)),
		"dodge_chance": float(hero_state["stats"].get("dodge_chance", 0)),
		"skills": hero_state.get("skills", []),
		"statuses": [],
	}
	enemies.clear()
	for mid in monster_ids:
		var m := DataRegistry.get_monster(mid)
		if m.is_empty():
			continue
		var s: Dictionary = m.get("stats", {})
		enemies.append({
			"id": mid,
			"name": m.get("display_name", "Ennemi"),
			"hp": int(s.get("hp", 1)),
			"max_hp": int(s.get("hp", 1)),
			"attack": int(s.get("attack", 1)),
			"defense": int(s.get("defense", 0)),
			"speed": int(s.get("speed", 0)),
			"crit_chance": float(s.get("crit_chance", 0)),
			"crit_mult": float(s.get("crit_mult", 1.5)),
			"dodge_chance": float(s.get("dodge_chance", 0)),
			"xp_reward": int(m.get("xp_reward", 0)),
			"loot_table_id": m.get("loot_table_id", ""),
			"statuses": [],
		})
	_begin_round()

# --- Déroulé des manches ----------------------------------------------------

func _begin_round() -> void:
	round_num += 1
	# Liste d'initiative : tous les acteurs vivants, triés par vitesse décroissante.
	# En cas d'égalité, le héros agit en premier.
	var actors: Array = []
	actors.append({ "ref": HERO, "speed": int(hero["speed"]), "hero": true })
	for i in enemies.size():
		if enemies[i]["hp"] > 0:
			actors.append({ "ref": i, "speed": int(enemies[i]["speed"]), "hero": false })
	actors.sort_custom(func(a, b):
		if a["speed"] == b["speed"]:
			return a["hero"] and not b["hero"]
		return a["speed"] > b["speed"])
	_order = []
	for a in actors:
		_order.append(a["ref"])
	_order_pos = 0
	_advance_until_hero()

## Fait jouer les ennemis jusqu'à tomber sur le tour du héros (ou la fin du combat).
func _advance_until_hero() -> void:
	while _order_pos < _order.size():
		if not is_ongoing():
			return
		var idx := int(_order[_order_pos])
		if idx == HERO:
			if hero["hp"] > 0:
				_tick_statuses(hero)        # altérations en début de tour du héros
				if hero["hp"] > 0:
					return                  # on attend l'action du joueur
			_order_pos += 1
			continue
		if idx < enemies.size() and enemies[idx]["hp"] > 0:
			_tick_statuses(enemies[idx])    # altérations en début de tour de l'ennemi
			if enemies[idx]["hp"] > 0:
				_enemy_act(idx)
		_order_pos += 1
	# Manche terminée : on recommence si le combat continue.
	if is_ongoing():
		_begin_round()

func _enemy_act(idx: int) -> void:
	var e: Dictionary = enemies[idx]
	var res := resolve_attack(8, e, hero)
	if res["dodged"]:
		log_lines.append("Héros esquive l'attaque de %s !" % e["name"])
		return
	hero["hp"] = max(0, hero["hp"] - int(res["damage"]))
	log_lines.append("%s attaque : %d dégâts%s." % [
		e["name"], int(res["damage"]), "  CRITIQUE !" if res["crit"] else ""])
	if hero["hp"] <= 0:
		log_lines.append("Héros est tombé...")

# --- Action du héros --------------------------------------------------------

## Le héros utilise une compétence sur l'ennemi ciblé. Renvoie true si jouée.
func hero_use_skill(skill_id: String, target_index: int) -> bool:
	if not is_ongoing() or not is_hero_turn():
		return false
	var skill := DataRegistry.get_skill(skill_id)
	if skill.is_empty():
		return false
	var cost := int(skill.get("resource_cost", {}).get("amount", 0))
	if hero["mana"] < cost:
		log_lines.append("Pas assez d'énergie pour %s." % skill.get("display_name", skill_id))
		return false
	var target := _resolve_target(target_index)
	if target < 0:
		return false
	hero["mana"] -= cost
	if int(skill.get("power", 0)) > 0 and skill.get("effect_type", "") == "damage":
		var res := resolve_attack(int(skill.get("power", 0)), hero, enemies[target])
		if res["dodged"]:
			log_lines.append("%s esquive %s !" % [
				enemies[target]["name"], skill.get("display_name", skill_id)])
		else:
			enemies[target]["hp"] = max(0, enemies[target]["hp"] - int(res["damage"]))
			log_lines.append("%s sur %s : %d dégâts%s." % [
				skill.get("display_name", skill_id), enemies[target]["name"],
				int(res["damage"]), "  CRITIQUE !" if res["crit"] else ""])
	if enemies[target]["hp"] > 0:
		_apply_status_effects(skill, enemies[target])
	if enemies[target]["hp"] <= 0:
		log_lines.append("%s est vaincu !" % enemies[target]["name"])
	_order_pos += 1
	_advance_until_hero()
	return true

## Le héros utilise un objet consommable (ex. potion de soin). Renvoie true si joué.
## La gestion de l'inventaire (retrait de l'objet) est faite par l'appelant.
func hero_use_item(item_id: String) -> bool:
	if not is_ongoing() or not is_hero_turn():
		return false
	var item := DataRegistry.get_item(item_id)
	var on_use: Dictionary = item.get("on_use", {})
	if on_use.get("effect_type", "") == "heal":
		var heal := int(on_use.get("power", 0))
		var before := int(hero["hp"])
		hero["hp"] = min(int(hero["max_hp"]), before + heal)
		log_lines.append("Héros utilise %s : +%d PV." % [
			item.get("display_name", item_id), int(hero["hp"]) - before])
	_order_pos += 1
	_advance_until_hero()
	return true

## Renvoie un index d'ennemi vivant : la cible demandée si valide, sinon le premier vivant.
func _resolve_target(target_index: int) -> int:
	if target_index >= 0 and target_index < enemies.size() and enemies[target_index]["hp"] > 0:
		return target_index
	return first_alive_enemy()

func first_alive_enemy() -> int:
	for i in enemies.size():
		if enemies[i]["hp"] > 0:
			return i
	return -1

func is_hero_turn() -> bool:
	return _order_pos < _order.size() and int(_order[_order_pos]) == HERO and hero["hp"] > 0

# --- État du combat ---------------------------------------------------------

func is_ongoing() -> bool:
	return hero["hp"] > 0 and first_alive_enemy() >= 0

func hero_won() -> bool:
	return hero["hp"] > 0 and first_alive_enemy() < 0

func hero_lost() -> bool:
	return hero["hp"] <= 0

func total_xp_reward() -> int:
	var total := 0
	for e in enemies:
		total += int(e.get("xp_reward", 0))
	return total

# --- Dégâts & loot ----------------------------------------------------------

## Formule de dégâts du projet : max(1, power + attaque - défense) avec légère variance.
## L'attaque/défense effectives tiennent compte des altérations (buffs/debuffs) actives.
func compute_damage(power: int, attacker: Dictionary, defender: Dictionary) -> int:
	var raw := power + _effective_stat(attacker, "attack") - _effective_stat(defender, "defense")
	raw = max(1, raw)
	var variance := rng.randi_range(-1, 1)
	return max(1, raw + variance)

## Résout une attaque complète : esquive éventuelle, dégâts, puis coup critique.
## Renvoie { "damage": int, "dodged": bool, "crit": bool }.
func resolve_attack(power: int, attacker: Dictionary, defender: Dictionary) -> Dictionary:
	if rng.randf() * 100.0 < float(defender.get("dodge_chance", 0)):
		return { "damage": 0, "dodged": true, "crit": false }
	var dmg := compute_damage(power, attacker, defender)
	var crit := rng.randf() * 100.0 < float(attacker.get("crit_chance", 0))
	if crit:
		dmg = max(1, int(round(dmg * float(attacker.get("crit_mult", 1.5)))))
	return { "damage": dmg, "dodged": false, "crit": crit }

## Valeur d'une stat après application des modificateurs de statut (atk_down / def_down).
func _effective_stat(actor: Dictionary, stat: String) -> int:
	var value := int(actor.get(stat, 0))
	for s in actor.get("statuses", []):
		if s.get("type", "") == stat + "_down":
			value -= int(s.get("magnitude", 0))
	return max(0, value)

## Applique les effets de statut d'une compétence à la cible.
func _apply_status_effects(skill: Dictionary, target: Dictionary) -> void:
	for eff in skill.get("status_effects", []):
		target["statuses"].append({
			"id": eff.get("id", "effet"),
			"type": eff.get("type", "dot"),
			"duration": int(eff.get("duration", 1)),
			"magnitude": int(eff.get("magnitude", 0)),
		})
		log_lines.append("%s subit : %s." % [target["name"], eff.get("id", "effet")])

## Résout les altérations en début de tour de l'acteur (DoT) puis décrémente leur durée.
func _tick_statuses(actor: Dictionary) -> void:
	var remaining: Array = []
	for s in actor.get("statuses", []):
		if s.get("type", "") == "dot":
			var dmg := int(s.get("magnitude", 0))
			actor["hp"] = max(0, int(actor["hp"]) - dmg)
			log_lines.append("%s subit %d dégâts (%s)." % [actor["name"], dmg, s.get("id", "dot")])
		s["duration"] = int(s.get("duration", 1)) - 1
		if int(s["duration"]) > 0 and actor["hp"] > 0:
			remaining.append(s)
	actor["statuses"] = remaining
	if actor["hp"] <= 0:
		log_lines.append("%s succombe à ses blessures." % actor["name"])

## Butin cumulé de tous les ennemis vaincus : [{ "item_id", "count" }].
func roll_loot() -> Array:
	var result: Array = []
	for e in enemies:
		var table := DataRegistry.get_loot_table(e.get("loot_table_id", ""))
		if table.is_empty():
			continue
		var entries: Array = table.get("entries", [])
		for _i in int(table.get("rolls", 1)):
			var idx := rng.weighted_pick(entries)
			if idx >= 0:
				var entry: Dictionary = entries[idx]
				var count := rng.randi_range(int(entry.get("min", 1)), int(entry.get("max", 1)))
				result.append({ "item_id": entry.get("item_id", ""), "count": count })
	return result
