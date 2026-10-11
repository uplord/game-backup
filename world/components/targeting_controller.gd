extends Node
class_name UplordTargetingController
## One selected entity per loaded scene; coordinates approach and interaction state.
signal target_changed(entity: UplordWorldEntity)
signal target_range_changed(in_range: bool)
## Emitted when an approach started by entity click or Interact reaches its slot.
signal interaction_activated(entity: UplordWorldEntity, action: String)
signal interaction_cancelled(entity: UplordWorldEntity)

enum InteractionState { IDLE, APPROACHING, READY, INTERACTING }
var interaction_state: InteractionState = InteractionState.IDLE

var target_in_range: bool = false
var _approach_destination: Vector2 = Vector2.ZERO
var _approaching: bool = false
var _reserved_slot: int = -1
var _nearby_entity: UplordWorldEntity = null

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

func _physics_process(_delta: float) -> void:
    if not is_instance_valid(_player):
        return
    _update_nearby_entity()
    if not is_instance_valid(selected_entity) or _reserved_slot < 0:
        return
    var slot_point: Vector2 = selected_entity.slot_position(_reserved_slot)
    var arrived: bool = _player.global_position.distance_to(slot_point) <= _player.stop_distance + 3.0
    if arrived and interaction_state == InteractionState.APPROACHING:
        _approaching = false
        _player.stop_moving()
        interaction_state = InteractionState.READY
        _face_entity(selected_entity)
        _perform_interaction()
    elif _approaching and not _player.has_destination:
        _player.set_destination(slot_point)

func _update_nearby_entity() -> void:
    # Walking near an entity reveals its action without selecting or moving.
    var nearest: UplordWorldEntity = null
    var nearest_distance: float = INF
    if is_instance_valid(selected_entity) and _within_range(selected_entity):
        nearest = selected_entity
    else:
        for entity in _entities:
            if not is_instance_valid(entity) or not _within_range(entity):
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
    return is_instance_valid(_player) and _player.global_position.distance_to(entity.global_position) <= entity.interaction_radius

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
    _release_slot()
    _set_range(false)

func _start_approach() -> void:
    _approaching = false
    _set_range(false)
    if not is_instance_valid(selected_entity) or not is_instance_valid(_player):
        return
    _reserved_slot = selected_entity.reserve_slot(_player, _player.movement_bounds, _player.clamp_to_bounds)
    if _reserved_slot < 0:
        push_warning("No available interaction slot for %s" % selected_entity.placement_id)
        return
    _approach_destination = selected_entity.slot_position(_reserved_slot)
    if _player.global_position.distance_to(_approach_destination) <= _player.stop_distance + 3.0:
        _player.stop_moving()
        interaction_state = InteractionState.READY
        _face_entity(selected_entity)
        _perform_interaction()
        return
    _approaching = true
    interaction_state = InteractionState.APPROACHING
    _player.set_destination(_approach_destination)

func _interaction_action(entity: UplordWorldEntity) -> String:
    match entity.entity_type:
        "npc": return "Talk"
        "resource": return "Gather"
        "enemy": return "Engage"
        "object": return "Inspect"
        _: return "Interact"

func _update_interact_button() -> void:
    if not is_instance_valid(_interact_button):
        return
    # An explicit click is an interaction intent. Keep the action visible while
    # approaching even if the player is not yet inside the proximity radius.
    # This also handles outer resource slots that sit close to the radius edge.
    var approaching_selected: bool = is_instance_valid(selected_entity) and interaction_state == InteractionState.APPROACHING
    var selected_in_range: bool = is_instance_valid(selected_entity) and _within_range(selected_entity)
    var selected_at_slot: bool = is_instance_valid(selected_entity) and _reserved_slot >= 0 and (interaction_state == InteractionState.READY or interaction_state == InteractionState.INTERACTING)
    var entity_for_button: UplordWorldEntity = selected_entity if (approaching_selected or selected_in_range or selected_at_slot) else _nearby_entity
    var available: bool = is_instance_valid(entity_for_button)
    _interact_button.visible = available
    _interact_button.disabled = not available or approaching_selected
    if available:
        _interact_button.text = "Moving..." if approaching_selected else _interaction_action(entity_for_button)

func activate_interaction() -> void:
    # Button is a request to approach; the action fires only upon arrival.
    _update_nearby_entity()
    if not is_instance_valid(_nearby_entity) or interaction_state == InteractionState.APPROACHING:
        return
    var entity: UplordWorldEntity = _nearby_entity
    if selected_entity != entity:
        # select_target already starts the approach on a new selection.
        select_target(entity)
    else:
        _cancel_approach()
        _start_approach()
    _update_interact_button()

func _perform_interaction() -> void:
    if not is_instance_valid(selected_entity):
        return
    var action: String = _interaction_action(selected_entity)
    interaction_state = InteractionState.INTERACTING
    interaction_activated.emit(selected_entity, action)
    _feedback.text = "%s: coming soon" % action
    _update_interact_button()

func _exit_tree() -> void:
    # Scene changes and map destruction must release any held slot immediately.
    _release_slot()
    if is_instance_valid(selected_entity):
        selected_entity.set_selected(false)
    selected_entity = null
    _nearby_entity = null
    interaction_state = InteractionState.IDLE
