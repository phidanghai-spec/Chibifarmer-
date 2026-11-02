class_name RandomBotPlaytest
extends GdUnitTestSuite

const FIXED_SEED: int = 20261102
const TOTAL_STEPS: int = 200
const SCREEN_W: float = 1152.0
const SCREEN_H: float = 648.0
const MAX_ALLOWED_PROP_PX: float = 340.0
const MAX_ALLOWED_HEART_PX: float = 48.0

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _action_history: Array[String] = []

func test_random_bot_200_steps_visual_and_logic_invariants() -> void:
	_rng.seed = FIXED_SEED
	_action_history.clear()
	
	# Khởi chạy cảnh chính bằng GdUnitSceneRunner
	var main_scene_path: String = "res://scenes/main/MainFarm.tscn"
	if not FileAccess.file_exists(main_scene_path):
		main_scene_path = ProjectSettings.get_setting("application/run/main_scene") as String
		
	var runner: GdUnitSceneRunner = scene_runner(main_scene_path)
	if runner.scene() != null and runner.scene().get_tree() != null:
		runner.scene().get_tree().current_scene = runner.scene()
	await runner.simulate_frames(10)
	
	for step: int in range(1, TOTAL_STEPS + 1):
		var action_desc: String = _perform_random_bot_action()
		_action_history.append("Bước %03d: %s" % [step, action_desc])
		
		# Chờ 3 frame để game xử lý di chuyển, Tween, hiệu ứng hạt và UI
		await runner.simulate_frames(3)
		
		# Kiểm tra toàn bộ bất biến Logic & Hình ảnh sau mỗi bước
		var violation: String = _check_all_invariants(runner.scene())
		if not violation.is_empty():
			var trace_dump: String = "\n".join(_action_history.slice(maxi(0, _action_history.size() - 15)))
			fail("PHÁT HIỆN LỖI TẠI BƯỚC %d (Seed=%d):\n👉 %s\n\n--- 15 Hành động gần nhất ---\n%s" % [
				step, FIXED_SEED, violation, trace_dump
			])
			return

# ==============================================================================
# GIẢ LẬP HÀNH ĐỘNG NGẪU NHIÊN BẰNG Input.parse_input_event()
# ==============================================================================
func _perform_random_bot_action() -> String:
	var roll: int = _rng.randi_range(0, 4)
	match roll:
		0:
			# Click chuột trái vào một vị trí bất kỳ trên nông trại (di chuyển / bấm nhà Poodle / bấm cây)
			var pos: Vector2 = Vector2(_rng.randf_range(80.0, 1060.0), _rng.randf_range(90.0, 540.0))
			_send_mouse_click(pos, MOUSE_BUTTON_LEFT)
			return "Click Trái tại (%.0f, %.0f)" % [pos.x, pos.y]
		1:
			# Kéo chuột (Drag-and-Swipe) qua khu vực ruộng để gặt lúa / gieo hạt
			var start_p: Vector2 = Vector2(_rng.randf_range(300.0, 620.0), _rng.randf_range(260.0, 440.0))
			var end_p: Vector2 = start_p + Vector2(_rng.randf_range(-96.0, 96.0), _rng.randf_range(-64.0, 64.0))
			_send_mouse_drag(start_p, end_p)
			return "Drag-Swipe từ (%.0f, %.0f) đến (%.0f, %.0f)" % [start_p.x, start_p.y, end_p.x, end_p.y]
		2:
			# Click vào thanh công cụ phía dưới màn hình (Xây dựng, Liềm, Ruộng, Đường, Tháo Dỡ, Sạp Hàng)
			var toolbar_pos: Vector2 = Vector2(_rng.randf_range(160.0, 960.0), 608.0)
			_send_mouse_click(toolbar_pos, MOUSE_BUTTON_LEFT)
			return "Bấm thanh công cụ dưới tại X=%.0f" % toolbar_pos.x
		3:
			# Click chuột phải để hủy công cụ hoặc đóng menu
			var r_pos: Vector2 = Vector2(576.0, 324.0)
			_send_mouse_click(r_pos, MOUSE_BUTTON_RIGHT)
			return "Click Phải giữa màn hình (Hủy chế độ)"
		_:
			# Bấm phím ESC để kiểm tra luôn thoát được khỏi các Modal/Popup
			var key_ev: InputEventKey = InputEventKey.new()
			key_ev.keycode = KEY_ESCAPE
			key_ev.pressed = true
			Input.parse_input_event(key_ev)
			var key_up: InputEventKey = InputEventKey.new()
			key_up.keycode = KEY_ESCAPE
			key_up.pressed = false
			Input.parse_input_event(key_up)
			return "Nhấn phím ESC"

func _send_mouse_click(pos: Vector2, button: MouseButton) -> void:
	var down: InputEventMouseButton = InputEventMouseButton.new()
	down.position = pos
	down.global_position = pos
	down.button_index = button
	down.pressed = true
	Input.parse_input_event(down)
	
	var up: InputEventMouseButton = InputEventMouseButton.new()
	up.position = pos
	up.global_position = pos
	up.button_index = button
	up.pressed = false
	Input.parse_input_event(up)

