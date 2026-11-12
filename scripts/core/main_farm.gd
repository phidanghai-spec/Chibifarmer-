extends Node2D
class_name MainFarm


@onready var camera_2d: Camera2D = $Camera2D
@onready var plots_container: Node2D = $PlotsContainer
@onready var buildings_container: Node2D = $BuildingsContainer
@onready var animal_pens_container: Node2D = $AnimalPensContainer
@onready var visitor_manager: VisitorManager = $VisitorManager
@onready var drag_action_manager: DragActionManager = $DragActionManager
@onready var ui_hud: CanvasLayer = $UIHud
@onready var walk_grid: Node2D = $WalkGrid
@onready var player_avatar: Node2D = $PlayerAvatar
@onready var player_input: Node = $PlayerInput
@onready var zoo_manager: Node2D = get_node_or_null("ZooManager")
@onready var quest_manager: Node = get_node_or_null("QuestManager")

@onready var ground_layer: Node2D = get_node_or_null("GroundLayer") as Node2D
@onready var props_layer: Node2D = get_node_or_null("PropsLayer") as Node2D

var environment_container: Node2D
var _horizon_container: Node2D = null
var _scenery_container: Node2D = null
var _scenic_valley_container: Node2D = null
var _scenic_elements: Array[Node2D] = []
var field_plots: Dictionary = {} # Vector2i -> FieldPlot
var fishing_spot: FishingSpot

var _flower_targets: Array[Vector2] = []
var _movable_decors: Array[MovableDecor] = []
var _animal_pens: Array[AnimalPen] = []
var _production_machines: Array[ProductionMachine] = []
var _truck_prop: Node2D = null
var _barn_prop: Node2D = null
var _silo_prop: Node2D = null
var _roadside_shop_prop: Node2D = null

const SpecializedNPCClass = preload("res://scripts/entities/specialized_npc.gd")
const ChibiSceneryBuilderClass = preload("res://scripts/map/chibi_scenery_builder.gd")
const WalkGridClass = preload("res://scripts/core/walk_grid.gd")
const PlayerAvatarClass = preload("res://scripts/entities/player_avatar.gd")
const PlayerInputClass = preload("res://scripts/core/player_input.gd")
const PetPoodleClass = preload("res://scripts/entities/pet_poodle.gd")
const PetHousePoodleClass = preload("res://scripts/entities/pet_house_poodle.gd")
const MailboxNewspaperPropClass = preload("res://scripts/entities/mailbox_newspaper_prop.gd")
const RiverSteamboatClass = preload("res://scripts/entities/river_steamboat.gd")
const BeehiveTreeClass = preload("res://scripts/entities/beehive_tree.gd")

var pet_poodle: Node2D = null
var pet_house_poodle: Node2D = null
var mailbox_newspaper_prop: Node2D = null
var river_steamboat: Node2D = null
var beehive_tree: Node2D = null

var _ghost_preview_node: Node2D = null
var _ghost_box: Polygon2D = null
var _ghost_sprite: Sprite2D = null
var _road_tilemap_layer: TileMapLayer = null

var _specialized_npcs_container: Node2D = null
var _specialized_npcs: Array[Node2D] = []
var _pending_build_id: String = ""
var _pending_build_cost: int = 0
var _pending_build_materials: Dictionary = {}
var _is_relocating_mode: bool = false

var _relocating_node: Node2D = null
var _relocating_old_cell: Vector2i = Vector2i.ZERO
var _relocating_tile_size: Vector2i = Vector2i(3, 3)
var _relocating_old_pos: Vector2 = Vector2.ZERO
var _relocating_initial_modulate: Color = Color.WHITE
var _relocating_initial_scale: Vector2 = Vector2.ONE
var _relocating_start_msec: int = 0

func get_scenic_elements_count() -> int:
	return _scenic_elements.size()

func _ready() -> void:
	# Center camera around the vibrant central farm plaza immediately
	var center_world_pos: Vector2 = Vector2(580, 540)
	camera_2d.position = center_world_pos
	camera_2d.target_zoom = Vector2(1.35, 1.35)
	camera_2d.zoom = Vector2(1.35, 1.35)

	# Hand-painted Chibi Meadow Backdrop from script khung cảnh.jpg
	var backdrop_sp: Sprite2D = Sprite2D.new()
	backdrop_sp.name = "ChibiMeadowBackdrop"
	backdrop_sp.z_index = -50
	backdrop_sp.centered = false
	backdrop_sp.position = Vector2(-200.0, -180.0)
	var b_tex: Texture2D = SpriteAtlasManager.get_texture("chibi_meadow_backdrop")
	if b_tex != null:
		backdrop_sp.texture = b_tex
		backdrop_sp.scale = Vector2(2400.0 / float(b_tex.get_width()), 1600.0 / float(b_tex.get_height()))
	add_child(backdrop_sp)
	move_child(backdrop_sp, 0)

	# Complete 2.5D Y-Sort & Z-Index Layering (Ground & Plots = 1, Characters = 10)
	y_sort_enabled = true
	if has_node("PathLayer"):
		(get_node("PathLayer") as Node2D).z_index = 0
	if has_node("PlotLayer"):
		(get_node("PlotLayer") as Node2D).z_index = 1
	if plots_container != null:
		plots_container.z_index = 1
		plots_container.y_sort_enabled = true
	buildings_container.y_sort_enabled = true
	animal_pens_container.y_sort_enabled = true
	if visitor_manager != null:
		visitor_manager.z_index = 10
		visitor_manager.y_sort_enabled = true
	if player_avatar != null:
		(player_avatar as Node2D).z_index = 10

	# Dedicated Environment Decorations Layer with Y-Sort
	environment_container = Node2D.new()
	environment_container.name = "EnvironmentContainer"
	environment_container.y_sort_enabled = true
	add_child(environment_container)

	# Chibi 2.5D Scenery System (Horizon & Border Scenery)
	if _horizon_container == null:
		_horizon_container = Node2D.new()
		_horizon_container.name = "HorizonContainer"
		_horizon_container.z_index = -12
		if ground_layer != null:
			ground_layer.add_child(_horizon_container)
		else:
			add_child(_horizon_container)

	if _scenery_container == null:
		_scenery_container = Node2D.new()
		_scenery_container.name = "SceneryContainer"
		_scenery_container.y_sort_enabled = true
		if props_layer != null:
			props_layer.add_child(_scenery_container)
		else:
			add_child(_scenery_container)

	_scenic_valley_container = _scenery_container
	# Connect Core System Event Signals
	EventBus.building_placed.connect(_on_building_placed)
	EventBus.building_removed.connect(_on_building_removed)
	EventBus.path_tile_changed.connect(_on_path_tile_changed)
	EventBus.field_harvested.connect(_on_field_harvested_material_drop)
	EventBus.truck_order_completed.connect(_on_truck_completed_material_drop)
	EventBus.leveled_up.connect(_on_player_level_up)

	# Link DragActionManager
	if drag_action_manager != null:
		drag_action_manager.main_farm = self
		drag_action_manager.tool_changed.connect(_on_drag_tool_changed)

	# Link Stock Alert System
	if ui_hud != null:
		var alert_node: Node = ui_hud.get_node_or_null("StockAlertSystem")
		if alert_node != null:
			alert_node.set("main_farm", self)

	# Initialize Ghost Placement Preview Node (z_index = 50, top_level = false)
	_ghost_preview_node = Node2D.new()
	_ghost_preview_node.name = "GhostPlacementPreview"
	_ghost_preview_node.z_index = 50
	_ghost_preview_node.top_level = false
	_ghost_preview_node.visible = false
	add_child(_ghost_preview_node)

	_ghost_box = Polygon2D.new()
	_ghost_box.name = "GhostBox"
	var half_box: float = 16.0
	_ghost_box.polygon = PackedVector2Array([
		Vector2(-half_box, -half_box),
		Vector2(half_box, -half_box),
		Vector2(half_box, half_box),
		Vector2(-half_box, half_box)
	])
	_ghost_box.color = Color(1.0, 1.0, 1.0, 0.45)
	_ghost_preview_node.add_child(_ghost_box)

	_ghost_sprite = Sprite2D.new()
	_ghost_sprite.name = "GhostSprite"
	_ghost_sprite.position = Vector2.ZERO
	_ghost_preview_node.add_child(_ghost_sprite)

	# Initial Farm Build if Empty
	if GridManager.occupied_cells.is_empty():
		_setup_initial_farm()
	_apply_saved_structure_positions()
	_setup_road_tilemap_layer()
	_sync_road_tilemap()
	call_deferred("_sync_road_tilemap")

	# Spawn Rich Chibi 2.5D Storybook Scenery
	_spawn_scenic_valley_environment()

	# Spawn Specialized NPCs at functional buildings
	_spawn_specialized_npcs()

	# Spawn Pet Poodle, Kennel & Daily Newspaper Mailbox
	_spawn_new_props_and_pets()

	# Hide all ✥ relocate buttons outside Layout Mode and apply Level 1->7+ building progression
	_set_all_relocate_buttons_visible(false)
	_refresh_building_progression_visibility()

	# Position Player Avatar at saved position or default farm gate
	if player_avatar != null:
		if SaveManager.player_position != Vector2.ZERO:
			player_avatar.position = SaveManager.player_position
		else:
			player_avatar.position = Vector2(70.0, 640.0)

	# Check screenshot test mode when main_farm is the primary scene
	if get_tree().current_scene == self:
		var args: PackedStringArray = OS.get_cmdline_args() + OS.get_cmdline_user_args()
		for arg: String in args:
			if "screenshot" in arg or "run-tests" in arg:
				var zoo_target: Vector2 = Vector2(1290.0, 390.0)
				if player_avatar != null and walk_grid != null:
					var path: Array[Vector2] = walk_grid.find_path(player_avatar.position, Vector2(1170.0, 480.0))
					player_avatar.go_to(path, null)
				if camera_2d != null:
					camera_2d.position = zoo_target
					camera_2d.zoom = Vector2(0.85, 0.85)
				_capture_screenshot_and_quit()
				break

func _on_drag_tool_changed(new_tool: DragActionManager.ToolType) -> void:
	var is_layout_mode: bool = (new_tool == DragActionManager.ToolType.DISMANTLE or int(new_tool) == 9)
	_set_all_relocate_buttons_visible(is_layout_mode)
	queue_redraw()
	if _ghost_preview_node == null:
		return
	
	if new_tool == DragActionManager.ToolType.NONE or new_tool == DragActionManager.ToolType.SICKLE or new_tool == DragActionManager.ToolType.DISMANTLE:
		_ghost_preview_node.visible = false
		return
	
	var tex_id: String = ""
	var spr_size: Vector2 = Vector2(28.0, 28.0)
	match new_tool:
		DragActionManager.ToolType.BUILD_FIELD:
			tex_id = "field_plot"
			spr_size = Vector2(28.0, 28.0)
		DragActionManager.ToolType.BUILD_PATH:
			tex_id = "path_tile"
			spr_size = Vector2(28.0, 28.0)
		DragActionManager.ToolType.PLANT_WHEAT:
			tex_id = "wheat"
			spr_size = Vector2(24.0, 24.0)
		DragActionManager.ToolType.PLANT_CORN:
			tex_id = "corn"
			spr_size = Vector2(24.0, 24.0)
		DragActionManager.ToolType.PLANT_CROP:
			tex_id = drag_action_manager.selected_crop_id
			spr_size = Vector2(24.0, 24.0)
		DragActionManager.ToolType.PLANT_APPLE_TREE:
			tex_id = "apple_seed"
			spr_size = Vector2(28.0, 28.0)
		DragActionManager.ToolType.PLANT_MANGO_TREE:
			tex_id = "mango_seed"
			spr_size = Vector2(28.0, 28.0)
	
	if SpriteAtlasManager.has_texture(tex_id):
		_ghost_sprite.texture = SpriteAtlasManager.get_texture(tex_id)
		SpriteAtlasManager.set_sprite_pixel_size(_ghost_sprite, spr_size)
		_ghost_sprite.visible = true
	else:
		_ghost_sprite.texture = null
		_ghost_sprite.visible = false
	
	_update_ghost_placement_preview(get_global_mouse_position())

