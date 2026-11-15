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
	"gender": "male",
	"body": "body_warm_ivory",
	"eyes": "eyes_sparkle_brown",
	"hair": "hair_short_sunny",
	"outfit": "outfit_denim_overalls",
	"hat": "hat_straw_ribbon",
	"poodle": "poodle_apricot_red"
}

var preview_mode: PreviewMode = PreviewMode.IDLE
var _anim_time: float = 0.0
var _base_shadow_scale: Vector2 = Vector2(1.0, 1.0)
var _base_sprite_scale: Vector2 = Vector2(0.75, 0.75)

func _ready() -> void:
	if dynamic_shadow != null:
		_base_shadow_scale = dynamic_shadow.scale
	_hide_legacy_paperdoll_layers()
	apply_full_config(current_config)

func _hide_legacy_paperdoll_layers() -> void:
	if eyes_layer != null:
		eyes_layer.visible = false
	if outfit_layer != null:
		outfit_layer.visible = false
	if hair_layer != null:
		hair_layer.visible = false
	if hat_layer != null:
		hat_layer.visible = false

func _process(delta: float) -> void:
	_anim_time += delta
	var is_moving_in_world: bool = velocity.length_squared() > 4.0
	var active_mode: PreviewMode = PreviewMode.WALK if is_moving_in_world else preview_mode
	_update_procedural_motion(active_mode)

func apply_full_config(new_config: Dictionary) -> void:
	for key: String in new_config.keys():
		current_config[key] = str(new_config[key])
	_refresh_authentic_avatar_sprite()

func equip_part(category: String, part_id: String) -> void:
	current_config[category] = part_id
	_refresh_authentic_avatar_sprite()
	if is_inside_tree() and visual_pivot != null:
		var tw: Tween = create_tween()
		tw.tween_property(visual_pivot, "scale", Vector2(1.08, 0.92), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(visual_pivot, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _refresh_authentic_avatar_sprite() -> void:
	_hide_legacy_paperdoll_layers()
	if body_layer == null:
		return

	var outfit_id: String = str(current_config.get("outfit", "outfit_denim_overalls"))
	var hair_id: String = str(current_config.get("hair", "hair_short_sunny"))
	var hat_id: String = str(current_config.get("hat", "hat_straw_ribbon"))
	var body_id: String = str(current_config.get("body", "body_warm_ivory"))
	var gender: String = str(current_config.get("gender", "male"))

	# Hair/preset selection: female-styled hairs switch to female base unless male-only hair is picked
	var is_female: bool = (gender == "female")
	if hair_id == "hair_braid_chestnut" or hair_id == "hair_curly_berry":
		is_female = true
	elif hair_id == "hair_short_sunny":
		is_female = false

	# Determine visual variant from outfit + hat/hair so every option changes appearance
	var effective_style: String = outfit_id
	if outfit_id == "outfit_denim_overalls":
		if hat_id == "hat_chef_toque" or hair_id == "hair_bun_baker":
			effective_style = "outfit_baker_apron"
		elif hat_id == "hat_postman_cap":
			effective_style = "outfit_carpenter_vest"

	var sprite_id: String = "avatar_male_overalls"
	if is_female:
		match effective_style:
			"outfit_floral_dress":
				sprite_id = "avatar_female_dress"
			"outfit_baker_apron":
				sprite_id = "avatar_female_baker"
			"outfit_carpenter_vest":
				sprite_id = "avatar_female_carpenter"
			_:
				sprite_id = "avatar_female_overalls"
	else:
		match effective_style:
			"outfit_floral_dress":
				sprite_id = "avatar_male_floral"
			"outfit_baker_apron":
				sprite_id = "avatar_male_baker"
			"outfit_carpenter_vest":
				sprite_id = "avatar_male_carpenter"
			_:
				sprite_id = "avatar_male_overalls"
	_assign_atlas_texture(body_layer, sprite_id)

	# Normalize scale so every 2.5D character sprite fits cleanly on the stage (target height ~175px)
	if body_layer.texture != null:
		var tex_h: float = maxf(1.0, body_layer.texture.get_height())
		var target_scale: float = 175.0 / tex_h
		_base_sprite_scale = Vector2(target_scale, target_scale)
		body_layer.scale = _base_sprite_scale
		body_layer.position = Vector2(0.0, -82.0)

	# Distinct skin/lighting & hair/hat tint so every Tab 1 & Tab 2 option gives clear visual feedback
	var base_tint: Color = Color(1.0, 1.0, 1.0, 1.0)
	match body_id:
		"body_peach_sunny":
			base_tint = Color(1.05, 0.94, 0.92, 1.0)
		"body_honey_tan":
			base_tint = Color(0.96, 0.87, 0.74, 1.0)
		"body_cocoa_warm":
			base_tint = Color(0.84, 0.72, 0.62, 1.0)
		_:
			base_tint = Color(1.0, 1.0, 1.0, 1.0)

	if hair_id == "hair_curly_berry":
		base_tint = base_tint * Color(1.04, 0.91, 0.96, 1.0)
	elif hair_id == "hair_short_sunny":
		base_tint = base_tint * Color(1.03, 1.01, 0.94, 1.0)

	body_layer.modulate = base_tint

func set_preview_action(mode: PreviewMode) -> void:
	preview_mode = mode
	_anim_time = 0.0
	if tool_layer == null:
		return
	match mode:
		PreviewMode.HARVEST:
			tool_layer.visible = true
			_assign_atlas_texture(tool_layer, "tool_sickle_chibi")
			tool_layer.position = Vector2(-29.0, -70.0)
			tool_layer.offset = Vector2(-15.0, -18.0)
			tool_layer.scale = Vector2(0.55, 0.55)
		PreviewMode.FISH:
			tool_layer.visible = true
			_assign_atlas_texture(tool_layer, "tool_fishing_rod_chibi")
			tool_layer.position = Vector2(-29.0, -70.0)
			tool_layer.offset = Vector2(-36.0, -32.0)
			tool_layer.scale = Vector2(0.58, 0.58)
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
			var breath: float = sin(_anim_time * 3.2) * 0.024
			visual_pivot.position = Vector2.ZERO
			visual_pivot.rotation = 0.0
			visual_pivot.scale = Vector2(1.0 - breath * 0.4, 1.0 + breath)
			if dynamic_shadow != null:
				dynamic_shadow.scale = _base_shadow_scale * (1.0 + breath * 0.18)
		PreviewMode.WALK:
			var wave: float = abs(sin(_anim_time * 10.5))
			var tilt: float = sin(_anim_time * 5.25) * 0.055
			visual_pivot.position.y = -wave * 6.5
			visual_pivot.rotation = tilt
			visual_pivot.scale = Vector2(1.0 + (0.5 - wave) * 0.06, 1.0 - (0.5 - wave) * 0.06)
			if dynamic_shadow != null:
				var shadow_factor: float = 1.0 - wave * 0.2
				dynamic_shadow.scale = _base_shadow_scale * shadow_factor
		PreviewMode.HARVEST:
			var swing: float = sin(_anim_time * 8.0)
			visual_pivot.position.y = -abs(swing) * 3.0
			visual_pivot.rotation = swing * 0.07
			if tool_layer != null:
				tool_layer.rotation = swing * 0.6
		PreviewMode.FISH:
			var pull: float = sin(_anim_time * 4.5)
			visual_pivot.position.y = -maxf(0.0, pull) * 4.5
			visual_pivot.rotation = -maxf(0.0, pull) * 0.08
			if tool_layer != null:
				tool_layer.rotation = -0.22 + pull * 0.32
