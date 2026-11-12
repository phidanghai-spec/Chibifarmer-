extends Node2D
class_name ProductionMachine

@export var machine_id: String = "bakery" # "bakery", "feed_mill", "dairy"
@export var machine_size: Vector2 = Vector2(96.0, 96.0)

var instance_id: int = 0
var grid_pos: Vector2i = Vector2i.ZERO

# Production queue: Array of Dictionaries
var queue: Array[Dictionary] = []
var completed_items: Array[String] = []
var _completed_xp_rewards: Array[int] = []

var _sprite: Sprite2D
var _base_scale: Vector2 = Vector2.ONE
var _smoke_particles: CPUParticles2D
var _label_status: Label
var _label_title: Label
var _btn_rename: Button
var _btn_relocate: Button

func _ready() -> void:
	add_to_group("interactable")
	# 1. Machine Sprite
	_sprite = Sprite2D.new()
	if SpriteAtlasManager.has_texture(machine_id):
		_sprite.texture = SpriteAtlasManager.get_texture(machine_id)
		SpriteAtlasManager.set_sprite_pixel_size(_sprite, Vector2(90, 90))
		_base_scale = _sprite.scale
		_sprite.position = Vector2(0, -8)
		_sprite.z_index = 1
	add_child(_sprite)

	# 2. Chimney Smoke Particles
	_smoke_particles = CPUParticles2D.new()
	_smoke_particles.name = "SmokeParticles"
	_smoke_particles.emitting = false
	_smoke_particles.amount = 8
	_smoke_particles.lifetime = 1.6
	_smoke_particles.direction = Vector2(0, -1)
	_smoke_particles.spread = 24.0
	_smoke_particles.gravity = Vector2(0, -18)
	_smoke_particles.initial_velocity_min = 12.0
	_smoke_particles.initial_velocity_max = 22.0
	_smoke_particles.scale_amount_min = 2.0
	_smoke_particles.scale_amount_max = 4.0
	_smoke_particles.color = Color(1.0, 0.98, 0.94, 0.55)
	_smoke_particles.position = Vector2(16.0, -44.0)
	_smoke_particles.z_index = 3

	var grad: Gradient = Gradient.new()
	grad.colors = PackedColorArray([Color(1.0, 1.0, 1.0, 0.8), Color(1.0, 1.0, 1.0, 0.0)])
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	var grad_tex: GradientTexture2D = GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	grad_tex.fill_from = Vector2(0.5, 0.5)
	grad_tex.fill_to = Vector2(1.0, 0.5)
	grad_tex.width = 16
	grad_tex.height = 16
	_smoke_particles.texture = grad_tex
	add_child(_smoke_particles)

	# 3. Title Label & Rename Button
	_label_title = Label.new()
	_update_title_display()
	_label_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label_title.position = Vector2(-75, -92)
	_label_title.size = Vector2(130, 20)
	_label_title.clip_text = false
	_label_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label_title.add_theme_font_size_override("font_size", 11)
	_label_title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_label_title.add_theme_color_override("font_outline_color", Color(0.18, 0.10, 0.05, 1.0))
	_label_title.add_theme_constant_override("outline_size", 3)
	add_child(_label_title)

	_btn_rename = Button.new()
	_btn_rename.text = "✏️"
	_btn_rename.tooltip_text = "Đổi tên công trình"
	_btn_rename.position = Vector2(58, -94)
	_btn_rename.size = Vector2(22, 22)
	_btn_rename.custom_minimum_size = Vector2(22, 22)
	_btn_rename.mouse_filter = Control.MOUSE_FILTER_STOP
	_btn_rename.visible = false # Mặc định ẩn trong chế độ chơi bình thường để tránh rối mắt
	_btn_rename.pressed.connect(_on_rename_pressed)
	add_child(_btn_rename)

	# 3b. Relocate / Quy Hoạch button
	_btn_relocate = Button.new()
	_btn_relocate.text = "✥"
	_btn_relocate.tooltip_text = "Di chuyển / Quy hoạch công trình"
	_btn_relocate.position = Vector2(82, -94)
	_btn_relocate.size = Vector2(22, 22)
	_btn_relocate.custom_minimum_size = Vector2(22, 22)
	_btn_relocate.mouse_filter = Control.MOUSE_FILTER_STOP
	_btn_relocate.z_index = 25
	var sb_reloc: StyleBoxFlat = StyleBoxFlat.new()
	sb_reloc.bg_color = Color(0.22, 0.16, 0.10, 0.85)
	sb_reloc.border_color = Color(0.95, 0.85, 0.55, 0.9)
	sb_reloc.set_border_width_all(1)
	sb_reloc.set_corner_radius_all(5)
	_btn_relocate.add_theme_stylebox_override("normal", sb_reloc)
	_btn_relocate.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	_btn_relocate.add_theme_font_size_override("font_size", 11)
	_btn_relocate.pressed.connect(_on_relocate_pressed)
	add_child(_btn_relocate)

	# 4. Status Label raised higher above roof with crisp dark outline and bright yellow text
	_label_status = Label.new()
	_label_status.text = ""
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

