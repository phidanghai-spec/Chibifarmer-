# scripts/core/level_progression_manager.gd
# Manages the full progression roadmap from Level 1 to Level 33 for Web & Desktop.
extends Node
class_name LevelProgressionManager

const UNLOCK_ROADMAP: Dictionary = {
	1: {
		"title": "Tập Sự Làm Nông",
		"crops": ["Lúa Mì (Wheat)"],
		"buildings": ["6 Ô Ruộng Đầu Tiên", "Chuồng Gà Đẻ Trứng", "Máy Nghiền Cám"],
		"gold_reward": 100,
		"diamonds_reward": 2,
		"coins_reward": 50,
		"desc": "Bắt đầu khởi nghiệp nông trại! Học cách gieo lúa mì và cho gà ăn."
	},
	2: {
		"title": "Mở Rộng Mùa Vụ",
		"crops": ["Ngô Vàng (Corn)"],
		"buildings": ["+2 Ô Ruộng Mới"],
		"gold_reward": 120,
		"diamonds_reward": 2,
		"coins_reward": 20,
		"desc": "Ngô ngọt giúp làm thức ăn cho gia súc và chế biến bỏng ngô."
	},
	3: {
		"title": "Hương Vị Bánh Mì",
		"crops": ["Cà Rốt (Carrot)"],
		"buildings": ["Lò Nướng Bánh Mì"],
		"gold_reward": 150,
		"diamonds_reward": 2,
		"coins_reward": 30,
		"desc": "Lò bánh mì tỏa hương thơm nức, phục vụ khách tham quan."
	},
	4: {
		"title": "Nông Nghiệp Xanh",
		"crops": ["Đậu Nành (Soybean)"],
		"buildings": ["+2 Ô Ruộng Mới"],
		"gold_reward": 180,
		"diamonds_reward": 2,
		"coins_reward": 25,
		"desc": "Đậu nành giàu dinh dưỡng, nguyên liệu chế biến thức ăn bò."
	},
	5: {
		"title": "Đồng Cỏ Sữa Tươi",
		"crops": [],
		"buildings": ["Chuồng Bò Sữa 🐄", "Sạp Hàng Ven Đường 🏪"],
		"gold_reward": 250,
		"diamonds_reward": 3,
		"coins_reward": 50,
		"desc": "Thu hoạch sữa bò tươi ngon và bán nông sản lấy Vàng tại Sạp Hàng!"
	},
	6: {
		"title": "Giao Thương Đường Dài",
		"crops": ["Mía Đường (Sugarcane)"],
		"buildings": ["Bến Đơn Xe Tải 🚚"],
		"gold_reward": 300,
		"diamonds_reward": 3,
		"coins_reward": 60,
		"desc": "Xe tải bắt đầu nhận đơn hàng xuất khẩu, kiếm nhiều Vàng & XP."
	},
	7: {
		"title": "Vườn Hoa Hướng Dương",
		"crops": ["Hoa Hướng Dương (Sunflower)"],
		"buildings": ["Hàng Rào Gỗ Trắng Decor"],
		"gold_reward": 320,
		"diamonds_reward": 2,
		"coins_reward": 40,
		"desc": "Sắc vàng rực rỡ thu hút thêm nhiều du khách tới chụp ảnh."
	},
	8: {
		"title": "Bếp Bánh Ngọt Ngào",
		"crops": ["Cà Chua (Tomato)"],
		"buildings": ["Lò Bánh Ngọt 🍰"],
		"gold_reward": 350,
		"diamonds_reward": 3,
		"coins_reward": 50,
		"desc": "Làm bánh gato và bánh dâu ngọt ngào cho khách du lịch."
	},
	9: {
		"title": "Trang Trại Đa Dạng",
		"crops": [],
		"buildings": ["Chuồng Heo Lấy Thịt 🐖", "+2 Ô Ruộng Mới"],
		"gold_reward": 400,
		"diamonds_reward": 3,
		"coins_reward": 60,
		"desc": "Nuôi heo lấy thịt xông khói béo ngậy cho các món ăn cao cấp."
	},
	10: {
		"title": "Đầm Câu Cá Sinh Thái",
		"crops": ["Dâu Tây (Strawberry)"],
		"buildings": ["Đầm Câu Cá Tự Nhiên 🎣"],
		"gold_reward": 500,
		"diamonds_reward": 5,
		"coins_reward": 100,
		"desc": "Trổ tài câu cá chép, cá hồi tươi sống với minigame thú vị."
	},
	11: {
		"title": "Khai Trương Sở Thú Bờ Đông",
		"crops": ["Cá Chép (Carp)"],
		"buildings": ["Cầu Gỗ Qua Sông 🌉", "Hồ Capybara 🍊 (Sở Thú)"],
		"gold_reward": 600,
		"diamonds_reward": 5,
		"coins_reward": 150,
		"desc": "Sửa cầu gỗ sang bờ Đông và khai trương Chuồng Capybara thân thiện!"
	},
	12: {
		"title": "Vườn Cây Táo Đỏ",
		"crops": ["Cây Táo Đỏ (Apple Tree)"],
		"buildings": ["+4 Ô Ruộng Mới"],
		"gold_reward": 650,
		"diamonds_reward": 3,
		"coins_reward": 80,
		"desc": "Trồng vườn táo đỏ ngọt lịm để làm bánh táo và cho thú ăn."
	},
	13: {
		"title": "Quầy Nước Mát Lạnh",
		"crops": [],
		"buildings": ["Quầy Pha Chế Nước Ép 🍹"],
		"gold_reward": 700,
		"diamonds_reward": 4,
		"coins_reward": 100,
		"desc": "Nước ép táo và dâu tây mát lạnh giải nhiệt cho du khách."
	},
	14: {
		"title": "Hương Sắc Oải Hương",
		"crops": ["Hoa Oải Hương (Lavender)"],
		"buildings": ["Ghế Nghỉ Gỗ Công Viên"],
		"gold_reward": 750,
		"diamonds_reward": 3,
		"coins_reward": 100,
		"desc": "Cánh đồng hoa tím ngát hương làm say lòng mọi du khách."
	},
	15: {
		"title": "Bảo Tồn Gấu Trúc Quý",
		"crops": [],
		"buildings": ["Rừng Trúc Gấu Trúc 🐼 (Sở Thú)"],
		"gold_reward": 850,
		"diamonds_reward": 6,
		"coins_reward": 200,
		"desc": "Đón những chú gấu trúc Chibi thích ăn táo và mía đường!"
	},
	16: {
		"title": "Lễ Hội Bí Ngô Vàng",
		"crops": ["Bí Đỏ Khổng Lồ (Pumpkin)"],
		"buildings": ["Bù Nhìn Rơm & Ụ Rơm Vàng Decor"],
		"gold_reward": 900,
		"diamonds_reward": 4,
		"coins_reward": 120,
		"desc": "Mùa thu hoạch bí ngô vàng chuẩn bị cho lễ hội nông trại."
	},
	17: {
		"title": "Mở Rộng Kho Chứa",
		"crops": [],
		"buildings": ["Nâng Cấp Kho Silo & Barn (+50 Sức chứa)"],
		"gold_reward": 950,
		"diamonds_reward": 4,
		"coins_reward": 150,
		"desc": "Nâng cấp kho để chứa được nhiều nông sản và sản phẩm hơn."
	},
	18: {
		"title": "Quầy Lưu Niệm Sở Thú",
		"crops": ["Cá Hồi Vàng (Salmon)"],
		"buildings": ["Quầy Quà Lưu Niệm Sở Thú 🎁"],
		"gold_reward": 1000,
		"diamonds_reward": 5,
		"coins_reward": 250,
		"desc": "Bán đồ lưu niệm Chibi cho khách du lịch tăng doanh thu Xu."
	},
	19: {
		"title": "Xứ Sở Băng Tuyết",
		"crops": [],
		"buildings": ["Bờ Đá Chim Cánh Cụt 🐧 (Sở Thú)"],
		"gold_reward": 1100,
		"diamonds_reward": 6,
		"coins_reward": 300,
		"desc": "Những chú chim cánh cụt lạch bạch bơi lội ăn cá tươi ngon."
	},
	20: {
		"title": "Vườn Hồng Tình Yêu",
		"crops": ["Hoa Hồng Đỏ (Red Rose)"],
		"buildings": ["Cổng Hoa Vòm Lãng Mạn"],
		"gold_reward": 1200,
		"diamonds_reward": 5,
		"coins_reward": 200,
		"desc": "Hoa hồng kiêu sa nâng tầm điểm hấp dẫn nông trại du lịch."
	},
	21: {
		"title": "Mở Rộng Thổ Nhưỡng",
		"crops": [],
		"buildings": ["+4 Ô Ruộng Mới (Tổng 18 Ô)"],
		"gold_reward": 1300,
		"diamonds_reward": 4,
		"coins_reward": 180,
		"desc": "Quy mô canh tác tăng cao đáp ứng các đơn đặt hàng lớn."
	},
	22: {
		"title": "Cây Trái Nhiệt Đới",
		"crops": ["Cây Xoài Cát (Mango Tree)"],
		"buildings": ["Đèn Lồng Công Viên Chiếu Sáng"],
		"gold_reward": 1400,
		"diamonds_reward": 5,
		"coins_reward": 220,
		"desc": "Xoài chín vàng thơm ngọt cho các món tráng miệng thượng hạng."
	},
	23: {
		"title": "Điểm Hấp Dẫn Bùng Nổ",
		"crops": [],
		"buildings": ["Đài Phun Nước Bờ Đông ⛲"],
		"gold_reward": 1500,
		"diamonds_reward": 5,
		"coins_reward": 300,
		"desc": "Đài phun nước mát lành tăng mạnh số lượng khách VIP ghé thăm."
	},
	24: {
		"title": "Thảo Nguyên Phi Châu",
		"crops": [],
		"buildings": ["Thảo Nguyên Hươu Cao Cổ 🦒 (Sở Thú)"],
		"gold_reward": 1650,
		"diamonds_reward": 8,
		"coins_reward": 400,
		"desc": "Khu bảo tồn hươu cao cổ kiêu hãnh ăn lúa mì vàng óng."
	},
	25: {
		"title": "Nông Trại Tiêu Biểu",
		"crops": [],
		"buildings": ["Bảng Vinh Danh Nông Trại 🏆"],
		"gold_reward": 1800,
		"diamonds_reward": 6,
		"coins_reward": 350,
		"desc": "Trang trại đạt chuẩn 4 sao thu hút các đoàn du lịch quốc tế."
	},
	26: {
		"title": "Canh Tác Đỉnh Cao",
		"crops": [],
		"buildings": ["+4 Ô Ruộng Mới (Tổng 22 Ô)"],
		"gold_reward": 2000,
		"diamonds_reward": 6,
		"coins_reward": 300,
		"desc": "Mảnh đất màu mỡ năng suất gấp bội phần."
	},
	27: {
		"title": "Đại Kho Lương Thực",
		"crops": [],
		"buildings": ["Nâng Cấp Kho Silo & Barn (+100 Sức chứa)"],
		"gold_reward": 2200,
		"diamonds_reward": 8,
		"coins_reward": 400,
		"desc": "Kho hàng đồ sộ không lo đầy chỗ chứa."
	},
	28: {
		"title": "Bay Cùng Khinh Khí Cầu",
		"crops": [],
		"buildings": ["Khinh Khí Cầu Rực Rỡ 🎈 (Sở Thú)"],
		"gold_reward": 2500,
		"diamonds_reward": 10,
		"coins_reward": 600,
		"desc": "Khinh khí cầu 7 sắc cầu vồng ngắm toàn cảnh và đón khách VIP!"
	},
	29: {
		"title": "Chuyên Gia Chăm Thú",
		"crops": [],
		"buildings": ["Hệ Thống Thức Ăn Nhanh Sở Thú"],
		"gold_reward": 2700,
		"diamonds_reward": 8,
		"coins_reward": 500,
		"desc": "Động vật được cho ăn no nê nhân đôi lượng Xu Tip du khách thưởng."
	},
	30: {
		"title": "Vùng Đất Thiên Đường",
		"crops": [],
		"buildings": ["Tượng Vàng Nông Dân Chibi 🗿"],
		"gold_reward": 3000,
		"diamonds_reward": 12,
		"coins_reward": 800,
		"desc": "Điểm đến du lịch hàng đầu cả nước với cảnh sắc tuyệt mỹ."
	},
	31: {
		"title": "Đại Thương Hội Nông Sản",
		"crops": [],
		"buildings": ["Sạp Hàng Mở Rộng 6 Ô Trưng Bày"],
		"gold_reward": 3300,
		"diamonds_reward": 10,
		"coins_reward": 700,
		"desc": "Giao thương tấp nập, khách chen chân mua hàng."
	},
	32: {
		"title": "Bậc Thầy Nông Nghiệp",
		"crops": [],
		"buildings": ["+2 Ô Ruộng Tối Đa (Tổng 24 Ô Đất)"],
		"gold_reward": 3600,
		"diamonds_reward": 12,
		"coins_reward": 900,
		"desc": "Trang trại phủ kín sắc màu của tất cả các loài cây trồng trù phú."
	},
	33: {
		"title": "Đại Điền Chủ Hoàng Gia",
		"crops": [],
		"buildings": ["Danh Hiệu Đại Điền Chủ 👑", "Huy Hiệu Vàng Vĩnh Viễn", "Kho Hàng Sức Chứa Gấp Đôi"],
		"gold_reward": 5000,
		"diamonds_reward": 25,
		"coins_reward": 2000,
		"desc": "Chúc mừng bạn đã đạt đỉnh cao Cấp 33! Nông trại du lịch vĩ đại nhất!"
	}
}

