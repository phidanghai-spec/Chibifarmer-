extends Node

const SAVE_PATH: String = "user://hayday_save.json"

const SAVE_VERSION: int = 10
const MAX_OFFLINE_SECONDS: int = 28800 # 8 hours limit

signal player_settings_changed()
signal zoo_updated(animal_id: String)
signal puzzle_pieces_changed(new_count: int)
signal quest_updated(quest_id: String)

var custom_decorations: Array = []
var building_custom_names: Dictionary = {} # building_id -> String

var selected_character: String = "minh" # "minh" or "mai"
var player_name: String = "Minh"
var instant_interact: bool = false
var player_position: Vector2 = Vector2(70.0, 640.0)

# Zoo Sanctuary & Puzzle System
var puzzle_pieces: int = 5
var zoo_data: Dictionary = {
	"zoo_capybara": { "unlocked": true, "fed_until": 0, "love_count": 0 },
	"zoo_panda": { "unlocked": false, "fed_until": 0, "love_count": 0 },
	"zoo_penguin": { "unlocked": false, "fed_until": 0, "love_count": 0 },
	"zoo_giraffe": { "unlocked": false, "fed_until": 0, "love_count": 0 }
}

# Quest System
var quests_data: Dictionary = {}
var daily_quests_data: Dictionary = {}
var daily_activity_points: int = 0
var daily_chest_50_claimed: bool = false
var daily_chest_100_claimed: bool = false
var vip_requests: Array = []


var _accum_save: float = 0.0
const AUTO_SAVE_INTERVAL: float = 30.0

func _ready() -> void:
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

func reset_to_level_1() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var global_p: String = ProjectSettings.globalize_path(SAVE_PATH)
		DirAccess.remove_absolute(global_p)
		print("[SaveManager] Reset and removed save file for Level 1 fresh start: ", SAVE_PATH)
	custom_decorations.clear()
	building_custom_names.clear()
	
	StorageManager.level = 1
	StorageManager.xp = 0
	StorageManager.gold = 500
	StorageManager.coins = 100
	StorageManager.diamonds = 15
	StorageManager.silo_capacity = 100
	StorageManager.barn_capacity = 100
	
	StorageManager.silo_items.clear()
	StorageManager.silo_items["wheat"] = 5
	StorageManager.silo_items["corn"] = 5
	
	StorageManager.barn_items.clear()
	StorageManager.barn_items["chicken_feed"] = 3
	StorageManager.barn_items["cow_feed"] = 2
	
	EventBus.coins_changed.emit(StorageManager.coins, 0)
	EventBus.gold_changed.emit(StorageManager.gold, 0)
	EventBus.diamonds_changed.emit(StorageManager.diamonds, 0)
	EventBus.xp_changed.emit(StorageManager.xp, StorageManager.get_required_xp(StorageManager.level), StorageManager.level)
	EventBus.storage_updated.emit("silo", StorageManager.get_silo_used(), StorageManager.silo_capacity)
	EventBus.storage_updated.emit("barn", StorageManager.get_barn_used(), StorageManager.barn_capacity)
	selected_character = "minh"
	player_name = "Minh"
	instant_interact = false
	player_position = Vector2(70.0, 640.0)
	player_settings_changed.emit()
	save_game()
	print("[SaveManager] Successfully reset account to Fresh Level 1!")

