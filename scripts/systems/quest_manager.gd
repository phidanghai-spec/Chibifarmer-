extends Node
class_name QuestManager

signal quest_progress_changed(quest_id: String)
signal quest_claimed(quest_id: String)
signal vip_requests_updated()

# 12 Mốc Nhiệm Vụ Cốt Truyện Nông Trại & Sở Thú Chia 3 Chương
var story_quests: Array[Dictionary] = [
	# --- CHƯƠNG 1: KHÔI PHỤC NÔNG TRẠI ---
	{
		"id": "main_01",
		"chapter": 1,
		"chapter_title": "Chương 1: Khôi Phục Nông Trại",
		"title": "Mùa Gặt Đầu Tiên",
		"desc": "Thu hoạch 6 cây trồng bất kỳ trên đồng ruộng.",
		"target": 6,
		"type": "harvest",
		"reward_gold": 150,
		"reward_xp": 50,
		"reward_coins": 0,
		"reward_diamonds": 0,
		"reward_pieces": 1,
		"nav_pos": Vector2(440, 560),
		"nav_name": "Khu Ruộng Trồng Trọt"
	},
	{
		"id": "main_02",
		"chapter": 1,
		"chapter_title": "Chương 1: Khôi Phục Nông Trại",
		"title": "Xay Cám Chăn Nuôi",
		"desc": "Thu hoạch 3 sản phẩm từ chuồng trại gia súc hoặc xưởng sản xuất.",
		"target": 3,
		"type": "pen_or_production",
		"reward_gold": 200,
		"reward_xp": 80,
		"reward_coins": 0,
		"reward_diamonds": 0,
		"reward_pieces": 1,
		"nav_pos": Vector2(300, 320),
		"nav_name": "Khu Chuồng Trại Gia Súc"
	},
	{
		"id": "main_03",
		"chapter": 1,
		"chapter_title": "Chương 1: Khôi Phục Nông Trại",
		"title": "Chào Đón Capybara",
		"desc": "Cho Capybara ở Khu Bảo Tồn Sở Thú ăn 1 lần.",
		"target": 1,
		"type": "zoo_feed",
		"reward_gold": 0,
		"reward_xp": 100,
		"reward_coins": 250,
		"reward_diamonds": 0,
		"reward_pieces": 2,
		"nav_pos": Vector2(1290, 195),
		"nav_name": "Hồ Capybara Sở Thú"
	},
	{
		"id": "main_04",
		"chapter": 1,
		"chapter_title": "Chương 1: Khôi Phục Nông Trại",
		"title": "Đầu Bếp Bảo Tồn",
		"desc": "Chế biến và thu hoạch 2 món tại các Nhà máy nông trại.",
		"target": 2,
		"type": "production",
		"reward_gold": 300,
		"reward_xp": 120,
		"reward_coins": 0,
		"reward_diamonds": 0,
		"reward_pieces": 2,
		"nav_pos": Vector2(570, 270),
		"nav_name": "Xưởng Chế Biến Bánh Mì"
	},

	# --- CHƯƠNG 2: KHAI TRƯƠNG SỞ THÚ ---
	{
		"id": "main_05",
		"chapter": 2,
		"chapter_title": "Chương 2: Khai Trương Sở Thú",
		"title": "Mở Khóa Bạn Mới",
		"desc": "Mở khóa thêm 1 chuồng thú tại Khu Bảo Tồn Sở Thú bờ Đông.",
		"target": 1,
		"type": "zoo_unlock",
		"reward_gold": 0,
		"reward_xp": 150,
		"reward_coins": 350,
		"reward_diamonds": 0,
		"reward_pieces": 2,
		"nav_pos": Vector2(1450, 195),
		"nav_name": "Chuồng Thú Bờ Đông"
	},
	{
		"id": "main_06",
		"chapter": 2,
		"chapter_title": "Chương 2: Khai Trương Sở Thú",
		"title": "Ngư Thủ Bờ Sông",
		"desc": "Câu thành công 2 con cá tại Đầm Câu Cá bờ sông.",
		"target": 2,
		"type": "fish",
		"reward_gold": 400,
		"reward_xp": 180,
		"reward_coins": 0,
		"reward_diamonds": 0,
		"reward_pieces": 3,
		"nav_pos": Vector2(780, 720),
		"nav_name": "Đầm Câu Cá Tự Nhiên"
	},
	{
		"id": "main_07",
		"chapter": 2,
		"chapter_title": "Chương 2: Khai Trương Sở Thú",
		"title": "Chăm Sóc Khu Bảo Tồn",
		"desc": "Cho các loài thú ở Sở Thú ăn tổng cộng 3 lần.",
		"target": 3,
		"type": "zoo_feed",
		"reward_gold": 0,
		"reward_xp": 200,
		"reward_coins": 450,
		"reward_diamonds": 0,
		"reward_pieces": 3,
		"nav_pos": Vector2(1290, 195),
		"nav_name": "Khu Bảo Tồn Bờ Đông"
	},
	{
		"id": "main_08",
		"chapter": 2,
		"chapter_title": "Chương 2: Khai Trương Sở Thú",
		"title": "Vườn Quả Ngọt Lành",
		"desc": "Thu hoạch 8 nông sản hoặc cây trái tích trữ kho Silo.",
		"target": 8,
		"type": "harvest",
		"reward_gold": 500,
		"reward_xp": 220,
		"reward_coins": 0,
		"reward_diamonds": 0,
		"reward_pieces": 3,
		"nav_pos": Vector2(440, 560),
		"nav_name": "Khu Ruộng & Vườn Quả"
	},

	# --- CHƯƠNG 3: THIÊN ĐƯỜNG DU LỊCH ---
	{
		"id": "main_09",
		"chapter": 3,
		"chapter_title": "Chương 3: Thiên Đường Du Lịch",
		"title": "Điểm Check-in Nổi Tiếng",
		"desc": "Đón 4 lượt Du Khách ghé thăm, mua hàng hoặc rơi tiền Tip.",
		"target": 4,
		"type": "visitor",
		"reward_gold": 0,
		"reward_xp": 250,
		"reward_coins": 600,
		"reward_diamonds": 5,
		"reward_pieces": 0,
		"nav_pos": Vector2(192, 544),
		"nav_name": "Sạp Hàng Bên Đường"
	},
	{
		"id": "main_10",
		"chapter": 3,
		"chapter_title": "Chương 3: Thiên Đường Du Lịch",
		"title": "Thương Gia Nông Sản",
		"desc": "Giao 3 đơn hàng xe tải, đơn sạp hàng hoặc khách VIP.",
		"target": 3,
		"type": "delivery_or_shop",
		"reward_gold": 800,
		"reward_xp": 300,
		"reward_coins": 0,
		"reward_diamonds": 5,
		"reward_pieces": 0,
		"nav_pos": Vector2(435, 660),
		"nav_name": "Bến Bãi Xe Tải Giao Hàng"
	},
	{
		"id": "main_11",
		"chapter": 3,
		"chapter_title": "Chương 3: Thiên Đường Du Lịch",
		"title": "Sở Thú Trọn Vẹn",
		"desc": "Mở khóa toàn bộ 4 chuồng thú quý hiếm tại Sở Thú bờ Đông.",
		"target": 4,
		"type": "zoo_all_unlocked",
		"reward_gold": 0,
		"reward_xp": 400,
		"reward_coins": 1000,
		"reward_diamonds": 10,
		"reward_pieces": 5,
		"nav_pos": Vector2(1370, 295),
		"nav_name": "Quần Thể Sở Thú Bờ Đông"
	},
	{
		"id": "main_12",
		"chapter": 3,
		"chapter_title": "Chương 3: Thiên Đường Du Lịch",
		"title": "Thiên Đường Nông Trại",
		"desc": "Đạt 350 Điểm Hấp Dẫn Nông Trại (Attraction Score).",
		"target": 350,
		"type": "attraction",
		"reward_gold": 1500,
		"reward_xp": 500,
		"reward_coins": 0,
		"reward_diamonds": 15,
		"reward_pieces": 0,
		"nav_pos": Vector2(1185, 440),
		"nav_name": "Cổng Khu Bảo Tồn Sở Thú"
	}
]

