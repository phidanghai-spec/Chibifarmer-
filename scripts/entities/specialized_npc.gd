extends Node2D
class_name SpecializedNPC

## SpecializedNPC
## 5 NPC Chuyên trách Chibi đứng cố định cạnh các công trình chức năng:
## - npc_baker: Đứng cạnh Lò Bánh Mì
## - npc_pastry: Đứng cạnh Lò Bánh Ngọt
## - npc_barista: Đứng cạnh Quầy Nước Pha Chế
## - npc_rancher: Đứng lối vào Chuồng Bò / Gà
## - npc_keeper: Đứng giữa Kho Silo & Barn
## 100% Static Typing GDScript 2.0.

@export var npc_id: String = "baker"
@export var npc_name: String = "Thợ Bánh Mì"
@export var sprite_key: String = "npc_char_01"

var _sprite: Sprite2D
var _speech_bubble: PanelContainer
var _lbl_message: Label
var _orig_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	y_sort_enabled = true
	
	# Soft circular ground shadow
	var shadow: Polygon2D = Polygon2D.new()
	shadow.name = "GroundShadow"
	var pts: PackedVector2Array = PackedVector2Array()
	var num_pts: int = 12
	var rad_x: float = 14.0
	var rad_y: float = 6.5
	for i: int in range(num_pts):
		var ang: float = (float(i) / float(num_pts)) * TAU
		pts.append(Vector2(cos(ang) * rad_x, sin(ang) * rad_y))
	shadow.polygon = pts
	shadow.color = Color(0.12, 0.22, 0.10, 0.28)
	shadow.position = Vector2(0, 0)
	shadow.z_index = 0
	add_child(shadow)
	
	_sprite = Sprite2D.new()
	_sprite.name = "NPCSprite"
	if SpriteAtlasManager.has_texture(sprite_key):
		_sprite.texture = SpriteAtlasManager.get_texture(sprite_key)
		SpriteAtlasManager.set_sprite_pixel_size(_sprite, Vector2(36, 46))
	_sprite.position = Vector2(0, -20)
	_sprite.z_index = 2
	add_child(_sprite)
	_orig_scale = _sprite.scale
	
	# Idle breathing animation
	var tw: Tween = create_tween().set_loops()
	tw.tween_property(_sprite, "scale:y", _orig_scale.y * 1.05, 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_sprite, "scale:y", _orig_scale.y, 1.2).set_trans(Tween.TRANS_SINE)
	
	# Speech bubble above head
	_speech_bubble = PanelContainer.new()
	_speech_bubble.name = "SpeechBubble"
	_speech_bubble.position = Vector2(-55, -55)
	_speech_bubble.custom_minimum_size = Vector2(110, 22)
	_speech_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speech_bubble.z_index = 20
	
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 0.99, 0.94, 0.96)
	sb.border_color = Color(0.68, 0.45, 0.25, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.shadow_color = Color(0.4, 0.25, 0.15, 0.2)
	sb.shadow_size = 3
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	_speech_bubble.add_theme_stylebox_override("panel", sb)
	
	_lbl_message = Label.new()
	_lbl_message.name = "LabelMessage"
	_lbl_message.text = "✨ Sẵn Sàng!"
	_lbl_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lbl_message.add_theme_font_size_override("font_size", 9)
	_lbl_message.add_theme_color_override("font_color", Color(0.25, 0.15, 0.05))
	_speech_bubble.add_child(_lbl_message)
	add_child(_speech_bubble)
	
	# Tap interaction button
	var btn_click: Button = Button.new()
	btn_click.flat = true
	btn_click.position = Vector2(-18, -38)
	btn_click.size = Vector2(36, 40)
	btn_click.mouse_filter = Control.MOUSE_FILTER_STOP
	btn_click.pressed.connect(_on_npc_clicked)
	add_child(btn_click)

func set_alert(msg: String, is_warning: bool = true) -> void:
	if _speech_bubble == null or _lbl_message == null:
		return
	if msg == "":
		_speech_bubble.visible = false
	else:
		_speech_bubble.visible = true
		_lbl_message.text = msg
		if is_warning:
			_lbl_message.add_theme_color_override("font_color", Color(0.85, 0.20, 0.05))
		else:
			_lbl_message.add_theme_color_override("font_color", Color(0.20, 0.55, 0.15))

func _on_npc_clicked() -> void:
	AudioManager.play_sfx("click")
	if _sprite != null:
		var tw: Tween = create_tween()
		tw.tween_property(_sprite, "scale", Vector2(_orig_scale.x * 1.15, _orig_scale.y * 0.85), 0.08)
		tw.tween_property(_sprite, "scale", _orig_scale, 0.1)
