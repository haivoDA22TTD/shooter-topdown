extends CharacterBody2D
class_name ZombieBase

enum ZombieState { IDLE, WANDER, CHASE, ATTACK, HURT, DEAD }

# Stats - override in subclasses
@export var zombie_name: String = "Zombie"
@export var max_health: int = 50
@export var damage: int = 10
@export var move_speed: float = 60.0
@export var chase_speed: float = 100.0
@export var attack_range: float = 30.0
@export var detection_range: float = 150.0
@export var attack_cooldown: float = 1.5

# Colors for different zombie types
@export var body_color: Color = Color(0.4, 0.5, 0.3)
@export var skin_color: Color = Color(0.5, 0.6, 0.4)

var health: int
var state: ZombieState = ZombieState.IDLE
var target: Player = null
var can_attack: bool = true
var wander_point: Vector2
var last_direction: String = "down"
var facing_direction: Vector2 = Vector2.DOWN

var anim_sprite: AnimatedSprite2D
var drops: Array[Dictionary] = []

@onready var detection_area: Area2D = $DetectionArea
@onready var attack_timer: Timer = $AttackTimer
@onready var state_timer: Timer = $StateTimer

func _ready() -> void:
	health = max_health
	wander_point = global_position
	attack_timer.wait_time = attack_cooldown
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	state_timer.timeout.connect(_on_state_timer_timeout)
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	_create_animated_zombie()
	_setup_drops()
	state_timer.start(randf_range(2.0, 5.0))

func _setup_drops() -> void:
	drops = [
		{"item_id": "cloth", "min": 0, "max": 2, "chance": 0.5},
		{"item_id": "meat", "min": 1, "max": 2, "chance": 0.7}
	]

func _create_animated_zombie() -> void:
	anim_sprite = AnimatedSprite2D.new()
	anim_sprite.name = "AnimatedSprite"
	add_child(anim_sprite)
	
	var frames = SpriteFrames.new()
	var directions = ["down", "up", "left", "right"]
	
	for dir in directions:
		# Idle
		frames.add_animation("idle_" + dir)
		frames.set_animation_speed("idle_" + dir, 3)
		frames.set_animation_loop("idle_" + dir, true)
		for i in range(2):
			var img = _create_zombie_frame(dir, "idle", i)
			frames.add_frame("idle_" + dir, ImageTexture.create_from_image(img))
		
		# Walk
		frames.add_animation("walk_" + dir)
		frames.set_animation_speed("walk_" + dir, 6)
		frames.set_animation_loop("walk_" + dir, true)
		for i in range(4):
			var img = _create_zombie_frame(dir, "walk", i)
			frames.add_frame("walk_" + dir, ImageTexture.create_from_image(img))
		
		# Attack
		frames.add_animation("attack_" + dir)
		frames.set_animation_speed("attack_" + dir, 8)
		frames.set_animation_loop("attack_" + dir, false)
		for i in range(3):
			var img = _create_zombie_frame(dir, "attack", i)
			frames.add_frame("attack_" + dir, ImageTexture.create_from_image(img))
		
		# Hurt
		frames.add_animation("hurt_" + dir)
		frames.set_animation_speed("hurt_" + dir, 8)
		frames.set_animation_loop("hurt_" + dir, false)
		var hurt_img = _create_zombie_frame(dir, "hurt", 0)
		frames.add_frame("hurt_" + dir, ImageTexture.create_from_image(hurt_img))
	
	# Death animation
	frames.add_animation("death")
	frames.set_animation_speed("death", 4)
	frames.set_animation_loop("death", false)
	for i in range(4):
		var img = _create_death_frame(i)
		frames.add_frame("death", ImageTexture.create_from_image(img))
	
	if frames.has_animation("default"):
		frames.remove_animation("default")
	
	anim_sprite.sprite_frames = frames
	anim_sprite.play("idle_down")
	anim_sprite.scale = Vector2(2, 2)
	anim_sprite.animation_finished.connect(_on_animation_finished)

