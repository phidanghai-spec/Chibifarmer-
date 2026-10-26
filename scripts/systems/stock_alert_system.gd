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
	custom_minimum_size = Vector2(240, 36)
	size = Vector2(240, 36)
	
	# Đặt bảng cảnh báo ở góc phải trên màn hình, ngay dưới nút Âm thanh (TopRightHUD)
	anchors_preset = Control.PRESET_TOP_RIGHT
	anchor_left = 1.0
	anchor_right = 1.0
	offset_left = -250.0
	offset_top = 56.0
	offset_right = -18.0
	offset_bottom = 92.0
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	
	_banner_btn = Button.new()
	_banner_btn.name = "AlertBannerButton"
	_banner_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_banner_btn.custom_minimum_size = Vector2(232, 34)
	_banner_btn.size = Vector2(232, 34)
	_banner_btn.text = "✨ Nông trại êm ả!"
	_banner_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_btn.add_theme_font_size_override("font_size", 10)
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
	_timer.autostart = false
	_timer.timeout.connect(_scan_stock_alerts)
	add_child(_timer)

func register_npc(npc_key: String, npc_node: Node2D) -> void:
	npcs[npc_key] = npc_node

func _scan_stock_alerts() -> void:
	_active_alerts.clear()
	_update_npc_bubble("baker", "🍞 Bánh Đã Sẵn!", false)
	_update_npc_bubble("pastry", "🍰 Bánh Kem Xong!", false)
	_update_npc_bubble("barista", "🧃 Nước Mát Lạnh!", false)
	_update_npc_bubble("rancher", "🥛 Bầy Thú No Nê!", false)
	if npcs.has("keeper"):
		_update_npc_bubble("keeper", "🌾 Kho Sẵn Sàng!", false)
	if npcs.has("fisher"):
		_update_npc_bubble("fisher", "🎣 Sẵn Sàng!", false)
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
		if main_farm != null and main_farm.get("camera_2d") != null:
			var cam: CameraController = main_farm.get("camera_2d") as CameraController
			if cam != null:
				cam.pan_to_target(target_pos)
				AudioManager.play_sfx("click")
