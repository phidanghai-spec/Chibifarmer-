extends Node2D
class_name FishingSpot

enum SpotState {
	READY,
	COOLDOWN
}

@export var spot_size: Vector2 = Vector2(380.0, 420.0)

var state: SpotState = SpotState.READY
var finish_timestamp: int = 0
var instance_id: int = 0
var grid_pos: Vector2i = Vector2i(23, 22)

# Fishing click detection rectangle covering the Fishing Hut and water bank in front of it
var fishing_rect: Rect2 = Rect2(Vector2(730.0, 675.0), Vector2(140.0, 115.0))

var _label_status: Label
var _area_click: Area2D
var _minigame: FishingMinigame
var _hut_sprite: Sprite2D
var _hut_shadow: Sprite2D

# River ribbon segment quads (drawn statically once)
var _grass_border_quads: Array[PackedVector2Array] = []
var _sand_quads: Array[PackedVector2Array] = []
var _water_quads: Array[PackedVector2Array] = []
var _deep_water_quads: Array[PackedVector2Array] = []

static func get_river_center_x(y: float) -> float:
	var base_x: float = 920.0
	var wave1: float = sin((y + 120.0) * 0.0030) * 60.0
	var wave2: float = cos((y + 120.0) * 0.0065) * 22.0
	return base_x + wave1 - wave2

static func is_in_water_or_sand(pos: Vector2) -> bool:
	# Wooden river bridge spans across at y = 636..684, x = 820..1080
	if pos.y >= 636.0 and pos.y <= 684.0 and pos.x >= 820.0 and pos.x <= 1080.0:
		return false
	var rx: float = get_river_center_x(pos.y)
	return absf(pos.x - rx) <= 108.0 and pos.y >= -100.0 and pos.y <= 1400.0

func _ready() -> void:
	y_sort_enabled = true
	set_process(false) # Tắt hoàn toàn _process để triệt tiêu redraw liên tục, chống giật lag
	_generate_river_geometry()

	# 1. Fishing Hut (Nhà Câu Cá Mái Xanh có Thùng Gỗ)
	# Đặt sát mép bờ Tây phía Nam cầu gỗ, quay mặt tiền hướng ra sông (flip_h = true)
	var hut_pos: Vector2 = Vector2(790.0, 745.0)

	_hut_shadow = Sprite2D.new()
	_hut_shadow.texture = _create_ellipse_texture(Vector2(84.0, 34.0))
	_hut_shadow.position = hut_pos + Vector2(0.0, 32.0)
	_hut_shadow.z_index = 0
	add_child(_hut_shadow)

	_hut_sprite = Sprite2D.new()
	var hut_tex: Texture2D = SpriteAtlasManager.get_texture("fishing_hut")
	if hut_tex != null:
		_hut_sprite.texture = hut_tex
		SpriteAtlasManager.set_sprite_pixel_size(_hut_sprite, Vector2(96.0, 96.0))
	_hut_sprite.flip_h = true # Hướng cửa và mặt tiền thẳng ra dòng sông
	_hut_sprite.position = hut_pos
	_hut_sprite.z_index = 1
	add_child(_hut_sprite)

	# 2. Status Label directly above the roof of the Fishing Hut (không đè lên cầu gỗ)
	_label_status = Label.new()
	_label_status.text = "🎣 BẤM CÂU CÁ"
	_label_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label_status.clip_text = false
	_label_status.position = Vector2(hut_pos.x - 70.0, hut_pos.y - 70.0)
	_label_status.size = Vector2(140.0, 24.0)
	_label_status.z_index = 25
	_label_status.add_theme_font_size_override("font_size", 12)
	_label_status.add_theme_color_override("font_color", Color(1.0, 0.95, 0.2))
	_label_status.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.02, 1.0))
	_label_status.add_theme_constant_override("outline_size", 5)
	add_child(_label_status)

	# 3. Click detection Area for the Fishing Hut & Pier
	_area_click = Area2D.new()
	var col: CollisionShape2D = CollisionShape2D.new()
	var rect_shape: RectangleShape2D = RectangleShape2D.new()
	rect_shape.size = fishing_rect.size
	col.shape = rect_shape
	col.position = fishing_rect.position + fishing_rect.size * 0.5
	_area_click.add_child(col)
	_area_click.input_event.connect(_on_area_input_event)
	add_child(_area_click)

	# 4. Popup Fishing Minigame
	_minigame = FishingMinigame.new()
	_minigame.minigame_finished.connect(_on_minigame_finished)
	add_child(_minigame)

	EventBus.second_ticked.connect(_on_second_ticked)