func _create_zombie_frame(direction: String, anim_type: String, frame_idx: int) -> Image:
	var img = Image.create(24, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	var y_offset = 0
	if anim_type == "walk":
		y_offset = [0, -1, 0, -1][frame_idx]
	elif anim_type == "hurt":
		y_offset = 1
	
	var head_x = 12
	var head_y = 6 + y_offset
	
	# Torn clothes color
	var clothes_color = body_color.darkened(0.2)
	
	match direction:
		"down":
			# Head
			_draw_ellipse(img, head_x, head_y, 5, 6, skin_color)
			# Zombie eyes (red/yellow)
			img.set_pixel(10, 5 + y_offset, Color.RED)
			img.set_pixel(14, 5 + y_offset, Color.YELLOW)
			# Mouth
			img.set_pixel(11, 9 + y_offset, Color.DARK_RED)
			img.set_pixel(12, 9 + y_offset, Color.DARK_RED)
			img.set_pixel(13, 9 + y_offset, Color.DARK_RED)
			# Body (torn)
			_draw_rect_img(img, 8, 12 + y_offset, 8, 10, clothes_color)
			# Arms
			var arm_offset = 0
			if anim_type == "walk":
				arm_offset = [-2, 0, 2, 0][frame_idx]
			elif anim_type == "attack":
				arm_offset = [-3, -5, -3][frame_idx]
			_draw_rect_img(img, 4, 13 + y_offset + arm_offset, 4, 9, skin_color)
			_draw_rect_img(img, 16, 13 + y_offset - arm_offset, 4, 9, skin_color)
			# Pants (torn)
			_draw_rect_img(img, 8, 22 + y_offset, 4, 9, Color(0.2, 0.2, 0.2))
			_draw_rect_img(img, 12, 22 + y_offset, 4, 9, Color(0.2, 0.2, 0.2))
		
		"up":
			_draw_ellipse(img, head_x, head_y, 5, 6, skin_color)
			_draw_rect_img(img, 8, 12 + y_offset, 8, 10, clothes_color)
			var arm_offset = 0
			if anim_type == "walk":
				arm_offset = [-2, 0, 2, 0][frame_idx]
			_draw_rect_img(img, 4, 13 + y_offset - arm_offset, 4, 9, skin_color)
			_draw_rect_img(img, 16, 13 + y_offset + arm_offset, 4, 9, skin_color)
			_draw_rect_img(img, 8, 22 + y_offset, 4, 9, Color(0.2, 0.2, 0.2))
			_draw_rect_img(img, 12, 22 + y_offset, 4, 9, Color(0.2, 0.2, 0.2))
		
		"left", "right":
			var flip = 1 if direction == "right" else -1
			var hx = head_x + (2 * flip)
			_draw_ellipse(img, hx, head_y, 5, 6, skin_color)
			# Eye
			var eye_x = 8 if direction == "left" else 16
			img.set_pixel(eye_x, 5 + y_offset, Color.RED)
			# Body
			_draw_rect_img(img, 9, 12 + y_offset, 6, 10, clothes_color)
			# Arm
			var arm_x = 5 if direction == "left" else 15
			var arm_y = 13 + y_offset
			if anim_type == "attack":
				var ext = [0, 4, 2][frame_idx]
				if direction == "left":
					_draw_rect_img(img, arm_x - ext, arm_y - 3, 4 + ext, 4, skin_color)
				else:
					_draw_rect_img(img, arm_x, arm_y - 3, 4 + ext, 4, skin_color)
			else:
				_draw_rect_img(img, arm_x, arm_y, 4, 9, skin_color)
			# Legs
			var leg_offset = 0
			if anim_type == "walk":
				leg_offset = [-2, 0, 2, 0][frame_idx]
			_draw_rect_img(img, 9, 22 + y_offset, 3, 9 + leg_offset, Color(0.2, 0.2, 0.2))
			_draw_rect_img(img, 12, 22 + y_offset, 3, 9 - leg_offset, Color(0.2, 0.2, 0.2))
	
	return img

func _create_death_frame(frame_idx: int) -> Image:
	var img = Image.create(32, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	var alpha = 1.0 - (frame_idx * 0.2)
	var col = skin_color
	col.a = alpha
	
	# Lying down zombie
	_draw_rect_img(img, 4, 6, 24, 8, col)
	_draw_ellipse(img, 6, 8, 4, 3, col)
	
	return img

func _draw_rect_img(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for px in range(x, min(x + w, img.get_width())):
		for py in range(y, min(y + h, img.get_height())):
			if px >= 0 and py >= 0:
				img.set_pixel(px, py, color)

func _draw_ellipse(img: Image, cx: int, cy: int, rx: int, ry: int, color: Color) -> void:
	for x in range(cx - rx, cx + rx + 1):
		for y in range(cy - ry, cy + ry + 1):
			var dx = float(x - cx) / float(rx) if rx > 0 else 0
			var dy = float(y - cy) / float(ry) if ry > 0 else 0
			if dx * dx + dy * dy <= 1.0:
				if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
					img.set_pixel(x, y, color)

func _physics_process(delta: float) -> void:
	if state == ZombieState.DEAD:
		return
	
	match state:
		ZombieState.IDLE:
			_idle_behavior(delta)
		ZombieState.WANDER:
			_wander_behavior(delta)
		ZombieState.CHASE:
			_chase_behavior(delta)
		ZombieState.ATTACK:
			_attack_behavior(delta)
	
	_update_animation()

func _idle_behavior(_delta: float) -> void:
	velocity = Vector2.ZERO

func _wander_behavior(_delta: float) -> void:
	var dir = (wander_point - global_position).normalized()
	velocity = dir * move_speed
	_update_facing(dir)
	move_and_slide()
	
	if global_position.distance_to(wander_point) < 10:
		state = ZombieState.IDLE
		state_timer.start(randf_range(1.0, 3.0))

func _chase_behavior(_delta: float) -> void:
	if target == null or not is_instance_valid(target):
		state = ZombieState.IDLE
		return
	
	var distance = global_position.distance_to(target.global_position)
	
	if distance <= attack_range:
		state = ZombieState.ATTACK
		velocity = Vector2.ZERO
	else:
		var dir = (target.global_position - global_position).normalized()
		velocity = dir * chase_speed
		_update_facing(dir)
		move_and_slide()

func _attack_behavior(_delta: float) -> void:
	if target == null or not is_instance_valid(target):
		state = ZombieState.IDLE
		return
	
	var distance = global_position.distance_to(target.global_position)
	
	if distance > attack_range * 1.5:
		state = ZombieState.CHASE
		return
	
	if can_attack:
		_perform_attack()

func _perform_attack() -> void:
	can_attack = false
	attack_timer.start()
	
	if anim_sprite:
		anim_sprite.play("attack_" + last_direction)
	
	# Delay damage to sync with animation
	await get_tree().create_timer(0.3).timeout
	
	if target and is_instance_valid(target):
		var dist = global_position.distance_to(target.global_position)
		if dist <= attack_range * 1.5:
			target.take_damage(damage)

func _update_facing(dir: Vector2) -> void:
	facing_direction = dir
	if abs(dir.x) > abs(dir.y):
		last_direction = "right" if dir.x > 0 else "left"
	else:
		last_direction = "down" if dir.y > 0 else "up"

func _update_animation() -> void:
	if not anim_sprite or state == ZombieState.DEAD:
		return
	
	if state == ZombieState.ATTACK:
		return  # Attack animation handled separately
	
	if velocity.length() > 5:
		anim_sprite.play("walk_" + last_direction)
	else:
		anim_sprite.play("idle_" + last_direction)

func take_damage(amount: int) -> void:
	if state == ZombieState.DEAD:
		return
	
	health -= amount
	
	if anim_sprite:
		anim_sprite.modulate = Color.RED
		var tween = create_tween()
		tween.tween_property(anim_sprite, "modulate", Color.WHITE, 0.15)
	
	if health <= 0:
		die()

func die() -> void:
	state = ZombieState.DEAD
	velocity = Vector2.ZERO
	
	if anim_sprite:
		anim_sprite.play("death")
	
	_drop_loot()
	
	# Remove after death animation
	await get_tree().create_timer(1.0).timeout
	queue_free()

func _drop_loot() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager == null:
		return
	
	for drop in drops:
		if randf() <= drop.get("chance", 0.5):
			var qty = randi_range(drop["min"], drop["max"])
			if qty > 0:
				game_manager.spawn_dropped_item(drop["item_id"], qty, global_position)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		target = body
		state = ZombieState.CHASE

func _on_body_exited(body: Node2D) -> void:
	if body == target:
		target = null
		state = ZombieState.IDLE

func _on_attack_timer_timeout() -> void:
	can_attack = true

func _on_state_timer_timeout() -> void:
	if state == ZombieState.IDLE and target == null:
		state = ZombieState.WANDER
		wander_point = global_position + Vector2(randf_range(-80, 80), randf_range(-80, 80))

func _on_animation_finished() -> void:
	pass
