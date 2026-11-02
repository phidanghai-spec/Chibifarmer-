# scripts/systems/daily_newspaper.gd
# Daily Newspaper System (Báo Nông Thôn - Chợ Phiên Giảm Giá Offline)
extends Node

signal newspaper_updated()

const TOTAL_SLOTS: int = 6
const REFRESH_INTERVAL_SECONDS: int = 180

var slots: Array[Dictionary] = []
var next_refresh_timestamp: int = 0

const NEIGHBORS: Array[Dictionary] = [
	{ "name": "Bác Ba Phi", "farm": "Trang Trại Ba Phi 🌾", "avatar": "npc_char_01", "specialty": "crops" },
	{ "name": "Cô Tư Hoa", "farm": "Vườn Hoa Tư Hoa 🌻", "avatar": "npc_char_04", "specialty": "florals" },
	{ "name": "Chú Bảy Cối Xay", "farm": "Cối Xay Chú Bảy 🥖", "avatar": "npc_baker", "specialty": "bakery" },
	{ "name": "Chị Sáu Bánh Ngọt", "farm": "Tiệm Bánh Chị Sáu 🍰", "avatar": "npc_pastry", "specialty": "pastry" },
	{ "name": "Anh Ba Đánh Cá", "farm": "Bến Sông Ba Cá 🐟", "avatar": "npc_fisher", "specialty": "fish" },
	{ "name": "Bác Năm Chăn Nuôi", "farm": "Trại Bò Bác Năm 🥛", "avatar": "npc_rancher", "specialty": "ranch" },
	{ "name": "Cụ Chín Bảo Tồn", "farm": "Trạm Cứu Hộ Động Vật 🐾", "avatar": "npc_char_06", "specialty": "zoo" }
]

const GOODS_CATALOG: Array[Dictionary] = [
	# Nông sản Silo
	{ "id": "wheat", "name": "Lúa mì", "type": "silo", "base_price": 4, "count_min": 6, "count_max": 12 },
	{ "id": "corn", "name": "Bắp ngô", "type": "silo", "base_price": 6, "count_min": 5, "count_max": 10 },
	{ "id": "carrot", "name": "Cà rốt", "type": "silo", "base_price": 8, "count_min": 4, "count_max": 8 },
	{ "id": "tomato", "name": "Cà chua", "type": "silo", "base_price": 10, "count_min": 4, "count_max": 8 },
	{ "id": "strawberry", "name": "Dâu tây", "type": "silo", "base_price": 14, "count_min": 3, "count_max": 6 },
	{ "id": "apple", "name": "Táo đỏ", "type": "silo", "base_price": 16, "count_min": 3, "count_max": 6 },
	
	# Cám & Chăn nuôi Barn
	{ "id": "chicken_feed", "name": "Cám Gà", "type": "barn", "base_price": 8, "count_min": 4, "count_max": 8 },
	{ "id": "cow_feed", "name": "Cám Bò", "type": "barn", "base_price": 12, "count_min": 3, "count_max": 6 },
	{ "id": "pig_feed", "name": "Cám Heo", "type": "barn", "base_price": 10, "count_min": 3, "count_max": 6 },
	{ "id": "milk", "name": "Sữa bò tươi", "type": "barn", "base_price": 24, "count_min": 2, "count_max": 5 },
	{ "id": "egg", "name": "Trứng gà", "type": "barn", "base_price": 16, "count_min": 3, "count_max": 6 },
	
	# Món ăn & Bánh ngọt Barn
	{ "id": "bread", "name": "Bánh mì ổ", "type": "barn", "base_price": 28, "count_min": 2, "count_max": 4 },
	{ "id": "cookie", "name": "Bánh quy bơ", "type": "barn", "base_price": 45, "count_min": 2, "count_max": 3 },
	{ "id": "cream_cake", "name": "Bánh kem tươi", "type": "barn", "base_price": 80, "count_min": 1, "count_max": 2 },
	{ "id": "fish_carp", "name": "Cá chép sông", "type": "barn", "base_price": 35, "count_min": 2, "count_max": 4 },
	
	# Vật phẩm đặc biệt Sở Thú
	{ "id": "sanctuary_feed", "name": "Bó Cỏ Dinh Dưỡng", "type": "barn", "base_price": 75, "count_min": 2, "count_max": 3 },
	{ "id": "puzzle_piece", "name": "Mảnh Ghép Sở Thú", "type": "special", "base_price": 260, "count_min": 1, "count_max": 1 }
]

func _ready() -> void:
	EventBus.second_ticked.connect(_on_second_ticked)
	# Check if existing slots saved in SaveManager
	if SaveManager != null and SaveManager.newspaper_data != null and SaveManager.newspaper_data.has("slots") and not (SaveManager.newspaper_data["slots"] as Array).is_empty():
		var saved_arr: Array = SaveManager.newspaper_data["slots"] as Array
		slots.clear()
		for s in saved_arr:
			slots.append(s as Dictionary)
		next_refresh_timestamp = SaveManager.newspaper_next_refresh
	
	if slots.is_empty() or next_refresh_timestamp <= TickManager.now():
		generate_new_issue()

