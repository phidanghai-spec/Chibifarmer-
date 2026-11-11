class_name OnboardingDirector
extends Node

## OnboardingDirector
## Điều phối hoạt cảnh mở đầu Tàu hơi nước cập bến, Hướng dẫn tân thủ 3 bước tương tác
## và kích hoạt Báo cáo Lợi nhuận Vắng nhà.
## 100% Static Typing GDScript 2.0.

enum Step {
	NONE,
	INTRO_STEAMBOAT,
	STEP_1_SWIPE_WHEAT,
	STEP_2_MILL_AND_FEED,
	STEP_3_PATH_AND_VISITOR,
	COMPLETED
}

@export var steamboat_node: Node2D
@export var poodle_node: Node2D
@export var player_avatar: Node2D
@export var camera_node: Camera2D

@export var first_field_plot_pos: Vector2 = Vector2(400.0, 560.0)
@export var feed_mill_pos: Vector2 = Vector2(720.0, 460.0)
@export var road_path_pos: Vector2 = Vector2(460.0, 420.0)

var tutorial_overlay: Control = null
var dialogue_label: Label = null
var hand_pointer: Sprite2D = null
var step_label: Label = null
var elder_portrait: TextureRect = null

var current_step: Step = Step.NONE
var _anim_time: float = 0.0
var _pointer_world_target: Vector2 = Vector2.ZERO
var _harvested_count: int = 0
var _planted_count: int = 0
var _initial_dock_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	_resolve_ui_nodes()
	_resolve_world_positions()
	if tutorial_overlay != null:
		tutorial_overlay.visible = false
	_connect_gameplay_events()
	
	# Khởi động dựa trên trạng thái save hiện tại
	call_deferred("_auto_start_from_save")

func _resolve_ui_nodes() -> void:
	tutorial_overlay = get_node_or_null("../UILayer/TutorialOverlay") as Control
	if tutorial_overlay == null:
		tutorial_overlay = get_node_or_null("TutorialOverlay") as Control
		
	if tutorial_overlay != null:
		tutorial_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dialogue_label = tutorial_overlay.find_child("GuideDialogueLabel", true, false) as Label
		hand_pointer = tutorial_overlay.find_child("HandPointerSprite", true, false) as Sprite2D
		step_label = tutorial_overlay.find_child("StepProgressLabel", true, false) as Label
		elder_portrait = tutorial_overlay.find_child("ElderPortrait", true, false) as TextureRect

		if elder_portrait != null and SpriteAtlasManager != null:
			var p_tex: Texture2D = SpriteAtlasManager.get_texture("npc_elder_portrait")
			if p_tex != null:
				elder_portrait.texture = p_tex

		if hand_pointer != null and SpriteAtlasManager != null:
			var ptr_tex: Texture2D = SpriteAtlasManager.get_texture("ui_hand_pointer_chibi")
			if ptr_tex != null:
				hand_pointer.texture = ptr_tex

func _resolve_world_positions() -> void:
	# Tìm vị trí thực tế của ô ruộng đầu tiên trên bản đồ nếu có
	var plots_container: Node2D = get_node_or_null("../PlotsContainer") as Node2D
	if plots_container != null and plots_container.get_child_count() > 0:
		var first_plot: Node2D = plots_container.get_child(0) as Node2D
		if first_plot != null:
			first_field_plot_pos = first_plot.global_position

	# Tìm vị trí máy xay cám nếu có
	var buildings_container: Node2D = get_node_or_null("../BuildingsContainer") as Node2D
	if buildings_container != null:
		for b: Node in buildings_container.get_children():
			if "feed_mill" in b.name.to_lower():
				var b_node: Node2D = b as Node2D
				if b_node != null:
					feed_mill_pos = b_node.global_position
					break

func _auto_start_from_save() -> void:
	if steamboat_node == null:
		steamboat_node = get_node_or_null("../RiverSteamboat") as Node2D
		if steamboat_node == null:
			steamboat_node = get_node_or_null("../BuildingsContainer/RiverSteamboat") as Node2D
	if poodle_node == null:
		poodle_node = get_node_or_null("../PetPoodle") as Node2D
	if camera_node == null:
		camera_node = get_node_or_null("../Camera2D") as Camera2D

	var save_data: Dictionary = {}
	if SaveManager != null and SaveManager.has_method("get_current_slot_data"):
		save_data = SaveManager.get_current_slot_data()
	start_for_slot(save_data)

