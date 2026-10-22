extends Area2D
class_name FieldPlot

enum PlotState {
	EMPTY,
	GROWING,
	READY
}

@export var plot_size: Vector2 = Vector2(32.0, 32.0)

var state: PlotState = PlotState.EMPTY
var crop_id: String = ""
var plant_timestamp: int = 0
var finish_timestamp: int = 0
var grid_pos: Vector2i = Vector2i.ZERO
var instance_id: int = 0

var _label_timer: Label
var _collision_shape: CollisionShape2D
var _crop_sprite: Sprite2D
var _harvest_icon: Sprite2D

func _ready() -> void:
	y_sort_enabled = true
	
	# 1. Collision shape (Area2D covers 32x32 px)
	_collision_shape = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = plot_size
	_collision_shape.shape = shape
	add_child(_collision_shape)
	
	# Direct click / tap handling on Area2D
	input_pickable = true
	input_event.connect(_on_input_event)
	
	# 2. Main Crop Sprite (wheat, corn, carrot) sized strictly within 30x30 px
	_crop_sprite = Sprite2D.new()
	_crop_sprite.visible = false
	_crop_sprite.position = Vector2(0, -2)
	_crop_sprite.z_index = 3
	add_child(_crop_sprite)
	
	# 3. Small Harvest Ready Indicator Icon (16x16 px)
	_harvest_icon = Sprite2D.new()
	_harvest_icon.visible = false
	if SpriteAtlasManager.has_texture("sickle"):
		_harvest_icon.texture = SpriteAtlasManager.get_texture("sickle")
		SpriteAtlasManager.set_sprite_pixel_size(_harvest_icon, Vector2(16, 16))
	_harvest_icon.position = Vector2(0, -18)
	_harvest_icon.z_index = 8
	add_child(_harvest_icon)
	
	# 4. Timer Label - Crisp, perfectly centered in plot (32x14 px), never clipped
	_label_timer = Label.new()
	_label_timer.text = ""
	_label_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_timer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label_timer.position = Vector2(-16, -15)
	_label_timer.size = Vector2(32, 14)
	_label_timer.clip_text = false
	_label_timer.z_index = 10
	_label_timer.add_theme_font_size_override("font_size", 8)
	_label_timer.add_theme_color_override("font_color", Color(0.24, 0.15, 0.10))
	_label_timer.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 1.0))
	_label_timer.add_theme_constant_override("outline_size", 2)
	add_child(_label_timer)
	
	EventBus.second_ticked.connect(_on_second_ticked)
	queue_redraw()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.is_pressed():
			var dam: DragActionManager = get_tree().root.find_child("DragActionManager", true, false) as DragActionManager
			if dam != null and dam.current_tool != DragActionManager.ToolType.NONE:
				dam.apply_tool_to_plot(self)

func _process(_delta: float) -> void:
	var time: float = Time.get_ticks_msec() * 0.005
	if state == PlotState.READY and _harvest_icon.visible:
		_harvest_icon.position.y = -18.0 + sin(time * 2.0) * 2.0
	elif state == PlotState.GROWING:
		queue_redraw()

func _on_second_ticked(_current_unix: int) -> void:
	if state == PlotState.GROWING:
		if TickManager.is_finished(finish_timestamp):
			state = PlotState.READY
			_label_timer.text = "GẶT"
			_label_timer.add_theme_color_override("font_color", Color(0.92, 0.35, 0.08))
			_show_ready_crop()
		else:
			var remaining: int = TickManager.get_time_remaining(finish_timestamp)
			_label_timer.text = TickManager.format_duration(remaining)
			_label_timer.add_theme_color_override("font_color", Color(0.24, 0.15, 0.10))
		queue_redraw()

func plant(new_crop_id: String) -> bool:
	if state != PlotState.EMPTY:
		return false
	
	if not StorageManager.has_item(new_crop_id, 1):
		print("[FieldPlot] Thiếu hạt giống ", new_crop_id, " trong kho Silo!")
		return false
	
	var crop_data: Dictionary = DataManager.get_crop(new_crop_id)
	if crop_data.is_empty():
		return false
	
	var success: bool = StorageManager.remove_item(new_crop_id, 1)
	if not success:
		return false
	
	crop_id = new_crop_id
	plant_timestamp = TickManager.now()
	var growth_seconds: int = int(crop_data.get("growth_time_seconds", 10))
	finish_timestamp = TickManager.calculate_finish_timestamp(growth_seconds)
	state = PlotState.GROWING
	
	_label_timer.text = TickManager.format_duration(growth_seconds)
	_label_timer.add_theme_color_override("font_color", Color(0.24, 0.15, 0.10))
	_crop_sprite.visible = false
	_harvest_icon.visible = false
	
	EventBus.field_planted.emit(instance_id, crop_id, finish_timestamp)
	queue_redraw()
	return true

