extends Node

const SAVE_PATH: String = "user://hayday_save.json"

const SAVE_VERSION: int = 7

var custom_decorations: Array = []

var _accum_save: float = 0.0
const AUTO_SAVE_INTERVAL: float = 30.0

func _ready() -> void:
	load_game()

func _process(delta: float) -> void:
	_accum_save += delta
	if _accum_save >= AUTO_SAVE_INTERVAL:
		_accum_save = 0.0
		save_game()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()

func reset_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var global_p: String = ProjectSettings.globalize_path(SAVE_PATH)
		DirAccess.remove_absolute(global_p)
		print("[SaveManager] Reset and removed legacy save file: ", SAVE_PATH)

func save_game() -> void:
	var save_data: Dictionary = {
		"version": SAVE_VERSION,
		"save_timestamp": TickManager.now(),
		"economy": {
			"gold": StorageManager.gold,
			"diamonds": StorageManager.diamonds,
			"xp": StorageManager.xp,
			"level": StorageManager.level,
			"silo_capacity": StorageManager.silo_capacity,
			"barn_capacity": StorageManager.barn_capacity,
			"silo_items": StorageManager.silo_items.duplicate(),
			"barn_items": StorageManager.barn_items.duplicate()
		},
		"attraction_score": GridManager.total_attraction_score
	}
	
	# Save Roadside Shop slots if available
	if RoadsideShop != null:
		save_data["roadside_shop"] = RoadsideShop.get_slots().duplicate(true)
	
	# Save Custom Decorations layout
	save_data["custom_decorations"] = custom_decorations.duplicate(true)
	
	var json_str: String = JSON.stringify(save_data, "\t")
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(json_str)
		file.close()
		print("[SaveManager] Game state saved successfully to ", SAVE_PATH)
	else:
		push_error("[SaveManager] Failed to write save file: " + str(FileAccess.get_open_error()))

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("[SaveManager] No save file found, starting fresh game.")
		return false
	
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	
	var content: String = file.get_as_text()
	file.close()
	
	var test_json_conv: JSON = JSON.new()
	var err: Error = test_json_conv.parse(content)
	if err != OK or typeof(test_json_conv.data) != TYPE_DICTIONARY:
		push_error("[SaveManager] Save file corrupted or invalid JSON.")
		return false
	
	var data: Dictionary = test_json_conv.data as Dictionary
	var ver: int = int(data.get("version", 0))
	if ver < SAVE_VERSION:
		print("[SaveManager] Legacy save version ", ver, " detected. Resetting to pristine spacious farm layout.")
		reset_save()
		return false
	
	var saved_ts: int = int(data.get("save_timestamp", 0))
	var offline_elapsed: int = maxi(0, TickManager.now() - saved_ts)
	print("[SaveManager] Game loaded! Offline time elapsed: ", offline_elapsed, " seconds.")
	
	# Restore Economy
	var econ: Dictionary = data.get("economy", {}) as Dictionary
	if not econ.is_empty():
		StorageManager.gold = int(econ.get("gold", StorageManager.gold))
		StorageManager.diamonds = int(econ.get("diamonds", StorageManager.diamonds))
		StorageManager.xp = int(econ.get("xp", StorageManager.xp))
		StorageManager.level = int(econ.get("level", StorageManager.level))
		StorageManager.silo_capacity = int(econ.get("silo_capacity", StorageManager.silo_capacity))
		StorageManager.barn_capacity = int(econ.get("barn_capacity", StorageManager.barn_capacity))
		
		var s_items: Dictionary = econ.get("silo_items", {}) as Dictionary
		if not s_items.is_empty():
			StorageManager.silo_items = s_items
			if not StorageManager.silo_items.has("apple_seed"):
				StorageManager.silo_items["apple_seed"] = 2
			if not StorageManager.silo_items.has("mango_seed"):
				StorageManager.silo_items["mango_seed"] = 2
		var b_items: Dictionary = econ.get("barn_items", {}) as Dictionary
		if not b_items.is_empty():
			StorageManager.barn_items = b_items
		
		EventBus.gold_changed.emit(StorageManager.gold, 0)
		EventBus.diamonds_changed.emit(StorageManager.diamonds, 0)
		EventBus.xp_changed.emit(StorageManager.xp, StorageManager.get_required_xp(StorageManager.level), StorageManager.level)
		EventBus.storage_updated.emit("silo", StorageManager.get_silo_used(), StorageManager.silo_capacity)
		EventBus.storage_updated.emit("barn", StorageManager.get_barn_used(), StorageManager.barn_capacity)
	
	# Restore Roadside Shop
	# Restore Custom Decorations
	if data.has("custom_decorations"):
		custom_decorations = (data["custom_decorations"] as Array).duplicate(true)
	else:
		custom_decorations = []
	
	if data.has("roadside_shop") and RoadsideShop != null:
		var saved_slots: Array = data["roadside_shop"] as Array
		if not saved_slots.is_empty():
			RoadsideShop.slots.clear()
			for slot_val: Variant in saved_slots:
				RoadsideShop.slots.append(slot_val as Dictionary)
			RoadsideShop.shop_updated.emit()
	
	return true
