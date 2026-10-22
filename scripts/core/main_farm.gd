extends Node2D
class_name MainFarm


@onready var camera_2d: Camera2D = $Camera2D
@onready var plots_container: Node2D = $PlotsContainer
@onready var buildings_container: Node2D = $BuildingsContainer
@onready var animal_pens_container: Node2D = $AnimalPensContainer
@onready var visitor_manager: VisitorManager = $VisitorManager
@onready var drag_action_manager: DragActionManager = $DragActionManager

var environment_container: Node2D
var _scenic_valley_container: Node2D = null
var _scenic_elements: Array[Node2D] = []
var _scenic_clouds: Array[Dictionary] = []

func get_scenic_elements_count() -> int:
	return _scenic_elements.size()
var field_plots: Dictionary = {} # Vector2i -> FieldPlot
var fishing_spot: FishingSpot

# --- Living Ecosystem Enums & Classes ---
enum CritterState {
	IDLE,
	MOVING_LAND,
	SWIMMING,
	SHAKING
}

enum LocomotionStyle {
	HOPPING,   # Rabbit, Chick
	WADDLING,  # Duck, Dog
	FLUTTERING # Butterfly, Bee
}

class FlyingBird:
	var sprite: Sprite2D
	var shadow: Sprite2D
	var base_y: float = 0.0
	var speed: float = 50.0
	var flap_phase: float = 0.0
	var flap_freq: float = 7.5
	var base_scale: Vector2 = Vector2(0.28, 0.28)

class WaterRippleNode extends Node2D:
	var is_swimming: bool = false
	var ripple_phase: float = 0.0
	var facing_left: bool = false
	
	func _process(delta: float) -> void:
		if is_swimming and visible:
			ripple_phase += delta * 3.0
			queue_redraw()
	
	func _draw_ellipse(center: Vector2, rx: float, ry: float, col: Color, line_w: float = 1.2) -> void:
		var points: PackedVector2Array = PackedVector2Array()
		const SEGMENTS: int = 24
		for i: int in range(SEGMENTS + 1):
			var theta: float = float(i) * TAU / float(SEGMENTS)
			points.append(center + Vector2(cos(theta) * rx, sin(theta) * ry))
		draw_polyline(points, col, line_w, true)
	
	func _draw() -> void:
		if not is_swimming or not visible:
			return
		
		var center: Vector2 = Vector2(0.0, 8.0)
		
		# 1st flattened horizontal ellipse (rx: 10..14px, ry: 3..5px)
		var p1: float = fmod(ripple_phase, 1.0)
		var rx1: float = 10.0 + p1 * 4.0
		var ry1: float = 3.0 + p1 * 1.5
		var a1: float = (1.0 - p1) * 0.45
		var col1: Color = Color(0.9, 0.98, 1.0, a1)
		_draw_ellipse(center, rx1, ry1, col1, 1.2)
		
		# 2nd flattened horizontal ellipse (out of phase by 0.5)
		var p2: float = fmod(ripple_phase + 0.5, 1.0)
		var rx2: float = 10.0 + p2 * 4.0
		var ry2: float = 3.0 + p2 * 1.5
		var a2: float = (1.0 - p2) * 0.38
		var col2: Color = Color(0.9, 0.98, 1.0, a2)
		_draw_ellipse(center, rx2, ry2, col2, 1.2)

class AmbientCritter:
	var root: Node2D
	var sprite: Sprite2D
	var shadow: Sprite2D
	var ripple_node: WaterRippleNode
	var critter_id: String = ""
	var locomotion: int = LocomotionStyle.HOPPING
	var state: int = CritterState.IDLE
	var current_pos: Vector2 = Vector2.ZERO
	var target_pos: Vector2 = Vector2.ZERO
	var speed: float = 38.0
	var state_timer: float = 0.0
	var move_progress: float = 0.0
	var move_duration: float = 2.0
	var base_scale: Vector2 = Vector2(0.22, 0.22)
	var float_phase: float = 0.0
	var shake_timer: float = 0.0
	var hop_height: float = 8.5
	var can_swim: bool = false

var _flying_birds: Array[FlyingBird] = []
var _ambient_critters: Array[AmbientCritter] = []
var _critters_container: Node2D
var _birds_container: Node2D
var _flower_targets: Array[Vector2] = []
var _movable_decors: Array[MovableDecor] = []
var _animal_pens: Array[AnimalPen] = []
var _production_machines: Array[ProductionMachine] = []
var _truck_prop: Node2D = null

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
	_setup_scenic_clouds()

	# Dedicated Critters Layer (z_index = 0, y_sorted below tree foliage)
	_critters_container = Node2D.new()
	_critters_container.name = "CrittersContainer"
	_critters_container.z_index = 0
	_critters_container.y_sort_enabled = true
	add_child(_critters_container)

	# Dedicated Sky Birds Layer (z_index = 20)
	_birds_container = Node2D.new()
	_birds_container.name = "BirdsContainer"
	_birds_container.z_index = 20
	add_child(_birds_container)

	# Connect Core System Event Signals
	EventBus.building_placed.connect(_on_building_placed)
	EventBus.building_removed.connect(_on_building_removed)
	EventBus.path_tile_changed.connect(_on_path_tile_changed)

	# Link DragActionManager
	if drag_action_manager != null:
		drag_action_manager.main_farm = self

	# Initial Farm Build if Empty
	if GridManager.occupied_cells.is_empty():
		_setup_initial_farm()

	# Spawn Rich Chibi Nature & Environmental Scenery
	_setup_environment_decorations()

	# Spawn Living Ecosystem (Birds, Critters, Pets)
	_setup_flying_birds()
	_setup_ambient_critters()

	# Check screenshot test mode
	var args: PackedStringArray = OS.get_cmdline_args()
	for arg: String in args:
		if arg == "--screenshot" or arg == "--run-tests":
			_capture_screenshot_and_quit()
			break

