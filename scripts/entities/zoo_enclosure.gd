# scripts/entities/zoo_enclosure.gd
# Connected Fenced Zoo Park Enclosure (220x150px) with 2-3 Animated Chibi Animals
extends Node2D
class_name ZooEnclosure

signal enclosure_clicked(enclosure: ZooEnclosure)

@export var animal_id: String = "zoo_capybara"
@export var animal_name: String = "Capybara"
@export var enclosure_title: String = "Hồ Capybara 🍊"
@export var favorite_foods: Array[String] = ["carrot", "sanctuary_feed"]
@export var unlock_pieces_cost: int = 1
@export var unlock_gold_cost: int = 250
@export var base_attraction: int = 30

const ENCLOSURE_SIZE: Vector2 = Vector2(220.0, 150.0)
const PADDOCK_RECT: Rect2 = Rect2(-110.0, -75.0, 220.0, 150.0)

class AnimalInstance:
	var root: Node2D = null
	var sprite: Sprite2D = null
	var shadow: Polygon2D = null
	var current_pos: Vector2 = Vector2.ZERO
	var target_pos: Vector2 = Vector2.ZERO
	var base_scale: Vector2 = Vector2.ONE
	var phase_offset: float = 0.0
	var speed: float = 24.0
	var wait_timer: float = 0.0
	var home_pos: Vector2 = Vector2.ZERO
	var wander_radius: float = 22.0

var _animals: Array[AnimalInstance] = []
var _bubble_node: Node2D = null
var _bubble_label: Label = null
var _title_label: Label = null
var _lock_overlay: Node2D = null
var _anim_timer: float = 0.0

func _ready() -> void:
	add_to_group("interactable")
	y_sort_enabled = true
	_setup_visuals()
	_update_state()
	
	SaveManager.zoo_updated.connect(_on_zoo_updated)
	SaveManager.puzzle_pieces_changed.connect(_on_puzzle_pieces_changed)

func _draw() -> void:
	# 1. Wooden Post & Rail Fence along 4 edges with viewing gate
	var fence_wood: Color = Color(0.48, 0.32, 0.18)
	var fence_light: Color = Color(0.72, 0.52, 0.32)
	
	# Top & Left & Right Rails
	draw_line(Vector2(-108.0, -72.0), Vector2(108.0, -72.0), fence_wood, 3.5)
	draw_line(Vector2(-108.0, -66.0), Vector2(108.0, -66.0), fence_light, 2.5)
	
	draw_line(Vector2(-108.0, -72.0), Vector2(-108.0, 72.0), fence_wood, 3.5)
	draw_line(Vector2(-104.0, -72.0), Vector2(-104.0, 72.0), fence_light, 2.0)
	
	draw_line(Vector2(108.0, -72.0), Vector2(108.0, 72.0), fence_wood, 3.5)
	draw_line(Vector2(104.0, -72.0), Vector2(104.0, 72.0), fence_light, 2.0)
	
	# Bottom Rail with open gate in middle for visitors to observe
	draw_line(Vector2(-108.0, 72.0), Vector2(-28.0, 72.0), fence_wood, 3.5)
	draw_line(Vector2(28.0, 72.0), Vector2(108.0, 72.0), fence_wood, 3.5)
	
	# Wooden Fence Posts at regular intervals
	var post_positions: Array[Vector2] = [
		Vector2(-108.0, -72.0), Vector2(-54.0, -72.0), Vector2(0.0, -72.0), Vector2(54.0, -72.0), Vector2(108.0, -72.0),
		Vector2(-108.0, 0.0), Vector2(108.0, 0.0),
		Vector2(-108.0, 72.0), Vector2(-28.0, 72.0), Vector2(28.0, 72.0), Vector2(108.0, 72.0)
	]
	for p: Vector2 in post_positions:
		draw_rect(Rect2(p.x - 3.5, p.y - 7.0, 7.0, 14.0), fence_wood, true)
		draw_rect(Rect2(p.x - 2.5, p.y - 6.0, 5.0, 4.0), fence_light, true)

