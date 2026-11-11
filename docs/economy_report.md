# BÁO CÁO KIỂM TOÁN KINH TẾ THEO PHÚT (PHASE 2A)

> **File script tạo báo cáo:** [`tools/economy_report.py`](file:///d:/HayDayOffline/tools/economy_report.py)  
> **File dữ liệu xuất CSV:** [`docs/economy_report.csv`](file:///d:/HayDayOffline/docs/economy_report.csv) (47 dòng gồm 1 dòng header + 46 dòng dữ liệu thực thể)  
> **Nguyên tắc thực hiện:** Chỉ đọc và kiểm toán dữ liệu thực tế từ `data/*.json` và code hiện hành (`field_plot.gd`, `daily_newspaper.gd`, `data_manager.gd`, `production_machine.gd`, `animal_pen.gd`). **Tuyệt đối không tự ý sửa file JSON hay code gameplay.**

---

## 1. Xác nhận trực tiếp các mục `[CHƯA KIỂM CHỨNG]` trong `HANDOVER.md` (Mục 5.3 & 7.2)

### 1.1. `sanctuary_feed` (`craft_time_seconds = 12` $\rightarrow$ đã sửa thành `1200s`, `produce_count = 2`) — **ĐÃ XÁC NHẬN & ĐÃ SỬA**
- **Vị trí:** [`data/recipes.json`](file:///d:/HayDayOffline/data/recipes.json#L245-L262).
- **Dữ liệu ghi nhận ban đầu vs sau khi sửa:**
  - `"ingredients": { "wheat": 3, "corn": 2, "carrot": 1 }`
  - `"produce_count": 2`
  - `"craft_time_seconds"`: ban đầu là `12` (0.2 phút — lỗi thiếu hai số 0), **đã được sửa thành `1200` (20.0 phút)** và chạy lại `tools/economy_report.py`.
  - `"base_price": 35` (khớp với [`data/items.json`](file:///d:/HayDayOffline/data/items.json#L375-L382)).
- **Tác động kinh tế (sau khi sửa `craft_time_seconds = 1200`):**
  - **Vốn nguyên liệu:** `31 vàng` (theo giá `items.json`: `3×3 + 2×7 + 1×8`) hoặc `35 vàng` (theo giá gốc `crops.json`: `3×3 + 2×9 + 1×8`).
  - **Khi trả đủ `produce_count = 2` (doanh thu `70 vàng`):**
    - Lãi `+39 vàng` (theo `items.json`) → **`1.95 vàng/phút`** (trước khi sửa ở `12s` là `195.00 vàng/phút`).
    - Lãi `+35 vàng` (theo `crops.json`) → **`1.75 vàng/phút`** (trước khi sửa ở `12s` là `175.00 vàng/phút`).
  - **Khi chỉ trả `1` món (lỗi trong [`scripts/entities/production_machine.gd`](file:///d:/HayDayOffline/scripts/entities/production_machine.gd#L365-L368) trước Phase 1, doanh thu `35 vàng`):**
    - Lãi `+4 vàng` (`0.20 vàng/phút` theo `items.json`) hoặc **`0 vàng`** (`0.00 vàng/phút` theo `crops.json` — hòa vốn).

### 1.2. Mồi câu `red_lure`, `green_lure`, `gold_lure` có `ingredients = {}` — **ĐÃ XÁC NHẬN (+ Phát hiện lệch ID với `items.json`)**
- **Vị trí:** [`data/recipes.json`](file:///d:/HayDayOffline/data/recipes.json#L203-L244) và [`data/items.json`](file:///d:/HayDayOffline/data/items.json#L351-L374).
- **Xác nhận:**
  1. Cả 3 công thức `red_lure`, `green_lure`, `gold_lure` trong `recipes.json` đều có `"ingredients": {}` (chi phí nguyên liệu = `0 vàng`), nhưng có giá bán `base_price` lần lượt là `20`, `35`, `60` vàng.
  2. **Phát hiện thêm lỗi bất đồng bộ ID & giá giữa `recipes.json` / `fishes.json` và `items.json`:**
     - Trong `recipes.json` và `fishes.json` (`required_lure_id`): sử dụng ID **`red_lure`** (giá `20`), **`green_lure`** (giá `35`), **`gold_lure`** (giá `60`).
     - Trong `items.json` (dòng 351–374): **không tồn tại** `red_lure`, `green_lure`, `gold_lure`, mà lại khai báo dưới ID **`bait_red`** (giá `15`), **`bait_blue`** (giá `25`), **`bait_gold`** (giá `50`).

### 1.3. Giá `cookie` hardcode trong `daily_newspaper.gd` — **ĐÃ XÁC NHẬN (+ Phát hiện 15/17 mặt hàng trong báo chí bị hardcode lệch giá)**
- **Vị trí:** [`scripts/systems/daily_newspaper.gd`](file:///d:/HayDayOffline/scripts/systems/daily_newspaper.gd#L23-L48).
- **Xác nhận:**
  - Tại dòng 41 của `daily_newspaper.gd`: `{ "id": "cookie", "name": "Bánh quy bơ", "type": "barn", "base_price": 45, "count_min": 2, "count_max": 3 }`.
  - Giá `base_price` của `cookie` bị hardcode là **`45 vàng`**, trong khi trong `items.json` (cả key `"cookie"` dòng 271 và `"butter_cookie"` dòng 279) và `recipes.json` (`"butter_cookie"` dòng 102) đều có `"base_price": 150`. Với chiết khấu 30%–50% của báo chí, người chơi mua `cookie` từ báo chỉ tốn ~`22–31 vàng/chiếc` rồi bán lại ở sạp hàng giá `150 vàng/chiếc` (lãi khống hơn `118 vàng/chiếc`).
  - Hơn nữa, ID trong `recipes.json` là `butter_cookie`, còn `daily_newspaper.gd` cấp thẳng item ID `cookie`.
  - Không chỉ `cookie`, **15/17 mặt hàng** trong `GOODS_CATALOG` của `daily_newspaper.gd` đang bị hardcode `base_price` lệch so với `items.json` / `crops.json` (xem chi tiết tại Mục 3.4 bên dưới, đặc biệt `cream_cake` hardcode `80` so với `260` trong JSON).

### 1.4. Hệ số thu hoạch thực tế trong `scripts/entities/field_plot.gd` — **ĐÃ XÁC NHẬN**
- **Vị trí:** [`scripts/entities/field_plot.gd`](file:///d:/HayDayOffline/scripts/entities/field_plot.gd#L151-L214).
- **Xác nhận cơ chế code thực tế:**
  1. **Khi thu hoạch (`harvest()`, dòng 200 & 208):**
     ```gdscript
     var harvest_yield: int = int(crop_data.get("harvest_yield", 2))
     StorageManager.add_item(crop_id, harvest_yield)
     ```
     - Trong cả `crops.json` và `items.json` **đã có sẵn trường `"harvest_yield": 2`** (riêng `apple_seed` và `mango_seed` là `"harvest_yield": 1`).
     - Code `FieldPlot.harvest()` lấy trực tiếp `harvest_yield` từ JSON (tức thu về đúng **2 nông sản** mỗi ô ruộng), **không nhân thêm ×2 chồng lên `harvest_yield`**. Quy ước "thu hoạch nhận x2 nông sản" tại `GEMINI.md` dòng 11 chính là giá trị `harvest_yield = 2` này (hệ số nhân thêm trong code = `×1`). Nếu công thức mục 7.2 nhân thêm hệ số `×2` ngoài `harvest_yield` sẽ thành `2 × 2 = 4` nông sản/ô (sai lệch với code thực tế).
  2. **Khi gieo hạt (`plant()`, dòng 159–166):**
     - `crops.json` và `items.json` **không có trường `seed_cost` bằng vàng** (`THIẾU DỮ LIỆU seed_cost`).
     - Thay vào đó, `FieldPlot.plant()` tiêu thụ **1 đơn vị nông sản cùng loại từ kho Silo** (`StorageManager.remove_item(new_crop_id, 1)`). Nếu trồng `wheat` hoặc `corn` khi hết hạt (hoặc khi hết `wheat` và vàng `< 10`), cơ chế `Anti-Softlock` (dòng 161–163) cấp hạt giống miễn phí để người chơi không bị kẹt.
     - Do đó, xét theo vòng lặp tái canh bền vững (trồng 1 hạt → thu 2 hạt → giữ lại 1 hạt làm giống cho vụ sau, đem bán 1 hạt), **sản lượng ròng thực tế mỗi chu kỳ là `harvest_yield - 1 = 1` nông sản** (chi phí cơ hội của hạt giống = `1 × base_price`). Trong bảng báo cáo dưới đây và trong file CSV, cả 3 góc nhìn (**Doanh thu gộp x1 `harvest_yield`**, **Lãi ròng tái canh trừ 1 hạt giống**, và **Giả định nhân chồng x2 `harvest_yield`**) đều được tính đầy đủ để đối chiếu.

---

## 2. Bảng tổng hợp Kinh tế theo phút

### 2.1. Chuỗi Chế biến (`data/recipes.json` — 20 công thức)

> **Chú giải cột:**
> - **Vốn (`items` vs `crops`):** `DataManager.get_item_base_price()` hiện ưu tiên đọc `items.json` trước `crops.json`. Các công thức dùng `corn` (`7` vs `9`), `apple` (`15` vs `24`), `mango` (`22` vs `36`) có vốn khác nhau giữa 2 nguồn.
> - **Lãi (Đủ SL):** Lợi nhuận khi `ProductionMachine` trả đúng `produce_count` (`rev = base_price × produce_count`).
> - **Lãi (Lỗi 1 món):** Lợi nhuận theo lỗi trước Phase 1 khi `ProductionMachine` chỉ trả `1` món bất kể `produce_count`.

| ID Công thức | Tên | Máy (`building_id`) | Lv | Nguyên liệu | SL ra (`produce_count`) | Giá đơn vị | Vốn (`items` / `crops`) | Doanh thu (Đủ SL / 1 món) | Lãi Đủ SL (`items` / `crops`) | Lãi 1 món (`items`) | Craft Time (giây / phút) | **Lãi/phút (`items`)** | **Lãi/phút (`crops`)** | Lãi/phút (Lỗi 1 món) | Đánh giá / Cờ bất thường |
|---|---|---|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `sanctuary_feed` | Bó Cỏ Dinh Dưỡng | `feed_mill` | 3 | `wheat`×3, `corn`×2, `carrot`×1 | 2 | 35 | 31 / 35 | 70 / 35 | +39 / +35 | +4 | **1200s** (20.0m, đã sửa từ 12s) | **1.95** | **1.75** | 0.20 | Lệch vốn nguyên liệu (`corn`: 7 vs 9); đã sửa lỗi `12s` |
| `bread` | Bánh Mì Nóng | `bakery` | 2 | `wheat`×3 | 1 | 21 | 9 / 9 | 21 / 21 | +12 / +12 | +12 | 300s (5.0m) | **2.40** | **2.40** | 2.40 | OK (Chuỗi nhập môn chuẩn) |
| `cream_cake` | Bánh Kem Dâu | `cake_oven` | 9 | `strawberry`×2, `egg`×2, `milk`×1 | 1 | 260 | 76 / 76 | 260 / 260 | +184 / +184 | +184 | 5400s (90.0m) | **2.04** | **2.04** | 2.04 | OK |
| `item_herbal_tea` | Trà Thảo Mộc Mật Ong | `juice_stand` | 6 | `rose`×1, `honey`×1 | 1 | 140 | 84 / 84 | 140 / 140 | +56 / +56 | +56 | 1800s (30.0m) | **1.87** | **1.87** | 1.87 | OK |
| `butter_cookie` | Bánh Quy Bơ | `bakery` | 8 | `wheat`×2, `egg`×2, `sugarcane`×1 | 1 | 150 | 44 / 44 | 150 / 150 | +106 / +106 | +106 | 3600s (60.0m) | **1.77** | **1.77** | 1.77 | OK (Nhưng trùng lặp với `cookie` trong `items.json`) |
| `corn_bread` | Bánh Mì Ngô | `bakery` | 7 | `corn`×2, `egg`×2 | 1 | 90 | 38 / 42 | 90 / 90 | +52 / +48 | +52 | 1800s (30.0m) | **1.73** | **1.60** | 1.73 | Lệch vốn nguyên liệu (`corn`: 7 vs 9) |
| `chicken_feed` | Cám Gà | `feed_mill` | 1 | `wheat`×2, `corn`×1 | 3 | 7 | 13 / 15 | 21 / 7 | +8 / +6 | **-6** | 300s (5.0m) | **1.60** | **1.20** | **-1.20** | Lệch vốn (`corn`: 7 vs 9); **lỗ -6 vàng nếu chỉ trả 1 bao** |
| `cheese` | Phô Mai | `dairy` | 8 | `milk`×3 | 1 | 180 | 84 / 84 | 180 / 180 | +96 / +96 | +96 | 3600s (60.0m) | **1.60** | **1.60** | 1.60 | OK |
| `item_bacon_eggs` | Trứng Chiên Thịt Xông Khói | `bakery` | 10 | `egg`×2, `bacon`×1 | 1 | 150 | 89 / 89 | 150 / 150 | +61 / +61 | +61 | 2400s (40.0m) | **1.52** | **1.52** | 1.52 | OK |
| `cow_feed` | Cám Bò | `feed_mill` | 6 | `corn`×1, `soybean`×2 | 3 | 14 | 27 / 29 | 42 / 14 | +15 / +13 | **-13** | 600s (10.0m) | **1.50** | **1.30** | **-1.30** | Lệch vốn (`corn`: 7 vs 9); **lỗ -13 vàng nếu chỉ trả 1 bao** |
| `item_grilled_fish` | Cá Nướng Xiên Que | `bakery` | 4 | `fish_carp`×1, `corn`×1 | 1 | 52 | 32 / 34 | 52 / 52 | +20 / +18 | +20 | 900s (15.0m) | **1.33** | **1.20** | 1.33 | Lệch vốn (`corn`: 7 vs 9) |
| `item_fish_pie` | Bánh Pie Cá Nướng | `bakery` | 4 | `fish_carp`×1, `wheat`×2 | 1 | 55 | 31 / 31 | 55 / 55 | +24 / +24 | +24 | 1200s (20.0m) | **1.20** | **1.20** | 1.20 | OK |
| `butter` | Bơ Sữa | `dairy` | 6 | `milk`×1 | 1 | 50 | 28 / 28 | 50 / 50 | +22 / +22 | +22 | 1200s (20.0m) | **1.10** | **1.10** | 1.10 | OK |
| `apple_juice` | Nước Ép Táo | `juice_stand` | 6 | `apple`×2 | 1 | 65 | 30 / 48 | 65 / 65 | +35 / +17 | +35 | 2400s (40.0m) | **0.88** | **0.42** | 0.88 | Thấp hơn mục tiêu (1.2–2.0); lệch mạnh vốn `apple` (15 vs 24) |
| `pig_feed` | Cám Heo | `feed_mill` | 10 | `carrot`×2, `soybean`×1 | 3 | 14 | 26 / 26 | 42 / 14 | +16 / +16 | **-12** | 1200s (20.0m) | **0.80** | **0.80** | **-0.60** | Hơi thấp (< 1.0); **lỗ -12 vàng nếu chỉ trả 1 bao** |
| `mango_smoothie` | Sinh Tố Xoài | `juice_stand` | 6 | `mango`×2, `milk`×1 | 1 | 110 | 72 / 100 | 110 / 110 | +38 / +10 | +38 | 3000s (50.0m) | **0.76** | **0.20** | 0.76 | Thấp (đặc biệt chỉ đạt `0.20/phút` nếu dùng giá `mango=36` ở `crops.json`) |
| `sugarcane_juice` | Nước Mía Đá | `juice_stand` | 6 | `sugarcane`×2 | 1 | 38 | 28 / 28 | 38 / 38 | +10 / +10 | +10 | 1800s (30.0m) | **0.33** | **0.33** | 0.33 | **Quá thấp** so với mục tiêu Lv 6 (1.2–2.0) |
| `gold_lure` | Mồi Câu Vàng Kim | `lure_workbench` | 7 | `{}` *(Rỗng)* | 1 | 60 | 0 / 0 | 60 / 60 | +60 / +60 | +60 | 10800s (180.0m) | **0.33** | **0.33** | 0.33 | **BẤT THƯỜNG:** Nguyên liệu rỗng nhưng có doanh thu; thiếu ID trong `items.json` (`bait_gold`=50) |
| `green_lure` | Mồi Câu Xanh | `lure_workbench` | 5 | `{}` *(Rỗng)* | 1 | 35 | 0 / 0 | 35 / 35 | +35 / +35 | +35 | 7200s (120.0m) | **0.29** | **0.29** | 0.29 | **BẤT THƯỜNG:** Nguyên liệu rỗng nhưng có doanh thu; thiếu ID trong `items.json` (`bait_blue`=25) |
| `red_lure` | Mồi Câu Đỏ | `lure_workbench` | 4 | `{}` *(Rỗng)* | 1 | 20 | 0 / 0 | 20 / 20 | +20 / +20 | +20 | 5400s (90.0m) | **0.22** | **0.22** | 0.22 | **BẤT THƯỜNG:** Nguyên liệu rỗng nhưng có doanh thu; thiếu ID trong `items.json` (`bait_red`=15) |

---

### 2.2. Chuỗi Cây trồng (`data/crops.json` — 15 cây/hạt giống)

> **Ghi chú dữ liệu:**
> - Tất cả 15 mục trong `crops.json` **đều có trường `harvest_yield`** (`2` cho 13 cây trồng, `1` cho `apple_seed` và `mango_seed`), nhưng **không có trường `seed_cost`** (`THIẾU DỮ LIỆU seed_cost`).
> - Trong code [`scripts/entities/field_plot.gd`](file:///d:/HayDayOffline/scripts/entities/field_plot.gd#L200-L208), mỗi lần gặt chỉ cộng đúng `harvest_yield` (tức hệ số code = `×1`), và mỗi lần gieo trừ `1` nông sản làm giống từ Silo.
> - Bảng dưới tính theo thời gian sinh trưởng chuẩn của `crops.json` (Phương án B) và liệt kê cả 3 chỉ số:
>   1. **Gross x1 `harvest_yield` (`seed_cost = 0`):** `(harvest_yield × base_price) ÷ phút`
>   2. **Net tái canh (giữ lại 1 hạt làm giống, `seed_cost = 1 × base_price`):** `((harvest_yield - 1) × base_price) ÷ phút`
>   3. **Giả định nhân chồng x2 (`harvest_yield × 2`):** `(harvest_yield × 2 × base_price) ÷ phút`

| ID Cây | Tên | Lv | Thời gian (`crops.json` vs `items.json`) | `harvest_yield` | Giá đơn vị (`crops` vs `items`) | Chi phí hạt (`seed_cost`) | Doanh thu Gross (`crops` / `items`) | Lãi ròng tái canh `-1 hạt` (`crops` / `items`) | **Gross/phút (`crops` / `items`)** | **Net tái canh/phút (`crops` / `items`)** | Giả định x2 chồng/phút (`crops`) | Đánh giá / Cờ bất thường |
|---|---|---:|---|---:|---:|---|---:|---:|---:|---:|---:|---|
| `wheat` | Lúa Mì | 1 | **180s** (3.0m) vs `10s` | 2 | 3 / 3 | Thiếu (`Replant=3`) | 6 / 6 | +3 / +3 | **2.00** / 2.00 | **1.00** / 1.00 | 4.00 | Lệch `growth_time` (180s vs 10s) |
| `corn` | Ngô | 2 | **480s** (8.0m) vs `20s` | 2 | **9** / **7** | Thiếu (`Replant=9/7`) | 18 / 14 | +9 / +7 | **2.25** / 1.75 | **1.12** / 0.88 | 4.50 | Lệch `base_price` (9 vs 7) & `growth_time` (480s vs 20s) |
| `tomato` | Cà Chua | 2 | **240s** (4.0m) vs `25s` | 2 | 9 / 9 | Thiếu (`Replant=9`) | 18 / 18 | +9 / +9 | **4.50** / 4.50 | **2.25** / 2.25 | 9.00 | Lệch `growth_time` (240s vs 25s) |
| `carrot` | Cà Rốt | 3 | **300s** (5.0m) vs `30s` | 2 | 8 / 8 | Thiếu (`Replant=8`) | 16 / 16 | +8 / +8 | **3.20** / 3.20 | **1.60** / 1.60 | 6.40 | Lệch `growth_time` (300s vs 30s) |
| `strawberry` | Dâu Tây | 3 | **360s** (6.0m) vs `35s` | 2 | 12 / 12 | Thiếu (`Replant=12`) | 24 / 24 | +12 / +12 | **4.00** / 4.00 | **2.00** / 2.00 | 8.00 | Lệch `growth_time` (360s vs 35s) |
| `pumpkin` | Bí Đỏ | 4 | **600s** (10.0m) vs `40s` | 2 | 15 / 15 | Thiếu (`Replant=15`) | 30 / 30 | +15 / +15 | **3.00** / 3.00 | **1.50** / 1.50 | 6.00 | Lệch `growth_time` (600s vs 40s) |
| `soybean` | Đậu Nành | 5 | **1200s** (20.0m) vs `45s` | 2 | 10 / 10 | Thiếu (`Replant=10`) | 20 / 20 | +10 / +10 | **1.00** / 1.00 | **0.50** / 0.50 | 2.00 | Lệch `growth_time` (1200s vs 45s) |
| `sugarcane` | Mía Đường | 7 | **1800s** (30.0m) vs `50s` | 2 | 14 / 14 | Thiếu (`Replant=14`) | 28 / 28 | +14 / +14 | **0.93** / 0.93 | **0.47** / 0.47 | 1.87 | Lệch `growth_time` (1800s vs 50s) |
| `apple` | Táo Đỏ | 1 | **900s** (15.0m) vs `25s` | 2 | **24** / **15** | Thiếu (`Replant=24/15`) | 48 / 30 | +24 / +15 | **3.20** / 2.00 | **1.60** / 1.00 | 6.40 | Lệch `base_price` (24 vs 15) & `growth_time` (900s vs 25s) |
| `mango` | Xoài Chín | 1 | **1200s** (20.0m) vs `30s` | 2 | **36** / **22** | Thiếu (`Replant=36/22`) | 72 / 44 | +36 / +22 | **3.60** / 2.20 | **1.80** / 1.10 | 7.20 | Lệch `base_price` (36 vs 22) & `growth_time` (1200s vs 30s) |
| `apple_seed` | Hạt Giống Táo | 1 | **15s** (0.25m) vs `15s` | 1 | **0** / **8** | Thiếu (`can_sell=false`) | 0 / 8 | 0 / 0 | **0.00** / 32.00 | **0.00** / 0.00 | 0.00 | **BẤT THƯỜNG:** `15s < 60s`, `Lãi/phút < 0.1` (`crops`), lệch `base_price` (0 vs 8) |
| `mango_seed` | Hạt Giống Xoài | 1 | **15s** (0.25m) vs `15s` | 1 | **0** / **10** | Thiếu (`can_sell=false`) | 0 / 10 | 0 / 0 | **0.00** / 40.00 | **0.00** / 0.00 | 0.00 | **BẤT THƯỜNG:** `15s < 60s`, `Lãi/phút < 0.1` (`crops`), lệch `base_price` (0 vs 10) |
| `sunflower` | Hoa Hướng Dương | 2 | **240s** (4.0m) vs `25s` | 2 | 12 / 12 | Thiếu (`Replant=12`) | 24 / 24 | +12 / +12 | **6.00** / 6.00 | **3.00** / 3.00 | 12.00 | **BẤT THƯỜNG:** `Gross/phút = 6.00 > 5.0`; lệch `growth_time` (240s vs 25s) |
| `rose` | Hoa Hồng Đỏ | 3 | **360s** (6.0m) vs `35s` | 2 | 16 / 16 | Thiếu (`Replant=16`) | 32 / 32 | +16 / +16 | **5.33** / 5.33 | **2.67** / 2.67 | 10.67 | **BẤT THƯỜNG:** `Gross/phút = 5.33 > 5.0`; lệch `growth_time` (360s vs 35s) |
| `lavender` | Hoa Oải Hương | 4 | **480s** (8.0m) vs `45s` | 2 | 20 / 20 | Thiếu (`Replant=20`) | 40 / 40 | +20 / +20 | **5.00** / 5.00 | **2.50** / 2.50 | 10.00 | Chạm ngưỡng `5.00/phút`; lệch `growth_time` (480s vs 45s) |

---

### 2.3. Chuỗi Vật nuôi (`data/animals.json` — 4 loài)

> **Ghi chú dữ liệu & code:**
> 1. **Lệch giá giữa `animals.json` và `items.json`:** Trường `base_price` trong `animals.json` (`chicken=10`, `cow=30`, `pig=80`, `sheep=120`) khác với `base_price` của sản phẩm tương ứng trong `items.json` (`egg=12`, `milk=28`, `bacon=65`, `wool=90`). Khi bán sản phẩm ở sạp hàng, `DataManager.get_item_base_price()` lấy giá trong `items.json`.
> 2. **Chi phí cám:**
>    - **Giá mua/bán cám (`items.json`):** `chicken_feed = 7`, `cow_feed = 14`, `pig_feed = 14`, `sheep_feed = 20`.
>    - **Giá vốn tự xay 1 bao cám (chia cho `produce_count = 3` bao):**
>      - `chicken_feed`: `13 / 3 = 4.33 vàng` (`items.json`) hoặc `15 / 3 = 5.00 vàng` (`crops.json`).
>      - `cow_feed`: `27 / 3 = 9.00 vàng` (`items.json`) hoặc `29 / 3 = 9.67 vàng` (`crops.json`).
>      - `pig_feed`: `26 / 3 = 8.67 vàng` (cả hai).
>      - `sheep_feed`: **THIẾU CÔNG THỨC** trong `recipes.json` (tạm tính bằng giá mua `20.00 vàng`).
> 3. **Khác biệt giữa công thức 1 con (Mục 7.2 `HANDOVER.md`) và cả chuồng 3 con (`AnimalPen.gd`):**
>    - Trong [`scripts/entities/animal_pen.gd`](file:///d:/HayDayOffline/scripts/entities/animal_pen.gd#L401-L448), mỗi chuồng có `animal_count = 3` con, khi cho ăn chỉ trừ **1 bao cám** (`StorageManager.remove_item(feed_id, 1)`) nhưng khi thu hoạch lại nhận **`produce_count * 3 = 3` sản phẩm** (và thời gian trong `AnimalPen.gd` dòng 416 hiện vẫn đang hardcode `var duration: int = 15`). Bảng dưới trình bày cả tính toán chuẩn trên **1 con vật** và tính toán trên **cả chuồng 3 con** theo thời gian JSON.

| ID Vật nuôi | Tên & Sản phẩm | Chuồng (`pen_building_id`) | Lv | Thời gian (`animals.json`) | Giá SP (`items` vs `animals`) | Cám (`feed_item_id`) | Giá 1 bao cám (Mua / Xay `items` / Xay `crops`) | Lãi 1 con (Mua cám / Xay `items` / Xay `crops`) | **Lãi/phút 1 con (Mua cám)** | **Lãi/phút 1 con (Tự xay `items` / `crops`)** | **Lãi/phút Chuồng 3 con (1 cám → 3 SP)** | Đánh giá / Cờ bất thường |
|---|---|---|---:|---|---|---|---|---|---:|---:|---:|---|
| `chicken` | Gà → `egg` | `chicken_coop` | 1 | 1200s (20.0m) | **12** vs `10` | `chicken_feed` | 7.00 / 4.33 / 5.00 | +5.00 / +7.67 / +7.00 | **0.25** | **0.38** / **0.35** | **1.45** (Mua) / **1.58** (Xay) | Lệch giá (`egg=12` vs `chicken=10`); lãi 1 con thấp nhưng chuồng 3 con đạt chuẩn (1.45–1.58) |
| `cow` | Bò Sữa → `milk` | `cow_pasture` | 6 | 3600s (60.0m) | **28** vs `30` | `cow_feed` | 14.00 / 9.00 / 9.67 | +14.00 / +19.00 / +18.33 | **0.23** | **0.32** / **0.31** | **1.17** (Mua) / **1.25** (Xay) | Lệch giá (`milk=28` vs `cow=30`) |
| `pig` | Heo → `bacon` | `pig_pen` | 10 | 7200s (120.0m) | **65** vs `80` | `pig_feed` | 14.00 / 8.67 / 8.67 | +51.00 / +56.33 / +56.33 | **0.42** | **0.47** / **0.47** | **1.51** (Mua) / **1.55** (Xay) | Lệch giá (`bacon=65` vs `pig=80`) |
| `sheep` | Cừu → `wool` | `sheep_pasture` | 16 | 21600s (360.0m) | **90** vs `120` | `sheep_feed` | 20.00 / *(Thiếu)* / *(Thiếu)* | +70.00 / *(Thiếu)* | **0.19** | *(Thiếu)* | **0.69** | **THIẾU DỮ LIỆU:** Thiếu `sheep_feed` trong `recipes.json`, thiếu `sheep_pasture` trong `buildings.json`, lệch giá (`90` vs `120`) |

---

### 2.4. Chuỗi Cá & Câu cá (`data/fishes.json` — 7 loài)

| ID Cá | Tên | Lv | Mồi yêu cầu (`required_lure_id`) | Cooldown (`fishes.json`) | Giá bán (`fishes.json` vs `items.json`) | Giá cơ hội mồi câu (`recipes.json`) | Lãi (Mồi free / Trừ giá mồi) | **Lãi/phút (Mồi free)** | **Lãi/phút (Trừ giá mồi)** | Đánh giá / Cờ bất thường |
|---|---|---:|---|---|---|---|---|---:|---:|---|
| `fish_carp` | Cá Chép | 4 | `red_lure` | **30s** (0.5m) | 25 / 25 | 20 | +25 / +5 | **50.00** | **10.00** | **BẤT THƯỜNG:** `cooldown=30s<60s`, `Lãi/phút = 50.00 > 5.0` |
| `fish` | Cá Tươi | 4 | `red_lure` | **30s** (0.5m) | 25 / 25 | 20 | +25 / +5 | **50.00** | **10.00** | **BẤT THƯỜNG:** `cooldown=30s<60s`, `Lãi/phút = 50.00 > 5.0`, trùng vai trò với `fish_carp` |
| `golden_trout` | Cá Hồi Hoàng Kim | 10 | `gold_lure` | 14400s (240.0m) | 240 / *(Thiếu)* | 60 | +240 / +180 | **1.00** | **0.75** | **THIẾU TRONG `items.json`** (`items.json` lại có `fish_golden_koi` giá 150, Lv 8) |
| `catfish` | Cá Trê Khổng Lồ | 8 | `green_lure` | 9000s (150.0m) | 110 / *(Thiếu)* | 35 | +110 / +75 | **0.73** | **0.50** | **THIẾU TRONG `items.json`** |
| `salmon` | Cá Hồi Đỏ Đại Dương | 6 | `green_lure` | 7200s (120.0m) | 75 / *(Thiếu)* | 35 | +75 / +40 | **0.62** | **0.33** | **THIẾU TRONG `items.json`** |
| `lake_trout` | Cá Hồi Hồ | 5 | `red_lure` | 5400s (90.0m) | 45 / *(Thiếu)* | 20 | +45 / +25 | **0.50** | **0.28** | **THIẾU TRONG `items.json`** |
| `smallmouth_bass` | Cá Vược Miệng Nhỏ | 4 | `red_lure` | 3600s (60.0m) | 28 / *(Thiếu)* | 20 | +28 / +8 | **0.47** | **0.13** | **THIẾU TRONG `items.json`** (`items.json` lại có `fish_bass` giá 35, Lv 4) |

---

### 2.5. Tổng hợp Công trình & Chi phí xây dựng (`data/buildings.json` — 20 công trình)

| ID Công trình | Tên | Phân loại (`type`) | Lv mở khóa | Kích thước | `cost_gold` | `cost_coins` (Trường thừa) | `build_time_seconds` | `attraction_score` | Ghi chú kiểm toán |
|---|---|---|---:|---|---:|---:|---:|---:|---|
| `field_plot` | Ô Ruộng | `field` | 1 | 1×1 | 1 | — | 0s | 1 | OK |
| `path_tile` | Đường Lát Gạch | `path` | 1 | 1×1 | 5 | — | 0s | 1 | OK |
| `feed_mill` | Máy Nghiền Cám | `production` | 1 | 3×3 | 10 | — | 5s | 5 | OK |
| `chicken_coop` | Chuồng Gà | `pen` (`chicken`) | 1 | 3×3 | 20 | — | 0s | 5 | `capacity: 6` (nhưng `AnimalPen.gd` spawn 3 con) |
| `roadside_shop` | Sạp Hàng Ven Đường | `commercial` | 1 | 3×3 | 0 | — | 0s | 15 | OK |
| `bakery` | Lò Bánh Mì | `production` | 2 | 3×3 | 20 | — | 10s | 8 | OK |
| `flower_bed` | Bồn Hoa Rực Rỡ | `decor` | 2 | 1×1 | **25** | **20** | 0s | 6 | **Lệch 2 trường giá:** `cost_gold=25` vs `cost_coins=20` |
| `wooden_bench` | Ghế Gỗ Nghỉ Chân | `decor` | 2 | 1×1 | 15 | 15 | 0s | 4 | Dư trường `cost_coins=15` |
| `decor_picnic_table` | Bàn Picnic Đồng Quê | `decor` | 3 | 2×2 | **120** | **60** | 0s | 25 | **Lệch 2 trường giá:** `cost_gold=120` vs `cost_coins=60` |
| `lure_workbench` | Bàn Chế Tạo Mồi Câu | `production` | 4 | 2×2 | 80 | — | 60s | 10 | Có trong `buildings.json` nhưng cần kiểm tra menu xây dựng |
| `fishing_spot` | Bãi Câu Cá Ven Sông | `fishing` | 4 | 3×3 | 60 | — | 0s | 25 | OK |
| `duck_pond` | Hồ Vịt Trời Tắm Mát | `decor` | 4 | 3×3 | **180** | **90** | 0s | 35 | **Lệch 2 trường giá:** `cost_gold=180` vs `cost_coins=90` |
| `fountain` | Đài Phun Nước Cổ Kính | `decor` | 5 | 2×2 | **150** | **80** | 0s | 30 | **Lệch 2 trường giá:** `cost_gold=150` vs `cost_coins=80` |
| `windmill` | Cối Xay Gió Hà Lan | `decor` | 5 | 3×3 | **250** | **120** | 0s | 40 | **Lệch 2 trường giá:** `cost_gold=250` vs `cost_coins=120` |
| `cow_pasture` | Đồng Cỏ Bò | `pen` (`cow`) | 6 | 3×3 | 50 | — | 10s | 10 | `capacity: 5` |
| `dairy` | Xưởng Sữa | `production` | 6 | 3×3 | 50 | — | 30s | 12 | Mô tả ghi làm "bơ, phô mai và kem" nhưng `cream` chưa có công thức |
| `juice_stand` | Quầy Nước Pha Chế | `production` | 6 | 3×3 | 60 | — | 30s | 8 | OK |
| `mini_zoo` | Khu Sở Thú Ngựa & Lừa | `decor` | 8 | 3×3 | **200** | **100** | 60s | 20 | **Lệch 2 trường giá:** `cost_gold=200` vs `cost_coins=100` |
| `cake_oven` | Lò Bánh Ngọt | `production` | 9 | 3×3 | 120 | — | 45s | 6 | OK |
| `pig_pen` | Chuồng Heo | `pen` (`pig`) | 10 | 3×3 | 60 | — | 30s | 12 | `capacity: 5` |
| *(Thiếu)* `sheep_pasture` | *(Chuồng Cừu)* | `pen` (`sheep`) | 16 | — | *(Thiếu)* | — | *(Thiếu)* | — | **THIẾU DỮ LIỆU:** Được tham chiếu bởi `sheep` trong `animals.json` nhưng không tồn tại trong `buildings.json` |

---

## 3. Danh sách đầy đủ các mục bất thường & Lệch chuẩn SSOT

### 3.1. Nhóm bất thường về ngưỡng Kinh tế & Thời gian (Theo tiêu chí Prompt 2A)
1. **Lợi nhuận/phút `> 5.0` (4 mục hiện tại; ban đầu có 5 mục trước khi sửa `sanctuary_feed`):**
   - *(Đã sửa)* `sanctuary_feed` (recipe): ban đầu **`195.00`** / **`175.00 vàng/phút`** ở `12s`, sau khi sửa về `1200s` còn **`1.95`** / **`1.75 vàng/phút`** (đạt chuẩn).
   - `fish_carp` (fish): **`50.00 vàng/phút`** (mồi free) / **`10.00 vàng/phút`** (trừ giá cơ hội mồi) do `cooldown_seconds = 30s`.
   - `fish` (fish): **`50.00 vàng/phút`** (mồi free) / **`10.00 vàng/phút`** (trừ giá cơ hội mồi) do `cooldown_seconds = 30s`.
   - `sunflower` (crop): **`6.00 vàng/phút`** (tính theo doanh thu gộp Gross 2 bông / 4 phút; nếu trừ 1 hạt tái canh thì còn `3.00 vàng/phút`).
   - `rose` (crop): **`5.33 vàng/phút`** (tính theo doanh thu gộp Gross 2 bông / 6 phút; nếu trừ 1 hạt tái canh thì còn `2.67 vàng/phút`). *(Lưu ý: `lavender` đạt đúng `5.00 vàng/phút` Gross và `2.50 vàng/phút` Net).*
2. **Lợi nhuận/phút `< 0.1` (2 mục):**
   - `apple_seed` (crop): **`0.00 vàng/phút`** trong `crops.json` (`base_price = 0`, `can_sell = false`, `harvest_yield = 1`).
   - `mango_seed` (crop): **`0.00 vàng/phút`** trong `crops.json` (`base_price = 0`, `can_sell = false`, `harvest_yield = 1`).
   - *(Ngoài ra, nếu xảy ra lỗi `ProductionMachine` chỉ trả 1 món trước Phase 1, cả 3 loại cám `chicken_feed`, `cow_feed`, `pig_feed` đều bị **lợi nhuận âm**: `-1.20`, `-1.30`, `-0.60 vàng/phút`).*
3. **Thời gian `< 60 giây` (4 mục hiện tại; ban đầu có 5 mục trước khi sửa `sanctuary_feed`):**
   - *(Đã sửa)* `sanctuary_feed` (`recipes.json`): đã sửa từ `12s` $\rightarrow$ `1200s`.
   - `apple_seed` (`crops.json` & `items.json`): `growth_time_seconds = 15s`.
   - `mango_seed` (`crops.json` & `items.json`): `growth_time_seconds = 15s`.
   - `fish_carp` (`fishes.json`): `cooldown_seconds = 30s`.
   - `fish` (`fishes.json`): `cooldown_seconds = 30s`.
   - *(Lưu ý thêm: toàn bộ 15 cây trồng trong `items.json` đang có `growth_time_seconds` từ `10s` đến `50s`, tất cả đều `< 60s`).*
4. **Nguyên liệu rỗng (`ingredients = {}`) nhưng có doanh thu (3 mục):**
   - `red_lure` (`base_price = 20`, `craft_time = 5400s`).
   - `green_lure` (`base_price = 35`, `craft_time = 7200s`).
   - `gold_lure` (`base_price = 60`, `craft_time = 10800s`).

---

### 3.2. Danh sách 15 ID trùng lặp có giá trị khác nhau giữa `crops.json` và `items.json`

Do `DataManager.get_item_base_price()` ưu tiên đọc `items.json` trước `crops.json`, mọi sự lệch giá dưới đây trực tiếp làm sai lệch giá bán nông sản và giá vốn chế biến:

| STT | ID | Trường bị lệch | Giá trị trong `crops.json` (SSOT) | Giá trị trong `items.json` | Hệ quả |
|---:|---|---|---:|---:|---|
| 1 | `wheat` | `growth_time_seconds` | **180s** | **10s** | Lệch 18 lần thời gian sinh trưởng |
| 2 | `corn` | `base_price`, `growth_time_seconds` | **9 vàng**, **480s** | **7 vàng**, **20s** | Làm lệch vốn của `chicken_feed`, `cow_feed`, `corn_bread`, `sanctuary_feed`, `item_grilled_fish` |
| 3 | `tomato` | `growth_time_seconds` | **240s** | **25s** | Lệch thời gian |
| 4 | `carrot` | `growth_time_seconds` | **300s** | **30s** | Lệch thời gian |
| 5 | `strawberry` | `growth_time_seconds` | **360s** | **35s** | Lệch thời gian |
| 6 | `pumpkin` | `growth_time_seconds` | **600s** | **40s** | Lệch thời gian |
| 7 | `soybean` | `growth_time_seconds` | **1200s** | **45s** | Lệch thời gian |
| 8 | `sugarcane` | `growth_time_seconds` | **1800s** | **50s** | Lệch thời gian |
| 9 | `apple` | `base_price`, `growth_time_seconds` | **24 vàng**, **900s** | **15 vàng**, **25s** | Làm lệch mạnh vốn của `apple_juice` (30 vs 48) |
| 10 | `mango` | `base_price`, `growth_time_seconds` | **36 vàng**, **1200s** | **22 vàng**, **30s** | Làm lệch mạnh vốn của `mango_smoothie` (72 vs 100) |
| 11 | `apple_seed` | `base_price`, `can_sell` | **0 vàng**, `can_sell: false` | **8 vàng**, *(thiếu `can_sell`)* | `DataManager.get_item_base_price("apple_seed")` trả về 8 thay vì 0 |
| 12 | `mango_seed` | `base_price`, `can_sell` | **0 vàng**, `can_sell: false` | **10 vàng**, *(thiếu `can_sell`)* | `DataManager.get_item_base_price("mango_seed")` trả về 10 thay vì 0 |
| 13 | `sunflower` | `growth_time_seconds` | **240s** | **25s** | Lệch thời gian |
| 14 | `rose` | `growth_time_seconds` | **360s** | **35s** | Lệch thời gian |
| 15 | `lavender` | `growth_time_seconds` | **480s** | **45s** | Lệch thời gian |

---

### 3.3. Lệch giá và lệch ID giữa các file khác (`animals.json`, `fishes.json`, `recipes.json`, `items.json`)

| Nhóm | Thực thể / ID | File 1 | File 2 | Chi tiết bất đồng bộ |
|---|---|---|---|---|
| **Vật nuôi vs Sản phẩm** | `chicken` / `egg` | `animals.json`: `base_price = 10` | `items.json`: `egg.base_price = 12` | Giá trong `animals.json` (10) khác giá `egg` (12) |
| **Vật nuôi vs Sản phẩm** | `cow` / `milk` | `animals.json`: `base_price = 30` | `items.json`: `milk.base_price = 28` | Giá trong `animals.json` (30) khác giá `milk` (28) |
| **Vật nuôi vs Sản phẩm** | `pig` / `bacon` | `animals.json`: `base_price = 80` | `items.json`: `bacon.base_price = 65` | Giá trong `animals.json` (80) khác giá `bacon` (65) |
| **Vật nuôi vs Sản phẩm** | `sheep` / `wool` | `animals.json`: `base_price = 120` | `items.json`: `wool.base_price = 90` | Giá trong `animals.json` (120) khác giá `wool` (90) |
| **Mồi câu** | `red_lure` vs `bait_red` | `recipes.json`: `red_lure` (`base_price = 20`) | `items.json`: `bait_red` (`base_price = 15`) | Lệch cả tên ID lẫn giá bán (20 vs 15) |
| **Mồi câu** | `green_lure` vs `bait_blue` | `recipes.json`: `green_lure` (`base_price = 35`) | `items.json`: `bait_blue` (`base_price = 25`) | Lệch cả tên ID lẫn giá bán (35 vs 25) |
| **Mồi câu** | `gold_lure` vs `bait_gold` | `recipes.json`: `gold_lure` (`base_price = 60`) | `items.json`: `bait_gold` (`base_price = 50`) | Lệch cả tên ID lẫn giá bán (60 vs 50) |
| **Cá** | `smallmouth_bass` vs `fish_bass` | `fishes.json`: `smallmouth_bass` (`28 vàng`, Lv 4) | `items.json`: `fish_bass` (`35 vàng`, Lv 4) | Lệch cả ID lẫn giá bán |
| **Cá** | `golden_trout` vs `fish_golden_koi` | `fishes.json`: `golden_trout` (`240 vàng`, Lv 10) | `items.json`: `fish_golden_koi` (`150 vàng`, Lv 8) | Lệch ID, cấp mở khóa và giá bán |
| **Cá** | `lake_trout`, `salmon`, `catfish` | Có trong `fishes.json` (45, 75, 110 vàng) | **Không có** trong `items.json` | Thiếu định nghĩa trong `items.json` |
| **Bánh quy** | `butter_cookie` vs `cookie` | `recipes.json`: chỉ có `butter_cookie` (`150 vàng`) | `items.json`: có cả `cookie` (`150`) và `butter_cookie` (`150`) | Trùng lặp 2 mục cho cùng một vật phẩm; `daily_newspaper.gd` dùng `cookie` giá `45` |
| **Alias trùng trong `items.json`** | `fish_pie`, `grilled_fish`, `herbal_tea`, `bacon_eggs` | `items.json` có cả key có tiền tố `item_` và key không tiền tố | `recipes.json` chỉ dùng key có tiền tố `item_` | 4 cặp key bị lặp đúp trong `items.json` (dòng 403–474) |

---

### 3.4. Bảng đối chiếu giá hardcode trong `scripts/systems/daily_newspaper.gd` (`GOODS_CATALOG`)

Trong [`scripts/systems/daily_newspaper.gd`](file:///d:/HayDayOffline/scripts/systems/daily_newspaper.gd#L23-L48), 15/17 mặt hàng có `base_price` hardcode lệch với JSON:

| ID trong `GOODS_CATALOG` | Tên hiển thị | Giá hardcode (`daily_newspaper.gd`) | Giá trong `items.json` | Giá trong `crops.json` / `recipes.json` | Độ lệch |
|---|---|---:|---:|---:|---|
| `wheat` | Lúa mì | **4** | 3 | 3 | +1 vàng |
| `corn` | Bắp ngô | **6** | 7 | 9 | -1 đến -3 vàng |
| `carrot` | Cà rốt | 8 | 8 | 8 | Khớp |
| `tomato` | Cà chua | **10** | 9 | 9 | +1 vàng |
| `strawberry` | Dâu tây | **14** | 12 | 12 | +2 vàng |
| `apple` | Táo đỏ | **16** | 15 | 24 | +1 / -8 vàng |
| `chicken_feed` | Cám Gà | **8** | 7 | 7 | +1 vàng |
| `cow_feed` | Cám Bò | **12** | 14 | 14 | -2 vàng |
| `pig_feed` | Cám Heo | **10** | 14 | 14 | -4 vàng |
| `milk` | Sữa bò tươi | **24** | 28 | — (`cow=30`) | -4 vàng |
| `egg` | Trứng gà | **16** | 12 | — (`chicken=10`) | +4 vàng |
| `bread` | Bánh mì ổ | **28** | 21 | 21 | +7 vàng |
| `cookie` | Bánh quy bơ | **45** | **150** | **150** (`butter_cookie`) | **-105 vàng (Nghiêm trọng)** |
| `cream_cake` | Bánh kem tươi | **80** | **260** | **260** | **-180 vàng (Nghiêm trọng)** |
| `fish_carp` | Cá chép sông | **35** | 25 | 25 (`fishes.json`) | +10 vàng |
| `sanctuary_feed` | Bó Cỏ Dinh Dưỡng | **75** | **35** | **35** | +40 vàng (Gấp đôi giá gốc) |
| `puzzle_piece` | Mảnh Ghép Sở Thú | **260** | **100** | — | +160 vàng |

---

### 3.5. Danh sách các trường dữ liệu bị thiếu (`Missing Data`)

1. **`seed_cost` trong `data/crops.json` (và `data/items.json`):** Không có trường `seed_cost` cho bất kỳ cây trồng nào. Hiện `FieldPlot.plant()` trừ 1 nông sản từ kho Silo làm hạt giống (hoặc cấp miễn phí Anti-Softlock cho `wheat`/`corn`).
2. **Công thức `sheep_feed` trong `data/recipes.json`:** Có vật phẩm `sheep_feed` trong `items.json` (giá 20, Lv 16) và `sheep` trong `animals.json` yêu cầu `feed_item_id: "sheep_feed"`, nhưng **không có công thức chế biến** trong `recipes.json`.
3. **Công trình `sheep_pasture` trong `data/buildings.json`:** `sheep` trong `animals.json` yêu cầu `pen_building_id: "sheep_pasture"`, nhưng **không tồn tại** `sheep_pasture` trong `buildings.json`.
4. **Công trình chế biến `wool` (Lông Cừu):** `wool` (`items.json` dòng 191, giá 90, Lv 16) không được dùng làm nguyên liệu cho bất kỳ công thức nào trong `recipes.json`.
5. **Công thức `cream` (Kem Tươi) trong `data/recipes.json`:** `cream` có trong `items.json` (dòng 255, giá 45, Lv 6) và mô tả của `dairy` trong `buildings.json` (dòng 206) ghi *"Chế biến sữa tươi thành bơ, phô mai và kem béo ngậy"*, nhưng `recipes.json` **không có công thức** cho `cream` (và `cream_cake` hiện cũng chỉ dùng `strawberry + egg + milk` chứ không dùng `cream`).
6. **5 loài cá thiếu trong `data/items.json`:** `smallmouth_bass`, `lake_trout`, `salmon`, `catfish`, `golden_trout` có trong `fishes.json` nhưng không có trong `items.json`.
7. **3 mồi câu thiếu ID chuẩn trong `data/items.json`:** `red_lure`, `green_lure`, `gold_lure` có trong `recipes.json` và `fishes.json` nhưng không có trong `items.json` (bị đặt lệch thành `bait_red`, `bait_blue`, `bait_gold`).

---

## 4. Tóm tắt số liệu bàn giao Phase 2A

- **Đường dẫn script:** [`d:\HayDayOffline\tools\economy_report.py`](file:///d:/HayDayOffline/tools/economy_report.py)
- **Đường dẫn CSV:** [`d:\HayDayOffline\docs\economy_report.csv`](file:///d:/HayDayOffline/docs/economy_report.csv)
- **Đường dẫn báo cáo Markdown:** [`d:\HayDayOffline\docs\economy_report.md`](file:///d:/HayDayOffline/docs/economy_report.md)
- **Tổng số dòng trong CSV:** `47` dòng (`1` dòng tiêu đề + `46` dòng dữ liệu: `20` recipes, `15` crops, `4` animals, `7` fishes).
- **Tổng số dòng có cờ bất thường (`anomalies != OK`):** `36 / 46` dòng.
- **Tổng số ID trùng lặp nhưng lệch giá trị giữa các file JSON:** `15` ID trực tiếp (15/15 mục giữa `crops.json` và `items.json`) + `12` cặp lệch ID/giá chéo giữa `animals.json`, `recipes.json`, `fishes.json` và `items.json`.
