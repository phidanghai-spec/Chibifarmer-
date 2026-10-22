extends Node
# Autoload: SpriteAtlasManager
# Loads and pixel-normalizes Chibi & Cartoon spritesheets with 8px inset to remove black L-shaped borders

var textures: Dictionary = {}

# 1. Primary Character & Animals Sheet (chibi_sheet_2_characters.png - 4x3)
const CHIBI_SHEET2_PATHS: Array[String] = [
	"res://assets/sprites/chibi_sheet_2_characters.png",
	"res://assets/sprites/script nhn v?t.png"
]
const CHIBI_SHEET2_MAP: Array = [
	["cow", "sheep", "chicken", "milk_cheese"],
	["visitor_farmer", "visitor_tourist", "visitor_shopper", "visitor_chef"],
	["icon_gold", "icon_xp", "icon_heart", "sickle"]
]

# 2. Chibi Props, Plots & Coops Sheet (chibi_sheet_1.png - 4x3)
const CHIBI_SHEET1_PATHS: Array[String] = [
	"res://assets/sprites/chibi_sheet_1.png",
	"res://assets/sprites/script th?c ph?m.png"
]
const CHIBI_SHEET1_MAP: Array = [
	["chicken_coop", "chibi_eggs", "pig", "chibi_tool_shed"],
	["chibi_carrot_plot", "chibi_potato_plot", "chibi_harvest_basket", "chibi_sprout_stump"],
	["chibi_fence", "chibi_scarecrow", "chibi_easel", "chibi_telescope"]
]

# 3. Chibi Buildings & Production Sheet (chibi_sheet_3_buildings.png - 4x3)
const CHIBI_SHEET3_PATHS: Array[String] = [
	"res://assets/sprites/chibi_sheet_3_buildings.png",
	"res://assets/sprites/script nh c?a.png"
]
const CHIBI_SHEET3_MAP: Array = [
	["feed_mill", "bakery", "dairy", "roadside_shop"],
	["farmhouse", "cow_pasture", "sheep_pasture", "beehive_tree"],
	["visitor_ranger", "visitor_gardener", "visitor_mascot", "animal_duckling"]
]

# 4. Animals & Human Visitors Sheet (sprites_animals_visitors.jpg - 4x3)
# Row 0: 4 HUMAN VISITORS | Row 1: 4 ANIMALS | Row 2: 4 BUILDINGS
const SHEET_ANIMALS_VISITORS_PATHS: Array[String] = [
	"res://assets/sprites/sprites_animals_visitors.jpg",
	"res://assets/sprites/script nhn v?t+2.jpg"
]
const SHEET_ANIMALS_VISITORS_MAP: Array = [
	["visitor_fisherman", "visitor_florist", "visitor_postman", "visitor_miner"],
	["animal_horse", "animal_goat", "animal_dog", "animal_donkey"],
	["building_station", "building_pier", "building_icecream", "building_forge"]
]

# 5. Buildings & Attractions Sheet (sprites_buildings_crops.jpg - 4x3)
const SHEET_BUILDINGS_DECOR_PATHS: Array[String] = [
	"res://assets/sprites/sprites_buildings_crops.jpg",
	"res://assets/sprites/script nh + trang tr.jpg"
]
const SHEET_BUILDINGS_DECOR_MAP: Array = [
	["decor_duck_pond", "decor_shrimp_pond", "decor_crab_pond", "decor_cloud_waterfall"],
	["decor_carousel", "decor_treehouse", "decor_swing", "decor_cat_bush"],
	["decor_elephant", "decor_frog_fountain", "decor_duck", "decor_treasure_chest"]
]

# 6. Environment & Nature Sheet (sprites_environment_nature.png - 4x3)
const SHEET_ENVIRONMENT_NATURE_PATHS: Array[String] = [
	"res://assets/sprites/sprites_environment_nature.png"
]
const SHEET_ENVIRONMENT_NATURE_MAP: Array = [
	["env_hill_1", "env_hill_2", "env_cherry_tree_1", "env_cherry_tree_2"],
	["env_pine_tree", "env_apple_tree", "env_grass_flowers", "env_grass_mushrooms"],
	["env_mossy_rock_1", "env_mossy_rock_2", "env_sunflowers", "env_natural_pond"]
]

