extends GdUnitTestSuite

func _cleanup_farm(farm: Node) -> void:
	if farm != null and is_instance_valid(farm):
		var parent: Node = farm.get_parent()
		if parent != null:
			parent.remove_child(farm)
		farm.queue_free()

func test_east_bank_overlap_documentation() -> void:
	SaveManager.set_test_mode(true)
	SaveManager.reset_to_level_1()
	StorageManager.level = 11
	StorageManager.gold = 20000
	SaveManager.add_puzzle_pieces(50)

	var main_farm_scene: PackedScene = load("res://scenes/main/MainFarm.tscn") as PackedScene
	var farm1: MainFarm = main_farm_scene.instantiate() as MainFarm
	get_tree().root.add_child(farm1)
	await get_tree().process_frame

	# (a) Place field_plot inside Capybara zone (center ~ (1340, 210), size 192x128) before mini_zoo is built
	var capy_center: Vector2 = Vector2(1340.0, 210.0)
	var capy_cell: Vector2i = GridManager.world_to_grid(capy_center)
	farm1.drag_action_manager.set_tool(DragActionManager.ToolType.BUILD_FIELD)
	farm1.drag_action_manager._handle_build_field(capy_cell)
	farm1.drag_action_manager.set_tool(DragActionManager.ToolType.NONE)
	assert_bool(farm1.field_plots.has(capy_cell)).is_true()

	# (b) Build mini_zoo and unlock Capybara enclosure via real placement flow
	var zoo_cell: Vector2i = Vector2i(36, 9)
	farm1.start_building_placement("mini_zoo")
	farm1._handle_building_placement_click(GridManager.grid_to_world(zoo_cell))
	if not SaveManager.is_animal_unlocked("zoo_capybara"):
		SaveManager.unlock_animal("zoo_capybara")
	if farm1.zoo_manager != null and farm1.zoo_manager.has_method("refresh_zoo_grid_state"):
		farm1.zoo_manager.refresh_zoo_grid_state()
	await get_tree().process_frame

	# (c) Record state for field_plot overlap
	var plot_exists: bool = farm1.field_plots.has(capy_cell)
	var plot_node: FieldPlot = farm1.field_plots.get(capy_cell, null) as FieldPlot
	var capy_enc: Node2D = farm1.zoo_manager.enclosures.get("zoo_capybara", null) as Node2D
	var capy_visible: bool = capy_enc != null and is_instance_valid(capy_enc) and capy_enc.visible
	var capy_rect: Rect2 = Rect2(capy_center - Vector2(96.0, 64.0), Vector2(192.0, 128.0))
	var plot_overlaps_capy: bool = plot_node != null and capy_rect.has_point(plot_node.global_position)
	var cell_solid: bool = GridManager.astar_grid.is_point_solid(capy_cell)
	var walk_path: Array[Vector2] = farm1.walk_grid.find_path(Vector2(1170.0, 310.0), capy_center) if farm1.walk_grid != null else []
	print("[OVERLAP_REPORT_FIELD] cell=", capy_cell, " plot_exists=", plot_exists, " plot_overlaps_capy=", plot_overlaps_capy, " capy_visible=", capy_visible, " astar_solid=", cell_solid, " walk_path_len=", walk_path.size())

	assert_bool(plot_exists).is_true()
	assert_bool(capy_visible).is_true()

	_cleanup_farm(farm1)
	await get_tree().process_frame

	# (d) Repeat with pig_pen instead of field_plot
	SaveManager.reset_to_level_1()
	StorageManager.level = 11
	StorageManager.gold = 20000
	SaveManager.add_puzzle_pieces(50)

	var farm2: MainFarm = main_farm_scene.instantiate() as MainFarm
	get_tree().root.add_child(farm2)
	await get_tree().process_frame

	var pig_cell: Vector2i = Vector2i(40, 5)
	farm2.start_building_placement("pig_pen")
	farm2._handle_building_placement_click(GridManager.grid_to_world(pig_cell))

	var placed_pig: AnimalPen = null
	for pen: AnimalPen in farm2._animal_pens:
		if is_instance_valid(pen) and pen.animal_id == "pig" and pen.visible:
			placed_pig = pen
			break
	assert_object(placed_pig).is_not_null()
	assert_bool(placed_pig.grid_pos == pig_cell).is_true()

	farm2.start_building_placement("mini_zoo")
	farm2._handle_building_placement_click(GridManager.grid_to_world(zoo_cell))
	if not SaveManager.is_animal_unlocked("zoo_capybara"):
		SaveManager.unlock_animal("zoo_capybara")
	if farm2.zoo_manager != null and farm2.zoo_manager.has_method("refresh_zoo_grid_state"):
		farm2.zoo_manager.refresh_zoo_grid_state()
	await get_tree().process_frame

	var capy_enc2: Node2D = farm2.zoo_manager.enclosures.get("zoo_capybara", null) as Node2D
	var pig_rect: Rect2 = Rect2(Vector2(float(pig_cell.x) * 32.0, float(pig_cell.y) * 32.0), Vector2(128.0, 96.0))
	var pig_overlaps_capy: bool = pig_rect.intersects(capy_rect)
	var pig_walk_path: Array[Vector2] = farm2.walk_grid.find_path(Vector2(1170.0, 310.0), placed_pig.global_position) if farm2.walk_grid != null else []
	print("[OVERLAP_REPORT_PIG_BEFORE_SAVE] pig_pos=", placed_pig.grid_pos, " pig_visible=", placed_pig.visible, " capy_visible=", (capy_enc2 != null and capy_enc2.visible), " pig_overlaps_capy=", pig_overlaps_capy, " walk_path_len=", pig_walk_path.size())

	# (e) Save, free MainFarm, load, instantiate new MainFarm, record state
	SaveManager.save_game()
	_cleanup_farm(farm2)
	await get_tree().process_frame

	assert_bool(SaveManager.load_game()).is_true()
	var farm3: MainFarm = main_farm_scene.instantiate() as MainFarm
	get_tree().root.add_child(farm3)
	await get_tree().process_frame

	var reloaded_pig: AnimalPen = null
	for pen: AnimalPen in farm3._animal_pens:
		if is_instance_valid(pen) and pen.animal_id == "pig" and pen.visible:
			reloaded_pig = pen
			break
	var capy_enc3: Node2D = farm3.zoo_manager.enclosures.get("zoo_capybara", null) as Node2D
	var reloaded_capy_vis: bool = capy_enc3 != null and is_instance_valid(capy_enc3) and capy_enc3.visible
	print("[OVERLAP_REPORT_PIG_AFTER_RELOAD] pig_found=", (reloaded_pig != null), " pig_pos=", (reloaded_pig.grid_pos if reloaded_pig != null else Vector2i(-1, -1)), " capy_visible=", reloaded_capy_vis)

	assert_object(reloaded_pig).is_not_null()
	assert_bool(reloaded_pig.grid_pos == pig_cell).is_true()
	assert_bool(reloaded_capy_vis).is_true()

	_cleanup_farm(farm3)
	await get_tree().process_frame
