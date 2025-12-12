extends CanvasLayer
class_name HUD

# Top left - Status bars with icons
@onready var health_bar: ProgressBar = $TopLeft/VBox/HealthBar
@onready var hunger_bar: ProgressBar = $TopLeft/VBox/HungerBar
@onready var thirst_bar: ProgressBar = $TopLeft/VBox/ThirstBar

# Bottom - Hotbar
@onready var hotbar: HBoxContainer = $Bottom/Hotbar

# Right side - Action buttons
@onready var inventory_btn: Button = $RightButtons/InventoryBtn
@onready var crafting_btn: Button = $RightButtons/CraftingBtn
@onready var build_btn: Button = $RightButtons/BuildBtn

# Bottom left - Virtual joystick
@onready var joystick_outer: Panel = $BottomLeft/JoystickOuter
@onready var joystick_inner: Panel = $BottomLeft/JoystickOuter/JoystickInner

# Bottom right - Action buttons
@onready var attack_btn: Button = $BottomRight/AttackBtn
@onready var interact_btn: Button = $BottomRight/InteractBtn

# Zone indicator
@onready var zone_label: Label = $TopRight/ZoneLabel

# Weapon display
var weapon_panel: Panel
var weapon_icon: Sprite2D
var weapon_name_label: Label
var ammo_label: Label
var magazine_label: Label

var player: Player
var current_weapon: WeaponData = null
var joystick_active: bool = false
var joystick_vector: Vector2 = Vector2.ZERO
var joystick_radius: float = 50.0

var hotbar_slots: Array[Panel] = []
var selected_hotbar_slot: int = 0
var equipped_items: Array = []  # Danh sách vũ khí đã trang bị (tối đa 6)

signal joystick_input(direction: Vector2)
signal attack_pressed
signal interact_pressed
signal inventory_pressed
signal crafting_pressed
signal build_pressed
signal hotbar_slot_selected(index: int)

func _ready() -> void:
	_style_bars()
	_style_joystick()
	_style_buttons()
	_setup_hotbar()
	_connect_buttons()
	_setup_weapon_display()
	_localize_ui()

func _style_bars() -> void:
	# Health bar - Red with gradient look
	var hp_fill = StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.85, 0.15, 0.15)
	hp_fill.corner_radius_top_left = 6
	hp_fill.corner_radius_top_right = 6
	hp_fill.corner_radius_bottom_left = 6
	hp_fill.corner_radius_bottom_right = 6
	hp_fill.border_width_top = 1
	hp_fill.border_color = Color(1, 0.3, 0.3)
	health_bar.add_theme_stylebox_override("fill", hp_fill)
	
	var hp_bg = StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.15, 0.08, 0.08, 0.9)
	hp_bg.corner_radius_top_left = 6
	hp_bg.corner_radius_top_right = 6
	hp_bg.corner_radius_bottom_left = 6
	hp_bg.corner_radius_bottom_right = 6
	hp_bg.border_width_bottom = 1
	hp_bg.border_width_top = 1
	hp_bg.border_width_left = 1
	hp_bg.border_width_right = 1
	hp_bg.border_color = Color(0.3, 0.15, 0.15)
	health_bar.add_theme_stylebox_override("background", hp_bg)
	
	# Hunger bar - Orange
	var hunger_fill = StyleBoxFlat.new()
	hunger_fill.bg_color = Color(0.9, 0.55, 0.1)
	hunger_fill.corner_radius_top_left = 6
	hunger_fill.corner_radius_top_right = 6
	hunger_fill.corner_radius_bottom_left = 6
	hunger_fill.corner_radius_bottom_right = 6
	hunger_bar.add_theme_stylebox_override("fill", hunger_fill)
	
	var hunger_bg = StyleBoxFlat.new()
	hunger_bg.bg_color = Color(0.15, 0.1, 0.05, 0.9)
	hunger_bg.corner_radius_top_left = 6
	hunger_bg.corner_radius_top_right = 6
	hunger_bg.corner_radius_bottom_left = 6
	hunger_bg.corner_radius_bottom_right = 6
	hunger_bg.border_width_bottom = 1
	hunger_bg.border_width_top = 1
	hunger_bg.border_width_left = 1
	hunger_bg.border_width_right = 1
	hunger_bg.border_color = Color(0.3, 0.2, 0.1)
	hunger_bar.add_theme_stylebox_override("background", hunger_bg)
	
	# Thirst bar - Blue
	var thirst_fill = StyleBoxFlat.new()
	thirst_fill.bg_color = Color(0.2, 0.5, 0.9)
	thirst_fill.corner_radius_top_left = 6
	thirst_fill.corner_radius_top_right = 6
	thirst_fill.corner_radius_bottom_left = 6
	thirst_fill.corner_radius_bottom_right = 6
	thirst_bar.add_theme_stylebox_override("fill", thirst_fill)
	
	var thirst_bg = StyleBoxFlat.new()
	thirst_bg.bg_color = Color(0.05, 0.1, 0.15, 0.9)
	thirst_bg.corner_radius_top_left = 6
	thirst_bg.corner_radius_top_right = 6
	thirst_bg.corner_radius_bottom_left = 6
	thirst_bg.corner_radius_bottom_right = 6
	thirst_bg.border_width_bottom = 1
	thirst_bg.border_width_top = 1
	thirst_bg.border_width_left = 1
	thirst_bg.border_width_right = 1
	thirst_bg.border_color = Color(0.1, 0.2, 0.3)
	thirst_bar.add_theme_stylebox_override("background", thirst_bg)

