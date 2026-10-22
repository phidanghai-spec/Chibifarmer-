extends CanvasLayer
class_name FishingMinigame

signal minigame_finished(success: bool, fish_id: String)

var is_active: bool = false
var fish_id: String = "fish_carp"
var spot_pos: Vector2 = Vector2(928.0, 720.0)

var _panel_modal: PanelContainer
var _meter_area: Control
var _btn_catch: Button
var _btn_close: Button
var _label_status: Label
var _needle_val: float = 0.5
var _oscillation_speed: float = 3.2
var _time_elapsed: float = 0.0

func _ready() -> void:
	layer = 30
	visible = false
	_build_ui()
	set_process(false)

func _build_ui() -> void:
	# Center at Vector2(576 - 200, 324 - 130) = Vector2(376, 194)
	_panel_modal = PanelContainer.new()
	_panel_modal.custom_minimum_size = Vector2(400, 260)
	_panel_modal.position = Vector2(376.0, 194.0)
	_panel_modal.size = Vector2(400.0, 260.0)
	add_child(_panel_modal)
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.16, 0.22, 0.96)
	style.border_color = Color(0.35, 0.78, 0.95, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(16)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 16.0
	style.content_margin_bottom = 16.0
	_panel_modal.add_theme_stylebox_override("panel", style)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_panel_modal.add_child(vbox)
	
	# 1. Header
	var lbl_title: Label = Label.new()
	lbl_title.text = "🎣 CÂU CÁ HỒ LỚN"
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.add_theme_font_size_override("font_size", 18)
	lbl_title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.2))
	lbl_title.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.1))
	lbl_title.add_theme_constant_override("outline_size", 4)
	vbox.add_child(lbl_title)
	
	_label_status = Label.new()
	_label_status.text = "Canh kim vào vùng xanh và bấm Giật Cần!"
	_label_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_status.add_theme_font_size_override("font_size", 13)
	_label_status.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
	_label_status.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.1))
	_label_status.add_theme_constant_override("outline_size", 3)
	vbox.add_child(_label_status)
	
	# 2. Moving Tempo Needle Meter Area
	_meter_area = Control.new()
	_meter_area.custom_minimum_size = Vector2(360, 48)
	_meter_area.draw.connect(_on_meter_draw)
	vbox.add_child(_meter_area)
	
	# 3. Action Buttons
	var hbox_btns: HBoxContainer = HBoxContainer.new()
	hbox_btns.add_theme_constant_override("separation", 14)
	vbox.add_child(hbox_btns)
	
	_btn_catch = Button.new()
	_btn_catch.text = "🪝 GIẬT CẦN CÂU!"
	_btn_catch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_catch.custom_minimum_size = Vector2(0, 46)
	_btn_catch.add_theme_font_size_override("font_size", 16)
	_btn_catch.pressed.connect(pull_rod)
	
	var btn_catch_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_catch_style.bg_color = Color(0.18, 0.65, 0.35)
	btn_catch_style.border_color = Color(0.7, 1.0, 0.6)
	btn_catch_style.set_border_width_all(2)
	btn_catch_style.set_corner_radius_all(10)
	_btn_catch.add_theme_stylebox_override("normal", btn_catch_style)
	
	var btn_catch_hover: StyleBoxFlat = StyleBoxFlat.new()
	btn_catch_hover.bg_color = Color(0.24, 0.78, 0.42)
	btn_catch_hover.border_color = Color(1.0, 1.0, 0.8)
	btn_catch_hover.set_border_width_all(2)
	btn_catch_hover.set_corner_radius_all(10)
	_btn_catch.add_theme_stylebox_override("hover", btn_catch_hover)
	hbox_btns.add_child(_btn_catch)
	
	_btn_close = Button.new()
	_btn_close.text = "Đóng"
	_btn_close.custom_minimum_size = Vector2(80, 46)
	_btn_close.add_theme_font_size_override("font_size", 14)
	_btn_close.pressed.connect(close_minigame)
	hbox_btns.add_child(_btn_close)

