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
@onready var farmer_mai: Sprite2D = find_child("FarmerMai", true, false) as Sprite2D

@onready var cow_pet: Sprite2D = find_child("CowPet", true, false) as Sprite2D
@onready var sheep_pet: Sprite2D = find_child("SheepPet", true, false) as Sprite2D
@onready var pig_pet: Sprite2D = find_child("PigPet", true, false) as Sprite2D
@onready var chicken_pet: Sprite2D = find_child("ChickenPet", true, false) as Sprite2D
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
var _balloon_origin: Vector2 = Vector2(210.0, 115.0)
var _steamboat_origin: Vector2 = Vector2(1055.0, 495.0)

var _base_scales: Dictionary = {} # Node -> Vector2
var _base_positions: Dictionary = {} # Node -> Vector2

func _ready() -> void:
	save_slot_modal.visible = false
	settings_modal.visible = false
	
	if balloon_sprite != null:
		_balloon_origin = balloon_sprite.position
		_base_scales[balloon_sprite] = balloon_sprite.scale
	if steamboat_sprite != null:
		_steamboat_origin = steamboat_sprite.position
		_base_scales[steamboat_sprite] = steamboat_sprite.scale
		
	# Caching heroes
	if farmer_minh != null:
		_base_scales[farmer_minh] = farmer_minh.scale
		_base_positions[farmer_minh] = farmer_minh.position
	if farmer_mai != null:
		_base_scales[farmer_mai] = farmer_mai.scale
		_base_positions[farmer_mai] = farmer_mai.position
		
	# Caching animals
	if cow_pet != null:
		_base_scales[cow_pet] = cow_pet.scale
		_base_positions[cow_pet] = cow_pet.position
	if sheep_pet != null:
		_base_scales[sheep_pet] = sheep_pet.scale
		_base_positions[sheep_pet] = sheep_pet.position
	if pig_pet != null:
		_base_scales[pig_pet] = pig_pet.scale
		_base_positions[pig_pet] = pig_pet.position
	if chicken_pet != null:
		_base_scales[chicken_pet] = chicken_pet.scale
		_base_positions[chicken_pet] = chicken_pet.position
	if poodle_pet != null:
		_base_scales[poodle_pet] = poodle_pet.scale
		_base_positions[poodle_pet] = poodle_pet.position
		
	if ducks_root != null:
		for child: Node in ducks_root.get_children():
			if child is Node2D:
				var sp: Node2D = child as Node2D
				_base_scales[sp] = sp.scale

	if rabbits_root != null:
		for child: Node in rabbits_root.get_children():
			if child is Node2D:
				var sp: Node2D = child as Node2D
				if sp is Sprite2D and (sp as Sprite2D).texture != null:
					_base_scales[sp] = sp.scale
					_base_positions[sp] = sp.position

	if trees_root != null:
		for child: Node in trees_root.get_children():
			if child is Node2D:
				var sp: Node2D = child as Node2D
				_base_scales[sp] = sp.scale
		
	_refresh_continue_button()
	_bind_ui_signals()
	_populate_slot_cards()

func _process(delta: float) -> void:
	_time += delta
	_animate_live_panorama(delta)

