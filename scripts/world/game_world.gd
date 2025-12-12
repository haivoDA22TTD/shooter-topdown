extends Node2D
class_name GameWorld

@onready var player: Player = $Player
@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var resources_node: Node2D = $Resources
@onready var enemies_node: Node2D = $Enemies
@onready var dropped_items_node: Node2D = $DroppedItems
@onready var buildings_node: Node2D = $Buildings

# Larger map with zones
var map_size: Vector2i = Vector2i(200, 200)
var tile_size: int = 32

# Zone definitions - Added SNOW and DESERT
enum Zone { SAFE, FOREST, DESERT, CITY, MILITARY, SNOW }

var zone_colors: Dictionary = {
	Zone.SAFE: [Color(0.3, 0.6, 0.2), Color(0.35, 0.55, 0.25)],
	Zone.FOREST: [Color(0.15, 0.4, 0.1), Color(0.2, 0.35, 0.15)],
	Zone.DESERT: [Color(0.85, 0.75, 0.45), Color(0.8, 0.7, 0.4)],
	Zone.CITY: [Color(0.4, 0.4, 0.4), Color(0.35, 0.35, 0.35)],
	Zone.MILITARY: [Color(0.3, 0.3, 0.25), Color(0.25, 0.25, 0.2)],
	Zone.SNOW: [Color(0.9, 0.92, 0.95), Color(0.85, 0.88, 0.92)]
}

var zombie_scene: PackedScene
var boss_scene: PackedScene
var zone_noise: FastNoiseLite

func _ready() -> void:
	_load_zombie_scene()
	_setup_noise()
	_generate_map()
	_spawn_resources()
	_spawn_enemies()
	_spawn_loot_boxes()
	_spawn_boss()

func _load_zombie_scene() -> void:
	if ResourceLoader.exists("res://scenes/enemies/zombie_base.tscn"):
		zombie_scene = load("res://scenes/enemies/zombie_base.tscn")
	if ResourceLoader.exists("res://scenes/enemies/zombie_boss.tscn"):
		boss_scene = load("res://scenes/enemies/zombie_boss.tscn")

func _setup_noise() -> void:
	zone_noise = FastNoiseLite.new()
	zone_noise.seed = 12345
	zone_noise.frequency = 0.008

func _generate_map() -> void:
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(tile_size, tile_size)
	
	var source = TileSetAtlasSource.new()
	# 6 zones * 2 variants = 12 tiles + 1 water = 13 tiles * 32 = 416 pixels
	var img = Image.create(416, 64, false, Image.FORMAT_RGBA8)
	
	# Generate tiles for each zone (2 variants each)
	var tile_idx = 0
	for zone in Zone.values():
		var colors = zone_colors[zone]
		for variant in range(2):
			var base_x = tile_idx * 32
			for x in range(32):
				for y in range(32):
					if base_x + x < img.get_width():
						var variation = randf() * 0.05
						var col = colors[variant]
						col = Color(col.r + variation, col.g + variation, col.b + variation)
						img.set_pixel(base_x + x, y, col)
			tile_idx += 1
	
	# Water tile
	for x in range(0, 32):
		for y in range(32, 64):
			var variation = randf() * 0.1
			img.set_pixel(x, y, Color(0.1, 0.3 + variation, 0.6 + variation))
	
	var tex = ImageTexture.create_from_image(img)
	source.texture = tex
	source.texture_region_size = Vector2i(32, 32)
	
	# Tạo tiles cho tất cả zones (12 tiles) + water
	for i in range(12):
		source.create_tile(Vector2i(i, 0))
	source.create_tile(Vector2i(0, 1))  # Water tile
	
	tileset.add_source(source, 0)
	tilemap.tile_set = tileset
	
	var terrain_noise = FastNoiseLite.new()
	terrain_noise.seed = randi()
	terrain_noise.frequency = 0.02
	
	var half_x: int = map_size.x / 2
	var half_y: int = map_size.y / 2
	
	for x in range(-half_x, half_x):
		for y in range(-half_y, half_y):
			var value = terrain_noise.get_noise_2d(x, y)
			var zone_value = zone_noise.get_noise_2d(x, y)
			var dist_from_center = Vector2(x, y).length()
			
			var tile_coords: Vector2i
			
			if value < -0.5:
				tile_coords = Vector2i(0, 1)
			else:
				var zone = _calculate_zone(dist_from_center, zone_value, x, y)
				tile_coords = Vector2i(zone, 0)
			
			tilemap.set_cell(Vector2i(x, y), 0, tile_coords)

