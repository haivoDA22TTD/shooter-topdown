extends Resource
class_name CraftingRecipe

@export var id: String = ""
@export var result_item_id: String = ""
@export var result_quantity: int = 1
@export var ingredients: Array = []  # [{item_id: "wood", quantity: 5}]
@export var crafting_time: float = 2.0
@export var required_station: String = ""  # Empty = can craft anywhere

func can_craft(inventory: Inventory) -> bool:
	for ingredient in ingredients:
		var ing_dict = ingredient as Dictionary
		if not inventory.has_item(ing_dict["item_id"], ing_dict["quantity"]):
			return false
	return true

func consume_ingredients(inventory: Inventory) -> bool:
	if not can_craft(inventory):
		return false
	
	for ingredient in ingredients:
		var ing_dict = ingredient as Dictionary
		var remaining = ing_dict["quantity"]
		for i in range(inventory.slots_count):
			if remaining <= 0:
				break
			var item = inventory.get_item(i)
			if item != null and item.id == ing_dict["item_id"]:
				var qty = inventory.get_quantity(i)
				var to_remove = min(qty, remaining)
				inventory.remove_item(i, to_remove)
				remaining -= to_remove
	return true

func get_description() -> String:
	var text = "Ingredients:\n"
	for ingredient in ingredients:
		var ing_dict = ingredient as Dictionary
		text += "- %s x%d\n" % [ing_dict["item_id"], ing_dict["quantity"]]
	return text