# 4 Nhiệm vụ hàng ngày phong phú (+25 Điểm Năng Động mỗi khi nhận thưởng)
var daily_quest_pool: Array[Dictionary] = [
	{
		"id": "daily_harvest",
		"title": "Nông Dân Chăm Chỉ",
		"desc": "Thu hoạch 6 cây trồng bất kỳ trên ruộng đất.",
		"target": 6,
		"type": "harvest",
		"reward_gold": 150,
		"reward_xp": 50,
		"reward_coins": 0,
		"reward_diamonds": 0,
		"reward_pieces": 1,
		"nav_pos": Vector2(440, 560),
		"nav_name": "Khu Ruộng Trồng Trọt"
	},
	{
		"id": "daily_feed_pen",
		"title": "Gia Súc No Nê",
		"desc": "Cho gà, bò hoặc heo trong chuồng ăn 2 lần.",
		"target": 2,
		"type": "pen_feed",
		"reward_gold": 120,
		"reward_xp": 40,
		"reward_coins": 0,
		"reward_diamonds": 0,
		"reward_pieces": 1,
		"nav_pos": Vector2(300, 320),
		"nav_name": "Chuồng Gia Súc"
	},
	{
		"id": "daily_feed_zoo",
		"title": "Bảo Tồn Bờ Đông",
		"desc": "Cho thú Sở Thú ăn cỏ dinh dưỡng hoặc món yêu thích 1 lần.",
		"target": 1,
		"type": "zoo_feed",
		"reward_gold": 0,
		"reward_xp": 60,
		"reward_coins": 200,
		"reward_diamonds": 0,
		"reward_pieces": 1,
		"nav_pos": Vector2(1290, 195),
		"nav_name": "Chuồng Thú Sở Thú"
	},
	{
		"id": "daily_fish",
		"title": "Vận May Đầm Cá",
		"desc": "Câu thành công 1 con cá từ hồ câu tự nhiên.",
		"target": 1,
		"type": "fish",
		"reward_gold": 160,
		"reward_xp": 50,
		"reward_coins": 0,
		"reward_diamonds": 0,
		"reward_pieces": 1,
		"nav_pos": Vector2(780, 720),
		"nav_name": "Đầm Câu Cá"
	}
]

