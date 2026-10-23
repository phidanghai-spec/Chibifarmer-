extends Node2D
class_name VisitorNPC

enum VisitorState {
	INACTIVE,
	WALKING_IN,
	BROWSING_SHOP,
	SIGHTSEEING,
	WALKING_OUT
}

var npc_type: String = "visitor_tourist"
var state: VisitorState = VisitorState.INACTIVE
var move_speed: float = 40.0
var queue_destination: String = "none" # "shop", "farmhouse", "sightseeing"
var queue_slot_index: int = -1

var _path: PackedVector2Array = PackedVector2Array()
var _path_index: int = 0
var _wait_timer: float = 0.0
var _walk_phase: float = 0.0
var _base_sprite_scale: Vector2 = Vector2.ONE

var _body_sprite: Sprite2D
var _emote_sprite: Sprite2D
var _tip_sprite: Sprite2D
var _label_name: Label
var _label_demand: Label
var _chat_label: Label
var _dialogue_timer: Timer

# Tourism Demand Mechanics
var requested_item: String = "apple"
var requested_name: String = "🍎"
var reward_gold: int = 35
var reward_xp: int = 5
var _is_demand_satisfied: bool = false
var _demand_timer: float = 0.0

var manager: VisitorManager

func _ready() -> void:
	# 1. Main NPC Body Sprite
	_body_sprite = Sprite2D.new()
	_body_sprite.scale = Vector2(0.24, 0.24)
	_base_sprite_scale = _body_sprite.scale
	add_child(_body_sprite)

	# 2. Emote Sprite (heart icon)
	_emote_sprite = Sprite2D.new()
	if SpriteAtlasManager.has_texture("icon_heart"):
		_emote_sprite.texture = SpriteAtlasManager.get_texture("icon_heart")
		SpriteAtlasManager.set_sprite_pixel_size(_emote_sprite, Vector2(18, 18))
	_emote_sprite.position = Vector2(0, -42)
	_emote_sprite.visible = false
	add_child(_emote_sprite)

	# 3. Tip Coin / XP Sprite
	_tip_sprite = Sprite2D.new()
	if SpriteAtlasManager.has_texture("icon_gold"):
		_tip_sprite.texture = SpriteAtlasManager.get_texture("icon_gold")
		SpriteAtlasManager.set_sprite_pixel_size(_tip_sprite, Vector2(18, 18))
	_tip_sprite.position = Vector2(16, -28)
	_tip_sprite.visible = false
	add_child(_tip_sprite)

	# 4. Name Tag
	_label_name = Label.new()
	_label_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_name.position = Vector2(-36, -56)
	_label_name.size = Vector2(72, 16)
	_label_name.add_theme_font_size_override("font_size", 10)
	_label_name.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	_label_name.add_theme_color_override("font_outline_color", Color.BLACK)
	_label_name.add_theme_constant_override("outline_size", 2)
	add_child(_label_name)

	# 5. Overhead Tourism Demand Bubble
	_label_demand = Label.new()
	_label_demand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_demand.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label_demand.position = Vector2(-65, -78)
	_label_demand.size = Vector2(130, 20)
	_label_demand.z_index = 25
	_label_demand.add_theme_font_size_override("font_size", 11)
	_label_demand.add_theme_color_override("font_color", Color(1.0, 0.95, 0.25))
	_label_demand.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.02, 1.0))
	_label_demand.add_theme_constant_override("outline_size", 4)
	add_child(_label_demand)

	# 6. Overhead Emotion & Short Dialogue Bubble
	_chat_label = Label.new()
	_chat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chat_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_chat_label.position = Vector2(-95, -104)
	_chat_label.size = Vector2(190, 22)
	_chat_label.z_index = 30
	_chat_label.add_theme_font_size_override("font_size", 10)
	_chat_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	_chat_label.add_theme_color_override("font_outline_color", Color(0.2, 0.12, 0.05, 1.0))
	_chat_label.add_theme_constant_override("outline_size", 3)
	_chat_label.visible = false
	_chat_label.modulate.a = 0.0
	add_child(_chat_label)

	_dialogue_timer = Timer.new()
	_dialogue_timer.one_shot = false
	_dialogue_timer.wait_time = randf_range(12.0, 18.0)
	_dialogue_timer.autostart = true
	_dialogue_timer.timeout.connect(_on_dialogue_timeout)
	add_child(_dialogue_timer)

