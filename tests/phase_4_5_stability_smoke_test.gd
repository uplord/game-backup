extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene: PackedScene = load("res://world/areas/starter_town/scenes/plaza.tscn")
    if scene == null:
        _fail("Plaza scene missing")
        return
    var map: UplordMapBase = scene.instantiate() as UplordMapBase
    root.add_child(map)
    await process_frame
    var controller: UplordTargetingController = map.targeting
    var entities: Array[UplordWorldEntity] = map.list_world_entities()
    if entities.is_empty() or controller._interact_button == null:
        _fail("Entities or interaction HUD missing")
        return
    var entity: UplordWorldEntity = entities[0]
    controller.select_target(entity)
    if controller.selected_entity != entity or entity.reserved_slot_count() != 1:
        _fail("Click did not select and reserve a slot")
        return
    if not controller._interact_button.visible:
        _fail("Click approach did not show button")
        return
    controller.clear_target()
    if entity.reserved_slot_count() != 0:
        _fail("Clearing target leaked slot")
        return
    controller._player.global_position = entity.global_position + Vector2(0, 80)
    controller._update_nearby_entity()
    if not controller._interact_button.visible:
        _fail("Proximity did not show Interact button")
        return
    map.queue_free()
    await process_frame
    print("PASS: Phase 4.5 HUD, proximity, click approach, reservation cleanup")
    quit(0)

func _fail(message: String) -> void:
    push_error("FAIL: " + message)
    quit(1)
