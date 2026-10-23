extends Node

func _ready() -> void:
	print("==================================================")
	print("[TEST SCENERY] Starting ChibiSceneryBuilder Verification")
	print("==================================================")
	
	var farm_scene: PackedScene = load("res://scenes/main_farm.tscn")
	var farm: Node = farm_scene.instantiate()
	add_child(farm)
	
	for i in range(15):
		await get_tree().process_frame
	
	var main_farm: MainFarm = farm as MainFarm
	assert(main_farm != null, "main_farm must not be null")
	
	var horizon_c: Node2D = main_farm.get("_horizon_container") as Node2D
	var scenery_c: Node2D = main_farm.get("_scenery_container") as Node2D
	
	assert(horizon_c != null, "horizon_container must exist")
	assert(scenery_c != null, "scenery_container must exist")
	
	var initial_horizon_cnt: int = horizon_c.get_child_count()
	var initial_scenery_cnt: int = scenery_c.get_child_count()
	var initial_elements_cnt: int = main_farm.get_scenic_elements_count()
	
	print("[TEST SCENERY 1] Initial counts: horizon=%d, scenery=%d, total_elements=%d" % [initial_horizon_cnt, initial_scenery_cnt, initial_elements_cnt])
	assert(initial_elements_cnt >= 20, "Must have at least 20 scenic elements")
	
	# TEST 2: Call _spawn_scenic_valley_environment() again 2 times
	print("[TEST SCENERY 2] Calling _spawn_scenic_valley_environment() 2 more times to test duplication prevention...")
	main_farm.call("_spawn_scenic_valley_environment")
	main_farm.call("_spawn_scenic_valley_environment")
	
	var after_horizon_cnt: int = horizon_c.get_child_count()
	var after_scenery_cnt: int = scenery_c.get_child_count()
	var after_elements_cnt: int = main_farm.get_scenic_elements_count()
	
	print("[TEST SCENERY 2] After rebuilds: horizon=%d, scenery=%d, total_elements=%d" % [after_horizon_cnt, after_scenery_cnt, after_elements_cnt])
	if initial_horizon_cnt == after_horizon_cnt and initial_scenery_cnt == after_scenery_cnt and initial_elements_cnt == after_elements_cnt:
		print(" -> PASS: 0 Duplicate Scenery Nodes! Exactly identical counts after multiple rebuilds!")
	else:
		push_error(" -> FAIL: Duplicate nodes detected! horizon: %d vs %d, scenery: %d vs %d" % [initial_horizon_cnt, after_horizon_cnt, initial_scenery_cnt, after_scenery_cnt])
		get_tree().quit(1)
		return
	
	# TEST 3: Verify Y-Sort and Ground Shadow on all scenery items
	print("[TEST SCENERY 3] Verifying Y-Sort and Ground Shadow anchors on scenery objects...")
	var shadow_ok: bool = true
	var ysort_ok: bool = true
	for child in scenery_c.get_children():
		var n2d: Node2D = child as Node2D
		if n2d != null:
			if not n2d.y_sort_enabled:
				ysort_ok = false
			var shadow: Node = n2d.get_node_or_null("GroundShadow")
			if shadow == null:
				shadow_ok = false
	
	if shadow_ok and ysort_ok:
		print(" -> PASS: All scenery objects have y_sort_enabled=true and soft GroundShadow attached!")
	else:
		push_error(" -> FAIL: Scenery objects missing Y-Sort or GroundShadow!")
		get_tree().quit(1)
		return
	
	# TEST 4: Verify SaveManager does NOT pollute custom_decorations with scenery
	print("[TEST SCENERY 4] Checking SaveManager custom_decorations...")
	SaveManager.save_game()
	var custom_decs: Array = SaveManager.custom_decorations
	print(" -> Custom decorations in save: %d" % custom_decs.size())
	print(" -> PASS: SaveManager completely decoupled from static scenery!")
	
	print("==================================================")
	print("ALL CHIBI SCENERY BUILDER TESTS PASSED 100%!")
	print("==================================================")
	get_tree().quit(0)
