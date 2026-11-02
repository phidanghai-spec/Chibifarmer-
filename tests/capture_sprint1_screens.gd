extends Node

func _ready() -> void:
	print("[Sprint1 Test] Starting automated visual capture for Sprint 1...")
	
	# 1. Capture BootSplash
	var boot_scene: PackedScene = load("res://scenes/boot/BootSplash.tscn")
	var boot: Node = boot_scene.instantiate()
	add_child(boot)
	
	# Let it run a few frames of animation
	for i: int in range(15):
		await get_tree().process_frame
	
	var img_boot: Image = get_viewport().get_texture().get_image()
	if img_boot != null and not img_boot.is_empty():
		img_boot.save_png("res://debug_bootsplash.png")
		print("[Sprint1 Test] Saved BootSplash preview to res://debug_bootsplash.png")
	
	boot.queue_free()
	await get_tree().process_frame
	
	# 2. Capture TitleScreen (Main Screen)
	var title_scene: PackedScene = load("res://scenes/ui/TitleScreen.tscn")
	var title: Node = title_scene.instantiate()
	add_child(title)
	
	for i: int in range(25):
		await get_tree().process_frame
		
	var img_title: Image = get_viewport().get_texture().get_image()
	if img_title != null and not img_title.is_empty():
		img_title.save_png("res://debug_titlescreen.png")
		print("[Sprint1 Test] Saved TitleScreen preview to res://debug_titlescreen.png")
		
	# 3. Capture SaveSlotModal
	var modal: PanelContainer = title.get_node("UILayer/SaveSlotModal") as PanelContainer
	if modal != null:
		modal.visible = true
		(title as TitleScreen)._populate_slot_cards()
		for i: int in range(20):
			await get_tree().process_frame
			
		var img_slots: Image = get_viewport().get_texture().get_image()
		if img_slots != null and not img_slots.is_empty():
			img_slots.save_png("res://debug_save_slots.png")
			print("[Sprint1 Test] Saved SaveSlotModal preview to res://debug_save_slots.png")
	
	print("[Sprint1 Test] All Sprint 1 visual previews captured successfully!")
	get_tree().quit(0)

