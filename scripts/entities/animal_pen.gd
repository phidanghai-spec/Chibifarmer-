extends Node2D
class_name AnimalPen

enum PenState {
	HUNGRY,
	PRODUCING,
	READY_TO_COLLECT
}

@export var animal_id: String = "chicken" # "cow", "chicken", "pig"
@export var pen_size: Vector2 = Vector2(120.0, 86.0) # Clean 4x3 tiles (128x96 px)
@export var animal_count: int = 3

var state: PenState = PenState.HUNGRY
var finish_timestamp: int = 0
var instance_id: int = 0
var grid_pos: Vector2i = Vector2i.ZERO

class AnimalAgent:
	var root: Node2D
	var sprite: Sprite2D
	var shadow: Sprite2D
	var current_pos: Vector2 = Vector2.ZERO
	var target_pos: Vector2 = Vector2.ZERO
	var is_walking: bool = false
	var speed: float = 30.0
	var wait_time: float = 2.0
	var walk_phase: float = 0.0
	var phase_offset: float = 0.0
	var target_size: Vector2 = Vector2(32, 32)

var _agents: Array[AnimalAgent] = []
var _timer_label: Label
var _coop_sprite: Sprite2D
var _eggs_sprite: Sprite2D

func _ready() -> void:
	y_sort_enabled = true
	add_to_group("interactable")

	# 1. Pen Barn / Coop Structure in top-left
	if animal_id == "chicken" and SpriteAtlasManager.has_texture("chicken_coop"):
		_coop_sprite = Sprite2D.new()
		_coop_sprite.texture = SpriteAtlasManager.get_texture("chicken_coop")
		SpriteAtlasManager.set_sprite_pixel_size(_coop_sprite, Vector2(44, 44))
		_coop_sprite.position = Vector2(-34, -14)
		_coop_sprite.z_index = 1
		add_child(_coop_sprite)
	elif animal_id == "cow" and SpriteAtlasManager.has_texture("cow_pasture"):
		_coop_sprite = Sprite2D.new()
		_coop_sprite.texture = SpriteAtlasManager.get_texture("cow_pasture")
		SpriteAtlasManager.set_sprite_pixel_size(_coop_sprite, Vector2(50, 50))
		_coop_sprite.position = Vector2(-28, -10)
		_coop_sprite.z_index = 1
		add_child(_coop_sprite)
	elif animal_id == "sheep" and SpriteAtlasManager.has_texture("sheep_pasture"):
		_coop_sprite = Sprite2D.new()
		_coop_sprite.texture = SpriteAtlasManager.get_texture("sheep_pasture")
		SpriteAtlasManager.set_sprite_pixel_size(_coop_sprite, Vector2(50, 50))
		_coop_sprite.position = Vector2(-28, -10)
		_coop_sprite.z_index = 1
		add_child(_coop_sprite)
		
		# Egg Basket (visible when eggs are ready to collect)
		if SpriteAtlasManager.has_texture("chibi_eggs"):
			_eggs_sprite = Sprite2D.new()
			_eggs_sprite.texture = SpriteAtlasManager.get_texture("chibi_eggs")
			SpriteAtlasManager.set_sprite_pixel_size(_eggs_sprite, Vector2(24, 24))
			_eggs_sprite.position = Vector2(-22, -14)
			_eggs_sprite.visible = false
			add_child(_eggs_sprite)
		elif SpriteAtlasManager.has_texture("egg_milk"):
			_eggs_sprite = Sprite2D.new()
			_eggs_sprite.texture = SpriteAtlasManager.get_texture("egg_milk")
			SpriteAtlasManager.set_sprite_pixel_size(_eggs_sprite, Vector2(24, 24))
			_eggs_sprite.position = Vector2(-22, -14)
			_eggs_sprite.visible = false
			add_child(_eggs_sprite)

	# 2. Standardized Animal Pixel Sizes: Chicken (32x32), Pig (42x42), Cow (48x48)
	var max_anim_size: Vector2 = Vector2(32, 32)
	var shadow_size: Vector2 = Vector2(22, 10)
	
	if animal_id == "cow":
		max_anim_size = Vector2(48, 48)
		shadow_size = Vector2(34, 14)
	elif animal_id == "pig":
		max_anim_size = Vector2(42, 42)
		shadow_size = Vector2(28, 12)
	elif animal_id == "sheep":
		max_anim_size = Vector2(44, 44)
		shadow_size = Vector2(30, 12)

	var anim_tex: Texture2D = SpriteAtlasManager.get_texture(animal_id)

	for i: int in range(animal_count):
		var agent: AnimalAgent = AnimalAgent.new()
		agent.phase_offset = float(i) * 1.6
		agent.speed = randf_range(22.0, 32.0)
		agent.wait_time = randf_range(1.5, 3.5)
		agent.target_size = max_anim_size
		
		agent.root = Node2D.new()
		agent.root.y_sort_enabled = true
		
		# Soft shadow
		agent.shadow = _create_ellipse_shadow(shadow_size)
		agent.shadow.position = Vector2(0, 10)
		agent.shadow.z_index = -1
		agent.root.add_child(agent.shadow)
		
		# Animal Sprite with exact pixel sizing
		agent.sprite = Sprite2D.new()
		if anim_tex != null:
			agent.sprite.texture = anim_tex
			SpriteAtlasManager.set_sprite_pixel_size(agent.sprite, max_anim_size)
		agent.root.add_child(agent.sprite)
		
		# Position separated by >= 44px
		agent.current_pos = _find_valid_wander_point(_agents, 44.0)
		agent.target_pos = agent.current_pos
		agent.root.position = agent.current_pos
		
		add_child(agent.root)
		_agents.append(agent)

	# 3. Floating Status / Timer Label
	_timer_label = Label.new()
	_timer_label.text = "🥣 CHO BÒ ĂN" if animal_id == "cow" else "🥣 CHO ĂN"
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_timer_label.position = Vector2(-50, -65)
	_timer_label.size = Vector2(100, 24)
	_timer_label.z_index = 20
	_timer_label.add_theme_font_size_override("font_size", 15)
	_timer_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.25))
	_timer_label.add_theme_color_override("font_outline_color", Color(0.15, 0.1, 0.05))
	_timer_label.add_theme_constant_override("outline_size", 6)
	add_child(_timer_label)

	# Click area for feeding and harvesting
	var area: Area2D = Area2D.new()
	var col: CollisionShape2D = CollisionShape2D.new()
	var rect_shape: RectangleShape2D = RectangleShape2D.new()
	rect_shape.size = pen_size
	col.shape = rect_shape
	area.add_child(col)
	area.input_event.connect(_on_area_input_event)
	add_child(area)

	EventBus.second_ticked.connect(_on_second_ticked)
	queue_redraw()