static func get_unlock_info(lvl: int) -> Dictionary:
	if UNLOCK_ROADMAP.has(lvl):
		return UNLOCK_ROADMAP[lvl] as Dictionary
	return {
		"title": "Cấp Độ Mới",
		"crops": [],
		"buildings": ["Thưởng Thăng Cấp"],
		"gold_reward": 150 + lvl * 25,
		"diamonds_reward": 2,
		"coins_reward": 50,
		"desc": "Tiếp tục phát triển nông trại để mở khóa thêm nhiều điều bất ngờ!"
	}

static func is_crop_unlocked(crop_id: String, cur_level: int) -> bool:
	match crop_id:
		"wheat": return cur_level >= 1
		"corn": return cur_level >= 2
		"carrot": return cur_level >= 3
		"soybean": return cur_level >= 4
		"sugarcane": return cur_level >= 6
		"sunflower": return cur_level >= 7
		"tomato": return cur_level >= 8
		"strawberry": return cur_level >= 10
		"apple_tree": return cur_level >= 12
		"lavender": return cur_level >= 14
		"pumpkin": return cur_level >= 16
		"rose": return cur_level >= 20
		"mango_tree": return cur_level >= 22
		_: return true

static func is_building_unlocked(b_id: String, cur_level: int) -> bool:
	match b_id:
		"bakery": return cur_level >= 3
		"cow_pen": return cur_level >= 5
		"roadside_shop": return cur_level >= 5
		"truck": return cur_level >= 6
		"cake_oven": return cur_level >= 8
		"pig_pen": return cur_level >= 9
		"fishing": return cur_level >= 10
		"zoo_bridge": return cur_level >= 11
		"zoo_capybara": return cur_level >= 11
		"juice_press": return cur_level >= 13
		"zoo_panda": return cur_level >= 15
		"zoo_shop": return cur_level >= 18
		"zoo_penguin": return cur_level >= 19
		"zoo_giraffe": return cur_level >= 24
		"hot_air_balloon": return cur_level >= 28
		_: return true
