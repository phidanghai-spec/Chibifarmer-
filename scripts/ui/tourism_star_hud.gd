class_name TourismStarHUD
extends PanelContainer

## TourismStarHUD
## Hiển thị huy hiệu Thời Tiết thời gian thực và Xếp hạng Nông Trại 1-5 Sao
## 100% Static Typing GDScript 2.0.

@onready var weather_badge_icon: TextureRect = $HBoxContainer/WeatherBadgeIcon
@onready var star_icons_hbox: HBoxContainer = $HBoxContainer/StarIconsHBox
@onready var attraction_label: Label = $HBoxContainer/AttractionScoreLabel

var current_star_count: int = 1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_weather_icon("sunny_breeze")
	_rebuild_stars(1)
	
	EventBus.weather_state_changed.connect(func(weather_id: String, _mult: float, _bonus: float) -> void:
		_update_weather_icon(weather_id)
	)
	EventBus.time_of_day_changed.connect(func(phase_id: String, _col: Color, is_night: bool) -> void:
		if is_night:
			_update_weather_icon("night")
	)
	EventBus.tourism_star_rating_updated.connect(func(new_star: int, total_score: int) -> void:
		current_star_count = new_star
		_rebuild_stars(new_star)
		if attraction_label != null:
			attraction_label.text = "%d ⭐ (%d Điểm)" % [new_star, total_score]
	)

func _update_weather_icon(key: String) -> void:
	if weather_badge_icon == null or SpriteAtlasManager == null:
		return
	var tex: Texture2D = SpriteAtlasManager.get_weather_badge_texture(key)
	if tex != null:
		weather_badge_icon.texture = tex

func _rebuild_stars(star_count: int) -> void:
	if star_icons_hbox == null:
		return
	for child: Node in star_icons_hbox.get_children():
		child.queue_free()
		
	for i: int in range(5):
		var star_lbl: Label = Label.new()
		star_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		star_lbl.text = "⭐" if i < star_count else "☆"
		star_lbl.add_theme_font_size_override("font_size", 14)
		star_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25, 1.0) if i < star_count else Color(0.65, 0.60, 0.55, 0.8))
		star_icons_hbox.add_child(star_lbl)