func _setup_visuals() -> void:
	# 0. Authentic Chibi Habitat Diorama (Zen Koi pond, Bamboo pavilion, Goat/Penguin rocky cliff, Savannah shelter)
	var hab_key: String = "zoo_enclosure_" + animal_id.replace("zoo_", "")
	if SpriteAtlasManager != null and SpriteAtlasManager.has_texture(hab_key):
		var hab_sprite: Sprite2D = Sprite2D.new()
		hab_sprite.name = "HabitatDiorama"
		hab_sprite.texture = SpriteAtlasManager.get_texture(hab_key)
		SpriteAtlasManager.set_sprite_pixel_size(hab_sprite, Vector2(115.0, 115.0))
		hab_sprite.position = Vector2(-42.0, -2.0)
		hab_sprite.z_index = 0
		add_child(hab_sprite)

	# 1. Setup 2 to 3 Animals wandering inside with generous separation (> 50px)
	var animal_count: int = 3 if (animal_id == "zoo_capybara" or animal_id == "zoo_penguin") else 2
	var spawn_points: Array[Vector2] = []
	if animal_count == 3:
		spawn_points = [Vector2(26.0, -36.0), Vector2(72.0, 4.0), Vector2(28.0, 42.0)]
	else:
		spawn_points = [Vector2(32.0, -32.0), Vector2(68.0, 32.0)]
		
	var tex: Texture2D = null
	if SpriteAtlasManager.has_texture(animal_id):
		tex = SpriteAtlasManager.get_texture(animal_id)
		
	for i in range(animal_count):
		var inst: AnimalInstance = AnimalInstance.new()
		inst.root = Node2D.new()
		inst.root.y_sort_enabled = true
		inst.phase_offset = float(i) * 1.8
		inst.current_pos = spawn_points[i]
		inst.home_pos = spawn_points[i]
		inst.target_pos = inst.current_pos
		inst.root.position = inst.current_pos
		
		# Shadow
		inst.shadow = Polygon2D.new()
		inst.shadow.color = Color(0.0, 0.0, 0.0, 0.28)
		var pts: PackedVector2Array = PackedVector2Array()
		var segs: int = 12
		for s in range(segs):
			var a: float = (float(s) / float(segs)) * TAU
			pts.append(Vector2(cos(a) * 14.0, sin(a) * 6.0))
		inst.shadow.polygon = pts
		inst.shadow.position = Vector2(0.0, 18.0)
		inst.shadow.z_index = -1
		inst.root.add_child(inst.shadow)
		
		# Sprite
		inst.sprite = Sprite2D.new()
		inst.sprite.centered = true
		if tex != null:
			inst.sprite.texture = tex
		var a_size: Vector2 = Vector2(56.0, 56.0) if animal_id == "zoo_giraffe" else Vector2(46.0, 46.0)
		SpriteAtlasManager.set_sprite_pixel_size(inst.sprite, a_size)
		inst.base_scale = inst.sprite.scale
		inst.sprite.position = Vector2(0.0, 4.0)
		inst.root.add_child(inst.sprite)
		
		add_child(inst.root)
		_animals.append(inst)

	# 2. Enclosure Title
	_title_label = Label.new()
	_title_label.text = enclosure_title
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.position = Vector2(-100.0, -96.0)
	_title_label.custom_minimum_size = Vector2(200.0, 22.0)
	_title_label.add_theme_font_size_override("font_size", 12)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88))
	_title_label.add_theme_color_override("font_outline_color", Color(0.2, 0.12, 0.06))
	_title_label.add_theme_constant_override("outline_size", 5)
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title_label)
	
	# 3. Status / Food Speech Bubble
	_bubble_node = Node2D.new()
	_bubble_node.position = Vector2(30.0, -45.0)
	_bubble_node.z_index = 10
	add_child(_bubble_node)
	
	var b_panel: Panel = Panel.new()
	b_panel.custom_minimum_size = Vector2(48.0, 26.0)
	b_panel.position = Vector2(-24.0, -13.0)
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 0.98, 0.94, 0.95)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.42, 0.3, 0.2)
	sb.set_corner_radius_all(10)
	b_panel.add_theme_stylebox_override("panel", sb)
	b_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble_node.add_child(b_panel)
	
	_bubble_label = Label.new()
	_bubble_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bubble_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bubble_label.position = Vector2(-24.0, -13.0)
	_bubble_label.custom_minimum_size = Vector2(48.0, 26.0)
	_bubble_label.add_theme_font_size_override("font_size", 13)
	_bubble_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble_node.add_child(_bubble_label)
	
	# 4. Lock Overlay Node
	_lock_overlay = Node2D.new()
	_lock_overlay.position = Vector2(0.0, 10.0)
	_lock_overlay.z_index = 8
	add_child(_lock_overlay)
	
	var lock_panel: Panel = Panel.new()
	lock_panel.custom_minimum_size = Vector2(130.0, 28.0)
	lock_panel.position = Vector2(-65.0, -14.0)
	var lsb: StyleBoxFlat = StyleBoxFlat.new()
	lsb.bg_color = Color(0.12, 0.1, 0.08, 0.92)
	lsb.set_border_width_all(2)
	lsb.border_color = Color(0.85, 0.65, 0.25)
	lsb.set_corner_radius_all(10)
	lock_panel.add_theme_stylebox_override("panel", lsb)
	lock_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lock_overlay.add_child(lock_panel)
	
	var lock_lbl: Label = Label.new()
	lock_lbl.name = "LockLabel"
	lock_lbl.text = "🔒 Mở Khóa: 🧩 x%d" % unlock_pieces_cost
	lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lock_lbl.position = Vector2(-65.0, -14.0)
	lock_lbl.custom_minimum_size = Vector2(130.0, 28.0)
	lock_lbl.add_theme_font_size_override("font_size", 11)
	lock_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
	lock_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lock_overlay.add_child(lock_lbl)

