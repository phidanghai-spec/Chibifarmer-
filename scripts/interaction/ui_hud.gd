extends CanvasLayer
class_name UIHud

@export var drag_action_manager: DragActionManager

# --- Top-Left HUD Gauges (Inspired by Hay Day) ---
@onready var icon_gold: TextureRect = %IconGold
@onready var label_gold: Label = %LabelGold
@onready var label_diamonds: Label = %LabelDiamonds
@onready var label_level: Label = %LabelLevel
@onready var progress_xp: ProgressBar = %ProgressXP
@onready var label_silo: Label = %LabelSilo
@onready var progress_silo: ProgressBar = %ProgressSilo
@onready var label_barn: Label = %LabelBarn
@onready var progress_barn: ProgressBar = %ProgressBarn
@onready var label_xp: Label = %LabelXP
@onready var label_attraction: Label = %LabelAttraction
@onready var btn_audio_toggle: Button = %BtnAudioToggle
@onready var btn_settings: Button = %BtnSettings
@onready var btn_zoo: Button = %BtnZoo
@onready var badge_zoo: Label = %BadgeZoo
@onready var btn_quests: Button = %BtnQuests
@onready var badge_quests: Label = %BadgeQuests


# --- Bottom Tools ---
@onready var btn_view: Button = %BtnView
@onready var btn_seeds: Button = %BtnSeeds
@onready var panel_seeds_menu: Control = %PanelSeedsMenu
@onready var btn_select_wheat: Button = %BtnSelectWheat
@onready var btn_select_corn: Button = %BtnSelectCorn
@onready var btn_select_apple_tree: Button = %BtnSelectAppleTree
@onready var btn_select_mango_tree: Button = %BtnSelectMangoTree
@onready var btn_sickle: Button = %BtnSickle
@onready var btn_build_field: Button = %BtnBuildField
@onready var btn_build_path: Button = %BtnBuildPath
@onready var btn_dismantle: Button = %BtnDismantle
@onready var btn_open_shop: Button = %BtnOpenShop
@onready var btn_open_truck: Button = %BtnOpenTruck

# --- Popups ---
@onready var panel_shop: Control = %PanelShop
@onready var panel_truck: Control = %PanelTruck
@onready var shop_slots_container: GridContainer = %ShopSlotsContainer
@onready var truck_orders_container: Control = %TruckOrdersContainer
@onready var pill_silo: PanelContainer = find_child("PillSilo", true, false) as PanelContainer
@onready var pill_barn: PanelContainer = find_child("PillBarn", true, false) as PanelContainer
@onready var avatar_portrait: TextureRect = %AvatarPortrait
@onready var btn_quick_storage: Button = %BtnQuickStorage
@onready var avatar_frame: PanelContainer = find_child("AvatarFrame", true, false) as PanelContainer
@onready var badge_level: PanelContainer = %BadgeLevel
@onready var xp_container: PanelContainer = %XPContainer
@onready var btn_plus_coins: Button = %BtnPlusCoins
@onready var btn_plus_diamond: Button = %BtnPlusDiamond
@onready var btn_plus_gold: Button = %BtnPlusGold
@onready var bottom_panel: PanelContainer = find_child("BottomPanel", true, false) as PanelContainer

const StockAlertSystemClass = preload("res://scripts/systems/stock_alert_system.gd")
const LevelProgressionManagerClass = preload("res://scripts/core/level_progression_manager.gd")

var label_coins: Label = null
var stock_alert_system: Control = null
var _rename_modal: PanelContainer = null
var _settings_modal: PanelContainer = null
var _level_up_modal: PanelContainer = null
var _sell_picker_modal: PanelContainer = null
var _quests_modal: PanelContainer = null
var _zoo_modal: PanelContainer = null
var _zoo_feed_shop_modal: PanelContainer = null
var _hot_air_balloon_modal: PanelContainer = null
var _newspaper_modal: PanelContainer = null
var _steamboat_modal: PanelContainer = null
var _active_quest_tab: int = 0 # 0: Story, 1: Daily

var _tool_buttons: Dictionary = {}
var _crop_buttons: Dictionary = {}

const ALL_CROPS: Array[Dictionary] = [
	{"id": "wheat", "name": "Lúa Mì", "icon": "wheat"},
	{"id": "corn", "name": "Ngô", "icon": "corn"},
	{"id": "carrot", "name": "Cà Rốt", "icon": "carrot"},
	{"id": "soybean", "name": "Đậu Nành", "icon": "soybean"},
	{"id": "sugarcane", "name": "Mía Đường", "icon": "sugarcane"},
	{"id": "strawberry", "name": "Dâu Tây", "icon": "strawberry"},
	{"id": "sunflower", "name": "Hoa Hướng Dương", "icon": "sunflower"},
	{"id": "rose", "name": "Hoa Hồng Đỏ", "icon": "rose"},
	{"id": "lavender", "name": "Hoa Oải Hương", "icon": "lavender"},
	{"id": "tomato", "name": "Cà Chua", "icon": "tomato"},
	{"id": "pumpkin", "name": "Bí Đỏ", "icon": "pumpkin"},
	{"id": "apple_tree", "name": "Mầm Cây Táo", "icon": "apple_seed", "item_key": "apple_seed"},
	{"id": "mango_tree", "name": "Mầm Cây Xoài", "icon": "mango_seed", "item_key": "mango_seed"}
]

func _ready() -> void:
	_tool_buttons[DragActionManager.ToolType.NONE] = btn_view
	_tool_buttons[DragActionManager.ToolType.PLANT_WHEAT] = btn_seeds
	_tool_buttons[DragActionManager.ToolType.PLANT_CORN] = btn_seeds
	_tool_buttons[DragActionManager.ToolType.PLANT_CROP] = btn_seeds
	_tool_buttons[DragActionManager.ToolType.SICKLE] = btn_sickle
	_tool_buttons[DragActionManager.ToolType.BUILD_FIELD] = btn_build_field
	_tool_buttons[DragActionManager.ToolType.BUILD_PATH] = btn_build_path
	_tool_buttons[DragActionManager.ToolType.DISMANTLE] = btn_dismantle
	
	_setup_extra_seed_buttons()
	
	btn_view.pressed.connect(func() -> void:
		if panel_seeds_menu != null: panel_seeds_menu.visible = false
		if _build_modal != null and is_instance_valid(_build_modal) and _build_modal.visible:
			_build_modal.visible = false
			_on_tool_selected(DragActionManager.ToolType.NONE)
			return
		var farm: Node = get_tree().current_scene
		if farm != null and farm.get("_pending_build_id") != "":
			farm.set("_pending_build_id", "")
			var g_node: Node2D = farm.get("_ghost_preview_node") as Node2D
			if g_node != null: g_node.visible = false
			_on_tool_selected(DragActionManager.ToolType.NONE)
			return
		_on_tool_selected(DragActionManager.ToolType.NONE)
		open_build_modal()
	)
	btn_seeds.pressed.connect(func() -> void:
		if drag_action_manager != null and (
			drag_action_manager.current_tool == DragActionManager.ToolType.PLANT_WHEAT or
			drag_action_manager.current_tool == DragActionManager.ToolType.PLANT_CORN or
			drag_action_manager.current_tool == DragActionManager.ToolType.PLANT_CROP or
			drag_action_manager.current_tool == DragActionManager.ToolType.PLANT_APPLE_TREE or
			drag_action_manager.current_tool == DragActionManager.ToolType.PLANT_MANGO_TREE
		):
			if panel_seeds_menu != null: panel_seeds_menu.visible = false
			_on_tool_selected(DragActionManager.ToolType.NONE)
			return
		toggle_seeds_menu()
	)
	btn_select_wheat.pressed.connect(func() -> void: select_seed("wheat"))
	btn_select_corn.pressed.connect(func() -> void: select_seed("corn"))
	btn_sickle.pressed.connect(func() -> void:
		if panel_seeds_menu != null: panel_seeds_menu.visible = false
		if drag_action_manager != null and drag_action_manager.current_tool == DragActionManager.ToolType.SICKLE:
			_on_tool_selected(DragActionManager.ToolType.NONE)
		else:
			_on_tool_selected(DragActionManager.ToolType.SICKLE)
	)
	btn_build_field.pressed.connect(func() -> void:
		if panel_seeds_menu != null: panel_seeds_menu.visible = false
		if drag_action_manager != null and drag_action_manager.current_tool == DragActionManager.ToolType.BUILD_FIELD:
			_on_tool_selected(DragActionManager.ToolType.NONE)
		else:
			_on_tool_selected(DragActionManager.ToolType.BUILD_FIELD)
	)
	btn_build_path.pressed.connect(func() -> void:
		if panel_seeds_menu != null: panel_seeds_menu.visible = false
		if drag_action_manager != null and drag_action_manager.current_tool == DragActionManager.ToolType.BUILD_PATH:
			_on_tool_selected(DragActionManager.ToolType.NONE)
		else:
			_on_tool_selected(DragActionManager.ToolType.BUILD_PATH)
	)
	btn_dismantle.pressed.connect(func() -> void:
		if panel_seeds_menu != null: panel_seeds_menu.visible = false
		if drag_action_manager != null and drag_action_manager.current_tool == DragActionManager.ToolType.DISMANTLE:
			_on_tool_selected(DragActionManager.ToolType.NONE)
		else:
			_on_tool_selected(DragActionManager.ToolType.DISMANTLE)
	)
	
	btn_open_shop.pressed.connect(toggle_shop_popup)
	btn_open_truck.pressed.connect(toggle_truck_popup)
	
	# Ensure background containers ignore mouse filter so clicks pass to the farm plots
	if has_node("TopLeftHUD"):
		$TopLeftHUD.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for child in $TopLeftHUD.find_children("*", "Control"):
			if child is Button:
				child.mouse_filter = Control.MOUSE_FILTER_STOP
			else:
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if has_node("TopRightHUD"):
		$TopRightHUD.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for child in $TopRightHUD.find_children("*", "Control"):
			if child is Button:
				child.mouse_filter = Control.MOUSE_FILTER_STOP
			else:
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if has_node("BottomPanel"):
		$BottomPanel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for child in $BottomPanel.find_children("*", "Control"):
			if not (child is Button):
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Connect Core EventBus signals
	_setup_coins_hud()
	EventBus.coins_changed.connect(_on_coins_changed)
	EventBus.gold_changed.connect(_on_gold_changed)
	EventBus.diamonds_changed.connect(_on_diamonds_changed)
	EventBus.xp_changed.connect(_on_xp_changed)
	EventBus.leveled_up.connect(_on_leveled_up)
	EventBus.storage_updated.connect(_on_storage_updated)
	EventBus.attraction_score_changed.connect(_on_attraction_score_changed)
	EventBus.loot_collected.connect(_on_loot_collected)
	
	# Stock Alert System
	stock_alert_system = StockAlertSystemClass.new() as Control
	stock_alert_system.name = "StockAlertSystem"
	add_child(stock_alert_system)
	
	# Enable tooltips on currency & attraction pills + clicking Silo/Barn pills
	for pill_node: Control in [get_node_or_null("%PillCoins") as Control, get_node_or_null("%PillDiamonds") as Control, get_node_or_null("%PillGold") as Control, get_node_or_null("%PillAttraction") as Control]:
		if pill_node != null:
			pill_node.mouse_filter = Control.MOUSE_FILTER_STOP
	var btn_close_shop: Button = get_node_or_null("PanelShop/VBox/Header/BtnCloseShop") as Button
	if btn_close_shop != null:
		_apply_dialog_close_button(btn_close_shop)
	var btn_close_truck: Button = get_node_or_null("PanelTruck/VBox/Header/BtnCloseTruck") as Button
	if btn_close_truck != null:
		_apply_dialog_close_button(btn_close_truck)
	pill_silo.mouse_filter = Control.MOUSE_FILTER_STOP
	pill_barn.mouse_filter = Control.MOUSE_FILTER_STOP
	pill_silo.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			open_storage_popup("silo")
	)
	pill_barn.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			open_storage_popup("barn")
	)

	# Audio Mute / Unmute Toggle Button
	if btn_audio_toggle != null:
		btn_audio_toggle.text = "Tắt" if AudioManager.is_muted else "Loa"
		btn_audio_toggle.pressed.connect(func() -> void:
			var muted: bool = AudioManager.toggle_mute()
			btn_audio_toggle.text = "Tắt" if muted else "Loa"
			if not muted:
				AudioManager.play_sfx("click")
		)
	
	if btn_settings != null:
		btn_settings.pressed.connect(open_settings_modal)
	
	if btn_zoo != null:
		btn_zoo.pressed.connect(open_zoo_modal)
	if btn_quests != null:
		btn_quests.pressed.connect(open_quests_modal)
		
	SaveManager.puzzle_pieces_changed.connect(func(_cnt: int) -> void: _refresh_badges())
	SaveManager.zoo_updated.connect(func(_id: String) -> void: _refresh_badges())
	SaveManager.quest_updated.connect(func(_id: String) -> void: _refresh_badges())
	EventBus.quest_completed.connect(func(_id: String) -> void: _refresh_badges())
	EventBus.zoo_animal_fed.connect(func(_id: String) -> void: _refresh_badges())
	EventBus.leveled_up.connect(func(_lvl: int) -> void: _refresh_badges())
	_refresh_badges()
	
	if RoadsideShop != null:
		RoadsideShop.shop_updated.connect(_refresh_shop_ui)
	if TruckOrderSystem != null:
		TruckOrderSystem.orders_updated.connect(_refresh_truck_ui)
	
	if drag_action_manager != null:
		drag_action_manager.tool_changed.connect(_on_drag_tool_changed)
	
	# Top-Left Horizontal HUD: Avatar Portrait & Quick Storage
	_update_avatar_portrait()
	SaveManager.player_settings_changed.connect(func() -> void: _update_avatar_portrait())
	if btn_quick_storage != null:
		btn_quick_storage.pressed.connect(func() -> void:
			open_storage_popup("silo")
		)
	
	if btn_plus_coins != null:
		btn_plus_coins.pressed.connect(func() -> void:
			show_floating_notice(" Mở Sạp Hàng ven đường hoặc đón thêm du khách để nhận Xu Du Lịch!")
		)
	if btn_plus_diamond != null:
		btn_plus_diamond.pressed.connect(func() -> void:
			show_floating_notice("Kim Cương Hoàn thành Nhiệm Vụ & giải cứu thú sở thú để nhận thêm Kim Cương!")
		)
	if btn_plus_gold != null:
		btn_plus_gold.pressed.connect(func() -> void:
			show_floating_notice("💰 Thu hoạch cây trồng & giao hàng Xe Tải để tích lũy Vàng!")
		)
	
	panel_shop.visible = false
	panel_truck.visible = false
	if panel_seeds_menu != null:
		panel_seeds_menu.visible = false
	
	if icon_gold != null and SpriteAtlasManager != null and SpriteAtlasManager.has_texture("icon_gold"):
		icon_gold.texture = SpriteAtlasManager.get_texture("icon_gold")
	
	_apply_cozy_wooden_hud_theme()
	_refresh_all_hud()
	_refresh_shop_ui()
	_refresh_truck_ui()
	_setup_tool_button_icons()
	_highlight_active_button(DragActionManager.ToolType.NONE)

func _setup_tool_button_icons() -> void:
	if SpriteAtlasManager == null:
		return
	
	btn_view.text = "🏗️ Xây Dựng"
	btn_view.tooltip_text = "Mở cửa sổ Xây Dựng & Trang Trí: Mua chuồng trại, lò bánh, quầy nước, cây hoa."
	btn_sickle.text = "Liềm"
	btn_build_field.text = "Ruộng"
	btn_build_path.text = "Đường"
	btn_open_shop.text = "Sạp Hàng"
	btn_open_truck.text = "Xe Tải"
	
	btn_seeds.text = "🌱 Hạt Giống"
	
	if SpriteAtlasManager.has_texture("wheat"):
		btn_select_wheat.icon = SpriteAtlasManager.get_texture("wheat")
		btn_select_wheat.expand_icon = true
		btn_select_wheat.add_theme_constant_override("icon_max_width", 24)
	
	if SpriteAtlasManager.has_texture("corn"):
		btn_select_corn.icon = SpriteAtlasManager.get_texture("corn")
		btn_select_corn.expand_icon = true
		btn_select_corn.add_theme_constant_override("icon_max_width", 24)
	
	if btn_select_apple_tree != null:
		btn_select_apple_tree.pressed.connect(func() -> void: select_seed("apple_tree"))
		if SpriteAtlasManager.has_texture("apple_seed"):
			btn_select_apple_tree.icon = SpriteAtlasManager.get_texture("apple_seed")
			btn_select_apple_tree.expand_icon = true
			btn_select_apple_tree.add_theme_constant_override("icon_max_width", 24)
			
	if btn_select_mango_tree != null:
		btn_select_mango_tree.pressed.connect(func() -> void: select_seed("mango_tree"))
		if SpriteAtlasManager.has_texture("mango_seed"):
			btn_select_mango_tree.icon = SpriteAtlasManager.get_texture("mango_seed")
			btn_select_mango_tree.expand_icon = true
			btn_select_mango_tree.add_theme_constant_override("icon_max_width", 24)
	
	if SpriteAtlasManager.has_texture("sickle"):
		btn_sickle.icon = SpriteAtlasManager.get_texture("sickle")
		btn_sickle.expand_icon = true
	
	if SpriteAtlasManager.has_texture("field_plot"):
		btn_build_field.icon = SpriteAtlasManager.get_texture("field_plot")
		btn_build_field.expand_icon = true
	elif SpriteAtlasManager.has_texture("chibi_potato_plot"):
		btn_build_field.icon = SpriteAtlasManager.get_texture("chibi_potato_plot")
		btn_build_field.expand_icon = true
	
	if SpriteAtlasManager.has_texture("roadside_shop"):
		btn_open_shop.icon = SpriteAtlasManager.get_texture("roadside_shop")
		btn_open_shop.expand_icon = true
	
	if SpriteAtlasManager.has_texture("truck"):
		btn_open_truck.icon = SpriteAtlasManager.get_texture("truck")
		btn_open_truck.expand_icon = true
		btn_open_truck.add_theme_constant_override("icon_max_width", 26)
	elif SpriteAtlasManager.has_texture("truck_delivery"):
		btn_open_truck.icon = SpriteAtlasManager.get_texture("truck_delivery")
		btn_open_truck.expand_icon = true
		btn_open_truck.add_theme_constant_override("icon_max_width", 26)
	elif SpriteAtlasManager.has_texture("chibi_tool_shed"):
		btn_open_truck.icon = SpriteAtlasManager.get_texture("chibi_tool_shed")
		btn_open_truck.expand_icon = true

func _on_tool_selected(tool: DragActionManager.ToolType) -> void:
	if drag_action_manager != null:
		drag_action_manager.set_tool(tool)

func _on_drag_tool_changed(new_tool: DragActionManager.ToolType) -> void:
	_highlight_active_button(new_tool)

func _highlight_active_button(active_tool: DragActionManager.ToolType) -> void:
	for tool_key: Variant in _tool_buttons:
		var btn: Button = _tool_buttons[tool_key] as Button
		if active_tool != DragActionManager.ToolType.NONE and int(tool_key) == int(active_tool):
			btn.modulate = Color(1.35, 1.30, 0.65, 1.0)
		else:
			btn.modulate = Color(1.0, 1.0, 1.0, 1.0)

func cancel_all_active_tools() -> void:
	if panel_seeds_menu != null:
		panel_seeds_menu.visible = false
	if _build_modal != null and is_instance_valid(_build_modal):
		_build_modal.visible = false
	if _contextual_seed_popup != null and is_instance_valid(_contextual_seed_popup):
		_contextual_seed_popup.visible = false
	if _recipe_modal != null and is_instance_valid(_recipe_modal):
		_recipe_modal.visible = false
	if _storage_modal != null and is_instance_valid(_storage_modal):
		_storage_modal.visible = false
	if _quests_modal != null and is_instance_valid(_quests_modal):
		_quests_modal.visible = false
	if _zoo_modal != null and is_instance_valid(_zoo_modal):
		_zoo_modal.visible = false
	if _zoo_feed_shop_modal != null and is_instance_valid(_zoo_feed_shop_modal):
		_zoo_feed_shop_modal.visible = false
	if panel_shop != null:
		panel_shop.visible = false
	if panel_truck != null:
		panel_truck.visible = false
	if drag_action_manager != null:
		drag_action_manager.set_tool(DragActionManager.ToolType.NONE)
	_highlight_active_button(DragActionManager.ToolType.NONE)

func _apply_cozy_wooden_hud_theme() -> void:
	# 1. Avatar Frame & Level Badge & XP Container & Quick Storage Button
	if avatar_frame != null:
		var sb_av: StyleBoxFlat = _create_box_style(Color(0.98, 0.91, 0.76), Color(0.82, 0.48, 0.16), 4, 16, 6, Color(0.35, 0.20, 0.10, 0.35))
		avatar_frame.add_theme_stylebox_override("panel", sb_av)
	
	if badge_level != null:
		var sb_lvl: StyleBoxFlat = _create_box_style(Color(0.98, 0.76, 0.12), Color(0.35, 0.18, 0.08), 3, 17, 3, Color(0.35, 0.18, 0.08, 0.25))
		badge_level.add_theme_stylebox_override("panel", sb_lvl)
	if label_level != null:
		label_level.add_theme_color_override("font_color", Color(0.35, 0.18, 0.08))
		label_level.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0))
		label_level.add_theme_constant_override("outline_size", 2)
		label_level.add_theme_font_size_override("font_size", 13)
	
	if xp_container != null:
		var sb_xp: StyleBoxFlat = _create_box_style(Color(0.28, 0.16, 0.08, 0.92), Color(0.82, 0.65, 0.25), 2, 9, 2, Color(0, 0, 0, 0.3))
		xp_container.add_theme_stylebox_override("panel", sb_xp)
	
	if progress_xp != null:
		var sb_xp_bg: StyleBoxFlat = StyleBoxFlat.new()
		sb_xp_bg.bg_color = Color(0.18, 0.10, 0.05, 0.5)
		sb_xp_bg.set_corner_radius_all(7)
		progress_xp.add_theme_stylebox_override("background", sb_xp_bg)
		
		var sb_xp_fill: StyleBoxFlat = StyleBoxFlat.new()
		sb_xp_fill.bg_color = Color(0.20, 0.85, 0.48)
		sb_xp_fill.set_corner_radius_all(7)
		progress_xp.add_theme_stylebox_override("fill", sb_xp_fill)
	
	if label_xp != null:
		label_xp.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		label_xp.add_theme_color_override("font_outline_color", Color(0.24, 0.15, 0.14))
		label_xp.add_theme_constant_override("outline_size", 3)
		label_xp.add_theme_font_size_override("font_size", 10)
	
	if btn_quick_storage != null:
		_apply_wooden_button_style(
			btn_quick_storage,
			Color(0.94, 0.64, 0.22), # Golden orange wood
			Color(0.98, 0.72, 0.30),
			Color(0.86, 0.54, 0.16),
			Color(0.55, 0.30, 0.10),
			2, 10,
			Color(0.32, 0.15, 0.05),
			Color(1.0, 1.0, 1.0, 0.8),
			2, 12
		)
	
	# 2. Resource Pills (Cream ivory with thick orange-wood border)
	var pill_bg: Color = Color(0.99, 0.95, 0.86)
	var pill_border: Color = Color(0.78, 0.46, 0.18)
	var pill_nodes: Array[PanelContainer] = [
		find_child("PillCoins", true, false) as PanelContainer,
		find_child("PillDiamonds", true, false) as PanelContainer,
		find_child("PillGold", true, false) as PanelContainer,
		pill_silo,
		pill_barn
	]
	for p: PanelContainer in pill_nodes:
		if p != null:
			var sb_pill: StyleBoxFlat = _create_box_style(pill_bg, pill_border, 3, 18, 4, Color(0.40, 0.22, 0.10, 0.22))
			p.add_theme_stylebox_override("panel", sb_pill)
	
	# Number labels in pills: Bold dark brown with crisp white outline
	var dark_brown: Color = Color(0.36, 0.18, 0.06)
	var white_outline: Color = Color(1.0, 1.0, 1.0)
	for lbl: Label in [label_coins, label_diamonds, label_gold]:
		if lbl != null:
			lbl.add_theme_color_override("font_color", dark_brown)
			lbl.add_theme_color_override("font_outline_color", white_outline)
			lbl.add_theme_constant_override("outline_size", 2)
			lbl.add_theme_font_size_override("font_size", 15)
	for lbl: Label in [label_silo, label_barn]:
		if lbl != null:
			lbl.add_theme_color_override("font_color", dark_brown)
			lbl.add_theme_color_override("font_outline_color", white_outline)
			lbl.add_theme_constant_override("outline_size", 2)
			lbl.add_theme_font_size_override("font_size", 13)
	
	# Plus Buttons: Circular fresh green (#2ECC71) with white border
	var plus_buttons: Array[Button] = [btn_plus_coins, btn_plus_diamond, btn_plus_gold]
	for btn_p: Button in plus_buttons:
		if btn_p != null:
			_apply_wooden_button_style(
				btn_p,
				Color(0.18, 0.80, 0.44), # Vibrant fresh green
				Color(0.24, 0.88, 0.50),
				Color(0.14, 0.70, 0.38),
				Color(1.0, 1.0, 1.0),
				2, 12, # 12px radius = circle for 24x24
				Color(1.0, 1.0, 1.0),
				Color(0.10, 0.45, 0.25),
				2, 13
			)
	
	# 3. Top Right Buttons
	if btn_zoo != null:
		_apply_wooden_button_style(
			btn_zoo,
			Color(0.96, 0.62, 0.20),
			Color(1.0, 0.70, 0.28),
			Color(0.88, 0.52, 0.14),
			Color(0.55, 0.25, 0.08),
			2, 10,
			Color(1.0, 1.0, 1.0),
			Color(0.35, 0.18, 0.08),
			2, 14
		)
	if btn_quests != null:
		_apply_wooden_button_style(
			btn_quests,
			Color(0.96, 0.62, 0.20),
			Color(1.0, 0.70, 0.28),
			Color(0.88, 0.52, 0.14),
			Color(0.55, 0.25, 0.08),
			2, 10,
			Color(1.0, 1.0, 1.0),
			Color(0.35, 0.18, 0.08),
			2, 14
		)
	if btn_audio_toggle != null:
		_apply_wooden_button_style(
			btn_audio_toggle,
			Color(0.92, 0.72, 0.42),
			Color(0.98, 0.80, 0.52),
			Color(0.82, 0.60, 0.32),
			Color(0.48, 0.26, 0.10),
			2, 10,
			Color(0.36, 0.18, 0.06),
			Color(1.0, 1.0, 1.0, 0.8),
			2, 14
		)
	if btn_settings != null:
		_apply_wooden_button_style(
			btn_settings,
			Color(0.92, 0.72, 0.42),
			Color(0.98, 0.80, 0.52),
			Color(0.82, 0.60, 0.32),
			Color(0.48, 0.26, 0.10),
			2, 10,
			Color(0.36, 0.18, 0.06),
			Color(1.0, 1.0, 1.0, 0.8),
			2, 14
		)
	
	# 4. Bottom Taskbar Dock & Tool Buttons
	if bottom_panel != null:
		var sb_dock: StyleBoxFlat = StyleBoxFlat.new()
		sb_dock.bg_color = Color(0.98, 0.93, 0.82, 0.96)
		sb_dock.border_color = Color(0.68, 0.42, 0.18)
		sb_dock.border_width_top = 4
		sb_dock.border_width_left = 2
		sb_dock.border_width_right = 2
		sb_dock.border_width_bottom = 2
		sb_dock.corner_radius_top_left = 16
		sb_dock.corner_radius_top_right = 16
		sb_dock.shadow_color = Color(0.35, 0.20, 0.10, 0.25)
		sb_dock.shadow_size = 6
		bottom_panel.add_theme_stylebox_override("panel", sb_dock)
	
	var standard_tool_buttons: Array[Button] = [
		btn_view, btn_seeds, btn_sickle, btn_build_field, btn_build_path, btn_dismantle
	]
	for b_tool: Button in standard_tool_buttons:
		if b_tool != null:
			_apply_wooden_button_style(
				b_tool,
				Color(0.92, 0.72, 0.42), # Warm golden-camel wood
				Color(0.98, 0.80, 0.52), # Hover highlight
				Color(0.84, 0.62, 0.32), # Pressed
				Color(0.48, 0.26, 0.10), # Dark wood border
				2, 10,
				Color(0.36, 0.18, 0.06), # Dark brown text
				Color(1.0, 1.0, 1.0, 0.9), # Crisp white outline
				2, 13
			)
	
	# Special Golden-Orange buttons for Roadside Shop & Truck
	if btn_open_shop != null:
		_apply_wooden_button_style(
			btn_open_shop,
			Color(0.96, 0.62, 0.20),
			Color(1.0, 0.70, 0.28),
			Color(0.88, 0.52, 0.14),
			Color(0.55, 0.25, 0.08),
			2, 10,
			Color(0.30, 0.14, 0.04),
			Color(1.0, 1.0, 1.0, 0.9),
			2, 13
		)
	if btn_open_truck != null:
		_apply_wooden_button_style(
			btn_open_truck,
			Color(0.96, 0.62, 0.20),
			Color(1.0, 0.70, 0.28),
			Color(0.88, 0.52, 0.14),
			Color(0.55, 0.25, 0.08),
			2, 10,
			Color(0.30, 0.14, 0.04),
			Color(1.0, 1.0, 1.0, 0.9),
			2, 13
		)

