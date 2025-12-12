extends StaticBody2D
class_name ResourceNode

enum ResourceType { TREE, STONE, IRON, BUSH }

@export var resource_type: ResourceType = ResourceType.TREE
@export var health: int = 100

var drops: Array[Dictionary] = []
var max_health: int
var sprite: Sprite2D

func _ready() -> void:
	max_health = health
	_create_sprite()
	_setup_resource()

func _create_sprite() -> void:
	sprite = Sprite2D.new()
	sprite.name = "Sprite"
	add_child(sprite)

func _setup_resource() -> void:
	var img: Image
	
	match resource_type:
		ResourceType.TREE:
			img = _create_tree_image()
			drops = [{"item_id": "wood", "min": 2, "max": 5}]
			health = 80
		ResourceType.STONE:
			img = _create_stone_image()
			drops = [{"item_id": "stone", "min": 1, "max": 3}]
			health = 100
		ResourceType.IRON:
			img = _create_iron_image()
			drops = [
				{"item_id": "stone", "min": 1, "max": 2},
				{"item_id": "iron_ore", "min": 1, "max": 2}
			]
			health = 120
		ResourceType.BUSH:
			img = _create_bush_image()
			drops = [{"item_id": "berries", "min": 1, "max": 4}]
			health = 30
	
	max_health = health
	sprite.texture = ImageTexture.create_from_image(img)
	sprite.scale = Vector2(1.5, 1.5)

func _create_tree_image() -> Image:
	var img = Image.create(32, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	# Trunk
	for x in range(12, 20):
		for y in range(28, 48):
			var shade = randf() * 0.1
			img.set_pixel(x, y, Color(0.4 + shade, 0.25 + shade, 0.1))
	
	# Leaves (layered circles for depth)
	_draw_tree_leaves(img, 16, 18, 14, Color(0.15, 0.45, 0.1))
	_draw_tree_leaves(img, 14, 14, 10, Color(0.2, 0.5, 0.15))
	_draw_tree_leaves(img, 18, 12, 8, Color(0.25, 0.55, 0.2))
	_draw_tree_leaves(img, 16, 8, 6, Color(0.3, 0.6, 0.25))
	
	return img

func _draw_tree_leaves(img: Image, cx: int, cy: int, radius: int, color: Color) -> void:
	for x in range(cx - radius, cx + radius + 1):
		for y in range(cy - radius, cy + radius + 1):
			var dist = Vector2(x - cx, y - cy).length()
			if dist < radius:
				if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
					var shade = randf() * 0.08
					img.set_pixel(x, y, Color(color.r + shade, color.g + shade, color.b + shade))

func _create_stone_image() -> Image:
	var img = Image.create(32, 28, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	# Main rock body
	for x in range(4, 28):
		for y in range(6, 26):
			var dist = Vector2(x - 16, y - 16).length()
			if dist < 12 + randf() * 2:
				var shade = randf() * 0.15
				img.set_pixel(x, y, Color(0.5 + shade, 0.5 + shade, 0.5 + shade))
	
	# Darker spots
	for i in range(5):
		var sx = randi_range(8, 24)
		var sy = randi_range(10, 22)
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				if sx + dx >= 0 and sx + dx < 32 and sy + dy >= 0 and sy + dy < 28:
					if img.get_pixel(sx + dx, sy + dy).a > 0:
						img.set_pixel(sx + dx, sy + dy, Color(0.35, 0.35, 0.35))
	
	return img

func _create_iron_image() -> Image:
	var img = _create_stone_image()
	
	# Add iron ore spots (orange/rust colored)
	for i in range(4):
		var sx = randi_range(8, 24)
		var sy = randi_range(10, 22)
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				if sx + dx >= 0 and sx + dx < 32 and sy + dy >= 0 and sy + dy < 28:
					if img.get_pixel(sx + dx, sy + dy).a > 0 and randf() > 0.3:
						img.set_pixel(sx + dx, sy + dy, Color(0.6, 0.4, 0.25))
	
	return img

func _create_bush_image() -> Image:
	var img = Image.create(24, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	# Bush body
	for x in range(2, 22):
		for y in range(4, 18):
			var dist = Vector2(x - 12, y - 11).length()
			if dist < 9 + randf() * 2:
				var shade = randf() * 0.1
				img.set_pixel(x, y, Color(0.2 + shade, 0.5 + shade, 0.15 + shade))
	
	# Berries
	for i in range(6):
		var bx = randi_range(5, 19)
		var by = randi_range(6, 15)
		if img.get_pixel(bx, by).a > 0:
			img.set_pixel(bx, by, Color(0.8, 0.1, 0.1))
			if bx + 1 < 24:
				img.set_pixel(bx + 1, by, Color(0.8, 0.1, 0.1))
	
	return img

func take_damage(amount: int) -> void:
	health -= amount
	_shake()
	
	if health <= 0:
		_drop_items()
		queue_free()

func _shake() -> void:
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "position", Vector2(3, 0), 0.05)
		tween.tween_property(sprite, "position", Vector2(-3, 0), 0.05)
		tween.tween_property(sprite, "position", Vector2(2, 0), 0.04)
		tween.tween_property(sprite, "position", Vector2(-2, 0), 0.04)
		tween.tween_property(sprite, "position", Vector2.ZERO, 0.03)

func _drop_items() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager == null:
		return
	
	for drop in drops:
		var qty = randi_range(drop["min"], drop["max"])
		if qty > 0:
			game_manager.spawn_dropped_item(drop["item_id"], qty, global_position)

func interact(player: Player) -> void:
	take_damage(5 + (player.base_damage / 2))
