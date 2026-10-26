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

var _bg_sprite: Sprite2D = null
var _animal_sprite: Sprite2D = null
var _shadow_poly: Polygon2D = null
var _bubble_node: Node2D = null
var _bubble_label: Label = null
var _title_label: Label = null
var _lock_overlay: Node2D = null

var _anim_timer: float = 0.0
var _base_animal_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	add_to_group("interactable")
	y_sort_enabled = true
	_setup_visuals()
	_update_state()
	
	SaveManager.zoo_updated.connect(_on_zoo_updated)
	SaveManager.puzzle_pieces_changed.connect(_on_puzzle_pieces_changed)

func _setup_visuals() -> void:
	# 1. Enclosure Background
	_bg_sprite = Sprite2D.new()
	_bg_sprite.name = "EnclosureBG"
	_bg_sprite.centered = true
	var bg_tex_key: String = "zoo_enclosure_" + animal_id.replace("zoo_", "")
	if SpriteAtlasManager.has_texture(bg_tex_key):
		_bg_sprite.texture = SpriteAtlasManager.get_texture(bg_tex_key)
	elif SpriteAtlasManager.has_texture("zoo_enclosure_capybara"):
		_bg_sprite.texture = SpriteAtlasManager.get_texture("zoo_enclosure_capybara")
	SpriteAtlasManager.set_sprite_pixel_size(_bg_sprite, Vector2(110.0, 110.0))
	_bg_sprite.position = Vector2(0.0, -6.0)
	add_child(_bg_sprite)
	
	# 2. Soft Shadow for Animal
	_shadow_poly = Polygon2D.new()
	_shadow_poly.color = Color(0.0, 0.0, 0.0, 0.28)
	var pts: PackedVector2Array = PackedVector2Array()
	var segs: int = 12
	for i in range(segs):
		var a: float = (float(i) / float(segs)) * TAU
		pts.append(Vector2(cos(a) * 14.0, sin(a) * 6.0))
	_shadow_poly.polygon = pts
	_shadow_poly.position = Vector2(0.0, 18.0)
	add_child(_shadow_poly)
	
	# 3. Animal Sprite (Chibi size 48x48)
	_animal_sprite = Sprite2D.new()
	_animal_sprite.name = "AnimalSprite"
	_animal_sprite.centered = true
	if SpriteAtlasManager.has_texture(animal_id):
		_animal_sprite.texture = SpriteAtlasManager.get_texture(animal_id)
	SpriteAtlasManager.set_sprite_pixel_size(_animal_sprite, Vector2(48.0, 48.0))
	_base_animal_scale = _animal_sprite.scale
	_animal_sprite.position = Vector2(0.0, 4.0)
	_animal_sprite.z_index = 2
	add_child(_animal_sprite)
	
	# 4. Enclosure Title
	_title_label = Label.new()
	_title_label.text = enclosure_title
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.position = Vector2(-75.0, -82.0)
	_title_label.custom_minimum_size = Vector2(150.0, 20.0)
	_title_label.add_theme_font_size_override("font_size", 11)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88))
	_title_label.add_theme_color_override("font_outline_color", Color(0.2, 0.12, 0.06))
	_title_label.add_theme_constant_override("outline_size", 4)
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title_label)
	
	# 5. Status / Food Speech Bubble
	_bubble_node = Node2D.new()
	_bubble_node.position = Vector2(26.0, -42.0)
	_bubble_node.z_index = 10
	add_child(_bubble_node)
	
	var b_panel: Panel = Panel.new()
	b_panel.custom_minimum_size = Vector2(44.0, 24.0)
	b_panel.position = Vector2(-22.0, -12.0)
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 0.98, 0.94, 0.95)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.42, 0.3, 0.2)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_bottom_left = 8
	b_panel.add_theme_stylebox_override("panel", sb)
	b_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble_node.add_child(b_panel)
	
	_bubble_label = Label.new()
	_bubble_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bubble_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bubble_label.position = Vector2(-22.0, -12.0)
	_bubble_label.custom_minimum_size = Vector2(44.0, 24.0)
	_bubble_label.add_theme_font_size_override("font_size", 13)
	_bubble_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble_node.add_child(_bubble_label)
	
	# 6. Lock Overlay Node
	_lock_overlay = Node2D.new()
	_lock_overlay.position = Vector2(0.0, 32.0)
	_lock_overlay.z_index = 8
	add_child(_lock_overlay)
	
	var lock_panel: Panel = Panel.new()
	lock_panel.custom_minimum_size = Vector2(90.0, 24.0)
	lock_panel.position = Vector2(-45.0, -12.0)
	var lsb: StyleBoxFlat = StyleBoxFlat.new()
	lsb.bg_color = Color(0.12, 0.1, 0.08, 0.90)
	lsb.border_width_left = 2
	lsb.border_width_top = 2
	lsb.border_width_right = 2
	lsb.border_width_bottom = 2
	lsb.border_color = Color(0.85, 0.65, 0.25)
	lsb.corner_radius_top_left = 8
	lsb.corner_radius_top_right = 8
	lsb.corner_radius_bottom_right = 8
	lsb.corner_radius_bottom_left = 8
	lock_panel.add_theme_stylebox_override("panel", lsb)
	lock_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lock_overlay.add_child(lock_panel)
	
	var lock_lbl: Label = Label.new()
	lock_lbl.name = "LockLabel"
	lock_lbl.text = "🔒 🧩 x%d" % unlock_pieces_cost
	lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lock_lbl.position = Vector2(-45.0, -12.0)
	lock_lbl.custom_minimum_size = Vector2(90.0, 24.0)
	lock_lbl.add_theme_font_size_override("font_size", 11)
	lock_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	lock_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lock_overlay.add_child(lock_lbl)

