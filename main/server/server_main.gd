extends Node
## Run using: godot --headless --path . res://main/server/server_main.tscn
## No listener is started yet; networking is a later phase.
const STARTUP_DIAGNOSTICS = preload("res://core/dev/startup_diagnostics.gd")

func _ready() -> void:
    if not GameManager.initialize(GameManager.MODE_SERVER):
        push_error("Server bootstrap failed")
        return
    var diagnostics: Dictionary = STARTUP_DIAGNOSTICS.inspect()
    if not diagnostics["ok"]:
        for issue in diagnostics["issues"]:
            DevLogger.error("startup", issue)
        push_error("Uplord startup checks failed")
        return
    DevLogger.info("startup", "Uplord server ready", {"content_version": diagnostics["content_version"]})
