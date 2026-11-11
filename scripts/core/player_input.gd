extends Node
class_name PlayerInput

const WalkGridClass = preload("res://scripts/core/walk_grid.gd")
const PlayerAvatarClass = preload("res://scripts/entities/player_avatar.gd")
const RiverSteamboatClass = preload("res://scripts/entities/river_steamboat.gd")
const BeehiveTreeClass = preload("res://scripts/entities/beehive_tree.gd")

@export var main_farm: Node2D
@export var player_avatar: Node2D
@export var walk_grid: Node2D

func _ready() -> void:
	if main_farm == null:
		main_farm = get_parent() as Node2D
	if player_avatar == null and main_farm != null:
		player_avatar = main_farm.find_child("PlayerAvatar", true, false) as Node2D
	if walk_grid == null and main_farm != null:
		walk_grid = main_farm.find_child("WalkGrid", true, false) as Node2D

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
		
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.is_pressed():
		return
		
	if main_farm != null and (main_farm._pending_build_id != "" or main_farm._relocating_node != null):
		return

	if player_avatar == null or walk_grid == null:
		return

	var mpos: Vector2 = Vector2.ZERO
	if main_farm != null:
		mpos = main_farm.get_global_mouse_position()
	else:
		var vp: Viewport = get_viewport()
		if vp != null:
			mpos = vp.get_camera_2d().get_global_mouse_position() if vp.get_camera_2d() != null else Vector2.ZERO

	# 1. PRIORITY 1: Check VisitorNPCs with generous 72x88px bounding box
	var vm: VisitorManager = main_farm.find_child("VisitorManager", true, false) as VisitorManager if main_farm != null else null
	if vm != null:
		for npc: VisitorNPC in vm.get_active_visitors():
			if is_instance_valid(npc) and npc.state != VisitorNPC.VisitorState.INACTIVE:
				var local_pos: Vector2 = mpos - npc.global_position
				if Rect2(-36.0, -60.0, 72.0, 88.0).has_point(local_pos):
					if main_farm != null and main_farm.drag_action_manager != null and main_farm.drag_action_manager.current_tool != DragActionManager.ToolType.NONE:
						main_farm.drag_action_manager.set_tool(DragActionManager.ToolType.NONE)
					npc.handle_visitor_click()
					get_viewport().set_input_as_handled()
					return

	# 2. PRIORITY 2: Check Animal Pens (1-Click Feed / Harvest)
	if main_farm != null:
		for pen: AnimalPen in main_farm._animal_pens:
			if is_instance_valid(pen) and mpos.distance_to(pen.global_position) <= 95.0:
				if main_farm.drag_action_manager != null and main_farm.drag_action_manager.current_tool != DragActionManager.ToolType.NONE:
					main_farm.drag_action_manager.set_tool(DragActionManager.ToolType.NONE)
				pen.handle_pen_click()
				interact_with(pen)
				get_viewport().set_input_as_handled()
				return

	# 3. PRIORITY 3: Check Zoo Enclosures (1-Click Feed / Unlock)
	if main_farm != null:
		var zm: ZooManager = main_farm.find_child("ZooManager", true, false) as ZooManager
		if zm != null:
			for enc_id: String in zm.enclosures:
				var enc: ZooEnclosure = zm.enclosures[enc_id] as ZooEnclosure
				if is_instance_valid(enc) and mpos.distance_to(enc.global_position) <= 100.0:
					if main_farm.drag_action_manager != null and main_farm.drag_action_manager.current_tool != DragActionManager.ToolType.NONE:
						main_farm.drag_action_manager.set_tool(DragActionManager.ToolType.NONE)
					enc.on_player_interact(player_avatar)
					interact_with(enc)
					get_viewport().set_input_as_handled()
					return

	# 4. PRIORITY 4: Check River Steamboat (1-Click Popup Modal)
	if main_farm != null and is_instance_valid(main_farm.river_steamboat):
		var local_boat: Vector2 = mpos - main_farm.river_steamboat.global_position
		if Rect2(-45.0, -50.0, 175.0, 110.0).has_point(local_boat):
			if main_farm.drag_action_manager != null and main_farm.drag_action_manager.current_tool != DragActionManager.ToolType.NONE:
				main_farm.drag_action_manager.set_tool(DragActionManager.ToolType.NONE)
			main_farm.river_steamboat.handle_steamboat_click()
			get_viewport().set_input_as_handled()
			return

	# 5. PRIORITY 5: Check Beehive Tree (1-Click Harvest / Quick Boost)
	if main_farm != null and is_instance_valid(main_farm.beehive_tree):
		var local_hive: Vector2 = mpos - main_farm.beehive_tree.global_position
		if Rect2(-36.0, -48.0, 72.0, 84.0).has_point(local_hive):
			if main_farm.drag_action_manager != null and main_farm.drag_action_manager.current_tool != DragActionManager.ToolType.NONE:
				main_farm.drag_action_manager.set_tool(DragActionManager.ToolType.NONE)
			main_farm.beehive_tree.handle_beehive_click()
			get_viewport().set_input_as_handled()
			return

	# Ignore clicks if a tool is currently selected (e.g. planting seeds or harvesting crops)
	if main_farm != null:
		if main_farm.drag_action_manager != null and main_farm.drag_action_manager.current_tool != DragActionManager.ToolType.NONE:
			return

	var target_interactable: Node = find_interactable_at(mpos)
	
	if target_interactable != null:
		if SaveManager.instant_interact:
			# Instant mode: execute interaction directly without moving
			if target_interactable.has_method("on_player_interact"):
				target_interactable.call("on_player_interact", player_avatar)
			elif main_farm != null:
				main_farm.simulate_click_at_world_pos(mpos)
		else:
			# Walk-to-interact mode: walk adjacent to the object before interacting
			interact_with(target_interactable)
		get_viewport().set_input_as_handled()
	else:
		# Clicked on open ground: move avatar to clicked spot
		var path: Array[Vector2] = walk_grid.find_path(player_avatar.global_position, mpos)
		if not path.is_empty():
			player_avatar.go_to(path, null)
			get_viewport().set_input_as_handled()