func _process(delta: float) -> void:
	_anim_timer += delta
	
	# Gentle idle breathing / bobbing for the animal
	if _animal_sprite != null and _animal_sprite.visible:
		var breath: float = sin(_anim_timer * 3.5) * 0.05
		_animal_sprite.scale = _base_animal_scale * Vector2(1.0, 1.0 + breath)
		_animal_sprite.position.y = 4.0 - abs(sin(_anim_timer * 2.0)) * 2.0
		
	# Float speech bubble softly
	if _bubble_node != null and _bubble_node.visible:
		_bubble_node.position.y = -42.0 + sin(_anim_timer * 4.0) * 2.5

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
		if _animal_sprite != null:
			_animal_sprite.visible = false
		if _shadow_poly != null:
			_shadow_poly.visible = false
		if _bg_sprite != null:
			_bg_sprite.modulate = Color(0.75, 0.75, 0.75, 1.0)
		return
		
	if _lock_overlay != null:
		_lock_overlay.visible = false
	if _animal_sprite != null:
		_animal_sprite.visible = true
		_animal_sprite.modulate = Color.WHITE
	if _shadow_poly != null:
		_shadow_poly.visible = true
	if _bg_sprite != null:
		_bg_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		
	if _bubble_node != null:
		_bubble_node.visible = true
		if is_fed:
			_bubble_label.text = "❤️"
		else:
			# Show icon of primary favorite food
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
		_show_floating_text("✨ %s đang no nê & tăng x2 Xu Tip!" % animal_name)
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
		_show_floating_text("❤️ Đã cho %s ăn! (+60 XP, +80 Vàng, +25 Xu)" % animal_name)
		
		# Trigger Quest Manager
		var qm: Node = get_tree().current_scene.find_child("QuestManager", true, false)
		if qm != null and qm.has_method("notify_zoo_fed"):
			qm.call("notify_zoo_fed", animal_id)
	else:
		var food_names: String = "Cỏ Dinh Dưỡng hoặc " + favorite_foods[0]
		_show_floating_text("⚠️ Thiếu thức ăn! Cần %s" % food_names)
		AudioManager.play_sfx("error")

func _play_heart_burst() -> void:
	if _animal_sprite == null:
		return
	var tw: Tween = create_tween()
	tw.tween_property(_animal_sprite, "scale", Vector2(1.25, 1.25), 0.15).set_trans(Tween.TRANS_BACK)
	tw.tween_property(_animal_sprite, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_SINE)
	
	# Spawn floating hearts
	for i in range(3):
		var heart: Label = Label.new()
		heart.text = "❤️"
		heart.add_theme_font_size_override("font_size", 14)
		heart.position = Vector2(randf_range(-15, 15), -20.0)
		add_child(heart)
		var h_tw: Tween = create_tween()
		h_tw.tween_property(heart, "position:y", heart.position.y - 35.0, 0.7).set_trans(Tween.TRANS_CUBIC)
		h_tw.parallel().tween_property(heart, "modulate:a", 0.0, 0.7)
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
		var mpos: Vector2 = get_global_mouse_position()
		if mpos.distance_to(global_position) <= 55.0:
			if not SaveManager.instant_interact:
				var p_input: Node = get_tree().current_scene.find_child("PlayerInput", true, false)
				if p_input != null:
					p_input.call("interact_with", self)
					get_viewport().set_input_as_handled()
					return
			on_player_interact(null)
			get_viewport().set_input_as_handled()
