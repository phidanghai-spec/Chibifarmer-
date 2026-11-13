extends Node

const VERBOSE_LOG: bool = false
const SAVE_PATH: String = "user://hayday_save.json"

const SAVE_VERSION: int = 10
const MAX_OFFLINE_SECONDS: int = 28800 # 8 hours limit

signal player_settings_changed()
signal zoo_updated(animal_id: String)
signal puzzle_pieces_changed(new_count: int)
signal quest_updated(quest_id: String)
signal balloon_upgraded(new_level: int)
signal poodle_updated()
signal newspaper_updated()

var custom_decorations: Array = []
var building_custom_names: Dictionary = {} # building_id -> String
var custom_building_positions: Dictionary = {} # building_id / instance_id -> Dictionary
var unlocked_buildings: Array = ["farmhouse", "silo", "barn", "roadside_shop", "truck", "chicken", "chicken_pen", "feed_mill"]

var selected_character: String = "minh" # "minh"/"male" or "mai"/"female"
var player_name: String = "Nông Dân"
var farm_name: String = "Nông Trại Chibi"
var avatar_config: Dictionary = {
	"body": "body_warm_ivory",
	"eyes": "eyes_sparkle_brown",
	"hair": "hair_braid_chestnut",
	"outfit": "outfit_denim_overalls",
	"hat": "hat_straw_ribbon",
	"poodle": "poodle_apricot_red"
}

var instant_interact: bool = true
var player_position: Vector2 = Vector2(70.0, 640.0)

# Zoo Sanctuary & Balloon System
var puzzle_pieces: int = 0
var balloon_level: int = 1
var zoo_data: Dictionary = {
	"zoo_capybara": { "unlocked": false, "fed_until": 0, "love_count": 0 },
	"zoo_panda": { "unlocked": false, "fed_until": 0, "love_count": 0 },
	"zoo_penguin": { "unlocked": false, "fed_until": 0, "love_count": 0 },
	"zoo_giraffe": { "unlocked": false, "fed_until": 0, "love_count": 0 }
}

# Pet Poodle
var poodle_affinity: int = 0
var poodle_feed_count: int = 0
var poodle_next_dig_timestamp: int = 0
var is_tutorial_completed: bool = false
var last_save_timestamp: int = 0

# Daily Newspaper
var newspaper_data: Dictionary = {}
var newspaper_next_refresh: int = 0

# River Steamboat
var steamboat_data: Dictionary = {}
var steamboat_next_arrival: int = 0
signal steamboat_updated()

# Quest System
var quests_data: Dictionary = {}
var daily_quests_data: Dictionary = {}
var daily_activity_points: int = 0
var daily_chest_50_claimed: bool = false
var daily_chest_100_claimed: bool = false
var vip_requests: Array = []


var _accum_save: float = 0.0
const AUTO_SAVE_INTERVAL: float = 30.0
var current_slot: int = 1
var is_test_mode: bool = false

func set_test_mode(enabled: bool) -> void:
	is_test_mode = enabled

func _detect_test_mode() -> bool:
	if is_test_mode:
		return true
	for arg: String in OS.get_cmdline_args():
		var low: String = arg.to_lower()
		if "--test" in low or "gdunit" in low or "res://tests/" in low:
			is_test_mode = true
			return true
	for arg: String in OS.get_cmdline_user_args():
		var low: String = arg.to_lower()
		if "--test" in low or "gdunit" in low or "res://tests/" in low:
			is_test_mode = true
			return true
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene", "")
	if main_scene.begins_with("res://tests/"):
		is_test_mode = true
		return true
	var tree: SceneTree = get_tree()
	if tree != null and tree.current_scene != null:
		if tree.current_scene.scene_file_path.begins_with("res://tests/"):
			is_test_mode = true
			return true
	return false

func set_tutorial_completed(completed: bool) -> void:
	is_tutorial_completed = completed
	save_game()

func get_current_slot_data() -> Dictionary:
	var count: int = 0
	for z_id: String in zoo_data:
		var z_info: Dictionary = zoo_data[z_id] as Dictionary
		if z_info.get("unlocked", false):
			count += 1
	return {
		"is_tutorial_completed": is_tutorial_completed,
		"last_timestamp": last_save_timestamp if last_save_timestamp > 0 else TickManager.now(),
		"attraction_score": GridManager.total_attraction_score if GridManager != null else 10,
		"zoo_animals_count": maxi(1, count),
		"zoo_enclosures": zoo_data.duplicate()
	}

