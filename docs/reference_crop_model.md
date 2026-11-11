# PHÂN TÍCH MÔ HÌNH SINH TRƯỞNG CÂY (`nilold/farmer-game`) & THIẾT KẾ `CropQualityService` CHO HAYDAY OFFLINE

- **Dự án:** HayDay Offline (Chibi Farm) — Godot 4.7.2 Standard (`GL Compatibility`), GDScript 2.0 (100% Static Typing)
- **Tham chiếu:** `docs/HANDOVER.md` (Mục 10.1, 10.2, 10.4), `docs/references.md`, `scripts/entities/field_plot.gd`, `data/crops.json`
- **Nguồn khảo sát:** [`nilold/farmer-game`](https://github.com/nilold/farmer-game) (Giấy phép MIT — Christian Fisch, Godot 3.x)
- **Trạng thái:** **TÀI LIỆU NGHIÊN CỨU & THIẾT KẾ KIẾN TRÚC (Chưa viết code vào `scripts/`)** — Dùng cho giai đoạn mở rộng phẩm chất cây trồng **sau khi hoàn tất Phase 2A**.

---

## 1. TỔNG QUAN MÔ HÌNH SINH TRƯỞNG CÂY TRONG `nilold/farmer-game`

Kho lưu trữ `nilold/farmer-game` xây dựng một mô hình mô phỏng nông học chi tiết (lấy cảm hứng từ *SimFarm* 1993, tập trung vào giống cà phê *Coffea arabica*). Toàn bộ logic nằm tại 4 tệp chính:
- `Substract.gd`: Lớp chứa (container) nước và khoáng chất, được dùng cho cả **ô đất (Soil Substract)** lẫn **nội tại cây trồng (Plant Internal Substract)**.
- `world/weather.gd`: Trạng thái thời tiết toàn cục (`temperature`, `sun_strength`, `wind_strength`, `air_moisture`, `rain`).
- `crop/Crop.gd` (kế thừa `crop/Inffectable.gd`): Thực thể cây trồng với vòng lặp sinh học `cycle()`.
- `docs/crop-model-coffe.md`: Tài liệu sơ đồ vòng đời và phân bổ năng lượng qua 4 giai đoạn.

---

## 2. GIẢI PHẪU CÔNG THỨC TOÁN HỌC TRONG `nilold/farmer-game`

Mỗi nhịp mô phỏng, hàm `Crop.cycle()` thực thi tuần tự 5 bước:

```text
cycle()
 ├── 1. _absorve_nutrients_from_soil()   [Hút nước & khoáng N, P, K, Fe từ đất]
 ├── 2. _activate_diseases()             [Tác động sâu bệnh & hệ miễn dịch]
 ├── 3. _update_health()                 [Tính sát thương thiếu/thừa chất -> cập nhật health]
 ├── 4. _grow()                          [Quang hợp nắng + nước -> đẩy lá, chồi, hoa, quả]
 └── 5. _mature()                        [Chuyển giai đoạn vòng đời & rụng lá tự nhiên]
```

### 2.1. Phản ứng với Đất & Phân bón (`Substract.gd` & `_absorve_nutrients_from_soil`)
1. **Khoáng chất & Độ ẩm trong đất (`Substract.gd`):**
   - Mỗi ô đất lưu một từ điển `minerals` gồm 4 nguyên tố: `["N", "P", "K", "Fe"]` (khởi tạo ngẫu nhiên `200..500`, bão hòa ở `MINERAL_SATURATION = 600`) và lượng nước `water` (khởi tạo `50..100`, bão hòa ở `water_saturation = 1000`).
   - Khi người chơi bón phân hoặc tưới nước, hàm `add_mineral(mineral, quantity)` và `add_water(quantity)` cộng dồn giá trị và kẹp (`clamp`) trong ngưỡng bão hòa.
2. **Cơ chế rễ hút dinh dưỡng (`_absorve_nutrients_from_soil`):**
   - Trong mỗi chu kỳ, rễ cây hút khoáng và nước từ `soil_substract` sang kho dự trữ nội tại của cây theo sức khỏe bộ rễ (`root_health` $\in [0.0, 1.0]$):
     $$\Delta M_{\text{absorbed}} = \text{soil.consume\_mineral}\left(m,\; \text{mineral\_absorption\_flow} \times \text{root\_health}\right)$$
     $$\Delta W_{\text{absorbed}} = \text{soil.consume\_water}\left(\text{water\_absorption\_flow} \times \text{root\_health}\right)$$
   - Thông số mặc định: `mineral_absorption_flow = 1.8`, `water_absorption_flow = 0.1`, ngưỡng nước nội tại `water_saturation = 1.0`.
3. **Phản ứng sức khỏe với Thiếu chất (`needs`) và Ngộ độc thừa chất (`tolerates`):**
   - Cây định nghĩa nhu cầu khoáng `needs: Dictionary` và ngưỡng chịu đựng độc tố `tolerates: Dictionary`.
   - Tỷ lệ hư hại do thiếu khoáng (`_get_damage_by_lacking_minerals`):
     $$D_{\text{lack}} = \frac{\sum_{n \in \text{needs}} \left(\text{needs}[n] - M_{\text{present}}[n]\right)}{\sum_{n \in \text{needs}} \text{needs}[n]}$$
   - Tỷ lệ hư hại do vượt ngưỡng chịu đựng (`_get_damage_by_rejected_minerals`):
     $$D_{\text{reject}} = \frac{\sum_{r \in \text{tolerates}} M_{\text{present}}[r]}{\sum_{r \in \text{tolerates}} \text{tolerates}[r]}$$
   - Sức khỏe cây (`health` $\in [0.0, 1.0]$) suy giảm theo hệ số giảm chấn `damage_amortization = 0.5`:
     $$\text{health}_{t+1} = \text{clamp}\left(\text{health}_t \times (1 - D \times \text{damage\_amortization}),\; 0.0,\; 1.0\right)$$
   - Nếu `health < 0.01`, cây chết (`_die()`).

### 2.2. Phản ứng với Thời tiết & Độ ẩm (`world/weather.gd` & `_convert_energy`)
Để sinh trưởng, cây phải chuyển hóa **Ánh nắng (`_sun()`)** và **Nước (`water`)** thành năng lượng sinh học (`acquired_energy`):
1. **Quang hợp theo diện tích lá (`_convert_sun_to_energy`):**
   - Khả năng hấp thụ ánh nắng tỷ lệ thuận với cường độ nắng của thời tiết (`sun_strength`) nhân với tỷ lệ độ phủ lá hiện tại (`leaves / leaves_setpoint`, với `leaves_setpoint = 100`):
     $$E_{\text{sun}} = \text{clamp}\left(\text{sun\_strength} \times \frac{\text{leaves}}{\text{leaves\_setpoint}},\; 0,\; E_{\max}\right)$$
     $$E_{\text{from\_sun}} = E_{\text{required}} \times \frac{E_{\text{sun}}}{E_{\max}}$$
   - Khi cây bị bệnh hoặc thiếu chất làm giảm `health`, lá rụng nhanh hơn qua hàm `_lose_leaves()`:
     $$\text{leaves}_{t+1} = \text{leaves}_t \times \text{health} \times (1 - \text{natural\_leaf\_drop\_per\_cycle})$$
     $\rightarrow$ Lá giảm làm giảm quang hợp $E_{\text{sun}}$, tạo ra vòng phản hồi sinh học chặt chẽ.
2. **Giới hạn bởi Stress Nước (`_convert_water_to_energy`):**
   - Để sử dụng được lượng năng lượng $E_{\text{from\_sun}}$, cây phải tiêu hao một lượng nước tương ứng (`water_per_energy = 0.02`):
     $$W_{\text{consumed}} = \text{substract.consume\_water}\left(\text{water\_per\_energy} \times E_{\text{from\_sun}}\right)$$
     $$E_{\text{acquired}} = \text{clamp}\left(E_{\text{from\_sun}},\; 0,\; \frac{W_{\text{consumed}}}{\text{water\_per\_energy}}\right)$$
   - Nếu trời không mưa (`rain == 0`) và đất cạn nước, $W_{\text{consumed}} = 0 \implies E_{\text{acquired}} = 0$, cây ngừng phát triển hoàn toàn (Hydric Stress).

### 2.3. Công thức Lực sinh trưởng & "Nghịch lý tiêu thụ" (`_grow_by_energy_and_mineral`)
Tại mỗi giai đoạn trong 4 giai đoạn vòng đời (`INITIAL = 30`, `DEVELOPMNENT = 50`, `FLOWERY = 10`, `PRODUCTION = 40` chu kỳ):
1. **Áp lực sinh trưởng (`growth_pressure` $p \in [0.0, 1.0]$):**
   - Mọc lá (`_grow_leaves`): $p = \dfrac{\text{leaves\_setpoint} - \text{leaves}}{\text{leaves\_setpoint}}$
   - Mọc chồi (`_grow_sprouts`, chỉ kích hoạt khi $\text{leaves} \ge 70$): $p = \dfrac{\text{fruits\_setpoint} - \text{sprouts}}{\text{fruits\_setpoint}}$
   - Ra hoa (`_grow_flowers`, chuyển hóa từ chồi): $p = \dfrac{\text{sprouts}}{\text{sprouts} + \text{flowers}}$
   - Kết trái (`_grow_fruits`, chuyển hóa từ hoa): $p = \dfrac{\text{flowers}}{\text{flowers} + \text{total\_fruits}}$
2. **Giải bài toán "Growth Consumption Paradox" (Hoàn trả năng lượng khi thiếu khoáng):**
   - Nhu cầu năng lượng $E_{\text{req}} = p \times E_{\text{base}}$ và nhu cầu khoáng $M_{\text{req}} = p \times M_{\text{base}}$.
   - Nếu cây thu được tỷ lệ năng lượng $r_E = \dfrac{E_{\text{acquired}}}{E_{\text{req}}}$, nó chỉ yêu cầu lượng khoáng tương ứng $M'_{\text{req}} = M_{\text{req}} \times r_E$.
   - Nếu kho khoáng trong cây chỉ đáp ứng được tỷ lệ $r_M = \dfrac{M_{\text{consumed}}}{M'_{\text{req}}} < 1$, phần năng lượng mặt trời + nước đã trót chuyển hóa nhưng không có khoáng để tổng hợp mô tế bào sẽ được **hoàn trả lại thành nước** qua `_return_energy_resources(E_acquired * (1 - r_M))`.
3. **Phương trình Lực sinh trưởng (`growth_force`):**
   $$\text{growth\_force} = p^2 \times \left(\frac{E_{\text{acquired}}}{E_{\text{req}}}\right) \times \left(\frac{M_{\text{consumed}}}{M'_{\text{req}}}\right)$$
   $$\Delta \text{growth} = \text{growth\_force} \times \text{growth\_speed}$$

---

## 3. ĐÁNH GIÁ KHI ĐỐI CHIẾU VỚI KIẾN TRÚC `HayDayOffline`

| Khía cạnh | Cách làm của `nilold/farmer-game` | Yêu cầu của `HayDayOffline` (Cozy Chibi) | Quyết định chuyển đổi |
| :--- | :--- | :--- | :--- |
| **Hình phạt khi thiếu chăm sóc** | Cây giảm `health`, rụng lá, thối quả (`rot_fruits`) và **chết (`_die()`)** nếu đất khô hoặc thiếu khoáng. | Game Cozy Offline: người chơi có thể nghỉ nhiều giờ (`OfflineSimulator`). **Cây không bao giờ được chết hoặc héo mất trắng.** | **Bỏ cơ chế chết cây/hư hại.** Chuyển toàn bộ ảnh hưởng của Đất, Nước, Thời tiết thành **Thưởng Phẩm Chất (Quality Tier / Bonus Yield)** cộng thêm trên mức cơ bản. |
| **Thời gian sinh trưởng** | Không có timer cố định; phụ thuộc hoàn toàn vào số chu kỳ tích lũy đủ lá/hoa/quả. | Đã chốt **Quyết định D1 (Phương án B)**: giữ timer chuẩn từ `data/crops.json` (`180s`–`1800s`), mưa `COZY_RAIN` tăng tốc `×1.25`. | **Giữ nguyên timer của `FieldPlot`.** Mô hình mới không làm chậm timer gốc mà quyết định **Phẩm chất nông sản** khi thu hoạch (`harvest()`). |
| **Hiệu năng & Cú pháp** | Godot 3.x (GDScript 1.0 không kiểu tĩnh); mỗi cây tạo nhiều node con (`Substract`, `Disease`), gây giật khi trồng nhiều ô. | Godot 4.7.2, **100% Static Typing GDScript 2.0**, chạy mượt 60 FPS trên máy cấu hình nhẹ. | Viết thành một dịch vụ gọn nhẹ **`CropQualityService`** dùng dữ liệu thuần (`Dictionary` / Struct tĩnh trên từng ô lưới `Vector2i`), **không tạo thêm Node con** cho mỗi ô ruộng. |
| **Nguồn dữ liệu** | Khai báo rời rạc bằng `export var` trên từng scene. | **Quyết định D4 (SSOT):** mọi thông số cây trồng nằm duy nhất tại `data/crops.json`. | Đọc hệ số dinh dưỡng & độ nhạy thời tiết trực tiếp từ `data/crops.json` qua `DataManager`. |

---

## 4. THIẾT KẾ LẠI THÀNH `CropQualityService` CHO `HayDayOffline` (SAU PHASE 2A)

### 4.1. Mở rộng nhẹ cấu trúc SSOT trong `data/crops.json`
Mỗi cây trồng trong `data/crops.json` có thể bổ sung trường tùy chọn `"agronomy"` (nếu chưa khai báo, `CropQualityService` tự động dùng giá trị mặc định an toàn để không ảnh hưởng dữ liệu cũ):

```json
{
  "wheat": {
    "id": "wheat",
    "name": "Lúa Mì",
    "growth_time_seconds": 180,
    "harvest_yield": 2,
    "xp_reward": 1,
    "base_price": 3,
    "unlock_level": 1,
    "storage_type": "silo",
    "agronomy": {
      "nitrogen_delta": -0.08,
      "rain_quality_weight": 0.35,
      "soil_quality_weight": 0.45,
      "pollination_weight": 0.20
    }
  },
  "soybean": {
    "id": "soybean",
    "name": "Đậu Nành",
    "growth_time_seconds": 1200,
    "harvest_yield": 2,
    "xp_reward": 3,
    "base_price": 10,
    "unlock_level": 5,
    "storage_type": "silo",
    "agronomy": {
      "nitrogen_delta": 0.25,
      "rain_quality_weight": 0.30,
      "soil_quality_weight": 0.50,
      "pollination_weight": 0.20
    }
  }
}
```
> **Điểm sáng kế thừa từ `Substract.gd`:** Cây họ đậu (`soybean`) có `nitrogen_delta = +0.25` giúp **tự động bồi hoàn độ màu mỡ cho ô đất** khi người chơi luân canh (trồng Đậu Nành xen kẽ Lúa Mì/Ngô), tạo chiều sâu chiến thuật nhẹ nhàng mà không bắt buộc người chơi phải mua phân bón liên tục!

### 4.2. Công thức tính Điểm Phẩm Chất (`QualityScore`) khi thu hoạch
Khi một ô `FieldPlot` tại tọa độ lưới `grid_pos: Vector2i` bắt đầu trồng (`plant()`) và tiến tới thu hoạch (`harvest()`), `CropQualityService` tính **Điểm Phẩm Chất $Q \in [0.0, 1.0]$** từ 3 thành phần chuẩn hóa:

$$Q = \text{clamp}\left(w_{\text{soil}} \cdot F_{\text{soil}} + w_{\text{rain}} \cdot F_{\text{hydration}} + w_{\text{pol}} \cdot F_{\text{pollination}},\; 0.0,\; 1.0\right)$$

Trong đó:
1. **Hệ số Độ màu mỡ Đất & Phân bón ($F_{\text{soil}} \in [0.0, 1.0]$):**
   - Mỗi ô ruộng `grid_pos` có độ màu mỡ nền `fertility` khởi tạo ở `0.60`.
   - Khi thu hoạch cây thông thường, `fertility` giảm nhẹ (`nitrogen_delta = -0.08`, nhưng **không bao giờ thấp hơn sàn `0.35`** để người chơi bình thường luôn nhận đủ sản lượng gốc `harvest_yield = 2`).
   - Khi trồng cây họ đậu (`soybean`: `+0.25`) hoặc bón Phân Hữu Cơ (`compost`: `+0.40`), `fertility` tăng lên tối đa `1.0`.
2. **Hệ số Độ ẩm & Thời tiết Mưa ($F_{\text{hydration}} \in [0.0, 1.0]$):**
   - Kết nối trực tiếp với tín hiệu `EventBus.weather_state_changed` đã có trong `FieldPlot` (`scripts/entities/field_plot.gd` dòng 81).
   - Nếu trong vòng đời sinh trưởng, cây được tắm mưa **`COZY_RAIN`** (ngoài việc đã được tăng tốc độ lớn `×1.25`), biến `was_watered_by_rain = true` giúp $F_{\text{hydration}} = 1.0$ (ngược lại mặc định $0.40$, hoặc $0.75$ nếu ô đất nằm gần bờ sông).
3. **Hệ số Thụ phấn & Cảnh quan ($F_{\text{pollination}} \in [0.0, 1.0]$):**
   - Kế thừa giai đoạn `FLOWERY` của `nilold/farmer-game` kết hợp thực thể `BeehiveTree` của `HayDayOffline`: nếu ô ruộng nằm trong bán kính bay của ong mật (`BeehiveTree`) hoặc gần các ô trồng hoa (`sunflower`, `rose`, `lavender`), $F_{\text{pollination}} = 1.0$ (mặc định $0.30$).

### 4.3. Phân hạng Phẩm chất & Phần thưởng đầu ra
Để không làm phình số lượng ID vật phẩm trong kho Silo (`StorageManager`), phẩm chất cây khi thu hoạch (`FieldPlot.harvest()`) được quy đổi trực tiếp thành **Sản lượng thưởng (Bonus Yield) + XP thưởng + Xu Du Lịch**:

| Hạng Phẩm Chất | Ngưỡng điểm $Q$ | Hiệu ứng khi thu hoạch (`FieldPlot.harvest()`) |
| :--- | :---: | :--- |
| **Tiêu Chuẩn (`STANDARD`)** | $0.00 \le Q < 0.65$ | Giữ nguyên 100% theo `crops.json`: nhận `harvest_yield` (2 nông sản) + `xp_reward`. |
| **Tươi Tốt (`SILVER_CROP`)** | $0.65 \le Q < 0.85$ | Nhận `harvest_yield` + **`+1` XP thưởng** + **`+5` Vàng thưởng nông sản sạch**. |
| **Thượng Hạng (`GOLD_STAR_CROP`)** | $Q \ge 0.85$ | Nhận **`harvest_yield + 1` (3 nông sản)** + **`×2` `xp_reward`** + hiệu ứng hạt lấp lánh vàng. |

---

## 5. MẪU KIẾN TRÚC CODE `CropQualityService` (GDSCRIPT 2.0 STATIC TYPING)

Dưới đây là bản thiết kế lớp `CropQualityService` tuân thủ 100% Static Typing GDScript 2.0, sẵn sàng để triển khai vào `scripts/systems/crop_quality_service.gd` sau khi hoàn tất Phase 2A:

```gdscript
# scripts/systems/crop_quality_service.gd
# Thiết kế lại từ ý tưởng mô hình nông học của nilold/farmer-game (MIT License)
# Tuân thủ chuẩn GDScript 2.0 Static Typing & SSOT data/crops.json
class_name CropQualityService
extends RefCounted

enum QualityTier {
	STANDARD = 0,
	SILVER = 1,
	GOLD_STAR = 2
}

const MIN_SOIL_FERTILITY: float = 0.35
const DEFAULT_SOIL_FERTILITY: float = 0.60
const MAX_SOIL_FERTILITY: float = 1.00

# Lưu độ màu mỡ theo từng ô lưới Vector2i -> float (0.35 .. 1.00)
var _soil_fertility_map: Dictionary = {}

func get_soil_fertility(grid_pos: Vector2i) -> float:
	if not _soil_fertility_map.has(grid_pos):
		return DEFAULT_SOIL_FERTILITY
	return clampf(float(_soil_fertility_map[grid_pos]), MIN_SOIL_FERTILITY, MAX_SOIL_FERTILITY)

func apply_fertilizer(grid_pos: Vector2i, boost_amount: float = 0.40) -> float:
	var cur: float = get_soil_fertility(grid_pos)
	var updated: float = clampf(cur + boost_amount, MIN_SOIL_FERTILITY, MAX_SOIL_FERTILITY)
	_soil_fertility_map[grid_pos] = updated
	return updated

func evaluate_crop_quality(
	crop_id: String,
	grid_pos: Vector2i,
	was_watered_by_rain: bool,
	has_nearby_pollinators: bool
) -> Dictionary:
	var crop_data: Dictionary = DataManager.get_crop(crop_id) if DataManager != null else {}
	var agronomy: Dictionary = crop_data.get("agronomy", {}) as Dictionary

	var w_soil: float = float(agronomy.get("soil_quality_weight", 0.45))
	var w_rain: float = float(agronomy.get("rain_quality_weight", 0.35))
	var w_pol: float = float(agronomy.get("pollination_weight", 0.20))

	var f_soil: float = get_soil_fertility(grid_pos)
	var f_hydration: float = 1.0 if was_watered_by_rain else 0.40
	var f_pollination: float = 1.0 if has_nearby_pollinators else 0.30

	var score: float = clampf(
		w_soil * f_soil + w_rain * f_hydration + w_pol * f_pollination,
		0.0,
		1.0
	)

	var tier: QualityTier = QualityTier.STANDARD
	var bonus_yield: int = 0
	var bonus_xp: int = 0
	var bonus_gold: int = 0

	if score >= 0.85:
		tier = QualityTier.GOLD_STAR
		bonus_yield = 1
		bonus_xp = maxi(1, int(crop_data.get("xp_reward", 1)))
		bonus_gold = 10
	elif score >= 0.65:
		tier = QualityTier.SILVER
		bonus_xp = 1
		bonus_gold = 5

	return {
		"quality_score": score,
		"tier": tier,
		"bonus_yield": bonus_yield,
		"bonus_xp": bonus_xp,
		"bonus_gold": bonus_gold
	}

func on_crop_harvested_update_soil(crop_id: String, grid_pos: Vector2i) -> float:
	var crop_data: Dictionary = DataManager.get_crop(crop_id) if DataManager != null else {}
	var agronomy: Dictionary = crop_data.get("agronomy", {}) as Dictionary
	var default_delta: float = 0.25 if crop_id == "soybean" else -0.08
	var nitrogen_delta: float = float(agronomy.get("nitrogen_delta", default_delta))

	var next_fertility: float = clampf(
		get_soil_fertility(grid_pos) + nitrogen_delta,
		MIN_SOIL_FERTILITY,
		MAX_SOIL_FERTILITY
	)
	_soil_fertility_map[grid_pos] = next_fertility
	return next_fertility
```

---

## 6. LỘ TRÌNH TÍCH HỢP AN TOÀN (SAU PHASE 2A & 2B)

1. **Điều kiện tiên quyết:** Chỉ bắt đầu tích hợp `CropQualityService` sau khi **Phase 2A** (`docs/economy_report.md`) đã chốt xong bảng giá cơ bản trong `data/crops.json` và **Phase 2B** đã ổn định trải nghiệm đầu game.
2. **Kiểm soát lạm phát kinh tế:** Vì `QualityTier.GOLD_STAR` có thể cộng thêm `+1` sản lượng (`bonus_yield = 1`) khi người chơi kết hợp Luân canh Đậu Nành + Mưa `COZY_RAIN` + Tổ Ong gần ruộng, cần đưa biến kỳ vọng thưởng phẩm chất ($\approx +10\%$ đến $+15\%$ năng suất trung bình) vào `tools/economy_report.py` để kiểm tra lại lợi nhuận/phút.
3. **Unit Test đi kèm (`tests/unit/test_crop_quality.gd`):**
   - Kiểm tra độ màu mỡ không bao giờ tụt dưới `MIN_SOIL_FERTILITY = 0.35`.
   - Kiểm tra trồng `soybean` tăng độ màu mỡ ô đất thêm `+0.25`.
   - Kiểm tra kết hợp mưa `COZY_RAIN` + đất màu mỡ cao (`1.0`) + tổ ong thụ phấn đạt đúng hạng `QualityTier.GOLD_STAR`.