func _create_box_style(bg: Color, border: Color, border_w: int, corner: int, shadow: int, shadow_col: Color = Color(0, 0, 0, 0.25)) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(corner)
	sb.shadow_size = shadow
	sb.shadow_color = shadow_col
	return sb

func _apply_wooden_button_style(
	btn: Button,
	normal_bg: Color,
	hover_bg: Color,
	pressed_bg: Color,
	border_col: Color,
	border_w: int,
	corner_rad: int,
	text_col: Color,
	outline_col: Color,
	outline_sz: int,
	font_sz: int
) -> void:
	var sb_normal: StyleBoxFlat = _create_box_style(normal_bg, border_col, border_w, corner_rad, 3, Color(0.35, 0.20, 0.10, 0.25))
	var sb_hover: StyleBoxFlat = _create_box_style(hover_bg, border_col, border_w, corner_rad, 4, Color(0.35, 0.20, 0.10, 0.35))
	var sb_pressed: StyleBoxFlat = _create_box_style(pressed_bg, border_col, border_w + 1, corner_rad, 1, Color(0.35, 0.20, 0.10, 0.20))
	
	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	btn.add_theme_stylebox_override("focus", sb_hover)
	
	btn.add_theme_color_override("font_color", text_col)
	btn.add_theme_color_override("font_hover_color", text_col)
	btn.add_theme_color_override("font_pressed_color", text_col)
	btn.add_theme_color_override("font_focus_color", text_col)
	
	btn.add_theme_color_override("font_outline_color", outline_col)
	btn.add_theme_constant_override("outline_size", outline_sz)
	btn.add_theme_font_size_override("font_size", font_sz)

func _refresh_all_hud() -> void:
	if label_gold != null and StorageManager != null:
		label_gold.text = "%s" % _format_number(StorageManager.gold)
	if label_diamonds != null and StorageManager != null:
		label_diamonds.text = "%d" % StorageManager.diamonds
	if label_coins != null and StorageManager != null:
		label_coins.text = "%s Xu" % _format_number(StorageManager.coins)
	if label_level != null and StorageManager != null:
		label_level.text = "%d" % StorageManager.level
	if label_xp != null and StorageManager != null:
		var needed_xp: int = StorageManager.get_required_xp(StorageManager.level)
		label_xp.text = "XP: %s / %s" % [_format_number(StorageManager.xp), _format_number(needed_xp)]
	if progress_xp != null and StorageManager != null:
		var needed_xp: int = StorageManager.get_required_xp(StorageManager.level)
		progress_xp.max_value = float(needed_xp)
		progress_xp.value = float(StorageManager.xp)
	if label_silo != null and StorageManager != null:
		label_silo.text = "%d/%d" % [StorageManager.get_silo_used(), StorageManager.silo_capacity]
	if progress_silo != null and StorageManager != null:
		progress_silo.max_value = float(StorageManager.silo_capacity)
		progress_silo.value = float(StorageManager.get_silo_used())
	if label_barn != null and StorageManager != null:
		label_barn.text = "%d/%d" % [StorageManager.get_barn_used(), StorageManager.barn_capacity]
	if progress_barn != null and StorageManager != null:
		progress_barn.max_value = float(StorageManager.barn_capacity)
		progress_barn.value = float(StorageManager.get_barn_used())
	if label_attraction != null and GridManager != null:
		label_attraction.text = "%d" % GridManager.total_attraction_score
	_refresh_seed_counts()
	_update_avatar_portrait()

func _setup_extra_seed_buttons() -> void:
	var vbox_seeds: VBoxContainer = %VBoxSeeds as VBoxContainer
	if vbox_seeds == null:
		return
	
	if btn_select_wheat != null:
		btn_select_wheat.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn_select_wheat.expand_icon = true
		btn_select_wheat.add_theme_constant_override("icon_max_width", 24)
		if SpriteAtlasManager.has_texture("wheat"):
			btn_select_wheat.icon = SpriteAtlasManager.get_texture("wheat")
	
	if btn_select_corn != null:
		btn_select_corn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn_select_corn.expand_icon = true
		btn_select_corn.add_theme_constant_override("icon_max_width", 24)
		if SpriteAtlasManager.has_texture("corn"):
			btn_select_corn.icon = SpriteAtlasManager.get_texture("corn")
			
	if btn_select_apple_tree != null:
		btn_select_apple_tree.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn_select_apple_tree.expand_icon = true
		btn_select_apple_tree.add_theme_constant_override("icon_max_width", 24)
		if SpriteAtlasManager.has_texture("apple_seed"):
			btn_select_apple_tree.icon = SpriteAtlasManager.get_texture("apple_seed")
			
	if btn_select_mango_tree != null:
		btn_select_mango_tree.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn_select_mango_tree.expand_icon = true
		btn_select_mango_tree.add_theme_constant_override("icon_max_width", 24)
		if SpriteAtlasManager.has_texture("mango_seed"):
			btn_select_mango_tree.icon = SpriteAtlasManager.get_texture("mango_seed")
	
	_crop_buttons["wheat"] = btn_select_wheat
	_crop_buttons["corn"] = btn_select_corn
	_crop_buttons["apple_tree"] = btn_select_apple_tree
	_crop_buttons["mango_tree"] = btn_select_mango_tree

	var extra_crops: Array[Dictionary] = [
		{"id": "carrot", "name": "Cà Rốt", "icon": "carrot"},
		{"id": "strawberry", "name": "Dâu Tây", "icon": "strawberry"},
		{"id": "sunflower", "name": "Hoa Hướng Dương", "icon": "sunflower"},
		{"id": "rose", "name": "Hoa Hồng Đỏ", "icon": "rose"},
		{"id": "lavender", "name": "Hoa Oải Hương", "icon": "lavender"},
		{"id": "soybean", "name": "Đậu Nành", "icon": "soybean"},
		{"id": "sugarcane", "name": "Mía Đường", "icon": "sugarcane"},
		{"id": "tomato", "name": "Cà Chua", "icon": "tomato"},
		{"id": "pumpkin", "name": "Bí Đỏ", "icon": "pumpkin"}
	]

	for c: Dictionary in extra_crops:
		var c_id: String = String(c["id"])
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(0, 32)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.expand_icon = true
		btn.add_theme_constant_override("icon_max_width", 24)
		if SpriteAtlasManager.has_texture(String(c["icon"])):
			btn.icon = SpriteAtlasManager.get_texture(String(c["icon"]))
		var c_name: String = String(c["name"])
		var cnt: int = StorageManager.get_item_count(c_id)
		btn.text = "%s (%d)" % [c_name, cnt]
		btn.pressed.connect(func() -> void: select_seed(c_id))
		vbox_seeds.add_child(btn)
		_crop_buttons[c_id] = btn

func toggle_seeds_menu() -> void:
	if panel_seeds_menu == null:
		return
	panel_seeds_menu.visible = not panel_seeds_menu.visible
	if panel_seeds_menu.visible:
		_refresh_seed_counts()
		panel_seeds_menu.global_position.x = btn_seeds.global_position.x - 10.0
		panel_seeds_menu.global_position.y = btn_seeds.global_position.y - panel_seeds_menu.size.y - 8.0

func select_seed(crop_id: String) -> void:
	if panel_seeds_menu != null:
		panel_seeds_menu.visible = false
	if crop_id == "wheat":
		_on_tool_selected(DragActionManager.ToolType.PLANT_WHEAT)
		btn_seeds.text = "Gieo: Lúa (%d)" % StorageManager.get_item_count("wheat")
	elif crop_id == "corn":
		_on_tool_selected(DragActionManager.ToolType.PLANT_CORN)
		btn_seeds.text = "Gieo: Ngô (%d)" % StorageManager.get_item_count("corn")
	elif crop_id == "apple_tree":
		_on_tool_selected(DragActionManager.ToolType.PLANT_APPLE_TREE)
		btn_seeds.text = "Trồng: Táo (%d)" % StorageManager.get_item_count("apple_seed")
	elif crop_id == "mango_tree":
		_on_tool_selected(DragActionManager.ToolType.PLANT_MANGO_TREE)
		btn_seeds.text = "Trồng: Xoài (%d)" % StorageManager.get_item_count("mango_seed")
	else:
		if drag_action_manager != null:
			drag_action_manager.set_plant_tool(crop_id)
		var c_name: String = DataManager.get_crop_name(crop_id)
		if c_name == "":
			c_name = DataManager.get_item_name(crop_id)
		btn_seeds.text = "Gieo: %s (%d)" % [c_name, StorageManager.get_item_count(crop_id)]

func _refresh_seed_counts() -> void:
	var wheat_count: int = StorageManager.get_item_count("wheat")
	var corn_count: int = StorageManager.get_item_count("corn")
	var apple_seed_count: int = StorageManager.get_item_count("apple_seed")
	var mango_seed_count: int = StorageManager.get_item_count("mango_seed")
	if btn_select_wheat != null:
		btn_select_wheat.text = "Lúa Mì (%d)" % wheat_count
	if btn_select_corn != null:
		btn_select_corn.text = "Ngô (%d)" % corn_count
	if btn_select_apple_tree != null:
		btn_select_apple_tree.text = "Mầm Cây Táo (%d)" % apple_seed_count
	if btn_select_mango_tree != null:
		btn_select_mango_tree.text = "Mầm Cây Xoài (%d)" % mango_seed_count

	for c_dict: Dictionary in ALL_CROPS:
		var c_id: String = String(c_dict["id"])
		if _crop_buttons.has(c_id):
			var btn: Button = _crop_buttons[c_id] as Button
			var count_key: String = String(c_dict.get("item_key", c_id))
			var cnt: int = StorageManager.get_item_count(count_key)
			btn.text = "%s (%d)" % [String(c_dict["name"]), cnt]

	if drag_action_manager != null:
		if drag_action_manager.current_tool == DragActionManager.ToolType.PLANT_WHEAT:
			btn_seeds.text = "Gieo: Lúa (%d)" % wheat_count
		elif drag_action_manager.current_tool == DragActionManager.ToolType.PLANT_CORN:
			btn_seeds.text = "Gieo: Ngô (%d)" % corn_count
		elif drag_action_manager.current_tool == DragActionManager.ToolType.PLANT_APPLE_TREE:
			btn_seeds.text = "Trồng: Táo (%d)" % apple_seed_count
		elif drag_action_manager.current_tool == DragActionManager.ToolType.PLANT_MANGO_TREE:
			btn_seeds.text = "Trồng: Xoài (%d)" % mango_seed_count
		elif drag_action_manager.current_tool == DragActionManager.ToolType.PLANT_CROP:
			var s_id: String = drag_action_manager.selected_crop_id
			var c_name: String = DataManager.get_crop_name(s_id)
			if c_name == "":
				c_name = DataManager.get_item_name(s_id)
			btn_seeds.text = "Gieo: %s (%d)" % [c_name, StorageManager.get_item_count(s_id)]
		else:
			btn_seeds.text = "🌱 Hạt Giống"

func _setup_coins_hud() -> void:
	if label_coins == null:
		if has_node("%LabelCoins"):
			label_coins = %LabelCoins
		else:
			label_coins = find_child("LabelCoins", true, false) as Label
	if label_coins != null:
		label_coins.text = "%s Xu" % _format_number(StorageManager.coins)

func _update_avatar_portrait() -> void:
	if avatar_portrait == null:
		if has_node("%AvatarPortrait"):
			avatar_portrait = %AvatarPortrait
		else:
			avatar_portrait = find_child("AvatarPortrait", true, false) as TextureRect
	if avatar_portrait != null:
		var char_id: String = SaveManager.selected_character.to_lower()
		var tex_key: String = "portrait_mai" if (char_id == "mai" or char_id == "female") else "portrait_minh"
		if SpriteAtlasManager.has_texture(tex_key):
			avatar_portrait.texture = SpriteAtlasManager.get_texture(tex_key)


func _on_coins_changed(new_coins: int, _delta: int) -> void:
	if label_coins != null:
		label_coins.text = "%s Xu" % _format_number(new_coins)

func _on_gold_changed(new_gold: int, _delta: int) -> void:
	if label_gold != null:
		label_gold.text = "%s" % _format_number(new_gold)

func _on_diamonds_changed(new_diamonds: int, _delta: int) -> void:
	if label_diamonds != null:
		label_diamonds.text = "%d" % new_diamonds

func _on_xp_changed(current_xp: int, target_xp: int, current_level: int) -> void:
	if label_level != null:
		label_level.text = "%d" % current_level
	if progress_xp != null:
		progress_xp.max_value = target_xp
		progress_xp.value = current_xp
	if label_xp != null:
		label_xp.text = "XP: %s / %s" % [_format_number(current_xp), _format_number(target_xp)]

func _on_leveled_up(new_level: int) -> void:
	print("[UIHud] CONGRATULATIONS! Level up to: ", new_level)
	if label_level != null:
		label_level.text = "%d" % new_level
	_show_level_up_modal(new_level)

func show_floating_notice(msg: String) -> void:
	var notice_box: PanelContainer = PanelContainer.new()
	notice_box.z_index = 120
	notice_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.12, 0.08, 0.92)
	sb.border_color = Color(0.95, 0.78, 0.35, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	notice_box.add_theme_stylebox_override("panel", sb)
	
	var lbl: Label = Label.new()
	lbl.text = msg
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	lbl.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02))
	lbl.add_theme_constant_override("outline_size", 2)
	notice_box.add_child(lbl)
	
	add_child(notice_box)
	
	notice_box.anchors_preset = Control.PRESET_CENTER_TOP
	notice_box.anchor_left = 0.5
	notice_box.anchor_right = 0.5
	notice_box.anchor_top = 0.0
	notice_box.offset_left = -160.0
	notice_box.offset_right = 160.0
	notice_box.offset_top = 65.0
	
	var tw: Tween = create_tween()
	tw.tween_property(notice_box, "offset_top", 75.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.8)
	tw.tween_property(notice_box, "modulate:a", 0.0, 0.4)
	tw.tween_callback(notice_box.queue_free)

func _show_level_up_modal(new_level: int) -> void:
	AudioManager.play_sfx("level_up")
	if _level_up_modal != null and is_instance_valid(_level_up_modal):
		_level_up_modal.queue_free()
	
	var u_info: Dictionary = LevelProgressionManagerClass.get_unlock_info(new_level)
	var title_str: String = String(u_info.get("title", "Tiến Trình Mới"))
	var desc_str: String = String(u_info.get("desc", ""))
	var crops: Array = u_info.get("crops", [])
	var animals: Array = u_info.get("animals", [])
	var fishes: Array = u_info.get("fishes", [])
	var buildings: Array = u_info.get("buildings", [])
	var gold_reward: int = int(u_info.get("gold_reward", 150 + new_level * 25))
	var dia_reward: int = int(u_info.get("diamonds_reward", 2))
	var coins_reward: int = int(u_info.get("coins_reward", 50))
	
	_level_up_modal = PanelContainer.new()
	_level_up_modal.name = "LevelUpModal"
	_level_up_modal.custom_minimum_size = Vector2(400, 260)
	_level_up_modal.anchors_preset = Control.PRESET_CENTER
	_level_up_modal.anchor_left = 0.5
	_level_up_modal.anchor_top = 0.5
	_level_up_modal.anchor_right = 0.5
	_level_up_modal.anchor_bottom = 0.5
	_level_up_modal.offset_left = -200.0
	_level_up_modal.offset_top = -130.0
	_level_up_modal.offset_right = 200.0
	_level_up_modal.offset_bottom = 130.0
	_level_up_modal.z_index = 150
	
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.99, 0.96, 0.90, 0.98)
	sb.border_color = Color(0.85, 0.65, 0.18, 1.0)
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(16)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	sb.shadow_color = Color(0.3, 0.2, 0.05, 0.35)
	sb.shadow_size = 12
	_level_up_modal.add_theme_stylebox_override("panel", sb)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_level_up_modal.add_child(vbox)
	
	var lbl_title: Label = Label.new()
	lbl_title.text = "🎉 CHÚC MỪNG BẠN LÊN CẤP! 🎉"
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.add_theme_font_size_override("font_size", 16)
	lbl_title.add_theme_color_override("font_color", Color(0.85, 0.45, 0.05))
	lbl_title.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0))
	lbl_title.add_theme_constant_override("outline_size", 2)
	vbox.add_child(lbl_title)
	
	var lbl_level_badge: Label = Label.new()
	lbl_level_badge.text = "★ CẤP ĐỘ %d: %s ★" % [new_level, title_str]
	lbl_level_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_level_badge.add_theme_font_size_override("font_size", 18)
	lbl_level_badge.add_theme_color_override("font_color", Color(0.25, 0.15, 0.10))
	vbox.add_child(lbl_level_badge)
	
	if desc_str != "":
		var lbl_desc: Label = Label.new()
		lbl_desc.text = desc_str
		lbl_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_desc.add_theme_font_size_override("font_size", 11)
		lbl_desc.add_theme_color_override("font_color", Color(0.42, 0.32, 0.22))
		vbox.add_child(lbl_desc)
		
	var unlocks: Array[String] = []
	for c in crops:
		unlocks.append("🌱 " + String(c))
	for a in animals:
		unlocks.append("🐾 " + String(a))
	for f in fishes:
		unlocks.append("🐟 " + String(f))
	for b in buildings:
		unlocks.append("🏗️ " + String(b))
		
	if not unlocks.is_empty():
		var lbl_unlock: Label = Label.new()
		lbl_unlock.text = "🔓 Mở Khóa Mới: " + ", ".join(unlocks)
		lbl_unlock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_unlock.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_unlock.add_theme_font_size_override("font_size", 12)
		lbl_unlock.add_theme_color_override("font_color", Color(0.15, 0.48, 0.2))
		vbox.add_child(lbl_unlock)
	
	var lbl_rewards: Label = Label.new()
	lbl_rewards.text = " Phần thưởng: +%d 💰 Vàng  +%d Kim Cương  +%d Xu" % [gold_reward, dia_reward, coins_reward]
	lbl_rewards.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_rewards.add_theme_font_size_override("font_size", 12)
	lbl_rewards.add_theme_color_override("font_color", Color(0.85, 0.55, 0.10))
	vbox.add_child(lbl_rewards)
	
	var btn_ok: Button = Button.new()
	btn_ok.text = "🌟 Tuyệt Vời!"
	btn_ok.custom_minimum_size = Vector2(140, 36)
	btn_ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_ok.pressed.connect(func() -> void:
		_level_up_modal.queue_free()
	)
	vbox.add_child(btn_ok)
	
	add_child(_level_up_modal)

