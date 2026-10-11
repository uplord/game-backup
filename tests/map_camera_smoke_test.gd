extends SceneTree
func _initialize() -> void:
	var scene: PackedScene = load("res://characters/player/movement_preview.tscn")
	assert(scene != null, "Movement preview scene missing")
	var root: Node = scene.instantiate()
	assert(root != null, "Movement preview cannot instantiate")
	assert(root.get_node_or_null("Camera2D") != null, "Camera missing")
	assert(root.get_node_or_null("PlayerController") != null, "Player missing")
	print("PASS: Phase 2.3 camera scene and player")
	root.free()
	quit()
