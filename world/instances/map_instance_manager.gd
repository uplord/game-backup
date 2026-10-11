extends Node
class_name UplordMapInstanceManager
## Server-side population bookkeeping. No networking or spawning in Phase 3.4.
## Capacity is per area instance, NOT per individual scene.
signal player_joined(player_id: String, area_id: String, instance_id: int, scene_id: String)
signal player_left(player_id: String, area_id: String, instance_id: int)
@export_range(1, 500, 1) var default_capacity: int = 100
@export var area_capacities: Dictionary = {} # area_id -> positive integer
var _instances: Dictionary = {} # area_id -> Array[UplordMapInstance]
var _locations: Dictionary = {} # player_id -> {area_id, instance_id, scene_id}
var _next_ids: Dictionary = {} # area_id -> next monotonic instance ID

func capacity_for(area_id: String) -> int:
	return maxi(1, int(area_capacities.get(area_id, default_capacity)))

func get_location(player_id: String) -> Dictionary:
	return _locations.get(player_id, {}).duplicate()

func get_instances(area_id: String) -> Array:
	return (_instances.get(area_id, []) as Array).duplicate()

func get_instance(area_id: String, instance_id: int) -> UplordMapInstance:
	for instance in get_instances(area_id):
		if instance.instance_id == instance_id:
			return instance
	return null

func join_area(player_id: String, area_id: String, scene_id: String = "", preferred_instance_id: int = 0) -> Dictionary:
	if player_id.is_empty():
		push_warning("Cannot join instance without player ID")
		return {}
	var resolved_scene := scene_id if not scene_id.is_empty() else str(UplordMapRegistry.DEFAULT_SCENES.get(area_id, ""))
	if not UplordMapRegistry.has_scene(area_id, resolved_scene):
		push_warning("Unknown area/scene: %s/%s" % [area_id, resolved_scene])
		return {}
	var previous := get_location(player_id)
	if not previous.is_empty() and str(previous.area_id) == area_id:
		var existing := get_instance(area_id, int(previous.instance_id))
		if existing != null:
			existing.join(player_id, resolved_scene)
			_locations[player_id] = {"area_id": area_id, "instance_id": existing.instance_id, "scene_id": resolved_scene}
			return get_location(player_id)
	var target: UplordMapInstance = null
	if preferred_instance_id > 0:
		var preferred := get_instance(area_id, preferred_instance_id)
		if preferred != null and preferred.has_space():
			target = preferred
	if target == null:
		for candidate in get_instances(area_id):
			if candidate.has_space():
				target = candidate
				break
	if target == null:
		var next_id := int(_next_ids.get(area_id, 1))
		_next_ids[area_id] = next_id + 1
		target = UplordMapInstance.new(area_id, next_id, capacity_for(area_id))
		if not _instances.has(area_id):
			_instances[area_id] = []
		_instances[area_id].append(target)
	if not target.join(player_id, resolved_scene):
		return {}
	if not previous.is_empty():
		leave_area(player_id)
	_locations[player_id] = {"area_id": area_id, "instance_id": target.instance_id, "scene_id": resolved_scene}
	player_joined.emit(player_id, area_id, target.instance_id, resolved_scene)
	return get_location(player_id)

func leave_area(player_id: String) -> bool:
	if not _locations.has(player_id):
		return false
	var location: Dictionary = _locations[player_id]
	_locations.erase(player_id)
	var instance := get_instance(str(location.area_id), int(location.instance_id))
	if instance != null:
		instance.leave(player_id)
		player_left.emit(player_id, str(location.area_id), int(location.instance_id))
		if instance.members.is_empty():
			_instances[str(location.area_id)].erase(instance)
	return true

func population(area_id: String) -> int:
	var count := 0
	for instance in get_instances(area_id):
		count += instance.members.size()
	return count

func clear_all() -> void:
	_instances.clear()
	_locations.clear()
	_next_ids.clear()
