# scripts/entities/pet_poodle.gd
# Chibi Toy Poodle Pet Entity with Follow AI, Procedural Motion & 1-Click Treasure Digging
class_name PetPoodle
extends Node2D

@export var follow_distance_min: float = 44.0
@export var move_speed: float = 72.0

const DIG_COOLDOWN_SECONDS: int = 120

var _sprite: Sprite2D = null
var _shadow: Polygon2D = null
var _label_status: Label = null
var _btn_tap: Button = null

var _base_scale: Vector2 = Vector2.ONE
var _player_target: Node2D = null
var _walk_phase: float = 0.0
var _idle_timer: float = 0.0
var _is_interacting: bool = false
var _next_dig_timestamp: int = 0

# River & Bridge Waypoints (Visual bridge at y: 636..684, x: 820..1080)
const BRIDGE_WEST_X: float = 790.0
const BRIDGE_EAST_X: float = 1110.0
const BRIDGE_CROSSING_Y: float = 656.0

func _ready() -> void:
	add_to_group("interactable")
	y_sort_enabled = true
	z_index = 10
	_setup_visuals()
	call_deferred("_find_player_avatar")

func _setup_visuals() -> void:
	# 1. Soft Ellipse Ground Shadow (Warm 2-Layer & Clearly Grounded)
	_shadow = Polygon2D.new()
	_shadow.name = "PoodleShadow"
	_shadow.color = Color(0.12, 0.16, 0.08, 0.45)
	var pts: PackedVector2Array = PackedVector2Array()
	var segs: int = 16
	for i: int in range(segs):
		var a: float = (float(i) / float(segs)) * TAU
		pts.append(Vector2(cos(a) * 16.0, sin(a) * 7.5))
	_shadow.polygon = pts
	_shadow.position = Vector2(0.0, 14.0)
	_shadow.z_index = -1
	
	var inner_shadow: Polygon2D = Polygon2D.new()
	inner_shadow.name = "ShadowCore"
	var in_pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(segs):
		var a: float = (float(i) / float(segs)) * TAU
		in_pts.append(Vector2(cos(a) * 10.0, sin(a) * 4.5))
	inner_shadow.polygon = in_pts
	inner_shadow.color = Color(0.08, 0.12, 0.05, 0.35)
	_shadow.add_child(inner_shadow)
	
	add_child(_shadow)

	# 2. Chibi Poodle Sprite (strictly 40x40px display size)
	_sprite = Sprite2D.new()
	_sprite.centered = true
	var p_id: String = "pet_poodle"
	if SaveManager != null and SaveManager.avatar_config != null and SaveManager.avatar_config.has("poodle"):
		p_id = str(SaveManager.avatar_config["poodle"])
	if SpriteAtlasManager.has_texture(p_id):
		_sprite.texture = SpriteAtlasManager.get_texture(p_id)
	elif SpriteAtlasManager.has_texture("pet_poodle"):
		_sprite.texture = SpriteAtlasManager.get_texture("pet_poodle")
	SpriteAtlasManager.set_sprite_pixel_size(_sprite, Vector2(40.0, 40.0))
	_base_scale = _sprite.scale
	_sprite.position = Vector2(0.0, -2.0)
	add_child(_sprite)

	# 3. Overhead Name & Mood Tag
	_label_status = Label.new()
	DataManager.apply_emoji_font(_label_status)
	_label_status.text = "🐩 Poodle Bông"
	_label_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label_status.position = Vector2(-60.0, -42.0)
	_label_status.custom_minimum_size = Vector2(120.0, 18.0)
	_label_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label_status.add_theme_font_size_override("font_size", 9)
	_label_status.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	_label_status.add_theme_color_override("font_outline_color", Color(0.2, 0.12, 0.05))
	_label_status.add_theme_constant_override("outline_size", 3)
	add_child(_label_status)

	# 4. Tap interaction button
	_btn_tap = Button.new()
	_btn_tap.flat = true
	_btn_tap.custom_minimum_size = Vector2(44.0, 48.0)
	_btn_tap.position = Vector2(-22.0, -24.0)
	_btn_tap.pressed.connect(feed_and_dig_treasure)
	add_child(_btn_tap)

func _find_player_avatar() -> void:
	var farm: Node = get_tree().current_scene
	if farm != null:
		_player_target = farm.find_child("PlayerAvatar", true, false) as Node2D

