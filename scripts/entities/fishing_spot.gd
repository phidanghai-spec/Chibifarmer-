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
var grid_pos: Vector2i = Vector2i(24, 19)

# Expanded fishing click detection rectangle covering the river around the pier
var fishing_rect: Rect2 = Rect2(Vector2(620.0, 480.0), Vector2(380.0, 420.0))

var _label_status: Label
var _area_click: Area2D
var _minigame: FishingMinigame

# River ribbon segment quads
var _sand_quads: Array[PackedVector2Array] = []
var _water_quads: Array[PackedVector2Array] = []
var _deep_water_quads: Array[PackedVector2Array] = []

# 14 Multi-Colored Swimming Fish & Dynamic Water Ripples
var _fish_list: Array[Dictionary] = []
var _water_ripples: Array[Dictionary] = []
var _ripple_spawn_timer: float = 0.0

static func get_river_center_x(y: float) -> float:
	var base_x: float = 920.0
	var wave1: float = sin((y + 120.0) * 0.0030) * 60.0
	var wave2: float = cos((y + 120.0) * 0.0065) * 22.0
	return base_x + wave1 - wave2

func _ready() -> void:
	y_sort_enabled = true
	_generate_river_geometry()
	_init_fish_school()

	# 1. Status Label directly above the Wooden Pier (at y ~ 675, x ~ 735)
	_label_status = Label.new()
	_label_status.text = "🎣 BẤM CÂU CÁ"
	_label_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label_status.position = Vector2(780.0, 711.0)
	_label_status.size = Vector2(96.0, 22.0)
	_label_status.z_index = 25
	_label_status.add_theme_font_size_override("font_size", 12)
	_label_status.add_theme_color_override("font_color", Color(1.0, 0.95, 0.2))
	_label_status.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.02, 1.0))
	_label_status.add_theme_constant_override("outline_size", 5)
	add_child(_label_status)

	# 2. Click detection Area for the river & pier
	_area_click = Area2D.new()
	var col: CollisionShape2D = CollisionShape2D.new()
	var rect_shape: RectangleShape2D = RectangleShape2D.new()
	rect_shape.size = fishing_rect.size
	col.shape = rect_shape
	col.position = fishing_rect.position + fishing_rect.size * 0.5
	_area_click.add_child(col)
	_area_click.input_event.connect(_on_area_input_event)
	add_child(_area_click)

	# 3. Popup Fishing Minigame
	_minigame = FishingMinigame.new()
	_minigame.minigame_finished.connect(_on_minigame_finished)
	add_child(_minigame)

	EventBus.second_ticked.connect(_on_second_ticked)

# River ribbon segment quads
var _grass_border_quads: Array[PackedVector2Array] = []

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

