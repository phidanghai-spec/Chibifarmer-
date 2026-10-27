# scripts/systems/zoo_manager.gd
# Connected Zoo Park Sanctuary on East Bank with Enclosures & Hot Air Balloon Centerpiece
extends Node2D
class_name ZooManager

const ZooEnclosureClass = preload("res://scripts/entities/zoo_enclosure.gd")

var enclosures: Dictionary = {} # animal_id -> ZooEnclosure
var entrance_gate: Node2D = null
var feed_shop: Node2D = null
var hot_air_balloon: Node2D = null

var _feed_shop_sprite: Sprite2D = null
var _balloon_sprite: Sprite2D = null
var _balloon_shadow: Polygon2D = null
var _timer: float = 0.0
var _is_flying_tour: bool = false

func _ready() -> void:
	y_sort_enabled = true
	_setup_zoo_sanctuary()

func _draw() -> void:
	# Draw Sand Pathways linking the Zoo Park Plaza
	var sand_color: Color = Color(0.88, 0.78, 0.58, 0.95) # Warm sand path
	var sand_border: Color = Color(0.74, 0.62, 0.42, 0.95)
	
	# Central East-West Avenue from East bank promenade edge (x: 1136) to east edge (x: 1730)
	var h_path: Rect2 = Rect2(1136.0, 285.0, 594.0, 50.0)
	draw_rect(h_path, sand_color, true)
	draw_line(Vector2(1136.0, 285.0), Vector2(1730.0, 285.0), sand_border, 2.0)
	draw_line(Vector2(1136.0, 335.0), Vector2(1730.0, 335.0), sand_border, 2.0)
	
	# Entrance Plaza connector to Feed Shop (x: 1136 to 1176, y: 310 to 455)
	var shop_path: Rect2 = Rect2(1136.0, 310.0, 42.0, 145.0)
	draw_rect(shop_path, sand_color, true)
	draw_line(Vector2(1178.0, 335.0), Vector2(1178.0, 455.0), sand_border, 2.0)
	draw_line(Vector2(1136.0, 455.0), Vector2(1178.0, 455.0), sand_border, 2.0)
	
	# Central North-South Avenue between enclosures (x: 1450 to 1500)
	var v_path: Rect2 = Rect2(1450.0, 135.0, 50.0, 350.0)
	draw_rect(v_path, sand_color, true)
	draw_line(Vector2(1450.0, 135.0), Vector2(1450.0, 485.0), sand_border, 2.0)
	draw_line(Vector2(1500.0, 135.0), Vector2(1500.0, 485.0), sand_border, 2.0)
	
	# Central Plaza Circle for Hot Air Balloon
	draw_circle(Vector2(1475.0, 310.0), 40.0, sand_color)
	draw_arc(Vector2(1475.0, 310.0), 40.0, 0.0, TAU, 32, sand_border, 2.0)

func _process(delta: float) -> void:
	_timer += delta
	# Hot Air Balloon gentle floating bob
	if not _is_flying_tour and _balloon_sprite != null:
		var float_y: float = sin(_timer * 2.2) * 7.5
		_balloon_sprite.position.y = -40.0 + float_y
		if _balloon_shadow != null:
			var s_scale: float = 1.0 - (float_y / 40.0) * 0.15
			_balloon_shadow.scale = Vector2(s_scale, s_scale)