func _calculate_zone(dist: float, noise_val: float, x: int, y: int) -> int:
	# Directional zones - Snow in north, Desert in south
	var angle = atan2(y, x)
	var is_north = y < -20
	var is_south = y > 20
	
	if dist < 25:
		return Zone.SAFE
	elif dist < 50:
		return Zone.FOREST if noise_val < 0.2 else Zone.SAFE
	elif dist < 75:
		if is_north and noise_val > 0:
			return Zone.SNOW
		elif is_south and noise_val > -0.2:
			return Zone.DESERT
		else:
			return Zone.FOREST
	elif dist < 90:
		if is_north:
			return Zone.SNOW if noise_val > 0.3 else Zone.CITY
		elif is_south:
			return Zone.DESERT if noise_val > 0.3 else Zone.CITY
		else:
			return Zone.CITY
	else:
		return Zone.MILITARY

func get_zone_at(pos: Vector2) -> Zone:
	var tile_x = int(pos.x / tile_size)
	var tile_y = int(pos.y / tile_size)
	var dist = Vector2(tile_x, tile_y).length()
	var noise_val = zone_noise.get_noise_2d(tile_x, tile_y)
	return _calculate_zone(dist, noise_val, tile_x, tile_y)

func get_zone_name(zone: Zone) -> String:
	match zone:
		Zone.SAFE: return "Vùng An Toàn"
		Zone.FOREST: return "Rừng Rậm"
		Zone.DESERT: return "Sa Mạc"
		Zone.CITY: return "Thành Phố Hoang"
		Zone.MILITARY: return "Căn Cứ Quân Sự"
		Zone.SNOW: return "Vùng Băng Giá"
	return "Không Xác Định"

func _spawn_resources() -> void:
	var resource_scene: PackedScene = null
	if ResourceLoader.exists("res://scenes/resources/resource_node.tscn"):
		resource_scene = load("res://scenes/resources/resource_node.tscn")
	
	if resource_scene == null:
		return
	
	var spawn_range: float = float(map_size.x * tile_size) / 2.5
	
	for i in range(200):
		var pos = Vector2(randf_range(-spawn_range, spawn_range), randf_range(-spawn_range, spawn_range))
		var resource = resource_scene.instantiate()
		resource.position = pos
		
		var zone = get_zone_at(pos)
		match zone:
			Zone.SAFE, Zone.FOREST:
				resource.resource_type = 0 if randf() > 0.3 else 1
			Zone.DESERT:
				resource.resource_type = 1
			Zone.SNOW:
				resource.resource_type = 1 if randf() > 0.5 else 0
			Zone.CITY, Zone.MILITARY:
				resource.resource_type = 2 if randf() > 0.4 else 1
		
		resources_node.add_child(resource)

func _spawn_enemies() -> void:
	if zombie_scene == null:
		return
	
	var spawn_range: float = float(map_size.x * tile_size) / 2.5
	
	for i in range(100):
		var pos = Vector2(randf_range(-spawn_range, spawn_range), randf_range(-spawn_range, spawn_range))
		var zone = get_zone_at(pos)
		
		if zone == Zone.SAFE:
			continue
		
		var zombie = zombie_scene.instantiate()
		zombie.position = pos
		_configure_zombie_for_zone(zombie, zone)
		enemies_node.add_child(zombie)

func _configure_zombie_for_zone(zombie: ZombieBase, zone: Zone) -> void:
	match zone:
		Zone.FOREST:
			zombie.zombie_name = "Xác Sống Rừng"
			zombie.max_health = 40
			zombie.damage = 8
			zombie.move_speed = 50.0
			zombie.chase_speed = 85.0
			zombie.body_color = Color(0.3, 0.4, 0.25)
			zombie.skin_color = Color(0.4, 0.5, 0.35)
		Zone.DESERT:
			zombie.zombie_name = "Xác Sống Sa Mạc"
			zombie.max_health = 35
			zombie.damage = 12
			zombie.move_speed = 70.0
			zombie.chase_speed = 130.0
			zombie.body_color = Color(0.6, 0.5, 0.35)
			zombie.skin_color = Color(0.7, 0.6, 0.45)
		Zone.SNOW:
			zombie.zombie_name = "Xác Sống Băng Giá"
			zombie.max_health = 60
			zombie.damage = 10
			zombie.move_speed = 40.0
			zombie.chase_speed = 70.0
			zombie.body_color = Color(0.6, 0.65, 0.7)
			zombie.skin_color = Color(0.7, 0.75, 0.8)
		Zone.CITY:
			zombie.zombie_name = "Xác Sống Thành Phố"
			zombie.max_health = 55
			zombie.damage = 15
			zombie.move_speed = 55.0
			zombie.chase_speed = 95.0
			zombie.body_color = Color(0.35, 0.35, 0.35)
			zombie.skin_color = Color(0.45, 0.45, 0.4)
		Zone.MILITARY:
			zombie.zombie_name = "Xác Sống Quân Sự"
			zombie.max_health = 100
			zombie.damage = 25
			zombie.move_speed = 40.0
			zombie.chase_speed = 70.0
			zombie.body_color = Color(0.25, 0.3, 0.2)
			zombie.skin_color = Color(0.35, 0.4, 0.3)


