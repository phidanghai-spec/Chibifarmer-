extends Node2D
class_name PlayerAvatar

signal arrived(target: Node)

@export var speed: float = 150.0

var current_path: Array[Vector2] = []
var target_node: Node = null
var is_moving: bool = false

var _sprite: Sprite2D = null
var _name_label: Label = null
var _shadow_poly: Polygon2D = null

# Animation tracking
var _facing_row: int = 0 # 0: Down, 1: Up, 2: Right (flipped for Left)
var _anim_timer: float = 0.0
var _anim_frame_idx: int = 0
const ANIM_FRAME_TIME: float = 0.14

func _ready() -> void:
	z_index = 10
	z_as_relative = true
	_setup_nodes()
	_update_appearance()
	
	# Connect to SaveManager signal for live appearance and name updates
	SaveManager.player_settings_changed.connect(_on_settings_changed)
	
	# Initial position from SaveManager if set
	if SaveManager.player_position != Vector2.ZERO:
		position = SaveManager.player_position

func _setup_nodes() -> void:
	# 1. Shadow beneath feet
	_shadow_poly = Polygon2D.new()
	var pts: PackedVector2Array = PackedVector2Array()
	var segments: int = 14
	var rx: float = 18.0
	var ry: float = 7.0
	for i in range(segments):
		var angle: float = (float(i) / float(segments)) * TAU
		pts.append(Vector2(cos(angle) * rx, sin(angle) * ry))
	_shadow_poly.polygon = pts
	_shadow_poly.color = Color(0.0, 0.0, 0.0, 0.28)
	_shadow_poly.position = Vector2(0.0, 0.0)
	add_child(_shadow_poly)
	
	# 2. Character Sprite
	_sprite = Sprite2D.new()
	_sprite.centered = true
	# Ground-feet anchor: with 128px height, center is 64px up, so offset puts feet at (0, 0)
	_sprite.position = Vector2(0.0, -26.0)
	_sprite.scale = Vector2(0.42, 0.42)
	_sprite.hframes = 4
	_sprite.vframes = 4
	_sprite.frame = 0
	add_child(_sprite)
	
	# 3. Name Label above head
	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.text = SaveManager.player_name
	_name_label.position = Vector2(-70.0, -66.0)
	_name_label.custom_minimum_size = Vector2(140.0, 20.0)
	_name_label.add_theme_font_size_override("font_size", 12)
	_name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	_name_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
	_name_label.add_theme_constant_override("shadow_offset_x", 1)
	_name_label.add_theme_constant_override("shadow_offset_y", 1)
	_name_label.add_theme_color_override("font_outline_color", Color(0.12, 0.12, 0.12, 0.9))
	_name_label.add_theme_constant_override("outline_size", 3)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_label)

func _on_settings_changed() -> void:
	_update_appearance()

func _update_appearance() -> void:
	if _name_label != null:
		_name_label.text = SaveManager.player_name
	
	if _sprite == null:
		return
		
	var tex_key: String = "player_" + SaveManager.selected_character
	var tex: Texture2D = SpriteAtlasManager.get_texture(tex_key)
	if tex != null:
		_sprite.texture = tex
	else:
		# Fallback to visitor Chibi if player sprite not loaded
		var fallback_tex: Texture2D = SpriteAtlasManager.get_texture("visitor_farmer")
		if fallback_tex != null:
			_sprite.texture = fallback_tex
			_sprite.hframes = 1
			_sprite.vframes = 1
			_sprite.scale = Vector2(0.8, 0.8)
			if SaveManager.selected_character == "mai":
				_sprite.modulate = Color(1.0, 0.85, 0.95)
			else:
				_sprite.modulate = Color(0.9, 0.95, 1.0)
		return

	_sprite.hframes = 4
	_sprite.vframes = 4
	_sprite.scale = Vector2(0.42, 0.42)
	_sprite.modulate = Color.WHITE
	_apply_frame()

var _walk_time: float = 0.0

func go_to(path: Array[Vector2], target: Node = null) -> void:
	current_path = path.duplicate()
	target_node = target
	
	# Skip waypoints that are already reached
	while current_path.size() > 0 and position.distance_to(current_path[0]) < 6.0:
		current_path.remove_at(0)
		
	is_moving = (current_path.size() > 0)
	if is_moving and current_path.size() > 0:
		var final_dest: Vector2 = current_path[-1]
		var total_dx: float = final_dest.x - position.x
		if abs(total_dx) > 12.0 and _sprite != null:
			_sprite.flip_h = (total_dx < 0.0)
	else:
		_on_destination_reached()

func stop() -> void:
	current_path.clear()
	target_node = null
	is_moving = false
	_walk_time = 0.0
	if _sprite != null:
		_sprite.frame = 0
		_sprite.rotation_degrees = 0.0
		_sprite.position.y = -26.0

func _process(delta: float) -> void:
	if not is_moving or current_path.is_empty():
		_idle_process(delta)
		return
		
	var next_point: Vector2 = current_path[0]
	var dist: float = position.distance_to(next_point)
	var move_dist: float = speed * delta
	
	if dist <= move_dist:
		position = next_point
		current_path.remove_at(0)
		if current_path.is_empty():
			is_moving = false
			_on_destination_reached()
			return
		next_point = current_path[0]
		
	var dir: Vector2 = (next_point - position).normalized()
	position += dir * move_dist
	
	if abs(dir.x) > 0.4 and _sprite != null:
		_sprite.flip_h = (dir.x < 0.0)
		
	_walk_process(delta)
	
	# Periodically keep SaveManager position updated
	SaveManager.set_player_position(position)

func _walk_process(delta: float) -> void:
	_walk_time += delta
	if _sprite != null:
		_sprite.frame = 0 # Locked to best 3/4 front cozy frame, no erratic angle spinning
		var bob: float = abs(sin(_walk_time * 14.0)) * 3.0
		_sprite.position.y = -26.0 - bob
		_sprite.rotation_degrees = sin(_walk_time * 7.0) * 4.0 # Soft tilt -4 to +4 deg
	if _shadow_poly != null:
		var shrink: float = abs(sin(_walk_time * 14.0)) * 0.15
		_shadow_poly.scale = Vector2(1.0 - shrink, 1.0 - shrink)

func _idle_process(_delta: float) -> void:
	_walk_time = 0.0
	if _sprite != null:
		_sprite.frame = 0
		_sprite.rotation_degrees = 0.0
		var breath: float = sin(Time.get_ticks_msec() * 0.003) * 0.6
		_sprite.position.y = -26.0 + breath
		_sprite.scale = Vector2(0.42, 0.42 * (1.0 + breath * 0.015))
	if _shadow_poly != null:
		_shadow_poly.scale = Vector2.ONE

func _apply_frame() -> void:
	if _sprite != null:
		_sprite.frame = 0

func _on_destination_reached() -> void:
	is_moving = false
	_walk_time = 0.0
	if _sprite != null:
		_sprite.frame = 0
		_sprite.rotation_degrees = 0.0
		_sprite.position.y = -26.0
	if _shadow_poly != null:
		_shadow_poly.scale = Vector2.ONE
	
	SaveManager.set_player_position(position)
	SaveManager.save_game()
	
	var reached_target: Node = target_node
	target_node = null
	
	arrived.emit(reached_target)
	
	if reached_target != null and is_instance_valid(reached_target):
		if reached_target.has_method("on_player_interact"):
			reached_target.call("on_player_interact", self)
		elif reached_target.has_meta("interact_type"):
			var mf: Node = get_tree().current_scene
			if mf != null and mf.has_method("interact_with_prop"):
				mf.call("interact_with_prop", reached_target as Node2D)
