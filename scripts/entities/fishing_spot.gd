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
var _rain_luck_bonus: float = 0.0

# River ribbon polygons & static batched visuals (replacing 477-draw-call _draw())
var _river_visuals_root: Node2D = null
var _grass_border_quads: Array[PackedVector2Array] = []
var _sand_quads: Array[PackedVector2Array] = []
var _water_quads: Array[PackedVector2Array] = []
var _deep_water_quads: Array[PackedVector2Array] = []

static func get_river_center_x(y: float) -> float:
	return GridManager.get_river_center_x(y)

static func is_in_water_or_sand(pos: Vector2) -> bool:
	return GridManager.is_in_water_or_sand(pos)

func _ready() -> void:
	y_sort_enabled = true
	add_to_group("interactable")
	set_process(false) # Tắt hoàn toàn _process để triệt tiêu redraw liên tục, chống giật lag
	_generate_river_geometry()
	_build_batched_river_and_bridge()

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
	_label_status.text = ""
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
	EventBus.weather_state_changed.connect(_on_weather_state_changed)

func _on_weather_state_changed(weather_id: String, _speed_mult: float, fish_luck_bonus: float) -> void:
	if weather_id.to_upper() == "COZY_RAIN":
		_rain_luck_bonus = 0.25
	else:
		_rain_luck_bonus = fish_luck_bonus

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
			_label_status.text = ""
		else:
			var remaining: int = TickManager.get_time_remaining(finish_timestamp)
			_label_status.text = "⏳ HỒI: 00:%02d" % maxi(0, remaining)
			_label_status.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))

func on_player_interact(_avatar: Node2D) -> void:
	handle_fishing_click()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.is_pressed():
			var mpos: Vector2 = get_global_mouse_position()
			if fishing_rect.has_point(mpos):
				if not SaveManager.instant_interact:
					var p_input: Node = get_tree().current_scene.find_child("PlayerInput", true, false)
					if p_input != null:
						p_input.call("interact_with", self)
						get_viewport().set_input_as_handled()
						return
				if handle_fishing_click():
					get_viewport().set_input_as_handled()

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.is_pressed():
			if not SaveManager.instant_interact:
				var p_input: Node = get_tree().current_scene.find_child("PlayerInput", true, false)
				if p_input != null:
					p_input.call("interact_with", self)
					return
			handle_fishing_click()

func handle_fishing_click() -> bool:
	if _minigame != null and _minigame.is_active:
		return true
	if state != SpotState.READY:
		print("[FishingSpot] Bãi câu đang trong thời gian hồi!")
		return false

	var target_fish: String = "fish_carp"
	if _rain_luck_bonus > 0.15 and randf() < _rain_luck_bonus:
		target_fish = "fish_bass" if SpriteAtlasManager.has_texture("fish_bass") else "fish_carp"

	if _minigame != null:
		_minigame.open_minigame(target_fish, Vector2(768.0, 750.0))
		return true

	_complete_catch()
	return true

func _on_minigame_finished(success: bool, p_fish_id: String) -> void:
	if success:
		var catch_id: String = p_fish_id if p_fish_id != "" else "fish_carp"
		EventBus.fish_caught.emit(instance_id, catch_id, 1.5)
		_start_cooldown()

func _complete_catch() -> void:
	var fish_item: String = "fish_carp"
	if _rain_luck_bonus > 0.15 and randf() < _rain_luck_bonus:
		fish_item = "fish_bass" if SpriteAtlasManager.has_texture("fish_bass") else "fish_carp"

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
	EventBus.fish_caught.emit(instance_id, fish_item, 1.5)
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

func _build_ribbon_polygon(half_width: float) -> PackedVector2Array:
	var left_pts: Array[Vector2] = []
	var right_pts: Array[Vector2] = []
	var y_start: float = -120.0
	var y_end: float = 1380.0
	var step: float = 24.0
	var y: float = y_start
	while y <= y_end + step * 0.5:
		var cx: float = get_river_center_x(y)
		var dx: float = (get_river_center_x(y + 1.0) - get_river_center_x(y - 1.0)) * 0.5
		var dy: float = 1.0
		var length: float = sqrt(dx * dx + dy * dy)
		var nx: float = -dy / length
		var ny: float = dx / length
		left_pts.append(Vector2(cx - nx * half_width, y - ny * half_width))
		right_pts.append(Vector2(cx + nx * half_width, y + ny * half_width))
		y += step
	var poly: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in left_pts:
		poly.append(p)
	for i: int in range(right_pts.size() - 1, -1, -1):
		poly.append(right_pts[i])
	return poly

