extends Node
class_name Inventory

signal inventory_changed
signal item_added(item: Item, slot: int)
signal item_removed(item: Item, slot: int)

@export var slots_count: int = 20

var slots: Array[Dictionary] = []

func _ready() -> void:
	_init_slots()

func _init_slots() -> void:
	slots.clear()
	for i in range(slots_count):
		slots.append({"item": null, "quantity": 0})

func add_item(item: Item, quantity: int = 1) -> int:
	var remaining = quantity
	
	# First try to stack with existing items
	for i in range(slots_count):
		if remaining <= 0:
			break
		if slots[i]["item"] != null and slots[i]["item"].id == item.id:
			var can_add = item.max_stack - slots[i]["quantity"]
			var to_add = min(can_add, remaining)
			slots[i]["quantity"] += to_add
			remaining -= to_add
	
	# Then try empty slots
	for i in range(slots_count):
		if remaining <= 0:
			break
		if slots[i]["item"] == null:
			var to_add = min(item.max_stack, remaining)
			slots[i]["item"] = item
			slots[i]["quantity"] = to_add
			remaining -= to_add
			item_added.emit(item, i)
	
	inventory_changed.emit()
	return remaining  # Returns leftover items that couldn't fit

func remove_item(slot_index: int, quantity: int = 1) -> Item:
	if slot_index < 0 or slot_index >= slots_count:
		return null
	if slots[slot_index]["item"] == null:
		return null
	
	var item = slots[slot_index]["item"]
	slots[slot_index]["quantity"] -= quantity
	
	if slots[slot_index]["quantity"] <= 0:
		slots[slot_index]["item"] = null
		slots[slot_index]["quantity"] = 0
		item_removed.emit(item, slot_index)
	
	inventory_changed.emit()
	return item

func get_item(slot_index: int) -> Item:
	if slot_index < 0 or slot_index >= slots_count:
		return null
	return slots[slot_index]["item"]

func get_quantity(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= slots_count:
		return 0
	return slots[slot_index]["quantity"]

func has_item(item_id: String, quantity: int = 1) -> bool:
	var total = 0
	for slot in slots:
		if slot["item"] != null and slot["item"].id == item_id:
			total += slot["quantity"]
	return total >= quantity

func swap_slots(from: int, to: int) -> void:
	if from < 0 or from >= slots_count or to < 0 or to >= slots_count:
		return
	var temp = slots[from]
	slots[from] = slots[to]
	slots[to] = temp
	inventory_changed.emit()
