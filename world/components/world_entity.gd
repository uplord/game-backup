@tool
extends Area2D
class_name UplordWorldEntity
## A map placement refers to content by ID. No gameplay logic lives in the map.
signal interaction_requested(entity: UplordWorldEntity)
var is_selected: bool = false

func set_selected(value: bool) -> void:
    is_selected = value
    queue_redraw()
@export_enum("enemy", "npc", "resource", "object") var entity_type: String = "enemy":
    set(value):
        entity_type = value
        queue_redraw()
@export var definition_id: String = "":
    set(value):
        definition_id = value
        queue_redraw()
@export var placement_id: String = ""
@export var display_label: String = ""
@export var interaction_radius: float = 240.0
@export_range(1, 5, 1) var slots_per_side: int = 5
@export var slot_horizontal_distance: float = 210.0
@export var slot_vertical_spacing: float = 55.0
var _slot_owners: Dictionary = {} # slot index -> player instance id (local preview; server later)

func slot_position(index: int) -> Vector2:
    var count: int = clampi(slots_per_side, 1, 5)
    var side: float = -1.0 if index < count else 1.0
    var row: int = index % count
    var y: float = (float(row) - float(count - 1) * 0.5) * slot_vertical_spacing
    return global_position + Vector2(side * slot_horizontal_distance, y)

func reserve_slot(player: Node2D, bounds: Rect2, enforce_bounds: bool = true) -> int:
    if not is_instance_valid(player):
        return -1
    var owner: int = player.get_instance_id()
    for index in _slot_owners.keys():
        if _slot_owners[index] == owner:
            return int(index)
    var count: int = clampi(slots_per_side, 1, 5)
    var preferred_side: int = 0 if player.global_position.x <= global_position.x else 1
    for side in [preferred_side, 1 - preferred_side]:
        var options: Array[int] = []
        for row in range(count):
            var index: int = side * count + row
            var point: Vector2 = slot_position(index)
            if _slot_owners.has(index) or (enforce_bounds and not bounds.has_point(point)):
                continue
            options.append(index)
        options.sort_custom(func(a: int, b: int) -> bool:
            return slot_position(a).distance_squared_to(player.global_position) < slot_position(b).distance_squared_to(player.global_position)
        )
        if not options.is_empty():
            var chosen: int = options[0]
            _slot_owners[chosen] = owner
            return chosen
    return -1

func release_slot(player: Node2D) -> void:
    if not is_instance_valid(player):
        return
    var owner: int = player.get_instance_id()
    for index in _slot_owners.keys():
        if _slot_owners[index] == owner:
            _slot_owners.erase(index)

func reserved_slot_count() -> int:
    return _slot_owners.size()
## Clearance measured from the entity ground origin, not its sprite centre.
@export var visual_clearance_radius: float = 58.0
@export var player_clearance: float = 28.0
@export var marker_color: Color = Color(0.75, 0.27, 0.25):
    set(value):
        marker_color = value
        queue_redraw()

func _ready() -> void:
    collision_layer = 2
    collision_mask = 0
    input_pickable = true
    if Engine.is_editor_hint():
        return
    input_event.connect(_on_input_event)

func _draw() -> void:
    # Editor-visible placeholder, replaced by actual sprites in later phases.
    draw_circle(Vector2(0, -22), 20.0, marker_color)
    draw_circle(Vector2(0, -22), 20.0, Color(0.1, 0.1, 0.1), false, 2.0)
    if is_selected:
        draw_arc(Vector2(0, -22), 28.0, 0.0, TAU, 48, Color(1.0, 0.9, 0.25), 3.0)
    draw_line(Vector2(-18, 0), Vector2(18, 0), Color(0.1, 0.1, 0.1), 2.0)

func definition_collection() -> String:
    match entity_type:
        "enemy": return "enemies"
        "npc": return "npcs"
        "resource": return "resources"
        _: return "objects"

func resolve_definition(repository: UplordContentRepository) -> Dictionary:
    if repository == null or definition_id.is_empty():
        return {}
    return repository.get_definition(definition_collection(), definition_id)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_index: int) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        interaction_requested.emit(self)
        get_viewport().set_input_as_handled()
