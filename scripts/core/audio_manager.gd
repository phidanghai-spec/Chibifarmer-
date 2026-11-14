extends Node

## AudioManager
## Quản lý âm thanh 2.5D Chibi Cozy Farm với AudioStreamPlayer Pool, Combo Pitch Shifting,
## nhạc nền mộc mạc thư giãn (Acoustic Farm BGM) và hiệu ứng .wav gốc ấm áp.
## 100% Static Typing GDScript 2.0.

var is_muted: bool = false

var _sounds: Dictionary = {} # String -> AudioStreamWAV
var _players: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 8
var _current_player_idx: int = 0
var _last_play_time: Dictionary = {} # String -> float
const MIN_INTERVAL: float = 0.08 # seconds
var _combo_count: int = 0
var _last_combo_time: float = 0.0

# BGM Manager
const BGM_PATH: String = "res://assets/audio/bgm_cozy_farm.ogg"
var _bgm_player: AudioStreamPlayer = null
const DEFAULT_BGM_VOLUME: float = -22.0

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
	"sfx_error": "res://assets/audio/sfx_error.wav",
	"ui_wood_click": "res://assets/audio/sfx_ui_wood_click.wav",
	"sfx_ui_wood_click": "res://assets/audio/sfx_ui_wood_click.wav",
	"welcome_chime": "res://assets/audio/sfx_welcome_chime.wav",
	"sfx_welcome_chime": "res://assets/audio/sfx_welcome_chime.wav",
	"cloth_rustle": "res://assets/audio/sfx_cloth_rustle.wav",
	"sfx_cloth_rustle": "res://assets/audio/sfx_cloth_rustle.wav",
	"dice_roll": "res://assets/audio/sfx_dice_roll.wav",
	"sfx_dice_roll": "res://assets/audio/sfx_dice_roll.wav",
	"steamboat_whistle": "res://assets/audio/sfx_steamboat_whistle.wav",
	"sfx_steamboat_whistle": "res://assets/audio/sfx_steamboat_whistle.wav",
	"coins_jingle": "res://assets/audio/sfx_coins_jingle.wav",
	"sfx_coins_jingle": "res://assets/audio/sfx_coins_jingle.wav",
	"camera_shutter": "res://assets/audio/sfx_camera_shutter_chibi.wav",
	"sfx_camera_shutter": "res://assets/audio/sfx_camera_shutter_chibi.wav",
	"gentle_rain": "res://assets/audio/sfx_gentle_rain_loop.wav",
	"sfx_gentle_rain": "res://assets/audio/sfx_gentle_rain_loop.wav",
	"page_flip": "res://assets/audio/sfx_page_flip_almanac.wav",
	"sfx_page_flip": "res://assets/audio/sfx_page_flip_almanac.wav",
	# Các alias tiện ích hỗ trợ tương thích mã nguồn
	"sell": "res://assets/audio/sfx_coins_jingle.wav",
	"sfx_sell": "res://assets/audio/sfx_coins_jingle.wav",
	"level_up": "res://assets/audio/sfx_welcome_chime.wav",
	"sfx_level_up": "res://assets/audio/sfx_welcome_chime.wav",
	"fanfare": "res://assets/audio/sfx_welcome_chime.wav",
	"sfx_fanfare": "res://assets/audio/sfx_welcome_chime.wav",
	"bell": "res://assets/audio/sfx_coin.wav",
	"sfx_bell": "res://assets/audio/sfx_coin.wav",
	"whistle": "res://assets/audio/sfx_steamboat_whistle.wav",
	"sfx_whistle": "res://assets/audio/sfx_steamboat_whistle.wav",
	"place_building": "res://assets/audio/sfx_ui_wood_click.wav",
	"sfx_place_building": "res://assets/audio/sfx_ui_wood_click.wav",
	"bgm_cozy_farm": "res://assets/audio/bgm_cozy_farm.ogg"
}

