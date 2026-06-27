extends Node
## Tests automatisés (logique pure). Lancer avec :
##   godot --headless res://tests/TestRunner.tscn
## Sort avec le code 0 si tout passe, 1 sinon.

var _passed := 0
var _failed := 0

func _ready() -> void:
	print("=== Tests Velmoria ===")
	_test_data_loaded()
	_test_combat_victory()
	_test_combat_group()
	_test_turn_order()
	_test_status_effects()
	_test_crit_dodge()
	_test_progression()
	_test_loot()
	_test_save_roundtrip()
	await _test_scenes_instantiate()
	print("=== Résultat : %d OK / %d KO ===" % [_passed, _failed])
	get_tree().quit(1 if _failed > 0 else 0)

func _check(label: String, cond: bool) -> void:
	if cond:
		_passed += 1
		print("  [OK] ", label)
	else:
		_failed += 1
		print("  [KO] ", label)

func _test_data_loaded() -> void:
	print("- DataRegistry")
	_check("classe sentinelle chargée", not DataRegistry.get_class_def("cls_sentinelle").is_empty())
	_check("monstre rôdeur chargé", not DataRegistry.get_monster("mob_rodeur_landes").is_empty())
	_check("compétence frappe chargée", not DataRegistry.get_skill("skl_frappe").is_empty())
	_check("table de loot chargée", not DataRegistry.get_loot_table("loot_lande").is_empty())

func _test_combat_victory() -> void:
	print("- Combat 1v1")
	GameState.new_game()
	var eng := CombatEngine.new(RNG.new(42))
	eng.setup(GameState.player, ["mob_rodeur_landes"])
	var safety := 0
	while eng.is_ongoing() and safety < 100:
		eng.hero_use_skill("skl_frappe", eng.first_alive_enemy())
		safety += 1
	_check("le combat se termine", not eng.is_ongoing())
	_check("le héros gagne contre un rôdeur", eng.hero_won())
	_check("dégâts toujours >= 1", eng.compute_damage(0, eng.hero, eng.enemies[0]) >= 1)

func _test_combat_group() -> void:
	print("- Combat de groupe")
	GameState.new_game()
	var eng := CombatEngine.new(RNG.new(3))
	eng.setup(GameState.player, ["mob_rodeur_landes", "mob_larve_spectrale"])
	_check("deux ennemis présents", eng.enemies.size() == 2)
	var safety := 0
	while eng.is_ongoing() and safety < 200:
		eng.hero_use_skill("skl_garde_appuyee", eng.first_alive_enemy())
		safety += 1
	_check("le combat de groupe se termine", not eng.is_ongoing())
	_check("XP cumulée des deux ennemis", eng.total_xp_reward() == 21)

func _test_turn_order() -> void:
	print("- Ordre des tours (vitesse)")
	GameState.new_game()
	# La larve (vitesse 11) est plus rapide que le héros (vitesse 7) : elle agit avant.
	var eng := CombatEngine.new(RNG.new(1))
	eng.setup(GameState.player, ["mob_larve_spectrale"])
	var hp_max := int(GameState.player["stats"]["hp"])
	_check("l'ennemi rapide frappe avant le 1er tour du héros", eng.hero["hp"] < hp_max)

func _test_status_effects() -> void:
	print("- Effets de statut")
	GameState.new_game()
	var eng := CombatEngine.new(RNG.new(1))
	eng.setup(GameState.player, ["mob_rodeur_landes"])
	# DoT : inflige des dégâts puis expire après sa durée.
	var e: Dictionary = eng.enemies[0]
	e["statuses"].append({ "id": "Corrosion", "type": "dot", "duration": 2, "magnitude": 5 })
	var hp0 := int(e["hp"])
	eng._tick_statuses(e)
	_check("le DoT inflige des dégâts", int(e["hp"]) == hp0 - 5)
	eng._tick_statuses(e)
	_check("le DoT expire après sa durée", e["statuses"].is_empty())
	# Debuff d'attaque.
	var atk0 := eng._effective_stat(eng.hero, "attack")
	eng.hero["statuses"].append({ "id": "Faiblesse", "type": "attack_down", "duration": 2, "magnitude": 3 })
	_check("le debuff réduit l'attaque", eng._effective_stat(eng.hero, "attack") == atk0 - 3)
	# La compétence Onde Corrosive applique bien un statut sur une cible vivante.
	var eng2 := CombatEngine.new(RNG.new(9))
	eng2.setup(GameState.player, ["mob_rodeur_landes"])
	eng2.hero_use_skill("skl_onde_corrosive", 0)
	var applied: bool = (not eng2.enemies[0]["statuses"].is_empty()) or eng2.enemies[0]["hp"] <= 0
	_check("Onde Corrosive applique un statut", applied)

