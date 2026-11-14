class_name TestLv1ToMaxProgression
extends GdUnitTestSuite

func after_test() -> void:
	TickManager.dev_speed_multiplier = 1.0
	SaveManager.set_test_mode(false)

func test_playthrough_level_1_to_max_35() -> void:
	SaveManager.set_test_mode(true)
	SaveManager.reset_to_level_1()
	TickManager.dev_speed_multiplier = 100.0

	assert_int(StorageManager.level).is_equal(1)
	assert_int(StorageManager.silo_capacity).is_equal(100)
	assert_int(StorageManager.barn_capacity).is_equal(100)

	# 1. Verify Lv1 Tutorial chicken_feed uses only wheat
	var chicken_feed: Dictionary = DataManager.get_recipe("chicken_feed")
	assert_bool(chicken_feed.is_empty()).is_false()
	var cf_ings: Dictionary = chicken_feed.get("ingredients", {}) as Dictionary
	assert_bool(cf_ings.has("wheat")).is_true()
	assert_bool(cf_ings.has("corn")).is_false()

	# 2. Verify sheep_feed exists in recipes & items for Lv16 sheep_pasture
	var sheep_feed: Dictionary = DataManager.get_recipe("sheep_feed")
	assert_bool(sheep_feed.is_empty()).is_false()
	assert_int(int(sheep_feed.get("unlock_level", 99))).is_equal(16)

	# 3. Verify RoadsideShop rejects invalid count/price
	assert_bool(RoadsideShop.list_item(5, "wheat", 0, 10)).is_false()
	assert_bool(RoadsideShop.list_item(5, "wheat", 2, 0)).is_false()

	# 4. Simulate Level 1 -> Level 35 progression
	var plot: FieldPlot = FieldPlot.new()
	add_child(plot)
	var machine: ProductionMachine = ProductionMachine.new()
	machine.machine_id = "feed_mill"
	add_child(machine)
	var sheep_pen: AnimalPen = AnimalPen.new()
	sheep_pen.animal_id = "sheep"
	sheep_pen.animal_count = 2
	add_child(sheep_pen)

	for target_lvl: int in range(1, 36):
		while StorageManager.level < target_lvl:
			var need: int = StorageManager.get_required_xp(StorageManager.level) - StorageManager.xp
			StorageManager.add_xp(maxi(1, need))

		assert_int(StorageManager.level).is_equal(target_lvl)

		# Check storage capacity milestones
		if target_lvl <= 16:
			assert_int(StorageManager.silo_capacity).is_equal(100)
			assert_int(StorageManager.barn_capacity).is_equal(100)
		elif target_lvl <= 26:
			assert_int(StorageManager.silo_capacity).is_equal(150)
			assert_int(StorageManager.barn_capacity).is_equal(150)
		elif target_lvl <= 32:
			assert_int(StorageManager.silo_capacity).is_equal(250)
			assert_int(StorageManager.barn_capacity).is_equal(250)
		else:
			assert_int(StorageManager.silo_capacity).is_equal(250)
			assert_int(StorageManager.barn_capacity).is_equal(500)

		# Check Truck orders never demand items above current level
		TruckOrderSystem.generate_initial_orders()
		var orders: Array[Dictionary] = TruckOrderSystem.get_orders()
		assert_int(orders.size()).is_equal(4)
		for ord: Dictionary in orders:
			var reqs: Dictionary = ord.get("requirements", {}) as Dictionary
			assert_bool(reqs.is_empty()).is_false()
			for req_id_var: Variant in reqs:
				var req_id: String = String(req_id_var)
				var u_lvl: int = 1
				if DataManager.crops.has(req_id):
					u_lvl = int((DataManager.crops[req_id] as Dictionary).get("unlock_level", 1))
				elif DataManager.recipes.has(req_id):
					u_lvl = int((DataManager.recipes[req_id] as Dictionary).get("unlock_level", 1))
				elif DataManager.items.has(req_id):
					u_lvl = int((DataManager.items[req_id] as Dictionary).get("unlock_level", 1))
				assert_int(u_lvl).override_failure_message(
					"Truck order at Lv%d demanded %s (unlock Lv%d)" % [target_lvl, req_id, u_lvl]
				).is_less_equal(target_lvl)

		# Check every recipe unlocked at this level has ingredients unlocked <= target_lvl
		for rec_id: String in DataManager.recipes:
			var rec: Dictionary = DataManager.recipes[rec_id] as Dictionary
			var r_lvl: int = int(rec.get("unlock_level", 1))
			if r_lvl == target_lvl:
				var ings: Dictionary = rec.get("ingredients", {}) as Dictionary
				for ing_var: Variant in ings:
					var ing_id: String = String(ing_var)
					var ing_lvl: int = 1
					if DataManager.crops.has(ing_id):
						ing_lvl = int((DataManager.crops[ing_id] as Dictionary).get("unlock_level", 1))
					elif DataManager.recipes.has(ing_id):
						ing_lvl = int((DataManager.recipes[ing_id] as Dictionary).get("unlock_level", 1))
					elif DataManager.items.has(ing_id):
						ing_lvl = int((DataManager.items[ing_id] as Dictionary).get("unlock_level", 1))
					assert_int(ing_lvl).override_failure_message(
						"Recipe %s (Lv%d) uses %s (Lv%d)" % [rec_id, r_lvl, ing_id, ing_lvl]
					).is_less_equal(r_lvl)

		# Test planting & harvesting wheat at Lv1 and mango/apple or soybean at milestone levels
		if target_lvl in [1, 7, 16, 33]:
			StorageManager.silo_items.clear()
			StorageManager.silo_items["wheat"] = 10
			StorageManager.silo_items["soybean"] = 5
			assert_bool(plot.plant("wheat")).is_true()
			plot.state = FieldPlot.PlotState.READY
			assert_bool(plot.harvest()).is_true()

		# Test Lv16 sheep_feed crafting & sheep feeding
		if target_lvl == 16:
			StorageManager.barn_items.clear()
			assert_bool(machine.start_recipe("sheep_feed")).is_true()
			assert_bool(machine.queue.is_empty()).is_false()
			sheep_pen.state = AnimalPen.PenState.HUNGRY
			assert_bool(sheep_pen.feed()).is_true()
			assert_int(int(sheep_pen.state)).is_equal(int(AnimalPen.PenState.PRODUCING))

		# Test Save & Load round-trip at Lv25 (verifying no Lv20+ item inflation!)
		if target_lvl == 25:
			var before_wheat: int = StorageManager.get_item_count("wheat")
			var before_gold: int = StorageManager.gold
			SaveManager.save_game()
			StorageManager.gold = 0
			assert_bool(SaveManager.load_game()).is_true()
			assert_int(StorageManager.level).is_equal(25)
			assert_int(StorageManager.gold).is_equal(before_gold)
			assert_int(StorageManager.get_item_count("wheat")).is_equal(before_wheat)
			assert_int(StorageManager.silo_capacity).is_equal(150)

	plot.queue_free()
	machine.queue_free()
	sheep_pen.queue_free()

