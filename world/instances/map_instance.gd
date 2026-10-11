extends RefCounted
class_name UplordMapInstance
## One shared area instance; members can occupy different scenes of that area.
var area_id: String
var instance_id: int
var capacity: int
var members: Dictionary = {} # player_id -> scene_id

func _init(p_area_id: String, p_instance_id: int, p_capacity: int) -> void:
	area_id = p_area_id
	instance_id = p_instance_id
	capacity = maxi(1, p_capacity)

func has_space() -> bool:
	return members.size() < capacity

func join(player_id: String, scene_id: String) -> bool:
	if player_id.is_empty() or not UplordMapRegistry.has_scene(area_id, scene_id):
		return false
	if members.has(player_id):
		members[player_id] = scene_id
		return true
	if not has_space():
		return false
	members[player_id] = scene_id
	return true

func leave(player_id: String) -> bool:
	return members.erase(player_id)

func count_in_scene(scene_id: String) -> int:
	var count := 0
	for member_scene in members.values():
		if member_scene == scene_id:
			count += 1
	return count

func snapshot() -> Dictionary:
	return {"area_id": area_id, "instance_id": instance_id, "capacity": capacity, "population": members.size(), "scene_population": _scene_population()}

func _scene_population() -> Dictionary:
	var result: Dictionary = {}
	for scene_id in members.values():
		result[scene_id] = int(result.get(scene_id, 0)) + 1
	return result