func get_active_save_path() -> String:
	if is_test_mode or _detect_test_mode():
		return "user://test_bot_temp_save.json"
	return SaveSlotService.get_slot_path(current_slot)


func _ready() -> void:
	_detect_test_mode()
	_register_construction_materials()
	SaveSlotService.ensure_save_directory()
	EventBus.save_slot_selected.connect(_on_save_slot_selected)
	var latest: int = SaveSlotService.get_latest_active_slot()
	if latest != -1:
		current_slot = latest
	if not load_game():
		if not StorageManager.barn_items.has("mat_plank"):
			StorageManager.barn_items["mat_plank"] = 4
		if not StorageManager.barn_items.has("mat_bolt"):
			StorageManager.barn_items["mat_bolt"] = 4
		if not StorageManager.barn_items.has("mat_brick"):
			StorageManager.barn_items["mat_brick"] = 2

func _normalize_building_id(b_id: String) -> String:
	match b_id:
		"chicken_pen": return "chicken"
		"cow_pen", "cow_pasture": return "cow"
		"pig_pen": return "pig"
		"sheep_pen", "sheep_pasture": return "sheep"
		"bee_hive": return "beehive_tree"
		"pet_house_poodle", "pet_poodle": return "poodle_house"
	return b_id

func is_building_constructed(b_id: String) -> bool:
	if is_test_mode or _detect_test_mode():
		return true
	var norm: String = _normalize_building_id(b_id)
	if norm in ["farmhouse", "silo", "barn", "roadside_shop", "truck", "chicken", "feed_mill"]:
		return true
	return unlocked_buildings.has(norm) or unlocked_buildings.has(b_id)

func mark_building_constructed(b_id: String) -> void:
	var norm: String = _normalize_building_id(b_id)
	if not unlocked_buildings.has(norm):
		unlocked_buildings.append(norm)
	if not unlocked_buildings.has(b_id):
		unlocked_buildings.append(b_id)
	save_game()

func _register_construction_materials() -> void:
	if DataManager != null:
		DataManager.items["mat_plank"] = {
			"id": "mat_plank",
			"name": "Ván Gỗ Thông",
			"storage_type": "barn",
			"base_price": 45,
			"unlock_level": 1
		}
		DataManager.items["mat_bolt"] = {
			"id": "mat_bolt",
			"name": "Đinh Tán Thép",
			"storage_type": "barn",
			"base_price": 45,
			"unlock_level": 1
		}
		DataManager.items["mat_brick"] = {
			"id": "mat_brick",
			"name": "Gạch Nung Đỏ",
			"storage_type": "barn",
			"base_price": 50,
			"unlock_level": 1
		}
	if SpriteAtlasManager != null:
		for mat_id: String in ["mat_plank", "mat_bolt", "mat_brick"]:
			if not SpriteAtlasManager.textures.has(mat_id):
				SpriteAtlasManager.textures[mat_id] = _make_material_icon_texture(mat_id)

func _make_material_icon_texture(mat_id: String) -> ImageTexture:
	var img: Image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var outline_col: Color = Color(0.28, 0.16, 0.08, 1.0)
	if mat_id == "mat_plank":
		var wood_base: Color = Color(0.84, 0.56, 0.28, 1.0)
		var wood_hi: Color = Color(0.94, 0.72, 0.42, 1.0)
		var wood_grain: Color = Color(0.66, 0.40, 0.18, 1.0)
		for y: int in range(14, 50):
			for x: int in range(8, 56):
				if x == 8 or x == 55 or y == 14 or y == 25 or y == 27 or y == 38 or y == 49:
					img.set_pixel(x, y, outline_col)
				elif y == 26 or y == 39:
					img.set_pixel(x, y, Color(0, 0, 0, 0))
				elif (y + x / 6) % 5 == 0:
					img.set_pixel(x, y, wood_grain)
				elif y in [15, 16, 28, 29, 40, 41]:
					img.set_pixel(x, y, wood_hi)
				else:
					img.set_pixel(x, y, wood_base)
	elif mat_id == "mat_bolt":
		var steel_base: Color = Color(0.68, 0.76, 0.84, 1.0)
		var steel_hi: Color = Color(0.88, 0.93, 0.98, 1.0)
		var steel_dark: Color = Color(0.45, 0.52, 0.62, 1.0)
		for y: int in range(12, 26):
			for x: int in range(16, 48):
				if x == 16 or x == 47 or y == 12 or y == 25:
					img.set_pixel(x, y, outline_col)
				elif y <= 16:
					img.set_pixel(x, y, steel_hi)
				else:
					img.set_pixel(x, y, steel_base)
		for y: int in range(26, 52):
			for x: int in range(24, 40):
				if x == 24 or x == 39 or y == 51:
					img.set_pixel(x, y, outline_col)
				elif y % 5 == 0:
					img.set_pixel(x, y, steel_dark)
				elif x <= 28:
					img.set_pixel(x, y, steel_hi)
				else:
					img.set_pixel(x, y, steel_base)
	else:
		var brick_base: Color = Color(0.82, 0.32, 0.24, 1.0)
		var brick_hi: Color = Color(0.94, 0.48, 0.36, 1.0)
		var mortar: Color = Color(0.92, 0.88, 0.80, 1.0)
		for y: int in range(14, 50):
			for x: int in range(10, 54):
				if x == 10 or x == 53 or y == 14 or y == 49:
					img.set_pixel(x, y, outline_col)
				elif y in [25, 26, 37, 38] or (y < 25 and x in [31, 32]) or (y in range(27, 37) and x in [21, 22, 41, 42]) or (y > 38 and x in [31, 32]):
					img.set_pixel(x, y, mortar)
				elif y in [15, 16, 27, 28, 39, 40]:
					img.set_pixel(x, y, brick_hi)
				else:
					img.set_pixel(x, y, brick_base)
	return ImageTexture.create_from_image(img)