func _process(delta: float) -> void:
	_anim_timer += delta
	
	# Animals procedural motion (wander + idle breathing)
	var is_unlocked: bool = SaveManager.is_animal_unlocked(animal_id)
	if is_unlocked:
		for inst: AnimalInstance in _animals:
			if inst.sprite == null:
				continue
			var phase: float = _anim_timer * 3.5 + inst.phase_offset
			var breath: float = sin(phase) * 0.05
			inst.sprite.scale = inst.base_scale * Vector2(1.0, 1.0 + breath)
			
			# Wandering within its designated home sector to avoid overlapping
			inst.wait_timer -= delta
			if inst.wait_timer <= 0.0:
				inst.wait_timer = randf_range(3.5, 7.0)
				var wander_offset: Vector2 = Vector2(randf_range(-inst.wander_radius, inst.wander_radius), randf_range(-inst.wander_radius * 0.75, inst.wander_radius * 0.75))
				inst.target_pos = (inst.home_pos + wander_offset).clamp(Vector2(-15.0, -52.0), Vector2(85.0, 52.0))
			
			if inst.current_pos.distance_to(inst.target_pos) > 2.0:
				var move_step: Vector2 = (inst.target_pos - inst.current_pos).normalized() * inst.speed * delta
				inst.current_pos += move_step
				inst.root.position = inst.current_pos
				# Flip sprite towards walking direction
				inst.sprite.flip_h = move_step.x < 0.0
				# Bounce during walk
				inst.sprite.position.y = 4.0 - abs(sin(phase * 2.0)) * 3.0
			else:
				inst.sprite.position.y = 4.0
	
	# Float speech bubble softly
	if _bubble_node != null and _bubble_node.visible:
		_bubble_node.position.y = -45.0 + sin(_anim_timer * 4.0) * 3.0

func _on_zoo_updated(updated_id: String) -> void:
	if updated_id == animal_id or updated_id == "":
		_update_state()

func _on_puzzle_pieces_changed(_new_count: int) -> void:
	_update_state()

func _update_state() -> void:
	var is_unlocked: bool = SaveManager.is_animal_unlocked(animal_id)
	var is_fed: bool = SaveManager.is_animal_fed(animal_id)
	
	if not is_unlocked:
		if _lock_overlay != null:
			_lock_overlay.visible = true
		if _bubble_node != null:
			_bubble_node.visible = false
		for inst in _animals:
			inst.root.visible = false
		modulate = Color(0.75, 0.75, 0.75, 0.95)
		return
		
	if _lock_overlay != null:
		_lock_overlay.visible = false
	for inst in _animals:
		inst.root.visible = true
	modulate = Color.WHITE
		
	if _bubble_node != null:
		_bubble_node.visible = true
		if is_fed:
			_bubble_label.text = "❤️"
		else:
			if favorite_foods.has("carrot"):
				_bubble_label.text = "🥕"
			elif favorite_foods.has("apple"):
				_bubble_label.text = "🍎"
			elif favorite_foods.has("wheat"):
				_bubble_label.text = "🌾"
			elif favorite_foods.has("fish_carp"):
				_bubble_label.text = "🐟"
			else:
				_bubble_label.text = "🥗"
	queue_redraw()

