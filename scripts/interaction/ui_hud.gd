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
@onready var pill_silo: PanelContainer = $TopLeftHUD/PillSilo
@onready var pill_barn: PanelContainer = $TopLeftHUD/PillBarn

const StockAlertSystemClass = preload("res://scripts/systems/stock_alert_system.gd")

var label_coins: Label = null
var stock_alert_system: Control = null
var _rename_modal: PanelContainer = null
var _settings_modal: PanelContainer = null
var _level_up_modal: PanelContainer = null
var _sell_picker_modal: PanelContainer = null

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
	
	# Enable clicking on Silo and Barn progress pills to open Storage Management
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
		btn_audio_toggle.text = "🔇" if AudioManager.is_muted else "🔊"
		btn_audio_toggle.pressed.connect(func() -> void:
			var muted: bool = AudioManager.toggle_mute()
			btn_audio_toggle.text = "🔇" if muted else "🔊"
			if not muted:
				AudioManager.play_sfx("click")
		)
	
	if btn_settings != null:
		btn_settings.pressed.connect(open_settings_modal)
	
	if RoadsideShop != null:
		RoadsideShop.shop_updated.connect(_refresh_shop_ui)
	if TruckOrderSystem != null:
		TruckOrderSystem.orders_updated.connect(_refresh_truck_ui)
	
	if drag_action_manager != null:
		drag_action_manager.tool_changed.connect(_on_drag_tool_changed)
	
	panel_shop.visible = false
	panel_truck.visible = false
	if panel_seeds_menu != null:
		panel_seeds_menu.visible = false
	
	if icon_gold != null and SpriteAtlasManager != null and SpriteAtlasManager.has_texture("icon_gold"):
		icon_gold.texture = SpriteAtlasManager.get_texture("icon_gold")
	
	# Ensure crisp readability for HUD numbers: dark brown with white outline
	var dark_brown: Color = Color(0.24, 0.15, 0.14) # #3E2723
	var white_outline: Color = Color(1.0, 1.0, 1.0)
	for lbl in [label_silo, label_barn, label_level, label_diamonds, label_gold, label_xp]:
		if lbl != null:
			lbl.add_theme_color_override("font_color", dark_brown)
			lbl.add_theme_color_override("font_outline_color", white_outline)
			lbl.add_theme_constant_override("outline_size", 2)

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
	if panel_shop != null:
		panel_shop.visible = false
	if panel_truck != null:
		panel_truck.visible = false
	if drag_action_manager != null:
		drag_action_manager.set_tool(DragActionManager.ToolType.NONE)
	_highlight_active_button(DragActionManager.ToolType.NONE)

func _refresh_all_hud() -> void:
	_on_coins_changed(StorageManager.coins, 0)
	_on_gold_changed(StorageManager.gold, 0)
	_on_diamonds_changed(StorageManager.diamonds, 0)
	var needed_xp: int = StorageManager.get_required_xp(StorageManager.level)
	_on_xp_changed(StorageManager.xp, needed_xp, StorageManager.level)
	_on_storage_updated("silo", StorageManager.get_silo_used(), StorageManager.silo_capacity)
	_on_storage_updated("barn", StorageManager.get_barn_used(), StorageManager.barn_capacity)
	_on_attraction_score_changed(GridManager.total_attraction_score)
	_refresh_seed_counts()

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
	var top_hud: VBoxContainer = find_child("TopLeftHUD", true, false) as VBoxContainer
	if top_hud != null and label_coins == null:
		var row_coins: HBoxContainer = HBoxContainer.new()
		row_coins.name = "RowCoins"
		row_coins.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var pill_coins: PanelContainer = PanelContainer.new()
		pill_coins.name = "PillCoins"
		pill_coins.custom_minimum_size = Vector2(170, 36)
		pill_coins.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = Color(1.0, 0.99, 0.96, 0.96)
		sb.border_color = Color(0.42, 0.30, 0.21, 1.0)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(16)
		sb.shadow_color = Color(0.42, 0.30, 0.21, 0.18)
		sb.shadow_size = 4
		sb.content_margin_left = 8
		sb.content_margin_right = 8
		pill_coins.add_theme_stylebox_override("panel", sb)
		
		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_theme_constant_override("separation", 6)
		pill_coins.add_child(hbox)
		
		var icon_coin_rect: TextureRect = TextureRect.new()
		icon_coin_rect.name = "IconCoin"
		icon_coin_rect.custom_minimum_size = Vector2(22, 22)
		icon_coin_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_coin_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_coin_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if SpriteAtlasManager.has_texture("icon_coin"):
			icon_coin_rect.texture = SpriteAtlasManager.get_texture("icon_coin")
		hbox.add_child(icon_coin_rect)
		
		label_coins = Label.new()
		label_coins.name = "LabelCoins"
		label_coins.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label_coins.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label_coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label_coins.add_theme_color_override("font_color", Color(0.24, 0.15, 0.14))
		label_coins.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0))
		label_coins.add_theme_constant_override("outline_size", 2)
		label_coins.add_theme_font_size_override("font_size", 16)
		label_coins.text = "%s Xu" % _format_number(StorageManager.coins)
		hbox.add_child(label_coins)
		
		row_coins.add_child(pill_coins)
		top_hud.add_child(row_coins)
		top_hud.move_child(row_coins, 0)