# Thư viện Đơn Hàng Du Khách VIP Sở Thú
const VIP_POOL: Array[Dictionary] = [
	{
		"id": "vip_photo",
		"name": "Nhiếp Ảnh Gia Minh Anh",
		"avatar": "📸",
		"dialogue": "Tôi đang săn ảnh Chibi hoang dã bên hồ Capybara, cần chút năng lượng!",
		"needs": [
			{"item": "carrot", "count": 2},
			{"item": "bread", "count": 1}
		],
		"reward_gold": 300,
		"reward_coins": 250,
		"reward_xp": 120,
		"reward_pieces": 1
	},
	{
		"id": "vip_school",
		"name": "Đoàn Học Sinh Dã Ngoại",
		"avatar": "🎒",
		"dialogue": "Các bạn nhỏ muốn xem Capybara tắm nước nóng, cần mua lúa mì và trứng gà!",
		"needs": [
			{"item": "wheat", "count": 3},
			{"item": "egg", "count": 2}
		],
		"reward_gold": 260,
		"reward_coins": 220,
		"reward_xp": 110,
		"reward_pieces": 1
	},
	{
		"id": "vip_bio",
		"name": "Nhà Sinh Vật Học Hoàng Long",
		"avatar": "🔬",
		"dialogue": "Nghiên cứu khẩu phần sinh thái tiêu chuẩn cho gấu trúc và chim cánh cụt.",
		"needs": [
			{"item": "corn", "count": 2},
			{"item": "sanctuary_feed", "count": 1}
		],
		"reward_gold": 380,
		"reward_coins": 320,
		"reward_xp": 150,
		"reward_pieces": 1
	},
	{
		"id": "vip_foodie",
		"name": "Blogger Ẩm Thực Thuỳ Linh",
		"avatar": "🧁",
		"dialogue": "Review ẩm thực sạch phong cách đồng quê kết hợp sở thú sinh thái!",
		"needs": [
			{"item": "strawberry", "count": 2},
			{"item": "milk", "count": 2}
		],
		"reward_gold": 340,
		"reward_coins": 290,
		"reward_xp": 130,
		"reward_pieces": 1
	},
	{
		"id": "vip_guide",
		"name": "Hướng Dẫn Viên Tuấn Kiệt",
		"avatar": "🚩",
		"dialogue": "Khách đoàn muốn thưởng thức bánh quy thơm bơ và cá tươi chiên giòn!",
		"needs": [
			{"item": "cookie", "count": 1},
			{"item": "fish_carp", "count": 1}
		],
		"reward_gold": 420,
		"reward_coins": 360,
		"reward_xp": 180,
		"reward_pieces": 1
	}
]

