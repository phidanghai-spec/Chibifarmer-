extends Node

var crops: Dictionary = {}
var items: Dictionary = {}
var animals: Dictionary = {}
var buildings: Dictionary = {}
var recipes: Dictionary = {}
var fishes: Dictionary = {}
var visitors: Dictionary = {}
var avatar_catalog: Dictionary = {}
var level_rewards: Dictionary = {}
var main_font: FontFile = null
var emoji_font: FontFile = null

const ITEMS_PATH: String = "res://data/items.json"
const CROPS_PATH: String = "res://data/crops.json"
const ANIMALS_PATH: String = "res://data/animals.json"
const BUILDINGS_PATH: String = "res://data/buildings.json"
const RECIPES_PATH: String = "res://data/recipes.json"
const FISHES_PATH: String = "res://data/fishes.json"
const VISITORS_PATH: String = "res://data/visitors.json"
const AVATAR_CATALOG_PATH: String = "res://data/avatar_catalog.json"
const LEVEL_REWARDS_PATH: String = "res://data/level_rewards.json"

func _ready() -> void:
	_setup_emoji_fallback()
	load_all_data()

func _setup_emoji_fallback() -> void:
	if ResourceLoader.exists("res://assets/fonts/Nunito-Bold.ttf") and ResourceLoader.exists("res://assets/fonts/emoji_fallback.ttf"):
		main_font = load("res://assets/fonts/Nunito-Bold.ttf") as FontFile
		emoji_font = load("res://assets/fonts/emoji_fallback.ttf") as FontFile
		if main_font != null and emoji_font != null:
			var sys_emoji_font: SystemFont = SystemFont.new()
			sys_emoji_font.font_names = PackedStringArray([
				"Segoe UI Emoji", "Segoe UI Symbol", "Apple Color Emoji", "Noto Color Emoji", "Arial Unicode MS", "sans-serif"
			])
			emoji_font.fallbacks = [sys_emoji_font]
			main_font.fallbacks = [emoji_font, sys_emoji_font]
			if ThemeDB.fallback_font != null:
				ThemeDB.fallback_font.fallbacks = [emoji_font, main_font, sys_emoji_font]
			var proj_theme: Theme = ThemeDB.get_project_theme()
			if proj_theme != null:
				proj_theme.default_font = main_font
			var def_theme: Theme = ThemeDB.get_default_theme()
			if def_theme != null:
				def_theme.default_font = main_font
			print("[DataManager] Successfully configured emoji font fallback on main_font and ThemeDB!")

func apply_emoji_font(ctrl: Control) -> void:
	if ctrl == null:
		return
	if main_font == null:
		_setup_emoji_fallback()
	if main_font != null:
		ctrl.add_theme_font_override("font", main_font)

func load_all_data() -> void:
	items = _load_json(ITEMS_PATH)
	crops = _load_json(CROPS_PATH)
	animals = _load_json(ANIMALS_PATH)
	buildings = _load_json(BUILDINGS_PATH)
	recipes = _load_json(RECIPES_PATH)
	fishes = _load_json(FISHES_PATH)
	visitors = _load_json(VISITORS_PATH)
	avatar_catalog = _load_json(AVATAR_CATALOG_PATH)
	level_rewards = _load_json(LEVEL_REWARDS_PATH)
	print("[DataManager] Successfully loaded all game data configurations.")

