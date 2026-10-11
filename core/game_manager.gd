extends Node
## Lifecycle coordinator only. Gameplay rules belong to dedicated systems.
const MODE_CLIENT: StringName = &"client"
const MODE_SERVER: StringName = &"server"
var mode: StringName = &""
var is_initialized: bool = false

func initialize(requested_mode: StringName) -> bool:
    if requested_mode != MODE_CLIENT and requested_mode != MODE_SERVER:
        push_error("GameManager: invalid mode %s" % requested_mode)
        return false
    if is_initialized:
        if mode == requested_mode:
            return true
        push_error("GameManager: already initialized as %s" % mode)
        return false
    mode = requested_mode
    is_initialized = true
    EventBus.game_mode_changed.emit(mode)
    print("Uplord initialized: %s" % mode)
    return true

func shutdown() -> void:
    ServiceRegistry.clear_services()
    GameState.reset()
    mode = &""
    is_initialized = false
