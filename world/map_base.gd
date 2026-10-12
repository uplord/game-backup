@tool
extends Node2D
class_name UplordMapBase
## A map owns its layout and scale. Scaling character art never changes movement speed.
@export var map_id: String = "starter_town"
@export var scene_id: String = "plaza"
signal exit_requested(exit_node: UplordMapExit)
@export var map_size: Vector2 = Vector2(3200, 1080):
	set(value):
		map_size = Vector2(maxf(100.0, value.x), maxf(100.0, value.y))
		queue_redraw()
@export_range(0.2, 3.0, 0.05) var player_visual_scale: float = 1.0
@export var player_spawn: Vector2 = Vector2(400, 760)
@export var ground_color: Color = Color(0.19, 0.36, 0.24):
	set(value):
		ground_color = value
		queue_redraw()
@export var show_debug_grid: bool = true:
	set(value):
		show_debug_grid = value
		queue_redraw()

@onready var player: UplordPlayerController = $Actors/PlayerController
@onready var camera: Camera2D = $Camera2D
var targeting: UplordTargetingController
var combat: UplordCombatController
var gathering: UplordGatheringController

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	player.global_position = to_global(player_spawn)
	for exit_node in get_node("Exits").get_children():
		if exit_node is UplordMapExit:
			exit_node.entered.connect(_on_exit_entered)
	player.movement_bounds = Rect2(global_position, map_size)
	# 2.2's visual baseline is 2x. Map scale modifies art, NOT the physics body.
	player.character.scale = Vector2.ONE * (2.0 * player_visual_scale)
	camera.world_bounds = Rect2(global_position, map_size)
	camera.target_path = camera.get_path_to(player)
	camera.snap_to_player()
	# Each map owns its targeting state; changing scenes automatically clears it.
	targeting = UplordTargetingController.new()
	targeting.name = "TargetingController"
	add_child(targeting)
	targeting.configure(self)
	combat = UplordCombatController.new()
	combat.name = "CombatController"
	add_child(combat)
	combat.configure(self)
	gathering = UplordGatheringController.new()
	gathering.name = "GatheringController"
	add_child(gathering)
	gathering.configure(self)
	gathering.resource_gathered.connect(_on_resource_gathered)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, map_size), ground_color, true)
	if show_debug_grid:
		var x := 0.0
		while x <= map_size.x:
			draw_line(Vector2(x, 0), Vector2(x, map_size.y), Color(1, 1, 1, 0.08), 1.0)
			x += 128.0
		var y := 0.0
		while y <= map_size.y:
			draw_line(Vector2(0, y), Vector2(map_size.x, y), Color(1, 1, 1, 0.08), 1.0)
			y += 128.0
	draw_rect(Rect2(Vector2.ZERO, map_size), Color(0.8, 0.85, 0.6), false, 5.0)

func _on_exit_entered(exit_node: UplordMapExit) -> void:
	exit_requested.emit(exit_node)

func spawn_at(spawn_id: String) -> void:
	var point := get_node_or_null("Spawns/" + spawn_id) as Marker2D
	if point == null:
		push_warning("Spawn '%s' missing in %s/%s; using default" % [spawn_id, map_id, scene_id])
		player.global_position = to_global(player_spawn)
	else:
		player.global_position = point.global_position
	player.stop_moving()

## Map placements are nodes; content is resolved by the repository at runtime.
func list_world_entities() -> Array[UplordWorldEntity]:
	var result: Array[UplordWorldEntity] = []
	var container := get_node_or_null("Entities")
	if container == null:
		return result
	for child in container.get_children():
		if child is UplordWorldEntity:
			result.append(child)
	return result

func validate_world_entities(repository: UplordContentRepository) -> Array[String]:
	var errors: Array[String] = []
	var placements: Dictionary = {}
	for entity in list_world_entities():
		if entity.placement_id.is_empty():
			errors.append("Entity missing placement_id in %s/%s" % [map_id, scene_id])
		elif placements.has(entity.placement_id):
			errors.append("Duplicate placement_id '%s' in %s/%s" % [entity.placement_id, map_id, scene_id])
		else:
			placements[entity.placement_id] = true
		if entity.definition_id.is_empty() or not repository.has_definition(entity.definition_collection(), entity.definition_id):
			errors.append("Unknown %s definition '%s' in %s/%s" % [entity.entity_type, entity.definition_id, map_id, scene_id])
	return errors

## Bind all placed entities to the active published snapshot. Scene layout stays in Godot.
func bind_published_entities(repository: UplordContentRepository) -> Array[String]:
	var errors: Array[String] = []
	if repository == null:
		errors.append("Published content repository unavailable")
		return errors
	errors.append_array(validate_world_entities(repository))
	for entity in list_world_entities():
		if not entity.apply_published_definition(repository):
			errors.append("Missing %s/%s at %s" % [entity.definition_collection(), entity.definition_id, entity.placement_id])
	return errors

func _on_resource_gathered(item_id: String, quantity: int, _skill_id: String) -> void:
	if not Inventory.add_item(item_id, quantity):
		push_warning("Unknown inventory item from gathering: %s" % item_id)
