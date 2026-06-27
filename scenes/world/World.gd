extends Control
## Exploration de zone : déplacement tactile (tap-to-move) + déclenchement de rencontres.

var _player_marker: Control
var _target: Vector2
var _moving := false
var _hud_info: Label
var _rng := RNG.new()
var _zone := {}

const SPEED := 260.0          # pixels / seconde
const STEP_DISTANCE := 24.0   # distance parcourue avant un nouveau tirage de rencontre
var _accum_distance := 0.0

func _ready() -> void:
	_zone = DataRegistry.get_zone(GameState.current_zone)

	# Fond : image de la zone si disponible, sinon couleur unie (fallback).
	var bg_tex := Assets.texture(_zone.get("background", ""))
	if bg_tex != null:
		var bg_img := TextureRect.new()
		bg_img.texture = bg_tex
		bg_img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg_img)
	else:
		var bg := ColorRect.new()
		bg.color = Color(0.20, 0.30, 0.22)
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)

	# Bandeau sombre translucide en haut pour la lisibilité du texte sur l'image.
	var top_strip := ColorRect.new()
	top_strip.color = Color(0, 0, 0, 0.45)
	top_strip.position = Vector2(0, 40)
	top_strip.size = Vector2(720, 220)
	top_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_strip)

	# Bandeau d'info en haut.
	_hud_info = Label.new()
	_hud_info.add_theme_font_size_override("font_size", 28)
	_hud_info.position = Vector2(24, 60)
	_hud_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hud_info)
	_update_hud()

	# Indication.
	var hint := Label.new()
	hint.text = "Touche l'écran pour te déplacer.\nDes créatures rôdent dans les herbes."
	hint.add_theme_font_size_override("font_size", 22)
	hint.position = Vector2(24, 150)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)

	# Héros : sprite de la classe si disponible, sinon un carré (fallback).
	var cls := DataRegistry.get_class_def(GameState.player.get("class_id", ""))
	var hero_tex := Assets.texture(cls.get("sprite", ""))
	if hero_tex != null:
		var spr := TextureRect.new()
		spr.texture = hero_tex
		spr.size = Vector2(72, 72)
		spr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		_player_marker = spr
	else:
		var rect := ColorRect.new()
		rect.color = Color(0.42, 0.78, 0.75)
		rect.size = Vector2(48, 48)
		_player_marker = rect
	_player_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player_marker.position = Vector2(336, 620)
	add_child(_player_marker)
	_target = _player_marker.position

	# Boutons du bas : Sac (inventaire) + Sauvegarder.
	var bag_btn := Button.new()
	bag_btn.text = "Sac"
	bag_btn.custom_minimum_size = Vector2(180, 88)
	bag_btn.add_theme_font_size_override("font_size", 28)
	bag_btn.position = Vector2(40, 1140)
	bag_btn.pressed.connect(_toggle_inventory)
	add_child(bag_btn)

	var save_btn := Button.new()
	save_btn.text = "Sauvegarder"
	save_btn.custom_minimum_size = Vector2(280, 88)
	save_btn.add_theme_font_size_override("font_size", 28)
	save_btn.position = Vector2(260, 1140)
	save_btn.pressed.connect(_on_save)
	add_child(save_btn)

func _update_hud() -> void:
	var p := GameState.player
	var s := GameState.get_effective_stats()
	_hud_info.text = "%s — Niv.%d  PV %d/%d" % [
		_zone.get("display_name", "?"),
		int(p.get("level", 1)),
		int(p.get("current_hp", 0)),
		int(s.get("hp", 0)),
	]

# --- Inventaire ------------------------------------------------------------

var _inv_panel: Control = null

func _toggle_inventory() -> void:
	if _inv_panel != null:
		_inv_panel.queue_free()
		_inv_panel = null
		return
	_inv_panel = _build_inventory_panel()
	add_child(_inv_panel)

