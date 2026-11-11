class_name SaveSlotService
extends RefCounted

const MAX_SLOTS: int = 3
const SAVE_DIR: String = "user://saves/"
const LEGACY_SAVE_PATH: String = "user://hayday_save.json"

static func ensure_save_directory() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	# Tự động di chuyển dữ liệu cũ (nếu có) vào Slot 1 để bảo toàn tiến trình người chơi
	_migrate_legacy_save_if_needed()

static func _migrate_legacy_save_if_needed() -> void:
	var slot_1_path: String = get_slot_path(1)
	if not FileAccess.file_exists(slot_1_path) and FileAccess.file_exists(LEGACY_SAVE_PATH):
		var file_in: FileAccess = FileAccess.open(LEGACY_SAVE_PATH, FileAccess.READ)
		if file_in != null:
			var content: String = file_in.get_as_text()
			file_in.close()
			var file_out: FileAccess = FileAccess.open(slot_1_path, FileAccess.WRITE)
			if file_out != null:
				file_out.store_string(content)
				file_out.close()
				print("[SaveSlotService] Auto-migrated legacy save to Slot 1 successfully!")

static func get_slot_path(slot_index: int) -> String:
	return SAVE_DIR + "farm_slot_" + str(clampi(slot_index, 1, MAX_SLOTS)) + ".json"

static func has_save_slot(slot_index: int) -> bool:
	return FileAccess.file_exists(get_slot_path(slot_index))

static func get_latest_active_slot() -> int:
	ensure_save_directory()
	var latest_slot: int = -1
	var latest_timestamp: int = 0
	for i: int in range(1, MAX_SLOTS + 1):
		var meta: Dictionary = read_slot_summary(i)
		if not meta.is_empty() and not bool(meta.get("is_empty", true)):
			var ts: int = int(meta.get("last_timestamp", 0))
			if ts >= latest_timestamp:
				latest_timestamp = ts
				latest_slot = i
	return latest_slot

static func read_slot_summary(slot_index: int) -> Dictionary:
	ensure_save_directory()
	var path: String = get_slot_path(slot_index)
	if not FileAccess.file_exists(path):
		return {"is_empty": true}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"is_empty": true}
	var raw_text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw_text)
	if typeof(parsed) == TYPE_DICTIONARY:
		var d: Dictionary = parsed as Dictionary
		d["is_empty"] = false
		if d.has("economy"):
			var econ: Dictionary = d.get("economy", {}) as Dictionary
			d["level"] = int(econ.get("level", d.get("level", 1)))
			d["gold"] = int(econ.get("gold", d.get("gold", 500)))
		var p_info: Dictionary = d.get("player", {}) as Dictionary
		d["player_name"] = str(p_info.get("player_name", d.get("player_name", "Minh")))
		d["farm_name"] = str(d.get("farm_name", p_info.get("farm_name", "Nông Trại Chibi")))
		if d.has("save_timestamp") and not d.has("last_timestamp"):
			d["last_timestamp"] = d["save_timestamp"]
		return d
	return {"is_empty": true}

static func write_slot_data(slot_index: int, payload: Dictionary) -> bool:
	ensure_save_directory()
	var path: String = get_slot_path(slot_index)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	payload["last_timestamp"] = int(Time.get_unix_time_from_system())
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return true

static func delete_slot(slot_index: int) -> void:
	var path: String = get_slot_path(slot_index)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		print("[SaveSlotService] Deleted save slot %d at %s" % [slot_index, path])

