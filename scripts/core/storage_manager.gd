extends Node

var coins: int = 1500
var gold: int = 5450
var diamonds: int = 45
var xp: int = 1240
var level: int = 32

var silo_capacity: int = 200
var barn_capacity: int = 200

var silo_items: Dictionary = {}
var barn_items: Dictionary = {}

func _ready() -> void:
	_init_starter_inventory()

func _init_starter_inventory() -> void:
	# Initial stock mirroring Hay Day interface with all crop seeds and goods
	silo_items["wheat"] = 50
	silo_items["corn"] = 35
	silo_items["carrot"] = 15
	silo_items["soybean"] = 15
	silo_items["sugarcane"] = 10
	silo_items["strawberry"] = 10
	silo_items["tomato"] = 10
	silo_items["pumpkin"] = 10
	silo_items["apple"] = 5
	silo_items["mango"] = 5
	silo_items["apple_seed"] = 5
	silo_items["mango_seed"] = 5
	
	barn_items["egg"] = 25
	barn_items["milk"] = 20
	barn_items["bacon"] = 15
	barn_items["bread"] = 15
	barn_items["chicken_feed"] = 15
	barn_items["cow_feed"] = 15
	barn_items["pig_feed"] = 10
	barn_items["butter"] = 5
	barn_items["cheese"] = 5
	barn_items["cream"] = 5
	barn_items["fish_carp"] = 5
	
	_emit_storage_updated("silo")
	_emit_storage_updated("barn")
	EventBus.coins_changed.emit(coins, 0)
	EventBus.gold_changed.emit(gold, 0)
	EventBus.diamonds_changed.emit(diamonds, 0)
	EventBus.xp_changed.emit(xp, get_required_xp(level), level)

# --- Currency & Progression ---

func has_coins(amount: int) -> bool:
	return coins >= amount

func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	coins += amount
	EventBus.coins_changed.emit(coins, amount)

func spend_coins(amount: int) -> bool:
	if amount <= 0:
		return true
	if coins < amount:
		return false
	coins -= amount
	EventBus.coins_changed.emit(coins, -amount)
	return true

func has_gold(amount: int) -> bool:
	return gold >= amount

func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	EventBus.gold_changed.emit(gold, amount)

func spend_gold(amount: int) -> bool:
	if amount <= 0:
		return true
	if gold < amount:
		return false
	gold -= amount
	EventBus.gold_changed.emit(gold, -amount)
	return true

func has_diamonds(amount: int) -> bool:
	return diamonds >= amount

func add_diamonds(amount: int) -> void:
	if amount <= 0:
		return
	diamonds += amount
	EventBus.diamonds_changed.emit(diamonds, amount)

func spend_diamonds(amount: int) -> bool:
	if amount <= 0:
		return true
	if diamonds < amount:
		return false
	diamonds -= amount
	EventBus.diamonds_changed.emit(diamonds, -amount)
	return true

const LEVEL_XP_TABLE: Dictionary = {
	1: 20,
	2: 30,
	3: 45,
	4: 75,
	5: 170,
	6: 250,
	7: 380,
	8: 520,
	9: 720,
	10: 950,
	11: 1250,
	12: 1650,
	13: 2100,
	14: 2600,
	15: 3200,
	16: 3800
}

func get_required_xp(target_level: int) -> int:
	if LEVEL_XP_TABLE.has(target_level):
		return int(LEVEL_XP_TABLE[target_level])
	return int(3800 + (target_level - 16) * 800)

func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	xp += amount
	
	var needed: int = get_required_xp(level)
	while xp >= needed:
		xp -= needed
		level += 1
		var gold_reward: int = 8 if level >= 8 else 5
		add_gold(gold_reward)
		EventBus.leveled_up.emit(level)
		needed = get_required_xp(level)
		print("[StorageManager] Level up! New level: ", level, " (+", gold_reward, " Vàng thưởng!)")
	
	EventBus.xp_changed.emit(xp, needed, level)