func _process(delta: float) -> void:
	if current_step == Step.NONE or current_step == Step.COMPLETED:
		return
	_anim_time += delta
	_animate_hand_pointer()

func start_for_slot(save_data: Dictionary) -> void:
	var is_done: bool = bool(save_data.get("is_tutorial_completed", false))
	if not is_done:
		_play_steamboat_intro()
	else:
		current_step = Step.COMPLETED
		var report: Dictionary = OfflineSimulator.evaluate_offline_progress(save_data)
		if not report.is_empty():
			EventBus.offline_earnings_calculated.emit(int(report["elapsed_seconds"]), report)

func _play_steamboat_intro() -> void:
	current_step = Step.INTRO_STEAMBOAT
	EventBus.intro_cutscene_started.emit()
	
	if tutorial_overlay != null:
		tutorial_overlay.visible = true
	if hand_pointer != null:
		hand_pointer.visible = false
	if step_label != null:
		step_label.text = "Chào Mừng Đến Nông Trại Chibi!"
	if dialogue_label != null:
		dialogue_label.text = "Tàu hơi nước đã cập bến sông! Chú chó Poodle đang vẫy đuôi chờ bạn bên cầu gỗ kìa!"

	AudioManager.play_sfx("steamboat_whistle")

	if steamboat_node != null:
		_initial_dock_pos = steamboat_node.position
		steamboat_node.position = _initial_dock_pos + Vector2(0.0, -260.0)
		
		# Camera tập trung nhìn ra bến sông
		if camera_node != null:
			var cam_tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			cam_tween.tween_property(camera_node, "position", _initial_dock_pos, 2.0)
		
		# Poodle sủa mừng và nhảy tung tăng bên cầu
		if poodle_node != null:
			var poodle_tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			poodle_tween.tween_property(poodle_node, "scale", Vector2(1.25, 0.8), 0.2)
			poodle_tween.tween_property(poodle_node, "scale", Vector2.ONE, 0.2)
		
		var boat_tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		boat_tween.tween_property(steamboat_node, "position", _initial_dock_pos, 2.4)
		boat_tween.tween_callback(func() -> void:
			EventBus.intro_cutscene_finished.emit()
			_advance_to_step(Step.STEP_1_SWIPE_WHEAT)
		)
	else:
		_advance_to_step(Step.STEP_1_SWIPE_WHEAT)

func _advance_to_step(next_step: Step) -> void:
	current_step = next_step
	if tutorial_overlay != null:
		tutorial_overlay.visible = (current_step != Step.COMPLETED)
	if hand_pointer != null:
		hand_pointer.visible = (current_step != Step.COMPLETED and current_step != Step.NONE)

	match current_step:
		Step.STEP_1_SWIPE_WHEAT:
			_pointer_world_target = first_field_plot_pos
			if step_label != null:
				step_label.text = "Bước 1/3: Gặt Lúa & Gieo Hạt"
			if dialogue_label != null:
				dialogue_label.text = "Hãy nhấn giữ và kéo-lướt chuột (Drag-and-Swipe) qua ô ruộng để gặt Lúa mì chín vàng và gieo hạt mới!"
			_pan_camera_to_target(first_field_plot_pos)
			EventBus.tutorial_step_changed.emit(1, dialogue_label.text if dialogue_label != null else "", first_field_plot_pos)
			AudioManager.play_sfx("welcome_chime")
			
		Step.STEP_2_MILL_AND_FEED:
			_pointer_world_target = feed_mill_pos
			if step_label != null:
				step_label.text = "Bước 2/3: Xay Cám & Chăn Nuôi"
			if dialogue_label != null:
				dialogue_label.text = "Tuyệt lắm! Giờ hãy đưa Lúa mì vào Máy Xay Cám và cho đàn thú trong chuồng ăn nhé!"
			_pan_camera_to_target(feed_mill_pos)
			EventBus.tutorial_step_changed.emit(2, dialogue_label.text if dialogue_label != null else "", feed_mill_pos)
			AudioManager.play_sfx("welcome_chime")
			
		Step.STEP_3_PATH_AND_VISITOR:
			_pointer_world_target = road_path_pos
			if step_label != null:
				step_label.text = "Bước 3/3: Mở Đường Đón Du Khách"
			if dialogue_label != null:
				dialogue_label.text = "Hãy lát một ô đường đá sỏi để tăng điểm AttractionScore, thu hút đoàn du khách Chibi ghé thăm!"
			_pan_camera_to_target(road_path_pos)
			EventBus.tutorial_step_changed.emit(3, dialogue_label.text if dialogue_label != null else "", road_path_pos)
			AudioManager.play_sfx("welcome_chime")
			
		Step.COMPLETED:
			if tutorial_overlay != null:
				tutorial_overlay.visible = false
			if hand_pointer != null:
				hand_pointer.visible = false
			if SaveManager != null:
				SaveManager.set_tutorial_completed(true)
			EventBus.tutorial_completed.emit()
			AudioManager.play_sfx("coins_jingle")

