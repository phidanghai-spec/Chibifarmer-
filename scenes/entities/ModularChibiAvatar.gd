class_name ModularChibiAvatar
extends CharacterBody2D

enum PreviewMode { IDLE, WALK, HARVEST, FISH }

@onready var dynamic_shadow: Sprite2D = $DynamicShadow
@onready var visual_pivot: Node2D = $VisualPivot
@onready var body_layer: Sprite2D = $VisualPivot/BodyLayer
@onready var eyes_layer: Sprite2D = $VisualPivot/EyesLayer
@onready var outfit_layer: Sprite2D = $VisualPivot/OutfitLayer
@onready var hair_layer: Sprite2D = $VisualPivot/HairLayer
@onready var hat_layer: Sprite2D = $VisualPivot/HatLayer
@onready var tool_layer: Sprite2D = $VisualPivot/ToolLayer

var current_config: Dictionary = {
	"body": "body_warm_ivory",
	"eyes": "eyes_sparkle_brown",
	"hair": "hair_braid_chestnut",
	"outfit": "outfit_denim_overalls",
	"hat": "hat_straw_ribbon",
	"poodle": "poodle_apricot_red"
}

var preview_mode: PreviewMode = PreviewMode.IDLE
var _anim_time: float = 0.0
var _base_shadow_scale: Vector2 = Vector2(1.0, 1.0)

func _ready() -> void:
	if dynamic_shadow != null:
		_base_shadow_scale = dynamic_shadow.scale
	apply_full_config(current_config)

func _process(delta: float) -> void:
	_anim_time += delta
	var is_moving_in_world: bool = velocity.length_squared() > 4.0
	var active_mode: PreviewMode = PreviewMode.WALK if is_moving_in_world else preview_mode
	_update_procedural_motion(active_mode)

func apply_full_config(new_config: Dictionary) -> void:
	for key: String in new_config.keys():
		current_config[key] = str(new_config[key])
		equip_part(key, str(new_config[key]))

func equip_part(category: String, part_id: String) -> void:
	current_config[category] = part_id
	match category:
		"body":
			_assign_atlas_texture(body_layer, part_id)
		"eyes":
			_assign_atlas_texture(eyes_layer, part_id)
		"outfit":
			_assign_atlas_texture(outfit_layer, part_id)
		"hair":
			_assign_atlas_texture(hair_layer, part_id)
		"hat":
			if part_id == "hat_none" or part_id.is_empty():
				if hat_layer != null:
					hat_layer.visible = false
			else:
				if hat_layer != null:
					hat_layer.visible = true
					_assign_atlas_texture(hat_layer, part_id)

func set_preview_action(mode: PreviewMode) -> void:
	preview_mode = mode
	_anim_time = 0.0
	if tool_layer == null:
		return
	match mode:
		PreviewMode.HARVEST:
			tool_layer.visible = true
			_assign_atlas_texture(tool_layer, "tool_sickle_chibi")
		PreviewMode.FISH:
			tool_layer.visible = true
			_assign_atlas_texture(tool_layer, "tool_fishing_rod_chibi")
		_:
			tool_layer.visible = false
			tool_layer.rotation = 0.0

func _assign_atlas_texture(target_sprite: Sprite2D, region_id: String) -> void:
	if target_sprite == null or region_id.is_empty():
		return
	var tex: Texture2D = null
	if Engine.has_singleton("SpriteAtlasManager") or has_node("/root/SpriteAtlasManager"):
		var sam: Node = get_node_or_null("/root/SpriteAtlasManager")
		if sam != null:
			if sam.has_method("get_region_texture"):
				tex = sam.call("get_region_texture", region_id) as Texture2D
			if tex == null and sam.has_method("get_texture"):
				tex = sam.call("get_texture", region_id) as Texture2D
	
	if tex == null:
		var direct_path: String = "res://assets/sprites/" + region_id + ".png"
		if FileAccess.file_exists(direct_path):
			tex = load(direct_path) as Texture2D
			
	if tex != null:
		target_sprite.texture = tex

func _update_procedural_motion(mode: PreviewMode) -> void:
	if visual_pivot == null:
		return
	match mode:
		PreviewMode.IDLE:
			# Idle Breathing: nhịp thở tự nhiên khi đứng
			var breath: float = sin(_anim_time * 3.2) * 0.028
			visual_pivot.position = Vector2.ZERO
			visual_pivot.rotation = 0.0
			visual_pivot.scale = Vector2(1.0 - breath * 0.45, 1.0 + breath)
			if dynamic_shadow != null:
				dynamic_shadow.scale = _base_shadow_scale * (1.0 + breath * 0.2)
		PreviewMode.WALK:
			# Walk Bounce & Dynamic Shadow: nhún nhảy và bóng đổ co giãn theo nhịp chân
			var wave: float = abs(sin(_anim_time * 11.0))
			var tilt: float = sin(_anim_time * 5.5) * 0.06
			visual_pivot.position.y = -wave * 7.5
			visual_pivot.rotation = tilt
			visual_pivot.scale = Vector2(1.0 + (0.5 - wave) * 0.08, 1.0 - (0.5 - wave) * 0.08)
			if dynamic_shadow != null:
				var shadow_factor: float = 1.0 - wave * 0.22
				dynamic_shadow.scale = _base_shadow_scale * shadow_factor
		PreviewMode.HARVEST:
			# Hoạt ảnh vung liềm gặt lúa mượt mà
			var swing: float = sin(_anim_time * 8.0)
			visual_pivot.position.y = -abs(swing) * 3.0
			visual_pivot.rotation = swing * 0.08
			if tool_layer != null:
				tool_layer.rotation = swing * 0.65
		PreviewMode.FISH:
			# Hoạt ảnh giật cần câu cá bên cầu gỗ
			var pull: float = sin(_anim_time * 4.5)
			visual_pivot.position.y = -maxf(0.0, pull) * 5.0
			visual_pivot.rotation = -maxf(0.0, pull) * 0.10
			if tool_layer != null:
				tool_layer.rotation = -0.25 + pull * 0.35
