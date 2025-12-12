extends CharacterBody2D
class_name ZombieBoss

signal boss_defeated

@export var boss_name: String = "Chúa Tể Băng Giá"
@export var max_health: int = 500
@export var damage: int = 40
@export var move_speed: float = 60.0
@export var chase_speed: float = 100.0
@export var detection_range: float = 400.0
@export var attack_range: float = 80.0

var health: int = 500
var target: Node2D = null
var is_attacking: bool = false
var is_dead: bool = false
var current_state: String = "idle"

# Special attacks
var special_attack_cooldown: float = 0.0
var summon_cooldown: float = 0.0

# Visual
var sprite: AnimatedSprite2D
var health_bar: ProgressBar
var name_label: Label

# Colors
var body_color: Color = Color(0.4, 0.5, 0.7)
var skin_color: Color = Color(0.6, 0.7, 0.85)
var eye_color: Color = Color(0.8, 0.2, 0.2)

func _ready() -> void:
	health = max_health
	collision_layer = 2  # Enemy layer
	collision_mask = 1   # Player layer
	_create_sprite()
	_create_health_bar()
	_create_name_label()
	add_to_group("enemies")
	add_to_group("boss")

func _create_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	var frames = SpriteFrames.new()
	
	# Idle animation
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 3)
	frames.set_animation_loop("idle", true)
	for i in range(2):
		frames.add_frame("idle", ImageTexture.create_from_image(_create_boss_frame("idle", i)))
	
	# Walk animation
	frames.add_animation("walk")
	frames.set_animation_speed("walk", 6)
	frames.set_animation_loop("walk", true)
	for i in range(4):
		frames.add_frame("walk", ImageTexture.create_from_image(_create_boss_frame("walk", i)))
	
	# Attack animation
	frames.add_animation("attack")
	frames.set_animation_speed("attack", 8)
	frames.set_animation_loop("attack", false)
	for i in range(4):
		frames.add_frame("attack", ImageTexture.create_from_image(_create_boss_frame("attack", i)))
	
	if frames.has_animation("default"):
		frames.remove_animation("default")
	
	sprite.sprite_frames = frames
	sprite.play("idle")
	sprite.scale = Vector2(4, 4)  # Boss lớn hơn zombie thường
	add_child(sprite)
	
	sprite.animation_finished.connect(_on_animation_finished)

func _create_boss_frame(anim: String, frame_idx: int) -> Image:
	var img = Image.create(32, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	var y_off = 0
	if anim == "walk":
		y_off = [0, -2, 0, -2][frame_idx]
	
	# Thân to hơn
	_draw_rect(img, 8, 16 + y_off, 16, 20, body_color)
	
	# Đầu lớn
	_draw_ellipse(img, 16, 10 + y_off, 10, 10, skin_color)
	
	# Mắt đỏ phát sáng
	_draw_rect(img, 11, 8 + y_off, 4, 4, eye_color)
	_draw_rect(img, 17, 8 + y_off, 4, 4, eye_color)
	
	# Sừng băng
	_draw_rect(img, 8, 2 + y_off, 3, 8, Color(0.7, 0.85, 0.95))
	_draw_rect(img, 21, 2 + y_off, 3, 8, Color(0.7, 0.85, 0.95))
	
	# Tay
	var arm_off = 0
	if anim == "walk":
		arm_off = [-2, 0, 2, 0][frame_idx]
	if anim == "attack":
		arm_off = [0, -8, -4, 0][frame_idx]
	
	_draw_rect(img, 2, 18 + y_off + arm_off, 6, 14, skin_color)
	_draw_rect(img, 24, 18 + y_off - arm_off, 6, 14, skin_color)
	
	# Móng vuốt băng
	_draw_rect(img, 1, 30 + y_off + arm_off, 3, 6, Color(0.7, 0.85, 0.95))
	_draw_rect(img, 28, 30 + y_off - arm_off, 3, 6, Color(0.7, 0.85, 0.95))
	
	# Chân
	var leg_off = 0
	if anim == "walk":
		leg_off = [-3, 0, 3, 0][frame_idx]
	_draw_rect(img, 8, 36 + y_off, 6, 12 + leg_off, body_color)
	_draw_rect(img, 18, 36 + y_off, 6, 12 - leg_off, body_color)
	
	# Hiệu ứng băng giá xung quanh
	if randf() > 0.5:
		for i in range(5):
			var px = randi_range(0, 31)
			var py = randi_range(0, 47)
			if img.get_pixel(px, py).a < 0.1:
				img.set_pixel(px, py, Color(0.8, 0.9, 1.0, 0.5))
	
	return img

func _draw_rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for px in range(x, min(x + w, img.get_width())):
		for py in range(y, min(y + h, img.get_height())):
			if px >= 0 and py >= 0:
				img.set_pixel(px, py, color)

func _draw_ellipse(img: Image, cx: int, cy: int, rx: int, ry: int, color: Color) -> void:
	for x in range(cx - rx, cx + rx + 1):
		for y in range(cy - ry, cy + ry + 1):
			if rx > 0 and ry > 0:
				var dx = float(x - cx) / float(rx)
				var dy = float(y - cy) / float(ry)
				if dx * dx + dy * dy <= 1.0:
					if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
						img.set_pixel(x, y, color)

func _create_health_bar() -> void:
	health_bar = ProgressBar.new()
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.show_percentage = false
	health_bar.custom_minimum_size = Vector2(120, 12)
	health_bar.position = Vector2(-60, -100)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.8, 0.1, 0.1)
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	health_bar.add_theme_stylebox_override("fill", fill_style)
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	health_bar.add_theme_stylebox_override("background", bg_style)
	
	add_child(health_bar)

