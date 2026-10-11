extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed := load("res://world/world_preview.tscn") as PackedScene
    if packed == null:
        _fail("preview scene missing")
        return
    var world := packed.instantiate()
    root.add_child(world)
    await process_frame
    await process_frame
    if world.current_area != "starter_town" or world.current_scene != "plaza":
        _fail("initial spawn")
        return
    var original_id: int = world.current_instance_id
    if original_id <= 0:
        _fail("no area instance assigned")
        return
    if not world.open_scene("starter_town", "east_gate", "default"):
        _fail("same-area transition")
        return
    if world.current_instance_id != original_id:
        _fail("same-area transition changed instance")
        return
    await process_frame
    await process_frame
    if not world.open_scene("forest", "entrance", "default"):
        _fail("cross-area transition")
        return
    if world.instance_manager.population("starter_town") != 0 or world.instance_manager.population("forest") != 1:
        _fail("instance membership on area change")
        return
    var snapshot: Dictionary = world.get_world_location()
    if snapshot.get("scene_id") != "entrance" or snapshot.get("area_id") != "forest":
        _fail("location snapshot")
        return
    await process_frame
    await process_frame
    if not world.restore_world_location({"area_id":"starter_town", "scene_id":"plaza", "spawn_id":"default"}):
        _fail("restore location")
        return
    if world.open_scene("missing_area", "missing_scene"):
        _fail("invalid destination accepted")
        return
    if world.current_area != "starter_town" or world.current_scene != "plaza":
        _fail("invalid destination replaced active scene")
        return
    world.queue_free()
    await process_frame
    await process_frame
    print("PASS: world loading, transitions, instance membership, location restore")
    quit(0)

func _fail(reason: String) -> void:
    push_error("FAIL: " + reason)
    quit(1)
