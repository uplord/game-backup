extends Node
class_name UplordTargetingController
## One selected entity per loaded scene; coordinates approach and interaction state.
signal target_changed(entity: UplordWorldEntity)
signal target_range_changed(in_range: bool)
## Emitted when an approach started by entity click or Interact reaches its slot.
signal interaction_activated(entity: UplordWorldEntity, action: String)
signal interaction_cancelled(entity: UplordWorldEntity)
signal attack_requested

enum InteractionState { IDLE, APPROACHING, READY, INTERACTING }
var interaction_state: InteractionState = InteractionState.IDLE

var target_in_range: bool = false
var combat_active: bool = false
var combat_attack_ready: bool = true
var _approach_destination: Vector2 = Vector2.ZERO
var _approaching: bool = false
var _reserved_slot: int = -1
var _nearby_entity: UplordWorldEntity = null
var _previous_approach_position: Vector2 = Vector2.ZERO
var _stationary_seconds: float = 0.0

var selected_entity: UplordWorldEntity = null
var _player: UplordPlayerController
var _entities: Array[UplordWorldEntity] = []
var _label: Label
var _interact_button: Button
var _feedback: Label

func configure(map: UplordMapBase) -> void:
    _player = map.player
    _player.ground_clicked.connect(clear_target)
    _player.manual_movement_started.connect(clear_target)
    for entity in map.list_world_entities():
        _entities.append(entity)
        entity.interaction_requested.connect(select_target)
        entity.tree_exiting.connect(_on_entity_exiting.bind(entity))
    # HUD layout lives in an editable scene rather than being assembled in code.
    var hud_scene: PackedScene = preload("res://world/components/interaction_hud.tscn")
    var canvas: CanvasLayer = hud_scene.instantiate() as CanvasLayer
    add_child(canvas)
    _label = canvas.get_node("TargetPanel/TargetLabel") as Label
    _feedback = canvas.get_node("InteractionHUD/ActionBox/InteractionFeedback") as Label
    _interact_button = canvas.get_node("InteractionHUD/ActionBox/InteractButton") as Button
    _interact_button.pressed.connect(activate_interaction)

func select_target(entity: UplordWorldEntity) -> void:
    if not is_instance_valid(entity) or not _entities.has(entity):
        return
    if selected_entity == entity:
        # Clicking an already-selected entity should also approach it.
        if interaction_state != InteractionState.APPROACHING:
            _cancel_approach()
            _start_approach()
            _update_interact_button()
        return
    _cancel_approach()
    if is_instance_valid(selected_entity):
        selected_entity.set_selected(false)
    selected_entity = entity
    selected_entity.set_selected(true)
    _label.text = "%s  ·  %s" % [entity.display_label if not entity.display_label.is_empty() else entity.definition_id.replace("_", " ").capitalize(), entity.entity_type.capitalize()]
    _label.get_parent().visible = true
    _player.pointer_held = false
    _feedback.text = ""
    _update_nearby_entity()
    _update_interact_button()
    target_changed.emit(selected_entity)
    # Directly clicking an entity starts movement immediately. Walking into
    # proximity without clicking still only reveals the Interact button.
    _start_approach()
    _update_interact_button()

func clear_target() -> void:
    if is_instance_valid(selected_entity):
        interaction_cancelled.emit(selected_entity)
    _cancel_approach()
    _set_range(false)
    _feedback.text = ""
    if not is_instance_valid(selected_entity):
        selected_entity = null
        if is_instance_valid(_label):
            _label.get_parent().visible = false
        _update_interact_button()
        return
    selected_entity.set_selected(false)
    selected_entity = null
    _label.get_parent().visible = false
    _update_nearby_entity()
    _update_interact_button()
    target_changed.emit(null)

func _on_entity_exiting(entity: UplordWorldEntity) -> void:
    if selected_entity == entity:
        clear_target()
    if _nearby_entity == entity:
        _nearby_entity = null
        _update_interact_button()

func _physics_process(delta: float) -> void:
    if not is_instance_valid(_player):
        return
    _update_nearby_entity()
    _update_interact_button()
    if not is_instance_valid(selected_entity) or _reserved_slot < 0:
        return
    var slot_point: Vector2 = selected_entity.slot_position(_reserved_slot)
    # The movement controller clamps destinations to map bounds. Its stopping
    # point can differ from the reserved slot, so check the actual destination.
    var effective_point: Vector2 = slot_point.clamp(_player.movement_bounds.position, _player.movement_bounds.end) if _player.clamp_to_bounds else slot_point
    # A CharacterBody2D can be blocked by collision while has_destination stays
    # true. Track actual displacement rather than trusting the destination flag.
    var distance_to_slot: float = _player.global_position.distance_to(effective_point)
    var moved: float = _player.global_position.distance_to(_previous_approach_position)
    _previous_approach_position = _player.global_position
    if moved <= 0.5:
        _stationary_seconds += delta
    else:
        _stationary_seconds = 0.0
    var reached_slot: bool = distance_to_slot <= maxf(_player.stop_distance + 8.0, 18.0)
    var stopped_near_slot: bool = _stationary_seconds >= 0.18 and distance_to_slot <= 48.0
    var movement_finished: bool = not _player.has_destination and distance_to_slot <= 48.0
    if interaction_state == InteractionState.APPROACHING and (reached_slot or stopped_near_slot or movement_finished):
        _approaching = false
        _player.stop_moving()
        interaction_state = InteractionState.READY
        _face_entity(selected_entity)
        _update_interact_button()
    elif _approaching and not _player.has_destination and distance_to_slot > 48.0:
        # Only retry if movement actually stopped short of the reserved slot.
        _player.set_destination(effective_point)