func _send_mouse_drag(from_pos: Vector2, to_pos: Vector2) -> void:
	_send_mouse_click(from_pos, MOUSE_BUTTON_LEFT)
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = to_pos
	motion.global_position = to_pos
	motion.relative = to_pos - from_pos
	Input.parse_input_event(motion)
	_send_mouse_click(to_pos, MOUSE_BUTTON_LEFT)

# ==============================================================================
# KIỂM TRA BẤT BIẾN LOGIC & BẤT BIẾN HÌNH ẢNH SAU MỖI BƯỚC
# ==============================================================================
func _check_all_invariants(root_scene: Node) -> String:
	if root_scene == null:
		return "Cảnh hiện tại (root_scene) bị null!"

	# 1. BẤT BIẾN KINH TẾ: Tiền và vật phẩm không bao giờ âm
	var sm: Node = get_node_or_null("/root/StorageManager")
	if sm != null and sm.has_method("get_gold"):
		if int(sm.call("get_gold")) < 0:
			return "Bất biến Kinh tế vi phạm: Số Vàng bị âm!"

	# 2. BẤT BIẾN HÌNH ẢNH TOÀN CẢNH: Quét mọi Sprite2D đang hiển thị
	for node: Node in root_scene.find_children("*", "Sprite2D", true, false):
		var spr: Sprite2D = node as Sprite2D
		if not spr.is_visible_in_tree():
			continue
			
		# 2.1. Sprite đang hiển thị không được mất texture (trừ node placeholder)
		if spr.texture == null:
			if spr.name.begins_with("Placeholder"):
				continue
			return "Lỗi Hình Ảnh: Sprite2D '%s' đang hiển thị nhưng texture == null!" % spr.get_path()
			
		# 2.2. Kích thước thực tế sau khi nhân scale không được phóng đại che màn hình
		var rendered_w: float = float(spr.texture.get_width()) * absf(spr.global_scale.x)
		var rendered_h: float = float(spr.texture.get_height()) * absf(spr.global_scale.y)
		var node_name_low: String = spr.name.to_lower()
		
		# Bắt lỗi Trái Tim Poodle khổng lồ
		if "heart" in node_name_low:
			if rendered_w > MAX_ALLOWED_HEART_PX or rendered_h > MAX_ALLOWED_HEART_PX:
				return "Lỗi Hình Ảnh: Icon Trái tim '%s' phóng to bất thường (%.1fx%.1f px) che màn hình!" % [
					spr.name, rendered_w, rendered_h
				]
		# Bắt lỗi Thỏ / Cây / Đạo cụ phóng to đè giao diện (trừ ảnh nền sky/ground/river)
		elif not ("bg" in node_name_low or "sky" in node_name_low or "ground" in node_name_low or "river" in node_name_low or "backdrop" in node_name_low or "panorama" in node_name_low):
			if rendered_w > MAX_ALLOWED_PROP_PX or rendered_h > MAX_ALLOWED_PROP_PX:
				return "Lỗi Hình Ảnh: Sprite '%s' có kích thước hiển thị quá lớn (%.1fx%.1f px), nguy cơ đè màn hình!" % [
					spr.name, rendered_w, rendered_h
				]

	# 3. BẤT BIẾN VỊ TRÍ TÀU HƠI NƯỚC: Tàu không được chạy trên đất liền (X phải ở vùng sông >= 850)
	for node: Node in root_scene.find_children("*Steamboat*", "Node2D", true, false):
		var boat: Node2D = node as Node2D
		if boat.is_visible_in_tree() and boat.global_position.x < 850.0:
			return "Lỗi Vị Trí Hiển Thị: Tàu hơi nước '%s' đang nằm trên đất liền tại X=%.1f (< 850)!" % [
				boat.name, boat.global_position.x
			]

	# 4. BẤT BIẾN CHÓ POODLE & NHÂN VẬT: Không lội giữa sông & Không xoay lắc vòng vòng
	var gm: Node = get_node_or_null("/root/GridManager")
	for node: Node in root_scene.find_children("*Poodle*", "Node2D", true, false):
		var poodle: Node2D = node as Node2D
		if gm != null and gm.has_method("is_in_water_or_sand"):
			var in_water: bool = bool(gm.call("is_in_water_or_sand", poodle.global_position))
			var on_bridge_y: bool = absf(poodle.global_position.y - 656.0) <= 42.0
			if in_water and not on_bridge_y:
				return "Lỗi Điều Hướng: Chó Poodle đang lội dưới nước sông tại (%.1f, %.1f)!" % [
					poodle.global_position.x, poodle.global_position.y
				]

	for node: Node in root_scene.find_children("*PlayerAvatar*", "Node2D", true, false):
		var p: Node2D = node as Node2D
		if absf(p.rotation) > 0.05:
			return "Lỗi Hình Ảnh: Nhân vật PlayerAvatar đang bị xoay lắc rotation=%.2f!" % p.rotation

	return ""