func _process(delta: float) -> void:
	_update_flying_birds(delta)
	_update_ambient_critters(delta)
	_update_scenic_clouds(delta)
	queue_redraw()

func _screen_to_world(scr: Vector2) -> Vector2:
	return (scr - Vector2(576.0, 324.0)) / 1.35 + camera_2d.position

func _world_to_screen(world_pos: Vector2) -> Vector2:
	return (world_pos - camera_2d.position) * 1.35 + Vector2(576.0, 324.0)

# --- PHẦN 1.3: CƠ CHẾ KIỂM TRA MẶT NƯỚC (WATER POND DETECTION) ---
func _is_in_lake_zone(world_pos: Vector2) -> bool:
	return _is_in_water_pond(world_pos)

func _is_in_water_pond(pos: Vector2) -> bool:
	var rx: float = FishingSpot.get_river_center_x(pos.y)
	# Exclude wooden river bridge at y = 636..684, x = 820..1080
	if pos.y >= 636.0 and pos.y <= 684.0 and pos.x >= 820.0 and pos.x <= 1080.0:
		return false
	# Exclude fishing pier at y = 708..736, x = 780..885
	if pos.y >= 708.0 and pos.y <= 736.0 and pos.x >= 780.0 and pos.x <= 885.0:
		return false
	# Water half-width is 88px + 35px safety margin = 123px minimum distance from water edge!
	return absf(pos.x - rx) <= 125.0 and pos.y >= -50.0 and pos.y <= 1350.0

func _get_random_critter_waypoint(can_swim: bool = false, is_flutter: bool = false) -> Vector2:
	# Flutterers prefer landing on flowerbeds or apple trees for nectar
	if is_flutter and _flower_targets.size() > 0 and randf() < 0.72:
		var target: Vector2 = _flower_targets[randi() % _flower_targets.size()]
		return target + Vector2(randf_range(-16.0, 16.0), randf_range(-12.0, 12.0))

	# Swimming-capable ducks swim along the winding river
	if can_swim and randf() < 0.65:
		var ry: float = randf_range(350.0, 950.0)
		var rx: float = FishingSpot.get_river_center_x(ry) + randf_range(-40.0, 40.0)
		return Vector2(rx, ry)

	var tree_centers: Array[Vector2] = [
		Vector2(360, 115), Vector2(740, 115), Vector2(80, 480), Vector2(880, 520), Vector2(1040, 360),
		Vector2(75, 715), Vector2(110, 755), Vector2(175, 715), Vector2(540, 115), Vector2(650, 165),
		Vector2(310, 725), Vector2(420, 725), Vector2(950, 120), Vector2(1100, 220)
	]

	# Full-Map Free Roaming across visible screen (X: 100..1080, Y: 140..540)
	# Avoiding top-left HUD (X < 260, Y < 260) and bottom HUD (Y > 545)
	for attempt: int in range(40):
		var sx: float = randf_range(110.0, 1070.0)
		var sy: float = randf_range(145.0, 535.0)
		if sx < 260.0 and sy < 260.0:
			continue
		if sy > 540.0:
			continue
		
		# Land animals and insects MUST NEVER pick waypoints in the lake or on the pier
		if not can_swim and sx >= 670.0 and sy >= 400.0:
			continue

		var candidate_world: Vector2 = _screen_to_world(Vector2(sx, sy))
		if not is_flutter:
			var cell: Vector2i = Vector2i(int(candidate_world.x / 32.0), int(candidate_world.y / 32.0))
			if GridManager.occupied_cells.has(cell):
				continue
			var on_tree: bool = false
			for tc: Vector2 in tree_centers:
				if candidate_world.distance_to(tc) < 40.0:
					on_tree = true
					break
			if on_tree:
				continue
		return candidate_world

	return Vector2(580.0, 580.0)