func _load_json(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		push_error("[DataManager] File not found: " + file_path)
		return {}
	
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("[DataManager] Could not open file: " + file_path + " (Error: " + str(FileAccess.get_open_error()) + ")")
		return {}
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var test_json_conv: JSON = JSON.new()
	var error: Error = test_json_conv.parse(json_string)
	if error != OK:
		push_error("[DataManager] JSON Parse Error: " + test_json_conv.get_error_message() + " in " + file_path + " at line " + str(test_json_conv.get_error_line()))
		return {}
	
	var data: Variant = test_json_conv.data
	if typeof(data) != TYPE_DICTIONARY:
		push_error("[DataManager] JSON root is not a Dictionary: " + file_path)
		return {}
	
	return data as Dictionary

# --- Query Getters ---

func get_crop(crop_id: String) -> Dictionary:
	return crops.get(crop_id, {}) as Dictionary

func get_crop_name(crop_id: String) -> String:
	if crops.has(crop_id):
		return String((crops[crop_id] as Dictionary).get("name", ""))
	return get_item_name(crop_id)

func get_animal(animal_id: String) -> Dictionary:
	return animals.get(animal_id, {}) as Dictionary

func get_building(building_id: String) -> Dictionary:
	return buildings.get(building_id, {}) as Dictionary

func get_building_unlock_level(building_id: String, fallback: int = 1) -> int:
	if buildings.has(building_id):
		var b_dict: Dictionary = buildings[building_id] as Dictionary
		return int(b_dict.get("unlock_level", fallback))
	return fallback

func get_level_rewards() -> Dictionary:
	return level_rewards

func get_zoo_enclosures() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for b_key: Variant in buildings:
		var b_dict: Dictionary = buildings[b_key] as Dictionary
		if String(b_dict.get("category", "")) == "zoo_enclosure":
			result.append(b_dict)
	return result

func get_recipe(recipe_id: String) -> Dictionary:
	return recipes.get(recipe_id, {}) as Dictionary

func get_fish(fish_id: String) -> Dictionary:
	return fishes.get(fish_id, {}) as Dictionary

func get_visitor(visitor_id: String) -> Dictionary:
	return visitors.get(visitor_id, {}) as Dictionary

func get_recipes_for_building(building_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for recipe_key: Variant in recipes:
		var recipe_dict: Dictionary = recipes[recipe_key] as Dictionary
		if String(recipe_dict.get("building_id", "")) == building_id:
			result.append(recipe_dict)
	return result

func get_item_storage_type(item_id: String) -> String:
	if items.has(item_id):
		return String((items[item_id] as Dictionary).get("storage_type", "barn"))
	if crops.has(item_id):
		return String((crops[item_id] as Dictionary).get("storage_type", "silo"))
	if animals.has(item_id):
		return String((animals[item_id] as Dictionary).get("storage_type", "barn"))
	for recipe_key: Variant in recipes:
		var rec: Dictionary = recipes[recipe_key] as Dictionary
		if String(rec.get("produce_item_id", "")) == item_id:
			return String(rec.get("storage_type", "barn"))
	if fishes.has(item_id):
		return String((fishes[item_id] as Dictionary).get("storage_type", "barn"))
	return "barn"

func get_item_name(item_id: String) -> String:
	if items.has(item_id):
		return String((items[item_id] as Dictionary).get("name", item_id))
	match item_id.to_lower():
		"bacon", "pork":
			return "Thịt Xông Khói"
		"egg":
			return "Trứng Gà"
		"milk":
			return "Sữa Bò Tươi"
		"bread":
			return "Bánh Mì Nóng"
		"chicken_feed":
			return "Cám Gà"
		"cow_feed", "animal_feed":
			return "Cám Bò"
		"pig_feed":
			return "Cám Heo"
		"sanctuary_feed":
			return "Bó Cỏ Dinh Dưỡng"
		"butter":
			return "Bơ Sữa"
		"cheese":
			return "Phô Mai"
		"cream":
			return "Kem Tươi"
		"fish_carp", "fish":
			return "Cá Chép"
		"wheat":
			return "Lúa Mì"
		"corn":
			return "Ngô"
		"carrot":
			return "Cà Rốt"
		"soybean":
			return "Đậu Nành"
		"sugarcane":
			return "Mía Đường"
		"strawberry":
			return "Dâu Tây"
		"tomato":
			return "Cà Chua"
		"pumpkin":
			return "Bí Đỏ"
		"apple":
			return "Táo Đỏ"
		"mango":
			return "Xoài Chín"
		"apple_seed":
			return "Hạt Giống Táo"
		"mango_seed":
			return "Hạt Giống Xoài"
		"cookie":
			return "Bánh Quy Bơ"
		"corn_bread":
			return "Bánh Mì Ngô"
		"wool":
			return "Lông Cừu"
		"mat_plank":
			return "Ván Gỗ Thông"
		"mat_bolt":
			return "Đinh Tán Thép"
		"mat_brick":
			return "Gạch Nung Đỏ"

	if crops.has(item_id):
		return String((crops[item_id] as Dictionary).get("name", item_id))
	for rec_key: Variant in recipes:
		var rec: Dictionary = recipes[rec_key] as Dictionary
		if String(rec.get("produce_item_id", "")) == item_id:
			return String(rec.get("name", item_id))
	if animals.has(item_id):
		return String((animals[item_id] as Dictionary).get("name", item_id))
	if fishes.has(item_id):
		return String((fishes[item_id] as Dictionary).get("name", item_id))
	return item_id.capitalize()

func get_item_display_name(item_id: String) -> String:
	return get_item_name(item_id)

func get_item_base_price(item_id: String) -> int:
	if items.has(item_id):
		return int((items[item_id] as Dictionary).get("base_price", 5))
	if crops.has(item_id):
		return int((crops[item_id] as Dictionary).get("base_price", 1))
	for rec_key: Variant in recipes:
		var rec: Dictionary = recipes[rec_key] as Dictionary
		if String(rec.get("produce_item_id", "")) == item_id:
			return int(rec.get("base_price", 10))
	if fishes.has(item_id):
		return int((fishes[item_id] as Dictionary).get("base_price", 25))
	return 5

func get_building_name(building_id: String) -> String:
	if buildings.has(building_id):
		return String((buildings[building_id] as Dictionary).get("name", building_id.capitalize()))
	match building_id:
		"bakery": return "Lò Bánh Mì"
		"feed_mill": return "Máy Nghiền Cám"
		"dairy": return "Xưởng Sữa"
		"juice_stand": return "Quầy Nước"
		"cake_oven": return "Lò Bánh Ngọt"
		"mini_zoo": return "Khu Sở Thú"
		"building_barn", "barn": return "Nhà Kho Barn"
		"building_silo", "silo": return "Kho Silo"
		"truck", "truck_delivery": return "Bến Xe Tải"
		"roadside_shop": return "Sạp Hàng Ven Đường"
	return building_id.capitalize()