func open_minigame(p_fish_id: String = "fish_carp", p_spot_pos: Vector2 = Vector2(928.0, 720.0)) -> void:
	fish_id = p_fish_id
	spot_pos = p_spot_pos
	is_active = true
	visible = true
	_time_elapsed = 0.0
	_needle_val = 0.5
	_label_status.text = "Canh kim vào vùng xanh và bấm Giật Cần!"
	_label_status.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
	_btn_catch.disabled = false
	set_process(true)

func _process(delta: float) -> void:
	if not is_active:
		return
	_time_elapsed += delta
	# Oscillate between 0.05 and 0.95
	_needle_val = 0.5 + sin(_time_elapsed * _oscillation_speed) * 0.45
	if _meter_area != null:
		_meter_area.queue_redraw()

func pull_rod() -> void:
	if not is_active:
		return
	is_active = false
	set_process(false)
	
	# Determine catch reward
	var reward_fish: String = fish_id
	if not StorageManager.can_store_item(reward_fish, 1):
		if StorageManager.can_store_item("fish", 1):
			reward_fish = "fish"
		else:
			_label_status.text = "Kho Barn đã đầy!"
			visible = false
			minigame_finished.emit(false, reward_fish)
			return
	
	StorageManager.add_item(reward_fish, 1)
	StorageManager.add_gold(20)
	StorageManager.add_xp(5)
	
	EventBus.loot_collected.emit(reward_fish, 1, spot_pos)
	EventBus.loot_collected.emit("gold", 20, spot_pos)
	
	_label_status.text = "🎉 GIẬT ĐƯỢC CÁ CHÉP! (+1 🐟, +20🪙, +5⭐)"
	_label_status.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	_btn_catch.disabled = true
	
	visible = false
	minigame_finished.emit(true, reward_fish)

func close_minigame() -> void:
	is_active = false
	set_process(false)
	visible = false
	minigame_finished.emit(false, fish_id)

func _on_meter_draw() -> void:
	var w: float = _meter_area.size.x
	var h: float = _meter_area.size.y
	if w <= 0.0 or h <= 0.0:
		w = 360.0
		h = 48.0
	
	# 1. Outer meter background
	var bg_rect: Rect2 = Rect2(0, 8, w, h - 16)
	_meter_area.draw_rect(bg_rect, Color(0.12, 0.22, 0.30, 0.9), true)
	_meter_area.draw_rect(bg_rect, Color(0.3, 0.6, 0.8), false, 2.0)
	
	# 2. Target Sweet Spot in center (0.32 to 0.68)
	var sweet_start: float = w * 0.32
	var sweet_w: float = w * 0.36
	var sweet_rect: Rect2 = Rect2(sweet_start, 9, sweet_w, h - 18)
	_meter_area.draw_rect(sweet_rect, Color(0.18, 0.75, 0.35, 0.75), true)
	_meter_area.draw_rect(sweet_rect, Color(0.5, 1.0, 0.6, 0.95), false, 2.0)
	
	# 3. Moving Needle Indicator
	var needle_x: float = clampf(_needle_val * w, 4.0, w - 4.0)
	var needle_col: Color = Color(1.0, 0.95, 0.2)
	if _needle_val >= 0.32 and _needle_val <= 0.68:
		needle_col = Color(1.0, 1.0, 0.5)
	
	# Triangle pointer
	var p1: Vector2 = Vector2(needle_x, 4.0)
	var p2: Vector2 = Vector2(needle_x - 7.0, 14.0)
	var p3: Vector2 = Vector2(needle_x + 7.0, 14.0)
	_meter_area.draw_colored_polygon(PackedVector2Array([p1, p2, p3]), needle_col)
	_meter_area.draw_line(Vector2(needle_x, 10.0), Vector2(needle_x, h - 8.0), needle_col, 3.5)