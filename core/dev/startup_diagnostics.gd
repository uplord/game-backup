extends RefCounted
class_name UplordStartupDiagnostics
## Read-only checks; does not mutate game or connect to external services.
const CONTENT_REPOSITORY = preload("res://data/content_repository.gd")
const CONTENT_PATH := "res://data/local/content.json"

static func inspect() -> Dictionary:
    var issues: Array[String] = []
    for path in ["res://main/client/main.tscn", "res://main/server/server_main.tscn", CONTENT_PATH]:
        if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
            issues.append("Missing required file: %s" % path)
    for name in ["GameManager", "GameState", "EventBus", "ServiceRegistry", "DevLogger"]:
        if not ProjectSettings.has_setting("autoload/" + name):
            issues.append("Missing autoload: %s" % name)
    var content_version := ""
    if FileAccess.file_exists(CONTENT_PATH):
        var repo = CONTENT_REPOSITORY.new()
        var validation_errors: Array[String] = []
        repo.content_failed.connect(func(errors: Array):
            for item in errors:
                validation_errors.append(str(item))
        )
        if repo.load_from_file(CONTENT_PATH):
            content_version = repo.content_version
        else:
            issues.append_array(validation_errors)
        repo.free()
    return {"ok": issues.is_empty(), "issues": issues, "content_version": content_version, "godot_version": Engine.get_version_info().get("string", "unknown")}
