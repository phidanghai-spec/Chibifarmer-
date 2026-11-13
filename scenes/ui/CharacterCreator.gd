class_name CharacterCreator
extends Control

const TITLE_SCENE_PATH: String = "res://scenes/ui/TitleScreen.tscn"
const MAIN_FARM_SCENE_PATH: String = "res://scenes/main/MainFarm.tscn"
const TAB_KEYS: Array[String] = ["body", "hair", "outfit", "poodle"]

@onready var avatar_preview: ModularChibiAvatar = $MainSplitHBox/LeftStagePanel/StageVBox/PreviewViewportContainer/SubViewport/AvatarPreview
@onready var poodle_preview: Sprite2D = $MainSplitHBox/LeftStagePanel/StageVBox/PreviewViewportContainer/SubViewport/PetPoodlePreview

@onready var btn_pose_idle: Button = $MainSplitHBox/LeftStagePanel/StageVBox/AnimTestHBox/BtnPoseIdle
@onready var btn_pose_walk: Button = $MainSplitHBox/LeftStagePanel/StageVBox/AnimTestHBox/BtnPoseWalk
@onready var btn_pose_harvest: Button = $MainSplitHBox/LeftStagePanel/StageVBox/AnimTestHBox/BtnPoseHarvest
@onready var btn_pose_fish: Button = $MainSplitHBox/LeftStagePanel/StageVBox/AnimTestHBox/BtnPoseFish
@onready var btn_randomize: Button = $MainSplitHBox/LeftStagePanel/StageVBox/BtnRandomize

@onready var btn_preset_boy: Button = $MainSplitHBox/RightCustomizationPanel/RightVBox/PresetHBox/BtnPresetBoy
@onready var btn_preset_girl: Button = $MainSplitHBox/RightCustomizationPanel/RightVBox/PresetHBox/BtnPresetGirl
@onready var btn_outfit_overalls: Button = $MainSplitHBox/RightCustomizationPanel/RightVBox/QuickOutfitsHBox/BtnOutfitOveralls
@onready var btn_outfit_dress: Button = $MainSplitHBox/RightCustomizationPanel/RightVBox/QuickOutfitsHBox/BtnOutfitDress
@onready var btn_outfit_baker: Button = $MainSplitHBox/RightCustomizationPanel/RightVBox/QuickOutfitsHBox/BtnOutfitBaker
@onready var btn_outfit_carpenter: Button = $MainSplitHBox/RightCustomizationPanel/RightVBox/QuickOutfitsHBox/BtnOutfitCarpenter

@onready var category_tabs: TabBar = $MainSplitHBox/RightCustomizationPanel/RightVBox/CategoryTabs
@onready var options_grid: GridContainer = $MainSplitHBox/RightCustomizationPanel/RightVBox/OptionsGridScroll/OptionsGrid
@onready var input_player_name: LineEdit = $MainSplitHBox/RightCustomizationPanel/RightVBox/IdentityFormHBox/InputPlayerName
@onready var input_farm_name: LineEdit = $MainSplitHBox/RightCustomizationPanel/RightVBox/IdentityFormHBox/InputFarmName
@onready var btn_back: Button = $MainSplitHBox/RightCustomizationPanel/RightVBox/BottomActionsHBox/BtnBackToTitle
@onready var btn_start_farm: Button = $MainSplitHBox/RightCustomizationPanel/RightVBox/BottomActionsHBox/BtnStartFarm

var active_slot_index: int = 1
var _catalog: Dictionary = {}
var _current_gender: String = "male"

func _ready() -> void:
	var sm: Node = get_node_or_null("/root/SaveManager")
	if sm != null and sm.has_method("get"):
		active_slot_index = int(sm.get("current_slot"))
		if active_slot_index <= 0:
			active_slot_index = 1
			
	_load_catalog_data()
	_setup_tabs()
	_bind_buttons()
	_populate_category_options(0)
	
	# Default preset: Male
	_apply_preset("male")

