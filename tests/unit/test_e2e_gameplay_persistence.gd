extends GdUnitTestSuite
class_name TestE2EGameplayPersistence

const MAIN_FARM_SCENE_PATH: String = "res://scenes/main/MainFarm.tscn"

func _cleanup_farm(farm: Node2D) -> void:
	if farm != null and is_instance_valid(farm):
		if farm.get_parent() != null:
			farm.get_parent().remove_child(farm)
		farm.queue_free()

func test_e2e_build_gold_crop_seeds_east_bank_and_save_reload() -> void:
	SaveManager.set_test_mode(true)
	SaveManager.reset_to_level_1()
	GridManager.occupied_cells.clear()
	GridManager.placed_buildings.clear()
	GridManager.path_cells.clear()

	# 1. Instantiate MainFarm #1
	var scene: PackedScene = load(MAIN_FARM_SCENE_PATH) as PackedScene
	assert_object(scene).is_not_null()
	var farm1: MainFarm = scene.instantiate() as MainFarm
	assert_object(farm1).is_not_null()
	add_child(farm1)
	await get_tree().process_frame
	await get_tree().process_frame

	# 2. Lv1 Crop Seeds: wheat is finite, corn is 0 & cannot be planted
	var start_wheat: int = StorageManager.get_item_count("wheat")
	assert_int(start_wheat).is_greater(0)
	assert_int(StorageManager.get_item_count("corn")).is_equal(0)

	# Level up to Lv2 -> should grant +3 corn, +3 tomato, +3 sunflower
	StorageManager.add_xp(StorageManager.get_required_xp(1))
	assert_int(StorageManager.level).is_equal(2)
	assert_int(StorageManager.get_item_count("corn")).is_equal(3)

	# Give enough gold & level to test building pig_pen (unlock_level from buildings.json)
	var pig_info: Dictionary = DataManager.get_building("pig_pen")
	var pig_cost: int = int(pig_info.get("cost_gold", 220))
	var field_info: Dictionary = DataManager.get_building("field_plot")
	var field_cost: int = int(field_info.get("cost_gold", 10))
	StorageManager.gold = 2000
	var gold_before: int = StorageManager.gold

	# 3. East Bank must be unlocked before Zoo is built
	var east_plot_cell: Vector2i = Vector2i(36, 15)
	assert_bool(SaveManager.is_building_constructed("mini_zoo")).is_false()
	assert_bool(GridManager.can_place_building("field_plot", east_plot_cell)).is_true()

	# 4. Place FieldPlot via DragActionManager and verify gold deduction
	var dam: DragActionManager = farm1.drag_action_manager
	assert_object(dam).is_not_null()
	dam.set_tool(DragActionManager.ToolType.BUILD_FIELD)
	dam._handle_build_field(east_plot_cell)
	assert_int(StorageManager.gold).is_equal(gold_before - field_cost)
	assert_bool(farm1.field_plots.has(east_plot_cell)).is_true()

	# Plant corn in the newly placed East Bank plot
	var new_plot: FieldPlot = farm1.field_plots[east_plot_cell] as FieldPlot
	assert_object(new_plot).is_not_null()
	assert_bool(new_plot.plant("corn")).is_true()
	assert_int(StorageManager.get_item_count("corn")).is_equal(2)

	# 5. Place pig_pen via MainFarm.start_building_placement + _handle_building_placement_click
	var pig_cell: Vector2i = Vector2i(38, 16)
	var gold_before_pig: int = StorageManager.gold
	farm1.start_building_placement("pig_pen", pig_cost, {})
	farm1._handle_building_placement_click(GridManager.grid_to_world(pig_cell))
	assert_int(StorageManager.gold).is_equal(gold_before_pig - pig_cost)
	assert_bool(SaveManager.is_building_constructed("pig")).is_true()

	var placed_pig: AnimalPen = null
	for pen: AnimalPen in farm1._animal_pens:
		if is_instance_valid(pen) and pen.animal_id == "pig":
			placed_pig = pen
			break
	assert_object(placed_pig).is_not_null()
	assert_bool(placed_pig.visible).is_true()
	assert_bool(placed_pig.grid_pos == pig_cell).is_true()

	var expected_gold_after: int = StorageManager.gold

	# 6. Simulate Exit & Re-enter Game
	SaveManager.save_game()
	_cleanup_farm(farm1)
	await get_tree().process_frame

	# Wipe in-memory runtime state before load_game()
	GridManager.occupied_cells.clear()
	GridManager.placed_buildings.clear()
	GridManager.path_cells.clear()
	SaveManager.saved_plots_data.clear()
	SaveManager.saved_pens_data.clear()
	SaveManager.saved_paths_data.clear()
	SaveManager.saved_machines_data.clear()
	SaveManager.unlocked_buildings.clear()
	SaveManager.custom_building_positions.clear()
	StorageManager.gold = 0

	assert_bool(SaveManager.load_game()).is_true()
	assert_int(StorageManager.gold).is_equal(expected_gold_after)

	# Instantiate MainFarm #2
	var farm2: MainFarm = scene.instantiate() as MainFarm
	assert_object(farm2).is_not_null()
	add_child(farm2)
	await get_tree().process_frame
	await get_tree().process_frame

	# Verify placed FieldPlot & planted crop survived reload
	assert_bool(farm2.field_plots.has(east_plot_cell)).is_true()
	var reloaded_plot: FieldPlot = farm2.field_plots.get(east_plot_cell, null) as FieldPlot
	assert_object(reloaded_plot).is_not_null()
	assert_str(reloaded_plot.crop_id).is_equal("corn")
	assert_int(int(reloaded_plot.state)).is_equal(int(FieldPlot.PlotState.GROWING))

	# Verify placed pig_pen survived reload at the exact placed cell
	assert_bool(SaveManager.is_building_constructed("pig")).is_true()
	var reloaded_pig: AnimalPen = null
	for pen2: AnimalPen in farm2._animal_pens:
		if is_instance_valid(pen2) and pen2.animal_id == "pig":
			reloaded_pig = pen2
			break
	assert_object(reloaded_pig).is_not_null()
	assert_bool(reloaded_pig.visible).is_true()
	assert_bool(reloaded_pig.grid_pos == pig_cell).is_true()

	# 7. Verify all major UI modals open cleanly without script errors
	var hud: UIHud = farm2.ui_hud as UIHud
	assert_object(hud).is_not_null()
	hud.open_build_modal()
	hud.open_storage_popup("silo")
	hud.open_storage_popup("barn")
	hud.toggle_shop_popup()
	hud.toggle_truck_popup()
	hud.open_quests_modal()
	hud.open_settings_modal()

	_cleanup_farm(farm2)
	await get_tree().process_frame