func _create_ellipse_shadow(size: Vector2) -> Sprite2D:
	var img: Image = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	var cx: float = float(img.get_width()) * 0.5
	var cy: float = float(img.get_height()) * 0.5

	for x: int in range(img.get_width()):
		for y: int in range(img.get_height()):
			var nx: float = (float(x) - cx) / cx
			var ny: float = (float(y) - cy) / cy
			var dist_sq: float = nx * nx + ny * ny
			if dist_sq <= 1.0:
				var alpha: float = (1.0 - dist_sq) * 0.22
				img.set_pixel(x, y, Color(0.20, 0.15, 0.10, alpha))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))

	var tex: ImageTexture = ImageTexture.create_from_image(img)
	var sp: Sprite2D = Sprite2D.new()
	sp.texture = tex
	return sp

func _process(delta: float) -> void:
	for agent: AnimalAgent in _agents:
		if agent.is_walking:
			var to_target: Vector2 = agent.target_pos - agent.current_pos
			var dist: float = to_target.length()
			var step: float = agent.speed * delta
			
			if dist <= step:
				agent.current_pos = agent.target_pos
				agent.is_walking = false
				agent.wait_time = randf_range(2.0, 4.0)
				agent.sprite.rotation = 0.0
			else:
				var dir: Vector2 = to_target.normalized()
				agent.current_pos += dir * step
				
				# Flip face
				if dir.x < -0.1:
					agent.sprite.flip_h = true
				elif dir.x > 0.1:
					agent.sprite.flip_h = false
				
				# Walking footstep and bobbing animation
				agent.walk_phase += delta * 8.5
				agent.sprite.rotation = sin(agent.walk_phase + agent.phase_offset) * 0.08
				agent.sprite.position.y = -absf(sin(agent.walk_phase * 2.0)) * 2.0
			
			agent.root.position = agent.current_pos
		else:
			# Idle Grazing / Pecking
			agent.wait_time -= delta
			var breathe: float = sin(Time.get_ticks_msec() * 0.005 + agent.phase_offset) * 0.08
			agent.sprite.rotation = breathe
			agent.sprite.position.y = 0.0
			
			if agent.wait_time <= 0.0:
				agent.target_pos = _find_valid_wander_point(_agents, 44.0, agent)
				agent.is_walking = true
				agent.speed = randf_range(22.0, 32.0)

	if _eggs_sprite != null and _eggs_sprite.visible:
		_eggs_sprite.position.y = -14.0 + sin(Time.get_ticks_msec() * 0.005) * 2.0