# --- Dual Storage (Silo & Barn) ---

func get_silo_used() -> int:
	var total: int = 0
	for key: Variant in silo_items:
		total += int(silo_items[key])
	return total

func get_barn_used() -> int:
	var total: int = 0
	for key: Variant in barn_items:
		total += int(barn_items[key])
	return total

func get_storage_used(storage_type: String) -> int:
	if storage_type == "silo":
		return get_silo_used()
	return get_barn_used()

func get_storage_capacity(storage_type: String) -> int:
	if storage_type == "silo":
		return silo_capacity
	return barn_capacity

func can_store_item(item_id: String, count: int) -> bool:
	if count <= 0:
		return true
	var storage_type: String = DataManager.get_item_storage_type(item_id)
	return can_store_in_storage(storage_type, count)

func can_store_in_storage(storage_type: String, count: int) -> bool:
	if count <= 0:
		return true
	var used: int = get_storage_used(storage_type)
	var max_cap: int = get_storage_capacity(storage_type)
	return (used + count) <= max_cap

func add_item(item_id: String, count: int) -> bool:
	var storage_type: String = DataManager.get_item_storage_type(item_id)
	return add_item_to_storage(storage_type, item_id, count)

func add_item_to_storage(storage_type: String, item_id: String, count: int) -> bool:
	if count <= 0:
		return true
	if not can_store_in_storage(storage_type, count):
		return false
	
	if storage_type == "silo":
		silo_items[item_id] = int(silo_items.get(item_id, 0)) + count
	else:
		barn_items[item_id] = int(barn_items.get(item_id, 0)) + count
	
	_emit_storage_updated(storage_type)
	EventBus.item_added.emit(item_id, count, storage_type)
	return true

func remove_item(item_id: String, count: int) -> bool:
	var storage_type: String = DataManager.get_item_storage_type(item_id)
	return remove_item_from_storage(storage_type, item_id, count)

func remove_item_from_storage(storage_type: String, item_id: String, count: int) -> bool:
	if count <= 0:
		return true
	if not has_item_in_storage(storage_type, item_id, count):
		return false
	
	if storage_type == "silo":
		var current: int = int(silo_items.get(item_id, 0))
		var remainder: int = current - count
		if remainder <= 0:
			silo_items.erase(item_id)
		else:
			silo_items[item_id] = remainder
	else:
		var current: int = int(barn_items.get(item_id, 0))
		var remainder: int = current - count
		if remainder <= 0:
			barn_items.erase(item_id)
		else:
			barn_items[item_id] = remainder
	
	_emit_storage_updated(storage_type)
	EventBus.item_removed.emit(item_id, count, storage_type)
	return true

func has_item(item_id: String, count: int) -> bool:
	var storage_type: String = DataManager.get_item_storage_type(item_id)
	return has_item_in_storage(storage_type, item_id, count)

func has_item_in_storage(storage_type: String, item_id: String, count: int) -> bool:
	return get_item_count_in_storage(storage_type, item_id) >= count

func get_item_count(item_id: String) -> int:
	var storage_type: String = DataManager.get_item_storage_type(item_id)
	return get_item_count_in_storage(storage_type, item_id)

func get_item_count_in_storage(storage_type: String, item_id: String) -> int:
	if storage_type == "silo":
		return int(silo_items.get(item_id, 0))
	return int(barn_items.get(item_id, 0))

func upgrade_storage(storage_type: String, capacity_increase: int) -> void:
	if capacity_increase <= 0:
		return
	if storage_type == "silo":
		silo_capacity += capacity_increase
	else:
		barn_capacity += capacity_increase
	_emit_storage_updated(storage_type)

func _emit_storage_updated(storage_type: String) -> void:
	var used: int = get_storage_used(storage_type)
	var max_cap: int = get_storage_capacity(storage_type)
	EventBus.storage_updated.emit(storage_type, used, max_cap)

func get_gold() -> int:
	return gold