func _setup_zoo_sanctuary() -> void:
	# 1. Spawn Zoo Entrance Gate / Ticket Booth
	if entrance_gate == null:
		entrance_gate = Node2D.new()
		entrance_gate.name = "ZooEntrance"
		entrance_gate.position = Vector2(1155.0, 310.0)
		entrance_gate.y_sort_enabled = true
		
		var sp_gate: Sprite2D = Sprite2D.new()
		sp_gate.name = "GateSprite"
		sp_gate.centered = true
		if SpriteAtlasManager.has_texture("zoo_entrance"):
			sp_gate.texture = SpriteAtlasManager.get_texture("zoo_entrance")
		SpriteAtlasManager.set_sprite_pixel_size(sp_gate, Vector2(84.0, 84.0))
		entrance_gate.add_child(sp_gate)
		
		var lbl_sign: Label = Label.new()
		lbl_sign.text = "⛩️ CỔNG SỞ THÚ BỜ ĐÔNG"
		lbl_sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_sign.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_sign.position = Vector2(-75.0, -52.0)
		lbl_sign.custom_minimum_size = Vector2(150.0, 20.0)
		lbl_sign.add_theme_font_size_override("font_size", 10)
		lbl_sign.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
		lbl_sign.add_theme_color_override("font_outline_color", Color(0.2, 0.12, 0.05))
		lbl_sign.add_theme_constant_override("outline_size", 4)
		lbl_sign.mouse_filter = Control.MOUSE_FILTER_IGNORE
		entrance_gate.add_child(lbl_sign)
		
		entrance_gate.set_meta("interact_type", "zoo_entrance")
		add_child(entrance_gate)

	# 2. Spawn Zoo Feed Shop (Quầy Phục Vụ Sở Thú)
	if feed_shop == null:
		feed_shop = Node2D.new()
		feed_shop.name = "ZooFeedShop"
		feed_shop.position = Vector2(1155.0, 430.0)
		feed_shop.y_sort_enabled = true
		feed_shop.add_to_group("interactable")
		feed_shop.set_meta("interact_type", "zoo_feed_shop")
		
		_feed_shop_sprite = Sprite2D.new()
		_feed_shop_sprite.name = "ShopSprite"
		_feed_shop_sprite.centered = true
		if SpriteAtlasManager.has_texture("zoo_feed_shop"):
			_feed_shop_sprite.texture = SpriteAtlasManager.get_texture("zoo_feed_shop")
		SpriteAtlasManager.set_sprite_pixel_size(_feed_shop_sprite, Vector2(80.0, 80.0))
		feed_shop.add_child(_feed_shop_sprite)
		
		var lbl_shop: Label = Label.new()
		lbl_shop.text = "🏪 Quầy Phục Vụ"
		lbl_shop.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_shop.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_shop.position = Vector2(-60.0, -50.0)
		lbl_shop.custom_minimum_size = Vector2(120.0, 18.0)
		lbl_shop.add_theme_font_size_override("font_size", 10)
		lbl_shop.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
		lbl_shop.add_theme_color_override("font_outline_color", Color(0.2, 0.12, 0.05))
		lbl_shop.add_theme_constant_override("outline_size", 3)
		lbl_shop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		feed_shop.add_child(lbl_shop)
		
		var btn_shop: Button = Button.new()
		btn_shop.flat = true
		btn_shop.custom_minimum_size = Vector2(80.0, 80.0)
		btn_shop.position = Vector2(-40.0, -40.0)
		btn_shop.pressed.connect(func() -> void:
			_on_feed_shop_clicked()
		)
		feed_shop.add_child(btn_shop)
		add_child(feed_shop)

	# 3. Centerpiece: Hot Air Balloon (Khinh Khí Cầu Rực Rỡ)
	if hot_air_balloon == null:
		hot_air_balloon = Node2D.new()
		hot_air_balloon.name = "HotAirBalloon"
		hot_air_balloon.position = Vector2(1475.0, 310.0)
		hot_air_balloon.y_sort_enabled = true
		hot_air_balloon.add_to_group("interactable")
		
		# Ground shadow
		_balloon_shadow = Polygon2D.new()
		_balloon_shadow.color = Color(0.0, 0.0, 0.0, 0.3)
		var pts: PackedVector2Array = PackedVector2Array()
		var segs: int = 16
		for s in range(segs):
			var a: float = (float(s) / float(segs)) * TAU
			pts.append(Vector2(cos(a) * 26.0, sin(a) * 12.0))
		_balloon_shadow.polygon = pts
		_balloon_shadow.position = Vector2(0.0, 14.0)
		_balloon_shadow.z_index = -1
		hot_air_balloon.add_child(_balloon_shadow)
		
		# Balloon Sprite
		_balloon_sprite = Sprite2D.new()
		_balloon_sprite.centered = true
		if SpriteAtlasManager.has_texture("hot_air_balloon"):
			_balloon_sprite.texture = SpriteAtlasManager.get_texture("hot_air_balloon")
		SpriteAtlasManager.set_sprite_pixel_size(_balloon_sprite, Vector2(88.0, 100.0))
		_balloon_sprite.position = Vector2(0.0, -40.0)
		hot_air_balloon.add_child(_balloon_sprite)
		
		# Balloon Label
		var lbl_b: Label = Label.new()
		lbl_b.text = "🎈 Khinh Khí Cầu"
		lbl_b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_b.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_b.position = Vector2(-60.0, 18.0)
		lbl_b.custom_minimum_size = Vector2(120.0, 20.0)
		lbl_b.add_theme_font_size_override("font_size", 10)
		lbl_b.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))
		lbl_b.add_theme_color_override("font_outline_color", Color(0.15, 0.1, 0.05))
		lbl_b.add_theme_constant_override("outline_size", 3)
		lbl_b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hot_air_balloon.add_child(lbl_b)
		
		# Button click on Balloon
		var btn_b: Button = Button.new()
		btn_b.flat = true
		btn_b.custom_minimum_size = Vector2(80.0, 100.0)
		btn_b.position = Vector2(-40.0, -90.0)
		btn_b.pressed.connect(_on_balloon_clicked)
		hot_air_balloon.add_child(btn_b)
		
		add_child(hot_air_balloon)

	# 4. Spawn the 4 Large Sanctuary Enclosures in a 2x2 Connected Park
	var zoo_configs: Array[Dictionary] = [
		{
			"id": "zoo_capybara",
			"name": "Capybara",
			"title": "Hồ Capybara 🍊",
			"pos": Vector2(1340.0, 210.0),
			"foods": ["carrot", "sanctuary_feed"],
			"pieces": 1,
			"gold": 200,
			"attraction": 30
		},
		{
			"id": "zoo_panda",
			"name": "Gấu Trúc",
			"title": "Rừng Trúc Gấu Trúc 🐼",
			"pos": Vector2(1610.0, 210.0),
			"foods": ["apple", "sugarcane", "sanctuary_feed"],
			"pieces": 2,
			"gold": 350,
			"attraction": 35
		},
		{
			"id": "zoo_penguin",
			"name": "Chim Cánh Cụt",
			"title": "Bờ Đá Chim Cánh Cụt 🐧",
			"pos": Vector2(1340.0, 410.0),
			"foods": ["fish_carp", "fish_bass", "sanctuary_feed"],
			"pieces": 2,
			"gold": 400,
			"attraction": 40
		},
		{
			"id": "zoo_giraffe",
			"name": "Hươu Cao Cổ",
			"title": "Thảo Nguyên Hươu Cao Cổ 🦒",
			"pos": Vector2(1610.0, 410.0),
			"foods": ["wheat", "sanctuary_feed"],
			"pieces": 3,
			"gold": 500,
			"attraction": 45
		}
	]

	for cfg: Dictionary in zoo_configs:
		var a_id: String = cfg["id"]
		if not enclosures.has(a_id):
			var enc: ZooEnclosure = ZooEnclosureClass.new()
			enc.name = "Enclosure_" + a_id
			enc.animal_id = a_id
			enc.animal_name = cfg["name"]
			enc.enclosure_title = cfg["title"]
			enc.position = cfg["pos"]
			var f_list: Array[String] = []
			for f_item in cfg["foods"]:
				f_list.append(String(f_item))
			enc.favorite_foods = f_list
			enc.unlock_pieces_cost = cfg["pieces"]
			enc.unlock_gold_cost = cfg["gold"]
			enc.base_attraction = cfg["attraction"]
			add_child(enc)
			enclosures[a_id] = enc

	call_deferred("_clear_overlapping_scenery")

