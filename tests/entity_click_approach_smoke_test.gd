extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://world/areas/starter_town/scenes/plaza.tscn")
    if packed == null:
        _fail("Plaza missing")
        return
    var map: UplordMapBase = packed.instantiate() as UplordMapBase
    root.add_child(map)
    await process_frame
    var entities: Array[UplordWorldEntity] = map.list_world_entities()
    if entities.is_empty():
        _fail("No entities")
        return
    var target: UplordWorldEntity = entities[0]
    var controller: UplordTargetingController = map.targeting
    if target.reserved_slot_count() != 0:
        _fail("Proximity alone reserved a slot")
        return
    target.interaction_requested.emit(target)
    if controller.selected_entity != target or target.reserved_slot_count() != 1:
        _fail("Entity click did not select and reserve a slot")
        return
    if controller.interaction_state != UplordTargetingController.InteractionState.APPROACHING and controller.interaction_state != UplordTargetingController.InteractionState.INTERACTING:
        _fail("Entity click did not start approach")
        return
    controller.clear_target()
    if target.reserved_slot_count() != 0:
        _fail("Cancellation did not release slot")
        return
    print("PASS: entity click starts approach; cancellation releases slot")
    quit(0)

func _fail(message: String) -> void:
    push_error("FAIL: " + message)
    quit(1)
