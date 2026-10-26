extends Node

func _ready() -> void:
	var farm_scene: PackedScene = load("res://scenes/main_farm.tscn")
	var farm: Node = farm_scene.instantiate()
	add_child(farm)
	
	# 1. Capture East Bank Zoo Sanctuary (Entrance, Feed Shop with house sprite, 4 spaced enclosures)
	var cam: Camera2D = farm.get_node_or_null("Camera2D") as Camera2D
	if cam != null:
		cam.position = Vector2(1300.0, 360.0)
		cam.zoom = Vector2(0.85, 0.85)
		cam.set("target_zoom", Vector2(0.85, 0.85))
	
	for i: int in range(25):
		await get_tree().process_frame
	
	var img: Image = get_viewport().get_texture().get_image()
	if img != null and not img.is_empty():
		img.save_png("res://debug_preview.png")
		print("[SCREENSHOT] Saved screenshot to res://debug_preview.png (Size: ", img.get_size(), ")")
	
	# 2. Capture Avatar on Field Plot to verify avatar is drawn on top of plot soil
	var p_avatar: Node2D = farm.get_node_or_null("PlayerAvatar") as Node2D
	if p_avatar != null and cam != null:
		p_avatar.position = Vector2(430.0, 560.0)
		cam.position = Vector2(440.0, 560.0)
		cam.zoom = Vector2(1.6, 1.6)
		cam.set("target_zoom", Vector2(1.6, 1.6))
		for i: int in range(15):
			await get_tree().process_frame
		var img_plot: Image = get_viewport().get_texture().get_image()
		if img_plot != null and not img_plot.is_empty():
			img_plot.save_png("res://debug_avatar_plot.png")
			print("[SCREENSHOT] Saved avatar plot screenshot to res://debug_avatar_plot.png")
	
	# 3. Capture Zoo Feed Shop Modal (3 options)
	var hud: UIHud = farm.get_node_or_null("UIHud") as UIHud
	if hud != null:
		hud.open_zoo_feed_shop_modal()
		for i: int in range(15):
			await get_tree().process_frame
		var img_shop: Image = get_viewport().get_texture().get_image()
		if img_shop != null and not img_shop.is_empty():
			img_shop.save_png("res://debug_feed_shop.png")
			print("[SCREENSHOT] Saved Zoo Feed Shop modal to res://debug_feed_shop.png")
		var s_modal: PanelContainer = hud.get("_zoo_feed_shop_modal") as PanelContainer
		if s_modal != null:
			s_modal.queue_free()
	
	print("[SCREENSHOT] All preview screenshots successfully captured!")
	get_tree().quit()
