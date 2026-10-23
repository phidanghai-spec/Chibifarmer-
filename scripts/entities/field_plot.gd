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
var is_selected: bool = false

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
	
	input_pickable = true
	input_event.connect(_on_input_event)
	
	# 2. Main Crop Sprite (optional fallback)
	_crop_sprite = Sprite2D.new()
	_crop_sprite.visible = false
	_crop_sprite.position = Vector2(0, -2)
	_crop_sprite.z_index = 3
	add_child(_crop_sprite)
	
	# 3. Harvest Sickle Icon
	_harvest_icon = Sprite2D.new()
	_harvest_icon.visible = false
	if SpriteAtlasManager.has_texture("sickle"):
		_harvest_icon.texture = SpriteAtlasManager.get_texture("sickle")
		SpriteAtlasManager.set_sprite_pixel_size(_harvest_icon, Vector2(16, 16))
	_harvest_icon.position = Vector2(0, -18)
	_harvest_icon.z_index = 8
	add_child(_harvest_icon)
	
	# 4. Timer Label - Hidden by default, only shown when player taps on growing plot
	_label_timer = Label.new()
	_label_timer.text = ""
	_label_timer.visible = false
	_label_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_timer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label_timer.position = Vector2(-20, -18)
	_label_timer.size = Vector2(40, 14)
	_label_timer.clip_text = false
	_label_timer.z_index = 10
	_label_timer.add_theme_font_size_override("font_size", 9)
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
				return
			
			handle_direct_click()

func handle_direct_click() -> void:
	if state == PlotState.READY:
		var _res: bool = harvest()
	elif state == PlotState.EMPTY:
		var farm: Node = get_tree().current_scene
		var hud: UIHud = farm.find_child("UIHud", true, false) as UIHud if farm != null else null
		if hud != null:
			hud.open_contextual_seed_popup(self)
	elif state == PlotState.GROWING:
		is_selected = not is_selected
		_label_timer.visible = is_selected
		if is_selected:
			var remaining: int = TickManager.get_time_remaining(finish_timestamp)
			_label_timer.text = TickManager.format_duration(remaining)
		queue_redraw()

func _process(_delta: float) -> void:
	if state == PlotState.GROWING:
		queue_redraw()

func _on_second_ticked(_current_unix: int) -> void:
	if state == PlotState.GROWING:
		if TickManager.is_finished(finish_timestamp):
			state = PlotState.READY
			_label_timer.text = ""
			_label_timer.visible = false
			is_selected = false
			_show_ready_crop()
		elif is_selected:
			var remaining: int = TickManager.get_time_remaining(finish_timestamp)
			_label_timer.text = TickManager.format_duration(remaining)
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
	is_selected = false
	
	_label_timer.visible = false
	_crop_sprite.visible = false
	_harvest_icon.visible = false
	
	EventBus.field_planted.emit(instance_id, crop_id, finish_timestamp)
	AudioManager.play_sfx("plant")
	queue_redraw()
	return true

func _show_ready_crop() -> void:
	_crop_sprite.visible = false
	_harvest_icon.visible = false
	_label_timer.visible = false
	queue_redraw()

func harvest() -> bool:
	if state != PlotState.READY:
		return false
	
	var crop_data: Dictionary = DataManager.get_crop(crop_id)
	var harvest_yield: int = int(crop_data.get("harvest_yield", 2))
	var xp_reward: int = int(crop_data.get("xp_reward", 1))
	
	if not StorageManager.can_store_item(crop_id, harvest_yield):
		print("[FieldPlot] Kho Silo đã đầy!")
		AudioManager.play_sfx("error")
		return false
	
	StorageManager.add_item(crop_id, harvest_yield)
	StorageManager.add_xp(xp_reward)
	AudioManager.play_sfx("harvest")
	EventBus.field_harvested.emit(instance_id, crop_id)
	EventBus.loot_collected.emit(crop_id, harvest_yield, global_position)
	
	state = PlotState.EMPTY
	crop_id = ""
	plant_timestamp = 0
	finish_timestamp = 0
	is_selected = false
	_label_timer.visible = false
	_crop_sprite.visible = false
	_harvest_icon.visible = false
	queue_redraw()
	return true

