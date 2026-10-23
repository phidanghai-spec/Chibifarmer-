class_name MovableDecor
extends Node2D

enum TreeGrowthStage {
	STAGE_SAPLING,
	STAGE_GROWING,
	STAGE_RIPE,
	STAGE_WITHERED
}

var decor_id: String = ""
var decor_size: Vector2 = Vector2(32, 32)
var has_shadow: bool = true
var is_swaying: bool = false

var sprite: Sprite2D = null
var shadow_sprite: Sprite2D = null
var area: Area2D = null
var collision_shape: CollisionShape2D = null
var sway_tween: Tween = null

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var drag_start_pos: Vector2 = Vector2.ZERO

var main_farm: Node2D = null

# Fruit tree mechanics
var is_fruit_tree: bool = false
var is_apple_tree: bool = false
var is_mango_tree: bool = false
var is_ripe: bool = true
var growth_stage: TreeGrowthStage = TreeGrowthStage.STAGE_RIPE
var stage_timer: float = 0.0
var harvest_left: int = 3
var revived_once: bool = false
var timer_label: Label = null

func setup(p_id: String, p_pos: Vector2, p_size: Vector2, p_shadow: bool = true, p_sway: bool = false, p_main_farm: Node2D = null) -> void:
	decor_id = p_id
	position = p_pos
	decor_size = p_size
	has_shadow = p_shadow
	is_swaying = p_sway
	main_farm = p_main_farm
	y_sort_enabled = true
	
	if "tree" in decor_id:
		z_index = 1
	else:
		z_index = 0
	
	# 1. Shadow
	if has_shadow:
		shadow_sprite = _create_ellipse_shadow(Vector2(decor_size.x * 0.75, decor_size.y * 0.3))
		shadow_sprite.position = Vector2(0, decor_size.y * 0.35)
		shadow_sprite.z_index = -1
		add_child(shadow_sprite)
	
	# 2. Main Sprite
	sprite = Sprite2D.new()
	if SpriteAtlasManager.has_texture(decor_id):
		sprite.texture = SpriteAtlasManager.get_texture(decor_id)
		SpriteAtlasManager.set_sprite_pixel_size(sprite, decor_size)
	elif decor_id == "env_mango_tree" and SpriteAtlasManager.has_texture("env_apple_tree"):
		sprite.texture = SpriteAtlasManager.get_texture("env_apple_tree")
		SpriteAtlasManager.set_sprite_pixel_size(sprite, decor_size)
		sprite.modulate = Color(0.85, 1.15, 0.85) # Lush tropical green tint
	add_child(sprite)
	
	# 3. Soft wind sway for trees
	if is_swaying and sprite != null:
		_start_sway()
	
	# 4. Fruit Tree Initialization
	if decor_id == "env_apple_tree" or decor_id == "env_mango_tree":
		is_fruit_tree = true
		is_apple_tree = (decor_id == "env_apple_tree")
		is_mango_tree = (decor_id == "env_mango_tree")
		harvest_left = 3
		revived_once = false
		is_ripe = true
		growth_stage = TreeGrowthStage.STAGE_RIPE
		
		timer_label = Label.new()
		timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		timer_label.position = Vector2(-55, -decor_size.y * 0.52)
		timer_label.size = Vector2(110, 20)
		timer_label.add_theme_font_size_override("font_size", 11)
		timer_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.2))
		timer_label.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.02, 1.0))
		timer_label.add_theme_constant_override("outline_size", 4)
		timer_label.visible = false
		timer_label.z_index = 25
		add_child(timer_label)
		
		_update_tree_visuals()
	
	# 5. Interactive Area2D for Drag & Drop / Right-click removal
	area = Area2D.new()
	collision_shape = CollisionShape2D.new()
	var rect_shape: RectangleShape2D = RectangleShape2D.new()
	rect_shape.size = Vector2(maxf(decor_size.x * 0.9, 28.0), maxf(decor_size.y * 0.9, 28.0))
	collision_shape.shape = rect_shape
	area.add_child(collision_shape)
	
	area.input_event.connect(_on_area_input_event)
	area.mouse_entered.connect(_on_mouse_entered)
	area.mouse_exited.connect(_on_mouse_exited)
	add_child(area)

func set_growth_stage(stage: TreeGrowthStage) -> void:
	growth_stage = stage
	match stage:
		TreeGrowthStage.STAGE_SAPLING:
			stage_timer = 15.0
		TreeGrowthStage.STAGE_GROWING:
			stage_timer = 20.0
		TreeGrowthStage.STAGE_RIPE:
			stage_timer = 0.0
		TreeGrowthStage.STAGE_WITHERED:
			stage_timer = 0.0
	_update_tree_visuals()

