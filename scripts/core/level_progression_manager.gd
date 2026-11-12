# scripts/core/level_progression_manager.gd
# Manages the full progression roadmap from Level 1 to Level 33 using data/*.json as single source of truth.
extends Node
class_name LevelProgressionManager

const LEVEL_METADATA: Dictionary = {
	1: {
		"title": "Tập Sự Làm Nông",
		"gold_reward": 100,
		"diamonds_reward": 2,
		"coins_reward": 50,
		"desc": "Bắt đầu khởi nghiệp nông trại! Học cách gieo lúa mì và cho gà ăn."
	},
	2: {
		"title": "Mở Rộng Mùa Vụ",
		"gold_reward": 120,
		"diamonds_reward": 2,
		"coins_reward": 20,
		"desc": "Ngô ngọt giúp làm thức ăn cho gia súc và chế biến bỏng ngô."
	},
	3: {
		"title": "Hương Vị Bánh Mì",
		"gold_reward": 150,
		"diamonds_reward": 2,
		"coins_reward": 30,
		"desc": "Lò bánh mì tỏa hương thơm nức, phục vụ khách tham quan."
	},
	4: {
		"title": "Nông Nghiệp Xanh",
		"gold_reward": 180,
		"diamonds_reward": 2,
		"coins_reward": 25,
		"desc": "Đậu nành giàu dinh dưỡng, nguyên liệu chế biến thức ăn bò."
	},
	5: {
		"title": "Đồng Cỏ Sữa Tươi",
		"gold_reward": 250,
		"diamonds_reward": 3,
		"coins_reward": 50,
		"desc": "Thu hoạch sữa bò tươi ngon và bán nông sản lấy Vàng tại Sạp Hàng!"
	},
	6: {
		"title": "Giao Thương Đường Dài",
		"gold_reward": 300,
		"diamonds_reward": 3,
		"coins_reward": 60,
		"desc": "Xe tải bắt đầu nhận đơn hàng xuất khẩu, kiếm nhiều Vàng & XP."
	},
	7: {
		"title": "Vườn Hoa Hướng Dương",
		"gold_reward": 320,
		"diamonds_reward": 2,
		"coins_reward": 40,
		"desc": "Sắc vàng rực rỡ thu hút thêm nhiều du khách tới chụp ảnh."
	},
	8: {
		"title": "Bếp Bánh Ngọt Ngào",
		"gold_reward": 350,
		"diamonds_reward": 3,
		"coins_reward": 50,
		"desc": "Làm bánh gato và bánh dâu ngọt ngào cho khách du lịch."
	},
	9: {
		"title": "Trang Trại Đa Dạng",
		"gold_reward": 400,
		"diamonds_reward": 3,
		"coins_reward": 60,
		"desc": "Nuôi heo lấy thịt xông khói béo ngậy cho các món ăn cao cấp."
	},
	10: {
		"title": "Đầm Câu Cá Sinh Thái",
		"gold_reward": 500,
		"diamonds_reward": 5,
		"coins_reward": 100,
		"desc": "Trổ tài câu cá chép, cá hồi tươi sống với minigame thú vị."
	},
	11: {
		"title": "Khai Trương Sở Thú Bờ Đông",
		"gold_reward": 600,
		"diamonds_reward": 5,
		"coins_reward": 150,
		"desc": "Sửa cầu gỗ sang bờ Đông và khai trương Chuồng Capybara thân thiện!"
	},
	12: {
		"title": "Vườn Cây Táo Đỏ",
		"gold_reward": 650,
		"diamonds_reward": 3,
		"coins_reward": 80,
		"desc": "Trồng vườn táo đỏ ngọt lịm để làm bánh táo và cho thú ăn."
	},
	13: {
		"title": "Quầy Nước Mát Lạnh",
		"gold_reward": 700,
		"diamonds_reward": 4,
		"coins_reward": 100,
		"desc": "Nước ép táo và dâu tây mát lạnh giải nhiệt cho du khách."
	},
	14: {
		"title": "Hương Sắc Oải Hương",
		"gold_reward": 750,
		"diamonds_reward": 3,
		"coins_reward": 100,
		"desc": "Cánh đồng hoa tím ngát hương làm say lòng mọi du khách."
	},
	15: {
		"title": "Bảo Tồn Gấu Trúc Quý",
		"gold_reward": 850,
		"diamonds_reward": 6,
		"coins_reward": 200,
		"desc": "Đón những chú gấu trúc Chibi thích ăn táo và mía đường!"
	},
	16: {
		"title": "Lễ Hội Bí Ngô Vàng",
		"gold_reward": 900,
		"diamonds_reward": 4,
		"coins_reward": 120,
		"desc": "Mùa thu hoạch bí ngô vàng chuẩn bị cho lễ hội nông trại."
	},
	17: {
		"title": "Mở Rộng Kho Chứa",
		"gold_reward": 950,
		"diamonds_reward": 4,
		"coins_reward": 150,
		"desc": "Nâng cấp kho để chứa được nhiều nông sản và sản phẩm hơn."
	},
	18: {
		"title": "Quầy Lưu Niệm Sở Thú",
		"gold_reward": 1000,
		"diamonds_reward": 5,
		"coins_reward": 250,
		"desc": "Bán đồ lưu niệm Chibi cho khách du lịch tăng doanh thu Xu."
	},
	19: {
		"title": "Xứ Sở Băng Tuyết",
		"gold_reward": 1100,
		"diamonds_reward": 6,
		"coins_reward": 300,
		"desc": "Những chú chim cánh cụt lạch bạch bơi lội ăn cá tươi ngon."
	},
	20: {
		"title": "Vườn Hồng Tình Yêu",
		"gold_reward": 1200,
		"diamonds_reward": 5,
		"coins_reward": 200,
		"desc": "Hoa hồng kiêu sa nâng tầm điểm hấp dẫn nông trại du lịch."
	},
	21: {
		"title": "Mở Rộng Thổ Nhưỡng",
		"gold_reward": 1300,
		"diamonds_reward": 4,
		"coins_reward": 180,
		"desc": "Quy mô canh tác tăng cao đáp ứng các đơn đặt hàng lớn."
	},
	22: {
		"title": "Cây Trái Nhiệt Đới",
		"gold_reward": 1400,
		"diamonds_reward": 5,
		"coins_reward": 220,
		"desc": "Xoài chín vàng thơm ngọt cho các món tráng miệng thượng hạng."
	},
	23: {
		"title": "Điểm Hấp Dẫn Bùng Nổ",
		"gold_reward": 1500,
		"diamonds_reward": 5,
		"coins_reward": 300,
		"desc": "Đài phun nước mát lành tăng mạnh số lượng khách VIP ghé thăm."
	},
	24: {
		"title": "Thảo Nguyên Phi Châu",
		"gold_reward": 1650,
		"diamonds_reward": 8,
		"coins_reward": 400,
		"desc": "Khu bảo tồn hươu cao cổ kiêu hãnh ăn lúa mì vàng óng."
	},
	25: {
		"title": "Nông Trại Tiêu Biểu",
		"gold_reward": 1800,
		"diamonds_reward": 6,
		"coins_reward": 350,
		"desc": "Trang trại đạt chuẩn 4 sao thu hút các đoàn du lịch quốc tế."
	},
	26: {
		"title": "Canh Tác Đỉnh Cao",
		"gold_reward": 2000,
		"diamonds_reward": 6,
		"coins_reward": 300,
		"desc": "Mảnh đất màu mỡ năng suất gấp bội phần."
	},
	27: {
		"title": "Đại Kho Lương Thực",
		"gold_reward": 2200,
		"diamonds_reward": 8,
		"coins_reward": 400,
		"desc": "Kho hàng đồ sộ không lo đầy chỗ chứa."
	},
	28: {
		"title": "Bay Cùng Khinh Khí Cầu",
		"gold_reward": 2500,
		"diamonds_reward": 10,
		"coins_reward": 600,
		"desc": "Khinh khí cầu 7 sắc cầu vồng ngắm toàn cảnh và đón khách VIP!"
	},
	29: {
		"title": "Chuyên Gia Chăm Thú",
		"gold_reward": 2700,
		"diamonds_reward": 8,
		"coins_reward": 500,
		"desc": "Động vật được cho ăn no nê nhân đôi lượng Xu Tip du khách thưởng."
	},
	30: {
		"title": "Vùng Đất Thiên Đường",
		"gold_reward": 3000,
		"diamonds_reward": 12,
		"coins_reward": 800,
		"desc": "Điểm đến du lịch hàng đầu cả nước với cảnh sắc tuyệt mỹ."
	},
	31: {
		"title": "Đại Thương Hội Nông Sản",
		"gold_reward": 3300,
		"diamonds_reward": 10,
		"coins_reward": 700,
		"desc": "Giao thương tấp nập, khách chen chân mua hàng."
	},
	32: {
		"title": "Bậc Thầy Nông Nghiệp",
		"gold_reward": 3600,
		"diamonds_reward": 12,
		"coins_reward": 900,
		"desc": "Trang trại phủ kín sắc màu của tất cả các loài cây trồng trù phú."
	},
	33: {
		"title": "Đại Điền Chủ Hoàng Gia",
		"gold_reward": 5000,
		"diamonds_reward": 25,
		"coins_reward": 2000,
		"desc": "Chúc mừng bạn đã đạt đỉnh cao Cấp 33! Nông trại du lịch vĩ đại nhất!"
	}
}

