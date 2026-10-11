extends SceneTree
## Run: godot --headless --path . --script res://tests/core_smoke_test.gd
func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    var state := UplordPlayerState.new()
    state.character_id = "test"
    state.skill_xp["mining"] = 25
    var snapshot := state.to_snapshot()
    assert(snapshot["character_id"] == "test")
    assert(snapshot["skill_xp"]["mining"] == 25)
    state.reset()
    assert(state.character_id == "")
    assert(state.skill_xp.is_empty())
    print("PASS: player state snapshot and reset")
    quit(0)
