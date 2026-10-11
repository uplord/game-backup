extends SceneTree
## Run: godot --headless --path . --script res://tests/world_entities_smoke_test.gd
const REPOSITORY = preload("res://data/content_repository.gd")
const REGISTRY = preload("res://world/map_registry.gd")

func _initialize() -> void:
    # Wait until the SceneTree and autoloads are initialized before loading content.
    call_deferred("_run")

func _run() -> void:
    var repo = REPOSITORY.new()
    root.add_child(repo)
    var errors_from_loader: Array = []
    repo.content_failed.connect(func(errors: Array): errors_from_loader.append_array(errors))
    if not repo.load_from_file("res://data/local/content.json"):
        printerr("FAIL: content failed to load: %s" % str(errors_from_loader))
        repo.queue_free()
        quit(1)
        return

    var expected := {
        "starter_town": ["plaza", "east_gate"],
        "forest": ["entrance", "clearing"],
        "mine": ["entrance"]
    }
    var count := 0
    for area_id in expected:
        for scene_id in expected[area_id]:
            var packed: PackedScene = REGISTRY.load_scene(area_id, scene_id)
            if packed == null:
                printerr("FAIL: missing scene %s/%s" % [area_id, scene_id])
                repo.queue_free()
                quit(1)
                return
            var map_node = packed.instantiate()
            if map_node == null:
                printerr("FAIL: could not instantiate %s/%s" % [area_id, scene_id])
                repo.queue_free()
                quit(1)
                return
            var validation_errors: Array[String] = map_node.validate_world_entities(repo)
            count += map_node.list_world_entities().size()
            map_node.free()
            if not validation_errors.is_empty():
                printerr("FAIL: %s/%s: %s" % [area_id, scene_id, str(validation_errors)])
                repo.queue_free()
                quit(1)
                return
    repo.queue_free()
    if count != 4:
        printerr("FAIL: expected four entity placements, found %d" % count)
        quit(1)
        return
    print("PASS: four placements, content IDs and scene entity validation")
    quit(0)
