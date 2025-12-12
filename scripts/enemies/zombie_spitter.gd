extends ZombieBase
class_name ZombieSpitter

var spit_cooldown: float = 3.0
var can_spit: bool = true
var spit_range: float = 150.0
var spit_damage: int = 15

func _ready() -> void:
	zombie_name = "Spitter"
	max_health = 35
	damage = 5
	move_speed = 45.0
	chase_speed = 70.0
	detection_range = 180.0
	attack_range = 120.0  # Ranged attack
	body_color = Color(0.3, 0.5, 0.3)
	skin_color = Color(0.4, 0.6, 0.35)
	super._ready()

func _setup_drops() -> void:
	drops = [
		{"item_id": "cloth", "min": 1, "max": 3, "chance": 0.6},
		{"item_id": "meat", "min": 1, "max": 2, "chance": 0.5}
	]

func _perform_attack() -> void:
	if not can_spit:
		super._perform_attack()
		return
	
	can_spit = false
	can_attack = false
	attack_timer.start()
	
	if anim_sprite:
		anim_sprite.play("attack_" + last_direction)
	
	# Create projectile
	await get_tree().create_timer(0.2).timeout
	_spawn_spit()
	
	# Reset spit cooldown
	await get_tree().create_timer(spit_cooldown).timeout
	can_spit = true

func _spawn_spit() -> void:
	if target == null or not is_instance_valid(target):
		return
	
	var spit = Area2D.new()
	spit.collision_layer = 0
	spit.collision_mask = 1
	
	var sprite = Sprite2D.new()
	var img = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for x in range(8):
		for y in range(8):
			var dist = Vector2(x - 4, y - 4).length()
			if dist < 4:
				img.set_pixel(x, y, Color(0.2, 0.8, 0.2, 0.8))
	sprite.texture = ImageTexture.create_from_image(img)
	spit.add_child(sprite)
	
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 6
	collision.shape = shape
	spit.add_child(collision)
	
	spit.global_position = global_position
	get_parent().add_child(spit)
	
	var direction = (target.global_position - global_position).normalized()
	var speed = 200.0
	
	# Move projectile
	var tween = spit.create_tween()
	tween.tween_property(spit, "global_position", global_position + direction * spit_range, spit_range / speed)
	tween.tween_callback(spit.queue_free)
	
	# Check for hit
	spit.body_entered.connect(func(body):
		if body is Player:
			body.take_damage(spit_damage)
			spit.queue_free()
	)

func _create_zombie_frame(direction: String, anim_type: String, frame_idx: int) -> Image:
	var img = super._create_zombie_frame(direction, anim_type, frame_idx)
	
	# Add green glow/drool
	if direction == "down":
		img.set_pixel(11, 10, Color(0.2, 0.8, 0.2))
		img.set_pixel(12, 11, Color(0.2, 0.8, 0.2))
		img.set_pixel(13, 10, Color(0.2, 0.8, 0.2))
	
	return img