func _pan_camera_to_target(target_world: Vector2) -> void:
	if camera_node != null:
		var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(camera_node, "position", target_world, 1.2)

func _animate_hand_pointer() -> void:
	if hand_pointer == null or not hand_pointer.visible:
		return
		
	# Chuyển đổi tọa độ thế giới sang tọa độ CanvasLayer màn hình
	var screen_origin: Vector2 = _pointer_world_target
	if camera_node != null:
		screen_origin = camera_node.get_canvas_transform() * _pointer_world_target
	elif get_viewport() != null:
		screen_origin = get_viewport().get_canvas_transform() * _pointer_world_target
		
	var swipe_offset: Vector2 = Vector2(sin(_anim_time * 3.5) * 28.0, cos(_anim_time * 7.0) * 8.0) + Vector2(24.0, 28.0)
	hand_pointer.position = screen_origin + swipe_offset
	var pulse: float = 1.0 + sin(_anim_time * 6.0) * 0.08
	hand_pointer.scale = Vector2(pulse, pulse)

func _connect_gameplay_events() -> void:
	EventBus.crop_harvested.connect(func(_crop_id: String, _pos: Vector2i) -> void:
		if current_step == Step.STEP_1_SWIPE_WHEAT:
			_harvested_count += 1
			_check_step_1_completion()
	)
	EventBus.field_harvested.connect(func(_inst_id: int, _crop_id: String) -> void:
		if current_step == Step.STEP_1_SWIPE_WHEAT:
			_harvested_count += 1
			_check_step_1_completion()
	)
	EventBus.crop_planted.connect(func(_crop_id: String, _pos: Vector2i) -> void:
		if current_step == Step.STEP_1_SWIPE_WHEAT:
			_planted_count += 1
			_check_step_1_completion()
	)
	EventBus.field_planted.connect(func(_inst_id: int, _crop_id: String, _finish: int) -> void:
		if current_step == Step.STEP_1_SWIPE_WHEAT:
			_planted_count += 1
			_check_step_1_completion()
	)
	EventBus.animal_fed.connect(func(_a: Variant, _b: Variant, _c: Variant = 0) -> void:
		if current_step == Step.STEP_2_MILL_AND_FEED:
			_advance_to_step(Step.STEP_3_PATH_AND_VISITOR)
	)
	EventBus.decor_placed.connect(func(_decor_id: String, _attraction_delta: int) -> void:
		if current_step == Step.STEP_3_PATH_AND_VISITOR:
			_advance_to_step(Step.COMPLETED)
	)
	EventBus.path_tile_changed.connect(func(_pos: Vector2i, is_path: bool) -> void:
		if is_path and current_step == Step.STEP_3_PATH_AND_VISITOR:
			_advance_to_step(Step.COMPLETED)
	)

func _check_step_1_completion() -> void:
	if _harvested_count >= 1 and _planted_count >= 1:
		_advance_to_step(Step.STEP_2_MILL_AND_FEED)

