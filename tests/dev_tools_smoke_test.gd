extends SceneTree
const DIAGNOSTICS = preload("res://core/dev/startup_diagnostics.gd")
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var diagnostics: Dictionary = DIAGNOSTICS.inspect()
    if not diagnostics["ok"]:
        printerr("FAIL: startup diagnostics: %s" % str(diagnostics["issues"]))
        quit(1)
        return
    DevLogger.clear()
    DevLogger.info("test", "test event", {"count": 1})
    var history: Array[Dictionary] = DevLogger.entries()
    if history.size() != 1 or history[0]["category"] != "test":
        printerr("FAIL: logger did not retain entry")
        quit(1)
        return
    history[0]["message"] = "tampered"
    if DevLogger.entries()[0]["message"] != "test event":
        printerr("FAIL: logger history is mutable")
        quit(1)
        return
    print("PASS: Phase 1.4 startup diagnostics and structured logging")
    quit(0)
