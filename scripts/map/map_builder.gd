extends RefCounted
class_name MapBuilder

const TILE_SIZE: int = 32
const LAYOUT_PATH: String = "res://data/map_layout.json"

static func get_blocked_cells() -> Dictionary:
	var blocked: Dictionary = {} # Vector2i -> String

	# 1. Khu vực HUD góc trên bên trái (X < 280, Y < 220)
	var max_hud_col: int = int(ceil(280.0 / float(TILE_SIZE)))
	var max_hud_row: int = int(ceil(220.0 / float(TILE_SIZE)))
	for x: int in range(max_hud_col):
		for y: int in range(max_hud_row):
			blocked[Vector2i(x, y)] = "hud"

	# 2. Toàn bộ các ô thuộc Đường gạch (Path)
	for p_cell: Variant in GridManager.path_cells:
		blocked[p_cell as Vector2i] = "path"

	# 3. Dòng sông + Bờ cát (trừ khu vực Cầu gỗ ở Row 20)
	for y_idx: int in range(GridManager.GRID_HEIGHT):
		# Row 20 là cầu gỗ bắc qua sông
		if y_idx == 20:
			continue
		var world_y: float = float(y_idx * TILE_SIZE) + float(TILE_SIZE) * 0.5
		var cx: float = FishingSpot.get_river_center_x(world_y)
		var sand_half: float = 108.0
		var col_start: int = int(floor((cx - sand_half) / float(TILE_SIZE)))
		var col_end: int = int(ceil((cx + sand_half) / float(TILE_SIZE)))
		for x_idx: int in range(col_start, col_end + 1):
			if x_idx >= 0 and x_idx < GridManager.GRID_WIDTH:
				blocked[Vector2i(x_idx, y_idx)] = "river_sand"

	# 4. Các ô đã bị chiếm dụng bởi công trình/chuồng trại/ruộng
	for c: Variant in GridManager.occupied_cells:
		blocked[c as Vector2i] = "occupied"

	return blocked

static func is_cell_blocked(cell: Vector2i, blocked_dict: Dictionary) -> bool:
	return blocked_dict.has(cell)

static func load_layout_data() -> Dictionary:
	if not FileAccess.file_exists(LAYOUT_PATH):
		push_warning("[MapBuilder] Layout file not found: " + LAYOUT_PATH)
		return {}
	var file: FileAccess = FileAccess.open(LAYOUT_PATH, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	var err: Error = json.parse(text)
	if err != OK:
		push_error("[MapBuilder] Failed to parse JSON: " + json.get_error_message())
		return {}
	return json.data as Dictionary

static func build_farm(farm: Node2D) -> void:
	var data: Dictionary = load_layout_data()
	if data.is_empty():
		print("[MapBuilder] No layout data loaded, skipping build.")
		return

	# 1. Phân vùng 1: Khu Nhà & Xưởng Chế Biến
	var buildings: Array = data.get("buildings", []) as Array
	for b_val: Variant in buildings:
		if b_val is Dictionary:
			var b: Dictionary = b_val as Dictionary
			var b_type: String = String(b.get("type", "prop"))
			var cell_arr: Array = b.get("cell", [0, 0]) as Array
			var cell: Vector2i = Vector2i(int(cell_arr[0]), int(cell_arr[1]))
			if b_type == "machine":
				var m_id: String = String(b.get("machine_id", "bakery"))
				farm._spawn_production_machine(m_id, cell)
			else:
				var sp_id: String = String(b.get("sprite_id", "farmhouse"))
				var t_arr: Array = b.get("tile_size", [3, 3]) as Array
				var t_size: Vector2i = Vector2i(int(t_arr[0]), int(t_arr[1]))
				var sz_arr: Array = b.get("max_size", [90, 90]) as Array
				var m_size: Vector2 = Vector2(float(sz_arr[0]), float(sz_arr[1]))
				farm._spawn_building_prop(sp_id, cell, t_size, m_size)

	# 2. Phân vùng 2: Khu Ruộng Tập Trung
	var plots: Array = data.get("field_plots", []) as Array
	for p_val: Variant in plots:
		if p_val is Dictionary:
			var p: Dictionary = p_val as Dictionary
			var cell_arr: Array = p.get("cell", [0, 0]) as Array
			var coord: Vector2i = Vector2i(int(cell_arr[0]), int(cell_arr[1]))
			if not GridManager.is_cell_occupied(coord):
				var inst_id: int = GridManager.place_building("field_plot", coord)
				var plot: FieldPlot = farm._spawn_field_plot(coord, inst_id)
				var crop: String = String(p.get("crop", "empty"))
				if crop != "empty":
					plot.plant(crop)
					if bool(p.get("ready", false)):
						plot.state = FieldPlot.PlotState.READY
						plot._show_ready_crop()

	# 3. Phân vùng 3: Khu Chuồng Trại
	var pens: Array = data.get("animal_pens", []) as Array
	for a_val: Variant in pens:
		if a_val is Dictionary:
			var a: Dictionary = a_val as Dictionary
			var a_id: String = String(a.get("animal_id", "cow"))
			var cell_arr: Array = a.get("cell", [0, 0]) as Array
			var cell: Vector2i = Vector2i(int(cell_arr[0]), int(cell_arr[1]))
			var count: int = int(a.get("count", 2))
			farm._spawn_animal_pen(a_id, cell, count)

	# 4. Nhà Câu Cá & Bến Nước Sông
	var f_dict: Dictionary = data.get("fishing_spot", {}) as Dictionary
	var f_cell_arr: Array = f_dict.get("cell", [23, 22]) as Array
	var f_cell: Vector2i = Vector2i(int(f_cell_arr[0]), int(f_cell_arr[1]))
	farm._spawn_fishing_spot(f_cell)

	print("[MapBuilder] Grid 32px layout successfully generated for 5 farm zones!")
