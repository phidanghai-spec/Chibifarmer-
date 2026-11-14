extends Node

signal orders_updated()

const ORDER_COUNT: int = 4
const TRUCK_ORDERS_PATH: String = "res://data/truck_orders.json"
const GOLD_VALUE_MULTIPLIER: float = 1.25

# Array of order Dictionaries
var active_orders: Array[Dictionary] = []
var _order_counter: int = 1
var _order_config: Dictionary = {}
var _candidate_crops: Array[String] = []
var _candidate_products: Array[String] = []
var _config_loaded: bool = false

func _ready() -> void:
	_load_truck_config()
	generate_initial_orders()
	if not EventBus.second_ticked.is_connected(_on_second_ticked):
		EventBus.second_ticked.connect(_on_second_ticked)

func _load_truck_config() -> void:
	_config_loaded = true
	_order_config = {}
	_candidate_crops = []
	_candidate_products = []

	if not FileAccess.file_exists(TRUCK_ORDERS_PATH):
		push_warning("[TruckOrderSystem] Config not found: " + TRUCK_ORDERS_PATH)
		_candidate_crops = ["wheat", "corn"]
		_candidate_products = ["egg", "bread"]
		return

	var file: FileAccess = FileAccess.open(TRUCK_ORDERS_PATH, FileAccess.READ)
	if file == null:
		push_warning("[TruckOrderSystem] Could not open: " + TRUCK_ORDERS_PATH)
		_candidate_crops = ["wheat", "corn"]
		_candidate_products = ["egg", "bread"]
		return

	var json_text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var err: Error = json.parse(json_text)
	if err != OK or typeof(json.data) != TYPE_DICTIONARY:
		push_warning("[TruckOrderSystem] Failed to parse " + TRUCK_ORDERS_PATH)
		_candidate_crops = ["wheat", "corn"]
		_candidate_products = ["egg", "bread"]
		return

	var data: Dictionary = json.data as Dictionary
	if data.has("order_config") and typeof(data["order_config"]) == TYPE_DICTIONARY:
		_order_config = data["order_config"] as Dictionary

	if data.has("candidate_crops") and typeof(data["candidate_crops"]) == TYPE_ARRAY:
		for c: Variant in data["candidate_crops"] as Array:
			_candidate_crops.append(String(c))

	if data.has("candidate_products") and typeof(data["candidate_products"]) == TYPE_ARRAY:
		for p: Variant in data["candidate_products"] as Array:
			_candidate_products.append(String(p))

func _get_crop_unlock_level(crop_id: String) -> int:
	if DataManager.crops.has(crop_id):
		return int((DataManager.crops[crop_id] as Dictionary).get("unlock_level", 1))
	if DataManager.items.has(crop_id):
		return int((DataManager.items[crop_id] as Dictionary).get("unlock_level", 1))
	return 1

func _get_product_unlock_level(product_id: String) -> int:
	if DataManager.recipes.has(product_id):
		return int((DataManager.recipes[product_id] as Dictionary).get("unlock_level", 1))
	if DataManager.items.has(product_id):
		return int((DataManager.items[product_id] as Dictionary).get("unlock_level", 1))
	return 1

func generate_initial_orders() -> void:
	if not _config_loaded:
		_load_truck_config()
	active_orders.clear()
	for i: int in range(ORDER_COUNT):
		active_orders.append(_create_random_order())
	orders_updated.emit()

