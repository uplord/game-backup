extends Node
## Phase 6.3: session-wide inventory. Persistence and server authority follow later.
signal changed
const SLOTS := ["helm", "armour", "cape", "main_hand", "off_hand", "pickaxe", "axe", "fishing_rod"]
var items: Dictionary = {}
var equipment: Dictionary = {}

func definition(item_id: String) -> Dictionary:
	if PublishedContent.repository == null:
		return {}
	return PublishedContent.repository.get_definition("items", item_id)

func add_item(item_id: String, quantity: int = 1) -> bool:
	if quantity <= 0 or definition(item_id).is_empty():
		return false
	items[item_id] = int(items.get(item_id, 0)) + quantity
	changed.emit()
	return true

func remove_item(item_id: String, quantity: int = 1) -> bool:
	if quantity <= 0 or int(items.get(item_id, 0)) < quantity:
		return false
	var remaining := int(items[item_id]) - quantity
	if remaining == 0:
		items.erase(item_id)
	else:
		items[item_id] = remaining
	changed.emit()
	return true

func equip(item_id: String, slot: String) -> bool:
	if not SLOTS.has(slot) or int(items.get(item_id, 0)) < 1:
		return false
	var data := definition(item_id)
	if data.is_empty():
		return false
	var allowed := str(data.get("equipment_slot", data.get("equipmentSlot", data.get("slot", "")))).to_lower()
	if allowed != slot:
		return false
	var old_id := str(equipment.get(slot, ""))
	if not remove_item(item_id):
		return false
	if not old_id.is_empty():
		items[old_id] = int(items.get(old_id, 0)) + 1
	equipment[slot] = item_id
	changed.emit()
	return true

func unequip(slot: String) -> bool:
	var item_id := str(equipment.get(slot, ""))
	if item_id.is_empty():
		return false
	equipment.erase(slot)
	items[item_id] = int(items.get(item_id, 0)) + 1
	changed.emit()
	return true