func _ready() -> void:
	load_all_atlases()
	_setup_aliases()
	_ensure_essential_icons()

func load_all_atlases() -> void:
	# 1. Characters & Farm Animals (Chibi Sheet 2) - Inset 8px
	var img_c2: Image = _load_image_from_candidates(CHIBI_SHEET2_PATHS)
	if img_c2 != null:
		_process_atlas_sheet(img_c2, CHIBI_SHEET2_MAP, 8)
		print("[SpriteAtlasManager] Loaded 12 Chibi Characters, Animals & Icons.")

	# 2. Crops & Plots (Chibi Sheet 1) - Inset 8px
	var img_c1: Image = _load_image_from_candidates(CHIBI_SHEET1_PATHS)
	if img_c1 != null:
		_process_atlas_sheet(img_c1, CHIBI_SHEET1_MAP, 8)
		print("[SpriteAtlasManager] Loaded 12 Chibi Crops, Plots & Coops.")

	# 3. Chibi Buildings (Chibi Sheet 3) - Inset 8px
	var img_c3: Image = _load_image_from_candidates(CHIBI_SHEET3_PATHS)
	if img_c3 != null:
		_process_atlas_sheet(img_c3, CHIBI_SHEET3_MAP, 8)
		print("[SpriteAtlasManager] Loaded 12 Chibi Buildings & Machines.")

	# 4. Standard Animals & Human Visitors (Row 0: Humans, Row 1: Animals, Row 2: Buildings) - Inset 8px
	var img_av: Image = _load_image_from_candidates(SHEET_ANIMALS_VISITORS_PATHS)
	if img_av != null:
		_process_atlas_sheet(img_av, SHEET_ANIMALS_VISITORS_MAP, 8)
		print("[SpriteAtlasManager] Loaded 12 Standard Animals, Visitors & Extra Buildings.")

	# 5. Buildings & Attractions - Inset 8px to completely remove black L-shaped borders
	var img_bd: Image = _load_image_from_candidates(SHEET_BUILDINGS_DECOR_PATHS)
	if img_bd != null:
		_process_atlas_sheet(img_bd, SHEET_BUILDINGS_DECOR_MAP, 8)
		print("[SpriteAtlasManager] Loaded 12 Attractions & Decors.")

	# 6. Environment & Nature Spritesheet (Mountains, Trees, Rocks, Flowers, Ponds)
	var img_env: Image = _load_image_from_candidates(SHEET_ENVIRONMENT_NATURE_PATHS)
	if img_env != null:
		_process_atlas_sheet(img_env, SHEET_ENVIRONMENT_NATURE_MAP, 6)
		print("[SpriteAtlasManager] Loaded 12 Environment Nature Sprites.")
	# 7. Dedicated Crisp Standalone Sprites (Wheat, Corn, Sickle, Harvest Basket, Field Plot)
	_load_standalone_texture("wheat", "res://assets/sprites/crop_wheat.png")
	_load_standalone_texture("corn", "res://assets/sprites/crop_corn.png")
	_load_standalone_texture("sickle", "res://assets/sprites/tool_sickle.png")
	_load_standalone_texture("crop_basket", "res://assets/sprites/crop_basket.png")
	_load_standalone_texture("field_plot", "res://assets/sprites/field_plot.png")
	_load_standalone_texture("cow_pasture", "res://assets/sprites/cow_barn.png")
	_load_standalone_texture("bird_dove", "res://assets/sprites/bird_dove.png")
	_load_standalone_texture("bird_sparrow", "res://assets/sprites/bird_sparrow.png")
	_load_standalone_texture("critter_bunny", "res://assets/sprites/critter_bunny.png")
	_load_standalone_texture("critter_butterfly_pink", "res://assets/sprites/critter_butterfly_pink.png")
	_load_standalone_texture("critter_butterfly_yellow", "res://assets/sprites/critter_butterfly_yellow.png")
	_load_standalone_texture("critter_bee", "res://assets/sprites/critter_bee.png")
	_load_standalone_texture("flowerbed_daisies", "res://assets/sprites/flowerbed_daisies.png")
	_load_standalone_texture("flowerbed_roses", "res://assets/sprites/flowerbed_roses.png")
	_load_standalone_texture("flowerbed_lavender", "res://assets/sprites/flowerbed_lavender.png")
	_load_standalone_texture("flowerbed_round", "res://assets/sprites/flowerbed_round.png")
	_load_standalone_texture("tree_fruitless", "res://assets/sprites/tree_fruitless.png")
	_load_standalone_texture("tree_apple_ripe", "res://assets/sprites/tree_apple_ripe.png")
	_load_standalone_texture("tree_mango_ripe", "res://assets/sprites/tree_mango_ripe.png")
	_load_standalone_texture("env_apple_tree", "res://assets/sprites/tree_apple_ripe.png")
	_load_standalone_texture("env_mango_tree", "res://assets/sprites/tree_mango_ripe.png")
	_load_standalone_texture("icon_mango", "res://assets/sprites/icon_mango.png")
	_load_standalone_texture("mango", "res://assets/sprites/icon_mango.png")
	_load_standalone_texture("icon_apple_seed", "res://assets/sprites/icon_apple_seed.png")
	_load_standalone_texture("apple_seed", "res://assets/sprites/icon_apple_seed.png")
	_load_standalone_texture("icon_mango_seed", "res://assets/sprites/icon_mango_seed.png")
	_load_standalone_texture("mango_seed", "res://assets/sprites/icon_mango_seed.png")
	_load_standalone_texture("truck", "res://assets/sprites/icon_truck.png")
	_load_standalone_texture("truck_delivery", "res://assets/sprites/icon_truck.png")
	_load_standalone_texture("icon_truck", "res://assets/sprites/icon_truck.png")
	_load_standalone_texture("env_mountain_peak", "res://assets/sprites/env_mountain_peak.png")
	_load_standalone_texture("env_mountain_waterfall", "res://assets/sprites/env_mountain_waterfall.png")
	_load_standalone_texture("env_rock_outcrop", "res://assets/sprites/env_rock_outcrop.png")
	_load_standalone_texture("env_pine_cluster", "res://assets/sprites/env_pine_cluster.png")
	_load_standalone_texture("env_flower_meadow", "res://assets/sprites/env_flower_meadow.png")
	_load_standalone_texture("chibi_meadow_backdrop", "res://assets/sprites/chibi_meadow_backdrop.png")
	_load_standalone_texture("env_lush_green_tree", "res://assets/sprites/env_lush_green_tree.png")
	_load_standalone_texture("env_cherry_tree", "res://assets/sprites/env_cherry_tree.png")
	_load_standalone_texture("env_cherry_tree_1", "res://assets/sprites/env_cherry_tree.png")
	_load_standalone_texture("env_cherry_tree_2", "res://assets/sprites/env_cherry_tree.png")
	# --- CHIBI NATURE & SCENERY ASSETS ---
	_load_standalone_texture("chibi_special_peach_tree", "res://assets/sprites/chibi_special_peach_tree.png")
	_load_standalone_texture("chibi_tree_oak", "res://assets/sprites/chibi_tree_oak.png")
	_load_standalone_texture("chibi_tree_oak_2", "res://assets/sprites/chibi_tree_oak_2.png")
	_load_standalone_texture("chibi_tree_cypress", "res://assets/sprites/chibi_tree_cypress.png")
	_load_standalone_texture("chibi_tree_tall", "res://assets/sprites/chibi_tree_tall.png")
	_load_standalone_texture("chibi_bush_green", "res://assets/sprites/chibi_bush_green.png")
	_load_standalone_texture("chibi_hedge_1", "res://assets/sprites/chibi_hedge_1.png")
	_load_standalone_texture("chibi_hedge_2", "res://assets/sprites/chibi_hedge_2.png")
	_load_standalone_texture("chibi_hedge_3", "res://assets/sprites/chibi_hedge_3.png")
	_load_standalone_texture("chibi_hedge_4", "res://assets/sprites/chibi_hedge_4.png")
	_load_standalone_texture("chibi_rock_1", "res://assets/sprites/chibi_rock_1.png")
	_load_standalone_texture("chibi_rock_2", "res://assets/sprites/chibi_rock_2.png")
	_load_standalone_texture("chibi_rock_3", "res://assets/sprites/chibi_rock_3.png")
	_load_standalone_texture("chibi_rock_4", "res://assets/sprites/chibi_rock_4.png")
	_load_standalone_texture("chibi_rock_5", "res://assets/sprites/chibi_rock_5.png")
	_load_standalone_texture("chibi_rock_6", "res://assets/sprites/chibi_rock_6.png")
	_load_standalone_texture("chibi_flower_bush_1", "res://assets/sprites/chibi_flower_bush_1.png")
	_load_standalone_texture("chibi_flower_bush_2", "res://assets/sprites/chibi_flower_bush_2.png")
	_load_standalone_texture("chibi_flower_bush_3", "res://assets/sprites/chibi_flower_bush_3.png")
	_load_standalone_texture("chibi_flower_bush_4", "res://assets/sprites/chibi_flower_bush_4.png")
	_load_standalone_texture("chibi_flower_bush_5", "res://assets/sprites/chibi_flower_bush_5.png")
	_load_standalone_texture("chibi_flower_bush_6", "res://assets/sprites/chibi_flower_bush_6.png")
	_load_standalone_texture("chibi_flower_bush_7", "res://assets/sprites/chibi_flower_bush_7.png")
	_load_standalone_texture("chibi_flower_bush_8", "res://assets/sprites/chibi_flower_bush_8.png")
	_load_standalone_texture("chibi_floral_1", "res://assets/sprites/chibi_floral_1.png")
	_load_standalone_texture("chibi_floral_2", "res://assets/sprites/chibi_floral_2.png")
	_load_standalone_texture("chibi_floral_3", "res://assets/sprites/chibi_floral_3.png")
	_load_standalone_texture("chibi_floral_4", "res://assets/sprites/chibi_floral_4.png")
	_load_standalone_texture("chibi_floral_5", "res://assets/sprites/chibi_floral_5.png")
	_load_standalone_texture("chibi_floral_6", "res://assets/sprites/chibi_floral_6.png")
	_load_standalone_texture("chibi_cloud_1", "res://assets/sprites/chibi_cloud_1.png")
	_load_standalone_texture("chibi_cloud_2", "res://assets/sprites/chibi_cloud_2.png")
	_load_standalone_texture("chibi_cloud_3", "res://assets/sprites/chibi_cloud_3.png")
	_load_standalone_texture("chibi_cloud_4", "res://assets/sprites/chibi_cloud_4.png")
	_load_standalone_texture("chibi_mountain_high", "res://assets/sprites/chibi_mountain_high.png")
	_load_standalone_texture("chibi_mountain_valley", "res://assets/sprites/chibi_mountain_valley.png")


	_load_standalone_texture("env_river_bush", "res://assets/sprites/env_river_bush.png")
	_load_standalone_texture("visitor_adventurer", "res://assets/sprites/visitor_adventurer.png")

	# Barn and Silo Item Icons (128x128 RGBA Transparent)
	_load_standalone_texture("bread", "res://assets/sprites/bread.png")
	_load_standalone_texture("item_bread", "res://assets/sprites/item_bread.png")
	_load_standalone_texture("bacon", "res://assets/sprites/bacon.png")
	_load_standalone_texture("item_bacon", "res://assets/sprites/item_bacon.png")
	_load_standalone_texture("pork", "res://assets/sprites/pork.png")
	_load_standalone_texture("chicken_feed", "res://assets/sprites/chicken_feed.png")
	_load_standalone_texture("item_chicken_feed", "res://assets/sprites/item_chicken_feed.png")
	_load_standalone_texture("cow_feed", "res://assets/sprites/cow_feed.png")
	_load_standalone_texture("item_cow_feed", "res://assets/sprites/item_cow_feed.png")
	_load_standalone_texture("animal_feed", "res://assets/sprites/animal_feed.png")
	_load_standalone_texture("pig_feed", "res://assets/sprites/pig_feed.png")
	_load_standalone_texture("egg", "res://assets/sprites/egg.png")
	_load_standalone_texture("item_egg", "res://assets/sprites/item_egg.png")
	_load_standalone_texture("milk", "res://assets/sprites/milk.png")
	_load_standalone_texture("item_milk", "res://assets/sprites/item_milk.png")
	_load_standalone_texture("butter", "res://assets/sprites/butter.png")
	_load_standalone_texture("item_butter", "res://assets/sprites/item_butter.png")
	_load_standalone_texture("cheese", "res://assets/sprites/cheese.png")
	_load_standalone_texture("item_cheese", "res://assets/sprites/item_cheese.png")
	_load_standalone_texture("cream", "res://assets/sprites/cream.png")
	_load_standalone_texture("item_cream", "res://assets/sprites/item_cream.png")
	_load_standalone_texture("fish_carp", "res://assets/sprites/fish_carp.png")
	_load_standalone_texture("item_fish_carp", "res://assets/sprites/item_fish_carp.png")
	_load_standalone_texture("carrot", "res://assets/sprites/carrot.png")
	_load_standalone_texture("item_carrot", "res://assets/sprites/item_carrot.png")
	_load_standalone_texture("soybean", "res://assets/sprites/soybean.png")
	_load_standalone_texture("item_soybean", "res://assets/sprites/item_soybean.png")
	_load_standalone_texture("sugarcane", "res://assets/sprites/sugarcane.png")
	_load_standalone_texture("item_sugarcane", "res://assets/sprites/item_sugarcane.png")
	_load_standalone_texture("wheat", "res://assets/sprites/wheat.png")
	_load_standalone_texture("item_wheat", "res://assets/sprites/item_wheat.png")
	_load_standalone_texture("corn", "res://assets/sprites/corn.png")
	_load_standalone_texture("item_corn", "res://assets/sprites/item_corn.png")
	_load_standalone_texture("strawberry", "res://assets/sprites/strawberry.png")
	_load_standalone_texture("item_strawberry", "res://assets/sprites/item_strawberry.png")
	_load_standalone_texture("tomato", "res://assets/sprites/tomato.png")
	_load_standalone_texture("item_tomato", "res://assets/sprites/item_tomato.png")
	_load_standalone_texture("pumpkin", "res://assets/sprites/pumpkin.png")
	_load_standalone_texture("item_pumpkin", "res://assets/sprites/item_pumpkin.png")

	# Barn Building Sprite
	_load_standalone_texture("building_barn", "res://assets/sprites/building_barn.png")
	_load_standalone_texture("chibi_barn_red", "res://assets/sprites/chibi_barn_red.png")

	# Sliced Characters
	for i in range(1, 9):
		var char_key: String = "npc_char_%02d" % i
		var char_path: String = "res://assets/sprites/%s.png" % char_key
		_load_standalone_texture(char_key, char_path)