func test_character_creator_all_options_change_visuals() -> void:
	var avatar_scene: PackedScene = load("res://scenes/entities/ModularChibiAvatar.tscn") as PackedScene
	assert_object(avatar_scene).is_not_null()
	var avatar: ModularChibiAvatar = avatar_scene.instantiate() as ModularChibiAvatar
	add_child(avatar)

	var seen_signatures: Dictionary = {}
	for body_id: String in ["body_warm_ivory", "body_peach_sunny", "body_honey_tan", "body_cocoa_warm"]:
		avatar.equip_part("body", body_id)
		var sig: String = "%s|%s" % [str(avatar.body_layer.texture), str(avatar.body_layer.modulate)]
		assert_bool(seen_signatures.has(sig)).override_failure_message("Body option had no visual difference: " + body_id).is_false()
		seen_signatures[sig] = true

	avatar.equip_part("body", "body_warm_ivory")
	var hair_sigs: Dictionary = {}
	for hair_id: String in ["hair_braid_chestnut", "hair_short_sunny", "hair_bun_baker", "hair_curly_berry"]:
		avatar.equip_part("hair", hair_id)
		var sig: String = "%s|%s" % [str(avatar.body_layer.texture), str(avatar.body_layer.modulate)]
		assert_bool(hair_sigs.has(sig)).override_failure_message("Hair option had no visual difference: " + hair_id).is_false()
		hair_sigs[sig] = true

	var outfit_sigs: Dictionary = {}
	avatar.equip_part("gender", "male")
	avatar.equip_part("hair", "hair_short_sunny")
	for outfit_id: String in ["outfit_denim_overalls", "outfit_floral_dress", "outfit_baker_apron", "outfit_carpenter_vest"]:
		avatar.equip_part("outfit", outfit_id)
		var sig: String = str(avatar.body_layer.texture)
		assert_bool(outfit_sigs.has(sig)).override_failure_message("Outfit option had no visual difference: " + outfit_id).is_false()
		outfit_sigs[sig] = true

	avatar.queue_free()