func _on_coins_changed(new_coins: int, _delta: int) -> void:
	if label_coins != null:
		label_coins.text = "%s Xu" % _format_number(new_coins)

func _on_gold_changed(new_gold: int, _delta: int) -> void:
	if label_gold != null:
		label_gold.text = "👑 %s Vàng" % _format_number(new_gold)

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
	
	_level_up_modal = PanelContainer.new()
	_level_up_modal.name = "LevelUpModal"
	_level_up_modal.custom_minimum_size = Vector2(360, 220)
	_level_up_modal.anchors_preset = Control.PRESET_CENTER
	_level_up_modal.anchor_left = 0.5
	_level_up_modal.anchor_top = 0.5
	_level_up_modal.anchor_right = 0.5
	_level_up_modal.anchor_bottom = 0.5
	_level_up_modal.offset_left = -180.0
	_level_up_modal.offset_top = -110.0
	_level_up_modal.offset_right = 180.0
	_level_up_modal.offset_bottom = 110.0
	_level_up_modal.z_index = 150
	
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.99, 0.96, 0.90, 0.98)
	sb.border_color = Color(0.85, 0.65, 0.18, 1.0)
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	sb.shadow_color = Color(0.3, 0.2, 0.05, 0.3)
	sb.shadow_size = 10
	_level_up_modal.add_theme_stylebox_override("panel", sb)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
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
	lbl_level_badge.text = "⭐ CẤP ĐỘ %d ⭐" % new_level
	lbl_level_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_level_badge.add_theme_font_size_override("font_size", 22)
	lbl_level_badge.add_theme_color_override("font_color", Color(0.25, 0.15, 0.10))
	vbox.add_child(lbl_level_badge)
	
	var gold_reward: int = 150 + new_level * 25
	var dia_reward: int = 2
	var lbl_rewards: Label = Label.new()
	lbl_rewards.text = "🎁 Phần thưởng: +%d 👑 Vàng   +%d 💎 Kim Cương" % [gold_reward, dia_reward]
	lbl_rewards.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_rewards.add_theme_font_size_override("font_size", 12)
	lbl_rewards.add_theme_color_override("font_color", Color(0.18, 0.58, 0.22))
	vbox.add_child(lbl_rewards)
	
	var btn_ok: Button = Button.new()
	btn_ok.text = "🌟 Tuyệt Vời!"
	btn_ok.custom_minimum_size = Vector2(130, 36)
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
	_settings_modal.custom_minimum_size = Vector2(360, 260)
	_settings_modal.anchors_preset = Control.PRESET_CENTER
	_settings_modal.anchor_left = 0.5
	_settings_modal.anchor_top = 0.5
	_settings_modal.anchor_right = 0.5
	_settings_modal.anchor_bottom = 0.5
	_settings_modal.offset_left = -180.0
	_settings_modal.offset_top = -130.0
	_settings_modal.offset_right = 180.0
	_settings_modal.offset_bottom = 130.0
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
	
	var hbox_head: HBoxContainer = HBoxContainer.new()
	vbox.add_child(hbox_head)
	
	var lbl_title: Label = Label.new()
	lbl_title.text = "⚙️ CÀI ĐẶT & QUẢN LÝ DỮ LIỆU"
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_title.add_theme_font_size_override("font_size", 13)
	lbl_title.add_theme_color_override("font_color", Color(0.35, 0.20, 0.10))
	hbox_head.add_child(lbl_title)
	
	var btn_close: Button = Button.new()
	btn_close.text = "✕"
	btn_close.custom_minimum_size = Vector2(28, 28)
	btn_close.pressed.connect(func() -> void:
		_settings_modal.queue_free()
	)
	hbox_head.add_child(btn_close)
	
	var lbl_sub: Label = Label.new()
	lbl_sub.text = "Chọn chức năng lưu trữ hoặc chế độ chơi mong muốn:"
	lbl_sub.add_theme_font_size_override("font_size", 11)
	lbl_sub.add_theme_color_override("font_color", Color(0.45, 0.30, 0.20))
	vbox.add_child(lbl_sub)
	
	var btn_save: Button = Button.new()
	btn_save.text = "💾 Lưu Game Ngay"
	btn_save.custom_minimum_size = Vector2(0, 34)
	btn_save.pressed.connect(func() -> void:
		SaveManager.save_game()
		AudioManager.play_sfx("coin")
		show_floating_notice("💾 Đã lưu tiến trình nông trại an toàn!")
		_settings_modal.queue_free()
	)
	vbox.add_child(btn_save)
	
	var btn_reset_lvl1: Button = Button.new()
	btn_reset_lvl1.text = "🌱 Chơi Mới Chuẩn (Level 1)"
	btn_reset_lvl1.custom_minimum_size = Vector2(0, 34)
	btn_reset_lvl1.pressed.connect(func() -> void:
		SaveManager.reset_to_level_1()
		_refresh_all_hud()
		_refresh_shop_ui()
		_refresh_truck_ui()
		AudioManager.play_sfx("level_up")
		show_floating_notice("🌱 Đã thiết lập lại nông trại Cấp 1! Chúc bạn cày cuốc vui vẻ!")
		_settings_modal.queue_free()
	)
	vbox.add_child(btn_reset_lvl1)
	
	var btn_sandbox: Button = Button.new()
	btn_sandbox.text = "🛠️ Chế Độ Thử Nghiệm (Sandbox Level 32)"
	btn_sandbox.custom_minimum_size = Vector2(0, 34)
	btn_sandbox.pressed.connect(func() -> void:
		SaveManager.set_sandbox_level_32()
		_refresh_all_hud()
		_refresh_shop_ui()
		_refresh_truck_ui()
		AudioManager.play_sfx("coin")
		show_floating_notice("🛠️ Đã kích hoạt Chế Độ Thử Nghiệm Cấp 32!")
		_settings_modal.queue_free()
	)
	vbox.add_child(btn_sandbox)
	
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
		label_attraction.text = "✨ %d" % new_score

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
	card.custom_minimum_size = Vector2(140, 110)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)
	
	var item_id: String = String(slot.get("item_id", ""))
	var count: int = int(slot.get("count", 0))
	var price: int = int(slot.get("price", 0))
	var is_sold: bool = bool(slot.get("is_sold", false))
	
	if item_id == "":
		# Empty slot: button to quick list items
		var lbl_empty: Label = Label.new()
		lbl_empty.text = "Ô Trống"
		lbl_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lbl_empty)
		
		var btn_list: Button = Button.new()
		btn_list.text = "+ Đăng Bán"
		btn_list.pressed.connect(func() -> void: open_sell_item_picker(slot_index))
		vbox.add_child(btn_list)
	elif is_sold:
		# Sold: Collect money!
		var lbl_sold: Label = Label.new()
		lbl_sold.text = "💰 ĐÃ BÁN!"
		lbl_sold.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
		lbl_sold.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lbl_sold)
		
		var btn_collect: Button = Button.new()
		btn_collect.text = "Nhận %d Vàng" % price
		btn_collect.pressed.connect(func() -> void:
			RoadsideShop.collect_coins(slot_index)
		)
		vbox.add_child(btn_collect)
	else:
		# On sale
		var item_name: String = DataManager.get_item_name(item_id)
		var lbl_info: Label = Label.new()
		lbl_info.text = "%dx %s" % [count, item_name]
		lbl_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lbl_info)
		
		var lbl_price: Label = Label.new()
		lbl_price.text = "Giá: %d Vàng" % price
		lbl_price.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		lbl_price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lbl_price)
		
		var btn_sim: Button = Button.new()
		btn_sim.text = "Bán Cho Khách"
		btn_sim.pressed.connect(func() -> void:
			RoadsideShop.buy_slot_by_shopper(slot_index)
		)
		vbox.add_child(btn_sim)
	
	return card

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
	btn_close.text = "✕"
	btn_close.custom_minimum_size = Vector2(28, 28)
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
			btn_sell_max.text = "⭐ %d" % max_price
			btn_sell_max.tooltip_text = "Đăng bán giá tối đa"
			btn_sell_max.pressed.connect(func() -> void:
				if RoadsideShop.list_item(slot_index, i_id, sell_qty, max_price):
					AudioManager.play_sfx("coin")
					show_floating_notice("⭐ Đã đăng bán %dx %s giá tối đa (%d Vàng)!" % [sell_qty, i_name, max_price])
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
	lbl_rew.text = "+%d Vàng  +%d ⭐" % [gold, xp]
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
	btn_send.text = "🚚 Giao Hàng"
	btn_send.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_send.disabled = not can_fulfill
	btn_send.custom_minimum_size = Vector2(110, 30)
	btn_send.pressed.connect(func() -> void:
		if TruckOrderSystem.fulfill_order(order_index):
			# Emit flying loot for rewards
			var truck_screen_pos: Vector2 = Vector2(352, 576)
			_on_loot_collected("gold", gold, truck_screen_pos)
			_on_loot_collected("xp", xp, truck_screen_pos + Vector2(25, -15))
			
			# Trigger truck drive animation on farm
			var farm: Node = get_tree().current_scene
			if farm != null and farm.has_method("play_truck_delivery_animation"):
				farm.call("play_truck_delivery_animation")
			
			panel_truck.visible = false
	)
	hbox_btns.add_child(btn_send)
	
	var btn_trash: Button = Button.new()
	btn_trash.text = "🗑️ Đổi Đơn"
	btn_trash.custom_minimum_size = Vector2(80, 30)
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
	
	var default_title: String = "🌾 QUẢN LÝ KHO SILO" if _current_storage_view == "silo" else "📦 QUẢN LÝ KHO BARN"
	var building_key: String = "building_silo" if _current_storage_view == "silo" else "building_barn"
	var display_title: String = SaveManager.get_building_name(building_key, default_title)
	
	var lbl_title: Label = Label.new()
	lbl_title.text = display_title
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_title.add_theme_font_size_override("font_size", 16)
	lbl_title.add_theme_color_override("font_color", Color(0.35, 0.20, 0.10))
	hbox_head.add_child(lbl_title)
	
	var btn_rename: Button = Button.new()
	btn_rename.text = "✏️ Đổi Tên"
	btn_rename.custom_minimum_size = Vector2(80, 26)
	btn_rename.pressed.connect(func() -> void:
		open_rename_modal(building_key, default_title, func(_new_name: String) -> void:
			_refresh_storage_modal()
		)
	)
	hbox_head.add_child(btn_rename)
	
	var btn_close: Button = Button.new()
	btn_close.text = "✕"
	btn_close.custom_minimum_size = Vector2(28, 28)
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
	lbl_title.text = "✏️ Đổi Tên Công Trình"
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
	_build_modal.custom_minimum_size = Vector2(510, 390)
	_build_modal.anchors_preset = Control.PRESET_CENTER
	_build_modal.anchor_left = 0.5
	_build_modal.anchor_top = 0.5
	_build_modal.anchor_right = 0.5
	_build_modal.anchor_bottom = 0.5
	_build_modal.offset_left = -255.0
	_build_modal.offset_top = -195.0
	_build_modal.offset_right = 255.0
	_build_modal.offset_bottom = 195.0
	_build_modal.z_index = 80
	
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.98, 0.95, 0.88, 0.98)
	sb.border_color = Color(0.60, 0.40, 0.22, 1.0)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	_build_modal.add_theme_stylebox_override("panel", sb)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_build_modal.add_child(vbox)
	
	# Header
	var hbox_head: HBoxContainer = HBoxContainer.new()
	vbox.add_child(hbox_head)
	
	var lbl_title: Label = Label.new()
	lbl_title.text = "🏗️ CỬA HÀNG XÂY DỰNG & TRANG TRÍ"
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_title.add_theme_font_size_override("font_size", 15)
	lbl_title.add_theme_color_override("font_color", Color(0.35, 0.20, 0.10))
	hbox_head.add_child(lbl_title)
	
	var btn_close: Button = Button.new()
	btn_close.text = "✕"
	btn_close.custom_minimum_size = Vector2(28, 28)
	btn_close.pressed.connect(func() -> void:
		_build_modal.visible = false
	)
	hbox_head.add_child(btn_close)
	
	# Catalog Items
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(478, 310)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	
	var catalog: Array[Dictionary] = [
		{"id": "field_plot", "name": "Ô Ruộng Màu Mỡ", "desc": "Gieo hạt và thu hoạch nông sản", "cost": 1, "level": 1, "icon": "item_wheat"},
		{"id": "mini_zoo", "name": "Khu Sở Thú Thú Cưng", "desc": "Chuồng Ngựa & Lừa đi dạo", "cost": 200, "level": 8, "icon": "building_mini_zoo"},
		{"id": "cake_oven", "name": "Lò Bánh Ngọt", "desc": "Nướng bánh kem dâu tây", "cost": 120, "level": 5, "icon": "building_cake_oven"},
		{"id": "juice_stand", "name": "Quầy Nước Pha Chế", "desc": "Nước ép & sinh tố mát lạnh", "cost": 60, "level": 6, "icon": "building_juice_stand"},
		{"id": "ice_cream", "name": "Quầy Kem Tươi", "desc": "Chế biến kem tươi ngọt béo", "cost": 180, "level": 7, "icon": "building_ice_cream"},
		{"id": "bee_hive", "name": "Tổ Ong Mật", "desc": "Thu hoạch mật ong hoa thơm", "cost": 80, "level": 4, "icon": "building_bee_hive"},
		{"id": "flower_bed", "name": "Bồn Hoa Cúc Rực Rỡ", "desc": "Tăng điểm cảnh quan trang trại", "cost": 25, "level": 2, "icon": "flowerbed_round"},
		{"id": "wooden_bench", "name": "Ghế Gỗ Nghỉ Chân", "desc": "Khách du lịch dừng chân", "cost": 15, "level": 2, "icon": "wooden_bench"},
		{"id": "fountain", "name": "Đài Phun Nước Cổ Kính", "desc": "Tâm điểm check-in tuyệt đẹp", "cost": 150, "level": 5, "icon": "fountain"}
	]
	
	for item in catalog:
		var card: PanelContainer = _create_build_card(item)
		grid.add_child(card)
	
	add_child(_build_modal)

