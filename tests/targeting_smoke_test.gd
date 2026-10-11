extends SceneTree

func _initialize() -> void:
    call_deferred("run_test")

func run_test() -> void:
    var scene: PackedScene = load("res://world/areas/starter_town/scenes/plaza.tscn")
    if scene == null:
        push_error("FAIL: plaza scene missing")
        quit(1)
        return
    var map := scene.instantiate() as UplordMapBase
    root.add_child(map)
    await process_frame
    if map.targeting == null or map.list_world_entities().size() < 2:
        push_error("FAIL: targeting not configured")
        quit(1)
        return
    var entities := map.list_world_entities()
    map.targeting.select_target(entities[0])
    if map.targeting.selected_entity != entities[0] or not entities[0].is_selected:
        push_error("FAIL: target selection")
        quit(1)
        return
    map.targeting.select_target(entities[1])
    if entities[0].is_selected or not entities[1].is_selected:
        push_error("FAIL: exclusive selection")
        quit(1)
        return
    map.player.ground_clicked.emit()
    if map.targeting.selected_entity != null or entities[1].is_selected:
        push_error("FAIL: ground click clears target")
        quit(1)
        return
    if map.player.move_speed != 480.0:
        push_error("FAIL: expected 480 movement speed")
        quit(1)
        return
    print("PASS: selection, replacement, deselection, speed")
    map.queue_free()
    await process_frame
    quit(0)