func _draw() -> void:
	# 1. Warm pastel cream-brown soil base (#D1AE8A) with soft corners
	var soil_fill: Color = Color(0.82, 0.68, 0.54)
	var soil_border: Color = Color(0.68, 0.52, 0.38)
	var bottom_shadow: Color = Color(0.64, 0.48, 0.34, 0.65)
	
	# Rounded soil base (30x30)
	draw_rect(Rect2(-15, -15, 30, 30), soil_fill, true)
	draw_rect(Rect2(-13, 11, 26, 3), bottom_shadow, true)
	draw_rect(Rect2(-15, -15, 30, 30), soil_border, false, 1.2)
	
	# 2. 4 cute soil mounds in a 2x2 grid (Pinterest style)
	var quadrant_centers: Array[Vector2] = [
		Vector2(-7, -7), Vector2(7, -7),
		Vector2(-7, 7), Vector2(7, 7)
	]
	
	var mound_color: Color = Color(0.70, 0.54, 0.38)
	var mound_hi: Color = Color(0.88, 0.74, 0.58)
	
	for qc: Vector2 in quadrant_centers:
		draw_circle(qc, 4.2, mound_color)
		draw_circle(qc - Vector2(0, 0.8), 2.6, mound_hi)
	
	# 3. Stage Rendering
	if state == PlotState.GROWING:
		var ratio: float = TickManager.get_progress_ratio(plant_timestamp, finish_timestamp)
		if ratio < 0.25:
			# SEED STAGE: 4 tiny seed mounds with green/yellow speck
			for qc: Vector2 in quadrant_centers:
				draw_circle(qc, 1.6, Color(0.45, 0.75, 0.22))
		else:
			# SPROUT STAGE: 4 cute chibi sprouts emerging from mounds
			var sprout_size: float = lerpf(2.0, 4.5, ratio)
			var stem_h: float = lerpf(2.0, 5.5, ratio)
			var leaf_color: Color = Color(0.48, 0.82, 0.25)
			var stem_color: Color = Color(0.35, 0.62, 0.18)
			
			for qc: Vector2 in quadrant_centers:
				var base_pt: Vector2 = qc + Vector2(0, 1.5)
				draw_line(base_pt, base_pt - Vector2(0, stem_h), stem_color, 1.2)
				draw_circle(base_pt - Vector2(sprout_size * 0.7, stem_h * 0.7), sprout_size * 0.6, leaf_color)
				draw_circle(base_pt - Vector2(-sprout_size * 0.7, stem_h * 0.7), sprout_size * 0.6, leaf_color)
		
		# Show small progress bar only if selected
		if is_selected:
			draw_rect(Rect2(-12, 12, 24, 3), Color(0.2, 0.2, 0.2, 0.8), true)
			draw_rect(Rect2(-12, 12, 24 * ratio, 3), Color(0.4, 0.85, 0.3), true)
	
	elif state == PlotState.READY:
		# Golden glowing harvest border
		draw_rect(Rect2(-15, -15, 30, 30), Color(1.0, 0.88, 0.30, 0.95), false, 2.0)
		
		# Draw 4 cute ripe crops in the 4 mounds
		for qc: Vector2 in quadrant_centers:
			_draw_ripe_crop_quadrant(qc, crop_id)

func _draw_ripe_crop_quadrant(pos: Vector2, id: String) -> void:
	if id == "carrot":
		# Cute carrot shoulder peeking out of dirt
		draw_circle(pos + Vector2(0, 1), 3.2, Color(0.96, 0.48, 0.12)) # Orange carrot top
		draw_circle(pos - Vector2(1.5, 3.0), 1.6, Color(0.35, 0.75, 0.2)) # Leaf 1
		draw_circle(pos + Vector2(0.0, 4.2), 1.8, Color(0.30, 0.70, 0.18)) # Leaf 2
		draw_circle(pos + Vector2(1.5, 3.0), 1.6, Color(0.35, 0.75, 0.2)) # Leaf 3
	elif id == "corn":
		# Golden corn ear with green leaves
		draw_circle(pos - Vector2(1.5, 1.0), 2.0, Color(0.42, 0.72, 0.22)) # Leaf
		draw_circle(pos + Vector2(1.5, 1.0), 2.0, Color(0.42, 0.72, 0.22)) # Leaf
		draw_rect(Rect2(pos.x - 2.0, pos.y - 4.5, 4.0, 7.0), Color(0.98, 0.82, 0.15), true) # Yellow corn
		draw_line(pos + Vector2(0, -4.5), pos + Vector2(0, -6.0), Color(0.75, 0.55, 0.15), 1.2) # Tassel
	elif id == "sunflower":
		# Sunny yellow petals with orange/brown center
		draw_circle(pos - Vector2(0, 2), 4.2, Color(1.0, 0.82, 0.15))
		draw_circle(pos - Vector2(0, 2), 2.2, Color(0.65, 0.35, 0.12))
	elif id == "rose":
		# Crimson rose petals with green leaf
		draw_circle(pos + Vector2(2.5, 0), 1.8, Color(0.35, 0.70, 0.2))
		draw_circle(pos - Vector2(0, 1.5), 3.8, Color(0.92, 0.22, 0.25))
		draw_circle(pos - Vector2(0, 1.5), 1.8, Color(1.0, 0.45, 0.48))
	elif id == "lavender":
		# Purple lavender sprig
		draw_line(pos + Vector2(0, 2), pos - Vector2(0, 5), Color(0.35, 0.65, 0.2), 1.2)
		draw_circle(pos - Vector2(0, 2.0), 2.2, Color(0.68, 0.42, 0.88))
		draw_circle(pos - Vector2(0, 4.5), 1.8, Color(0.60, 0.35, 0.82))
	elif id == "strawberry":
		# Red strawberry with green cap
		draw_circle(pos + Vector2(0, 1), 3.5, Color(0.94, 0.22, 0.24))
		draw_circle(pos - Vector2(0, 2.5), 1.8, Color(0.35, 0.75, 0.2))
	else:
		# Wheat or default golden grains
		draw_line(pos + Vector2(0, 2), pos - Vector2(0, 5), Color(0.72, 0.55, 0.2), 1.2)
		draw_circle(pos - Vector2(1.2, 2.0), 1.8, Color(0.95, 0.82, 0.25))
		draw_circle(pos + Vector2(1.2, 3.5), 1.8, Color(0.95, 0.82, 0.25))
		draw_circle(pos - Vector2(0, 5.0), 1.6, Color(0.98, 0.88, 0.30))