func _test_crit_dodge() -> void:
	print("- Critique & esquive")
	var attacker := { "attack": 12, "crit_chance": 0.0, "crit_mult": 1.5, "dodge_chance": 0.0 }
	var defender := { "defense": 3, "dodge_chance": 0.0 }
	# Esquive garantie (dodge_chance 100).
	var eng := CombatEngine.new(RNG.new(1))
	var dodging := { "defense": 3, "dodge_chance": 100.0 }
	var res_dodge := eng.resolve_attack(10, attacker, dodging)
	_check("esquive à 100% -> attaque esquivée", res_dodge["dodged"])
	_check("esquive -> 0 dégât", int(res_dodge["damage"]) == 0)
	# Critique déterministe : même graine, avec/sans critique garanti.
	var eng_a := CombatEngine.new(RNG.new(123))
	var res_a := eng_a.resolve_attack(10, attacker, defender)
	var crit_attacker := { "attack": 12, "crit_chance": 100.0, "crit_mult": 2.0, "dodge_chance": 0.0 }
	var eng_b := CombatEngine.new(RNG.new(123))
	var res_b := eng_b.resolve_attack(10, crit_attacker, defender)
	_check("sans critique -> pas de crit", not res_a["crit"])
	_check("crit_chance 100% -> coup critique", res_b["crit"])
	_check("le critique applique x2", int(res_b["damage"]) == int(round(int(res_a["damage"]) * 2.0)))

func _test_progression() -> void:
	print("- Progression (niveaux)")
	GameState.new_game()
	var hp0 := int(GameState.player["stats"]["hp"])
	_check("niveau initial 1", int(GameState.player["level"]) == 1)
	_check("Onde Corrosive pas encore connue", not GameState.player["skills"].has("skl_onde_corrosive"))
	GameState.grant_xp(GameState.xp_to_next_level())   # juste assez pour le niveau 2
	_check("monte au niveau 2", int(GameState.player["level"]) == 2)
	_check("PV max augmenté selon la croissance", int(GameState.player["stats"]["hp"]) == hp0 + 8)
	_check("déblocage d'Onde Corrosive au niveau 2", GameState.player["skills"].has("skl_onde_corrosive"))
	# XP massive : plusieurs niveaux d'un coup, reste cohérent.
	GameState.new_game()
	GameState.grant_xp(1000)
	_check("XP massive fait gagner plusieurs niveaux", int(GameState.player["level"]) >= 3)
	_check("XP restante sous le prochain seuil", int(GameState.player["xp"]) < GameState.xp_to_next_level())

func _test_loot() -> void:
	print("- Loot")
	var eng := CombatEngine.new(RNG.new(7))
	eng.setup(GameState.player, ["mob_rodeur_landes"])
	var loot := eng.roll_loot()
	_check("le loot renvoie au moins une entrée", loot.size() >= 1)
	var valid := true
	for e in loot:
		if not DataRegistry.get_item(e["item_id"]).is_empty():
			continue
		valid = false
	_check("les objets du loot existent", valid)

func _test_save_roundtrip() -> void:
	print("- Sauvegarde")
	GameState.new_game()
	GameState.add_item("itm_eclat_quartz", 3)
	GameState.player["xp"] = 50      # valeurs posées directement (on teste le round-trip, pas le level-up)
	GameState.player["level"] = 4
	_check("sauvegarde écrite", SaveManager.save_game())
	GameState.new_game()  # on réinitialise pour vérifier le rechargement
	_check("après reset, xp = 0", int(GameState.player["xp"]) == 0)
	_check("chargement réussi", SaveManager.load_game())
	_check("xp restaurée (50)", int(GameState.player["xp"]) == 50)
	_check("niveau restauré (4)", int(GameState.player["level"]) == 4)
	_check("inventaire restauré (3 quartz)", int(GameState.inventory.get("itm_eclat_quartz", 0)) == 3)
	SaveManager.delete_save()

func _test_scenes_instantiate() -> void:
	print("- Scènes (smoke test)")
	GameState.new_game()
	GameState.battle_monster_ids = ["mob_rodeur_landes", "mob_larve_spectrale"]
	for path in [
		"res://scenes/boot/Boot.tscn",
		"res://scenes/world/World.tscn",
		"res://scenes/combat/Combat.tscn",
	]:
		var packed: PackedScene = load(path)
		var ok := packed != null
		if ok:
			var inst := packed.instantiate()
			ok = inst.get_script() != null  # script bien compilé et attaché
			add_child(inst)
			await get_tree().process_frame
			inst.queue_free()
			await get_tree().process_frame
		_check("instancie %s" % path.get_file(), ok)