func on_player_interact(_avatar: Node2D) -> void:
	var hud: Node = get_tree().current_scene.find_child("UIHud", true, false)
	
	# 1. If Locked: Prompt to Unlock
	if not SaveManager.is_animal_unlocked(animal_id):
		if SaveManager.puzzle_pieces >= unlock_pieces_cost:
			SaveManager.spend_puzzle_pieces(unlock_pieces_cost)
			SaveManager.unlock_animal(animal_id)
			AudioManager.play_sfx("level_up")
			_show_floating_text("🎉 ĐÃ MỞ KHÓA " + enclosure_title.to_upper() + "!")
			EventBus.attraction_score_changed.emit(GridManager.total_attraction_score + base_attraction)
		elif StorageManager.gold >= unlock_gold_cost:
			if hud != null and hud.has_method("show_confirm_dialog"):
				hud.call("show_confirm_dialog", 
					"Mở Khóa " + animal_name, 
					"Dùng %d Mảnh Ghép 🧩 hoặc %d Vàng 👑 để mở khóa chuồng?" % [unlock_pieces_cost, unlock_gold_cost],
					func() -> void:
						if StorageManager.spend_gold(unlock_gold_cost):
							EventBus.gold_changed.emit(StorageManager.gold, -unlock_gold_cost)
							SaveManager.unlock_animal(animal_id)
							AudioManager.play_sfx("level_up")
							_show_floating_text("🎉 ĐÃ MỞ KHÓA " + enclosure_title.to_upper() + "!")
							EventBus.attraction_score_changed.emit(GridManager.total_attraction_score + base_attraction)
				)
				return
		else:
			_show_floating_text("🔒 Cần %d Mảnh Ghép 🧩 hoặc %d Vàng!" % [unlock_pieces_cost, unlock_gold_cost])
			AudioManager.play_sfx("error")
		return

	# 2. If Already Fed
	if SaveManager.is_animal_fed(animal_id):
		_show_floating_text("✨ Đàn %s đang no nê & tăng x2 Xu Tip!" % animal_name)
		_play_heart_burst()
		return
		
	# 3. If Hungry -> Feed with favorite food or sanctuary_feed
	var chosen_food: String = ""
	for f: String in favorite_foods:
		if StorageManager.get_item_count(f) > 0:
			chosen_food = f
			break
			
	if chosen_food == "" and StorageManager.get_item_count("sanctuary_feed") > 0:
		chosen_food = "sanctuary_feed"
		
	if chosen_food != "":
		StorageManager.remove_item(chosen_food, 1)
		SaveManager.feed_animal(animal_id, 240) # Fed for 4 minutes
		
		# Rewards: +60 XP, +80 Gold, +25 Tour Coin (Xu)
		StorageManager.add_xp(60)
		StorageManager.add_gold(80)
		StorageManager.coins += 25
		EventBus.coins_changed.emit(StorageManager.coins, 25)
		
		AudioManager.play_sfx("sell")
		_play_heart_burst()
		_show_floating_text("❤️ Đã cho đàn %s ăn! (+60 XP, +80 Vàng, +25 Xu)" % animal_name)
		
		var qm: Node = get_tree().current_scene.find_child("QuestManager", true, false)
		if qm != null and qm.has_method("notify_zoo_fed"):
			qm.call("notify_zoo_fed", animal_id)
	else:
		var food_names: String = "Cỏ Dinh Dưỡng hoặc " + favorite_foods[0]
		_show_floating_text("⚠️ Thiếu thức ăn! Cần %s" % food_names)
		AudioManager.play_sfx("error")

func _play_heart_burst() -> void:
	for inst: AnimalInstance in _animals:
		if inst.sprite == null:
			continue
		var tw: Tween = create_tween()
		tw.tween_property(inst.sprite, "scale", inst.base_scale * 1.3, 0.15).set_trans(Tween.TRANS_BACK)
		tw.tween_property(inst.sprite, "scale", inst.base_scale, 0.2).set_trans(Tween.TRANS_SINE)
	
	# Spawn floating hearts
	for i in range(4):
		var heart: Label = Label.new()
		heart.text = "❤️"
		heart.add_theme_font_size_override("font_size", 15)
		heart.position = Vector2(randf_range(-30, 30), -20.0)
		add_child(heart)
		var h_tw: Tween = create_tween()
		h_tw.tween_property(heart, "position:y", heart.position.y - 45.0, 0.8).set_trans(Tween.TRANS_CUBIC)
		h_tw.parallel().tween_property(heart, "modulate:a", 0.0, 0.8)
		h_tw.tween_callback(heart.queue_free)

func _show_floating_text(msg: String) -> void:
	var hud: Node = get_tree().current_scene.find_child("UIHud", true, false)
	if hud != null and hud.has_method("show_floating_notice"):
		hud.call("show_floating_notice", msg)
	else:
		print("[ZooEnclosure] ", msg)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb.button_index == MOUSE_BUTTON_LEFT and mb.is_pressed():
		var mpos: Vector2 = to_local(get_global_mouse_position())
		if PADDOCK_RECT.has_point(mpos):
			if not SaveManager.instant_interact:
				var p_input: Node = get_tree().current_scene.find_child("PlayerInput", true, false)
				if p_input != null:
					p_input.call("interact_with", self)
					get_viewport().set_input_as_handled()
					return
			on_player_interact(null)
			get_viewport().set_input_as_handled()