func _setup_initial_farm() -> void:
	# 1. 12 Field Plots in 2 beds of 3x2 separated by a grassy lane
	var bed1_coords: Array[Vector2i] = [
		Vector2i(14, 15), Vector2i(15, 15), Vector2i(16, 15),
		Vector2i(14, 16), Vector2i(15, 16), Vector2i(16, 16)
	]
	var bed2_coords: Array[Vector2i] = [
		Vector2i(14, 18), Vector2i(15, 18), Vector2i(16, 18),
		Vector2i(14, 19), Vector2i(15, 19), Vector2i(16, 19)
	]

	# Bed 1: 6 plots EMPTY for seeding tests
	for coord: Vector2i in bed1_coords:
		if not GridManager.is_cell_occupied(coord):
			var inst_id: int = GridManager.place_building("field_plot", coord)
			_spawn_field_plot(coord, inst_id)

	# Bed 2: 6 plots for harvesting / growth tests
	for coord: Vector2i in bed2_coords:
		if not GridManager.is_cell_occupied(coord):
			var inst_id: int = GridManager.place_building("field_plot", coord)
			var plot: FieldPlot = _spawn_field_plot(coord, inst_id)
			if coord == Vector2i(14, 18):
				plot.plant("wheat")
				plot.state = FieldPlot.PlotState.READY
				plot._show_ready_crop()
			elif coord == Vector2i(14, 19):
				plot.plant("corn")
				plot.state = FieldPlot.PlotState.READY
				plot._show_ready_crop()
			elif coord.y == 18:
				plot.plant("wheat")
			else:
				plot.plant("corn")

	# 2. Roadside Shop & Delivery Truck (along main road)
	_spawn_building_prop("roadside_shop", Vector2i(6, 17), Vector2i(3, 3), Vector2(90, 90))
	_spawn_building_prop("truck", Vector2i(10, 17), Vector2i(2, 2), Vector2(90, 90))

	# 3. Hillside Estate (Farmhouse, Barn, Silo) placed safely at Y=11 so roofs are never cut off by top edge!
	_spawn_building_prop("farmhouse", Vector2i(15, 11), Vector2i(3, 3), Vector2(90, 90))
	_spawn_building_prop("barn", Vector2i(19, 11), Vector2i(3, 3), Vector2(90, 90))
	_spawn_building_prop("silo", Vector2i(23, 11), Vector2i(2, 3), Vector2(86, 86))

	# 4. Production Machines (Bakery & Feed Mill)
	_spawn_production_machine("bakery", Vector2i(20, 16))
	_spawn_production_machine("feed_mill", Vector2i(20, 21))

	# 5. Chibi Attraction Spots (Easel and Scarecrow, floating telescope removed!)
	_spawn_building_prop("chibi_scarecrow", Vector2i(17, 17), Vector2i(1, 1), Vector2(32, 44))
	_spawn_building_prop("chibi_easel", Vector2i(18, 13), Vector2i(2, 2), Vector2(44, 48))

	# 6. Animal Pens (Cow at Y=10 North of fields; Chicken & Pig neatly South of fields at Y=23)
	_spawn_animal_pen("cow", Vector2i(11, 10), 2)
	_spawn_animal_pen("chicken", Vector2i(11, 23), 3)
	_spawn_animal_pen("pig", Vector2i(17, 23), 2)

	# 7. Expansive Natural Lake at South-East (Y=19 so water is beautifully visible in bottom right!)
	_spawn_fishing_spot(Vector2i(24, 19))

func _setup_environment_decorations() -> void:
	_movable_decors.clear()
	_flower_targets.clear()

	# 1. Distant Rolling Hills along Northern Boundary (Fixed background landscape)
	_spawn_background_hill("env_hill_1", Vector2(280, 42), Vector2(280, 85))
	_spawn_background_hill("env_hill_2", Vector2(560, 38), Vector2(300, 90))
	_spawn_background_hill("env_hill_1", Vector2(840, 40), Vector2(290, 85))
	_spawn_background_hill("env_hill_2", Vector2(1100, 42), Vector2(300, 90))

	# 2. Customizable / Movable Decorations (Loaded from Save or Default Layout)
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
	_spawn_swaying_tree("env_cherry_tree_1", Vector2(360, 115), Vector2(84, 84))
	_spawn_swaying_tree("env_cherry_tree_2", Vector2(740, 115), Vector2(88, 88))

	# 2. Fruit Orchard (Apple & Mango) - Organized in neat rows in Southwest (below horizontal road)
	# Row 1 (y = 750)
	_spawn_apple_tree(Vector2(110, 750), Vector2(74, 78))
	_spawn_mango_tree(Vector2(230, 750), Vector2(72, 76))
	# Row 2 (y = 850)
	_spawn_mango_tree(Vector2(110, 850), Vector2(74, 76))
	_spawn_apple_tree(Vector2(230, 840), Vector2(74, 78))
	# Row 3 (y = 960)
	_spawn_apple_tree(Vector2(110, 960), Vector2(74, 78))
	_spawn_mango_tree(Vector2(230, 960), Vector2(72, 76))

	# 3. Soft Flowerbeds placed strictly near buildings/corners (clean and orderly)
	_spawn_flowerbed("flowerbed_daisies", Vector2(460, 675), Vector2(40, 28))
	_spawn_flowerbed("flowerbed_roses", Vector2(540, 675), Vector2(38, 26))
	_spawn_flowerbed("flowerbed_lavender", Vector2(600, 565), Vector2(38, 26))
	_spawn_flowerbed("flowerbed_daisies", Vector2(265, 360), Vector2(38, 26))
	_spawn_flowerbed("flowerbed_lavender", Vector2(560, 360), Vector2(38, 26))

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