func _load_standalone_texture(key: String, res_path: String) -> void:
	if FileAccess.file_exists(res_path):
		var global_path: String = ProjectSettings.globalize_path(res_path)
		var img: Image = Image.new()
		var err: Error = img.load(global_path)
		if err == OK and not img.is_empty():
			textures[key] = ImageTexture.create_from_image(img)
			print("[SpriteAtlasManager] Loaded authentic standalone texture: " + key)

func _setup_aliases() -> void:
	# Ensure backwards compatibility and easy access for game systems
	_alias("egg_milk", "milk_cheese")
	_alias("chibi_coop", "chicken_coop")
	_load_standalone_texture("barn", "res://assets/sprites/building_barn.png")
	_alias("barn", "building_barn")
	_alias("silo", "dairy")
	_alias("fishing_hut", "feed_mill")
	_alias("truck_delivery", "truck")
	_alias("apple_tree", "tree_apple_ripe")
	_alias("mango_tree", "tree_mango_ripe")
	_alias("env_mango_tree", "tree_mango_ripe")
	_alias("fountain", "decor_frog_fountain")
	_alias("cow_pen", "cow_pasture")
	_alias("harvest_basket", "crop_basket")
	_alias("basket", "crop_basket")
	
	# Environment aliases
	# _alias("env_cherry_tree", "env_cherry_tree")
	_alias("env_pine_tree", "chibi_tree_oak")
	_alias("env_pine_cluster", "chibi_tree_tall")
	_alias("env_rock_outcrop", "chibi_rock_1")
	_alias("env_flower_meadow", "chibi_flower_bush_1")
	_alias("env_mountain_peak", "chibi_mountain_high")
	_alias("env_mountain_waterfall", "chibi_mountain_valley")
	_alias("hill", "env_hill_1")
	_alias("hill_2", "env_hill_2")
	_alias("cherry_tree", "env_cherry_tree_1")
	_alias("cherry_tree_2", "env_cherry_tree_2")
	_alias("pine_tree", "env_pine_tree")
	_alias("apple_tree", "env_apple_tree")
	_alias("grass_flowers", "env_grass_flowers")
	_alias("grass_mushrooms", "env_grass_mushrooms")
	_alias("mossy_rock", "env_mossy_rock_1")
	_alias("mossy_rock_2", "env_mossy_rock_2")
	_alias("sunflowers", "env_sunflowers")
	_alias("natural_pond", "env_natural_pond")

