extends Node
class_name UplordContentRepository
## Read-only snapshot loaded from a local file; replace loader for CMS releases later.
signal content_loaded(version: String)
signal content_failed(errors: Array)
const VALIDATOR = preload("res://data/content_validator.gd")
var content_version: String = ""
var _definitions: Dictionary = {}
func load_from_file(path: String) -> bool:
    if not FileAccess.file_exists(path):
        content_failed.emit(["Missing content file: %s" % path])
        return false
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if typeof(parsed) != TYPE_DICTIONARY:
        content_failed.emit(["Invalid JSON object: %s" % path])
        return false
    return load_bundle(parsed)
func load_bundle(bundle: Dictionary) -> bool:
    var errors: Array[String] = VALIDATOR.validate_bundle(bundle)
    if not errors.is_empty():
        content_failed.emit(errors)
        return false
    var new_definitions: Dictionary = {}
    for type_id in bundle["definitions"].keys():
        var indexed: Dictionary = {}
        for entry in bundle["definitions"][type_id]:
            indexed[entry["id"]] = entry.duplicate(true)
        new_definitions[type_id] = indexed
    _definitions = new_definitions
    content_version = bundle["content_version"]
    content_loaded.emit(content_version)
    return true
func get_definition(type_id: String, content_id: String) -> Dictionary:
    var entry: Dictionary = _definitions.get(type_id, {}).get(content_id, {})
    return entry.duplicate(true)
func list_definitions(type_id: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for entry in _definitions.get(type_id, {}).values():
        result.append(entry.duplicate(true))
    return result
func has_definition(type_id: String, content_id: String) -> bool:
    return _definitions.get(type_id, {}).has(content_id)
