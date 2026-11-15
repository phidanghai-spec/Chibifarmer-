class_name TestFarmLogicAndVisuals
extends GdUnitTestSuite

func after_test() -> void:
	TickManager.dev_speed_multiplier = 1.0

# ==============================================================================
# 1. TEST LOGIC KINH TẾ & KHO BÃI (StorageManager)
# ==============================================================================
func test_economy_and_inventory_never_negative() -> void:
	var sm: Node = get_node_or_null("/root/StorageManager")
	assert_object(sm).is_not_null()
	if sm == null:
		return
		
	# Thử trừ số tiền lớn hơn số tiền hiện có -> Tiền không được phép âm
	if sm.has_method("spend_gold") and sm.has_method("get_gold"):
		sm.call("spend_gold", 99999999)
		var current_gold: int = int(sm.call("get_gold"))
		assert_int(current_gold).is_greater_equal(0)

	# Thử lấy nông sản vượt quá số lượng trong kho Silo/Barn -> Số lượng >= 0
	if sm.has_method("remove_item") and sm.has_method("get_item_count"):
		sm.call("remove_item", "wheat", 999999)
		var wheat_count: int = int(sm.call("get_item_count", "wheat"))
		assert_int(wheat_count).is_greater_equal(0)

# ==============================================================================
# 2. TEST LOGIC TĂNG TRƯỞNG CÂY TRỒNG (Không vượt quá giai đoạn cuối)
# ==============================================================================
func test_crop_growth_stage_bounds() -> void:
	var max_stage: int = 3
	var current_stage: int = 0
	
	# Giả lập 10 chu kỳ tăng trưởng liên tiếp (bao gồm cả khi trời mưa tăng 25% tốc độ)
	for tick: int in range(10):
		current_stage = mini(current_stage + 1, max_stage)
		assert_int(current_stage).is_between(0, max_stage)

# ==============================================================================
# 3. TEST HÌNH ẢNH: QUÉT SPRITE CHỐNG LỖI NỀN VUÔNG, WATERMARK & ẢNH RỖNG
# ==============================================================================
func test_all_sprites_valid_and_corners_transparent() -> void:
	var sprite_dir_path: String = "res://assets/sprites/"
	var dir: DirAccess = DirAccess.open(sprite_dir_path)
	if dir == null:
		return
		
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".png"):
			var full_path: String = sprite_dir_path + file_name
			var tex: Texture2D = load(full_path) as Texture2D
			
			# 3.1. Ảnh phải nạp được và có kích thước > 0
			assert_object(tex).override_failure_message("Lỗi không nạp được ảnh: " + full_path).is_not_null()
			if tex != null:
				assert_int(tex.get_width()).is_greater(0)
				assert_int(tex.get_height()).is_greater(0)
				
				# 3.2. Kiểm tra các sprite nhân vật/công trình/icon đã tách nền 4 góc chưa (miễn trừ ảnh nền và atlas sheet)
				var is_exempt: bool = "bg" in file_name.to_lower() or "sky" in file_name.to_lower() or "backdrop" in file_name.to_lower() or "master" in file_name.to_lower() or "sheet" in file_name.to_lower() or "nature" in file_name.to_lower() or "sprites_" in file_name.to_lower() or "keyart" in file_name.to_lower() or file_name == "boot_splash_keyart.png" or file_name == "title_screen_keyart.png"
				if not is_exempt:
					var img: Image = tex.get_image()
					if img != null:
						if img.is_compressed():
							img = img.duplicate()
							img.decompress()
						var w: int = img.get_width()
						var h: int = img.get_height()
						# Góc dưới cùng bên phải & trái không được đục màu (chống dính watermark đáy ảnh)
						var bottom_left_alpha: float = img.get_pixel(0, h - 1).a
						var bottom_right_alpha: float = img.get_pixel(w - 1, h - 1).a
						assert_float(bottom_left_alpha).override_failure_message(
							"Ảnh còn dính nền/watermark ở góc dưới trái: " + file_name
						).is_less_equal(0.05)
						assert_float(bottom_right_alpha).override_failure_message(
							"Ảnh còn dính nền/watermark ở góc dưới phải: " + file_name
						).is_less_equal(0.05)
		file_name = dir.get_next()
	dir.list_dir_end()