func _on_save_slot_selected(slot_index: int, is_new_game: bool) -> void:
	current_slot = clampi(slot_index, 1, SaveSlotService.MAX_SLOTS)
	if is_new_game:
		reset_to_level_1()
	else:
		load_game()

func get_building_name(building_id: String, default_name: String) -> String:
	return String(building_custom_names.get(building_id, default_name))

func set_building_name(building_id: String, new_name: String) -> void:
	var trimmed: String = new_name.strip_edges()
	if trimmed == "":
		building_custom_names.erase(building_id)
	else:
		building_custom_names[building_id] = trimmed.substr(0, 16)
	save_game()

func _process(delta: float) -> void:
	_accum_save += delta
	if _accum_save >= AUTO_SAVE_INTERVAL:
		_accum_save = 0.0
		save_game()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()

func reset_save() -> void:
	reset_to_level_1()

func reset_to_new_farm() -> void:
	reset_to_level_1()

func reset_to_level_1() -> void:
	var active_p: String = get_active_save_path()
	if FileAccess.file_exists(active_p):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(active_p))
	if not (is_test_mode or _detect_test_mode()):
		if FileAccess.file_exists(SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		var custom_pos_path: String = "user://custom_structure_positions.json"
		if FileAccess.file_exists(custom_pos_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(custom_pos_path))
	print("[SaveManager] Reset and removed save files for Level 1 fresh start: ", active_p)

	custom_decorations.clear()
	building_custom_names.clear()
	custom_building_positions.clear()
	unlocked_buildings = ["farmhouse", "silo", "barn", "roadside_shop", "truck", "chicken", "chicken_pen", "feed_mill"]
	
	StorageManager.level = 1
	StorageManager.xp = 0
	StorageManager.gold = 500
	StorageManager.coins = 100
	StorageManager.diamonds = 15
	StorageManager.silo_capacity = 100
	StorageManager.barn_capacity = 100
	
	StorageManager.silo_items.clear()
	StorageManager.silo_items["wheat"] = 10
	StorageManager.silo_items["corn"] = 5
	StorageManager.silo_items["carrot"] = 5
	StorageManager.silo_items["apple_seed"] = 2
	StorageManager.silo_items["mango_seed"] = 2
	
	StorageManager.barn_items.clear()
	StorageManager.barn_items["chicken_feed"] = 5
	StorageManager.barn_items["cow_feed"] = 5
	StorageManager.barn_items["egg"] = 2
	StorageManager.barn_items["milk"] = 2
	StorageManager.barn_items["mat_plank"] = 4
	StorageManager.barn_items["mat_bolt"] = 4
	StorageManager.barn_items["mat_brick"] = 2

	puzzle_pieces = 0
	balloon_level = 1
	poodle_affinity = 0
	poodle_feed_count = 0
	poodle_next_dig_timestamp = 0
	is_tutorial_completed = false

	zoo_data = {
		"zoo_capybara": { "unlocked": false, "fed_until": 0, "love_count": 0 },
		"zoo_panda": { "unlocked": false, "fed_until": 0, "love_count": 0 },
		"zoo_penguin": { "unlocked": false, "fed_until": 0, "love_count": 0 },
		"zoo_giraffe": { "unlocked": false, "fed_until": 0, "love_count": 0 }
	}

	quests_data.clear()
	daily_quests_data.clear()
	daily_activity_points = 0
	daily_chest_50_claimed = false
	daily_chest_100_claimed = false
	
	StorageManager.recalculate_capacities()
	EventBus.coins_changed.emit(StorageManager.coins, 0)
	EventBus.gold_changed.emit(StorageManager.gold, 0)
	EventBus.diamonds_changed.emit(StorageManager.diamonds, 0)
	EventBus.xp_changed.emit(StorageManager.xp, StorageManager.get_required_xp(StorageManager.level), StorageManager.level)
	zoo_updated.emit("")
	puzzle_pieces_changed.emit(puzzle_pieces)

	selected_character = "minh"
	player_name = "Nông Dân"
	farm_name = "Nông Trại Chibi"
	instant_interact = true
	player_position = Vector2(70.0, 640.0)
	player_settings_changed.emit()
	print("[SaveManager] Successfully reset account to Fresh Level 1!")

func set_sandbox_level_33() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var global_p: String = ProjectSettings.globalize_path(SAVE_PATH)
		DirAccess.remove_absolute(global_p)
	
	StorageManager.level = 33
	StorageManager.xp = 0
	StorageManager.gold = 190556
	StorageManager.coins = 50000
	StorageManager.diamonds = 250
	StorageManager.silo_capacity = 600
	StorageManager.barn_capacity = 600
	puzzle_pieces = 25
	balloon_level = 2
	poodle_affinity = 120
	poodle_feed_count = 3
	
	# Unlock all sanctuary animals
	unlock_animal("zoo_capybara")
	unlock_animal("zoo_panda")
	unlock_animal("zoo_penguin")
	unlock_animal("zoo_giraffe")
	
	StorageManager.silo_items.clear()
	StorageManager.silo_items["wheat"] = 80
	StorageManager.silo_items["corn"] = 60
	StorageManager.silo_items["tomato"] = 35
	StorageManager.silo_items["carrot"] = 35
	StorageManager.silo_items["strawberry"] = 30
	StorageManager.silo_items["pumpkin"] = 30
	StorageManager.silo_items["soybean"] = 30
	StorageManager.silo_items["sugarcane"] = 30
	StorageManager.silo_items["apple"] = 25
	StorageManager.silo_items["mango"] = 25
	StorageManager.silo_items["sunflower"] = 20
	StorageManager.silo_items["rose"] = 20
	StorageManager.silo_items["lavender"] = 20
	StorageManager.silo_items["apple_seed"] = 15
	StorageManager.silo_items["mango_seed"] = 15
	
	StorageManager.barn_items.clear()
	StorageManager.barn_items["egg"] = 50
	StorageManager.barn_items["milk"] = 45
	StorageManager.barn_items["bacon"] = 35
	StorageManager.barn_items["wool"] = 25
	StorageManager.barn_items["chicken_feed"] = 40
	StorageManager.barn_items["cow_feed"] = 40
	StorageManager.barn_items["pig_feed"] = 30
	StorageManager.barn_items["bread"] = 30
	StorageManager.barn_items["butter"] = 20
	StorageManager.barn_items["cheese"] = 20
	StorageManager.barn_items["cream"] = 20
	StorageManager.barn_items["cookie"] = 20
	StorageManager.barn_items["cream_cake"] = 15
	StorageManager.barn_items["sugarcane_juice"] = 20
	StorageManager.barn_items["apple_juice"] = 20
	StorageManager.barn_items["mango_smoothie"] = 20
	StorageManager.barn_items["fish_carp"] = 20
	StorageManager.barn_items["fish_bass"] = 15
	StorageManager.barn_items["fish_golden_koi"] = 8
	StorageManager.barn_items["bait_red"] = 15
	StorageManager.barn_items["bait_gold"] = 10
	StorageManager.barn_items["sanctuary_feed"] = 30
	StorageManager.barn_items["mat_plank"] = 50
	StorageManager.barn_items["mat_bolt"] = 50
	StorageManager.barn_items["mat_brick"] = 50
	unlocked_buildings = [
		"farmhouse", "silo", "barn", "roadside_shop", "truck",
		"chicken", "chicken_pen", "cow", "cow_pen", "pig", "pig_pen", "sheep", "sheep_pen",
		"feed_mill", "bakery", "juice_stand", "cake_oven", "beehive_tree", "bee_hive", "poodle_house"
	]
	
	EventBus.coins_changed.emit(StorageManager.coins, 0)
	EventBus.gold_changed.emit(StorageManager.gold, 0)
	EventBus.diamonds_changed.emit(StorageManager.diamonds, 0)
	EventBus.xp_changed.emit(StorageManager.xp, StorageManager.get_required_xp(StorageManager.level), StorageManager.level)
	EventBus.storage_updated.emit("silo", StorageManager.get_silo_used(), StorageManager.silo_capacity)
	EventBus.storage_updated.emit("barn", StorageManager.get_barn_used(), StorageManager.barn_capacity)
	zoo_updated.emit("")
	puzzle_pieces_changed.emit(puzzle_pieces)
	save_game()
	print("[SaveManager] Successfully activated Sandbox Mode Level 33!")

func set_sandbox_level_32() -> void:
	set_sandbox_level_33()

func save_game() -> void:
	var save_data: Dictionary = {
		"version": SAVE_VERSION,
		"save_timestamp": TickManager.now(),
		"economy": {
			"coins": StorageManager.coins,
			"gold": StorageManager.gold,
			"diamonds": StorageManager.diamonds,
			"xp": StorageManager.xp,
			"level": StorageManager.level,
			"silo_capacity": StorageManager.silo_capacity,
			"barn_capacity": StorageManager.barn_capacity,
			"silo_items": StorageManager.silo_items.duplicate(),
			"barn_items": StorageManager.barn_items.duplicate()
		},
		"building_custom_names": building_custom_names.duplicate(),
		"custom_building_positions": custom_building_positions.duplicate(true),
		"unlocked_buildings": unlocked_buildings.duplicate(),
		"attraction_score": GridManager.total_attraction_score
	}
	
	# Save Roadside Shop slots if available
	if RoadsideShop != null:
		save_data["roadside_shop"] = RoadsideShop.get_slots().duplicate(true)
	
	# Save Custom Decorations layout
	save_data["custom_decorations"] = custom_decorations.duplicate(true)
	
	# Save Player Avatar
	save_data["player"] = {
		"selected_character": selected_character,
		"player_name": player_name,
		"farm_name": farm_name,
		"avatar_config": avatar_config.duplicate(true),
		"instant_interact": instant_interact,
		"position_x": player_position.x,
		"position_y": player_position.y
	}
	save_data["farm_name"] = farm_name
	save_data["avatar_config"] = avatar_config.duplicate(true)
	save_data["is_tutorial_completed"] = is_tutorial_completed
	
	# Save Zoo Sanctuary & Balloon
	save_data["zoo_sanctuary"] = {
		"puzzle_pieces": puzzle_pieces,
		"animals": zoo_data.duplicate(true),
		"balloon_level": balloon_level
	}
	
	# Save Pet Poodle & Newspaper
	save_data["poodle"] = {
		"affinity": poodle_affinity,
		"feed_count": poodle_feed_count,
		"next_dig_timestamp": poodle_next_dig_timestamp
	}
	save_data["newspaper"] = {
		"data": newspaper_data.duplicate(true),
		"next_refresh": newspaper_next_refresh
	}
	save_data["steamboat"] = {
		"data": steamboat_data.duplicate(true),
		"next_arrival": steamboat_next_arrival
	}
	
	# Save Quests
	save_data["quests"] = {
		"story": quests_data.duplicate(true),
		"daily": daily_quests_data.duplicate(true),
		"activity_points": daily_activity_points,
		"chest_50": daily_chest_50_claimed,
		"chest_100": daily_chest_100_claimed,
		"vip_requests": vip_requests.duplicate(true)
	}
	
	var json_str: String = JSON.stringify(save_data, "\t")
	var target_path: String = get_active_save_path()
	if OS.has_feature("web"):
		var web_file: FileAccess = FileAccess.open(target_path, FileAccess.WRITE)
		if web_file != null:
			web_file.store_string(json_str)
			web_file.close()
		if not (is_test_mode or _detect_test_mode()):
			var web_leg: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
			if web_leg != null:
				web_leg.store_string(json_str)
				web_leg.close()
		return
	var temp_path: String = target_path + ".tmp"
	var file: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
	if file != null:
		file.store_string(json_str)
		file.close()
		if FileAccess.file_exists(temp_path):
			var global_temp: String = ProjectSettings.globalize_path(temp_path)
			var global_target: String = ProjectSettings.globalize_path(target_path)
			var rename_err: Error = DirAccess.rename_absolute(global_temp, global_target)
			if rename_err != OK:
				var copy_err: Error = DirAccess.copy_absolute(global_temp, global_target)
				if copy_err == OK:
					DirAccess.remove_absolute(global_temp)
				else:
					push_error("[SaveManager] Failed to atomic save: " + error_string(rename_err))
			if VERBOSE_LOG:
				print("[SaveManager] Game state saved successfully to slot %d: %s" % [current_slot, target_path])
	else:
		push_error("[SaveManager] Failed to write temp save file: " + str(FileAccess.get_open_error()))
	
	if not (is_test_mode or _detect_test_mode()):
		var leg_temp: String = SAVE_PATH + ".tmp"
		var leg_file: FileAccess = FileAccess.open(leg_temp, FileAccess.WRITE)
		if leg_file != null:
			leg_file.store_string(json_str)
			leg_file.close()
			if FileAccess.file_exists(leg_temp):
				var g_leg_temp: String = ProjectSettings.globalize_path(leg_temp)
				var g_leg_target: String = ProjectSettings.globalize_path(SAVE_PATH)
				var leg_err: Error = DirAccess.rename_absolute(g_leg_temp, g_leg_target)
				if leg_err != OK:
					if DirAccess.copy_absolute(g_leg_temp, g_leg_target) == OK:
						DirAccess.remove_absolute(g_leg_temp)

func load_game() -> bool:
	var target_path: String = get_active_save_path()
	if not FileAccess.file_exists(target_path):
		if not (is_test_mode or _detect_test_mode()) and FileAccess.file_exists(SAVE_PATH):
			target_path = SAVE_PATH
		else:
			if VERBOSE_LOG:
				print("[SaveManager] No save file found for slot %d, starting fresh game." % current_slot)
			return false
	
	var file: FileAccess = FileAccess.open(target_path, FileAccess.READ)
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
	last_save_timestamp = saved_ts
	is_tutorial_completed = bool(data.get("is_tutorial_completed", false))
	var raw_offline: int = maxi(0, TickManager.now() - saved_ts)
	var offline_elapsed: int = mini(raw_offline, MAX_OFFLINE_SECONDS)
	if VERBOSE_LOG:
		print("[SaveManager] Game loaded! Offline time elapsed: ", offline_elapsed, "s (clamped from ", raw_offline, "s).")
	
	# Restore Economy
	var econ: Dictionary = data.get("economy", {}) as Dictionary
	if not econ.is_empty():
		StorageManager.coins = int(econ.get("coins", StorageManager.coins))
		StorageManager.gold = int(econ.get("gold", StorageManager.gold))
		StorageManager.diamonds = int(econ.get("diamonds", StorageManager.diamonds))
		StorageManager.xp = int(econ.get("xp", StorageManager.xp))
		StorageManager.level = int(econ.get("level", StorageManager.level))
		StorageManager.silo_capacity = maxi(100, int(econ.get("silo_capacity", 100)))
		StorageManager.barn_capacity = maxi(100, int(econ.get("barn_capacity", 100)))
		
		var s_items: Dictionary = econ.get("silo_items", {}) as Dictionary
		if not s_items.is_empty():
			StorageManager.silo_items = s_items
		
		var b_items: Dictionary = econ.get("barn_items", {}) as Dictionary
		if not b_items.is_empty():
			StorageManager.barn_items = b_items

		if StorageManager.level >= 20:
			# Guarantee large stockpile of seeds, crops and flora
			var guaranteed_silo: Dictionary = {
				"wheat": 80,
				"corn": 60,
				"carrot": 50,
				"tomato": 40,
				"strawberry": 40,
				"pumpkin": 35,
				"soybean": 35,
				"sugarcane": 35,
				"apple": 25,
				"mango": 25,
				"sunflower": 20,
				"rose": 20,
				"lavender": 20,
				"apple_seed": 15,
				"mango_seed": 15
			}
			for k: String in guaranteed_silo:
				if int(StorageManager.silo_items.get(k, 0)) < int(guaranteed_silo[k]):
					StorageManager.silo_items[k] = int(guaranteed_silo[k])
			
			# Guarantee large stockpile of animal feeds and artisanal foods
			var guaranteed_barn: Dictionary = {
				"egg": 40,
				"milk": 40,
				"bacon": 30,
				"bread": 30,
				"cookie": 25,
				"butter": 20,
				"cheese": 20,
				"chicken_feed": 35,
				"cow_feed": 35,
				"pig_feed": 30,
				"sanctuary_feed": 20,
				"fish_carp": 20,
				"fish_bass": 15
			}
			for k: String in guaranteed_barn:
				if int(StorageManager.barn_items.get(k, 0)) < int(guaranteed_barn[k]):
					StorageManager.barn_items[k] = int(guaranteed_barn[k])
		
		StorageManager.recalculate_capacities()
		EventBus.coins_changed.emit(StorageManager.coins, 0)
		EventBus.gold_changed.emit(StorageManager.gold, 0)
		EventBus.diamonds_changed.emit(StorageManager.diamonds, 0)
		EventBus.xp_changed.emit(StorageManager.xp, StorageManager.get_required_xp(StorageManager.level), StorageManager.level)
	
	# Restore Building Custom Names
	if data.has("building_custom_names"):
		building_custom_names = (data["building_custom_names"] as Dictionary).duplicate()
	else:
		building_custom_names = {}
	
	# Restore Custom Building Positions
	if data.has("custom_building_positions"):
		custom_building_positions = (data["custom_building_positions"] as Dictionary).duplicate(true)
	else:
		custom_building_positions = {}
	
	# Restore Unlocked Buildings
	if data.has("unlocked_buildings"):
		unlocked_buildings = (data["unlocked_buildings"] as Array).duplicate()
	elif StorageManager.level >= 7:
		unlocked_buildings = [
			"farmhouse", "silo", "barn", "roadside_shop", "truck",
			"chicken", "chicken_pen", "cow", "cow_pen", "pig", "pig_pen", "sheep", "sheep_pen",
			"feed_mill", "bakery", "juice_stand", "cake_oven", "beehive_tree", "bee_hive", "poodle_house"
		]
	else:
		unlocked_buildings = ["farmhouse", "silo", "barn", "roadside_shop", "truck", "chicken", "chicken_pen", "feed_mill"]
	
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
	
	# Restore Player Avatar
	if data.has("farm_name"):
		farm_name = String(data["farm_name"])
	elif data.has("player") and (data["player"] as Dictionary).has("farm_name"):
		farm_name = String((data["player"] as Dictionary)["farm_name"])

	if data.has("avatar_config"):
		avatar_config = (data["avatar_config"] as Dictionary).duplicate(true)

	if data.has("player"):
		var p_data: Dictionary = data["player"] as Dictionary
		selected_character = String(p_data.get("selected_character", "minh"))
		player_name = String(p_data.get("player_name", "Nông Dân"))
		if p_data.has("farm_name"):
			farm_name = String(p_data.get("farm_name", farm_name))
		if p_data.has("avatar_config"):
			avatar_config = (p_data["avatar_config"] as Dictionary).duplicate(true)
		instant_interact = bool(p_data.get("instant_interact", true))
		var px: float = float(p_data.get("position_x", 70.0))
		var py: float = float(p_data.get("position_y", 640.0))
		player_position = Vector2(px, py)
		player_settings_changed.emit()
	
	# Restore Zoo Sanctuary
	if data.has("zoo_sanctuary"):
		var z_data: Dictionary = data["zoo_sanctuary"] as Dictionary
		puzzle_pieces = int(z_data.get("puzzle_pieces", 0))
		balloon_level = int(z_data.get("balloon_level", 1))
		if z_data.has("animals"):
			var anims: Dictionary = z_data["animals"] as Dictionary
			for k: String in anims:
				zoo_data[k] = (anims[k] as Dictionary).duplicate()
	if StorageManager.level < 11 and zoo_data.has("zoo_capybara"):
		var capy: Dictionary = zoo_data["zoo_capybara"] as Dictionary
		if int(capy.get("love_count", 0)) == 0 and int(capy.get("fed_until", 0)) == 0:
			capy["unlocked"] = false
	
	# Restore Pet Poodle & Newspaper
	if data.has("poodle"):
		var p_d: Dictionary = data["poodle"] as Dictionary
		poodle_affinity = int(p_d.get("affinity", 0))
		poodle_feed_count = int(p_d.get("feed_count", 0))
		poodle_next_dig_timestamp = int(p_d.get("next_dig_timestamp", 0))
	if data.has("newspaper"):
		var n_d: Dictionary = data["newspaper"] as Dictionary
		newspaper_data = (n_d.get("data", {}) as Dictionary).duplicate(true)
		newspaper_next_refresh = int(n_d.get("next_refresh", 0))
	
	# Restore Steamboat
	if data.has("steamboat"):
		var sb_d: Dictionary = data["steamboat"] as Dictionary
		steamboat_data = (sb_d.get("data", {}) as Dictionary).duplicate(true)
		steamboat_next_arrival = int(sb_d.get("next_arrival", 0))
	
	# Restore Quests
	if data.has("quests"):
		var q_data: Dictionary = data["quests"] as Dictionary
		if q_data.has("story"):
			quests_data = (q_data["story"] as Dictionary).duplicate(true)
		if q_data.has("daily"):
			daily_quests_data = (q_data["daily"] as Dictionary).duplicate(true)
		daily_activity_points = int(q_data.get("activity_points", 0))
		daily_chest_50_claimed = bool(q_data.get("chest_50", false))
		daily_chest_100_claimed = bool(q_data.get("chest_100", false))
		if q_data.has("vip_requests"):
			vip_requests = (q_data["vip_requests"] as Array).duplicate(true)
	
	return true

func set_player_character(char_key: String) -> void:
	if selected_character != char_key:
		selected_character = char_key
		player_settings_changed.emit()
		save_game()

func set_player_name(new_name: String) -> void:
	var trimmed: String = new_name.strip_edges()
	if trimmed != "":
		player_name = trimmed.substr(0, 16)
		player_settings_changed.emit()
		save_game()

func set_instant_interact(enabled: bool) -> void:
	if instant_interact != enabled:
		instant_interact = enabled
		player_settings_changed.emit()
		save_game()

func set_player_position(pos: Vector2) -> void:
	player_position = pos

# Zoo Sanctuary Helpers
func add_puzzle_pieces(amount: int) -> void:
	puzzle_pieces += amount
	puzzle_pieces_changed.emit(puzzle_pieces)
	save_game()

func spend_puzzle_pieces(amount: int) -> bool:
	if puzzle_pieces >= amount:
		puzzle_pieces -= amount
		puzzle_pieces_changed.emit(puzzle_pieces)
		save_game()
		return true
	return false

func is_animal_unlocked(animal_id: String) -> bool:
	var entry: Dictionary = zoo_data.get(animal_id, {}) as Dictionary
	return bool(entry.get("unlocked", false))

func unlock_animal(animal_id: String) -> void:
	if not zoo_data.has(animal_id):
		zoo_data[animal_id] = { "unlocked": true, "fed_until": 0, "love_count": 0 }
	else:
		zoo_data[animal_id]["unlocked"] = true
	zoo_updated.emit(animal_id)
	EventBus.zoo_enclosure_unlocked.emit(animal_id)
	save_game()

func is_animal_fed(animal_id: String) -> bool:
	var entry: Dictionary = zoo_data.get(animal_id, {}) as Dictionary
	var fed_until: int = int(entry.get("fed_until", 0))
	return TickManager.now() < fed_until

func feed_animal(animal_id: String, duration_seconds: int = 180) -> void:
	if not zoo_data.has(animal_id):
		zoo_data[animal_id] = { "unlocked": true, "fed_until": 0, "love_count": 0 }
	var cur_love: int = int(zoo_data[animal_id].get("love_count", 0))
	zoo_data[animal_id]["fed_until"] = TickManager.now() + duration_seconds
	zoo_data[animal_id]["love_count"] = cur_love + 1
	zoo_updated.emit(animal_id)
	save_game()

func add_activity_points(amount: int) -> void:
	daily_activity_points = mini(100, daily_activity_points + amount)
	save_game()

func claim_daily_chest(tier: int) -> bool:
	if tier == 50:
		if daily_activity_points >= 50 and not daily_chest_50_claimed:
			daily_chest_50_claimed = true
			add_puzzle_pieces(1)
			StorageManager.add_gold(100)
			StorageManager.add_item("sanctuary_feed", 1)
			save_game()
			return true
	elif tier == 100:
		if daily_activity_points >= 100 and not daily_chest_100_claimed:
			daily_chest_100_claimed = true
			add_puzzle_pieces(2)
			StorageManager.diamonds += 3
			EventBus.diamonds_changed.emit(StorageManager.diamonds, 3)
			StorageManager.add_item("sanctuary_feed", 2)
			save_game()
			return true
	return false



func set_building_custom_position(building_key: String, pos_dict: Dictionary) -> void:
	custom_building_positions[building_key] = pos_dict
	save_game()

func get_building_custom_position(building_key: String) -> Dictionary:
	return custom_building_positions.get(building_key, {}) as Dictionary
