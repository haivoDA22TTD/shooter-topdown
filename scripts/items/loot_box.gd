extends Area2D
class_name LootBox

enum BoxType { COMMON, RARE, MILITARY }

@export var box_type: BoxType = BoxType.COMMON

var is_opened: bool = false
var sprite: Sprite2D
var interaction_label: Label

# Loot tables
var common_loot = [
	{"item_id": "wooden_spear", "chance": 0.4},
	{"item_id": "bandage", "chance": 0.5},
	{"item_id": "berries", "chance": 0.6, "qty_min": 2, "qty_max": 5}
]

var rare_loot = [
	{"item_id": "pistol", "chance": 0.3},
	{"item_id": "knife", "chance": 0.4},
	{"item_id": "ammo_pistol", "chance": 0.5, "qty_min": 5, "qty_max": 15},
	{"item_id": "bandage", "chance": 0.4, "qty_min": 2, "qty_max": 4}
]

var military_loot = [
	{"item_id": "rifle", "chance": 0.25},
	{"item_id": "shotgun", "chance": 0.2},
	{"item_id": "pistol", "chance": 0.4},
	{"item_id": "ammo_rifle", "chance": 0.5, "qty_min": 10, "qty_max": 30},
	{"item_id": "ammo_shotgun", "chance": 0.4, "qty_min": 5, "qty_max": 12},
	{"item_id": "armor_vest", "chance": 0.15}
]

func _ready() -> void:
	# Layer 3 = Interactable, Mask 1 = Player
	collision_layer = 4  # Layer 3 (Interactable)
	collision_mask = 1   # Mask 1 (Player)
	monitoring = true
	monitorable = true
	_create_sprite()
	_create_label()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _create_sprite() -> void:
	sprite = Sprite2D.new()
	var img = Image.create(24, 20, false, Image.FORMAT_RGBA8)
	
	var box_color: Color
	var trim_color: Color
	match box_type:
		BoxType.COMMON:
			box_color = Color(0.5, 0.4, 0.25)
			trim_color = Color(0.4, 0.3, 0.15)
		BoxType.RARE:
			box_color = Color(0.3, 0.4, 0.6)
			trim_color = Color(0.5, 0.6, 0.8)
		BoxType.MILITARY:
			box_color = Color(0.3, 0.35, 0.25)
			trim_color = Color(0.5, 0.55, 0.3)
	
	# Draw box
	for x in range(2, 22):
		for y in range(4, 18):
			img.set_pixel(x, y, box_color)
	
	# Draw lid
	for x in range(1, 23):
		for y in range(2, 6):
			img.set_pixel(x, y, trim_color)
	
	# Draw lock/clasp
	for x in range(10, 14):
		for y in range(6, 10):
			img.set_pixel(x, y, Color(0.7, 0.6, 0.2))
	
	sprite.texture = ImageTexture.create_from_image(img)
	sprite.scale = Vector2(2, 2)
	add_child(sprite)

func _create_label() -> void:
	interaction_label = Label.new()
	var box_name = ""
	match box_type:
		BoxType.COMMON: box_name = "Thường"
		BoxType.RARE: box_name = "Hiếm"
		BoxType.MILITARY: box_name = "Quân Sự"
	interaction_label.text = "[E] Mở Hộp " + box_name
	interaction_label.position = Vector2(-40, -50)
	interaction_label.visible = false
	interaction_label.add_theme_font_size_override("font_size", 12)
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
	_give_loot(player)

func _open_animation() -> void:
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(2.2, 1.6), 0.1)
	tween.tween_property(sprite, "scale", Vector2(2, 2), 0.1)
	tween.tween_property(sprite, "modulate", Color(0.5, 0.5, 0.5), 0.3)

func _give_loot(player: Player) -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager == null:
		return
	
	var loot_table: Array
	match box_type:
		BoxType.COMMON: loot_table = common_loot
		BoxType.RARE: loot_table = rare_loot
		BoxType.MILITARY: loot_table = military_loot
	
	for loot in loot_table:
		if randf() <= loot["chance"]:
			var qty = 1
			if loot.has("qty_min"):
				qty = randi_range(loot["qty_min"], loot["qty_max"])
			game_manager.spawn_dropped_item(loot["item_id"], qty, global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20)))