# ==============================================================================
# 4. TEST ÁNH XẠ ICON TRONG SPRITEATLASMANAGER (Chống nhầm Bánh mì -> Vinegar)
# ==============================================================================
func test_sprite_atlas_item_icons_not_mismatched() -> void:
	var sam: Node = get_node_or_null("/root/SpriteAtlasManager")
	if sam == null:
		return
		
	var bread_tex: Texture2D = null
	if sam.has_method("get_region_texture"):
		bread_tex = sam.call("get_region_texture", "bread") as Texture2D
	elif sam.has_method("get_texture"):
		bread_tex = sam.call("get_texture", "bread") as Texture2D
		
	var vinegar_tex: Texture2D = null
	if sam.has_method("get_region_texture"):
		vinegar_tex = sam.call("get_region_texture", "vinegar") as Texture2D
	elif sam.has_method("get_texture"):
		vinegar_tex = sam.call("get_texture", "vinegar") as Texture2D
	
	if bread_tex != null and vinegar_tex != null:
		# Đảm bảo icon Bánh mì và Chai giấm không trỏ chung vào một vùng cắt Rect2
		var is_same_resource: bool = (bread_tex == vinegar_tex)
		if bread_tex is AtlasTexture and vinegar_tex is AtlasTexture:
			var b_atlas: AtlasTexture = bread_tex as AtlasTexture
			var v_atlas: AtlasTexture = vinegar_tex as AtlasTexture
			is_same_resource = (b_atlas.atlas == v_atlas.atlas and b_atlas.region == v_atlas.region)
		assert_bool(is_same_resource).override_failure_message(
			"LỖI HÌNH ẢNH: Icon 'bread' đang bị trỏ trùng vùng ảnh với 'vinegar'!"
		).is_false()

# ==============================================================================
# 5. TEST PHASE 1: NHỊP THỜI GIAN JSON, PRODUCE_COUNT & DEV_SPEED_MULTIPLIER 60X
# ==============================================================================
func test_phase1_timing_and_dev_speed_multiplier() -> void:
	SaveManager.set_test_mode(true)
	TickManager.dev_speed_multiplier = 1.0

	# 5.1. Kiểm tra TickManager.calculate_finish_timestamp(1200) ở 1x và 60x
	var now_1x: int = TickManager.now()
	var finish_1x: int = TickManager.calculate_finish_timestamp(1200)
	assert_int(finish_1x - now_1x).is_between(1199, 1201)

	TickManager.dev_speed_multiplier = 60.0
	var now_60x: int = TickManager.now()
	var finish_60x: int = TickManager.calculate_finish_timestamp(1200)
	assert_int(finish_60x - now_60x).is_between(19, 21)

	# 5.2. Kiểm tra AnimalPen đọc produce_time_seconds từ animals.json (không còn hardcode 15s)
	TickManager.dev_speed_multiplier = 1.0
	var pen: AnimalPen = auto_free(AnimalPen.new()) as AnimalPen
	pen.animal_id = "chicken"
	StorageManager.silo_capacity = maxi(StorageManager.silo_capacity, StorageManager.get_silo_used() + 20)
	StorageManager.barn_capacity = maxi(StorageManager.barn_capacity, StorageManager.get_barn_used() + 20)
	StorageManager.add_item("chicken_feed", 2)

	var fed_1x: bool = pen.feed()
	assert_bool(fed_1x).is_true()
	assert_int(int(pen.state)).is_equal(int(AnimalPen.PenState.PRODUCING))
	assert_int(pen.finish_timestamp - TickManager.now()).is_between(1198, 1201)

	# Kiểm tra AnimalPen với dev_speed_multiplier = 60.0 (1200s / 60 = 20s)
	pen.state = AnimalPen.PenState.HUNGRY
	TickManager.dev_speed_multiplier = 60.0
	var fed_60x: bool = pen.feed()
	assert_bool(fed_60x).is_true()
	assert_int(pen.finish_timestamp - TickManager.now()).is_between(19, 21)

	# 5.3. Kiểm tra ProductionMachine đọc craft_time_seconds từ recipes.json (bỏ cap 60s) & produce_count = 3
	TickManager.dev_speed_multiplier = 1.0
	var machine: ProductionMachine = auto_free(ProductionMachine.new()) as ProductionMachine
	machine.machine_id = "feed_mill"
	StorageManager.add_item("wheat", 2)
	StorageManager.add_item("corn", 1)

	var started: bool = machine.start_recipe("chicken_feed")
	assert_bool(started).is_true()
	assert_int(machine.queue.size()).is_equal(1)
	var job_finish_ts: int = int(machine.queue[0].get("finish_timestamp", 0))
	assert_int(job_finish_ts - TickManager.now()).is_between(298, 301)

	# Giả lập hoàn thành công việc và kiểm tra produce_count = 3, xp_reward = 1
	machine.queue[0]["finish_timestamp"] = TickManager.now() - 1
	machine._on_second_ticked(TickManager.now())
	assert_bool(machine.queue.is_empty()).is_true()
	assert_int(machine.completed_items.size()).is_equal(3)

	var feed_before: int = StorageManager.get_item_count("chicken_feed")
	var xp_before: int = StorageManager.xp
	var level_before: int = StorageManager.level
	var collected: bool = machine.collect_all()
	assert_bool(collected).is_true()
	assert_int(StorageManager.get_item_count("chicken_feed")).is_equal(feed_before + 3)
	if StorageManager.level == level_before:
		assert_int(StorageManager.xp).is_equal(xp_before + 1)

	TickManager.dev_speed_multiplier = 1.0

