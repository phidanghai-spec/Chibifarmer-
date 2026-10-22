extends Camera2D
class_name CameraController

@export var zoom_min: float = 0.5
@export var zoom_max: float = 2.0
@export var zoom_step: float = 0.1
@export var zoom_speed: float = 12.0
@export var pan_speed_keyboard: float = 480.0

var is_pan_locked: bool = false
var target_zoom: Vector2 = Vector2(1.35, 1.35)

var _is_panning: bool = false
var _pan_start_mouse_pos: Vector2 = Vector2.ZERO
var _pan_start_camera_pos: Vector2 = Vector2.ZERO

const MAP_MIN: Vector2 = Vector2(0.0, 0.0)
const MAP_MAX: Vector2 = Vector2(2048.0, 2048.0)

func _ready() -> void:
	zoom = Vector2(1.35, 1.35)
	target_zoom = Vector2(1.35, 1.35)
	
	# Clamp limits to map dimensions
	limit_left = 0
	limit_top = 0
	limit_right = 2048
	limit_bottom = 2048
	
	_clamp_camera_position()

func _process(delta: float) -> void:
	# Hardware check: If neither RMB nor MMB is held down, panning MUST be false
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		_is_panning = false

	# Smooth Zoom interpolation
	if not zoom.is_equal_approx(target_zoom):
		zoom = zoom.lerp(target_zoom, clampf(delta * zoom_speed, 0.0, 1.0))

	# Keyboard navigation (WASD & Arrow Keys)
	var move_dir: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):
		move_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
		move_dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
		move_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
		move_dir.x += 1.0

	if move_dir != Vector2.ZERO and not is_pan_locked:
		var speed: float = pan_speed_keyboard / zoom.x
		position += move_dir.normalized() * speed * delta
		_clamp_camera_position()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		
		# Zoom In / Out with Mouse Wheel
		if mb.is_pressed():
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				_adjust_zoom(zoom_step)
				get_viewport().set_input_as_handled()
				return
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_adjust_zoom(-zoom_step)
				get_viewport().set_input_as_handled()
				return
		
		# Panning ONLY with Right Mouse or Middle Mouse (NEVER Left Click!)
		if mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			if mb.is_pressed() and not is_pan_locked:
				_is_panning = true
				_pan_start_mouse_pos = mb.global_position
				_pan_start_camera_pos = position
				get_viewport().set_input_as_handled()
			else:
				_is_panning = false
	
	elif event is InputEventMouseMotion:
		# Double-check physical mouse state
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			_is_panning = false
		
		if _is_panning and not is_pan_locked:
			var mm: InputEventMouseMotion = event as InputEventMouseMotion
			var drag_offset: Vector2 = (_pan_start_mouse_pos - mm.global_position) / zoom
			position = _pan_start_camera_pos + drag_offset
			_clamp_camera_position()
			get_viewport().set_input_as_handled()

func _adjust_zoom(amount: float) -> void:
	var new_zoom_val: float = clampf(target_zoom.x + amount, zoom_min, zoom_max)
	target_zoom = Vector2(new_zoom_val, new_zoom_val)

func _clamp_camera_position() -> void:
	var vp_size: Vector2 = get_viewport_rect().size / zoom
	var half_vp: Vector2 = vp_size * 0.5
	
	var min_x: float = minf(MAP_MIN.x + half_vp.x, MAP_MAX.x - half_vp.x)
	var max_x: float = maxf(MAP_MIN.x + half_vp.x, MAP_MAX.x - half_vp.x)
	var min_y: float = minf(MAP_MIN.y + half_vp.y, MAP_MAX.y - half_vp.y)
	var max_y: float = maxf(MAP_MIN.y + half_vp.y, MAP_MAX.y - half_vp.y)
	
	position.x = clampf(position.x, min_x, max_x)
	position.y = clampf(position.y, min_y, max_y)
