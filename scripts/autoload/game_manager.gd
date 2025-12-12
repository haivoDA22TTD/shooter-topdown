extends Node

signal game_paused
signal game_resumed
signal day_night_changed(is_day: bool)
signal weapon_picked_up(weapon: WeaponData)

# References
var player: Player
var player_inventory: Inventory
var crafting_system: CraftingSystem
var building_system: BuildingSystem

# Item database
var items_db: Dictionary = {}

# Day/Night cycle
var time_of_day: float = 0.0  # 0-24
var day_length: float = 300.0  # seconds per day
var is_day: bool = true

# Dropped items scene
var dropped_item_scene: PackedScene

# Weapon box scene
var weapon_box_scene: PackedScene

func _ready() -> void:
	_init_items_database()
	_load_dropped_item_scene()
	_load_weapon_box_scene()

func _load_weapon_box_scene() -> void:
	if ResourceLoader.exists("res://scenes/items/weapon_box.tscn"):
		weapon_box_scene = load("res://scenes/items/weapon_box.tscn")

func _load_dropped_item_scene() -> void:
	if ResourceLoader.exists("res://scenes/items/dropped_item.tscn"):
		dropped_item_scene = load("res://scenes/items/dropped_item.tscn")

func _process(delta: float) -> void:
	_update_day_night_cycle(delta)

func _update_day_night_cycle(delta: float) -> void:
	time_of_day += (24.0 / day_length) * delta
	if time_of_day >= 24.0:
		time_of_day = 0.0
	
	var was_day = is_day
	is_day = time_of_day >= 6.0 and time_of_day < 20.0
	
	if was_day != is_day:
		day_night_changed.emit(is_day)

func _init_items_database() -> void:
	# Nguyên liệu
	_add_item("wood", "Gỗ", "Nguyên liệu xây dựng cơ bản", Item.ItemType.MATERIAL, 99)
	_add_item("stone", "Đá", "Nguyên liệu cứng để chế tạo", Item.ItemType.MATERIAL, 99)
	_add_item("iron_ore", "Quặng Sắt", "Sắt thô, cần nung chảy", Item.ItemType.MATERIAL, 50)
	_add_item("cloth", "Vải", "Vải để chế tạo", Item.ItemType.MATERIAL, 50)
	_add_item("meat", "Thịt Sống", "Thịt chưa nấu, cần nấu chín", Item.ItemType.MATERIAL, 20)
	
	# Thức ăn
	_add_item("berries", "Quả Mọng", "Nhỏ nhưng bổ dưỡng", Item.ItemType.FOOD, 30, true, false, 0, 10, 5, 0)
	_add_item("cooked_meat", "Thịt Chín", "Ngon và no bụng", Item.ItemType.FOOD, 20, true, false, 0, 30, 0, 0)
	
	# Y tế
	_add_item("bandage", "Băng Gạc", "Chữa vết thương nhẹ", Item.ItemType.MEDICAL, 10, true, false, 0, 25, 0, 0)
	
	# Công cụ
	_add_item("wooden_pickaxe", "Cuốc Gỗ", "Để đào đá", Item.ItemType.TOOL, 1, false, true, 15, 0, 0, 0)
	_add_item("wooden_axe", "Rìu Gỗ", "Để chặt cây", Item.ItemType.TOOL, 1, false, true, 15, 0, 0, 0)
	
	# Vũ khí cận chiến
	_add_item("wooden_spear", "Giáo Gỗ", "Vũ khí cận chiến cơ bản", Item.ItemType.WEAPON, 1, false, true, 20, 0, 0, 0)
	_add_item("knife", "Dao Chiến Đấu", "Vũ khí cận chiến nhanh", Item.ItemType.WEAPON, 1, false, true, 15, 0, 0, 0)
	
	# Vũ khí tầm xa
	_add_item("pistol", "Súng Lục", "Súng ngắn 9mm. Đáng tin cậy.", Item.ItemType.WEAPON, 1, false, true, 15, 0, 0, 0)
	_add_item("rifle", "Súng Trường", "Súng tự động. Sát thương cao.", Item.ItemType.WEAPON, 1, false, true, 25, 0, 0, 0)
	_add_item("shotgun", "Súng Hoa Cải", "Hủy diệt tầm gần.", Item.ItemType.WEAPON, 1, false, true, 40, 0, 0, 0)
	
	# Đạn dược
	_add_item("ammo_pistol", "Đạn 9mm", "Đạn cho súng lục", Item.ItemType.MATERIAL, 50)
	_add_item("ammo_rifle", "Đạn Súng Trường", "Đạn cho súng trường", Item.ItemType.MATERIAL, 100)
	_add_item("ammo_shotgun", "Đạn Hoa Cải", "Đạn cho súng hoa cải", Item.ItemType.MATERIAL, 30)
	
	# Giáp
	_add_item("armor_vest", "Áo Giáp", "Giảm sát thương nhận vào", Item.ItemType.ARMOR, 1, false, true, 0, 0, 0, 0)
	
	# Vật phẩm xây dựng
	_add_item("wooden_wall", "Tường Gỗ", "Tường chắc chắn", Item.ItemType.MATERIAL, 20)
	_add_item("wooden_floor", "Sàn Gỗ", "Nền móng để xây dựng", Item.ItemType.MATERIAL, 20)
	_add_item("campfire", "Lửa Trại", "Để nấu ăn và sưởi ấm", Item.ItemType.MATERIAL, 5)
	_add_item("storage_box", "Hộp Lưu Trữ", "Cất giữ đồ vật", Item.ItemType.MATERIAL, 5)