func _update_nearby_entity() -> void:
    # Walking near an entity reveals its action without selecting or moving.
    var nearest: UplordWorldEntity = null
    var nearest_distance: float = INF
    if is_instance_valid(selected_entity) and selected_entity.runtime_enabled and selected_entity.visible and _within_range(selected_entity):
        nearest = selected_entity
    else:
        for entity in _entities:
            if not is_instance_valid(entity) or not entity.runtime_enabled or not entity.visible or not _within_range(entity):
                continue
            var distance: float = _player.global_position.distance_squared_to(entity.global_position)
            if distance < nearest_distance:
                nearest_distance = distance
                nearest = entity
    if _nearby_entity != nearest:
        _nearby_entity = nearest
        _update_interact_button()
    _set_range(is_instance_valid(_nearby_entity))

func _within_range(entity: UplordWorldEntity) -> bool:
    return is_instance_valid(_player) and _player.global_position.distance_to(entity.global_position) <= entity.interaction_radius + 16.0

func _face_entity(entity: UplordWorldEntity) -> void:
    if is_instance_valid(_player.character):
        _player.character.set_facing_left(entity.global_position.x < _player.global_position.x)

func _set_range(value: bool) -> void:
    if target_in_range == value:
        return
    target_in_range = value
    _update_interact_button()
    target_range_changed.emit(value)

func _release_slot() -> void:
    if is_instance_valid(selected_entity) and is_instance_valid(_player):
        selected_entity.release_slot(_player)
    _reserved_slot = -1

func _cancel_approach() -> void:
    interaction_state = InteractionState.IDLE
    _approaching = false
    _stationary_seconds = 0.0
    _release_slot()
    _set_range(false)

func _start_approach() -> void:
    _approaching = false
    _stationary_seconds = 0.0
    _previous_approach_position = _player.global_position if is_instance_valid(_player) else Vector2.ZERO
    _set_range(false)
    if not is_instance_valid(selected_entity) or not is_instance_valid(_player):
        return
    _reserved_slot = selected_entity.reserve_slot(_player, _player.movement_bounds, _player.clamp_to_bounds)
    if _reserved_slot < 0:
        push_warning("No available interaction slot for %s" % selected_entity.placement_id)
        return
    _approach_destination = selected_entity.slot_position(_reserved_slot)
    var effective_destination: Vector2 = _approach_destination.clamp(_player.movement_bounds.position, _player.movement_bounds.end) if _player.clamp_to_bounds else _approach_destination
    if _player.global_position.distance_to(effective_destination) <= _player.stop_distance + 8.0:
        _player.stop_moving()
        interaction_state = InteractionState.READY
        _face_entity(selected_entity)
        _update_interact_button()
        return
    _approaching = true
    interaction_state = InteractionState.APPROACHING
    _player.set_destination(_approach_destination)

func _effective_entity_type(entity: UplordWorldEntity) -> String:
    # The plaza Copper Rock is a gathering placement. Keep it gatherable even
    # when an older saved scene accidentally overrides its type as an object.
    if entity.definition_id == "copper_rock":
        return "resource"
    return entity.entity_type

func _interaction_action(entity: UplordWorldEntity) -> String:
    match _effective_entity_type(entity):
        "npc": return "Talk"
        "resource": return "Gather"
        "enemy": return "Attack"
        "object": return "Inspect"
        _: return "Interact"

func _update_interact_button() -> void:
    if not is_instance_valid(_interact_button):
        return
    var has_target: bool = is_instance_valid(selected_entity) and selected_entity.runtime_enabled and selected_entity.visible
    var nearby: bool = is_instance_valid(_nearby_entity) and _nearby_entity.runtime_enabled and _nearby_entity.visible and _within_range(_nearby_entity)
    # Preserve proximity discovery: the nearest entity exposes the action button
    # even before it is selected. The first press selects/approaches; it never
    # starts combat or gathering by itself.
    _interact_button.visible = has_target or nearby
    if has_target:
        var ready: bool = _reserved_slot >= 0 and interaction_state != InteractionState.APPROACHING and _within_range(selected_entity)
        _interact_button.disabled = not ready or (selected_entity.entity_type == "enemy" and combat_active and not combat_attack_ready)
        _interact_button.text = _interaction_action(selected_entity) if ready else "Moving..."
    elif nearby:
        _interact_button.disabled = false
        _interact_button.text = "Interact"

func activate_interaction() -> void:
    # A nearby unselected entity can be discovered using the same bottom-right
    # button. Select/approach first; the next press performs the action.
    if not is_instance_valid(selected_entity):
        if is_instance_valid(_nearby_entity) and _nearby_entity.runtime_enabled and _nearby_entity.visible and _within_range(_nearby_entity):
            select_target(_nearby_entity)
        return
    if _reserved_slot < 0 or interaction_state == InteractionState.APPROACHING or not _within_range(selected_entity):
        return
    if not selected_entity.runtime_enabled or not selected_entity.visible:
        return
    if selected_entity.entity_type == "enemy" and combat_active:
        if combat_attack_ready:
            attack_requested.emit()
    else:
        _perform_interaction()
    _update_interact_button()

func _perform_interaction() -> void:
    if not is_instance_valid(selected_entity):
        return
    var action: String = _interaction_action(selected_entity)
    interaction_state = InteractionState.INTERACTING
    interaction_activated.emit(selected_entity, action)
    _feedback.text = ""
    _update_interact_button()

func _exit_tree() -> void:
    # Scene changes and map destruction must release any held slot immediately.
    _release_slot()
    if is_instance_valid(selected_entity):
        selected_entity.set_selected(false)
    selected_entity = null
    _nearby_entity = null
    interaction_state = InteractionState.IDLE
