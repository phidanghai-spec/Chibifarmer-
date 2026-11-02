class_name WeatherAndDayNightManager
extends Node2D

## WeatherAndDayNightManager
## Quản lý chu kỳ 4 khung giờ Ngày-Đêm (Dawn, Noon, Sunset, Night) và 3 trạng thái Thời Tiết Sinh Thái
## Tác động trực tiếp lên tốc độ sinh trưởng của cây trồng và vận may câu cá.
## 100% Static Typing GDScript 2.0.

enum TimePhase { DAWN, NOON, SUNSET, NIGHT }
enum WeatherType { SUNNY_BREEZE, COZY_RAIN, BALLOON_FESTIVAL }

const PHASE_DURATION_SECONDS: float = 90.0

@onready var canvas_modulate: CanvasModulate = get_node_or_null("DayNightModulate") as CanvasModulate
@onready var rain_particles: CPUParticles2D = get_node_or_null("CozyRainParticles") as CPUParticles2D
@onready var lantern_glow_root: Node2D = get_node_or_null("LanternGlowRoot") as Node2D

var current_phase: TimePhase = TimePhase.DAWN
var current_weather: WeatherType = WeatherType.SUNNY_BREEZE
var crop_growth_multiplier: float = 1.0
var fishing_luck_bonus: float = 0.0

var _phase_timer: float = 0.0
var _phase_colors: Dictionary = {
	TimePhase.DAWN: Color(1.0, 0.92, 0.88, 1.0),
	TimePhase.NOON: Color(1.0, 1.0, 0.98, 1.0),
	TimePhase.SUNSET: Color(0.98, 0.82, 0.72, 1.0),
	TimePhase.NIGHT: Color(0.62, 0.68, 0.86, 1.0)
}

func _ready() -> void:
	if rain_particles != null:
		rain_particles.emitting = false
	_apply_time_phase(TimePhase.NOON)
	_apply_weather(WeatherType.SUNNY_BREEZE)

func _process(delta: float) -> void:
	_phase_timer += delta
	if _phase_timer >= PHASE_DURATION_SECONDS:
		_phase_timer = 0.0
		_advance_time_phase()

func _advance_time_phase() -> void:
	var next_index: int = (int(current_phase) + 1) % 4
	_apply_time_phase(next_index as TimePhase)
	if current_phase == TimePhase.DAWN:
		_roll_daily_weather()

func _apply_time_phase(new_phase: TimePhase) -> void:
	current_phase = new_phase
	var target_col: Color = _phase_colors.get(new_phase, Color.WHITE) as Color
	var is_night_time: bool = (new_phase == TimePhase.NIGHT)
	
	if canvas_modulate != null:
		var tween: Tween = create_tween()
		tween.tween_property(canvas_modulate, "color", target_col, 3.5)
		
	if lantern_glow_root != null:
		lantern_glow_root.visible = is_night_time or (new_phase == TimePhase.SUNSET)
		
	var phase_name: String = _get_phase_key(new_phase)
	EventBus.time_of_day_changed.emit(phase_name, target_col, is_night_time)

func _roll_daily_weather() -> void:
	var roll: int = randi() % 100
	if roll < 55:
		_apply_weather(WeatherType.SUNNY_BREEZE)
	elif roll < 80:
		_apply_weather(WeatherType.COZY_RAIN)
	else:
		_apply_weather(WeatherType.BALLOON_FESTIVAL)

func _apply_weather(new_weather: WeatherType) -> void:
	current_weather = new_weather
	match new_weather:
		WeatherType.SUNNY_BREEZE:
			crop_growth_multiplier = 1.0
			fishing_luck_bonus = 0.0
			if rain_particles != null:
				rain_particles.emitting = false
			EventBus.weather_state_changed.emit("sunny_breeze", 1.0, 0.0)
		WeatherType.COZY_RAIN:
			# Mưa ấm áp giúp cây trồng và cây ăn quả lớn nhanh hơn 25%, cá dễ cắn câu hơn
			crop_growth_multiplier = 1.25
			fishing_luck_bonus = 0.25
			if rain_particles != null:
				rain_particles.emitting = true
			EventBus.weather_state_changed.emit("cozy_rain", 1.25, 0.25)
			AudioManager.play_sfx("gentle_rain")
		WeatherType.BALLOON_FESTIVAL:
			# Ngày hội Khinh khí cầu thu hút thêm khách VIP và tăng năng suất
			crop_growth_multiplier = 1.05
			fishing_luck_bonus = 0.10
			if rain_particles != null:
				rain_particles.emitting = false
			EventBus.weather_state_changed.emit("balloon_festival", 1.05, 0.10)

func _get_phase_key(phase: TimePhase) -> String:
	match phase:
		TimePhase.DAWN:
			return "dawn"
		TimePhase.NOON:
			return "noon"
		TimePhase.SUNSET:
			return "sunset"
		_:
			return "night"