# --- PHẦN 2.5: ĐÀN CHIM BAY LƯỢN (FLYING BIRDS SYSTEM - REFINED SHADOW) ---
func _setup_flying_birds() -> void:
	var bird_types: Array[String] = ["bird_dove", "bird_sparrow", "bird_dove", "bird_sparrow"]
	var initial_x_offsets: Array[float] = [280.0, 520.0, 760.0, 960.0]
	var initial_ys: Array[float] = [410.0, 470.0, 520.0, 620.0]

	for i: int in range(4):
		var b_type: String = bird_types[i]
		if not SpriteAtlasManager.has_texture(b_type):
			continue

		var bird: FlyingBird = FlyingBird.new()
		bird.base_y = initial_ys[i]
		bird.speed = randf_range(48.0, 65.0)
		bird.flap_freq = randf_range(7.0, 9.0)
		bird.flap_phase = randf_range(0.0, TAU)

		# Ground Shadow reduced to Color(0, 0, 0, 0.12) as requested!
		var shadow_sp: Sprite2D = _create_ellipse_shadow(Vector2(18.0, 8.0))
		shadow_sp.z_index = 1
		shadow_sp.modulate = Color(0.0, 0.0, 0.0, 0.12)
		_birds_container.add_child(shadow_sp)
		bird.shadow = shadow_sp

		# Sky Bird Sprite (z_index = 20)
		var sp: Sprite2D = Sprite2D.new()
		sp.texture = SpriteAtlasManager.get_texture(b_type)
		SpriteAtlasManager.set_sprite_pixel_size(sp, Vector2(26.0, 22.0))
		sp.position = Vector2(initial_x_offsets[i], bird.base_y)
		sp.z_index = 20
		_birds_container.add_child(sp)
		bird.sprite = sp
		bird.base_scale = sp.scale

		_flying_birds.append(bird)

func _update_flying_birds(delta: float) -> void:
	var time: float = Time.get_ticks_msec() * 0.001
	for bird: FlyingBird in _flying_birds:
		# Advance X position
		var cur_x: float = bird.sprite.position.x + bird.speed * delta

		# Sinusoidal Altitude Oscillation
		var sin_offset: float = sin(time * bird.flap_freq + bird.flap_phase) * 6.5
		var cur_y: float = bird.base_y + sin_offset

		# Flapping pulse
		var flap_scale_y: float = 1.0 + sin(time * bird.flap_freq * 2.0 + bird.flap_phase) * 0.16
		bird.sprite.scale = Vector2(bird.base_scale.x, bird.base_scale.y * flap_scale_y)
		bird.sprite.position = Vector2(cur_x, cur_y)

		# Shadow positioned at Y + 25px offset as requested!
		if bird.shadow != null:
			bird.shadow.position = Vector2(cur_x - 4.0, bird.base_y + 25.0)

		# Wrap around screen edge
		if cur_x > 1260.0:
			bird.sprite.position.x = -80.0
			bird.base_y = randf_range(380.0, 680.0)
			bird.speed = randf_range(48.0, 65.0)

# --- PHẦN 1: NÂNG CẤP AI ĐỘNG VẬT NHỎ (AMBIENT CRITTERS / PETS) ---
func _setup_ambient_critters() -> void:
	# 1 & 2. 2 Ducks (animal_duckling) initialized directly inside the lake in open water to verify swimming & ripples!
	# Lake center is (928, 720). Open water is around Vector2(945, 710) and Vector2(905, 675)
	var duck1: AmbientCritter = _create_critter("animal_duckling", Vector2(835.0, 755.0), Vector2(28, 28), LocomotionStyle.WADDLING, 36.0, true)
	duck1.state = CritterState.SWIMMING
	duck1.ripple_node.is_swimming = true
	duck1.ripple_node.visible = true
	duck1.shadow.visible = false

	var duck2: AmbientCritter = _create_critter("animal_duckling", Vector2(790.0, 765.0), Vector2(28, 28), LocomotionStyle.WADDLING, 36.0, true)
	duck2.state = CritterState.SWIMMING
	duck2.ripple_node.is_swimming = true
	duck2.ripple_node.visible = true
	duck2.shadow.visible = false

	# 3 & 4. 2 White Bunnies (critter_bunny) hopping on grass and meadows
	_create_critter("critter_bunny", Vector2(320, 480), Vector2(26, 26), LocomotionStyle.HOPPING, 42.0, false)
	_create_critter("critter_bunny", Vector2(650, 380), Vector2(26, 26), LocomotionStyle.HOPPING, 40.0, false)

	# 5 & 6. 2 Chicks (animal_duckling) hopping near fields & bakery
	_create_critter("animal_duckling", Vector2(460, 480), Vector2(24, 24), LocomotionStyle.HOPPING, 35.0, false)
	_create_critter("animal_duckling", Vector2(530, 490), Vector2(24, 24), LocomotionStyle.HOPPING, 35.0, false)

	# 7 & 8. 2 Butterflies fluttering among flowerbeds (never swimming!)
	_create_critter("critter_butterfly_pink", Vector2(535, 565), Vector2(18, 18), LocomotionStyle.FLUTTERING, 45.0, false)
	_create_critter("critter_butterfly_yellow", Vector2(560, 360), Vector2(18, 18), LocomotionStyle.FLUTTERING, 45.0, false)

	# 9 & 10. 2 Honey Bees fluttering near lavender & lake flowers
	_create_critter("critter_bee", Vector2(620, 565), Vector2(17, 17), LocomotionStyle.FLUTTERING, 40.0, false)
	_create_critter("critter_bee", Vector2(750, 665), Vector2(17, 17), LocomotionStyle.FLUTTERING, 40.0, false)