func _on_balloon_clicked() -> void:
	AudioManager.play_sfx("click")
	var farm: Node2D = get_tree().current_scene as Node2D
	var hud: UIHud = null
	if farm != null and farm.get("ui_hud") != null:
		hud = farm.get("ui_hud") as UIHud
	if hud != null:
		hud.open_hot_air_balloon_modal()

func fly_balloon_tour(on_finish: Callable) -> void:
	if _is_flying_tour or _balloon_sprite == null:
		if on_finish.is_valid():
			on_finish.call()
		return
	_is_flying_tour = true
	var orig_y: float = -40.0
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(_balloon_sprite, "position:y", -220.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_balloon_sprite, "scale", _balloon_sprite.scale * 1.15, 1.2)
	if _balloon_shadow != null:
		tw.tween_property(_balloon_shadow, "scale", Vector2(0.4, 0.4), 1.2)
	
	await tw.finished
	await get_tree().create_timer(0.3).timeout
	
	var tw_down: Tween = create_tween().set_parallel(true)
	tw_down.tween_property(_balloon_sprite, "position:y", orig_y, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw_down.tween_property(_balloon_sprite, "scale", _balloon_sprite.scale / 1.15, 1.0)
	if _balloon_shadow != null:
		tw_down.tween_property(_balloon_shadow, "scale", Vector2.ONE, 1.0)
	
	await tw_down.finished
	_is_flying_tour = false
	if on_finish.is_valid():
		on_finish.call()

func _clear_overlapping_scenery() -> void:
	var farm: Node2D = get_tree().current_scene as Node2D
	if farm != null:
		var sc_container: Node2D = farm.get("_scenery_container") as Node2D
		var zoo_rect: Rect2 = Rect2(1130.0, 90.0, 485.0, 430.0)
		if sc_container != null:
			for elem: Node in sc_container.get_children():
				if elem is Node2D and zoo_rect.has_point((elem as Node2D).global_position):
					elem.queue_free()

func _on_feed_shop_clicked() -> void:
	AudioManager.play_sfx("click")
	var farm: Node2D = get_tree().current_scene as Node2D
	var hud: UIHud = null
	if farm != null and farm.get("ui_hud") != null:
		hud = farm.get("ui_hud") as UIHud
	if hud != null:
		hud.open_zoo_feed_shop_modal()

func get_unlocked_enclosures() -> Array[ZooEnclosure]:
	var result: Array[ZooEnclosure] = []
	for a_id: String in enclosures:
		if SaveManager.is_animal_unlocked(a_id):
			result.append(enclosures[a_id])
	return result

func get_random_unlocked_enclosure() -> ZooEnclosure:
	var unlocked: Array[ZooEnclosure] = get_unlocked_enclosures()
	if unlocked.is_empty():
		return null
	return unlocked.pick_random()

func get_enclosure(animal_id: String) -> ZooEnclosure:
	return enclosures.get(animal_id, null) as ZooEnclosure

func get_total_attraction_score() -> int:
	var total: int = 15 # Base zoo entrance
	total += SaveManager.balloon_level * 10 # Balloon upgrade bonus (+10 per level)
	for a_id: String in enclosures:
		if SaveManager.is_animal_unlocked(a_id):
			var enc: ZooEnclosure = enclosures[a_id]
			var bonus: int = enc.base_attraction
			if SaveManager.is_animal_fed(a_id):
				bonus *= 2 # Doubled attraction when fed!
			total += bonus
	return total
