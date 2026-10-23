extends Node2D
class_name MainFarm


@onready var camera_2d: Camera2D = $Camera2D
@onready var plots_container: Node2D = $PlotsContainer
@onready var buildings_container: Node2D = $BuildingsContainer
@onready var animal_pens_container: Node2D = $AnimalPensContainer
@onready var visitor_manager: VisitorManager = $VisitorManager
@onready var drag_action_manager: DragActionManager = $DragActionManager
@onready var ui_hud: CanvasLayer = $UIHud

var environment_container: Node2D
var _scenic_valley_container: Node2D = null
var _scenic_elements: Array[Node2D] = []

func get_scenic_elements_count() -> int:
	return _scenic_elements.size()
var field_plots: Dictionary = {} # Vector2i -> FieldPlot
var fishing_spot: FishingSpot

var _flower_targets: Array[Vector2] = []
var _movable_decors: Array[MovableDecor] = []
var _animal_pens: Array[AnimalPen] = []
var _production_machines: Array[ProductionMachine] = []
var _truck_prop: Node2D = null
var _barn_prop: Node2D = null
var _silo_prop: Node2D = null

var _ghost_preview_node: Node2D = null
var _ghost_box: Polygon2D = null
var _ghost_sprite: Sprite2D = null

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

	# Complete 2.5D Y-Sort
	y_sort_enabled = true
	plots_container.y_sort_enabled = true
	buildings_container.y_sort_enabled = true
	animal_pens_container.y_sort_enabled = true
	visitor_manager.y_sort_enabled = true

	# Dedicated Environment Decorations Layer with Y-Sort
	environment_container = Node2D.new()
	environment_container.name = "EnvironmentContainer"
	environment_container.y_sort_enabled = true
	add_child(environment_container)

	_scenic_valley_container = Node2D.new()
	_scenic_valley_container.name = "ScenicValleyContainer"
	_scenic_valley_container.y_sort_enabled = true
	add_child(_scenic_valley_container)
	_spawn_scenic_valley_environment()
	# Connect Core System Event Signals
	EventBus.building_placed.connect(_on_building_placed)
	EventBus.building_removed.connect(_on_building_removed)
	EventBus.path_tile_changed.connect(_on_path_tile_changed)

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

	# Spawn Rich Chibi Nature & Environmental Scenery
	_setup_environment_decorations()

	# Tắt _process hoàn toàn để chống giật lag
	set_process(false)

	# Check screenshot test mode
	var args: PackedStringArray = OS.get_cmdline_args()
	for arg: String in args:
		if arg == "--screenshot" or arg == "--run-tests":
			_capture_screenshot_and_quit()
			break

func _on_drag_tool_changed(new_tool: DragActionManager.ToolType) -> void:
	if _ghost_preview_node == null:
		return
	
	if new_tool == DragActionManager.ToolType.NONE or new_tool == DragActionManager.ToolType.SICKLE:
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
	if cur_tool == DragActionManager.ToolType.NONE or cur_tool == DragActionManager.ToolType.SICKLE:
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
	return FishingSpot.is_in_water_or_sand(pos)

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

	# 2. Phân vùng 4: Khu Vườn Cây Ăn Quả (Góc Dưới Trái, X: 160..320, Y: 672..864)
	# 6 Cây Táo và Cây Xoài theo hàng lối thẳng tắp: 2 cột x 3 hàng (cách nhau 64px - 70px)
	_spawn_apple_tree(Vector2(192, 710), Vector2(74, 78))
	_spawn_mango_tree(Vector2(256, 710), Vector2(72, 76))
	_spawn_mango_tree(Vector2(192, 780), Vector2(74, 76))
	_spawn_apple_tree(Vector2(256, 780), Vector2(74, 78))
	_spawn_apple_tree(Vector2(192, 850), Vector2(74, 78))
	_spawn_mango_tree(Vector2(256, 850), Vector2(72, 76))

	# 3. Soft Flowerbeds placed strictly near buildings/corners (clean and orderly)
	_spawn_flowerbed("flowerbed_daisies", Vector2(320, 470), Vector2(40, 28))
	_spawn_flowerbed("flowerbed_roses", Vector2(320, 520), Vector2(38, 26))
	_spawn_flowerbed("flowerbed_lavender", Vector2(576, 470), Vector2(38, 26))
	_spawn_flowerbed("flowerbed_round", Vector2(576, 520), Vector2(36, 26))

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
		_truck_prop.position = Vector2(435.0, 660.0)
		_truck_prop.z_index = 2
	elif sprite_id == "barn" or sprite_id == "building_barn":
		_barn_prop = node_wrapper
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
	elif sprite_id == "silo":
		_silo_prop = node_wrapper
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
	return sp

func _spawn_production_machine(m_id: String, cell: Vector2i) -> ProductionMachine:
	for x: int in range(cell.x, cell.x + 3):
		for y: int in range(cell.y, cell.y + 3):
			var c: Vector2i = Vector2i(x, y)
			GridManager.occupied_cells[c] = 888
			GridManager.astar_grid.set_point_solid(c, true)

	var machine: ProductionMachine = ProductionMachine.new()
	machine.y_sort_enabled = true
	machine.machine_id = m_id
	machine.grid_pos = cell
	var center_pixel: Vector2 = Vector2(
		(float(cell.x) + 1.5) * 32.0,
		(float(cell.y) + 1.5) * 32.0
	)
	machine.position = center_pixel
	buildings_container.add_child(machine)
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