func _alias(alias_name: String, source_name: String) -> void:
	if not textures.has(alias_name) and textures.has(source_name):
		textures[alias_name] = textures[source_name]

func _ensure_essential_icons() -> void:
	if not textures.has("icon_gold"):
		textures["icon_gold"] = _generate_gold_coin_icon()
	if not textures.has("icon_heart"):
		textures["icon_heart"] = _generate_heart_icon()
	if not textures.has("icon_xp"):
		textures["icon_xp"] = _generate_star_icon()
	if not textures.has("fishing_net"):
		textures["fishing_net"] = textures.get("icon_gold")
	if not textures.has("apple"):
		textures["apple"] = _generate_fruit_icon(Color(0.92, 0.22, 0.20), "apple")
	if not textures.has("mango"):
		textures["mango"] = _generate_fruit_icon(Color(1.0, 0.76, 0.12), "mango")
	if not textures.has("apple_seed"):
		textures["apple_seed"] = _generate_seed_icon(Color(0.48, 0.28, 0.14))
	if not textures.has("mango_seed"):
		textures["mango_seed"] = _generate_seed_icon(Color(0.85, 0.70, 0.25))
	if not textures.has("fish_carp"):
		textures["fish_carp"] = _generate_carp_icon()
	if not textures.has("fish"):
		textures["fish"] = textures["fish_carp"]
	if textures.has("tree_mango_ripe"):
		textures["env_mango_tree"] = textures["tree_mango_ripe"]
	elif not textures.has("env_mango_tree"):
		if textures.has("env_apple_tree"):
			textures["env_mango_tree"] = textures["env_apple_tree"]
		elif textures.has("env_cherry_tree_1"):
			textures["env_mango_tree"] = textures["env_cherry_tree_1"]

