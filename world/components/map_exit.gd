@tool
extends Area2D
class_name UplordMapExit
## destination_area and destination_scene identify the destination independently.
signal entered(exit_node: UplordMapExit)
@export var destination_area: String = ""
@export var destination_scene: String = ""
@export var destination_spawn: String = "default"
@export var enabled: bool = true
@export var show_teleport_marker: bool = true
@export var teleport_color: Color = Color(0.28, 0.8, 1.0, 0.5)
@export var marker_size: Vector2 = Vector2(85, 180)
@export var marker_label: String = "TRAVEL"

func _draw() -> void:
    if not show_teleport_marker:
        return
    var bounds := Rect2(-marker_size * 0.5, marker_size)
    draw_rect(bounds, teleport_color, true)
    draw_rect(bounds, Color(0.7, 0.95, 1.0), false, 3.0)
    draw_line(Vector2(0, -marker_size.y * 0.3), Vector2(0, marker_size.y * 0.3), Color.WHITE, 3.0)
    draw_line(Vector2(-13, 0), Vector2(13, 0), Color.WHITE, 3.0)
func _ready() -> void:
    z_index = 5
    queue_redraw()
    if Engine.is_editor_hint():
        return
    collision_layer = 0
    collision_mask = 1
    body_entered.connect(_on_body_entered)
func _on_body_entered(body: Node2D) -> void:
    if enabled and body is UplordPlayerController:
        entered.emit(self)
