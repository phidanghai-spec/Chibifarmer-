class_name TitleScreen
extends Control

const CHAR_CREATOR_SCENE: String = "res://scenes/ui/CharacterCreator.tscn"
const MAIN_FARM_SCENE: String = "res://scenes/main/MainFarm.tscn"

@onready var balloon_sprite: Sprite2D = find_child("HotAirBalloon", true, false) as Sprite2D
@onready var steamboat_sprite: Sprite2D = find_child("SteamboatPreview", true, false) as Sprite2D
@onready var ducks_root: Node2D = find_child("SwimmingDucks", true, false) as Node2D
@onready var rabbits_root: Node2D = find_child("HoppingRabbits", true, false) as Node2D
@onready var trees_root: Node2D = find_child("SwayingAppleTrees", true, false) as Node2D
@onready var farmer_minh: Sprite2D = find_child("FarmerMinh", true, false) as Sprite2D
@onready var poodle_pet: Sprite2D = find_child("PoodlePet", true, false) as Sprite2D

@onready var btn_continue: Button = $UILayer/MainButtonsVBox/BtnContinue
@onready var btn_new_farm: Button = $UILayer/MainButtonsVBox/BtnNewFarm
@onready var btn_almanac: Button = $UILayer/MainButtonsVBox/BtnAlmanac
@onready var btn_settings: Button = $UILayer/MainButtonsVBox/BtnSettings
@onready var btn_exit: Button = $UILayer/MainButtonsVBox/BtnExit

@onready var save_slot_modal: PanelContainer = $UILayer/SaveSlotModal
@onready var slot_cards_hbox: HBoxContainer = $UILayer/SaveSlotModal.find_child("SlotCardsHBox", true, false) as HBoxContainer
@onready var settings_modal: PanelContainer = $UILayer/SettingsModal
@onready var farm_almanac_modal: FarmAlmanacModal = $UILayer/FarmAlmanacModal
@onready var btn_close_slots: Button = $UILayer/SaveSlotModal.find_child("BtnCloseSlots", true, false) as Button
@onready var btn_close_settings: Button = $UILayer/SettingsModal.find_child("BtnCloseSettings", true, false) as Button
@onready var btn_toggle_audio: Button = $UILayer/SettingsModal.find_child("BtnToggleAudio", true, false) as Button
@onready var btn_reset_sandbox: Button = $UILayer/SettingsModal.find_child("BtnResetSandbox", true, false) as Button

var _time: float = 0.0
var _latest_slot: int = -1
var _balloon_origin: Vector2 = Vector2(185.0, 120.0)
var _steamboat_origin: Vector2 = Vector2(1040.0, 505.0)

var _base_scales: Dictionary = {} # Node -> Vector2

func _ready() -> void:
	save_slot_modal.visible = false
	settings_modal.visible = false
	
	if balloon_sprite != null:
		_balloon_origin = balloon_sprite.position
		_base_scales[balloon_sprite] = balloon_sprite.scale
	if steamboat_sprite != null:
		_steamboat_origin = steamboat_sprite.position
		_base_scales[steamboat_sprite] = steamboat_sprite.scale
	if farmer_minh != null:
		_base_scales[farmer_minh] = farmer_minh.scale
	if poodle_pet != null:
		_base_scales[poodle_pet] = poodle_pet.scale
		
	if ducks_root != null:
		for child: Node in ducks_root.get_children():
			if child is Node2D:
				_base_scales[child] = (child as Node2D).scale

	if rabbits_root != null:
		for child: Node in rabbits_root.get_children():
			if child is Node2D:
				var sp: Node2D = child as Node2D
				# Enforce reasonable Chibi display size
				if sp is Sprite2D and (sp as Sprite2D).texture != null:
					var tw: float = float((sp as Sprite2D).texture.get_width())
					if tw > 100.0:
						sp.scale = Vector2(36.0 / tw, 36.0 / tw)
				_base_scales[sp] = sp.scale

	if trees_root != null:
		for child: Node in trees_root.get_children():
			if child is Node2D:
				var sp: Node2D = child as Node2D
				if sp is Sprite2D and (sp as Sprite2D).texture != null:
					var tw: float = float((sp as Sprite2D).texture.get_width())
					if tw > 200.0:
						sp.scale = Vector2(96.0 / tw, 96.0 / tw)
				_base_scales[sp] = sp.scale
		
	_refresh_continue_button()
	_bind_ui_signals()
	_populate_slot_cards()

func _process(delta: float) -> void:
	_time += delta
	_animate_live_panorama()

