extends Node

func _ready() -> void:
	var farm_scene: PackedScene = load("res://scenes/main_farm.tscn")
	var farm: Node = farm_scene.instantiate()
	add_child(farm)
	
	# Frame camera to show the winding river, wooden bridge, fishing pier, and farm center
	var cam: Camera2D = farm.get_node_or_null("Camera2D") as Camera2D
	if cam != null:
		cam.position = Vector2(720.0, 580.0)
		cam.zoom = Vector2(0.82, 0.82)
	
	# Wait for rendering pipeline
	for i in range(15):
		await get_tree().process_frame
	
	var img: Image = get_viewport().get_texture().get_image()
	if img != null and not img.is_empty():
		img.save_png("res://debug_preview.png")
		print("[SCREENSHOT] Saved screenshot to res://debug_preview.png (Size: ", img.get_size(), ")")
	else:
		push_error("[SCREENSHOT] Failed to get viewport image")
	
	get_tree().quit()
