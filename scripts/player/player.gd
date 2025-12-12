extends CharacterBody2D
class_name Player

signal health_changed(current: int, max_val: int)
signal hunger_changed(current: int, max_val: int)
signal thirst_changed(current: int, max_val: int)
signal stamina_changed(current: float, max_val: float)
signal ammo_changed(ammo_type: String, amount: int)
signal weapon_changed(weapon: WeaponData)
signal died

# Stats
@export var max_health: int = 100
@export var max_hunger: int = 100
@export var max_thirst: int = 100
@export var max_stamina: float = 100.0

var health: int = 100
var hunger: int = 100
var thirst: int = 100
var stamina: float = 100.0

# Movement
@export var walk_speed: float = 150.0
@export var run_speed: float = 250.0
@export var stamina_drain: float = 20.0
@export var stamina_regen: float = 15.0

var current_speed: float = 150.0
var is_running: bool = false
var facing_direction: Vector2 = Vector2.DOWN
var last_direction: String = "down"

# Combat
@export var base_damage: int = 10
var can_attack: bool = true
var is_attacking: bool = false
var is_shooting: bool = false
var is_reloading: bool = false
var equipped_weapon: Item = null
var equipped_weapon_data: WeaponData = null
var has_gun: bool = false
var current_weapon_type: String = "melee"

# Ammo
var ammo: Dictionary = {"pistol": 0, "rifle": 0, "shotgun": 0}
var current_magazine: int = 0  # Đạn trong băng hiện tại

# Weapon sprite
var weapon_sprite_node: WeaponSprite = null

# Mobile joystick
var joystick_direction: Vector2 = Vector2.ZERO

# Animation
var anim_player: AnimatedSprite2D
var weapon_sprite: Sprite2D
var muzzle_flash: Sprite2D

# References
@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var attack_timer: Timer = $AttackTimer
@onready var hunger_timer: Timer = $HungerTimer
@onready var thirst_timer: Timer = $ThirstTimer
@onready var attack_area: Area2D = $AttackArea

func _ready() -> void:
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	hunger_timer.timeout.connect(_on_hunger_timer_timeout)
	thirst_timer.timeout.connect(_on_thirst_timer_timeout)
	_create_animated_player()
	_create_weapon_sprite()

func _create_animated_player() -> void:
	if sprite:
		sprite.queue_free()
	
	anim_player = AnimatedSprite2D.new()
	anim_player.name = "AnimatedSprite"
	add_child(anim_player)
	
	var frames = SpriteFrames.new()
	var directions = ["down", "up", "left", "right"]
	
	for dir in directions:
		# Idle - no weapon
		frames.add_animation("idle_" + dir)
		frames.set_animation_speed("idle_" + dir, 4)
		frames.set_animation_loop("idle_" + dir, true)
		for i in range(2):
			frames.add_frame("idle_" + dir, ImageTexture.create_from_image(_create_player_frame(dir, "idle", i, "none")))
		
		# Walk - no weapon
		frames.add_animation("walk_" + dir)
		frames.set_animation_speed("walk_" + dir, 8)
		frames.set_animation_loop("walk_" + dir, true)
		for i in range(4):
			frames.add_frame("walk_" + dir, ImageTexture.create_from_image(_create_player_frame(dir, "walk", i, "none")))
		
		# Melee attack
		frames.add_animation("attack_" + dir)
		frames.set_animation_speed("attack_" + dir, 10)
		frames.set_animation_loop("attack_" + dir, false)
		for i in range(3):
			frames.add_frame("attack_" + dir, ImageTexture.create_from_image(_create_player_frame(dir, "attack", i, "melee")))
		
		# Gun idle
		frames.add_animation("gun_idle_" + dir)
		frames.set_animation_speed("gun_idle_" + dir, 4)
		frames.set_animation_loop("gun_idle_" + dir, true)
		for i in range(2):
			frames.add_frame("gun_idle_" + dir, ImageTexture.create_from_image(_create_player_frame(dir, "idle", i, "gun")))
		
		# Gun walk
		frames.add_animation("gun_walk_" + dir)
		frames.set_animation_speed("gun_walk_" + dir, 8)
		frames.set_animation_loop("gun_walk_" + dir, true)
		for i in range(4):
			frames.add_frame("gun_walk_" + dir, ImageTexture.create_from_image(_create_player_frame(dir, "walk", i, "gun")))
		
		# Gun shoot
		frames.add_animation("shoot_" + dir)
		frames.set_animation_speed("shoot_" + dir, 12)
		frames.set_animation_loop("shoot_" + dir, false)
		for i in range(3):
			frames.add_frame("shoot_" + dir, ImageTexture.create_from_image(_create_player_frame(dir, "shoot", i, "gun")))
	
	if frames.has_animation("default"):
		frames.remove_animation("default")
	
	anim_player.sprite_frames = frames
	anim_player.play("idle_down")
	anim_player.scale = Vector2(2.5, 2.5)
	anim_player.animation_finished.connect(_on_animation_finished)

