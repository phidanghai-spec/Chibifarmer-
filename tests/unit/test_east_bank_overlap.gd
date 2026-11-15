extends GdUnitTestSuite

func _cleanup_farm(farm: Node) -> void:
	if farm != null and is_instance_valid(farm):
		var parent: Node = farm.get_parent()
		if parent != null:
			parent.remove_child(farm)
		farm.queue_free()

func test_east_bank_reserve_and_legacy_save_protection() -> void:
	SaveManager.set_test_mode(true)
	SaveManager.reset_to_level_1()
	StorageManager.level = 11
	StorageManager.gold = 20000
	SaveManager.add_puzzle_pieces(50)

	var main_farm_scene: PackedScene = load("res://scenes/main/MainFarm.tscn") as PackedScene
	var farm1: MainFarm = main_farm_scene.instantiate() as MainFarm
	get_tree().root.add_child(farm1)
	await get_tree().process_frame

	# (a) Place field_plot and pig_pen inside reserved Capybara zone -> rejected, nothing created
	var capy_cfg: Dictionary = DataManager.get_building("zoo_capybara")
	var capy_pos_arr: Array = capy_cfg.get("pos", [1340.0, 210.0]) as Array
	var capy_center: Vector2 = Vector2(float(capy_pos_arr[0]), float(capy_pos_arr[1]))
	var capy_cell: Vector2i = GridManager.world_to_grid(capy_center)
	assert_bool(GridManager.is_zoo_reserved_cell(capy_cell)).is_true()

	farm1.drag_action_manager.set_tool(DragActionManager.ToolType.BUILD_FIELD)
	farm1.drag_action_manager._handle_build_field(capy_cell)
	farm1.drag_action_manager.set_tool(DragActionManager.ToolType.NONE)
	assert_bool(farm1.field_plots.has(capy_cell)).is_false()

	var pig_cell: Vector2i = capy_cell - Vector2i(1, 1)
	farm1.start_building_placement("pig_pen")
	farm1._handle_building_placement_click(GridManager.grid_to_world(pig_cell))
	var placed_pig: AnimalPen = null
	for pen: AnimalPen in farm1._animal_pens:
		if is_instance_valid(pen) and pen.animal_id == "pig" and pen.visible:
			placed_pig = pen
			break
	assert_object(placed_pig).is_null()

	# (b) Place field_plot right outside reserved zone -> succeeds
	var outside_cell: Vector2i = Vector2i(36, 15)
	assert_bool(GridManager.is_zoo_reserved_cell(outside_cell)).is_false()
	farm1.drag_action_manager.set_tool(DragActionManager.ToolType.BUILD_FIELD)
	farm1.drag_action_manager._handle_build_field(outside_cell)
	farm1.drag_action_manager.set_tool(DragActionManager.ToolType.NONE)
	assert_bool(farm1.field_plots.has(outside_cell)).is_true()

	# (d) Verify all 4 enclosures and zoo_balloon reject new field_plot placement
	for zone_id: String in ["zoo_capybara", "zoo_panda", "zoo_penguin", "zoo_giraffe", "zoo_balloon"]:
		var z_cells: Array[Vector2i] = GridManager.get_zoo_reserved_cells_for_enclosure(zone_id)
		assert_int(z_cells.size()).is_greater(0)
		for zc: Vector2i in z_cells:
			assert_bool(GridManager.can_place_building("field_plot", zc)).is_false()

	# (c) Legacy save with a field_plot already inside Capybara zone:
	# Write directly into saved_plots_data & save_game(), then reload
	SaveManager.saved_plots_data.append({
		"grid_x": capy_cell.x,
		"grid_y": capy_cell.y,
		"state": 0,
		"crop_id": "",
		"plant_timestamp": 0,
		"finish_timestamp": 0,
		"time_left": 0.0
	})
	var original_plots: Dictionary = farm1.field_plots.duplicate()
	var legacy_plot: FieldPlot = FieldPlot.new()
	legacy_plot.grid_pos = capy_cell
	farm1.field_plots[capy_cell] = legacy_plot
	SaveManager.save_game()
	farm1.field_plots = original_plots
	legacy_plot.queue_free()
	_cleanup_farm(farm1)
	await get_tree().process_frame

	assert_bool(SaveManager.load_game()).is_true()
	var farm2: MainFarm = main_farm_scene.instantiate() as MainFarm
	get_tree().root.add_child(farm2)
	await get_tree().process_frame

	# Legacy plot must NOT be deleted on load
	assert_bool(farm2.field_plots.has(capy_cell)).is_true()
	# Trying to build mini_zoo / unlock Capybara must be blocked
	var chk_blocked: Dictionary = GridManager.can_unlock_zoo_zone("zoo_capybara")
	assert_bool(bool(chk_blocked.get("ok", true))).is_false()
	assert_bool((chk_blocked.get("obstacles", []) as Array).has("Ruộng")).is_true()
	farm2.start_building_placement("mini_zoo")
	farm2._handle_building_placement_click(GridManager.grid_to_world(Vector2i(36, 9)))
	assert_bool(SaveManager.is_building_constructed("mini_zoo")).is_false()

	# Dismantle legacy plot, then retry -> succeeds!
	farm2.drag_action_manager._handle_dismantle(capy_cell)
	assert_bool(farm2.field_plots.has(capy_cell)).is_false()
	var chk_clear: Dictionary = GridManager.can_unlock_zoo_zone("zoo_capybara")
	assert_bool(bool(chk_clear.get("ok", false))).is_true()

	farm2.start_building_placement("mini_zoo")
	farm2._handle_building_placement_click(GridManager.grid_to_world(Vector2i(36, 9)))
	assert_bool(SaveManager.is_building_constructed("mini_zoo")).is_true()
	assert_bool(SaveManager.is_animal_unlocked("zoo_capybara")).is_true()

	# Save and reload -> remains unlocked and clean
	SaveManager.save_game()
	_cleanup_farm(farm2)
	await get_tree().process_frame

	assert_bool(SaveManager.load_game()).is_true()
	var farm3: MainFarm = main_farm_scene.instantiate() as MainFarm
	get_tree().root.add_child(farm3)
	await get_tree().process_frame

	assert_bool(SaveManager.is_building_constructed("mini_zoo")).is_true()
	assert_bool(SaveManager.is_animal_unlocked("zoo_capybara")).is_true()
	assert_bool(farm3.field_plots.has(capy_cell)).is_false()

	_cleanup_farm(farm3)
	await get_tree().process_frame