func open_settings_modal() -> void:
	AudioManager.play_sfx("click")
	if _settings_modal != null and is_instance_valid(_settings_modal):
		_settings_modal.queue_free()
		return
	
	_settings_modal = PanelContainer.new()
	_settings_modal.name = "SettingsModal"
	_settings_modal.custom_minimum_size = Vector2(400, 460)
	_settings_modal.anchors_preset = Control.PRESET_CENTER
	_settings_modal.anchor_left = 0.5
	_settings_modal.anchor_top = 0.5
	_settings_modal.anchor_right = 0.5
	_settings_modal.anchor_bottom = 0.5
	_settings_modal.offset_left = -200.0
	_settings_modal.offset_top = -230.0
	_settings_modal.offset_right = 200.0
	_settings_modal.offset_bottom = 230.0
	_settings_modal.z_index = 100
	
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.98, 0.95, 0.88, 0.98)
	sb.border_color = Color(0.60, 0.40, 0.22, 1.0)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	_settings_modal.add_theme_stylebox_override("panel", sb)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_settings_modal.add_child(vbox)
	
	# Header
	var hbox_head: HBoxContainer = HBoxContainer.new()
	vbox.add_child(hbox_head)
	
	var lbl_title: Label = Label.new()
	lbl_title.text = " CÀI ĐẶT & CHẾ ĐỘ CHƠI"
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_title.add_theme_font_size_override("font_size", 14)
	lbl_title.add_theme_color_override("font_color", Color(0.35, 0.20, 0.10))
	hbox_head.add_child(lbl_title)
	
	var btn_close: Button = Button.new()
	_apply_dialog_close_button(btn_close)
	btn_close.pressed.connect(func() -> void:
		_settings_modal.queue_free()
	)
	hbox_head.add_child(btn_close)
	
	# --- 1. Character Selection (Minh / Mai) ---
	var lbl_char_sec: Label = Label.new()
	lbl_char_sec.text = "👤 LỰA CHỌN NHÂN VẬT"
	lbl_char_sec.add_theme_font_size_override("font_size", 11)
	lbl_char_sec.add_theme_color_override("font_color", Color(0.40, 0.25, 0.12))
	vbox.add_child(lbl_char_sec)
	
	var hbox_chars: HBoxContainer = HBoxContainer.new()
	hbox_chars.add_theme_constant_override("separation", 10)
	vbox.add_child(hbox_chars)
	
	var btn_char_minh: Button = Button.new()
	btn_char_minh.text = "👨 Nông Dân Nam"
	btn_char_minh.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_char_minh.custom_minimum_size = Vector2(0, 34)
	hbox_chars.add_child(btn_char_minh)
	
	var btn_char_mai: Button = Button.new()
	btn_char_mai.text = "👩 Nông Dân Nữ"
	btn_char_mai.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_char_mai.custom_minimum_size = Vector2(0, 34)
	hbox_chars.add_child(btn_char_mai)
	
	var update_char_buttons: Callable = func() -> void:
		var sel_char: String = SaveManager.selected_character.to_lower()
		if sel_char == "minh" or sel_char == "male":
			btn_char_minh.modulate = Color(1.2, 1.3, 0.8)
			btn_char_mai.modulate = Color(0.9, 0.9, 0.9)
		else:
			btn_char_minh.modulate = Color(0.9, 0.9, 0.9)
			btn_char_mai.modulate = Color(1.3, 1.1, 1.2)
	
	update_char_buttons.call()
	
	btn_char_minh.pressed.connect(func() -> void:
		SaveManager.set_player_character("minh")
		update_char_buttons.call()
		_update_avatar_portrait()
		AudioManager.play_sfx("click")
		show_floating_notice("👨 Đã chọn nhân vật: Nông Dân Nam!")
	)
	btn_char_mai.pressed.connect(func() -> void:
		SaveManager.set_player_character("mai")
		update_char_buttons.call()
		_update_avatar_portrait()
		AudioManager.play_sfx("click")
		show_floating_notice("👩 Đã chọn nhân vật: Nông Dân Nữ!")
	)
	
	# Character Name Input
	var hbox_name: HBoxContainer = HBoxContainer.new()
	hbox_name.add_theme_constant_override("separation", 8)
	vbox.add_child(hbox_name)
	
	var lbl_name_prompt: Label = Label.new()
	lbl_name_prompt.text = "Tên nông dân:"
	lbl_name_prompt.add_theme_font_size_override("font_size", 11)
	lbl_name_prompt.add_theme_color_override("font_color", Color(0.35, 0.20, 0.10))
	hbox_name.add_child(lbl_name_prompt)
	
	var edit_player_name: LineEdit = LineEdit.new()
	edit_player_name.text = SaveManager.player_name
	edit_player_name.max_length = 16
	edit_player_name.placeholder_text = "Nhập tên của bạn..."
	edit_player_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit_player_name.text_changed.connect(func(new_text: String) -> void:
		SaveManager.set_player_name(new_text)
	)
	hbox_name.add_child(edit_player_name)
	
	# --- 2. Instant Interact vs Walk-to-Interact Toggle ---
	var lbl_interact_sec: Label = Label.new()
	lbl_interact_sec.text = "🎮 PHƯƠNG THỨC ĐIỀU KHIỂN & TƯƠNG TÁC"
	lbl_interact_sec.add_theme_font_size_override("font_size", 11)
	lbl_interact_sec.add_theme_color_override("font_color", Color(0.40, 0.25, 0.12))
	vbox.add_child(lbl_interact_sec)
	
	var btn_toggle_interact: Button = Button.new()
	btn_toggle_interact.custom_minimum_size = Vector2(0, 34)
	
	var update_interact_btn: Callable = func() -> void:
		if SaveManager.instant_interact:
			btn_toggle_interact.text = "⚡ Tương tác tức thì 1 Chạm: [BẬT]"
			btn_toggle_interact.modulate = Color(1.2, 1.25, 0.8)
		else:
			btn_toggle_interact.text = "🚶 Tương tác tức thì: [TẮT] (Đi bộ tới nơi)"
			btn_toggle_interact.modulate = Color(0.9, 1.15, 1.2)
			
	update_interact_btn.call()
	
	btn_toggle_interact.pressed.connect(func() -> void:
		SaveManager.set_instant_interact(not SaveManager.instant_interact)
		update_interact_btn.call()
		AudioManager.play_sfx("click")
		if SaveManager.instant_interact:
			show_floating_notice("⚡ Đã bật Tương tác 1 Chạm!")
		else:
			show_floating_notice("🚶 Đã bật chế độ Đi bộ tới đối tượng!")
	)
	vbox.add_child(btn_toggle_interact)
	
	var btn_fps_overlay: Button = Button.new()
	btn_fps_overlay.custom_minimum_size = Vector2(0, 32)
	btn_fps_overlay.text = "📊 Bật/Tắt FPS & Đồ Thị Hiệu Năng (F3)"
	btn_fps_overlay.pressed.connect(func() -> void:
		var dm: Node = get_node_or_null("/root/DebugMenu")
		if dm != null:
			var cur_style: int = int(dm.get("style"))
			dm.set("style", (cur_style + 1) % 3)
			AudioManager.play_sfx("click")
	)
	vbox.add_child(btn_fps_overlay)
	
	# --- 3. Web Testing Game Modes: Level 1 Story vs Level 33 Sandbox ---
	var lbl_mode_sec: Label = Label.new()
	lbl_mode_sec.text = "🚀 CHUYỂN NHANH CHẾ ĐỘ CHƠI (WEB TEST)"
	lbl_mode_sec.add_theme_font_size_override("font_size", 11)
	lbl_mode_sec.add_theme_color_override("font_color", Color(0.40, 0.25, 0.12))
	vbox.add_child(lbl_mode_sec)
	
	var btn_reset_lvl1: Button = Button.new()
	btn_reset_lvl1.text = "🌱 Chơi Từ Cấp 1 (Cốt Truyện Lv.1 -> Lv.33)"
	btn_reset_lvl1.custom_minimum_size = Vector2(0, 36)
	btn_reset_lvl1.pressed.connect(func() -> void:
		SaveManager.reset_to_level_1()
		_refresh_all_hud()
		_refresh_shop_ui()
		_refresh_truck_ui()
		_update_avatar_portrait()
		AudioManager.play_sfx("level_up")
		show_floating_notice("🌱 Đã thiết lập lại nông trại Cấp 1 Chuẩn Cốt Truyện!")
		_settings_modal.queue_free()
	)
	vbox.add_child(btn_reset_lvl1)
	
	var btn_sandbox: Button = Button.new()
	btn_sandbox.text = "👑 Chế Độ Sandbox Cấp 33 (Full Mở Khóa & Tài Nguyên)"
	btn_sandbox.custom_minimum_size = Vector2(0, 36)
	btn_sandbox.pressed.connect(func() -> void:
		SaveManager.set_sandbox_level_33()
		_refresh_all_hud()
		_refresh_shop_ui()
		_refresh_truck_ui()
		_update_avatar_portrait()
		AudioManager.play_sfx("coin")
		show_floating_notice("👑 Đã kích hoạt Chế Độ Sandbox Cấp 33 (190,556 Vàng, Full Thú)!")
		_settings_modal.queue_free()
	)
	vbox.add_child(btn_sandbox)
	
	var btn_save: Button = Button.new()
	btn_save.text = "💾 Lưu Tiến Trình"
	btn_save.custom_minimum_size = Vector2(0, 32)
	btn_save.pressed.connect(func() -> void:
		SaveManager.save_game()
		AudioManager.play_sfx("coin")
		show_floating_notice("💾 Đã lưu tiến trình nông trại!")
		_settings_modal.queue_free()
	)
	vbox.add_child(btn_save)
	
	add_child(_settings_modal)

func _on_storage_updated(storage_type: String, current_used: int, max_cap: int) -> void:
	if storage_type == "silo":
		if label_silo != null:
			label_silo.text = "%d/%d" % [current_used, max_cap]
		if progress_silo != null:
			progress_silo.max_value = max_cap
			progress_silo.value = current_used
		_refresh_seed_counts()
	elif storage_type == "barn":
		if label_barn != null:
			label_barn.text = "%d/%d" % [current_used, max_cap]
		if progress_barn != null:
			progress_barn.max_value = max_cap
			progress_barn.value = current_used
	
	# Update shop & truck panels if open
	if panel_truck.visible:
		_refresh_truck_ui()

func _on_attraction_score_changed(new_score: int) -> void:
	if label_attraction != null:
		label_attraction.text = " %d" % new_score

func _format_number(num: int) -> String:
	# Format with commas: 5450 -> "5,450"
	var s: String = str(num)
	var res: String = ""
	var count: int = 0
	for i: int in range(s.length() - 1, -1, -1):
		res = s[i] + res
		count += 1
		if count % 3 == 0 and i > 0:
			res = "," + res
	return res

# --- Roadside Shop Modal ---

func toggle_shop_popup() -> void:
	AudioManager.play_sfx("click")
	panel_shop.visible = not panel_shop.visible
	if panel_shop.visible:
		panel_truck.visible = false
		_refresh_shop_ui()

func _refresh_shop_ui() -> void:
	if shop_slots_container == null or RoadsideShop == null:
		return
	
	# Clear previous children
	for child: Node in shop_slots_container.get_children():
		child.queue_free()
	
	var slots: Array[Dictionary] = RoadsideShop.get_slots()
	for i: int in range(slots.size()):
		var slot: Dictionary = slots[i]
		var card: PanelContainer = _create_shop_slot_card(i, slot)
		shop_slots_container.add_child(card)

func _create_shop_slot_card(slot_index: int, slot: Dictionary) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(150, 135)
	
	# Warm wooden board styling for roadside shop slots
	var wood_box: StyleBoxFlat = StyleBoxFlat.new()
	wood_box.bg_color = Color(0.82, 0.58, 0.35, 1.0) # Bảng gỗ nâu ấm
	wood_box.border_color = Color(0.46, 0.26, 0.12, 1.0) # Viền gỗ sẫm
	wood_box.set_border_width_all(3)
	wood_box.border_width_bottom = 5
	wood_box.set_corner_radius_all(12)
	wood_box.shadow_color = Color(0.2, 0.1, 0.05, 0.35)
	wood_box.shadow_size = 4
	wood_box.shadow_offset = Vector2(0, 2)
	wood_box.content_margin_left = 8
	wood_box.content_margin_right = 8
	wood_box.content_margin_top = 8
	wood_box.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", wood_box)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)
	
	var item_id: String = String(slot.get("item_id", ""))
	var count: int = int(slot.get("count", 0))
	var price: int = int(slot.get("price", 0))
	var is_sold: bool = bool(slot.get("is_sold", false))
	
	if item_id == "":
		# Empty slot: button to quick list items
		var empty_wood: StyleBoxFlat = wood_box.duplicate() as StyleBoxFlat
		empty_wood.bg_color = Color(0.72, 0.50, 0.30, 0.75)
		card.add_theme_stylebox_override("panel", empty_wood)
		
		var lbl_empty: Label = Label.new()
		lbl_empty.text = "Ô Trống"
		lbl_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_empty.add_theme_font_size_override("font_size", 14)
		lbl_empty.add_theme_color_override("font_color", Color(0.35, 0.20, 0.08))
		vbox.add_child(lbl_empty)
		
		var btn_list: Button = Button.new()
		btn_list.text = "+ Đăng Bán"
		btn_list.custom_minimum_size = Vector2(100, 32)
		_apply_dialog_action_button(btn_list, false)
		btn_list.pressed.connect(func() -> void: open_sell_item_picker(slot_index))
		vbox.add_child(btn_list)
	elif is_sold:
		# Sold: Collect money!
		var icon_rect: TextureRect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(40, 40)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture = _get_item_or_crop_texture(item_id)
		vbox.add_child(icon_rect)
		
		var lbl_sold: Label = Label.new()
		lbl_sold.text = "💰 ĐÃ BÁN!"
		lbl_sold.add_theme_color_override("font_color", Color(1.0, 0.95, 0.2))
		lbl_sold.add_theme_font_size_override("font_size", 13)
		lbl_sold.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lbl_sold)
		
		var btn_collect: Button = Button.new()
		btn_collect.text = "Nhận %d Vàng" % price
		btn_collect.custom_minimum_size = Vector2(110, 30)
		_apply_dialog_action_button(btn_collect, true)
		btn_collect.pressed.connect(func() -> void:
			RoadsideShop.collect_coins(slot_index)
		)
		vbox.add_child(btn_collect)
	else:
		# On sale: Show item image, count and price
		var icon_rect: TextureRect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(44, 44)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture = _get_item_or_crop_texture(item_id)
		vbox.add_child(icon_rect)
		
		var item_name: String = DataManager.get_item_name(item_id)
		var lbl_info: Label = Label.new()
		lbl_info.text = "%dx %s" % [count, item_name]
		lbl_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_info.add_theme_font_size_override("font_size", 12)
		lbl_info.add_theme_color_override("font_color", Color(0.25, 0.12, 0.04))
		vbox.add_child(lbl_info)
		
		var lbl_price: Label = Label.new()
		lbl_price.text = "Giá: %d Vàng" % price
		lbl_price.add_theme_color_override("font_color", Color(1.0, 0.92, 0.3))
		lbl_price.add_theme_font_size_override("font_size", 12)
		lbl_price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lbl_price)
		
		var btn_sim: Button = Button.new()
		btn_sim.text = "Bán Cho Khách"
		btn_sim.custom_minimum_size = Vector2(110, 26)
		_apply_dialog_action_button(btn_sim, true)
		btn_sim.pressed.connect(func() -> void:
			RoadsideShop.buy_slot_by_shopper(slot_index)
		)
		vbox.add_child(btn_sim)
	
	return card

func _get_item_or_crop_texture(item_id: String) -> Texture2D:
	if SpriteAtlasManager.has_texture(item_id):
		return SpriteAtlasManager.get_texture(item_id)
	if SpriteAtlasManager.has_texture("crop_" + item_id):
		return SpriteAtlasManager.get_texture("crop_" + item_id)
	if SpriteAtlasManager.has_texture("item_" + item_id):
		return SpriteAtlasManager.get_texture("item_" + item_id)
	if SpriteAtlasManager.has_texture("icon_" + item_id):
		return SpriteAtlasManager.get_texture("icon_" + item_id)
	return null

func open_sell_item_picker(slot_index: int) -> void:
	AudioManager.play_sfx("click")
	if _sell_picker_modal != null and is_instance_valid(_sell_picker_modal):
		_sell_picker_modal.queue_free()
	
	_sell_picker_modal = PanelContainer.new()
	_sell_picker_modal.name = "SellPickerModal"
	_sell_picker_modal.custom_minimum_size = Vector2(420, 340)
	_sell_picker_modal.anchors_preset = Control.PRESET_CENTER
	_sell_picker_modal.anchor_left = 0.5
	_sell_picker_modal.anchor_top = 0.5
	_sell_picker_modal.anchor_right = 0.5
	_sell_picker_modal.anchor_bottom = 0.5
	_sell_picker_modal.offset_left = -210.0
	_sell_picker_modal.offset_top = -170.0
	_sell_picker_modal.offset_right = 210.0
	_sell_picker_modal.offset_bottom = 170.0
	_sell_picker_modal.z_index = 95
	
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.98, 0.95, 0.88, 0.98)
	sb.border_color = Color(0.60, 0.40, 0.22, 1.0)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	_sell_picker_modal.add_theme_stylebox_override("panel", sb)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_sell_picker_modal.add_child(vbox)
	
	var hbox_head: HBoxContainer = HBoxContainer.new()
	vbox.add_child(hbox_head)
	
	var lbl_title: Label = Label.new()
	lbl_title.text = "📦 CHỌN HÀNG ĐĂNG BÁN (Ô #%d)" % (slot_index + 1)
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_title.add_theme_font_size_override("font_size", 13)
	lbl_title.add_theme_color_override("font_color", Color(0.35, 0.20, 0.10))
	hbox_head.add_child(lbl_title)
	
	var btn_close: Button = Button.new()
	_apply_dialog_close_button(btn_close)
	btn_close.pressed.connect(func() -> void:
		_sell_picker_modal.queue_free()
	)
	hbox_head.add_child(btn_close)
	
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(388, 260)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	var vbox_list: VBoxContainer = VBoxContainer.new()
	vbox_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_list.add_theme_constant_override("separation", 6)
	scroll.add_child(vbox_list)
	
	var sellable_items: Array[Dictionary] = []
	for item_id: Variant in StorageManager.silo_items:
		var cnt: int = int(StorageManager.silo_items[item_id])
		if cnt > 0:
			sellable_items.append({"id": String(item_id), "count": cnt, "type": "silo"})
	for item_id: Variant in StorageManager.barn_items:
		var cnt: int = int(StorageManager.barn_items[item_id])
		if cnt > 0:
			sellable_items.append({"id": String(item_id), "count": cnt, "type": "barn"})
			
	if sellable_items.is_empty():
		var lbl_empty: Label = Label.new()
		lbl_empty.text = "Kho trống! Bạn chưa có nông sản hay thành phẩm nào."
		lbl_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_empty.add_theme_font_size_override("font_size", 12)
		lbl_empty.add_theme_color_override("font_color", Color(0.5, 0.35, 0.2))
		vbox_list.add_child(lbl_empty)
	else:
		for s_data: Dictionary in sellable_items:
			var i_id: String = String(s_data["id"])
			var i_cnt: int = int(s_data["count"])
			var i_name: String = DataManager.get_item_name(i_id)
			var base_p: int = DataManager.get_item_base_price(i_id)
			
			var row_item: PanelContainer = PanelContainer.new()
			var r_sb: StyleBoxFlat = StyleBoxFlat.new()
			r_sb.bg_color = Color(1.0, 1.0, 1.0, 0.9)
			r_sb.border_color = Color(0.85, 0.75, 0.60, 1.0)
			r_sb.set_border_width_all(1)
			r_sb.set_corner_radius_all(6)
			r_sb.content_margin_left = 8
			r_sb.content_margin_right = 8
			r_sb.content_margin_top = 4
			r_sb.content_margin_bottom = 4
			row_item.add_theme_stylebox_override("panel", r_sb)
			
			var hbox_row: HBoxContainer = HBoxContainer.new()
			hbox_row.add_theme_constant_override("separation", 8)
			row_item.add_child(hbox_row)
			
			var icon_rect: TextureRect = TextureRect.new()
			icon_rect.custom_minimum_size = Vector2(36, 36)
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			if SpriteAtlasManager.has_texture(i_id):
				icon_rect.texture = SpriteAtlasManager.get_texture(i_id)
			hbox_row.add_child(icon_rect)
			
			var vbox_info: VBoxContainer = VBoxContainer.new()
			vbox_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			vbox_info.alignment = BoxContainer.ALIGNMENT_CENTER
			hbox_row.add_child(vbox_info)
			
			var lbl_row_name: Label = Label.new()
			lbl_row_name.text = "%s (Có: %d)" % [i_name, i_cnt]
			lbl_row_name.add_theme_font_size_override("font_size", 11)
			lbl_row_name.add_theme_color_override("font_color", Color(0.25, 0.15, 0.05))
			vbox_info.add_child(lbl_row_name)
			
			var sell_qty: int = mini(i_cnt, 5) if i_cnt >= 5 else i_cnt
			var norm_price: int = base_p * sell_qty
			var max_price: int = RoadsideShop.get_suggested_price(i_id, sell_qty)
			
			var lbl_row_price: Label = Label.new()
			lbl_row_price.text = "Bán %d: %d Vàng (Max: %d)" % [sell_qty, norm_price, max_price]
			lbl_row_price.add_theme_font_size_override("font_size", 9)
			lbl_row_price.add_theme_color_override("font_color", Color(0.65, 0.45, 0.10))
			vbox_info.add_child(lbl_row_price)
			
			var btn_sell_norm: Button = Button.new()
			btn_sell_norm.text = "%d Vàng" % norm_price
			btn_sell_norm.tooltip_text = "Đăng bán giá chuẩn"
			btn_sell_norm.pressed.connect(func() -> void:
				if RoadsideShop.list_item(slot_index, i_id, sell_qty, norm_price):
					AudioManager.play_sfx("coin")
					show_floating_notice("💰 Đã đăng bán %dx %s (%d Vàng)!" % [sell_qty, i_name, norm_price])
					_sell_picker_modal.queue_free()
					_refresh_shop_ui()
			)
			hbox_row.add_child(btn_sell_norm)
			
			var btn_sell_max: Button = Button.new()
			btn_sell_max.text = "★ %d" % max_price
			btn_sell_max.tooltip_text = "Đăng bán giá tối đa"
			btn_sell_max.pressed.connect(func() -> void:
				if RoadsideShop.list_item(slot_index, i_id, sell_qty, max_price):
					AudioManager.play_sfx("coin")
					show_floating_notice("★ Đã đăng bán %dx %s giá tối đa (%d Vàng)!" % [sell_qty, i_name, max_price])
					_sell_picker_modal.queue_free()
					_refresh_shop_ui()
			)
			hbox_row.add_child(btn_sell_max)
			
			vbox_list.add_child(row_item)
	
	add_child(_sell_picker_modal)

# --- Truck Orders Modal ---

func toggle_truck_popup() -> void:
	AudioManager.play_sfx("click")
	panel_truck.visible = not panel_truck.visible
	if panel_truck.visible:
		panel_shop.visible = false
		if _storage_modal != null:
			_storage_modal.visible = false
		_refresh_truck_ui()

func _refresh_truck_ui() -> void:
	if truck_orders_container == null or TruckOrderSystem == null:
		return
	
	for child: Node in truck_orders_container.get_children():
		child.queue_free()
	
	var orders: Array[Dictionary] = TruckOrderSystem.get_orders()
	for i: int in range(orders.size()):
		var order: Dictionary = orders[i]
		var card: PanelContainer = _create_truck_order_card(i, order)
		truck_orders_container.add_child(card)

