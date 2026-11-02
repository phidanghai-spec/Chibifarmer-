class_name OfflineReportModal
extends PanelContainer

## OfflineReportModal
## Hộp thoại thông báo sản lượng nông sản & tiền vé Vườn Thú Bờ Tây trong thời gian vắng mặt.
## 100% Static Typing GDScript 2.0.

@onready var away_duration_label: Label = $ReportVBox/AwayDurationLabel
@onready var summary_vbox: VBoxContainer = $ReportVBox/SummaryStatsVBox
@onready var btn_claim: Button = $ReportVBox/BtnClaimOfflineRewards
@onready var chest_banner: TextureRect = $ReportVBox/ChestBannerRect

var _pending_gold: int = 0
var _pending_honey: int = 0
var _pending_crops: int = 0

func _ready() -> void:
	visible = false
	if btn_claim != null:
		btn_claim.pressed.connect(_on_claim_pressed)
	
	if chest_banner != null and SpriteAtlasManager != null:
		var tex: Texture2D = SpriteAtlasManager.get_texture("ui_offline_chest_banner")
		if tex != null:
			chest_banner.texture = tex
			
	EventBus.offline_earnings_calculated.connect(_on_offline_earnings_calculated)

func _on_offline_earnings_calculated(elapsed_seconds: int, summary_data: Dictionary) -> void:
	var minutes: int = int(summary_data.get("elapsed_minutes", elapsed_seconds / 60))
	var hours: int = minutes / 60
	var rem_mins: int = minutes % 60
	
	if away_duration_label != null:
		if hours > 0:
			away_duration_label.text = "Thời gian bạn vắng nhà: %d giờ %d phút" % [hours, rem_mins]
		else:
			away_duration_label.text = "Thời gian bạn vắng nhà: %d phút" % [rem_mins]
		
	_pending_gold = int(summary_data.get("passive_zoo_gold", 0))
	_pending_honey = int(summary_data.get("honey_collected", 0))
	_pending_crops = int(summary_data.get("ripened_crops_count", 0))
	
	_rebuild_summary_rows(_pending_crops, _pending_honey, _pending_gold)
	
	# Hiển thị modal với hiệu ứng nảy nhẹ nhàng
	visible = true
	scale = Vector2(0.85, 0.85)
	pivot_offset = size * 0.5
	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.28)
	
	AudioManager.play_sfx("welcome_chime")

func _rebuild_summary_rows(crops_ready: int, honey_count: int, zoo_gold: int) -> void:
	if summary_vbox == null:
		return
	for child: Node in summary_vbox.get_children():
		child.queue_free()
		
	var lines: Array[String] = [
		"🌾 Ruộng đất & Cây ăn quả (Táo, Xoài) đã chín: +%d ô" % crops_ready,
		"🍯 Đàn ong mật chăm chỉ thu hoạch: +%d Hũ mật ong" % honey_count,
		"🎟️ Vé tham quan Vườn Thú Bờ Tây (Capybara, Panda): +%d Vàng" % zoo_gold
	]
	
	for line_text: String in lines:
		var panel: PanelContainer = PanelContainer.new()
		var pstyle: StyleBoxFlat = StyleBoxFlat.new()
		pstyle.bg_color = Color(0.96, 0.91, 0.82, 0.9)
		pstyle.set_corner_radius_all(6)
		pstyle.content_margin_left = 12
		pstyle.content_margin_right = 12
		pstyle.content_margin_top = 6
		pstyle.content_margin_bottom = 6
		panel.add_theme_stylebox_override("panel", pstyle)
		
		var lbl: Label = Label.new()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lbl.add_theme_color_override("font_color", Color(0.28, 0.18, 0.10, 1.0))
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.text = line_text
		panel.add_child(lbl)
		summary_vbox.add_child(panel)

func _on_claim_pressed() -> void:
	AudioManager.play_sfx("coins_jingle")
	
	if has_node("/root/StorageManager"):
		var sm: Node = get_node("/root/StorageManager")
		if _pending_gold > 0 and sm.has_method("add_gold"):
			sm.call("add_gold", _pending_gold)
		if _pending_honey > 0:
			if sm.has_method("add_item_to_barn"):
				sm.call("add_item_to_barn", "honey", _pending_honey)
			elif sm.has_method("add_item"):
				sm.call("add_item", "honey", _pending_honey)
			
	EventBus.offline_report_claimed.emit(_pending_gold)
	
	# Thu nhỏ biến mất
	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(0.8, 0.8), 0.18)
	tween.tween_callback(func() -> void:
		visible = false
		scale = Vector2.ONE
	)

