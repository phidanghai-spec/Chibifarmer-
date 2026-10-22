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
	else:
		push_error("[SCREENSHOT] Failed to get viewport image")
	
	get_tree().quit()
