extends SceneTree
const REPO = preload("res://data/content_repository.gd")
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var repo = REPO.new()
    root.add_child(repo)
    if not repo.load_from_file("res://data/local/content.json"):
        printerr("FAIL: local content rejected")
        quit(1)
        return
    var copper: Dictionary = repo.get_definition("resources", "copper_rock")
    if copper.get("required_level") != 1 or copper.get("respawn_seconds") != 30:
        printerr("FAIL: copper rock metadata missing")
        quit(1)
        return
    var invalid: Dictionary = {"schema_version":1,"content_version":"bad","definitions":{"resources":[{"id":"bad_rock","name":"Bad Rock","skill_id":"missing_skill"}]}}
    if repo.load_bundle(invalid):
        printerr("FAIL: broken resource skill accepted")
        quit(1)
        return
    if repo.content_version != "0.2.0-local":
        printerr("FAIL: invalid bundle replaced snapshot")
        quit(1)
        return
    print("PASS: Phase 5 content metadata and reference checks")
    quit(0)