func _spawn_loot_boxes() -> void:
	var loot_box_scene: PackedScene = null
	if ResourceLoader.exists("res://scenes/items/loot_box.tscn"):
		loot_box_scene = load("res://scenes/items/loot_box.tscn")
	
	var weapon_box_scene: PackedScene = null
	if ResourceLoader.exists("res://scenes/items/weapon_box.tscn"):
		weapon_box_scene = load("res://scenes/items/weapon_box.tscn")
	
	var spawn_range: float = float(map_size.x * tile_size) / 2.5
	var spawned_count = 0
	var weapon_box_count = 0
	
	# Spawn loot boxes based on zones
	for i in range(50):
		var pos = Vector2(randf_range(-spawn_range, spawn_range), randf_range(-spawn_range, spawn_range))
		var zone = get_zone_at(pos)
		
		# Skip safe zone for loot
		if zone == Zone.SAFE:
			continue
		
		if loot_box_scene:
			var box = loot_box_scene.instantiate()
			box.position = pos
			
			# Set box type based on zone
			match zone:
				Zone.FOREST:
					box.box_type = 0  # COMMON
				Zone.DESERT, Zone.SNOW:
					box.box_type = 0 if randf() > 0.3 else 1  # COMMON or RARE
				Zone.CITY:
					box.box_type = 1  # RARE
				Zone.MILITARY:
					box.box_type = 2  # MILITARY
			
			dropped_items_node.add_child(box)
			spawned_count += 1
	
	# Spawn weapon boxes ngẫu nhiên trên bản đồ
	if weapon_box_scene:
		print("Weapon box scene loaded successfully!")
		
		# Spawn một số hộp súng gần vị trí bắt đầu để dễ test
		for i in range(5):
			var weapon_box = weapon_box_scene.instantiate()
			weapon_box.position = Vector2(randf_range(100, 300), randf_range(100, 300))
			weapon_box.rarity = i % 3  # Xoay vòng các loại rarity
			dropped_items_node.add_child(weapon_box)
			weapon_box_count += 1
		
		# Spawn nhiều hộp súng trên toàn bản đồ
		for i in range(80):
			var pos = Vector2(randf_range(-spawn_range, spawn_range), randf_range(-spawn_range, spawn_range))
			var zone = get_zone_at(pos)
			
			# Cho phép spawn ở safe zone với tỉ lệ thấp
			if zone == Zone.SAFE and randf() > 0.3:
				continue
			
			var weapon_box = weapon_box_scene.instantiate()
			weapon_box.position = pos
			
			# Set rarity based on zone
			match zone:
				Zone.SAFE:
					weapon_box.rarity = 0  # COMMON
				Zone.FOREST:
					weapon_box.rarity = 0  # COMMON
				Zone.DESERT, Zone.SNOW:
					weapon_box.rarity = 0 if randf() > 0.4 else 1  # COMMON or RARE
				Zone.CITY:
					weapon_box.rarity = 1  # RARE
				Zone.MILITARY:
					weapon_box.rarity = 1 if randf() > 0.5 else 2  # RARE or MILITARY
			
			dropped_items_node.add_child(weapon_box)
			weapon_box_count += 1
	else:
		print("ERROR: Weapon box scene NOT found at res://scenes/items/weapon_box.tscn")
	
	print("Đã spawn ", spawned_count, " hộp đồ và ", weapon_box_count, " hộp súng")

func _spawn_boss() -> void:
	if boss_scene == null:
		print("WARNING: Boss scene not found!")
		return
	
	# Spawn boss ở vùng tuyết (phía bắc bản đồ)
	var boss = boss_scene.instantiate()
	boss.position = Vector2(0, -1800)  # Vùng tuyết phía bắc
	boss.boss_name = "Chúa Tể Băng Giá"
	enemies_node.add_child(boss)
	
	print("Đã spawn Boss: Chúa Tể Băng Giá tại vùng tuyết!")
