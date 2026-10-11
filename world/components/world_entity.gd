@tool
extends Area2D
class_name UplordWorldEntity
## A map placement refers to content by ID. No gameplay logic lives in the map.
signal interaction_requested(entity: UplordWorldEntity)
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
@export var interaction_radius: float = 90.0
@export var marker_color: Color = Color(0.75, 0.27, 0.25):
    set(value):
        marker_color = value
        queue_redraw()

func _ready() -> void:
    collision_layer = 0
    collision_mask = 0
    input_pickable = true
    if Engine.is_editor_hint():
        return
    input_event.connect(_on_input_event)

func _draw() -> void:
    # Editor-visible placeholder, replaced by actual sprites in later phases.
    draw_circle(Vector2(0, -22), 20.0, marker_color)
    draw_circle(Vector2(0, -22), 20.0, Color(0.1, 0.1, 0.1), false, 2.0)
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
