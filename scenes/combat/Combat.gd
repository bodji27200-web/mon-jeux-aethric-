extends Control
## Combat tour par tour (1v1). Le héros choisit une compétence ; le monstre riposte.

var _engine: CombatEngine
var _hero_label: Label
var _enemy_label: Label
var _log_label: Label
var _action_box: VBoxContainer

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.10, 0.16)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_engine = CombatEngine.new()
	_engine.setup(GameState.player, GameState.battle_monster_id)

	_enemy_label = _make_label(48, 90, 36)
	add_child(_enemy_label)

	_hero_label = _make_label(48, 200, 30)
	add_child(_hero_label)

	_log_label = _make_label(48, 320, 24)
	_log_label.custom_minimum_size = Vector2(624, 360)
	add_child(_log_label)

	_action_box = VBoxContainer.new()
	_action_box.add_theme_constant_override("separation", 16)
	_action_box.position = Vector2(48, 760)
	add_child(_action_box)

	_build_actions()
	_refresh()

func _make_label(x: float, y: float, font_size: int) -> Label:
	var l := Label.new()
	l.position = Vector2(x, y)
	l.add_theme_font_size_override("font_size", font_size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size = Vector2(624, 0)
	return l

func _build_actions() -> void:
	for child in _action_box.get_children():
		child.queue_free()
	for skill_id in _engine.hero.get("skills", []):
		var skill := DataRegistry.get_skill(skill_id)
		if skill.is_empty():
			continue
		var b := Button.new()
		var cost := int(skill.get("resource_cost", {}).get("amount", 0))
		b.text = "%s%s" % [skill.get("display_name", skill_id),
			("  (-%d énergie)" % cost) if cost > 0 else ""]
		b.custom_minimum_size = Vector2(624, 96)
		b.add_theme_font_size_override("font_size", 30)
		b.pressed.connect(_on_skill.bind(skill_id))
		_action_box.add_child(b)

func _on_skill(skill_id: String) -> void:
	if not _engine.is_ongoing():
		return
	_engine.hero_use_skill(skill_id)
	_refresh()
	if not _engine.is_ongoing():
		_end_combat()

func _refresh() -> void:
	_enemy_label.text = "%s — PV %d/%d" % [
		_engine.enemy["name"], _engine.enemy["hp"], _engine.enemy["max_hp"]]
	_hero_label.text = "Héros — PV %d/%d   Énergie %d" % [
		_engine.hero["hp"], _engine.hero["max_hp"], _engine.hero["mana"]]
	_log_label.text = "\n".join(_engine.log_lines.slice(-8))

func _end_combat() -> void:
	for child in _action_box.get_children():
		child.queue_free()

	if _engine.hero_won():
		GameState.grant_xp(_engine.enemy.get("xp_reward", 0))
		var loot := _engine.roll_loot()
		var loot_text := ""
		for entry in loot:
			GameState.add_item(entry["item_id"], entry["count"])
			var item := DataRegistry.get_item(entry["item_id"])
			loot_text += "\n+ %d × %s" % [entry["count"], item.get("display_name", entry["item_id"])]
		GameState.full_restore()
		SaveManager.save_game()
		_log_label.text = "VICTOIRE !\n+%d XP%s\n\n(Sauvegarde automatique)" % [
			_engine.enemy.get("xp_reward", 0), loot_text]
	else:
		# Défaite : on soigne le héros et on le renvoie en zone (pas de game over dur au lot 1).
		GameState.full_restore()
		_log_label.text = "Tu as été mis K.O.\nTu te réveilles, soigné, dans la clairière."

	var back := Button.new()
	back.text = "Retour à la zone"
	back.custom_minimum_size = Vector2(624, 96)
	back.add_theme_font_size_override("font_size", 30)
	back.pressed.connect(func() -> void:
		GameState.battle_monster_id = ""
		SceneRouter.goto("res://scenes/world/World.tscn"))
	_action_box.add_child(back)