func _style_joystick() -> void:
	var outer_style = StyleBoxFlat.new()
	outer_style.bg_color = Color(0.15, 0.15, 0.15, 0.6)
	outer_style.corner_radius_top_left = 65
	outer_style.corner_radius_top_right = 65
	outer_style.corner_radius_bottom_left = 65
	outer_style.corner_radius_bottom_right = 65
	outer_style.border_width_bottom = 2
	outer_style.border_width_top = 2
	outer_style.border_width_left = 2
	outer_style.border_width_right = 2
	outer_style.border_color = Color(0.3, 0.3, 0.3, 0.8)
	joystick_outer.add_theme_stylebox_override("panel", outer_style)
	
	var inner_style = StyleBoxFlat.new()
	inner_style.bg_color = Color(0.4, 0.4, 0.4, 0.9)
	inner_style.corner_radius_top_left = 25
	inner_style.corner_radius_top_right = 25
	inner_style.corner_radius_bottom_left = 25
	inner_style.corner_radius_bottom_right = 25
	joystick_inner.add_theme_stylebox_override("panel", inner_style)

func _style_buttons() -> void:
	var buttons = [inventory_btn, crafting_btn, build_btn, attack_btn, interact_btn]
	for btn in buttons:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.18, 0.18, 0.18, 0.9)
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		style.border_width_bottom = 2
		style.border_width_top = 2
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_color = Color(0.35, 0.35, 0.35)
		btn.add_theme_stylebox_override("normal", style)
		
		var hover = style.duplicate()
		hover.bg_color = Color(0.25, 0.25, 0.25, 0.95)
		hover.border_color = Color(0.5, 0.5, 0.5)
		btn.add_theme_stylebox_override("hover", hover)
		
		var pressed = style.duplicate()
		pressed.bg_color = Color(0.12, 0.12, 0.12, 0.95)
		btn.add_theme_stylebox_override("pressed", pressed)