func _find_valid_wander_point(existing_agents: Array[AnimalAgent], min_dist: float, current_agent: AnimalAgent = null) -> Vector2:
	var half: Vector2 = pen_size * 0.5
	var padding: float = 24.0
	var min_x: float = -half.x + padding
	var max_x: float = half.x - padding
	var min_y: float = -half.y + padding
	var max_y: float = half.y - padding
	
	var best_pos: Vector2 = Vector2.ZERO
	var best_score: float = -1.0
	
	for attempt: int in range(16):
		var test_pos: Vector2 = Vector2(randf_range(min_x, max_x), randf_range(min_y, max_y))
		if animal_id == "cow":
			if test_pos.x < 18.0 and test_pos.y < 22.0:
				continue
		elif (animal_id == "chicken" or animal_id == "sheep") and test_pos.x < -15.0 and test_pos.y < -5.0:
			continue
		
		var closest_dist: float = 9999.0
		for other: AnimalAgent in existing_agents:
			if other == current_agent:
				continue
			var d: float = test_pos.distance_to(other.current_pos)
			if d < closest_dist:
				closest_dist = d
		
		if closest_dist >= min_dist:
			return test_pos
		if closest_dist > best_score:
			best_score = closest_dist
			best_pos = test_pos
			
	return best_pos if best_score > 0.0 else (Vector2(randf_range(20, 50), randf_range(-10, 25)) if animal_id == "cow" else Vector2(randf_range(-25, 25), randf_range(-15, 15)))

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.is_pressed():
			if not SaveManager.instant_interact:
				var p_input: Node = get_tree().current_scene.find_child("PlayerInput", true, false)
				if p_input != null:
					p_input.call("interact_with", self)
					get_viewport().set_input_as_handled()
					return
			if state == PenState.HUNGRY:
				feed()
				get_viewport().set_input_as_handled()
			elif state == PenState.READY_TO_COLLECT:
				collect()
				get_viewport().set_input_as_handled()

func _on_second_ticked(_current_unix: int) -> void:
	if state == PenState.PRODUCING:
		if TickManager.is_finished(finish_timestamp):
			state = PenState.READY_TO_COLLECT
			if animal_id == "cow":
				_timer_label.text = "🥛 THU SỮA"
			elif animal_id == "chicken":
				_timer_label.text = "🥚 THU TRỨNG"
			else:
				_timer_label.text = "✨ THU HOẠCH"
			_timer_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.25))
			_timer_label.add_theme_color_override("font_outline_color", Color(0.15, 0.1, 0.05))
			_timer_label.add_theme_constant_override("outline_size", 6)
			if _eggs_sprite != null:
				_eggs_sprite.visible = true
		else:
			var remaining: int = TickManager.get_time_remaining(finish_timestamp)
			_timer_label.text = "⏳ " + TickManager.format_duration(remaining)
			_timer_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
			_timer_label.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.1))
			_timer_label.add_theme_constant_override("outline_size", 3)

func on_player_interact(_avatar: Node2D) -> void:
	handle_pen_click()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.is_pressed():
			var mpos: Vector2 = get_global_mouse_position()
			if mpos.distance_to(global_position) <= 95.0:
				if not SaveManager.instant_interact:
					var p_input: Node = get_tree().current_scene.find_child("PlayerInput", true, false)
					if p_input != null:
						p_input.call("interact_with", self)
						get_viewport().set_input_as_handled()
						return
				if handle_pen_click():
					get_viewport().set_input_as_handled()

func handle_pen_click() -> bool:
	if state == PenState.HUNGRY:
		return feed()
	elif state == PenState.READY_TO_COLLECT:
		return collect()
	return false