func _create_truck_order_card(order_index: int, order: Dictionary) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(280, 140)
	
	# Cozy Pastel Wood/Parchment StyleBox
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.97, 0.93, 0.84, 0.96)
	sb.border_color = Color(0.72, 0.54, 0.35, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", sb)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)
	
	if bool(order.get("is_refreshing", false)):
		var cd: int = int(order.get("refresh_time_left", 15))
		var lbl_cd: Label = Label.new()
		lbl_cd.text = "⏳ Đang đổi đơn mới...\nCòn lại: %d giây" % cd
		lbl_cd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_cd.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_cd.size_flags_vertical = Control.SIZE_EXPAND_FILL
		lbl_cd.add_theme_font_size_override("font_size", 13)
		lbl_cd.add_theme_color_override("font_color", Color(0.5, 0.35, 0.2))
		vbox.add_child(lbl_cd)
		return card
	
	# Header: Order ID & Reward Badges
	var hbox_header: HBoxContainer = HBoxContainer.new()
	vbox.add_child(hbox_header)
	
	var lbl_id: Label = Label.new()
	lbl_id.text = "📋 ĐƠN #%d" % (order_index + 1)
	lbl_id.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_id.add_theme_font_size_override("font_size", 13)
	lbl_id.add_theme_color_override("font_color", Color(0.35, 0.22, 0.12))
	hbox_header.add_child(lbl_id)
	
	var gold: int = int(order.get("reward_gold", 0))
	var xp: int = int(order.get("reward_xp", 0))
	var lbl_rew: Label = Label.new()
	lbl_rew.text = "+%d Vàng  +%d ★" % [gold, xp]
	lbl_rew.add_theme_font_size_override("font_size", 12)
	lbl_rew.add_theme_color_override("font_color", Color(0.85, 0.55, 0.10))
	hbox_header.add_child(lbl_rew)
	
	# Requirements list
	var reqs: Dictionary = order.get("requirements", {}) as Dictionary
	var can_fulfill: bool = true
	
	for item_id: Variant in reqs:
		var needed: int = int(reqs[item_id])
		var have: int = StorageManager.get_item_count(String(item_id))
		var item_name: String = DataManager.get_item_name(String(item_id))
		
		var hbox_item: HBoxContainer = HBoxContainer.new()
		hbox_item.add_theme_constant_override("separation", 6)
		
		var item_icon: TextureRect = TextureRect.new()
		item_icon.custom_minimum_size = Vector2(20, 20)
		item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if SpriteAtlasManager.has_texture(String(item_id)):
			item_icon.texture = SpriteAtlasManager.get_texture(String(item_id))
		hbox_item.add_child(item_icon)
		
		var lbl_req: Label = Label.new()
		lbl_req.text = "%s: %d/%d" % [item_name, have, needed]
		lbl_req.add_theme_font_size_override("font_size", 12)
		if have < needed:
			can_fulfill = false
			lbl_req.add_theme_color_override("font_color", Color(0.85, 0.25, 0.20)) # Red-orange
		else:
			lbl_req.add_theme_color_override("font_color", Color(0.18, 0.58, 0.18)) # Fresh Green
		hbox_item.add_child(lbl_req)
		vbox.add_child(hbox_item)
	
	# Action Buttons: Giao Hàng & Đổi Đơn
	var hbox_btns: HBoxContainer = HBoxContainer.new()
	hbox_btns.add_theme_constant_override("separation", 8)
	vbox.add_child(hbox_btns)
	
	var btn_send: Button = Button.new()
	btn_send.text = "Giao Hàng"
	btn_send.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_send.disabled = not can_fulfill
	btn_send.custom_minimum_size = Vector2(110, 32)
	_apply_dialog_action_button(btn_send, false)
	btn_send.pressed.connect(func() -> void:
		if TruckOrderSystem.fulfill_order(order_index):
			var truck_screen_pos: Vector2 = Vector2(352, 576)
			_on_loot_collected("gold", gold, truck_screen_pos)
			_on_loot_collected("xp", xp, truck_screen_pos + Vector2(25, -15))
			var farm: Node = get_tree().current_scene
			if farm != null and farm.has_method("play_truck_delivery_animation"):
				farm.call("play_truck_delivery_animation")
			panel_truck.visible = false
	)
	hbox_btns.add_child(btn_send)
	
	var btn_trash: Button = Button.new()
	btn_trash.text = "Đổi Đơn"
	btn_trash.custom_minimum_size = Vector2(80, 32)
	var sb_trash: StyleBoxFlat = StyleBoxFlat.new()
	sb_trash.bg_color = Color(0.85, 0.35, 0.25)
	sb_trash.border_color = Color(0.60, 0.20, 0.15)
	sb_trash.set_border_width_all(2)
	sb_trash.set_corner_radius_all(8)
	btn_trash.add_theme_stylebox_override("normal", sb_trash)
	btn_trash.add_theme_stylebox_override("hover", sb_trash)
	btn_trash.add_theme_color_override("font_color", Color(1, 1, 1))
	btn_trash.pressed.connect(func() -> void:
		TruckOrderSystem.trash_order(order_index)
	)
	hbox_btns.add_child(btn_trash)
	
	return card

# --- Flying Loot Bezier Animation ---

func _on_loot_collected(item_id: String, amount: int, world_pos: Vector2) -> void:
	if amount <= 0:
		return
	
	# Convert world coordinates to Canvas screen coordinates
	var screen_start: Vector2 = Vector2.ZERO
	var farm: Node = get_tree().current_scene
	if farm != null and farm.has_method("_world_to_screen"):
		screen_start = farm.call("_world_to_screen", world_pos)
	else:
		var canvas_xform: Transform2D = get_viewport().get_canvas_transform()
		screen_start = canvas_xform * world_pos
	
	# Destination position on HUD & Target Control for punch animation
	var target_punch_node: Control = progress_barn
	var item_color: Color = Color(1.0, 0.95, 0.7, 1.0)
	var text_display: String = "+%d" % amount
	
	if item_id == "gold" or item_id == "coins" or item_id == "coin":
		target_punch_node = label_gold if label_gold != null else progress_barn
		item_color = Color(1.0, 0.88, 0.2, 1.0)
		text_display = "+%d Xu" % amount
	elif item_id == "xp":
		target_punch_node = label_level if label_level != null else progress_barn
		item_color = Color(0.45, 0.88, 1.0, 1.0)
		text_display = "+%d XP" % amount
	elif item_id in ["wheat", "corn", "carrot", "apple", "mango", "soybean", "sugarcane", "sunflower", "rose", "lavender", "tomato", "pumpkin", "apple_seed", "mango_seed"] or DataManager.get_item_storage_type(item_id) == "silo":
		target_punch_node = progress_silo if progress_silo != null else progress_barn
		item_color = Color(1.0, 0.95, 0.4, 1.0)
	else:
		target_punch_node = progress_barn
	
	var screen_target: Vector2 = Vector2(170, 150)
	if is_instance_valid(target_punch_node) and target_punch_node.is_inside_tree():
		screen_target = target_punch_node.global_position + target_punch_node.size * 0.5
	
	# Spawn floating loot node
	var loot_box: HBoxContainer = HBoxContainer.new()
	loot_box.z_index = 120
	loot_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loot_box.add_theme_constant_override("separation", 5)
	
	var icon_rect: TextureRect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(30, 30)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if SpriteAtlasManager != null:
		if SpriteAtlasManager.has_texture(item_id):
			icon_rect.texture = SpriteAtlasManager.get_texture(item_id)
		elif (item_id == "gold" or item_id == "coins") and SpriteAtlasManager.has_texture("icon_gold"):
			icon_rect.texture = SpriteAtlasManager.get_texture("icon_gold")
		elif item_id == "xp" and SpriteAtlasManager.has_texture("icon_xp"):
			icon_rect.texture = SpriteAtlasManager.get_texture("icon_xp")
		elif SpriteAtlasManager.has_texture("crop_basket"):
			icon_rect.texture = SpriteAtlasManager.get_texture("crop_basket")
	loot_box.add_child(icon_rect)
	
	var lbl: Label = Label.new()
	lbl.text = text_display
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", item_color)
	lbl.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.04, 1.0))
	lbl.add_theme_constant_override("outline_size", 3)
	loot_box.add_child(lbl)
	
	add_child(loot_box)
	loot_box.position = screen_start - Vector2(20.0, 15.0)
	loot_box.scale = Vector2(0.4, 0.4)
	
	# Phase 1: Hop bounce up in place
	var hop_target: Vector2 = loot_box.position + Vector2(0.0, -30.0)
	var hop_tw: Tween = create_tween().set_parallel(true)
	hop_tw.tween_property(loot_box, "position:y", hop_target.y, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	hop_tw.tween_property(loot_box, "scale", Vector2(1.15, 1.15), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Phase 2: Quadratic Bezier Curve to HUD
	await hop_tw.finished
	if not is_instance_valid(loot_box):
		return
	
	var p0: Vector2 = loot_box.position
	var p2: Vector2 = screen_target
	var p1: Vector2 = (p0 + p2) * 0.5
	p1.y -= randf_range(60.0, 110.0)
	p1.x += randf_range(-30.0, 30.0)
	
	var fly_tw: Tween = create_tween().set_parallel(true)
	fly_tw.tween_method(func(t: float) -> void:
		if is_instance_valid(loot_box):
			var inv_t: float = 1.0 - t
			loot_box.position = inv_t * inv_t * p0 + 2.0 * inv_t * t * p1 + t * t * p2
	, 0.0, 1.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	fly_tw.tween_property(loot_box, "scale", Vector2(0.65, 0.65), 0.55)
	
	await fly_tw.finished
	if is_instance_valid(target_punch_node) and target_punch_node.is_inside_tree():
		var punch: Tween = create_tween()
		target_punch_node.pivot_offset = target_punch_node.size * 0.5
		punch.tween_property(target_punch_node, "scale", Vector2(1.14, 1.14), 0.06)
		punch.tween_property(target_punch_node, "scale", Vector2.ONE, 0.08)
	
	if is_instance_valid(loot_box):
		loot_box.queue_free()

# --- Storage Management Modal (Silo & Barn) ---

var _storage_modal: PanelContainer = null
var _current_storage_view: String = "silo"

func open_storage_popup(storage_type: String) -> void:
	AudioManager.play_sfx("click")
	_current_storage_view = storage_type
	panel_shop.visible = false
	panel_truck.visible = false
	if panel_seeds_menu != null:
		panel_seeds_menu.visible = false
	
	if _storage_modal == null:
		_init_storage_modal()
	
	_refresh_storage_modal()
	_storage_modal.visible = true

func _init_storage_modal() -> void:
	_storage_modal = PanelContainer.new()
	_storage_modal.name = "StorageModal"
	_storage_modal.custom_minimum_size = Vector2(460, 390)
	_storage_modal.anchors_preset = Control.PRESET_CENTER
	_storage_modal.anchor_left = 0.5
	_storage_modal.anchor_top = 0.5
	_storage_modal.anchor_right = 0.5
	_storage_modal.anchor_bottom = 0.5
	_storage_modal.offset_left = -230.0
	_storage_modal.offset_top = -195.0
	_storage_modal.offset_right = 230.0
	_storage_modal.offset_bottom = 195.0
	_storage_modal.z_index = 60
	
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.96, 0.92, 0.83, 0.98)
	sb.border_color = Color(0.58, 0.38, 0.22, 1.0)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	_storage_modal.add_theme_stylebox_override("panel", sb)
	
	add_child(_storage_modal)

func _refresh_storage_modal() -> void:
	if _storage_modal == null:
		return
	
	for ch: Node in _storage_modal.get_children():
		ch.queue_free()
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_storage_modal.add_child(vbox)
	
	# Header
	var hbox_head: HBoxContainer = HBoxContainer.new()
	vbox.add_child(hbox_head)
	
	var default_title: String = " QUẢN LÝ KHO SILO" if _current_storage_view == "silo" else "📦 QUẢN LÝ KHO BARN"
	var building_key: String = "building_silo" if _current_storage_view == "silo" else "building_barn"
	var display_title: String = SaveManager.get_building_name(building_key, default_title)
	
	var lbl_title: Label = Label.new()
	lbl_title.text = display_title
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_title.add_theme_font_size_override("font_size", 16)
	lbl_title.add_theme_color_override("font_color", Color(0.35, 0.20, 0.10))
	hbox_head.add_child(lbl_title)
	
	var btn_rename: Button = Button.new()
	btn_rename.text = "Đổi Tên"
	btn_rename.custom_minimum_size = Vector2(80, 26)
	btn_rename.pressed.connect(func() -> void:
		open_rename_modal(building_key, default_title, func(_new_name: String) -> void:
			_refresh_storage_modal()
		)
	)
	hbox_head.add_child(btn_rename)
	
	var btn_close: Button = Button.new()
	_apply_dialog_close_button(btn_close)
	btn_close.pressed.connect(func() -> void:
		_storage_modal.visible = false
	)
	hbox_head.add_child(btn_close)
	
	# Capacity Info
	var used: int = StorageManager.get_silo_used() if _current_storage_view == "silo" else StorageManager.get_barn_used()
	var max_cap: int = StorageManager.silo_capacity if _current_storage_view == "silo" else StorageManager.barn_capacity
	
	var hbox_cap: HBoxContainer = HBoxContainer.new()
	hbox_cap.add_theme_constant_override("separation", 8)
	vbox.add_child(hbox_cap)
	
	var lbl_cap: Label = Label.new()
	lbl_cap.text = "Sức chứa: %d / %d ô" % [used, max_cap]
	lbl_cap.add_theme_font_size_override("font_size", 13)
	lbl_cap.add_theme_color_override("font_color", Color(0.24, 0.15, 0.10))
	hbox_cap.add_child(lbl_cap)
	
	var pbar: ProgressBar = ProgressBar.new()
	pbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pbar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pbar.custom_minimum_size = Vector2(120, 10)
	pbar.max_value = max_cap
	pbar.value = used
	pbar.show_percentage = false
	hbox_cap.add_child(pbar)
	
	# Item Grid in ScrollContainer with MarginContainer padding
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(420, 210)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var margin_container: MarginContainer = MarginContainer.new()
	margin_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin_container.add_theme_constant_override("margin_top", 10)
	margin_container.add_theme_constant_override("margin_bottom", 10)
	margin_container.add_theme_constant_override("margin_left", 6)
	margin_container.add_theme_constant_override("margin_right", 6)
	scroll.add_child(margin_container)
	
	var grid: GridContainer = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	margin_container.add_child(grid)
	
	var items_dict: Dictionary = StorageManager.silo_items if _current_storage_view == "silo" else StorageManager.barn_items
	var item_count_total: int = 0
	
	for item_id: Variant in items_dict:
		var count: int = int(items_dict[item_id])
		if count > 0:
			item_count_total += 1
			var item_card: PanelContainer = PanelContainer.new()
			item_card.custom_minimum_size = Vector2(96, 88)
			
			var item_sb: StyleBoxFlat = StyleBoxFlat.new()
			item_sb.bg_color = Color(1.0, 1.0, 1.0, 0.8)
			item_sb.border_color = Color(0.8, 0.7, 0.55, 1.0)
			item_sb.set_border_width_all(1)
			item_sb.set_corner_radius_all(6)
			item_card.add_theme_stylebox_override("panel", item_sb)
			
			var cvbox: VBoxContainer = VBoxContainer.new()
			cvbox.alignment = BoxContainer.ALIGNMENT_CENTER
			item_card.add_child(cvbox)
			
			var s_icon: TextureRect = TextureRect.new()
			s_icon.custom_minimum_size = Vector2(44, 44)
			s_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			s_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			s_icon.texture = SpriteAtlasManager.get_texture(String(item_id))
			cvbox.add_child(s_icon)
			
			var s_name: Label = Label.new()
			s_name.text = DataManager.get_item_name(String(item_id))
			s_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			s_name.add_theme_font_size_override("font_size", 10)
			s_name.add_theme_color_override("font_color", Color(0.3, 0.2, 0.1))
			cvbox.add_child(s_name)
			
			var s_qty: Label = Label.new()
			s_qty.text = "x%d" % count
			s_qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			s_qty.add_theme_font_size_override("font_size", 11)
			s_qty.add_theme_color_override("font_color", Color(0.1, 0.5, 0.15))
			cvbox.add_child(s_qty)
			
			grid.add_child(item_card)
	
	if item_count_total == 0:
		var empty_lbl: Label = Label.new()
		empty_lbl.text = "Kho hiện đang trống."
		empty_lbl.add_theme_font_size_override("font_size", 12)
		empty_lbl.add_theme_color_override("font_color", Color(0.6, 0.5, 0.4))
		grid.add_child(empty_lbl)
	
	# Upgrade button
	var btn_upgrade: Button = Button.new()
	var can_upgrade: bool = StorageManager.has_gold(300)
	if can_upgrade:
		btn_upgrade.text = "⬆️ Nâng Cấp Kho (+25 sức chứa) - 300 Vàng"
		btn_upgrade.disabled = false
	else:
		btn_upgrade.text = "⬆️ Nâng Cấp Kho (+25 sức chứa) - Cần 300 Vàng"
		btn_upgrade.disabled = true
	
	btn_upgrade.custom_minimum_size = Vector2(0, 36)
	btn_upgrade.pressed.connect(func() -> void:
		if StorageManager.spend_gold(300):
			StorageManager.upgrade_storage(_current_storage_view, 25)
			SaveManager.save_game()
			_refresh_storage_modal()
			# Emit gold changed
			EventBus.gold_changed.emit(StorageManager.gold, -300)
	)
	vbox.add_child(btn_upgrade)

func open_rename_modal(building_id: String, default_name: String, on_renamed: Callable = Callable()) -> void:
	AudioManager.play_sfx("click")
	if _rename_modal != null and is_instance_valid(_rename_modal):
		_rename_modal.queue_free()
	
	_rename_modal = PanelContainer.new()
	_rename_modal.name = "RenameModal"
	_rename_modal.custom_minimum_size = Vector2(340, 180)
	_rename_modal.anchors_preset = Control.PRESET_CENTER
	_rename_modal.anchor_left = 0.5
	_rename_modal.anchor_top = 0.5
	_rename_modal.anchor_right = 0.5
	_rename_modal.anchor_bottom = 0.5
	_rename_modal.offset_left = -170.0
	_rename_modal.offset_top = -90.0
	_rename_modal.offset_right = 170.0
	_rename_modal.offset_bottom = 90.0
	_rename_modal.z_index = 80
	
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.98, 0.95, 0.88, 0.98)
	sb.border_color = Color(0.60, 0.40, 0.22, 1.0)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	_rename_modal.add_theme_stylebox_override("panel", sb)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_rename_modal.add_child(vbox)
	
	var lbl_title: Label = Label.new()
	lbl_title.text = "Đổi Tên Công Trình"
	lbl_title.add_theme_font_size_override("font_size", 14)
	lbl_title.add_theme_color_override("font_color", Color(0.35, 0.20, 0.10))
	vbox.add_child(lbl_title)
	
	var edit: LineEdit = LineEdit.new()
	edit.max_length = 16
	edit.placeholder_text = "Nhập tên (tối đa 16 ký tự)..."
	edit.text = SaveManager.get_building_name(building_id, default_name)
	vbox.add_child(edit)
	
	var hbox_btns: HBoxContainer = HBoxContainer.new()
	hbox_btns.alignment = BoxContainer.ALIGNMENT_END
	hbox_btns.add_theme_constant_override("separation", 8)
	vbox.add_child(hbox_btns)
	
	var btn_default: Button = Button.new()
	btn_default.text = "Mặc Định"
	btn_default.pressed.connect(func() -> void:
		SaveManager.set_building_name(building_id, "")
		AudioManager.play_sfx("click")
		if on_renamed.is_valid():
			on_renamed.call(default_name)
		_rename_modal.queue_free()
	)
	hbox_btns.add_child(btn_default)
	
	var btn_confirm: Button = Button.new()
	btn_confirm.text = "Xác Nhận"
	btn_confirm.pressed.connect(func() -> void:
		var new_name: String = edit.text.strip_edges()
		if new_name == "":
			new_name = default_name
			SaveManager.set_building_name(building_id, "")
		else:
			SaveManager.set_building_name(building_id, new_name)
		AudioManager.play_sfx("click")
		if on_renamed.is_valid():
			on_renamed.call(new_name)
		_rename_modal.queue_free()
	)
	hbox_btns.add_child(btn_confirm)
	
	var btn_cancel: Button = Button.new()
	btn_cancel.text = "Đóng"
	btn_cancel.pressed.connect(func() -> void:
		_rename_modal.queue_free()
	)
	hbox_btns.add_child(btn_cancel)
	
	add_child(_rename_modal)

# --- Contextual Popups & Construction Catalog (Hay Day Episode 1 Standard) ---

var _build_modal: PanelContainer = null
var _contextual_seed_popup: PanelContainer = null
var _recipe_modal: PanelContainer = null

func open_build_modal() -> void:
	AudioManager.play_sfx("click")
	if _build_modal != null and is_instance_valid(_build_modal):
		_build_modal.queue_free()
	
	_build_modal = PanelContainer.new()
	_build_modal.name = "BuildModal"
	_build_modal.custom_minimum_size = Vector2(760, 520)
	_build_modal.anchors_preset = Control.PRESET_CENTER
	_build_modal.anchor_left = 0.5
	_build_modal.anchor_top = 0.5
	_build_modal.anchor_right = 0.5
	_build_modal.anchor_bottom = 0.5
	_build_modal.offset_left = -380.0
	_build_modal.offset_top = -260.0
	_build_modal.offset_right = 380.0
	_build_modal.offset_bottom = 260.0
	_build_modal.z_index = 80
	
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.99, 0.96, 0.90, 0.98)
	sb.border_color = Color(0.60, 0.40, 0.22, 1.0)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	_build_modal.add_theme_stylebox_override("panel", sb)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_build_modal.add_child(vbox)
	
	# Header
	var hbox_head: HBoxContainer = HBoxContainer.new()
	vbox.add_child(hbox_head)
	
	var lbl_title: Label = Label.new()
	lbl_title.text = "CỬA HÀNG XÂY DỰNG & TRANG TRÍ"
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_title.add_theme_font_size_override("font_size", 16)
	lbl_title.add_theme_color_override("font_color", Color(0.35, 0.20, 0.10))
	hbox_head.add_child(lbl_title)
	
	var btn_close: Button = Button.new()
	_apply_dialog_close_button(btn_close)
	btn_close.pressed.connect(func() -> void:
		_build_modal.visible = false
	)
	hbox_head.add_child(btn_close)
	
	var shop_ids: Array[String] = [
		"field_plot", "feed_mill", "bakery", "cow_pasture", "pig_pen", "sheep_pasture",
		"juice_stand", "cake_oven",
		"wooden_bench", "flower_bed", "fountain", "hedge_white", "wood_bridge", "park_bench",
		"scarecrow", "zoo_shop", "flower_arch", "lantern_park", "fountain_east", "honor_board",
		"zoo_fastfood", "golden_statue"
	]
	
	var catalog: Array[Dictionary] = []
	for b_id: String in shop_ids:
		var b_data: Dictionary = DataManager.get_building(b_id)
		if b_data.is_empty():
			continue
		
		var icon_key: String = ""
		var custom_sprite: String = String(b_data.get("sprite", ""))
		if not custom_sprite.is_empty() and SpriteAtlasManager.has_texture(custom_sprite):
			icon_key = custom_sprite
		elif SpriteAtlasManager.has_texture(b_id):
			icon_key = b_id
		else:
			match b_id:
				"field_plot": icon_key = "wheat"
				"cow_pasture": icon_key = "cow"
				"pig_pen": icon_key = "pig"
				"sheep_pasture": icon_key = "sheep"
				"juice_stand": icon_key = "building_juice_stand"
				"cake_oven": icon_key = "building_cake_oven"
				"flower_bed": icon_key = "flowerbed_round"
				"hedge_white": icon_key = "wooden_bench"
				"wood_bridge": icon_key = "decor_wooden_bench"
				"flower_arch": icon_key = "flowerbed_round"
				"honor_board": icon_key = "decor_wooden_bench"
				"zoo_fastfood": icon_key = "zoo_feed_shop"
				"golden_statue": icon_key = "fountain"
				_: icon_key = "decor_wooden_bench"
		
		var is_prod: bool = (b_id in ["field_plot", "feed_mill", "bakery", "cow_pasture", "pig_pen", "sheep_pasture", "juice_stand", "cake_oven"])
		catalog.append({
			"id": b_id,
			"name": String(b_data.get("name", b_id.capitalize())),
			"desc": String(b_data.get("description", "")),
			"cost_gold": b_data.get("cost_gold", null),
			"unlock_level": int(b_data.get("unlock_level", 1)),
			"build_materials": b_data.get("build_materials", {}) as Dictionary,
			"icon": icon_key,
			"category": "production" if is_prod else "decor"
		})
	
	catalog.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var lv_a: int = int(a.get("unlock_level", 1))
		var lv_b: int = int(b.get("unlock_level", 1))
		if lv_a != lv_b:
			return lv_a < lv_b
		return String(a.get("id", "")) < String(b.get("id", ""))
	)
	
	# Category Tabs
	var hbox_tabs: HBoxContainer = HBoxContainer.new()
	hbox_tabs.add_theme_constant_override("separation", 8)
	vbox.add_child(hbox_tabs)
	
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(728, 410)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)
	
	var populate_grid: Callable = func(filter_cat: String) -> void:
		for c: Node in grid.get_children():
			c.queue_free()
		for item: Dictionary in catalog:
			if filter_cat != "all" and String(item.get("category", "")) != filter_cat:
				continue
			var card: PanelContainer = _create_build_card(item)
			grid.add_child(card)
			
	var btn_all: Button = Button.new()
	btn_all.text = "Tất Cả (%d)" % catalog.size()
	_apply_dialog_action_button(btn_all, true)
	btn_all.pressed.connect(func() -> void: populate_grid.call("all"))
	hbox_tabs.add_child(btn_all)
	
	var btn_prod: Button = Button.new()
	btn_prod.text = "Sản Xuất & Ruộng"
	_apply_dialog_action_button(btn_prod, true)
	btn_prod.pressed.connect(func() -> void: populate_grid.call("production"))
	hbox_tabs.add_child(btn_prod)
	
	var btn_decor: Button = Button.new()
	btn_decor.text = "Trang Trí & Cảnh Quan"
	_apply_dialog_action_button(btn_decor, true)
	btn_decor.pressed.connect(func() -> void: populate_grid.call("decor"))
	hbox_tabs.add_child(btn_decor)
	
	populate_grid.call("all")
	add_child(_build_modal)

func _create_build_card(item: Dictionary) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(236, 96)
	
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 1.0, 1.0, 0.92)
	sb.border_color = Color(0.80, 0.70, 0.55, 1.0)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	card.add_theme_stylebox_override("panel", sb)
	
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	card.add_child(hbox)
	
	var icon: TextureRect = TextureRect.new()
	icon.custom_minimum_size = Vector2(56, 56)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var icon_key: String = String(item.get("icon", ""))
	if SpriteAtlasManager.has_texture(icon_key):
		icon.texture = SpriteAtlasManager.get_texture(icon_key)
	hbox.add_child(icon)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(vbox)
	
	var lbl_name: Label = Label.new()
	lbl_name.text = String(item.get("name", ""))
	lbl_name.add_theme_font_size_override("font_size", 11)
	lbl_name.add_theme_color_override("font_color", Color(0.3, 0.18, 0.08))
	vbox.add_child(lbl_name)
	
	var b_id: String = String(item.get("id", ""))
	var raw_cost: Variant = item.get("cost_gold", null)
	var has_price: bool = (raw_cost != null)
	var cost: int = int(raw_cost) if has_price else 0
	var req_level: int = int(item.get("unlock_level", 1))
	var req_mats: Dictionary = item.get("build_materials", {}) as Dictionary
	var mat_str_parts: Array[String] = []
	var has_all_mats: bool = true
	var missing_mat_msg: String = ""
	for m_id: String in req_mats:
		var needed: int = int(req_mats[m_id])
		var cur: int = StorageManager.get_item_count(m_id)
		var m_name: String = StorageManager.get_item_display_name(m_id)
		if m_id == "mat_plank": mat_str_parts.append("Ván Gỗ:%d" % needed)
		elif m_id == "mat_bolt": mat_str_parts.append("Bu-lông:%d" % needed)
		elif m_id == "mat_brick": mat_str_parts.append("Gạch:%d" % needed)
		else: mat_str_parts.append("%s x%d" % [m_name, needed])
		if cur < needed:
			has_all_mats = false
			if missing_mat_msg.is_empty():
				missing_mat_msg = "Thiếu %s (%d/%d)" % [m_name, cur, needed]
	
	var lbl_info: Label = Label.new()
	var cost_text: String = ""
	if has_price:
		cost_text = "Cấp %d | %d Vàng" % [req_level, cost]
	else:
		cost_text = "Cấp %d | Chưa có giá" % req_level
	if not mat_str_parts.is_empty():
		cost_text += " | " + " ".join(mat_str_parts)
	lbl_info.text = cost_text
	lbl_info.add_theme_font_size_override("font_size", 10)
	lbl_info.add_theme_color_override("font_color", Color(0.8, 0.45, 0.1))
	vbox.add_child(lbl_info)
	
	var btn_buy: Button = Button.new()
	btn_buy.custom_minimum_size = Vector2(0, 26)
	var can_afford_gold: bool = StorageManager.gold >= cost
	var meets_level: bool = StorageManager.level >= req_level
	if not has_price:
		btn_buy.text = "Chưa có giá"
		btn_buy.disabled = true
	elif not meets_level:
		btn_buy.text = "Cần Cấp %d" % req_level
		btn_buy.disabled = true
	elif not can_afford_gold:
		btn_buy.text = "Thiếu Vàng"
		btn_buy.disabled = true
	elif not has_all_mats:
		btn_buy.text = missing_mat_msg
		btn_buy.disabled = true
	else:
		btn_buy.text = "Xây Dựng"
		btn_buy.disabled = false
		_apply_dialog_action_button(btn_buy, false)
		btn_buy.pressed.connect(func() -> void:
			_build_modal.visible = false
			if b_id == "field_plot":
				_on_tool_selected(DragActionManager.ToolType.BUILD_FIELD)
				return
			var farm: Node = get_tree().current_scene
			if farm != null and farm.has_method("start_building_placement"):
				farm.call("start_building_placement", b_id, cost, req_mats)
		)
	vbox.add_child(btn_buy)
	
	return card

