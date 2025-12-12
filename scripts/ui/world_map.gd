extends CanvasLayer
class_name WorldMap

signal location_selected(location_id: String)

@onready var panel: Panel = $Panel
@onready var map_container: Control = $Panel/MapContainer
@onready var close_btn: Button = $Panel/CloseBtn
@onready var location_info: Panel = $Panel/LocationInfo
@onready var location_name: Label = $Panel/LocationInfo/VBox/LocationName
@onready var location_desc: Label = $Panel/LocationInfo/VBox/LocationDesc
@onready var travel_btn: Button = $Panel/LocationInfo/VBox/TravelBtn
@onready var energy_label: Label = $Panel/EnergyLabel

var is_open: bool = false
var selected_location: String = ""
var player_energy: int = 100
var max_energy: int = 100

# Location data
var locations: Dictionary = {
	"home": {
		"name": "Căn Cứ",
		"desc": "Nơi an toàn của bạn. Nghỉ ngơi và chế tạo.",
		"pos": Vector2(0.5, 0.6),
		"zone": "safe",
		"energy_cost": 0,
		"unlocked": true
	},
	"forest_1": {
		"name": "Rừng Thông",
		"desc": "Gỗ và quả mọng. Nguy hiểm thấp.",
		"pos": Vector2(0.35, 0.65),
		"zone": "forest",
		"energy_cost": 5,
		"unlocked": true
	},
	"forest_2": {
		"name": "Rừng Sồi",
		"desc": "Nhiều tài nguyên, nhiều zombie hơn.",
		"pos": Vector2(0.25, 0.55),
		"zone": "forest",
		"energy_cost": 8,
		"unlocked": true
	},
	"snow_1": {
		"name": "Hồ Băng",
		"desc": "Lạnh và nguy hiểm. Nguyên liệu hiếm.",
		"pos": Vector2(0.4, 0.25),
		"zone": "snow",
		"energy_cost": 12,
		"unlocked": true
	},
	"snow_2": {
		"name": "Hang Băng",
		"desc": "Cực lạnh. Đồ tốt.",
		"pos": Vector2(0.6, 0.15),
		"zone": "snow",
		"energy_cost": 18,
		"unlocked": false
	},
	"desert_1": {
		"name": "Đồi Cát",
		"desc": "Nóng và khô. Đá và sắt.",
		"pos": Vector2(0.7, 0.7),
		"zone": "desert",
		"energy_cost": 10,
		"unlocked": true
	},
	"desert_2": {
		"name": "Mỏ Hoang",
		"desc": "Giàu quặng. Cẩn thận sập hầm.",
		"pos": Vector2(0.85, 0.6),
		"zone": "desert",
		"energy_cost": 15,
		"unlocked": true
	},
	"city_1": {
		"name": "Ngoại Ô Hoang",
		"desc": "Lục lọi vật tư. Nguy hiểm trung bình.",
		"pos": Vector2(0.6, 0.45),
		"zone": "city",
		"energy_cost": 12,
		"unlocked": true
	},
	"military": {
		"name": "Hầm Quân Sự",
		"desc": "Vũ khí và giáp. Cực kỳ nguy hiểm!",
		"pos": Vector2(0.8, 0.3),
		"zone": "military",
		"energy_cost": 25,
		"unlocked": false
	}
}

var location_markers: Dictionary = {}
var player_marker: Control = null
var player_ref: Node2D = null

func _ready() -> void:
	panel.visible = false
	close_btn.pressed.connect(_close)
	travel_btn.pressed.connect(_on_travel_pressed)
	location_info.visible = false
	_create_map_background()
	_create_location_markers()
	_create_player_marker()
	_update_energy_display()

func setup_player(player: Node2D) -> void:
	player_ref = player