func _build_inventory_panel() -> Control:
	var panel := ColorRect.new()
	panel.color = Color(0.08, 0.07, 0.11, 0.95)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.position = Vector2(40, 80)
	box.custom_minimum_size = Vector2(640, 0)
	panel.add_child(box)

	var title := Label.new()
	title.text = "Sac & Équipement"
	title.add_theme_font_size_override("font_size", 34)
	box.add_child(title)

	# Équipement porté.
	var equip: Dictionary = GameState.player.get("equipment", {})
	for slot in ["weapon", "armor", "trinket"]:
		var id: String = equip.get(slot, "")
		var item_name := "—"
		if id != "":
			item_name = DataRegistry.get_item(id).get("display_name", id)
		var row := Label.new()
		row.text = "%s : %s" % [_slot_label(slot), item_name]
		row.add_theme_font_size_override("font_size", 24)
		box.add_child(row)

	var sep := Label.new()
	sep.text = "— Objets —"
	sep.add_theme_font_size_override("font_size", 26)
	box.add_child(sep)

	if GameState.inventory.is_empty():
		var empty := Label.new()
		empty.text = "(vide)"
		empty.add_theme_font_size_override("font_size", 22)
		box.add_child(empty)
	else:
		for item_id in GameState.inventory:
			var item := DataRegistry.get_item(item_id)
			var count := int(GameState.inventory[item_id])
			var hb := HBoxContainer.new()
			hb.add_theme_constant_override("separation", 12)
			var lbl := Label.new()
			lbl.text = "%s ×%d" % [item.get("display_name", item_id), count]
			lbl.add_theme_font_size_override("font_size", 24)
			lbl.custom_minimum_size = Vector2(420, 0)
			hb.add_child(lbl)
			if item.get("slot", "") in ["weapon", "armor", "trinket"]:
				var eq := Button.new()
				eq.text = "Équiper"
				eq.add_theme_font_size_override("font_size", 22)
				eq.pressed.connect(_on_equip.bind(item_id))
				hb.add_child(eq)
			box.add_child(hb)

	var close := Button.new()
	close.text = "Fermer"
	close.custom_minimum_size = Vector2(640, 80)
	close.add_theme_font_size_override("font_size", 28)
	close.pressed.connect(_toggle_inventory)
	box.add_child(close)
	return panel

func _slot_label(slot: String) -> String:
	match slot:
		"weapon": return "Arme"
		"armor": return "Armure"
		"trinket": return "Bijou"
	return slot

func _on_equip(item_id: String) -> void:
	if GameState.equip(item_id):
		_update_hud()
		# Reconstruire le panneau pour refléter le changement.
		if _inv_panel != null:
			_inv_panel.queue_free()
			_inv_panel = _build_inventory_panel()
			add_child(_inv_panel)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_target = event.position
		_moving = true
	elif event is InputEventMouseButton and event.pressed:
		_target = event.position
		_moving = true

func _process(delta: float) -> void:
	if not _moving:
		return
	var center := _player_marker.position + _player_marker.size * 0.5
	var to_target := _target - center
	var dist := to_target.length()
	if dist < 4.0:
		_moving = false
		return
	var step := minf(SPEED * delta, dist)
	_player_marker.position += to_target.normalized() * step
	_accum_distance += step
	while _accum_distance >= STEP_DISTANCE:
		_accum_distance -= STEP_DISTANCE
		_roll_encounter()
		if not _moving:
			return

func _roll_encounter() -> void:
	var chance := float(_zone.get("encounter_step_chance", 0.0))
	if _rng.randf() < chance:
		_moving = false
		var table: Array = _zone.get("encounter_table", [])
		var group_min := int(_zone.get("encounter_group_min", 1))
		var group_max := int(_zone.get("encounter_group_max", 1))
		var count := _rng.randi_range(group_min, group_max)
		var group: Array = []
		for _i in count:
			var idx := _rng.weighted_pick(table)
			if idx >= 0:
				group.append(table[idx].get("monster_id", ""))
		if not group.is_empty():
			GameState.battle_monster_ids = group
			SceneRouter.goto("res://scenes/combat/Combat.tscn")

func _on_save() -> void:
	if SaveManager.save_game():
		_hud_info.text = "Partie sauvegardée."
		await get_tree().create_timer(1.0).timeout
		_update_hud()
