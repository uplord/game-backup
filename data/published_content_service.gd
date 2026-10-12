extends Node
## Read-only Cloud Firestore release loader. Never include service account credentials in clients.
signal snapshot_ready(version: String, source: String)
signal refresh_failed(reason: String)

const REPOSITORY = preload("res://data/content_repository.gd")
const LOCAL_PATH := "res://data/local/content.json"
const CACHE_PATH := "user://published_content_cache.json"
const CONFIG_PATH := "res://data/firebase_content_config.json"

var repository: UplordContentRepository
var source: String = ""
var _request: HTTPRequest
var _config: Dictionary = {}
var _request_stage: String = ""
var _project_id: String = ""
var _database_id: String = "(default)"

func _ready() -> void:
    repository = REPOSITORY.new()
    add_child(repository)
    _request = HTTPRequest.new()
    _request.timeout = 12.0
    add_child(_request)
    _request.request_completed.connect(_on_request_completed)
    _config = _read_json(CONFIG_PATH)
    load_offline_snapshot()
    if bool(_config.get("enabled", false)):
        refresh()

func load_offline_snapshot() -> bool:
    for candidate in [CACHE_PATH, LOCAL_PATH]:
        var bundle := _read_json(candidate)
        if not bundle.is_empty() and repository.load_bundle(bundle):
            source = "cache" if candidate == CACHE_PATH else "local"
            snapshot_ready.emit(repository.content_version, source)
            return true
    refresh_failed.emit("No valid cached or bundled content snapshot")
    return false

func refresh() -> void:
    if _request_stage != "" or _request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
        return
    _project_id = str(_config.get("project_id", "")).strip_edges()
    _database_id = str(_config.get("database_id", "(default)")).strip_edges()
    var config_doc := str(_config.get("published_config_document", "content_config/current")).strip_edges()
    if not _valid_segment(_project_id) or not _valid_segment(_database_id) or not _valid_document_path(config_doc):
        refresh_failed.emit("Invalid Firestore project/database/config document configuration")
        return
    _fetch_document(config_doc, "config")

func _valid_segment(value: String) -> bool:
    if value.is_empty() or value == "." or value == "..":
        return false
    for character in value:
        if not (character.is_valid_identifier() or character in "-()."):
            return false
    return not value.contains("/")

func _valid_document_path(path: String) -> bool:
    var parts := path.split("/", false)
    if parts.size() < 2 or parts.size() % 2 != 0:
        return false
    for part in parts:
        if not _valid_segment(part):
            return false
    return true

func _fetch_document(path: String, stage: String) -> void:
    var url := "https://firestore.googleapis.com/v1/projects/%s/databases/%s/documents/%s" % [_project_id, _database_id.uri_encode(), path]
    _request_stage = stage
    var error := _request.request(url, ["Accept: application/json"], HTTPClient.METHOD_GET)
    if error != OK:
        _request_stage = ""
        refresh_failed.emit("Firestore request could not start: %s" % error)

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    var stage := _request_stage
    _request_stage = ""
    if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
        refresh_failed.emit("Firestore %s fetch failed (result %d, HTTP %d); retaining %s snapshot" % [stage, result, response_code, source])
        return
    var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
    if typeof(parsed) != TYPE_DICTIONARY or typeof(parsed.get("fields")) != TYPE_DICTIONARY:
        refresh_failed.emit("Invalid Firestore document response")
        return
    var document: Dictionary = _decode_firestore_fields(parsed["fields"])
    if stage == "config":
        var version := str(document.get("publishedVersion", ""))
        if version.is_empty() or not _valid_segment(version):
            refresh_failed.emit("Missing or invalid publishedVersion in content_config/current")
            return
        var releases_collection := str(_config.get("releases_collection", "content_releases"))
        if not _valid_segment(releases_collection):
            refresh_failed.emit("Invalid releases collection")
            return
        _fetch_document("%s/%s" % [releases_collection, version], "release")
    elif stage == "release":
        # A release document contains a `bundle` map with content_version and definitions.
        var bundle: Variant = document.get("bundle", {})
        if typeof(bundle) != TYPE_DICTIONARY:
            refresh_failed.emit("Published release is missing its bundle map")
            return
        # The repository validates before changing active content.
        if not repository.load_bundle(bundle):
            refresh_failed.emit("Published Firestore content failed validation; retaining previous snapshot")
            return
        source = "firestore"
        _write_cache(bundle)
        snapshot_ready.emit(repository.content_version, source)

static func _decode_firestore_fields(fields: Dictionary) -> Dictionary:
    var result := {}
    for key in fields:
        result[key] = _decode_firestore_value(fields[key])
    return result

static func _decode_firestore_value(value: Variant) -> Variant:
    if typeof(value) != TYPE_DICTIONARY:
        return null
    if value.has("mapValue"):
        return _decode_firestore_fields(value["mapValue"].get("fields", {}))
    if value.has("arrayValue"):
        var items := []
        for item in value["arrayValue"].get("values", []):
            items.append(_decode_firestore_value(item))
        return items
    if value.has("stringValue"):
        return str(value["stringValue"])
    if value.has("integerValue"):
        return int(value["integerValue"])
    if value.has("doubleValue"):
        return float(value["doubleValue"])
    if value.has("booleanValue"):
        return bool(value["booleanValue"])
    if value.has("nullValue"):
        return null
    return null

func _read_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func _write_cache(bundle: Dictionary) -> void:
    var file := FileAccess.open(CACHE_PATH + ".tmp", FileAccess.WRITE)
    if file == null:
        push_warning("Unable to write published content cache")
        return
    file.store_string(JSON.stringify(bundle))
    file.close()
    var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(CACHE_PATH + ".tmp"), ProjectSettings.globalize_path(CACHE_PATH))
    if err != OK:
        push_warning("Unable to replace published content cache: %s" % err)