func _add_item(id: String, name: String, desc: String, type: Item.ItemType, max_stack: int, 
		usable: bool = false, equip: bool = false, dmg: int = 0, hp: int = 0, hunger: int = 0, thirst: int = 0) -> void:
	var item = Item.new()
	item.id = id
	item.name = name
	item.description = desc
	item.item_type = type
	item.max_stack = max_stack
	item.is_usable = usable
	item.is_equippable = equip
	item.damage = dmg
	item.health_restore = hp
	item.hunger_restore = hunger
	item.thirst_restore = thirst
	items_db[id] = item

func get_item(item_id: String) -> Item:
	if items_db.has(item_id):
		return items_db[item_id].duplicate()
	return null

func spawn_dropped_item(item_id: String, quantity: int, pos: Vector2) -> void:
	var item = get_item(item_id)
	if item == null:
		return
	
	var dropped = _create_dropped_item(item, quantity)
	dropped.global_position = pos + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	
	var world = get_tree().current_scene
	var dropped_container = world.get_node_or_null("DroppedItems")
	if dropped_container:
		dropped_container.add_child(dropped)
	else:
		world.add_child(dropped)

func _create_dropped_item(item: Item, quantity: int) -> Area2D:
	var dropped = Area2D.new()
	dropped.collision_layer = 4
	dropped.collision_mask = 1
	dropped.set_meta("item", item)
	dropped.set_meta("quantity", quantity)
	
	var sprite = Sprite2D.new()
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(_get_item_color(item.item_type))
	sprite.texture = ImageTexture.create_from_image(img)
	dropped.add_child(sprite)
	
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 10
	collision.shape = shape
	dropped.add_child(collision)
	
	dropped.body_entered.connect(_on_dropped_item_body_entered.bind(dropped))
	
	return dropped

func _get_item_color(type: Item.ItemType) -> Color:
	match type:
		Item.ItemType.WEAPON: return Color.SILVER
		Item.ItemType.TOOL: return Color.BURLYWOOD
		Item.ItemType.FOOD: return Color.ORANGE
		Item.ItemType.DRINK: return Color.DODGER_BLUE
		Item.ItemType.MATERIAL: return Color.SADDLE_BROWN
		Item.ItemType.ARMOR: return Color.STEEL_BLUE
		Item.ItemType.MEDICAL: return Color.LIGHT_GREEN
	return Color.WHITE

func _on_dropped_item_body_entered(body: Node2D, dropped: Area2D) -> void:
	if body is Player and player_inventory:
		var item = dropped.get_meta("item") as Item
		var qty = dropped.get_meta("quantity") as int
		var leftover = player_inventory.add_item(item, qty)
		if leftover < qty:
			if leftover > 0:
				dropped.set_meta("quantity", leftover)
			else:
				dropped.queue_free()

func setup_player(p: Player, inv: Inventory) -> void:
	player = p
	player_inventory = inv

# Spawn weapon drop với animation
func spawn_weapon_drop(weapon: WeaponData, pos: Vector2) -> void:
	var dropped = _create_weapon_drop(weapon)
	dropped.global_position = pos
	
	var world = get_tree().current_scene
	var dropped_container = world.get_node_or_null("DroppedItems")
	if dropped_container:
		dropped_container.add_child(dropped)
	else:
		world.add_child(dropped)
	
	# Animation bay lên rồi rơi xuống
	var tween = dropped.create_tween()
	tween.tween_property(dropped, "global_position", pos + Vector2(0, -40), 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_property(dropped, "global_position", pos + Vector2(0, 10), 0.2).set_ease(Tween.EASE_IN)

func _create_weapon_drop(weapon: WeaponData) -> Area2D:
	var dropped = Area2D.new()
	dropped.collision_layer = 4
	dropped.collision_mask = 1
	dropped.monitoring = true
	dropped.monitorable = true
	dropped.set_meta("weapon_data", weapon)
	
	# Tạo sprite súng
	var weapon_sprite = WeaponSprite.new()
	weapon_sprite.setup(weapon)
	dropped.add_child(weapon_sprite)
	
	# Label tên súng
	var label = Label.new()
	label.text = weapon.name_vi
	label.position = Vector2(-30, -35)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	label.visible = false
	label.name = "NameLabel"
	dropped.add_child(label)
	
	# Collision
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 20
	collision.shape = shape
	dropped.add_child(collision)
	
	# Hiệu ứng glow
	var glow = Sprite2D.new()
	var glow_img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for x in range(32):
		for y in range(32):
			var dist = Vector2(x - 16, y - 16).length()
			if dist < 16:
				glow_img.set_pixel(x, y, Color(1, 0.8, 0.3, (1.0 - dist / 16.0) * 0.3))
	glow.texture = ImageTexture.create_from_image(glow_img)
	glow.scale = Vector2(2, 2)
	glow.name = "Glow"
	dropped.add_child(glow)
	glow.z_index = -1
	
	dropped.body_entered.connect(_on_weapon_drop_body_entered.bind(dropped))
	dropped.body_exited.connect(_on_weapon_drop_body_exited.bind(dropped))
	
	return dropped

func _on_weapon_drop_body_entered(body: Node2D, dropped: Area2D) -> void:
	if body is Player:
		var label = dropped.get_node_or_null("NameLabel")
		if label:
			label.visible = true
			label.text = "[E] " + dropped.get_meta("weapon_data").name_vi

func _on_weapon_drop_body_exited(body: Node2D, dropped: Area2D) -> void:
	if body is Player:
		var label = dropped.get_node_or_null("NameLabel")
		if label:
			label.visible = false

func pickup_weapon(dropped: Area2D) -> void:
	var weapon = dropped.get_meta("weapon_data") as WeaponData
	if weapon and player:
		player.equip_weapon_data(weapon)
		weapon_picked_up.emit(weapon)
		dropped.queue_free()