func _animate_live_panorama(_delta: float) -> void:
	# 1. Khinh khí cầu lượn nhẹ trên bầu trời
	if balloon_sprite != null:
		balloon_sprite.position.x = _balloon_origin.x + sin(_time * 0.35) * 35.0
		balloon_sprite.position.y = _balloon_origin.y + cos(_time * 0.7) * 12.0
		balloon_sprite.rotation = sin(_time * 0.5) * 0.035

	# 2. Tàu hơi nước nhấp nhô trên sông
	if steamboat_sprite != null:
		var b_scale: Vector2 = _base_scales.get(steamboat_sprite, Vector2(0.68, 0.68))
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

	# 4. Đàn thỏ nhảy parabol co giãn (hop arc squash & stretch)
	if rabbits_root != null:
		var r_idx: int = 0
		for child: Node in rabbits_root.get_children():
			if child is Node2D:
				var rabbit: Node2D = child as Node2D
				if _base_positions.has(rabbit):
					var b_scale: Vector2 = _base_scales.get(rabbit, Vector2(0.1, 0.1))
					var b_pos: Vector2 = _base_positions.get(rabbit, rabbit.position)
					var hop_wave: float = abs(sin(_time * 4.5 + float(r_idx) * 2.1))
					rabbit.position.y = b_pos.y - hop_wave * 12.0
					rabbit.scale = b_scale * Vector2(1.0 - hop_wave * 0.10, 1.0 + hop_wave * 0.14)
				r_idx += 1

	# 5. Cây táo & cây hoa anh đào đung đưa theo gió
	if trees_root != null:
		var t_idx: int = 0
		for child: Node in trees_root.get_children():
			if child is Node2D:
				var tree: Node2D = child as Node2D
				var b_scale: Vector2 = _base_scales.get(tree, Vector2(0.13, 0.13))
				tree.rotation = sin(_time * 1.6 + float(t_idx) * 1.5) * 0.03
				var tree_sway: float = sin(_time * 2.0 + float(t_idx)) * 0.02
				tree.scale = b_scale * Vector2(1.0 + tree_sway, 1.0 - tree_sway)
				t_idx += 1

	# 6. Hero Characters (Farmer Minh bên trái & Farmer Mai bên phải) hướng và chỉ tay vào nút Chơi
	if farmer_minh != null:
		var b_scale: Vector2 = _base_scales.get(farmer_minh, Vector2(1.15, 1.15))
		var b_pos: Vector2 = _base_positions.get(farmer_minh, farmer_minh.position)
		var f_breath: float = sin(_time * 2.8) * 0.03
		var lean_angle: float = 0.05 + sin(_time * 2.2) * 0.025
		farmer_minh.rotation = lean_angle
		farmer_minh.scale = b_scale * Vector2(1.0 + f_breath, 1.0 - f_breath)
		farmer_minh.position.y = b_pos.y + sin(_time * 2.2) * 2.0

	if farmer_mai != null:
		var b_scale: Vector2 = _base_scales.get(farmer_mai, Vector2(1.15, 1.15))
		var b_pos: Vector2 = _base_positions.get(farmer_mai, farmer_mai.position)
		var f_breath: float = sin(_time * 2.8 + 1.2) * 0.03
		var lean_angle: float = -0.05 - sin(_time * 2.2 + 1.2) * 0.025
		farmer_mai.rotation = lean_angle
		farmer_mai.scale = b_scale * Vector2(1.0 + f_breath, 1.0 - f_breath)
		farmer_mai.position.y = b_pos.y + sin(_time * 2.2 + 1.2) * 2.0

	# 7. Đàn thú cưng quây quần vui nhộn (Bò, Cừu, Heo, Gà, Chó Poodle)
	if cow_pet != null:
		var b_scale: Vector2 = _base_scales.get(cow_pet, Vector2(0.75, 0.75))
		var chew: float = sin(_time * 3.2) * 0.03
		cow_pet.scale = b_scale * Vector2(1.0 + chew, 1.0 - chew)
		cow_pet.rotation = sin(_time * 1.8) * 0.025

	if sheep_pet != null:
		var b_scale: Vector2 = _base_scales.get(sheep_pet, Vector2(0.75, 0.75))
		var bob: float = sin(_time * 3.0 + 1.0) * 0.03
		sheep_pet.scale = b_scale * Vector2(1.0 - bob, 1.0 + bob)
		sheep_pet.rotation = -sin(_time * 1.7) * 0.02

	if pig_pet != null:
		var b_scale: Vector2 = _base_scales.get(pig_pet, Vector2(0.65, 0.65))
		var snuffle: float = sin(_time * 4.2) * 0.035
		pig_pet.scale = b_scale * Vector2(1.0 + snuffle, 1.0 - snuffle)

	if chicken_pet != null:
		var b_scale: Vector2 = _base_scales.get(chicken_pet, Vector2(0.65, 0.65))
		var peck: float = abs(sin(_time * 5.0)) * 0.06
		chicken_pet.scale = b_scale * Vector2(1.0 + peck * 0.5, 1.0 - peck)
		chicken_pet.rotation = -peck * 0.2

	if poodle_pet != null:
		var b_scale: Vector2 = _base_scales.get(poodle_pet, Vector2(0.55, 0.55))
		var p_breath: float = sin(_time * 3.8) * 0.04
		poodle_pet.scale = b_scale * Vector2(1.0 + p_breath, 1.0 - p_breath)
		poodle_pet.rotation = sin(_time * 4.0) * 0.03

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
		card.custom_minimum_size = Vector2(210.0, 260.0)
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
			var player_name: String = str(summary.get("player_name", "Nông Dân"))
			var level: int = int(summary.get("level", 1))
			var gold: int = int(summary.get("gold", 0))
			info_lbl.text = "🌱 %s\n🧑 Chủ: %s\n⭐ Cấp độ: %d\n🪙 Vàng: %d" % [farm_name, player_name, level, gold]
		vbox.add_child(info_lbl)
		
		var btn_green_sb: StyleBoxFlat = StyleBoxFlat.new()
		btn_green_sb.bg_color = Color(0.42, 0.72, 0.25, 1.0)
		btn_green_sb.border_color = Color(0.22, 0.44, 0.12, 1.0)
		btn_green_sb.set_border_width_all(2)
		btn_green_sb.border_width_bottom = 3
		btn_green_sb.set_corner_radius_all(10)

		var btn_wood_sb: StyleBoxFlat = StyleBoxFlat.new()
		btn_wood_sb.bg_color = Color(0.96, 0.73, 0.19, 1.0)
		btn_wood_sb.border_color = Color(0.48, 0.26, 0.12, 1.0)
		btn_wood_sb.set_border_width_all(2)
		btn_wood_sb.border_width_bottom = 3
		btn_wood_sb.set_corner_radius_all(10)

		if is_empty:
			var btn_action: Button = Button.new()
			btn_action.custom_minimum_size = Vector2(0.0, 36.0)
			btn_action.text = "CHỌN LẬP MỚI"
			btn_action.add_theme_stylebox_override("normal", btn_green_sb)
			btn_action.add_theme_stylebox_override("hover", btn_green_sb)
			btn_action.add_theme_color_override("font_color", Color.WHITE)
			btn_action.pressed.connect(func() -> void:
				AudioManager.play_sfx("ui_wood_click")
				SaveManager.current_slot = slot_idx
				SaveManager.reset_to_level_1()
				get_tree().change_scene_to_file(CHAR_CREATOR_SCENE)
			)
			vbox.add_child(btn_action)
		else:
			var btn_continue: Button = Button.new()
			btn_continue.custom_minimum_size = Vector2(0.0, 34.0)
			btn_continue.text = "TIẾP TỤC"
			btn_continue.add_theme_stylebox_override("normal", btn_green_sb)
			btn_continue.add_theme_stylebox_override("hover", btn_green_sb)
			btn_continue.add_theme_color_override("font_color", Color.WHITE)
			btn_continue.pressed.connect(func() -> void:
				AudioManager.play_sfx("ui_wood_click")
				SaveManager.current_slot = slot_idx
				EventBus.save_slot_selected.emit(slot_idx, false)
				get_tree().change_scene_to_file(_get_target_farm_scene())
			)
			vbox.add_child(btn_continue)

			var btn_new: Button = Button.new()
			btn_new.custom_minimum_size = Vector2(0.0, 28.0)
			btn_new.text = "🔄 LẬP MỚI (CẤP 1)"
			btn_new.add_theme_font_size_override("font_size", 11)
			btn_new.add_theme_stylebox_override("normal", btn_wood_sb)
			btn_new.add_theme_stylebox_override("hover", btn_wood_sb)
			btn_new.add_theme_color_override("font_color", Color(0.28, 0.14, 0.05, 1.0))
			btn_new.pressed.connect(func() -> void:
				AudioManager.play_sfx("ui_wood_click")
				SaveManager.current_slot = slot_idx
				SaveManager.reset_to_level_1()
				get_tree().change_scene_to_file(CHAR_CREATOR_SCENE)
			)
			vbox.add_child(btn_new)
		slot_cards_hbox.add_child(card)
