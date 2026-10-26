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

var _soil_sprite: Sprite2D
var _label_timer: Label
var _collision_shape: CollisionShape2D
var _crop_sprite: Sprite2D

func _ready() -> void:
	y_sort_enabled = true
	add_to_group("interactable")
	
	# 0. Soil Background Sprite (scaled 1.45x to seamlessly tile rich soil patches)
	_soil_sprite = Sprite2D.new()
	_soil_sprite.name = "SoilSprite"
	if SpriteAtlasManager.has_texture("plot_soil_empty"):
		_soil_sprite.texture = SpriteAtlasManager.get_texture("plot_soil_empty")
	elif SpriteAtlasManager.has_texture("plot_block_empty"):
		_soil_sprite.texture = SpriteAtlasManager.get_texture("plot_block_empty")
	SpriteAtlasManager.set_sprite_pixel_size(_soil_sprite, plot_size * 1.45)
	_soil_sprite.position = Vector2.ZERO
	_soil_sprite.z_index = 0
	add_child(_soil_sprite)
	
	# 1. Collision shape (Area2D covers 32x32 px)
	_collision_shape = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = plot_size
	_collision_shape.shape = shape
	add_child(_collision_shape)
	
	input_pickable = true
	input_event.connect(_on_input_event)
	
	# 2. Main Crop Sprite (layered above soil, shifted up -6px to reveal soil base)
	_crop_sprite = Sprite2D.new()
	_crop_sprite.visible = false
	_crop_sprite.position = Vector2(0.0, -6.0)
	_crop_sprite.z_index = 2
	add_child(_crop_sprite)
	
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
			
			if not SaveManager.instant_interact:
				var p_input: Node = get_tree().current_scene.find_child("PlayerInput", true, false)
				if p_input != null and p_input.has_method("interact_with"):
					p_input.call("interact_with", self)
					return
			
			handle_direct_click()

func on_player_interact(_avatar: Node2D) -> void:
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
	pass

func _on_second_ticked(_current_unix: int) -> void:
	if state == PlotState.GROWING:
		if TickManager.is_finished(finish_timestamp):
			state = PlotState.READY
			_label_timer.text = ""
			_label_timer.visible = false
			is_selected = false
			_update_crop_visual()
		else:
			if is_selected:
				var remaining: int = TickManager.get_time_remaining(finish_timestamp)
				_label_timer.text = TickManager.format_duration(remaining)
			_update_crop_visual()

func plant(new_crop_id: String) -> bool:
	if state != PlotState.EMPTY:
		return false
	
	var crop_data: Dictionary = DataManager.get_crop(new_crop_id)
	if crop_data.is_empty():
		return false
	
	if StorageManager.has_item(new_crop_id, 1):
		StorageManager.remove_item(new_crop_id, 1)
	elif new_crop_id in ["wheat", "corn"] or (StorageManager.get_item_count("wheat") == 0 and StorageManager.gold < 10):
		# Anti-Softlock: basic crops can always be planted when empty to prevent player being stuck
		print("[FieldPlot] Anti-Softlock: Cấp hạt giống khẩn cấp cho ", new_crop_id)
	else:
		print("[FieldPlot] Thiếu hạt giống ", new_crop_id, " trong kho Silo!")
		return false
	
	crop_id = new_crop_id
	plant_timestamp = TickManager.now()
	var growth_seconds: int = int(crop_data.get("growth_time_seconds", 10))
	finish_timestamp = TickManager.calculate_finish_timestamp(growth_seconds)
	state = PlotState.GROWING
	is_selected = false
	
	_label_timer.visible = false
	_update_crop_visual()
	
	EventBus.field_planted.emit(instance_id, crop_id, finish_timestamp)
	AudioManager.play_sfx("plant")
	return true

func _show_ready_crop() -> void:
	_label_timer.visible = false
	_update_crop_visual()

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
	_update_crop_visual()
	return true

func _update_crop_visual() -> void:
	if _soil_sprite != null:
		var soil_key: String = "plot_soil_empty"
		if state == PlotState.GROWING or state == PlotState.READY:
			if SpriteAtlasManager.has_texture("plot_soil"):
				soil_key = "plot_soil"
		if SpriteAtlasManager.has_texture(soil_key):
			_soil_sprite.texture = SpriteAtlasManager.get_texture(soil_key)
			SpriteAtlasManager.set_sprite_pixel_size(_soil_sprite, plot_size * 1.45)
	
	if state == PlotState.EMPTY:
		_crop_sprite.visible = false
		return
	
	_crop_sprite.visible = true
	var tex_key: String = ""
	
	if state == PlotState.GROWING:
		var sprout_key: String = "crop_%s_sprout" % crop_id
		if SpriteAtlasManager.has_texture(sprout_key):
			tex_key = sprout_key
		else:
			var ratio: float = TickManager.get_progress_ratio(plant_timestamp, finish_timestamp)
			var stage_idx: int = 0 if ratio < 0.5 else 1
			tex_key = "crop_%s_%d" % [crop_id, stage_idx]
	elif state == PlotState.READY:
		var ripe_key: String = "crop_%s_ripe" % crop_id
		if SpriteAtlasManager.has_texture(ripe_key):
			tex_key = ripe_key
		else:
			tex_key = "crop_%s" % crop_id
	
	if not SpriteAtlasManager.has_texture(tex_key):
		tex_key = "crop_%s" % crop_id
	if not SpriteAtlasManager.has_texture(tex_key):
		tex_key = "item_%s" % crop_id
	
	if SpriteAtlasManager.has_texture(tex_key):
		_crop_sprite.texture = SpriteAtlasManager.get_texture(tex_key)
		SpriteAtlasManager.set_sprite_pixel_size(_crop_sprite, Vector2(26.0, 26.0))
		_crop_sprite.position = Vector2(0.0, -6.0)

