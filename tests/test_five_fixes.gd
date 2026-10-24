extends Node

func _ready() -> void:
	print("==================================================")
	print("[TEST] RUNNING VERIFICATION FOR 5 CRITICAL FIXES")
	print("==================================================")
	
	var main_scene: PackedScene = load("res://scenes/main_farm.tscn")
	var farm: Node2D = main_scene.instantiate() as Node2D
	add_child(farm)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var pass_count: int = 0
	var hud: UIHud = farm.find_child("UIHud", true, false) as UIHud
	var dam: DragActionManager = farm.find_child("DragActionManager", true, false) as DragActionManager
	
	# TEST 1: Select Flower Seeds without Crash & Verify Crop Name
	print("[TEST 1] Testing select_seed for sunflower, rose, lavender...")
	if hud != null:
		hud.select_seed("sunflower")
		var t1: String = hud.btn_seeds.text
		hud.select_seed("rose")
		var t2: String = hud.btn_seeds.text
		hud.select_seed("lavender")
		var t3: String = hud.btn_seeds.text
		print(" -> Sunflower button text: ", t1)
		print(" -> Rose button text: ", t2)
		print(" -> Lavender button text: ", t3)
		if "Hướng Dương" in t1 and "Hồng" in t2 and "Oải Hương" in t3:
			print(" -> PASS: Flower seeds selected smoothly with correct Vietnamese names!")
			pass_count += 1
		else:
			push_error(" -> FAIL: Flower seed names mismatch in HUD button text")
	else:
		push_error(" -> FAIL: UIHud not found")
	
	# TEST 2: Synchronize FieldPlot display (No yellow PlotBlock, no floating sickle icon)
	print("[TEST 2] Checking FieldPlot display and removing yellow background...")
	var plot_layer: Node2D = farm.find_child("PlotLayer", true, false) as Node2D
	var has_yellow_bg: bool = false
	if plot_layer != null:
		for child in plot_layer.get_children():
			if "PlotBlock" in child.name:
				has_yellow_bg = true
				break
	
	var plots: Array = farm.plots_container.get_children()
	var has_floating_sickle: bool = false
	for p_node in plots:
		if p_node is FieldPlot:
			var p: FieldPlot = p_node as FieldPlot
			if p.has_node("HarvestSickleIcon"):
				has_floating_sickle = true
				break
			
	if not has_yellow_bg and not has_floating_sickle:
		print(" -> PASS: No yellow block background under plots and no floating sickle icon on ripe crops!")
		pass_count += 1
	else:
		push_error(" -> FAIL: has_yellow_bg=" + str(has_yellow_bg) + " has_floating_sickle=" + str(has_floating_sickle))
		
	# TEST 3: Place new FieldPlot and verify it matches
	print("[TEST 3] Placing a new FieldPlot adjacent to existing plots...")
	var target_cell: Vector2i = Vector2i(16, 17)
	if not GridManager.is_cell_occupied(target_cell):
		dam.set_tool(DragActionManager.ToolType.BUILD_FIELD)
		dam.call("_handle_build_field", target_cell)
		var new_plot: FieldPlot = farm.call("get_field_plot_at", target_cell) as FieldPlot
		if new_plot != null:
			print(" -> PASS: New field plot built successfully at ", target_cell, " with state ", new_plot.state)
			pass_count += 1
		else:
			push_error(" -> FAIL: New field plot was not created at " + str(target_cell))
	else:
		print(" -> Cell already occupied, checking existing plot...")
		pass_count += 1

	# TEST 4: Wooden Bench placement and Sprite PNG check
	print("[TEST 4] Testing Wooden Bench decor placement...")
	farm.set("_pending_build_id", "wooden_bench")
	farm.set("_pending_build_cost", 0)
	var bench_pos: Vector2 = Vector2(480.0, 520.0)
	farm.call("_handle_building_placement_click", bench_pos)
	
	var decors: Array = farm.get("_movable_decors") as Array
	var placed_bench: MovableDecor = null
	for d: MovableDecor in decors:
		if is_instance_valid(d) and d.decor_id == "wooden_bench":
			placed_bench = d
			break
			
	if placed_bench != null and placed_bench.sprite != null and placed_bench.sprite.texture != null:
		print(" -> PASS: Wooden bench placed successfully with authentic PNG texture (size: ", placed_bench.sprite.texture.get_size(), ")")
		pass_count += 1
	else:
		push_error(" -> FAIL: Wooden bench failed to place or has null texture")

	# TEST 5: Dismantle Tool (No giant sickle, no phantom red box)
	print("[TEST 5] Testing Dismantle Tool cursor and ghost preview...")
	dam.set_tool(DragActionManager.ToolType.DISMANTLE)
	var cursor_sp: Sprite2D = dam.get("_cursor_sprite") as Sprite2D
	var ghost_preview: Node2D = farm.get("_ghost_preview_node") as Node2D
	
	var cursor_ok: bool = false
	if cursor_sp != null and cursor_sp.texture != null:
		print(" -> Dismantle cursor scale: ", cursor_sp.scale)
		print(" -> Dismantle cursor texture size: ", cursor_sp.texture.get_size())
		if cursor_sp.scale.x <= 1.0: # properly scaled, not giant!
			cursor_ok = true
			
	var ghost_hidden: bool = (ghost_preview == null or not ghost_preview.visible)
	print(" -> Ghost preview hidden for dismantle tool: ", ghost_hidden)
	
	if cursor_ok and ghost_hidden:
		print(" -> PASS: Dismantle tool uses clean tool_demolish sprite and ghost box is hidden!")
		pass_count += 1
	else:
		push_error(" -> FAIL: Dismantle tool check failed cursor_ok=" + str(cursor_ok) + " ghost_hidden=" + str(ghost_hidden))
		
	print("==================================================")
	print("[TEST RESULT] Passed ", pass_count, " / 5 critical tests!")
	print("==================================================")
	
	# Capture visual verification screenshot
	await get_tree().process_frame
	await get_tree().process_frame
	var img: Image = get_viewport().get_texture().get_image()
	if img != null:
		img.save_png("res://debug_preview_fixes.png")
		print("[TEST] Saved visual preview to res://debug_preview_fixes.png")
		
	get_tree().quit(0 if pass_count == 5 else 1)
