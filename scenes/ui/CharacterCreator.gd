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

@onready var category_tabs: TabBar = $MainSplitHBox/RightCustomizationPanel/RightVBox/CategoryTabs
@onready var options_grid: GridContainer = $MainSplitHBox/RightCustomizationPanel/RightVBox/OptionsGridScroll/OptionsGrid
@onready var input_player_name: LineEdit = $MainSplitHBox/RightCustomizationPanel/RightVBox/IdentityFormHBox/InputPlayerName
@onready var input_farm_name: LineEdit = $MainSplitHBox/RightCustomizationPanel/RightVBox/IdentityFormHBox/InputFarmName
@onready var btn_back: Button = $MainSplitHBox/RightCustomizationPanel/RightVBox/BottomActionsHBox/BtnBackToTitle
@onready var btn_start_farm: Button = $MainSplitHBox/RightCustomizationPanel/RightVBox/BottomActionsHBox/BtnStartFarm

var active_slot_index: int = 1
var _catalog: Dictionary = {}

func _ready() -> void:
	if SaveManager != null and SaveManager.has_method("get"):
		active_slot_index = int(SaveManager.get("current_slot"))
		if active_slot_index <= 0:
			active_slot_index = 1
			
	_load_catalog_data()
	_setup_tabs()
	_bind_buttons()
	_populate_category_options(0)

func _load_catalog_data() -> void:
	if DataManager != null and DataManager.get("avatar_catalog") != null and not (DataManager.avatar_catalog as Dictionary).is_empty():
		_catalog = DataManager.avatar_catalog
	else:
		_catalog = {
			"body": [
				{"id": "body_warm_ivory", "name": "Da Kem Ấm", "sub": "eyes_sparkle_brown"},
				{"id": "body_peach_sunny", "name": "Da Hồng Nắng", "sub": "eyes_emerald_gentle"},
				{"id": "body_honey_tan", "name": "Da Mật Ong", "sub": "eyes_happy_arc"},
				{"id": "body_cocoa_warm", "name": "Da Nâu Ấm", "sub": "eyes_sky_bright"}
			],
			"hair": [
				{"id": "hair_braid_chestnut", "name": "Tóc Bím + Mũ Rơm", "hat": "hat_straw_ribbon"},
				{"id": "hair_short_sunny", "name": "Tóc Ngắn + Mũ Bưu Tá", "hat": "hat_postman_cap"},
				{"id": "hair_bun_baker", "name": "Tóc Búi + Mũ Bếp", "hat": "hat_chef_toque"},
				{"id": "hair_curly_berry", "name": "Tóc Xoăn Tự Nhiên", "hat": "hat_none"}
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
	category_tabs.tab_changed.connect(_populate_category_options)

func _bind_buttons() -> void:
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

func _populate_category_options(tab_idx: int) -> void:
	if options_grid == null:
		return
	for child: Node in options_grid.get_children():
		child.queue_free()
		
	var category_key: String = TAB_KEYS[clampi(tab_idx, 0, TAB_KEYS.size() - 1)]
	var items: Array = _catalog.get(category_key, []) as Array
	
	for item_var: Variant in items:
		if typeof(item_var) == TYPE_DICTIONARY:
			var item: Dictionary = item_var as Dictionary
			var card_btn: Button = Button.new()
			card_btn.custom_minimum_size = Vector2(150.0, 96.0)
			card_btn.text = str(item.get("name", "Tùy chọn"))
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
	if FileAccess.file_exists(MAIN_FARM_SCENE_PATH):
		return MAIN_FARM_SCENE_PATH
	return "res://scenes/main_farm.tscn"

func _on_confirm_start_farm() -> void:
	AudioManager.play_sfx("welcome_chime")
	var p_name: String = input_player_name.text.strip_edges()
	var f_name: String = input_farm_name.text.strip_edges()
	if p_name.is_empty():
		p_name = "Nông Dân Chibi"
	if f_name.is_empty():
		f_name = "Nông Trại Nắng Ấm"
		
	var initial_save_payload: Dictionary = {
		"slot_index": active_slot_index,
		"player_name": p_name,
		"farm_name": f_name,
		"level": 1,
		"gold": 500,
		"xp": 0,
		"avatar_config": avatar_preview.current_config.duplicate(),
		"is_tutorial_completed": false
	}
	
	SaveSlotService.write_slot_data(active_slot_index, initial_save_payload)
	
	if SaveManager != null:
		SaveManager.player_name = p_name
		SaveManager.save_game()
		
	EventBus.character_creation_confirmed.emit(active_slot_index, p_name, f_name, avatar_preview.current_config)
	get_tree().change_scene_to_file(_get_target_farm_scene())
