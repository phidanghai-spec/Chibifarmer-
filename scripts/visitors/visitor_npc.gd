extends Node2D
class_name VisitorNPC

enum VisitorState {
	INACTIVE,
	WALKING_IN,
	BROWSING_SHOP,
	SIGHTSEEING,
	VISITING_ZOO,
	VISITING_ORCHARD,
	PICNIC_REST,
	WALKING_OUT
}

var npc_type: String = "visitor_tourist"
var state: VisitorState = VisitorState.INACTIVE
var move_speed: float = 40.0
var queue_destination: String = "none" # "shop", "farmhouse", "sightseeing", "zoo"
var queue_slot_index: int = -1
var _visited_zoo: bool = false
var _visited_orchard: bool = false
var _visited_picnic: bool = false
var _target_zoo_enclosure: Node2D = null
var _target_orchard_tree: Node2D = null
var _target_picnic_spot: Vector2 = Vector2.ZERO
var _shadow_poly: Polygon2D = null

var _path: PackedVector2Array = PackedVector2Array()
var _path_index: int = 0
var _wait_timer: float = 0.0
var _walk_phase: float = 0.0
var _base_sprite_scale: Vector2 = Vector2.ONE
var _notifier: VisibleOnScreenNotifier2D = null
var _is_on_screen: bool = true
var _weather_speed_mult: float = 1.0

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
	z_index = 10

	# 0. Warm 2-Layer Ellipse Ground Shadow
	_shadow_poly = Polygon2D.new()
	_shadow_poly.name = "GroundShadow"
	_shadow_poly.color = Color(0.12, 0.16, 0.08, 0.45)
	var s_pts: PackedVector2Array = PackedVector2Array()
	var segs: int = 16
	for i: int in range(segs):
		var a: float = (float(i) / float(segs)) * TAU
		s_pts.append(Vector2(cos(a) * 15.0, sin(a) * 6.5))
	_shadow_poly.polygon = s_pts
	_shadow_poly.position = Vector2(0.0, 18.0)
	_shadow_poly.z_index = -1
	
	var in_shadow: Polygon2D = Polygon2D.new()
	in_shadow.name = "ShadowCore"
	var in_pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(segs):
		var a: float = (float(i) / float(segs)) * TAU
		in_pts.append(Vector2(cos(a) * 9.5, sin(a) * 4.0))
	in_shadow.polygon = in_pts
	in_shadow.color = Color(0.08, 0.12, 0.05, 0.35)
	_shadow_poly.add_child(in_shadow)
	
	add_child(_shadow_poly)

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

	# 4. Name Tag (Hidden to remove text clutter)
	_label_name = Label.new()
	_label_name.visible = false
	add_child(_label_name)

	# 5. Overhead Tourism Demand Bubble (Single clean line)
	_label_demand = Label.new()
	_label_demand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_demand.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label_demand.position = Vector2(-75, -52)
	_label_demand.size = Vector2(150, 20)
	_label_demand.z_index = 25
	_label_demand.add_theme_font_size_override("font_size", 10)
	_label_demand.add_theme_color_override("font_color", Color(1.0, 0.95, 0.25))
	_label_demand.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.02, 1.0))
	_label_demand.add_theme_constant_override("outline_size", 4)
	add_child(_label_demand)

	# 6. Overhead Short Dialogue Bubble (Only for walking tourists)
	_chat_label = Label.new()
	_chat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chat_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_chat_label.position = Vector2(-95, -52)
	_chat_label.size = Vector2(190, 20)
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

	_notifier = VisibleOnScreenNotifier2D.new()
	_notifier.rect = Rect2(-30.0, -50.0, 60.0, 60.0)
	_notifier.screen_entered.connect(func() -> void: _is_on_screen = true)
	_notifier.screen_exited.connect(func() -> void: _is_on_screen = false)
	add_child(_notifier)

	EventBus.weather_state_changed.connect(_on_weather_changed)

