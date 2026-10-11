extends SceneTree

func _initialize() -> void:
    var packed: PackedScene = load("res://characters/player/player_controller.tscn")
    assert(packed != null, "Player controller scene failed to load")
    var player: CharacterBody2D = packed.instantiate()
    assert(player != null, "Player controller failed to instantiate")
    root.add_child.call_deferred(player)
    _check.call_deferred(player)

func _check(player: CharacterBody2D) -> void:
    assert(player.has_method("set_destination"))
    assert(player.has_method("stop_moving"))
    player.set_destination(Vector2(200, 300))
    assert(player.has_destination)
    player.stop_moving()
    assert(not player.has_destination)
    assert(player.get_node_or_null("PlayerCharacter") != null)
    print("PASS: Phase 2.2 player controller, movement target, stop and modular visuals")
    quit(0)
