extends Node

@onready var game_world: GameWorld = $GameWorld
@onready var player: Player = $GameWorld/Player
@onready var player_inventory: Inventory = $PlayerInventory
@onready var crafting_system: CraftingSystem = $CraftingSystem
@onready var hud: HUD = $HUD
@onready var inventory_ui: InventoryUI = $InventoryUI
@onready var crafting_ui: CraftingUI = $CraftingUI
@onready var world_map: WorldMap = $WorldMap
@onready var weather_system: WeatherSystem = $WeatherSystem
@onready var pause_menu: PauseMenu = $PauseMenu

var _is_equipping: bool = false

func _ready() -> void:
	hud.setup(player)
	inventory_ui.setup(player_inventory)
	crafting_ui.setup(crafting_system, player_inventory)
	world_map.location_selected.connect(_on_location_selected)
	world_map.setup_player(player)
	
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.setup_player(player, player_inventory)
	
	# Connect signals
	hud.inventory_pressed.connect(_on_inventory_pressed)
	hud.crafting_pressed.connect(_on_crafting_pressed)
	hud.build_pressed.connect(_on_build_pressed)
	hud.attack_pressed.connect(_on_attack_pressed)
	hud.interact_pressed.connect(_on_interact_pressed)
	hud.joystick_input.connect(_on_joystick_input)
	hud.hotbar_slot_selected.connect(_on_hotbar_selected)
	
	inventory_ui.item_used.connect(_on_item_used)
	inventory_ui.item_dropped.connect(_on_item_dropped)
	inventory_ui.closed.connect(_on_ui_closed)
	
	player_inventory.inventory_changed.connect(_on_inventory_changed)
	
	weather_system.time_changed.connect(_on_time_changed)
	weather_system.weather_changed.connect(_on_weather_changed)
	
	# Kết nối weapon_changed để cập nhật HUD
	player.weapon_changed.connect(_on_weapon_changed)
	
	# Kết nối inventory_ui equip
	inventory_ui.item_equipped.connect(_on_item_equipped)
	
	_give_starter_items()
	
	player.health_changed.emit(player.health, player.max_health)
	player.hunger_changed.emit(player.hunger, player.max_hunger)
	player.thirst_changed.emit(player.thirst, player.max_thirst)
	player.stamina_changed.emit(player.stamina, player.max_stamina)

func _process(_delta: float) -> void:
	_update_zone_display()

func _update_zone_display() -> void:
	var zone = game_world.get_zone_at(player.global_position)
	var zone_name = game_world.get_zone_name(zone)
	hud.update_zone(zone_name)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		inventory_ui.toggle()
	elif event.is_action_pressed("crafting"):
		crafting_ui.toggle()
	elif event.is_action_pressed("build_mode"):
		_on_build_pressed()
	elif event.is_action_pressed("map"):
		print("Map key pressed!")
		if world_map:
			world_map.toggle()
		else:
			print("ERROR: world_map is null!")

func _give_starter_items() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager == null:
		return
	
	var starter_items = [
		{"id": "wood", "qty": 15},
		{"id": "stone", "qty": 10},
		{"id": "berries", "qty": 8},
		{"id": "ammo_pistol", "qty": 30},
		{"id": "ammo_rifle", "qty": 20}
	]
	
	for item_data in starter_items:
		var item = game_manager.get_item(item_data["id"])
		if item:
			player_inventory.add_item(item, item_data["qty"])
	
	# Cho người chơi một ít đạn dự trữ
	player.add_ammo("pistol", 30)
	player.add_ammo("rifle", 20)
	player.add_ammo("shotgun", 10)

func _on_inventory_pressed() -> void:
	inventory_ui.toggle()

func _on_crafting_pressed() -> void:
	crafting_ui.toggle()

func _on_build_pressed() -> void:
	pass

func _on_attack_pressed() -> void:
	player.attack()

func _on_interact_pressed() -> void:
	player.interact()

func _on_joystick_input(direction: Vector2) -> void:
	player.joystick_direction = direction

func _on_hotbar_selected(index: int) -> void:
	# Khi click vào hotbar, sử dụng vũ khí đã trang bị ở slot đó
	if _is_equipping:
		return
	if index < hud.equipped_items.size() and hud.equipped_items[index] != null:
		_is_equipping = true
		var equipped = hud.equipped_items[index]
		if equipped is Item:
			player.equip_item(equipped)
		elif equipped is WeaponData:
			player.equip_weapon_data(equipped)
		_is_equipping = false

func _on_item_used(slot_index: int) -> void:
	var item = player_inventory.get_item(slot_index)
	if item and item.is_usable:
		if item.use(player):
			player_inventory.remove_item(slot_index, 1)

func _on_item_dropped(slot_index: int) -> void:
	var item = player_inventory.get_item(slot_index)
	var qty = player_inventory.get_quantity(slot_index)
	if item:
		var game_manager = get_node_or_null("/root/GameManager")
		if game_manager:
			game_manager.spawn_dropped_item(item.id, qty, player.global_position)
		player_inventory.remove_item(slot_index, qty)

func _on_ui_closed() -> void:
	pass

func _on_inventory_changed() -> void:
	# Không cần update hotbar từ inventory nữa vì hotbar chỉ hiển thị vũ khí đã trang bị
	pass

func _on_time_changed(hour: int, is_day: bool) -> void:
	pass

func _on_weather_changed(weather_type: String) -> void:
	pass

func _on_weapon_changed(weapon: WeaponData) -> void:
	hud.update_weapon_display(weapon)
	if weapon and not _is_equipping:
		_is_equipping = true
		var slot = hud.add_equipped_item(weapon)
		hud.select_hotbar_slot(slot)
		_is_equipping = false

func _on_item_equipped(slot_index: int) -> void:
	if _is_equipping:
		return
	var item = player_inventory.get_item(slot_index)
	if item and item.is_equippable:
		_is_equipping = true
		player.equip_item(item)
		var equipped_slot = hud.add_equipped_item(item)
		hud.select_hotbar_slot(equipped_slot)
		_is_equipping = false

func _on_location_selected(location_id: String) -> void:
	# Di chuyển người chơi đến vị trí
	print("Đang di chuyển đến: ", location_id)
	match location_id:
		"home":
			player.global_position = Vector2(0, 0)
		"forest_1":
			player.global_position = Vector2(-800, 200)
		"forest_2":
			player.global_position = Vector2(-1200, -200)
		"snow_1":
			player.global_position = Vector2(0, -1500)
		"snow_2":
			player.global_position = Vector2(600, -2000)
		"desert_1":
			player.global_position = Vector2(1200, 400)
		"desert_2":
			player.global_position = Vector2(1800, 0)
		"city_1":
			player.global_position = Vector2(600, -400)
		"military":
			player.global_position = Vector2(1500, -1000)
