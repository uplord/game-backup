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
    var targets: Array[UplordWorldEntity] = map.list_world_entities()
    if targets.size() < 2:
        _fail("Expected two entities")
        return
    var targeting: UplordTargetingController = map.targeting
    targeting.select_target(targets[0])
    if targets[0].reserved_slot_count() != 1:
        _fail("Initial slot not reserved")
        return
    targeting.select_target(targets[1])
    if targets[0].reserved_slot_count() != 0 or targets[1].reserved_slot_count() != 1:
        _fail("Switch did not transfer reservation")
        return
    targeting._player.manual_movement_started.emit()
    if targeting.selected_entity != null or targets[1].reserved_slot_count() != 0:
        _fail("Manual movement did not cancel target")
        return
    targeting.select_target(targets[0])
    targeting._player.ground_clicked.emit()
    if targeting.selected_entity != null or targets[0].reserved_slot_count() != 0:
        _fail("Ground click did not cancel target")
        return
    targeting.select_target(targets[0])
    targeting.queue_free()
    await process_frame
    if targets[0].reserved_slot_count() != 0:
        _fail("Controller teardown leaked slot")
        return
    map.queue_free()
    await process_frame
    print("PASS: targeting integration, cancellation and slot cleanup")
    quit(0)

func _fail(message: String) -> void:
    push_error("FAIL: " + message)
    quit(1)
