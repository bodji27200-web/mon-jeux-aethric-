extends Node
## Transitions de scènes. Libère la scène précédente pour limiter la mémoire sur mobile.

func goto(scene_path: String) -> void:
	call_deferred("_deferred_goto", scene_path)

func _deferred_goto(scene_path: String) -> void:
	var tree := get_tree()
	var current := tree.current_scene
	if current != null:
		current.queue_free()
	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("SceneRouter: scène introuvable: %s" % scene_path)
		return
	var instance := packed.instantiate()
	tree.root.add_child(instance)
	tree.current_scene = instance
