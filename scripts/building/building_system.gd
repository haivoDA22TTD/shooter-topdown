extends Node2D
class_name BuildingSystem

signal building_placed(building_type: String, position: Vector2)
signal building_mode_changed(is_active: bool)

enum BuildingType { WALL, FLOOR, DOOR, CAMPFIRE, STORAGE }

var is_building_mode: bool = false
var current_building_type: BuildingType = BuildingType.WALL
var preview_node: Node2D = null
var can_place: bool = false
var grid_size: int = 32

var building_costs: Dictionary = {
	BuildingType.WALL: {"item_id": "wooden_wall", "quantity": 1},
	BuildingType.FLOOR: {"item_id": "wooden_floor", "quantity": 1},
	BuildingType.CAMPFIRE: {"item_id": "campfire", "quantity": 1},
	BuildingType.STORAGE: {"item_id": "storage_box", "quantity": 1}
}

@onready var buildings_container: Node2D

func _ready() -> void:
	buildings_container = get_parent().get_node_or_null("Buildings")

func _process(_delta: float) -> void:
	if is_building_mode and preview_node:
		_update_preview_position()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("build_mode"):
		toggle_building_mode()
	
	if is_building_mode:
		if event.is_action_pressed("place_building"):
			_try_place_building()
		elif event.is_action_pressed("cancel_building"):
			exit_building_mode()
		elif event.is_action_pressed("rotate_building"):
			_rotate_preview()
		elif event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_cycle_building_type(1)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_cycle_building_type(-1)

func toggle_building_mode() -> void:
	if is_building_mode:
		exit_building_mode()
	else:
		enter_building_mode()

func enter_building_mode() -> void:
	is_building_mode = true
	_create_preview()
	building_mode_changed.emit(true)

func exit_building_mode() -> void:
	is_building_mode = false
	if preview_node:
		preview_node.queue_free()
		preview_node = null
	building_mode_changed.emit(false)

func _create_preview() -> void:
	if preview_node:
		preview_node.queue_free()
	
	preview_node = Node2D.new()
	var sprite = Sprite2D.new()
	sprite.name = "Sprite"
	
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	_draw_building_preview(img, current_building_type)
	sprite.texture = ImageTexture.create_from_image(img)
	sprite.modulate = Color(0, 1, 0, 0.5)
	
	preview_node.add_child(sprite)
	add_child(preview_node)

func _draw_building_preview(img: Image, type: BuildingType) -> void:
	match type:
		BuildingType.WALL:
			img.fill(Color.SADDLE_BROWN)
		BuildingType.FLOOR:
			for x in range(32):
				for y in range(32):
					img.set_pixel(x, y, Color(0.6, 0.4, 0.2, 0.8))
		BuildingType.CAMPFIRE:
			for x in range(8, 24):
				for y in range(16, 32):
					img.set_pixel(x, y, Color.SADDLE_BROWN)
			for x in range(10, 22):
				for y in range(4, 18):
					img.set_pixel(x, y, Color.ORANGE_RED)
		BuildingType.STORAGE:
			img.fill(Color.BURLYWOOD)

func _update_preview_position() -> void:
	var mouse_pos = get_global_mouse_position()
	var snapped_pos = Vector2(
		snapped(mouse_pos.x, grid_size),
		snapped(mouse_pos.y, grid_size)
	)
	preview_node.global_position = snapped_pos
	
	# Check if can place
	can_place = _check_placement_valid(snapped_pos)
	var sprite = preview_node.get_node("Sprite") as Sprite2D
	sprite.modulate = Color(0, 1, 0, 0.5) if can_place else Color(1, 0, 0, 0.5)

func _check_placement_valid(pos: Vector2) -> bool:
	# Check for overlapping buildings
	var space = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collision_mask = 8  # Building layer
	var results = space.intersect_point(query)
	return results.is_empty()

func _try_place_building() -> void:
	if not can_place:
		return
	
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager == null:
		return
	
	var cost = building_costs.get(current_building_type)
	if cost and not game_manager.player_inventory.has_item(cost["item_id"], cost["quantity"]):
		return
	
	# Consume item
	if cost:
		for i in range(game_manager.player_inventory.slots_count):
			var item = game_manager.player_inventory.get_item(i)
			if item and item.id == cost["item_id"]:
				game_manager.player_inventory.remove_item(i, cost["quantity"])
				break
	
	_place_building(preview_node.global_position)

func _place_building(pos: Vector2) -> void:
	var building = _create_building(current_building_type)
	building.global_position = pos
	
	if buildings_container:
		buildings_container.add_child(building)
	else:
		get_parent().add_child(building)
	
	building_placed.emit(_get_building_name(current_building_type), pos)

func _create_building(type: BuildingType) -> StaticBody2D:
	var building = StaticBody2D.new()
	building.collision_layer = 8
	building.collision_mask = 0
	
	var sprite = Sprite2D.new()
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	_draw_building_preview(img, type)
	sprite.texture = ImageTexture.create_from_image(img)
	sprite.modulate = Color.WHITE
	building.add_child(sprite)
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(30, 30)
	collision.shape = shape
	building.add_child(collision)
	
	# Add interaction for special buildings
	if type == BuildingType.CAMPFIRE or type == BuildingType.STORAGE:
		var area = Area2D.new()
		area.collision_layer = 4
		var area_shape = CollisionShape2D.new()
		area_shape.shape = shape.duplicate()
		area.add_child(area_shape)
		building.add_child(area)
		
		var script_path = "res://scripts/building/campfire.gd" if type == BuildingType.CAMPFIRE else "res://scripts/building/storage_box.gd"
		if ResourceLoader.exists(script_path):
			building.set_script(load(script_path))
	
	return building

func _rotate_preview() -> void:
	if preview_node:
		preview_node.rotation_degrees += 90

func _cycle_building_type(direction: int) -> void:
	var types = BuildingType.values()
	var current_index = types.find(current_building_type)
	current_index = (current_index + direction) % types.size()
	if current_index < 0:
		current_index = types.size() - 1
	current_building_type = types[current_index]
	_create_preview()

func _get_building_name(type: BuildingType) -> String:
	match type:
		BuildingType.WALL: return "Wall"
		BuildingType.FLOOR: return "Floor"
		BuildingType.DOOR: return "Door"
		BuildingType.CAMPFIRE: return "Campfire"
		BuildingType.STORAGE: return "Storage"
	return "Unknown"