func _load_catalog_data() -> void:
	var dm: Node = get_node_or_null("/root/DataManager")
	if dm != null and dm.get("avatar_catalog") != null and not (dm.get("avatar_catalog") as Dictionary).is_empty():
		_catalog = dm.get("avatar_catalog") as Dictionary
	else:
		_catalog = {
			"body": [
				{"id": "body_warm_ivory", "name": "Da Kem Ấm", "sub": "eyes_sparkle_brown"},
				{"id": "body_peach_sunny", "name": "Da Hồng Nắng", "sub": "eyes_emerald_gentle"},
				{"id": "body_honey_tan", "name": "Da Mật Ong", "sub": "eyes_happy_arc"},
				{"id": "body_cocoa_warm", "name": "Da Nâu Ấm", "sub": "eyes_sky_bright"}
			],
			"hair": [
				{"id": "hair_short_sunny", "name": "Tóc Ngắn Nắng + Mũ Rơm", "hat": "hat_straw_ribbon"},
				{"id": "hair_braid_chestnut", "name": "Tóc Bím Hạt Dẻ + Mũ Rơm", "hat": "hat_straw_ribbon"},
				{"id": "hair_bun_baker", "name": "Tóc Búi Bếp + Mũ Toque", "hat": "hat_chef_toque"},
				{"id": "hair_curly_berry", "name": "Tóc Xoăn Tự Nhiên", "hat": "hat_postman_cap"}
			],
			"outfit": [
				{"id": "outfit_denim_overalls", "name": "Yếm Jean Nông Dân"},
				{"id": "outfit_floral_dress", "name": "Váy Hoa Đồng Nội"},
				{"id": "outfit_baker_apron", "name": "Tạp Dề Lò Bánh"},
				{"id": "outfit_carpenter_vest", "name": "Áo Khoác Thợ Mộc"}
			],
			"poodle": [
				{"id": "poodle_apricot_red", "name": "Poodle Vàng Mơ"},
				{"id": "poodle_cream_blue", "name": "Poodle Trắng Kem"},
				{"id": "poodle_choco_yellow", "name": "Poodle Socola"}
			]
		}

func _setup_tabs() -> void:
	if category_tabs == null:
		return
	category_tabs.clear_tabs()
	category_tabs.add_tab("1. Diện Mạo")
	category_tabs.add_tab("2. Tóc & Mũ")
	category_tabs.add_tab("3. Trang Phục")
	category_tabs.add_tab("4. Chó Poodle")
	var tab_sel: StyleBoxFlat = StyleBoxFlat.new()
	tab_sel.bg_color = Color(0.96, 0.73, 0.19, 1.0)
	tab_sel.border_color = Color(0.48, 0.26, 0.12, 1.0)
	tab_sel.set_border_width_all(2)
	tab_sel.corner_radius_top_left = 10
	tab_sel.corner_radius_top_right = 10
	tab_sel.content_margin_left = 14
	tab_sel.content_margin_right = 14
	tab_sel.content_margin_top = 6
	tab_sel.content_margin_bottom = 6
	var tab_unsel: StyleBoxFlat = StyleBoxFlat.new()
	tab_unsel.bg_color = Color(0.93, 0.86, 0.74, 1.0)
	tab_unsel.border_color = Color(0.62, 0.42, 0.24, 1.0)
	tab_unsel.set_border_width_all(2)
	tab_unsel.corner_radius_top_left = 10
	tab_unsel.corner_radius_top_right = 10
	tab_unsel.content_margin_left = 14
	tab_unsel.content_margin_right = 14
	tab_unsel.content_margin_top = 6
	tab_unsel.content_margin_bottom = 6
	category_tabs.add_theme_stylebox_override("tab_selected", tab_sel)
	category_tabs.add_theme_stylebox_override("tab_unselected", tab_unsel)
	category_tabs.add_theme_stylebox_override("tab_hovered", tab_sel)
	category_tabs.add_theme_color_override("font_selected_color", Color(0.24, 0.11, 0.03, 1.0))
	category_tabs.add_theme_color_override("font_unselected_color", Color(0.42, 0.25, 0.12, 1.0))
	category_tabs.add_theme_color_override("font_hovered_color", Color(0.24, 0.11, 0.03, 1.0))
	var input_sb: StyleBoxFlat = StyleBoxFlat.new()
	input_sb.bg_color = Color(1.0, 0.98, 0.92, 1.0)
	input_sb.border_color = Color(0.55, 0.34, 0.16, 1.0)
	input_sb.set_border_width_all(2)
	input_sb.set_corner_radius_all(10)
	input_sb.content_margin_left = 12
	input_sb.content_margin_right = 12
	for le: LineEdit in [input_player_name, input_farm_name]:
		if le != null:
			le.add_theme_stylebox_override("normal", input_sb)
			le.add_theme_stylebox_override("focus", input_sb)
			le.add_theme_color_override("font_color", Color(0.25, 0.12, 0.04, 1.0))
			le.add_theme_color_override("font_placeholder_color", Color(0.55, 0.40, 0.26, 0.8))
	if input_player_name != null:
		input_player_name.text_changed.connect(func(_new_text: String) -> void:
			input_player_name.add_theme_stylebox_override("normal", input_sb)
			input_player_name.add_theme_stylebox_override("focus", input_sb)
		)
	category_tabs.tab_changed.connect(_populate_category_options)