func _create_map_background() -> void:
	var map_rect = TextureRect.new()
	map_rect.name = "MapBackground"
	map_rect.anchors_preset = Control.PRESET_FULL_RECT
	map_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	
	# Create stylized world map image
	var img = Image.create(600, 400, false, Image.FORMAT_RGBA8)
	
	# Base - ocean/water
	img.fill(Color(0.2, 0.4, 0.5))
	
	# Draw landmass with zones
	_draw_zone_on_map(img, Vector2(300, 240), 280, 200, Color(0.4, 0.6, 0.3))  # Main land (green)
	
	# Snow region (top)
	_draw_zone_on_map(img, Vector2(300, 100), 200, 120, Color(0.85, 0.9, 0.95))
	_draw_zone_blend(img, Vector2(300, 160), 180, 40, Color(0.85, 0.9, 0.95), Color(0.4, 0.6, 0.3))
	
	# Desert region (right)
	_draw_zone_on_map(img, Vector2(480, 260), 140, 150, Color(0.85, 0.75, 0.5))
	_draw_zone_blend(img, Vector2(400, 260), 60, 100, Color(0.85, 0.75, 0.5), Color(0.4, 0.6, 0.3))
	
	# Forest (left) - darker green
	_draw_zone_on_map(img, Vector2(120, 240), 120, 140, Color(0.2, 0.45, 0.2))
	
	# City area (center-right)
	_draw_zone_on_map(img, Vector2(360, 180), 80, 60, Color(0.5, 0.5, 0.5))
	
	# Military (top-right)
	_draw_zone_on_map(img, Vector2(480, 120), 60, 50, Color(0.35, 0.35, 0.3))
	
	# Draw roads
	_draw_road(img, Vector2(300, 240), Vector2(200, 220))
	_draw_road(img, Vector2(300, 240), Vector2(400, 260))
	_draw_road(img, Vector2(300, 240), Vector2(300, 160))
	_draw_road(img, Vector2(300, 160), Vector2(360, 180))
	_draw_road(img, Vector2(360, 180), Vector2(480, 120))
	_draw_road(img, Vector2(400, 260), Vector2(500, 240))
	
	# Add some texture/detail
	_add_map_details(img)
	
	map_rect.texture = ImageTexture.create_from_image(img)
	map_container.add_child(map_rect)
	map_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _draw_zone_on_map(img: Image, center: Vector2, width: float, height: float, color: Color) -> void:
	for x in range(int(center.x - width/2), int(center.x + width/2)):
		for y in range(int(center.y - height/2), int(center.y + height/2)):
			if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
				var dx = (x - center.x) / (width/2)
				var dy = (y - center.y) / (height/2)
				var dist = dx*dx + dy*dy
				if dist < 1.0:
					var edge_fade = 1.0 - pow(dist, 0.5)
					var variation = randf() * 0.03
					var c = Color(color.r + variation, color.g + variation, color.b + variation, edge_fade)
					var existing = img.get_pixel(x, y)
					img.set_pixel(x, y, existing.blend(c))

func _draw_zone_blend(img: Image, center: Vector2, width: float, height: float, from_color: Color, to_color: Color) -> void:
	for x in range(int(center.x - width/2), int(center.x + width/2)):
		for y in range(int(center.y - height/2), int(center.y + height/2)):
			if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
				var t = float(y - (center.y - height/2)) / height
				var c = from_color.lerp(to_color, t)
				c.a = 0.5
				var existing = img.get_pixel(x, y)
				img.set_pixel(x, y, existing.blend(c))

func _draw_road(img: Image, from: Vector2, to: Vector2) -> void:
	var steps = int(from.distance_to(to))
	for i in range(steps):
		var t = float(i) / steps
		var pos = from.lerp(to, t)
		for dx in range(-3, 4):
			for dy in range(-3, 4):
				var px = int(pos.x) + dx
				var py = int(pos.y) + dy
				if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
					if abs(dx) + abs(dy) <= 3:
						img.set_pixel(px, py, Color(0.4, 0.35, 0.3))

