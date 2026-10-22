extends Node

func _ready() -> void:
	var farm_scene: PackedScene = load("res://scenes/main_farm.tscn")
	var farm: Node = farm_scene.instantiate()
	add_child(farm)
	
	# Frame camera to show the winding river, wooden bridge, fishing pier, and farm center
	var cam: Camera2D = farm.get_node_or_null("Camera2D") as Camera2D
	if cam != null:
		cam.position = Vector2(700.0, 520.0)
		cam.zoom = Vector2(0.78, 0.78)
		cam.set("target_zoom", Vector2(0.78, 0.78))
	
	# Start a production batch on Bakery to verify full countdown display
	var main_farm: MainFarm = farm as MainFarm
	if main_farm != null and not main_farm._production_machines.is_empty():
		for m: ProductionMachine in main_farm._production_machines:
			if m.machine_id == "bakery":
				m.handle_machine_click()
				break

	# Wait for rendering pipeline
	for i: int in range(25):
		await get_tree().process_frame
	
	var img: Image = get_viewport().get_texture().get_image()
	if img != null and not img.is_empty():
		img.save_png("res://debug_preview.png")
		print("[SCREENSHOT] Saved screenshot to res://debug_preview.png (Size: ", img.get_size(), ")")
	
	# Open Barn Storage Modal and capture
	var hud: UIHud = farm.get_node_or_null("UIHud") as UIHud
	if hud != null:
		hud.open_storage_popup("barn")
		for i: int in range(10):
			await get_tree().process_frame
		var img_barn: Image = get_viewport().get_texture().get_image()
		if img_barn != null and not img_barn.is_empty():
			img_barn.save_png("res://debug_barn_storage.png")
			print("[SCREENSHOT] Saved barn storage screenshot to res://debug_barn_storage.png")
		
		# Open Silo Storage Modal and capture
		hud.open_storage_popup("silo")
		for i: int in range(10):
			await get_tree().process_frame
		var img_silo: Image = get_viewport().get_texture().get_image()
		if img_silo != null and not img_silo.is_empty():
			img_silo.save_png("res://debug_silo_storage.png")
			print("[SCREENSHOT] Saved silo storage screenshot to res://debug_silo_storage.png")
		
		# Close storage and toggle seeds menu
		if hud.get("_storage_modal") != null:
			(hud.get("_storage_modal") as CanvasItem).visible = false
		hud.toggle_seeds_menu()
		for i: int in range(10):
			await get_tree().process_frame
		var img_seeds: Image = get_viewport().get_texture().get_image()
		if img_seeds != null and not img_seeds.is_empty():
			img_seeds.save_png("res://debug_seeds_menu.png")
			print("[SCREENSHOT] Saved seeds menu screenshot to res://debug_seeds_menu.png")
	
	get_tree().quit()