func _create_random_order() -> Dictionary:
	if not _config_loaded:
		_load_truck_config()

	var order_id: String = "TRUCK_%03d" % _order_counter
	_order_counter += 1

	var cur_lvl: int = StorageManager.level
	var possible_crops: Array[String] = []
	var possible_products: Array[String] = []

	for crop_id: String in _candidate_crops:
		if _get_crop_unlock_level(crop_id) <= cur_lvl:
			possible_crops.append(crop_id)

	for prod_id: String in _candidate_products:
		if _get_product_unlock_level(prod_id) <= cur_lvl:
			possible_products.append(prod_id)

	var pool: Array[String] = []
	pool.append_array(possible_crops)
	pool.append_array(possible_products)
	if pool.is_empty():
		pool.append("wheat")

	var min_items: int = int(_order_config.get("min_items", 2))
	var max_items: int = int(_order_config.get("max_items", 4))
	var min_duration: int = int(_order_config.get("min_duration_seconds", 1800))
	var max_duration: int = int(_order_config.get("max_duration_seconds", 7200))
	var min_coins_reward: int = int(_order_config.get("min_gold_reward", 1))
	var max_coins_reward: int = int(_order_config.get("max_gold_reward", 2))
	var base_xp_reward: int = int(_order_config.get("base_xp_reward", 20))

	var target_count: int = clampi(randi_range(min_items, max_items), 1, pool.size())
	pool.shuffle()

	var requirements: Dictionary = {}
	var total_base_price: int = 0
	for i: int in range(target_count):
		var item_id: String = pool[i]
		var qty: int = randi_range(2, 5) if item_id in possible_crops else randi_range(1, 3)
		requirements[item_id] = qty
		total_base_price += DataManager.get_item_base_price(item_id) * qty

	var reward_gold: int = int(total_base_price * GOLD_VALUE_MULTIPLIER)
	var reward_coins: int = randi_range(min_coins_reward, max_coins_reward)
	var reward_xp: int = base_xp_reward
	var duration_seconds: int = randi_range(min_duration, max_duration)

	return {
		"order_id": order_id,
		"requirements": requirements,
		"reward_gold": reward_gold,
		"reward_coins": reward_coins,
		"reward_xp": reward_xp,
		"duration_seconds": duration_seconds,
		"is_refreshing": false,
		"refresh_seconds": 0
	}

func get_orders() -> Array[Dictionary]:
	return active_orders

func can_fulfill_order(order_index: int) -> bool:
	if order_index < 0 or order_index >= active_orders.size():
		return false
	
	var order: Dictionary = active_orders[order_index]
	var reqs: Dictionary = order.get("requirements", {}) as Dictionary
	for item_id: Variant in reqs:
		var count: int = int(reqs[item_id])
		if not StorageManager.has_item(String(item_id), count):
			return false
	return true

func fulfill_order(order_index: int) -> bool:
	if not can_fulfill_order(order_index):
		return false
	
	var order: Dictionary = active_orders[order_index]
	var reqs: Dictionary = order.get("requirements", {}) as Dictionary
	var reward_coins: int = int(order.get("reward_coins", 0))
	var reward_gold: int = int(order.get("reward_gold", 0))
	var reward_xp: int = int(order.get("reward_xp", 0))
	var order_id: String = String(order.get("order_id", ""))
	
	# 1. Deduct items from Silo/Barn
	for item_id: Variant in reqs:
		var count: int = int(reqs[item_id])
		StorageManager.remove_item(String(item_id), count)
	
	# 2. Reward Coins, Gold and XP
	if reward_coins > 0:
		StorageManager.add_coins(reward_coins)
	if reward_gold > 0:
		StorageManager.add_gold(reward_gold)
	if reward_xp > 0:
		StorageManager.add_xp(reward_xp)
	AudioManager.play_sfx("coin")
	
	EventBus.truck_order_completed.emit(order_id, reward_gold, reward_xp)
	print("[TruckOrderSystem] Fulfilled order ", order_id, "! Earned +", reward_coins, " coins, +", reward_gold, " gold, +", reward_xp, " XP")
	
	# 3. Generate replacement order
	active_orders[order_index] = _create_random_order()
	orders_updated.emit()
	return true

func trash_order(order_index: int) -> void:
	if order_index >= 0 and order_index < active_orders.size():
		var ord: Dictionary = active_orders[order_index]
		if bool(ord.get("is_refreshing", false)):
			return
		ord["is_refreshing"] = true
		ord["refresh_seconds"] = 15
		ord["refresh_time_left"] = 15
		orders_updated.emit()
		print("[TruckOrderSystem] Discarded order, finding new order in 15s...")

func _on_second_ticked(_current_unix: int) -> void:
	var updated: bool = false
	for i: int in range(active_orders.size()):
		var ord: Dictionary = active_orders[i]
		if bool(ord.get("is_refreshing", false)):
			var sec: int = int(ord.get("refresh_seconds", 0)) - 1
			ord["refresh_seconds"] = sec
			ord["refresh_time_left"] = sec
			if sec <= 0:
				active_orders[i] = _create_random_order()
				updated = true
	if updated:
		orders_updated.emit()

func export_state() -> Array:
	return active_orders.duplicate(true)

func import_state(saved_orders: Array) -> void:
	if not saved_orders.is_empty():
		active_orders.clear()
		for item: Variant in saved_orders:
			if item is Dictionary:
				active_orders.append((item as Dictionary).duplicate(true))
	orders_updated.emit()
