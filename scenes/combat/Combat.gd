extends Control
## Combat tour par tour contre un groupe d'ennemis, avec présentation animée :
## sprites, sélection de cible, dégâts flottants et flash de coup.

var _engine: CombatEngine
var _hero_label: Label
var _hero_sprite: Control
var _log_label: Label
var _action_box: VBoxContainer
var _selected_target := 0

# Pour chaque ennemi : un panneau { "select": Button, "sprite": Control }.
var _enemy_panels: Array = []

func _ready() -> void:
	# Fond : on réutilise l'ambiance de la zone courante si une image existe.
	var zone := DataRegistry.get_zone(GameState.current_zone)
	var bg_tex := Assets.texture(zone.get("background", ""))
	if bg_tex != null:
		var bg_img := TextureRect.new()
		bg_img.texture = bg_tex
		bg_img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg_img.modulate = Color(0.6, 0.6, 0.7)  # assombri pour lisibilité
		add_child(bg_img)
	var dark := ColorRect.new()
	dark.color = Color(0.08, 0.07, 0.11, 0.55)
	dark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dark)

	_engine = CombatEngine.new()
	_engine.setup(GameState.player, GameState.battle_monster_ids)
	_selected_target = _engine.first_alive_enemy()

	var title := Label.new()
	title.text = "Combat !"
	title.position = Vector2(48, 56)
	title.add_theme_font_size_override("font_size", 34)
	add_child(title)

	# Rangée d'ennemis avec sprites.
	var enemies_row := HBoxContainer.new()
	enemies_row.add_theme_constant_override("separation", 24)
	enemies_row.position = Vector2(48, 120)
	add_child(enemies_row)
	_build_enemies(enemies_row)

	# Héros : sprite + infos.
	var cls := DataRegistry.get_class_def(GameState.player.get("class_id", ""))
	_hero_sprite = _make_sprite(cls.get("sprite", ""), Color(0.42, 0.78, 0.75))
	_hero_sprite.position = Vector2(60, 430)
	add_child(_hero_sprite)

	_hero_label = _make_label(180, 450, 28)
	add_child(_hero_label)

	_log_label = _make_label(48, 560, 24)
	_log_label.custom_minimum_size = Vector2(624, 220)
	add_child(_log_label)

	_action_box = VBoxContainer.new()
	_action_box.add_theme_constant_override("separation", 14)
	_action_box.position = Vector2(48, 800)
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

## Crée un nœud sprite (TextureRect) avec fallback carré coloré.
func _make_sprite(path: String, fallback: Color) -> Control:
	var tex := Assets.texture(path)
	if tex != null:
		var spr := TextureRect.new()
		spr.texture = tex
		spr.custom_minimum_size = Vector2(96, 96)
		spr.size = Vector2(96, 96)
		spr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		return spr
	var rect := ColorRect.new()
	rect.color = fallback
	rect.custom_minimum_size = Vector2(72, 72)
	rect.size = Vector2(72, 72)
	return rect

func _build_enemies(row: HBoxContainer) -> void:
	_enemy_panels.clear()
	for i in _engine.enemies.size():
		var e: Dictionary = _engine.enemies[i]
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 6)
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		var sprite := _make_sprite(DataRegistry.get_monster(e["id"]).get("sprite", ""),
			Color(0.7, 0.4, 0.4))
		col.add_child(sprite)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(190, 56)
		btn.add_theme_font_size_override("font_size", 22)
		btn.pressed.connect(_on_select_target.bind(i))
		col.add_child(btn)
		row.add_child(col)
		_enemy_panels.append({ "select": btn, "sprite": sprite })

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
		b.custom_minimum_size = Vector2(624, 88)
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

	# Instantané des PV avant l'action pour animer les dégâts.
	var hero_before := int(_engine.hero["hp"])
	var enemies_before: Array = []
	for e in _engine.enemies:
		enemies_before.append(int(e["hp"]))

	_engine.hero_use_skill(skill_id, _selected_target)

	# Animations : dégâts flottants + flash sur les acteurs touchés.
	for i in _engine.enemies.size():
		var delta: int = int(enemies_before[i]) - int(_engine.enemies[i]["hp"])
		if delta > 0:
			var spr: Control = _enemy_panels[i]["sprite"]
			_flash(spr)
			_float_number("-%d" % delta, Color(1, 0.5, 0.4), spr.global_position + Vector2(40, 0))
	var hero_delta := hero_before - int(_engine.hero["hp"])
	if hero_delta > 0:
		_flash(_hero_sprite)
		_float_number("-%d" % hero_delta, Color(1, 0.6, 0.5), _hero_sprite.global_position + Vector2(40, 0))

	if _selected_target < 0 or _engine.enemies[_selected_target]["hp"] <= 0:
		_selected_target = _engine.first_alive_enemy()
	_refresh()
	if not _engine.is_ongoing():
		_end_combat()

