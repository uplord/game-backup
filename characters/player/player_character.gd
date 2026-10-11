extends Node2D
## Visual-only modular character. Movement, networking and combat arrive in later phases.
class_name UplordPlayerCharacter

@export var primary_color: Color = Color("567f9e"):
	set(value):
		primary_color = value
		if is_node_ready(): _apply_palette()
@export var secondary_color: Color = Color("35485c"):
	set(value):
		secondary_color = value
		if is_node_ready(): _apply_palette()
@export var accent_color: Color = Color("b8a67c"):
	set(value):
		accent_color = value
		if is_node_ready(): _apply_palette()
@export var skin_color: Color = Color("c89170"):
	set(value):
		skin_color = value
		if is_node_ready(): _apply_palette()

## Facing is left/right; the art always remains a three-quarter front view.
@export_enum("Right", "Left") var facing: int = 0:
	set(value):
		facing = value
		if is_node_ready(): _update_facing()

@onready var visuals: Node2D = $Visuals
@onready var body_parts: Node2D = $Visuals/BodyParts
@onready var sockets: Node2D = $Visuals/EquipmentSockets

func _ready() -> void:
	_apply_palette()
	_update_facing()

func set_facing_left(left: bool) -> void:
	facing = 1 if left else 0

func get_part(part_name: String) -> Polygon2D:
	return body_parts.get_node_or_null(part_name) as Polygon2D

func get_equipment_socket(slot_name: String) -> Marker2D:
	return sockets.get_node_or_null(slot_name) as Marker2D

func _update_facing() -> void:
	visuals.scale.x = -1.0 if facing == 1 else 1.0

func _apply_palette() -> void:
	for name in ["Chest", "UpperArmBack", "UpperArmFront", "ThighBack", "ThighFront"]:
		var part := get_part(name)
		if part != null: part.color = primary_color
	for name in ["ShinBack", "ShinFront", "FootBack", "FootFront"]:
		var part := get_part(name)
		if part != null: part.color = secondary_color
	for name in ["Head", "HandBack", "HandFront"]:
		var part := get_part(name)
		if part != null: part.color = skin_color
	var collar := get_part("Collar")
	if collar != null: collar.color = accent_color