func _load_image_from_candidates(candidates: Array[String]) -> Image:
	for path: String in candidates:
		if FileAccess.file_exists(path):
			var global_path: String = ProjectSettings.globalize_path(path)
			var img: Image = Image.new()
			var err: Error = img.load(global_path)
			if err == OK and not img.is_empty():
				return img
	return null

func _process_atlas_sheet(image: Image, mapping: Array, inset_margin: int = 8) -> void:
	image.convert(Image.FORMAT_RGBA8)
	var img_w: int = image.get_width()
	var img_h: int = image.get_height()
	var cell_w: int = int(float(img_w) / 4.0)
	var cell_h: int = int(float(img_h) / 3.0)

	for row: int in range(3):
		for col: int in range(4):
			var sprite_name: String = mapping[row][col] as String
			if sprite_name == "" or sprite_name == "empty":
				continue
			var start_x: int = col * cell_w
			var start_y: int = row * cell_h

			# 8px inset crop to eliminate L-shaped black borders at outer edges
			var inner_x: int = start_x + inset_margin
			var inner_y: int = start_y + inset_margin
			var inner_w: int = cell_w - (inset_margin * 2)
			var inner_h: int = cell_h - (inset_margin * 2)

			if inner_w <= 0 or inner_h <= 0:
				continue

			var cell_rect: Rect2i = Rect2i(inner_x, inner_y, inner_w, inner_h)
			var cell_img: Image = image.get_region(cell_rect)

			# Flood-fill background removal on clean inset region
			_flood_fill_transparent_background_local(cell_img)

			var tex: ImageTexture = ImageTexture.create_from_image(cell_img)
			textures[sprite_name] = tex