## Flash blanc/rouge bref sur un sprite touché.
func _flash(node: Control) -> void:
	if node == null:
		return
	var t := create_tween()
	t.tween_property(node, "modulate", Color(1.6, 0.6, 0.6), 0.08)
	t.tween_property(node, "modulate", Color(1, 1, 1), 0.18)

## Affiche un nombre qui monte et s'efface (dégâts).
func _float_number(text: String, color: Color, pos: Vector2) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 34)
	lbl.add_theme_color_override("font_color", color)
	lbl.global_position = pos
	add_child(lbl)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(lbl, "global_position", pos + Vector2(0, -70), 0.7)
	t.tween_property(lbl, "modulate", Color(color.r, color.g, color.b, 0.0), 0.7)
	t.chain().tween_callback(lbl.queue_free)

func _refresh() -> void:
	for i in _enemy_panels.size():
		var e: Dictionary = _engine.enemies[i]
		var btn: Button = _enemy_panels[i]["select"]
		var spr: Control = _enemy_panels[i]["sprite"]
		var marker := "▶ " if i == _selected_target and e["hp"] > 0 else ""
		if e["hp"] > 0:
			btn.text = "%s%s\nPV %d/%d" % [marker, e["name"], e["hp"], e["max_hp"]]
			btn.disabled = false
			spr.modulate = Color(1, 1, 1)
		else:
			btn.text = "%s (vaincu)" % e["name"]
			btn.disabled = true
			spr.modulate = Color(0.3, 0.3, 0.3, 0.5)
	_hero_label.text = "Héros\nPV %d/%d   Énergie %d" % [
		_engine.hero["hp"], _engine.hero["max_hp"], _engine.hero["mana"]]
	_log_label.text = "\n".join(_engine.log_lines.slice(-6))

func _end_combat() -> void:
	for child in _action_box.get_children():
		child.queue_free()

	if _engine.hero_won():
		var xp := _engine.total_xp_reward()
		var lvl_before := int(GameState.player["level"])
		GameState.grant_xp(xp)
		var loot := _engine.roll_loot()
		var loot_text := ""
		for entry in loot:
			GameState.add_item(entry["item_id"], entry["count"])
			var item := DataRegistry.get_item(entry["item_id"])
			loot_text += "\n+ %d × %s" % [entry["count"], item.get("display_name", entry["item_id"])]
		var lvl_text := ""
		if int(GameState.player["level"]) > lvl_before:
			lvl_text = "\nNIVEAU %d atteint !" % int(GameState.player["level"])
		GameState.full_restore()
		SaveManager.save_game()
		_log_label.text = "VICTOIRE !\n+%d XP%s%s\n\n(Sauvegarde automatique)" % [xp, lvl_text, loot_text]
	else:
		GameState.full_restore()
		_log_label.text = "Tu as été mis K.O.\nTu te réveilles, soigné, dans la clairière."

	var back := Button.new()
	back.text = "Retour à la zone"
	back.custom_minimum_size = Vector2(624, 88)
	back.add_theme_font_size_override("font_size", 30)
	back.pressed.connect(func() -> void:
		GameState.battle_monster_ids = []
		SceneRouter.goto("res://scenes/world/World.tscn"))
	_action_box.add_child(back)
