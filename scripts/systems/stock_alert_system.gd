extends Control
class_name StockAlertSystem

## StockAlertSystem - Hệ thống Cảnh Báo NPC Chuyên Trách
## Hiển thị cảnh báo từ Thợ Bánh, Thợ Bánh Ngọt, Quầy Nước, Người Chăn Nuôi, Thủ Kho.
## Khi người chơi bấm vào thông báo, Camera tự động di chuyển mượt (Tween) đến đúng vị trí công trình!
## 100% Static Typing GDScript 2.0.

signal alert_clicked(target_pos: Vector2)

var _banner_btn: Button
var _timer: Timer
var _active_alerts: Array[Dictionary] = []
var _current_alert_idx: int = 0
var main_farm: Node2D = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(360, 36)
	size = Vector2(360, 36)
	
	# Định vị banner ở giữa phía trên màn hình (dưới thanh tiền tệ)
	position = Vector2(396.0, 52.0)
	
	_banner_btn = Button.new()
	_banner_btn.name = "AlertBannerButton"
	_banner_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_banner_btn.custom_minimum_size = Vector2(360, 34)
	_banner_btn.size = Vector2(360, 34)
	_banner_btn.text = "✨ Nông trại đang hoạt động êm ả!"
	_banner_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_btn.add_theme_font_size_override("font_size", 11)
	_banner_btn.add_theme_color_override("font_color", Color(0.24, 0.15, 0.08))
	_banner_btn.add_theme_color_override("font_hover_color", Color(0.85, 0.25, 0.05))
	
	# Phong cách Chibi Cozy
	var style_normal: StyleBoxFlat = StyleBoxFlat.new()
	style_normal.bg_color = Color(1.0, 0.97, 0.90, 0.95)
	style_normal.border_color = Color(0.75, 0.55, 0.35, 1.0)
	style_normal.set_border_width_all(2)
	style_normal.set_corner_radius_all(17)
	style_normal.content_margin_left = 12.0
	style_normal.content_margin_right = 12.0
	_banner_btn.add_theme_stylebox_override("normal", style_normal)
	
	var style_hover: StyleBoxFlat = style_normal.duplicate() as StyleBoxFlat
	style_hover.bg_color = Color(1.0, 1.0, 0.95, 1.0)
	style_hover.border_color = Color(0.92, 0.45, 0.15, 1.0)
	_banner_btn.add_theme_stylebox_override("hover", style_hover)
	
	_banner_btn.pressed.connect(_on_banner_pressed)
	add_child(_banner_btn)
	
	visible = false
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	
	# Timer quét định kỳ mỗi 4 giây
	_timer = Timer.new()
	_timer.name = "AlertCheckTimer"
	_timer.wait_time = 4.0
	_timer.autostart = true
	_timer.timeout.connect(_scan_stock_alerts)
	add_child(_timer)

func _scan_stock_alerts() -> void:
	_active_alerts.clear()
	
	# 1. Thợ làm bánh mì báo thiếu lúa mì
	if StorageManager.get_item_count("wheat") <= 1:
		_active_alerts.append({
			"text": "🥖 Thợ bánh: Hết lúa mì rồi, gieo thêm lúa mì nhé!",
			"pos": Vector2(496.0, 464.0)
		})
	
	# 2. Thợ làm bánh ngọt báo thiếu nguyên liệu
	if StorageManager.get_item_count("butter") <= 0 or StorageManager.get_item_count("egg") <= 0 or StorageManager.get_item_count("strawberry") <= 0:
		_active_alerts.append({
			"text": "🎂 Thợ bánh ngọt: Thiếu bơ, trứng và dâu tây!",
			"pos": Vector2(304.0, 464.0)
		})
	
	# 3. Pha chế quầy nước báo thiếu sữa / trái cây
	if StorageManager.get_item_count("milk") <= 0 or StorageManager.get_item_count("mango") <= 0 or StorageManager.get_item_count("apple") <= 0:
		_active_alerts.append({
			"text": "🍹 Quầy nước: Cần thêm sữa tươi và trái cây!",
			"pos": Vector2(752.0, 304.0)
		})
	
	# 4. Người chăn nuôi báo thú đói
	if StorageManager.get_item_count("chicken_feed") <= 0 or StorageManager.get_item_count("cow_feed") <= 0:
		_active_alerts.append({
			"text": "🐮 Người chăn nuôi: Hết thức ăn cho bầy thú rồi!",
			"pos": Vector2(352.0, 752.0)
		})
	
	# 5. Thủ kho báo kho đầy
	var silo_left: int = StorageManager.silo_capacity - StorageManager.get_silo_used()
	var barn_left: int = StorageManager.barn_capacity - StorageManager.get_barn_used()
	if silo_left <= 10 or barn_left <= 10:
		_active_alerts.append({
			"text": "📦 Thủ kho: Kho Silo hoặc Barn sắp đầy sức chứa!",
			"pos": Vector2(608.0, 288.0)
		})
	
	if _active_alerts.is_empty():
		_hide_banner()
	else:
		_current_alert_idx = (_current_alert_idx + 1) % _active_alerts.size()
		_show_alert(_active_alerts[_current_alert_idx])

func _show_alert(alert_info: Dictionary) -> void:
	_banner_btn.text = String(alert_info.get("text", ""))
	visible = true
	var tw: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.35)

func _hide_banner() -> void:
	if modulate.a > 0.0:
		var tw: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(self, "modulate:a", 0.0, 0.35)
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
				var tw: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tw.tween_property(cam, "position", target_pos, 0.6)
				AudioManager.play_sfx("click")
