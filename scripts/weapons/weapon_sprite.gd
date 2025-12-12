extends Node2D
class_name WeaponSprite

var weapon_data: WeaponData
var sprite: Sprite2D
var muzzle_flash: Sprite2D
var is_flashing: bool = false

func _ready() -> void:
	_create_muzzle_flash()

func setup(data: WeaponData) -> void:
	weapon_data = data
	_create_weapon_sprite()

func _create_weapon_sprite() -> void:
	if sprite:
		sprite.queue_free()
	
	sprite = Sprite2D.new()
	sprite.name = "GunSprite"
	
	var img: Image
	match weapon_data.weapon_type:
		WeaponData.WeaponType.PISTOL:
			img = _draw_pistol()
		WeaponData.WeaponType.RIFLE:
			img = _draw_rifle()
		WeaponData.WeaponType.SHOTGUN:
			img = _draw_shotgun()
		WeaponData.WeaponType.SMG:
			img = _draw_smg()
		WeaponData.WeaponType.SNIPER:
			img = _draw_sniper()
	
	sprite.texture = ImageTexture.create_from_image(img)
	sprite.scale = Vector2(2, 2)
	add_child(sprite)

func _draw_pistol() -> Image:
	var img = Image.create(20, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	# Thân súng
	_draw_rect(img, 0, 4, 14, 6, weapon_data.body_color)
	# Nòng súng
	_draw_rect(img, 14, 5, 6, 4, weapon_data.accent_color)
	# Tay cầm
	_draw_rect(img, 2, 10, 6, 6, weapon_data.handle_color)
	# Cò súng
	_draw_rect(img, 8, 10, 2, 3, weapon_data.body_color)
	# Highlight
	_draw_rect(img, 1, 5, 12, 1, Color(1, 1, 1, 0.2))
	
	return img

func _draw_rifle() -> Image:
	var img = Image.create(40, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	# Báng súng
	_draw_rect(img, 0, 5, 10, 7, weapon_data.handle_color)
	# Thân súng
	_draw_rect(img, 8, 4, 24, 6, weapon_data.body_color)
	# Nòng súng
	_draw_rect(img, 32, 5, 8, 4, weapon_data.accent_color)
	# Băng đạn
	_draw_rect(img, 16, 10, 6, 6, weapon_data.body_color)
	# Tay cầm trước
	_draw_rect(img, 26, 10, 4, 4, weapon_data.handle_color)
	# Ống ngắm nhỏ
	_draw_rect(img, 14, 2, 8, 2, weapon_data.accent_color)
	# Highlight
	_draw_rect(img, 9, 5, 22, 1, Color(1, 1, 1, 0.15))
	
	return img

func _draw_shotgun() -> Image:
	var img = Image.create(36, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	# Báng gỗ
	_draw_rect(img, 0, 4, 12, 8, weapon_data.handle_color)
	# Thân súng
	_draw_rect(img, 10, 4, 18, 6, weapon_data.body_color)
	# Nòng súng đôi
	_draw_rect(img, 28, 4, 8, 3, weapon_data.accent_color)
	_draw_rect(img, 28, 7, 8, 3, weapon_data.accent_color)
	# Cò súng
	_draw_rect(img, 14, 10, 3, 4, weapon_data.body_color)
	# Tay cầm pump
	_draw_rect(img, 20, 10, 6, 3, weapon_data.handle_color)
	# Highlight gỗ
	_draw_rect(img, 1, 5, 10, 1, Color(1, 1, 1, 0.2))
	
	return img

func _draw_smg() -> Image:
	var img = Image.create(28, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	# Thân súng compact
	_draw_rect(img, 4, 4, 16, 6, weapon_data.body_color)
	# Nòng súng
	_draw_rect(img, 20, 5, 8, 4, weapon_data.accent_color)
	# Tay cầm
	_draw_rect(img, 6, 10, 5, 6, weapon_data.handle_color)
	# Băng đạn
	_draw_rect(img, 12, 10, 4, 6, weapon_data.body_color)
	# Báng gấp
	_draw_rect(img, 0, 5, 4, 4, weapon_data.accent_color)
	# Highlight
	_draw_rect(img, 5, 5, 14, 1, Color(1, 1, 1, 0.15))
	
	return img

func _draw_sniper() -> Image:
	var img = Image.create(48, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	# Báng súng
	_draw_rect(img, 0, 4, 12, 8, weapon_data.handle_color)
	# Thân súng dài
	_draw_rect(img, 10, 5, 28, 5, weapon_data.body_color)
	# Nòng súng dài
	_draw_rect(img, 38, 6, 10, 3, weapon_data.accent_color)
	# Ống ngắm lớn
	_draw_rect(img, 16, 0, 14, 4, weapon_data.accent_color)
	_draw_rect(img, 18, 1, 10, 2, Color(0.3, 0.5, 0.7))  # Kính ngắm
	# Băng đạn
	_draw_rect(img, 24, 10, 4, 4, weapon_data.body_color)
	# Chân chống
	_draw_rect(img, 32, 10, 2, 4, weapon_data.accent_color)
	# Highlight
	_draw_rect(img, 11, 6, 26, 1, Color(1, 1, 1, 0.12))
	
	return img

func _draw_rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for px in range(x, min(x + w, img.get_width())):
		for py in range(y, min(y + h, img.get_height())):
			if px >= 0 and py >= 0:
				img.set_pixel(px, py, color)

func _create_muzzle_flash() -> void:
	muzzle_flash = Sprite2D.new()
	muzzle_flash.name = "MuzzleFlash"
	muzzle_flash.visible = false
	
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for x in range(16):
		for y in range(16):
			var dist = Vector2(x - 8, y - 8).length()
			if dist < 8:
				var alpha = 1.0 - (dist / 8.0)
				var col = Color(1, 0.9, 0.3, alpha)
				if dist < 4:
					col = Color(1, 1, 0.8, alpha)
				img.set_pixel(x, y, col)
	
	muzzle_flash.texture = ImageTexture.create_from_image(img)
	muzzle_flash.scale = Vector2(1.5, 1.5)
	add_child(muzzle_flash)

func show_muzzle_flash(direction: String) -> void:
	if is_flashing:
		return
	
	is_flashing = true
	muzzle_flash.visible = true
	
	# Vị trí flash theo hướng
	match direction:
		"down": muzzle_flash.position = Vector2(0, 20)
		"up": muzzle_flash.position = Vector2(0, -20)
		"left": muzzle_flash.position = Vector2(-25, 0)
		"right": muzzle_flash.position = Vector2(25, 0)
	
	var tween = create_tween()
	tween.tween_property(muzzle_flash, "scale", Vector2(2.5, 2.5), 0.05)
	tween.tween_property(muzzle_flash, "scale", Vector2(0.5, 0.5), 0.08)
	tween.tween_callback(func():
		muzzle_flash.visible = false
		muzzle_flash.scale = Vector2(1.5, 1.5)
		is_flashing = false
	)

func update_direction(direction: String) -> void:
	if not sprite:
		return
	
	match direction:
		"down":
			sprite.rotation = PI / 2
			sprite.position = Vector2(10, 15)
			sprite.flip_v = false
		"up":
			sprite.rotation = -PI / 2
			sprite.position = Vector2(-10, -15)
			sprite.flip_v = false
		"left":
			sprite.rotation = PI
			sprite.position = Vector2(-20, 5)
			sprite.flip_v = true
		"right":
			sprite.rotation = 0
			sprite.position = Vector2(20, 5)
			sprite.flip_v = false

func play_recoil_animation() -> void:
	if not sprite:
		return
	
	var original_pos = sprite.position
	var tween = create_tween()
	tween.tween_property(sprite, "position", original_pos - Vector2(3, 0).rotated(sprite.rotation), 0.05)
	tween.tween_property(sprite, "position", original_pos, 0.1)