func _animate_live_panorama() -> void:
	# 1. Khinh khí cầu lượn nhẹ trên bầu trời
	if balloon_sprite != null:
		balloon_sprite.position.x = _balloon_origin.x + sin(_time * 0.35) * 35.0
		balloon_sprite.position.y = _balloon_origin.y + cos(_time * 0.7) * 12.0
		balloon_sprite.rotation = sin(_time * 0.5) * 0.035

	# 2. Tàu hơi nước nhấp nhô trên sông (Strictly preserving _base_scale)
	if steamboat_sprite != null:
		var b_scale: Vector2 = _base_scales.get(steamboat_sprite, Vector2(0.72, 0.72))
		var bob: float = sin(_time * 2.2) * 3.0
		steamboat_sprite.position.y = _steamboat_origin.y + bob
		steamboat_sprite.scale = b_scale * Vector2(1.0 + bob * 0.005, 1.0 - bob * 0.005)

	# 3. Đàn vịt bơi lướt sóng elip trên mặt hồ
	if ducks_root != null:
		var idx: int = 0
		for child: Node in ducks_root.get_children():
			if child is Node2D:
				var duck: Node2D = child as Node2D
				var b_scale: Vector2 = _base_scales.get(duck, Vector2(0.10, 0.10))
				var phase: float = _time * 1.4 + float(idx) * 1.6
				duck.position = Vector2(cos(phase) * 28.0, sin(phase) * 10.0)
				duck.scale.x = (-b_scale.x) if sin(phase) > 0.0 else b_scale.x
				idx += 1

	# 4. Đàn thỏ nhảy parabol co giãn (hop arc squash & stretch - NEVER overwrite scale to 1.0)
	if rabbits_root != null:
		var r_idx: int = 0
		for child: Node in rabbits_root.get_children():
			if child is Node2D:
				var rabbit: Node2D = child as Node2D
				var b_scale: Vector2 = _base_scales.get(rabbit, Vector2(0.08, 0.08))
				var hop_wave: float = abs(sin(_time * 4.5 + float(r_idx) * 2.1))
				rabbit.position.y = -hop_wave * 14.0
				rabbit.scale = b_scale * Vector2(1.0 - hop_wave * 0.12, 1.0 + hop_wave * 0.15)
				r_idx += 1

	# 5. Cây táo đung đưa theo gió
	if trees_root != null:
		var t_idx: int = 0
		for child: Node in trees_root.get_children():
			if child is Node2D:
				var tree: Node2D = child as Node2D
				var b_scale: Vector2 = _base_scales.get(tree, Vector2(0.12, 0.12))
				tree.rotation = sin(_time * 1.6 + float(t_idx) * 1.5) * 0.03
				var tree_sway: float = sin(_time * 2.0 + float(t_idx)) * 0.02
				tree.scale = b_scale * Vector2(1.0 + tree_sway, 1.0 - tree_sway)
				t_idx += 1

	# 6. Farmer Minh & Poodle Pet Idle Breathing
	if farmer_minh != null:
		var b_scale: Vector2 = _base_scales.get(farmer_minh, Vector2(0.38, 0.38))
		var f_breath: float = sin(_time * 2.8) * 0.025
		farmer_minh.scale = b_scale * Vector2(1.0 + f_breath, 1.0 - f_breath)
	if poodle_pet != null:
		var b_scale: Vector2 = _base_scales.get(poodle_pet, Vector2(0.55, 0.55))
		var p_breath: float = sin(_time * 3.5) * 0.035
		poodle_pet.scale = b_scale * Vector2(1.0 + p_breath, 1.0 - p_breath)

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
	if btn_reset_sandbox != null:
		btn_reset_sandbox.pressed.connect(func() -> void:
			AudioManager.play_sfx("level_up")
			SaveManager.set_sandbox_level_33()
			settings_modal.visible = false
			_refresh_continue_button()
			_populate_slot_cards()
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
	if farm_almanac_modal != null:
		farm_almanac_modal.open_modal()

func _on_exit_pressed() -> void:
	AudioManager.play_sfx("ui_wood_click")
	get_tree().quit()

func _populate_slot_cards() -> void:
	if slot_cards_hbox == null:
		return
		
	for child: Node in slot_cards_hbox.get_children():
		child.queue_free()
		
	for slot_idx: int in range(1, 4):
		var card: PanelContainer = PanelContainer.new()
		card.custom_minimum_size = Vector2(210.0, 230.0)
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(0.98, 0.94, 0.85, 1.0)
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
		style.border_color = Color(0.55, 0.32, 0.16, 1.0)
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_right = 12
		style.corner_radius_bottom_left = 12
		card.add_theme_stylebox_override("panel", style)
		
		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 8)
		card.add_child(vbox)
		
		var title: Label = Label.new()
		title.text = "Ô LƯU %d" % slot_idx
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 16)
		title.add_theme_color_override("font_color", Color(0.35, 0.18, 0.08, 1.0))
		vbox.add_child(title)
		
		var summary: Dictionary = SaveSlotService.read_slot_summary(slot_idx)
		var is_empty: bool = bool(summary.get("is_empty", true))
		
		var info_lbl: Label = Label.new()
		info_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		info_lbl.add_theme_font_size_override("font_size", 13)
		info_lbl.add_theme_color_override("font_color", Color(0.42, 0.24, 0.12, 1.0))
		
		if is_empty:
			info_lbl.text = "\n[Ô Đất Trống]\nChưa có nông trại\nSẵn sàng khai hoang!"
		else:
			var farm_name: String = str(summary.get("farm_name", "Nông Trại"))
			var player_name: String = str(summary.get("player_name", "Minh"))
			var level: int = int(summary.get("level", 1))
			var gold: int = int(summary.get("gold", 0))
			info_lbl.text = "🌱 %s\n🧑 Chủ: %s\n⭐ Cấp độ: %d\n🪙 Vàng: %d" % [farm_name, player_name, level, gold]
		vbox.add_child(info_lbl)
		
		var btn_action: Button = Button.new()
		btn_action.custom_minimum_size = Vector2(0.0, 36.0)
		btn_action.text = "CHỌN LẬP MỚI" if is_empty else "TIẾP TỤC"
		btn_action.pressed.connect(func() -> void:
			AudioManager.play_sfx("ui_wood_click")
			if is_empty:
				SaveManager.current_slot = slot_idx
				get_tree().change_scene_to_file(CHAR_CREATOR_SCENE)
			else:
				SaveManager.current_slot = slot_idx
				EventBus.save_slot_selected.emit(slot_idx, false)
				get_tree().change_scene_to_file(_get_target_farm_scene())
		)
		vbox.add_child(btn_action)
		slot_cards_hbox.add_child(card)