func _create_ellipse_shadow(size: Vector2) -> Sprite2D:
	var img: Image = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
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

	var tex: ImageTexture = ImageTexture.create_from_image(img)
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
	queue_redraw()

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

	# 3. Cozy Buttercream Terracotta Roads (#F3E5AB and #C9A66B)
	var road_base: Color = Color(0.953, 0.898, 0.671) # #F3E5AB
	var road_border: Color = Color(0.788, 0.651, 0.420) # #C9A66B
	var road_grain: Color = Color(0.86, 0.74, 0.50)

	for path_cell: Variant in GridManager.path_cells:
		var c: Vector2i = path_cell as Vector2i
		var pos: Vector2 = Vector2(c.x * 32, c.y * 32)
		var r: Rect2 = Rect2(pos, Vector2(32, 32))
		draw_rect(r, road_base, true)
		draw_rect(r, road_border, false, 1.2)

		# Cute pastel specks
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

func _capture_screenshot_and_quit() -> void:
	await get_tree().create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	var vp: Viewport = get_viewport()
	var tex: ViewportTexture = vp.get_texture()
	var img: Image = tex.get_image()
	if img != null and not img.is_empty():
		var save_path: String = ProjectSettings.globalize_path("res://debug_preview.png")
		var err: Error = img.save_png(save_path)
		print("[MainFarm] Captured screenshot to ", save_path, " (Result: ", err, ")")
	get_tree().quit()

func play_truck_delivery_animation() -> void:
	if _truck_prop == null or not is_instance_valid(_truck_prop):
		return
	var orig_pos: Vector2 = Vector2(435.0, 660.0)
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
		if is_instance_valid(pen):
			if world_pos.distance_to(pen.global_position) <= 95.0:
				return pen.handle_pen_click()
	
	# 3. Máy Sản Xuất (Lò bánh mì, Máy xay thức ăn, bán kính <= 75px)
	for machine: ProductionMachine in _production_machines:
		if is_instance_valid(machine):
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
	
	return false

func _unhandled_input(event: InputEvent) -> void:
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
	sp.position = Vector2(0.0, -size.y * 0.45)
	node.add_child(sp)
	
	_scenic_valley_container.add_child(node)
	_scenic_elements.append(node)
	return node

func _spawn_scenic_valley_environment() -> void:
	# 1. Phân vùng 5: Rừng Anh Đào & Công Viên Bờ Đông (X: 1088..1376, Y: 192..864)
	# Phía Bắc Cầu Gỗ (Y: 200..600):
	_spawn_scenic_element("env_cherry_tree", Vector2(1120, 210), Vector2(88, 92))
	_spawn_scenic_element("env_river_bush", Vector2(1145, 260), Vector2(40, 36))
	_spawn_scenic_element("env_lush_green_tree", Vector2(1240, 240), Vector2(90, 95))
	_spawn_scenic_element("flowerbed_round", Vector2(1160, 310), Vector2(36, 26))

	_spawn_scenic_element("env_lush_green_tree", Vector2(1135, 380), Vector2(90, 95))
	_spawn_scenic_element("env_river_bush", Vector2(1150, 440), Vector2(40, 36))
	_spawn_scenic_element("env_cherry_tree", Vector2(1240, 400), Vector2(88, 92))
	_spawn_scenic_element("env_lush_green_tree", Vector2(1250, 490), Vector2(90, 95))
	_spawn_scenic_element("flowerbed_roses", Vector2(1165, 490), Vector2(38, 26))

	_spawn_scenic_element("env_cherry_tree", Vector2(1120, 560), Vector2(88, 92))
	_spawn_scenic_element("env_river_bush", Vector2(1155, 610), Vector2(40, 36))
	_spawn_scenic_element("flowerbed_lavender", Vector2(1240, 580), Vector2(38, 26))

	# Phía Nam Cầu Gỗ trên bờ Đông (lấp đầy khoảng trống góc dưới bên phải):
	_spawn_scenic_element("env_lush_green_tree", Vector2(1125, 720), Vector2(90, 95))
	_spawn_scenic_element("env_river_bush", Vector2(1145, 770), Vector2(40, 36))
	_spawn_scenic_element("env_cherry_tree", Vector2(1240, 740), Vector2(88, 92))
	_spawn_scenic_element("flowerbed_daisies", Vector2(1165, 810), Vector2(38, 26))

	_spawn_scenic_element("env_cherry_tree", Vector2(1130, 860), Vector2(88, 92))
	_spawn_scenic_element("env_river_bush", Vector2(1150, 910), Vector2(40, 36))
	_spawn_scenic_element("env_lush_green_tree", Vector2(1240, 880), Vector2(90, 95))

	# 2. Hàng cây phía Bắc ôm sau khu nhà xưởng (Y: 95..100):
	_spawn_scenic_element("env_cherry_tree", Vector2(340, 95), Vector2(88, 92))
	_spawn_scenic_element("env_lush_green_tree", Vector2(520, 100), Vector2(90, 95))
	_spawn_scenic_element("env_cherry_tree", Vector2(700, 95), Vector2(88, 92))
	_spawn_scenic_element("env_lush_green_tree", Vector2(880, 100), Vector2(90, 95))

	# 3. Bờ Tây ven sông (phía Bắc cầu gỗ):
	_spawn_scenic_element("env_river_bush", Vector2(765, 380), Vector2(42, 38))
	_spawn_scenic_element("flowerbed_round", Vector2(755, 550), Vector2(36, 26))

	print("[MainFarm] Spawned Harmonious Hay Day Scenic Valley with ", _scenic_elements.size(), " elements!")
