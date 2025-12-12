extends Node
class_name CraftingSystem

signal crafting_started(recipe: CraftingRecipe)
signal crafting_completed(item_id: String, quantity: int)
signal crafting_failed(reason: String)

var recipes: Dictionary = {}  # id -> CraftingRecipe
var is_crafting: bool = false
var current_recipe: CraftingRecipe = null
var craft_timer: float = 0.0

func _ready() -> void:
	_init_recipes()

func _init_recipes() -> void:
	# Basic recipes
	_add_recipe("wooden_pickaxe", "wooden_pickaxe", 1, [
		{"item_id": "wood", "quantity": 5},
		{"item_id": "stone", "quantity": 2}
	], 3.0)
	
	_add_recipe("wooden_axe", "wooden_axe", 1, [
		{"item_id": "wood", "quantity": 5},
		{"item_id": "stone", "quantity": 2}
	], 3.0)
	
	_add_recipe("wooden_spear", "wooden_spear", 1, [
		{"item_id": "wood", "quantity": 8}
	], 2.0)
	
	_add_recipe("campfire", "campfire", 1, [
		{"item_id": "wood", "quantity": 10},
		{"item_id": "stone", "quantity": 5}
	], 5.0)
	
	_add_recipe("wooden_wall", "wooden_wall", 1, [
		{"item_id": "wood", "quantity": 15}
	], 4.0)
	
	_add_recipe("wooden_floor", "wooden_floor", 1, [
		{"item_id": "wood", "quantity": 10}
	], 3.0)
	
	_add_recipe("storage_box", "storage_box", 1, [
		{"item_id": "wood", "quantity": 20}
	], 5.0)
	
	_add_recipe("bandage", "bandage", 2, [
		{"item_id": "cloth", "quantity": 3}
	], 2.0)
	
	_add_recipe("cooked_meat", "cooked_meat", 1, [
		{"item_id": "meat", "quantity": 1}
	], 3.0, "campfire")

func _add_recipe(id: String, result: String, qty: int, ingredients: Array, time: float, station: String = "") -> void:
	var recipe = CraftingRecipe.new()
	recipe.id = id
	recipe.result_item_id = result
	recipe.result_quantity = qty
	recipe.ingredients = ingredients.duplicate()
	recipe.crafting_time = time
	recipe.required_station = station
	recipes[id] = recipe

func _process(delta: float) -> void:
	if is_crafting:
		craft_timer -= delta
		if craft_timer <= 0:
			_complete_crafting()

func start_crafting(recipe_id: String, inventory: Inventory, station: String = "") -> bool:
	if is_crafting:
		crafting_failed.emit("Already crafting")
		return false
	
	if not recipes.has(recipe_id):
		crafting_failed.emit("Recipe not found")
		return false
	
	var recipe = recipes[recipe_id] as CraftingRecipe
	
	if recipe.required_station != "" and recipe.required_station != station:
		crafting_failed.emit("Requires: " + recipe.required_station)
		return false
	
	if not recipe.can_craft(inventory):
		crafting_failed.emit("Missing ingredients")
		return false
	
	if not recipe.consume_ingredients(inventory):
		crafting_failed.emit("Failed to consume ingredients")
		return false
	
	is_crafting = true
	current_recipe = recipe
	craft_timer = recipe.crafting_time
	crafting_started.emit(recipe)
	return true

func _complete_crafting() -> void:
	is_crafting = false
	if current_recipe:
		crafting_completed.emit(current_recipe.result_item_id, current_recipe.result_quantity)
	current_recipe = null

func get_available_recipes(_inventory: Inventory, station: String = "") -> Array[CraftingRecipe]:
	var available: Array[CraftingRecipe] = []
	for recipe in recipes.values():
		if recipe.required_station == "" or recipe.required_station == station:
			available.append(recipe)
	return available

func get_craftable_recipes(inventory: Inventory, station: String = "") -> Array[CraftingRecipe]:
	var craftable: Array[CraftingRecipe] = []
	for recipe in recipes.values():
		if recipe.can_craft(inventory):
			if recipe.required_station == "" or recipe.required_station == station:
				craftable.append(recipe)
	return craftable