func _create_name_label() -> void:
	name_label = Label.new()
	name_label.text = "👑 " + boss_name
	name_label.position = Vector2(-60, -120)
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	add_child(name_label)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	_find_target()
	_update_cooldowns(delta)
	
	match current_state:
		"idle":
			_state_idle()
		"chase":
			_state_chase(delta)
		"attack":
			_state_attack()

func _find_target() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		# Tìm player trực tiếp
		var player = get_tree().current_scene.get_node_or_null("GameWorld/Player")
		if player:
			target = player
		return
	target = players[0]

func _update_cooldowns(delta: float) -> void:
	if special_attack_cooldown > 0:
		special_attack_cooldown -= delta
	if summon_cooldown > 0:
		summon_cooldown -= delta

func _state_idle() -> void:
	if target == null:
		return
	
	var dist = global_position.distance_to(target.global_position)
	if dist < detection_range:
		current_state = "chase"
		sprite.play("walk")

func _state_chase(delta: float) -> void:
	if target == null:
		current_state = "idle"
		sprite.play("idle")
		return
	
	var dist = global_position.distance_to(target.global_position)
	
	if dist > detection_range * 1.5:
		current_state = "idle"
		sprite.play("idle")
		return
	
	if dist < attack_range:
		current_state = "attack"
		_do_attack()
		return
	
	# Di chuyển về phía target
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * chase_speed
	move_and_slide()
	
	# Flip sprite
	if direction.x < 0:
		sprite.flip_h = true
	else:
		sprite.flip_h = false

func _state_attack() -> void:
	if is_attacking:
		return
	
	if target == null:
		current_state = "idle"
		return
	
	var dist = global_position.distance_to(target.global_position)
	if dist > attack_range * 1.5:
		current_state = "chase"
		sprite.play("walk")

func _do_attack() -> void:
	is_attacking = true
	sprite.play("attack")
	
	# Gây sát thương sau một chút delay
	await get_tree().create_timer(0.3).timeout
	
	if target and global_position.distance_to(target.global_position) < attack_range * 1.5:
		if target.has_method("take_damage"):
			target.take_damage(damage)
			_create_ice_effect()

func _create_ice_effect() -> void:
	# Hiệu ứng băng giá khi tấn công
	var ice = Sprite2D.new()
	var img = Image.create(40, 40, false, Image.FORMAT_RGBA8)
	for x in range(40):
		for y in range(40):
			var dist = Vector2(x - 20, y - 20).length()
			if dist < 20:
				img.set_pixel(x, y, Color(0.7, 0.9, 1.0, 0.8 - dist / 25.0))
	ice.texture = ImageTexture.create_from_image(img)
	ice.global_position = target.global_position if target else global_position
	get_parent().add_child(ice)
	
	var tween = ice.create_tween()
	tween.tween_property(ice, "scale", Vector2(3, 3), 0.3)
	tween.parallel().tween_property(ice, "modulate:a", 0.0, 0.3)
	tween.tween_callback(ice.queue_free)

func _on_animation_finished() -> void:
	if sprite.animation == "attack":
		is_attacking = false
		current_state = "chase"
		sprite.play("walk")

func take_damage(amount: int) -> void:
	if is_dead:
		return
	
	health -= amount
	health_bar.value = health
	
	# Hiệu ứng bị đánh
	sprite.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
	
	if health <= 0:
		_die()

func _die() -> void:
	is_dead = true
	boss_defeated.emit()
	
	# Drop loot tốt
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		# Drop nhiều đồ tốt
		game_manager.spawn_dropped_item("rifle", 1, global_position)
		game_manager.spawn_dropped_item("ammo_rifle", 50, global_position + Vector2(20, 0))
		game_manager.spawn_dropped_item("armor_vest", 1, global_position + Vector2(-20, 0))
		game_manager.spawn_dropped_item("bandage", 5, global_position + Vector2(0, 20))
	
	# Animation chết
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(0.5, 0.5, 0.5), 0.5)
	tween.tween_property(self, "scale", Vector2(0.1, 0.1), 0.5)
	tween.tween_callback(queue_free)