func _setup_hotbar() -> void:
	for i in range(6):
		var slot = Panel.new()
		slot.custom_minimum_size = Vector2(58, 58)
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.12, 0.12, 0.92)
		style.border_width_bottom = 2
		style.border_width_top = 2
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_color = Color(0.35, 0.35, 0.35)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		slot.add_theme_stylebox_override("panel", style)
		
		# Item icon placeholder
		var icon_rect = ColorRect.new()
		icon_rect.name = "IconRect"
		icon_rect.color = Color.TRANSPARENT
		icon_rect.custom_minimum_size = Vector2(40, 40)
		icon_rect.position = Vector2(9, 5)
		slot.add_child(icon_rect)
		
		var label = Label.new()
		label.name = "ItemLabel"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		label.anchors_preset = Control.PRESET_FULL_RECT
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		slot.add_child(label)
		
		var qty_label = Label.new()
		qty_label.name = "QtyLabel"
		qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		qty_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		qty_label.anchors_preset = Control.PRESET_FULL_RECT
		qty_label.add_theme_font_size_override("font_size", 11)
		qty_label.add_theme_color_override("font_color", Color.WHITE)
		slot.add_child(qty_label)
		
		# Key hint
		var key_label = Label.new()
		key_label.name = "KeyLabel"
		key_label.text = str(i + 1)
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		key_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		key_label.position = Vector2(3, 0)
		key_label.add_theme_font_size_override("font_size", 9)
		key_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		slot.add_child(key_label)
		
		var btn = Button.new()
		btn.name = "SlotBtn"
		btn.anchors_preset = Control.PRESET_FULL_RECT
		btn.flat = true
		btn.pressed.connect(_on_hotbar_slot_pressed.bind(i))
		slot.add_child(btn)
		
		hotbar.add_child(slot)
		hotbar_slots.append(slot)
	
	_highlight_hotbar_slot(0)

func _connect_buttons() -> void:
	inventory_btn.pressed.connect(func(): inventory_pressed.emit())
	crafting_btn.pressed.connect(func(): crafting_pressed.emit())
	build_btn.pressed.connect(func(): build_pressed.emit())
	attack_btn.button_down.connect(func(): attack_pressed.emit())
	interact_btn.pressed.connect(func(): interact_pressed.emit())

func setup(p: Player) -> void:
	player = p
	player.health_changed.connect(_on_health_changed)
	player.hunger_changed.connect(_on_hunger_changed)
	player.thirst_changed.connect(_on_thirst_changed)
	player.weapon_changed.connect(_on_weapon_changed)

func _on_weapon_changed(weapon: WeaponData) -> void:
	update_weapon_display(weapon)

func _on_health_changed(current: int, max_val: int) -> void:
	health_bar.max_value = max_val
	health_bar.value = current

func _on_hunger_changed(current: int, max_val: int) -> void:
	hunger_bar.max_value = max_val
	hunger_bar.value = current

func _on_thirst_changed(current: int, max_val: int) -> void:
	thirst_bar.max_value = max_val
	thirst_bar.value = current

func _input(event: InputEvent) -> void:
	_handle_joystick(event)
	
	if event is InputEventKey and event.pressed:
		for i in range(6):
			if event.keycode == KEY_1 + i:
				select_hotbar_slot(i)
				break

func _handle_joystick(event: InputEvent) -> void:
	var joystick_center = joystick_outer.global_position + joystick_outer.size / 2
	
	if event is InputEventScreenTouch:
		if event.pressed:
			var dist = event.position.distance_to(joystick_center)
			if dist < 80:
				joystick_active = true
		else:
			if joystick_active:
				joystick_active = false
				joystick_inner.position = joystick_outer.size / 2 - joystick_inner.size / 2
				joystick_vector = Vector2.ZERO
				joystick_input.emit(joystick_vector)
	
	if event is InputEventScreenDrag and joystick_active:
		var diff = event.position - joystick_center
		if diff.length() > joystick_radius:
			diff = diff.normalized() * joystick_radius
		joystick_inner.position = joystick_outer.size / 2 - joystick_inner.size / 2 + diff
		joystick_vector = diff / joystick_radius
		joystick_input.emit(joystick_vector)

func _on_hotbar_slot_pressed(index: int) -> void:
	select_hotbar_slot(index)

func select_hotbar_slot(index: int) -> void:
	_highlight_hotbar_slot(index)
	selected_hotbar_slot = index
	hotbar_slot_selected.emit(index)

