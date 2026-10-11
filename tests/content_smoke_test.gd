extends SceneTree
## Run: godot --headless --path . --script res://tests/content_smoke_test.gd
const REPOSITORY = preload("res://data/content_repository.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var repo = REPOSITORY.new()
	root.add_child(repo)
	if not repo.load_from_file("res://data/local/content.json"):
		printerr("FAIL: sample content did not load")
		quit(1)
		return
	# Verify the actual JSON parsing path (numeric 1 is parsed as 1.0 by Godot).
	var json_bundle: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/local/content.json"))
	if typeof(json_bundle) != TYPE_DICTIONARY or not UplordContentValidator.validate_bundle(json_bundle).is_empty():
		printerr("FAIL: parsed JSON schema version was rejected")
		quit(1)
		return
	if not repo.has_definition("items", "copper_ore"):
		printerr("FAIL: copper ore missing")
		quit(1)
		return
	var item := repo.get_definition("items", "copper_ore")
	item["name"] = "Changed"
	if repo.get_definition("items", "copper_ore")["name"] != "Copper Ore":
		printerr("FAIL: repository exposed mutable content")
		quit(1)
		return
	var bad := {"schema_version": 1, "content_version": "bad", "definitions": {"recipes": [{"id":"bad_recipe", "name":"Bad Recipe", "ingredients":[{"item_id":"missing_item"}], "outputs":[]}]}}
	if repo.load_bundle(bad):
		printerr("FAIL: broken reference was accepted")
		quit(1)
		return
	if repo.content_version != "0.1.0-local":
		printerr("FAIL: rejected content replaced the working snapshot")
		quit(1)
		return
	print("PASS: content load, lookup, defensive copy, reference validation, atomic replacement")
	quit(0)
