extends CharacterBody2D
class_name UplordPlayerController
## Phase 2.2 local movement controller. Multiplayer authority comes later.
signal manual_movement_started
signal ground_clicked
## Position is at the player's feet. Character artwork is a visual child.

@export var move_speed: float = 480.0
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
var _touch_held: bool = false
var _keyboard_was_active: bool = false

func _ready() -> void:
	destination = global_position

func _unhandled_input(event: InputEvent) -> void:
	if not allow_click_to_move:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pointer_held = event.pressed
		if event.pressed:
			ground_clicked.emit()
			set_destination(get_global_mouse_position())
	elif event is InputEventScreenTouch:
		_touch_held = event.pressed
		pointer_held = event.pressed
		if event.pressed:
			ground_clicked.emit()
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

	# Mouse releases over UI may be handled by Controls rather than _unhandled_input.
	# Keep hold state in sync even when the release event is consumed.
	if pointer_held and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not _touch_held:
		pointer_held = false

	if input_direction != Vector2.ZERO:
		if not _keyboard_was_active:
			manual_movement_started.emit()
		_keyboard_was_active = true
		has_destination = false
		velocity = input_direction * move_speed
	else:
		_keyboard_was_active = false
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
	# Do not clear pointer_held here: held movement updates this destination
	# every physics frame. Entity targeting explicitly cancels the hold.
	destination = world_position.clamp(movement_bounds.position, movement_bounds.end) if clamp_to_bounds else world_position
	has_destination = true

func stop_moving() -> void:
	pointer_held = false
	_touch_held = false
	has_destination = false
	velocity = Vector2.ZERO