func activate(type_id: String, start_pos: Vector2, target_pos: Vector2, dest_type: String = "sightseeing", slot_idx: int = -1) -> void:
	var valid_types: Array[String] = [
		"visitor_farmer", "visitor_shopper", "visitor_tourist", "visitor_chef",
		"visitor_fisherman", "visitor_florist", "visitor_postman", "visitor_miner",
		"visitor_ranger", "visitor_gardener"
	]
	if type_id in valid_types:
		npc_type = type_id
	else:
		npc_type = "visitor_farmer"
	
	queue_destination = dest_type
	queue_slot_index = slot_idx
	position = start_pos
	visible = true
	state = VisitorState.WALKING_IN
	_wait_timer = 0.0
	_walk_phase = randf_range(0.0, 10.0)
	_emote_sprite.visible = false
	_tip_sprite.visible = false
	
	if SpriteAtlasManager.has_texture(npc_type):
		_body_sprite.texture = SpriteAtlasManager.get_texture(npc_type)
		SpriteAtlasManager.set_sprite_pixel_size(_body_sprite, Vector2(44, 44))
	_base_sprite_scale = _body_sprite.scale
	self.scale = Vector2.ONE
	
	match npc_type:
		"visitor_farmer":
			_label_name.text = "Nông Dân"
			move_speed = 42.0
		"visitor_shopper":
			_label_name.text = "Khách Mua"
			move_speed = 50.0
		"visitor_tourist":
			_label_name.text = "Du Khách"
			move_speed = 38.0
		"visitor_chef":
			_label_name.text = "Đầu Bếp"
			move_speed = 46.0
		"visitor_fisherman":
			_label_name.text = "Cậu Bé Câu Cá"
			move_speed = 40.0
		"visitor_florist":
			_label_name.text = "Bé Gái Hoa"
			move_speed = 44.0
		"visitor_postman":
			_label_name.text = "Chú Bưu Tá"
			move_speed = 52.0
		"visitor_miner":
			_label_name.text = "Chú Thợ Mỏ"
			move_speed = 42.0
		"visitor_ranger":
			_label_name.text = "Bác Kiểm Lâm"
			move_speed = 45.0
		"visitor_gardener":
			_label_name.text = "Bé Làm Vườn"
			move_speed = 43.0
	
	_assign_new_demand()
	_path = GridManager.get_tourist_path(start_pos, target_pos)
	_path_index = 0

func _assign_new_demand() -> void:
	_is_demand_satisfied = false
	var demand_pool: Array[Dictionary] = [
		{"id": "apple", "icon": "🍎", "gold": 35, "xp": 5},
		{"id": "mango", "icon": "🥭", "gold": 45, "xp": 6},
		{"id": "fish_carp", "icon": "🐟", "gold": 50, "xp": 8},
		{"id": "milk", "icon": "🥛", "gold": 40, "xp": 6},
		{"id": "bread", "icon": "🍞", "gold": 55, "xp": 8}
	]
	var choice: Dictionary = demand_pool[randi() % demand_pool.size()]
	requested_item = String(choice["id"])
	requested_name = String(choice["icon"])
	reward_gold = int(choice["gold"])
	reward_xp = int(choice["xp"])
	
	if _label_demand != null:
		_label_demand.text = "🛒 Cần: 1 %s (+%d Vàng)" % [requested_name, reward_gold]
		_label_demand.add_theme_color_override("font_color", Color(1.0, 0.95, 0.25))
		_label_demand.visible = true

