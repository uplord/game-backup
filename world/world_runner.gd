extends Node2D
## Phase 3.5: local world orchestration. Networking/server authority comes later.
@export var initial_area: String = "starter_town"
@export var initial_scene: String = "plaza"
@export var local_player_id: String = "local_preview_player"
@export_range(1, 500, 1) var default_instance_capacity: int = 100
@export var area_instance_capacities: Dictionary = {}

signal world_scene_changed(area_id: String, scene_id: String, instance_id: int)
signal world_scene_failed(area_id: String, scene_id: String)

var current_area: String = ""
var current_scene: String = ""
var current_instance_id: int = 0
var current_map: UplordMapBase
var instance_manager: UplordMapInstanceManager
var _transitioning: bool = false
var _last_spawn_id: String = "default"
var _bound_content_version: String = ""

func _ready() -> void:
	instance_manager = UplordMapInstanceManager.new()
	instance_manager.name = "InstanceManager"
	instance_manager.default_capacity = default_instance_capacity
	instance_manager.area_capacities = area_instance_capacities.duplicate(true)
	add_child(instance_manager)
	if not PublishedContent.snapshot_ready.is_connected(_on_published_snapshot_ready):
		PublishedContent.snapshot_ready.connect(_on_published_snapshot_ready)
	open_scene(initial_area, initial_scene, "default")

func open_scene(area_id: String, scene_id: String, spawn_id: String = "default") -> bool:
	if _transitioning or instance_manager == null:
		return false
	if not UplordMapRegistry.has_scene(area_id, scene_id):
		push_warning("Unknown world scene %s/%s" % [area_id, scene_id])
		world_scene_failed.emit(area_id, scene_id)
		return false
	var packed: PackedScene = UplordMapRegistry.load_scene(area_id, scene_id)
	if packed == null:
		world_scene_failed.emit(area_id, scene_id)
		return false
	# Instantiate and verify before replacing the existing scene or membership.
	var next_map := packed.instantiate() as UplordMapBase
	if next_map == null:
		world_scene_failed.emit(area_id, scene_id)
		return false
	if next_map.map_id != area_id or next_map.scene_id != scene_id:
		push_error("Map scene identity mismatch: %s/%s" % [area_id, scene_id])
		next_map.free()
		world_scene_failed.emit(area_id, scene_id)
		return false
	var location := instance_manager.join_area(local_player_id, area_id, scene_id)
	if location.is_empty():
		next_map.free()
		world_scene_failed.emit(area_id, scene_id)
		return false
	_transitioning = true
	var previous_map := current_map
	# Remove the previous PhantomCameraHost before registering the new one.
	# Keeping both maps in the tree for a frame causes host hand-offs/tweens.
	if is_instance_valid(previous_map):
		if is_instance_valid(previous_map.targeting):
			previous_map.targeting.clear_target()
		remove_child(previous_map)
	current_map = next_map
	add_child(next_map)
	current_area = area_id
	current_scene = scene_id
	current_instance_id = int(location.get("instance_id", 0))
	_last_spawn_id = spawn_id
	next_map.exit_requested.connect(_on_exit_requested)
	next_map.spawn_at(spawn_id)
	_bind_map_content(next_map)
	next_map.camera.snap_to_player()
	if is_instance_valid(previous_map):
		previous_map.queue_free()
	world_scene_changed.emit(current_area, current_scene, current_instance_id)
	call_deferred("_finish_transition")
	return true

func _finish_transition() -> void:
	_transitioning = false

func _on_exit_requested(exit_node: UplordMapExit) -> void:
	if _transitioning:
		return
	call_deferred("open_scene", exit_node.destination_area, exit_node.destination_scene, exit_node.destination_spawn)

func get_world_location() -> Dictionary:
	var location := instance_manager.get_location(local_player_id) if instance_manager != null else {}
	location["spawn_id"] = _last_spawn_id
	if is_instance_valid(current_map):
		location["position"] = current_map.player.global_position
	return location

func restore_world_location(saved: Dictionary) -> bool:
	var area_id := str(saved.get("area_id", initial_area))
	var scene_id := str(saved.get("scene_id", UplordMapRegistry.DEFAULT_SCENES.get(area_id, "")))
	var spawn_id := str(saved.get("spawn_id", "default"))
	if not open_scene(area_id, scene_id, spawn_id):
		return false
	# A saved position is only valid if inside the destination map.
	var saved_position: Variant = saved.get("position", null)
	if saved_position is Vector2 and current_map != null:
		var bounds := Rect2(current_map.global_position, current_map.map_size)
		if bounds.has_point(saved_position):
			current_map.player.global_position = saved_position
			current_map.player.stop_moving()
	return true

func _exit_tree() -> void:
	if instance_manager != null:
		instance_manager.leave_area(local_player_id)

func _bind_map_content(map_node: UplordMapBase) -> void:
	if not is_instance_valid(map_node) or PublishedContent.repository == null:
		return
	var errors: Array[String] = map_node.bind_published_entities(PublishedContent.repository)
	for issue in errors:
		push_warning("Content binding: %s" % issue)
	_bound_content_version = PublishedContent.repository.content_version

func _on_published_snapshot_ready(_version: String, _source: String) -> void:
	# Refresh placed entities after a new release loads, including on map transitions.
	if is_instance_valid(current_map):
		_bind_map_content(current_map)

func get_content_definition(category: String, definition_id: String) -> Dictionary:
	if PublishedContent.repository == null:
		return {}
	return PublishedContent.repository.get_definition(category, definition_id)

func get_content_version() -> String:
	return _bound_content_version
