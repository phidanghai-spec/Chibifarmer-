extends Node

func _ready() -> void:
	SaveManager.set_sandbox_level_33()
	var farm_scene: PackedScene = load("res://scenes/main_farm.tscn")
	var farm: Node = farm_scene.instantiate()
	add_child(farm)
	
	var cam: Camera2D = farm.get_node_or_null("Camera2D") as Camera2D
	var hud: UIHud = farm.get_node_or_null("UIHud") as UIHud
	var avatar: Node2D = farm.get_node_or_null("PlayerAvatar") as Node2D
	var poodle: Node2D = farm.get_node_or_null("PetPoodle") as Node2D
	
	# 1. Capture East Bank Zoo Sanctuary & Hot Air Balloon + East Park Decor
	if cam != null:
		cam.position = Vector2(1440.0, 320.0)
		cam.zoom = Vector2(0.85, 0.85)
		cam.set("target_zoom", Vector2(0.85, 0.85))
	
	for i: int in range(25):
		await get_tree().process_frame
	
	var img: Image = get_viewport().get_texture().get_image()
	if img != null and not img.is_empty():
		img.save_png("res://debug_preview.png")
		print("[SCREENSHOT] Saved zoo & balloon preview to res://debug_preview.png")
	
	# 2. Capture West Bank Farm (Poodle at Mushroom Farmhouse Lawn, Kennel, Central Fields)
	if cam != null:
		cam.position = Vector2(340.0, 320.0)
		cam.zoom = Vector2(0.95, 0.95)
		cam.set("target_zoom", Vector2(0.95, 0.95))
	
	for i: int in range(20):
		await get_tree().process_frame
	
	var img_farm: Image = get_viewport().get_texture().get_image()
	if img_farm != null and not img_farm.is_empty():
		img_farm.save_png("res://debug_farm_west.png")
		print("[SCREENSHOT] Saved west farm preview to res://debug_farm_west.png")
	
	# 3. Capture Zoo Feed Shop Modal (Crisp text on green buttons)
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

	# 4. Capture Daily Newspaper Modal
	if hud != null:
		hud.open_newspaper_modal()
		for i: int in range(15):
			await get_tree().process_frame
		var img_news: Image = get_viewport().get_texture().get_image()
		if img_news != null and not img_news.is_empty():
			img_news.save_png("res://debug_newspaper.png")
			print("[SCREENSHOT] Saved Daily Newspaper modal to res://debug_newspaper.png")
		var n_modal: PanelContainer = hud.get("_newspaper_modal") as PanelContainer
		if n_modal != null:
			n_modal.queue_free()

	# 5. Capture Hot Air Balloon Flight & Upgrade Modal (Crisp text on green buttons)
	if hud != null:
		hud.open_hot_air_balloon_modal()
		for i: int in range(15):
			await get_tree().process_frame
		var img_bal: Image = get_viewport().get_texture().get_image()
		if img_bal != null and not img_bal.is_empty():
			img_bal.save_png("res://debug_balloon.png")
			print("[SCREENSHOT] Saved Hot Air Balloon modal to res://debug_balloon.png")
		var b_modal: PanelContainer = hud.get("_hot_air_balloon_modal") as PanelContainer
		if b_modal != null:
			b_modal.queue_free()

	# 6. Capture Poodle following across the Wooden Bridge
	if avatar != null and poodle != null and cam != null:
		avatar.global_position = Vector2(1200.0, 656.0)
		poodle.global_position = Vector2(920.0, 656.0) # On the wooden bridge deck
		cam.position = Vector2(950.0, 656.0)
		cam.zoom = Vector2(1.0, 1.0)
		cam.set("target_zoom", Vector2(1.0, 1.0))
		for i: int in range(25):
			await get_tree().process_frame
		var img_bridge: Image = get_viewport().get_texture().get_image()
		if img_bridge != null and not img_bridge.is_empty():
			img_bridge.save_png("res://debug_poodle_bridge.png")
			print("[SCREENSHOT] Saved Poodle on Bridge preview to res://debug_poodle_bridge.png")
	
	print("[SCREENSHOT] All Đợt 10 screenshots successfully captured!")
	get_tree().quit()
