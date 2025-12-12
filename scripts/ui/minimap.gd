extends CanvasLayer
class_name Minimap

@onready var panel: Panel = $Panel
@onready var map_texture: TextureRect = $Panel/MapTexture
@onready var player_marker: ColorRect = $Panel/MapTexture/PlayerMarker
@onready var close_btn: Button = $Panel/CloseBtn
@onready var zone_label: Label = $Panel/ZoneLabel
@onready var coords_label: Label = $Panel/CoordsLabel

var player: Player
var game_world: GameWorld
var is_open: bool = false
var map_image: Image
var map_size: Vector2i = Vector2i(200, 200)
var minimap_size: Vector2i = Vector2i(400, 400)

# Zone colors for minimap
var zone_colors: Dictionary = {
	0: Color(0.4, 0.7, 0.3),   # Safe - Green
	1: Color(0.2, 0.5, 0.15),  # Forest - Dark Green
	2: Color(0.9, 0.8, 0.5),   # Desert - Sand
	3: Color(0.5, 0.5, 0.5),   # City - Gray
	4: Color(0.3, 0.3, 0.25),  # Military - Dark
	5: Color(0.9, 0.95, 1.0),  # Snow - White
	-1: Color(0.2, 0.4, 0.7)   # Water - Blue
}

func _ready() -> void:
	panel.visible = false
	close_btn.pressed.connect(_close)
	_generate_map_image()

func _generate_map_image() -> void:
	map_image = Image.create(minimap_size.x, minimap_size.y, false, Image.FORMAT_RGBA8)
	map_image.fill(Color(0.1, 0.1, 0.1))
	
	# Generate minimap based on zones
	var noise = FastNoiseLite.new()
	noise.seed = 12345  # Fixed seed for consistent map
	noise.frequency = 0.008
	
	for x in range(minimap_size.x):
		for y in range(minimap_size.y):
			# Convert to world coordinates
			var world_x = (x - minimap_size.x / 2) * (map_size.x / float(minimap_size.x))
			var world_y = (y - minimap_size.y / 2) * (map_size.y / float(minimap_size.y))
			
			var dist = Vector2(world_x, world_y).length()
			var noise_val = noise.get_noise_2d(world_x, world_y)
			
			var zone: int
			if noise_val < -0.4:
				zone = -1  # Water
			elif dist < 25:
				zone = 0  # Safe
			elif dist < 45:
				zone = 1 if noise_val < 0.2 else 0  # Forest/Safe
			elif dist < 65:
				if noise_val > 0.3:
					zone = 5  # Snow
				else:
					zone = 2  # Desert
			elif dist < 85:
				zone = 3  # City
			else:
				zone = 4  # Military
			
			var color = zone_colors.get(zone, Color.BLACK)
			# Add some variation
			var variation = randf() * 0.05
			color = Color(color.r + variation, color.g + variation, color.b + variation)
			map_image.set_pixel(x, y, color)
	
	# Draw zone borders/roads
	_draw_zone_markers()
	
	var tex = ImageTexture.create_from_image(map_image)
	map_texture.texture = tex

func _draw_zone_markers() -> void:
	# Draw center marker (spawn)
	var center = minimap_size / 2
	for dx in range(-3, 4):
		for dy in range(-3, 4):
			if abs(dx) + abs(dy) <= 3:
				map_image.set_pixel(center.x + dx, center.y + dy, Color.WHITE)

func setup(p: Player, world: GameWorld) -> void:
	player = p
	game_world = world

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("map"):
		toggle()

func toggle() -> void:
	is_open = !is_open
	panel.visible = is_open
	if is_open:
		_update_player_position()

func _close() -> void:
	is_open = false
	panel.visible = false

func _process(_delta: float) -> void:
	if is_open and player:
		_update_player_position()

func _update_player_position() -> void:
	if player == null:
		return
	
	# Convert player world position to minimap position
	var tile_size = 32
	var player_tile_x = player.global_position.x / tile_size
	var player_tile_y = player.global_position.y / tile_size
	
	# Scale to minimap
	var map_x = (player_tile_x / map_size.x + 0.5) * minimap_size.x
	var map_y = (player_tile_y / map_size.y + 0.5) * minimap_size.y
	
	# Clamp to minimap bounds
	map_x = clamp(map_x, 5, minimap_size.x - 5)
	map_y = clamp(map_y, 5, minimap_size.y - 5)
	
	player_marker.position = Vector2(map_x - 4, map_y - 4)
	
	# Update zone label
	var zone_name = _get_zone_name(player_tile_x, player_tile_y)
	zone_label.text = zone_name
	
	# Update coordinates
	coords_label.text = "X: %d  Y: %d" % [int(player_tile_x), int(player_tile_y)]

func _get_zone_name(x: float, y: float) -> String:
	var dist = Vector2(x, y).length()
	
	if dist < 25:
		return "Safe Zone"
	elif dist < 45:
		return "Forest"
	elif dist < 65:
		return "Desert / Snow"
	elif dist < 85:
		return "City Ruins"
	else:
		return "Military Base"