func _highlight_hotbar_slot(index: int) -> void:
	for i in range(hotbar_slots.size()):
		var slot = hotbar_slots[i]
		var style = slot.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if i == index:
			style.border_color = Color(0.95, 0.75, 0.2)
			style.border_width_bottom = 3
			style.border_width_top = 3
			style.border_width_left = 3
			style.border_width_right = 3
		else:
			style.border_color = Color(0.35, 0.35, 0.35)
			style.border_width_bottom = 2
			style.border_width_top = 2
			style.border_width_left = 2
			style.border_width_right = 2
		slot.add_theme_stylebox_override("panel", style)

func update_hotbar(inventory: Inventory) -> void:
	# Hotbar chỉ hiển thị vũ khí đã trang bị, không phải inventory
	_refresh_equipped_display()

func _refresh_equipped_display() -> void:
	for i in range(hotbar_slots.size()):
		var slot = hotbar_slots[i]
		var item_label = slot.get_node("ItemLabel") as Label
		var qty_label = slot.get_node("QtyLabel") as Label
		var icon_rect = slot.get_node("IconRect") as ColorRect
		
		if i < equipped_items.size() and equipped_items[i] != null:
			var item = equipped_items[i]
			if item is Item:
				item_label.text = item.name.substr(0, 6)
				qty_label.text = ""
				icon_rect.color = Color(0.6, 0.6, 0.6, 0.6)  # Weapon color
			elif item is WeaponData:
				item_label.text = item.name_vi.substr(0, 6)
				qty_label.text = ""
				icon_rect.color = Color(0.7, 0.5, 0.3, 0.6)  # Gun color
		else:
			item_label.text = ""
			qty_label.text = ""
			icon_rect.color = Color.TRANSPARENT

func add_equipped_item(item) -> int:
	# Thêm vũ khí vào hotbar, trả về slot index
	for i in range(6):
		if i >= equipped_items.size():
			equipped_items.append(item)
			_refresh_equipped_display()
			return i
		elif equipped_items[i] == null:
			equipped_items[i] = item
			_refresh_equipped_display()
			return i
	# Hotbar đầy, thay thế slot đầu tiên
	equipped_items[0] = item
	_refresh_equipped_display()
	return 0

func remove_equipped_item(slot_index: int) -> void:
	if slot_index >= 0 and slot_index < equipped_items.size():
		equipped_items[slot_index] = null
		_refresh_equipped_display()

func update_zone(zone_name: String) -> void:
	if zone_label:
		zone_label.text = zone_name

func update_ammo(ammo_type: String, amount: int) -> void:
	# Update ammo display if we have one
	pass

func update_weapon(weapon_name: String) -> void:
	# Update current weapon display
	pass

func _setup_weapon_display() -> void:
	# Panel chứa thông tin súng
	weapon_panel = Panel.new()
	weapon_panel.name = "WeaponPanel"
	weapon_panel.custom_minimum_size = Vector2(180, 70)
	weapon_panel.visible = false
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.1, 0.85)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.border_width_bottom = 2
	panel_style.border_width_top = 2
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_color = Color(0.4, 0.35, 0.2)
	weapon_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Vị trí góc dưới phải, trên nút attack
	weapon_panel.anchor_left = 1.0
	weapon_panel.anchor_right = 1.0
	weapon_panel.anchor_top = 1.0
	weapon_panel.anchor_bottom = 1.0
	weapon_panel.offset_left = -195
	weapon_panel.offset_right = -15
	weapon_panel.offset_top = -175
	weapon_panel.offset_bottom = -105
	
	add_child(weapon_panel)
	
	# Tên súng
	weapon_name_label = Label.new()
	weapon_name_label.name = "WeaponName"
	weapon_name_label.text = "Súng Lục"
	weapon_name_label.position = Vector2(10, 5)
	weapon_name_label.add_theme_font_size_override("font_size", 14)
	weapon_name_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	weapon_panel.add_child(weapon_name_label)
	
	# Đạn trong băng
	magazine_label = Label.new()
	magazine_label.name = "MagazineLabel"
	magazine_label.text = "12 / 12"
	magazine_label.position = Vector2(10, 28)
	magazine_label.add_theme_font_size_override("font_size", 18)
	magazine_label.add_theme_color_override("font_color", Color.WHITE)
	weapon_panel.add_child(magazine_label)
	
	# Tổng đạn dự trữ
	ammo_label = Label.new()
	ammo_label.name = "AmmoLabel"
	ammo_label.text = "Dự trữ: 0"
	ammo_label.position = Vector2(10, 50)
	ammo_label.add_theme_font_size_override("font_size", 11)
	ammo_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	weapon_panel.add_child(ammo_label)
	
	# Phím reload
	var reload_hint = Label.new()
	reload_hint.text = "[R] Nạp đạn"
	reload_hint.position = Vector2(100, 50)
	reload_hint.add_theme_font_size_override("font_size", 10)
	reload_hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	weapon_panel.add_child(reload_hint)

