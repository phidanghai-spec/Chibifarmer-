# scripts/entities/mailbox_newspaper_prop.gd
# Interactive Chibi Mailbox Prop for Daily Newspaper
class_name MailboxNewspaperProp
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
		pts.append(Vector2(cos(a) * 18.0, sin(a) * 8.0))
	_shadow.polygon = pts
	_shadow.position = Vector2(0.0, 16.0)
	_shadow.z_index = -1
	add_child(_shadow)

	# 2. Mailbox Sprite
	_sprite = Sprite2D.new()
	_sprite.centered = true
	if SpriteAtlasManager.has_texture("mailbox_newspaper"):
		_sprite.texture = SpriteAtlasManager.get_texture("mailbox_newspaper")
	SpriteAtlasManager.set_sprite_pixel_size(_sprite, Vector2(46.0, 64.0))
	_sprite.position = Vector2(0.0, -10.0)
	add_child(_sprite)

	# 3. Label
	_label = Label.new()
	_label.text = "📮 Báo Nông Thôn"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.position = Vector2(-65.0, -52.0)
	_label.custom_minimum_size = Vector2(130.0, 18.0)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 10)
	_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.82))
	_label.add_theme_color_override("font_outline_color", Color(0.2, 0.12, 0.05))
	_label.add_theme_constant_override("outline_size", 3)
	add_child(_label)

	# 4. Tap Button
	var btn: Button = Button.new()
	btn.flat = true
	btn.custom_minimum_size = Vector2(50.0, 65.0)
	btn.position = Vector2(-25.0, -42.0)
	btn.pressed.connect(_on_mailbox_clicked)
	add_child(btn)

func _on_mailbox_clicked() -> void:
	AudioManager.play_sfx("click")
	var farm: Node = get_tree().current_scene
	var hud: UIHud = farm.find_child("UIHud", true, false) as UIHud if farm != null else null
	if hud != null:
		hud.open_newspaper_modal()
