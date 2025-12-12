extends Area2D
class_name WeaponBox

enum BoxRarity { COMMON, RARE, MILITARY }

@export var rarity: BoxRarity = BoxRarity.COMMON

var is_opened: bool = false
var sprite: Sprite2D
var glow_sprite: Sprite2D
var interaction_label: Label
var float_offset: float = 0.0

# Màu theo độ hiếm
var rarity_colors: Dictionary = {
	BoxRarity.COMMON: {
		"box": Color(0.5, 0.45, 0.35),
		"trim": Color(0.6, 0.55, 0.4),
		"glow": Color(0.8, 0.7, 0.4, 0.3)
	},
	BoxRarity.RARE: {
		"box": Color(0.3, 0.4, 0.6),
		"trim": Color(0.4, 0.55, 0.8),
		"glow": Color(0.4, 0.6, 1.0, 0.4)
	},
	BoxRarity.MILITARY: {
		"box": Color(0.25, 0.35, 0.2),
		"trim": Color(0.4, 0.5, 0.3),
		"glow": Color(0.3, 0.8, 0.3, 0.5)
	}
}

func _ready() -> void:
	collision_layer = 4  # Layer 3 (Interactable)
	collision_mask = 1   # Mask 1 (Player)
	monitoring = true
	monitorable = true
	_create_glow()
	_create_sprite()
	_create_label()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if not is_opened:
		# Hiệu ứng lơ lửng
		float_offset += delta * 2.0
		if sprite:
			sprite.position.y = sin(float_offset) * 3.0
		if glow_sprite:
			glow_sprite.modulate.a = 0.3 + sin(float_offset * 1.5) * 0.15

func _create_glow() -> void:
	glow_sprite = Sprite2D.new()
	var colors = rarity_colors[rarity]
	
	var img = Image.create(48, 40, false, Image.FORMAT_RGBA8)
	for x in range(48):
		for y in range(40):
			var dist = Vector2(x - 24, y - 20).length()
			if dist < 24:
				var alpha = (1.0 - dist / 24.0) * 0.5
				img.set_pixel(x, y, Color(colors["glow"].r, colors["glow"].g, colors["glow"].b, alpha))
	
	glow_sprite.texture = ImageTexture.create_from_image(img)
	glow_sprite.scale = Vector2(2, 2)
	add_child(glow_sprite)

func _create_sprite() -> void:
	sprite = Sprite2D.new()
	var colors = rarity_colors[rarity]
	
	var img = Image.create(28, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	# Thân hộp
	for x in range(2, 26):
		for y in range(6, 22):
			img.set_pixel(x, y, colors["box"])
	
	# Nắp hộp
	for x in range(1, 27):
		for y in range(3, 8):
			img.set_pixel(x, y, colors["trim"])
	
	# Khóa/móc
	for x in range(11, 17):
		for y in range(8, 13):
			img.set_pixel(x, y, Color(0.8, 0.7, 0.3))
	
	# Viền sáng
	for x in range(3, 25):
		img.set_pixel(x, 4, Color(1, 1, 1, 0.3))
	
	# Biểu tượng súng trên hộp
	_draw_gun_icon(img, 14, 15, colors["trim"])
	
	sprite.texture = ImageTexture.create_from_image(img)
	sprite.scale = Vector2(2.5, 2.5)
	add_child(sprite)

func _draw_gun_icon(img: Image, cx: int, cy: int, color: Color) -> void:
	# Vẽ icon súng nhỏ
	for x in range(cx - 5, cx + 5):
		for y in range(cy - 1, cy + 2):
			if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
				img.set_pixel(x, y, color)
	# Tay cầm
	for x in range(cx - 3, cx):
		for y in range(cy + 1, cy + 4):
			if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
				img.set_pixel(x, y, color)

func _create_label() -> void:
	interaction_label = Label.new()
	
	var rarity_text = ""
	match rarity:
		BoxRarity.COMMON: rarity_text = "Thường"
		BoxRarity.RARE: rarity_text = "Hiếm"
		BoxRarity.MILITARY: rarity_text = "Quân Sự"
	
	interaction_label.text = "[E] Mở Hộp " + rarity_text
	interaction_label.position = Vector2(-50, -60)
	interaction_label.visible = false
	interaction_label.add_theme_font_size_override("font_size", 12)
	interaction_label.add_theme_color_override("font_color", rarity_colors[rarity]["trim"])
	add_child(interaction_label)

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not is_opened:
		interaction_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		interaction_label.visible = false

func interact(player: Player) -> void:
	if is_opened:
		return
	
	is_opened = true
	interaction_label.visible = false
	_open_animation()
	_give_weapon(player)

func _open_animation() -> void:
	# Dừng hiệu ứng lơ lửng
	set_process(false)
	
	var tween = create_tween()
	# Nắp mở ra
	tween.tween_property(sprite, "scale", Vector2(3.0, 2.0), 0.15)
	tween.tween_property(sprite, "scale", Vector2(2.5, 2.5), 0.1)
	
	# Hiệu ứng ánh sáng
	tween.parallel().tween_property(glow_sprite, "scale", Vector2(4, 4), 0.2)
	tween.parallel().tween_property(glow_sprite, "modulate:a", 0.8, 0.1)
	tween.tween_property(glow_sprite, "modulate:a", 0.0, 0.3)
	
	# Làm mờ hộp
	tween.tween_property(sprite, "modulate", Color(0.4, 0.4, 0.4), 0.3)

func _give_weapon(player: Player) -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager == null:
		return
	
	# Lấy súng ngẫu nhiên theo độ hiếm
	var weapon = WeaponData.get_random_by_rarity(rarity)
	
	# Spawn súng rơi ra
	game_manager.spawn_weapon_drop(weapon, global_position + Vector2(0, -20))
	
	# Spawn thêm đạn
	var ammo_type = _get_ammo_type(weapon)
	var ammo_qty = _get_ammo_quantity()
	game_manager.spawn_dropped_item(ammo_type, ammo_qty, global_position + Vector2(randf_range(-15, 15), randf_range(10, 25)))

func _get_ammo_type(weapon: WeaponData) -> String:
	match weapon.weapon_type:
		WeaponData.WeaponType.PISTOL, WeaponData.WeaponType.SMG:
			return "ammo_pistol"
		WeaponData.WeaponType.RIFLE:
			return "ammo_rifle"
		WeaponData.WeaponType.SHOTGUN:
			return "ammo_shotgun"
		WeaponData.WeaponType.SNIPER:
			return "ammo_rifle"
	return "ammo_pistol"

func _get_ammo_quantity() -> int:
	match rarity:
		BoxRarity.COMMON: return randi_range(10, 20)
		BoxRarity.RARE: return randi_range(20, 40)
		BoxRarity.MILITARY: return randi_range(30, 60)
	return 15