func _init_fish_school() -> void:
	_fish_list.clear()
	# 1. 4 Cá Koi Đỏ Cam (Color(1.0, 0.35, 0.18, 0.92)) - swimming near bridge & pier (y: 640..800)
	for i: int in range(4):
		_fish_list.append({
			"type": "koi",
			"color": Color(1.0, 0.35, 0.18, 0.92),
			"accent": Color(1.0, 0.95, 0.85, 0.95),
			"y_base": 640.0 + float(i) * 45.0,
			"amp_y": 55.0 + float(i) * 6.0,
			"lateral": -32.0 + float(i) * 20.0,
			"speed": 0.55 + float(i) * 0.06,
			"phase": float(i) * 1.57,
			"size": 6.8,
			"pos": Vector2.ZERO,
			"rot": 0.0,
			"wag": 0.0
		})
	# 2. 4 Cá Chép Vàng Óng (Color(1.0, 0.82, 0.2, 0.92)) - swimming north of bridge (y: 420..620)
	for i: int in range(4):
		_fish_list.append({
			"type": "carp",
			"color": Color(1.0, 0.82, 0.2, 0.92),
			"accent": Color(1.0, 0.60, 0.08, 0.88),
			"y_base": 420.0 + float(i) * 50.0,
			"amp_y": 50.0 + float(i) * 5.0,
			"lateral": -25.0 + float(i) * 16.0,
			"speed": 0.48 + float(i) * 0.07,
			"phase": float(i) * 1.57 + 0.8,
			"size": 6.2,
			"pos": Vector2.ZERO,
			"rot": 0.0,
			"wag": 0.0
		})
	# 3. 3 Cá Vược Xanh Bạc (Color(0.55, 0.88, 1.0, 0.88)) - swimming south of pier (y: 820..980)
	for i: int in range(3):
		_fish_list.append({
			"type": "bass",
			"color": Color(0.55, 0.88, 1.0, 0.88),
			"accent": Color(0.92, 0.98, 1.0, 0.95),
			"y_base": 820.0 + float(i) * 55.0,
			"amp_y": 60.0 + float(i) * 8.0,
			"lateral": -30.0 + float(i) * 28.0,
			"speed": 0.65 + float(i) * 0.08,
			"phase": float(i) * 2.09 + 0.4,
			"size": 5.8,
			"pos": Vector2.ZERO,
			"rot": 0.0,
			"wag": 0.0
		})
	# 4. 3 Bóng Cá Nước Sâu (Color(0.08, 0.22, 0.38, 0.65)) - deep stream currents (y: 200..380 and 1020..1150)
	for i: int in range(3):
		_fish_list.append({
			"type": "shadow",
			"color": Color(0.08, 0.22, 0.38, 0.65),
			"accent": Color(0.04, 0.14, 0.26, 0.45),
			"y_base": 240.0 + float(i) * 400.0,
			"amp_y": 70.0 + float(i) * 10.0,
			"lateral": -10.0 + float(i) * 10.0,
			"speed": 0.38 + float(i) * 0.05,
			"phase": float(i) * 2.09 + 1.2,
			"size": 7.5,
			"pos": Vector2.ZERO,
			"rot": 0.0,
			"wag": 0.0
		})

func get_fish_count() -> int:
	return _fish_list.size()

func _process(delta: float) -> void:
	var time_sec: float = float(Time.get_ticks_msec()) * 0.001

	# 1. Update each fish along the winding river stream
	for fish: Dictionary in _fish_list:
		var spd: float = float(fish["speed"])
		var ph: float = float(fish["phase"])
		var t: float = time_sec * spd + ph
		var y_base: float = float(fish["y_base"])
		var amp_y: float = float(fish["amp_y"])
		var lateral: float = float(fish["lateral"])

		var cur_y: float = y_base + sin(t) * amp_y
		var cur_x: float = get_river_center_x(cur_y) + lateral + cos(t * 1.6) * 8.0

		var dy: float = cos(t) * amp_y * spd
		var dx: float = (get_river_center_x(cur_y + 1.0) - get_river_center_x(cur_y - 1.0)) * 0.5 * dy - sin(t * 1.6) * 8.0 * (1.6 * spd)
		var vel: Vector2 = Vector2(dx, dy)

		fish["pos"] = Vector2(cur_x, cur_y)
		fish["rot"] = vel.angle()
		fish["wag"] = sin(time_sec * 8.5 + ph * 3.0) * 0.32

	# 2. Surface ripples periodically every 2-3s
	_ripple_spawn_timer -= delta
	if _ripple_spawn_timer <= 0.0:
		_ripple_spawn_timer = randf_range(2.0, 3.2)
		if not _fish_list.is_empty():
			var rand_fish: Dictionary = _fish_list[randi() % _fish_list.size()]
			_water_ripples.append({
				"pos": rand_fish["pos"],
				"radius": 2.0,
				"max_radius": randf_range(16.0, 24.0),
				"alpha": 0.60
			})

	# 3. Update existing ripples drifting gently downstream
	for i: int in range(_water_ripples.size() - 1, -1, -1):
		var rip: Dictionary = _water_ripples[i]
		rip["radius"] = float(rip["radius"]) + delta * 14.0
		var r_pos: Vector2 = rip["pos"] as Vector2
		r_pos.y += delta * 8.0
		rip["pos"] = r_pos
		var frac: float = float(rip["radius"]) / float(rip["max_radius"])
		rip["alpha"] = clampf(0.60 * (1.0 - frac), 0.0, 0.60)
		if frac >= 1.0:
			_water_ripples.remove_at(i)

	queue_redraw()

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
		_minigame.open_minigame("fish_carp", Vector2(800.0, 720.0))
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
	EventBus.loot_collected.emit(fish_item, 1, Vector2(800.0, 720.0))
	EventBus.loot_collected.emit("gold", 20, Vector2(800.0, 720.0))
	_start_cooldown()