func _build_batched_river_and_bridge() -> void:
	if _river_visuals_root != null:
		return
	_river_visuals_root = Node2D.new()
	_river_visuals_root.name = "RiverStaticBatched"
	_river_visuals_root.z_index = 0
	add_child(_river_visuals_root)
	move_child(_river_visuals_root, 0)

	# 1. 4 continuous Polygon2D river layers (4 draw calls instead of 248)
	var layers: Array[Dictionary] = [
		{"name": "RiverGrassBorder", "w": 116.0, "col": Color(0.36, 0.58, 0.22)},
		{"name": "RiverSandBorder", "w": 105.0, "col": Color(0.84, 0.76, 0.56)},
		{"name": "RiverShallowWater", "w": 88.0, "col": Color(0.28, 0.68, 0.86)},
		{"name": "RiverDeepWater", "w": 52.0, "col": Color(0.18, 0.52, 0.78)}
	]
	for cfg: Dictionary in layers:
		var poly_node: Polygon2D = Polygon2D.new()
		poly_node.name = String(cfg["name"])
		poly_node.polygon = _build_ribbon_polygon(float(cfg["w"]))
		poly_node.color = cfg["col"] as Color
		_river_visuals_root.add_child(poly_node)

	# 2. All riverbank pebbles batched into 1 MultiMeshInstance2D (1 draw call)
	var pebble_img: Image = Image.create(10, 10, false, Image.FORMAT_RGBA8)
	pebble_img.fill(Color(0, 0, 0, 0))
	_paint_circle(pebble_img, Vector2(5.0, 5.0), 3.4, Color(0.74, 0.71, 0.62, 1.0))
	_paint_circle(pebble_img, Vector2(4.2, 4.2), 1.6, Color(0.88, 0.86, 0.78, 1.0))
	var pebble_tex: ImageTexture = ImageTexture.create_from_image(pebble_img)
	var pebble_positions: Array[Vector2] = []
	var p_y: float = -100.0
	while p_y <= 1360.0:
		var p_cx: float = get_river_center_x(p_y)
		pebble_positions.append(Vector2(p_cx - 104.0, p_y))
		pebble_positions.append(Vector2(p_cx + 104.0, p_y + 16.0))
		p_y += 38.0
	var pebble_mm: MultiMeshInstance2D = _create_batched_multimesh("RiverPebblesMultiMesh", pebble_tex, Vector2(10.0, 10.0), pebble_positions)
	_river_visuals_root.add_child(pebble_mm)

	# 3. All static water ripple arcs batched into 1 MultiMeshInstance2D (1 draw call)
	var ripple_img: Image = Image.create(32, 24, false, Image.FORMAT_RGBA8)
	ripple_img.fill(Color(0, 0, 0, 0))
	var flow_soft: Color = Color(0.88, 0.96, 1.0, 0.38)
	var flow_bright: Color = Color(1.0, 1.0, 1.0, 0.50)
	_paint_arc(ripple_img, Vector2(12.0, 11.0), 9.0, -0.65, 0.65, 1.4, flow_soft)
	_paint_arc(ripple_img, Vector2(16.0, 13.0), 5.5, -0.5, 0.5, 1.1, flow_bright)
	var ripple_tex: ImageTexture = ImageTexture.create_from_image(ripple_img)
	var ripple_positions: Array[Vector2] = [
		Vector2(950.0, 320.0), Vector2(980.0, 360.0), Vector2(810.0, 560.0),
		Vector2(830.0, 810.0), Vector2(920.0, 1020.0), Vector2(940.0, 1060.0),
		Vector2(890.0, 460.0), Vector2(930.0, 780.0),
		Vector2(910.0, 240.0), Vector2(960.0, 420.0), Vector2(870.0, 510.0),
		Vector2(840.0, 750.0), Vector2(890.0, 910.0), Vector2(950.0, 1140.0)
	]
	var ripple_mm: MultiMeshInstance2D = _create_batched_multimesh("RiverRipplesMultiMesh", ripple_tex, Vector2(32.0, 24.0), ripple_positions)
	_river_visuals_root.add_child(ripple_mm)

	# 4. Pre-baked Wooden River Bridge Sprite2D (1 draw call instead of 60+)
	var bridge_sp: Sprite2D = Sprite2D.new()
	bridge_sp.name = "RiverBridgeBackdrop"
	bridge_sp.texture = _create_baked_bridge_texture()
	bridge_sp.position = Vector2(950.0, 667.0)
	_river_visuals_root.add_child(bridge_sp)

func _create_batched_multimesh(node_name: String, tex: Texture2D, quad_size: Vector2, positions: Array[Vector2]) -> MultiMeshInstance2D:
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	var qmesh: QuadMesh = QuadMesh.new()
	qmesh.size = quad_size
	mm.mesh = qmesh
	mm.instance_count = positions.size()
	for i: int in range(positions.size()):
		mm.set_instance_transform_2d(i, Transform2D(0.0, positions[i]))
	var mmi: MultiMeshInstance2D = MultiMeshInstance2D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.texture = tex
	return mmi

