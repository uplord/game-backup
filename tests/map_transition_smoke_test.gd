extends SceneTree
func _initialize() -> void:
	var registry = load("res://world/map_registry.gd")
	var expected := {"starter_town":["plaza","east_gate"], "forest":["entrance","clearing"], "mine":["entrance"]}
	for area_id in expected:
		for scene_id in expected[area_id]:
			var packed: PackedScene = registry.load_scene(area_id, scene_id)
			if packed == null:
				push_error("FAIL: missing %s/%s" % [area_id, scene_id]); quit(1); return
			var map_node = packed.instantiate()
			if map_node == null or map_node.get_node_or_null("Exits") == null or map_node.get_node_or_null("Spawns/default") == null:
				push_error("FAIL: missing map nodes in %s/%s" % [area_id, scene_id]); quit(1); return
			for exit_node in map_node.get_node("Exits").get_children():
				if not registry.has_scene(exit_node.destination_area, exit_node.destination_scene):
					push_error("FAIL: broken exit in %s/%s" % [area_id, scene_id]); quit(1); return
			map_node.free()
	print("PASS: five linked scenes, spawn markers, exit destinations")
	quit(0)
