# scripts/entities/beehive_tree.gd
# Chibi Beehive Tree with Honey Gathering & 3 Flying Chibi Bees
class_name BeehiveTree
extends Node2D

signal honey_harvested(amount: int)
signal beehive_state_changed(new_state: int)

enum HiveState {
	GATHERING,
	READY
}

const HONEY_CYCLE_SEC: float = 20.0
const FLOWER_TARGETS: Array[Vector2] = [
	Vector2(-45.0, -75.0),
	Vector2(35.0, -55.0),
	Vector2(-35.0, 45.0),
	Vector2(65.0, 25.0)
]

var state: HiveState = HiveState.GATHERING
var _timer: float = 0.0
var _flight_time: float = 0.0

var _tree_sprite: Sprite2D = null
var _tree_base_scale: Vector2 = Vector2.ONE
var _bees: Array[Sprite2D] = []
var _bee_base_scale: Vector2 = Vector2.ONE

var _pill_bubble: PanelContainer = null
var _lbl_bubble: Label = null
var _lbl_name: Label = null

func _ready() -> void:
	add_to_group("interactable")
	y_sort_enabled = true
	z_index = 6
	_setup_visuals()

func _setup_visuals() -> void:
	# 1. Beehive Tree Sprite (locked at 64x64 display size)
	_tree_sprite = Sprite2D.new()
	_tree_sprite.centered = true
	_tree_sprite.name = "TreeSprite"
	if SpriteAtlasManager.has_texture("beehive_tree"):
		_tree_sprite.texture = SpriteAtlasManager.get_texture("beehive_tree")
	SpriteAtlasManager.set_sprite_pixel_size(_tree_sprite, Vector2(64.0, 64.0))
	_tree_base_scale = _tree_sprite.scale
	_tree_sprite.position = Vector2(0.0, 0.0)
	add_child(_tree_sprite)

	# 2. 3 Chibi Honeybees (locked at 18x18 display size)
	for i: int in range(3):
		var bee: Sprite2D = Sprite2D.new()
		bee.centered = true
		bee.name = "Bee_%d" % i
		if SpriteAtlasManager.has_texture("bee_chibi"):
			bee.texture = SpriteAtlasManager.get_texture("bee_chibi")
		SpriteAtlasManager.set_sprite_pixel_size(bee, Vector2(18.0, 18.0))
		_bee_base_scale = bee.scale
		bee.position = Vector2(0.0, -8.0)
		add_child(bee)
		_bees.append(bee)

	# 3. Tree Name Label
	_lbl_name = Label.new()
	_lbl_name.text = "🐝 Cây Tổ Ong"
	_lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lbl_name.position = Vector2(-50.0, -48.0)
	_lbl_name.custom_minimum_size = Vector2(100.0, 16.0)
	_lbl_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lbl_name.add_theme_font_size_override("font_size", 9)
	_lbl_name.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75))
	_lbl_name.add_theme_color_override("font_outline_color", Color(0.20, 0.12, 0.05))
	_lbl_name.add_theme_constant_override("outline_size", 3)
	add_child(_lbl_name)

	# 4. Ready Status Pill Bubble ("🍯 Sẵn Sàng!")
	_pill_bubble = PanelContainer.new()
	_pill_bubble.position = Vector2(-36.0, -68.0)
	_pill_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var psb: StyleBoxFlat = StyleBoxFlat.new()
	psb.bg_color = Color(1.0, 0.98, 0.92, 0.95)
	psb.border_color = Color(0.85, 0.55, 0.15, 0.9)
	psb.set_border_width_all(2)
	psb.set_corner_radius_all(10)
	psb.content_margin_left = 8
	psb.content_margin_right = 8
	psb.content_margin_top = 2
	psb.content_margin_bottom = 2
	_pill_bubble.add_theme_stylebox_override("panel", psb)

	_lbl_bubble = Label.new()
	_lbl_bubble.text = "🍯 Sẵn Sàng!"
	_lbl_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lbl_bubble.add_theme_font_size_override("font_size", 10)
	_lbl_bubble.add_theme_color_override("font_color", Color(0.85, 0.40, 0.05))
	_pill_bubble.add_child(_lbl_bubble)
	_pill_bubble.visible = false
	add_child(_pill_bubble)

	# 5. Tap interaction button
	var btn_tap: Button = Button.new()
	btn_tap.flat = true
	btn_tap.position = Vector2(-36.0, -48.0)
	btn_tap.custom_minimum_size = Vector2(72.0, 84.0)
	btn_tap.pressed.connect(handle_beehive_click)
	add_child(btn_tap)