func _create_build_card(item: Dictionary) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(230, 92)
	
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 1.0, 1.0, 0.88)
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
	
	var cost: int = int(item.get("cost", 0))
	var req_level: int = int(item.get("level", 1))
	var lbl_info: Label = Label.new()
	lbl_info.text = "Cấp %d | 💰 %d Vàng" % [req_level, cost]
	lbl_info.add_theme_font_size_override("font_size", 10)
	lbl_info.add_theme_color_override("font_color", Color(0.8, 0.45, 0.1))
	vbox.add_child(lbl_info)
	
	var btn_buy: Button = Button.new()
	btn_buy.custom_minimum_size = Vector2(0, 24)
	var can_afford: bool = StorageManager.gold >= cost
	var meets_level: bool = StorageManager.level >= req_level
	if not meets_level:
		btn_buy.text = "🔒 Cần Cấp %d" % req_level
		btn_buy.disabled = true
	elif not can_afford:
		btn_buy.text = "Thiếu Vàng"
		btn_buy.disabled = true
	else:
		btn_buy.text = "🔨 Xây Dựng"
		btn_buy.disabled = false
		var b_id: String = String(item.get("id", ""))
		btn_buy.pressed.connect(func() -> void:
			_build_modal.visible = false
			if b_id == "field_plot":
				_on_tool_selected(DragActionManager.ToolType.BUILD_FIELD)
				return
			var farm: Node = get_tree().current_scene
			if farm != null and farm.has_method("start_building_placement"):
				farm.call("start_building_placement", b_id, cost)
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
	btn_close.text = "✕"
	btn_close.custom_minimum_size = Vector2(20, 20)
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
	btn_rename.text = "✏️ Đổi Tên"
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
	btn_close.text = "✕"
	btn_close.custom_minimum_size = Vector2(28, 28)
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
		btn_speedup.text = "⚡ Hoàn Thành Ngay (1 💎)"
		btn_speedup.custom_minimum_size = Vector2(0, 30)
		btn_speedup.pressed.connect(func() -> void:
			if StorageManager.diamonds < 1:
				show_floating_notice("⚠️ Bạn không đủ Kim Cương (cần 1 💎)!")
				return
			if is_instance_valid(machine):
				if machine.speed_up_current_job():
					show_floating_notice("⚡ Đã hoàn thành ngay bằng 1 💎!")
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
		btn_craft.text = "⚠️ Thiếu Đồ"
		btn_craft.pressed.connect(func() -> void:
			show_floating_notice("⚠️ Không đủ nguyên liệu để sản xuất %s!" % String(rec.get("name", prod_item)))
			AudioManager.play_sfx("click")
		)
	else:
		btn_craft.text = "🍳 Sản Xuất"
		btn_craft.disabled = false
		btn_craft.pressed.connect(func() -> void:
			if is_instance_valid(machine):
				machine.start_recipe(rec_id)
				AudioManager.play_sfx("plant")
				open_production_recipe_modal(machine)
		)
	hbox.add_child(btn_craft)
	
	return row
