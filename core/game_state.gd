extends Node
## Runtime state snapshot, not persistence or source of authority.
var player: UplordPlayerState = UplordPlayerState.new()
var current_area_id: StringName = &""
var current_instance_id: int = 0
var selected_target_id: StringName = &""

func enter_area(area_id: StringName, instance_id: int = 1) -> void:
    if area_id == &"" or instance_id < 1:
        push_warning("GameState: rejected invalid area")
        return
    current_area_id = area_id
    current_instance_id = instance_id
    player.area_id = area_id
    player.instance_id = instance_id
    select_target(&"")
    EventBus.area_changed.emit(area_id, instance_id)
    EventBus.player_state_changed.emit(player.to_snapshot())

func select_target(target_id: StringName) -> void:
    selected_target_id = target_id
    EventBus.target_changed.emit(target_id)

func reset() -> void:
    player.reset()
    current_area_id = &""
    current_instance_id = 0
    select_target(&"")
    EventBus.player_state_changed.emit(player.to_snapshot())
