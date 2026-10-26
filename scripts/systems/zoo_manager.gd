extends Node2D
class_name ZooManager

const ZooEnclosureClass = preload("res://scripts/entities/zoo_enclosure.gd")

var enclosures: Dictionary = {} # animal_id -> ZooEnclosure
var entrance_gate: Node2D = null
var feed_shop: Node2D = null
var _feed_shop_sprite: Sprite2D = null

func _ready() -> void:
	y_sort_enabled = true
	_setup_zoo_sanctuary()

func _setup_zoo_sanctuary() -> void:
	# 1. Spawn Zoo Entrance Gate / Ticket Booth on East Bank (after wooden bridge)
	if entrance_gate == null:
		entrance_gate = Node2D.new()
		entrance_gate.name = "ZooEntrance"
		entrance_gate.position = Vector2(1185.0, 440.0)
		entrance_gate.y_sort_enabled = true
		
		var sp_gate: Sprite2D = Sprite2D.new()
		sp_gate.name = "GateSprite"
		sp_gate.centered = true
		if SpriteAtlasManager.has_texture("zoo_entrance"):
			sp_gate.texture = SpriteAtlasManager.get_texture("zoo_entrance")
		SpriteAtlasManager.set_sprite_pixel_size(sp_gate, Vector2(100.0, 100.0))
		entrance_gate.add_child(sp_gate)
		
		var lbl_sign: Label = Label.new()
		lbl_sign.text = "⛩️ KHU BẢO TỒN SỞ THÚ"
		lbl_sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_sign.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_sign.position = Vector2(-75.0, -60.0)
		lbl_sign.custom_minimum_size = Vector2(150.0, 20.0)
		lbl_sign.add_theme_font_size_override("font_size", 11)
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
		feed_shop.position = Vector2(1185.0, 565.0)
		feed_shop.y_sort_enabled = true
		feed_shop.add_to_group("interactable")
		feed_shop.set_meta("interact_type", "zoo_feed_shop")
		
		_feed_shop_sprite = Sprite2D.new()
		_feed_shop_sprite.name = "ShopSprite"
		_feed_shop_sprite.centered = true
		if SpriteAtlasManager.has_texture("zoo_feed_shop"):
			_feed_shop_sprite.texture = SpriteAtlasManager.get_texture("zoo_feed_shop")
		SpriteAtlasManager.set_sprite_pixel_size(_feed_shop_sprite, Vector2(88.0, 88.0))
		feed_shop.add_child(_feed_shop_sprite)
		
		var lbl_shop: Label = Label.new()
		lbl_shop.text = "🏪 Quầy Phục Vụ Sở Thú"
		lbl_shop.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_shop.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_shop.position = Vector2(-75.0, -56.0)
		lbl_shop.custom_minimum_size = Vector2(150.0, 20.0)
		lbl_shop.add_theme_font_size_override("font_size", 10)
		lbl_shop.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
		lbl_shop.add_theme_color_override("font_outline_color", Color(0.2, 0.12, 0.05))
		lbl_shop.add_theme_constant_override("outline_size", 3)
		lbl_shop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		feed_shop.add_child(lbl_shop)
		
		# Quick interactive button for Feed Shop
		var btn_shop: Button = Button.new()
		btn_shop.flat = true
		btn_shop.custom_minimum_size = Vector2(88.0, 88.0)
		btn_shop.position = Vector2(-44.0, -44.0)
		btn_shop.pressed.connect(func() -> void:
			_on_feed_shop_clicked()
		)
		feed_shop.add_child(btn_shop)
		add_child(feed_shop)

	# 3. Spawn the 4 Sanctuary Enclosures on East Bank
	var zoo_configs: Array[Dictionary] = [
		{
			"id": "zoo_capybara",
			"name": "Capybara",
			"title": "Hồ Capybara 🍊",
			"pos": Vector2(1290.0, 195.0),
			"foods": ["carrot", "sanctuary_feed"],
			"pieces": 1,
			"gold": 200,
			"attraction": 30
		},
		{
			"id": "zoo_panda",
			"name": "Gấu Trúc",
			"title": "Rừng Trúc Gấu Trúc 🐼",
			"pos": Vector2(1450.0, 195.0),
			"foods": ["apple", "sugarcane", "sanctuary_feed"],
			"pieces": 2,
			"gold": 350,
			"attraction": 35
		},
		{
			"id": "zoo_penguin",
			"name": "Chim Cánh Cụt",
			"title": "Bờ Đá Chim Cánh Cụt 🐧",
			"pos": Vector2(1290.0, 395.0),
			"foods": ["fish_carp", "fish_bass", "sanctuary_feed"],
			"pieces": 2,
			"gold": 400,
			"attraction": 40
		},
		{
			"id": "zoo_giraffe",
			"name": "Hươu Cao Cổ",
			"title": "Thảo Nguyên Hươu Cao Cổ 🦒",
			"pos": Vector2(1450.0, 395.0),
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

	# 4. Clear any scenery overlapping with Zoo Sanctuary
	call_deferred("_clear_overlapping_scenery")

func _clear_overlapping_scenery() -> void:
	var farm: Node2D = get_tree().current_scene as Node2D
	if farm != null:
		var sc_container: Node2D = farm.get("_scenery_container") as Node2D
		var zoo_rect: Rect2 = Rect2(780.0, 120.0, 800.0, 560.0)
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
	for a_id: String in enclosures:
		if SaveManager.is_animal_unlocked(a_id):
			var enc: ZooEnclosure = enclosures[a_id]
			var bonus: int = enc.base_attraction
			if SaveManager.is_animal_fed(a_id):
				bonus *= 2 # Doubled attraction when fed!
			total += bonus
	return total
