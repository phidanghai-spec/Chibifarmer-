# scripts/entities/pet_house_poodle.gd
# Cozy Wooden Kennel House for Pet Poodle
class_name PetHousePoodle
extends Node2D

var _sprite: Sprite2D = null
var _shadow: Polygon2D = null
var _label: Label = null

func _ready() -> void:
	add_to_group("interactable")
	y_sort_enabled = true
	_setup_visuals()

func _setup_visuals() -> void:
	# 1. Soft Ellipse Shadow
	_shadow = Polygon2D.new()
	_shadow.color = Color(0.12, 0.22, 0.10, 0.28)
	var pts: PackedVector2Array = PackedVector2Array()
	var segs: int = 16
	for i in range(segs):
		var a: float = (float(i) / float(segs)) * TAU
		pts.append(Vector2(cos(a) * 32.0, sin(a) * 14.0))
	_shadow.polygon = pts
	_shadow.position = Vector2(0.0, 22.0)
	_shadow.z_index = -1
	add_child(_shadow)

	# 2. Dog House Sprite
	_sprite = Sprite2D.new()
	_sprite.centered = true
	if SpriteAtlasManager.has_texture("pet_house_poodle"):
		_sprite.texture = SpriteAtlasManager.get_texture("pet_house_poodle")
	SpriteAtlasManager.set_sprite_pixel_size(_sprite, Vector2(66.0, 64.0))
	_sprite.position = Vector2(0.0, -8.0)
	add_child(_sprite)

	# 3. Label
	_label = Label.new()
	_label.text = "🏠 Nhà Poodle"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.position = Vector2(-60.0, -56.0)
	_label.custom_minimum_size = Vector2(120.0, 18.0)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 10)
	_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.82))
	_label.add_theme_color_override("font_outline_color", Color(0.2, 0.12, 0.05))
	_label.add_theme_constant_override("outline_size", 3)
	add_child(_label)

	# 4. Tap Button
	var btn: Button = Button.new()
	btn.flat = true
	btn.custom_minimum_size = Vector2(66.0, 64.0)
	btn.position = Vector2(-33.0, -40.0)
	btn.pressed.connect(_on_kennel_clicked)
	add_child(btn)

func _on_kennel_clicked() -> void:
	AudioManager.play_sfx("ui_wood_click")
	_spawn_floating_heart()
	var farm: Node = get_tree().current_scene
	if farm != null:
		var poodle: Node2D = farm.find_child("PetPoodle", true, false) as Node2D
		if poodle != null and poodle.has_method("feed_and_dig_treasure"):
			poodle.call("feed_and_dig_treasure")

func _spawn_floating_heart() -> void:
	var heart_sp: Sprite2D = Sprite2D.new()
	heart_sp.centered = true
	if SpriteAtlasManager.has_texture("icon_heart"):
		heart_sp.texture = SpriteAtlasManager.get_texture("icon_heart")
	
	var tex_w: float = 256.0
	var tex_h: float = 256.0
	if heart_sp.texture != null:
		tex_w = float(heart_sp.texture.get_width())
		tex_h = float(heart_sp.texture.get_height())
		
	# Strictly normalized to 28x28 pixels
	var heart_scale: Vector2 = Vector2(28.0 / tex_w, 28.0 / tex_h)
	heart_sp.scale = heart_scale * 0.5
	heart_sp.position = Vector2(0.0, -38.0)
	heart_sp.z_index = 25
	add_child(heart_sp)
	
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(heart_sp, "scale", heart_scale, 0.22)
	tw.tween_property(heart_sp, "position:y", -72.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(heart_sp, "modulate:a", 0.0, 0.3)
	tw.chain().tween_callback(heart_sp.queue_free)