func _start_cooldown() -> void:
	state = SpotState.COOLDOWN
	finish_timestamp = TickManager.calculate_finish_timestamp(15)
	_label_status.text = "⏳ HỒI: 00:15"
	_label_status.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))

	var tw: Tween = create_tween()
	tw.tween_property(self, "scale", Vector2(1.03, 0.97), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func get_minigame() -> FishingMinigame:
	return _minigame

func _draw() -> void:
	# ====================================================================
	# 1. WINDING RIVER WATER BODY & SANDY RIVERBANKS
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

	# D. Downstream Flowing Wave Ripple Streaks (Color(1.0, 1.0, 1.0, 0.35))
	var wave_time: float = float(Time.get_ticks_msec()) * 0.001
	var streak_color: Color = Color(1.0, 1.0, 1.0, 0.35)
	for k: int in range(12):
		var base_y: float = fmod(float(k) * 110.0 + wave_time * 35.0, 1400.0) - 100.0
		var r_cx: float = get_river_center_x(base_y)
		var offset_x: float = (float(k % 3) - 1.0) * 22.0
		var streak_pts: PackedVector2Array = PackedVector2Array([
			Vector2(r_cx + offset_x - 14.0, base_y - 12.0),
			Vector2(r_cx + offset_x, base_y),
			Vector2(r_cx + offset_x + 12.0, base_y + 12.0)
		])
		draw_polyline(streak_pts, streak_color, 1.6)

	# E. Expanding Surface Ripples
	for rip: Dictionary in _water_ripples:
		var r_pos: Vector2 = rip["pos"] as Vector2
		var r_rad: float = float(rip["radius"])
		var r_al: float = float(rip["alpha"])
		draw_arc(r_pos, r_rad, 0.0, TAU, 18, Color(0.88, 0.96, 1.0, r_al), 1.6)
		if r_rad > 6.0:
			draw_arc(r_pos, r_rad * 0.55, 0.0, TAU, 12, Color(0.92, 1.0, 1.0, r_al * 0.45), 1.0)

	# ====================================================================
	# 2. 14 SWIMMING FISH ALONG THE RIVER
	# ====================================================================
	for fish: Dictionary in _fish_list:
		var f_pos: Vector2 = fish["pos"] as Vector2
		var f_rot: float = float(fish["rot"])
		var f_wag: float = float(fish["wag"])
		var f_sz: float = float(fish["size"])
		var f_col: Color = fish["color"] as Color
		var f_acc: Color = fish["accent"] as Color
		var f_type: String = String(fish["type"])

		draw_set_transform(f_pos, f_rot, Vector2.ONE)

		# Fish Torso
		draw_set_transform(f_pos, f_rot, Vector2(1.8, 0.85))
		draw_circle(Vector2.ZERO, f_sz * 0.65, f_col)
		draw_set_transform(f_pos, f_rot, Vector2.ONE)

		# Distinct Markings
		if f_type == "koi":
			draw_circle(Vector2(f_sz * 0.2, -1.0), f_sz * 0.25, f_acc)
			draw_circle(Vector2(-f_sz * 0.3, 1.0), f_sz * 0.22, f_acc)
		elif f_type == "bass":
			draw_line(Vector2(-f_sz * 0.6, 0.0), Vector2(f_sz * 0.5, 0.0), f_acc, 1.5)
		elif f_type == "carp":
			draw_circle(Vector2(-f_sz * 0.1, 0.0), f_sz * 0.3, f_acc)

		# Pectoral Fins
		draw_line(Vector2(f_sz * 0.2, 0.0), Vector2(0.0, -f_sz * 0.75), f_col, 1.8)
		draw_line(Vector2(f_sz * 0.2, 0.0), Vector2(0.0, f_sz * 0.75), f_col, 1.8)

		# Wagging Tail
		var tail_base: Vector2 = Vector2(-f_sz * 0.85, 0.0)
		var tail_tip1: Vector2 = Vector2(-f_sz * 1.7, -f_sz * 0.65 + f_wag * f_sz)
		var tail_tip2: Vector2 = Vector2(-f_sz * 1.7, f_sz * 0.65 + f_wag * f_sz)
		draw_line(tail_base, tail_tip1, f_col, 2.2)
		draw_line(tail_base, tail_tip2, f_col, 2.2)
		draw_line(tail_tip1, tail_tip2, f_acc, 1.4)

		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# ====================================================================
	# 3. WATER LILIES ALONG THE RIVER MEANDER
	# ====================================================================
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



	# Draw small river pebbles along sandy border
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

	# ====================================================================
	# 4. WOODEN RIVER BRIDGE (CẦU GỖ BẮC QUA SÔNG) AT Y = 660
	# ====================================================================
	# Bridge spans across river from West bank (x = 820) to East bank (x = 1080), y = 636..684
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

	# ====================================================================
	# 5. FISHING PIER (BẾN CÂU CÁ) AT Y = 708..736, X = 780..880
	# ====================================================================
	var pier_x0: float = 780.0
	var pier_x1: float = 880.0
	var pier_y0: float = 708.0
	var pier_y1: float = 736.0
	var pier_pw: float = pier_x1 - pier_x0
	var pier_ph: float = pier_y1 - pier_y0

	# Pier Shadow
	draw_rect(Rect2(pier_x0 + 4.0, pier_y1, pier_pw - 6.0, 10.0), Color(0.08, 0.25, 0.42, 0.35), true)

	# Pier Support Piles
	var pier_piles: Array[float] = [pier_x0 + 30.0, pier_x0 + 65.0, pier_x1 - 5.0]
	for px: float in pier_piles:
		draw_rect(Rect2(Vector2(px - 4.0, pier_y0 - 2.0), Vector2(8.0, pier_ph + 12.0)), wood_dark, true)
		draw_circle(Vector2(px, pier_y1 + 10.0), 3.5, Color(0.18, 0.42, 0.58, 0.65))

	# Pier Planks
	draw_rect(Rect2(pier_x0, pier_y0, pier_pw, pier_ph), wood_base, true)
	draw_rect(Rect2(pier_x0, pier_y0, pier_pw, pier_ph), wood_dark, false, 2.0)

	var p_cur: float = pier_x0 + 12.0
	while p_cur < pier_x1:
		draw_line(Vector2(p_cur, pier_y0), Vector2(p_cur, pier_y1), wood_dark, 1.4)
		draw_line(Vector2(p_cur + 1.0, pier_y0), Vector2(p_cur + 1.0, pier_y1), wood_light, 1.0)
		p_cur += 12.0

	# Mooring Tie Posts at Pier Head
	draw_circle(Vector2(pier_x1 - 4.0, pier_y0 + 4.0), 3.5, wood_dark)
	draw_circle(Vector2(pier_x1 - 4.0, pier_y1 - 4.0), 3.5, wood_dark)