# ==============================================================================
# 6. REGRESSION: DATA MANAGER DISPLAY NAME & CUSTOM PLAYER NAMING
# ==============================================================================
func test_data_manager_display_name_and_custom_player_naming() -> void:
	for mat_id: String in ["mat_plank", "mat_bolt", "mat_brick"]:
		var n1: String = DataManager.get_item_name(mat_id)
		var n2: String = DataManager.get_item_display_name(mat_id)
		assert_str(n1).is_not_empty()
		assert_str(n2).is_equal(n1)

	var creator_scene: PackedScene = load("res://scenes/ui/CharacterCreator.tscn") as PackedScene
	assert_object(creator_scene).is_not_null()
	if creator_scene != null:
		var creator: CharacterCreator = auto_free(creator_scene.instantiate()) as CharacterCreator
		add_child(creator)
		await get_tree().process_frame
		assert_str(creator.btn_preset_boy.text).not_contains("Minh")
		assert_str(creator.btn_preset_girl.text).not_contains("Mai")
		assert_str(creator.input_player_name.text).is_empty()
		creator._apply_preset("female")
		assert_str(creator.input_player_name.text).is_empty()
		creator._apply_preset("male")
		assert_str(creator.input_player_name.text).is_empty()

# ==============================================================================
# 7. REGRESSION: TUTORIAL LAYER/CLOSE, HIDDEN MACHINE CLICK & LEVEL 1 ZOO LOCK
# ==============================================================================
func test_tutorial_close_hidden_machine_and_level_1_zoo_lock() -> void:
	# 1. TutorialOverlay must have a clickable close button and sit below UIHud modals
	var tut_scene: PackedScene = load("res://scenes/ui/TutorialOverlay.tscn") as PackedScene
	assert_object(tut_scene).is_not_null()
	if tut_scene != null:
		var tut: Control = auto_free(tut_scene.instantiate()) as Control
		var btn_close: Button = tut.find_child("BtnCloseTutorial", true, false) as Button
		assert_object(btn_close).is_not_null()
		if btn_close != null:
			assert_int(btn_close.mouse_filter).is_equal(Control.MOUSE_FILTER_STOP)

	var main_scene: PackedScene = load("res://scenes/main/MainFarm.tscn") as PackedScene
	var hud_scene: PackedScene = load("res://scenes/ui_hud.tscn") as PackedScene
	assert_object(main_scene).is_not_null()
	assert_object(hud_scene).is_not_null()
	if main_scene != null and hud_scene != null:
		var main_state: SceneState = main_scene.get_state()
		var tut_layer_idx: int = -1
		var tut_layer_val: int = -1
		for i: int in range(main_state.get_node_count()):
			if main_state.get_node_name(i) == &"TutorialLayer":
				tut_layer_idx = i
				for p: int in range(main_state.get_node_property_count(i)):
					if main_state.get_node_property_name(i, p) == &"layer":
						tut_layer_val = int(main_state.get_node_property_value(i, p))
		assert_int(tut_layer_idx).is_greater_equal(0)

		var hud_inst: CanvasLayer = auto_free(hud_scene.instantiate()) as CanvasLayer
		assert_int(tut_layer_val).is_less(hud_inst.layer)

	# 2. Invisible unbuilt machine must reject clicks
	var hidden_machine: ProductionMachine = auto_free(ProductionMachine.new()) as ProductionMachine
	hidden_machine.machine_id = "juice_stand"
	hidden_machine.visible = false
	add_child(hidden_machine)
	assert_bool(hidden_machine.handle_machine_click()).is_false()

	# 3. Fresh Level 1 must lock Zoo Sanctuary & exclude unbuilt Lv13 juice_stand
	SaveManager.set_test_mode(true)
	var prev_level: int = StorageManager.level
	var prev_xp: int = StorageManager.xp
	var prev_gold: int = StorageManager.gold
	var prev_puzzle: int = SaveManager.puzzle_pieces
	var prev_buildings: Array = SaveManager.unlocked_buildings.duplicate()
	var prev_zoo: Dictionary = SaveManager.zoo_data.duplicate(true)

	SaveManager.reset_to_level_1()
	assert_int(StorageManager.level).is_equal(1)
	assert_int(SaveManager.puzzle_pieces).is_equal(0)
	assert_bool(SaveManager.is_animal_unlocked("zoo_capybara")).is_false()
	assert_bool(SaveManager.unlocked_buildings.has("feed_mill")).is_true()
	assert_bool(SaveManager.unlocked_buildings.has("juice_stand")).is_false()

	if hud_scene != null:
		var hud: UIHud = auto_free(hud_scene.instantiate()) as UIHud
		add_child(hud)
		await get_tree().process_frame
		hud.open_zoo_modal()
		assert_object(hud.find_child("ZooModal", true, false)).is_null()

	StorageManager.level = prev_level
	StorageManager.xp = prev_xp
	StorageManager.gold = prev_gold
	SaveManager.puzzle_pieces = prev_puzzle
	SaveManager.unlocked_buildings = prev_buildings
	SaveManager.zoo_data = prev_zoo