func _ready() -> void:
	_init_quests()
	_connect_event_bus()
	_sync_dynamic_quests()

func _init_quests() -> void:
	# 1. Initialize story quests if not present in SaveManager
	for q: Dictionary in story_quests:
		var q_id: String = q["id"]
		if not SaveManager.quests_data.has(q_id):
			SaveManager.quests_data[q_id] = {
				"progress": 0,
				"claimed": false
			}
			
	# 2. Initialize daily quests if empty or not 4
	if SaveManager.daily_quests_data.size() < daily_quest_pool.size():
		_generate_daily_quests()

	# 3. Initialize VIP requests if empty
	_ensure_vip_requests()

func _ensure_vip_requests() -> void:
	if SaveManager.vip_requests.size() < 2:
		SaveManager.vip_requests.clear()
		var pool_copy: Array = VIP_POOL.duplicate()
		pool_copy.shuffle()
		for i in range(2):
			SaveManager.vip_requests.append((pool_copy[i] as Dictionary).duplicate(true))
		SaveManager.save_game()

func _generate_daily_quests() -> void:
	SaveManager.daily_quests_data.clear()
	for q: Dictionary in daily_quest_pool:
		SaveManager.daily_quests_data[q["id"]] = {
			"progress": 0,
			"claimed": false
		}
	SaveManager.save_game()

func _connect_event_bus() -> void:
	EventBus.field_harvested.connect(func(_plot: int, _crop: String) -> void: notify_crop_harvested())
	EventBus.production_collected.connect(func(_m: int, _p: String) -> void: notify_production_collected())
	EventBus.animal_collected.connect(func(_pen: int, _p: String) -> void: notify_animal_collected())
	EventBus.animal_fed.connect(func(_pen: int, _a: String, _t: int) -> void: notify_animal_fed())
	EventBus.fish_caught.connect(func(_s: int, _f: String, _w: float) -> void: notify_fish_caught())
	EventBus.tourist_tipped.connect(func(_v: int, _g: int, _x: int, _pos: Vector2) -> void: notify_visitor_served())
	EventBus.visitor_action_completed.connect(func(_v: int, _a: String, _g: int, _x: int) -> void: notify_visitor_served())
	EventBus.zoo_animal_fed.connect(func(a_id: String) -> void: notify_zoo_fed(a_id))
	EventBus.zoo_enclosure_unlocked.connect(func(_a_id: String) -> void: notify_zoo_unlocked())
	EventBus.truck_order_completed.connect(func(_o_id: String, _g: int, _x: int) -> void: notify_delivery_or_shop())
	EventBus.roadside_shop_item_sold.connect(func(_idx: int, _item: String, _cnt: int, _price: int) -> void: notify_delivery_or_shop())
	EventBus.attraction_score_changed.connect(func(score: int) -> void: notify_attraction_score(score))

func _sync_dynamic_quests() -> void:
	# Check unlocked zoo enclosures count
	var unlocked_count: int = 0
	for a_id: String in ["zoo_capybara", "zoo_panda", "zoo_penguin", "zoo_giraffe"]:
		if SaveManager.is_animal_unlocked(a_id):
			unlocked_count += 1
	_set_progress_by_id("main_11", unlocked_count)

	# Check attraction score
	if Engine.has_singleton("GridManager") or get_tree().root.has_node("GridManager"):
		_set_progress_by_id("main_12", GridManager.total_attraction_score)

# Progression triggers
func notify_crop_harvested() -> void:
	_add_progress_by_type("harvest", 1)

func notify_production_collected() -> void:
	_add_progress_by_type("production", 1)
	_add_progress_by_type("pen_or_production", 1)

func notify_animal_collected() -> void:
	_add_progress_by_type("pen_or_production", 1)

func notify_animal_fed() -> void:
	_add_progress_by_type("pen_feed", 1)

func notify_fish_caught() -> void:
	_add_progress_by_type("fish", 1)

func notify_visitor_served() -> void:
	_add_progress_by_type("visitor", 1)

func notify_zoo_fed(_animal_id: String = "") -> void:
	_add_progress_by_type("zoo_feed", 1)

