extends Node2D
## Client entry point. Keep rendering and Phantom Camera setup here later.
const STARTUP_DIAGNOSTICS = preload("res://core/dev/startup_diagnostics.gd")

func _ready() -> void:
    if not GameManager.initialize(GameManager.MODE_CLIENT):
        push_error("Client bootstrap failed")
        return
    var diagnostics: Dictionary = STARTUP_DIAGNOSTICS.inspect()
    if not diagnostics["ok"]:
        for issue in diagnostics["issues"]:
            DevLogger.error("startup", issue)
        push_error("Uplord startup checks failed")
        return
    DevLogger.info("startup", "Uplord client ready", {"content_version": PublishedContent.repository.content_version, "content_source": PublishedContent.source})

    if OS.is_debug_build():
        add_child(preload("res://ui/debug/debug_overlay.gd").new())