func activate(type_id: String, start_pos: Vector2, target_pos: Vector2, dest_type: String = "sightseeing", slot_idx: int = -1) -> void:
	var valid_types: Array[String] = [
		"visitor_buyer", "visitor_shopper", "visitor_tourist",
		"visitor_farmer", "visitor_chef", "visitor_fisherman",
		"visitor_florist", "visitor_postman", "visitor_miner",
		"visitor_ranger", "visitor_gardener"
	]
	if type_id in valid_types:
		npc_type = type_id
	else:
		npc_type = "visitor_tourist"
	
	queue_destination = dest_type
	queue_slot_index = slot_idx
	position = start_pos
	visible = true
	if _shadow_poly != null:
		_shadow_poly.visible = true
	state = VisitorState.WALKING_IN
	_wait_timer = 0.0
	_walk_phase = randf_range(0.0, 10.0)
	_emote_sprite.visible = false
	_tip_sprite.visible = false
	_visited_zoo = false
	_visited_orchard = false
	_visited_picnic = false
	_target_zoo_enclosure = null
	_target_orchard_tree = null
	_target_picnic_spot = Vector2.ZERO
	
	if SpriteAtlasManager.has_texture(npc_type):
		_body_sprite.texture = SpriteAtlasManager.get_texture(npc_type)
		SpriteAtlasManager.set_sprite_pixel_size(_body_sprite, Vector2(34, 44))
	_base_sprite_scale = _body_sprite.scale
	self.scale = Vector2.ONE
	
	match npc_type:
		"visitor_tourist":
			move_speed = 38.0
		"visitor_buyer":
			move_speed = 44.0
		"visitor_shopper":
			move_speed = 48.0
		_:
			move_speed = 42.0
	
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
		_label_demand.visible = false
		_label_demand.text = "🛒 Cần: 1 %s (+%d Xu)" % [requested_name, reward_gold]
		_label_demand.add_theme_color_override("font_color", Color(1.0, 0.95, 0.25))