func open_contextual_seed_popup(plot: FieldPlot) -> void:
	if not is_instance_valid(plot) or plot.state != FieldPlot.PlotState.EMPTY:
		return
	
	AudioManager.play_sfx("click")
	if _contextual_seed_popup != null and is_instance_valid(_contextual_seed_popup):
		_contextual_seed_popup.queue_free()
	
	_contextual_seed_popup = PanelContainer.new()
	_contextual_seed_popup.name = "ContextualSeedPopup"
	_contextual_seed_popup.custom_minimum_size = Vector2(270, 110)
	_contextual_seed_popup.z_index = 85
	
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 0.99, 0.95, 0.98)
	sb.border_color = Color(0.60, 0.42, 0.22, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.shadow_color = Color(0.3, 0.2, 0.1, 0.25)
	sb.shadow_size = 6
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	_contextual_seed_popup.add_theme_stylebox_override("panel", sb)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_contextual_seed_popup.add_child(vbox)
	
	# Header
	var hbox_head: HBoxContainer = HBoxContainer.new()
	vbox.add_child(hbox_head)
	
	var lbl: Label = Label.new()
	lbl.text = "🌱 CHỌN HẠT GIỐNG GIEO TRỒNG"
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.35, 0.22, 0.12))
	hbox_head.add_child(lbl)
	
	var btn_close: Button = Button.new()
	_apply_dialog_close_button(btn_close)
	btn_close.custom_minimum_size = Vector2(24, 24)
	btn_close.pressed.connect(func() -> void:
		if is_instance_valid(_contextual_seed_popup):
			_contextual_seed_popup.queue_free()
	)
	hbox_head.add_child(btn_close)
	
	# Seed icons horizontal scroll
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(254, 70)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	
	var hbox_seeds: HBoxContainer = HBoxContainer.new()
	hbox_seeds.add_theme_constant_override("separation", 6)
	scroll.add_child(hbox_seeds)
	
	var quick_crops: Array[Dictionary] = [
		{"id": "wheat", "name": "Lúa Mì", "icon": "wheat"},
		{"id": "corn", "name": "Ngô", "icon": "corn"},
		{"id": "carrot", "name": "Cà Rốt", "icon": "carrot"},
		{"id": "strawberry", "name": "Dâu Tây", "icon": "strawberry"},
		{"id": "sunflower", "name": "Hoa Hướng Dương", "icon": "sunflower"},
		{"id": "rose", "name": "Hoa Hồng", "icon": "rose"},
		{"id": "lavender", "name": "Hoa Oải Hương", "icon": "lavender"},
		{"id": "soybean", "name": "Đậu Nành", "icon": "soybean"},
		{"id": "sugarcane", "name": "Mía", "icon": "sugarcane"}
	]
	
	for qc in quick_crops:
		var c_id: String = String(qc["id"])
		var c_name: String = String(qc["name"])
		var c_cnt: int = StorageManager.get_item_count(c_id)
		
		var s_btn: Button = Button.new()
		s_btn.custom_minimum_size = Vector2(52, 60)
		s_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		s_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s_btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		s_btn.expand_icon = true
		s_btn.add_theme_constant_override("icon_max_width", 28)
		if SpriteAtlasManager.has_texture(String(qc["icon"])):
			s_btn.icon = SpriteAtlasManager.get_texture(String(qc["icon"]))
		s_btn.text = "%d" % c_cnt
		s_btn.tooltip_text = "%s (%d)" % [c_name, c_cnt]
		
		if c_cnt <= 0:
			s_btn.modulate = Color(0.6, 0.6, 0.6, 0.7)
		
		s_btn.pressed.connect(func() -> void:
			if is_instance_valid(plot) and plot.state == FieldPlot.PlotState.EMPTY:
				if StorageManager.has_item(c_id, 1):
					plot.plant(c_id)
					_refresh_seed_counts()
				else:
					AudioManager.play_sfx("error")
			if is_instance_valid(_contextual_seed_popup):
				_contextual_seed_popup.queue_free()
		)
		hbox_seeds.add_child(s_btn)
	
	add_child(_contextual_seed_popup)
	
	# Position near plot in screen coordinates
	var screen_pos: Vector2 = Vector2.ZERO
	var farm: Node = get_tree().current_scene
	if farm != null and farm.has_method("_world_to_screen"):
		screen_pos = farm.call("_world_to_screen", plot.global_position)
	else:
		var xform: Transform2D = get_viewport().get_canvas_transform()
		screen_pos = xform * plot.global_position
	
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var target_x: float = clampf(screen_pos.x - 135.0, 16.0, vp_size.x - 286.0)
	var target_y: float = clampf(screen_pos.y - 125.0, 16.0, vp_size.y - 126.0)
	_contextual_seed_popup.position = Vector2(target_x, target_y)

func open_production_recipe_modal(machine: ProductionMachine) -> void:
	if not is_instance_valid(machine):
		return
	
	AudioManager.play_sfx("click")
	if _recipe_modal != null and is_instance_valid(_recipe_modal):
		_recipe_modal.queue_free()
	
	_recipe_modal = PanelContainer.new()
	_recipe_modal.name = "RecipeModal"
	_recipe_modal.custom_minimum_size = Vector2(440, 320)
	_recipe_modal.anchors_preset = Control.PRESET_CENTER
	_recipe_modal.anchor_left = 0.5
	_recipe_modal.anchor_top = 0.5
	_recipe_modal.anchor_right = 0.5
	_recipe_modal.anchor_bottom = 0.5
	_recipe_modal.offset_left = -220.0
	_recipe_modal.offset_top = -160.0
	_recipe_modal.offset_right = 220.0
	_recipe_modal.offset_bottom = 160.0
	_recipe_modal.z_index = 80
	
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.98, 0.95, 0.88, 0.98)
	sb.border_color = Color(0.60, 0.40, 0.22, 1.0)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	_recipe_modal.add_theme_stylebox_override("panel", sb)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_recipe_modal.add_child(vbox)
	
	# Header
	var hbox_head: HBoxContainer = HBoxContainer.new()
	vbox.add_child(hbox_head)
	
	var m_name: String = DataManager.get_building_name(machine.machine_id)
	var lbl_title: Label = Label.new()
	lbl_title.text = "🍳 %s (CÔNG THỨC CHẾ BIẾN)" % m_name.to_upper()
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_title.add_theme_font_size_override("font_size", 14)
	lbl_title.add_theme_color_override("font_color", Color(0.35, 0.20, 0.10))
	hbox_head.add_child(lbl_title)
	
	var btn_rename: Button = Button.new()
	btn_rename.text = "Đổi Tên"
	btn_rename.custom_minimum_size = Vector2(75, 26)
	btn_rename.tooltip_text = "Đổi tên công trình này"
	btn_rename.pressed.connect(func() -> void:
		_recipe_modal.visible = false
		open_rename_modal(machine.machine_id, m_name, func(_new_name: String) -> void:
			if is_instance_valid(machine):
				machine.call("_update_title_display")
		)
	)
	hbox_head.add_child(btn_rename)

	var btn_close: Button = Button.new()
	_apply_dialog_close_button(btn_close)
	btn_close.pressed.connect(func() -> void:
		_recipe_modal.queue_free()
	)
	hbox_head.add_child(btn_close)
	
	# Status row
	var lbl_status: Label = Label.new()
	var cur_status: String = "Trạng thái: "
	if not machine.queue.is_empty():
		var remaining: int = TickManager.get_time_remaining(int(machine.queue[0].get("finish_timestamp", 0)))
		cur_status += "Đang làm việc (%s)" % TickManager.format_duration(remaining)
	elif not machine.completed_items.is_empty():
		cur_status += "Có %d món đã chín chờ thu!" % machine.completed_items.size()
	else:
		cur_status += "Đang rảnh rỗi (Sẵn sàng sản xuất)"
	lbl_status.text = cur_status
	lbl_status.add_theme_font_size_override("font_size", 11)
	lbl_status.add_theme_color_override("font_color", Color(0.4, 0.25, 0.12))
	vbox.add_child(lbl_status)
	
	if not machine.queue.is_empty():
		var btn_speedup: Button = Button.new()
		btn_speedup.text = "Hoàn Thành Ngay (1 Kim Cương)"
		btn_speedup.custom_minimum_size = Vector2(0, 30)
		btn_speedup.pressed.connect(func() -> void:
			if StorageManager.diamonds < 1:
				show_floating_notice("⚠️ Bạn không đủ Kim Cương (cần 1 Kim Cương)!")
				return
			if is_instance_valid(machine):
				if machine.speed_up_current_job():
					show_floating_notice("⚡ Đã hoàn thành ngay bằng 1 Kim Cương!")
					open_production_recipe_modal(machine)
		)
		vbox.add_child(btn_speedup)
	
	# Recipes Scroll
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(408, 220)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	var vbox_recipes: VBoxContainer = VBoxContainer.new()
	vbox_recipes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_recipes.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox_recipes)
	
	var found_recipes: int = 0
	for rec_key: Variant in DataManager.recipes:
		var rec: Dictionary = DataManager.recipes[rec_key] as Dictionary
		if String(rec.get("building_id", "")) == machine.machine_id:
			found_recipes += 1
			var r_card: PanelContainer = _create_recipe_row(machine, rec)
			vbox_recipes.add_child(r_card)
	
	if found_recipes == 0:
		var lbl_empty: Label = Label.new()
		lbl_empty.text = "Chưa có công thức cho nhà máy này."
		lbl_empty.add_theme_font_size_override("font_size", 12)
		vbox_recipes.add_child(lbl_empty)
	
	add_child(_recipe_modal)

func _create_recipe_row(machine: ProductionMachine, rec: Dictionary) -> PanelContainer:
	var row: PanelContainer = PanelContainer.new()
	row.custom_minimum_size = Vector2(400, 60)
	
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 1.0, 1.0, 0.85)
	sb.border_color = Color(0.85, 0.75, 0.60, 1.0)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	row.add_theme_stylebox_override("panel", sb)
	
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	row.add_child(hbox)
	
	var prod_item: String = String(rec.get("produce_item_id", ""))
	var icon: TextureRect = TextureRect.new()
	icon.custom_minimum_size = Vector2(44, 44)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if SpriteAtlasManager.has_texture(prod_item):
		icon.texture = SpriteAtlasManager.get_texture(prod_item)
	hbox.add_child(icon)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(vbox)
	
	var lbl_name: Label = Label.new()
	lbl_name.text = String(rec.get("name", prod_item))
	lbl_name.add_theme_font_size_override("font_size", 11)
	lbl_name.add_theme_color_override("font_color", Color(0.25, 0.15, 0.05))
	vbox.add_child(lbl_name)
	
	# Ingredients summary
	var ings: Dictionary = rec.get("ingredients", {}) as Dictionary
	var ing_strs: Array[String] = []
	var has_all_ings: bool = true
	for ing: Variant in ings:
		var needed: int = int(ings[ing])
		var current: int = StorageManager.get_item_count(String(ing))
		if current < needed:
			has_all_ings = false
		ing_strs.append("%s (%d/%d)" % [DataManager.get_item_name(String(ing)), current, needed])
	
	var lbl_ings: Label = Label.new()
	lbl_ings.text = "Cần: " + ", ".join(ing_strs)
	lbl_ings.add_theme_font_size_override("font_size", 9)
	if has_all_ings:
		lbl_ings.add_theme_color_override("font_color", Color(0.15, 0.55, 0.20))
	else:
		lbl_ings.add_theme_color_override("font_color", Color(0.80, 0.25, 0.10))
	vbox.add_child(lbl_ings)
	
	var btn_craft: Button = Button.new()
	btn_craft.custom_minimum_size = Vector2(90, 32)
	var rec_id: String = String(rec.get("id", ""))
	if not has_all_ings:
		btn_craft.text = "Thiếu Đồ"
		btn_craft.pressed.connect(func() -> void:
			show_floating_notice("⚠️ Không đủ nguyên liệu để sản xuất %s!" % String(rec.get("name", prod_item)))
			AudioManager.play_sfx("click")
		)
	else:
		btn_craft.text = "Sản Xuất"
		btn_craft.disabled = false
		btn_craft.pressed.connect(func() -> void:
			if is_instance_valid(machine):
				machine.start_recipe(rec_id)
				AudioManager.play_sfx("plant")
				open_production_recipe_modal(machine)
		)
	hbox.add_child(btn_craft)
	
	return row

# ====================================================================
# SỞ THÚ (ZOO SANCTUARY) & BẢNG NHIỆM VỤ (QUEST SYSTEM) MODALS
# ====================================================================

func _refresh_badges() -> void:
	var farm: Node2D = get_tree().current_scene as Node2D
	var qm: QuestManager = null
	if farm != null and farm.get("quest_manager") != null:
		qm = farm.get("quest_manager") as QuestManager
	
	# 1. Quests notification badge
	if badge_quests != null:
		var unclaimed: int = qm.get_unclaimed_count() if qm != null else 0
		if unclaimed > 0:
			badge_quests.visible = true
			badge_quests.text = str(unclaimed)
		else:
			badge_quests.visible = false
			
	# 2. Zoo notification badge (chỉ kích hoạt từ Cấp 11 trở lên)
	if badge_zoo != null:
		if StorageManager.level < 11:
			badge_zoo.visible = false
			if btn_zoo != null:
				btn_zoo.modulate = Color(0.75, 0.75, 0.75, 0.85)
				btn_zoo.tooltip_text = "[Khóa]  Sở Thú Bờ Đông (Mở khóa ở Cấp 11)"
		else:
			if btn_zoo != null:
				btn_zoo.modulate = Color(1, 1, 1, 1)
				btn_zoo.tooltip_text = "Sở Thú Bờ Đông"
			var zoo_alerts: int = 0
			for enc_cfg: Dictionary in DataManager.get_zoo_enclosures():
				var raw_pieces: Variant = enc_cfg.get("puzzle_piece_cost", null)
				if raw_pieces == null:
					continue
				var a_id: String = String(enc_cfg.get("id", ""))
				if not SaveManager.is_animal_unlocked(a_id):
					var cost: int = int(raw_pieces)
					if SaveManager.puzzle_pieces >= cost:
						zoo_alerts += 1
				elif not SaveManager.is_animal_fed(a_id):
					var foods_var: Variant = enc_cfg.get("foods", [])
					if foods_var is Array:
						for f_item: Variant in (foods_var as Array):
							if StorageManager.get_item_count(String(f_item)) > 0:
								zoo_alerts += 1
								break
							
			if zoo_alerts > 0:
				badge_zoo.visible = true
				badge_zoo.text = str(zoo_alerts)
			else:
				badge_zoo.visible = false

func open_quests_modal() -> void:
	AudioManager.play_sfx("click")
	if _quests_modal != null and is_instance_valid(_quests_modal):
		_quests_modal.queue_free()
		return
	
	cancel_all_active_tools()
	
	_quests_modal = PanelContainer.new()
	_quests_modal.name = "QuestsModal"
	_quests_modal.custom_minimum_size = Vector2(580, 480)
	_quests_modal.anchors_preset = Control.PRESET_CENTER
	_quests_modal.anchor_left = 0.5
	_quests_modal.anchor_top = 0.5
	_quests_modal.anchor_right = 0.5
	_quests_modal.anchor_bottom = 0.5
	_quests_modal.offset_left = -290.0
	_quests_modal.offset_top = -240.0
	_quests_modal.offset_right = 290.0
	_quests_modal.offset_bottom = 240.0
	_quests_modal.z_index = 85
	
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.98, 0.95, 0.88, 0.98)
	sb.border_color = Color(0.55, 0.35, 0.18, 1.0)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	sb.shadow_color = Color(0.2, 0.1, 0.05, 0.35)
	sb.shadow_size = 8
	_quests_modal.add_theme_stylebox_override("panel", sb)
	
	var vbox_main: VBoxContainer = VBoxContainer.new()
	vbox_main.add_theme_constant_override("separation", 10)
	_quests_modal.add_child(vbox_main)
	
	# Header
	var hbox_head: HBoxContainer = HBoxContainer.new()
	vbox_main.add_child(hbox_head)
	
	var lbl_title: Label = Label.new()
	lbl_title.text = " BẢNG NHIỆM VỤ NÔNG TRẠI & SỞ THÚ"
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_title.add_theme_font_size_override("font_size", 15)
	lbl_title.add_theme_color_override("font_color", Color(0.35, 0.20, 0.10))
	lbl_title.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0))
	lbl_title.add_theme_constant_override("outline_size", 2)
	hbox_head.add_child(lbl_title)
	
	var btn_close: Button = Button.new()
	_apply_dialog_close_button(btn_close)
	btn_close.pressed.connect(func() -> void:
		_quests_modal.queue_free()
	)
	hbox_head.add_child(btn_close)
	
	# 3 Tabs
	var hbox_tabs: HBoxContainer = HBoxContainer.new()
	hbox_tabs.add_theme_constant_override("separation", 8)
	vbox_main.add_child(hbox_tabs)
	
	var btn_tab_story: Button = Button.new()
	btn_tab_story.text = "📖 Cốt Truyện (12)"
	btn_tab_story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_tab_story.custom_minimum_size = Vector2(0, 32)
	hbox_tabs.add_child(btn_tab_story)
	
	var btn_tab_daily: Button = Button.new()
	btn_tab_daily.text = "⚡ Hàng Ngày & Rương"
	btn_tab_daily.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_tab_daily.custom_minimum_size = Vector2(0, 32)
	hbox_tabs.add_child(btn_tab_daily)
	
	var btn_tab_vip: Button = Button.new()
	btn_tab_vip.text = "📸 Khách VIP Sở Thú"
	btn_tab_vip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_tab_vip.custom_minimum_size = Vector2(0, 32)
	hbox_tabs.add_child(btn_tab_vip)
	
	# Scroll content container
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox_main.add_child(scroll)
	
	var vbox_list: VBoxContainer = VBoxContainer.new()
	vbox_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_list.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox_list)
	
	var refresh_tabs_ui: Callable = func() -> void:
		btn_tab_story.modulate = Color(1.2, 1.25, 0.8) if _active_quest_tab == 0 else Color(1.0, 1.0, 1.0)
		btn_tab_daily.modulate = Color(1.2, 1.25, 0.8) if _active_quest_tab == 1 else Color(1.0, 1.0, 1.0)
		btn_tab_vip.modulate = Color(1.2, 1.25, 0.8) if _active_quest_tab == 2 else Color(1.0, 1.0, 1.0)
		_render_quests_list(vbox_list)
	
	btn_tab_story.pressed.connect(func() -> void:
		_active_quest_tab = 0
		AudioManager.play_sfx("click")
		refresh_tabs_ui.call()
	)
	btn_tab_daily.pressed.connect(func() -> void:
		_active_quest_tab = 1
		AudioManager.play_sfx("click")
		refresh_tabs_ui.call()
	)
	btn_tab_vip.pressed.connect(func() -> void:
		_active_quest_tab = 2
		AudioManager.play_sfx("click")
		refresh_tabs_ui.call()
	)
	
	refresh_tabs_ui.call()
	add_child(_quests_modal)

func _render_quests_list(vbox_list: VBoxContainer) -> void:
	for ch in vbox_list.get_children():
		ch.queue_free()
		
	var farm: Node2D = get_tree().current_scene as Node2D
	var qm: QuestManager = null
	if farm != null and farm.get("quest_manager") != null:
		qm = farm.get("quest_manager") as QuestManager
	if qm == null:
		return
		
	if _active_quest_tab == 0:
		# Banner Lộ Trình Mở Khóa Cấp Độ
		var roadmap_banner: PanelContainer = PanelContainer.new()
		var rm_sb: StyleBoxFlat = StyleBoxFlat.new()
		rm_sb.bg_color = Color(0.99, 0.94, 0.82, 0.98)
		rm_sb.border_color = Color(0.85, 0.65, 0.35, 1.0)
		rm_sb.set_border_width_all(2)
		rm_sb.set_corner_radius_all(10)
		rm_sb.content_margin_left = 12
		rm_sb.content_margin_right = 12
		rm_sb.content_margin_top = 8
		rm_sb.content_margin_bottom = 8
		roadmap_banner.add_theme_stylebox_override("panel", rm_sb)
		var rm_vbox: VBoxContainer = VBoxContainer.new()
		rm_vbox.add_theme_constant_override("separation", 3)
		roadmap_banner.add_child(rm_vbox)
		
		var cur_lvl: int = StorageManager.level
		var next_lvl: int = cur_lvl + 1
		var rm_title: Label = Label.new()
		rm_title.text = "🌟 LỘ TRÌNH MỞ KHÓA: CẤP %d ➔ CẤP %d" % [cur_lvl, next_lvl]
		rm_title.add_theme_font_size_override("font_size", 12)
		rm_title.add_theme_color_override("font_color", Color(0.68, 0.35, 0.05))
		rm_vbox.add_child(rm_title)
		
		var unlock_preview: String = ""
		match cur_lvl:
			1: unlock_preview = " Cây Ngô (Bắp) |  Máy Nghiền Cám |  Thêm Ô Ruộng (+3)"
			2: unlock_preview = "🥕 Cà Rốt | 🥖 Lò Bánh Mì Nóng | 🐄 Chuồng Bò Sữa (+Sữa Tươi)"
			3: unlock_preview = "🌱 Đậu Nành | 🚢 Bến Tàu Hơi Nước | 🎣 Đầm Câu Cá Tự Nhiên"
			4: unlock_preview = "🎋 Mía Đường | 🧃 Quầy Nước Pha Chế | 🐖 Chuồng Heo | 🐝 Cây Tổ Ong"
			5: unlock_preview = "🍓 Dâu Tây | 🎂 Tiệm Bánh Ngọt Kem | 🐑 Chuồng Cừu | 🐶 Nhà Cún Poodle"
			_: unlock_preview = " Khu Bảo Tồn Sở Thú Bờ Đông | 🎈 Bến Khinh Khí Cầu | 🦩 Thú Quý Hiếm"
		var rm_desc: Label = Label.new()
		rm_desc.text = "Mở khóa tiếp theo: " + unlock_preview
		rm_desc.add_theme_font_size_override("font_size", 10)
		rm_desc.add_theme_color_override("font_color", Color(0.35, 0.22, 0.12))
		rm_vbox.add_child(rm_desc)
		vbox_list.add_child(roadmap_banner)
		
		# Tab 1: Story quests grouped by chapter
		var last_chapter: int = -1
		for q in qm.story_quests:
			var chap: int = int(q.get("chapter", 1))
			if chap != last_chapter:
				last_chapter = chap
				var chap_banner: PanelContainer = PanelContainer.new()
				var b_sb: StyleBoxFlat = StyleBoxFlat.new()
				b_sb.bg_color = Color(0.88, 0.78, 0.62, 0.95)
				b_sb.set_corner_radius_all(6)
				b_sb.content_margin_left = 10
				b_sb.content_margin_right = 10
				b_sb.content_margin_top = 4
				b_sb.content_margin_bottom = 4
				chap_banner.add_theme_stylebox_override("panel", b_sb)
				
				var chap_lbl: Label = Label.new()
				chap_lbl.text = String(q.get("chapter_title", "Chương %d" % chap)).to_upper()
				chap_lbl.add_theme_font_size_override("font_size", 11)
				chap_lbl.add_theme_color_override("font_color", Color(0.35, 0.20, 0.08))
				chap_banner.add_child(chap_lbl)
				vbox_list.add_child(chap_banner)
				
			vbox_list.add_child(_build_quest_card(q, false, qm, vbox_list))
			
	elif _active_quest_tab == 1:
		# Tab 2: Daily Quests + Activity Points Bar
		vbox_list.add_child(_build_activity_points_bar(vbox_list))
		
		# 4 Daily Quests
		for q_id in SaveManager.daily_quests_data:
			var matched_q: Dictionary = {}
			for p_q in qm.daily_quest_pool:
				if p_q["id"] == q_id:
					matched_q = p_q
					break
			if not matched_q.is_empty():
				vbox_list.add_child(_build_quest_card(matched_q, true, qm, vbox_list))
				
	elif _active_quest_tab == 2:
		# Tab 3: VIP Requests
		var banner: PanelContainer = PanelContainer.new()
		var b_sb: StyleBoxFlat = StyleBoxFlat.new()
		b_sb.bg_color = Color(0.85, 0.76, 0.62, 0.95)
		b_sb.set_corner_radius_all(6)
		b_sb.content_margin_left = 10
		b_sb.content_margin_right = 10
		b_sb.content_margin_top = 6
		b_sb.content_margin_bottom = 6
		banner.add_theme_stylebox_override("panel", b_sb)
		
		var b_vbox: VBoxContainer = VBoxContainer.new()
		banner.add_child(b_vbox)
		
		var b_title: Label = Label.new()
		b_title.text = "📸 YÊU CẦU ĐẶC BIỆT TỪ DU KHÁCH VIP SỞ THÚ"
		b_title.add_theme_font_size_override("font_size", 11)
		b_title.add_theme_color_override("font_color", Color(0.35, 0.20, 0.08))
		b_vbox.add_child(b_title)
		
		var b_sub: Label = Label.new()
		b_sub.text = "Phục vụ các vị khách VIP để nhận Xu Du Lịch, Vàng, XP và 🧩 Mảnh Ghép Sở Thú!"
		b_sub.add_theme_font_size_override("font_size", 9)
		b_sub.add_theme_color_override("font_color", Color(0.48, 0.35, 0.22))
		b_vbox.add_child(b_sub)
		vbox_list.add_child(banner)
		
		for i in range(SaveManager.vip_requests.size()):
			var req: Dictionary = SaveManager.vip_requests[i] as Dictionary
			vbox_list.add_child(_build_vip_card(req, i, qm, vbox_list))

