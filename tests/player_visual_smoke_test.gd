extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://characters/player/player_character.tscn")
	assert(scene != null, "Player character scene must load")
	var player: UplordPlayerCharacter = scene.instantiate()
	root.add_child.call_deferred(player)
	_check.call_deferred(player)

func _check(player: UplordPlayerCharacter) -> void:
	assert(player.get_part("Head") != null, "Head missing")
	assert(player.get_part("ShinFront") != null, "Front shin missing")
	assert(player.get_part("HandBack") != null, "Back hand missing")
	for slot in ["Helm", "Armour", "Cape", "MainHand", "OffHand"]:
		assert(player.get_equipment_socket(slot) != null, "Missing socket: " + slot)
	player.set_facing_left(true)
	assert(player.visuals.scale.x == -1.0, "Left-facing mirror failed")
	player.set_facing_left(false)
	assert(player.visuals.scale.x == 1.0, "Right-facing mirror failed")
	print("PASS: modular player scene, equipment sockets, facing")
	quit()
