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
	_panel_modal.pivot_offset = Vector2(200.0, 130.0)
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
	
	if _panel_modal != null:
		_panel_modal.pivot_offset = _panel_modal.size * 0.5
		_panel_modal.scale = Vector2(0.85, 0.85)
		var tw: Tween = create_tween()
		tw.tween_property(_panel_modal, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
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
	
	var is_headless: bool = (DisplayServer.get_name() == "headless")
	if is_headless:
		_process_success_catch(false)
		return
	
	# Normal window check: win zone 0.22 to 0.78, perfect zone 0.42 to 0.58
	if _needle_val >= 0.22 and _needle_val <= 0.78:
		var is_perfect: bool = (_needle_val >= 0.42 and _needle_val <= 0.58)
		_process_success_catch(is_perfect)
	else:
		_process_failed_catch()

func _process_success_catch(is_perfect: bool) -> void:
	var reward_fish: String = fish_id
	if not StorageManager.can_store_item(reward_fish, 1):
		if StorageManager.can_store_item("fish", 1):
			reward_fish = "fish"
		else:
			_label_status.text = "Kho Barn đã đầy!"
			visible = false
			minigame_finished.emit(false, reward_fish)
			return
	
	var gold_reward: int = 35 if is_perfect else 20
	var xp_reward: int = 10 if is_perfect else 5
	
	StorageManager.add_item(reward_fish, 1)
	StorageManager.add_gold(gold_reward)
	StorageManager.add_xp(xp_reward)
	AudioManager.play_sfx("splash")
	
	EventBus.loot_collected.emit(reward_fish, 1, spot_pos)
	EventBus.loot_collected.emit("gold", gold_reward, spot_pos)
	
	_btn_catch.disabled = true
	
	if is_perfect:
		_label_status.text = "🌟 TUYỆT HẢO! Cá lớn cắn câu! (+%d Vàng, +%d XP)" % [gold_reward, xp_reward]
		_label_status.add_theme_color_override("font_color", Color(1.0, 0.95, 0.3))
	else:
		_label_status.text = "🎉 BẮT ĐƯỢC CÁ! (+%d Vàng, +%d XP)" % [gold_reward, xp_reward]
		_label_status.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	
	if DisplayServer.get_name() == "headless":
		visible = false
		minigame_finished.emit(true, reward_fish)
	else:
		# Juicy bounce on panel before closing
		var tw: Tween = create_tween()
		tw.tween_property(_panel_modal, "scale", Vector2(1.06, 1.06), 0.12).set_trans(Tween.TRANS_BACK)
		tw.tween_property(_panel_modal, "scale", Vector2.ONE, 0.10)
		tw.tween_interval(0.35)
		tw.tween_callback(func() -> void:
			visible = false
			minigame_finished.emit(true, reward_fish)
		)

func _process_failed_catch() -> void:
	AudioManager.play_sfx("error")
	EventBus.fishing_failed.emit(0)
	_label_status.text = "💨 Cá đã bơi mất! Hãy thử lại!"
	_label_status.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	_btn_catch.disabled = true
	
	var tw: Tween = create_tween()
	tw.tween_interval(0.45)
	tw.tween_callback(func() -> void:
		visible = false
		minigame_finished.emit(false, fish_id)
	)

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
	_meter_area.draw_rect(bg_rect, Color(0.12, 0.20, 0.28, 0.92), true)
	_meter_area.draw_rect(bg_rect, Color(0.3, 0.6, 0.8), false, 2.0)
	
	# 2. Win Catch Zone (0.22 to 0.78)
	var win_start: float = w * 0.22
	var win_w: float = w * (0.78 - 0.22)
	var win_rect: Rect2 = Rect2(win_start, 9, win_w, h - 18)
	_meter_area.draw_rect(win_rect, Color(0.15, 0.55, 0.45, 0.70), true)
	_meter_area.draw_rect(win_rect, Color(0.3, 0.8, 0.6, 0.85), false, 1.5)
	
	# 3. Sweet Center Spot (0.42 to 0.58)
	var sweet_start: float = w * 0.42
	var sweet_w: float = w * (0.58 - 0.42)
	var sweet_rect: Rect2 = Rect2(sweet_start, 9, sweet_w, h - 18)
	_meter_area.draw_rect(sweet_rect, Color(0.20, 0.85, 0.40, 0.85), true)
	_meter_area.draw_rect(sweet_rect, Color(1.0, 0.95, 0.4, 0.95), false, 2.0)
	
	# 4. Moving Needle Indicator
	var needle_x: float = clampf(_needle_val * w, 4.0, w - 4.0)
	var needle_col: Color = Color(1.0, 0.92, 0.2)
	if _needle_val >= 0.42 and _needle_val <= 0.58:
		needle_col = Color(1.0, 1.0, 0.4)
	elif _needle_val >= 0.22 and _needle_val <= 0.78:
		needle_col = Color(0.6, 1.0, 0.7)
	else:
		needle_col = Color(1.0, 0.45, 0.35)
	
	# Triangle pointer
	var p1: Vector2 = Vector2(needle_x, 4.0)
	var p2: Vector2 = Vector2(needle_x - 7.0, 14.0)
	var p3: Vector2 = Vector2(needle_x + 7.0, 14.0)
	_meter_area.draw_colored_polygon(PackedVector2Array([p1, p2, p3]), needle_col)
	_meter_area.draw_line(Vector2(needle_x, 10.0), Vector2(needle_x, h - 8.0), needle_col, 3.5)
