extends Node2D
class_name ProductionMachine

@export var machine_id: String = "bakery" # "bakery", "feed_mill", "dairy"
@export var machine_size: Vector2 = Vector2(96.0, 96.0)

var instance_id: int = 0
var grid_pos: Vector2i = Vector2i.ZERO

# Production queue: Array of Dictionaries
var queue: Array[Dictionary] = []
var completed_items: Array[String] = []

var _sprite: Sprite2D
var _label_status: Label

func _ready() -> void:
	# 1. Machine Sprite
	_sprite = Sprite2D.new()
	if SpriteAtlasManager.has_texture(machine_id):
		_sprite.texture = SpriteAtlasManager.get_texture(machine_id)
		SpriteAtlasManager.set_sprite_pixel_size(_sprite, Vector2(90, 90))
		_sprite.position = Vector2(0, -8)
		_sprite.z_index = 1
	add_child(_sprite)

	# 2. Status Label raised higher above roof with crisp dark outline and bright yellow text
	_label_status = Label.new()
	_label_status.text = "SẴN SÀNG"
	_label_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label_status.position = Vector2(-80, -68)
	_label_status.size = Vector2(160, 24)
	_label_status.clip_text = false
	_label_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label_status.add_theme_font_size_override("font_size", 11)
	_label_status.add_theme_color_override("font_color", Color(1.0, 0.95, 0.3))
	_label_status.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.02, 0.95))
	_label_status.add_theme_constant_override("outline_size", 4)
	add_child(_label_status)

	EventBus.second_ticked.connect(_on_second_ticked)

func _process(_delta: float) -> void:
	if not queue.is_empty() and _sprite != null:
		_sprite.position.x = sin(Time.get_ticks_msec() * 0.02) * 0.6
	elif _sprite != null:
		_sprite.position.x = 0

func _on_second_ticked(_current_unix: int) -> void:
	if not queue.is_empty():
		var current_job: Dictionary = queue[0]
		var finish_ts: int = int(current_job.get("finish_timestamp", 0))
		if TickManager.is_finished(finish_ts):
			completed_items.append(String(current_job.get("produce_item_id", "")))
			EventBus.production_finished.emit(instance_id, String(current_job.get("recipe_id", "")))
			queue.remove_at(0)
			
			if not queue.is_empty():
				var next_job: Dictionary = queue[0]
				var rec: Dictionary = DataManager.get_recipe(String(next_job["recipe_id"]))
				var craft_time: int = mini(int(rec.get("craft_time_seconds", 30)), 60)
				next_job["finish_timestamp"] = TickManager.calculate_finish_timestamp(craft_time)
		else:
			var remaining: int = TickManager.get_time_remaining(finish_ts)
			_label_status.text = "ĐANG LÀM: %s" % TickManager.format_duration(remaining)
			_label_status.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))

	if queue.is_empty():
		if not completed_items.is_empty():
			_label_status.text = "CHỜ THU (%d)" % completed_items.size()
			_label_status.add_theme_color_override("font_color", Color(1.0, 0.95, 0.3))
			_label_status.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.02, 0.95))
			_label_status.add_theme_constant_override("outline_size", 4)
		else:
			_label_status.text = "SẴN SÀNG"
			_label_status.add_theme_color_override("font_color", Color(1.0, 0.95, 0.3))
			_label_status.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.02, 0.95))
			_label_status.add_theme_constant_override("outline_size", 4)

func handle_machine_click() -> bool:
	if not completed_items.is_empty():
		var _ret: bool = collect_all()
	elif queue.is_empty():
		# If READY (SẴN SÀNG), immediately harvest primary product into Barn and start next batch
		var def_item: String = ""
		if machine_id == "bakery":
			def_item = "bread"
		elif machine_id == "feed_mill":
			def_item = "cow_feed"
		elif machine_id == "dairy":
			def_item = "butter"
		
		if def_item != "" and StorageManager.can_store_item(def_item, 1):
			StorageManager.add_item(def_item, 1)
			StorageManager.add_xp(3)
			AudioManager.play_sfx("harvest")
			EventBus.loot_collected.emit(def_item, 1, global_position)
			_spawn_local_harvest_fx(def_item)
		
		# Auto restart new batch
		var rec_id: String = def_item
		if rec_id != "":
			var rec: Dictionary = DataManager.get_recipe(rec_id)
			var ings: Dictionary = rec.get("ingredients", {}) as Dictionary
			for ing: Variant in ings:
				if not StorageManager.has_item(String(ing), int(ings[ing])):
					StorageManager.add_item(String(ing), int(ings[ing]))
			start_recipe(rec_id)
	else:
		# Machine is currently producing! Do NOT add product to inventory!
		var hint_text: String = "Đang nướng bánh..." if machine_id == "bakery" else "Đang sản xuất..."
		_show_floating_hint(hint_text)
		AudioManager.play_sfx("error")

	var tw: Tween = create_tween()
	tw.tween_property(self, "scale", Vector2(1.08, 0.92), 0.08)
	tw.tween_property(self, "scale", Vector2.ONE, 0.1)
	return true