func _create_ellipse_texture(size: Vector2) -> ImageTexture:
	var img: Image = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	var cx: float = float(img.get_width()) * 0.5
	var cy: float = float(img.get_height()) * 0.5
	var shadow_color: Color = Color(0.18, 0.24, 0.14, 0.28)
	for x: int in range(img.get_width()):
		for y: int in range(img.get_height()):
			var dx: float = (float(x) - cx) / cx
			var dy: float = (float(y) - cy) / cy
			var dist_sq: float = dx * dx + dy * dy
			if dist_sq <= 1.0:
				var alpha: float = (1.0 - dist_sq) * shadow_color.a
				img.set_pixel(x, y, Color(shadow_color.r, shadow_color.g, shadow_color.b, alpha))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)

func _generate_river_geometry() -> void:
	_grass_border_quads.clear()
	_sand_quads.clear()
	_water_quads.clear()
	_deep_water_quads.clear()

	_grass_border_quads = _build_ribbon_quads(116.0) # 232px lush dark green riverbank fringe
	_sand_quads = _build_ribbon_quads(105.0)         # 210px warm sand/pebble border
	_water_quads = _build_ribbon_quads(88.0)          # 176px shallow turquoise water
	_deep_water_quads = _build_ribbon_quads(52.0)     # 104px deep blue center stream

func _build_ribbon_quads(half_width: float) -> Array[PackedVector2Array]:
	var quads: Array[PackedVector2Array] = []
	var y_start: float = -120.0
	var y_end: float = 1380.0
	var step: float = 24.0

	var prev_left: Vector2 = Vector2.ZERO
	var prev_right: Vector2 = Vector2.ZERO
	var has_prev: bool = false

	var y: float = y_start
	while y <= y_end + step * 0.5:
		var cx: float = get_river_center_x(y)
		var dx: float = (get_river_center_x(y + 1.0) - get_river_center_x(y - 1.0)) * 0.5
		var dy: float = 1.0
		var length: float = sqrt(dx * dx + dy * dy)
		var nx: float = -dy / length
		var ny: float = dx / length

		var cur_left: Vector2 = Vector2(cx - nx * half_width, y - ny * half_width)
		var cur_right: Vector2 = Vector2(cx + nx * half_width, y + ny * half_width)

		if has_prev:
			var quad: PackedVector2Array = PackedVector2Array([prev_left, cur_left, cur_right, prev_right])
			quads.append(quad)

		prev_left = cur_left
		prev_right = cur_right
		has_prev = true
		y += step

	return quads

func get_fish_count() -> int:
	return 0

func _on_second_ticked(_current_unix: int) -> void:
	if state == SpotState.COOLDOWN:
		if TickManager.is_finished(finish_timestamp):
			state = SpotState.READY
			_label_status.text = "🎣 BẤM CÂU CÁ"
			_label_status.add_theme_color_override("font_color", Color(1.0, 0.95, 0.2))
		else:
			var remaining: int = TickManager.get_time_remaining(finish_timestamp)
			_label_status.text = "⏳ HỒI: 00:%02d" % maxi(0, remaining)
			_label_status.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.is_pressed():
			var mpos: Vector2 = get_global_mouse_position()
			if fishing_rect.has_point(mpos):
				if handle_fishing_click():
					get_viewport().set_input_as_handled()

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.is_pressed():
			handle_fishing_click()

func handle_fishing_click() -> bool:
	if state != SpotState.READY:
		print("[FishingSpot] Bãi câu đang trong thời gian hồi!")
		return false

	if _minigame != null:
		_minigame.open_minigame("fish_carp", Vector2(768.0, 750.0))
		return true

	_complete_catch()
	return true

