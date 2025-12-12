extends CanvasLayer
class_name PauseMenu

signal resumed
signal quit_game

var is_open: bool = false

var panel: Panel
var title_label: Label
var resume_btn: Button
var controls_btn: Button
var quit_btn: Button
var controls_panel: Panel
var back_btn: Button

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_ui()
	visible = false
	# Đảm bảo game không bị pause khi bắt đầu
	get_tree().paused = false

func _create_ui() -> void:
	# Overlay tối
	var overlay = ColorRect.new()
	overlay.name = "Overlay"
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	# Panel chính
	panel = Panel.new()
	panel.name = "MainPanel"
	panel.custom_minimum_size = Vector2(400, 450)
	panel.anchors_preset = Control.PRESET_CENTER
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -200
	panel.offset_right = 200
	panel.offset_top = -225
	panel.offset_bottom = 225
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.12, 0.15, 0.95)
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_top_right = 15
	panel_style.corner_radius_bottom_left = 15
	panel_style.corner_radius_bottom_right = 15
	panel_style.border_width_bottom = 3
	panel_style.border_width_top = 3
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_color = Color(0.4, 0.35, 0.2)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)
	
	# VBox cho nội dung
	var vbox = VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 30
	vbox.offset_right = -30
	vbox.offset_top = 30
	vbox.offset_bottom = -30
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)
	
	# Tiêu đề
	title_label = Label.new()
	title_label.text = "TẠM DỪNG"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	vbox.add_child(title_label)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)
	
	# Nút Tiếp tục
	resume_btn = _create_button("▶ TIẾP TỤC", Color(0.2, 0.5, 0.3))
	resume_btn.pressed.connect(_on_resume)
	vbox.add_child(resume_btn)
	
	# Nút Hướng dẫn
	controls_btn = _create_button("⌨ HƯỚNG DẪN PHÍM", Color(0.3, 0.4, 0.5))
	controls_btn.pressed.connect(_show_controls)
	vbox.add_child(controls_btn)
	
	# Nút Thoát
	quit_btn = _create_button("✕ THOÁT GAME", Color(0.5, 0.2, 0.2))
	quit_btn.pressed.connect(_on_quit)
	vbox.add_child(quit_btn)
	
	# Panel hướng dẫn phím
	_create_controls_panel()

func _create_button(text: String, color: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 55)
	
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	btn.add_theme_stylebox_override("normal", style)
	
	var hover = style.duplicate()
	hover.bg_color = color.lightened(0.2)
	btn.add_theme_stylebox_override("hover", hover)
	
	var pressed = style.duplicate()
	pressed.bg_color = color.darkened(0.2)
	btn.add_theme_stylebox_override("pressed", pressed)
	
	btn.add_theme_font_size_override("font_size", 18)
	
	return btn

func _create_controls_panel() -> void:
	controls_panel = Panel.new()
	controls_panel.name = "ControlsPanel"
	controls_panel.custom_minimum_size = Vector2(450, 500)
	controls_panel.anchors_preset = Control.PRESET_CENTER
	controls_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	controls_panel.offset_left = -225
	controls_panel.offset_right = 225
	controls_panel.offset_top = -250
	controls_panel.offset_bottom = 250
	controls_panel.visible = false
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.12, 0.98)
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_top_right = 15
	panel_style.corner_radius_bottom_left = 15
	panel_style.corner_radius_bottom_right = 15
	panel_style.border_width_bottom = 3
	panel_style.border_width_top = 3
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_color = Color(0.3, 0.4, 0.5)
	controls_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(controls_panel)
	
	var vbox = VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 25
	vbox.offset_right = -25
	vbox.offset_top = 20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 8)
	controls_panel.add_child(vbox)
	
	# Tiêu đề
	var title = Label.new()
	title.text = "HƯỚNG DẪN PHÍM TẮT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.7, 0.85, 1))
	vbox.add_child(title)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	# Danh sách phím
	var controls = [
		["W A S D", "Di chuyển"],
		["SHIFT", "Chạy nhanh"],
		["SPACE / Chuột trái", "Tấn công / Bắn"],
		["E", "Tương tác / Nhặt đồ"],
		["R", "Nạp đạn"],
		["B", "Mở túi đồ"],
		["C", "Mở chế tạo"],
		["TAB", "Chế độ xây dựng"],
		["M", "Mở bản đồ"],
		["1-6", "Chọn ô nhanh"],
		["ESC", "Tạm dừng"]
	]
	
	for ctrl in controls:
		var hbox = HBoxContainer.new()
		
		var key_label = Label.new()
		key_label.text = ctrl[0]
		key_label.custom_minimum_size = Vector2(180, 0)
		key_label.add_theme_font_size_override("font_size", 14)
		key_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
		hbox.add_child(key_label)
		
		var desc_label = Label.new()
		desc_label.text = ctrl[1]
		desc_label.add_theme_font_size_override("font_size", 14)
		desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		hbox.add_child(desc_label)
		
		vbox.add_child(hbox)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	# Nút quay lại
	back_btn = _create_button("← QUAY LẠI", Color(0.3, 0.35, 0.4))
	back_btn.pressed.connect(_hide_controls)
	vbox.add_child(back_btn)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		toggle()

func toggle() -> void:
	is_open = !is_open
	visible = is_open
	controls_panel.visible = false
	panel.visible = true
	
	if is_open:
		get_tree().paused = true
	else:
		get_tree().paused = false
		resumed.emit()

func _on_resume() -> void:
	toggle()

func _show_controls() -> void:
	panel.visible = false
	controls_panel.visible = true

func _hide_controls() -> void:
	controls_panel.visible = false
	panel.visible = true

func _on_quit() -> void:
	get_tree().paused = false
	quit_game.emit()
	get_tree().quit()
