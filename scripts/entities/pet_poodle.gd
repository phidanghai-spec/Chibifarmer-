# scripts/entities/pet_poodle.gd
# Chibi Toy Poodle Pet Entity with Follow AI, Procedural Motion & 1-Click Treasure Digging
class_name PetPoodle
extends Node2D

@export var follow_distance_min: float = 40.0
@export var follow_distance_max: float = 58.0
@export var move_speed: float = 68.0

var _sprite: Sprite2D = null
var _shadow: Polygon2D = null
var _label_status: Label = null
var _emote_sprite: Sprite2D = null

var _base_scale: Vector2 = Vector2.ONE
var _player_target: Node2D = null
var _walk_phase: float = 0.0
var _idle_timer: float = 0.0
var _is_interacting: bool = false

# River & Bridge Waypoints
const RIVER_MIN_X: float = 635.0
const RIVER_MAX_X: float = 1085.0
const BRIDGE_WEST_X: float = 620.0
const BRIDGE_EAST_X: float = 1100.0
const BRIDGE_Y: float = 656.0
const BRIDGE_ALT_Y: float = 528.0

func _ready() -> void:
	add_to_group("interactable")
	y_sort_enabled = true
	z_index = 10
	_setup_visuals()
	call_deferred("_find_player_avatar")

func _setup_visuals() -> void:
	# 1. Soft Ellipse Ground Shadow
	_shadow = Polygon2D.new()
	_shadow.color = Color(0.12, 0.22, 0.10, 0.28)
	var pts: PackedVector2Array = PackedVector2Array()
	var segs: int = 16
	for i: int in range(segs):
		var a: float = (float(i) / float(segs)) * TAU
		pts.append(Vector2(cos(a) * 16.0, sin(a) * 7.5))
	_shadow.polygon = pts
	_shadow.position = Vector2(0.0, 14.0)
	_shadow.z_index = -1
	add_child(_shadow)

	# 2. Chibi Poodle Sprite (strictly 40x40px display size)
	_sprite = Sprite2D.new()
	_sprite.centered = true
	if SpriteAtlasManager.has_texture("pet_poodle"):
		_sprite.texture = SpriteAtlasManager.get_texture("pet_poodle")
	SpriteAtlasManager.set_sprite_pixel_size(_sprite, Vector2(40.0, 40.0))
	_base_scale = _sprite.scale
	_sprite.position = Vector2(0.0, -2.0)
	add_child(_sprite)

	# 3. Emote Sprite (Heart / Music / Sparkle)
	_emote_sprite = Sprite2D.new()
	_emote_sprite.centered = true
	if SpriteAtlasManager.has_texture("icon_heart"):
		_emote_sprite.texture = SpriteAtlasManager.get_texture("icon_heart")
	SpriteAtlasManager.set_sprite_pixel_size(_emote_sprite, Vector2(20.0, 20.0))
	_emote_sprite.position = Vector2(0.0, -38.0)
	_emote_sprite.visible = false
	add_child(_emote_sprite)

	# 4. Overhead Name & Mood Tag
	_label_status = Label.new()
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

	# 5. Tap interaction button
	var btn_tap: Button = Button.new()
	btn_tap.flat = true
	btn_tap.custom_minimum_size = Vector2(44.0, 48.0)
	btn_tap.position = Vector2(-22.0, -24.0)
	btn_tap.pressed.connect(feed_and_dig_treasure)
	add_child(btn_tap)

func _find_player_avatar() -> void:
	var farm: Node = get_tree().current_scene
	if farm != null:
		_player_target = farm.find_child("PlayerAvatar", true, false) as Node2D