func _update_tree_visuals() -> void:
	if not is_fruit_tree or sprite == null:
		return
	
	var size_boost: float = 1.0 + float(3 - harvest_left) * 0.08
	match growth_stage:
		TreeGrowthStage.STAGE_SAPLING:
			is_ripe = false
			scale = Vector2(0.55, 0.55)
			modulate = Color.WHITE
			if SpriteAtlasManager.has_texture("tree_fruitless"):
				sprite.texture = SpriteAtlasManager.get_texture("tree_fruitless")
				SpriteAtlasManager.set_sprite_pixel_size(sprite, decor_size)
			if timer_label != null:
				timer_label.text = "🌱 Cây Non: %ds" % maxi(1, int(stage_timer))
				timer_label.visible = true
				timer_label.add_theme_color_override("font_color", Color(0.7, 1.0, 0.6))
		
		TreeGrowthStage.STAGE_GROWING:
			is_ripe = false
			scale = Vector2(0.8, 0.8) * size_boost
			modulate = Color.WHITE
			if SpriteAtlasManager.has_texture("tree_fruitless"):
				sprite.texture = SpriteAtlasManager.get_texture("tree_fruitless")
				SpriteAtlasManager.set_sprite_pixel_size(sprite, decor_size)
			if timer_label != null:
				timer_label.text = "🌼 Kết Trái: %ds" % maxi(1, int(stage_timer))
				timer_label.visible = true
				timer_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
		
		TreeGrowthStage.STAGE_RIPE:
			is_ripe = true
			scale = Vector2.ONE * size_boost
			modulate = Color.WHITE
			var ripe_key: String = "tree_apple_ripe" if is_apple_tree else "tree_mango_ripe"
			if SpriteAtlasManager.has_texture(ripe_key):
				sprite.texture = SpriteAtlasManager.get_texture(ripe_key)
			elif SpriteAtlasManager.has_texture(decor_id):
				sprite.texture = SpriteAtlasManager.get_texture(decor_id)
			SpriteAtlasManager.set_sprite_pixel_size(sprite, decor_size)
			if timer_label != null:
				timer_label.visible = false
		
		TreeGrowthStage.STAGE_WITHERED:
			is_ripe = false
			scale = Vector2.ONE * size_boost
			modulate = Color(0.85, 0.72, 0.45, 1.0)
			if SpriteAtlasManager.has_texture("tree_fruitless"):
				sprite.texture = SpriteAtlasManager.get_texture("tree_fruitless")
				SpriteAtlasManager.set_sprite_pixel_size(sprite, decor_size)
			if timer_label != null:
				timer_label.visible = true
				if not revived_once:
					timer_label.text = "💧 Hồi Sinh Cây"
					timer_label.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
				else:
					timer_label.text = "🪚 Đốn Cây Khô"
					timer_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
	queue_redraw()

func _create_ellipse_shadow(size: Vector2) -> Sprite2D:
	var img: Image = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	var center: Vector2 = size * 0.5
	var rx: float = size.x * 0.5
	var ry: float = size.y * 0.5
	for y: int in range(int(size.y)):
		for x: int in range(int(size.x)):
			var dx: float = (float(x) - center.x) / rx
			var dy: float = (float(y) - center.y) / ry
			var dist_sq: float = dx * dx + dy * dy
			if dist_sq <= 1.0:
				var alpha: float = (1.0 - sqrt(dist_sq)) * 0.38
				img.set_pixel(x, y, Color(0.12, 0.22, 0.12, alpha))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	var sp: Sprite2D = Sprite2D.new()
	sp.texture = tex
	return sp