func handle_visitor_click() -> bool:
	if state == VisitorState.INACTIVE:
		return false
	
	if _is_demand_satisfied:
		# Already thanked player, give friendly greeting
		_show_emote()
		return true
	
	# Check if player has the requested item in Silo or Barn
	if StorageManager.has_item(requested_item, 1):
		StorageManager.remove_item(requested_item, 1)
		StorageManager.add_gold(reward_gold)
		StorageManager.add_xp(reward_xp)
		GridManager.add_attraction_score(5)
		
		EventBus.loot_collected.emit("gold", reward_gold, global_position)
		EventBus.loot_collected.emit("xp", reward_xp, global_position)
		
		_is_demand_satisfied = true
		_demand_timer = 20.0
		
		_label_demand.text = "😍 Cảm ơn! +5✨"
		_label_demand.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		_show_emote()
		AudioManager.play_sfx("coin")
		
		var tw: Tween = create_tween()
		self.scale = Vector2(1.08, 0.92)
		tw.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_body_sprite.scale = _base_sprite_scale
		return true
	else:
		# Player doesn't have requested item yet -> Friendly tip +10 gold for visiting
		StorageManager.add_gold(10)
		AudioManager.play_sfx("coin")
		EventBus.loot_collected.emit("gold", 10, global_position)
		
		_label_demand.text = "Chưa có %s! Tặng 10 Vàng" % requested_name
		_label_demand.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
		
		var tw: Tween = create_tween()
		tw.tween_interval(2.5)
		tw.tween_callback(func() -> void:
			if not _is_demand_satisfied and is_instance_valid(_label_demand):
				_label_demand.text = "🛒 Cần: 1 %s (+%d Vàng)" % [requested_name, reward_gold]
				_label_demand.add_theme_color_override("font_color", Color(1.0, 0.95, 0.25))
		)
		return true

func _unhandled_input(event: InputEvent) -> void:
	if state == VisitorState.INACTIVE:
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.is_pressed():
			var mpos: Vector2 = get_global_mouse_position()
			if mpos.distance_to(global_position) <= 55.0:
				if handle_visitor_click():
					get_viewport().set_input_as_handled()

func deactivate() -> void:
	if manager != null and queue_slot_index >= 0:
		if queue_destination == "shop":
			manager.release_shop_slot(queue_slot_index)
		elif queue_destination == "farmhouse":
			manager.release_farmhouse_slot(queue_slot_index)
		queue_slot_index = -1
		queue_destination = "none"

	state = VisitorState.INACTIVE
	visible = false
	_path = PackedVector2Array()
	self.scale = Vector2.ONE
	if _body_sprite != null:
		_body_sprite.scale = _base_sprite_scale
	if _chat_label != null:
		_chat_label.visible = false
		_chat_label.modulate.a = 0.0

func _process(delta: float) -> void:
	if state == VisitorState.INACTIVE:
		return
	
	if _is_demand_satisfied:
		_demand_timer -= delta
		if _demand_timer <= 0.0:
			_assign_new_demand()
	
	_apply_separation_steering(delta)
	
	if state == VisitorState.WALKING_IN or state == VisitorState.WALKING_OUT:
		_walk_phase += delta * 11.0
		_body_sprite.position.y = -absf(sin(_walk_phase)) * 2.8
		_body_sprite.rotation = sin(_walk_phase * 0.5) * 0.06
		var step_squash: float = 1.0 + sin(_walk_phase) * 0.04
		var step_stretch: float = 1.0 - sin(_walk_phase) * 0.03
		_body_sprite.scale = Vector2(_base_sprite_scale.x * step_squash, _base_sprite_scale.y * step_stretch)
		_follow_path(delta)
	elif state == VisitorState.BROWSING_SHOP or state == VisitorState.SIGHTSEEING:
		var wave_time: float = Time.get_ticks_msec() * 0.007
		_body_sprite.rotation = sin(wave_time) * 0.09
		_body_sprite.position.y = 0.0
		var breath_x: float = 1.0 + sin(wave_time * 0.7) * 0.035
		var breath_y: float = 1.0 - sin(wave_time * 0.7) * 0.025
		_body_sprite.scale = Vector2(_base_sprite_scale.x * breath_x, _base_sprite_scale.y * breath_y)
		
		_wait_timer -= delta
		if _wait_timer <= 0.0:
			_start_walking_to_exit()

func _apply_separation_steering(delta: float) -> void:
	if manager == null:
		return
	var active_npcs: Array[VisitorNPC] = manager.get_active_visitors()
	var sep_force: Vector2 = Vector2.ZERO
	const MIN_SEP_DIST: float = 45.0
	
	for other: VisitorNPC in active_npcs:
		if other == self:
			continue
		var to_self: Vector2 = position - other.position
		var d: float = to_self.length()
		if d < MIN_SEP_DIST and d > 0.01:
			var push_strength: float = (MIN_SEP_DIST - d) / MIN_SEP_DIST
			sep_force += (to_self / d) * push_strength * 30.0
	
	if sep_force != Vector2.ZERO:
		position += sep_force * delta