func _on_second_ticked(_current_unix: int) -> void:
	if next_refresh_timestamp > 0 and TickManager.now() >= next_refresh_timestamp:
		generate_new_issue()

func generate_new_issue(force: bool = false) -> void:
	slots.clear()
	var shuffled_neighbors: Array = NEIGHBORS.duplicate()
	shuffled_neighbors.shuffle()
	
	var discount_tiers: Array[int] = [30, 35, 40, 45, 50]
	
	for i in range(TOTAL_SLOTS):
		var n_idx: int = i % shuffled_neighbors.size()
		var n_data: Dictionary = shuffled_neighbors[n_idx] as Dictionary
		
		# Pick catalog item
		var goods: Dictionary = GOODS_CATALOG.pick_random()
		# Make sure at least one slot in issue has sanctuary_feed or puzzle_piece
		if i == 5 and randf() < 0.65:
			goods = GOODS_CATALOG[GOODS_CATALOG.size() - (1 if randf() < 0.5 else 2)]
			
		var count: int = randi_range(int(goods["count_min"]), int(goods["count_max"]))
		var base_p: int = int(goods["base_price"]) * count
		var discount: int = discount_tiers.pick_random()
		var sale_p: int = maxi(1, int(float(base_p) * (1.0 - float(discount) / 100.0)))
		
		slots.append({
			"slot_index": i,
			"neighbor_name": String(n_data["name"]),
			"farm_name": String(n_data["farm"]),
			"avatar": String(n_data["avatar"]),
			"item_id": String(goods["id"]),
			"item_name": String(goods["name"]),
			"item_type": String(goods["type"]),
			"count": count,
			"original_price": base_p,
			"discount": discount,
			"sale_price": sale_p,
			"is_sold": false
		})
	
	next_refresh_timestamp = TickManager.now() + REFRESH_INTERVAL_SECONDS
	SaveManager.newspaper_data["slots"] = slots.duplicate(true)
	SaveManager.newspaper_next_refresh = next_refresh_timestamp
	SaveManager.save_game()
	newspaper_updated.emit()
	print("[DailyNewspaper] Issued fresh morning edition with 6 neighbor classifieds!")

func buy_slot(index: int) -> Dictionary:
	if index < 0 or index >= slots.size():
		return { "success": false, "message": "Ô tin không hợp lệ!" }
	
	var slot: Dictionary = slots[index]
	if bool(slot.get("is_sold", false)):
		return { "success": false, "message": "Mặt hàng này đã có người mua trước rồi!" }
	
	var cost: int = int(slot["sale_price"])
	if not StorageManager.has_gold(cost):
		return { "success": false, "message": "Bạn không đủ Vàng (Cần %d Vàng)!" % cost }
	
	var i_id: String = String(slot["item_id"])
	var i_type: String = String(slot["item_type"])
	var i_count: int = int(slot["count"])
	var i_name: String = String(slot["item_name"])
	
	# Storage capacity check
	if i_type == "silo":
		if not StorageManager.can_store_item(i_id, i_count):
			return { "success": false, "message": "Kho Silo đã đầy, hãy nâng cấp hoặc bán bớt nông sản!" }
	elif i_type == "barn":
		if not StorageManager.can_store_item(i_id, i_count):
			return { "success": false, "message": "Kho Barn đã đầy, hãy nâng cấp hoặc mở rộng kho!" }
	
	# Deduct gold & grant items
	StorageManager.spend_gold(cost)
	EventBus.gold_changed.emit(StorageManager.gold, -cost)
	
	if i_id == "puzzle_piece":
		SaveManager.add_puzzle_pieces(i_count)
	else:
		StorageManager.add_item(i_id, i_count)
		
	slot["is_sold"] = true
	SaveManager.newspaper_data["slots"] = slots.duplicate(true)
	SaveManager.save_game()
	newspaper_updated.emit()
	
	AudioManager.play_sfx("sell")
	return {
		"success": true,
		"message": "Mua thành công %d %s (-%d Vàng) về kho!" % [i_count, i_name, cost]
	}

func manual_refresh(cost: int = 50) -> bool:
	if not StorageManager.has_gold(cost):
		return false
	StorageManager.spend_gold(cost)
	EventBus.gold_changed.emit(StorageManager.gold, -cost)
	AudioManager.play_sfx("click")
	generate_new_issue(true)
	return true

func get_seconds_until_refresh() -> int:
	return maxi(0, next_refresh_timestamp - TickManager.now())

func get_time_remaining() -> int:
	return get_seconds_until_refresh()

func get_newspaper_slots() -> Array[Dictionary]:
	return slots

func force_refresh_newspaper() -> void:
	generate_new_issue(true)
