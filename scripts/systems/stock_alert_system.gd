extends Control
class_name StockAlertSystem

## StockAlertSystem - Hệ thống Cảnh Báo NPC Chuyên Trách
## Quản lý 5 NPC đứng tại các khu vực chức năng & phát cảnh báo thiếu nguyên liệu:
## 1. Đầu bếp Bánh Mì (npc_baker): Đứng cạnh Lò Bánh Mì
## 2. Thợ Bánh Ngọt (npc_pastry): Đứng cạnh Lò Bánh Ngọt
## 3. Nhân viên Pha Chế (npc_barista): Đứng cạnh Quầy Nước
## 4. Người Chăn Nuôi (npc_rancher): Đứng lối vào Chuồng Bò / Gà
## 5. Thủ Kho (npc_keeper): Đứng giữa Kho Silo & Nhà Kho
## Khi người chơi bấm vào thông báo góc phải, Camera tự động lướt mượt đến đúng vị trí NPC!
## 100% Static Typing GDScript 2.0.

signal alert_clicked(target_pos: Vector2)

const SpecializedNPCClass = preload("res://scripts/entities/specialized_npc.gd")

var _banner_btn: Button
var _timer: Timer
var _active_alerts: Array[Dictionary] = []
var _current_alert_idx: int = 0
var main_farm: Node2D = null

# References to the 5 Specialized NPCs on farm
var npcs: Dictionary = {} # String -> Node2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(326, 36)
	size = Vector2(326, 36)
	
	# Đặt bảng cảnh báo ở góc phải trên màn hình, ngay dưới TourismStarHUD (tránh đè nút & cắt chữ)
	anchors_preset = Control.PRESET_TOP_RIGHT
	anchor_left = 1.0
	anchor_right = 1.0
	offset_left = -340.0
	offset_top = 104.0
	offset_right = -14.0
	offset_bottom = 140.0
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	
	_banner_btn = Button.new()
	_banner_btn.name = "AlertBannerButton"
	_banner_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_banner_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_banner_btn.custom_minimum_size = Vector2(326, 34)
	_banner_btn.text = "Nông trại êm ả!"
	_banner_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_btn.add_theme_font_size_override("font_size", 11)
	_banner_btn.add_theme_color_override("font_color", Color(0.24, 0.15, 0.08))
	_banner_btn.add_theme_color_override("font_hover_color", Color(0.85, 0.25, 0.05))
	
	# Phong cách Chibi Cozy
	var style_normal: StyleBoxFlat = StyleBoxFlat.new()
	style_normal.bg_color = Color(1.0, 0.98, 0.92, 0.96)
	style_normal.border_color = Color(0.80, 0.55, 0.30, 1.0)
	style_normal.set_border_width_all(2)
	style_normal.set_corner_radius_all(14)
	style_normal.shadow_color = Color(0.3, 0.2, 0.1, 0.18)
	style_normal.shadow_size = 3
	style_normal.content_margin_left = 8.0
	style_normal.content_margin_right = 8.0
	_banner_btn.add_theme_stylebox_override("normal", style_normal)
	
	var style_hover: StyleBoxFlat = style_normal.duplicate() as StyleBoxFlat
	style_hover.bg_color = Color(1.0, 1.0, 0.95, 1.0)
	style_hover.border_color = Color(0.92, 0.45, 0.15, 1.0)
	_banner_btn.add_theme_stylebox_override("hover", style_hover)
	
	_banner_btn.pressed.connect(_on_banner_pressed)
	add_child(_banner_btn)
	
	visible = false
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	
	_timer = Timer.new()
	_timer.name = "AlertCheckTimer"
	_timer.wait_time = 5.0
	_timer.autostart = true
	_timer.timeout.connect(_scan_stock_alerts)
	add_child(_timer)
	_timer.start(5.0)
	call_deferred("_scan_stock_alerts")

func register_npc(npc_key: String, npc_node: Node2D) -> void:
	npcs[npc_key] = npc_node

func _get_resource_target_pos(resource_id: String, fallback: Vector2) -> Vector2:
	var farm: Node = main_farm if main_farm != null else get_tree().current_scene
	if farm != null:
		if resource_id == "wheat" or resource_id == "corn":
			var plots_c: Node2D = farm.find_child("PlotsContainer", true, false) as Node2D
			if plots_c != null and plots_c.get_child_count() > 0:
				var first_p: Node2D = plots_c.get_child(0) as Node2D
				if first_p != null:
					return first_p.global_position
		elif resource_id == "egg":
			var pens: Array = farm.get("_animal_pens") as Array if farm.get("_animal_pens") != null else []
			for p: Variant in pens:
				var pen: Node2D = p as Node2D
				if pen != null and String(pen.get("animal_id")) == "chicken":
					return pen.global_position
		elif resource_id == "milk":
			var pens: Array = farm.get("_animal_pens") as Array if farm.get("_animal_pens") != null else []
			for p: Variant in pens:
				var pen: Node2D = p as Node2D
				if pen != null and String(pen.get("animal_id")) == "cow":
					return pen.global_position
	
	if resource_id == "egg" or resource_id == "milk":
		return _get_npc_pos("rancher", fallback)
	elif resource_id == "wheat":
		return _get_npc_pos("baker", fallback)
	return fallback