func interact_with(target: Node) -> void:
	if target == null or player_avatar == null or walk_grid == null:
		return
		
	if SaveManager.instant_interact:
		if target.has_method("on_player_interact"):
			target.call("on_player_interact", player_avatar)
		return

	var target_pos: Vector2 = player_avatar.global_position
	var stand_dist: float = 32.0

	if target is FieldPlot:
		var fp: FieldPlot = target as FieldPlot
		target_pos = fp.global_position
		stand_dist = 28.0
	elif target is ProductionMachine:
		var pm: ProductionMachine = target as ProductionMachine
		target_pos = pm.global_position
		stand_dist = 52.0
	elif target is AnimalPen:
		var ap: AnimalPen = target as AnimalPen
		target_pos = ap.global_position
		stand_dist = 64.0
	elif target is FishingSpot:
		target_pos = Vector2(768.0, 750.0) # Fisherman wooden dock
		stand_dist = 18.0
	elif target is MovableDecor:
		var md: MovableDecor = target as MovableDecor
		target_pos = md.global_position
		stand_dist = 36.0
	elif target is RiverSteamboatClass:
		target.call("handle_steamboat_click")
		return
	elif target is BeehiveTreeClass:
		target.call("handle_beehive_click")
		return
	elif target is Node2D:
		target_pos = (target as Node2D).global_position
		stand_dist = 42.0

	# Calculate offset adjacent to the target towards player's current position
	var to_player: Vector2 = (player_avatar.global_position - target_pos).normalized()
	if to_player == Vector2.ZERO:
		to_player = Vector2.DOWN
	var stand_target_pos: Vector2 = target_pos + to_player * stand_dist

	var path: Array[Vector2] = walk_grid.find_path(player_avatar.global_position, stand_target_pos)
	player_avatar.go_to(path, target)

func find_interactable_at(world_pos: Vector2) -> Node:
	if main_farm == null:
		return null
		
	# 1. FieldPlot (Ruộng)
	var clicked_cell: Vector2i = GridManager.world_to_grid(world_pos)
	var plot: FieldPlot = main_farm.get_field_plot_at(clicked_cell)
	if plot != null and is_instance_valid(plot):
		return plot

	# 2. Production Machines (Lò nướng, Cối xay)
	for machine: ProductionMachine in main_farm._production_machines:
		if is_instance_valid(machine) and world_pos.distance_to(machine.global_position) <= 75.0:
			return machine

	# 3. Animal Pens (Chuồng gia súc)
	for pen: AnimalPen in main_farm._animal_pens:
		if is_instance_valid(pen) and world_pos.distance_to(pen.global_position) <= 95.0:
			return pen

	# 4. Fishing Spot (Bến câu cá)
	if main_farm.fishing_spot != null and is_instance_valid(main_farm.fishing_spot):
		if main_farm.fishing_spot.fishing_rect.has_point(world_pos) or world_pos.distance_to(Vector2(790.0, 745.0)) <= 80.0:
			return main_farm.fishing_spot

	# 5. Fruit Trees (Cây ăn quả)
	for decor: MovableDecor in main_farm._movable_decors:
		if is_instance_valid(decor) and decor.is_fruit_tree and world_pos.distance_to(decor.global_position) <= 60.0:
			return decor

	# 6. Barn, Silo, Truck, Roadside Shop Props
	if main_farm._barn_prop != null and is_instance_valid(main_farm._barn_prop):
		if world_pos.distance_to(main_farm._barn_prop.global_position) <= 65.0:
			return main_farm._barn_prop
			
	if main_farm._silo_prop != null and is_instance_valid(main_farm._silo_prop):
		if world_pos.distance_to(main_farm._silo_prop.global_position) <= 65.0:
			return main_farm._silo_prop
			
	if main_farm._truck_prop != null and is_instance_valid(main_farm._truck_prop):
		if world_pos.distance_to(main_farm._truck_prop.global_position) <= 65.0:
			return main_farm._truck_prop

	if main_farm._roadside_shop_prop != null and is_instance_valid(main_farm._roadside_shop_prop):
		if world_pos.distance_to(main_farm._roadside_shop_prop.global_position) <= 65.0:
			return main_farm._roadside_shop_prop

	# 7. River Steamboat & Beehive Tree
	if main_farm.river_steamboat != null and is_instance_valid(main_farm.river_steamboat):
		var local_b: Vector2 = world_pos - main_farm.river_steamboat.global_position
		if Rect2(-45.0, -50.0, 175.0, 110.0).has_point(local_b):
			return main_farm.river_steamboat

	if main_farm.beehive_tree != null and is_instance_valid(main_farm.beehive_tree):
		var local_h: Vector2 = world_pos - main_farm.beehive_tree.global_position
		if Rect2(-36.0, -48.0, 72.0, 84.0).has_point(local_h):
			return main_farm.beehive_tree

	# 8. Generic registered interactables
	for node: Node in get_tree().get_nodes_in_group("interactable"):
		if node is Node2D and is_instance_valid(node):
			var n2d: Node2D = node as Node2D
			if world_pos.distance_to(n2d.global_position) <= 40.0:
				return n2d

	return null