func _create_critter(sprite_id: String, init_pos: Vector2, size: Vector2, loco_style: int, speed_val: float, swim_capable: bool) -> AmbientCritter:
	if not SpriteAtlasManager.has_texture(sprite_id):
		return null

	var critter: AmbientCritter = AmbientCritter.new()
	critter.critter_id = sprite_id
	critter.locomotion = loco_style
	critter.current_pos = init_pos
	critter.target_pos = init_pos
	critter.speed = speed_val
	critter.can_swim = swim_capable
	critter.state = CritterState.IDLE
	critter.state_timer = randf_range(1.0, 2.5)
	critter.float_phase = randf_range(0.0, TAU)

	var wrapper: Node2D = Node2D.new()
	wrapper.position = init_pos
	wrapper.y_sort_enabled = true
	_critters_container.add_child(wrapper)
	critter.root = wrapper

	# Water Ripple Node (renders below the sprite when swimming)
	var ripple: WaterRippleNode = WaterRippleNode.new()
	ripple.visible = false
	wrapper.add_child(ripple)
	critter.ripple_node = ripple
	if loco_style == LocomotionStyle.FLUTTERING:
		critter.can_swim = false
		wrapper.z_index = 2

	# Shadow
	var shadow_sp: Sprite2D = _create_ellipse_shadow(Vector2(size.x * 0.7, size.y * 0.35))
	shadow_sp.position = Vector2(0, size.y * 0.35)
	shadow_sp.z_index = -1
	wrapper.add_child(shadow_sp)
	critter.shadow = shadow_sp

	# Critter Sprite
	var sp: Sprite2D = Sprite2D.new()
	sp.texture = SpriteAtlasManager.get_texture(sprite_id)
	SpriteAtlasManager.set_sprite_pixel_size(sp, size)
	wrapper.add_child(sp)
	critter.sprite = sp
	critter.base_scale = sp.scale

	_ambient_critters.append(critter)
	return critter

