extends CanvasLayer
class_name CraftingUI

@onready var panel: Panel = $Panel
@onready var close_btn: Button = $Panel/TopBar/CloseBtn
@onready var recipe_list: VBoxContainer = $Panel/Content/RecipeScroll/RecipeList
@onready var recipe_info: VBoxContainer = $Panel/Content/RecipeInfo
@onready var recipe_name: Label = $Panel/Content/RecipeInfo/RecipeName
@onready var ingredients_list: VBoxContainer = $Panel/Content/RecipeInfo/IngredientsScroll/IngredientsList
@onready var craft_btn: Button = $Panel/Content/RecipeInfo/CraftBtn
@onready var progress_bar: ProgressBar = $Panel/Content/RecipeInfo/ProgressBar

var crafting_system: CraftingSystem
var inventory: Inventory
var is_open: bool = false
var current_station: String = ""
var available_recipes: Array[CraftingRecipe] = []
var selected_recipe: CraftingRecipe = null
var recipe_buttons: Array[Button] = []

func _ready() -> void:
	panel.visible = false
	close_btn.pressed.connect(_close)
	craft_btn.pressed.connect(_on_craft_pressed)

func setup(craft_sys: CraftingSystem, inv: Inventory) -> void:
	crafting_system = craft_sys
	inventory = inv
	crafting_system.crafting_started.connect(_on_crafting_started)
	crafting_system.crafting_completed.connect(_on_crafting_completed)
	crafting_system.crafting_failed.connect(_on_crafting_failed)

func _input(_event: InputEvent) -> void:
	pass  # Handled by main.gd

func _process(_delta: float) -> void:
	if is_open and crafting_system.is_crafting:
		var progress = 1.0 - (crafting_system.craft_timer / crafting_system.current_recipe.crafting_time)
		progress_bar.value = progress

func toggle(station: String = "") -> void:
	current_station = station
	is_open = !is_open
	panel.visible = is_open
	
	if is_open:
		_refresh_recipes()
		recipe_info.visible = false

func _close() -> void:
	is_open = false
	panel.visible = false

func _refresh_recipes() -> void:
	# Clear old buttons
	for btn in recipe_buttons:
		btn.queue_free()
	recipe_buttons.clear()
	
	available_recipes = crafting_system.get_available_recipes(inventory, current_station)
	var game_manager = get_node_or_null("/root/GameManager")
	
	for i in range(available_recipes.size()):
		var recipe = available_recipes[i]
		var can_craft = recipe.can_craft(inventory)
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 50)
		
		# Lấy tên tiếng Việt
		var item_name = recipe.result_item_id.replace("_", " ").capitalize()
		if game_manager:
			var item = game_manager.get_item(recipe.result_item_id)
			if item:
				item_name = item.name
		btn.text = item_name
		btn.pressed.connect(_on_recipe_selected.bind(i))
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.25, 0.25, 0.25) if can_craft else Color(0.15, 0.15, 0.15)
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		btn.add_theme_stylebox_override("normal", style)
		
		if not can_craft:
			btn.modulate = Color(0.6, 0.6, 0.6)
		
		recipe_list.add_child(btn)
		recipe_buttons.append(btn)

func _on_recipe_selected(index: int) -> void:
	if index < 0 or index >= available_recipes.size():
		return
	
	selected_recipe = available_recipes[index]
	_update_recipe_info()
	recipe_info.visible = true

func _update_recipe_info() -> void:
	if selected_recipe == null:
		return
	
	# Lấy tên tiếng Việt từ game manager
	var game_manager = get_node_or_null("/root/GameManager")
	var item_name = selected_recipe.result_item_id.replace("_", " ").capitalize()
	if game_manager:
		var item = game_manager.get_item(selected_recipe.result_item_id)
		if item:
			item_name = item.name
	
	recipe_name.text = item_name + " x" + str(selected_recipe.result_quantity)
	
	# Clear old ingredients
	for child in ingredients_list.get_children():
		child.queue_free()
	
	# Add ingredients
	for ingredient in selected_recipe.ingredients:
		var hbox = HBoxContainer.new()
		
		var name_label = Label.new()
		var ing_name = ingredient["item_id"].replace("_", " ").capitalize()
		if game_manager:
			var ing_item = game_manager.get_item(ingredient["item_id"])
			if ing_item:
				ing_name = ing_item.name
		name_label.text = ing_name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_label)
		
		var qty_label = Label.new()
		var has_qty = _count_item(ingredient["item_id"])
		var required = ingredient["quantity"]
		qty_label.text = "%d/%d" % [has_qty, required]
		qty_label.modulate = Color.GREEN if has_qty >= required else Color.RED
		hbox.add_child(qty_label)
		
		ingredients_list.add_child(hbox)
	
	craft_btn.text = "Chế Tạo"
	craft_btn.disabled = not selected_recipe.can_craft(inventory) or crafting_system.is_crafting

func _count_item(item_id: String) -> int:
	var total = 0
	for i in range(inventory.slots_count):
		var item = inventory.get_item(i)
		if item and item.id == item_id:
			total += inventory.get_quantity(i)
	return total

func _on_craft_pressed() -> void:
	if selected_recipe == null:
		return
	crafting_system.start_crafting(selected_recipe.id, inventory, current_station)

func _on_crafting_started(_recipe: CraftingRecipe) -> void:
	craft_btn.disabled = true
	progress_bar.visible = true
	progress_bar.value = 0

func _on_crafting_completed(item_id: String, quantity: int) -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		var item = game_manager.get_item(item_id)
		if item:
			inventory.add_item(item, quantity)
	
	progress_bar.visible = false
	progress_bar.value = 0
	_refresh_recipes()
	_update_recipe_info()

func _on_crafting_failed(_reason: String) -> void:
	progress_bar.visible = false
	progress_bar.value = 0
