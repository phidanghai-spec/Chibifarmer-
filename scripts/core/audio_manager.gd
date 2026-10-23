extends Node

## AudioManager
## Quản lý âm thanh 2.5D Chibi Cozy Farm với AudioStreamPlayer Pool và 6 hiệu ứng .wav gốc.
## 100% Static Typing GDScript 2.0.

var is_muted: bool = false

var _sounds: Dictionary = {} # String -> AudioStreamWAV
var _players: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 8
var _current_player_idx: int = 0

const SFX_MAP: Dictionary = {
	"click": "res://assets/audio/sfx_click.wav",
	"sfx_click": "res://assets/audio/sfx_click.wav",
	"plant": "res://assets/audio/sfx_plant.wav",
	"sfx_plant": "res://assets/audio/sfx_plant.wav",
	"harvest": "res://assets/audio/sfx_harvest.wav",
	"sfx_harvest": "res://assets/audio/sfx_harvest.wav",
	"coin": "res://assets/audio/sfx_coin.wav",
	"sfx_coin": "res://assets/audio/sfx_coin.wav",
	"splash": "res://assets/audio/sfx_splash.wav",
	"sfx_splash": "res://assets/audio/sfx_splash.wav",
	"error": "res://assets/audio/sfx_error.wav",
	"sfx_error": "res://assets/audio/sfx_error.wav"
}

func _ready() -> void:
	# 1. Tải sẵn toàn bộ tài nguyên âm thanh .wav
	for key: Variant in SFX_MAP:
		var k_str: String = str(key)
		var path_str: String = str(SFX_MAP[k_str])
		if FileAccess.file_exists(path_str):
			var stream: AudioStream = load(path_str) as AudioStream
			if stream != null:
				_sounds[k_str] = stream

	# 2. Tạo Pool AudioStreamPlayer
	for i: int in range(POOL_SIZE):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		p.bus = "Master"
		add_child(p)
		_players.append(p)

	print("[AudioManager] Initialized with %d sounds and %d pooled players." % [_sounds.size(), _players.size()])

func play_sfx(sfx_name: String) -> void:
	if is_muted:
		return
	
	var clean_key: String = sfx_name.to_lower().strip_edges()
	if not _sounds.has(clean_key):
		if not clean_key.begins_with("sfx_"):
			clean_key = "sfx_" + clean_key
		if not _sounds.has(clean_key):
			return

	var stream: AudioStream = _sounds[clean_key] as AudioStream
	if stream == null or _players.is_empty():
		return

	# Lấy player rảnh tiếp theo trong pool
	var player: AudioStreamPlayer = _players[_current_player_idx]
	_current_player_idx = (_current_player_idx + 1) % _players.size()
	
	player.stop()
	player.stream = stream
	player.play()

func toggle_mute() -> bool:
	is_muted = not is_muted
	if is_muted:
		for p: AudioStreamPlayer in _players:
			p.stop()
	print("[AudioManager] Sound muted: ", is_muted)
	return is_muted