func _bind_buttons() -> void:
	btn_preset_boy.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_wood_click")
		_apply_preset("male")
	)
	btn_preset_girl.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_wood_click")
		_apply_preset("female")
	)
	
	btn_outfit_overalls.pressed.connect(func() -> void:
		_apply_quick_outfit("outfit_denim_overalls", "hat_straw_ribbon")
	)
	btn_outfit_dress.pressed.connect(func() -> void:
		_apply_quick_outfit("outfit_floral_dress", "hat_none")
	)
	btn_outfit_baker.pressed.connect(func() -> void:
		_apply_quick_outfit("outfit_baker_apron", "hat_chef_toque")
	)
	btn_outfit_carpenter.pressed.connect(func() -> void:
		_apply_quick_outfit("outfit_carpenter_vest", "hat_postman_cap")
	)

	btn_pose_idle.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_wood_click")
		avatar_preview.set_preview_action(ModularChibiAvatar.PreviewMode.IDLE)
	)
	btn_pose_walk.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_wood_click")
		avatar_preview.set_preview_action(ModularChibiAvatar.PreviewMode.WALK)
	)
	btn_pose_harvest.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_wood_click")
		avatar_preview.set_preview_action(ModularChibiAvatar.PreviewMode.HARVEST)
	)
	btn_pose_fish.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_wood_click")
		avatar_preview.set_preview_action(ModularChibiAvatar.PreviewMode.FISH)
	)
	
	btn_randomize.pressed.connect(_on_randomize_pressed)
	btn_back.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_wood_click")
		get_tree().change_scene_to_file(TITLE_SCENE_PATH)
	)
	btn_start_farm.pressed.connect(_on_confirm_start_farm)

func _apply_preset(gender: String) -> void:
	_current_gender = gender
	if avatar_preview == null:
		return
	if gender == "male":
		avatar_preview.equip_part("gender", "male")
		avatar_preview.equip_part("body", "body_warm_ivory")
		avatar_preview.equip_part("eyes", "eyes_sparkle_brown")
		avatar_preview.equip_part("hair", "hair_short_sunny")
		avatar_preview.equip_part("hat", "hat_straw_ribbon")
		avatar_preview.equip_part("outfit", "outfit_denim_overalls")
		avatar_preview.equip_part("tool", "tool_sickle_chibi")
		if input_farm_name.text.is_empty():
			input_farm_name.text = "Nông Trại Nắng Ấm"
	else:
		avatar_preview.equip_part("gender", "female")
		avatar_preview.equip_part("body", "body_peach_sunny")
		avatar_preview.equip_part("eyes", "eyes_emerald_gentle")
		avatar_preview.equip_part("hair", "hair_braid_chestnut")
		avatar_preview.equip_part("hat", "hat_straw_ribbon")
		avatar_preview.equip_part("outfit", "outfit_floral_dress")
		avatar_preview.equip_part("tool", "tool_sickle_chibi")
		if input_farm_name.text.is_empty():
			input_farm_name.text = "Nông Trại Hương Hoa"

func _apply_quick_outfit(outfit_id: String, hat_id: String) -> void:
	AudioManager.play_sfx("cloth_rustle")
	if avatar_preview == null:
		return
	avatar_preview.equip_part("outfit", outfit_id)
	avatar_preview.equip_part("hat", hat_id)
	EventBus.avatar_part_equipped.emit("outfit", outfit_id)