func notify_zoo_unlocked() -> void:
	_add_progress_by_type("zoo_unlock", 1)
	_sync_dynamic_quests()

func notify_delivery_or_shop() -> void:
	_add_progress_by_type("delivery_or_shop", 1)

func notify_attraction_score(score: int) -> void:
	_set_progress_by_id("main_12", score)

func _add_progress_by_type(q_type: String, amount: int) -> void:
	var changed: bool = false
	
	# 1. Update Story Quests
	for q: Dictionary in story_quests:
		if q["type"] == q_type:
			var q_id: String = q["id"]
			var data: Dictionary = SaveManager.quests_data.get(q_id, {}) as Dictionary
			if not bool(data.get("claimed", false)):
				var cur: int = int(data.get("progress", 0))
				var target: int = int(q["target"])
				if cur < target:
					data["progress"] = mini(cur + amount, target)
					SaveManager.quests_data[q_id] = data
					changed = true
					quest_progress_changed.emit(q_id)
					if data["progress"] >= target:
						EventBus.quest_completed.emit(q_id)
						AudioManager.play_sfx("level_up")
						
	# 2. Update Daily Quests
	for q: Dictionary in daily_quest_pool:
		var q_id: String = q["id"]
		if SaveManager.daily_quests_data.has(q_id) and q["type"] == q_type:
			var data: Dictionary = SaveManager.daily_quests_data[q_id] as Dictionary
			if not bool(data.get("claimed", false)):
				var cur: int = int(data.get("progress", 0))
				var target: int = int(q["target"])
				if cur < target:
					data["progress"] = mini(cur + amount, target)
					SaveManager.daily_quests_data[q_id] = data
					changed = true
					quest_progress_changed.emit(q_id)
					if data["progress"] >= target:
						EventBus.quest_completed.emit(q_id)
						AudioManager.play_sfx("level_up")
						
	if changed:
		SaveManager.save_game()

func _set_progress_by_id(q_id: String, val: int) -> void:
	if not SaveManager.quests_data.has(q_id):
		return
	var data: Dictionary = SaveManager.quests_data[q_id] as Dictionary
	if bool(data.get("claimed", false)):
		return
	var target: int = 0
	for q: Dictionary in story_quests:
		if q["id"] == q_id:
			target = int(q["target"])
			break
	if target <= 0:
		return
	var new_prog: int = mini(val, target)
	if int(data.get("progress", 0)) != new_prog:
		data["progress"] = new_prog
		SaveManager.quests_data[q_id] = data
		quest_progress_changed.emit(q_id)
		if new_prog >= target:
			EventBus.quest_completed.emit(q_id)
			AudioManager.play_sfx("level_up")
		SaveManager.save_game()

func claim_story_quest(quest_id: String) -> bool:
	for q: Dictionary in story_quests:
		if q["id"] == quest_id:
			var data: Dictionary = SaveManager.quests_data.get(quest_id, {}) as Dictionary
			if bool(data.get("claimed", false)):
				return false
			var prog: int = int(data.get("progress", 0))
			if prog >= int(q["target"]):
				data["claimed"] = true
				SaveManager.quests_data[quest_id] = data
				_apply_rewards(q)
				quest_claimed.emit(quest_id)
				SaveManager.save_game()
				return true
	return false

func claim_daily_quest(quest_id: String) -> bool:
	if not SaveManager.daily_quests_data.has(quest_id):
		return false
		
	var data: Dictionary = SaveManager.daily_quests_data[quest_id] as Dictionary
	if bool(data.get("claimed", false)):
		return false
		
	for q: Dictionary in daily_quest_pool:
		if q["id"] == quest_id:
			var prog: int = int(data.get("progress", 0))
			if prog >= int(q["target"]):
				data["claimed"] = true
				SaveManager.daily_quests_data[quest_id] = data
				_apply_rewards(q)
				
				# Cộng +25 Điểm Năng Động Hàng Ngày
				SaveManager.add_activity_points(25)
				quest_claimed.emit(quest_id)
				
				# Check if all daily quests claimed -> auto refresh
				var all_done: bool = true
				for k: String in SaveManager.daily_quests_data:
					var d: Dictionary = SaveManager.daily_quests_data[k] as Dictionary
					if not bool(d.get("claimed", false)):
						all_done = false
						break
				if all_done:
					_generate_daily_quests()
					
				SaveManager.save_game()
				return true
	return false