func set_sandbox_level_32() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var global_p: String = ProjectSettings.globalize_path(SAVE_PATH)
		DirAccess.remove_absolute(global_p)
	
	StorageManager.level = 32
	StorageManager.xp = 1240
	StorageManager.gold = 99999
	StorageManager.coins = 25000
	StorageManager.diamonds = 150
	StorageManager.silo_capacity = 500
	StorageManager.barn_capacity = 500
	
	StorageManager.silo_items.clear()
	StorageManager.silo_items["wheat"] = 60
	StorageManager.silo_items["corn"] = 45
	StorageManager.silo_items["tomato"] = 25
	StorageManager.silo_items["carrot"] = 25
	StorageManager.silo_items["strawberry"] = 20
	StorageManager.silo_items["pumpkin"] = 20
	StorageManager.silo_items["soybean"] = 20
	StorageManager.silo_items["sugarcane"] = 20
	StorageManager.silo_items["apple"] = 15
	StorageManager.silo_items["mango"] = 15
	StorageManager.silo_items["sunflower"] = 15
	StorageManager.silo_items["rose"] = 15
	StorageManager.silo_items["lavender"] = 15
	StorageManager.silo_items["apple_seed"] = 10
	StorageManager.silo_items["mango_seed"] = 10
	
	StorageManager.barn_items.clear()
	StorageManager.barn_items["egg"] = 40
	StorageManager.barn_items["milk"] = 35
	StorageManager.barn_items["bacon"] = 25
	StorageManager.barn_items["wool"] = 15
	StorageManager.barn_items["chicken_feed"] = 30
	StorageManager.barn_items["cow_feed"] = 30
	StorageManager.barn_items["pig_feed"] = 20
	StorageManager.barn_items["bread"] = 25
	StorageManager.barn_items["butter"] = 15
	StorageManager.barn_items["cheese"] = 15
	StorageManager.barn_items["cream"] = 15
	StorageManager.barn_items["cookie"] = 15
	StorageManager.barn_items["cream_cake"] = 10
	StorageManager.barn_items["sugarcane_juice"] = 15
	StorageManager.barn_items["apple_juice"] = 15
	StorageManager.barn_items["mango_smoothie"] = 15
	StorageManager.barn_items["fish_carp"] = 15
	StorageManager.barn_items["fish_bass"] = 10
	StorageManager.barn_items["fish_golden_koi"] = 5
	StorageManager.barn_items["bait_red"] = 10
	StorageManager.barn_items["bait_gold"] = 5
	
	EventBus.coins_changed.emit(StorageManager.coins, 0)
	EventBus.gold_changed.emit(StorageManager.gold, 0)
	EventBus.diamonds_changed.emit(StorageManager.diamonds, 0)
	EventBus.xp_changed.emit(StorageManager.xp, StorageManager.get_required_xp(StorageManager.level), StorageManager.level)
	EventBus.storage_updated.emit("silo", StorageManager.get_silo_used(), StorageManager.silo_capacity)
	EventBus.storage_updated.emit("barn", StorageManager.get_barn_used(), StorageManager.barn_capacity)
	save_game()
	print("[SaveManager] Successfully activated Sandbox Mode Level 32!")

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
		"instant_interact": instant_interact,
		"position_x": player_position.x,
		"position_y": player_position.y
	}
	
	# Save Zoo Sanctuary
	save_data["zoo_sanctuary"] = {
		"puzzle_pieces": puzzle_pieces,
		"animals": zoo_data.duplicate(true)
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
	var raw_offline: int = maxi(0, TickManager.now() - saved_ts)
	var offline_elapsed: int = mini(raw_offline, MAX_OFFLINE_SECONDS)
	print("[SaveManager] Game loaded! Offline time elapsed: ", offline_elapsed, "s (clamped from ", raw_offline, "s).")
	
	# Restore Economy
	var econ: Dictionary = data.get("economy", {}) as Dictionary
	if not econ.is_empty():
		StorageManager.coins = int(econ.get("coins", StorageManager.coins))
		StorageManager.gold = int(econ.get("gold", StorageManager.gold))
		StorageManager.diamonds = int(econ.get("diamonds", StorageManager.diamonds))
		StorageManager.xp = int(econ.get("xp", StorageManager.xp))
		StorageManager.level = int(econ.get("level", StorageManager.level))
		StorageManager.silo_capacity = maxi(600, int(econ.get("silo_capacity", 600)))
		StorageManager.barn_capacity = maxi(600, int(econ.get("barn_capacity", 600)))
		
		var s_items: Dictionary = econ.get("silo_items", {}) as Dictionary
		if not s_items.is_empty():
			StorageManager.silo_items = s_items
		
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
		
		var b_items: Dictionary = econ.get("barn_items", {}) as Dictionary
		if not b_items.is_empty():
			StorageManager.barn_items = b_items
		
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
		
		EventBus.coins_changed.emit(StorageManager.coins, 0)
		EventBus.gold_changed.emit(StorageManager.gold, 0)
		EventBus.diamonds_changed.emit(StorageManager.diamonds, 0)
		EventBus.xp_changed.emit(StorageManager.xp, StorageManager.get_required_xp(StorageManager.level), StorageManager.level)
		EventBus.storage_updated.emit("silo", StorageManager.get_silo_used(), StorageManager.silo_capacity)
		EventBus.storage_updated.emit("barn", StorageManager.get_barn_used(), StorageManager.barn_capacity)
	
	# Restore Building Custom Names
	if data.has("building_custom_names"):
		building_custom_names = (data["building_custom_names"] as Dictionary).duplicate()
	else:
		building_custom_names = {}
	
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
	if data.has("player"):
		var p_data: Dictionary = data["player"] as Dictionary
		selected_character = String(p_data.get("selected_character", "minh"))
		player_name = String(p_data.get("player_name", "Minh"))
		instant_interact = bool(p_data.get("instant_interact", false))
		var px: float = float(p_data.get("position_x", 70.0))
		var py: float = float(p_data.get("position_y", 640.0))
		player_position = Vector2(px, py)
		player_settings_changed.emit()
	
	# Restore Zoo Sanctuary
	if data.has("zoo_sanctuary"):
		var z_data: Dictionary = data["zoo_sanctuary"] as Dictionary
		puzzle_pieces = int(z_data.get("puzzle_pieces", 5))
		if z_data.has("animals"):
			var anims: Dictionary = z_data["animals"] as Dictionary
			for k: String in anims:
				zoo_data[k] = (anims[k] as Dictionary).duplicate()
	
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


