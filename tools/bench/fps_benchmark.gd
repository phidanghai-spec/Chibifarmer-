extends SceneTree

var _elapsed: float = 0.0
var _phase_idx: int = 0
var _frame_times_ms: Array[float] = []
var _fps_samples: Array[float] = []
var _draw_calls_samples: Array[float] = []
var _main_farm: Node2D = null
var _env_dir: Node2D = null
var _camera: Camera2D = null
var _done: bool = false

const DURATION_SECONDS: float = 18.0
const STATES: Array[Dictionary] = [
	{"phase": 1, "weather": 0, "name": "NOON + SUNNY_BREEZE", "cam": Vector2(440.0, 500.0)},
	{"phase": 0, "weather": 0, "name": "DAWN + SUNNY_BREEZE", "cam": Vector2(885.0, 480.0)},
	{"phase": 2, "weather": 2, "name": "SUNSET + BALLOON_FESTIVAL", "cam": Vector2(1380.0, 420.0)},
	{"phase": 3, "weather": 0, "name": "NIGHT + FIREFLIES_LANTERNS", "cam": Vector2(885.0, 560.0)},
	{"phase": 1, "weather": 1, "name": "NOON + COZY_RAIN", "cam": Vector2(580.0, 540.0)}
]

func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/main/MainFarm.tscn") as PackedScene
	if packed == null:
		push_error("Failed to load MainFarm.tscn")
		quit(1)
		return
	_main_farm = packed.instantiate() as Node2D
	root.add_child(_main_farm)
	current_scene = _main_farm
	_env_dir = _main_farm.get_node_or_null("EnvironmentDirector") as Node2D
	_camera = _main_farm.get_node_or_null("Camera2D") as Camera2D
	print("[FPS_BENCH] Started MainFarm windowed benchmark (GL Compatibility)")
	_apply_state(0)

func _apply_state(idx: int) -> void:
	if _env_dir == null:
		return
	var st: Dictionary = STATES[idx]
	_env_dir.call("_apply_time_phase", int(st["phase"]))
	_env_dir.call("_apply_weather", int(st["weather"]))
	if _camera != null:
		_camera.position = st["cam"] as Vector2
	print("[FPS_BENCH] Switched state -> ", st["name"])

func _process(delta: float) -> bool:
	if _done:
		return true
	_elapsed += delta
	# Ignore first 1.5s warm-up while scene/textures initialize
	if _elapsed >= 1.5:
		_frame_times_ms.append(delta * 1000.0)
		_fps_samples.append(Engine.get_frames_per_second())
		_draw_calls_samples.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))

	var target_idx: int = mini(int(_elapsed / (DURATION_SECONDS / float(STATES.size()))), STATES.size() - 1)
	if target_idx != _phase_idx:
		_phase_idx = target_idx
		_apply_state(_phase_idx)

	if _elapsed >= DURATION_SECONDS:
		_done = true
		_print_report()
		quit(0)
		return true
	return false

func _print_report() -> void:
	if _frame_times_ms.is_empty():
		print("[FPS_BENCH] No samples collected")
		return
	var sorted_ft: Array[float] = _frame_times_ms.duplicate()
	sorted_ft.sort()
	var sum_ft: float = 0.0
	var max_ft: float = 0.0
	var min_ft: float = 99999.0
	for ft: float in sorted_ft:
		sum_ft += ft
		if ft > max_ft:
			max_ft = ft
		if ft < min_ft:
			min_ft = ft
	var avg_ft: float = sum_ft / float(sorted_ft.size())
	var p95_ft: float = sorted_ft[mini(int(float(sorted_ft.size()) * 0.95), sorted_ft.size() - 1)]
	var p99_ft: float = sorted_ft[mini(int(float(sorted_ft.size()) * 0.99), sorted_ft.size() - 1)]

	var sum_fps: float = 0.0
	var min_fps: float = 99999.0
	var max_fps: float = 0.0
	for f: float in _fps_samples:
		sum_fps += f
		if f < min_fps:
			min_fps = f
		if f > max_fps:
			max_fps = f
	var avg_fps: float = sum_fps / float(_fps_samples.size())

	var sum_dc: float = 0.0
	var max_dc: float = 0.0
	for dc: float in _draw_calls_samples:
		sum_dc += dc
		if dc > max_dc:
			max_dc = dc
	var avg_dc: float = sum_dc / float(_draw_calls_samples.size())

	var static_mem_mb: float = Performance.get_monitor(Performance.MEMORY_STATIC) / (1024.0 * 1024.0)
	var obj_count: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))

	print("==========================================")
	print("[FPS_BENCH_RESULT] Duration_s=", snappedf(_elapsed, 0.01), " Samples=", sorted_ft.size())
	print("[FPS_BENCH_RESULT] Engine_FPS avg=", snappedf(avg_fps, 0.2), " min=", snappedf(min_fps, 0.2), " max=", snappedf(max_fps, 0.2))
	print("[FPS_BENCH_RESULT] FrameTime_ms avg=", snappedf(avg_ft, 0.01), " min=", snappedf(min_ft, 0.01), " p95=", snappedf(p95_ft, 0.01), " p99=", snappedf(p99_ft, 0.01), " max=", snappedf(max_ft, 0.01))
	print("[FPS_BENCH_RESULT] Equivalent_Avg_FPS=", snappedf(1000.0 / avg_ft, 0.2))
	print("[FPS_BENCH_RESULT] DrawCalls avg=", snappedf(avg_dc, 0.1), " max=", int(max_dc))
	print("[FPS_BENCH_RESULT] StaticMem_MB=", snappedf(static_mem_mb, 0.01), " ObjectCount=", obj_count)
	print("==========================================")
