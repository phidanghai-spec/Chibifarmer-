extends Node

const GRID_WIDTH: int = 64
const GRID_HEIGHT: int = 64
const CELL_SIZE: Vector2 = Vector2(32.0, 32.0)

const ENTRANCE_CELL: Vector2i = Vector2i(0, 20)
const EXIT_CELL: Vector2i = Vector2i(63, 20)
const DEFAULT_SHOP_CELL: Vector2i = Vector2i(6, 18)

var astar_grid: AStarGrid2D = AStarGrid2D.new()

# Maps Vector2i -> instance_id: int
var occupied_cells: Dictionary = {}

# Maps instance_id: int -> Dictionary (data about placed building)
var placed_buildings: Dictionary = {}

# Maps Vector2i -> bool (cells that have paved paths)
var path_cells: Dictionary = {}

var total_attraction_score: int = 10
var _next_instance_id: int = 1

func add_attraction_score(amount: int) -> void:
	if amount <= 0:
		return
	total_attraction_score += amount
	EventBus.attraction_score_changed.emit(total_attraction_score)

func _ready() -> void:
	_init_astar()
	_init_default_layout()

func _init_astar() -> void:
	astar_grid.region = Rect2i(0, 0, GRID_WIDTH, GRID_HEIGHT)
	astar_grid.cell_size = CELL_SIZE
	astar_grid.offset = CELL_SIZE * 0.5
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.update()
	
	# Default weight on grass is higher; path tiles will have weight 1.0
	for x: int in range(GRID_WIDTH):
		for y: int in range(GRID_HEIGHT):
			var cell: Vector2i = Vector2i(x, y)
			astar_grid.set_point_weight_scale(cell, 3.0)

func _init_default_layout() -> void:
	# Main east-west road from entrance (0, 20) across farm center, over the wooden bridge to East Bank (x = 0..42)
	for x: int in range(0, 42):
		place_path(Vector2i(x, 20))
	# Hillside road leading North to Farmhouse & Barns
	for y: int in range(13, 20):
		place_path(Vector2i(18, y))
	# South alley leading to Bakery & Feed Mill
	for y: int in range(20, 25):
		place_path(Vector2i(18, y))
	# Pathway branching into Fishing Hut at West Bank
	place_path(Vector2i(23, 21))
	# East Bank scenic walking promenade
	for y: int in range(14, 20):
		place_path(Vector2i(35, y))
	for y: int in range(21, 28):
		place_path(Vector2i(35, y))

# --- Coordinate Utilities ---

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / CELL_SIZE.x)),
		int(floor(world_pos.y / CELL_SIZE.y))
	)


func get_world_position(grid_pos: Vector2i) -> Vector2:
	return grid_to_world(grid_pos)

func get_grid_position(world_pos: Vector2) -> Vector2i:
	return world_to_grid(world_pos)
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * CELL_SIZE.x + CELL_SIZE.x * 0.5,
		grid_pos.y * CELL_SIZE.y + CELL_SIZE.y * 0.5
	)

func is_within_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < GRID_WIDTH and cell.y < GRID_HEIGHT

# --- Building & Path Queries ---

func is_cell_occupied(cell: Vector2i) -> bool:
	return occupied_cells.has(cell)

func get_building_instance_at(cell: Vector2i) -> int:
	return int(occupied_cells.get(cell, -1))

func get_building_data(instance_id: int) -> Dictionary:
	return placed_buildings.get(instance_id, {}) as Dictionary

func is_path_tile(cell: Vector2i) -> bool:
	return path_cells.get(cell, false) as bool

func is_cell_walkable(cell: Vector2i) -> bool:
	if not is_within_bounds(cell):
		return false
	return not astar_grid.is_point_solid(cell)

# --- Placement Logic ---

func can_place_building(building_id: String, grid_pos: Vector2i) -> bool:
	var b_data: Dictionary = DataManager.get_building(building_id)
	if b_data.is_empty():
		return false
	
	var raw_size: Array = b_data.get("size", [1, 1]) as Array
	var size_x: int = int(raw_size[0])
	var size_y: int = int(raw_size[1])
	
	if grid_pos.x < 0 or grid_pos.y < 0:
		return false
	if (grid_pos.x + size_x) > GRID_WIDTH or (grid_pos.y + size_y) > GRID_HEIGHT:
		return false
	
	for x: int in range(grid_pos.x, grid_pos.x + size_x):
		for y: int in range(grid_pos.y, grid_pos.y + size_y):
			var check_cell: Vector2i = Vector2i(x, y)
			if occupied_cells.has(check_cell):
				return false
	
	return true

