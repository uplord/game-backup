extends SceneTree
func _initialize() -> void:
    var service = preload("res://data/published_content_service.gd")
    var fields := {
        "publishedVersion": {"stringValue": "v0.0.1"},
        "bundle": {"mapValue": {"fields": {
            "content_version": {"stringValue": "v0.0.1"},
            "definitions": {"mapValue": {"fields": {"resources": {"arrayValue": {"values": [{"mapValue": {"fields": {"id": {"stringValue": "copper_rock"}, "level": {"integerValue": "1"}}}}]}}}}}
        }}}
    }
    var decoded: Dictionary = service._decode_firestore_fields(fields)
    assert(decoded["publishedVersion"] == "v0.0.1")
    assert(decoded["bundle"]["definitions"]["resources"][0]["level"] == 1)
    print("PASS: Firestore typed document decoding")
    quit()
