extends CanvasLayer
class_name InventoryUI

signal item_used(slot_index: int)
signal item_dropped(slot_index: int)
signal item_equipped(slot_index: int)
signal closed

@onready var panel: Panel = $Panel
@onready var close_btn: Button = $Panel/TopBar/CloseBtn
@onready var grid: GridContainer = $Panel/Content/ScrollContainer/GridContainer
@onready var item_info_panel: Panel = $Panel/Content/ItemInfo
@onready var item_name_label: Label = $Panel/Content/ItemInfo/VBox/ItemName
@onready var item_desc_label: Label = $Panel/Content/ItemInfo/VBox/ItemDesc
@onready var use_btn: Button = $Panel/Content/ItemInfo/VBox/Buttons/UseBtn
@onready var drop_btn: Button = $Panel/Content/ItemInfo/VBox/Buttons/DropBtn
@onready var equip_btn: Button = $Panel/Content/ItemInfo/VBox/Buttons/EquipBtn

var inventory: Inventory
var slot_buttons: Array[Button] = []
var selected_slot: int = -1
var is_open: bool = false

const SLOT_SIZE = Vector2(70, 70)

func _ready() -> void:
	panel.visible = false
	close_btn.pressed.connect(_close)
	use_btn.pressed.connect(_on_use_pressed)
	drop_btn.pressed.connect(_on_drop_pressed)
	equip_btn.pressed.connect(_on_equip_pressed)
	_create_slot_buttons()
	_hide_item_info()

func _create_slot_buttons() -> void:
	for i in range(20):
		var btn = Button.new()
		btn.custom_minimum_size = SLOT_SIZE
		btn.text = ""
		btn.pressed.connect(_on_slot_pressed.bind(i))
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.2, 0.2, 0.95)
		style.border_width_bottom = 2
		style.border_width_top = 2
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_color = Color(0.4, 0.4, 0.4)
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		btn.add_theme_stylebox_override("normal", style)
		
		var hover_style = style.duplicate()
		hover_style.border_color = Color(0.6, 0.6, 0.6)
		btn.add_theme_stylebox_override("hover", hover_style)
		
		grid.add_child(btn)
		slot_buttons.append(btn)

func setup(inv: Inventory) -> void:
	inventory = inv
	inventory.inventory_changed.connect(_refresh_ui)
	_refresh_ui()

func _input(_event: InputEvent) -> void:
	pass  # Handled by main.gd

func toggle() -> void:
	is_open = !is_open
	panel.visible = is_open
	if is_open:
		_refresh_ui()
		_hide_item_info()
		selected_slot = -1

func _close() -> void:
	is_open = false
	panel.visible = false
	closed.emit()

func _refresh_ui() -> void:
	if inventory == null:
		return
	
	for i in range(slot_buttons.size()):
		var btn = slot_buttons[i]
		var item = inventory.get_item(i)
		var qty = inventory.get_quantity(i)
		
		if item != null:
			btn.text = item.name.substr(0, 5) + "\n" + str(qty)
		else:
			btn.text = ""
		
		_update_slot_style(i, i == selected_slot)

func _update_slot_style(index: int, selected: bool) -> void:
	var btn = slot_buttons[index]
	var style = btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	if selected:
		style.border_color = Color.GOLD
		style.border_width_bottom = 3
		style.border_width_top = 3
		style.border_width_left = 3
		style.border_width_right = 3
	else:
		style.border_color = Color(0.4, 0.4, 0.4)
		style.border_width_bottom = 2
		style.border_width_top = 2
		style.border_width_left = 2
		style.border_width_right = 2
	btn.add_theme_stylebox_override("normal", style)

func _on_slot_pressed(index: int) -> void:
	var old_selected = selected_slot
	selected_slot = index
	
	if old_selected >= 0:
		_update_slot_style(old_selected, false)
	_update_slot_style(index, true)
	
	_show_item_info(index)

func _show_item_info(index: int) -> void:
	var item = inventory.get_item(index)
	if item == null:
		_hide_item_info()
		return
	
	item_info_panel.visible = true
	item_name_label.text = item.name
	item_desc_label.text = item.description
	
	# Cập nhật text nút tiếng Việt
	use_btn.text = "Sử Dụng"
	drop_btn.text = "Vứt Bỏ"
	equip_btn.text = "Trang Bị"
	
	# Show relevant buttons
	use_btn.visible = item.is_usable
	equip_btn.visible = item.is_equippable
	drop_btn.visible = true

func _hide_item_info() -> void:
	item_info_panel.visible = false

func _on_use_pressed() -> void:
	if selected_slot >= 0:
		item_used.emit(selected_slot)
		_refresh_ui()
		_hide_item_info()

func _on_drop_pressed() -> void:
	if selected_slot >= 0:
		item_dropped.emit(selected_slot)
		_refresh_ui()
		_hide_item_info()

func _on_equip_pressed() -> void:
	if selected_slot >= 0:
		item_equipped.emit(selected_slot)
		_close()
