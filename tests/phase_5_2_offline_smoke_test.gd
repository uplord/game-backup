extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var service := preload("res://data/published_content_service.gd").new()
    root.add_child(service)
    await process_frame
    assert(service.repository != null, "Missing repository")
    assert(service.repository.has_definition("resources", "copper_rock"), "Copper Rock missing")
    assert(not service.repository.content_version.is_empty(), "Missing content version")
    print("PASS: Phase 5.2 offline content fallback, version=", service.repository.content_version)
    service.queue_free()
    quit()
