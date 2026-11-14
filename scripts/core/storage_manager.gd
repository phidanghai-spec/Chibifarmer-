extends Node

var coins: int = 100
var gold: int = 500
var diamonds: int = 15
var xp: int = 0
var level: int = 1

var silo_capacity: int = 100
var barn_capacity: int = 100
var purchased_silo_bonus: int = 0
var purchased_barn_bonus: int = 0

var silo_items: Dictionary = {}
var barn_items: Dictionary = {}

const ITEM_NAMES: Dictionary = {
	"mat_plank": "Ván Gỗ Thông",
	"mat_bolt": "Đinh Tán Thép",
	"mat_brick": "Gạch Nung Đỏ"
}

const CONSTRUCTION_MATERIALS: Array[String] = ["mat_plank", "mat_bolt", "mat_brick"]

func _ready() -> void:
	_init_starter_inventory()
	recalculate_capacities()

func _init_starter_inventory() -> void:
	silo_items.clear()
	silo_items["wheat"] = 10
	silo_items["corn"] = 5
	silo_items["carrot"] = 5
	silo_items["apple_seed"] = 2
	silo_items["mango_seed"] = 2
	
	barn_items.clear()
	barn_items["chicken_feed"] = 5
	barn_items["cow_feed"] = 5
	barn_items["egg"] = 2
	barn_items["milk"] = 2
	barn_items["mat_plank"] = 1
	barn_items["mat_bolt"] = 1
	barn_items["mat_brick"] = 1
	
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
	2: 35,
	3: 50,
	4: 75,
	5: 110,
	6: 150,
	7: 200,
	8: 260,
	9: 330,
	10: 420,
	11: 500,
	12: 600,
	13: 720,
	14: 860,
	15: 1000,
	16: 1150
}

func get_required_xp(target_level: int) -> int:
	if target_level <= 16:
		return int(LEVEL_XP_TABLE.get(target_level, 20))
	return int(1150 + (target_level - 16) * 300)

func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	xp += amount
	
	var needed: int = get_required_xp(level)
	while xp >= needed:
		xp -= needed
		level += 1
		recalculate_capacities()
		var gold_reward: int = 150 + level * 25
		var dia_reward: int = 2
		add_gold(gold_reward)
		add_diamonds(dia_reward)
		EventBus.leveled_up.emit(level)
		needed = get_required_xp(level)
		print("[StorageManager] Level up! New level: ", level, " (+", gold_reward, " Vàng, +", dia_reward, " Kim Cương thưởng!)")
	
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

func get_current_silo_usage() -> int:
	return get_silo_used()

func get_current_barn_usage() -> int:
	return get_barn_used()

func get_silo_capacity_left() -> int:
	return maxi(0, silo_capacity - get_current_silo_usage())

func get_barn_capacity_left() -> int:
	return maxi(0, barn_capacity - get_current_barn_usage())

func get_item_display_name(item_id: String) -> String:
	if ITEM_NAMES.has(item_id):
		return String(ITEM_NAMES[item_id])
	return DataManager.get_item_name(item_id)

func try_drop_bonus_material(_source_label: String = "") -> String:
	if get_barn_capacity_left() <= 0:
		return ""
	if randf() > 0.25:
		return ""
	var mat_id: String = CONSTRUCTION_MATERIALS[randi() % CONSTRUCTION_MATERIALS.size()]
	if add_item_to_storage("barn", mat_id, 1):
		return mat_id
	return ""

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

func recalculate_capacities() -> void:
	var rewards: Dictionary = DataManager.get_level_rewards() if DataManager != null else {}
	var new_silo_cap: int = 100 + purchased_silo_bonus
	var new_barn_cap: int = 100 + purchased_barn_bonus

	var cap_entries: Array = rewards.get("silo_barn_capacity", []) as Array
	for entry_var: Variant in cap_entries:
		if typeof(entry_var) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_var as Dictionary
		if int(entry.get("level", 999999)) <= level:
			var add_val: int = int(entry.get("add", 0))
			new_silo_cap += add_val
			new_barn_cap += add_val

	var double_entries: Array = rewards.get("barn_capacity_double", []) as Array
	for entry_var: Variant in double_entries:
		if typeof(entry_var) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_var as Dictionary
		if int(entry.get("level", 999999)) <= level:
			new_barn_cap *= 2
			break

	silo_capacity = new_silo_cap
	barn_capacity = new_barn_cap
	EventBus.storage_updated.emit("silo", get_silo_used(), silo_capacity)
	EventBus.storage_updated.emit("barn", get_barn_used(), barn_capacity)

func upgrade_storage(storage_type: String, capacity_increase: int) -> void:
	if capacity_increase <= 0:
		return
	if storage_type == "silo":
		purchased_silo_bonus += capacity_increase
	else:
		purchased_barn_bonus += capacity_increase
	recalculate_capacities()

func _emit_storage_updated(storage_type: String) -> void:
	var used: int = get_storage_used(storage_type)
	var max_cap: int = get_storage_capacity(storage_type)
	EventBus.storage_updated.emit(storage_type, used, max_cap)

func get_gold() -> int:
	return gold
