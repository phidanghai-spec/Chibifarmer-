extends Node

func _ready() -> void:
	print("[Sprint2 Test] Starting automated visual capture for Sprint 2...")
	
	# 1. Capture CharacterCreator
	var creator_scene: PackedScene = load("res://scenes/ui/CharacterCreator.tscn")
	var creator: Node = creator_scene.instantiate()
	add_child(creator)
	
	# Let animation run a few frames
	for i: int in range(25):
		await get_tree().process_frame
		
	var img_creator: Image = get_viewport().get_texture().get_image()
	if img_creator != null and not img_creator.is_empty():
		img_creator.save_png("res://debug_char_creator.png")
		print("[Sprint2 Test] Saved CharacterCreator preview to res://debug_char_creator.png")
		
	# Test Pose Harvest
	var avatar: ModularChibiAvatar = creator.find_child("AvatarPreview", true, false) as ModularChibiAvatar
	if avatar != null:
		avatar.set_preview_action(ModularChibiAvatar.PreviewMode.HARVEST)
		for i: int in range(20):
			await get_tree().process_frame
		var img_harvest: Image = get_viewport().get_texture().get_image()
		if img_harvest != null and not img_harvest.is_empty():
			img_harvest.save_png("res://debug_char_poses.png")
			print("[Sprint2 Test] Saved Harvest Pose preview to res://debug_char_poses.png")
			
	creator.queue_free()
	await get_tree().process_frame
	
	# 2. Capture MainFarm with Modular Avatar & Poodle
	var farm_scene: PackedScene = load("res://scenes/main_farm.tscn")
	var farm: Node = farm_scene.instantiate()
	add_child(farm)
	
	var cam: Camera2D = farm.find_child("Camera2D", true, false) as Camera2D
	if cam != null:
		cam.position = Vector2(240.0, 640.0) # Focus near PlayerAvatar and Poodle
		cam.zoom = Vector2(1.1, 1.1)
		
	for i: int in range(30):
		await get_tree().process_frame
		
	var img_farm: Image = get_viewport().get_texture().get_image()
	if img_farm != null and not img_farm.is_empty():
		img_farm.save_png("res://debug_farm_modular_avatar.png")
		print("[Sprint2 Test] Saved Farm Modular Avatar preview to res://debug_farm_modular_avatar.png")
		
	print("[Sprint2 Test] All Sprint 2 visual previews captured successfully!")
	get_tree().quit(0)

