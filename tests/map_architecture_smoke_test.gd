extends SceneTree

func _initialize() -> void:
    var registry = load("res://world/map_registry.gd")
    for map_id in ["starter_town", "forest", "mine"]:
        var scene: PackedScene = registry.load_map(map_id)
        if scene == null:
            push_error("FAIL: cannot load map " + map_id)
            quit(1)
            return
        var map = scene.instantiate()
        if map == null or map.map_id != map_id or map.player_visual_scale <= 0.0:
            push_error("FAIL: invalid map settings " + map_id)
            quit(1)
            return
        map.free()
    print("PASS: map scenes and per-map visual scales")
    quit(0)