func _create_weapon_sprite() -> void:
	weapon_sprite = Sprite2D.new()
	weapon_sprite.name = "WeaponSprite"
	weapon_sprite.visible = false
	add_child(weapon_sprite)
	
	muzzle_flash = Sprite2D.new()
	muzzle_flash.name = "MuzzleFlash"
	muzzle_flash.visible = false
	var flash_img = Image.create(10, 10, false, Image.FORMAT_RGBA8)
	for x in range(10):
		for y in range(10):
			var dist = Vector2(x - 5, y - 5).length()
			if dist < 5:
				flash_img.set_pixel(x, y, Color(1, 0.9, 0.3, 1.0 - dist / 5.0))
	muzzle_flash.texture = ImageTexture.create_from_image(flash_img)
	muzzle_flash.scale = Vector2(2, 2)
	add_child(muzzle_flash)
	
	# Tạo weapon sprite node cho hệ thống súng mới
	weapon_sprite_node = WeaponSprite.new()
	weapon_sprite_node.name = "WeaponSpriteNode"
	weapon_sprite_node.visible = false
	add_child(weapon_sprite_node)

func _create_player_frame(direction: String, anim_type: String, frame_idx: int, weapon_type: String) -> Image:
	var img = Image.create(32, 40, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	var body_color = Color(0.2, 0.45, 0.25)
	var skin_color = Color(0.95, 0.8, 0.7)
	var pants_color = Color(0.3, 0.25, 0.2)
	var hair_color = Color(0.25, 0.18, 0.1)
	var gun_color = Color(0.25, 0.25, 0.25)
	var gun_handle = Color(0.4, 0.3, 0.2)
	
	var y_off = 0
	if anim_type == "walk":
		y_off = [0, -1, 0, -1][frame_idx]
	
	var cx = 16
	var cy = 10 + y_off
	
	match direction:
		"down":
			_draw_ellipse(img, cx, cy - 2, 6, 4, hair_color)
			_draw_ellipse(img, cx, cy, 5, 6, skin_color)
			img.set_pixel(14, 9 + y_off, Color.BLACK)
			img.set_pixel(18, 9 + y_off, Color.BLACK)
			_draw_rect_img(img, 11, 16 + y_off, 10, 12, body_color)
			
			var arm_off = 0
			if anim_type == "walk": arm_off = [-1, 0, 1, 0][frame_idx]
			
			if weapon_type == "gun":
				# Both arms forward holding gun
				_draw_rect_img(img, 7, 17 + y_off, 4, 8, skin_color)
				_draw_rect_img(img, 21, 17 + y_off, 4, 8, skin_color)
				# Gun in front
				_draw_rect_img(img, 13, 28 + y_off, 6, 4, gun_color)
				_draw_rect_img(img, 14, 32 + y_off, 4, 3, gun_handle)
				if anim_type == "shoot" and frame_idx == 1:
					_draw_rect_img(img, 14, 25 + y_off, 4, 3, Color(1, 0.8, 0.2))
			elif weapon_type == "melee" and anim_type == "attack":
				var swing = [0, -8, -4][frame_idx]
				_draw_rect_img(img, 7, 17 + y_off + arm_off, 4, 8, skin_color)
				_draw_rect_img(img, 21, 12 + y_off + swing, 4, 10, skin_color)
				# Knife/weapon
				_draw_rect_img(img, 23, 8 + y_off + swing, 3, 12, Color.SILVER)
			else:
				_draw_rect_img(img, 7, 17 + y_off + arm_off, 4, 8, skin_color)
				_draw_rect_img(img, 21, 17 + y_off - arm_off, 4, 8, skin_color)
			
			_draw_rect_img(img, 11, 28 + y_off, 5, 10, pants_color)
			_draw_rect_img(img, 16, 28 + y_off, 5, 10, pants_color)
		
		"up":
			_draw_ellipse(img, cx, cy, 6, 6, hair_color)
			_draw_rect_img(img, 11, 16 + y_off, 10, 12, body_color)
			var arm_off = 0
			if anim_type == "walk": arm_off = [-1, 0, 1, 0][frame_idx]
			
			if weapon_type == "gun":
				_draw_rect_img(img, 7, 15 + y_off, 4, 10, skin_color)
				_draw_rect_img(img, 21, 15 + y_off, 4, 10, skin_color)
				_draw_rect_img(img, 13, 5 + y_off, 6, 4, gun_color)
			else:
				_draw_rect_img(img, 7, 17 + y_off - arm_off, 4, 8, skin_color)
				_draw_rect_img(img, 21, 17 + y_off + arm_off, 4, 8, skin_color)
			
			_draw_rect_img(img, 11, 28 + y_off, 5, 10, pants_color)
			_draw_rect_img(img, 16, 28 + y_off, 5, 10, pants_color)

		"left":
			_draw_ellipse(img, cx - 2, cy, 5, 6, skin_color)
			_draw_ellipse(img, cx, cy - 1, 5, 5, hair_color)
			img.set_pixel(12, 9 + y_off, Color.BLACK)
			_draw_rect_img(img, 12, 16 + y_off, 8, 12, body_color)
			
			if weapon_type == "gun":
				# Arm extended with gun
				_draw_rect_img(img, 4, 18 + y_off, 10, 4, skin_color)
				# Gun
				_draw_rect_img(img, 0, 17 + y_off, 8, 5, gun_color)
				_draw_rect_img(img, 6, 22 + y_off, 3, 4, gun_handle)
				if anim_type == "shoot" and frame_idx == 1:
					_draw_rect_img(img, 0, 18 + y_off, 3, 3, Color(1, 0.8, 0.2))
			elif weapon_type == "melee" and anim_type == "attack":
				var swing = [0, 6, 3][frame_idx]
				_draw_rect_img(img, 8 - swing, 16 + y_off, 4, 8, skin_color)
				_draw_rect_img(img, 2 - swing, 12 + y_off, 3, 14, Color.SILVER)
			else:
				var leg_off = 0
				if anim_type == "walk": leg_off = [-2, 0, 2, 0][frame_idx]
				_draw_rect_img(img, 8, 18 + y_off, 4, 8, skin_color)
			
			var leg_off = 0
			if anim_type == "walk": leg_off = [-2, 0, 2, 0][frame_idx]
			_draw_rect_img(img, 12, 28 + y_off, 4, 10 + leg_off, pants_color)
			_draw_rect_img(img, 16, 28 + y_off, 4, 10 - leg_off, pants_color)
		
		"right":
			_draw_ellipse(img, cx + 2, cy, 5, 6, skin_color)
			_draw_ellipse(img, cx, cy - 1, 5, 5, hair_color)
			img.set_pixel(20, 9 + y_off, Color.BLACK)
			_draw_rect_img(img, 12, 16 + y_off, 8, 12, body_color)
			
			if weapon_type == "gun":
				_draw_rect_img(img, 18, 18 + y_off, 10, 4, skin_color)
				_draw_rect_img(img, 24, 17 + y_off, 8, 5, gun_color)
				_draw_rect_img(img, 23, 22 + y_off, 3, 4, gun_handle)
				if anim_type == "shoot" and frame_idx == 1:
					_draw_rect_img(img, 29, 18 + y_off, 3, 3, Color(1, 0.8, 0.2))
			elif weapon_type == "melee" and anim_type == "attack":
				var swing = [0, 6, 3][frame_idx]
				_draw_rect_img(img, 20 + swing, 16 + y_off, 4, 8, skin_color)
				_draw_rect_img(img, 27 + swing, 12 + y_off, 3, 14, Color.SILVER)
			else:
				_draw_rect_img(img, 20, 18 + y_off, 4, 8, skin_color)
			
			var leg_off = 0
			if anim_type == "walk": leg_off = [-2, 0, 2, 0][frame_idx]
			_draw_rect_img(img, 12, 28 + y_off, 4, 10 - leg_off, pants_color)
			_draw_rect_img(img, 16, 28 + y_off, 4, 10 + leg_off, pants_color)
	
	return img

func _draw_rect_img(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
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

func _physics_process(delta: float) -> void:
	if is_attacking or is_shooting:
		return
	_handle_movement(delta)
	_handle_stamina(delta)
	_update_animation()

func _handle_movement(_delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if joystick_direction.length() > 0.1:
		input_dir = joystick_direction
	
	is_running = Input.is_action_pressed("run") and stamina > 0 and input_dir != Vector2.ZERO
	current_speed = run_speed if is_running else walk_speed
	velocity = input_dir * current_speed
	
	if input_dir.length() > 0.1:
		facing_direction = input_dir.normalized()
		_update_direction_string()
	
	move_and_slide()

func _update_direction_string() -> void:
	if abs(facing_direction.x) > abs(facing_direction.y):
		last_direction = "right" if facing_direction.x > 0 else "left"
	else:
		last_direction = "down" if facing_direction.y > 0 else "up"
	
	if attack_area:
		match last_direction:
			"down": attack_area.position = Vector2(0, 25)
			"up": attack_area.position = Vector2(0, -25)
			"left": attack_area.position = Vector2(-25, 0)
			"right": attack_area.position = Vector2(25, 0)

func _update_animation() -> void:
	if not anim_player:
		return
	
	var prefix = "gun_" if has_gun else ""
	if velocity.length() > 10:
		anim_player.play(prefix + "walk_" + last_direction)
	else:
		anim_player.play(prefix + "idle_" + last_direction)
	
	# Cập nhật hướng weapon sprite
	if weapon_sprite_node and weapon_sprite_node.visible:
		weapon_sprite_node.update_direction(last_direction)

func _handle_stamina(delta: float) -> void:
	if is_running:
		stamina = max(0, stamina - stamina_drain * delta)
	else:
		stamina = min(max_stamina, stamina + stamina_regen * delta)
	stamina_changed.emit(stamina, max_stamina)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		attack()
	elif event.is_action_pressed("interact"):
		interact()
	elif event.is_action_pressed("reload"):
		reload_weapon()

func attack() -> void:
	if not can_attack or is_attacking or is_shooting:
		return
	
	if has_gun and (equipped_weapon or equipped_weapon_data):
		_shoot()
	else:
		_melee_attack()

func _melee_attack() -> void:
	is_attacking = true
	can_attack = false
	attack_timer.start()
	
	if anim_player:
		anim_player.play("attack_" + last_direction)
	
	var damage = base_damage
	if equipped_weapon:
		damage += equipped_weapon.damage
	
	if attack_area:
		var bodies = attack_area.get_overlapping_bodies()
		for body in bodies:
			if body.has_method("take_damage"):
				body.take_damage(damage)

func _shoot() -> void:
	if is_reloading:
		return
	
	# Kiểm tra đạn trong băng
	if equipped_weapon_data:
		if current_magazine <= 0:
			reload_weapon()
			return
		current_magazine -= 1
	else:
		var ammo_type = _get_ammo_type()
		if ammo[ammo_type] <= 0:
			return
		ammo[ammo_type] -= 1
	
	var ammo_type = _get_ammo_type()
	ammo_changed.emit(ammo_type, ammo[ammo_type])
	
	is_shooting = true
	can_attack = false
	
	if anim_player:
		anim_player.play("shoot_" + last_direction)
	
	_show_muzzle_flash()
	
	# Hiệu ứng muzzle flash từ weapon sprite
	if weapon_sprite_node and weapon_sprite_node.visible:
		weapon_sprite_node.show_muzzle_flash(last_direction)
		weapon_sprite_node.play_recoil_animation()
	
	_spawn_bullet()
	
	await get_tree().create_timer(_get_fire_rate()).timeout
	is_shooting = false
	can_attack = true

func reload_weapon() -> void:
	print("Reload pressed! equipped_weapon_data: ", equipped_weapon_data, " is_reloading: ", is_reloading)
	if is_reloading:
		print("Already reloading!")
		return
	if not equipped_weapon_data:
		print("No weapon equipped!")
		return
	
	var ammo_type = _get_ammo_type()
	print("Ammo type: ", ammo_type, " available: ", ammo[ammo_type])
	if ammo[ammo_type] <= 0:
		print("No ammo!")
		return
	
	if current_magazine >= equipped_weapon_data.magazine_size:
		print("Magazine full!")
		return
	
	is_reloading = true
	print("Reloading... wait ", equipped_weapon_data.reload_time, " seconds")
	
	# Animation reload
	await get_tree().create_timer(equipped_weapon_data.reload_time).timeout
	
	var needed = equipped_weapon_data.magazine_size - current_magazine
	var available = ammo[ammo_type]
	var to_load = min(needed, available)
	
	current_magazine += to_load
	ammo[ammo_type] -= to_load
	ammo_changed.emit(ammo_type, ammo[ammo_type])
	
	is_reloading = false
	print("Reload complete! Magazine: ", current_magazine)

func _get_ammo_type() -> String:
	if equipped_weapon_data:
		match equipped_weapon_data.weapon_type:
			WeaponData.WeaponType.PISTOL, WeaponData.WeaponType.SMG:
				return "pistol"
			WeaponData.WeaponType.RIFLE, WeaponData.WeaponType.SNIPER:
				return "rifle"
			WeaponData.WeaponType.SHOTGUN:
				return "shotgun"
	if equipped_weapon:
		match equipped_weapon.id:
			"pistol": return "pistol"
			"rifle": return "rifle"
			"shotgun": return "shotgun"
	return "pistol"

func _get_fire_rate() -> float:
	if equipped_weapon_data:
		return equipped_weapon_data.fire_rate
	if equipped_weapon:
		match equipped_weapon.id:
			"pistol": return 0.4
			"rifle": return 0.15
			"shotgun": return 0.8
	return 0.5

func _show_muzzle_flash() -> void:
	muzzle_flash.visible = true
	match last_direction:
		"down": muzzle_flash.position = Vector2(0, 40)
		"up": muzzle_flash.position = Vector2(0, -30)
		"left": muzzle_flash.position = Vector2(-35, 5)
		"right": muzzle_flash.position = Vector2(35, 5)
	
	var tween = create_tween()
	tween.tween_property(muzzle_flash, "modulate:a", 0.0, 0.1)
	tween.tween_callback(func(): muzzle_flash.visible = false; muzzle_flash.modulate.a = 1.0)

func _spawn_bullet() -> void:
	var damage = 15
	var pellets = 1
	var spread = 0.0
	var bullet_speed = 400.0
	
	if equipped_weapon_data:
		damage = equipped_weapon_data.damage
		pellets = equipped_weapon_data.pellets
		spread = equipped_weapon_data.spread
		bullet_speed = equipped_weapon_data.bullet_speed
	elif equipped_weapon:
		damage = equipped_weapon.damage
		if equipped_weapon.id == "shotgun":
			pellets = 5
			damage = 8
	
	for i in range(pellets):
		var bullet = Area2D.new()
		bullet.collision_layer = 0
		bullet.collision_mask = 2
		
		var bsprite = Sprite2D.new()
		var bimg = Image.create(8, 4, false, Image.FORMAT_RGBA8)
		bimg.fill(Color(1, 0.9, 0.3))
		bsprite.texture = ImageTexture.create_from_image(bimg)
		bullet.add_child(bsprite)
		
		var col = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 4
		col.shape = shape
		bullet.add_child(col)
		
		var bullet_spread = 0.0
		if pellets > 1:
			bullet_spread = randf_range(-spread, spread)
		elif spread > 0:
			bullet_spread = randf_range(-spread, spread)
		
		var dir = facing_direction.rotated(bullet_spread)
		bullet.global_position = global_position + dir * 30
		bsprite.rotation = dir.angle()
		
		get_parent().add_child(bullet)
		
		bullet.body_entered.connect(func(body):
			if body.has_method("take_damage"):
				body.take_damage(damage)
				bullet.queue_free()
		)
		
		var travel_time = 500.0 / bullet_speed
		var tween = bullet.create_tween()
		tween.tween_property(bullet, "global_position", bullet.global_position + dir * 500, travel_time)
		tween.tween_callback(bullet.queue_free)

func equip_item(item: Item) -> void:
	equipped_weapon = item
	if item:
		has_gun = item.id in ["pistol", "rifle", "shotgun", "smg", "sniper"]
		current_weapon_type = "gun" if has_gun else "melee"
	else:
		has_gun = false
		current_weapon_type = "melee"

func equip_weapon_data(weapon: WeaponData) -> void:
	equipped_weapon_data = weapon
	has_gun = true
	current_weapon_type = "gun"
	current_magazine = weapon.magazine_size
	
	# Cập nhật weapon sprite
	if weapon_sprite_node:
		weapon_sprite_node.setup(weapon)
		weapon_sprite_node.visible = true
		weapon_sprite_node.update_direction(last_direction)
	
	weapon_changed.emit(weapon)

func unequip_weapon() -> void:
	equipped_weapon_data = null
	equipped_weapon = null
	has_gun = false
	current_weapon_type = "melee"
	current_magazine = 0
	
	if weapon_sprite_node:
		weapon_sprite_node.visible = false
	
	weapon_changed.emit(null)

func add_ammo(ammo_type: String, amount: int) -> void:
	if ammo.has(ammo_type):
		ammo[ammo_type] += amount
		ammo_changed.emit(ammo_type, ammo[ammo_type])

func _on_animation_finished() -> void:
	if anim_player.animation.begins_with("attack_"):
		is_attacking = false
	elif anim_player.animation.begins_with("shoot_"):
		is_shooting = false

func interact() -> void:
	var bodies = interaction_area.get_overlapping_bodies()
	var areas = interaction_area.get_overlapping_areas()
	
	for body in bodies:
		if body.has_method("interact"):
			body.interact(self)
			return
	
	# Tìm weapon drop trong phạm vi gần
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = global_position
	query.collision_mask = 4  # Layer Interactable
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var results = space_state.intersect_point(query, 10)
	
	for result in results:
		var collider = result["collider"]
		if collider is Area2D and collider.has_meta("weapon_data"):
			var game_manager = get_node_or_null("/root/GameManager")
			if game_manager:
				game_manager.pickup_weapon(collider)
			return
	
	for area in areas:
		# Kiểm tra nếu là weapon drop
		if area.has_meta("weapon_data"):
			var game_manager = get_node_or_null("/root/GameManager")
			if game_manager:
				game_manager.pickup_weapon(area)
			return
		
		if area.has_method("interact"):
			area.interact(self)
			return

func take_damage(amount: int) -> void:
	health = max(0, health - amount)
	health_changed.emit(health, max_health)
	
	if anim_player:
		anim_player.modulate = Color.RED
		var tween = create_tween()
		tween.tween_property(anim_player, "modulate", Color.WHITE, 0.2)
	
	if health <= 0:
		die()

func restore_health(amount: int) -> void:
	health = min(max_health, health + amount)
	health_changed.emit(health, max_health)

func restore_hunger(amount: int) -> void:
	hunger = min(max_hunger, hunger + amount)
	hunger_changed.emit(hunger, max_hunger)

func restore_thirst(amount: int) -> void:
	thirst = min(max_thirst, thirst + amount)
	thirst_changed.emit(thirst, max_thirst)

func die() -> void:
	died.emit()

func _on_attack_timer_timeout() -> void:
	can_attack = true
	is_attacking = false

func _on_hunger_timer_timeout() -> void:
	hunger = max(0, hunger - 1)
	hunger_changed.emit(hunger, max_hunger)
	if hunger <= 0:
		take_damage(2)

func _on_thirst_timer_timeout() -> void:
	thirst = max(0, thirst - 1)
	thirst_changed.emit(thirst, max_thirst)
	if thirst <= 0:
		take_damage(3)