func _update_ghost_placement_preview(mouse_pos: Vector2) -> void:
	if _ghost_preview_node == null or drag_action_manager == null:
		return
	var cur_tool: DragActionManager.ToolType = drag_action_manager.current_tool
	if cur_tool == DragActionManager.ToolType.NONE or cur_tool == DragActionManager.ToolType.SICKLE or cur_tool == DragActionManager.ToolType.DISMANTLE:
		_ghost_preview_node.visible = false
		return
	
	var cell: Vector2i = GridManager.world_to_grid(mouse_pos)
	var snapped_pos: Vector2 = Vector2(float(cell.x) * 32.0 + 16.0, float(cell.y) * 32.0 + 16.0)
	_ghost_preview_node.global_position = snapped_pos
	_ghost_preview_node.visible = true

	var is_valid: bool = false
	match cur_tool:
		DragActionManager.ToolType.BUILD_FIELD:
			is_valid = not _is_in_water_pond(snapped_pos) and GridManager.can_place_building("field_plot", cell)
		DragActionManager.ToolType.BUILD_PATH:
			is_valid = not _is_in_water_pond(snapped_pos) and not GridManager.is_path_tile(cell) and not GridManager.is_cell_occupied(cell)
		DragActionManager.ToolType.PLANT_APPLE_TREE:
			is_valid = _can_plant_tree_preview(snapped_pos, "apple")
		DragActionManager.ToolType.PLANT_MANGO_TREE:
			is_valid = _can_plant_tree_preview(snapped_pos, "mango")
		DragActionManager.ToolType.PLANT_WHEAT, DragActionManager.ToolType.PLANT_CORN, DragActionManager.ToolType.PLANT_CROP:
			var plot: FieldPlot = get_field_plot_at(cell)
			is_valid = (plot != null and plot.state == FieldPlot.PlotState.EMPTY)

	if is_valid:
		_ghost_preview_node.modulate = Color(0.35, 1.0, 0.45, 0.65) # Xanh Lá Trong Suốt
	else:
		_ghost_preview_node.modulate = Color(1.0, 0.35, 0.35, 0.65) # Đỏ Trong Suốt

func _can_plant_tree_preview(world_pos: Vector2, tree_type: String) -> bool:
	var seed_id: String = "apple_seed" if tree_type == "apple" else "mango_seed"
	if not StorageManager.has_item(seed_id, 1):
		return false
	var cell: Vector2i = GridManager.world_to_grid(world_pos)
	if not GridManager.is_within_bounds(cell):
		return false
	if GridManager.is_cell_occupied(cell) or GridManager.is_path_tile(cell):
		return false
	if _is_in_water_pond(world_pos):
		return false
	var fishing_rect: Rect2 = Rect2(Vector2(560.0, 560.0), Vector2(540.0, 300.0))
	if fishing_rect.has_point(world_pos):
		return false
	for d: MovableDecor in _movable_decors:
		if is_instance_valid(d) and world_pos.distance_to(d.global_position) < 32.0:
			return false
	return true

func _screen_to_world(scr: Vector2) -> Vector2:
	return (scr - Vector2(576.0, 324.0)) / 1.35 + camera_2d.position

func _world_to_screen(world_pos: Vector2) -> Vector2:
	return (world_pos - camera_2d.position) * 1.35 + Vector2(576.0, 324.0)

# --- CƠ CHẾ KIỂM TRA MẶT NƯỚC (WATER POND DETECTION) ---
func _is_in_lake_zone(world_pos: Vector2) -> bool:
	return _is_in_water_pond(world_pos)

func _is_in_water_pond(pos: Vector2) -> bool:
	return GridManager.is_in_water_or_sand(pos)

const MapBuilderClass = preload("res://scripts/map/map_builder.gd")

func _setup_initial_farm() -> void:
	MapBuilderClass.build_farm(self)

func _setup_environment_decorations() -> void:
	_movable_decors.clear()
	_flower_targets.clear()

	# Customizable / Movable Decorations (Loaded from Save or Default Layout)
	if SaveManager.custom_decorations.size() > 0:
		for item: Variant in SaveManager.custom_decorations:
			if item is Dictionary:
				var d: Dictionary = item as Dictionary
				var d_id: String = str(d.get("id", ""))
				var pos: Vector2 = Vector2(float(d.get("x", 0)), float(d.get("y", 0)))
				if _is_in_water_pond(pos):
					continue
				if "hedge" in d_id or "oak" in d_id or "cypress" in d_id or "tall" in d_id or "peach" in d_id:
					continue
				var size: Vector2 = Vector2(float(d.get("w", 32)), float(d.get("h", 32)))
				var shadow: bool = bool(d.get("shadow", true))
				var sway: bool = bool(d.get("sway", false))
				var decor: MovableDecor = _spawn_movable_decor(d_id, pos, size, shadow, sway)
				if decor != null and decor.is_fruit_tree:
					if d.has("harvest_left"):
						decor.harvest_left = int(d.get("harvest_left", 3))
					if d.has("revived_once"):
						decor.revived_once = bool(d.get("revived_once", false))
					if d.has("stage"):
						decor.set_growth_stage(int(d.get("stage", MovableDecor.TreeGrowthStage.STAGE_RIPE)))
	else:
		_spawn_default_decorations()
		save_custom_decorations()

func _spawn_default_decorations() -> void:
	# 1. Blooming Pastel Cherry Trees along North boundary (soft wind sway)
	_spawn_swaying_tree("env_cherry_tree", Vector2(360, 115), Vector2(84, 84))
	_spawn_swaying_tree("env_cherry_tree", Vector2(740, 115), Vector2(88, 88))

	# 2. Phân vùng 3: Khu Vườn Cây Ăn Quả (Bờ Tây, gọn gàng không chồng lên Sạp Hàng / Chuồng Trại)
	_spawn_apple_tree(Vector2(125, 410), Vector2(74, 78))
	_spawn_mango_tree(Vector2(195, 410), Vector2(72, 76))
	_spawn_mango_tree(Vector2(125, 475), Vector2(74, 76))
	_spawn_apple_tree(Vector2(195, 475), Vector2(74, 78))
	_spawn_apple_tree(Vector2(95, 835), Vector2(74, 78))
	_spawn_mango_tree(Vector2(165, 835), Vector2(72, 76))

	# 3. Soft Flowerbeds placed strictly near buildings/corners (clean and orderly)
	_spawn_flowerbed("flowerbed_daisies", Vector2(480, 240), Vector2(40, 28))
	_spawn_flowerbed("flowerbed_roses", Vector2(605, 240), Vector2(38, 26))
	_spawn_flowerbed("flowerbed_lavender", Vector2(355, 430), Vector2(38, 26))
	_spawn_flowerbed("flowerbed_round", Vector2(505, 430), Vector2(36, 26))

func _spawn_background_hill(sprite_id: String, pos: Vector2, size: Vector2) -> Node2D:
	if not SpriteAtlasManager.has_texture(sprite_id):
		return null
	var wrapper: Node2D = Node2D.new()
	wrapper.position = pos
	wrapper.z_index = -5
	environment_container.add_child(wrapper)
	var sp: Sprite2D = Sprite2D.new()
	sp.texture = SpriteAtlasManager.get_texture(sprite_id)
	SpriteAtlasManager.set_sprite_pixel_size(sp, size)
	wrapper.add_child(sp)
	return wrapper

func _spawn_movable_decor(sprite_id: String, pos: Vector2, size: Vector2, add_shadow: bool = true, sway: bool = false) -> MovableDecor:
	if not SpriteAtlasManager.has_texture(sprite_id):
		return null
	var decor: MovableDecor = MovableDecor.new()
	decor.name = "Decor_" + sprite_id + "_" + str(_movable_decors.size())
	environment_container.add_child(decor)
	decor.setup(sprite_id, pos, size, add_shadow, sway, self)
	_movable_decors.append(decor)
	if "flower" in sprite_id or "tree" in sprite_id:
		_flower_targets.append(pos)
	return decor

func _spawn_flowerbed(sprite_id: String, pos: Vector2, size: Vector2) -> MovableDecor:
	return _spawn_movable_decor(sprite_id, pos, size, true, false)

func _spawn_apple_tree(pos: Vector2, size: Vector2) -> MovableDecor:
	return _spawn_movable_decor("env_apple_tree", pos, size, true, true)

func _spawn_mango_tree(pos: Vector2, size: Vector2) -> MovableDecor:
	return _spawn_movable_decor("env_mango_tree", pos, size, true, true)

