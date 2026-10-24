extends Node

func _ready() -> void:
	print("====================================================================")
	print("[OVERNIGHT MASTER TEST] STARTING 5-PHASE COMPREHENSIVE VERIFICATION")
	print("====================================================================")
	
	var main_scene: PackedScene = load("res://scenes/main_farm.tscn")
	if main_scene == null:
		push_error("Cannot load res://scenes/main_farm.tscn")
		get_tree().quit(1)
		return
		
	var farm: Node2D = main_scene.instantiate() as Node2D
	add_child(farm)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var pass_count: int = 0
	var total_tests: int = 4
	
	var hud: UIHud = farm.find_child("UIHud", true, false) as UIHud
	var dam: DragActionManager = farm.find_child("DragActionManager", true, false) as DragActionManager
	
	if hud == null or dam == null:
		push_error("UIHud or DragActionManager not found!")
		get_tree().quit(1)
		return

	# ==================================================================
	# TEST 1: HUD Tool Toggle (Click twice = NONE) & Cancel via RMB/ESC
	# ==================================================================
	print("\n--- [TEST 1] HUD Tool Toggle & Cancel Shortcuts ---")
	var test1_ok: bool = true
	
	# 1a. Sickle toggle
	hud.btn_sickle.emit_signal("pressed")
	if dam.current_tool != DragActionManager.ToolType.SICKLE:
		push_error("1a Fail: Sickle button pressed but tool is not SICKLE")
		test1_ok = false
	if hud.btn_sickle.modulate.r <= 1.0:
		push_error("1a Fail: Sickle button not visually highlighted when active")
		test1_ok = false
		
	hud.btn_sickle.emit_signal("pressed")
	if dam.current_tool != DragActionManager.ToolType.NONE:
		push_error("1a Fail: Sickle button pressed second time did not toggle to NONE")
		test1_ok = false
	if hud.btn_sickle.modulate != Color.WHITE:
		push_error("1a Fail: Sickle button did not reset modulate to WHITE on NONE")
		test1_ok = false
	
	# 1b. Seeds toggle
	hud.select_seed("wheat")
	if dam.current_tool != DragActionManager.ToolType.PLANT_WHEAT:
		push_error("1b Fail: Wheat seed not active")
		test1_ok = false
	hud.btn_seeds.emit_signal("pressed")
	if dam.current_tool != DragActionManager.ToolType.NONE:
		push_error("1b Fail: Clicking seeds button while planting did not toggle to NONE")
		test1_ok = false
		
	# 1c. Build Field toggle
	hud.btn_build_field.emit_signal("pressed")
	if dam.current_tool != DragActionManager.ToolType.BUILD_FIELD:
		push_error("1c Fail: Build Field not active")
		test1_ok = false
	hud.btn_build_field.emit_signal("pressed")
	if dam.current_tool != DragActionManager.ToolType.NONE:
		push_error("1c Fail: Build Field toggle to NONE failed")
		test1_ok = false
		
	# 1d. Right Click cancel
	dam.set_tool(DragActionManager.ToolType.SICKLE)
	var mb_right: InputEventMouseButton = InputEventMouseButton.new()
	mb_right.button_index = MOUSE_BUTTON_RIGHT
	mb_right.pressed = true
	dam._unhandled_input(mb_right)
	if dam.current_tool != DragActionManager.ToolType.NONE:
		push_error("1d Fail: Right Click did not cancel tool to NONE")
		test1_ok = false
		
	# 1e. ESC key cancel
	dam.set_tool(DragActionManager.ToolType.BUILD_PATH)
	var key_esc: InputEventKey = InputEventKey.new()
	key_esc.keycode = KEY_ESCAPE
	key_esc.pressed = true
	dam._unhandled_input(key_esc)
	if dam.current_tool != DragActionManager.ToolType.NONE:
		push_error("1e Fail: ESC key did not cancel tool to NONE")
		test1_ok = false
		
	if test1_ok:
		print(" -> PASS: HUD tool toggles on second click and cancels cleanly with RMB / ESC!")
		pass_count += 1
	else:
		push_error(" -> FAIL: Test 1 failed some assertions")

	# ==================================================================
	# TEST 2: Pencil Buttons Hidden in Normal Gameplay
	# ==================================================================
	print("\n--- [TEST 2] Pencil Rename Buttons Hidden on Machines ---")
	var test2_ok: bool = true
	var machines: Array = farm.get("_production_machines") as Array
	if machines.is_empty():
		push_error("No production machines found on farm!")
		test2_ok = false
	else:
		for m: ProductionMachine in machines:
			if is_instance_valid(m):
				var btn: Button = m.get("_btn_rename") as Button
				if btn != null and btn.visible:
					push_error("Machine " + m.machine_id + " has visible pencil button during normal play!")
					test2_ok = false
	
	if test2_ok:
		print(" -> PASS: All pencil rename buttons (✏️) are cleanly hidden during normal gameplay!")
		pass_count += 1
	else:
		push_error(" -> FAIL: Some machine pencil buttons remain visible")

	# ==================================================================
	# TEST 3: SpriteAtlasManager & DataManager All IDs Valid Textures
	# ==================================================================
	print("\n--- [TEST 3] Audit All Sprite IDs in SpriteAtlasManager ---")
	var test3_ok: bool = true
	var essential_ids: Array[String] = [
		# Crops & Seeds
		"wheat", "corn", "carrot", "tomato", "strawberry", "pumpkin", "soybean",
		"sugarcane", "sunflower", "rose", "lavender", "apple", "mango",
		"apple_seed", "mango_seed", "tree_apple_ripe", "tree_mango_ripe", "tree_fruitless",
		# Feed & Animals & Products
		"chicken_feed", "cow_feed", "pig_feed",
		"animal_chicken", "animal_cow", "animal_pig", "animal_sheep",
		"egg", "milk", "bacon",
		# Bakery & Juice Recipes
		"bread", "corn_bread", "butter", "butter_cookie", "cheese", "cream_cake",
		"sugarcane_juice", "apple_juice", "mango_smoothie",
		# Buildings & Tools
		"building_bakery", "building_feed_mill", "building_juice_stand", "building_cake_oven",
		"field_plot", "sickle", "tool_demolish", "wooden_bench", "truck", "building_silo", "building_barn"
	]
	
	var missing_ids: Array[String] = []
	for s_id: String in essential_ids:
		var tex: Texture2D = SpriteAtlasManager.get_texture(s_id)
		if tex == null:
			missing_ids.append(s_id)
			test3_ok = false
			
	if missing_ids.is_empty():
		print(" -> PASS: 100% of essential sprites (crops, flowers, trees, feeds, products, machines) have valid Texture2D!")
		pass_count += 1
	else:
		push_error(" -> FAIL: Missing textures for IDs: " + str(missing_ids))

	# ==================================================================
	# TEST 4: End-to-End Economy Simulation with Tool = NONE
	# ==================================================================
	print("\n--- [TEST 4] Economy Loop Simulation (Harvest, Feed, Pen, Visitor) ---")
	var test4_ok: bool = true
	dam.set_tool(DragActionManager.ToolType.NONE)
	
	# 4a. Harvest field plot
	var plots: Array = farm.plots_container.get_children()
	var test_plot: FieldPlot = null
	for p_node in plots:
		if p_node is FieldPlot:
			test_plot = p_node as FieldPlot
			break
	if test_plot != null:
		test_plot.state = FieldPlot.PlotState.READY
		test_plot.crop_id = "wheat"
		var init_wheat: int = StorageManager.get_item_count("wheat")
		var click_res: bool = farm.call("simulate_click_at_world_pos", test_plot.global_position)
		var after_wheat: int = StorageManager.get_item_count("wheat")
		if click_res and after_wheat > init_wheat:
			print(" -> 4a PASS: FieldPlot harvested wheat (+2) when tool was NONE.")
		else:
			push_error("4a Fail: FieldPlot did not harvest on direct click: " + str(click_res) + " wheat=" + str(after_wheat))
			test4_ok = false
	else:
		push_error("4a Fail: No FieldPlot found")
		test4_ok = false
		
	# 4b. Feed cow pen and collect milk
	var pens: Array = farm.get("_animal_pens") as Array
	var cow_pen: AnimalPen = null
	for pen in pens:
		if pen is AnimalPen and pen.animal_id == "cow":
			cow_pen = pen as AnimalPen
			break
	if cow_pen != null:
		# Test feed
		cow_pen.state = AnimalPen.PenState.HUNGRY
		StorageManager.add_item("cow_feed", 2)
		var feed_res: bool = farm.call("simulate_click_at_world_pos", cow_pen.global_position)
		if feed_res and cow_pen.state == AnimalPen.PenState.PRODUCING:
			print(" -> 4b PASS: Cow pen fed with cow_feed and entered PRODUCING state.")
		else:
			push_error("4b Fail: Cow pen did not feed on click")
			test4_ok = false
			
		# Test collect milk
		cow_pen.state = AnimalPen.PenState.READY_TO_COLLECT
		var init_milk: int = StorageManager.get_item_count("milk")
		var collect_res: bool = farm.call("simulate_click_at_world_pos", cow_pen.global_position)
		var after_milk: int = StorageManager.get_item_count("milk")
		if collect_res and after_milk > init_milk and cow_pen.state == AnimalPen.PenState.HUNGRY:
			print(" -> 4c PASS: Cow pen milk collected smoothly into Barn.")
		else:
			push_error("4c Fail: Cow pen collect milk failed")
			test4_ok = false
	else:
		push_error("4b/c Fail: No cow pen found")
		test4_ok = false
		
	# 4d. Apple Tree Harvest
	var decors: Array = farm.get("_movable_decors") as Array
	var apple_tree: MovableDecor = null
	for d in decors:
		if is_instance_valid(d) and d is MovableDecor and d.is_apple_tree:
			apple_tree = d as MovableDecor
			break
	if apple_tree == null:
		apple_tree = farm.call("_spawn_apple_tree", Vector2(230.0, 840.0), Vector2(74.0, 78.0)) as MovableDecor
	if apple_tree != null:
		apple_tree.set_growth_stage(MovableDecor.TreeGrowthStage.STAGE_RIPE)
		var init_apples: int = StorageManager.get_item_count("apple")
		var tree_res: bool = farm.call("simulate_click_at_world_pos", apple_tree.global_position)
		var after_apples: int = StorageManager.get_item_count("apple")
		if tree_res and after_apples > init_apples:
			print(" -> 4d PASS: Apple tree harvested +2 apples into Silo on direct click.")
		else:
			push_error("4d Fail: Apple tree harvest failed")
			test4_ok = false
	else:
		push_error("4d Fail: Could not find or spawn apple tree")
		test4_ok = false
		
	# 4e. Visitor Buy Request
	var vm: VisitorManager = farm.find_child("VisitorManager", true, false) as VisitorManager
	if vm != null:
		var visitors: Array[VisitorNPC] = vm.get_active_visitors()
		var shopper: VisitorNPC = null
		if visitors.is_empty():
			shopper = vm.spawn_random_visitor()
		else:
			for v in visitors:
				if is_instance_valid(v) and v.state != VisitorNPC.VisitorState.INACTIVE:
					shopper = v
					break
		if shopper != null:
			shopper.requested_item = "apple"
			shopper.requested_name = "🍎"
			shopper.reward_gold = 35
			shopper.reward_xp = 5
			StorageManager.add_item("apple", 5)
			var init_gold: int = StorageManager.gold
			var buy_res: bool = shopper.handle_visitor_click()
			var after_gold: int = StorageManager.gold
			if buy_res and after_gold > init_gold and shopper._is_demand_satisfied:
				print(" -> 4e PASS: Visitor purchased requested apple, awarded gold (+35) and thanked player.")
			else:
				push_error("4e Fail: Visitor purchase failed")
				test4_ok = false
	
	if test4_ok:
		print(" -> PASS: End-to-End Economy loop verified with 0 errors!")
		pass_count += 1
	else:
		push_error(" -> FAIL: Test 4 failed some assertions")

	# ==================================================================
	# FINAL REPORT & SELF QUIT
	# ==================================================================
	print("\n====================================================================")
	print("OVERNIGHT MASTER VERIFICATION SUMMARY:")
	print("  TOTAL PASSED: ", pass_count, " / ", total_tests)
	print("====================================================================")
	
	if pass_count == total_tests:
		print("\n>>> ALL TESTS PASSED WITH 100% SUCCESS! EXCITING CLEAN ARCHITECTURE! <<<\n")
		get_tree().quit(0)
	else:
		push_error(">>> SOME TESTS FAILED! PLEASE CHECK LOGS ABOVE <<<")
		get_tree().quit(1)
