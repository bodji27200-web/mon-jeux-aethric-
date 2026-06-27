extends Control
## Combat tour par tour contre un groupe d'ennemis.
## Le joueur choisit une cible (parmi les ennemis vivants) puis une compétence.

var _engine: CombatEngine
var _hero_label: Label
var _enemies_box: VBoxContainer
var _log_label: Label
var _action_box: VBoxContainer
var _selected_target := 0
var _enemy_buttons: Array = []

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.10, 0.16)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_engine = CombatEngine.new()
	_engine.setup(GameState.player, GameState.battle_monster_ids)
	_selected_target = _engine.first_alive_enemy()

	var title := Label.new()
	title.text = "Combat !"
	title.position = Vector2(48, 60)
	title.add_theme_font_size_override("font_size", 34)
	add_child(title)

	_enemies_box = VBoxContainer.new()
	_enemies_box.add_theme_constant_override("separation", 10)
	_enemies_box.position = Vector2(48, 120)
	add_child(_enemies_box)

	_hero_label = _make_label(48, 360, 30)
	add_child(_hero_label)

	_log_label = _make_label(48, 440, 24)
	_log_label.custom_minimum_size = Vector2(624, 280)
	add_child(_log_label)

	_action_box = VBoxContainer.new()
	_action_box.add_theme_constant_override("separation", 14)
	_action_box.position = Vector2(48, 760)
	add_child(_action_box)

	_build_enemies()
	_build_actions()
	_refresh()

func _make_label(x: float, y: float, font_size: int) -> Label:
	var l := Label.new()
	l.position = Vector2(x, y)
	l.add_theme_font_size_override("font_size", font_size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size = Vector2(624, 0)
	return l

func _build_enemies() -> void:
	for c in _enemies_box.get_children():
		c.queue_free()
	_enemy_buttons.clear()
	for i in _engine.enemies.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(624, 64)
		b.add_theme_font_size_override("font_size", 26)
		b.pressed.connect(_on_select_target.bind(i))
		_enemies_box.add_child(b)
		_enemy_buttons.append(b)

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
		b.custom_minimum_size = Vector2(624, 92)
		b.add_theme_font_size_override("font_size", 30)
		b.pressed.connect(_on_skill.bind(skill_id))
		_action_box.add_child(b)

func _on_select_target(i: int) -> void:
	if i < _engine.enemies.size() and _engine.enemies[i]["hp"] > 0:
		_selected_target = i
		_refresh()

func _on_skill(skill_id: String) -> void:
	if not _engine.is_ongoing():
		return
	if _selected_target < 0 or _engine.enemies[_selected_target]["hp"] <= 0:
		_selected_target = _engine.first_alive_enemy()
	_engine.hero_use_skill(skill_id, _selected_target)
	if _selected_target < 0 or _engine.enemies[_selected_target]["hp"] <= 0:
		_selected_target = _engine.first_alive_enemy()
	_refresh()
	if not _engine.is_ongoing():
		_end_combat()

func _refresh() -> void:
	for i in _enemy_buttons.size():
		var e: Dictionary = _engine.enemies[i]
		var b: Button = _enemy_buttons[i]
		var marker := "▶ " if i == _selected_target and e["hp"] > 0 else ""
		if e["hp"] > 0:
			b.text = "%s%s — PV %d/%d" % [marker, e["name"], e["hp"], e["max_hp"]]
			b.disabled = false
		else:
			b.text = "%s (vaincu)" % e["name"]
			b.disabled = true
	_hero_label.text = "Héros — PV %d/%d   Énergie %d" % [
		_engine.hero["hp"], _engine.hero["max_hp"], _engine.hero["mana"]]
	_log_label.text = "\n".join(_engine.log_lines.slice(-7))

func _end_combat() -> void:
	for child in _action_box.get_children():
		child.queue_free()

	if _engine.hero_won():
		var xp := _engine.total_xp_reward()
		GameState.grant_xp(xp)
		var loot := _engine.roll_loot()
		var loot_text := ""
		for entry in loot:
			GameState.add_item(entry["item_id"], entry["count"])
			var item := DataRegistry.get_item(entry["item_id"])
			loot_text += "\n+ %d × %s" % [entry["count"], item.get("display_name", entry["item_id"])]
		GameState.full_restore()
		SaveManager.save_game()
		_log_label.text = "VICTOIRE !\n+%d XP%s\n\n(Sauvegarde automatique)" % [xp, loot_text]
	else:
		GameState.full_restore()
		_log_label.text = "Tu as été mis K.O.\nTu te réveilles, soigné, dans la clairière."

	var back := Button.new()
	back.text = "Retour à la zone"
	back.custom_minimum_size = Vector2(624, 92)
	back.add_theme_font_size_override("font_size", 30)
	back.pressed.connect(func() -> void:
		GameState.battle_monster_ids = []
		SceneRouter.goto("res://scenes/world/World.tscn"))
	_action_box.add_child(back)
