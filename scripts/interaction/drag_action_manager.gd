extends Node2D
class_name DragActionManager

enum ToolType {
	NONE,
	PLANT_WHEAT,
	PLANT_CORN,
	SICKLE,
	BUILD_FIELD,
	BUILD_PATH,
	PLANT_APPLE_TREE,
	PLANT_MANGO_TREE,
	PLANT_CROP
}

signal tool_changed(new_tool: ToolType)

@export var camera_controller: CameraController

var current_tool: ToolType = ToolType.NONE
var selected_crop_id: String = ""
var _is_dragging: bool = false
var _touched_plots: Dictionary = {} # FieldPlot -> bool
var _last_drag_cell: Vector2i = Vector2i(-999, -999)

# Hovering tool icon cursor
var _cursor_sprite: Sprite2D

# Reference to MainFarm to lookup field plot instances
var main_farm: Node2D

func _ready() -> void:
	if main_farm == null:
		main_farm = get_parent() as Node2D
		
	_cursor_sprite = Sprite2D.new()
	_cursor_sprite.visible = false
	_cursor_sprite.z_index = 100
	add_child(_cursor_sprite)
	
	set_tool(ToolType.NONE)

func _process(_delta: float) -> void:
	if _cursor_sprite != null and _cursor_sprite.visible:
		_cursor_sprite.global_position = get_global_mouse_position() + Vector2(16, -16)

func set_tool(new_tool: ToolType) -> void:
	current_tool = new_tool
	_is_dragging = false
	_touched_plots.clear()
	_last_drag_cell = Vector2i(-999, -999)
	
	if camera_controller != null:
		camera_controller.is_pan_locked = (current_tool != ToolType.NONE)
	
	_update_cursor_sprite()
	tool_changed.emit(current_tool)
	print("[DragActionManager] Tool selected: ", ToolType.keys()[current_tool])

func set_plant_tool(crop_id: String) -> void:
	selected_crop_id = crop_id
	if crop_id == "wheat":
		set_tool(ToolType.PLANT_WHEAT)
	elif crop_id == "corn":
		set_tool(ToolType.PLANT_CORN)
	elif crop_id == "apple" or crop_id == "apple_tree":
		set_tool(ToolType.PLANT_APPLE_TREE)
	elif crop_id == "mango" or crop_id == "mango_tree":
		set_tool(ToolType.PLANT_MANGO_TREE)
	else:
		set_tool(ToolType.PLANT_CROP)

func _update_cursor_sprite() -> void:
	if _cursor_sprite == null or SpriteAtlasManager == null:
		return
	
	match current_tool:
		ToolType.SICKLE:
			_cursor_sprite.texture = SpriteAtlasManager.get_texture("sickle")
			_cursor_sprite.visible = (_cursor_sprite.texture != null)
			SpriteAtlasManager.set_sprite_pixel_size(_cursor_sprite, Vector2(38, 38))
		ToolType.PLANT_WHEAT:
			_cursor_sprite.texture = SpriteAtlasManager.get_texture("wheat")
			_cursor_sprite.visible = (_cursor_sprite.texture != null)
			SpriteAtlasManager.set_sprite_pixel_size(_cursor_sprite, Vector2(30, 30))
		ToolType.PLANT_CORN:
			_cursor_sprite.texture = SpriteAtlasManager.get_texture("corn")
			_cursor_sprite.visible = (_cursor_sprite.texture != null)
			SpriteAtlasManager.set_sprite_pixel_size(_cursor_sprite, Vector2(30, 30))
		ToolType.PLANT_CROP:
			_cursor_sprite.texture = SpriteAtlasManager.get_texture(selected_crop_id)
			_cursor_sprite.visible = (_cursor_sprite.texture != null)
			SpriteAtlasManager.set_sprite_pixel_size(_cursor_sprite, Vector2(30, 30))
		ToolType.PLANT_APPLE_TREE:
			_cursor_sprite.texture = SpriteAtlasManager.get_texture("apple_seed")
			_cursor_sprite.visible = (_cursor_sprite.texture != null)
			SpriteAtlasManager.set_sprite_pixel_size(_cursor_sprite, Vector2(32, 32))
		ToolType.PLANT_MANGO_TREE:
			_cursor_sprite.texture = SpriteAtlasManager.get_texture("mango_seed")
			_cursor_sprite.visible = (_cursor_sprite.texture != null)
			SpriteAtlasManager.set_sprite_pixel_size(_cursor_sprite, Vector2(32, 32))
		_:
			_cursor_sprite.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if current_tool == ToolType.NONE:
		return
	
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			var mpos: Vector2 = get_global_mouse_position()
			var fishing_rect: Rect2 = Rect2(Vector2(560.0, 560.0), Vector2(540.0, 300.0))
			if fishing_rect.has_point(mpos) and current_tool != ToolType.BUILD_FIELD and current_tool != ToolType.BUILD_PATH:
				# Allow clicking the wooden pier / lake to fish even when holding sickle/seeds
				return
			
			if mb.is_pressed():
				_is_dragging = true
				_touched_plots.clear()
				_apply_action_at_world_pos(mpos)
				get_viewport().set_input_as_handled()
			else:
				_is_dragging = false
				_touched_plots.clear()
				_last_drag_cell = Vector2i(-999, -999)
	
	elif event is InputEventMouseMotion and _is_dragging:
		var mpos: Vector2 = get_global_mouse_position()
		_apply_action_at_world_pos(mpos)
		get_viewport().set_input_as_handled()

