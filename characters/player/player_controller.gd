extends CharacterBody2D
class_name UplordPlayerController
## Phase 2.2 local movement controller. Multiplayer authority comes later.
## Position is at the player's feet. Character artwork is a visual child.

@export var move_speed: float = 240.0
@export var stop_distance: float = 5.0
@export var allow_click_to_move: bool = true
@export var allow_keyboard: bool = true
@export var hold_to_move: bool = true
@export var movement_bounds: Rect2 = Rect2(0, 0, 1920, 1080)
@export var clamp_to_bounds: bool = true

@onready var character: UplordPlayerCharacter = $PlayerCharacter
var destination: Vector2 = Vector2.ZERO
var has_destination: bool = false
var pointer_held: bool = false

func _ready() -> void:
    destination = global_position

func _unhandled_input(event: InputEvent) -> void:
    if not allow_click_to_move:
        return
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        pointer_held = event.pressed
        if event.pressed:
            set_destination(get_global_mouse_position())
    elif event is InputEventScreenTouch:
        pointer_held = event.pressed
        if event.pressed:
            set_destination(get_global_mouse_position())
    elif event is InputEventScreenDrag and hold_to_move:
        set_destination(get_global_mouse_position())

func _physics_process(_delta: float) -> void:
    var input_direction := Vector2.ZERO
    if allow_keyboard:
        input_direction = Vector2(
            float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
            float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
        ).normalized()

    if input_direction != Vector2.ZERO:
        has_destination = false
        velocity = input_direction * move_speed
    else:
        if pointer_held and hold_to_move and allow_click_to_move:
            set_destination(get_global_mouse_position())
        var offset := destination - global_position
        if has_destination and offset.length() > stop_distance:
            velocity = offset.normalized() * minf(move_speed, offset.length() * 12.0)
        else:
            velocity = Vector2.ZERO
            has_destination = false

    if velocity.x != 0.0:
        character.set_facing_left(velocity.x < 0.0)
    move_and_slide()
    if clamp_to_bounds:
        global_position = global_position.clamp(movement_bounds.position, movement_bounds.end)

func set_destination(world_position: Vector2) -> void:
    destination = world_position.clamp(movement_bounds.position, movement_bounds.end) if clamp_to_bounds else world_position
    has_destination = true

func stop_moving() -> void:
    pointer_held = false
    has_destination = false
    velocity = Vector2.ZERO
