extends Node
## Shared signals; systems emit events, UI listens. No game rules here.
signal area_changed(area_id: StringName, instance_id: int)
signal target_changed(target_id: StringName)
signal player_state_changed(snapshot: Dictionary)
signal game_mode_changed(mode: StringName)
signal action_requested(action: Dictionary)
signal action_completed(result: Dictionary)
signal service_registered(service_id: StringName)
signal service_unregistered(service_id: StringName)