func _update_title_display() -> void:
	if _label_title != null:
		var def_name: String = DataManager.get_building_name(machine_id)
		_label_title.text = SaveManager.get_building_name(machine_id, def_name)

func _on_rename_pressed() -> void:
	var farm: Node = get_tree().current_scene
	var hud: UIHud = farm.find_child("UIHud", true, false) as UIHud if farm != null else null
	if hud != null:
		var def_name: String = DataManager.get_building_name(machine_id)
		hud.open_rename_modal(machine_id, def_name, func(_new_name: String) -> void:
			_update_title_display()
		)

func _on_relocate_pressed() -> void:
	var farm: Node = get_tree().current_scene
	if farm != null and farm.has_method("start_relocating_structure"):
		farm.call("start_relocating_structure", self)

func set_rename_button_visible(v: bool) -> void:
	if _btn_rename != null:
		_btn_rename.visible = v

func set_relocate_button_visible(v: bool) -> void:
	if _btn_relocate != null:
		_btn_relocate.visible = v

func _process(_delta: float) -> void:
	if not queue.is_empty() and _sprite != null:
		if _smoke_particles != null and not _smoke_particles.emitting:
			_smoke_particles.emitting = true
		var t: float = Time.get_ticks_msec() * 0.006
		var squash: float = sin(t) * 0.045
		_sprite.scale = Vector2(_base_scale.x * (1.0 + squash * 0.6), _base_scale.y * (1.0 - squash))
		_sprite.position.x = sin(t * 1.5) * 0.6
		_sprite.position.y = -8.0 + absf(sin(t)) * 1.5
	elif _sprite != null:
		if _smoke_particles != null and _smoke_particles.emitting:
			_smoke_particles.emitting = false
		_sprite.scale = _base_scale
		_sprite.position = Vector2(0.0, -8.0)

func _on_second_ticked(_current_unix: int) -> void:
	if not queue.is_empty():
		var current_job: Dictionary = queue[0]
		var finish_ts: int = int(current_job.get("finish_timestamp", 0))
		if TickManager.is_finished(finish_ts):
			var prod_item: String = String(current_job.get("produce_item_id", ""))
			var produce_count: int = maxi(1, int(current_job.get("produce_count", 1)))
			var job_xp: int = int(current_job.get("xp_reward", 2))
			for i: int in range(produce_count):
				completed_items.append(prod_item)
				_completed_xp_rewards.append(job_xp if i == 0 else 0)
			EventBus.production_finished.emit(instance_id, String(current_job.get("recipe_id", "")))
			queue.remove_at(0)
			
			if not queue.is_empty():
				var next_job: Dictionary = queue[0]
				var rec: Dictionary = DataManager.get_recipe(String(next_job["recipe_id"]))
				var craft_time: int = int(rec.get("craft_time_seconds", 30))
				next_job["finish_timestamp"] = TickManager.calculate_finish_timestamp(craft_time)
		else:
			var remaining: int = TickManager.get_time_remaining(finish_ts)
			if _label_status != null:
				_label_status.text = "ĐANG LÀM: %s" % TickManager.format_duration(remaining)
				_label_status.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))

	if queue.is_empty() and _label_status != null:
		if not completed_items.is_empty():
			_label_status.text = "CHỜ THU (%d)" % completed_items.size()
			_label_status.add_theme_color_override("font_color", Color(1.0, 0.95, 0.3))
			_label_status.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.02, 0.95))
			_label_status.add_theme_constant_override("outline_size", 4)
		else:
			_label_status.text = ""

