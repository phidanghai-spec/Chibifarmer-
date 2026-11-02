class_name TitleScreen
extends Control

const CHAR_CREATOR_SCENE: String = "res://scenes/ui/CharacterCreator.tscn"
const MAIN_FARM_SCENE: String = "res://scenes/main/MainFarm.tscn"

@onready var balloon_sprite: Sprite2D = $LivePanoramaBg/HotAirBalloon
@onready var steamboat_sprite: Sprite2D = $LivePanoramaBg/RiverWater/SteamboatPreview
@onready var ducks_root: Node2D = $LivePanoramaBg/RiverWater/SwimmingDucks
@onready var rabbits_root: Node2D = $LivePanoramaBg/MeadowForeground/HoppingRabbits

@onready var btn_continue: Button = $UILayer/MainButtonsVBox/BtnContinue
@onready var btn_new_farm: Button = $UILayer/MainButtonsVBox/BtnNewFarm
@onready var btn_almanac: Button = $UILayer/MainButtonsVBox/BtnAlmanac
@onready var btn_settings: Button = $UILayer/MainButtonsVBox/BtnSettings
@onready var btn_exit: Button = $UILayer/MainButtonsVBox/BtnExit

@onready var save_slot_modal: PanelContainer = $UILayer/SaveSlotModal
@onready var slot_cards_hbox: HBoxContainer = $UILayer/SaveSlotModal.find_child("SlotCardsHBox", true, false) as HBoxContainer
@onready var settings_modal: PanelContainer = $UILayer/SettingsModal
@onready var btn_close_slots: Button = $UILayer/SaveSlotModal.find_child("BtnCloseSlots", true, false) as Button
@onready var btn_close_settings: Button = $UILayer/SettingsModal.find_child("BtnCloseSettings", true, false) as Button
@onready var btn_toggle_audio: Button = $UILayer/SettingsModal.find_child("BtnToggleAudio", true, false) as Button

var _time: float = 0.0
var _latest_slot: int = -1
var _balloon_origin: Vector2 = Vector2(220.0, 140.0)
var _steamboat_origin: Vector2 = Vector2(820.0, 390.0)

func _ready() -> void:
	save_slot_modal.visible = false
	settings_modal.visible = false
	
	if balloon_sprite != null:
		_balloon_origin = balloon_sprite.position
	if steamboat_sprite != null:
		_steamboat_origin = steamboat_sprite.position
		
	_refresh_continue_button()
	_bind_ui_signals()
	_populate_slot_cards()

func _process(delta: float) -> void:
	_time += delta
	_animate_live_panorama()

func _animate_live_panorama() -> void:
	# 1. Khinh khí cầu lượn nhẹ trên bầu trời
	if balloon_sprite != null:
		balloon_sprite.position.x = _balloon_origin.x + sin(_time * 0.35) * 45.0
		balloon_sprite.position.y = _balloon_origin.y + cos(_time * 0.7) * 14.0
		balloon_sprite.rotation = sin(_time * 0.5) * 0.04

	# 2. Tàu hơi nước nhấp nhô trên sông
	if steamboat_sprite != null:
		var bob: float = sin(_time * 2.2) * 3.5
		steamboat_sprite.position.y = _steamboat_origin.y + bob
		steamboat_sprite.scale = Vector2(1.0 + bob * 0.004, 1.0 - bob * 0.004)

	# 3. Đàn vịt bơi lướt sóng elip trên mặt hồ
	if ducks_root != null:
		var idx: int = 0
		for child: Node in ducks_root.get_children():
			if child is Node2D:
				var duck: Node2D = child as Node2D
				var phase: float = _time * 1.4 + float(idx) * 1.6
				duck.position = Vector2(cos(phase) * 36.0, sin(phase) * 14.0)
				duck.scale.x = -1.0 if sin(phase) > 0.0 else 1.0
				idx += 1

	# 4. Đàn thỏ nhảy parabol co giãn (hop arc squash & stretch)
	if rabbits_root != null:
		var r_idx: int = 0
		for child: Node in rabbits_root.get_children():
			if child is Node2D:
				var rabbit: Node2D = child as Node2D
				var hop_wave: float = abs(sin(_time * 4.5 + float(r_idx) * 2.1))
				rabbit.position.y = -hop_wave * 18.0
				rabbit.scale = Vector2(1.0 - hop_wave * 0.12, 1.0 + hop_wave * 0.15)
				r_idx += 1

func _refresh_continue_button() -> void:
	_latest_slot = SaveSlotService.get_latest_active_slot()
	if _latest_slot != -1:
		var summary: Dictionary = SaveSlotService.read_slot_summary(_latest_slot)
		var farm_name: String = str(summary.get("farm_name", "Nông Trại Chibi"))
		var level: int = int(summary.get("level", 1))
		btn_continue.disabled = false
		btn_continue.text = "TIẾP TỤC: %s (Cấp %d)" % [farm_name, level]
	else:
		btn_continue.disabled = true
		btn_continue.text = "CHƯA CÓ DỮ LIỆU LƯU"