func _add_map_details(img: Image) -> void:
	# Add trees in forest
	for i in range(30):
		var x = randi_range(60, 180)
		var y = randi_range(180, 300)
		_draw_tree_icon(img, x, y)
	
	# Add snow trees
	for i in range(20):
		var x = randi_range(200, 400)
		var y = randi_range(60, 140)
		_draw_pine_icon(img, x, y, Color(0.3, 0.5, 0.4))
	
	# Add cacti in desert
	for i in range(15):
		var x = randi_range(420, 560)
		var y = randi_range(200, 340)
		_draw_cactus_icon(img, x, y)

func _draw_tree_icon(img: Image, cx: int, cy: int) -> void:
	for dx in range(-4, 5):
		for dy in range(-6, 3):
			var px = cx + dx
			var py = cy + dy
			if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
				if dy >= 0:
					img.set_pixel(px, py, Color(0.4, 0.25, 0.15))
				elif abs(dx) + abs(dy + 3) < 5:
					img.set_pixel(px, py, Color(0.15, 0.4, 0.15))

func _draw_pine_icon(img: Image, cx: int, cy: int, color: Color) -> void:
	for dy in range(-8, 3):
		var width = 1 if dy >= 0 else int(4 - abs(dy + 4) * 0.5)
		for dx in range(-width, width + 1):
			var px = cx + dx
			var py = cy + dy
			if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
				if dy >= 0:
					img.set_pixel(px, py, Color(0.35, 0.25, 0.2))
				else:
					img.set_pixel(px, py, color)

func _draw_cactus_icon(img: Image, cx: int, cy: int) -> void:
	for dy in range(-6, 2):
		var px = cx
		var py = cy + dy
		if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
			img.set_pixel(px, py, Color(0.3, 0.5, 0.25))
			if dy == -3:
				img.set_pixel(px - 2, py, Color(0.3, 0.5, 0.25))
				img.set_pixel(px + 2, py, Color(0.3, 0.5, 0.25))

func _create_location_markers() -> void:
	for loc_id in locations:
		var loc = locations[loc_id]
		var marker = Button.new()
		marker.name = "Marker_" + loc_id
		marker.custom_minimum_size = Vector2(40, 50)
		marker.flat = true
		marker.anchors_preset = Control.PRESET_CENTER
		
		# Position based on map percentage
		marker.position = Vector2(
			loc["pos"].x * 600 - 20,
			loc["pos"].y * 400 - 40
		)
		
		# Create marker visual
		var marker_container = Control.new()
		marker_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Pin/marker icon
		var pin = ColorRect.new()
		pin.size = Vector2(24, 30)
		pin.position = Vector2(8, 5)
		pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Color based on zone
		var pin_color = _get_zone_color(loc["zone"])
		if not loc["unlocked"]:
			pin_color = Color(0.3, 0.3, 0.3)
		pin.color = pin_color
		marker_container.add_child(pin)
		
		# Star/skull icon on pin
		var icon = Label.new()
		icon.text = "💀" if loc["zone"] == "military" else "⭐"
		icon.position = Vector2(12, 8)
		icon.add_theme_font_size_override("font_size", 14)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker_container.add_child(icon)
		
		marker.add_child(marker_container)
		marker.pressed.connect(_on_location_clicked.bind(loc_id))
		
		map_container.add_child(marker)
		location_markers[loc_id] = marker

func _get_zone_color(zone: String) -> Color:
	match zone:
		"safe": return Color(0.2, 0.7, 0.3)
		"forest": return Color(0.15, 0.5, 0.2)
		"snow": return Color(0.7, 0.8, 0.9)
		"desert": return Color(0.85, 0.7, 0.4)
		"city": return Color(0.5, 0.5, 0.55)
		"military": return Color(0.6, 0.2, 0.2)
	return Color.WHITE

