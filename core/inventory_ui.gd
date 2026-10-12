extends CanvasLayer
## Press I to toggle inventory; select an item to equip it when compatible.
var panel: PanelContainer
var list: VBoxContainer
var selected_item: String = ""

func _ready() -> void:
	panel = PanelContainer.new()
	panel.name = "InventoryPanel"
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(390, 380)
	panel.offset_left = -195
	panel.offset_top = -190
	panel.offset_right = 195
	panel.offset_bottom = 190
	var root := VBoxContainer.new()
	panel.add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var title := Label.new()
	title.text = "Inventory & Equipment (I)"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.text = "X"
	close.pressed.connect(func(): panel.hide())
	header.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(370, 330)
	root.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	Inventory.changed.connect(_refresh)
	panel.hide()
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_I:
		panel.visible = not panel.visible
		get_viewport().set_input_as_handled()
		if panel.visible:
			_refresh()

func _refresh() -> void:
	if not is_instance_valid(list):
		return
	for child in list.get_children():
		child.queue_free()
	var heading := Label.new()
	heading.text = "Items (select to equip)"
	list.add_child(heading)
	for item_id in Inventory.items.keys():
		var data := Inventory.definition(str(item_id))
		var btn := Button.new()
		btn.text = "%s  x%d" % [str(data.get("name", item_id)), int(Inventory.items[item_id])]
		btn.pressed.connect(_select_item.bind(str(item_id)))
		list.add_child(btn)
	var equipped_heading := Label.new()
	equipped_heading.text = "Equipment (click to unequip)"
	list.add_child(equipped_heading)
	for slot in Inventory.SLOTS:
		var equipped := str(Inventory.equipment.get(slot, ""))
		var btn := Button.new()
		btn.text = "%s: %s" % [slot.replace("_", " ").capitalize(), equipped if not equipped.is_empty() else "Empty"]
		btn.disabled = equipped.is_empty()
		btn.pressed.connect(_unequip.bind(slot))
		list.add_child(btn)

func _select_item(item_id: String) -> void:
	var data := Inventory.definition(item_id)
	var slot := str(data.get("equipment_slot", data.get("equipmentSlot", data.get("slot", "")))).to_lower()
	if Inventory.SLOTS.has(slot):
		Inventory.equip(item_id, slot)

func _unequip(slot: String) -> void:
	Inventory.unequip(slot)