func _flood_fill_transparent_background_local(image: Image) -> void:
	var w: int = image.get_width()
	var h: int = image.get_height()
	var total_pixels: int = w * h
	var visited: PackedByteArray = PackedByteArray()
	visited.resize(total_pixels)
	visited.fill(0)

	var queue: Array[Vector2i] = []
	var bg_threshold: float = 0.88

	for x: int in range(w):
		_enqueue_local_seed(image, x, 0, w, bg_threshold, visited, queue)
		_enqueue_local_seed(image, x, h - 1, w, bg_threshold, visited, queue)

	for y: int in range(h):
		_enqueue_local_seed(image, 0, y, w, bg_threshold, visited, queue)
		_enqueue_local_seed(image, w - 1, y, w, bg_threshold, visited, queue)

	var head: int = 0
	var transparent_color: Color = Color(1.0, 1.0, 1.0, 0.0)

	while head < queue.size():
		var p: Vector2i = queue[head]
		head += 1

		image.set_pixel(p.x, p.y, transparent_color)

		var neighbors: Array[Vector2i] = [
			Vector2i(p.x + 1, p.y),
			Vector2i(p.x - 1, p.y),
			Vector2i(p.x, p.y + 1),
			Vector2i(p.x, p.y - 1)
		]

		for n: Vector2i in neighbors:
			if n.x >= 0 and n.x < w and n.y >= 0 and n.y < h:
				var idx: int = n.y * w + n.x
				if visited[idx] == 0:
					visited[idx] = 1
					var col: Color = image.get_pixel(n.x, n.y)
					if col.r >= bg_threshold and col.g >= bg_threshold and col.b >= bg_threshold:
						queue.append(n)