func _build_activity_points_bar(vbox_list: VBoxContainer) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	var card_sb: StyleBoxFlat = StyleBoxFlat.new()
	card_sb.bg_color = Color(0.95, 0.90, 0.80, 0.95)
	card_sb.border_color = Color(0.75, 0.60, 0.40, 1.0)
	card_sb.set_border_width_all(1)
	card_sb.set_corner_radius_all(8)
	card_sb.content_margin_left = 12
	card_sb.content_margin_right = 12
	card_sb.content_margin_top = 8
	card_sb.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", card_sb)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)
	
	var cur_pts: int = SaveManager.daily_activity_points
	var lbl_pts: Label = Label.new()
	lbl_pts.text = "⚡ ĐIỂM NĂNG ĐỘNG HÔM NAY: %d / 100 ⚡" % cur_pts
	lbl_pts.add_theme_font_size_override("font_size", 12)
	lbl_pts.add_theme_color_override("font_color", Color(0.35, 0.20, 0.08))
	vbox.add_child(lbl_pts)
	
	# Progress Bar
	var pbar: ProgressBar = ProgressBar.new()
	pbar.custom_minimum_size = Vector2(0, 14)
	pbar.min_value = 0
	pbar.max_value = 100
	pbar.value = cur_pts
	pbar.show_percentage = false
	var pbar_bg: StyleBoxFlat = StyleBoxFlat.new()
	pbar_bg.bg_color = Color(0.85, 0.80, 0.72)
	pbar_bg.set_corner_radius_all(4)
	pbar.add_theme_stylebox_override("background", pbar_bg)
	var pbar_fill: StyleBoxFlat = StyleBoxFlat.new()
	pbar_fill.bg_color = Color(0.95, 0.65, 0.15)
	pbar_fill.set_corner_radius_all(4)
	pbar.add_theme_stylebox_override("fill", pbar_fill)
	vbox.add_child(pbar)
	
	# 2 Chest buttons
	var hbox_chests: HBoxContainer = HBoxContainer.new()
	hbox_chests.add_theme_constant_override("separation", 10)
	vbox.add_child(hbox_chests)
	
	# Chest 50
	var btn_c50: Button = Button.new()
	btn_c50.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_c50.custom_minimum_size = Vector2(0, 32)
	if SaveManager.daily_chest_50_claimed:
		btn_c50.text = "Rương 50 Điểm (Đã nhận)"
		btn_c50.disabled = true
	elif cur_pts >= 50:
		btn_c50.text = "Mở Rương 50 Điểm"
		_apply_dialog_action_button(btn_c50, false)
		btn_c50.pressed.connect(func() -> void:
			if SaveManager.claim_daily_chest(50):
				var rews: Array[Dictionary] = [
					{"text": "+1 Mảnh Ghép Sở Thú", "icon": _get_item_or_crop_texture("item_zoo_puzzle_piece")},
					{"text": "+100 Vàng", "icon": _get_item_or_crop_texture("wheat")},
					{"text": "+1 Cỏ Dinh Dưỡng", "icon": _get_item_or_crop_texture("mat_plank")}
				]
				show_chest_reward_modal("RƯƠNG BÁU 50 ĐIỂM", rews)
				_refresh_badges()
				_render_quests_list(vbox_list)
		)
	else:
		btn_c50.text = "Rương 50 Điểm (Cần 50 Điểm)"
		btn_c50.disabled = true
	hbox_chests.add_child(btn_c50)
	
	# Chest 100
	var btn_c100: Button = Button.new()
	btn_c100.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_c100.custom_minimum_size = Vector2(0, 32)
	if SaveManager.daily_chest_100_claimed:
		btn_c100.text = "Rương 100 Điểm (Đã nhận)"
		btn_c100.disabled = true
	elif cur_pts >= 100:
		btn_c100.text = "Mở Rương 100 Điểm"
		_apply_dialog_action_button(btn_c100, false)
		btn_c100.pressed.connect(func() -> void:
			if SaveManager.claim_daily_chest(100):
				var rews: Array[Dictionary] = [
					{"text": "+2 Mảnh Ghép Sở Thú", "icon": _get_item_or_crop_texture("item_zoo_puzzle_piece")},
					{"text": "+3 Kim Cương", "icon": _get_item_or_crop_texture("wheat")},
					{"text": "+2 Cỏ Dinh Dưỡng", "icon": _get_item_or_crop_texture("mat_plank")}
				]
				show_chest_reward_modal("RƯƠNG BÁU 100 ĐIỂM", rews)
				_refresh_badges()
				_render_quests_list(vbox_list)
		)
	else:
		btn_c100.text = "Rương 100 Điểm (Cần 100 Điểm)"
		btn_c100.disabled = true
	hbox_chests.add_child(btn_c100)
	
	return card

func _build_quest_card(q: Dictionary, is_daily: bool, qm: QuestManager, vbox_list: VBoxContainer) -> PanelContainer:
	var q_id: String = q["id"]
	var data: Dictionary = {}
	if is_daily:
		data = SaveManager.daily_quests_data.get(q_id, {}) as Dictionary
	else:
		data = SaveManager.quests_data.get(q_id, {}) as Dictionary
		
	var cur_prog: int = int(data.get("progress", 0))
	var target_prog: int = int(q.get("target", 1))
	var is_claimed: bool = bool(data.get("claimed", false))
	var can_claim: bool = (cur_prog >= target_prog and not is_claimed)
	var nav_pos: Vector2 = q.get("nav_pos", Vector2.ZERO) as Vector2
	var nav_name: String = String(q.get("nav_name", "Khu Vực"))
	
	var card: PanelContainer = PanelContainer.new()
	var card_sb: StyleBoxFlat = StyleBoxFlat.new()
	card_sb.bg_color = Color(1.0, 1.0, 1.0, 0.88)
	card_sb.border_color = Color(0.78, 0.65, 0.48, 1.0)
	card_sb.set_border_width_all(1)
	card_sb.set_corner_radius_all(8)
	card_sb.content_margin_left = 12
	card_sb.content_margin_right = 12
	card_sb.content_margin_top = 8
	card_sb.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", card_sb)
	
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	card.add_child(hbox)
	
	# Left Icon
	var icon_lbl: Label = Label.new()
	icon_lbl.text = "[Hằng Ngày]" if is_daily else "[Mục Tiêu]"
	icon_lbl.add_theme_font_size_override("font_size", 22)
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon_lbl)
	
	# Center Info
	var vbox_info: VBoxContainer = VBoxContainer.new()
	vbox_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_info.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(vbox_info)
	
	var lbl_title: Label = Label.new()
	lbl_title.text = String(q.get("title", ""))
	lbl_title.add_theme_font_size_override("font_size", 12)
	lbl_title.add_theme_color_override("font_color", Color(0.28, 0.16, 0.08))
	vbox_info.add_child(lbl_title)
	
	var lbl_desc: Label = Label.new()
	lbl_desc.text = String(q.get("desc", ""))
	lbl_desc.add_theme_font_size_override("font_size", 10)
	lbl_desc.add_theme_color_override("font_color", Color(0.48, 0.38, 0.30))
	vbox_info.add_child(lbl_desc)
	
	# Progress text & Rewards
	var rew_parts: Array[String] = []
	var g: int = int(q.get("reward_gold", 0))
	var xp: int = int(q.get("reward_xp", 0))
	var coins: int = int(q.get("reward_coins", 0))
	var dia: int = int(q.get("reward_diamonds", 0))
	var pieces: int = int(q.get("reward_pieces", 0))
	if g > 0: rew_parts.append("+%d Vàng" % g)
	if coins > 0: rew_parts.append("+%d Xu" % coins)
	if xp > 0: rew_parts.append("+%d XP" % xp)
	if dia > 0: rew_parts.append("+%d Kim Cương" % dia)
	if pieces > 0: rew_parts.append("+%d Mảnh Ghép" % pieces)
	var mats_rew: Dictionary = q.get("reward_materials", {}) as Dictionary
	for m_id: String in mats_rew:
		var cnt: int = int(mats_rew[m_id])
		if cnt > 0:
			var m_name: String = StorageManager.get_item_display_name(m_id)
			rew_parts.append("+%d %s" % [cnt, m_name])
	if is_daily: rew_parts.append("+25 Điểm")
	
	var lbl_rew: Label = Label.new()
	lbl_rew.text = "Tiến độ: (%d/%d)  |  Thưởng: %s" % [mini(cur_prog, target_prog), target_prog, ", ".join(rew_parts)]
	lbl_rew.add_theme_font_size_override("font_size", 10)
	lbl_rew.add_theme_color_override("font_color", Color(0.18, 0.55, 0.20) if can_claim else Color(0.55, 0.40, 0.20))
	vbox_info.add_child(lbl_rew)
	
	# Right Action Buttons
	var hbox_action: HBoxContainer = HBoxContainer.new()
	hbox_action.add_theme_constant_override("separation", 6)
	hbox.add_child(hbox_action)
	
	if is_claimed:
		var btn_done: Button = Button.new()
		btn_done.custom_minimum_size = Vector2(90, 32)
		btn_done.text = "Đã Nhận"
		btn_done.disabled = true
		hbox_action.add_child(btn_done)
	elif can_claim:
		var btn_claim: Button = Button.new()
		btn_claim.custom_minimum_size = Vector2(100, 32)
		btn_claim.text = "Nhận Thưởng"
		_apply_dialog_action_button(btn_claim, false)
		btn_claim.modulate = Color(1.2, 1.3, 0.8)
		btn_claim.pressed.connect(func() -> void:
			if is_daily:
				qm.claim_daily_quest(q_id)
			else:
				qm.claim_story_quest(q_id)
			show_floating_notice("🎉 Đã nhận thưởng: " + String(q.get("title", "")))
			_refresh_badges()
			_render_quests_list(vbox_list)
		)
		hbox_action.add_child(btn_claim)
	else:
		# Show navigation button "🏃 Thực Hiện" if nav_pos != Vector2.ZERO
		if nav_pos != Vector2.ZERO:
			var btn_nav: Button = Button.new()
			btn_nav.custom_minimum_size = Vector2(95, 32)
			btn_nav.text = "Thực Hiện"
			_apply_dialog_action_button(btn_nav, true)
			btn_nav.tooltip_text = "Di chuyển nhân vật và camera tới %s" % nav_name
			btn_nav.pressed.connect(func() -> void:
				_navigate_to_world_pos(nav_pos, nav_name)
			)
			hbox_action.add_child(btn_nav)
		else:
			var btn_prog: Button = Button.new()
			btn_prog.custom_minimum_size = Vector2(90, 32)
			btn_prog.text = "%d / %d" % [mini(cur_prog, target_prog), target_prog]
			btn_prog.disabled = true
			hbox_action.add_child(btn_prog)
	
	return card

func _build_vip_card(req: Dictionary, index: int, qm: QuestManager, vbox_list: VBoxContainer) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	var card_sb: StyleBoxFlat = StyleBoxFlat.new()
	card_sb.bg_color = Color(1.0, 1.0, 1.0, 0.88)
	card_sb.border_color = Color(0.78, 0.65, 0.48, 1.0)
	card_sb.set_border_width_all(1)
	card_sb.set_corner_radius_all(8)
	card_sb.content_margin_left = 12
	card_sb.content_margin_right = 12
	card_sb.content_margin_top = 8
	card_sb.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", card_sb)
	
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	card.add_child(hbox)
	
	# Left Avatar
	var avatar_lbl: Label = Label.new()
	avatar_lbl.text = String(req.get("avatar", "📸"))
	avatar_lbl.add_theme_font_size_override("font_size", 26)
	avatar_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(avatar_lbl)
	
	# Center Details
	var vbox_info: VBoxContainer = VBoxContainer.new()
	vbox_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_info.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(vbox_info)
	
	var lbl_name: Label = Label.new()
	lbl_name.text = String(req.get("name", "Du Khách VIP"))
	lbl_name.add_theme_font_size_override("font_size", 12)
	lbl_name.add_theme_color_override("font_color", Color(0.28, 0.16, 0.08))
	vbox_info.add_child(lbl_name)
	
	var lbl_dial: Label = Label.new()
	lbl_dial.text = '"' + String(req.get("dialogue", "")) + '"'
	lbl_dial.add_theme_font_size_override("font_size", 10)
	lbl_dial.add_theme_color_override("font_color", Color(0.48, 0.38, 0.30))
	vbox_info.add_child(lbl_dial)
	
	# Needs list
	var needs: Array = req.get("needs", []) as Array
	var needs_strs: Array[String] = []
	var has_all_items: bool = true
	
	for n_item in needs:
		var d_item: Dictionary = n_item as Dictionary
		var i_name: String = String(d_item.get("item", ""))
		var i_req: int = int(d_item.get("count", 1))
		var i_cur: int = StorageManager.get_item_count(i_name)
		var item_display: String = DataManager.get_item_name(i_name)
		if i_cur < i_req:
			has_all_items = false
			needs_strs.append("%s (%d/%d)" % [item_display, i_cur, i_req])
		else:
			needs_strs.append("%s (%d/%d)" % [item_display, i_cur, i_req])
			
	var lbl_needs: Label = Label.new()
	lbl_needs.text = "Cần: " + ", ".join(needs_strs)
	lbl_needs.add_theme_font_size_override("font_size", 10)
	lbl_needs.add_theme_color_override("font_color", Color(0.18, 0.55, 0.20) if has_all_items else Color(0.70, 0.25, 0.15))
	vbox_info.add_child(lbl_needs)
	
	# Rewards
	var rew_parts: Array[String] = []
	var g: int = int(req.get("reward_gold", 0))
	var coins: int = int(req.get("reward_coins", 0))
	var xp: int = int(req.get("reward_xp", 0))
	var pieces: int = int(req.get("reward_pieces", 0))
	if g > 0: rew_parts.append("+%d Vàng" % g)
	if coins > 0: rew_parts.append("+%d Xu" % coins)
	if xp > 0: rew_parts.append("+%d XP" % xp)
	if pieces > 0: rew_parts.append("+%d Mảnh Ghép" % pieces)
	
	var lbl_rew: Label = Label.new()
	lbl_rew.text = "Thưởng: " + ", ".join(rew_parts)
	lbl_rew.add_theme_font_size_override("font_size", 10)
	lbl_rew.add_theme_color_override("font_color", Color(0.55, 0.40, 0.20))
	vbox_info.add_child(lbl_rew)
	
	# Right Button
	var btn_ship: Button = Button.new()
	btn_ship.custom_minimum_size = Vector2(110, 32)
	if has_all_items:
		btn_ship.text = "🤝 Giao Hàng VIP"
		btn_ship.modulate = Color(1.2, 1.3, 0.8)
		btn_ship.pressed.connect(func() -> void:
			if qm.fulfill_vip_request(index):
				show_floating_notice("🎉 Đã giao hàng thành công cho %s!" % String(req.get("name", "VIP")))
				_refresh_badges()
				_render_quests_list(vbox_list)
		)
	else:
		btn_ship.text = "Thiếu Hàng"
		btn_ship.disabled = true
	hbox.add_child(btn_ship)
	
	return card

func _navigate_to_world_pos(dest_pos: Vector2, area_name: String) -> void:
	if _quests_modal != null and is_instance_valid(_quests_modal):
		_quests_modal.queue_free()
		
	var farm: Node2D = get_tree().current_scene as Node2D
	if farm != null:
		var cam: Camera2D = farm.get("camera_2d") as Camera2D
		if cam != null:
			var tw: Tween = create_tween()
			tw.tween_property(cam, "position", dest_pos, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			
		var avatar: Node2D = farm.get("player_avatar") as Node2D
		var grid: Node2D = farm.get("walk_grid") as Node2D
		if avatar != null and grid != null and grid.has_method("find_path"):
			var path: Array[Vector2] = grid.call("find_path", avatar.global_position, dest_pos) as Array[Vector2]
			if avatar.has_method("go_to"):
				avatar.call("go_to", path, null)
				
		show_floating_notice("🏃 Đang di chuyển tới %s..." % area_name)

func open_zoo_modal() -> void:
	AudioManager.play_sfx("click")
	if StorageManager.level < 11:
		show_floating_notice("[Khóa]  Sở Thú Bờ Đông sẽ mở khóa ở Cấp 11! (Hiện tại: Cấp %d)" % StorageManager.level)
		return
	if _zoo_modal != null and is_instance_valid(_zoo_modal):
		_zoo_modal.queue_free()
		return
	
	cancel_all_active_tools()
	
	_zoo_modal = PanelContainer.new()
	_zoo_modal.name = "ZooModal"
	_zoo_modal.custom_minimum_size = Vector2(550, 460)
	_zoo_modal.anchors_preset = Control.PRESET_CENTER
	_zoo_modal.anchor_left = 0.5
	_zoo_modal.anchor_top = 0.5
	_zoo_modal.anchor_right = 0.5
	_zoo_modal.anchor_bottom = 0.5
	_zoo_modal.offset_left = -275.0
	_zoo_modal.offset_top = -230.0
	_zoo_modal.offset_right = 275.0
	_zoo_modal.offset_bottom = 230.0
	_zoo_modal.z_index = 85
	
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.98, 0.95, 0.88, 0.98)
	sb.border_color = Color(0.55, 0.35, 0.18, 1.0)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	sb.shadow_color = Color(0.2, 0.1, 0.05, 0.35)
	sb.shadow_size = 8
	_zoo_modal.add_theme_stylebox_override("panel", sb)
	
	var vbox_main: VBoxContainer = VBoxContainer.new()
	vbox_main.add_theme_constant_override("separation", 10)
	_zoo_modal.add_child(vbox_main)
	
	# Header
	var hbox_head: HBoxContainer = HBoxContainer.new()
	vbox_main.add_child(hbox_head)
	
	var lbl_title: Label = Label.new()
	lbl_title.text = " SỔ TAY BẢO TỒN SỞ THÚ (BỜ ĐÔNG SÔNG)"
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_title.add_theme_font_size_override("font_size", 14)
	lbl_title.add_theme_color_override("font_color", Color(0.35, 0.20, 0.10))
	lbl_title.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0))
	lbl_title.add_theme_constant_override("outline_size", 2)
	hbox_head.add_child(lbl_title)
	
	var btn_close: Button = Button.new()
	_apply_dialog_close_button(btn_close)
	btn_close.pressed.connect(func() -> void:
		_zoo_modal.queue_free()
	)
	hbox_head.add_child(btn_close)
	
	# Stats summary banner
	var farm: Node2D = get_tree().current_scene as Node2D
	var zoo_mgr: ZooManager = null
	if farm != null and farm.get("zoo_manager") != null:
		zoo_mgr = farm.get("zoo_manager") as ZooManager
	var total_attr: int = zoo_mgr.get_total_attraction_score() if zoo_mgr != null else 30
	
	var hbox_stats: HBoxContainer = HBoxContainer.new()
	hbox_stats.add_theme_constant_override("separation", 14)
	vbox_main.add_child(hbox_stats)
	
	var lbl_puzzle: Label = Label.new()
	lbl_puzzle.text = "🧩 Mảnh Ghép Sở Thú: %d" % SaveManager.puzzle_pieces
	lbl_puzzle.add_theme_font_size_override("font_size", 12)
	lbl_puzzle.add_theme_color_override("font_color", Color(0.20, 0.45, 0.70))
	hbox_stats.add_child(lbl_puzzle)
	
	var lbl_attr: Label = Label.new()
	lbl_attr.text = " Điểm Hấp Dẫn Sở Thú: +%d" % total_attr
	lbl_attr.add_theme_font_size_override("font_size", 12)
	lbl_attr.add_theme_color_override("font_color", Color(0.85, 0.40, 0.10))
	hbox_stats.add_child(lbl_attr)
	
	# Scroll animal cards
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox_main.add_child(scroll)
	
	var vbox_cards: VBoxContainer = VBoxContainer.new()
	vbox_cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_cards.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox_cards)
	
	_render_zoo_cards(vbox_cards, lbl_puzzle, lbl_attr)
	add_child(_zoo_modal)

func _render_zoo_cards(vbox_cards: VBoxContainer, lbl_puzzle: Label, lbl_attr: Label) -> void:
	for ch in vbox_cards.get_children():
		ch.queue_free()
		
	var farm: Node2D = get_tree().current_scene as Node2D
	var zoo_mgr: ZooManager = null
	if farm != null and farm.get("zoo_manager") != null:
		zoo_mgr = farm.get("zoo_manager") as ZooManager
		
	var zoo_list: Array[Dictionary] = []
	for enc_cfg: Dictionary in DataManager.get_zoo_enclosures():
		var raw_pieces: Variant = enc_cfg.get("puzzle_piece_cost", null)
		if raw_pieces == null:
			continue
		var food_keys: Array[String] = []
		var food_names: Array[String] = []
		var foods_var: Variant = enc_cfg.get("foods", [])
		if foods_var is Array:
			for f_item: Variant in (foods_var as Array):
				var f_id: String = String(f_item)
				food_keys.append(f_id)
				food_names.append(DataManager.get_item_display_name(f_id))
		var raw_gold: Variant = enc_cfg.get("cost_gold", 0)
		zoo_list.append({
			"id": String(enc_cfg.get("id", "")),
			"name": String(enc_cfg.get("animal_name", enc_cfg.get("name", ""))),
			"title": String(enc_cfg.get("name", "")),
			"foods": " / ".join(food_names),
			"food_keys": food_keys,
			"pieces": int(raw_pieces),
			"gold": int(raw_gold) if raw_gold != null else 0,
			"attr": int(enc_cfg.get("attraction_score", 30))
		})
	
	for z in zoo_list:
		vbox_cards.add_child(_build_zoo_card(z, zoo_mgr, vbox_cards, lbl_puzzle, lbl_attr))