func _on_minigame_finished(success: bool, _fish_id: String) -> void:
	if success:
		_start_cooldown()

func _complete_catch() -> void:
	var fish_item: String = "fish_carp"
	if not StorageManager.can_store_item(fish_item, 1):
		if not StorageManager.can_store_item("fish", 1):
			print("[FishingSpot] Kho Barn đã đầy, không thể chứa thêm cá!")
			return
		fish_item = "fish"

	StorageManager.add_item(fish_item, 1)
	StorageManager.add_gold(20)
	StorageManager.add_xp(5)
	EventBus.loot_collected.emit(fish_item, 1, Vector2(768.0, 750.0))
	EventBus.loot_collected.emit("gold", 20, Vector2(768.0, 750.0))
	_start_cooldown()

func _start_cooldown() -> void:
	state = SpotState.COOLDOWN
	finish_timestamp = TickManager.calculate_finish_timestamp(7)
	_label_status.text = "⏳ HỒI: 00:07"
	_label_status.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))

	if _hut_sprite != null:
		var base_scale: Vector2 = _hut_sprite.scale
		var tw: Tween = create_tween()
		tw.tween_property(_hut_sprite, "scale", base_scale * Vector2(1.08, 0.92), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(_hut_sprite, "scale", base_scale, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func get_minigame() -> FishingMinigame:
	return _minigame

func _draw() -> void:
	# ====================================================================
	# 1. DÒNG SÔNG VÀ BỜ CÁT VẼ TĨNH 1 LẦN (KHÔNG VẼ LẠI 60FPS)
	# ====================================================================
	# 0. Grass Edge Fringe Quads (drawn underneath sand)
	var fringe_color: Color = Color(0.36, 0.58, 0.22)
	for q: PackedVector2Array in _grass_border_quads:
		draw_colored_polygon(q, fringe_color)

	# A. Sandy Riverbank Border (Color(0.84, 0.76, 0.56))
	var sand_color: Color = Color(0.84, 0.76, 0.56)
	for q: PackedVector2Array in _sand_quads:
		draw_colored_polygon(q, sand_color)

	# B. Shallow Turquoise River Water (Color(0.28, 0.68, 0.86))
	var water_color: Color = Color(0.28, 0.68, 0.86)
	for q: PackedVector2Array in _water_quads:
		draw_colored_polygon(q, water_color)

	# C. Deep Blue Center Current (Color(0.18, 0.52, 0.78))
	var deep_color: Color = Color(0.18, 0.52, 0.78)
	for q: PackedVector2Array in _deep_water_quads:
		draw_colored_polygon(q, deep_color)

	# D. Small river pebbles along sandy border
	var pebble_base: Color = Color(0.74, 0.71, 0.62)
	var pebble_light: Color = Color(0.88, 0.86, 0.78)
	var p_step: float = 38.0
	var p_y: float = -100.0
	while p_y <= 1360.0:
		var p_cx: float = get_river_center_x(p_y)
		var p_left: Vector2 = Vector2(p_cx - 104.0, p_y)
		var p_right: Vector2 = Vector2(p_cx + 104.0, p_y + 16.0)
		draw_circle(p_left, 3.2, pebble_base)
		draw_circle(p_left + Vector2(-0.8, -0.8), 1.5, pebble_light)
		draw_circle(p_right, 3.5, pebble_base)
		draw_circle(p_right + Vector2(-0.8, -0.8), 1.6, pebble_light)
		p_y += p_step

	# E. Static Water Lilies along the river meander
	var lily_positions: Array[Vector2] = [
		Vector2(950.0, 320.0), Vector2(980.0, 360.0), Vector2(810.0, 560.0),
		Vector2(830.0, 810.0), Vector2(920.0, 1020.0), Vector2(940.0, 1060.0)
	]
	var lily_col: Color = Color(0.24, 0.62, 0.22)
	var lily_dark: Color = Color(0.18, 0.48, 0.16)
	for lp: Vector2 in lily_positions:
		draw_circle(lp, 8.5, lily_col)
		draw_arc(lp, 8.5, 0.2, TAU - 0.2, 12, lily_dark, 1.4)
	draw_circle(Vector2(950.0, 320.0), 3.0, Color(1.0, 0.55, 0.75))
	draw_circle(Vector2(810.0, 560.0), 3.0, Color(1.0, 1.0, 1.0))
	draw_circle(Vector2(920.0, 1020.0), 3.0, Color(1.0, 0.88, 0.35))

	# ====================================================================
	# 2. WOODEN RIVER BRIDGE (CẦU GỖ BẮC QUA SÔNG) AT Y = 660
	# Mặt cầu hoàn toàn sạch sẽ, không có chữ hay icon câu cá đè lên!
	# ====================================================================
	var br_x0: float = 820.0
	var br_x1: float = 1080.0
	var br_w: float = br_x1 - br_x0
	var br_y0: float = 636.0
	var br_y1: float = 684.0
	var br_h: float = br_y1 - br_y0

	var wood_base: Color = Color(0.74, 0.54, 0.34)
	var wood_dark: Color = Color(0.48, 0.32, 0.18)
	var wood_light: Color = Color(0.84, 0.66, 0.44)
	var wood_rail: Color = Color(0.52, 0.34, 0.18)

	# A. Bridge Soft Water Shadow
	draw_rect(Rect2(br_x0 + 12.0, br_y1, br_w - 24.0, 14.0), Color(0.08, 0.25, 0.42, 0.35), true)

	# B. Heavy Wooden Support Piers in the water
	var pier_piles_x: Array[float] = [br_x0 + 65.0, br_x0 + 130.0, br_x0 + 195.0]
	for px: float in pier_piles_x:
		draw_rect(Rect2(Vector2(px - 5.0, br_y0 - 2.0), Vector2(10.0, br_h + 16.0)), wood_dark, true)
		draw_circle(Vector2(px, br_y1 + 14.0), 4.5, Color(0.18, 0.42, 0.58, 0.65))

	# C. Arched Wooden Bridge Deck (Planks)
	draw_rect(Rect2(br_x0, br_y0, br_w, br_h), wood_base, true)
	draw_rect(Rect2(br_x0, br_y0, br_w, br_h), wood_dark, false, 2.0)

	# Vertical Plank Lines on Deck
	var plank_step: float = 14.0
	var cur_px: float = br_x0 + plank_step
	while cur_px < br_x1:
		draw_line(Vector2(cur_px, br_y0), Vector2(cur_px, br_y1), wood_dark, 1.5)
		draw_line(Vector2(cur_px + 1.0, br_y0), Vector2(cur_px + 1.0, br_y1), wood_light, 1.0)
		cur_px += plank_step

	# D. Handrails with Baluster Posts (Lan can gỗ) - North & South Rails
	draw_line(Vector2(br_x0, br_y0 + 2.0), Vector2(br_x1, br_y0 + 2.0), wood_rail, 3.0)
	draw_line(Vector2(br_x0, br_y0 + 6.0), Vector2(br_x1, br_y0 + 6.0), wood_rail, 1.8)
	draw_line(Vector2(br_x0, br_y1 - 2.0), Vector2(br_x1, br_y1 - 2.0), wood_rail, 3.0)
	draw_line(Vector2(br_x0, br_y1 - 6.0), Vector2(br_x1, br_y1 - 6.0), wood_rail, 1.8)

	var post_x: float = br_x0 + 6.0
	while post_x <= br_x1:
		draw_line(Vector2(post_x, br_y0 - 4.0), Vector2(post_x, br_y0 + 8.0), wood_rail, 2.8)
		draw_line(Vector2(post_x, br_y1 - 8.0), Vector2(post_x, br_y1 + 4.0), wood_rail, 2.8)
		draw_circle(Vector2(post_x, br_y0 - 4.0), 2.2, wood_light)
		draw_circle(Vector2(post_x, br_y1 + 4.0), 2.2, wood_light)
		post_x += 24.0
