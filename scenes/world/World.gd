extends Control
## Exploration de zone : déplacement tactile (tap-to-move) + déclenchement de rencontres.

var _player_marker: ColorRect
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

	var bg := ColorRect.new()
	bg.color = Color(0.20, 0.30, 0.22)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Bandeau d'info en haut.
	_hud_info = Label.new()
	_hud_info.add_theme_font_size_override("font_size", 28)
	_hud_info.position = Vector2(24, 60)
	add_child(_hud_info)
	_update_hud()

	# Indication.
	var hint := Label.new()
	hint.text = "Touche l'écran pour te déplacer.\nDes créatures rôdent dans les herbes."
	hint.add_theme_font_size_override("font_size", 22)
	hint.position = Vector2(24, 150)
	add_child(hint)

	# Marqueur du joueur.
	_player_marker = ColorRect.new()
	_player_marker.color = Color(0.42, 0.78, 0.75)
	_player_marker.size = Vector2(48, 48)
	_player_marker.position = Vector2(336, 620)
	add_child(_player_marker)
	_target = _player_marker.position

	# Bouton sauvegarder (en bas).
	var save_btn := Button.new()
	save_btn.text = "Sauvegarder"
	save_btn.custom_minimum_size = Vector2(280, 88)
	save_btn.add_theme_font_size_override("font_size", 28)
	save_btn.position = Vector2(220, 1140)
	save_btn.pressed.connect(_on_save)
	add_child(save_btn)

func _update_hud() -> void:
	var p := GameState.player
	_hud_info.text = "%s — Niv.%d  PV %d/%d" % [
		_zone.get("display_name", "?"),
		int(p.get("level", 1)),
		int(p.get("current_hp", 0)),
		int(p["stats"].get("hp", 0)),
	]

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