func _update_ambient_critters(delta: float) -> void:
	var time: float = Time.get_ticks_msec() * 0.001
	for critter: AmbientCritter in _ambient_critters:
		if critter.locomotion == LocomotionStyle.FLUTTERING:
			if critter.state == CritterState.SWIMMING or critter.state == CritterState.SHAKING:
				critter.state = CritterState.IDLE
			critter.ripple_node.is_swimming = false
			critter.ripple_node.visible = false
		else:
			critter.ripple_node.visible = (critter.state == CritterState.SWIMMING)
		match critter.state:
			CritterState.IDLE:
				critter.state_timer -= delta

				# Subtle cute idle behaviors
				if critter.locomotion == LocomotionStyle.HOPPING:
					# Pecking grain / nibbling grass (squash & stretch scale.y)
					critter.sprite.scale.y = critter.base_scale.y * (1.0 - absf(sin(time * 5.0)) * 0.12)
					critter.sprite.scale.x = critter.base_scale.x * (1.0 + absf(sin(time * 5.0)) * 0.08)
					critter.sprite.rotation = 0.0
				elif critter.locomotion == LocomotionStyle.WADDLING:
					# Gentle breathing tilt
					critter.sprite.rotation = sin(time * 3.5) * 0.03
					critter.sprite.scale = critter.base_scale
				elif critter.locomotion == LocomotionStyle.FLUTTERING:
					# Hovering or perching on petals: gentle wing beat
					critter.sprite.scale.x = critter.base_scale.x * (0.85 + sin(time * 10.0) * 0.15)
					critter.sprite.scale.y = critter.base_scale.y

				# Check when idle finishes -> choose new destination
				if critter.state_timer <= 0.0:
					critter.target_pos = _get_random_critter_waypoint(critter.can_swim, critter.locomotion == LocomotionStyle.FLUTTERING)
					var dist: float = critter.current_pos.distance_to(critter.target_pos)
					if dist < 25.0:
						dist = 25.0

					critter.sprite.flip_h = (critter.target_pos.x < critter.current_pos.x)
					critter.ripple_node.facing_left = critter.sprite.flip_h

					# Determine starting move state based on whether current spot is in water
					if critter.can_swim and critter.locomotion != LocomotionStyle.FLUTTERING and _is_in_water_pond(critter.current_pos):
						critter.state = CritterState.SWIMMING
						critter.ripple_node.is_swimming = true
						critter.ripple_node.visible = true
						critter.shadow.visible = false
						critter.move_duration = dist / (critter.speed * 0.70)
					else:
						critter.state = CritterState.MOVING_LAND
						critter.ripple_node.is_swimming = false
						critter.ripple_node.visible = false
						critter.shadow.visible = true
						critter.move_duration = dist / critter.speed

					critter.move_progress = 0.0

			CritterState.MOVING_LAND:
				critter.move_progress += delta / critter.move_duration
				var p: float = clampf(critter.move_progress, 0.0, 1.0)
				var new_pos: Vector2 = critter.current_pos.lerp(critter.target_pos, p)

				# Non-swimming land critters turn back immediately if approaching the lake water/pier
				if not critter.can_swim and _is_in_lake_zone(new_pos):
					critter.target_pos = critter.current_pos
					critter.root.position = critter.current_pos
					critter.state = CritterState.IDLE
					critter.state_timer = randf_range(1.0, 2.0)
					continue

				critter.root.position = new_pos

				# Swimming-capable ducks seamlessly switch to SWIMMING!
				if critter.can_swim and critter.locomotion != LocomotionStyle.FLUTTERING and _is_in_water_pond(new_pos):
					critter.state = CritterState.SWIMMING
					critter.ripple_node.is_swimming = true
					critter.ripple_node.visible = true
					critter.shadow.visible = false
					var rem_dist: float = new_pos.distance_to(critter.target_pos)
					critter.move_duration = critter.move_progress * critter.move_duration + (rem_dist / (critter.speed * 0.70))

				# Land Locomotion animations
				if critter.locomotion == LocomotionStyle.HOPPING:
					# Parabolic / sinusoidal hop trajectory
					var hop: float = absf(sin(p * PI * 4.0)) * critter.hop_height
					critter.sprite.position.y = -hop
					critter.sprite.rotation = 0.0
					critter.sprite.scale = critter.base_scale
				elif critter.locomotion == LocomotionStyle.WADDLING:
					# Continuous waddling sway side-to-side
					critter.sprite.position.y = 0.0
					critter.sprite.rotation = sin(time * 12.0) * 0.08
					critter.sprite.scale = critter.base_scale
				elif critter.locomotion == LocomotionStyle.FLUTTERING:
					# Smooth undulating wave flight path
					critter.sprite.position.y = sin(time * 5.0 + critter.float_phase) * 6.0
					critter.sprite.scale.x = critter.base_scale.x * (0.8 + sin(time * 20.0) * 0.25)

				if critter.move_progress >= 1.0:
					critter.current_pos = critter.target_pos
					critter.root.position = critter.current_pos
					critter.sprite.position.y = 0.0
					critter.sprite.rotation = 0.0
					critter.state = CritterState.IDLE
					critter.state_timer = randf_range(1.5, 3.0)

			CritterState.SWIMMING:
				critter.shadow.visible = false
				critter.ripple_node.is_swimming = true
				critter.ripple_node.visible = true

				critter.move_progress += delta / critter.move_duration
				var sp_p: float = clampf(critter.move_progress, 0.0, 1.0)
				var swim_pos: Vector2 = critter.current_pos.lerp(critter.target_pos, sp_p)
				critter.root.position = swim_pos

				# Water emergence detection: swimming onto shore!
				if not _is_in_water_pond(swim_pos):
					critter.ripple_node.is_swimming = false
					critter.ripple_node.visible = false
					critter.shadow.visible = true
					critter.state = CritterState.SHAKING
					critter.shake_timer = 0.45
					critter.sprite.scale = critter.base_scale
					critter.sprite.position.y = 0.0

				# Swimming animation: glide with soft wave bobbing and submerged body tuck
				critter.sprite.position.y = sin(time * 4.0) * 2.0
				critter.sprite.rotation = sin(time * 3.0) * 0.04
				critter.sprite.scale = Vector2(critter.base_scale.x, critter.base_scale.y * 0.85)

				if critter.move_progress >= 1.0:
					critter.current_pos = critter.target_pos
					critter.root.position = critter.current_pos
					critter.state = CritterState.IDLE
					critter.state_timer = randf_range(1.5, 3.0)

			CritterState.SHAKING:
				# Quick joyful shake-off-water animation upon exiting pond!
				critter.shake_timer -= delta
				critter.sprite.rotation = sin(critter.shake_timer * 38.0) * 0.18
				critter.sprite.position.y = 0.0
				critter.sprite.scale = critter.base_scale

				if critter.shake_timer <= 0.0:
					critter.sprite.rotation = 0.0
					critter.state = CritterState.IDLE
					critter.state_timer = randf_range(1.0, 2.0)

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
	for x: int in range(cell.x, cell.x + 6):
		for y: int in range(cell.y, cell.y + 4):
			var c: Vector2i = Vector2i(x, y)
			GridManager.occupied_cells[c] = 777
			GridManager.astar_grid.set_point_solid(c, true)

	var pen: AnimalPen = AnimalPen.new()
	pen.y_sort_enabled = true
	pen.animal_id = a_id
	pen.animal_count = count
	pen.grid_pos = cell
	var center_pixel: Vector2 = Vector2(
		(float(cell.x) + 3.0) * 32.0,
		(float(cell.y) + 2.0) * 32.0
	)
	pen.position = center_pixel
	animal_pens_container.add_child(pen)
	_animal_pens.append(pen)
	return pen