func place_building(building_id: String, grid_pos: Vector2i) -> int:
	if not can_place_building(building_id, grid_pos):
		return -1
	
	var b_data: Dictionary = DataManager.get_building(building_id)
	var raw_size: Array = b_data.get("size", [1, 1]) as Array
	var size: Vector2i = Vector2i(int(raw_size[0]), int(raw_size[1]))
	var is_walkable: bool = bool(b_data.get("is_walkable", false))
	var attraction: int = int(b_data.get("attraction_score", 0))
	
	var instance_id: int = _next_instance_id
	_next_instance_id += 1
	
	var info: Dictionary = {
		"instance_id": instance_id,
		"building_id": building_id,
		"grid_pos": grid_pos,
		"size": size,
		"is_walkable": is_walkable,
		"attraction_score": attraction,
		"type": String(b_data.get("type", "unknown"))
	}
	
	placed_buildings[instance_id] = info
	
	for x: int in range(grid_pos.x, grid_pos.x + size.x):
		for y: int in range(grid_pos.y, grid_pos.y + size.y):
			var cell: Vector2i = Vector2i(x, y)
			occupied_cells[cell] = instance_id
			if not is_walkable:
				astar_grid.set_point_solid(cell, true)
	
	total_attraction_score += attraction
	EventBus.building_placed.emit(instance_id, building_id, grid_pos)
	EventBus.attraction_score_changed.emit(total_attraction_score)
	return instance_id

func place_path(grid_pos: Vector2i) -> bool:
	if not is_within_bounds(grid_pos):
		return false
	if occupied_cells.has(grid_pos):
		return false
	if path_cells.get(grid_pos, false):
		return true
	
	path_cells[grid_pos] = true
	astar_grid.set_point_solid(grid_pos, false)
	# Path tiles have weight 1.0 (highly preferred over grass weight 3.0)
	astar_grid.set_point_weight_scale(grid_pos, 1.0)
	
	var path_info: Dictionary = DataManager.get_building("path_tile")
	var attraction: int = int(path_info.get("attraction_score", 1))
	total_attraction_score += attraction
	
	EventBus.path_tile_changed.emit(grid_pos, true)
	EventBus.attraction_score_changed.emit(total_attraction_score)
	return true

func remove_path(grid_pos: Vector2i) -> bool:
	if not path_cells.get(grid_pos, false):
		return false
	
	path_cells.erase(grid_pos)
	astar_grid.set_point_weight_scale(grid_pos, 3.0)
	
	var path_info: Dictionary = DataManager.get_building("path_tile")
	var attraction: int = int(path_info.get("attraction_score", 1))
	total_attraction_score = maxi(0, total_attraction_score - attraction)
	
	EventBus.path_tile_changed.emit(grid_pos, false)
	EventBus.attraction_score_changed.emit(total_attraction_score)
	return true

func remove_building(instance_id: int) -> bool:
	if not placed_buildings.has(instance_id):
		return false
	
	var info: Dictionary = placed_buildings[instance_id] as Dictionary
	var grid_pos: Vector2i = info["grid_pos"] as Vector2i
	var size: Vector2i = info["size"] as Vector2i
	var is_walkable: bool = bool(info["is_walkable"])
	var attraction: int = int(info["attraction_score"])
	
	for x: int in range(grid_pos.x, grid_pos.x + size.x):
		for y: int in range(grid_pos.y, grid_pos.y + size.y):
			var cell: Vector2i = Vector2i(x, y)
			occupied_cells.erase(cell)
			if not is_walkable:
				astar_grid.set_point_solid(cell, false)
				# Reset weight scale based on whether it is a path tile
				if path_cells.get(cell, false):
					astar_grid.set_point_weight_scale(cell, 1.0)
				else:
					astar_grid.set_point_weight_scale(cell, 3.0)
	
	placed_buildings.erase(instance_id)
	total_attraction_score = maxi(0, total_attraction_score - attraction)
	
	EventBus.building_removed.emit(instance_id, grid_pos)
	EventBus.attraction_score_changed.emit(total_attraction_score)
	return true