func _process(delta: float) -> void:
	# Safety clamp: Poodle sprite must never balloon out of Chibi scale
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

	# Check which bank Poodle and Player are on
	var is_poodle_west: bool = cur_pos.x < 750.0
	var is_player_west: bool = p_pos.x < 750.0
	var crossing_river: bool = (is_poodle_west != is_player_west)

	var target_dest: Vector2 = p_pos
	# Choose bridge crossing Y (actual visual bridge row 20 at 656, or 528 if near upper bank)
	var crossing_y: float = BRIDGE_ALT_Y if absf(p_pos.y - BRIDGE_ALT_Y) < 70.0 else BRIDGE_Y

	if crossing_river:
		# Poodle must cross via Wooden Bridge Waypoints
		if is_poodle_west:
			if cur_pos.x < BRIDGE_WEST_X - 10.0:
				target_dest = Vector2(BRIDGE_WEST_X, crossing_y)
			else:
				target_dest = Vector2(BRIDGE_EAST_X, crossing_y)
		else:
			if cur_pos.x > BRIDGE_EAST_X + 10.0:
				target_dest = Vector2(BRIDGE_EAST_X, crossing_y)
			else:
				target_dest = Vector2(BRIDGE_WEST_X, crossing_y)
	else:
		var dir_to_p: Vector2 = (p_pos - cur_pos).normalized()
		target_dest = p_pos - dir_to_p * follow_distance_min

	var move_dist: float = cur_pos.distance_to(target_dest)

	if move_dist > 8.0:
		# Follow / Move mode
		_idle_timer = 0.0
		var step: float = move_speed * delta * (1.45 if dist > 140.0 else 1.0)
		var next_pos: Vector2 = cur_pos.move_toward(target_dest, step)

		# Strict River Barrier: Outside the wooden bridge corridor, x cannot be inside [635, 1085]
		var is_in_bridge_corridor: bool = (next_pos.y >= 505.0 and next_pos.y <= 690.0)
		if not is_in_bridge_corridor:
			if next_pos.x >= RIVER_MIN_X and next_pos.x <= RIVER_MAX_X:
				if cur_pos.x < 750.0:
					next_pos.x = RIVER_MIN_X - 1.0
				else:
					next_pos.x = RIVER_MAX_X + 1.0

		global_position = next_pos

		# Procedural Walk Bounce & Squish (multiplied by _base_scale)
		_walk_phase += delta * 14.0
		_sprite.position.y = -2.0 - absf(sin(_walk_phase)) * 4.2
		_sprite.rotation = sin(_walk_phase * 0.5) * 0.07
		_sprite.scale = _base_scale * Vector2(1.0 + sin(_walk_phase) * 0.06, 1.0 - sin(_walk_phase) * 0.06)
		_shadow.scale = Vector2.ONE * (1.0 - absf(sin(_walk_phase)) * 0.12)

		var move_dir_x: float = target_dest.x - cur_pos.x
		if move_dir_x < -0.1:
			_sprite.flip_h = true
		elif move_dir_x > 0.1:
			_sprite.flip_h = false

	elif not crossing_river and dist < follow_distance_min - 10.0:
		# Step back politely so as not to crowd player
		var push_dir: Vector2 = (cur_pos - p_pos).normalized()
		global_position += push_dir * (move_speed * 0.5 * delta)
	else:
		# Idle & Roam near Master Mode
		_walk_phase = 0.0
		_sprite.position.y = -2.0
		_sprite.rotation = 0.0
		_shadow.scale = Vector2.ONE

		_idle_timer += delta
		var breath: float = sin(Time.get_ticks_msec() * 0.005) * 0.045
		_sprite.scale = _base_scale * Vector2(1.0 + breath, 1.0 - breath)

		# Occasional tail wagging & happy bark
		if int(_idle_timer) % 7 == 3:
			_sprite.rotation = sin(Time.get_ticks_msec() * 0.02) * 0.12

func feed_and_dig_treasure() -> void:
	if _is_interacting:
		return

	var farm: Node = get_tree().current_scene
	var hud: UIHud = farm.find_child("UIHud", true, false) as UIHud if farm != null else null

	# Cost: 1 Milk (Sữa bò) or 40 Gold
	var has_milk: bool = StorageManager.has_item("milk", 1)
	var has_gold: bool = StorageManager.has_gold(40)

	if not has_milk and not has_gold:
		AudioManager.play_sfx("error")
		if hud != null:
			hud.show_floating_notice("⚠️ Cần 1 Sữa Bò tươi 🥛 hoặc 40 Vàng 🪙 để cho Poodle ăn!")
		return

	_is_interacting = true
	var used_milk: bool = false
	if has_milk:
		StorageManager.remove_item("milk", 1)
		used_milk = true
	else:
		StorageManager.spend_gold(40)
		EventBus.gold_changed.emit(StorageManager.gold, -40)

	AudioManager.play_sfx("level_up")

	# Happy Jump & Spin Tween (Strictly respecting _base_scale)
	var orig_y: float = _sprite.position.y
	var tw: Tween = create_tween().set_parallel(false)
	tw.tween_property(_sprite, "position:y", orig_y - 24.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_sprite, "scale", _base_scale * Vector2(1.15, 0.88), 0.15)
	tw.tween_property(_sprite, "position:y", orig_y, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_property(_sprite, "scale", _base_scale, 0.15)

	# Show Emote Heart & Notes
	_emote_sprite.visible = true
	_emote_sprite.scale = Vector2.ZERO
	var tw_e: Tween = create_tween()
	tw_e.tween_property(_emote_sprite, "scale", Vector2(1.4, 1.4), 0.2)
	tw_e.tween_property(_emote_sprite, "position:y", -54.0, 0.8)
	tw_e.tween_property(_emote_sprite, "modulate:a", 0.0, 0.3)

	_label_status.text = "❤️ Gâu Gâu! (Đào đất...)"

	await get_tree().create_timer(0.65).timeout

	# Digging animation (quick shake)
	var tw_dig: Tween = create_tween().set_loops(4)
	tw_dig.tween_property(_sprite, "position:x", 3.0, 0.06)
	tw_dig.tween_property(_sprite, "position:x", -3.0, 0.06)
	await tw_dig.finished
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
	# 35% chance to dig up a Diamond or Puzzle Piece
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
		var cost_msg: String = "1 Sữa bò" if used_milk else "40 Vàng"
		hud.show_floating_notice("🐩 Poodle đào trúng kho báu! (+%d XP, +%d Vàng, +%d Xu%s)" % [xp_reward, gold_reward, coins_reward, bonus_text])

	_label_status.text = "🐾 Poodle Thân Thiết (Lv.%d)" % (1 + SaveManager.poodle_affinity / 50)
	_emote_sprite.visible = false
	_emote_sprite.position = Vector2(0.0, -38.0)
	_emote_sprite.modulate.a = 1.0

	_is_interacting = false