func _spawn_fishing_spot(cell: Vector2i) -> FishingSpot:
	for x: int in range(cell.x, cell.x + 10):
		for y: int in range(cell.y, cell.y + 7):
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

	# 4. Railroad Track + Pastel Steam Train on Northern Ridge
	_draw_railroad_and_train()

	# 5. Perimeter Hand-drawn Border
	var fence_col: Color = Color(0.42, 0.30, 0.21, 0.6)
	draw_rect(Rect2(0, 0, total_w, total_h), fence_col, false, 3.0)

	# Entrance Gate marker at (0, 20)
	var gate_pos: Vector2 = Vector2(0, 20 * 32)
	draw_rect(Rect2(gate_pos, Vector2(12, 32)), Color(0.96, 0.82, 0.45), true)
	draw_rect(Rect2(gate_pos, Vector2(12, 32)), Color(0.42, 0.30, 0.21), false, 1.8)

func _draw_railroad_and_train() -> void:
	var track_y: float = 68.0
	var track_len: float = 1250.0

	# Wooden ties in warm brown
	for tx: float in range(0, track_len, 14.0):
		draw_line(Vector2(tx, track_y - 10), Vector2(tx, track_y + 10), Color(0.52, 0.38, 0.26), 2.5)

	# Steel rails
	draw_line(Vector2(0, track_y - 7), Vector2(track_len, track_y - 7), Color(0.80, 0.78, 0.82), 2.0)
	draw_line(Vector2(0, track_y + 7), Vector2(track_len, track_y + 7), Color(0.80, 0.78, 0.82), 2.0)

	# Moving Steam Locomotive in Cozy Pastel Red & Mustard
	var train_x: float = fmod(Time.get_ticks_msec() * 0.055, 1300.0) - 200.0

	# Wagon 2 (Pastel Hay)
	draw_rect(Rect2(train_x - 105, track_y - 14, 46, 24), Color(0.65, 0.48, 0.32), true)
	draw_circle(Vector2(train_x - 82, track_y - 16), 10.0, Color(0.96, 0.85, 0.45))

	# Wagon 1 (Pastel Blue Milk)
	draw_rect(Rect2(train_x - 52, track_y - 15, 46, 26), Color(0.55, 0.68, 0.78), true)
	draw_circle(Vector2(train_x - 29, track_y - 17), 8.0, Color(0.98, 0.98, 0.95))

	# Engine Body (Pastel Terracotta)
	draw_rect(Rect2(train_x, track_y - 18, 56, 30), Color(0.88, 0.42, 0.38), true)
	draw_rect(Rect2(train_x + 10, track_y - 28, 24, 10), Color(0.42, 0.30, 0.21), true)
	draw_rect(Rect2(train_x + 44, track_y - 26, 8, 8), Color(0.38, 0.32, 0.30), true)

	# Steam Puffs
	var time_val: float = Time.get_ticks_msec() * 0.005
	for p: int in range(4):
		var puff_offset: float = float(p) * 14.0
		var puff_x: float = train_x + 46.0 - puff_offset - sin(time_val + float(p)) * 4.0
		var puff_y: float = track_y - 34.0 - float(p) * 8.0
		var puff_r: float = 6.0 + float(p) * 3.0
		var puff_alpha: float = clampf(0.55 - float(p) * 0.12, 0.05, 0.6)
		draw_circle(Vector2(puff_x, puff_y), puff_r, Color(1.0, 1.0, 1.0, puff_alpha))

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

	# 5. Hồ Câu Cá & Cầu Gỗ (Rect2(560, 560, 540, 300) bao phủ cả Cầu Gỗ lẫn Mặt Hồ)
	var f_rect: Rect2 = Rect2(Vector2(560.0, 560.0), Vector2(540.0, 300.0))
	if f_rect.has_point(world_pos):
		if fishing_spot != null and is_instance_valid(fishing_spot):
			if fishing_spot.state == FishingSpot.SpotState.READY:
				return fishing_spot.handle_fishing_click()
	
	return false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
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
	# 1. BỜ ĐÔNG BÊN KIA CẦU GỖ (x: 1080..1320) - Khu Vườn Sinh Thái & Đồi Hoa Anh Đào Chibi
	_spawn_scenic_element("env_cherry_tree", Vector2(1120, 180), Vector2(88, 92))
	_spawn_scenic_element("env_river_bush", Vector2(1145, 230), Vector2(40, 36))
	_spawn_scenic_element("env_lush_green_tree", Vector2(1220, 220), Vector2(90, 95))
	_spawn_scenic_element("flowerbed_round", Vector2(1160, 280), Vector2(36, 26))

	_spawn_scenic_element("env_lush_green_tree", Vector2(1135, 360), Vector2(90, 95))
	_spawn_scenic_element("env_river_bush", Vector2(1150, 420), Vector2(40, 36))
	_spawn_scenic_element("env_cherry_tree", Vector2(1230, 380), Vector2(88, 92))
	_spawn_scenic_element("flowerbed_roses", Vector2(1165, 470), Vector2(38, 26))

	_spawn_scenic_element("env_cherry_tree", Vector2(1120, 530), Vector2(88, 92))
	_spawn_scenic_element("env_river_bush", Vector2(1155, 590), Vector2(40, 36))
	_spawn_scenic_element("env_lush_green_tree", Vector2(1225, 560), Vector2(90, 95))
	_spawn_scenic_element("flowerbed_lavender", Vector2(1165, 650), Vector2(38, 26))

	_spawn_scenic_element("env_lush_green_tree", Vector2(1125, 730), Vector2(90, 95))
	_spawn_scenic_element("env_river_bush", Vector2(1145, 790), Vector2(40, 36))
	_spawn_scenic_element("env_cherry_tree", Vector2(1230, 760), Vector2(88, 92))
	_spawn_scenic_element("flowerbed_daisies", Vector2(1165, 840), Vector2(38, 26))

	_spawn_scenic_element("env_cherry_tree", Vector2(1130, 890), Vector2(88, 92))
	_spawn_scenic_element("env_river_bush", Vector2(1150, 940), Vector2(40, 36))
	_spawn_scenic_element("env_lush_green_tree", Vector2(1230, 930), Vector2(90, 95))

	# 2. PHÍA BẮC ÔM SAU CHUỒNG BÒ & KHU NHÀ NẤM (y: 200..320)
	_spawn_scenic_element("env_cherry_tree", Vector2(180, 230), Vector2(88, 92))
	_spawn_scenic_element("env_lush_green_tree", Vector2(280, 220), Vector2(90, 95))
	_spawn_scenic_element("env_lush_green_tree", Vector2(380, 220), Vector2(90, 95))
	_spawn_scenic_element("env_cherry_tree", Vector2(490, 230), Vector2(88, 92))
	_spawn_scenic_element("env_lush_green_tree", Vector2(610, 220), Vector2(90, 95))
	_spawn_scenic_element("env_cherry_tree", Vector2(730, 230), Vector2(88, 92))
	_spawn_scenic_element("env_lush_green_tree", Vector2(840, 220), Vector2(90, 95))
	_spawn_scenic_element("flowerbed_daisies", Vector2(320, 260), Vector2(38, 26))
	_spawn_scenic_element("flowerbed_roses", Vector2(660, 260), Vector2(38, 26))

	# 3. BỜ TÂY VEN SÔNG (cách mép nước > 40px, tuyệt đối không đè mặt sông)
	_spawn_scenic_element("env_river_bush", Vector2(765, 380), Vector2(42, 38))
	_spawn_scenic_element("env_lush_green_tree", Vector2(775, 480), Vector2(85, 90))
	_spawn_scenic_element("flowerbed_round", Vector2(755, 550), Vector2(36, 26))
	_spawn_scenic_element("env_river_bush", Vector2(760, 615), Vector2(42, 38))
	_spawn_scenic_element("env_cherry_tree", Vector2(765, 830), Vector2(85, 90))
	_spawn_scenic_element("env_river_bush", Vector2(755, 895), Vector2(42, 38))
	_spawn_scenic_element("flowerbed_lavender", Vector2(750, 950), Vector2(38, 26))
	_spawn_scenic_element("env_lush_green_tree", Vector2(140, 1140), Vector2(90, 95))
	_spawn_scenic_element("env_cherry_tree", Vector2(460, 1140), Vector2(88, 92))

	print("[MainFarm] Spawned Harmonious Hay Day Scenic Valley with ", _scenic_elements.size(), " elements!")

