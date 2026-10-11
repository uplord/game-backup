extends Node2D
## Temporary Phase 2.1 visual preview. Not the gameplay player controller.
@onready var character: UplordPlayerCharacter = $PlayerCharacter

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_LEFT or event.keycode == KEY_A:
			character.set_facing_left(true)
		elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
			character.set_facing_left(false)
