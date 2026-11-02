class_name OfflineSimulator
extends RefCounted

## OfflineSimulator
## Mô-đun tính toán tiến độ nông trại và lợi nhuận vắng nhà khi người chơi quay lại (Sprint 3)
## 100% Static Typing GDScript 2.0.

const MIN_OFFLINE_SECONDS: int = 60
const MAX_OFFLINE_CAP_SECONDS: int = 86400 # Tối đa 24 giờ
const BASE_ZOO_TICKET_PER_MINUTE: int = 4

static func evaluate_offline_progress(save_data: Dictionary) -> Dictionary:
	var now_ts: int = int(Time.get_unix_time_from_system())
	var last_ts: int = int(save_data.get("last_timestamp", now_ts))
	var elapsed: int = clampi(now_ts - last_ts, 0, MAX_OFFLINE_CAP_SECONDS)
	
	if elapsed < MIN_OFFLINE_SECONDS:
		return {}
		
	var elapsed_minutes: int = elapsed / 60
	var attraction_score: int = int(save_data.get("attraction_score", 10))
	
	# Đếm số chuồng thú đã mở khóa từ save_data
	var unlocked_zoo_animals: int = int(save_data.get("zoo_animals_count", 1))
	if save_data.has("zoo_enclosures"):
		var enclosures: Dictionary = save_data.get("zoo_enclosures", {}) as Dictionary
		if not enclosures.is_empty():
			unlocked_zoo_animals = maxi(1, enclosures.size())
	
	# Tính doanh thu thụ động từ du khách mua vé Vườn Thú Bờ Tây
	var passive_zoo_gold: int = elapsed_minutes * BASE_ZOO_TICKET_PER_MINUTE * unlocked_zoo_animals
	passive_zoo_gold += int(float(elapsed_minutes) * float(attraction_score) * 0.25)
	
	# Ước tính số mẻ nông sản chín trong thời gian vắng mặt (tối đa 12 ô)
	var ripened_crops_count: int = mini(12, elapsed_minutes / 2)
	# Mật ong đàn ong thu hoạch (tối đa 5 hũ)
	var honey_collected: int = mini(5, elapsed_minutes / 15)
	
	var report: Dictionary = {
		"elapsed_seconds": elapsed,
		"elapsed_minutes": elapsed_minutes,
		"passive_zoo_gold": passive_zoo_gold,
		"ripened_crops_count": ripened_crops_count,
		"honey_collected": honey_collected
	}
	return report
