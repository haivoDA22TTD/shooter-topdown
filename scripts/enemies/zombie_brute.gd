extends ZombieBase
class_name ZombieBrute

func _ready() -> void:
	zombie_name = "Brute"
	max_health = 120
	damage = 25
	move_speed = 35.0
	chase_speed = 60.0
	attack_range = 40.0
	attack_cooldown = 2.0
	body_color = Color(0.3, 0.35, 0.25)
	skin_color = Color(0.4, 0.45, 0.35)
	super._ready()

func _setup_drops() -> void:
	drops = [
		{"item_id": "cloth", "min": 2, "max": 4, "chance": 0.8},
		{"item_id": "meat", "min": 2, "max": 4, "chance": 0.9},
		{"item_id": "iron_ore", "min": 0, "max": 1, "chance": 0.3}
	]

func _create_zombie_frame(direction: String, anim_type: String, frame_idx: int) -> Image:
	# Bigger zombie
	var img = Image.create(32, 40, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	var y_offset = 0
	if anim_type == "walk":
		y_offset = [0, -1, 0, -1][frame_idx]
	
	var head_x = 16
	var head_y = 8 + y_offset
	var clothes_color = body_color.darkened(0.2)
	
	# Bigger head
	_draw_ellipse(img, head_x, head_y, 7, 8, skin_color)
	
	# Eyes
	if direction == "down":
		img.set_pixel(13, 7 + y_offset, Color.RED)
		img.set_pixel(19, 7 + y_offset, Color.RED)
	
	# Massive body
	_draw_rect_img(img, 6, 16 + y_offset, 20, 14, clothes_color)
	
	# Big arms
	var arm_offset = 0
	if anim_type == "attack":
		arm_offset = [-4, -6, -4][frame_idx]
	_draw_rect_img(img, 2, 17 + y_offset + arm_offset, 5, 12, skin_color)
	_draw_rect_img(img, 25, 17 + y_offset - arm_offset, 5, 12, skin_color)
	
	# Legs
	_draw_rect_img(img, 8, 30 + y_offset, 6, 10, Color(0.25, 0.25, 0.25))
	_draw_rect_img(img, 18, 30 + y_offset, 6, 10, Color(0.25, 0.25, 0.25))
	
	return img