func _process(delta: float) -> void:
	# Strict scale clamp
	if _tree_sprite != null and _tree_sprite.scale.x > _tree_base_scale.x * 1.3:
		_tree_sprite.scale = _tree_base_scale

	_flight_time += delta

	match state:
		HiveState.GATHERING:
			_timer += delta
			if _timer >= HONEY_CYCLE_SEC:
				state = HiveState.READY
				beehive_state_changed.emit(state)
				_pill_bubble.visible = true
				AudioManager.play_sfx("bell")

			# Flying bees path: ping-pong wave between hive (0, -8) and flowers
			for i: int in range(_bees.size()):
				var target_flower: Vector2 = FLOWER_TARGETS[i % FLOWER_TARGETS.size()]
				var phase: float = _flight_time * (0.45 + float(i) * 0.14) + float(i) * 1.2
				var ping_pong: float = absf(fmod(phase, 2.0) - 1.0) # 0.0 -> 1.0 -> 0.0
				var base_pos: Vector2 = Vector2(0.0, -8.0).lerp(target_flower, ping_pong)
				var wave_y: float = sin(_flight_time * 7.0 + float(i) * 2.0) * 6.0
				_bees[i].position = base_pos + Vector2(0.0, wave_y)
				_bees[i].flip_h = (fmod(phase, 2.0) > 1.0)
				_bees[i].scale = _bee_base_scale * Vector2(1.0 + sin(_flight_time * 12.0) * 0.08, 1.0 - sin(_flight_time * 12.0) * 0.08)

		HiveState.READY:
			_pill_bubble.visible = true
			# Gentle bob of ready bubble
			_pill_bubble.position.y = -68.0 + sin(Time.get_ticks_msec() * 0.005) * 2.5
			# 3 bees circling hive happily
			for i: int in range(_bees.size()):
				var angle: float = _flight_time * 2.8 + float(i) * (TAU / 3.0)
				var circle_offset: Vector2 = Vector2(cos(angle) * 18.0, sin(angle) * 10.0 - 8.0)
				_bees[i].position = circle_offset
				_bees[i].flip_h = (cos(angle) < 0.0)
				_bees[i].scale = _bee_base_scale

func handle_beehive_click() -> void:
	AudioManager.play_sfx("click")
	var farm: Node = get_tree().current_scene
	var hud: UIHud = farm.find_child("UIHud", true, false) as UIHud if farm != null else null

	if state == HiveState.READY:
		harvest_honey()
	else:
		# Gathering in progress
		var rem_s: int = int(ceil(HONEY_CYCLE_SEC - _timer))
		if StorageManager.has_gold(20):
			# Option: Quick boost for 20 gold
			StorageManager.spend_gold(20)
			EventBus.gold_changed.emit(StorageManager.gold, -20)
			AudioManager.play_sfx("sell")
			if hud != null:
				hud.show_floating_notice("⚡ Đã thúc đàn ong hoàn thành mật sớm! (-20 Vàng)")
			state = HiveState.READY
			_timer = HONEY_CYCLE_SEC
			_pill_bubble.visible = true
		else:
			if hud != null:
				hud.show_floating_notice("🐝 Đàn ong đang hút mật hoa (còn %ds)..." % rem_s)

func harvest_honey() -> void:
	if state != HiveState.READY:
		return

	# Rewards
	var honey_yield: int = 2
	var gold_reward: int = 90
	var xp_reward: int = 45
	var coins_reward: int = 25

	StorageManager.add_item("honey", honey_yield)
	StorageManager.add_gold(gold_reward)
	StorageManager.add_xp(xp_reward)
	StorageManager.add_coins(coins_reward)

	AudioManager.play_sfx("harvest")

	# Squash & Stretch Tree Bounce Tween
	var tw: Tween = create_tween().set_parallel(false)
	tw.tween_property(_tree_sprite, "scale", _tree_base_scale * Vector2(1.12, 0.90), 0.12)
	tw.tween_property(_tree_sprite, "scale", _tree_base_scale, 0.16)

	EventBus.loot_collected.emit("honey", honey_yield, global_position + Vector2(0, -20))
	honey_harvested.emit(honey_yield)

	var farm: Node = get_tree().current_scene
	var hud: UIHud = farm.find_child("UIHud", true, false) as UIHud if farm != null else null
	if hud != null:
		hud.show_floating_notice("+2 🍯 Mật Ong Rừng (+%d Vàng, +%d XP, +%d Xu)!" % [gold_reward, xp_reward, coins_reward])

	state = HiveState.GATHERING
	_timer = 0.0
	_pill_bubble.visible = false
	beehive_state_changed.emit(state)

func on_player_interact(_player: Node2D = null) -> void:
	handle_beehive_click()