func _localize_ui() -> void:
	# Cập nhật text tiếng Việt cho các nút
	if inventory_btn:
		inventory_btn.text = "B\nTÚI ĐỒ"
	if crafting_btn:
		crafting_btn.text = "C\nCHẾ TẠO"
	if build_btn:
		build_btn.text = "TAB\nXÂY"
	if attack_btn:
		attack_btn.text = "SPACE\nTẤN CÔNG"
	if interact_btn:
		interact_btn.text = "E\nTƯƠNG TÁC"

func update_weapon_display(weapon: WeaponData) -> void:
	current_weapon = weapon
	if weapon == null:
		weapon_panel.visible = false
		return
	
	weapon_panel.visible = true
	weapon_name_label.text = weapon.name_vi
	
	if player:
		magazine_label.text = str(player.current_magazine) + " / " + str(weapon.magazine_size)
		var ammo_type = _get_weapon_ammo_type(weapon)
		ammo_label.text = "Dự trữ: " + str(player.ammo[ammo_type])

func _get_weapon_ammo_type(weapon: WeaponData) -> String:
	match weapon.weapon_type:
		WeaponData.WeaponType.PISTOL, WeaponData.WeaponType.SMG:
			return "pistol"
		WeaponData.WeaponType.RIFLE, WeaponData.WeaponType.SNIPER:
			return "rifle"
		WeaponData.WeaponType.SHOTGUN:
			return "shotgun"
	return "pistol"

func _process(_delta: float) -> void:
	# Cập nhật hiển thị đạn liên tục
	if current_weapon and player and weapon_panel.visible:
		magazine_label.text = str(player.current_magazine) + " / " + str(current_weapon.magazine_size)
		var ammo_type = _get_weapon_ammo_type(current_weapon)
		ammo_label.text = "Dự trữ: " + str(player.ammo[ammo_type])
		
		# Đổi màu khi hết đạn
		if player.current_magazine <= 0:
			magazine_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		elif player.current_magazine <= current_weapon.magazine_size * 0.3:
			magazine_label.add_theme_color_override("font_color", Color(1, 0.7, 0.3))
		else:
			magazine_label.add_theme_color_override("font_color", Color.WHITE)

func set_equipped_slot(slot_index: int) -> void:
	# Highlight slot được trang bị với màu đặc biệt
	for i in range(hotbar_slots.size()):
		var slot = hotbar_slots[i]
		var style = slot.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if i == slot_index:
			# Slot được trang bị - viền xanh lá
			style.border_color = Color(0.3, 0.9, 0.4)
			style.border_width_bottom = 3
			style.border_width_top = 3
			style.border_width_left = 3
			style.border_width_right = 3
			style.bg_color = Color(0.15, 0.25, 0.15, 0.95)
		elif i == selected_hotbar_slot:
			# Slot được chọn - viền vàng
			style.border_color = Color(0.95, 0.75, 0.2)
			style.border_width_bottom = 3
			style.border_width_top = 3
			style.border_width_left = 3
			style.border_width_right = 3
			style.bg_color = Color(0.12, 0.12, 0.12, 0.92)
		else:
			style.border_color = Color(0.35, 0.35, 0.35)
			style.border_width_bottom = 2
			style.border_width_top = 2
			style.border_width_left = 2
			style.border_width_right = 2
			style.bg_color = Color(0.12, 0.12, 0.12, 0.92)
		slot.add_theme_stylebox_override("panel", style)
