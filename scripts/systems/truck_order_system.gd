extends Node

signal orders_updated()

const ORDER_COUNT: int = 4

# Array of order Dictionaries
var active_orders: Array[Dictionary] = []
var _order_counter: int = 1

func _ready() -> void:
	generate_initial_orders()

func generate_initial_orders() -> void:
	active_orders.clear()
	for i: int in range(ORDER_COUNT):
		active_orders.append(_create_random_order())
	orders_updated.emit()

func _create_random_order() -> Dictionary:
	var order_id: String = "TRUCK_%03d" % _order_counter
	_order_counter += 1
	
	# Possible items to order from Silo and Barn
	var possible_crops: Array[String] = ["wheat", "corn", "carrot", "apple"]
	var possible_goods: Array[String] = ["egg", "milk", "bread", "cow_feed"]
	
	var requirements: Dictionary = {}
	var total_base_val: int = 0
	
	# 1st item (crop)
	var crop: String = possible_crops.pick_random()
	var crop_qty: int = randi_range(2, 6)
	requirements[crop] = crop_qty
	total_base_val += DataManager.get_item_base_price(crop) * crop_qty
	
	# 2nd item (product or second crop)
	var good: String = possible_goods.pick_random()
	var good_qty: int = randi_range(1, 3)
	requirements[good] = good_qty
	total_base_val += DataManager.get_item_base_price(good) * good_qty
	
	# Calculate balanced rewards: 130% coins + 1-2 gold + XP
	var reward_coins: int = int(total_base_val * 1.3)
	var reward_gold: int = randi_range(1, 2)
	var reward_xp: int = int(total_base_val * 0.5) + 15
	
	return {
		"order_id": order_id,
		"requirements": requirements,
		"reward_coins": reward_coins,
		"reward_gold": reward_gold,
		"reward_xp": reward_xp
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
	var reward_coins: int = int(order.get("reward_coins", int(order.get("reward_gold", 0))))
	var reward_gold: int = int(order.get("reward_gold", 1))
	var reward_xp: int = int(order.get("reward_xp", 0))
	var order_id: String = String(order.get("order_id", ""))
	
	# 1. Deduct items from Silo/Barn
	for item_id: Variant in reqs:
		var count: int = int(reqs[item_id])
		StorageManager.remove_item(String(item_id), count)
	
	# 2. Reward Coins, Gold and XP
	StorageManager.add_coins(reward_coins)
	StorageManager.add_gold(reward_gold)
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
		active_orders[order_index] = _create_random_order()
		orders_updated.emit()
		print("[TruckOrderSystem] Discarded order and generated new one.")