func _apply_action_at_world_pos(world_pos: Vector2) -> void:
	if current_tool == ToolType.PLANT_APPLE_TREE:
		if main_farm != null and main_farm.has_method("try_plant_tree"):
			if main_farm.call("try_plant_tree", world_pos, "apple"):
				set_tool(ToolType.NONE)
		return
	elif current_tool == ToolType.PLANT_MANGO_TREE:
		if main_farm != null and main_farm.has_method("try_plant_tree"):
			if main_farm.call("try_plant_tree", world_pos, "mango"):
				set_tool(ToolType.NONE)
		return
	
	var cell: Vector2i = GridManager.world_to_grid(world_pos)
	if not GridManager.is_within_bounds(cell):
		return
	
	match current_tool:
		ToolType.SICKLE:
			_handle_sickle(cell)
		ToolType.PLANT_WHEAT:
			_handle_plant(cell, "wheat")
		ToolType.PLANT_CORN:
			_handle_plant(cell, "corn")
		ToolType.PLANT_CROP:
			_handle_plant(cell, selected_crop_id)
		ToolType.BUILD_FIELD:
			_handle_build_field(cell)
		ToolType.BUILD_PATH:
			_handle_build_path(cell)

func apply_tool_to_plot(plot: FieldPlot) -> void:
	if plot == null or _touched_plots.has(plot):
		return
	
	match current_tool:
		ToolType.SICKLE:
			if plot.state == FieldPlot.PlotState.READY:
				if plot.harvest():
					_touched_plots[plot] = true
					print("[DragActionManager] Harvested crop at cell: ", plot.grid_pos)
		ToolType.PLANT_WHEAT:
			if plot.state == FieldPlot.PlotState.EMPTY:
				if plot.plant("wheat"):
					_touched_plots[plot] = true
					print("[DragActionManager] Planted wheat at cell: ", plot.grid_pos)
		ToolType.PLANT_CORN:
			if plot.state == FieldPlot.PlotState.EMPTY:
				if plot.plant("corn"):
					_touched_plots[plot] = true
					print("[DragActionManager] Planted corn at cell: ", plot.grid_pos)
		ToolType.PLANT_CROP:
			if plot.state == FieldPlot.PlotState.EMPTY:
				if plot.plant(selected_crop_id):
					_touched_plots[plot] = true
					print("[DragActionManager] Planted ", selected_crop_id, " at cell: ", plot.grid_pos)

func _handle_sickle(cell: Vector2i) -> void:
	var plot: FieldPlot = _get_field_plot_at(cell)
	if plot != null:
		apply_tool_to_plot(plot)
	
	var cell_pos: Vector2 = GridManager.grid_to_world(cell)
	if main_farm != null:
		var decors: Array = main_farm.get("_movable_decors") as Array
		for d in decors:
			if d is MovableDecor and d.is_fruit_tree:
				if d.global_position.distance_to(cell_pos) <= 55.0:
					if d.growth_stage == MovableDecor.TreeGrowthStage.STAGE_WITHERED:
						d.try_interact_withered()
					elif d.is_ripe:
						d.try_harvest()

func _handle_plant(cell: Vector2i, _crop_id: String) -> void:
	var plot: FieldPlot = _get_field_plot_at(cell)
	if plot != null:
		apply_tool_to_plot(plot)

func _handle_build_field(cell: Vector2i) -> void:
	if cell == _last_drag_cell:
		return
	_last_drag_cell = cell
	
	var cost: int = 1
	var b_info: Dictionary = DataManager.get_building("field_plot")
	if not b_info.is_empty():
		cost = int(b_info.get("cost_gold", 1))
	
	if not StorageManager.has_gold(cost):
		return
	
	if GridManager.can_place_building("field_plot", cell):
		if StorageManager.spend_gold(cost):
			if main_farm != null and main_farm.has_method("auto_clear_decor_at_cell"):
				main_farm.call("auto_clear_decor_at_cell", cell)
			var inst_id: int = GridManager.place_building("field_plot", cell)
			print("[DragActionManager] Built new field plot at cell: ", cell, " (inst_id: ", inst_id, ")")

func _handle_build_path(cell: Vector2i) -> void:
	if cell == _last_drag_cell:
		return
	_last_drag_cell = cell
	
	var cost: int = 5
	var p_info: Dictionary = DataManager.get_building("path_tile")
	if not p_info.is_empty():
		cost = int(p_info.get("cost_gold", 5))
	
	if not StorageManager.has_gold(cost):
		return
	
	if not GridManager.is_path_tile(cell) and not GridManager.is_cell_occupied(cell):
		if StorageManager.spend_gold(cost):
			if main_farm != null and main_farm.has_method("auto_clear_decor_at_cell"):
				main_farm.call("auto_clear_decor_at_cell", cell)
			GridManager.place_path(cell)
			print("[DragActionManager] Built path tile at cell: ", cell)

func _get_field_plot_at(cell: Vector2i) -> FieldPlot:
	if main_farm == null:
		main_farm = get_parent() as Node2D
	if main_farm != null and main_farm.has_method("get_field_plot_at"):
		return main_farm.call("get_field_plot_at", cell) as FieldPlot
	return null