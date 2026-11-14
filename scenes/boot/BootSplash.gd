class_name BootSplash
extends Control

const TITLE_SCENE_PATH: String = "res://scenes/ui/TitleScreen.tscn"

@onready var windmill_blades: Sprite2D = $CenterStage/WindmillBlades
@onready var status_label: Label = $LoadingBarContainer/StatusLabel
@onready var progress_bar: ProgressBar = $LoadingBarContainer/WoodProgressBar
@onready var fade_overlay: ColorRect = $FadeOverlay

@onready var clouds_root: Node2D = $Scenery/Clouds
@onready var doves_root: Node2D = $Scenery/Doves
@onready var trees_root: Node2D = $Scenery/Trees
@onready var wheat_root: Node2D = $Scenery/WheatField

var _anim_time: float = 0.0
var _load_step: int = 0
var _step_timer: float = 0.0
var _is_transitioning: bool = false

var _wheat_nodes: Array[Sprite2D] = []
var _tree_nodes: Array[Sprite2D] = []
var _cloud_nodes: Array[Sprite2D] = []
var _dove_nodes: Array[Sprite2D] = []
var _dove_base_y: Array[float] = []

func _ready() -> void:
	if DisplayServer.get_name() != "headless":
		ResourceLoader.load_threaded_request(TITLE_SCENE_PATH)
	SaveSlotService.ensure_save_directory()
	progress_bar.value = 0.0
	status_label.text = "Đang nạp dữ liệu nông trại..."
	fade_overlay.modulate.a = 0.0
	_cache_animated_nodes()

func _cache_animated_nodes() -> void:
	if wheat_root != null:
		for child: Node in wheat_root.get_children():
			if child is Sprite2D:
				_wheat_nodes.append(child as Sprite2D)
				
	if trees_root != null:
		for child: Node in trees_root.get_children():
			if child is Sprite2D:
				_tree_nodes.append(child as Sprite2D)
				
	if clouds_root != null:
		for child: Node in clouds_root.get_children():
			if child is Sprite2D:
				_cloud_nodes.append(child as Sprite2D)
				
	if doves_root != null:
		for child: Node in doves_root.get_children():
			if child is Sprite2D:
				var sp: Sprite2D = child as Sprite2D
				_dove_nodes.append(sp)
				_dove_base_y.append(sp.position.y)

func _process(delta: float) -> void:
	_anim_time += delta
	_animate_scenery(delta)
	
	if _is_transitioning:
		return
		
	_step_timer += delta
	if _step_timer >= 0.08:
		_step_timer = 0.0
		_execute_preload_step()

func _animate_scenery(delta: float) -> void:
	# 1. Cối xay gió quay cánh quạt
	if windmill_blades != null:
		windmill_blades.rotation += 1.8 * delta
		
	# 2. Mây trôi nhẹ nhàng trên bầu trời
	for cloud: Sprite2D in _cloud_nodes:
		cloud.position.x += 16.0 * delta
		if cloud.position.x > 1250.0:
			cloud.position.x = -150.0
			
	# 3. Đàn chim bồ câu bay lượn dập dờn
	var dove_count: int = _dove_nodes.size()
	for i: int in range(dove_count):
		var dove: Sprite2D = _dove_nodes[i]
		var base_y: float = _dove_base_y[i]
		dove.position.x += 38.0 * delta
		dove.position.y = base_y + sin(_anim_time * 4.5 + float(i) * 1.5) * 6.0
		if dove.position.x > 1250.0:
			dove.position.x = -80.0
			
	# 4. Hàng cây đung đưa theo gió
	var tree_count: int = _tree_nodes.size()
	for i: int in range(tree_count):
		var tree: Sprite2D = _tree_nodes[i]
		tree.rotation = sin(_anim_time * 1.8 + float(i) * 1.4) * 0.025
		
	# 5. Cánh đồng lúa mì vàng óng đung đưa theo làn gió
	var wheat_count: int = _wheat_nodes.size()
	for i: int in range(wheat_count):
		var wheat: Sprite2D = _wheat_nodes[i]
		var wave: float = sin(_anim_time * 3.5 + float(i) * 0.45)
		wheat.rotation = wave * 0.12
		wheat.scale.y = 0.90 + wave * 0.03

func _execute_preload_step() -> void:
	_load_step += 1
	match _load_step:
		1:
			status_label.text = "Đang nạp dữ liệu hạt giống & mùa màng..."
			progress_bar.value = 35.0
			EventBus.boot_preload_progress.emit(35.0, status_label.text)
		2:
			status_label.text = "Đang nạp dữ liệu nông trại..."
			progress_bar.value = 75.0
			EventBus.boot_preload_progress.emit(75.0, status_label.text)
		3:
			status_label.text = "Đồng bộ thời gian & sẵn sàng khởi hành..."
			progress_bar.value = 100.0
			EventBus.boot_preload_progress.emit(100.0, status_label.text)
			EventBus.boot_preload_completed.emit()
			_transition_to_title()

func _transition_to_title() -> void:
	_is_transitioning = true
	var tween: Tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, 0.15)
	tween.tween_callback(func() -> void:
		if ResourceLoader.load_threaded_get_status(TITLE_SCENE_PATH) == ResourceLoader.THREAD_LOAD_LOADED:
			get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(TITLE_SCENE_PATH) as PackedScene)
		else:
			get_tree().change_scene_to_file(TITLE_SCENE_PATH)
	)