func _build_zoo_card(z: Dictionary, zoo_mgr: ZooManager, vbox_cards: VBoxContainer, lbl_puzzle: Label, lbl_attr: Label) -> PanelContainer:
	var a_id: String = z["id"]
	var is_unlocked: bool = SaveManager.is_animal_unlocked(a_id)
	var is_fed: bool = SaveManager.is_animal_fed(a_id)
	
	var card: PanelContainer = PanelContainer.new()
	var card_sb: StyleBoxFlat = StyleBoxFlat.new()
	card_sb.bg_color = Color(1.0, 1.0, 1.0, 0.88)
	card_sb.border_color = Color(0.78, 0.65, 0.48, 1.0)
	card_sb.set_border_width_all(1)
	card_sb.set_corner_radius_all(8)
	card_sb.content_margin_left = 12
	card_sb.content_margin_right = 12
	card_sb.content_margin_top = 8
	card_sb.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", card_sb)
	
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	card.add_child(hbox)
	
	# Left Animal Sprite
	var icon_rect: TextureRect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(48, 48)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if SpriteAtlasManager.has_texture(a_id):
		icon_rect.texture = SpriteAtlasManager.get_texture(a_id)
	hbox.add_child(icon_rect)
	
	# Center Details
	var vbox_info: VBoxContainer = VBoxContainer.new()
	vbox_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_info.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(vbox_info)
	
	var lbl_name: Label = Label.new()
	lbl_name.text = "%s - %s" % [z["title"], z["name"]]
	lbl_name.add_theme_font_size_override("font_size", 12)
	lbl_name.add_theme_color_override("font_color", Color(0.28, 0.16, 0.08))
	vbox_info.add_child(lbl_name)
	
	var lbl_fav: Label = Label.new()
	lbl_fav.text = "Thích: " + String(z["foods"])
	lbl_fav.add_theme_font_size_override("font_size", 10)
	lbl_fav.add_theme_color_override("font_color", Color(0.50, 0.38, 0.28))
	vbox_info.add_child(lbl_fav)
	
	var lbl_status: Label = Label.new()
	lbl_status.add_theme_font_size_override("font_size", 10)
	if not is_unlocked:
		lbl_status.text = "[Khóa]  Chưa Mở Khóa  |  Chi phí: %d 🧩 Mảnh Ghép hoặc %d 👑 Vàng" % [z["pieces"], z["gold"]]
		lbl_status.add_theme_color_override("font_color", Color(0.70, 0.35, 0.15))
	elif is_fed:
		lbl_status.text = "🟢 Đang No Bụng  |  +x2 Điểm Hấp Dẫn (+%d )" % (int(z["attr"]) * 2)
		lbl_status.add_theme_color_override("font_color", Color(0.18, 0.60, 0.20))
	else:
		lbl_status.text = "🟡 Đang Đói Bụng  |  Điểm Hấp Dẫn: +%d " % int(z["attr"])
		lbl_status.add_theme_color_override("font_color", Color(0.80, 0.50, 0.10))
	vbox_info.add_child(lbl_status)
	
	# Right Action Buttons
	var hbox_btns: HBoxContainer = HBoxContainer.new()
	hbox_btns.add_theme_constant_override("separation", 6)
	hbox.add_child(hbox_btns)
	
	if not is_unlocked:
		var p_cost: int = int(z["pieces"])
		var g_cost: int = int(z["gold"])
		
		var btn_unlock_p: Button = Button.new()
		btn_unlock_p.text = "%d 🧩" % p_cost
		btn_unlock_p.tooltip_text = "Mở khóa bằng Mảnh Ghép"
		btn_unlock_p.disabled = (SaveManager.puzzle_pieces < p_cost)
		btn_unlock_p.pressed.connect(func() -> void:
			if SaveManager.spend_puzzle_pieces(p_cost):
				SaveManager.unlock_animal(a_id)
				AudioManager.play_sfx("level_up")
				show_floating_notice("🎉 Đã mở khóa %s!" % z["title"])
				lbl_puzzle.text = "🧩 Mảnh Ghép Sở Thú: %d" % SaveManager.puzzle_pieces
				if zoo_mgr != null: lbl_attr.text = " Điểm Hấp Dẫn Sở Thú: +%d" % zoo_mgr.get_total_attraction_score()
				_refresh_badges()
				_render_zoo_cards(vbox_cards, lbl_puzzle, lbl_attr)
		)
		hbox_btns.add_child(btn_unlock_p)
		
		var btn_unlock_g: Button = Button.new()
		btn_unlock_g.text = "%d 👑" % g_cost
		btn_unlock_g.tooltip_text = "Mở khóa bằng Vàng"
		btn_unlock_g.disabled = not StorageManager.has_gold(g_cost)
		btn_unlock_g.pressed.connect(func() -> void:
			if StorageManager.spend_gold(g_cost):
				EventBus.gold_changed.emit(StorageManager.gold, -g_cost)
				SaveManager.unlock_animal(a_id)
				AudioManager.play_sfx("level_up")
				show_floating_notice("🎉 Đã mở khóa %s!" % z["title"])
				if zoo_mgr != null: lbl_attr.text = " Điểm Hấp Dẫn Sở Thú: +%d" % zoo_mgr.get_total_attraction_score()
				_refresh_badges()
				_render_zoo_cards(vbox_cards, lbl_puzzle, lbl_attr)
		)
		hbox_btns.add_child(btn_unlock_g)
	else:
		# Button: Walk avatar to enclosure
		var btn_walk: Button = Button.new()
		btn_walk.text = "🏃 Tới Chuồng"
		btn_walk.tooltip_text = "Nhân vật tự đi bộ qua cầu gỗ sang chuồng này"
		btn_walk.pressed.connect(func() -> void:
			if _zoo_modal != null and is_instance_valid(_zoo_modal):
				_zoo_modal.queue_free()
			var farm: Node2D = get_tree().current_scene as Node2D
			if farm != null:
				var zm: ZooManager = farm.get("zoo_manager") as ZooManager
				var enc: ZooEnclosure = zm.get_enclosure(a_id) if zm != null else null
				if enc != null:
					var dest_pos: Vector2 = enc.global_position + Vector2(0.0, 35.0)
					var avatar: Node2D = farm.get("player_avatar") as Node2D
					var grid: Node2D = farm.get("walk_grid") as Node2D
					if avatar != null and grid != null and grid.has_method("find_path"):
						var path: Array[Vector2] = grid.call("find_path", avatar.global_position, dest_pos) as Array[Vector2]
						if avatar.has_method("go_to"):
							avatar.call("go_to", path, enc)
					var cam: Camera2D = farm.get("camera_2d") as Camera2D
					if cam != null:
						var tw: Tween = create_tween()
						tw.tween_property(cam, "position", dest_pos, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
					show_floating_notice("🚶 Đang đi bộ tới %s..." % z["title"])
		)
		hbox_btns.add_child(btn_walk)
		
		# Button: Feed animal directly
		var btn_feed: Button = Button.new()
		if is_fed:
			btn_feed.text = "❤️ Đã No"
			btn_feed.disabled = true
		else:
			btn_feed.text = "🍎 Cho Ăn"
			btn_feed.modulate = Color(1.15, 1.25, 0.8)
			btn_feed.pressed.connect(func() -> void:
				var food_candidates: Array = z["food_keys"]
				var chosen_food: String = ""
				for f_key in food_candidates:
					if StorageManager.get_item_count(String(f_key)) > 0:
						chosen_food = String(f_key)
						break
				if chosen_food != "":
					StorageManager.remove_item(chosen_food, 1)
					SaveManager.feed_animal(a_id, 300)
					StorageManager.add_xp(60)
					StorageManager.add_gold(80)
					StorageManager.coins += 25
					EventBus.coins_changed.emit(StorageManager.coins, 25)
					EventBus.zoo_animal_fed.emit(a_id)
					AudioManager.play_sfx("sell")
					show_floating_notice("❤️ Cho %s ăn thành công! +60 XP, +80 Vàng, +25 Xu Du Lịch!" % z["name"])
					if zoo_mgr != null: lbl_attr.text = " Điểm Hấp Dẫn Sở Thú: +%d" % zoo_mgr.get_total_attraction_score()
					_refresh_badges()
					_render_zoo_cards(vbox_cards, lbl_puzzle, lbl_attr)
				else:
					show_floating_notice("⚠️ Kho không có thức ăn phù hợp (%s)!" % z["foods"])
			)
		hbox_btns.add_child(btn_feed)
		
	return card

func open_zoo_feed_shop_modal() -> void:
	AudioManager.play_sfx("click")
	if _zoo_feed_shop_modal != null and is_instance_valid(_zoo_feed_shop_modal):
		_zoo_feed_shop_modal.queue_free()
		return
	
	cancel_all_active_tools()
	
	_zoo_feed_shop_modal = PanelContainer.new()
	_zoo_feed_shop_modal.name = "ZooFeedShopModal"
	_zoo_feed_shop_modal.custom_minimum_size = Vector2(530, 420)
	_zoo_feed_shop_modal.anchors_preset = Control.PRESET_CENTER
	_zoo_feed_shop_modal.anchor_left = 0.5
	_zoo_feed_shop_modal.anchor_top = 0.5
	_zoo_feed_shop_modal.anchor_right = 0.5
	_zoo_feed_shop_modal.anchor_bottom = 0.5
	_zoo_feed_shop_modal.offset_left = -265.0
	_zoo_feed_shop_modal.offset_top = -210.0
	_zoo_feed_shop_modal.offset_right = 265.0
	_zoo_feed_shop_modal.offset_bottom = 210.0
	_zoo_feed_shop_modal.z_index = 90
	
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.98, 0.95, 0.88, 0.98)
	sb.border_color = Color(0.55, 0.35, 0.18, 1.0)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	sb.shadow_color = Color(0.2, 0.1, 0.05, 0.35)
	sb.shadow_size = 8
	_zoo_feed_shop_modal.add_theme_stylebox_override("panel", sb)
	
	var vbox_main: VBoxContainer = VBoxContainer.new()
	vbox_main.add_theme_constant_override("separation", 10)
	_zoo_feed_shop_modal.add_child(vbox_main)
	
	# Header
	var hbox_head: HBoxContainer = HBoxContainer.new()
	vbox_main.add_child(hbox_head)
	
	var lbl_title: Label = Label.new()
	lbl_title.text = "🏪 QUẦY PHỤC VỤ & LƯU NIỆM SỞ THÚ"
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_title.add_theme_font_size_override("font_size", 13)
	lbl_title.add_theme_color_override("font_color", Color(0.35, 0.20, 0.10))
	lbl_title.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0))
	lbl_title.add_theme_constant_override("outline_size", 2)
	hbox_head.add_child(lbl_title)
	
	var btn_close: Button = Button.new()
	_apply_dialog_close_button(btn_close)
	btn_close.pressed.connect(func() -> void:
		AudioManager.play_sfx("click")
		_zoo_feed_shop_modal.queue_free()
	)
	hbox_head.add_child(btn_close)
	
	var lbl_sub: Label = Label.new()
	lbl_sub.text = "Chào mừng bạn đến Quầy Phục Vụ Sở Thú! Hãy chọn dịch vụ bên dưới:"
	lbl_sub.add_theme_font_size_override("font_size", 10)
	lbl_sub.add_theme_color_override("font_color", Color(0.45, 0.30, 0.18))
	vbox_main.add_child(lbl_sub)
	
	var vbox_options: VBoxContainer = VBoxContainer.new()
	vbox_options.name = "OptionsContainer"
	vbox_options.add_theme_constant_override("separation", 8)
	vbox_main.add_child(vbox_options)
	
	_render_feed_shop_options(vbox_options)
	add_child(_zoo_feed_shop_modal)

func _render_feed_shop_options(container: VBoxContainer) -> void:
	for child in container.get_children():
		child.queue_free()
		
	# Card 1: Chế Biến Nhanh Bó Cỏ Dinh Dưỡng
	var card1: PanelContainer = _create_feed_shop_card(
		"🥗 Chế Biến Bó Cỏ Dinh Dưỡng",
		"Đổi 2 Lúa mì + 1 Cà rốt (hoặc 120 Vàng) nhận ngay +2 Bó Cỏ Dinh Dưỡng vào kho Barn.",
		"Lúa mì: %d/2 | Cà rốt: %d/1 | Kho Cỏ: %d" % [StorageManager.get_item_count("wheat"), StorageManager.get_item_count("carrot"), StorageManager.get_item_count("sanctuary_feed")],
		"🥗 Chế Biến (+2 Cỏ)",
		func() -> void:
			var w_cnt: int = StorageManager.get_item_count("wheat")
			var c_cnt: int = StorageManager.get_item_count("carrot")
			if w_cnt >= 2 and c_cnt >= 1:
				StorageManager.remove_item("wheat", 2)
				StorageManager.remove_item("carrot", 1)
				StorageManager.add_item("sanctuary_feed", 2)
				AudioManager.play_sfx("harvest")
				show_floating_notice("🥗 Chế biến thành công +2 Bó Cỏ Dinh Dưỡng từ 2 Lúa mì + 1 Cà rốt!")
			elif StorageManager.has_gold(120):
				StorageManager.spend_gold(120)
				EventBus.gold_changed.emit(StorageManager.gold, -120)
				StorageManager.add_item("sanctuary_feed", 2)
				AudioManager.play_sfx("sell")
				show_floating_notice("🥗 Mua nhanh +2 Bó Cỏ Dinh Dưỡng (-120 Vàng)!")
			else:
				AudioManager.play_sfx("error")
				show_floating_notice("⚠️ Cần 2 Lúa mì + 1 Cà rốt (hoặc 120 Vàng)!")
				return
			_refresh_all_hud()
			_render_feed_shop_options(container)
	)
	container.add_child(card1)
	
	# Card 2: Làm Quà Lưu Niệm Sở Thú
	var crops_available: int = 0
	var crop_candidates: Array[String] = ["wheat", "corn", "carrot", "tomato", "strawberry", "pumpkin", "soybean", "sugarcane", "apple", "mango", "sunflower", "rose", "lavender"]
	for cr in crop_candidates:
		crops_available += StorageManager.get_item_count(cr)
		
	var card2: PanelContainer = _create_feed_shop_card(
		"🧸 Làm Quà Lưu Niệm Sở Thú",
		"Đổi 2 Nông sản/Hoa bất kỳ nhận ngay +120 Xu Du Lịch & +50 XP (tính tiến độ nhiệm vụ).",
		"Nông sản trong kho Silo: %d cái (Cần 2 cái)" % crops_available,
		"🧸 Làm Quà (+120 Xu)",
		func() -> void:
			var collected: Array[String] = []
			for item_id: String in crop_candidates:
				var count: int = StorageManager.get_item_count(item_id)
				while count > 0 and collected.size() < 2:
					collected.append(item_id)
					count -= 1
				if collected.size() >= 2:
					break
			if collected.size() >= 2:
				for item_id in collected:
					StorageManager.remove_item(item_id, 1)
				StorageManager.coins += 120
				EventBus.coins_changed.emit(StorageManager.coins, 120)
				StorageManager.add_xp(50)
				EventBus.roadside_shop_item_sold.emit(0, "souvenir", 1, 120)
				var farm_scene: Node = get_tree().current_scene
				if farm_scene != null:
					var qm: Node = farm_scene.find_child("QuestManager", true, false)
					if qm != null and qm.has_method("notify_delivery_or_shop"):
						qm.call("notify_delivery_or_shop")
				AudioManager.play_sfx("sell")
				show_floating_notice("🧸 Chế tác Quà Lưu Niệm thành công! +120 Xu Du Lịch & +50 XP!")
			else:
				AudioManager.play_sfx("error")
				show_floating_notice("⚠️ Cần ít nhất 2 nông sản hoặc hoa trong kho Silo!")
				return
			_refresh_all_hud()
			_render_feed_shop_options(container)
	)
	container.add_child(card2)
	
	# Card 3: Phát Vé Mời Du Khách (100 Vàng)
	var card3: PanelContainer = _create_feed_shop_card(
		"🎫 Phát Vé Mời Du Khách (100 Vàng)",
		"Mời ngay 2 Du Khách mới đi qua cầu gỗ sang ngắm thú & chụp ảnh tại Sở Thú bờ Đông.",
		"Vàng hiện có: %d Vàng (Chi phí: 100 Vàng)" % StorageManager.gold,
		"🎫 Phát Vé (100 Vàng)",
		func() -> void:
			if StorageManager.has_gold(100):
				StorageManager.spend_gold(100)
				EventBus.gold_changed.emit(StorageManager.gold, -100)
				var farm_node: Node = get_tree().current_scene
				var vm: VisitorManager = farm_node.find_child("VisitorManager", true, false) as VisitorManager if farm_node != null else null
				var count_spawned: int = 0
				if vm != null:
					count_spawned = vm.summon_zoo_visitors(2)
				AudioManager.play_sfx("click")
				show_floating_notice("🎫 Đã phát vé mời! 2 Du Khách mới đang qua cầu sang thăm Sở Thú!")
			else:
				AudioManager.play_sfx("error")
				show_floating_notice("⚠️ Cần 100 Vàng để phát vé mời Du Khách!")
				return
			_refresh_all_hud()
			_render_feed_shop_options(container)
	)
	container.add_child(card3)

func _create_feed_shop_card(title: String, desc: String, status_text: String, btn_text: String, on_action: Callable) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	var csb: StyleBoxFlat = StyleBoxFlat.new()
	csb.bg_color = Color(1.0, 0.98, 0.93, 0.95)
	csb.border_color = Color(0.75, 0.55, 0.35, 0.8)
	csb.set_border_width_all(2)
	csb.set_corner_radius_all(10)
	csb.content_margin_left = 12
	csb.content_margin_right = 12
	csb.content_margin_top = 8
	csb.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", csb)
	
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	card.add_child(hbox)
	
	var vbox_text: VBoxContainer = VBoxContainer.new()
	vbox_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_text.add_theme_constant_override("separation", 3)
	hbox.add_child(vbox_text)
	
	var lbl_t: Label = Label.new()
	lbl_t.text = title
	lbl_t.add_theme_font_size_override("font_size", 12)
	lbl_t.add_theme_color_override("font_color", Color(0.35, 0.18, 0.08))
	vbox_text.add_child(lbl_t)
	
	var lbl_d: Label = Label.new()
	lbl_d.text = desc
	lbl_d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_d.add_theme_font_size_override("font_size", 10)
	lbl_d.add_theme_color_override("font_color", Color(0.48, 0.32, 0.18))
	vbox_text.add_child(lbl_d)
	
	var lbl_s: Label = Label.new()
	lbl_s.text = status_text
	lbl_s.add_theme_font_size_override("font_size", 9)
	lbl_s.add_theme_color_override("font_color", Color(0.2, 0.45, 0.15))
	vbox_text.add_child(lbl_s)
	
	var btn_action: Button = Button.new()
	btn_action.text = btn_text
	btn_action.custom_minimum_size = Vector2(165, 38)
	btn_action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn_action.add_theme_font_size_override("font_size", 14)
	btn_action.pressed.connect(on_action)
	_apply_dialog_action_button(btn_action, false)
	hbox.add_child(btn_action)
	
	return card

func _apply_dialog_close_button(btn: Button) -> void:
	if btn == null:
		return
	btn.text = "X"
	btn.custom_minimum_size = Vector2(32, 32)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.9))
	btn.add_theme_font_size_override("font_size", 16)
	
	var sb_norm: StyleBoxFlat = StyleBoxFlat.new()
	sb_norm.bg_color = Color(0.91, 0.30, 0.24) # #E74C3C 3D Red-Orange
	sb_norm.border_color = Color(0.75, 0.20, 0.15) # #C0392B
	sb_norm.set_border_width_all(2)
	sb_norm.set_corner_radius_all(8)
	sb_norm.shadow_color = Color(0.2, 0.05, 0.05, 0.3)
	sb_norm.shadow_size = 2
	
	var sb_hov: StyleBoxFlat = StyleBoxFlat.new()
	sb_hov.bg_color = Color(0.95, 0.38, 0.32)
	sb_hov.border_color = Color(0.85, 0.25, 0.20)
	sb_hov.set_border_width_all(2)
	sb_hov.set_corner_radius_all(8)
	sb_hov.shadow_color = Color(0.2, 0.05, 0.05, 0.4)
	sb_hov.shadow_size = 3
	
	var sb_press: StyleBoxFlat = StyleBoxFlat.new()
	sb_press.bg_color = Color(0.80, 0.22, 0.16)
	sb_press.border_color = Color(0.65, 0.18, 0.12)
	sb_press.set_border_width_all(2)
	sb_press.set_corner_radius_all(8)
	
	btn.add_theme_stylebox_override("normal", sb_norm)
	btn.add_theme_stylebox_override("hover", sb_hov)
	btn.add_theme_stylebox_override("pressed", sb_press)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_outline_color", Color(0.35, 0.1, 0.08))
	btn.add_theme_constant_override("outline_size", 1)
	btn.add_theme_font_size_override("font_size", 13)

func _apply_dialog_action_button(btn: Button, is_secondary: bool = false) -> void:
	if btn == null:
		return
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var sb_norm: StyleBoxFlat = StyleBoxFlat.new()
	var sb_hov: StyleBoxFlat = StyleBoxFlat.new()
	var sb_press: StyleBoxFlat = StyleBoxFlat.new()
	
	if not is_secondary:
		# Vibrant 3D Green (#2ECC71, viền #1E8449)
		sb_norm.bg_color = Color(0.18, 0.80, 0.44)
		sb_norm.border_color = Color(0.12, 0.52, 0.29)
		sb_norm.set_border_width_all(2)
		sb_norm.set_corner_radius_all(8)
		sb_norm.shadow_color = Color(0.06, 0.28, 0.15, 0.35)
		sb_norm.shadow_size = 2
		
		sb_hov.bg_color = Color(0.24, 0.88, 0.50)
		sb_hov.border_color = Color(0.15, 0.60, 0.33)
		sb_hov.set_border_width_all(2)
		sb_hov.set_corner_radius_all(8)
		sb_hov.shadow_color = Color(0.06, 0.28, 0.15, 0.45)
		sb_hov.shadow_size = 3
		
		sb_press.bg_color = Color(0.14, 0.68, 0.36)
		sb_press.border_color = Color(0.10, 0.45, 0.24)
		sb_press.set_border_width_all(2)
		sb_press.set_corner_radius_all(8)
		
		btn.add_theme_color_override("font_outline_color", Color(0.08, 0.35, 0.20)) # #145A32
	else:
		# Vibrant 3D Warm Wood / Orange Gold (#E67E22)
		sb_norm.bg_color = Color(0.92, 0.55, 0.18)
		sb_norm.border_color = Color(0.70, 0.38, 0.10)
		sb_norm.set_border_width_all(2)
		sb_norm.set_corner_radius_all(8)
		sb_norm.shadow_color = Color(0.35, 0.18, 0.05, 0.35)
		sb_norm.shadow_size = 2
		
		sb_hov.bg_color = Color(0.98, 0.63, 0.25)
		sb_hov.border_color = Color(0.78, 0.45, 0.14)
		sb_hov.set_border_width_all(2)
		sb_hov.set_corner_radius_all(8)
		sb_hov.shadow_color = Color(0.35, 0.18, 0.05, 0.45)
		sb_hov.shadow_size = 3
		
		sb_press.bg_color = Color(0.82, 0.48, 0.15)
		sb_press.border_color = Color(0.60, 0.32, 0.08)
		sb_press.set_border_width_all(2)
		sb_press.set_corner_radius_all(8)
		
		btn.add_theme_color_override("font_outline_color", Color(0.38, 0.18, 0.06))
	
	btn.add_theme_stylebox_override("normal", sb_norm)
	btn.add_theme_stylebox_override("hover", sb_hov)
	btn.add_theme_stylebox_override("pressed", sb_press)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_constant_override("outline_size", 1)
	btn.add_theme_font_size_override("font_size", 14)

func open_hot_air_balloon_modal() -> void:
	if _hot_air_balloon_modal != null and is_instance_valid(_hot_air_balloon_modal):
		_hot_air_balloon_modal.queue_free()
	
	_hot_air_balloon_modal = PanelContainer.new()
	_hot_air_balloon_modal.name = "HotAirBalloonModal"
	_hot_air_balloon_modal.custom_minimum_size = Vector2(460, 340)
	_hot_air_balloon_modal.anchors_preset = Control.PRESET_CENTER
	_hot_air_balloon_modal.anchor_left = 0.5
	_hot_air_balloon_modal.anchor_top = 0.5
	_hot_air_balloon_modal.anchor_right = 0.5
	_hot_air_balloon_modal.anchor_bottom = 0.5
	_hot_air_balloon_modal.offset_left = -230
	_hot_air_balloon_modal.offset_top = -170
	_hot_air_balloon_modal.offset_right = 230
	_hot_air_balloon_modal.offset_bottom = 170
	_hot_air_balloon_modal.z_index = 100
	
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 0.98, 0.93, 0.98)
	sb.border_color = Color(0.72, 0.45, 0.18, 1.0)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.shadow_color = Color(0.18, 0.10, 0.04, 0.45)
	sb.shadow_size = 10
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	_hot_air_balloon_modal.add_theme_stylebox_override("panel", sb)
	
	var vbox_main: VBoxContainer = VBoxContainer.new()
	vbox_main.add_theme_constant_override("separation", 10)
	_hot_air_balloon_modal.add_child(vbox_main)
	
	# Header
	var hbox_head: HBoxContainer = HBoxContainer.new()
	vbox_main.add_child(hbox_head)
	
	var lbl_title: Label = Label.new()
	lbl_title.text = "🎈 KHINH KHÍ CẦU NGẮM CẢNH SỞ THÚ"
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_title.add_theme_font_size_override("font_size", 13)
	lbl_title.add_theme_color_override("font_color", Color(0.35, 0.20, 0.10))
	lbl_title.add_theme_color_override("font_outline_color", Color.WHITE)
	lbl_title.add_theme_constant_override("outline_size", 2)
	hbox_head.add_child(lbl_title)
	
	var btn_close: Button = Button.new()
	_apply_dialog_close_button(btn_close)
	btn_close.pressed.connect(func() -> void:
		AudioManager.play_sfx("click")
		_hot_air_balloon_modal.queue_free()
	)
	hbox_head.add_child(btn_close)
	
	var lbl_sub: Label = Label.new()
	lbl_sub.text = "Thưởng ngoạn toàn cảnh Sở Thú từ trên mây & tăng tiền Tip du khách (Hiện tại: Lv.%d/5 - Tip +%d%%)" % [SaveManager.balloon_level, SaveManager.balloon_level * 10]
	lbl_sub.add_theme_font_size_override("font_size", 10)
	lbl_sub.add_theme_color_override("font_color", Color(0.48, 0.32, 0.18))
	vbox_main.add_child(lbl_sub)
	
	var vbox_cards: VBoxContainer = VBoxContainer.new()
	vbox_cards.add_theme_constant_override("separation", 8)
	vbox_main.add_child(vbox_cards)
	
	# Card 1: Khởi hành bay ngắm cảnh (120 Vàng)
	var card1: PanelContainer = _create_feed_shop_card(
		"🚀 Khởi Hành Bay Ngắm Cảnh (120 Vàng)",
		"Khinh khí cầu bay lượn trên bầu trời 2.5s, nhận ngay +150 Xu Du Lịch, +80 XP và +1 Mảnh Ghép 🧩!",
		"Chi phí: 120 Vàng (Bạn có: %d Vàng)" % StorageManager.gold,
		"🚀 Bay Ngắm Cảnh",
		func() -> void:
			if StorageManager.has_gold(120):
				StorageManager.spend_gold(120)
				EventBus.gold_changed.emit(StorageManager.gold, -120)
				AudioManager.play_sfx("click")
				_hot_air_balloon_modal.queue_free()
				
				var farm: Node = get_tree().current_scene
				var zm: ZooManager = farm.find_child("ZooManager", true, false) as ZooManager if farm != null else null
				if zm != null:
					zm.fly_balloon_tour(func() -> void:
						StorageManager.coins += 150
						EventBus.coins_changed.emit(StorageManager.coins, 150)
						StorageManager.add_xp(80)
						SaveManager.add_puzzle_pieces(1)
						AudioManager.play_sfx("fanfare")
						show_floating_notice("🎉 Chuyến bay ngắm cảnh thành công! +150 Xu Du Lịch, +80 XP & +1 Mảnh Ghép 🧩!")
						EventBus.loot_collected.emit("coins", 150, Vector2(1475.0, 310.0))
						EventBus.loot_collected.emit("puzzle_piece", 1, Vector2(1475.0, 310.0))
						_refresh_all_hud()
					)
				else:
					StorageManager.coins += 150
					EventBus.coins_changed.emit(StorageManager.coins, 150)
					StorageManager.add_xp(80)
					SaveManager.add_puzzle_pieces(1)
					show_floating_notice("🎉 +150 Xu Du Lịch, +80 XP & +1 Mảnh Ghép 🧩!")
					_refresh_all_hud()
			else:
				AudioManager.play_sfx("error")
				show_floating_notice("⚠️ Bạn cần 120 Vàng để khởi hành chuyến bay!")
	)
	vbox_cards.add_child(card1)
	
	# Card 2: Nâng cấp Khinh Khí Cầu
	var cur_lvl: int = SaveManager.balloon_level
	if cur_lvl < 5:
		var cost: int = cur_lvl * 150 + 100
		var card2: PanelContainer = _create_feed_shop_card(
			"⬆️ Nâng Cấp Khinh Khí Cầu (Lv.%d -> Lv.%d)" % [cur_lvl, cur_lvl + 1],
			"Tăng vĩnh viễn +10% tiền Tip Xu Du Lịch mỗi cấp khi du khách chụp ảnh & +10 Điểm Năng Động.",
			"Chi phí: %d Vàng (Bạn có: %d Vàng)" % [cost, StorageManager.gold],
			"⬆️ Nâng Cấp (Lv.%d)" % (cur_lvl + 1),
			func() -> void:
				if StorageManager.has_gold(cost):
					StorageManager.spend_gold(cost)
					EventBus.gold_changed.emit(StorageManager.gold, -cost)
					SaveManager.balloon_level += 1
					SaveManager.save_game()
					GridManager.add_attraction_score(10)
					AudioManager.play_sfx("level_up")
					show_floating_notice("🎈 Khinh Khí Cầu đã lên Cấp %d! (+10%% Tip Xu Du Lịch & +10 Năng Động)" % SaveManager.balloon_level)
					_refresh_all_hud()
					open_hot_air_balloon_modal()
				else:
					AudioManager.play_sfx("error")
					show_floating_notice("⚠️ Cần %d Vàng để nâng cấp Khinh Khí Cầu!" % cost)
		)
		vbox_cards.add_child(card2)
	else:
		var card_max: PanelContainer = _create_feed_shop_card(
			"★ Khinh Khí Cầu Đạt Cấp Tối Đa (Lv.5)",
			"Đã mở khóa toàn bộ hiệu suất! Tip du khách tại Sở Thú tăng tối đa +50% vĩnh viễn.",
			"Trạng thái: Tối đa (Level 5)",
			"★ Đã Tối Đa",
			func() -> void:
				show_floating_notice("★ Khinh Khí Cầu đã đạt cấp độ tối đa!")
		)
		vbox_cards.add_child(card_max)
	
	add_child(_hot_air_balloon_modal)