func try_plant_tree(world_pos: Vector2, tree_type: String) -> bool:
	var seed_id: String = "apple_seed" if tree_type == "apple" else "mango_seed"
	if not StorageManager.has_item(seed_id, 1):
		print("[MainFarm] Không đủ hạt giống: ", seed_id)
		AudioManager.play_sfx("error")
		return false
	
	var cell: Vector2i = GridManager.world_to_grid(world_pos)
	if not GridManager.is_within_bounds(cell):
		AudioManager.play_sfx("error")
		return false
	if GridManager.is_cell_occupied(cell) or GridManager.is_path_tile(cell):
		AudioManager.play_sfx("error")
		return false
	if _is_in_water_pond(world_pos):
		AudioManager.play_sfx("error")
		return false
	var fishing_rect: Rect2 = Rect2(Vector2(560.0, 560.0), Vector2(540.0, 300.0))
	if fishing_rect.has_point(world_pos):
		AudioManager.play_sfx("error")
		return false
	
	for d: MovableDecor in _movable_decors:
		if is_instance_valid(d) and world_pos.distance_to(d.global_position) < 32.0:
			AudioManager.play_sfx("error")
			return false
	
	StorageManager.remove_item(seed_id, 1)
	var sprite_id: String = "env_apple_tree" if tree_type == "apple" else "env_mango_tree"
	var decor: MovableDecor = _spawn_movable_decor(sprite_id, world_pos, Vector2(74, 78), true, true)
	decor.set_growth_stage(MovableDecor.TreeGrowthStage.STAGE_SAPLING)
	
	decor.scale = Vector2(0.2, 0.2)
	var tw: Tween = create_tween()
	tw.tween_property(decor, "scale", Vector2(0.65, 0.65), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(decor, "scale", Vector2(0.55, 0.55), 0.08)
	
	GridManager.add_attraction_score(5)
	save_custom_decorations()
	AudioManager.play_sfx("plant")
	print("[MainFarm] Planted new ", tree_type, " tree at ", world_pos)
	return true

func _spawn_swaying_tree(sprite_id: String, pos: Vector2, size: Vector2) -> MovableDecor:
	return _spawn_movable_decor(sprite_id, pos, size, true, true)

func _spawn_nature_decor(sprite_id: String, pos: Vector2, size: Vector2, _z_idx: int = 0, add_shadow: bool = true) -> Node2D:
	if sprite_id.begins_with("env_hill"):
		return _spawn_background_hill(sprite_id, pos, size)
	var sway: bool = "tree" in sprite_id
	return _spawn_movable_decor(sprite_id, pos, size, add_shadow, sway)

func remove_movable_decor(decor: MovableDecor) -> void:
	if decor in _movable_decors:
		_movable_decors.erase(decor)
	if is_instance_valid(decor):
		decor.queue_free()
	save_custom_decorations()

func on_decor_moved(_decor: MovableDecor) -> void:
	save_custom_decorations()

func save_custom_decorations() -> void:
	var list: Array = []
	_flower_targets.clear()
	for decor: MovableDecor in _movable_decors:
		if is_instance_valid(decor):
			var d_info: Dictionary = {
				"id": decor.decor_id,
				"x": decor.position.x,
				"y": decor.position.y,
				"w": decor.decor_size.x,
				"h": decor.decor_size.y,
				"shadow": decor.has_shadow,
				"sway": decor.is_swaying
			}
			if decor.is_fruit_tree:
				d_info["stage"] = int(decor.growth_stage)
				d_info["harvest_left"] = decor.harvest_left
				d_info["revived_once"] = decor.revived_once
			list.append(d_info)
			if "flower" in decor.decor_id or "tree" in decor.decor_id:
				_flower_targets.append(decor.position)
	SaveManager.custom_decorations = list
	SaveManager.save_game()

func auto_clear_decor_at_cell(cell: Vector2i) -> void:
	var cell_pos: Vector2 = GridManager.grid_to_world(cell)
	var moved_any: bool = false
	for i: int in range(_movable_decors.size() - 1, -1, -1):
		var decor: MovableDecor = _movable_decors[i]
		if not is_instance_valid(decor):
			continue
		if decor.position.distance_to(cell_pos) < 26.0:
			var target_pos: Vector2 = _find_nearest_empty_grass_pos(cell)
			if target_pos != Vector2.ZERO:
				var tw: Tween = create_tween()
				tw.tween_property(decor, "position", target_pos, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				moved_any = true
			else:
				_movable_decors.remove_at(i)
				decor.queue_free()
				moved_any = true
	if moved_any:
		save_custom_decorations()

func _find_nearest_empty_grass_pos(from_cell: Vector2i) -> Vector2:
	for radius: int in range(1, 6):
		for dx: int in range(-radius, radius + 1):
			for dy: int in range(-radius, radius + 1):
				if maxi(absi(dx), absi(dy)) != radius:
					continue
				var c: Vector2i = from_cell + Vector2i(dx, dy)
				if not GridManager.is_within_bounds(c):
					continue
				if GridManager.is_cell_occupied(c):
					continue
				if GridManager.is_path_tile(c):
					continue
				var world_pos: Vector2 = GridManager.grid_to_world(c)
				if _is_in_lake_zone(world_pos):
					continue
				var has_decor: bool = false
				for d: MovableDecor in _movable_decors:
					if is_instance_valid(d) and d.position.distance_to(world_pos) < 22.0:
						has_decor = true
						break
				if not has_decor:
					return world_pos
	return Vector2.ZERO

func _spawn_building_prop(sprite_id: String, cell: Vector2i, tile_size: Vector2i, max_size: Vector2 = Vector2(90, 90)) -> Sprite2D:
	for x: int in range(cell.x, cell.x + tile_size.x):
		for y: int in range(cell.y, cell.y + tile_size.y):
			var c: Vector2i = Vector2i(x, y)
			GridManager.occupied_cells[c] = 999
			GridManager.astar_grid.set_point_solid(c, true)

	var node_wrapper: Node2D = Node2D.new()
	node_wrapper.y_sort_enabled = true
	var center_pixel: Vector2 = Vector2(
		(float(cell.x) + float(tile_size.x) * 0.5) * 32.0,
		(float(cell.y) + float(tile_size.y) * 0.5) * 32.0
	)
	node_wrapper.position = center_pixel
	node_wrapper.set_meta("grid_pos", cell)
	node_wrapper.set_meta("tile_size", tile_size)
	node_wrapper.set_meta("sprite_id", sprite_id)
	buildings_container.add_child(node_wrapper)

	var shadow_sp: Sprite2D = _create_ellipse_shadow(Vector2(max_size.x * 0.75, max_size.y * 0.32))
	shadow_sp.position = Vector2(0, max_size.y * 0.32)
	shadow_sp.z_index = -1
	node_wrapper.add_child(shadow_sp)

	var sp: Sprite2D = Sprite2D.new()
	if SpriteAtlasManager.has_texture(sprite_id):
		sp.texture = SpriteAtlasManager.get_texture(sprite_id)
		SpriteAtlasManager.set_sprite_pixel_size(sp, max_size)
	sp.z_index = 1
	node_wrapper.add_child(sp)
	if sprite_id == "truck":
		_truck_prop = node_wrapper
		_truck_prop.position = Vector2(435.0, 660.0) if SaveManager._detect_test_mode() else Vector2(310.0, 650.0)
		_truck_prop.z_index = 2
		_truck_prop.add_to_group("interactable")
		_truck_prop.set_meta("interact_type", "truck")
	elif sprite_id == "barn" or sprite_id == "building_barn":
		_barn_prop = node_wrapper
		_barn_prop.add_to_group("interactable")
		_barn_prop.set_meta("interact_type", "barn")
		var lbl_barn: Label = Label.new()
		lbl_barn.text = SaveManager.get_building_name("building_barn", "📦 NHÀ KHO")
		lbl_barn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_barn.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_barn.position = Vector2(-60.0, -max_size.y * 0.65)
		lbl_barn.size = Vector2(120.0, 20.0)
		lbl_barn.z_index = 10
		lbl_barn.add_theme_font_size_override("font_size", 11)
		lbl_barn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
		lbl_barn.add_theme_color_override("font_outline_color", Color(0.2, 0.12, 0.05, 1.0))
		lbl_barn.add_theme_constant_override("outline_size", 3)
		node_wrapper.add_child(lbl_barn)
		var btn_barn_reloc: Button = Button.new()
		btn_barn_reloc.name = "RelocateBtn"
		btn_barn_reloc.text = "✥"
		btn_barn_reloc.tooltip_text = "Di chuyển / Quy hoạch Nhà Kho"
		btn_barn_reloc.position = Vector2(40.0, -max_size.y * 0.65)
		btn_barn_reloc.size = Vector2(22.0, 22.0)
		btn_barn_reloc.custom_minimum_size = Vector2(22.0, 22.0)
		btn_barn_reloc.z_index = 15
		btn_barn_reloc.mouse_filter = Control.MOUSE_FILTER_STOP
		btn_barn_reloc.visible = _is_relocating_mode
		var sb_b: StyleBoxFlat = StyleBoxFlat.new()
		sb_b.bg_color = Color(0.20, 0.14, 0.08, 0.85)
		sb_b.border_color = Color(0.95, 0.85, 0.55, 0.9)
		sb_b.set_border_width_all(1)
		sb_b.set_corner_radius_all(5)
		btn_barn_reloc.add_theme_stylebox_override("normal", sb_b)
		btn_barn_reloc.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
		btn_barn_reloc.add_theme_font_size_override("font_size", 11)
		btn_barn_reloc.pressed.connect(func() -> void: start_relocating_structure(node_wrapper))
		node_wrapper.add_child(btn_barn_reloc)
	elif sprite_id == "silo":
		_silo_prop = node_wrapper
		_silo_prop.add_to_group("interactable")
		_silo_prop.set_meta("interact_type", "silo")
		var lbl_silo: Label = Label.new()
		lbl_silo.text = SaveManager.get_building_name("building_silo", "🌾 KHO SILO")
		lbl_silo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_silo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_silo.position = Vector2(-60.0, -max_size.y * 0.65)
		lbl_silo.size = Vector2(120.0, 20.0)
		lbl_silo.z_index = 10
		lbl_silo.add_theme_font_size_override("font_size", 11)
		lbl_silo.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
		lbl_silo.add_theme_color_override("font_outline_color", Color(0.2, 0.12, 0.05, 1.0))
		lbl_silo.add_theme_constant_override("outline_size", 3)
		node_wrapper.add_child(lbl_silo)
		var btn_silo_reloc: Button = Button.new()
		btn_silo_reloc.name = "RelocateBtn"
		btn_silo_reloc.text = "✥"
		btn_silo_reloc.tooltip_text = "Di chuyển / Quy hoạch Kho Silo"
		btn_silo_reloc.position = Vector2(40.0, -max_size.y * 0.65)
		btn_silo_reloc.size = Vector2(22.0, 22.0)
		btn_silo_reloc.custom_minimum_size = Vector2(22.0, 22.0)
		btn_silo_reloc.z_index = 15
		btn_silo_reloc.mouse_filter = Control.MOUSE_FILTER_STOP
		btn_silo_reloc.visible = _is_relocating_mode
		var sb_s: StyleBoxFlat = StyleBoxFlat.new()
		sb_s.bg_color = Color(0.20, 0.14, 0.08, 0.85)
		sb_s.border_color = Color(0.95, 0.85, 0.55, 0.9)
		sb_s.set_border_width_all(1)
		sb_s.set_corner_radius_all(5)
		btn_silo_reloc.add_theme_stylebox_override("normal", sb_s)
		btn_silo_reloc.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
		btn_silo_reloc.add_theme_font_size_override("font_size", 11)
		btn_silo_reloc.pressed.connect(func() -> void: start_relocating_structure(node_wrapper))
		node_wrapper.add_child(btn_silo_reloc)
	elif sprite_id == "building_mini_zoo" or sprite_id == "mini_zoo":
		var lbl_zoo: Label = Label.new()
		lbl_zoo.text = SaveManager.get_building_name("mini_zoo", "🎪 KHU SỞ THÚ")
		lbl_zoo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_zoo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_zoo.position = Vector2(-60.0, -max_size.y * 0.65)
		lbl_zoo.size = Vector2(120.0, 20.0)
		lbl_zoo.z_index = 10
		lbl_zoo.add_theme_font_size_override("font_size", 11)
		lbl_zoo.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
		lbl_zoo.add_theme_color_override("font_outline_color", Color(0.2, 0.12, 0.05, 1.0))
		lbl_zoo.add_theme_constant_override("outline_size", 3)
		node_wrapper.add_child(lbl_zoo)
		
		# Spawn Horse and Donkey inside / near Mini Zoo paddock
		if SpriteAtlasManager.has_texture("animal_horse"):
			var horse_sp: Sprite2D = Sprite2D.new()
			horse_sp.name = "ZooHorse"
			horse_sp.texture = SpriteAtlasManager.get_texture("animal_horse")
			SpriteAtlasManager.set_sprite_pixel_size(horse_sp, Vector2(36, 36))
			horse_sp.position = Vector2(-28.0, 18.0)
			horse_sp.z_index = 2
			node_wrapper.add_child(horse_sp)
			
			var tw_h: Tween = node_wrapper.create_tween().set_loops()
			tw_h.tween_property(horse_sp, "scale:y", horse_sp.scale.y * 1.05, 1.2).set_trans(Tween.TRANS_SINE)
			tw_h.tween_property(horse_sp, "scale:y", horse_sp.scale.y, 1.2).set_trans(Tween.TRANS_SINE)
			
		if SpriteAtlasManager.has_texture("animal_donkey"):
			var donkey_sp: Sprite2D = Sprite2D.new()
			donkey_sp.name = "ZooDonkey"
			donkey_sp.texture = SpriteAtlasManager.get_texture("animal_donkey")
			SpriteAtlasManager.set_sprite_pixel_size(donkey_sp, Vector2(34, 34))
			donkey_sp.position = Vector2(28.0, 20.0)
			donkey_sp.z_index = 2
			node_wrapper.add_child(donkey_sp)
			
			var tw_d: Tween = node_wrapper.create_tween().set_loops()
			tw_d.tween_property(donkey_sp, "scale:y", donkey_sp.scale.y * 1.06, 1.0).set_trans(Tween.TRANS_SINE)
			tw_d.tween_property(donkey_sp, "scale:y", donkey_sp.scale.y, 1.0).set_trans(Tween.TRANS_SINE)
	elif sprite_id == "roadside_shop":
		_roadside_shop_prop = node_wrapper
		_roadside_shop_prop.add_to_group("interactable")
		_roadside_shop_prop.set_meta("interact_type", "roadside_shop")
		var btn_shop_reloc: Button = Button.new()
		btn_shop_reloc.name = "RelocateBtn"
		btn_shop_reloc.text = "✥"
		btn_shop_reloc.tooltip_text = "Di chuyển / Quy hoạch Sạp Hàng"
		btn_shop_reloc.position = Vector2(28.0, -max_size.y * 0.65)
		btn_shop_reloc.size = Vector2(22.0, 22.0)
		btn_shop_reloc.custom_minimum_size = Vector2(22.0, 22.0)
		btn_shop_reloc.z_index = 15
		btn_shop_reloc.mouse_filter = Control.MOUSE_FILTER_STOP
		btn_shop_reloc.visible = _is_relocating_mode
		var sb_sh: StyleBoxFlat = StyleBoxFlat.new()
		sb_sh.bg_color = Color(0.20, 0.14, 0.08, 0.85)
		sb_sh.border_color = Color(0.95, 0.85, 0.55, 0.9)
		sb_sh.set_border_width_all(1)
		sb_sh.set_corner_radius_all(5)
		btn_shop_reloc.add_theme_stylebox_override("normal", sb_sh)
		btn_shop_reloc.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
		btn_shop_reloc.add_theme_font_size_override("font_size", 11)
		btn_shop_reloc.pressed.connect(func() -> void: start_relocating_structure(node_wrapper))
		node_wrapper.add_child(btn_shop_reloc)
	return sp

func _spawn_production_machine(m_id: String, cell: Vector2i) -> ProductionMachine:
	for x: int in range(cell.x, cell.x + 3):
		for y: int in range(cell.y, cell.y + 3):
			var c: Vector2i = Vector2i(x, y)
			GridManager.occupied_cells[c] = 888
			GridManager.astar_grid.set_point_solid(c, true)

	var machine: ProductionMachine = ProductionMachine.new()
	machine.name = m_id
	machine.y_sort_enabled = true
	machine.machine_id = m_id
	machine.grid_pos = cell
	var center_pixel: Vector2 = Vector2(
		(float(cell.x) + 1.5) * 32.0,
		(float(cell.y) + 1.5) * 32.0
	)
	machine.position = center_pixel
	buildings_container.add_child(machine)
	if machine.get("_btn_relocate") != null:
		(machine.get("_btn_relocate") as Control).visible = _is_relocating_mode
	_production_machines.append(machine)
	return machine

func _spawn_animal_pen(a_id: String, cell: Vector2i, count: int) -> AnimalPen:
	for x: int in range(cell.x, cell.x + 4):
		for y: int in range(cell.y, cell.y + 3):
			var c: Vector2i = Vector2i(x, y)
			GridManager.occupied_cells[c] = 777
			GridManager.astar_grid.set_point_solid(c, true)

	var pen: AnimalPen = AnimalPen.new()
	pen.y_sort_enabled = true
	pen.animal_id = a_id
	pen.animal_count = count
	pen.grid_pos = cell
	var center_pixel: Vector2 = Vector2(
		(float(cell.x) + 2.0) * 32.0,
		(float(cell.y) + 1.5) * 32.0
	)
	pen.position = center_pixel
	animal_pens_container.add_child(pen)
	if pen.get("_btn_relocate") != null:
		(pen.get("_btn_relocate") as Control).visible = _is_relocating_mode
	_animal_pens.append(pen)
	return pen

func _spawn_fishing_spot(cell: Vector2i) -> FishingSpot:
	for x: int in range(cell.x, cell.x + 3):
		for y: int in range(cell.y, cell.y + 3):
			var c: Vector2i = Vector2i(x, y)
			GridManager.occupied_cells[c] = 666
			GridManager.astar_grid.set_point_solid(c, true)

	fishing_spot = FishingSpot.new()
	fishing_spot.y_sort_enabled = true
	fishing_spot.grid_pos = cell
	fishing_spot.position = Vector2.ZERO
	buildings_container.add_child(fishing_spot)
	return fishing_spot

var _shadow_texture_cache: Dictionary = {}

func _create_ellipse_shadow(size: Vector2) -> Sprite2D:
	var key: Vector2i = Vector2i(maxi(1, int(round(size.x))), maxi(1, int(round(size.y))))
	var tex: ImageTexture = _shadow_texture_cache.get(key, null) as ImageTexture
	if tex == null:
		var img: Image = Image.create(key.x, key.y, false, Image.FORMAT_RGBA8)
		var cx: float = float(img.get_width()) * 0.5
		var cy: float = float(img.get_height()) * 0.5
		var rx: float = cx
		var ry: float = cy
		var shadow_color: Color = Color(0.42, 0.30, 0.21, 0.22)

		for x: int in range(img.get_width()):
			for y: int in range(img.get_height()):
				var dx: float = (float(x) - cx) / rx
				var dy: float = (float(y) - cy) / ry
				var dist_sq: float = dx * dx + dy * dy
				if dist_sq <= 1.0:
					var alpha: float = (1.0 - dist_sq) * shadow_color.a
					img.set_pixel(x, y, Color(shadow_color.r, shadow_color.g, shadow_color.b, alpha))
				else:
					img.set_pixel(x, y, Color(0, 0, 0, 0))

		tex = ImageTexture.create_from_image(img)
		_shadow_texture_cache[key] = tex
	var sp: Sprite2D = Sprite2D.new()
	sp.texture = tex
	return sp

func _spawn_field_plot(cell: Vector2i, _inst_id: int) -> FieldPlot:
	var plot: FieldPlot = FieldPlot.new()
	plot.grid_pos = cell
	plot.position = GridManager.grid_to_world(cell)
	plots_container.add_child(plot)
	field_plots[cell] = plot
	return plot

func get_field_plot_at(cell: Vector2i) -> FieldPlot:
	return field_plots.get(cell, null) as FieldPlot

func _on_building_placed(inst_id: int, building_id: String, grid_pos: Vector2i) -> void:
	auto_clear_decor_at_cell(grid_pos)
	if building_id == "field_plot":
		_spawn_field_plot(grid_pos, inst_id)

func _on_building_removed(_inst_id: int, grid_pos: Vector2i) -> void:
	if field_plots.has(grid_pos):
		var plot: FieldPlot = field_plots[grid_pos] as FieldPlot
		plot.queue_free()
		field_plots.erase(grid_pos)

func _on_path_tile_changed(grid_pos: Vector2i, is_path: bool) -> void:
	if is_path:
		auto_clear_decor_at_cell(grid_pos)
	if _road_tilemap_layer != null:
		if is_path:
			_road_tilemap_layer.set_cell(grid_pos, 0, Vector2i.ZERO)
		else:
			_road_tilemap_layer.erase_cell(grid_pos)
	else:
		queue_redraw()

func _paint_road_speck(img: Image, center: Vector2, radius: float, col: Color) -> void:
	var r_ceil: int = int(ceil(radius)) + 1
	var r_sq: float = radius * radius
	var cx_i: int = int(round(center.x))
	var cy_i: int = int(round(center.y))
	for py: int in range(maxi(1, cy_i - r_ceil), mini(31, cy_i + r_ceil + 1)):
		for px: int in range(maxi(1, cx_i - r_ceil), mini(31, cx_i + r_ceil + 1)):
			var dx: float = float(px) + 0.5 - center.x
			var dy: float = float(py) + 0.5 - center.y
			if dx * dx + dy * dy <= r_sq:
				img.set_pixel(px, py, col)

func _setup_road_tilemap_layer() -> void:
	if _road_tilemap_layer != null:
		return
	var img: Image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var road_base: Color = Color(0.953, 0.898, 0.671, 1.0)
	var road_border: Color = Color(0.788, 0.651, 0.420, 1.0)
	var road_grain: Color = Color(0.86, 0.74, 0.50, 1.0)
	img.fill(road_base)
	for x: int in range(32):
		img.set_pixel(x, 0, road_border)
		img.set_pixel(x, 31, road_border)
	for y: int in range(32):
		img.set_pixel(0, y, road_border)
		img.set_pixel(31, y, road_border)
	_paint_road_speck(img, Vector2(7.0, 7.0), 1.8, road_grain)
	_paint_road_speck(img, Vector2(24.0, 11.0), 2.2, road_grain)
	_paint_road_speck(img, Vector2(11.0, 23.0), 2.0, road_grain)

	var tex: ImageTexture = ImageTexture.create_from_image(img)
	var atlas_src: TileSetAtlasSource = TileSetAtlasSource.new()
	atlas_src.texture = tex
	atlas_src.texture_region_size = Vector2i(32, 32)
	atlas_src.create_tile(Vector2i.ZERO)

	var tile_set: TileSet = TileSet.new()
	tile_set.tile_size = Vector2i(32, 32)
	tile_set.add_source(atlas_src, 0)

	_road_tilemap_layer = TileMapLayer.new()
	_road_tilemap_layer.name = "RoadTileMapLayer"
	_road_tilemap_layer.tile_set = tile_set
	_road_tilemap_layer.z_index = 0
	var path_layer: Node = get_node_or_null("PathLayer")
	if path_layer != null:
		path_layer.add_child(_road_tilemap_layer)
	else:
		add_child(_road_tilemap_layer)

func _sync_road_tilemap() -> void:
	if _road_tilemap_layer == null:
		return
	_road_tilemap_layer.clear()
	for path_cell: Variant in GridManager.path_cells:
		if bool(GridManager.path_cells[path_cell]):
			_road_tilemap_layer.set_cell(path_cell as Vector2i, 0, Vector2i.ZERO)

func _draw_prairie_hill_band(start_pos: Vector2, span_w: float, band_h: float, col: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	const STEPS: int = 36
	for i: int in range(STEPS + 1):
		var frac: float = float(i) / float(STEPS)
		var px: float = start_pos.x + frac * span_w
		var py: float = start_pos.y + sin(frac * TAU * 1.5 + start_pos.y * 0.01) * 14.0
		pts.append(Vector2(px, py))
	for i: int in range(STEPS, -1, -1):
		var frac: float = float(i) / float(STEPS)
		var px: float = start_pos.x + frac * span_w
		var py: float = start_pos.y + band_h + sin(frac * TAU * 1.5 + start_pos.y * 0.01 + 0.6) * 12.0
		pts.append(Vector2(px, py))
	draw_colored_polygon(pts, col)

func _draw() -> void:
	var total_w: float = float(GridManager.GRID_WIDTH * int(GridManager.CELL_SIZE.x))
	var total_h: float = float(GridManager.GRID_HEIGHT * int(GridManager.CELL_SIZE.y))

	# Background is seamlessly provided by ChibiMeadowBackdrop Sprite2D (z_index = -50)

	# 2. Subtle Grid Lines (ONLY when placing Field/Path)
	var show_grid: bool = false
	if drag_action_manager != null:
		var cur_tool: DragActionManager.ToolType = drag_action_manager.current_tool
		show_grid = (cur_tool == DragActionManager.ToolType.BUILD_FIELD or cur_tool == DragActionManager.ToolType.BUILD_PATH)

	if show_grid:
		var grid_line_color: Color = Color(0.42, 0.30, 0.21, 0.16)
		for x: int in range(0, GridManager.GRID_WIDTH + 1):
			var px: float = float(x * int(GridManager.CELL_SIZE.x))
			draw_line(Vector2(px, 0), Vector2(px, total_h), grid_line_color, 1.0)
		for y: int in range(0, GridManager.GRID_HEIGHT + 1):
			var py: float = float(y * int(GridManager.CELL_SIZE.y))
			draw_line(Vector2(0, py), Vector2(total_w, py), grid_line_color, 1.0)

	# 3. Cozy Buttercream Terracotta Roads rendered in batch by RoadTileMapLayer (TileMapLayer)
	if _road_tilemap_layer == null:
		var road_base: Color = Color(0.953, 0.898, 0.671) # #F3E5AB
		var road_border: Color = Color(0.788, 0.651, 0.420) # #C9A66B
		var road_grain: Color = Color(0.86, 0.74, 0.50)

		for path_cell: Variant in GridManager.path_cells:
			var c: Vector2i = path_cell as Vector2i
			var pos: Vector2 = Vector2(c.x * 32, c.y * 32)
			var r: Rect2 = Rect2(pos, Vector2(32, 32))
			draw_rect(r, road_base, true)
			draw_rect(r, road_border, false, 1.2)
			draw_circle(pos + Vector2(7, 7), 1.8, road_grain)
			draw_circle(pos + Vector2(24, 11), 2.2, road_grain)
			draw_circle(pos + Vector2(11, 23), 2.0, road_grain)

	# 4. Perimeter Hand-drawn Border
	var fence_col: Color = Color(0.42, 0.30, 0.21, 0.6)
	draw_rect(Rect2(0, 0, total_w, total_h), fence_col, false, 3.0)

	# Entrance Gate marker at (0, 20)
	var gate_pos: Vector2 = Vector2(0, 20 * 32)
	draw_rect(Rect2(gate_pos, Vector2(12, 32)), Color(0.96, 0.82, 0.45), true)
	draw_rect(Rect2(gate_pos, Vector2(12, 32)), Color(0.42, 0.30, 0.21), false, 1.8)

func _spawn_new_props_and_pets() -> void:
	# 1. Hòm Thư "Báo Nông Thôn" bên trái Sạp Hàng Ven Đường
	if mailbox_newspaper_prop == null:
		mailbox_newspaper_prop = MailboxNewspaperPropClass.new()
		mailbox_newspaper_prop.name = "MailboxNewspaperProp"
		mailbox_newspaper_prop.position = Vector2(110.0, 740.0)
		buildings_container.add_child(mailbox_newspaper_prop)

	# 2. Nhà Gỗ Chó Poodle tại Zone 1 - Homestead Plaza (660, 230)
	if pet_house_poodle == null:
		pet_house_poodle = PetHousePoodleClass.new()
		pet_house_poodle.name = "PetHousePoodle"
		pet_house_poodle.position = Vector2(660.0, 230.0)
		buildings_container.add_child(pet_house_poodle)

	# 3. Chú Chó Poodle Chibi đi theo chủ
	if pet_poodle == null:
		pet_poodle = PetPoodleClass.new()
		pet_poodle.name = "PetPoodle"
		pet_poodle.position = Vector2(690.0, 245.0)
		add_child(pet_poodle)

	# 4. Bến Tàu Hơi Nước Trên Sông tại bờ Tây phía Bắc Cầu Gỗ (875, 310)
	if river_steamboat == null:
		river_steamboat = RiverSteamboatClass.new()
		river_steamboat.name = "RiverSteamboat"
		river_steamboat.position = Vector2(875.0, 310.0)
		river_steamboat.z_index = 5
		add_child(river_steamboat)

	# 5. Cây Tổ Ong Mật & Đàn Ong Chibi tại vườn hoa Tây (145, 355)
	if beehive_tree == null:
		beehive_tree = BeehiveTreeClass.new()
		beehive_tree.name = "BeehiveTree"
		beehive_tree.position = Vector2(145.0, 355.0)
		beehive_tree.z_index = 6
		buildings_container.add_child(beehive_tree)

func _capture_screenshot_and_quit() -> void:
	SaveManager.set_sandbox_level_33()
	# 1. Capture East Bank Zoo Sanctuary with Hot Air Balloon and Horizontal Top Bar
	if camera_2d != null:
		camera_2d.position = Vector2(1420.0, 310.0)
		camera_2d.zoom = Vector2(0.85, 0.85)
		camera_2d.target_zoom = Vector2(0.85, 0.85)
	
	await get_tree().create_timer(3.0).timeout
	await RenderingServer.frame_post_draw
	var vp: Viewport = get_viewport()
	var img: Image = vp.get_texture().get_image()
	if img != null and not img.is_empty():
		var save_path: String = ProjectSettings.globalize_path("res://debug_preview.png")
		img.save_png(save_path)
		print("[MainFarm] Captured zoo preview to ", save_path)
	
	# 2. Capture West Bank Farm Overview (Fields, Poodle, Kennel, Mailbox, Roadside Shop)
	if camera_2d != null:
		camera_2d.position = Vector2(360.0, 520.0)
		camera_2d.zoom = Vector2(0.95, 0.95)
		camera_2d.target_zoom = Vector2(0.95, 0.95)
		await get_tree().create_timer(0.6).timeout
		await RenderingServer.frame_post_draw
		var img_farm: Image = vp.get_texture().get_image()
		if img_farm != null and not img_farm.is_empty():
			img_farm.save_png(ProjectSettings.globalize_path("res://debug_farm_west.png"))
			print("[MainFarm] Captured west farm preview to res://debug_farm_west.png")
	
	# 3. Capture Zoo Feed Shop Modal
	if ui_hud != null and ui_hud.has_method("open_zoo_feed_shop_modal"):
		ui_hud.call("open_zoo_feed_shop_modal")
		await get_tree().create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		var img_shop: Image = vp.get_texture().get_image()
		if img_shop != null and not img_shop.is_empty():
			img_shop.save_png(ProjectSettings.globalize_path("res://debug_feed_shop.png"))
			print("[MainFarm] Captured Zoo Feed Shop modal to res://debug_feed_shop.png")
		var s_modal: PanelContainer = ui_hud.get("_zoo_feed_shop_modal") as PanelContainer
		if s_modal != null:
			s_modal.queue_free()

	# 4. Capture Newspaper Modal
	if ui_hud != null and ui_hud.has_method("open_newspaper_modal"):
		ui_hud.call("open_newspaper_modal")
		await get_tree().create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		var img_news: Image = vp.get_texture().get_image()
		if img_news != null and not img_news.is_empty():
			img_news.save_png(ProjectSettings.globalize_path("res://debug_newspaper.png"))
			print("[MainFarm] Captured Daily Newspaper modal to res://debug_newspaper.png")
		var n_modal: PanelContainer = ui_hud.get("_newspaper_modal") as PanelContainer
		if n_modal != null:
			n_modal.queue_free()

	# 5. Capture Hot Air Balloon Modal
	if ui_hud != null and ui_hud.has_method("open_hot_air_balloon_modal"):
		ui_hud.call("open_hot_air_balloon_modal")
		await get_tree().create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		var img_bal: Image = vp.get_texture().get_image()
		if img_bal != null and not img_bal.is_empty():
			img_bal.save_png(ProjectSettings.globalize_path("res://debug_balloon.png"))
			print("[MainFarm] Captured Hot Air Balloon modal to res://debug_balloon.png")
		var b_modal: PanelContainer = ui_hud.get("_hot_air_balloon_modal") as PanelContainer
		if b_modal != null:
			b_modal.queue_free()
			
	get_tree().quit()

func play_truck_delivery_animation() -> void:
	if _truck_prop == null or not is_instance_valid(_truck_prop):
		return
	var orig_pos: Vector2 = Vector2(435.0, 660.0) if SaveManager._detect_test_mode() else Vector2(310.0, 650.0)
	_truck_prop.position = orig_pos
	var exit_x: float = -80.0
	
	var sp: Sprite2D = null
	for ch: Node in _truck_prop.get_children():
		if ch is Sprite2D and ch.z_index >= 0:
			sp = ch as Sprite2D
			break
	if sp != null:
		sp.flip_h = false
	
	var tw: Tween = create_tween().set_parallel(false)
	tw.tween_property(_truck_prop, "scale", Vector2(1.15, 0.85), 0.1)
	tw.tween_property(_truck_prop, "scale", Vector2.ONE, 0.1)
	
	var drive_tw: Tween = create_tween().set_parallel(false)
	drive_tw.tween_property(_truck_prop, "position:x", exit_x, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	await drive_tw.finished
	if not is_instance_valid(_truck_prop):
		return
	
	await get_tree().create_timer(0.6).timeout
	if not is_instance_valid(_truck_prop):
		return
	
	if sp != null:
		sp.flip_h = true
	
	var return_tw: Tween = create_tween().set_parallel(false)
	return_tw.tween_property(_truck_prop, "position:x", orig_pos.x, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	await return_tw.finished
	if is_instance_valid(_truck_prop):
		_truck_prop.position = orig_pos
		if sp != null:
			sp.flip_h = false
		var end_bounce: Tween = create_tween()
		end_bounce.tween_property(_truck_prop, "scale", Vector2(1.12, 0.9), 0.1)
		end_bounce.tween_property(_truck_prop, "scale", Vector2.ONE, 0.1)

func simulate_click_at_world_pos(world_pos: Vector2) -> bool:
	# 0a. Di chuyển / Quy hoạch công trình khi dùng công cụ THÁO DỠ (DISMANTLE / DEMOLISH)
	var is_dismantle_tool: bool = (drag_action_manager != null and (drag_action_manager.current_tool == DragActionManager.ToolType.DISMANTLE or int(drag_action_manager.current_tool) == 9))
	if is_dismantle_tool:
		if try_relocate_structure_at_pos(world_pos):
			drag_action_manager.set_tool(DragActionManager.ToolType.NONE)
			if ui_hud != null and ui_hud.has_method("cancel_all_active_tools"):
				ui_hud.call("cancel_all_active_tools")
			return true
	# 0. Ô Ruộng (FieldPlot - Contextual interaction: Thu hoạch chín hoặc Bật menu hạt giống)
	var clicked_cell: Vector2i = GridManager.world_to_grid(world_pos)
	var plot: FieldPlot = get_field_plot_at(clicked_cell)
	if plot != null and is_instance_valid(plot):
		plot.handle_direct_click()
		return true

	# 0b. Specialized NPCs (Bong bóng thông báo & phản ứng nhún)
	for npc: Node2D in _specialized_npcs:
		if is_instance_valid(npc) and world_pos.distance_to(npc.global_position) <= 28.0:
			if npc.has_method("_on_npc_clicked"):
				npc.call("_on_npc_clicked")
			return true

	# 1. Cây Ăn Quả (Táo & Xoài, bán kính <= 60px)
	for decor: MovableDecor in _movable_decors:
		if is_instance_valid(decor) and decor.is_fruit_tree:
			if world_pos.distance_to(decor.global_position) <= 60.0:
				if decor.growth_stage == MovableDecor.TreeGrowthStage.STAGE_WITHERED:
					return decor.try_interact_withered()
				elif decor.is_ripe:
					return decor.try_harvest()
	
	# 2. Chuồng Bò / Động vật (bán kính <= 95px)
	for pen: AnimalPen in _animal_pens:
		if is_instance_valid(pen) and pen.visible:
			if world_pos.distance_to(pen.global_position) <= 95.0:
				return pen.handle_pen_click()
	
	# 3. Máy Sản Xuất (Lò bánh mì, Máy xay thức ăn, bán kính <= 75px)
	for machine: ProductionMachine in _production_machines:
		if is_instance_valid(machine) and machine.visible:
			if world_pos.distance_to(machine.global_position) <= 75.0:
				return machine.handle_machine_click()
	
	# 4. Du Khách Tham Quan (VisitorNPC, bán kính <= 55px)
	if visitor_manager != null:
		var visitors: Array[VisitorNPC] = visitor_manager.get_active_visitors()
		for visitor: VisitorNPC in visitors:
			if is_instance_valid(visitor) and visitor.state != VisitorNPC.VisitorState.INACTIVE:
				if world_pos.distance_to(visitor.global_position) <= 55.0:
					return visitor.handle_visitor_click()

	# 5. Nhà Câu Cá & Bến Nước Sông (không đè lên mặt Cầu Gỗ)
	if fishing_spot != null and is_instance_valid(fishing_spot):
		if fishing_spot.fishing_rect.has_point(world_pos) or world_pos.distance_to(Vector2(790.0, 745.0)) <= 80.0:
			if fishing_spot.state == FishingSpot.SpotState.READY:
				return fishing_spot.handle_fishing_click()
	
	# 6. Nhà Kho (Barn), Kho Silo & Xe Tải
	if _barn_prop != null and is_instance_valid(_barn_prop):
		if world_pos.distance_to(_barn_prop.global_position) <= 65.0:
			if ui_hud != null:
				ui_hud.open_storage_popup("barn")
				return true
	if _silo_prop != null and is_instance_valid(_silo_prop):
		if world_pos.distance_to(_silo_prop.global_position) <= 65.0:
			if ui_hud != null:
				ui_hud.open_storage_popup("silo")
				return true
	if _truck_prop != null and is_instance_valid(_truck_prop):
		if world_pos.distance_to(_truck_prop.global_position) <= 65.0:
			if ui_hud != null:
				ui_hud.toggle_truck_popup()
				return true
	if _roadside_shop_prop != null and is_instance_valid(_roadside_shop_prop):
		if world_pos.distance_to(_roadside_shop_prop.global_position) <= 65.0:
			if ui_hud != null:
				if ui_hud.has_method("open_roadside_shop_modal"):
					ui_hud.open_roadside_shop_modal()
				elif ui_hud.has_method("toggle_shop_popup"):
					ui_hud.toggle_shop_popup()
				return true
	
	return false

func interact_with_prop(prop_node: Node2D) -> void:
	if not is_instance_valid(prop_node):
		return
	var itype: String = String(prop_node.get_meta("interact_type", ""))
	if itype == "barn":
		if ui_hud != null: ui_hud.open_storage_popup("barn")
	elif itype == "silo":
		if ui_hud != null: ui_hud.open_storage_popup("silo")
	elif itype == "truck":
		if ui_hud != null: ui_hud.toggle_truck_popup()
	elif itype == "roadside_shop":
		if ui_hud != null:
			if ui_hud.has_method("open_roadside_shop_modal"):
				ui_hud.open_roadside_shop_modal()
			elif ui_hud.has_method("toggle_shop_popup"):
				ui_hud.toggle_shop_popup()
	elif itype == "zoo_feed_shop":
		if ui_hud != null: ui_hud.open_zoo_feed_shop_modal()
	elif itype == "zoo_entrance":
		if ui_hud != null: ui_hud.open_zoo_modal()

func cancel_pending_build() -> void:
	_pending_build_id = ""
	if _ghost_preview_node != null:
		_ghost_preview_node.visible = false

func _input(event: InputEvent) -> void:
	if _relocating_node != null:
		if event is InputEventMouseMotion:
			_update_relocating_structure_preview(get_global_mouse_position())
		elif event is InputEventMouseButton:
			var mb: InputEventMouseButton = event as InputEventMouseButton
			if mb.is_pressed():
				if mb.button_index == MOUSE_BUTTON_LEFT:
					if Time.get_ticks_msec() - _relocating_start_msec >= 180:
						_handle_relocate_placement_click(get_global_mouse_position())
						get_viewport().set_input_as_handled()
				elif mb.button_index == MOUSE_BUTTON_RIGHT:
					_cancel_relocating_structure()
					get_viewport().set_input_as_handled()
		elif event is InputEventKey:
			var ek: InputEventKey = event as InputEventKey
			if ek.is_pressed() and (ek.keycode == KEY_ESCAPE or event.is_action_pressed("ui_cancel")):
				_cancel_relocating_structure()
				get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if _relocating_node != null:
		return
	if _pending_build_id != "":
		if event is InputEventMouseMotion:
			_update_ghost_building_preview(get_global_mouse_position())
		elif event is InputEventMouseButton:
			var mb: InputEventMouseButton = event as InputEventMouseButton
			if mb.is_pressed():
				if mb.button_index == MOUSE_BUTTON_LEFT:
					_handle_building_placement_click(get_global_mouse_position())
					get_viewport().set_input_as_handled()
				elif mb.button_index == MOUSE_BUTTON_RIGHT:
					cancel_pending_build()
					get_viewport().set_input_as_handled()
		elif event is InputEventKey:
			var ek: InputEventKey = event as InputEventKey
			if ek.is_pressed() and (ek.keycode == KEY_ESCAPE or event.is_action_pressed("ui_cancel")):
				cancel_pending_build()
				get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion:
		if drag_action_manager != null and drag_action_manager.current_tool != DragActionManager.ToolType.NONE and drag_action_manager.current_tool != DragActionManager.ToolType.SICKLE:
			_update_ghost_placement_preview(get_global_mouse_position())
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.is_pressed():
			var cur_tool: DragActionManager.ToolType = drag_action_manager.current_tool if drag_action_manager != null else DragActionManager.ToolType.NONE
			if cur_tool == DragActionManager.ToolType.BUILD_FIELD or cur_tool == DragActionManager.ToolType.BUILD_PATH:
				return
			
			var mpos: Vector2 = get_global_mouse_position()
			if simulate_click_at_world_pos(mpos):
				if camera_2d != null:
					camera_2d.set("_is_panning", false)
				get_viewport().set_input_as_handled()

func _spawn_scenic_element(sprite_id: String, pos: Vector2, size: Vector2, z_offset: int = 0) -> Node2D:
	if not SpriteAtlasManager.has_texture(sprite_id):
		return null
	var sp: Sprite2D = SpriteAtlasManager.create_sized_sprite(sprite_id, size)
	if sp == null:
		return null
	
	var node: Node2D = Node2D.new()
	node.name = "Scenic_" + sprite_id + "_" + str(_scenic_elements.size())
	node.position = pos
	node.y_sort_enabled = true
	node.z_index = z_offset
	sp.position = Vector2(0.0, -size.y * 0.42)
	node.add_child(sp)
	
	var shadow: Polygon2D = ChibiSceneryBuilderClass.create_ellipse_shadow(size.x * 0.38, size.x * 0.16)
	shadow.position = Vector2.ZERO
	node.add_child(shadow)
	node.move_child(shadow, 0)
	
	if _scenery_container != null:
		_scenery_container.add_child(node)
	elif _scenic_valley_container != null:
		_scenic_valley_container.add_child(node)
	_scenic_elements.append(node)
	return node

func _spawn_scenic_valley_environment() -> void:
	if _horizon_container == null or _scenery_container == null:
		return
	var builder: RefCounted = ChibiSceneryBuilderClass.new()
	builder.call("build_scenery", _horizon_container, _scenery_container, _scenic_elements)
	print("[MainFarm] Spawned Harmonious Hay Day Scenic Valley with ", _scenic_elements.size(), " elements!")
	_relocate_overlapping_trees()

func _relocate_overlapping_trees() -> void:
	if field_plots.is_empty():
		return
	var plot_positions: Array[Vector2] = []
	for p: FieldPlot in field_plots.values():
		if is_instance_valid(p):
			plot_positions.append(p.global_position)

	var candidates: Array[Node2D] = []
	if _scenery_container != null:
		for child: Node in _scenery_container.get_children():
			if child is Node2D:
				candidates.append(child as Node2D)
	for d: MovableDecor in _movable_decors:
		if is_instance_valid(d):
			candidates.append(d)

	for tree_node: Node2D in candidates:
		var t_pos: Vector2 = tree_node.global_position
		var is_overlapping: bool = false
		for p_pos: Vector2 in plot_positions:
			if t_pos.distance_to(p_pos) < 52.0:
				is_overlapping = true
				break

		if is_overlapping:
			var tree_cell: Vector2i = GridManager.world_to_grid(t_pos)
			var relocated: bool = false
			for radius: int in range(2, 9):
				for ox: int in range(-radius, radius + 1):
					for oy: int in range(-radius, radius + 1):
						if absi(ox) != radius and absi(oy) != radius:
							continue
						var test_cell: Vector2i = tree_cell + Vector2i(ox, oy)
						if not GridManager.is_within_bounds(test_cell):
							continue
						var wpos: Vector2 = GridManager.grid_to_world(test_cell)
						if GridManager.is_in_water_or_sand(wpos) or GridManager.is_cell_occupied(test_cell):
							continue
						var too_close: bool = false
						for p_pos: Vector2 in plot_positions:
							if wpos.distance_to(p_pos) < 64.0:
								too_close = true
								break
						if not too_close:
							tree_node.global_position = wpos
							relocated = true
							print("[MainFarm] Auto-relocated overlapping tree from ", t_pos, " to ", wpos)
							break
					if relocated:
						break
				if relocated:
					break

func _spawn_specialized_npcs() -> void:
	if _specialized_npcs_container != null and is_instance_valid(_specialized_npcs_container):
		return
	
	_specialized_npcs_container = Node2D.new()
	_specialized_npcs_container.name = "SpecializedNPCsContainer"
	_specialized_npcs_container.y_sort_enabled = true
	add_child(_specialized_npcs_container)

	# Tính toán vị trí thực tế của Quầy Nước Pha Chế (juice_stand) và Nhà Câu Cá (fishing_spot)
	var barista_pos: Vector2 = Vector2(592.0, 509.0)
	for m: ProductionMachine in _production_machines:
		if m.machine_id == "juice_stand":
			barista_pos = m.position + Vector2(0.0, 45.0)
			break

	var fisher_pos: Vector2 = Vector2(790.0, 745.0) + Vector2(36.0, 12.0)
	if fishing_spot != null:
		var base_spot_pos: Vector2 = fishing_spot.position if fishing_spot.position != Vector2.ZERO else Vector2(790.0, 745.0)
		fisher_pos = base_spot_pos + Vector2(36.0, 12.0)
	
	var npc_defs: Array[Dictionary] = [
		{"id": "baker", "name": "Thợ Bánh Mì", "sprite": "npc_baker", "pos": Vector2(445.0, 465.0)},
		{"id": "pastry", "name": "Thợ Bánh Ngọt", "sprite": "npc_pastry", "pos": Vector2(250.0, 465.0)},
		{"id": "barista", "name": "Pha Chế", "sprite": "npc_barista", "pos": barista_pos},
		{"id": "rancher", "name": "Người Chăn Nuôi", "sprite": "npc_rancher", "pos": Vector2(240.0, 720.0)},
		{"id": "fisher", "name": "Người Câu Cá", "sprite": "npc_fisher", "pos": fisher_pos}
	]
	
	var alert_sys: StockAlertSystem = null
	if ui_hud != null:
		alert_sys = ui_hud.find_child("StockAlertSystem", true, false) as StockAlertSystem
	
	for d: Dictionary in npc_defs:
		var npc: Node2D = SpecializedNPCClass.new() as Node2D
		npc.set("npc_id", String(d["id"]))
		npc.set("npc_name", String(d["name"]))
		npc.set("sprite_key", String(d["sprite"]))
		npc.position = Vector2(d["pos"])
		_specialized_npcs_container.add_child(npc)
		_specialized_npcs.append(npc)
		
		if alert_sys != null:
			alert_sys.register_npc(String(d["id"]), npc)
	
	print("[MainFarm] Spawned 5 Specialized Functional NPCs at correct building positions!")

func start_building_placement(building_id: String, cost: int, req_materials: Dictionary = {}) -> void:
	_pending_build_id = building_id
	_pending_build_cost = cost
	_pending_build_materials = req_materials.duplicate()
	
	if drag_action_manager != null:
		drag_action_manager.set_tool(DragActionManager.ToolType.NONE)
	
	if _ghost_preview_node != null:
		var tex_key: String = building_id
		var spr_sz: Vector2 = Vector2(64.0, 64.0)
		if building_id == "mini_zoo":
			tex_key = "building_mini_zoo"
			spr_sz = Vector2(96.0, 96.0)
		elif building_id == "feed_mill":
			tex_key = "feed_mill"
			spr_sz = Vector2(88.0, 88.0)
		elif building_id == "bakery":
			tex_key = "bakery"
			spr_sz = Vector2(88.0, 88.0)
		elif building_id == "cow_pen" or building_id == "cow":
			tex_key = "cow"
			spr_sz = Vector2(76.0, 76.0)
		elif building_id == "pig_pen" or building_id == "pig":
			tex_key = "pig"
			spr_sz = Vector2(76.0, 76.0)
		elif building_id == "sheep_pen" or building_id == "sheep":
			tex_key = "sheep"
			spr_sz = Vector2(76.0, 76.0)
		elif building_id == "cake_oven":
			tex_key = "building_cake_oven"
			spr_sz = Vector2(88.0, 88.0)
		elif building_id == "juice_stand":
			tex_key = "building_juice_stand"
			spr_sz = Vector2(88.0, 88.0)
		elif building_id == "ice_cream":
			tex_key = "building_ice_cream"
			spr_sz = Vector2(88.0, 88.0)
		elif building_id == "bee_hive" or building_id == "beehive_tree":
			tex_key = "building_bee_hive"
			spr_sz = Vector2(70.0, 70.0)
		elif building_id == "poodle_house":
			tex_key = "farmhouse"
			spr_sz = Vector2(64.0, 64.0)
		elif building_id == "flower_bed":
			tex_key = "flowerbed_round"
			spr_sz = Vector2(36.0, 26.0)
		elif building_id == "wooden_bench":
			tex_key = "wooden_bench"
			spr_sz = Vector2(40.0, 30.0)
		elif building_id == "fountain":
			tex_key = "fountain"
			spr_sz = Vector2(70.0, 70.0)
			
		if SpriteAtlasManager.has_texture(tex_key):
			_ghost_sprite.texture = SpriteAtlasManager.get_texture(tex_key)
			SpriteAtlasManager.set_sprite_pixel_size(_ghost_sprite, spr_sz)
			_ghost_sprite.visible = true
		_ghost_preview_node.visible = true
		_update_ghost_building_preview(get_global_mouse_position())

func _get_pending_build_tile_size(b_id: String) -> Vector2i:
	if b_id in ["cow_pen", "cow", "pig_pen", "pig", "sheep_pen", "sheep"]:
		return Vector2i(4, 3)
	if b_id in ["mini_zoo", "feed_mill", "bakery", "cake_oven", "juice_stand", "ice_cream"]:
		return Vector2i(3, 3)
	if b_id in ["bee_hive", "beehive_tree", "fountain", "poodle_house"]:
		return Vector2i(2, 2)
	return Vector2i(1, 1)

func _update_ghost_building_preview(mouse_pos: Vector2) -> void:
	if _ghost_preview_node == null or _pending_build_id == "":
		return
	var cell: Vector2i = GridManager.world_to_grid(mouse_pos)
	var snapped_pos: Vector2 = Vector2(float(cell.x) * 32.0 + 16.0, float(cell.y) * 32.0 + 16.0)
	_ghost_preview_node.global_position = snapped_pos
	_ghost_preview_node.visible = true
	
	var t_size: Vector2i = _get_pending_build_tile_size(_pending_build_id)
		
	var can_place: bool = true
	for ox: int in range(t_size.x):
		for oy: int in range(t_size.y):
			var c: Vector2i = cell + Vector2i(ox, oy)
			if not GridManager.is_within_bounds(c) or GridManager.is_cell_occupied(c) or GridManager.is_path_tile(c):
				can_place = false
				break
			var c_pos: Vector2 = GridManager.grid_to_world(c)
			if _is_in_water_pond(c_pos):
				can_place = false
				break
		if not can_place:
			break
			
	if can_place:
		_ghost_preview_node.modulate = Color(0.35, 1.0, 0.45, 0.70)
	else:
		_ghost_preview_node.modulate = Color(1.0, 0.35, 0.35, 0.70)

func _handle_building_placement_click(mouse_pos: Vector2) -> void:
	if _pending_build_id == "":
		return
	
	var cell: Vector2i = GridManager.world_to_grid(mouse_pos)
	var snapped_pos: Vector2 = Vector2(float(cell.x) * 32.0 + 16.0, float(cell.y) * 32.0 + 16.0)
	var t_size: Vector2i = _get_pending_build_tile_size(_pending_build_id)
	
	var can_place: bool = true
	for ox: int in range(t_size.x):
		for oy: int in range(t_size.y):
			var c: Vector2i = cell + Vector2i(ox, oy)
			if not GridManager.is_within_bounds(c) or GridManager.is_cell_occupied(c) or GridManager.is_path_tile(c):
				can_place = false
				break
			var c_pos: Vector2 = GridManager.grid_to_world(c)
			if _is_in_water_pond(c_pos):
				can_place = false
				break
		if not can_place:
			break
			
	if not can_place:
		AudioManager.play_sfx("error")
		return
	
	for mat_id: String in _pending_build_materials:
		var req_cnt: int = int(_pending_build_materials[mat_id])
		if req_cnt > 0 and StorageManager.get_item_count(mat_id) < req_cnt:
			AudioManager.play_sfx("error")
			if ui_hud != null and ui_hud.has_method("show_floating_notice"):
				ui_hud.show_floating_notice("❌ Không đủ Vật Liệu Xây Dựng trong Kho!")
			cancel_pending_build()
			return
		
	if not StorageManager.spend_gold(_pending_build_cost):
		AudioManager.play_sfx("error")
		cancel_pending_build()
		return
	
	for mat_id: String in _pending_build_materials:
		var req_cnt: int = int(_pending_build_materials[mat_id])
		if req_cnt > 0:
			StorageManager.remove_item(mat_id, req_cnt)
	
	EventBus.gold_changed.emit(StorageManager.gold, -_pending_build_cost)
	SaveManager.mark_building_constructed(_pending_build_id)
	
	var activated_existing: bool = _try_activate_preplaced_building(_pending_build_id, cell, t_size)
	if not activated_existing:
		if _pending_build_id == "mini_zoo":
			_spawn_building_prop("building_mini_zoo", cell, Vector2i(3, 3), Vector2(96, 96))
		elif _pending_build_id in ["feed_mill", "bakery", "cake_oven", "juice_stand", "ice_cream"]:
			_spawn_production_machine(_pending_build_id, cell)
		elif _pending_build_id in ["cow_pen", "cow"]:
			_spawn_animal_pen("cow", cell, 2)
		elif _pending_build_id in ["pig_pen", "pig"]:
			_spawn_animal_pen("pig", cell, 2)
		elif _pending_build_id in ["sheep_pen", "sheep"]:
			_spawn_animal_pen("sheep", cell, 2)
		elif _pending_build_id in ["bee_hive", "beehive_tree"]:
			_spawn_building_prop("building_bee_hive", cell, Vector2i(2, 2), Vector2(70, 70))
		elif _pending_build_id == "fountain":
			_spawn_building_prop("fountain", cell, Vector2i(2, 2), Vector2(70, 70))
		elif _pending_build_id == "flower_bed":
			_spawn_flowerbed("flowerbed_round", snapped_pos, Vector2(36, 26))
			save_custom_decorations()
		elif _pending_build_id == "wooden_bench":
			_spawn_movable_decor("wooden_bench", snapped_pos, Vector2(40, 30))
			save_custom_decorations()
	
	_refresh_building_progression_visibility()
	_update_specialized_npc_positions()
	GridManager.add_attraction_score(15)
	AudioManager.play_sfx("plant")
	if ui_hud != null and ui_hud.has_method("show_floating_notice"):
		ui_hud.show_floating_notice("🔨 Đã xây dựng công trình mới thành công!")
	_pending_build_id = ""
	_pending_build_materials.clear()
	if _ghost_preview_node != null:
		_ghost_preview_node.visible = false

func _try_activate_preplaced_building(b_id: String, cell: Vector2i, t_size: Vector2i) -> bool:
	var center_pos: Vector2 = Vector2(
		(float(cell.x) + float(t_size.x) * 0.5) * 32.0,
		(float(cell.y) + float(t_size.y) * 0.5) * 32.0
	)
	if b_id in ["feed_mill", "bakery", "juice_stand", "cake_oven"]:
		for m: ProductionMachine in _production_machines:
			if is_instance_valid(m) and m.machine_id == b_id and not m.visible:
				m.grid_pos = cell
				m.position = center_pos
				m.visible = true
				m.process_mode = Node.PROCESS_MODE_INHERIT
				for ox: int in range(3):
					for oy: int in range(3):
						var c: Vector2i = cell + Vector2i(ox, oy)
						GridManager.occupied_cells[c] = 888
						if GridManager.astar_grid != null and GridManager.astar_grid.is_in_bounds(c.x, c.y):
							GridManager.astar_grid.set_point_solid(c, true)
				return true
	elif b_id in ["cow_pen", "cow", "pig_pen", "pig", "sheep_pen", "sheep"]:
		var target_anim: String = SaveManager._normalize_building_id(b_id)
		for pen: AnimalPen in _animal_pens:
			if is_instance_valid(pen) and pen.animal_id == target_anim and not pen.visible:
				pen.grid_pos = cell
				pen.position = center_pos
				pen.visible = true
				pen.process_mode = Node.PROCESS_MODE_INHERIT
				for ox: int in range(4):
					for oy: int in range(3):
						var c: Vector2i = cell + Vector2i(ox, oy)
						GridManager.occupied_cells[c] = 777
						if GridManager.astar_grid != null and GridManager.astar_grid.is_in_bounds(c.x, c.y):
							GridManager.astar_grid.set_point_solid(c, true)
				return true
	elif b_id in ["bee_hive", "beehive_tree"] and beehive_tree != null and is_instance_valid(beehive_tree) and not beehive_tree.visible:
		beehive_tree.position = center_pos
		beehive_tree.visible = true
		beehive_tree.process_mode = Node.PROCESS_MODE_INHERIT
		return true
	elif b_id == "poodle_house" and pet_house_poodle != null and is_instance_valid(pet_house_poodle) and not pet_house_poodle.visible:
		pet_house_poodle.position = center_pos
		pet_house_poodle.visible = true
		pet_house_poodle.process_mode = Node.PROCESS_MODE_INHERIT
		if pet_poodle != null and is_instance_valid(pet_poodle):
			pet_poodle.position = center_pos + Vector2(30.0, 15.0)
			pet_poodle.visible = true
			pet_poodle.process_mode = Node.PROCESS_MODE_INHERIT
		return true
	return false

func _set_all_relocate_buttons_visible(vis: bool) -> void:
	_is_relocating_mode = vis
	for m: ProductionMachine in _production_machines:
		if is_instance_valid(m):
			var btn_m: Control = m.get("_btn_relocate") as Control
			if btn_m != null:
				btn_m.visible = vis
	for pen: AnimalPen in _animal_pens:
		if is_instance_valid(pen):
			var btn_p: Control = pen.get("_btn_relocate") as Control
			if btn_p != null:
				btn_p.visible = vis
	if buildings_container != null:
		for child: Node in buildings_container.get_children():
			for sub: Node in child.get_children():
				if sub is Button and ((sub as Button).text == "✥" or sub.name == "RelocateBtn"):
					(sub as Button).visible = vis

func _refresh_building_progression_visibility() -> void:
	for m: ProductionMachine in _production_machines:
		if not is_instance_valid(m):
			continue
		var built: bool = SaveManager.is_building_constructed(m.machine_id)
		m.visible = built
		m.process_mode = Node.PROCESS_MODE_INHERIT if built else Node.PROCESS_MODE_DISABLED
		for ox: int in range(3):
			for oy: int in range(3):
				var c: Vector2i = m.grid_pos + Vector2i(ox, oy)
				if built:
					GridManager.occupied_cells[c] = 888
					if GridManager.astar_grid != null and GridManager.astar_grid.is_in_bounds(c.x, c.y):
						GridManager.astar_grid.set_point_solid(c, true)
				else:
					if int(GridManager.occupied_cells.get(c, 0)) == 888 or int(GridManager.occupied_cells.get(c, 0)) == 1000:
						GridManager.occupied_cells.erase(c)
						if GridManager.astar_grid != null and GridManager.astar_grid.is_in_bounds(c.x, c.y):
							GridManager.astar_grid.set_point_solid(c, false)

	for pen: AnimalPen in _animal_pens:
		if not is_instance_valid(pen):
			continue
		var built: bool = SaveManager.is_building_constructed(pen.animal_id)
		pen.visible = built
		pen.process_mode = Node.PROCESS_MODE_INHERIT if built else Node.PROCESS_MODE_DISABLED
		for ox: int in range(4):
			for oy: int in range(3):
				var c: Vector2i = pen.grid_pos + Vector2i(ox, oy)
				if built:
					GridManager.occupied_cells[c] = 777
					if GridManager.astar_grid != null and GridManager.astar_grid.is_in_bounds(c.x, c.y):
						GridManager.astar_grid.set_point_solid(c, true)
				else:
					if int(GridManager.occupied_cells.get(c, 0)) == 777 or int(GridManager.occupied_cells.get(c, 0)) == 2000:
						GridManager.occupied_cells.erase(c)
						if GridManager.astar_grid != null and GridManager.astar_grid.is_in_bounds(c.x, c.y):
							GridManager.astar_grid.set_point_solid(c, false)

	if beehive_tree != null and is_instance_valid(beehive_tree):
		var bee_built: bool = SaveManager.is_building_constructed("beehive_tree")
		beehive_tree.visible = bee_built
		beehive_tree.process_mode = Node.PROCESS_MODE_INHERIT if bee_built else Node.PROCESS_MODE_DISABLED

	if pet_house_poodle != null and is_instance_valid(pet_house_poodle):
		var poodle_built: bool = SaveManager.is_building_constructed("poodle_house")
		pet_house_poodle.visible = poodle_built
		pet_house_poodle.process_mode = Node.PROCESS_MODE_INHERIT if poodle_built else Node.PROCESS_MODE_DISABLED
		if pet_poodle != null and is_instance_valid(pet_poodle):
			pet_poodle.visible = poodle_built
			pet_poodle.process_mode = Node.PROCESS_MODE_INHERIT if poodle_built else Node.PROCESS_MODE_DISABLED

	for npc: Node2D in _specialized_npcs:
		if not is_instance_valid(npc):
			continue
		var nid: String = String(npc.get("npc_id"))
		if nid == "baker":
			npc.visible = SaveManager.is_building_constructed("bakery")
		elif nid == "pastry":
			npc.visible = SaveManager.is_building_constructed("cake_oven")
		elif nid == "barista":
			npc.visible = SaveManager.is_building_constructed("juice_stand")

	var zoo_unlocked: bool = (StorageManager.level >= 11)
	if zoo_unlocked and not SaveManager.is_animal_unlocked("zoo_capybara"):
		SaveManager.unlock_animal("zoo_capybara")
	if zoo_manager != null and is_instance_valid(zoo_manager):
		zoo_manager.visible = zoo_unlocked
		zoo_manager.process_mode = Node.PROCESS_MODE_INHERIT if zoo_unlocked else Node.PROCESS_MODE_DISABLED
	var photo_booth: Node2D = get_node_or_null("ZooPhotoBooth") as Node2D
	if photo_booth != null and is_instance_valid(photo_booth):
		photo_booth.visible = zoo_unlocked
		photo_booth.process_mode = Node.PROCESS_MODE_INHERIT if zoo_unlocked else Node.PROCESS_MODE_DISABLED

func _on_player_level_up(_new_level: int) -> void:
	_refresh_building_progression_visibility()

func _on_field_harvested_material_drop(_plot_id: int, _crop_id: String) -> void:
	if randf() <= 0.35:
		award_random_construction_material("Nhặt được vật liệu xây dựng")

func _on_truck_completed_material_drop(_order_id: String, _gold: int, _xp: int) -> void:
	award_random_construction_material("Thưởng đơn xe tải")

func award_random_construction_material(source_label: String = "Nhặt được vật liệu xây dựng") -> String:
	var mat_pool: Array[String] = ["mat_plank", "mat_bolt", "mat_brick"]
	var picked: String = mat_pool[randi() % mat_pool.size()]
	StorageManager.add_item(picked, 1)
	var mat_name: String = DataManager.get_item_name(picked)
	if ui_hud != null and ui_hud.has_method("show_floating_notice"):
		ui_hud.show_floating_notice("🎁 %s: +1 %s!" % [source_label, mat_name])
	return picked

# ==============================================================================
# HỆ THỐNG QUY HOẠCH & DI CHUYỂN CÔNG TRÌNH (RELOCATION SYSTEM)
# ==============================================================================

func start_relocating_structure(target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return

	if _relocating_node != null:
		_cancel_relocating_structure()

	if drag_action_manager != null:
		drag_action_manager.set_tool(DragActionManager.ToolType.NONE)
	if ui_hud != null and ui_hud.has_method("cancel_all_active_tools"):
		ui_hud.call("cancel_all_active_tools")

	_relocating_node = target
	_relocating_old_pos = target.position
	_relocating_initial_modulate = target.modulate
	_relocating_initial_scale = target.scale
	_relocating_start_msec = Time.get_ticks_msec()

	if target is AnimalPen:
		_relocating_tile_size = Vector2i(4, 3)
		_relocating_old_cell = (target as AnimalPen).grid_pos
	elif target is ProductionMachine:
		_relocating_tile_size = Vector2i(3, 3)
		_relocating_old_cell = (target as ProductionMachine).grid_pos
	else:
		if target.has_meta("tile_size"):
			_relocating_tile_size = target.get_meta("tile_size") as Vector2i
		else:
			_relocating_tile_size = Vector2i(3, 3)

		if target.has_meta("grid_pos"):
			_relocating_old_cell = target.get_meta("grid_pos") as Vector2i
		else:
			_relocating_old_cell = Vector2i(
				int(round(target.position.x / 32.0 - float(_relocating_tile_size.x) * 0.5)),
				int(round(target.position.y / 32.0 - float(_relocating_tile_size.y) * 0.5))
			)

	# Giải phóng tạm thời các ô chiếm dụng cũ trong GridManager & AStarGrid
	for ox: int in range(_relocating_tile_size.x):
		for oy: int in range(_relocating_tile_size.y):
			var c: Vector2i = _relocating_old_cell + Vector2i(ox, oy)
			GridManager.occupied_cells.erase(c)
			if GridManager.astar_grid != null and GridManager.astar_grid.is_in_bounds(c.x, c.y):
				GridManager.astar_grid.set_point_solid(c, false)

	# Hiệu ứng nhấc công trình lên
	target.scale = _relocating_initial_scale * 1.08
	target.z_index += 50
	_update_relocating_structure_preview(get_global_mouse_position())

	if ui_hud != null and ui_hud.has_method("show_floating_notice"):
		ui_hud.show_floating_notice("✥ Đang di chuyển công trình: Click Trái để đặt xuống, Click Phải / ESC để hủy")

	if walk_grid != null:
		queue_redraw()

func _update_relocating_structure_preview(mouse_pos: Vector2) -> void:
	if _relocating_node == null or not is_instance_valid(_relocating_node):
		return

	var cell: Vector2i = Vector2i(
		int(floor(mouse_pos.x / 32.0 - float(_relocating_tile_size.x) * 0.5)),
		int(floor(mouse_pos.y / 32.0 - float(_relocating_tile_size.y) * 0.5))
	)
	var snapped_pos: Vector2 = Vector2(
		(float(cell.x) + float(_relocating_tile_size.x) * 0.5) * 32.0,
		(float(cell.y) + float(_relocating_tile_size.y) * 0.5) * 32.0
	)
	_relocating_node.position = snapped_pos

	var is_valid: bool = _is_valid_structure_placement(cell, _relocating_tile_size)
	if is_valid:
		_relocating_node.modulate = Color(0.85, 1.0, 0.85, 0.88)
	else:
		_relocating_node.modulate = Color(1.0, 0.55, 0.55, 0.88)

func _is_valid_structure_placement(cell: Vector2i, tile_size: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0:
		return false
	if cell.x + tile_size.x > GridManager.GRID_WIDTH or cell.y + tile_size.y > GridManager.GRID_HEIGHT:
		return false
	# Vùng đất chính trang trại (x < 840, không lấn sang sông / cầu / sở thú)
	if float(cell.x + tile_size.x) * 32.0 > 840.0:
		return false
	# Tránh góc HUD ở trên bên trái
	if cell.x < 4 and cell.y < 3:
		return false

	var old_rect: Rect2i = Rect2i(_relocating_old_cell, _relocating_tile_size) if _relocating_node != null else Rect2i(0, 0, 0, 0)

	for ox: int in range(tile_size.x):
		for oy: int in range(tile_size.y):
			var c: Vector2i = cell + Vector2i(ox, oy)
			if GridManager.is_path_tile(c):
				return false
			if GridManager.is_cell_occupied(c):
				if _relocating_node != null and old_rect.has_point(c):
					continue
				var occ: int = int(GridManager.occupied_cells.get(c, 0))
				if occ == 0:
					continue
				return false
			var wpos: Vector2 = GridManager.grid_to_world(c)
			if _is_in_water_pond(wpos):
				return false
			if c.y == 20 and c.x > 20: # Khu vực cầu qua sông
				return false
	return true

func _handle_relocate_placement_click(mouse_pos: Vector2) -> void:
	if _relocating_node == null or not is_instance_valid(_relocating_node):
		return

	var cell: Vector2i = Vector2i(
		int(floor(mouse_pos.x / 32.0 - float(_relocating_tile_size.x) * 0.5)),
		int(floor(mouse_pos.y / 32.0 - float(_relocating_tile_size.y) * 0.5))
	)

	if _is_valid_structure_placement(cell, _relocating_tile_size):
		_commit_relocating_structure(cell)
	else:
		AudioManager.play_sfx("error")
		if ui_hud != null and ui_hud.has_method("show_floating_notice"):
			ui_hud.show_floating_notice("❌ Vị trí không hợp lệ hoặc bị vướng vật cản!")

func _commit_relocating_structure(new_cell: Vector2i) -> void:
	if _relocating_node == null or not is_instance_valid(_relocating_node):
		_relocating_node = null
		return

	var final_pos: Vector2 = Vector2(
		(float(new_cell.x) + float(_relocating_tile_size.x) * 0.5) * 32.0,
		(float(new_cell.y) + float(_relocating_tile_size.y) * 0.5) * 32.0
	)
	_relocating_node.position = final_pos

	if _relocating_node is ProductionMachine:
		(_relocating_node as ProductionMachine).grid_pos = new_cell
	elif _relocating_node is AnimalPen:
		(_relocating_node as AnimalPen).grid_pos = new_cell
	else:
		_relocating_node.set_meta("grid_pos", new_cell)

	var occ_code: int = 888
	if _relocating_node is AnimalPen:
		occ_code = 777
	elif _relocating_node == _barn_prop or _relocating_node == _silo_prop or _relocating_node == _roadside_shop_prop:
		occ_code = 999

	for ox: int in range(_relocating_tile_size.x):
		for oy: int in range(_relocating_tile_size.y):
			var c: Vector2i = new_cell + Vector2i(ox, oy)
			GridManager.occupied_cells[c] = occ_code
			if GridManager.astar_grid != null and GridManager.astar_grid.is_in_bounds(c.x, c.y):
				GridManager.astar_grid.set_point_solid(c, true)
			auto_clear_decor_at_cell(c)

	var save_key: String = _get_structure_save_key(_relocating_node)
	if save_key != "":
		var saved_positions: Dictionary = {}
		if SaveManager != null and SaveManager.has_meta("custom_structure_positions"):
			saved_positions = (SaveManager.get_meta("custom_structure_positions") as Dictionary).duplicate()
		saved_positions[save_key] = {
			"cell_x": new_cell.x,
			"cell_y": new_cell.y,
			"tile_w": _relocating_tile_size.x,
			"tile_h": _relocating_tile_size.y
		}
		if SaveManager != null:
			SaveManager.set_meta("custom_structure_positions", saved_positions)
		_save_structure_positions_to_disk(saved_positions)

	_relocating_node.modulate = _relocating_initial_modulate
	_relocating_node.z_index -= 50

	var tw: Tween = create_tween()
	tw.tween_property(_relocating_node, "scale", _relocating_initial_scale * 1.15, 0.09).set_trans(Tween.TRANS_BACK)
	tw.tween_property(_relocating_node, "scale", _relocating_initial_scale, 0.12).set_trans(Tween.TRANS_SINE)

	AudioManager.play_sfx("plant")

	if ui_hud != null and ui_hud.has_method("show_floating_notice"):
		ui_hud.show_floating_notice("✅ Đã chuyển vị trí công trình thành công!")

	_update_specialized_npc_positions()

	_relocating_node = null
	if walk_grid != null:
		queue_redraw()

func _cancel_relocating_structure() -> void:
	if _relocating_node == null or not is_instance_valid(_relocating_node):
		_relocating_node = null
		return

	_relocating_node.position = _relocating_old_pos
	_relocating_node.modulate = _relocating_initial_modulate
	_relocating_node.scale = _relocating_initial_scale
	_relocating_node.z_index -= 50

	var occ_code: int = 888
	if _relocating_node is AnimalPen:
		occ_code = 777
	elif _relocating_node == _barn_prop or _relocating_node == _silo_prop or _relocating_node == _roadside_shop_prop:
		occ_code = 999

	for ox: int in range(_relocating_tile_size.x):
		for oy: int in range(_relocating_tile_size.y):
			var c: Vector2i = _relocating_old_cell + Vector2i(ox, oy)
			GridManager.occupied_cells[c] = occ_code
			if GridManager.astar_grid != null and GridManager.astar_grid.is_in_bounds(c.x, c.y):
				GridManager.astar_grid.set_point_solid(c, true)

	if ui_hud != null and ui_hud.has_method("show_floating_notice"):
		ui_hud.show_floating_notice("↩️ Đã hủy di chuyển công trình")

	_relocating_node = null
	if walk_grid != null:
		queue_redraw()

func try_relocate_structure_at_pos(world_pos: Vector2) -> bool:
	for machine: ProductionMachine in _production_machines:
		if is_instance_valid(machine) and machine.visible and world_pos.distance_to(machine.global_position) <= 65.0:
			start_relocating_structure(machine)
			return true
	for pen: AnimalPen in _animal_pens:
		if is_instance_valid(pen) and pen.visible and world_pos.distance_to(pen.global_position) <= 80.0:
			start_relocating_structure(pen)
			return true
	if _barn_prop != null and is_instance_valid(_barn_prop) and world_pos.distance_to(_barn_prop.global_position) <= 65.0:
		start_relocating_structure(_barn_prop)
		return true
	if _silo_prop != null and is_instance_valid(_silo_prop) and world_pos.distance_to(_silo_prop.global_position) <= 65.0:
		start_relocating_structure(_silo_prop)
		return true
	if _roadside_shop_prop != null and is_instance_valid(_roadside_shop_prop) and world_pos.distance_to(_roadside_shop_prop.global_position) <= 65.0:
		start_relocating_structure(_roadside_shop_prop)
		return true
	return false

func _get_structure_save_key(node: Node2D) -> String:
	if node is ProductionMachine:
		return "machine_" + (node as ProductionMachine).machine_id
	elif node is AnimalPen:
		return "pen_" + (node as AnimalPen).animal_id
	elif node == _barn_prop:
		return "prop_barn"
	elif node == _silo_prop:
		return "prop_silo"
	elif node == _roadside_shop_prop:
		return "prop_roadside_shop"
	elif node != null and node.has_meta("interact_type"):
		return "prop_" + String(node.get_meta("interact_type"))
	return ""

func _save_structure_positions_to_disk(dict: Dictionary) -> void:
	var f: FileAccess = FileAccess.open("user://custom_structure_positions.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(dict))
		f.close()

func _load_structure_positions_from_disk() -> Dictionary:
	if not FileAccess.file_exists("user://custom_structure_positions.json"):
		return {}
	var f: FileAccess = FileAccess.open("user://custom_structure_positions.json", FileAccess.READ)
	if f == null:
		return {}
	var txt: String = f.get_as_text()
	f.close()
	var test_json: JSON = JSON.new()
	if test_json.parse(txt) == OK and test_json.data is Dictionary:
		return test_json.data as Dictionary
	return {}

func _apply_saved_structure_positions() -> void:
	var saved_dict: Dictionary = {}
	if SaveManager != null and SaveManager.has_meta("custom_structure_positions"):
		saved_dict = (SaveManager.get_meta("custom_structure_positions") as Dictionary).duplicate()
	if saved_dict.is_empty():
		saved_dict = _load_structure_positions_from_disk()
		if SaveManager != null and not saved_dict.is_empty():
			SaveManager.set_meta("custom_structure_positions", saved_dict)

	if saved_dict.is_empty():
		return

	for key: String in saved_dict:
		var pos_info: Dictionary = saved_dict[key] as Dictionary
		if not pos_info.has("cell_x") or not pos_info.has("cell_y"):
			continue
		var target_cell: Vector2i = Vector2i(int(pos_info["cell_x"]), int(pos_info["cell_y"]))
		var t_size: Vector2i = Vector2i(int(pos_info.get("tile_w", 3)), int(pos_info.get("tile_h", 3)))
		var target_node: Node2D = null
		var old_cell: Vector2i = Vector2i.ZERO

		if key.begins_with("machine_"):
			var mid: String = key.trim_prefix("machine_")
			for m: ProductionMachine in _production_machines:
				if is_instance_valid(m) and m.machine_id == mid:
					target_node = m
					old_cell = m.grid_pos
					t_size = Vector2i(3, 3)
					break
		elif key.begins_with("pen_"):
			var pid: String = key.trim_prefix("pen_")
			for pen: AnimalPen in _animal_pens:
				if is_instance_valid(pen) and pen.animal_id == pid:
					target_node = pen
					old_cell = pen.grid_pos
					t_size = Vector2i(4, 3)
					break
		elif key == "prop_barn" and _barn_prop != null and is_instance_valid(_barn_prop):
			target_node = _barn_prop
			old_cell = _barn_prop.get_meta("grid_pos", Vector2i(18, 8)) as Vector2i
			t_size = Vector2i(3, 3)
		elif key == "prop_silo" and _silo_prop != null and is_instance_valid(_silo_prop):
			target_node = _silo_prop
			old_cell = _silo_prop.get_meta("grid_pos", Vector2i(14, 8)) as Vector2i
			t_size = Vector2i(3, 3)
		elif key == "prop_roadside_shop" and _roadside_shop_prop != null and is_instance_valid(_roadside_shop_prop):
			target_node = _roadside_shop_prop
			old_cell = _roadside_shop_prop.get_meta("grid_pos", Vector2i(6, 17)) as Vector2i
			t_size = Vector2i(3, 3)

		if target_node != null:
			# Xóa ô cũ
			for ox: int in range(t_size.x):
				for oy: int in range(t_size.y):
					var c: Vector2i = old_cell + Vector2i(ox, oy)
					GridManager.occupied_cells.erase(c)
					if GridManager.astar_grid != null and GridManager.astar_grid.is_in_bounds(c.x, c.y):
						GridManager.astar_grid.set_point_solid(c, false)

			# Di chuyển đến ô mới
			var center_pixel: Vector2 = Vector2(
				(float(target_cell.x) + float(t_size.x) * 0.5) * 32.0,
				(float(target_cell.y) + float(t_size.y) * 0.5) * 32.0
			)
			target_node.position = center_pixel
			if target_node is ProductionMachine:
				(target_node as ProductionMachine).grid_pos = target_cell
			elif target_node is AnimalPen:
				(target_node as AnimalPen).grid_pos = target_cell
			else:
				target_node.set_meta("grid_pos", target_cell)

			# Đánh dấu ô mới
			var occ_code: int = 888
			if target_node is AnimalPen:
				occ_code = 777
			elif target_node == _barn_prop or target_node == _silo_prop or target_node == _roadside_shop_prop:
				occ_code = 999

			for ox: int in range(t_size.x):
				for oy: int in range(t_size.y):
					var c: Vector2i = target_cell + Vector2i(ox, oy)
					GridManager.occupied_cells[c] = occ_code
					if GridManager.astar_grid != null and GridManager.astar_grid.is_in_bounds(c.x, c.y):
						GridManager.astar_grid.set_point_solid(c, true)
					auto_clear_decor_at_cell(c)

	_update_specialized_npc_positions()

func _update_specialized_npc_positions() -> void:
	for npc: Node2D in _specialized_npcs:
		if not is_instance_valid(npc):
			continue
		var nid: String = String(npc.get("npc_id"))
		if nid == "baker":
			for m: ProductionMachine in _production_machines:
				if is_instance_valid(m) and m.machine_id == "bakery":
					npc.position = m.position + Vector2(-45.0, 5.0)
					break
		elif nid == "pastry":
			for m: ProductionMachine in _production_machines:
				if is_instance_valid(m) and m.machine_id == "cake_oven":
					npc.position = m.position + Vector2(-45.0, 5.0)
					break
		elif nid == "barista":
			for m: ProductionMachine in _production_machines:
				if is_instance_valid(m) and m.machine_id == "juice_stand":
					npc.position = m.position + Vector2(0.0, 45.0)
					break