func _on_location_clicked(loc_id: String) -> void:
	selected_location = loc_id
	var loc = locations[loc_id]
	
	location_info.visible = true
	location_name.text = loc["name"]
	
	var desc = loc["desc"] + "\n\nNăng lượng: " + str(loc["energy_cost"])
	if not loc["unlocked"]:
		desc += "\n[CHƯA MỞ KHÓA]"
	location_desc.text = desc
	
	travel_btn.disabled = not loc["unlocked"] or player_energy < loc["energy_cost"]
	travel_btn.text = "DI CHUYỂN" if loc["unlocked"] else "KHÓA"

func _on_travel_pressed() -> void:
	if selected_location == "":
		return
	
	var loc = locations[selected_location]
	if loc["unlocked"] and player_energy >= loc["energy_cost"]:
		player_energy -= loc["energy_cost"]
		_update_energy_display()
		location_selected.emit(selected_location)
		_close()

func _update_energy_display() -> void:
	energy_label.text = "⚡ Năng lượng: " + str(player_energy) + "/" + str(max_energy)

# Input handled by main.gd to avoid conflicts

func toggle() -> void:
	is_open = !is_open
	panel.visible = is_open
	if is_open:
		location_info.visible = false
		_update_player_marker()

func _close() -> void:
	is_open = false
	panel.visible = false

func set_energy(current: int, max_val: int) -> void:
	player_energy = current
	max_energy = max_val
	_update_energy_display()

func unlock_location(loc_id: String) -> void:
	if locations.has(loc_id):
		locations[loc_id]["unlocked"] = true
		# Update marker color
		if location_markers.has(loc_id):
			var marker = location_markers[loc_id]
			var pin = marker.get_child(0).get_child(0) as ColorRect
			pin.color = _get_zone_color(locations[loc_id]["zone"])


func _create_player_marker() -> void:
	player_marker = Control.new()
	player_marker.name = "PlayerMarker"
	player_marker.custom_minimum_size = Vector2(20, 20)
	player_marker.z_index = 100
	
	# Vòng tròn nhấp nháy
	var outer_circle = ColorRect.new()
	outer_circle.name = "OuterCircle"
	outer_circle.size = Vector2(24, 24)
	outer_circle.position = Vector2(-12, -12)
	outer_circle.color = Color(0.2, 0.8, 1.0, 0.5)
	outer_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_marker.add_child(outer_circle)
	
	# Điểm chính
	var inner_circle = ColorRect.new()
	inner_circle.name = "InnerCircle"
	inner_circle.size = Vector2(12, 12)
	inner_circle.position = Vector2(-6, -6)
	inner_circle.color = Color(0.3, 0.9, 1.0)
	inner_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_marker.add_child(inner_circle)
	
	# Label "BẠN"
	var label = Label.new()
	label.text = "BẠN"
	label.position = Vector2(-15, -28)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_marker.add_child(label)
	
	map_container.add_child(player_marker)

func _update_player_marker() -> void:
	if player_marker == null or player_ref == null:
		return
	
	# Chuyển đổi vị trí world sang vị trí map
	# Map size: 600x400, World range: khoảng -3200 đến 3200
	var world_range = 3200.0
	var map_width = 600.0
	var map_height = 400.0
	
	var player_pos = player_ref.global_position
	var map_x = (player_pos.x / world_range + 1.0) * 0.5 * map_width
	var map_y = (player_pos.y / world_range + 1.0) * 0.5 * map_height
	
	# Giới hạn trong phạm vi map
	map_x = clamp(map_x, 10, map_width - 10)
	map_y = clamp(map_y, 10, map_height - 10)
	
	player_marker.position = Vector2(map_x, map_y)

func _process(_delta: float) -> void:
	if is_open:
		_update_player_marker()
		_animate_player_marker()

var _marker_pulse: float = 0.0

func _animate_player_marker() -> void:
	if player_marker == null:
		return
	_marker_pulse += 0.1
	var scale_factor = 1.0 + sin(_marker_pulse) * 0.2
	var outer = player_marker.get_node_or_null("OuterCircle")
	if outer:
		outer.modulate.a = 0.3 + sin(_marker_pulse) * 0.3
