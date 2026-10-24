extends RefCounted
class_name MapBuilder

const TILE_SIZE: int = 32
const LAYOUT_PATH: String = "res://data/map_layout.json"

## Bảng kiểm tra ô bị chặn và ô bị chiếm dụng
static var _blocked: Dictionary = {} # Vector2i -> String ("hud", "river", "path", "plot")
static var _occupied: Dictionary = {} # Vector2i -> String ("building", "pen", "prop")

static func get_blocked_cells() -> Dictionary:
	_init_blocked_and_occupied()
	return _blocked

static func get_occupied_cells() -> Dictionary:
	return _occupied

static func is_cell_blocked(cell: Vector2i, blocked_dict: Dictionary = _blocked) -> bool:
	return blocked_dict.has(cell)

static func is_cell_occupied(cell: Vector2i, occupied_dict: Dictionary = _occupied) -> bool:
	return occupied_dict.has(cell)

## Khởi tạo danh sách các ô bị cấm (_blocked) bao gồm Sông, Đường gạch, Ruộng và HUD
static func _init_blocked_and_occupied() -> void:
	_blocked.clear()
	_occupied.clear()

	# 1. Khu vực HUD góc trên bên trái (X < 280, Y < 220)
	var max_hud_col: int = int(ceil(280.0 / float(TILE_SIZE)))
	var max_hud_row: int = int(ceil(220.0 / float(TILE_SIZE)))
	for x: int in range(max_hud_col):
		for y: int in range(max_hud_row):
			_blocked[Vector2i(x, y)] = "hud"

	# 2. Toàn bộ các ô thuộc Dòng sông + Bờ cát (trừ khu vực Cầu gỗ ở Row 20)
	for y_idx: int in range(GridManager.GRID_HEIGHT):
		if y_idx == 20: # Row 20 là cầu gỗ chính bắc qua sông
			continue
		var world_y: float = float(y_idx * TILE_SIZE) + float(TILE_SIZE) * 0.5
		var cx: float = FishingSpot.get_river_center_x(world_y)
		var sand_half: float = 108.0
		var col_start: int = int(floor((cx - sand_half) / float(TILE_SIZE)))
		var col_end: int = int(ceil((cx + sand_half) / float(TILE_SIZE)))
		for x_idx: int in range(col_start, col_end + 1):
			if x_idx >= 0 and x_idx < GridManager.GRID_WIDTH:
				_blocked[Vector2i(x_idx, y_idx)] = "river"

	# 3. Toàn bộ các ô thuộc Đường gạch (Path)
	for p_cell: Variant in GridManager.path_cells:
		_blocked[p_cell as Vector2i] = "path"

	# 4. Toàn bộ các ô thuộc Ruộng (FieldPlot)
	for p_coord: Variant in GridManager.occupied_cells:
		var c: Vector2i = p_coord as Vector2i
		_occupied[c] = "occupied"

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

	# Khởi tạo bảng kiểm tra vùng cấm
	_init_blocked_and_occupied()

	# 1. Phân vùng 1: Khu Nhà & Xưởng Chế Biến (Footprint 3x3 ô = 96x96px)
	var buildings: Array = data.get("buildings", []) as Array
	for b_val: Variant in buildings:
		if b_val is Dictionary:
			var b: Dictionary = b_val as Dictionary
			var b_type: String = String(b.get("type", "prop"))
			var cell_arr: Array = b.get("cell", [0, 0]) as Array
			var cell: Vector2i = Vector2i(int(cell_arr[0]), int(cell_arr[1]))
			var t_arr: Array = b.get("tile_size", [3, 3]) as Array
			var t_size: Vector2i = Vector2i(int(t_arr[0]), int(t_arr[1]))

			# Đánh dấu các ô công trình chiếm dụng vào _occupied
			for ox: int in range(t_size.x):
				for oy: int in range(t_size.y):
					_occupied[cell + Vector2i(ox, oy)] = String(b.get("id", "building"))

			if b_type == "machine":
				var m_id: String = String(b.get("machine_id", "bakery"))
				farm._spawn_production_machine(m_id, cell)
			else:
				var sp_id: String = String(b.get("sprite_id", "farmhouse"))
				var sz_arr: Array = b.get("max_size", [90, 90]) as Array
				var m_size: Vector2 = Vector2(float(sz_arr[0]), float(sz_arr[1]))
				farm._spawn_building_prop(sp_id, cell, t_size, m_size)

	# 2. Phân vùng 2: Khu Ruộng Tập Trung (Nhóm khối 4x2 ô với Sprite2D nền plot_block_empty trên PlotLayer)
	var plot_layer: Node2D = farm.find_child("PlotLayer", true, false) as Node2D
	if plot_layer == null:
		plot_layer = farm
	
	var blocks: Array = data.get("field_blocks", []) as Array
	if blocks.is_empty():
		# Fallback cho dữ liệu cũ nếu chưa có field_blocks
		var legacy_plots: Array = data.get("field_plots", []) as Array
		if not legacy_plots.is_empty():
			blocks.append({
				"cell": [12, 17],
				"size": [4, 2],
				"plots": legacy_plots
			})
	
	for b_val: Variant in blocks:
		if b_val is Dictionary:
			var b: Dictionary = b_val as Dictionary
			var cell_arr: Array = b.get("cell", [12, 17]) as Array
			var top_left: Vector2i = Vector2i(int(cell_arr[0]), int(cell_arr[1]))
			var size_arr: Array = b.get("size", [4, 2]) as Array
			var b_size: Vector2i = Vector2i(int(size_arr[0]), int(size_arr[1]))
			
			# Tạo từng ô FieldPlot con trong khối (mỗi ô là một FieldPlot độc lập để trồng/thu hoạch)
			var sub_plots: Array = b.get("plots", []) as Array
			var plot_idx: int = 0
			for oy: int in range(b_size.y):
				for ox: int in range(b_size.x):
					var coord: Vector2i = top_left + Vector2i(ox, oy)
					_blocked[coord] = "plot"
					_occupied[coord] = "plot"
					if not GridManager.is_cell_occupied(coord):
						var inst_id: int = GridManager.place_building("field_plot", coord)
						var plot: FieldPlot = farm._spawn_field_plot(coord, inst_id)
						var crop_info: Dictionary = {}
						if plot_idx < sub_plots.size() and sub_plots[plot_idx] is Dictionary:
							crop_info = sub_plots[plot_idx] as Dictionary
						var crop: String = String(crop_info.get("crop", "empty"))
						if crop != "empty":
							plot.plant(crop)
							if bool(crop_info.get("ready", false)):
								plot.state = FieldPlot.PlotState.READY
								plot._show_ready_crop()
					plot_idx += 1

	# 3. Phân vùng 3: Khu Chuồng Trại (Chuồng Bò, Gà, Heo thẳng hàng tại Row 22)
	var pens: Array = data.get("animal_pens", []) as Array
	for a_val: Variant in pens:
		if a_val is Dictionary:
			var a: Dictionary = a_val as Dictionary
			var a_id: String = String(a.get("animal_id", "cow"))
			var cell_arr: Array = a.get("cell", [0, 0]) as Array
			var cell: Vector2i = Vector2i(int(cell_arr[0]), int(cell_arr[1]))
			var t_arr: Array = a.get("tile_size", [4, 3]) as Array
			var t_size: Vector2i = Vector2i(int(t_arr[0]), int(t_arr[1]))
			for ox: int in range(t_size.x):
				for oy: int in range(t_size.y):
					_occupied[cell + Vector2i(ox, oy)] = a_id
			var count: int = int(a.get("count", 2))
			farm._spawn_animal_pen(a_id, cell, count)

	# 4. Nhà Câu Cá & Bến Nước Bờ Tây Cạnh Cầu Gỗ
	var f_dict: Dictionary = data.get("fishing_spot", {}) as Dictionary
	var f_cell_arr: Array = f_dict.get("cell", [23, 22]) as Array
	var f_cell: Vector2i = Vector2i(int(f_cell_arr[0]), int(f_cell_arr[1]))
	_occupied[f_cell] = "fishing_spot"
	_occupied[f_cell + Vector2i(1, 0)] = "fishing_spot"
	_occupied[f_cell + Vector2i(0, 1)] = "fishing_spot"
	_occupied[f_cell + Vector2i(1, 1)] = "fishing_spot"
	farm._spawn_fishing_spot(f_cell)

	print("[MapBuilder] Grid 32px layout successfully generated for 5 farm zones! (Blocked cells: ", _blocked.size(), ", Occupied cells: ", _occupied.size(), ")")