func open_newspaper_modal() -> void:
	if _newspaper_modal != null and is_instance_valid(_newspaper_modal):
		_newspaper_modal.queue_free()
	
	_newspaper_modal = PanelContainer.new()
	_newspaper_modal.name = "NewspaperModal"
	_newspaper_modal.custom_minimum_size = Vector2(640, 480)
	_newspaper_modal.anchors_preset = Control.PRESET_CENTER
	_newspaper_modal.anchor_left = 0.5
	_newspaper_modal.anchor_top = 0.5
	_newspaper_modal.anchor_right = 0.5
	_newspaper_modal.anchor_bottom = 0.5
	_newspaper_modal.offset_left = -320
	_newspaper_modal.offset_top = -240
	_newspaper_modal.offset_right = 320
	_newspaper_modal.offset_bottom = 240
	_newspaper_modal.z_index = 100
	
	# Warm Vintage Newspaper StyleBox
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.98, 0.95, 0.88, 0.99)
	sb.border_color = Color(0.48, 0.32, 0.18, 1.0)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.shadow_color = Color(0.18, 0.10, 0.04, 0.45)
	sb.shadow_size = 12
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	_newspaper_modal.add_theme_stylebox_override("panel", sb)
	
	var vbox_main: VBoxContainer = VBoxContainer.new()
	vbox_main.add_theme_constant_override("separation", 8)
	_newspaper_modal.add_child(vbox_main)
	
	# Header
	var hbox_head: HBoxContainer = HBoxContainer.new()
	vbox_main.add_child(hbox_head)
	
	var lbl_title: Label = Label.new()
	lbl_title.text = "📰 BÁO NÔNG THÔN - CHỢ PHIÊN HÔM NAY"
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_title.add_theme_font_size_override("font_size", 14)
	lbl_title.add_theme_color_override("font_color", Color(0.32, 0.18, 0.08))
	lbl_title.add_theme_color_override("font_outline_color", Color.WHITE)
	lbl_title.add_theme_constant_override("outline_size", 2)
	hbox_head.add_child(lbl_title)
	
	var btn_close: Button = Button.new()
	_apply_dialog_close_button(btn_close)
	btn_close.pressed.connect(func() -> void:
		AudioManager.play_sfx("click")
		_newspaper_modal.queue_free()
	)
	hbox_head.add_child(btn_close)
	
	# Subtitle / Toolbar Bar
	var hbox_bar: HBoxContainer = HBoxContainer.new()
	hbox_bar.add_theme_constant_override("separation", 12)
	vbox_main.add_child(hbox_bar)
	
	var remaining_time: int = DailyNewspaper.get_time_remaining()
	var lbl_timer: Label = Label.new()
	lbl_timer.text = "⏳ Tự động đổi số báo sau: %02d:%02d" % [remaining_time / 60, remaining_time % 60]
	lbl_timer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_timer.add_theme_font_size_override("font_size", 11)
	lbl_timer.add_theme_color_override("font_color", Color(0.45, 0.30, 0.15))
	hbox_bar.add_child(lbl_timer)
	
	var btn_refresh: Button = Button.new()
	btn_refresh.text = "🔄 Đổi Số Báo Mới (50 Vàng)"
	btn_refresh.custom_minimum_size = Vector2(170, 30)
	_apply_dialog_action_button(btn_refresh, false)
	btn_refresh.pressed.connect(func() -> void:
		if StorageManager.has_gold(50):
			StorageManager.spend_gold(50)
			EventBus.gold_changed.emit(StorageManager.gold, -50)
			DailyNewspaper.force_refresh_newspaper()
			AudioManager.play_sfx("sell")
			show_floating_notice("📰 Đã phát hành số báo mới từ các nông trại láng giềng!")
			_refresh_all_hud()
			open_newspaper_modal()
		else:
			AudioManager.play_sfx("error")
			show_floating_notice("⚠️ Cần 50 Vàng để đổi số báo mới ngay lập tức!")
	)
	hbox_bar.add_child(btn_refresh)
	
	# Grid Container: 3 cols x 2 rows (6 classified ads)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox_main.add_child(grid)
	
	var slots: Array[Dictionary] = DailyNewspaper.get_newspaper_slots()
	for i in range(slots.size()):
		var slot_data: Dictionary = slots[i]
		var card: PanelContainer = _create_newspaper_slot_card(slot_data, i)
		grid.add_child(card)
	
	add_child(_newspaper_modal)

func _create_newspaper_slot_card(slot: Dictionary, slot_idx: int) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(195, 175)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var csb: StyleBoxFlat = StyleBoxFlat.new()
	var is_sold: bool = bool(slot.get("is_sold", false))
	if is_sold:
		csb.bg_color = Color(0.92, 0.90, 0.84, 0.8)
		csb.border_color = Color(0.72, 0.68, 0.60, 0.7)
	else:
		csb.bg_color = Color(1.0, 0.99, 0.96, 0.98)
		csb.border_color = Color(0.78, 0.60, 0.40, 0.9)
	csb.set_border_width_all(2)
	csb.set_corner_radius_all(10)
	csb.content_margin_left = 8
	csb.content_margin_right = 8
	csb.content_margin_top = 6
	csb.content_margin_bottom = 6
	card.add_theme_stylebox_override("panel", csb)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	card.add_child(vbox)
	
	# Seller info & Discount Tag
	var hbox_seller: HBoxContainer = HBoxContainer.new()
	vbox.add_child(hbox_seller)
	
	var seller_str: String = String(slot.get("neighbor_name", slot.get("seller_name", "Nông Trại")))
	var lbl_seller: Label = Label.new()
	lbl_seller.text = "🏡 %s" % seller_str
	lbl_seller.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_seller.add_theme_font_size_override("font_size", 10)
	lbl_seller.add_theme_color_override("font_color", Color(0.38, 0.22, 0.10))
	hbox_seller.add_child(lbl_seller)
	
	var disc_pct: int = int(slot.get("discount", slot.get("discount_pct", 30)))
	var lbl_disc: Label = Label.new()
	lbl_disc.text = "-%d%%" % disc_pct
	lbl_disc.add_theme_font_size_override("font_size", 9)
	lbl_disc.add_theme_color_override("font_color", Color(0.9, 0.15, 0.15))
	hbox_seller.add_child(lbl_disc)
	
	# Item Name & Count
	var lbl_item: Label = Label.new()
	var item_name: String = String(slot.get("item_name", "Vật Phẩm"))
	var count: int = int(slot.get("count", 1))
	lbl_item.text = "%s x%d" % [item_name, count]
	lbl_item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_item.add_theme_font_size_override("font_size", 11)
	lbl_item.add_theme_color_override("font_color", Color(0.20, 0.12, 0.05))
	vbox.add_child(lbl_item)
	
	# Item Icon / Sprite Preview
	var icon_box: CenterContainer = CenterContainer.new()
	icon_box.custom_minimum_size = Vector2(40, 40)
	vbox.add_child(icon_box)
	
	var tex_id: String = String(slot.get("item_id", ""))
	if SpriteAtlasManager.has_texture(tex_id):
		var sp: TextureRect = TextureRect.new()
		sp.texture = SpriteAtlasManager.get_texture(tex_id)
		sp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sp.custom_minimum_size = Vector2(36, 36)
		icon_box.add_child(sp)
	else:
		var lbl_emoji: Label = Label.new()
		lbl_emoji.text = "📦"
		lbl_emoji.add_theme_font_size_override("font_size", 20)
		icon_box.add_child(lbl_emoji)
	
	# Price Display: Original Price struck out & Sale Price
	var hbox_p: HBoxContainer = HBoxContainer.new()
	hbox_p.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_p.add_theme_constant_override("separation", 6)
	vbox.add_child(hbox_p)
	
	var orig_p: int = int(slot.get("original_price", 0))
	var sale_p: int = int(slot.get("sale_price", 0))
	
	var lbl_orig: Label = Label.new()
	lbl_orig.text = "%dV" % orig_p
	lbl_orig.add_theme_font_size_override("font_size", 9)
	lbl_orig.add_theme_color_override("font_color", Color(0.60, 0.50, 0.40))
	hbox_p.add_child(lbl_orig)
	
	var lbl_sale: Label = Label.new()
	lbl_sale.text = "💰 %d Vàng" % sale_p
	lbl_sale.add_theme_font_size_override("font_size", 11)
	lbl_sale.add_theme_color_override("font_color", Color(0.85, 0.45, 0.05))
	hbox_p.add_child(lbl_sale)
	
	# Buy Action or "ĐÃ MUA" Banner
	if is_sold:
		var lbl_bought: Label = Label.new()
		lbl_bought.text = "✅ ĐÃ BÁN HẾT"
		lbl_bought.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_bought.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_bought.custom_minimum_size = Vector2(140, 28)
		lbl_bought.add_theme_font_size_override("font_size", 10)
		lbl_bought.add_theme_color_override("font_color", Color(0.4, 0.5, 0.35))
		vbox.add_child(lbl_bought)
	else:
		var btn_buy: Button = Button.new()
		btn_buy.text = "🛒 Mua Ngay"
		btn_buy.custom_minimum_size = Vector2(140, 28)
		_apply_dialog_action_button(btn_buy, false)
		btn_buy.pressed.connect(func() -> void:
			var res: Dictionary = DailyNewspaper.buy_slot(slot_idx)
			if bool(res.get("success", false)):
				AudioManager.play_sfx("sell")
				show_floating_notice(String(res.get("message", "Đã mua hàng thành công!")))
				EventBus.loot_collected.emit(tex_id, count, Vector2(135.0, 550.0))
				_refresh_all_hud()
				open_newspaper_modal()
			else:
				AudioManager.play_sfx("error")
				show_floating_notice(String(res.get("message", "Không đủ Vàng hoặc kho đã đầy!")))
		)
		vbox.add_child(btn_buy)
	
	return card

func open_steamboat_modal(boat: Node2D = null) -> void:
	if _steamboat_modal != null and is_instance_valid(_steamboat_modal):
		_steamboat_modal.queue_free()
	
	if boat == null:
		var farm: Node = get_tree().current_scene
		if farm != null:
			boat = farm.find_child("RiverSteamboat", true, false) as Node2D
			
	if boat == null:
		return
		
	_steamboat_modal = PanelContainer.new()
	_steamboat_modal.name = "SteamboatModal"
	_steamboat_modal.custom_minimum_size = Vector2(500, 360)
	_steamboat_modal.anchors_preset = Control.PRESET_CENTER
	_steamboat_modal.anchor_left = 0.5
	_steamboat_modal.anchor_top = 0.5
	_steamboat_modal.anchor_right = 0.5
	_steamboat_modal.anchor_bottom = 0.5
	_steamboat_modal.offset_left = -250
	_steamboat_modal.offset_top = -180
	_steamboat_modal.offset_right = 250
	_steamboat_modal.offset_bottom = 180
	_steamboat_modal.z_index = 100
	
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 0.98, 0.93, 0.98) # Warm cream
	sb.border_color = Color(0.70, 0.48, 0.25, 0.95)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	sb.shadow_color = Color(0.12, 0.08, 0.04, 0.45)
	sb.shadow_size = 6
	_steamboat_modal.add_theme_stylebox_override("panel", sb)
	
	var vbox_main: VBoxContainer = VBoxContainer.new()
	vbox_main.add_theme_constant_override("separation", 10)
	_steamboat_modal.add_child(vbox_main)
	
	# Header
	var hbox_head: HBoxContainer = HBoxContainer.new()
	vbox_main.add_child(hbox_head)
	
	var lbl_title: Label = Label.new()
	lbl_title.text = "🚢 CHUYẾN TÀU NÔNG SẢN ĐƯỜNG SÔNG"
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_title.add_theme_font_size_override("font_size", 14)
	lbl_title.add_theme_color_override("font_color", Color(0.35, 0.20, 0.08))
	lbl_title.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0))
	lbl_title.add_theme_constant_override("outline_size", 2)
	hbox_head.add_child(lbl_title)
	
	var btn_close: Button = Button.new()
	_apply_dialog_close_button(btn_close)
	btn_close.pressed.connect(func() -> void:
		AudioManager.play_sfx("click")
		_steamboat_modal.queue_free()
	)
	hbox_head.add_child(btn_close)
	
	var is_cooldown: bool = (int(boat.get("state")) == 3) # BoatState.COOLDOWN
	
	if is_cooldown:
		var lbl_cd: Label = Label.new()
		lbl_cd.text = "⏳ Tàu đang trên đường quay lại bến..."
		lbl_cd.add_theme_font_size_override("font_size", 12)
		lbl_cd.add_theme_color_override("font_color", Color(0.48, 0.32, 0.18))
		vbox_main.add_child(lbl_cd)
		
		var btn_instant: Button = Button.new()
		btn_instant.text = "⚡ Gọi Tàu Cập Bến Ngay (Miễn Phí)"
		btn_instant.custom_minimum_size = Vector2(250, 38)
		btn_instant.add_theme_font_size_override("font_size", 14)
		_apply_dialog_action_button(btn_instant, false)
		btn_instant.pressed.connect(func() -> void:
			if boat.has_method("instant_summon_boat"):
				boat.call("instant_summon_boat")
			_steamboat_modal.queue_free()
		)
		vbox_main.add_child(btn_instant)
		add_child(_steamboat_modal)
		return
	
	var lbl_sub: Label = Label.new()
	lbl_sub.text = "Đóng đủ 3 kiện hàng để nhận Rương Bến Tàu & Mảnh Ghép Sở Thú 🧩!"
	lbl_sub.add_theme_font_size_override("font_size", 11)
	lbl_sub.add_theme_color_override("font_color", Color(0.45, 0.28, 0.15))
	vbox_main.add_child(lbl_sub)
	
	# Crates Container (3 vertical rows)
	var vbox_crates: VBoxContainer = VBoxContainer.new()
	vbox_crates.add_theme_constant_override("separation", 8)
	vbox_main.add_child(vbox_crates)
	
	var crates_arr: Array = boat.get("crates") as Array if boat.get("crates") != null else []
	for i: int in range(crates_arr.size()):
		var crate: Dictionary = crates_arr[i] as Dictionary
		var card: PanelContainer = _create_steamboat_crate_card(boat, crate, i)
		vbox_crates.add_child(card)
		
	# Footer: Grand Chest or Progress
	var hbox_foot: HBoxContainer = HBoxContainer.new()
	hbox_foot.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_main.add_child(hbox_foot)
	
	var all_filled: bool = bool(boat.call("are_all_crates_filled")) if boat.has_method("are_all_crates_filled") else false
	if all_filled:
		var btn_chest: Button = Button.new()
		btn_chest.text = " Nhận Rương Bến Tàu & Cho Tàu Khởi Hành"
		btn_chest.custom_minimum_size = Vector2(380, 42)
		btn_chest.add_theme_font_size_override("font_size", 14)
		_apply_dialog_action_button(btn_chest, false)
		btn_chest.pressed.connect(func() -> void:
			var res: Dictionary = boat.call("claim_chest_and_depart") as Dictionary
			if bool(res.get("success", false)):
				show_floating_notice(String(res.get("message", "Đã nhận thưởng Rương Bến Tàu!")))
				_refresh_all_hud()
				_steamboat_modal.queue_free()
		)
		hbox_foot.add_child(btn_chest)
	else:
		var filled_cnt: int = int(boat.call("get_filled_crates_count")) if boat.has_method("get_filled_crates_count") else 0
		var lbl_prog: Label = Label.new()
		lbl_prog.text = "📦 Tiến độ: %d/3 kiện hàng đã đóng. Hãy đóng đủ 3 kiện để tàu nhổ neo!" % filled_cnt
		lbl_prog.add_theme_font_size_override("font_size", 11)
		lbl_prog.add_theme_color_override("font_color", Color(0.48, 0.30, 0.16))
		hbox_foot.add_child(lbl_prog)
		
	add_child(_steamboat_modal)

func _create_steamboat_crate_card(boat: Node2D, crate: Dictionary, idx: int) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	var csb: StyleBoxFlat = StyleBoxFlat.new()
	csb.bg_color = Color(1.0, 0.98, 0.93, 0.95)
	csb.border_color = Color(0.75, 0.55, 0.35, 0.8)
	csb.set_border_width_all(2)
	csb.set_corner_radius_all(10)
	csb.content_margin_left = 12
	csb.content_margin_right = 12
	csb.content_margin_top = 8
	csb.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", csb)
	
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	card.add_child(hbox)
	
	# Icon Preview
	var icon_box: CenterContainer = CenterContainer.new()
	icon_box.custom_minimum_size = Vector2(40, 40)
	hbox.add_child(icon_box)
	
	var item_id: String = String(crate.get("item_id", ""))
	if SpriteAtlasManager.has_texture(item_id):
		var sp: TextureRect = TextureRect.new()
		sp.texture = SpriteAtlasManager.get_texture(item_id)
		sp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sp.custom_minimum_size = Vector2(36, 36)
		icon_box.add_child(sp)
	else:
		var lbl_em: Label = Label.new()
		lbl_em.text = "📦"
		lbl_em.add_theme_font_size_override("font_size", 20)
		icon_box.add_child(lbl_em)
		
	# Text Info
	var vbox_text: VBoxContainer = VBoxContainer.new()
	vbox_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_text.add_theme_constant_override("separation", 2)
	hbox.add_child(vbox_text)
	
	var item_name: String = String(crate.get("item_name", "Vật phẩm"))
	var qty: int = int(crate.get("qty", 1))
	var gold_r: int = int(crate.get("gold_reward", 20))
	var xp_r: int = int(crate.get("xp_reward", 20))
	var is_filled: bool = bool(crate.get("filled", false))
	
	var lbl_n: Label = Label.new()
	lbl_n.text = "%s x%d" % [item_name, qty]
	lbl_n.add_theme_font_size_override("font_size", 12)
	lbl_n.add_theme_color_override("font_color", Color(0.35, 0.18, 0.08))
	vbox_text.add_child(lbl_n)
	
	var cur_stock: int = StorageManager.get_item_count(item_id)
	var lbl_stock: Label = Label.new()
	lbl_stock.text = "Kho có: %d/%d" % [cur_stock, qty]
	lbl_stock.add_theme_font_size_override("font_size", 10)
	if cur_stock >= qty:
		lbl_stock.add_theme_color_override("font_color", Color(0.15, 0.55, 0.25))
	else:
		lbl_stock.add_theme_color_override("font_color", Color(0.80, 0.40, 0.10))
	vbox_text.add_child(lbl_stock)
	
	var lbl_rew: Label = Label.new()
	lbl_rew.text = "+%d Vàng, +%d XP, +15 Xu" % [gold_r, xp_r]
	lbl_rew.add_theme_font_size_override("font_size", 9)
	lbl_rew.add_theme_color_override("font_color", Color(0.85, 0.50, 0.08))
	vbox_text.add_child(lbl_rew)
	
	# Action Button
	if is_filled:
		var lbl_done: Label = Label.new()
		lbl_done.text = "✅ ĐÃ ĐÓNG KIỆN"
		lbl_done.custom_minimum_size = Vector2(165, 38)
		lbl_done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_done.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_done.add_theme_font_size_override("font_size", 12)
		lbl_done.add_theme_color_override("font_color", Color(0.18, 0.65, 0.28))
		hbox.add_child(lbl_done)
	else:
		var can_fill: bool = (cur_stock >= qty)
		var btn_crate: Button = Button.new()
		btn_crate.custom_minimum_size = Vector2(165, 38)
		btn_crate.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn_crate.add_theme_font_size_override("font_size", 14)
		
		if can_fill:
			btn_crate.text = "📦 Đóng Kiện (+%dV)" % gold_r
			_apply_dialog_action_button(btn_crate, false)
			btn_crate.pressed.connect(func() -> void:
				var res: Dictionary = boat.call("fill_crate", idx, false) as Dictionary
				if bool(res.get("success", false)):
					AudioManager.play_sfx("harvest")
					show_floating_notice(String(res.get("message", "Đã đóng kiện hàng!")))
					_refresh_all_hud()
					open_steamboat_modal(boat)
				else:
					AudioManager.play_sfx("error")
					show_floating_notice(String(res.get("message", "Không đủ vật phẩm!")))
			)
		else:
			btn_crate.text = "⚡ Đóng Hộ (80 Vàng)"
			_apply_dialog_action_button(btn_crate, true)
			btn_crate.pressed.connect(func() -> void:
				var res: Dictionary = boat.call("fill_crate", idx, true) as Dictionary
				if bool(res.get("success", false)):
					AudioManager.play_sfx("sell")
					show_floating_notice(String(res.get("message", "Đã thuê đóng hộ kiện hàng!")))
					_refresh_all_hud()
					open_steamboat_modal(boat)
				else:
					AudioManager.play_sfx("error")
					show_floating_notice(String(res.get("message", "Cần 80 Vàng!")))
			)
		hbox.add_child(btn_crate)
		
	return card


func show_chest_reward_modal(title_text: String, rewards: Array[Dictionary]) -> void:
	AudioManager.play_sfx("welcome_chime")
	var modal: PanelContainer = PanelContainer.new()
	modal.name = "ChestRewardModal"
	modal.custom_minimum_size = Vector2(460, 340)
	modal.anchors_preset = Control.PRESET_CENTER
	modal.anchor_left = 0.5
	modal.anchor_top = 0.5
	modal.anchor_right = 0.5
	modal.anchor_bottom = 0.5
	modal.offset_left = -230.0
	modal.offset_top = -170.0
	modal.offset_right = 230.0
	modal.offset_bottom = 170.0
	modal.z_index = 120
	
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.99, 0.96, 0.90, 0.98)
	sb.border_color = Color(0.85, 0.65, 0.20, 1.0)
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(18)
	sb.shadow_color = Color(0.2, 0.1, 0.05, 0.6)
	sb.shadow_size = 16
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	modal.add_theme_stylebox_override("panel", sb)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	modal.add_child(vbox)
	
	var chest_img: TextureRect = TextureRect.new()
	chest_img.custom_minimum_size = Vector2(160, 90)
	chest_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chest_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tex_banner: Texture2D = load("res://assets/sprites/ui_offline_chest_banner.png") as Texture2D
	if tex_banner != null:
		chest_img.texture = tex_banner
	vbox.add_child(chest_img)
	
	var lbl_t: Label = Label.new()
	lbl_t.text = title_text
	lbl_t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_t.add_theme_font_size_override("font_size", 16)
	lbl_t.add_theme_color_override("font_color", Color(0.45, 0.22, 0.05))
	vbox.add_child(lbl_t)
	
	var r_box: VBoxContainer = VBoxContainer.new()
	r_box.add_theme_constant_override("separation", 6)
	vbox.add_child(r_box)
	
	for rew: Dictionary in rewards:
		var row: HBoxContainer = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 8)
		
		var icon_tex: Texture2D = rew.get("icon", null) as Texture2D
		if icon_tex != null:
			var icon_rect: TextureRect = TextureRect.new()
			icon_rect.custom_minimum_size = Vector2(28, 28)
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.texture = icon_tex
			row.add_child(icon_rect)
			
		var lbl_rew: Label = Label.new()
		lbl_rew.text = String(rew.get("text", ""))
		lbl_rew.add_theme_font_size_override("font_size", 14)
		lbl_rew.add_theme_color_override("font_color", Color(0.18, 0.55, 0.20))
		row.add_child(lbl_rew)
		r_box.add_child(row)
		
	var btn_ok: Button = Button.new()
	btn_ok.text = "NHẬN QUÀ"
	btn_ok.custom_minimum_size = Vector2(180, 40)
	btn_ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_apply_dialog_action_button(btn_ok, false)
	btn_ok.pressed.connect(func() -> void:
		AudioManager.play_sfx("welcome_chime")
		modal.queue_free()
	)
	vbox.add_child(btn_ok)
	
	add_child(modal)