func _follow_path(delta: float) -> void:
	if _path.is_empty() or _path_index >= _path.size():
		_on_reached_destination()
		return
	
	var target_pt: Vector2 = _path[_path_index]
	var dist: float = position.distance_to(target_pt)
	var step: float = move_speed * delta
	
	if dist <= step:
		position = target_pt
		_path_index += 1
		if _path_index >= _path.size():
			_on_reached_destination()
	else:
		var prev_x: float = position.x
		position = position.move_toward(target_pt, step)
		if target_pt.x < prev_x - 0.2:
			_body_sprite.flip_h = true
		elif target_pt.x > prev_x + 0.2:
			_body_sprite.flip_h = false

func _on_reached_destination() -> void:
	if state == VisitorState.WALKING_IN:
		if queue_destination == "shop":
			state = VisitorState.BROWSING_SHOP
			_wait_timer = randf_range(3.0, 5.0)
			_show_emote()
			if RoadsideShop != null:
				RoadsideShop.buy_random_available_slot()
		elif queue_destination == "farmhouse":
			state = VisitorState.SIGHTSEEING
			_wait_timer = randf_range(4.0, 6.0)
			_show_emote()
			_drop_tip()
		else:
			state = VisitorState.SIGHTSEEING
			_wait_timer = randf_range(3.5, 5.5)
			_show_emote()
			_drop_tip()
	elif state == VisitorState.WALKING_OUT:
		deactivate()

func _show_emote() -> void:
	_emote_sprite.visible = true
	var tween: Tween = create_tween()
	tween.tween_property(_emote_sprite, "position:y", -50.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.8)
	tween.tween_property(_emote_sprite, "visible", false, 0.1)

func _drop_tip() -> void:
	_tip_sprite.visible = true
	var reward_coins: int = 15 + int(GridManager.total_attraction_score * 0.5)
	StorageManager.add_gold(reward_coins)
	StorageManager.add_xp(5)
	AudioManager.play_sfx("coin")
	EventBus.tourist_tipped.emit(0, reward_coins, 5, position)
	
	var tween: Tween = create_tween()
	tween.tween_property(_tip_sprite, "position:y", -42.0, 0.5)
	tween.tween_interval(1.4)
	tween.tween_property(_tip_sprite, "visible", false, 0.1)

func _on_dialogue_timeout() -> void:
	if state == VisitorState.INACTIVE or not visible:
		return
	
	const PRAISE_QUOTES: Array[String] = [
		"🌸 Hoa anh đào bên sông đẹp quá!",
		"🍞 Bánh mì mới ra lò thơm phức!",
		"🌉 Đi dạo qua cầu gỗ mát thật!",
		"🍎 Vườn cây trái nhìn mê quá!",
		"✨ Nông trại yên bình tuyệt vời!"
	]
	
	var quote: String = PRAISE_QUOTES[randi() % PRAISE_QUOTES.size()]
	_show_chat_dialogue(quote)
	if _dialogue_timer != null:
		_dialogue_timer.wait_time = randf_range(12.0, 18.0)

func _show_chat_dialogue(text: String) -> void:
	if _chat_label == null:
		return
	_chat_label.text = text
	_chat_label.visible = true
	_chat_label.modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.tween_property(_chat_label, "modulate:a", 1.0, 0.35)
	tw.tween_interval(2.65)
	tw.tween_property(_chat_label, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func() -> void:
		if is_instance_valid(_chat_label):
			_chat_label.visible = false
	)

func _start_walking_to_exit() -> void:
	if manager != null and queue_slot_index >= 0:
		if queue_destination == "shop":
			manager.release_shop_slot(queue_slot_index)
		elif queue_destination == "farmhouse":
			manager.release_farmhouse_slot(queue_slot_index)
		queue_slot_index = -1
		queue_destination = "none"

	state = VisitorState.WALKING_OUT
	var exit_pos: Vector2 = GridManager.grid_to_world(GridManager.ENTRANCE_CELL)
	_path = GridManager.get_tourist_path(position, exit_pos)
	_path_index = 0

func _draw() -> void:
	if state != VisitorState.INACTIVE:
		var shadow_col: Color = Color(0.0, 0.0, 0.0, 0.22)
		draw_set_transform(Vector2(0, 16), 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, 13.0, shadow_col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)