extends Node

var _accum: float = 0.0
var dev_speed_multiplier: float = 1.0

func _process(delta: float) -> void:
	_accum += delta
	if _accum >= 1.0:
		_accum -= 1.0
		EventBus.second_ticked.emit(now())

func now() -> int:
	return int(Time.get_unix_time_from_system())

func calculate_finish_timestamp(duration_seconds: int) -> int:
	var adjusted: int = int(float(duration_seconds) / dev_speed_multiplier)
	if adjusted < 1:
		adjusted = 1
	return now() + adjusted

func get_time_remaining(finish_timestamp: int) -> int:
	var current: int = now()
	if current >= finish_timestamp:
		return 0
	return finish_timestamp - current

func is_finished(finish_timestamp: int) -> bool:
	return now() >= finish_timestamp

func get_progress_ratio(start_timestamp: int, finish_timestamp: int) -> float:
	var total: int = finish_timestamp - start_timestamp
	if total <= 0:
		return 1.0
	var elapsed: int = now() - start_timestamp
	return clampf(float(elapsed) / float(total), 0.0, 1.0)

func format_duration(seconds: int) -> String:
	if seconds <= 0:
		return "00:00"
	var hours: int = int(float(seconds) / 3600.0)
	var remainder: int = seconds % 3600
	var minutes: int = int(float(remainder) / 60.0)
	var secs: int = remainder % 60
	
	if hours > 0:
		return "%02d:%02d:%02d" % [hours, minutes, secs]
	return "%02d:%02d" % [minutes, secs]