func handle_machine_click() -> bool:
	if not visible or (is_inside_tree() and not is_visible_in_tree()):
		return false
	if machine_id != "" and SaveManager != null and not SaveManager.is_building_constructed(machine_id):
		return false
	var farm: Node = get_tree().current_scene if is_inside_tree() else null
	var hud: UIHud = farm.find_child("UIHud", true, false) as UIHud if farm != null else null

	if not completed_items.is_empty():
		collect_all()
		_show_floating_hint("✨ Đã thu hoạch vào Kho Barn!")
	elif not queue.is_empty():
		var remaining: int = TickManager.get_time_remaining(int(queue[0].get("finish_timestamp", 0)))
		_show_floating_hint("⏳ Đang chế biến (%s)..." % TickManager.format_duration(remaining))
	elif SaveManager.is_test_mode or (SaveManager.has_method("_detect_test_mode") and SaveManager._detect_test_mode()):
		var def_item: String = ""
		if machine_id == "bakery":
			def_item = "bread"
		elif machine_id == "feed_mill":
			def_item = "cow_feed"
		elif machine_id == "dairy":
			def_item = "butter"
		elif machine_id == "cake_oven":
			def_item = "cream_cake"
		elif machine_id == "juice_stand":
			def_item = "sugarcane_juice"
		
		if def_item != "" and StorageManager.can_store_item(def_item, 1):
			var def_rec: Dictionary = DataManager.get_recipe(def_item)
			var def_xp: int = int(def_rec.get("xp_reward", 2))
			StorageManager.add_item(def_item, 1)
			StorageManager.add_xp(def_xp)
			AudioManager.play_sfx("harvest")
			EventBus.loot_collected.emit(def_item, 1, global_position)
			_spawn_local_harvest_fx(def_item)
		
		var rec_id: String = def_item
		if rec_id != "":
			var rec: Dictionary = DataManager.get_recipe(rec_id)
			var ings: Dictionary = rec.get("ingredients", {}) as Dictionary
			for ing: Variant in ings:
				if not StorageManager.has_item(String(ing), int(ings[ing])):
					StorageManager.add_item(String(ing), int(ings[ing]))
			start_recipe(rec_id)

	if hud != null:
		hud.open_production_recipe_modal(self)

	if is_inside_tree():
		var tw: Tween = create_tween()
		tw.tween_property(self, "scale", Vector2(1.08, 0.92), 0.08)
		tw.tween_property(self, "scale", Vector2.ONE, 0.1)
	return true

func speed_up_current_job() -> bool:
	if queue.is_empty():
		return false
	if not StorageManager.spend_diamonds(1):
		AudioManager.play_sfx("error")
		return false
	
	var cur_job: Dictionary = queue[0]
	var prod_item: String = String(cur_job.get("produce_item_id", ""))
	var produce_count: int = maxi(1, int(cur_job.get("produce_count", 1)))
	var job_xp: int = int(cur_job.get("xp_reward", 2))
	for i: int in range(produce_count):
		completed_items.append(prod_item)
		_completed_xp_rewards.append(job_xp if i == 0 else 0)
	EventBus.production_finished.emit(instance_id, String(cur_job.get("recipe_id", "")))
	queue.remove_at(0)
	
	if not queue.is_empty():
		var next_job: Dictionary = queue[0]
		var rec: Dictionary = DataManager.get_recipe(String(next_job["recipe_id"]))
		var craft_time: int = int(rec.get("craft_time_seconds", 30))
		next_job["finish_timestamp"] = TickManager.calculate_finish_timestamp(craft_time)
	
	AudioManager.play_sfx("coin")
	_show_floating_hint("⚡ Xong ngay! (-1 💎)")
	return true

func _show_floating_hint(hint_text: String) -> void:
	if not is_inside_tree():
		return
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
	if not is_inside_tree():
		return
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

func on_player_interact(_avatar: Node2D) -> void:
	handle_machine_click()

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not is_visible_in_tree():
		return
	if machine_id != "" and SaveManager != null and not SaveManager.is_building_constructed(machine_id):
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.is_pressed():
			var farm_node: Node = get_tree().current_scene
			var drag_mgr: DragActionManager = farm_node.find_child("DragActionManager", true, false) as DragActionManager if farm_node != null else null
			if drag_mgr != null and (drag_mgr.current_tool == DragActionManager.ToolType.DISMANTLE or int(drag_mgr.current_tool) == 9):
				return
			var mpos: Vector2 = get_global_mouse_position()
			if mpos.distance_to(global_position) <= 75.0:
				if not SaveManager.instant_interact:
					var p_input: Node = get_tree().current_scene.find_child("PlayerInput", true, false)
					if p_input != null and p_input.has_method("interact_with"):
						p_input.call("interact_with", self)
						get_viewport().set_input_as_handled()
						return
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
	
	var craft_time: int = int(rec.get("craft_time_seconds", 30))
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
	var xp_to_collect: Array[int] = _completed_xp_rewards.duplicate()
	completed_items.clear()
	_completed_xp_rewards.clear()
	var success_all: bool = true
	
	for i: int in range(items_to_collect.size()):
		var item_id: String = items_to_collect[i]
		var xp_reward: int = xp_to_collect[i] if i < xp_to_collect.size() else int(DataManager.get_recipe(item_id).get("xp_reward", 2))
		if StorageManager.can_store_item(item_id, 1):
			StorageManager.add_item(item_id, 1)
			if xp_reward > 0:
				StorageManager.add_xp(xp_reward)
			AudioManager.play_sfx("harvest")
			EventBus.production_collected.emit(instance_id, item_id)
			EventBus.loot_collected.emit(item_id, 1, global_position)
			_spawn_local_harvest_fx(item_id)
		else:
			completed_items.append(item_id)
			_completed_xp_rewards.append(xp_reward)
			success_all = false
			print("[ProductionMachine] Kho Barn đã đầy!")
			AudioManager.play_sfx("error")
	
	return success_all