func _enqueue_local_seed(
	image: Image, x: int, y: int, w: int,
	bg_threshold: float,
	visited: PackedByteArray, queue: Array[Vector2i]
) -> void:
	var idx: int = y * w + x
	if visited[idx] == 0:
		visited[idx] = 1
		var col: Color = image.get_pixel(x, y)
		if col.r >= bg_threshold and col.g >= bg_threshold and col.b >= bg_threshold:
			queue.append(Vector2i(x, y))

# --- Pixel Normalization Utility ---

func set_sprite_pixel_size(sprite: Sprite2D, max_size: Vector2) -> void:
	if sprite == null or sprite.texture == null:
		return
	var tex_size: Vector2 = sprite.texture.get_size()
	if tex_size.x <= 0 or tex_size.y <= 0:
		return
	var factor: float = minf(max_size.x / tex_size.x, max_size.y / tex_size.y)
	sprite.scale = Vector2(factor, factor)

func create_sized_sprite(sprite_id: String, max_size: Vector2) -> Sprite2D:
	var tex: Texture2D = get_texture(sprite_id)
	if tex == null:
		return null
	var sp: Sprite2D = Sprite2D.new()
	sp.texture = tex
	set_sprite_pixel_size(sp, max_size)
	return sp

func get_texture(sprite_id: String) -> Texture2D:
	if textures.has(sprite_id):
		return textures[sprite_id] as Texture2D
	var item_key: String = "item_" + sprite_id
	if textures.has(item_key):
		return textures[item_key] as Texture2D
	var lower_key: String = sprite_id.to_lower()
	if textures.has(lower_key):
		return textures[lower_key] as Texture2D
	var lower_item_key: String = "item_" + lower_key
	if textures.has(lower_item_key):
		return textures[lower_item_key] as Texture2D

	# Synonyms mapping
	match lower_key:
		"pork":
			return get_texture("bacon")
		"feed_chicken", "cám_gà":
			return get_texture("chicken_feed")
		"feed_cow", "cám_bò", "animal_feed":
			return get_texture("cow_feed")
		"feed_pig", "cám_heo":
			return get_texture("pig_feed")
		"fish", "carp", "cá":
			return get_texture("fish_carp")
		"barn":
			if textures.has("building_barn"):
				return textures["building_barn"] as Texture2D

	return null

func has_texture(sprite_id: String) -> bool:
	return get_texture(sprite_id) != null

func create_sprite(sprite_id: String, target_size: Vector2 = Vector2.ZERO) -> Sprite2D:
	if target_size != Vector2.ZERO:
		return create_sized_sprite(sprite_id, target_size)
	var tex: Texture2D = get_texture(sprite_id)
	if tex == null:
		return null
	var sp: Sprite2D = Sprite2D.new()
	sp.texture = tex
	return sp

func _generate_gold_coin_icon() -> Texture2D:
	var img: Image = Image.create(48, 48, false, Image.FORMAT_RGBA8)
	for x: int in range(48):
		for y: int in range(48):
			var dist: float = Vector2(x - 24, y - 24).length()
			if dist <= 20.0:
				if dist >= 17.0:
					img.set_pixel(x, y, Color(0.42, 0.30, 0.21))
				else:
					img.set_pixel(x, y, Color(0.98, 0.82, 0.35))
	return ImageTexture.create_from_image(img)