func feed() -> bool:
	if state != PenState.HUNGRY:
		return false
	
	var a_data: Dictionary = DataManager.get_animal(animal_id)
	var feed_id: String = String(a_data.get("feed_item_id", "chicken_feed"))
	
	if StorageManager.has_item(feed_id, 1):
		StorageManager.remove_item(feed_id, 1)
	elif animal_id == "cow" and StorageManager.has_item("wheat", 1):
		StorageManager.remove_item("wheat", 1)
	elif animal_id == "cow" and StorageManager.has_item("corn", 1):
		StorageManager.remove_item("corn", 1)
	elif animal_id == "chicken" and StorageManager.has_item("wheat", 1):
		StorageManager.remove_item("wheat", 1)
	elif StorageManager.gold >= 2:
		StorageManager.spend_gold(2)
		print("[AnimalPen] Đã mua thức ăn khẩn cấp (-2 Vàng)!")
	else:
		# Miễn phí khẩn cấp để không bao giờ bị kẹt vòng lặp sản xuất
		print("[AnimalPen] Cho ăn miễn phí khẩn cấp!")
	
	var duration: int = 15
	finish_timestamp = TickManager.calculate_finish_timestamp(duration)
	state = PenState.PRODUCING
	
	EventBus.animal_fed.emit(instance_id, animal_id, finish_timestamp)
	AudioManager.play_sfx("plant")
	_timer_label.text = "⏳ " + TickManager.format_duration(duration)
	_timer_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_timer_label.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.1))
	_timer_label.add_theme_constant_override("outline_size", 3)
	if _eggs_sprite != null:
		_eggs_sprite.visible = false
	return true

func collect() -> bool:
	if state != PenState.READY_TO_COLLECT:
		return false
	
	var a_data: Dictionary = DataManager.get_animal(animal_id)
	var product_id: String = String(a_data.get("produce_item_id", "egg"))
	var count: int = int(a_data.get("produce_count", 1)) * animal_count
	var xp: int = int(a_data.get("xp_reward", 2)) * animal_count
	
	if not StorageManager.can_store_item(product_id, count):
		print("[AnimalPen] Kho Barn đã đầy!")
		AudioManager.play_sfx("error")
		return false
	
	StorageManager.add_item(product_id, count)
	StorageManager.add_xp(xp)
	AudioManager.play_sfx("harvest")
	EventBus.animal_collected.emit(instance_id, product_id)
	EventBus.loot_collected.emit(product_id, count, global_position)
	
	state = PenState.HUNGRY
	finish_timestamp = 0
	_timer_label.text = "🥣 CHO BÒ ĂN" if animal_id == "cow" else "🥣 CHO ĂN"
	_timer_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.25))
	_timer_label.add_theme_color_override("font_outline_color", Color(0.15, 0.1, 0.05))
	_timer_label.add_theme_constant_override("outline_size", 6)
	if _eggs_sprite != null:
		_eggs_sprite.visible = false
	return true

func _draw() -> void:
	var half: Vector2 = pen_size * 0.5
	var r: Rect2 = Rect2(-half, pen_size)
	
	# 1. Clean natural ground - seamlessly blends with matcha lawn without rectangular background boxes

	# 2. Neat Slim Wooden Fence with posts and double horizontal rails (No overlapping clutter!)
	var fence_wood: Color = Color(0.50, 0.34, 0.18)
	var fence_rail: Color = Color(0.65, 0.45, 0.25)
	
	# Upper and lower rails
	draw_rect(r.grow(-2), fence_rail, false, 2.5)
	draw_rect(r.grow(-6), fence_rail, false, 2.0)
	
	# Posts spaced neatly around perimeter
	var posts_x: Array[float] = [-half.x, -half.x * 0.33, half.x * 0.33, half.x]
	for px: float in posts_x:
		draw_rect(Rect2(Vector2(px - 3, -half.y - 4), Vector2(6, 12)), fence_wood, true)
		draw_rect(Rect2(Vector2(px - 3, half.y - 8), Vector2(6, 12)), fence_wood, true)
	
	var posts_y: Array[float] = [-half.y * 0.33, half.y * 0.33]
	for py: float in posts_y:
		draw_rect(Rect2(Vector2(-half.x - 4, py - 3), Vector2(10, 6)), fence_wood, true)
		draw_rect(Rect2(Vector2(half.x - 6, py - 3), Vector2(10, 6)), fence_wood, true)