func _show_floating_hint(hint_text: String) -> void:
	var lbl: Label = Label.new()
	lbl.text = hint_text
	lbl.position = Vector2(-50.0, -45.0)
	lbl.size = Vector2(100.0, 20.0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	lbl.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02))
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.z_index = 20
	add_child(lbl)

	var tw: Tween = create_tween()
	tw.tween_property(lbl, "position:y", -65.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.7).set_delay(0.3)
	tw.tween_callback(lbl.queue_free)

func _spawn_local_harvest_fx(item_id: String) -> void:
	# Local floating icon right above roof (Vector2(0, -30.0)) with no double offset
	var fx: Node2D = Node2D.new()
	fx.position = Vector2(0.0, -30.0)
	fx.z_index = 25

	var sp: Sprite2D = Sprite2D.new()
	if SpriteAtlasManager.has_texture(item_id):
		sp.texture = SpriteAtlasManager.get_texture(item_id)
		SpriteAtlasManager.set_sprite_pixel_size(sp, Vector2(28.0, 28.0))
	fx.add_child(sp)
	add_child(fx)

	var tw: Tween = create_tween()
	tw.tween_property(fx, "position:y", -55.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(fx, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tw.tween_callback(fx.queue_free)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.is_pressed():
			var mpos: Vector2 = get_global_mouse_position()
			if mpos.distance_to(global_position) <= 75.0:
				if handle_machine_click():
					get_viewport().set_input_as_handled()

func start_recipe(recipe_id: String) -> bool:
	var rec: Dictionary = DataManager.get_recipe(recipe_id)
	if rec.is_empty():
		return false
	
	var ings: Dictionary = rec.get("ingredients", {}) as Dictionary
	for item: Variant in ings:
		var needed: int = int(ings[item])
		if not StorageManager.has_item(String(item), needed):
			print("[ProductionMachine] Thiếu nguyên liệu: ", item)
			return false
	
	for item: Variant in ings:
		var needed: int = int(ings[item])
		StorageManager.remove_item(String(item), needed)
	
	var craft_time: int = mini(int(rec.get("craft_time_seconds", 30)), 60)
	var finish_ts: int = 0
	if queue.is_empty():
		finish_ts = TickManager.calculate_finish_timestamp(craft_time)
	
	var job: Dictionary = {
		"recipe_id": recipe_id,
		"produce_item_id": String(rec.get("produce_item_id", "")),
		"produce_count": int(rec.get("produce_count", 1)),
		"xp_reward": int(rec.get("xp_reward", 2)),
		"finish_timestamp": finish_ts
	}
	queue.append(job)
	EventBus.production_started.emit(instance_id, recipe_id, finish_ts)
	return true

func collect_all() -> bool:
	if completed_items.is_empty():
		return false
	
	var items_to_collect: Array[String] = completed_items.duplicate()
	completed_items.clear()
	var success_all: bool = true
	
	for item_id: String in items_to_collect:
		if StorageManager.can_store_item(item_id, 1):
			StorageManager.add_item(item_id, 1)
			StorageManager.add_xp(3)
			AudioManager.play_sfx("harvest")
			EventBus.production_collected.emit(instance_id, item_id)
			EventBus.loot_collected.emit(item_id, 1, global_position)
			_spawn_local_harvest_fx(item_id)
		else:
			completed_items.append(item_id)
			success_all = false
			print("[ProductionMachine] Kho Barn đã đầy!")
			AudioManager.play_sfx("error")
	
	return success_all