func _scan_stock_alerts() -> void:
	_active_alerts.clear()
	
	var wheat_count: int = StorageManager.get_item_count("wheat") if StorageManager != null else 10
	var corn_count: int = StorageManager.get_item_count("corn") if StorageManager != null else 10
	var egg_count: int = StorageManager.get_item_count("egg") if StorageManager != null else 10
	var milk_count: int = StorageManager.get_item_count("milk") if StorageManager != null else 10
	
	var wheat_pos: Vector2 = _get_resource_target_pos("wheat", Vector2(400.0, 560.0))
	var corn_pos: Vector2 = _get_resource_target_pos("corn", Vector2(460.0, 560.0))
	var egg_pos: Vector2 = _get_resource_target_pos("egg", Vector2(240.0, 720.0))
	var milk_pos: Vector2 = _get_resource_target_pos("milk", Vector2(300.0, 720.0))
	
	if wheat_count <= 4:
		_active_alerts.append({
			"item": "wheat",
			"text": "Thiếu Lúa Mì (%d còn lại)! Bấm để gieo hạt" % wheat_count,
			"pos": wheat_pos
		})
		_update_npc_bubble("baker", "Cần Lúa Mì!", true)
	else:
		_update_npc_bubble("baker", "Bánh Đã Sẵn!", false)
	
	if corn_count <= 4:
		_active_alerts.append({
			"item": "corn",
			"text": "Thiếu Ngô (%d còn lại)! Bấm để gieo trồng" % corn_count,
			"pos": corn_pos
		})
		_update_npc_bubble("rancher", "Cần Ngô Xay Cám!", true)
	else:
		_update_npc_bubble("rancher", "Bầy Thú No Nê!", false)
	
	if egg_count <= 2:
		_active_alerts.append({
			"item": "egg",
			"text": "Thiếu Trứng Gà (%d còn lại)! Bấm để thăm chuồng" % egg_count,
			"pos": egg_pos
		})
		_update_npc_bubble("pastry", "Cần Trứng Gà!", true)
	else:
		_update_npc_bubble("pastry", "Bánh Kem Xong!", false)
	
	if milk_count <= 2:
		_active_alerts.append({
			"item": "milk",
			"text": "Thiếu Sữa Bò (%d còn lại)! Bấm để vắt sữa" % milk_count,
			"pos": milk_pos
		})
		_update_npc_bubble("barista", "Cần Sữa Tươi!", true)
	else:
		_update_npc_bubble("barista", "Nước Mát Lạnh!", false)
	
	if npcs.has("keeper"):
		_update_npc_bubble("keeper", "Kho Sẵn Sàng!", false)
	if npcs.has("fisher"):
		var fish_unlock_lv: int = DataManager.get_building_unlock_level("fishing_spot", 4) if DataManager != null else 4
		if StorageManager != null and StorageManager.level >= fish_unlock_lv:
			_update_npc_bubble("fisher", "Bến Cá Sẵn Sàng!", false)
		else:
			_update_npc_bubble("fisher", "", false)
	
	if not _active_alerts.is_empty():
		_current_alert_idx = _current_alert_idx % _active_alerts.size()
		_show_alert(_active_alerts[_current_alert_idx])
	else:
		_hide_banner()

func _get_npc_pos(npc_key: String, fallback: Vector2) -> Vector2:
	if npcs.has(npc_key):
		var npc_node: Node2D = npcs[npc_key] as Node2D
		if is_instance_valid(npc_node):
			return npc_node.global_position
	return fallback

func _update_npc_bubble(npc_key: String, msg: String, is_warn: bool) -> void:
	if npcs.has(npc_key):
		var npc_node: Node2D = npcs[npc_key] as Node2D
		if is_instance_valid(npc_node) and npc_node.has_method("set_alert"):
			npc_node.call("set_alert", msg, is_warn)

func _show_alert(alert_info: Dictionary) -> void:
	_banner_btn.text = String(alert_info.get("text", ""))
	visible = true
	var tw: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.3)

func _hide_banner() -> void:
	if modulate.a > 0.0:
		var tw: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(self, "modulate:a", 0.0, 0.3)
		tw.tween_callback(func() -> void: visible = false)

func _on_banner_pressed() -> void:
	if _active_alerts.is_empty():
		return
	var cur: Dictionary = _active_alerts[_current_alert_idx]
	var target_pos: Vector2 = cur.get("pos", Vector2.ZERO) as Vector2
	if target_pos != Vector2.ZERO:
		alert_clicked.emit(target_pos)
		var farm: Node = main_farm if main_farm != null else get_tree().current_scene
		if farm != null:
			var cam_ctrl: CameraController = farm.get("camera_2d") as CameraController
			if cam_ctrl != null:
				cam_ctrl.pan_to_target(target_pos)
				AudioManager.play_sfx("click")
			else:
				var cam: Camera2D = farm.find_child("Camera2D", true, false) as Camera2D
				if cam != null:
					var tw: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
					tw.tween_property(cam, "position", target_pos, 0.8)
					AudioManager.play_sfx("click")
	
	if _active_alerts.size() > 1:
		_current_alert_idx = (_current_alert_idx + 1) % _active_alerts.size()
		_show_alert(_active_alerts[_current_alert_idx])