func _bind_ui_signals() -> void:
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_new_farm.pressed.connect(_on_new_farm_pressed)
	btn_almanac.pressed.connect(_on_almanac_pressed)
	btn_settings.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_wood_click")
		settings_modal.visible = not settings_modal.visible
	)
	btn_exit.pressed.connect(_on_exit_pressed)
	
	if btn_close_slots != null:
		btn_close_slots.pressed.connect(func() -> void:
			AudioManager.play_sfx("ui_wood_click")
			save_slot_modal.visible = false
		)
	if btn_close_settings != null:
		btn_close_settings.pressed.connect(func() -> void:
			AudioManager.play_sfx("ui_wood_click")
			settings_modal.visible = false
		)
	if btn_toggle_audio != null:
		btn_toggle_audio.pressed.connect(func() -> void:
			AudioManager.is_muted = not AudioManager.is_muted
			btn_toggle_audio.text = "Âm Thanh: %s" % ("TẮT" if AudioManager.is_muted else "BẬT")
			AudioManager.play_sfx("ui_wood_click")
		)

func _get_target_farm_scene() -> String:
	if FileAccess.file_exists(MAIN_FARM_SCENE):
		return MAIN_FARM_SCENE
	return "res://scenes/main_farm.tscn"

func _on_continue_pressed() -> void:
	if _latest_slot == -1:
		return
	AudioManager.play_sfx("welcome_chime")
	EventBus.save_slot_selected.emit(_latest_slot, false)
	get_tree().change_scene_to_file(_get_target_farm_scene())

func _on_new_farm_pressed() -> void:
	AudioManager.play_sfx("ui_wood_click")
	_populate_slot_cards()
	save_slot_modal.visible = true

func _on_almanac_pressed() -> void:
	AudioManager.play_sfx("ui_wood_click")
	# Hiển thị thông báo hoặc mở sổ tay nông trại
	_populate_slot_cards()
	save_slot_modal.visible = true

func _populate_slot_cards() -> void:
	if slot_cards_hbox == null:
		return
	for child: Node in slot_cards_hbox.get_children():
		child.queue_free()
		
	for slot_idx: int in range(1, SaveSlotService.MAX_SLOTS + 1):
		var card: PanelContainer = _create_slot_card(slot_idx)
		slot_cards_hbox.add_child(card)

func _create_slot_card(slot_idx: int) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(240.0, 280.0)
	
	# Style cho card ô lưu
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.98, 0.94, 0.86, 0.96)
	style.border_color = Color(0.55, 0.32, 0.16, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0.3, 0.18, 0.08, 0.25)
	style.shadow_size = 6
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	
	var title_lbl: Label = Label.new()
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_color_override("font_color", Color(0.35, 0.18, 0.08, 1.0))
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.text = "🌾 Ô LƯU SỐ %d" % slot_idx
	vbox.add_child(title_lbl)
	
	var summary: Dictionary = SaveSlotService.read_slot_summary(slot_idx)
	var action_btn: Button = Button.new()
	action_btn.custom_minimum_size = Vector2(180, 42)
	
	if summary.is_empty():
		var empty_lbl: Label = Label.new()
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_color_override("font_color", Color(0.5, 0.4, 0.3, 1.0))
		empty_lbl.text = "[ Ô Đất Trống ]\nSẵn sàng khai hoang!"
		vbox.add_child(empty_lbl)
		
		action_btn.text = "Tạo Nông Trại Mới"
		action_btn.pressed.connect(func() -> void:
			AudioManager.play_sfx("welcome_chime")
			EventBus.save_slot_selected.emit(slot_idx, true)
			if FileAccess.file_exists(CHAR_CREATOR_SCENE):
				get_tree().change_scene_to_file(CHAR_CREATOR_SCENE)
			else:
				get_tree().change_scene_to_file(_get_target_farm_scene())
		)
		vbox.add_child(action_btn)
	else:
		var info_lbl: Label = Label.new()
		info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info_lbl.add_theme_color_override("font_color", Color(0.28, 0.16, 0.08, 1.0))
		var f_name: String = str(summary.get("farm_name", "Nông Trại"))
		var gold: int = int(summary.get("gold", 500))
		var lvl: int = int(summary.get("level", 1))
		info_lbl.text = "%s\nCấp độ: %d\nVàng: %d 🪙" % [f_name, lvl, gold]
		vbox.add_child(info_lbl)
		
		action_btn.text = "Vào Nông Trại Này"
		action_btn.pressed.connect(func() -> void:
			AudioManager.play_sfx("welcome_chime")
			EventBus.save_slot_selected.emit(slot_idx, false)
			get_tree().change_scene_to_file(_get_target_farm_scene())
		)
		vbox.add_child(action_btn)
		
		var del_btn: Button = Button.new()
		del_btn.custom_minimum_size = Vector2(120, 32)
		del_btn.text = "Xóa Ô Lưu"
		del_btn.pressed.connect(func() -> void:
			AudioManager.play_sfx("ui_wood_click")
			SaveSlotService.delete_slot(slot_idx)
			EventBus.save_slot_deleted.emit(slot_idx)
			_populate_slot_cards()
			_refresh_continue_button()
		)
		vbox.add_child(del_btn)
		
	return panel

func _on_exit_pressed() -> void:
	AudioManager.play_sfx("ui_wood_click")
	get_tree().quit()
