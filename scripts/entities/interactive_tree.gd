# scripts/entities/interactive_tree.gd
# Interactive Scenic Tree & Plant Entity for Hay Day Offline
class_name InteractiveTree
extends Node2D

@export var sprite_id: String = "env_apple_tree"
@export var target_size: Vector2 = Vector2(80.0, 84.0)

var _sprite: Sprite2D = null
var _shadow: Polygon2D = null
var _area: Area2D = null
var _col_shape: CollisionShape2D = null
var _mini_menu: PanelContainer = null

var is_moving_mode: bool = false
var _original_position: Vector2 = Vector2.ZERO
var _current_grid_cell: Vector2i = Vector2i(-1, -1)
var _is_chopped: bool = false

func _ready() -> void:
	add_to_group("interactable_trees")
	y_sort_enabled = true
	_setup_collision()
	_update_grid_solid(true)

func _exit_tree() -> void:
	if not _is_chopped:
		_update_grid_solid(false)

func setup(p_sprite_id: String, p_pos: Vector2, p_size: Vector2) -> void:
	sprite_id = p_sprite_id
	position = p_pos
	target_size = p_size
	_original_position = p_pos

func _setup_collision() -> void:
	if _area != null:
		return
		
	_area = Area2D.new()
	_area.name = "TreeClickArea"
	_area.input_pickable = true
	add_child(_area)
	
	_col_shape = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = maxf(target_size.x, target_size.y) * 0.45
	_col_shape.shape = shape
	_col_shape.position = Vector2(0.0, -target_size.y * 0.35)
	_area.add_child(_col_shape)
	
	_area.input_event.connect(_on_area_input_event)

func _update_grid_solid(is_solid: bool) -> void:
	if GridManager == null:
		return
	var cell: Vector2i = GridManager.world_to_grid(global_position)
	if is_solid:
		_current_grid_cell = cell
		GridManager.mark_footprint_solid(cell, Vector2i(1, 1), true, 5000)
	elif _current_grid_cell != Vector2i(-1, -1):
		GridManager.mark_footprint_solid(_current_grid_cell, Vector2i(1, 1), false, -1)
		_current_grid_cell = Vector2i(-1, -1)

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _is_chopped:
		return
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb.button_index == MOUSE_BUTTON_LEFT and mb.is_pressed():
		handle_tree_click()

func handle_tree_click() -> void:
	if _is_chopped:
		return
	var tree_root: SceneTree = get_tree()
	var farm: Node = tree_root.current_scene if tree_root != null else null
	var drag_mgr: DragActionManager = farm.find_child("DragActionManager", true, false) as DragActionManager if farm != null else null
	
	# If DISMANTLE tool is selected, chop immediately!
	if drag_mgr != null and drag_mgr.current_tool == DragActionManager.ToolType.DISMANTLE:
		chop_tree()
		return
		
	# Otherwise toggle floating mini action menu
	if _mini_menu != null and is_instance_valid(_mini_menu):
		_mini_menu.queue_free()
		_mini_menu = null
		return
		
	_show_mini_menu()

func _show_mini_menu() -> void:
	_mini_menu = PanelContainer.new()
	_mini_menu.name = "TreeMiniMenu"
	_mini_menu.z_index = 60
	
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.98, 0.94, 0.86, 0.96)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.48, 0.28, 0.12, 1.0)
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_right = 10
	sb.corner_radius_bottom_left = 10
	sb.shadow_size = 4
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.3)
	_mini_menu.add_theme_stylebox_override("panel", sb)
	
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	_mini_menu.add_child(hbox)
	
	# Button Move
	var btn_move: Button = Button.new()
	btn_move.text = "🔄 Di Chuyển"
	btn_move.custom_minimum_size = Vector2(90.0, 32.0)
	btn_move.add_theme_font_size_override("font_size", 12)
	btn_move.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_wood_click")
		_start_moving_mode()
	)
	hbox.add_child(btn_move)
	
	# Button Chop
	var btn_chop: Button = Button.new()
	btn_chop.text = "🪓 Chặt Cây"
	btn_chop.custom_minimum_size = Vector2(85.0, 32.0)
	btn_chop.add_theme_font_size_override("font_size", 12)
	btn_chop.pressed.connect(func() -> void:
		chop_tree()
	)
	hbox.add_child(btn_chop)
	
	_mini_menu.position = Vector2(-90.0, -target_size.y * 0.9 - 36.0)
	add_child(_mini_menu)

func _start_moving_mode() -> void:
	if _is_chopped:
		return
	if _mini_menu != null and is_instance_valid(_mini_menu):
		_mini_menu.queue_free()
		_mini_menu = null
		
	_original_position = global_position
	_update_grid_solid(false)
	is_moving_mode = true
	modulate.a = 0.75

func _unhandled_input(event: InputEvent) -> void:
	if not is_moving_mode:
		return
		
	if event is InputEventMouseMotion:
		var farm: Node = get_tree().current_scene
		var mpos: Vector2 = farm.get_global_mouse_position() if farm != null else get_global_mouse_position()
		# Snap to 32x32 grid
		var cell: Vector2i = GridManager.world_to_grid(mpos)
		global_position = GridManager.grid_to_world(cell)
		
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.is_pressed():
			_commit_move()
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.is_pressed():
			_cancel_move()
			get_viewport().set_input_as_handled()

func _commit_move() -> void:
	var cell: Vector2i = GridManager.world_to_grid(global_position)
	var wpos: Vector2 = GridManager.grid_to_world(cell)
	
	# Validate position: cannot be on water, cannot overlap building or plot
	if GridManager.is_in_water_or_sand(wpos) or GridManager.is_cell_occupied(cell):
		AudioManager.play_sfx("error")
		return
		
	is_moving_mode = false
	modulate.a = 1.0
	global_position = wpos
	_update_grid_solid(true)
	AudioManager.play_sfx("place_building")

func _cancel_move() -> void:
	is_moving_mode = false
	modulate.a = 1.0
	global_position = _original_position
	_update_grid_solid(true)
	AudioManager.play_sfx("ui_wood_click")

func chop_tree() -> void:
	if _is_chopped:
		return
	_is_chopped = true
	is_moving_mode = false
	if _area != null:
		_area.input_pickable = false
	if _mini_menu != null and is_instance_valid(_mini_menu):
		_mini_menu.queue_free()
		_mini_menu = null
	AudioManager.play_sfx("harvest")
	_update_grid_solid(false)
	
	var xp_reward: int = 5
	var gold_reward: int = 15
	StorageManager.add_xp(xp_reward)
	StorageManager.add_gold(gold_reward)
	EventBus.gold_changed.emit(StorageManager.gold, gold_reward)
	
	var tree_root: SceneTree = get_tree()
	var farm: Node = tree_root.current_scene if tree_root != null else null
	var hud: UIHud = farm.find_child("UIHud", true, false) as UIHud if farm != null else null
	if hud != null:
		hud.show_floating_notice("🪓 Đã chặt dọn cây (+%d Vàng, +%d XP)!" % [gold_reward, xp_reward])
		
	# Spawn falling leaf / wood burst particles then free
	if is_inside_tree():
		var tw: Tween = create_tween()
		tw.tween_property(self, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_callback(queue_free)
	else:
		queue_free()