func _start_sway() -> void:
	if sway_tween != null and sway_tween.is_valid():
		sway_tween.kill()
	var sway_angle: float = deg_to_rad(randf_range(1.8, 2.5))
	var duration: float = randf_range(2.8, 3.8)
	sway_tween = create_tween().set_loops()
	sway_tween.tween_property(sprite, "rotation", sway_angle, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sway_tween.tween_property(sprite, "rotation", -sway_angle, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _can_interact() -> bool:
	if main_farm != null:
		var d_mgr: Object = main_farm.get("drag_action_manager")
		if d_mgr != null:
			var current_tool: int = int(d_mgr.get("current_tool"))
			return current_tool == DragActionManager.ToolType.NONE
	return true

func _can_harvest() -> bool:
	if main_farm != null:
		var d_mgr: Object = main_farm.get("drag_action_manager")
		if d_mgr != null:
			var current_tool: int = int(d_mgr.get("current_tool"))
			return current_tool == DragActionManager.ToolType.NONE or current_tool == DragActionManager.ToolType.SICKLE
	return true

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.is_pressed() and _can_interact():
				_start_drag(mb.global_position)
				get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.is_pressed():
			if _can_interact():
				_delete_decor()
				get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if not is_dragging:
		return
	
	if event is InputEventMouseMotion:
		global_position = get_global_mouse_position() + drag_offset
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.is_pressed():
			_finish_drag()
			get_viewport().set_input_as_handled()

func _start_drag(mouse_global_pos: Vector2) -> void:
	is_dragging = true
	drag_start_pos = position
	drag_offset = global_position - mouse_global_pos
	z_index = 35
	scale = Vector2(1.15, 1.15)
	modulate = Color(1.2, 1.2, 1.2, 0.95)
	
	if main_farm != null:
		var cam: Object = main_farm.get("camera_2d")
		if cam != null:
			cam.set("is_pan_locked", true)

func _finish_drag() -> void:
	is_dragging = false
	var target_base_sc: Vector2 = Vector2.ONE
	if is_fruit_tree:
		var size_boost: float = 1.0 + float(3 - harvest_left) * 0.08
		if growth_stage == TreeGrowthStage.STAGE_SAPLING:
			target_base_sc = Vector2(0.55, 0.55)
		elif growth_stage == TreeGrowthStage.STAGE_GROWING:
			target_base_sc = Vector2(0.8, 0.8) * size_boost
		else:
			target_base_sc = Vector2.ONE * size_boost
	scale = target_base_sc
	modulate = Color(0.85, 0.72, 0.45, 1.0) if (is_fruit_tree and growth_stage == TreeGrowthStage.STAGE_WITHERED) else Color.WHITE
	z_index = 1 if "tree" in decor_id else 0
	
	if main_farm != null:
		var cam: Object = main_farm.get("camera_2d")
		if cam != null:
			cam.set("is_pan_locked", false)
	
	# Validate position: cannot place in deep water pond
	if main_farm != null and main_farm.has_method("_is_in_water_pond"):
		if main_farm.call("_is_in_water_pond", position):
			var tw_revert: Tween = create_tween()
			tw_revert.tween_property(self, "position", drag_start_pos, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			return
	
	var dist: float = position.distance_to(drag_start_pos)
	if dist < 6.0 and is_fruit_tree:
		if growth_stage == TreeGrowthStage.STAGE_WITHERED:
			try_interact_withered()
		elif is_ripe:
			try_harvest()
	
	var pop_tw: Tween = create_tween()
	var base_sc: Vector2 = scale
	pop_tw.tween_property(self, "scale", base_sc * 1.1, 0.08)
	pop_tw.tween_property(self, "scale", base_sc, 0.08)
	
	if main_farm != null and main_farm.has_method("on_decor_moved"):
		main_farm.call("on_decor_moved", self)

func _delete_decor() -> void:
	if main_farm != null and main_farm.has_method("remove_movable_decor"):
		var tw: Tween = create_tween()
		tw.tween_property(self, "scale", Vector2(0.1, 0.1), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_callback(func() -> void:
			if is_instance_valid(self):
				main_farm.call("remove_movable_decor", self)
		)

func _on_mouse_entered() -> void:
	if not is_dragging and _can_interact():
		modulate = Color(1.18, 1.18, 1.18, 1.0)

func _on_mouse_exited() -> void:
	if not is_dragging:
		modulate = Color.WHITE

func _process(delta: float) -> void:
	if not is_fruit_tree or is_ripe or growth_stage == TreeGrowthStage.STAGE_WITHERED:
		return
	
	stage_timer -= delta
	var size_boost: float = 1.0 + float(3 - harvest_left) * 0.08
	if growth_stage == TreeGrowthStage.STAGE_SAPLING:
		if timer_label != null:
			timer_label.text = "🌱 Cây Non: %ds" % maxi(1, int(stage_timer))
		if stage_timer <= 0.0:
			set_growth_stage(TreeGrowthStage.STAGE_GROWING)
			var pop: Tween = create_tween()
			pop.tween_property(self, "scale", Vector2(0.9, 0.9), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			pop.tween_property(self, "scale", Vector2(0.8, 0.8) * size_boost, 0.12)
	elif growth_stage == TreeGrowthStage.STAGE_GROWING:
		if timer_label != null:
			timer_label.text = "🌼 Kết Trái: %ds" % maxi(1, int(stage_timer))
		if stage_timer <= 0.0:
			set_growth_stage(TreeGrowthStage.STAGE_RIPE)
			var pop: Tween = create_tween()
			var target_sc: Vector2 = Vector2.ONE * size_boost
			pop.tween_property(self, "scale", target_sc * 1.15, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			pop.tween_property(self, "scale", target_sc, 0.12)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.is_pressed():
			if is_fruit_tree:
				var mpos: Vector2 = get_global_mouse_position()
				if mpos.distance_to(global_position) <= 60.0:
					if growth_stage == TreeGrowthStage.STAGE_WITHERED:
						if try_interact_withered():
							get_viewport().set_input_as_handled()
					elif is_ripe and _can_harvest():
						if try_harvest():
							get_viewport().set_input_as_handled()

func try_harvest() -> bool:
	if not is_fruit_tree or not is_ripe or growth_stage != TreeGrowthStage.STAGE_RIPE:
		return false
	
	var fruit_id: String = "apple" if is_apple_tree else "mango"
	if not StorageManager.can_store_item(fruit_id, 2):
		print("[MovableDecor] Kho Silo đã đầy, không thể chứa thêm quả!")
		return false
	
	# Add fruit: +2 quả vào Silo
	StorageManager.add_item(fruit_id, 2)
	AudioManager.play_sfx("harvest")
	EventBus.loot_collected.emit(fruit_id, 2, global_position)
	
	# Drop seed: rớt ngẫu nhiên +1 hạt giống (apple_seed hoặc mango_seed)
	var seed_drop: String = "apple_seed" if is_apple_tree else "mango_seed"
	if StorageManager.can_store_item(seed_drop, 1):
		StorageManager.add_item(seed_drop, 1)
		EventBus.loot_collected.emit(seed_drop, 1, global_position)
	
	if is_apple_tree:
		GridManager.add_attraction_score(3)
		StorageManager.add_xp(2)
	else:
		GridManager.add_attraction_score(4)
		StorageManager.add_xp(5)
	
	harvest_left -= 1
	if harvest_left > 0:
		set_growth_stage(TreeGrowthStage.STAGE_GROWING)
		var bounce: Tween = create_tween()
		var grow_sc: Vector2 = Vector2(0.8, 0.8) * (1.0 + float(3 - harvest_left) * 0.08)
		bounce.tween_property(self, "scale", grow_sc * 0.9, 0.08)
		bounce.tween_property(self, "scale", grow_sc, 0.1)
	else:
		set_growth_stage(TreeGrowthStage.STAGE_WITHERED)
		var bounce: Tween = create_tween()
		bounce.tween_property(self, "scale", Vector2(1.05, 0.92), 0.1)
		bounce.tween_property(self, "scale", Vector2.ONE, 0.1)
	
	return true

func try_interact_withered() -> bool:
	if not is_fruit_tree or growth_stage != TreeGrowthStage.STAGE_WITHERED:
		return false
	
	if not revived_once:
		revived_once = true
		harvest_left = 1
		set_growth_stage(TreeGrowthStage.STAGE_GROWING)
		stage_timer = 20.0
		
		StorageManager.add_xp(3)
		EventBus.loot_collected.emit("xp", 3, global_position)
		
		var pop: Tween = create_tween()
		pop.tween_property(self, "scale", Vector2(1.15, 1.15), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		var grow_sc: Vector2 = Vector2(0.8, 0.8) * (1.0 + float(3 - harvest_left) * 0.08)
		pop.tween_property(self, "scale", grow_sc, 0.12)
		print("[MovableDecor] Cây đã được tưới nước hồi sinh (💧 Hồi sinh cây!), thêm 1 vụ quả bonus!")
		return true
	else:
		var seed_reward: String = "apple_seed" if is_apple_tree else "mango_seed"
		if StorageManager.can_store_item(seed_reward, 1):
			StorageManager.add_item(seed_reward, 1)
			EventBus.loot_collected.emit(seed_reward, 1, global_position)
		StorageManager.add_xp(5)
		EventBus.loot_collected.emit("xp", 5, global_position)
		
		print("[MovableDecor] Đã đốn cây khô (🪚), thưởng +1 ", seed_reward, " và +5 XP!")
		if main_farm != null and main_farm.has_method("remove_movable_decor"):
			main_farm.call("remove_movable_decor", self)
		else:
			queue_free()
		return true

func _harvest_apple() -> void:
	try_harvest()

func _draw() -> void:
	pass