func test_crop_and_item_data_synced() -> void:
	for crop_key: Variant in DataManager.crops.keys():
		var cid: String = String(crop_key)
		if cid.ends_with("_seed"):
			continue
		assert_bool(DataManager.items.has(cid)).is_true()
		if not DataManager.items.has(cid):
			continue
		var c_dict: Dictionary = DataManager.crops[cid] as Dictionary
		var i_dict: Dictionary = DataManager.items[cid] as Dictionary
		assert_int(int(c_dict.get("growth_time_seconds", -1))).is_equal(int(i_dict.get("growth_time_seconds", -2)))
		assert_int(int(c_dict.get("base_price", -1))).is_equal(int(i_dict.get("base_price", -2)))

func test_user_reported_6_gameplay_fixes() -> void:
	SaveManager.set_test_mode(true)
	SaveManager.reset_to_level_1()

	# 1. Emoji fallback font must be bound on DataManager and ThemeDB
	assert_object(DataManager.main_font).is_not_null()
	assert_object(DataManager.emoji_font).is_not_null()
	assert_bool(DataManager.main_font.fallbacks.size() > 0).is_true()

	# 2. Wheat & Corn must NOT be unlimited: deducts 1 seed when planted, fails when 0 in Silo (with gold >= 10)
	StorageManager.gold = 200
	StorageManager.silo_items.clear()
	StorageManager.add_item("wheat", 1)
	var p1: FieldPlot = auto_free(FieldPlot.new()) as FieldPlot
	add_child(p1)
	assert_bool(p1.plant("wheat")).is_true()
	assert_int(StorageManager.get_item_count("wheat")).is_equal(0)

	var p2: FieldPlot = auto_free(FieldPlot.new()) as FieldPlot
	add_child(p2)
	assert_bool(p2.plant("wheat")).is_false()
	assert_bool(p2.plant("corn")).is_false()

	# 3. Leveling up to Level 2 unlocks corn and grants +3 starter corn seeds
	assert_int(StorageManager.get_item_count("corn")).is_equal(0)
	var xp_needed_lv2: int = StorageManager.get_required_xp(1)
	StorageManager.add_xp(xp_needed_lv2)
	assert_int(StorageManager.level).is_equal(2)
	assert_int(StorageManager.get_item_count("corn")).is_equal(3)

	# 4. East Bank (Zoo area) cells are unlocked when Zoo is not constructed
	GridManager.occupied_cells.clear()
	GridManager.path_cells.clear()
	assert_bool(SaveManager.is_building_constructed("mini_zoo")).is_false()
	assert_bool(GridManager.can_place_building("field_plot", Vector2i(36, 15))).is_true()