static func _read_json_static(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	var f: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		return parsed as Dictionary
	return {}

static func _get_dm_sources() -> Dictionary:
	var ml: MainLoop = Engine.get_main_loop()
	if ml is SceneTree:
		var dm: Node = (ml as SceneTree).root.get_node_or_null("DataManager")
		if dm != null:
			var c_dict: Variant = dm.get("crops")
			var b_dict: Variant = dm.get("buildings")
			var a_dict: Variant = dm.get("animals")
			var f_dict: Variant = dm.get("fishes")
			var r_dict: Variant = dm.get("level_rewards")
			if c_dict is Dictionary and not (c_dict as Dictionary).is_empty() and b_dict is Dictionary and not (b_dict as Dictionary).is_empty():
				return {
					"crops": c_dict as Dictionary,
					"buildings": b_dict as Dictionary,
					"animals": a_dict as Dictionary if a_dict is Dictionary else {},
					"fishes": f_dict as Dictionary if f_dict is Dictionary else {},
					"level_rewards": r_dict as Dictionary if r_dict is Dictionary else {}
				}
	return {
		"crops": _read_json_static("res://data/crops.json"),
		"buildings": _read_json_static("res://data/buildings.json"),
		"animals": _read_json_static("res://data/animals.json"),
		"fishes": _read_json_static("res://data/fishes.json"),
		"level_rewards": _read_json_static("res://data/level_rewards.json")
	}

static func get_unlock_info(lvl: int) -> Dictionary:
	var meta: Dictionary = {}
	if LEVEL_METADATA.has(lvl):
		meta = LEVEL_METADATA[lvl] as Dictionary
	else:
		meta = {
			"title": "Cấp Độ %d" % lvl,
			"desc": "Tiếp tục phát triển nông trại du lịch!",
			"gold_reward": 100 + lvl * 25,
			"diamonds_reward": 1,
			"coins_reward": 10 + lvl * 5
		}
	var sources: Dictionary = _get_dm_sources()
	var crops_data: Dictionary = sources.get("crops", {}) as Dictionary
	var buildings_data: Dictionary = sources.get("buildings", {}) as Dictionary
	var animals_data: Dictionary = sources.get("animals", {}) as Dictionary
	var fishes_data: Dictionary = sources.get("fishes", {}) as Dictionary
	var rewards_data: Dictionary = sources.get("level_rewards", {}) as Dictionary
	
	var unlock_crops: Array[String] = []
	for c_key: Variant in crops_data:
		var c_id: String = String(c_key)
		if c_id.ends_with("_seed"):
			continue
		var c_dict: Dictionary = crops_data[c_key] as Dictionary
		if int(c_dict.get("unlock_level", 1)) == lvl:
			unlock_crops.append(String(c_dict.get("name", c_id)))
	
	var unlock_animals: Array[String] = []
	for a_key: Variant in animals_data:
		var a_id: String = String(a_key)
		var a_dict: Dictionary = animals_data[a_key] as Dictionary
		if int(a_dict.get("unlock_level", 1)) == lvl:
			var a_name: String = String(a_dict.get("name", a_id))
			if bool(a_dict.get("locked", false)):
				a_name += " (Mở khóa sau)"
			unlock_animals.append(a_name)
	
	var unlock_fishes: Array[String] = []
	for f_key: Variant in fishes_data:
		var f_id: String = String(f_key)
		var f_dict: Dictionary = fishes_data[f_key] as Dictionary
		if int(f_dict.get("unlock_level", 1)) == lvl:
			unlock_fishes.append(String(f_dict.get("name", f_id)))
	
	var unlock_buildings: Array[String] = []
	for b_key: Variant in buildings_data:
		var b_id: String = String(b_key)
		var b_dict: Dictionary = buildings_data[b_key] as Dictionary
		if int(b_dict.get("unlock_level", 1)) == lvl:
			var b_name: String = String(b_dict.get("name", b_id))
			if String(b_dict.get("category", "")) == "zoo_enclosure":
				var p_cost: Variant = b_dict.get("puzzle_piece_cost", null)
				if p_cost != null:
					unlock_buildings.append("Khu Sở Thú: %s (%d Mảnh Ghép)" % [b_name, int(p_cost)])
				else:
					unlock_buildings.append("Khu Sở Thú: %s" % b_name)
			else:
				unlock_buildings.append(b_name)
	
	var cap_expansions: Variant = rewards_data.get("silo_barn_capacity", [])
	if cap_expansions is Array:
		for entry: Variant in (cap_expansions as Array):
			if entry is Dictionary and int((entry as Dictionary).get("level", 0)) == lvl:
				unlock_buildings.append("+%d Sức Chứa Kho Silo & Barn" % int((entry as Dictionary).get("add", 0)))
	
	var double_barn: Variant = rewards_data.get("barn_capacity_double", [])
	if double_barn is Array:
		for entry: Variant in (double_barn as Array):
			if entry is Dictionary and int((entry as Dictionary).get("level", 0)) == lvl:
				unlock_buildings.append("Nhân Đôi Sức Chứa Kho Barn (x2)")
	
	var stall_slots: Variant = rewards_data.get("stall_display_slots", [])
	if stall_slots is Array:
		for entry: Variant in (stall_slots as Array):
			if entry is Dictionary and int((entry as Dictionary).get("level", 0)) == lvl:
				unlock_buildings.append("+%d Ô Trưng Bày Sạp Hàng" % int((entry as Dictionary).get("add", 0)))
	
	var title_rewards: Variant = rewards_data.get("titles", [])
	if title_rewards is Array:
		for entry: Variant in (title_rewards as Array):
			if entry is Dictionary and int((entry as Dictionary).get("level", 0)) == lvl:
				unlock_buildings.append("Danh Hiệu: %s" % String((entry as Dictionary).get("name", "")))
	
	return {
		"title": String(meta.get("title", "Cấp Độ %d" % lvl)),
		"desc": String(meta.get("desc", "")),
		"crops": unlock_crops,
		"animals": unlock_animals,
		"fishes": unlock_fishes,
		"buildings": unlock_buildings,
		"gold_reward": int(meta.get("gold_reward", 100 + lvl * 25)),
		"diamonds_reward": int(meta.get("diamonds_reward", 1)),
		"coins_reward": int(meta.get("coins_reward", 10 + lvl * 5))
	}
