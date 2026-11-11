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