func move_building(instance_id: int, new_grid_pos: Vector2i) -> bool:
	if not placed_buildings.has(instance_id):
		return false
	
	var info: Dictionary = placed_buildings[instance_id] as Dictionary
	var old_pos: Vector2i = info["grid_pos"] as Vector2i
	var size: Vector2i = info["size"] as Vector2i
	var is_walkable: bool = bool(info["is_walkable"])
	
	# 1. Temporarily clear old occupancy
	for x: int in range(old_pos.x, old_pos.x + size.x):
		for y: int in range(old_pos.y, old_pos.y + size.y):
			occupied_cells.erase(Vector2i(x, y))
	
	# 2. Check if new position is valid
	var can_place: bool = true
	if new_grid_pos.x < 0 or new_grid_pos.y < 0:
		can_place = false
	elif (new_grid_pos.x + size.x) > GRID_WIDTH or (new_grid_pos.y + size.y) > GRID_HEIGHT:
		can_place = false
	else:
		for x: int in range(new_grid_pos.x, new_grid_pos.x + size.x):
			for y: int in range(new_grid_pos.y, new_grid_pos.y + size.y):
				if occupied_cells.has(Vector2i(x, y)):
					can_place = false
					break
			if not can_place:
				break
	
	# 3. If cannot place, rollback to old position
	if not can_place:
		for x: int in range(old_pos.x, old_pos.x + size.x):
			for y: int in range(old_pos.y, old_pos.y + size.y):
				occupied_cells[Vector2i(x, y)] = instance_id
		return false
	
	# 4. Commit new position
	for x: int in range(old_pos.x, old_pos.x + size.x):
		for y: int in range(old_pos.y, old_pos.y + size.y):
			var cell: Vector2i = Vector2i(x, y)
			if not is_walkable:
				astar_grid.set_point_solid(cell, false)
				astar_grid.set_point_weight_scale(cell, 1.0 if path_cells.get(cell, false) else 3.0)
	
	for x: int in range(new_grid_pos.x, new_grid_pos.x + size.x):
		for y: int in range(new_grid_pos.y, new_grid_pos.y + size.y):
			var cell: Vector2i = Vector2i(x, y)
			occupied_cells[cell] = instance_id
			if not is_walkable:
				astar_grid.set_point_solid(cell, true)
	
	info["grid_pos"] = new_grid_pos
	EventBus.building_moved.emit(instance_id, new_grid_pos)
	return true

# --- Tourism & Visitor Pathfinding ---

func get_tourist_path(start_pos: Vector2, target_pos: Vector2) -> PackedVector2Array:
	var start_cell: Vector2i = world_to_grid(start_pos)
	var target_cell: Vector2i = world_to_grid(target_pos)
	
	if not is_within_bounds(start_cell) or not is_within_bounds(target_cell):
		return PackedVector2Array()
	
	# If target is solid (e.g. inside building), find closest walkable adjacent cell
	if not is_cell_walkable(target_cell):
		target_cell = get_closest_walkable_neighbor(target_cell)
	
	if not is_cell_walkable(start_cell):
		start_cell = get_closest_walkable_neighbor(start_cell)
	
	return astar_grid.get_point_path(start_cell, target_cell)

func get_closest_walkable_neighbor(center: Vector2i) -> Vector2i:
	var neighbors: Array[Vector2i] = [
		center + Vector2i.UP,
		center + Vector2i.DOWN,
		center + Vector2i.LEFT,
		center + Vector2i.RIGHT,
		center + Vector2i(-1, -1),
		center + Vector2i(1, -1),
		center + Vector2i(-1, 1),
		center + Vector2i(1, 1)
	]
	
	for n: Vector2i in neighbors:
		if is_cell_walkable(n):
			return n
	return center

func get_points_of_interest() -> Array[Vector2i]:
	var pois: Array[Vector2i] = []
	for id_val: Variant in placed_buildings:
		var info: Dictionary = placed_buildings[id_val] as Dictionary
		var pos: Vector2i = info["grid_pos"] as Vector2i
		var size: Vector2i = info["size"] as Vector2i
		
		# Find cells bordering the building
		for x: int in range(pos.x - 1, pos.x + size.x + 1):
			for y: int in range(pos.y - 1, pos.y + size.y + 1):
				var check: Vector2i = Vector2i(x, y)
				if is_cell_walkable(check):
					pois.append(check)
	return pois

func get_random_interest_point() -> Vector2i:
	var pois: Array[Vector2i] = get_points_of_interest()
	if not pois.is_empty():
		return pois.pick_random()
	
	# Fallback to any paved path tile or entrance
	if not path_cells.is_empty():
		var keys: Array = path_cells.keys()
		return keys.pick_random() as Vector2i
	
	return ENTRANCE_CELL
