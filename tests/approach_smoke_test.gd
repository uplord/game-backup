extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene: PackedScene = load("res://world/areas/starter_town/scenes/plaza.tscn")
    if scene == null:
        push_error("FAIL: cannot load plaza")
        quit(1)
        return
    var map: UplordMapBase = scene.instantiate()
    root.add_child(map)
    await process_frame
    var entities: Array[UplordWorldEntity] = map.list_world_entities()
    if entities.is_empty() or map.targeting == null:
        push_error("FAIL: missing entities or targeting")
        quit(1)
        return
    map.targeting.select_target(entities[0])
    if map.targeting.selected_entity != entities[0]:
        push_error("FAIL: selection")
        quit(1)
        return
    if entities[0].interaction_radius < 150.0:
        push_error("FAIL: interaction radius was not increased")
        quit(1)
        return
    var standing_point: Vector2 = map.targeting._choose_approach_point()
    if standing_point.y < entities[0].global_position.y:
        push_error("FAIL: approach point is above entity")
        quit(1)
        return
    var offset: Vector2 = standing_point - entities[0].global_position
    if offset.length() < entities[0].visual_clearance_radius + entities[0].player_clearance:
        push_error("FAIL: standing point overlaps entity clearance")
        quit(1)
        return
    if offset.y < absf(offset.x) * tan(deg_to_rad(map.targeting.minimum_south_angle_degrees)) - 0.01:
        push_error("FAIL: standing point is not in the lower approach arc")
        quit(1)
        return
    map.targeting.clear_target()
    if map.targeting.selected_entity != null:
        push_error("FAIL: deselection")
        quit(1)
        return
    print("PASS: approach selection and cancellation")
    map.queue_free()
    await process_frame
    quit(0)
