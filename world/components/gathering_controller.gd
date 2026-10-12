extends Node
class_name UplordGatheringController
## Phase 6.2: local gathering preview. Inventory and XP are session-only.
signal resource_gathered(item_id: String, quantity: int, skill_id: String)
var map: UplordMapBase
var inventory: Dictionary = {}
var skill_xp: Dictionary = {}
var skill_levels: Dictionary = {"mining": 1, "woodcutting": 1, "fishing": 1}
var depleted: Dictionary = {} # instance ID -> remaining seconds
var active_resource: UplordWorldEntity
var progress: float = 0.0
var panel: PanelContainer
var status: Label
var gather_button: Button

func configure(owner_map: UplordMapBase) -> void:
	map = owner_map
	map.targeting.interaction_activated.connect(_on_interaction)
	map.targeting.target_changed.connect(_on_target_changed)
	var hud := CanvasLayer.new()
	hud.name = "GatheringHUD"
	add_child(hud)
	panel = PanelContainer.new()
	hud.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	panel.offset_left = 18
	panel.offset_right = 302
	panel.offset_top = -132
	panel.offset_bottom = -18
	var stack := VBoxContainer.new()
	panel.add_child(stack)
	status = Label.new()
	stack.add_child(status)
	_update_hud()

func _on_target_changed(entity: UplordWorldEntity) -> void:
	if entity != active_resource:
		progress = 0.0
	active_resource = entity if is_instance_valid(entity) and (entity.entity_type == "resource" or entity.definition_id == "copper_rock") else null
	_update_hud()

func _on_interaction(entity: UplordWorldEntity, _action: String) -> void:
	if (entity.entity_type != "resource" and entity.definition_id != "copper_rock") or not entity.runtime_enabled:
		return
	active_resource = entity
	_start_gather()

func _start_gather() -> void:
	if progress > 0.0:
		return
	if not is_instance_valid(active_resource) or not active_resource.runtime_enabled:
		return
	if depleted.has(active_resource.get_instance_id()):
		return
	if map.player.global_position.distance_to(active_resource.global_position) > active_resource.interaction_radius + 16.0:
		return
	var skill_id := str(active_resource.get_gameplay_value("skill_id", "mining"))
	var required := maxi(1, int(active_resource.get_gameplay_value("required_level", 1)))
	if int(skill_levels.get(skill_id, 1)) < required:
		status.text = "%s level %d required" % [skill_id.capitalize(), required]
		return
	progress = maxf(0.2, float(active_resource.get_gameplay_value("gather_seconds", 2.0)))
	_update_hud()

func _process(delta: float) -> void:
	for key in depleted.keys():
		depleted[key] = float(depleted[key]) - delta
		if float(depleted[key]) <= 0.0:
			depleted.erase(key)
			for entity in map.list_world_entities():
				if entity.get_instance_id() == int(key):
					entity.visible = true
					entity.input_pickable = true
	if progress <= 0.0:
		_update_hud()
		return
	if not is_instance_valid(active_resource) or map.player.global_position.distance_to(active_resource.global_position) > active_resource.interaction_radius + 16.0:
		progress = 0.0
		_update_hud()
		return
	progress -= delta
	if progress <= 0.0:
		_complete_gather()
	else:
		_update_hud()

func _complete_gather() -> void:
	if not is_instance_valid(active_resource):
		return
	var item_id := str(active_resource.get_gameplay_value("item_id", ""))
	var skill_id := str(active_resource.get_gameplay_value("skill_id", "mining"))
	var quantity := maxi(1, int(active_resource.get_gameplay_value("quantity", 1)))
	if item_id.is_empty():
		push_warning("Gathering resource has no item_id: %s" % active_resource.definition_id)
		return
	inventory[item_id] = int(inventory.get(item_id, 0)) + quantity
	skill_xp[skill_id] = int(skill_xp.get(skill_id, 0)) + maxi(0, int(active_resource.get_gameplay_value("xp", 10)))
	resource_gathered.emit(item_id, quantity, skill_id)
	var respawn := maxf(1.0, float(active_resource.get_gameplay_value("respawn_seconds", 30.0)))
	depleted[active_resource.get_instance_id()] = respawn
	active_resource.visible = false
	active_resource.input_pickable = false
	progress = 0.0
	_update_hud()

func _update_hud() -> void:
	if not is_instance_valid(status):
		return
	if is_instance_valid(active_resource):
		var item_id := str(active_resource.get_gameplay_value("item_id", ""))
		var skill_id := str(active_resource.get_gameplay_value("skill_id", "mining"))
		status.text = "%s\n%s: %d  |  XP: %d" % [active_resource.display_label, item_id.replace("_", " ").capitalize(), int(inventory.get(item_id, 0)), int(skill_xp.get(skill_id, 0))]
		if progress > 0.0:
			status.text += "\nGathering... %.1fs" % progress
		elif depleted.has(active_resource.get_instance_id()):
			status.text += "\nDepleted (%.0fs)" % float(depleted[active_resource.get_instance_id()])
	else:
		status.text = "Gathering: select a resource"
	var selected_resource: bool = is_instance_valid(active_resource) and active_resource.entity_type == "resource" and map.targeting.selected_entity == active_resource
	panel.visible = selected_resource
	var in_range: bool = selected_resource and map.player.global_position.distance_to(active_resource.global_position) <= active_resource.interaction_radius if selected_resource else false
	# Action is handled by the bottom-right InteractionHUD button.