func _generate_heart_icon() -> Texture2D:
	var img: Image = Image.create(48, 48, false, Image.FORMAT_RGBA8)
	for x: int in range(48):
		for y: int in range(48):
			var nx: float = float(x - 24) / 16.0
			var ny: float = float(y - 20) / 16.0
			var formula: float = pow(nx * nx + ny * ny - 1.0, 3.0) - nx * nx * pow(ny, 3.0)
			if formula <= 0.0:
				img.set_pixel(x, y, Color(0.98, 0.45, 0.60))
	return ImageTexture.create_from_image(img)

func _generate_star_icon() -> Texture2D:
	var img: Image = Image.create(48, 48, false, Image.FORMAT_RGBA8)
	for x: int in range(48):
		for y: int in range(48):
			var dist: float = Vector2(x - 24, y - 24).length()
			if dist <= 18.0:
				img.set_pixel(x, y, Color(0.45, 0.78, 0.95))
	return ImageTexture.create_from_image(img)

func _generate_fruit_icon(fruit_col: Color, type: String) -> ImageTexture:
	var img: Image = Image.create(36, 36, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center: Vector2 = Vector2(18, 20)
	for y: int in range(36):
		for x: int in range(36):
			var pos: Vector2 = Vector2(x, y)
			var d: float = pos.distance_to(center)
			if type == "mango":
				var d_mango: float = pos.distance_to(center + Vector2(1, 1)) * 0.95 + absf(pos.x - center.x) * 0.2
				if d_mango <= 12.5:
					var highlight: float = clampf(1.0 - pos.distance_to(Vector2(14, 15)) / 10.0, 0.0, 0.4)
					var col: Color = fruit_col.lightened(highlight)
					img.set_pixel(x, y, col)
			else:
				if d <= 12.0:
					var highlight: float = clampf(1.0 - pos.distance_to(Vector2(14, 16)) / 9.0, 0.0, 0.45)
					var col: Color = fruit_col.lightened(highlight)
					img.set_pixel(x, y, col)
	# Brown stem
	for y: int in range(4, 10):
		img.set_pixel(18, y, Color(0.42, 0.25, 0.12))
		img.set_pixel(19, y, Color(0.42, 0.25, 0.12))
	# Green leaf
	for lx: int in range(19, 26):
		for ly: int in range(4, 9):
			if lx + ly < 33:
				img.set_pixel(lx, ly, Color(0.28, 0.75, 0.22))
	return ImageTexture.create_from_image(img)

func _generate_seed_icon(seed_col: Color) -> ImageTexture:
	var img: Image = Image.create(36, 36, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center: Vector2 = Vector2(18, 21)
	for y: int in range(36):
		for x: int in range(36):
			var pos: Vector2 = Vector2(x, y)
			var d: float = pos.distance_to(center)
			if d <= 9.0:
				var col: Color = seed_col.lightened(clampf(1.0 - pos.distance_to(Vector2(15, 18)) / 7.0, 0.0, 0.3))
				img.set_pixel(x, y, col)
	# Sprout
	for sy: int in range(6, 14):
		img.set_pixel(18, sy, Color(0.35, 0.85, 0.28))
	for lx: int in range(14, 18):
		img.set_pixel(lx, 8, Color(0.35, 0.85, 0.28))
	for rx: int in range(18, 23):
		img.set_pixel(rx, 7, Color(0.35, 0.85, 0.28))
	return ImageTexture.create_from_image(img)

func _generate_carp_icon() -> ImageTexture:
	var img: Image = Image.create(36, 36, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center: Vector2 = Vector2(18, 18)
	var carp_col: Color = Color(0.96, 0.52, 0.16)
	for y: int in range(36):
		for x: int in range(36):
			var pos: Vector2 = Vector2(x, y)
			var dx: float = (pos.x - center.x) / 14.0
			var dy: float = (pos.y - center.y) / 7.0
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, carp_col)
	# Tail fin
	for ty: int in range(11, 26):
		img.set_pixel(5, ty, Color(0.88, 0.40, 0.12))
		img.set_pixel(6, ty, Color(0.92, 0.46, 0.14))
	# Eye
	img.set_pixel(27, 16, Color(0.1, 0.1, 0.1))
	return ImageTexture.create_from_image(img)
