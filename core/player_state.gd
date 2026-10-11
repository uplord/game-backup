extends RefCounted
class_name UplordPlayerState
## Local snapshot. The server will own authoritative player data later.
var character_id: String = ""
var display_name: String = ""
var area_id: StringName = &""
var instance_id: int = 0
var position: Vector2 = Vector2.ZERO
var hp: int = 100
var max_hp: int = 100
var mp: int = 100
var max_mp: int = 100
var skill_xp: Dictionary = {}

func reset() -> void:
    character_id = ""
    display_name = ""
    area_id = &""
    instance_id = 0
    position = Vector2.ZERO
    hp = 100
    max_hp = 100
    mp = 100
    max_mp = 100
    skill_xp.clear()

func to_snapshot() -> Dictionary:
    return {"character_id": character_id, "display_name": display_name,
        "area_id": String(area_id), "instance_id": instance_id,
        "position": {"x": position.x, "y": position.y},
        "hp": hp, "max_hp": max_hp, "mp": mp, "max_mp": max_mp,
        "skill_xp": skill_xp.duplicate(true)}