func fulfill_vip_request(index: int) -> bool:
	_ensure_vip_requests()
	if index < 0 or index >= SaveManager.vip_requests.size():
		return false
		
	var req: Dictionary = SaveManager.vip_requests[index] as Dictionary
	var needs: Array = req.get("needs", []) as Array
	
	# 1. Check item inventory
	for item_req: Variant in needs:
		var d_item: Dictionary = item_req as Dictionary
		var i_name: String = String(d_item.get("item", ""))
		var i_count: int = int(d_item.get("count", 1))
		if StorageManager.get_item_count(i_name) < i_count:
			return false
			
	# 2. Deduct items
	for item_req: Variant in needs:
		var d_item: Dictionary = item_req as Dictionary
		var i_name: String = String(d_item.get("item", ""))
		var i_count: int = int(d_item.get("count", 1))
		StorageManager.remove_item(i_name, i_count)
		
	# 3. Apply rewards
	var g: int = int(req.get("reward_gold", 0))
	var coins: int = int(req.get("reward_coins", 0))
	var xp: int = int(req.get("reward_xp", 0))
	var pieces: int = int(req.get("reward_pieces", 0))
	
	if g > 0: StorageManager.add_gold(g)
	if coins > 0:
		StorageManager.coins += coins
		EventBus.coins_changed.emit(StorageManager.coins, coins)
	if xp > 0: StorageManager.add_xp(xp)
	if pieces > 0: SaveManager.add_puzzle_pieces(pieces)
	
	AudioManager.play_sfx("sell")
	notify_delivery_or_shop()
	
	# 4. Replace with new random VIP request
	var cur_id: String = String(req.get("id", ""))
	var other_id: String = ""
	var other_idx: int = 1 if index == 0 else 0
	if other_idx < SaveManager.vip_requests.size():
		other_id = String((SaveManager.vip_requests[other_idx] as Dictionary).get("id", ""))
		
	var candidates: Array[Dictionary] = []
	for v: Dictionary in VIP_POOL:
		if v["id"] != cur_id and v["id"] != other_id:
			candidates.append(v)
	if candidates.is_empty():
		candidates = VIP_POOL.duplicate()
	candidates.shuffle()
	
	SaveManager.vip_requests[index] = (candidates[0] as Dictionary).duplicate(true)
	SaveManager.save_game()
	vip_requests_updated.emit()
	return true

func _apply_rewards(q: Dictionary) -> void:
	var g: int = int(q.get("reward_gold", 0))
	var xp: int = int(q.get("reward_xp", 0))
	var coins: int = int(q.get("reward_coins", 0))
	var dia: int = int(q.get("reward_diamonds", 0))
	var pieces: int = int(q.get("reward_pieces", 0))
	
	if g > 0: StorageManager.add_gold(g)
	if xp > 0: StorageManager.add_xp(xp)
	if coins > 0:
		StorageManager.coins += coins
		EventBus.coins_changed.emit(StorageManager.coins, coins)
	if dia > 0:
		StorageManager.diamonds += dia
		EventBus.diamonds_changed.emit(StorageManager.diamonds, dia)
	if pieces > 0:
		SaveManager.add_puzzle_pieces(pieces)
		
	AudioManager.play_sfx("level_up")

func get_unclaimed_count() -> int:
	var count: int = 0
	for q: Dictionary in story_quests:
		var q_id: String = q["id"]
		var data: Dictionary = SaveManager.quests_data.get(q_id, {}) as Dictionary
		if not bool(data.get("claimed", false)) and int(data.get("progress", 0)) >= int(q["target"]):
			count += 1
	for q_id: String in SaveManager.daily_quests_data:
		var data: Dictionary = SaveManager.daily_quests_data[q_id] as Dictionary
		if not bool(data.get("claimed", false)):
			for q: Dictionary in daily_quest_pool:
				if q["id"] == q_id and int(data.get("progress", 0)) >= int(q["target"]):
					count += 1
					break
	# Check chests
	if SaveManager.daily_activity_points >= 50 and not SaveManager.daily_chest_50_claimed:
		count += 1
	if SaveManager.daily_activity_points >= 100 and not SaveManager.daily_chest_100_claimed:
		count += 1
	return count
