extends Node
class_name UplordCombatController
## Phase 6.1 local combat preview. Multiplayer authority is a later phase.
signal combat_updated
var map: UplordMapBase
var target: UplordWorldEntity
var enemy_hp: int = 0
var enemy_max_hp: int = 0
var player_hp: int = 100
var player_max_hp: int = 100
var active: bool = false
var enemy_dead: bool = false
var respawning_enemy: UplordWorldEntity = null
var attack_timer: float = 0.0
var enemy_timer: float = 0.0
var respawn_timer: float = 0.0
var hud: CanvasLayer
var status: Label
var panel: PanelContainer
var attack_button: Button

func configure(owner_map: UplordMapBase) -> void:
	map = owner_map
	map.targeting.interaction_activated.connect(_on_interaction)
	map.targeting.target_changed.connect(_on_target_changed)
	map.targeting.attack_requested.connect(attack)
	hud = CanvasLayer.new()
	hud.name = "CombatHUD"
	add_child(hud)
	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	panel.position = Vector2(18, -112)
	panel.custom_minimum_size = Vector2(270, 0)
	hud.add_child(panel)
	var stack := VBoxContainer.new()
	panel.add_child(stack)
	status = Label.new()
	status.text = "Combat: select an enemy"
	stack.add_child(status)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	panel.offset_left = 18
	panel.offset_right = 290
	panel.offset_top = -112
	panel.offset_bottom = -18
	_update_hud()

func _on_target_changed(entity: UplordWorldEntity) -> void:
	if active and entity != target:
		# Combat locks the encounter until the enemy dies or the map changes.
		return
	if not active:
		target = entity if is_instance_valid(entity) and entity.entity_type == "enemy" else null
		_update_hud()

func _on_interaction(entity: UplordWorldEntity, _action: String) -> void:
	if entity.entity_type != "enemy" or not entity.runtime_enabled:
		return
	if active or enemy_dead:
		return
	target = entity
	enemy_max_hp = maxi(1, int(entity.get_gameplay_value("max_hp", 100)))
	enemy_hp = enemy_max_hp
	active = true
	attack_timer = 0.0
	enemy_timer = maxf(0.2, float(entity.get_gameplay_value("attack_interval", 2.0)))
	_update_hud()

func _process(delta: float) -> void:
	if enemy_dead:
		respawn_timer -= delta
		if respawn_timer <= 0.0:
			# Respawn the defeated entity even if the player deselected it.
			if is_instance_valid(respawning_enemy):
				respawning_enemy.runtime_enabled = true
				respawning_enemy.visible = true
				respawning_enemy.input_pickable = true
				enemy_hp = maxi(1, int(respawning_enemy.get_gameplay_value("max_hp", 100)))
				enemy_max_hp = enemy_hp
			enemy_dead = false
			respawning_enemy = null
			_update_hud()
		return
	if not active:
		_update_hud()
		return
	if not is_instance_valid(target):
		active = false
		target = null
		_update_hud()
		return
	attack_timer = maxf(0.0, attack_timer - delta)
	_update_hud()
	enemy_timer -= delta
	if enemy_timer <= 0.0:
		enemy_timer = maxf(0.2, float(target.get_gameplay_value("attack_interval", 2.0)))
		player_hp = maxi(0, player_hp - maxi(0, int(target.get_gameplay_value("damage", 5))))
		if player_hp == 0:
			active = false
			player_hp = player_max_hp # Local preview reset; server death handling comes later.
		_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_1:
		attack()

func attack() -> void:
	if not active or not is_instance_valid(target) or attack_timer > 0.0:
		return
	if map.player.global_position.distance_to(target.global_position) > target.interaction_radius + 16.0:
		return
	attack_timer = maxf(0.2, float(target.get_gameplay_value("player_attack_interval", 1.0)))
	enemy_hp = maxi(0, enemy_hp - maxi(1, int(target.get_gameplay_value("preview_player_damage", 10))))
	if enemy_hp == 0:
		active = false
		enemy_dead = true
		respawning_enemy = target
		respawn_timer = maxf(1.0, float(target.get_gameplay_value("respawn_seconds", 15.0)))
		target.visible = false
		target.input_pickable = false
		target.runtime_enabled = false
	_update_hud()

func _update_hud() -> void:
	if is_instance_valid(map) and is_instance_valid(map.targeting):
		map.targeting.combat_active = active
		map.targeting.combat_attack_ready = attack_timer <= 0.0
		map.targeting._update_interact_button()
	if not is_instance_valid(status):
		return
	if active and is_instance_valid(target):
		status.text = "%s  Lv.%d  HP %d/%d\nPlayer HP %d/%d" % [target.display_label, int(target.get_gameplay_value("level", 1)), enemy_hp, enemy_max_hp, player_hp, player_max_hp]
	elif enemy_dead:
		status.text = "Enemy defeated · respawning in %ds" % ceili(respawn_timer)
	elif is_instance_valid(target) and target.entity_type == "enemy":
		status.text = "%s  Lv.%d  HP %d/%d\nApproach, then press Attack to start combat" % [target.display_label, int(target.get_gameplay_value("level", 1)), int(target.get_gameplay_value("max_hp", 100)), int(target.get_gameplay_value("max_hp", 100))]
	else:
		status.text = "Combat: approach an enemy and Attack"
	var selected_enemy: bool = is_instance_valid(target) and target.entity_type == "enemy" and map.targeting.selected_entity == target
	panel.visible = selected_enemy and not enemy_dead
	var in_range: bool = selected_enemy and map.player.global_position.distance_to(target.global_position) <= target.interaction_radius if selected_enemy else false
	# Action is handled by the bottom-right InteractionHUD button.