func _process(delta: float) -> void:
	if _sprite != null and _sprite.scale.x > _base_scale.x * 1.3:
		_sprite.scale = _base_scale

	if _is_interacting:
		return

	if _player_target == null or not is_instance_valid(_player_target):
		_find_player_avatar()
		return

	var p_pos: Vector2 = _player_target.global_position
	var cur_pos: Vector2 = global_position
	var dist: float = cur_pos.distance_to(p_pos)

	# Bank detection (River bridge connects around x = 790..1110, y = 636..684)
	var is_poodle_west: bool = cur_pos.x < 920.0
	var is_player_west: bool = p_pos.x < 920.0
	var crossing_river: bool = (is_poodle_west != is_player_west)

	# EMERGENCY WATER EVACUATION: If somehow placed in river, immediately return to safe bridge entrance
	if GridManager != null and GridManager.is_in_water_or_sand(cur_pos):
		cur_pos.x = BRIDGE_WEST_X if is_poodle_west else BRIDGE_EAST_X
		cur_pos.y = BRIDGE_CROSSING_Y
		global_position = cur_pos

	var target_dest: Vector2 = p_pos
	if crossing_river:
		# Poodle must first travel to its bank's bridge entrance, then cross through the bridge center
		var my_entrance: Vector2 = Vector2(BRIDGE_WEST_X, BRIDGE_CROSSING_Y) if is_poodle_west else Vector2(BRIDGE_EAST_X, BRIDGE_CROSSING_Y)
		var other_entrance: Vector2 = Vector2(BRIDGE_EAST_X, BRIDGE_CROSSING_Y) if is_poodle_west else Vector2(BRIDGE_WEST_X, BRIDGE_CROSSING_Y)
		
		if cur_pos.distance_to(my_entrance) > 24.0:
			target_dest = my_entrance
		else:
			target_dest = other_entrance
	else:
		# Follow beside or behind player, never directly on player's head
		var side_offset: Vector2 = Vector2(-44.0, 10.0)
		if _player_target.scale.x < 0.0:
			side_offset.x = 44.0
		target_dest = p_pos + side_offset

	var move_dist: float = cur_pos.distance_to(target_dest)

	if move_dist > 10.0 and dist > follow_distance_min:
		_idle_timer = 0.0
		var step: float = move_speed * delta * (1.5 if dist > 140.0 else 1.0)
		var next_pos: Vector2 = cur_pos.move_toward(target_dest, step)

		# STRICT RIVER BARRIER: Never step into water or sand!
		if GridManager != null and GridManager.is_in_water_or_sand(next_pos):
			# Head toward bridge entrance
			var safe_entrance: Vector2 = Vector2(BRIDGE_WEST_X if is_poodle_west else BRIDGE_EAST_X, BRIDGE_CROSSING_Y)
			next_pos = cur_pos.move_toward(safe_entrance, step)
			if GridManager.is_in_water_or_sand(next_pos):
				return # Completely halt rather than walk into river!

		global_position = next_pos

		# Procedural Walk Bounce & Squish
		_walk_phase += delta * 14.0
		_sprite.position.y = -2.0 - absf(sin(_walk_phase)) * 4.2
		_sprite.rotation = 0.0
		_sprite.scale = _base_scale * Vector2(1.0 + sin(_walk_phase) * 0.06, 1.0 - sin(_walk_phase) * 0.06)
		_shadow.scale = Vector2.ONE * (1.0 - absf(sin(_walk_phase)) * 0.12)

		var move_dir_x: float = target_dest.x - cur_pos.x
		if move_dir_x < -0.1:
			_sprite.flip_h = true
		elif move_dir_x > 0.1:
			_sprite.flip_h = false

	elif not crossing_river and dist < follow_distance_min - 12.0:
		# Step back gently if master gets too close
		var push_dir: Vector2 = (cur_pos - p_pos).normalized()
		var candidate_pos: Vector2 = cur_pos + push_dir * (move_speed * 0.5 * delta)
		if GridManager == null or not GridManager.is_in_water_or_sand(candidate_pos):
			global_position = candidate_pos
	else:
		# Idle & Roam near Master Mode
		_walk_phase = 0.0
		_sprite.position.y = -2.0
		_sprite.rotation = 0.0
		_shadow.scale = Vector2.ONE

		_idle_timer += delta
		var breath: float = sin(Time.get_ticks_msec() * 0.005) * 0.045
		_sprite.scale = _base_scale * Vector2(1.0 + breath, 1.0 - breath)

		if int(_idle_timer) % 7 == 3:
			_sprite.rotation = sin(Time.get_ticks_msec() * 0.02) * 0.08

