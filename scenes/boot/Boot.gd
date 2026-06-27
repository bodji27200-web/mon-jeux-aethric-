extends Control
## Écran de lancement : titre + Nouvelle partie / Continuer.

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.17, 0.14, 0.25)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.add_theme_constant_override("separation", 24)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(box)

	var title := Label.new()
	title.text = "VELMORIA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Clairière des Brumes"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 28)
	box.add_child(subtitle)

	box.add_child(_make_button("Nouvelle partie", _on_new_game))

	if SaveManager.has_save():
		box.add_child(_make_button("Continuer", _on_continue))

func _make_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(360, 96)
	b.add_theme_font_size_override("font_size", 32)
	b.pressed.connect(cb)
	return b

func _on_new_game() -> void:
	SaveManager.delete_save()
	GameState.new_game()
	SceneRouter.goto("res://scenes/world/World.tscn")

func _on_continue() -> void:
	SaveManager.load_game()
	SceneRouter.goto("res://scenes/world/World.tscn")