func _paint_circle(img: Image, center: Vector2, radius: float, col: Color) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var r_sq: float = radius * radius
	var min_x: int = maxi(0, int(floor(center.x - radius - 1.0)))
	var max_x: int = mini(w - 1, int(ceil(center.x + radius + 1.0)))
	var min_y: int = maxi(0, int(floor(center.y - radius - 1.0)))
	var max_y: int = mini(h - 1, int(ceil(center.y + radius + 1.0)))
	for py: int in range(min_y, max_y + 1):
		for px: int in range(min_x, max_x + 1):
			var dx: float = float(px) + 0.5 - center.x
			var dy: float = float(py) + 0.5 - center.y
			if dx * dx + dy * dy <= r_sq:
				img.set_pixel(px, py, col)

func _paint_arc(img: Image, center: Vector2, radius: float, a0: float, a1: float, thickness: float, col: Color) -> void:
	var steps: int = 18
	for i: int in range(steps + 1):
		var a: float = lerpf(a0, a1, float(i) / float(steps))
		var pt: Vector2 = center + Vector2(cos(a) * radius, sin(a) * radius)
		_paint_circle(img, pt, thickness * 0.5, col)

func _paint_rect(img: Image, rect: Rect2i, col: Color) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	for py: int in range(maxi(0, rect.position.y), mini(h, rect.position.y + rect.size.y)):
		for px: int in range(maxi(0, rect.position.x), mini(w, rect.position.x + rect.size.x)):
			img.set_pixel(px, py, col)

func _create_baked_bridge_texture() -> ImageTexture:
	# Covers world x: 812..1088 (276px), y: 626..708 (82px); center = (950, 667)
	var origin: Vector2 = Vector2(812.0, 626.0)
	var img: Image = Image.create(276, 82, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var br_x0: int = int(820.0 - origin.x)
	var br_x1: int = int(1080.0 - origin.x)
	var br_w: int = br_x1 - br_x0
	var br_y0: int = int(636.0 - origin.y)
	var br_y1: int = int(684.0 - origin.y)
	var br_h: int = br_y1 - br_y0

	var wood_base: Color = Color(0.74, 0.54, 0.34, 1.0)
	var wood_dark: Color = Color(0.48, 0.32, 0.18, 1.0)
	var wood_light: Color = Color(0.84, 0.66, 0.44, 1.0)
	var wood_rail: Color = Color(0.52, 0.34, 0.18, 1.0)

	# A. Bridge Soft Water Shadow
	_paint_rect(img, Rect2i(br_x0 + 12, br_y1, br_w - 24, 14), Color(0.08, 0.25, 0.42, 0.35))

	# B. Support Piers in the water
	for px_off: int in [65, 130, 195]:
		var px: int = br_x0 + px_off
		_paint_rect(img, Rect2i(px - 5, br_y0 - 2, 10, br_h + 16), wood_dark)
		_paint_circle(img, Vector2(float(px), float(br_y1 + 14)), 4.5, Color(0.18, 0.42, 0.58, 0.65))

	# C. Arched Wooden Bridge Deck & border
	_paint_rect(img, Rect2i(br_x0, br_y0, br_w, br_h), wood_base)
	_paint_rect(img, Rect2i(br_x0, br_y0, br_w, 2), wood_dark)
	_paint_rect(img, Rect2i(br_x0, br_y1 - 2, br_w, 2), wood_dark)
	_paint_rect(img, Rect2i(br_x0, br_y0, 2, br_h), wood_dark)
	_paint_rect(img, Rect2i(br_x1 - 2, br_y0, 2, br_h), wood_dark)

	# Vertical Plank Lines
	var cur_px: int = br_x0 + 14
	while cur_px < br_x1:
		_paint_rect(img, Rect2i(cur_px, br_y0, 2, br_h), wood_dark)
		_paint_rect(img, Rect2i(cur_px + 2, br_y0, 1, br_h), wood_light)
		cur_px += 14

	# D. North & South Handrails + Baluster Posts
	_paint_rect(img, Rect2i(br_x0, br_y0 + 1, br_w, 3), wood_rail)
	_paint_rect(img, Rect2i(br_x0, br_y0 + 5, br_w, 2), wood_rail)
	_paint_rect(img, Rect2i(br_x0, br_y1 - 4, br_w, 3), wood_rail)
	_paint_rect(img, Rect2i(br_x0, br_y1 - 7, br_w, 2), wood_rail)

	var post_x: int = br_x0 + 6
	while post_x <= br_x1:
		_paint_rect(img, Rect2i(post_x - 1, br_y0 - 4, 3, 12), wood_rail)
		_paint_rect(img, Rect2i(post_x - 1, br_y1 - 8, 3, 12), wood_rail)
		_paint_circle(img, Vector2(float(post_x), float(br_y0 - 4)), 2.2, wood_light)
		_paint_circle(img, Vector2(float(post_x), float(br_y1 + 4)), 2.2, wood_light)
		post_x += 24

	return ImageTexture.create_from_image(img)

func get_minigame() -> FishingMinigame:
	return _minigame