func _ready() -> void:
	# 1. Tải sẵn toàn bộ tài nguyên âm thanh .wav (bảo đảm tắt hardware loop để chống rè tiếng)
	for key: Variant in SFX_MAP:
		var k_str: String = str(key)
		var path_str: String = str(SFX_MAP[k_str])
		if FileAccess.file_exists(path_str):
			var stream: AudioStream = load(path_str) as AudioStream
			if stream != null:
				if stream is AudioStreamWAV:
					(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
				_sounds[k_str] = stream

	# 2. Tạo Pool AudioStreamPlayer SFX với volume_db = -14.0 dịu êm
	for i: int in range(POOL_SIZE):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		p.bus = "Master"
		p.volume_db = -14.0
		add_child(p)
		_players.append(p)

	# 3. Khởi tạo BGM Player riêng biệt chơi nhạc nền mộc mạc êm dịu (-22.0 dB)
	_setup_bgm_player()

	print("[AudioManager] Initialized with %d sounds, %d pooled players, BGM ready." % [_sounds.size(), _players.size()])

func _setup_bgm_player() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "CozyBGMPlayer"
	_bgm_player.bus = "Master"
	_bgm_player.volume_db = DEFAULT_BGM_VOLUME
	add_child(_bgm_player)

	if FileAccess.file_exists(BGM_PATH):
		var bgm_stream: AudioStream = load(BGM_PATH) as AudioStream
		if bgm_stream != null:
			if bgm_stream is AudioStreamWAV:
				var wav: AudioStreamWAV = bgm_stream as AudioStreamWAV
				wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
			_bgm_player.stream = bgm_stream
			# Kết nối sự kiện finished để bảo đảm loop 100% mượt mà, không gây tiếng rè do loop_begin == loop_end == 0
			_bgm_player.finished.connect(_on_bgm_finished)
			if not is_muted:
				_bgm_player.play()
				print("[AudioManager] Cozy farm background music started (looping at %s dB)." % DEFAULT_BGM_VOLUME)

func _on_bgm_finished() -> void:
	if not is_muted and _bgm_player != null and is_instance_valid(_bgm_player):
		_bgm_player.play()

func play_sfx(sfx_name: String) -> void:
	if is_muted:
		return
	
	var clean_key: String = sfx_name.to_lower().strip_edges()
	if not _sounds.has(clean_key):
		if not clean_key.begins_with("sfx_"):
			clean_key = "sfx_" + clean_key
		if not _sounds.has(clean_key):
			return

	var now: float = float(Time.get_ticks_msec()) / 1000.0
	if _last_play_time.has(clean_key):
		if now - float(_last_play_time[clean_key]) < MIN_INTERVAL:
			return
	_last_play_time[clean_key] = now

	var stream: AudioStream = _sounds[clean_key] as AudioStream
	if stream == null or _players.is_empty():
		return

	# Lấy player rảnh tiếp theo trong pool
	var player: AudioStreamPlayer = _players[_current_player_idx]
	_current_player_idx = (_current_player_idx + 1) % _players.size()
	
	# Hiệu ứng Combo Pitch Shifting (Stardew Valley / Hay Day Swipe Feel)
	var pitch: float = randf_range(0.97, 1.04)
	if clean_key.contains("harvest") or clean_key.contains("plant") or clean_key.contains("coin"):
		if now - _last_combo_time <= 0.85:
			_combo_count = mini(_combo_count + 1, 8)
		else:
			_combo_count = 0
		_last_combo_time = now
		pitch = 1.0 + float(_combo_count) * 0.04 + randf_range(-0.015, 0.015)
	
	player.stop()
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = -14.0
	player.play()

func play_bgm() -> void:
	if is_muted or _bgm_player == null or not is_instance_valid(_bgm_player):
		return
	if not _bgm_player.playing and _bgm_player.stream != null:
		_bgm_player.play()

func stop_bgm() -> void:
	if _bgm_player != null and is_instance_valid(_bgm_player):
		_bgm_player.stop()

func set_bgm_volume(volume_db: float) -> void:
	if _bgm_player != null and is_instance_valid(_bgm_player):
		_bgm_player.volume_db = volume_db

func toggle_mute() -> bool:
	is_muted = not is_muted
	if is_muted:
		for p: AudioStreamPlayer in _players:
			if is_instance_valid(p):
				p.stop()
		stop_bgm()
	else:
		play_bgm()
	print("[AudioManager] Sound muted: ", is_muted)
	return is_muted
