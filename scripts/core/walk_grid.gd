extends Node2D
class_name WalkGrid

const CELL_SIZE: float = 16.0
const MAP_WIDTH: float = 2048.0
const MAP_HEIGHT: float = 2048.0
const COLS: int = int(MAP_WIDTH / CELL_SIZE) # 128
const ROWS: int = int(MAP_HEIGHT / CELL_SIZE) # 128

var astar: AStar2D = AStar2D.new()

func _ready() -> void:
	build_grid()
	
	# Connect to grid changes to update navigation when new buildings or paths are placed
	EventBus.building_placed.connect(func(_id: int, _b_id: String, _pos: Vector2i) -> void:
		call_deferred("build_grid")
	)
	EventBus.path_tile_changed.connect(func(_pos: Vector2i, _placed: bool) -> void:
		call_deferred("build_grid")
	)

func get_point_id(gx: int, gy: int) -> int:
	return gy * COLS + gx

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		clampi(int(floor(world_pos.x / CELL_SIZE)), 0, COLS - 1),
		clampi(int(floor(world_pos.y / CELL_SIZE)), 0, ROWS - 1)
	)

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2((grid_pos.x + 0.5) * CELL_SIZE, (grid_pos.y + 0.5) * CELL_SIZE)

func is_cell_walkable(gx: int, gy: int) -> bool:
	# Outside world perimeter borders (except the entrance gate at x=0..2, y=39..42)
	var is_gate: bool = (gx <= 2 and gy >= 38 and gy <= 43)
	if not is_gate:
		if gx < 1 or gx >= COLS - 1 or gy < 1 or gy >= ROWS - 1:
			return false
	
	var world_pos: Vector2 = Vector2((gx + 0.5) * CELL_SIZE, (gy + 0.5) * CELL_SIZE)
	
	# Check river water / sand (wooden bridge is automatically exempt in is_in_water_or_sand)
	if GridManager.is_in_water_or_sand(world_pos):
		return false
	
	# Check GridManager occupied cells (32px cells)
	var cell_32: Vector2i = Vector2i(int(floor(world_pos.x / 32.0)), int(floor(world_pos.y / 32.0)))
	if GridManager.occupied_cells.has(cell_32):
		var b_instance_id: int = int(GridManager.occupied_cells[cell_32])
		var b_data: Dictionary = GridManager.get_building_data(b_instance_id)
		if not bool(b_data.get("is_walkable", false)):
			return false
	
	return true

func build_grid() -> void:
	astar.clear()
	
	# Add walkable points to AStar2D
	for y: int in range(ROWS):
		for x: int in range(COLS):
			if is_cell_walkable(x, y):
				var pid: int = get_point_id(x, y)
				var wpos: Vector2 = Vector2((x + 0.5) * CELL_SIZE, (y + 0.5) * CELL_SIZE)
				
				# Paved roads have lower weight so player prefers walking on neat paths
				var cell_32: Vector2i = Vector2i(int(floor(wpos.x / 32.0)), int(floor(wpos.y / 32.0)))
				var weight: float = 1.0 if GridManager.is_path_tile(cell_32) else 1.6
				
				astar.add_point(pid, wpos, weight)

	# Connect adjacent neighbors (4-directional: East & South)
	for y: int in range(ROWS):
		for x: int in range(COLS):
			var pid: int = get_point_id(x, y)
			if not astar.has_point(pid):
				continue
			
			# Connect Right neighbor
			if x + 1 < COLS:
				var r_id: int = get_point_id(x + 1, y)
				if astar.has_point(r_id):
					astar.connect_points(pid, r_id)
			
			# Connect Down neighbor
			if y + 1 < ROWS:
				var d_id: int = get_point_id(x, y + 1)
				if astar.has_point(d_id):
					astar.connect_points(pid, d_id)

func find_path(from: Vector2, to: Vector2) -> Array[Vector2]:
	if astar.get_point_count() == 0:
		return []
	
	var from_id: int = astar.get_closest_point(from)
	var to_id: int = astar.get_closest_point(to)
	
	if from_id == -1 or to_id == -1:
		return []
	
	var target_wpos: Vector2 = astar.get_point_position(to_id)
	if from_id == to_id:
		return [target_wpos]
	
	var raw_path: PackedVector2Array = astar.get_point_path(from_id, to_id)
	var path: Array[Vector2] = []
	for p: Vector2 in raw_path:
		path.append(p)
	
	# If the first waypoint is behind current position, we can optimize
	if path.size() > 1 and from.distance_to(path[1]) < from.distance_to(path[0]):
		path.remove_at(0)
		
	return path