func _setup_scenic_clouds() -> void:
	_scenic_clouds.clear()
	var cloud_configs: Array[Dictionary] = [
		{"id": "chibi_cloud_1", "pos": Vector2(140.0, 45.0), "size": Vector2(140.0, 95.0), "speed": 14.0},
		{"id": "chibi_cloud_2", "pos": Vector2(460.0, 75.0), "size": Vector2(130.0, 62.0), "speed": 17.0},
		{"id": "chibi_cloud_3", "pos": Vector2(780.0, 40.0), "size": Vector2(120.0, 75.0), "speed": 13.0},
		{"id": "chibi_cloud_4", "pos": Vector2(1120.0, 85.0), "size": Vector2(145.0, 58.0), "speed": 16.0},
		{"id": "chibi_cloud_2", "pos": Vector2(1460.0, 50.0), "size": Vector2(130.0, 62.0), "speed": 15.0}
	]

	for cfg: Dictionary in cloud_configs:
		var c_id: String = str(cfg["id"])
		var c_size: Vector2 = cfg["size"] as Vector2
		var sp: Sprite2D = SpriteAtlasManager.create_sized_sprite(c_id, c_size)
		if sp != null:
			sp.position = cfg["pos"] as Vector2
			sp.z_index = 35
			sp.modulate = Color(1.0, 1.0, 1.0, 0.88)
			add_child(sp)
			_scenic_clouds.append({
				"sprite": sp,
				"speed": float(cfg["speed"])
			})
	print("[MainFarm] Setup ", _scenic_clouds.size(), " drifting scenic clouds at North horizon.")

func _update_scenic_clouds(delta: float) -> void:
	for cloud_data: Dictionary in _scenic_clouds:
		var sp: Sprite2D = cloud_data["sprite"] as Sprite2D
		if sp != null and is_instance_valid(sp):
			var spd: float = float(cloud_data["speed"])
			sp.position.x += spd * delta
			if sp.position.x > 1850.0:
				sp.position.x = -250.0
