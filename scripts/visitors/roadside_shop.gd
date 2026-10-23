extends Node

signal shop_updated()

const TOTAL_SLOTS: int = 6

# Array of slot Dictionaries
var slots: Array[Dictionary] = []

func _ready() -> void:
	_init_slots()

func _init_slots() -> void:
	slots.clear()
	for i: int in range(TOTAL_SLOTS):
		slots.append({
			"slot_index": i,
			"item_id": "",
			"count": 0,
			"price": 0,
			"is_sold": false
		})
	
	# Pre-populate sample slots like in Hay Day
	# Slot 0: 10 eggs for sale
	slots[0]["item_id"] = "egg"
	slots[0]["count"] = 5
	slots[0]["price"] = 90
	slots[0]["is_sold"] = false
	
	# Slot 1: Sold wheat ready to collect coins
	slots[1]["item_id"] = "wheat"
	slots[1]["count"] = 10
	slots[1]["price"] = 36
	slots[1]["is_sold"] = true
	
	# Slot 2: 2 bread loaves
	slots[2]["item_id"] = "bread"
	slots[2]["count"] = 2
	slots[2]["price"] = 42
	slots[2]["is_sold"] = false
	
	shop_updated.emit()

func get_slots() -> Array[Dictionary]:
	return slots

func get_slot(slot_index: int) -> Dictionary:
	if slot_index >= 0 and slot_index < slots.size():
		return slots[slot_index]
	return {}

func is_slot_empty(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= slots.size():
		return false
	var slot: Dictionary = slots[slot_index]
	return String(slot.get("item_id", "")) == ""

func get_suggested_price(item_id: String, count: int) -> int:
	var base: int = DataManager.get_item_base_price(item_id)
	return int(base * count * 1.2) # Hay Day default max suggested price

func list_item(slot_index: int, item_id: String, count: int, price: int) -> bool:
	if slot_index < 0 or slot_index >= slots.size():
		return false
	if not is_slot_empty(slot_index):
		return false
	if not StorageManager.has_item(item_id, count):
		return false
	
	# Deduct from storage (Silo or Barn)
	if not StorageManager.remove_item(item_id, count):
		return false
	
	slots[slot_index]["item_id"] = item_id
	slots[slot_index]["count"] = count
	slots[slot_index]["price"] = price
	slots[slot_index]["is_sold"] = false
	
	shop_updated.emit()
	print("[RoadsideShop] Listed ", count, "x ", item_id, " for ", price, " gold in slot ", slot_index)
	return true

func collect_coins(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= slots.size():
		return false
	
	var slot: Dictionary = slots[slot_index]
	if not bool(slot.get("is_sold", false)):
		return false
	
	var coins: int = int(slot.get("price", 0))
	StorageManager.add_gold(coins)
	AudioManager.play_sfx("coin")
	
	# Clear slot
	slot["item_id"] = ""
	slot["count"] = 0
	slot["price"] = 0
	slot["is_sold"] = false
	
	shop_updated.emit()
	print("[RoadsideShop] Collected ", coins, " gold from slot ", slot_index)
	return true

func buy_slot_by_shopper(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= slots.size():
		return false
	
	var slot: Dictionary = slots[slot_index]
	if String(slot.get("item_id", "")) == "" or bool(slot.get("is_sold", false)):
		return false
	
	slot["is_sold"] = true
	var item_id: String = String(slot.get("item_id", ""))
	var count: int = int(slot.get("count", 0))
	var price: int = int(slot.get("price", 0))
	
	EventBus.roadside_shop_item_sold.emit(slot_index, item_id, count, price)
	shop_updated.emit()
	print("[RoadsideShop] Shopper bought slot ", slot_index, ": ", count, "x ", item_id)
	return true

func buy_random_available_slot() -> bool:
	var available: Array[int] = []
	for i: int in range(slots.size()):
		var slot: Dictionary = slots[i]
		if String(slot.get("item_id", "")) != "" and not bool(slot.get("is_sold", false)):
			available.append(i)
	
	if available.is_empty():
		return false
	
	var picked: int = available.pick_random()
	return buy_slot_by_shopper(picked)
