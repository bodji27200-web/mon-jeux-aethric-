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
	print("- Combat")
	GameState.new_game()
	var eng := CombatEngine.new(RNG.new(42))
	eng.setup(GameState.player, "mob_rodeur_landes")
	var safety := 0
	while eng.is_ongoing() and safety < 100:
		eng.hero_use_skill("skl_frappe")
		safety += 1
	_check("le combat se termine", not eng.is_ongoing())
	_check("le héros gagne contre un rôdeur", eng.hero_won())
	_check("dégâts toujours >= 1", eng.compute_damage(0, eng.hero, eng.enemy) >= 1)

func _test_loot() -> void:
	print("- Loot")
	var eng := CombatEngine.new(RNG.new(7))
	eng.setup(GameState.player, "mob_rodeur_landes")
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
	GameState.grant_xp(50)
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
	GameState.battle_monster_id = "mob_rodeur_landes"
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