func handle_visitor_click() -> bool:
	if state == VisitorState.INACTIVE:
		return false
	
	if _is_demand_satisfied:
		# Already thanked player, give friendly greeting
		_show_emote()
		_show_chat_dialogue("Cảm ơn bạn nhé! Nông trại đẹp lắm! ✨")
		return true
	
	var attraction: int = GridManager.total_attraction_score
	var attraction_mult: float = 1.0 + float(attraction) * 0.008
	var final_gold: int = int(float(reward_gold) * attraction_mult)
	var tip_coins: int = maxi(2, int(float(attraction) * 0.15))
	
	# Check if player has the requested item in Silo or Barn
	if requested_item != "" and StorageManager.has_item(requested_item, 1):
		StorageManager.remove_item(requested_item, 1)
		StorageManager.add_gold(final_gold)
		StorageManager.add_coins(tip_coins)
		StorageManager.add_xp(reward_xp)
		GridManager.add_attraction_score(5)
		
		EventBus.loot_collected.emit("gold", final_gold, global_position)
		EventBus.loot_collected.emit("coins", tip_coins, global_position)
		EventBus.loot_collected.emit("xp", reward_xp, global_position)
		
		_is_demand_satisfied = true
		_demand_timer = 30.0
		
		_label_demand.text = "😍 +%dV +%dXu! ✨" % [final_gold, tip_coins]
		_label_demand.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		_show_emote()
		_show_chat_dialogue("Đã nhận %s! Cảm ơn bạn rất nhiều! ❤️" % requested_name)
		AudioManager.play_sfx("sell")
		
		var tw: Tween = create_tween()
		self.scale = Vector2(1.10, 0.92)
		tw.tween_property(self, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_body_sprite.scale = _base_sprite_scale
		
		# Direct visitor happily toward Zoo or sightseeing
		_wait_timer = 2.0
		queue_destination = "zoo"
		return true
	elif requested_item != "":
		# Player doesn't have requested item -> Clear immediate feedback notice
		var farm: Node = get_tree().current_scene
		var hud: UIHud = farm.find_child("UIHud", true, false) as UIHud if farm != null else null
		if hud != null:
			hud.show_floating_notice("⚠️ Thiếu %s trong kho để bán cho khách!" % requested_name)
		AudioManager.play_sfx("error")
		
		# Visual shake on demand label
		if _label_demand != null:
			var tw_err: Tween = create_tween()
			tw_err.tween_property(_label_demand, "position:x", -75.0 + 4.0, 0.05)
			tw_err.tween_property(_label_demand, "position:x", -75.0 - 4.0, 0.05)
			tw_err.tween_property(_label_demand, "position:x", -75.0, 0.05)
		return true
	else:
		# Pure tourist visiting farm -> Drop generous tip
		var visit_gold: int = 15 + int(float(attraction) * 0.1)
		var visit_coins: int = maxi(2, int(float(attraction) * 0.08))
		StorageManager.add_gold(visit_gold)
		StorageManager.add_coins(visit_coins)
		StorageManager.add_xp(5)
		AudioManager.play_sfx("coin")
		EventBus.loot_collected.emit("gold", visit_gold, global_position)
		EventBus.loot_collected.emit("coins", visit_coins, global_position)
		
		_show_emote()
		_show_chat_dialogue("Thăm quan vui quá! Gửi bạn ít tiền tip nhé! ✨")
		_label_demand.text = "+%dV +%dXu! ✨" % [visit_gold, visit_coins]
		_label_demand.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
		_label_demand.visible = true
		return true

func _unhandled_input(event: InputEvent) -> void:
	if state == VisitorState.INACTIVE:
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.is_pressed():
			var mpos: Vector2 = get_global_mouse_position()
			var local_pos: Vector2 = mpos - global_position
			# Wide 72x88px bounding box covering character and overhead bubble
			if Rect2(-36.0, -60.0, 72.0, 88.0).has_point(local_pos):
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
	if _shadow_poly != null:
		_shadow_poly.visible = false
	_visited_zoo = false
	_visited_orchard = false
	_visited_picnic = false
	_target_zoo_enclosure = null
	_target_orchard_tree = null
	_target_picnic_spot = Vector2.ZERO

func _process(delta: float) -> void:
	if state == VisitorState.INACTIVE:
		return
	
	if _is_demand_satisfied:
		_demand_timer -= delta
		if _demand_timer <= 0.0:
			_assign_new_demand()
	
	if _is_on_screen:
		_apply_separation_steering(delta)
	
	if state == VisitorState.WALKING_IN or state == VisitorState.WALKING_OUT:
		if _is_on_screen:
			_walk_phase += delta * 11.0
			_body_sprite.position.y = -absf(sin(_walk_phase)) * 2.8
			_body_sprite.rotation = sin(_walk_phase * 0.5) * 0.06
			var step_squash: float = 1.0 + sin(_walk_phase) * 0.04
			var step_stretch: float = 1.0 - sin(_walk_phase) * 0.03
			_body_sprite.scale = Vector2(_base_sprite_scale.x * step_squash, _base_sprite_scale.y * step_stretch)
			if _shadow_poly != null:
				var s_shrink: float = absf(sin(_walk_phase)) * 0.12
				_shadow_poly.scale = Vector2.ONE * (1.0 - s_shrink)
		_follow_path(delta)
	elif state == VisitorState.BROWSING_SHOP or state == VisitorState.SIGHTSEEING or state == VisitorState.VISITING_ZOO or state == VisitorState.VISITING_ORCHARD or state == VisitorState.PICNIC_REST:
		if _is_on_screen:
			var wave_time: float = Time.get_ticks_msec() * 0.007
			_body_sprite.rotation = sin(wave_time) * 0.09
			_body_sprite.position.y = 0.0
			var breath_x: float = 1.0 + sin(wave_time * 0.7) * 0.035
			var breath_y: float = 1.0 - sin(wave_time * 0.7) * 0.025
			_body_sprite.scale = Vector2(_base_sprite_scale.x * breath_x, _base_sprite_scale.y * breath_y)
			if _shadow_poly != null:
				_shadow_poly.scale = Vector2.ONE * (1.0 + sin(wave_time * 0.7) * 0.035)
		
		_wait_timer -= delta
		if _wait_timer <= 0.0:
			_check_next_visitor_activity()

func _check_next_visitor_activity() -> void:
	var farm: Node = get_tree().current_scene
	
	# 1. Trạm Tự Hái Quả (U-Pick Orchard): 45% cơ hội nếu có cây quả và chưa hái
	if not _visited_orchard and randf() < 0.45:
		var valid_trees: Array[Node2D] = []
		if farm != null and farm.get("_movable_decors") != null:
			for d in farm.get("_movable_decors") as Array:
				if d is Node2D and bool(d.get("is_fruit_tree")):
					valid_trees.append(d as Node2D)
		
		if not valid_trees.is_empty():
			var picked_tree: Node2D = null
			for t: Node2D in valid_trees:
				if bool(t.get("is_ripe")):
					picked_tree = t
					break
			if picked_tree == null:
				picked_tree = valid_trees.pick_random()
			
			_visited_orchard = true
			_target_orchard_tree = picked_tree
			queue_destination = "orchard"
			state = VisitorState.WALKING_IN
			var stand_pos: Vector2 = picked_tree.position + Vector2(randf_range(-20.0, 20.0), 30.0)
			_path = GridManager.get_tourist_path(position, stand_pos)
			_path_index = 0
			return

	# 2. Nghỉ Chân Uống Trà Thảo Mộc Tại Bàn Picnic / Ghế Gỗ: 45% cơ hội nếu chưa nghỉ
	if not _visited_picnic and randf() < 0.45:
		var picnic_spots: Array[Vector2] = [
			Vector2(160.0, 615.0),
			Vector2(575.0, 615.0),
			Vector2(1460.0, 84.0),
			Vector2(1310.0, 635.0),
			Vector2(1850.0, 650.0)
		]
		if farm != null and farm.get("_movable_decors") != null:
			for d in farm.get("_movable_decors") as Array:
				if d is Node2D:
					var d_id: String = String(d.get("decor_id"))
					if d_id == "wooden_bench" or d_id == "decor_wooden_bench" or d_id == "decor_picnic_table":
						picnic_spots.append((d as Node2D).position + Vector2(0.0, 16.0))
		
		_visited_picnic = true
		queue_destination = "picnic"
		state = VisitorState.WALKING_IN
		_target_picnic_spot = picnic_spots.pick_random()
		_path = GridManager.get_tourist_path(position, _target_picnic_spot)
		_path_index = 0
		return

	# 3. Thăm Chuồng Thú Sở Thú Bờ Đông (Đứng chính xác trên Đại lộ Cát y = 308.0)
	if not _visited_zoo and randf() < 0.55:
		_visited_zoo = true
		var zoo_mgr: Node = farm.find_child("ZooManager", true, false) if farm != null else null
		if zoo_mgr != null and zoo_mgr.has_method("get_random_unlocked_enclosure"):
			var enc: Node2D = zoo_mgr.call("get_random_unlocked_enclosure") as Node2D
			if enc != null:
				_target_zoo_enclosure = enc
				state = VisitorState.WALKING_IN
				queue_destination = "zoo"
				var view_pos: Vector2 = Vector2(enc.position.x + randf_range(-24.0, 24.0), 308.0)
				_path = GridManager.get_tourist_path(position, view_pos)
				_path_index = 0
				return

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
	var step: float = (move_speed * _weather_speed_mult) * delta
	
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
			if _label_demand != null and not _is_demand_satisfied and npc_type != "visitor_tourist":
				_label_demand.visible = true
				var tw_d: Tween = create_tween()
				tw_d.tween_interval(2.5)
				tw_d.tween_property(_label_demand, "visible", false, 0.2)
			if RoadsideShop != null:
				RoadsideShop.buy_random_available_slot()
		elif queue_destination == "zoo":
			state = VisitorState.VISITING_ZOO
			_wait_timer = randf_range(3.5, 5.0)
			_show_camera_emote()
			_trigger_photo_checkin()
			_drop_zoo_tip()
		elif queue_destination == "orchard":
			state = VisitorState.VISITING_ORCHARD
			_wait_timer = randf_range(3.5, 4.5)
			_show_chat_dialogue("🍎 Tự hái quả tươi! Vé x1.5! 📸")
			_show_emote()
			_trigger_photo_checkin()
			_drop_orchard_reward()
		elif queue_destination == "picnic":
			state = VisitorState.PICNIC_REST
			_wait_timer = 4.0
			_handle_picnic_tea_rest()
		elif queue_destination == "farmhouse":
			state = VisitorState.SIGHTSEEING
			_wait_timer = randf_range(4.0, 6.0)
			_show_emote()
			_drop_tip()
		else:
			state = VisitorState.SIGHTSEEING
			_wait_timer = randf_range(3.5, 5.5)
			_show_emote()
			if npc_type == "visitor_tourist" and randf() < 0.65:
				_trigger_photo_checkin()
			_drop_tip()
	elif state == VisitorState.WALKING_OUT:
		deactivate()

func _on_weather_changed(weather_id: String, _crop_mult: float, _fish_luck: float) -> void:
	if weather_id.to_lower() == "cozy_rain":
		_weather_speed_mult = 1.20
	else:
		_weather_speed_mult = 1.0

func _trigger_photo_checkin() -> void:
	var flash: Polygon2D = Polygon2D.new()
	flash.polygon = PackedVector2Array([
		Vector2(-40.0, -80.0),
		Vector2(40.0, -80.0),
		Vector2(40.0, 20.0),
		Vector2(-40.0, 20.0)
	])
	flash.color = Color(1.0, 1.0, 1.0, 0.7)
	add_child(flash)
	var tw: Tween = create_tween()
	tw.tween_property(flash, "color:a", 0.0, 0.25)
	tw.tween_callback(flash.queue_free)
	
	AudioManager.play_sfx("camera_shutter")
	
	var tip_bonus: int = 15
	StorageManager.add_gold(tip_bonus)
	EventBus.gold_changed.emit(StorageManager.gold, tip_bonus)
	
	var v_id_str: String = str(get_instance_id())
	var a_id: String = "zoo_capybara"
	if _target_zoo_enclosure != null and _target_zoo_enclosure.has_method("get"):
		a_id = String(_target_zoo_enclosure.get("animal_id"))
	
	EventBus.zoo_photo_checkin_completed.emit(v_id_str, a_id, tip_bonus)
	EventBus.visitor_action_completed.emit(get_instance_id(), "tourist_visit", tip_bonus, 1)

func _show_camera_emote() -> void:
	_show_chat_dialogue("📸 Chụp ảnh thú cưng đẹp quá!")
	_show_emote()

func _drop_zoo_tip() -> void:
	_tip_sprite.visible = true
	var base_coins: int = 15
	var base_gold: int = 25
	if _target_zoo_enclosure != null:
		var a_id: String = String(_target_zoo_enclosure.get("animal_id"))
		if SaveManager.is_animal_fed(a_id):
			base_coins *= 2
			base_gold *= 2
	
	# Hot Air Balloon tip multiplier (+10% per level)
	var balloon_mult: float = 1.0 + float(SaveManager.balloon_level) * 0.10
	base_coins = int(float(base_coins) * balloon_mult)
	
	StorageManager.coins += base_coins
	StorageManager.add_gold(base_gold)
	StorageManager.add_xp(8)
	EventBus.coins_changed.emit(StorageManager.coins, base_coins)
	AudioManager.play_sfx("coin")
	EventBus.tourist_tipped.emit(base_coins, base_gold, 8, position)
	
	var qm: Node = get_tree().current_scene.find_child("QuestManager", true, false)
	if qm != null and qm.has_method("notify_visitor_served"):
		qm.call("notify_visitor_served")
		
	var tween: Tween = create_tween()
	tween.tween_property(_tip_sprite, "position:y", -42.0, 0.5)
	tween.tween_interval(1.4)
	tween.tween_property(_tip_sprite, "visible", false, 0.1)

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
	if npc_type != "visitor_tourist":
		return
	if _label_demand != null and _label_demand.visible:
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
	if _label_demand != null:
		_label_demand.visible = false
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

func _drop_orchard_reward() -> void:
	_tip_sprite.visible = true
	var reward_gold_orchard: int = 60
	var reward_coins_orchard: int = 10
	var reward_xp_orchard: int = 8
	
	StorageManager.add_gold(reward_gold_orchard)
	StorageManager.coins += reward_coins_orchard
	StorageManager.add_xp(reward_xp_orchard)
	
	EventBus.gold_changed.emit(StorageManager.gold, reward_gold_orchard)
	EventBus.coins_changed.emit(StorageManager.coins, reward_coins_orchard)
	AudioManager.play_sfx("coin")
	EventBus.tourist_tipped.emit(reward_coins_orchard, reward_gold_orchard, reward_xp_orchard, position)
	
	if _target_orchard_tree != null and is_instance_valid(_target_orchard_tree):
		if bool(_target_orchard_tree.get("is_ripe")):
			var crop_name: String = "apple"
			if bool(_target_orchard_tree.get("is_mango_tree")):
				crop_name = "mango"
			if StorageManager.get_barn_capacity_left() > 0:
				StorageManager.add_item(crop_name, 1)
	
	var tw: Tween = create_tween()
	tw.tween_property(_tip_sprite, "position:y", -42.0, 0.5)
	tw.tween_interval(1.4)
	tw.tween_property(_tip_sprite, "visible", false, 0.1)

func _handle_picnic_tea_rest() -> void:
	_show_chat_dialogue("🍵 Thưởng thức Trà Thảo Mộc ấm áp! ✨")
	_show_emote()
	_tip_sprite.visible = true
	
	var has_tea: bool = StorageManager.has_item("item_herbal_tea", 1) or StorageManager.has_item("herbal_tea", 1)
	var earned_gold: int = 30
	var earned_coins: int = 8
	var earned_xp: int = 5
	
	if has_tea:
		if StorageManager.has_item("item_herbal_tea", 1):
			StorageManager.remove_item("item_herbal_tea", 1)
		elif StorageManager.has_item("herbal_tea", 1):
			StorageManager.remove_item("herbal_tea", 1)
		
		earned_gold = 210
		earned_coins = 25
		earned_xp = 18
		AudioManager.play_sfx("level_up")
	else:
		AudioManager.play_sfx("coin")
	
	StorageManager.add_gold(earned_gold)
	StorageManager.coins += earned_coins
	StorageManager.add_xp(earned_xp)
	
	EventBus.gold_changed.emit(StorageManager.gold, earned_gold)
	EventBus.coins_changed.emit(StorageManager.coins, earned_coins)
	EventBus.tourist_tipped.emit(earned_coins, earned_gold, earned_xp, position)
	
	var tw: Tween = create_tween()
	tw.tween_property(_tip_sprite, "position:y", -42.0, 0.5)
	tw.tween_interval(1.4)
	tw.tween_property(_tip_sprite, "visible", false, 0.1)

func _draw() -> void:
	pass