func feed_and_dig_treasure() -> void:
	if _is_interacting:
		return

	var tree_root: SceneTree = get_tree()
	var farm: Node = tree_root.current_scene if tree_root != null else null
	var hud: UIHud = farm.find_child("UIHud", true, false) as UIHud if farm != null else null

	var cooldown_until: int = maxi(_next_dig_timestamp, SaveManager.poodle_next_dig_timestamp if SaveManager != null else 0)
	if cooldown_until > 0 and not TickManager.is_finished(cooldown_until):
		var rem_s: int = TickManager.get_time_remaining(cooldown_until)
		AudioManager.play_sfx("click")
		if hud != null:
			hud.show_floating_notice("🐾 Poodle đang nghỉ ngơi (còn %s)..." % TickManager.format_duration(rem_s))
		return

	var has_milk: bool = StorageManager.has_item("milk", 1)
	var has_gold: bool = StorageManager.has_gold(40)

	if not has_milk and not has_gold:
		AudioManager.play_sfx("error")
		if hud != null:
			hud.show_floating_notice("⚠ Cần 1 Sữa Bò tươi 🥛 hoặc 40 Vàng 💰 để cho Poodle ăn!")
		return

	_is_interacting = true
	if _btn_tap != null:
		_btn_tap.disabled = true

	var used_milk: bool = false
	if has_milk:
		StorageManager.remove_item("milk", 1)
		used_milk = true
	else:
		StorageManager.spend_gold(40)
		EventBus.gold_changed.emit(StorageManager.gold, -40)

	# Lock cooldown timestamp atomically before animation/awaits to block rapid spam exploit
	var next_ts: int = TickManager.calculate_finish_timestamp(DIG_COOLDOWN_SECONDS)
	_next_dig_timestamp = next_ts
	if SaveManager != null:
		SaveManager.poodle_next_dig_timestamp = next_ts

	AudioManager.play_sfx("level_up")

	# Happy Jump Tween (Strictly respecting _base_scale)
	if _sprite != null and is_inside_tree():
		var orig_y: float = _sprite.position.y
		var tw: Tween = create_tween().set_parallel(false)
		tw.tween_property(_sprite, "position:y", orig_y - 20.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(_sprite, "scale", _base_scale * Vector2(1.12, 0.90), 0.15)
		tw.tween_property(_sprite, "position:y", orig_y, 0.20).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw.tween_property(_sprite, "scale", _base_scale, 0.15)

		# Float a 28x28 heart sprite
		_spawn_floating_heart()

	if _label_status != null:
		_label_status.text = "❤ Gâu Gâu! (Đào đất...)"

	if is_inside_tree() and get_tree() != null:
		await get_tree().create_timer(0.60).timeout
	if not is_inside_tree() or not is_instance_valid(self):
		_is_interacting = false
		return

	# Digging animation (quick shake)
	if _sprite != null and is_inside_tree():
		var tw_dig: Tween = create_tween().set_loops(4)
		tw_dig.tween_property(_sprite, "position:x", 3.0, 0.06)
		tw_dig.tween_property(_sprite, "position:x", -3.0, 0.06)
		await tw_dig.finished
	if not is_inside_tree() or not is_instance_valid(self):
		_is_interacting = false
		return

	if _sprite != null:
		_sprite.position.x = 0.0
		_sprite.scale = _base_scale

	# Grant Rewards
	var xp_reward: int = 80
	var gold_reward: int = 120
	var coins_reward: int = 35

	StorageManager.add_xp(xp_reward)
	StorageManager.add_gold(gold_reward)
	StorageManager.add_coins(coins_reward)

	SaveManager.poodle_affinity += 10
	SaveManager.poodle_feed_count += 1
	SaveManager.poodle_updated.emit()
	SaveManager.save_game()

	var bonus_text: String = ""
	var r: float = randf()
	if r < 0.20:
		SaveManager.add_puzzle_pieces(1)
		bonus_text = " + 1 🧩 Mảnh Ghép Sở Thú"
	elif r < 0.35:
		StorageManager.diamonds += 1
		EventBus.diamonds_changed.emit(StorageManager.diamonds, 1)
		bonus_text = " + 1 💎 Kim Cương"

	AudioManager.play_sfx("harvest")
	if hud != null:
		var _cost_msg: String = "1 Sữa bò" if used_milk else "40 Vàng"
		hud.show_floating_notice("🐩 Poodle đào trúng kho báu! (+%d XP, +%d Vàng, +%d Xu%s)" % [xp_reward, gold_reward, coins_reward, bonus_text])

	if _label_status != null:
		_label_status.text = "🐾 Poodle Thân Thiết (Lv.%d)" % (1 + SaveManager.poodle_affinity / 50)
	_is_interacting = false
	if _btn_tap != null:
		_btn_tap.disabled = false

func _spawn_floating_heart() -> void:
	var heart_sp: Sprite2D = Sprite2D.new()
	heart_sp.centered = true
	if SpriteAtlasManager.has_texture("icon_heart"):
		heart_sp.texture = SpriteAtlasManager.get_texture("icon_heart")
	
	var tex_w: float = 256.0
	var tex_h: float = 256.0
	if heart_sp.texture != null:
		tex_w = float(heart_sp.texture.get_width())
		tex_h = float(heart_sp.texture.get_height())
		
	# Strictly normalized to 28x28 pixels
	var heart_scale: Vector2 = Vector2(28.0 / tex_w, 28.0 / tex_h)
	heart_sp.scale = heart_scale * 0.5
	heart_sp.position = Vector2(0.0, -32.0)
	heart_sp.z_index = 25
	add_child(heart_sp)
	
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(heart_sp, "scale", heart_scale, 0.20)
	tw.tween_property(heart_sp, "position:y", -66.0, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(heart_sp, "modulate:a", 0.0, 0.30)
	tw.chain().tween_callback(heart_sp.queue_free)
