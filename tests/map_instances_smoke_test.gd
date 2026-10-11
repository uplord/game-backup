extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var manager := UplordMapInstanceManager.new()
    root.add_child(manager)
    manager.default_capacity = 2
    manager.area_capacities = {"forest": 1}
    var a := manager.join_area("alice", "starter_town", "plaza")
    var b := manager.join_area("bob", "starter_town", "east_gate")
    _check(int(a.get("instance_id", 0)) == 1, "first instance")
    _check(int(b.get("instance_id", 0)) == 1, "two scenes share same area instance")
    var first := manager.get_instance("starter_town", 1)
    _check(first.members.size() == 2, "capacity reached")
    _check(first.count_in_scene("plaza") == 1, "plaza population")
    _check(first.count_in_scene("east_gate") == 1, "east gate population")
    var c := manager.join_area("charlie", "starter_town", "plaza")
    _check(int(c.get("instance_id", 0)) == 2, "overflow creates second instance")
    var a2 := manager.join_area("alice", "starter_town", "east_gate")
    _check(int(a2.get("instance_id", 0)) == 1, "same-area scene transfer retains instance")
    _check(first.count_in_scene("east_gate") == 2, "scene transfer population")
    _check(manager.join_area("nobody", "unknown", "entrance").is_empty(), "invalid area rejected")
    var moved := manager.join_area("alice", "forest", "entrance")
    _check(int(moved.get("instance_id", 0)) == 1, "cross-area travel allocates forest instance")
    _check(manager.population("starter_town") == 2, "old area count reduced")
    _check(manager.leave_area("bob"), "disconnect releases slot")
    _check(manager.get_instance("starter_town", 1) == null, "empty instance removed")
    manager.clear_all()
    _check(manager.population("starter_town") == 0, "reset")
    manager.queue_free()
    print("PASS: map instances, area capacity, scene membership, travel, cleanup")
    quit(0)

func _check(condition: bool, message: String) -> void:
    if not condition:
        push_error("FAIL: " + message)
        quit(1)
