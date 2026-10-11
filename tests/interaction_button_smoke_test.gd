extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://world/areas/starter_town/scenes/plaza.tscn")
    if packed == null:
        _fail("plaza scene missing")
        return
    var map: UplordMapBase = packed.instantiate() as UplordMapBase
    root.add_child(map)
    await process_frame
    var controller: UplordTargetingController = map.targeting
    if controller == null or controller._interact_button == null:
        _fail("interaction HUD missing")
        return
    if controller._interact_button.visible or not controller._interact_button.disabled:
        _fail("button should start hidden and disabled")
        return
    var entities := map.list_world_entities()
    if entities.is_empty():
        _fail("plaza has no entities")
        return
    controller.select_target(entities[0])
    if not controller._interact_button.visible or not controller._interact_button.disabled:
        _fail("button should appear disabled while approaching")
        return
    controller._player.global_position = entities[0].slot_position(controller._reserved_slot)
    controller._player.stop_moving()
    await physics_frame
    await physics_frame
    if not controller.target_in_range or controller._interact_button.disabled:
        _fail("button should enable at reserved slot")
        return
    var events: Array[String] = []
    controller.interaction_activated.connect(func(_entity: UplordWorldEntity, action: String) -> void: events.append(action))
    controller.activate_interaction()
    if events.size() != 1:
        _fail("interact did not emit")
        return
    controller.clear_target()
    if controller._interact_button.visible:
        _fail("button remains visible after deselect")
        return
    map.queue_free()
    await process_frame
    print("PASS: contextual interaction button, range and action signal")
    quit(0)

func _fail(message: String) -> void:
    push_error("FAIL: " + message)
    quit(1)
