extends RefCounted
class_name UplordContentValidator
## Validates local and CMS-published content without modifying it.
const TYPES := ["items", "enemies", "skills", "areas", "resources", "recipes", "npcs", "quests", "loot_tables", "shops", "objects"]
static func validate_bundle(bundle: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    # Godot JSON.parse_string() represents JSON numbers as floats (1 becomes 1.0).
    # Accept the numeric schema version 1 from JSON and integer 1 from GDScript,
    # but reject strings, booleans and any other version.
    var schema_version: Variant = bundle.get("schema_version", null)
    if (typeof(schema_version) != TYPE_INT and typeof(schema_version) != TYPE_FLOAT) or schema_version != 1:
        errors.append("schema_version must be integer 1")
    if not bundle.has("content_version") or typeof(bundle.get("content_version")) != TYPE_STRING or str(bundle.get("content_version", "")).is_empty():
        errors.append("content_version must be a non-empty string")
    var definitions: Variant = bundle.get("definitions")
    if typeof(definitions) != TYPE_DICTIONARY:
        errors.append("definitions must be an object")
        return errors
    var seen: Dictionary = {}
    for type_id in definitions.keys():
        if not TYPES.has(str(type_id)):
            errors.append("Unknown content type: %s" % type_id)
            continue
        var entries: Variant = definitions[type_id]
        if typeof(entries) != TYPE_ARRAY:
            errors.append("%s must be an array" % type_id)
            continue
        seen[type_id] = {}
        for entry in entries:
            if typeof(entry) != TYPE_DICTIONARY:
                errors.append("%s entry must be an object" % type_id)
                continue
            var id: Variant = entry.get("id", "")
            if typeof(id) != TYPE_STRING or not _valid_id(id):
                errors.append("Invalid %s ID: %s" % [type_id, id])
                continue
            if seen[type_id].has(id):
                errors.append("Duplicate %s ID: %s" % [type_id, id])
            seen[type_id][id] = true
            if typeof(entry.get("name", null)) != TYPE_STRING or str(entry.get("name", "")).strip_edges().is_empty():
                errors.append("%s/%s requires name" % [type_id, id])
    for type_id in definitions.keys():
        if not TYPES.has(str(type_id)) or typeof(definitions[type_id]) != TYPE_ARRAY:
            continue
        for entry in definitions[type_id]:
            if typeof(entry) != TYPE_DICTIONARY:
                continue
            var id := str(entry.get("id", "<invalid>"))
            if type_id == "recipes":
                _check_refs(errors, seen, "recipes/%s ingredients" % id, entry.get("ingredients", []), "items", "item_id")
                _check_refs(errors, seen, "recipes/%s outputs" % id, entry.get("outputs", []), "items", "item_id")
            if type_id == "loot_tables":
                _check_refs(errors, seen, "loot_tables/%s entries" % id, entry.get("entries", []), "items", "item_id")
            if type_id == "enemies" and entry.has("loot_table_id"):
                _check_ref(errors, seen, "enemies/%s" % id, "loot_tables", entry["loot_table_id"])
            if type_id == "resources":
                if entry.has("item_id"):
                    _check_ref(errors, seen, "resources/%s" % id, "items", entry["item_id"])
                if entry.has("skill_id"):
                    _check_ref(errors, seen, "resources/%s" % id, "skills", entry["skill_id"])
                _check_nonnegative(errors, "resources/%s required_level" % id, entry, "required_level")
                _check_nonnegative(errors, "resources/%s respawn_seconds" % id, entry, "respawn_seconds")
            if type_id == "enemies":
                _check_nonnegative(errors, "enemies/%s level" % id, entry, "level")
                _check_nonnegative(errors, "enemies/%s max_hp" % id, entry, "max_hp")
            if type_id == "items" and entry.has("stackable") and typeof(entry["stackable"]) != TYPE_BOOL:
                errors.append("items/%s stackable must be a boolean" % id)
            if type_id == "quests":
                _check_refs(errors, seen, "quests/%s rewards" % id, entry.get("rewards", []), "items", "item_id")
            if type_id == "shops":
                _check_refs(errors, seen, "shops/%s stock" % id, entry.get("stock", []), "items", "item_id")
            if type_id == "recipes" and entry.has("skill_id"):
                _check_ref(errors, seen, "recipes/%s" % id, "skills", entry["skill_id"])
    return errors
static func _valid_id(value: String) -> bool:
    if value.is_empty():
        return false
    for c in value:
        if not (c >= "a" and c <= "z") and not (c >= "0" and c <= "9") and c != "_":
            return false
    return true
static func _check_refs(errors: Array[String], seen: Dictionary, label: String, values: Variant, target: String, field: String) -> void:
    if typeof(values) != TYPE_ARRAY:
        errors.append("%s must be an array" % label)
        return
    for value in values:
        if typeof(value) != TYPE_DICTIONARY or not value.has(field):
            errors.append("%s entry missing %s" % [label, field])
            continue
        _check_ref(errors, seen, label, target, value[field])
static func _check_ref(errors: Array[String], seen: Dictionary, label: String, target: String, ref_id: Variant) -> void:
    if typeof(ref_id) != TYPE_STRING or not seen.get(target, {}).has(ref_id):
        errors.append("%s references missing %s/%s" % [label, target, ref_id])

static func _check_nonnegative(errors: Array[String], label: String, entry: Dictionary, field: String) -> void:
    if not entry.has(field):
        return
    var value: Variant = entry[field]
    if (typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT) or value < 0:
        errors.append("%s must be a non-negative number" % label)