func _show_ready_crop() -> void:
	var tex_id: String = crop_id
	if not SpriteAtlasManager.has_texture(tex_id):
		tex_id = "wheat"
	
	if SpriteAtlasManager.has_texture(tex_id):
		_crop_sprite.texture = SpriteAtlasManager.get_texture(tex_id)
		var display_size: Vector2 = Vector2(20, 20) if tex_id == "corn" else Vector2(22, 22)
		SpriteAtlasManager.set_sprite_pixel_size(_crop_sprite, display_size)
		_crop_sprite.z_index = 3
		_crop_sprite.visible = true
	
	# Sickle icon disabled per design: ripe crop is clearly shown without flashing sickle
	_harvest_icon.visible = false
	_label_timer.text = "" # Hide GẶT text because bouncing Sickle icon is clear
	_label_timer.position = Vector2(-16, 5)
	queue_redraw()

func harvest() -> bool:
	if state != PlotState.READY:
		return false
	
	var crop_data: Dictionary = DataManager.get_crop(crop_id)
	var harvest_yield: int = int(crop_data.get("harvest_yield", 2))
	var xp_reward: int = int(crop_data.get("xp_reward", 1))
	
	if not StorageManager.can_store_item(crop_id, harvest_yield):
		print("[FieldPlot] Kho Silo đã đầy!")
		return false
	
	StorageManager.add_item(crop_id, harvest_yield)
	StorageManager.add_xp(xp_reward)
	EventBus.field_harvested.emit(instance_id, crop_id)
	EventBus.loot_collected.emit(crop_id, harvest_yield, global_position)
	
	state = PlotState.EMPTY
	crop_id = ""
	plant_timestamp = 0
	finish_timestamp = 0
	_label_timer.text = ""
	_label_timer.position = Vector2(-16, -15)
	_crop_sprite.visible = false
	_harvest_icon.visible = false
	queue_redraw()
	return true

func _draw() -> void:
	# 1. Authentic Warm Pastel Brown Soil Base (#C9A66B and #8D6E63 - Sample 3 Style)
	var soil_fill: Color = Color(0.79, 0.65, 0.42) # Warm pastel brown #C9A66B
	var soil_border: Color = Color(0.55, 0.43, 0.39) # Soft dark border #8D6E63
	var furrow_dark: Color = Color(0.55, 0.43, 0.39)
	var furrow_light: Color = Color(0.88, 0.76, 0.56, 0.7)
	var bottom_shadow: Color = Color(0.70, 0.52, 0.32, 0.75)
	
	# Rounded soil base (30x30 with 4px corner bevels)
	draw_rect(Rect2(-15, -15, 30, 30), soil_fill, true)
	# Soft 2.5D elevation shadow at bottom edge
	draw_rect(Rect2(-13, 11, 26, 3), bottom_shadow, true)
	# Soft cozy outer border
	draw_rect(Rect2(-15, -15, 30, 30), soil_border, false, 1.5)
	
	# 2. 4 Sub-Quadrants (2x2 furrows - cross groove like in script đất trồng.jpg)
	# Vertical groove
	draw_line(Vector2(0, -13), Vector2(0, 13), furrow_dark, 1.5)
	draw_line(Vector2(1, -12), Vector2(1, 12), furrow_light, 1.0)
	# Horizontal groove
	draw_line(Vector2(-13, 0), Vector2(13, 0), furrow_dark, 1.5)
	draw_line(Vector2(-12, 1), Vector2(12, 1), furrow_light, 1.0)
	
	# Subtle furrow curved depression in each quadrant
	var quadrant_centers: Array[Vector2] = [
		Vector2(-7, -7), Vector2(7, -7),
		Vector2(-7, 7), Vector2(7, 7)
	]
	
	# 3. When GROWING: Draw 4 pairs of cute chibi sprouts (1 in each sub-quadrant)
	if state == PlotState.GROWING:
		var ratio: float = TickManager.get_progress_ratio(plant_timestamp, finish_timestamp)
		var sprout_size: float = lerpf(2.0, 5.0, ratio)
		var stem_h: float = lerpf(2.0, 6.0, ratio)
		var leaf_color: Color = Color(0.48, 0.78, 0.22) # Fresh sprout green
		var leaf_outline: Color = Color(0.33, 0.55, 0.18)
		
		for qc: Vector2 in quadrant_centers:
			var base_pt: Vector2 = qc + Vector2(0, 2)
			# Small stem
			draw_line(base_pt, base_pt - Vector2(0, stem_h), leaf_outline, 1.2)
			# Left leaf
			draw_circle(base_pt - Vector2(sprout_size * 0.7, stem_h * 0.7), sprout_size * 0.6, leaf_color)
			# Right leaf
			draw_circle(base_pt - Vector2(-sprout_size * 0.7, stem_h * 0.7), sprout_size * 0.6, leaf_color)
	elif state == PlotState.READY:
		# Golden glowing harvest border
		draw_rect(Rect2(-15, -15, 30, 30), Color(1.0, 0.88, 0.30, 0.9), false, 2.0)
