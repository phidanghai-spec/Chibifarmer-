class_name BootSplash
extends Control

const TITLE_SCENE_PATH: String = "res://scenes/ui/TitleScreen.tscn"

@onready var windmill_blades: Sprite2D = $CenterStage/WindmillBlades
@onready var wheat_icon: Sprite2D = $CenterStage/ChibiWheatIcon
@onready var status_label: Label = $LoadingBarContainer/StatusLabel
@onready var progress_bar: ProgressBar = $LoadingBarContainer/WoodProgressBar
@onready var fade_overlay: ColorRect = $FadeOverlay

var _anim_time: float = 0.0
var _load_step: int = 0
var _step_timer: float = 0.0
var _is_transitioning: bool = false

func _ready() -> void:
	SaveSlotService.ensure_save_directory()
	progress_bar.value = 0.0
	status_label.text = "Đang đánh thức nông trại Chibi..."
	fade_overlay.modulate.a = 0.0

func _process(delta: float) -> void:
	_anim_time += delta
	_animate_chibi_logo(delta)
	
	if _is_transitioning:
		return
		
	_step_timer += delta
	if _step_timer >= 0.35:
		_step_timer = 0.0
		_execute_preload_step()

func _animate_chibi_logo(delta: float) -> void:
	if windmill_blades != null:
		windmill_blades.rotation += 1.8 * delta
	if wheat_icon != null:
		var sway: float = sin(_anim_time * 4.5) * 0.08
		wheat_icon.rotation = sway
		var breath: float = sin(_anim_time * 3.0) * 0.04
		wheat_icon.scale = Vector2(1.0 - breath * 0.5, 1.0 + breath)

func _execute_preload_step() -> void:
	_load_step += 1
	match _load_step:
		1:
			status_label.text = "Đang nạp dữ liệu hạt giống & công thức (DataManager)..."
			progress_bar.value = 35.0
			EventBus.boot_preload_progress.emit(35.0, status_label.text)
		2:
			status_label.text = "Đang đăng ký Sprite Atlas 2.5D (SpriteAtlasManager)..."
			progress_bar.value = 75.0
			EventBus.boot_preload_progress.emit(75.0, status_label.text)
		3:
			status_label.text = "Đồng bộ thời gian thực (TickManager)..."
			progress_bar.value = 100.0
			EventBus.boot_preload_progress.emit(100.0, status_label.text)
			EventBus.boot_preload_completed.emit()
			_transition_to_title()

func _transition_to_title() -> void:
	_is_transitioning = true
	var tween: Tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, 0.4)
	tween.tween_callback(func() -> void:
		get_tree().change_scene_to_file(TITLE_SCENE_PATH)
	)