func _populate_category_options(tab_idx: int) -> void:
	if options_grid == null:
		return
	for child: Node in options_grid.get_children():
		child.queue_free()
		
	var category_key: String = TAB_KEYS[clampi(tab_idx, 0, TAB_KEYS.size() - 1)]
	var items: Array = _catalog.get(category_key, []) as Array
	
	var card_normal: StyleBoxFlat = StyleBoxFlat.new()
	card_normal.bg_color = Color(0.99, 0.93, 0.78, 1.0)
	card_normal.border_color = Color(0.55, 0.34, 0.16, 1.0)
	card_normal.set_border_width_all(2)
	card_normal.border_width_bottom = 4
	card_normal.set_corner_radius_all(12)
	card_normal.content_margin_left = 8
	card_normal.content_margin_right = 8
	var card_hover: StyleBoxFlat = card_normal.duplicate() as StyleBoxFlat
	card_hover.bg_color = Color(1.0, 0.86, 0.45, 1.0)

	for item_var: Variant in items:
		if typeof(item_var) == TYPE_DICTIONARY:
			var item: Dictionary = item_var as Dictionary
			var card_btn: Button = Button.new()
			card_btn.custom_minimum_size = Vector2(148.0, 76.0)
			card_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card_btn.text = str(item.get("name", "Tùy chọn"))
			card_btn.add_theme_stylebox_override("normal", card_normal)
			card_btn.add_theme_stylebox_override("hover", card_hover)
			card_btn.add_theme_stylebox_override("pressed", card_hover)
			card_btn.add_theme_color_override("font_color", Color(0.28, 0.14, 0.05, 1.0))
			card_btn.add_theme_color_override("font_hover_color", Color(0.20, 0.09, 0.02, 1.0))
			card_btn.add_theme_font_size_override("font_size", 14)
			card_btn.pressed.connect(func() -> void: _on_option_selected(category_key, item))
			options_grid.add_child(card_btn)

func _on_option_selected(category_key: String, item: Dictionary) -> void:
	AudioManager.play_sfx("cloth_rustle")
	var part_id: String = str(item.get("id", ""))
	if avatar_preview != null:
		if category_key == "poodle":
			if poodle_preview != null:
				var p_tex: Texture2D = null
				if SpriteAtlasManager != null:
					p_tex = SpriteAtlasManager.get_texture(part_id)
				if p_tex != null:
					poodle_preview.texture = p_tex
			avatar_preview.current_config["poodle"] = part_id
		else:
			avatar_preview.equip_part(category_key, part_id)
			if item.has("sub"):
				avatar_preview.equip_part("eyes", str(item.get("sub")))
			if item.has("hat"):
				avatar_preview.equip_part("hat", str(item.get("hat")))
				
	EventBus.avatar_part_equipped.emit(category_key, part_id)

func _on_randomize_pressed() -> void:
	AudioManager.play_sfx("dice_roll")
	for key: String in TAB_KEYS:
		var list: Array = _catalog.get(key, []) as Array
		if not list.is_empty():
			var pick: Dictionary = list[randi() % list.size()] as Dictionary
			_on_option_selected(key, pick)
	EventBus.avatar_config_randomized.emit(avatar_preview.current_config)

func _get_target_farm_scene() -> String:
	if ResourceLoader.exists(MAIN_FARM_SCENE_PATH):
		return MAIN_FARM_SCENE_PATH
	if ResourceLoader.exists("res://scenes/main_farm.tscn"):
		return "res://scenes/main_farm.tscn"
	return MAIN_FARM_SCENE_PATH

func _on_confirm_start_farm() -> void:
	var p_name: String = input_player_name.text.strip_edges().substr(0, 16)
	var f_name: String = input_farm_name.text.strip_edges()
	if p_name.is_empty():
		AudioManager.play_sfx("ui_wood_click")
		if input_player_name != null:
			input_player_name.placeholder_text = "Vui lòng nhập tên của bạn!"
			input_player_name.grab_focus()
			var normal_sb: StyleBox = input_player_name.get_theme_stylebox("normal")
			if normal_sb is StyleBoxFlat:
				var err_sb: StyleBoxFlat = normal_sb.duplicate() as StyleBoxFlat
				err_sb.border_color = Color(0.85, 0.22, 0.18, 1.0)
				input_player_name.add_theme_stylebox_override("normal", err_sb)
				input_player_name.add_theme_stylebox_override("focus", err_sb)
		return
	AudioManager.play_sfx("welcome_chime")
	if f_name.is_empty():
		f_name = "Nông Trại Nắng Ấm"
		
	var saved_avatar_cfg: Dictionary = avatar_preview.current_config.duplicate()
	saved_avatar_cfg["is_custom"] = true
	saved_avatar_cfg["gender"] = _current_gender
	
	if SaveManager != null:
		SaveManager.current_slot = active_slot_index
		SaveManager.reset_to_level_1()
		SaveManager.player_name = p_name
		SaveManager.farm_name = f_name
		SaveManager.selected_character = "mai" if _current_gender == "female" else "minh"
		SaveManager.avatar_config = saved_avatar_cfg
		SaveManager.is_tutorial_completed = false
		SaveManager.save_game()
		
	EventBus.character_creation_confirmed.emit(active_slot_index, p_name, f_name, avatar_preview.current_config)
	get_tree().change_scene_to_file(_get_target_farm_scene())
