extends SceneTree
const DIAGNOSTICS = preload("res://core/dev/startup_diagnostics.gd")
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var report: Dictionary = DIAGNOSTICS.inspect()
    if not report["ok"]:
        printerr("FAIL: %s" % str(report["issues"]))
        quit(1)
        return
    print("PASS: startup files, autoload configuration, content bundle v%s" % report["content_version"])
    quit(0)
