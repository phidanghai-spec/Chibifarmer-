# BÁO CÁO KIỂM TOÁN DỮ LIỆU GAME (DATA AUDIT & SINGLE SOURCE OF TRUTH)

- **Dự án:** HayDay Offline (`D:\HayDayOffline`) — Godot 4.7.2, GDScript 2.0
- **Phạm vi kiểm toán:**
  - `data/crops.json`
  - `data/items.json`
  - `data/animals.json`
  - `data/buildings.json`
  - `data/recipes.json`
  - `scripts/core/data_manager.gd` *(kèm đối chiếu nhanh nơi tiêu thụ dữ liệu trực tiếp trong code để làm rõ tác động thực tế)*
- **Trạng thái:** Chỉ đọc & lập báo cáo, **chưa chỉnh sửa bất kỳ file cấu hình hoặc mã nguồn nào**.

---

## 1. TỔNG QUAN NGUYÊN NHÂN GÂY LỆCH DỮ LIỆU HIỆN TẠI

Qua kiểm tra chi tiết `scripts/core/data_manager.gd` và 5 file JSON trên:

1. **Trùng lặp thực thể giữa `items.json` và các bảng chuyên biệt (`crops.json`, `recipes.json`, `fishes.json`):**
   - Toàn bộ 15 mục trong `crops.json` đều bị nhân bản trong `items.json` với thông số `growth_time_seconds` và `base_price` khác nhau.
   - Các món chế biến trong `recipes.json` lặp lại trường `base_price` và `unlock_level` trong `items.json`, đồng thời phát sinh ID trùng/lệch (`cookie` vs `butter_cookie`, `bait_*` vs `*_lure`, bộ đôi `item_*` vs không `item_*`).
2. **Thứ tự ưu tiên đọc ngược nhau trong `DataManager`:**
   - `DataManager.get_crop(crop_id)` đọc **chỉ `crops.json`** (khiến `FieldPlot` lấy `growth_time_seconds` dài 180s–1800s).
   - `DataManager.get_item_base_price(item_id)` và `DataManager.get_item_storage_type(item_id)` lại ưu tiên **`items.json` trước**, sau đó mới fallback sang `crops.json` $\rightarrow$ `recipes.json` $\rightarrow$ `fishes.json` (khiến mọi chỉnh sửa giá trong `crops.json` hoặc `recipes.json` bị `items.json` che khuất ngầm).
   - `DataManager` **không cung cấp** hàm truy vấn `unlock_level` thống nhất; các hệ thống khác như `LevelProgressionManager` và `UIHud` tự hardcode bảng cấp độ riêng nên dẫn đến lệch mốc mở khóa.
3. **Runtime code bỏ qua một phần dữ liệu JSON:**
   - `ProductionMachine` (`scripts/entities/production_machine.gd`) ép trần `mini(craft_time_seconds, 60)` (tối đa 60 giây), đồng thời hardcode `add_item(..., 1)` và `add_xp(3)` thay vì dùng `produce_count` và `xp_reward` của `recipes.json`.
   - `AnimalPen` (`scripts/entities/animal_pen.gd`) hardcode `duration = 15` giây, bỏ qua `produce_time_seconds` trong `animals.json` (1200s–21600s).

---

## 2. BẢNG LIỆT KÊ TOÀN BỘ CHỖ BỊ LỆCH DỮ LIỆU

### 2.1. Độ lệch Thời Gian Sinh Trưởng / Sản Xuất / Chế Biến

> **Quy chuẩn đề xuất:** Theo định hướng offline dễ chơi & dễ kiểm thử của dự án (`GEMINI.md`: Lúa mì 10s, Ngô 20s), sử dụng **nhịp Cozy Nhanh có phân bậc rõ ràng** (10s–60s cho cây trồng/cám/món cơ bản, 20s–90s cho vật nuôi & món cao cấp), thay vì giữ mức idle 30 phút–6 giờ vốn đang bị code cap lại một cách thiếu đồng bộ.

| Tên | File | Giá trị hiện tại | Giá trị đề xuất |
| :--- | :--- | :--- | :--- |
| Lúa Mì (`wheat`) | `data/crops.json` | `growth_time_seconds = 180` | `10` (đồng bộ làm 1 nguồn ở `crops.json`) |
| Lúa Mì (`wheat`) | `data/items.json` | `growth_time_seconds = 10` | Xóa khỏi `items.json` (đọc từ `crops.json`) |
| Ngô (`corn`) | `data/crops.json` | `growth_time_seconds = 480` | `20` |
| Ngô (`corn`) | `data/items.json` | `growth_time_seconds = 20` | Xóa khỏi `items.json` |
| Cà Chua (`tomato`) | `data/crops.json` | `growth_time_seconds = 240` *(nhanh hơn Ngô 480s và Cà Rốt 300s dù cấp sau/bằng)* | `25` |
| Cà Chua (`tomato`) | `data/items.json` | `growth_time_seconds = 25` | Xóa khỏi `items.json` |
| Cà Rốt (`carrot`) | `data/crops.json` | `growth_time_seconds = 300` | `30` |
| Cà Rốt (`carrot`) | `data/items.json` | `growth_time_seconds = 30` | Xóa khỏi `items.json` |
| Dâu Tây (`strawberry`) | `data/crops.json` | `growth_time_seconds = 360` | `35` |
| Dâu Tây (`strawberry`) | `data/items.json` | `growth_time_seconds = 35` | Xóa khỏi `items.json` |
| Bí Đỏ (`pumpkin`) | `data/crops.json` | `growth_time_seconds = 600` | `40` |
| Bí Đỏ (`pumpkin`) | `data/items.json` | `growth_time_seconds = 40` | Xóa khỏi `items.json` |
| Đậu Nành (`soybean`) | `data/crops.json` | `growth_time_seconds = 1200` | `45` |
| Đậu Nành (`soybean`) | `data/items.json` | `growth_time_seconds = 45` | Xóa khỏi `items.json` |
| Mía Đường (`sugarcane`) | `data/crops.json` | `growth_time_seconds = 1800` | `50` |
| Mía Đường (`sugarcane`) | `data/items.json` | `growth_time_seconds = 50` | Xóa khỏi `items.json` |
| Táo Đỏ (`apple`) | `data/crops.json` | `growth_time_seconds = 900` | `25` *(thu hoạch cây ăn quả lâu năm)* |
| Táo Đỏ (`apple`) | `data/items.json` | `growth_time_seconds = 25` | Xóa khỏi `items.json` |
| Xoài Chín (`mango`) | `data/crops.json` | `growth_time_seconds = 1200` | `30` |
| Xoài Chín (`mango`) | `data/items.json` | `growth_time_seconds = 30` | Xóa khỏi `items.json` |
| Hoa Hướng Dương (`sunflower`) | `data/crops.json` | `growth_time_seconds = 240` | `25` |
| Hoa Hướng Dương (`sunflower`) | `data/items.json` | `growth_time_seconds = 25` | Xóa khỏi `items.json` |
| Hoa Hồng Đỏ (`rose`) | `data/crops.json` | `growth_time_seconds = 360` | `35` |
| Hoa Hồng Đỏ (`rose`) | `data/items.json` | `growth_time_seconds = 35` | Xóa khỏi `items.json` |
| Hoa Oải Hương (`lavender`) | `data/crops.json` | `growth_time_seconds = 480` | `45` |
| Hoa Oải Hương (`lavender`) | `data/items.json` | `growth_time_seconds = 45` | Xóa khỏi `items.json` |
| Gà (`chicken`) | `data/animals.json` | `produce_time_seconds = 1200` *(code `animal_pen.gd` ép cứng 15s)* | `15` *(bỏ hardcode trong code để đọc JSON)* |
| Bò Sữa (`cow`) | `data/animals.json` | `produce_time_seconds = 3600` *(code ép cứng 15s)* | `30` |
| Heo (`pig`) | `data/animals.json` | `produce_time_seconds = 7200` *(code ép cứng 15s)* | `45` |
| Cừu (`sheep`) | `data/animals.json` | `produce_time_seconds = 21600` *(6 giờ; code ép cứng 15s)* | `60` |
| Cám Gà (`chicken_feed`) | `data/recipes.json` | `craft_time_seconds = 300` *(code `production_machine.gd` cắt trần 60s)* | `10` *(bỏ cap 60s trong code để đọc JSON)* |
| Bánh Mì Nóng (`bread`) | `data/recipes.json` | `craft_time_seconds = 300` | `15` |
| Cám Bò (`cow_feed`) | `data/recipes.json` | `craft_time_seconds = 600` | `20` |
| Bơ Sữa (`butter`) | `data/recipes.json` | `craft_time_seconds = 1200` | `25` |
| Cám Heo (`pig_feed`) | `data/recipes.json` | `craft_time_seconds = 1200` | `25` |
| Bánh Mì Ngô (`corn_bread`) | `data/recipes.json` | `craft_time_seconds = 1800` | `30` |
| Cá Nướng Xiên Que (`item_grilled_fish`) | `data/recipes.json` | `craft_time_seconds = 900` | `25` |
| Bánh Pie Cá Nướng (`item_fish_pie`) | `data/recipes.json` | `craft_time_seconds = 1200` | `30` |
| Nước Mía Đá (`sugarcane_juice`) | `data/recipes.json` | `craft_time_seconds = 1800` | `25` |
| Trà Thảo Mộc Mật Ong (`item_herbal_tea`) | `data/recipes.json` | `craft_time_seconds = 1800` | `30` |
| Nước Ép Táo (`apple_juice`) | `data/recipes.json` | `craft_time_seconds = 2400` | `30` |
| Trứng Chiên Thịt Xông Khói (`item_bacon_eggs`) | `data/recipes.json` | `craft_time_seconds = 2400` | `35` |
| Sinh Tố Xoài (`mango_smoothie`) | `data/recipes.json` | `craft_time_seconds = 3000` | `35` |
| Bánh Quy Bơ (`butter_cookie`) | `data/recipes.json` | `craft_time_seconds = 3600` | `40` |
| Phô Mai (`cheese`) | `data/recipes.json` | `craft_time_seconds = 3600` | `45` |
| Bánh Kem Dâu (`cream_cake`) | `data/recipes.json` | `craft_time_seconds = 5400` | `55` |
| Mồi Câu Đỏ (`red_lure`) | `data/recipes.json` | `craft_time_seconds = 5400` | `30` |
| Mồi Câu Xanh (`green_lure`) | `data/recipes.json` | `craft_time_seconds = 7200` | `45` |
| Mồi Câu Vàng Kim (`gold_lure`) | `data/recipes.json` | `craft_time_seconds = 10800` | `60` |
| Bó Cỏ Dinh Dưỡng (`sanctuary_feed`) | `data/recipes.json` | `craft_time_seconds = 12` *(lạc nhịp hẳn so với phần còn lại của `recipes.json` 300–10800s)* | `20` |

---

### 2.2. Độ lệch Giá (`base_price`, `cost_gold`, `cost_coins`) & Tỷ suất Kinh tế

> Lưu ý: Với công thức chế biến và chăn nuôi, `base_price` của sản phẩm đầu ra cần lớn hơn tổng `base_price` nguyên liệu đầu vào, đồng thời không được trùng khác giá giữa hai file JSON.

| Tên | File | Giá trị hiện tại | Giá trị đề xuất |
| :--- | :--- | :--- | :--- |
| Ngô (`corn`) | `data/crops.json` | `base_price = 9` | `7` *(khớp `items.json`, `DataManager` & `RiverSteamboat`)* |
| Ngô (`corn`) | `data/items.json` | `base_price = 7` | Xóa khỏi `items.json` (đọc từ `crops.json`) |
| Cà Rốt (`carrot`) vs Cà Chua (`tomato`) | `data/crops.json`, `data/items.json` | `carrot` (Lv 3) giá `8` < `tomato` (Lv 2) giá `9` | `tomato = 8` (Lv 2), `carrot = 10` (Lv 3) |
| Đậu Nành (`soybean`) & Mía Đường (`sugarcane`) | `data/crops.json`, `data/items.json` | `soybean` (Lv 5) giá `10`, `sugarcane` (Lv 7) giá `14` đều < `pumpkin` (Lv 4) giá `15` | `pumpkin = 12` (Lv 4), `soybean = 14` (Lv 5), `sugarcane = 16` (Lv 6) |
| Táo Đỏ (`apple`) | `data/crops.json` | `base_price = 24` | `20` *(bảo đảm `2 apple = 40` < `apple_juice = 65`)* |
| Táo Đỏ (`apple`) | `data/items.json` | `base_price = 15` *(đang ghi đè `24` qua `DataManager.get_item_base_price`)* | Xóa khỏi `items.json` |
| Xoài Chín (`mango`) | `data/crops.json` | `base_price = 36` | `30` |
| Xoài Chín (`mango`) | `data/items.json` | `base_price = 22` *(đang ghi đè `36` qua `DataManager.get_item_base_price`)* | Xóa khỏi `items.json` |
| Hạt Giống Táo (`apple_seed`) | `data/crops.json` | `base_price = 0`, `can_sell = false` | Giữ `base_price = 0, can_sell = false` ở `crops.json` |
| Hạt Giống Táo (`apple_seed`) | `data/items.json` | `base_price = 8` *(cho phép định giá bán vì `items.json` đè `crops.json`)* | Xóa khỏi `items.json` |
| Hạt Giống Xoài (`mango_seed`) | `data/crops.json` | `base_price = 0`, `can_sell = false` | Giữ `base_price = 0, can_sell = false` ở `crops.json` |
| Hạt Giống Xoài (`mango_seed`) | `data/items.json` | `base_price = 10` | Xóa khỏi `items.json` |
| Gà (`chicken`) vs Trứng Gà (`egg`) | `data/animals.json` vs `data/items.json` | `animals.json: chicken.base_price = 10`; `items.json: egg.base_price = 12` | Bỏ `base_price` khỏi `animals.json`; chuẩn hóa `egg = 12` ở `items.json` |
| Bò Sữa (`cow`) vs Sữa Bò Tươi (`milk`) | `data/animals.json` vs `data/items.json` | `animals.json: cow.base_price = 30`; `items.json: milk.base_price = 28` | Bỏ `base_price` khỏi `animals.json`; chuẩn hóa `milk = 28` ở `items.json` |
| Heo (`pig`) vs Thịt Xông Khói (`bacon`) | `data/animals.json` vs `data/items.json` | `animals.json: pig.base_price = 80`; `items.json: bacon.base_price = 65` | Bỏ `base_price` khỏi `animals.json`; chuẩn hóa `bacon = 65` ở `items.json` |
| Cừu (`sheep`) vs Lông Cừu (`wool`) | `data/animals.json` vs `data/items.json` | `animals.json: sheep.base_price = 120`; `items.json: wool.base_price = 90` | Bỏ `base_price` khỏi `animals.json`; chuẩn hóa `wool = 90` ở `items.json` |
| Mồi Câu Đỏ (`red_lure` / `bait_red`) | `data/recipes.json` vs `data/items.json` | `recipes.json: red_lure = 20` (`ingredients = {}`); `items.json: bait_red = 15` | Gộp thành `red_lure = 20` trong `items.json` (và thêm nguyên liệu vào công thức nếu cần) |
| Mồi Câu Xanh (`green_lure` / `bait_blue`) | `data/recipes.json` vs `data/items.json` | `recipes.json: green_lure = 35`; `items.json: bait_blue = 25` | Gộp thành `green_lure = 35` trong `items.json`, xóa `bait_blue` |
| Mồi Câu Vàng Kim (`gold_lure` / `bait_gold`) | `data/recipes.json` vs `data/items.json` | `recipes.json: gold_lure = 60`; `items.json: bait_gold = 50` | Gộp thành `gold_lure = 60` trong `items.json`, xóa `bait_gold` |
| Cám Gà (`chicken_feed`) | `data/recipes.json` & `data/items.json` | `base_price = 7`, `produce_count = 3` (tổng thu 21; nhưng `production_machine.gd` chỉ cộng `1` món -> lỗ so với giá 2 Lúa + 1 Ngô = 13) | Sửa code nhận `produce_count = 3` và giữ `base_price = 7` trong `items.json` (tổng 21 > 13) |
| Cám Bò (`cow_feed`) | `data/recipes.json` & `data/items.json` | `base_price = 14`, `produce_count = 3` (1 Ngô + 2 Đậu Nành = 27~35 -> với 3 bao = 42) | Sửa code nhận `produce_count = 3`; giữ `base_price = 15` trong `items.json` |
| Cám Heo (`pig_feed`) | `data/recipes.json` & `data/items.json` | `base_price = 14`, `produce_count = 3` (2 Cà Rốt + 1 Đậu Nành = 26~34 -> 3 bao = 42) | Sửa code nhận `produce_count = 3`; giữ `base_price = 15` trong `items.json` |
| Bánh Quy Bơ (`cookie` / `butter_cookie`) | `data/items.json` vs `data/recipes.json` | `items.json` có cả `cookie` (`150`) và `butter_cookie` (`150`); `daily_newspaper.gd` dùng `cookie` | Chỉ giữ ID chuẩn `butter_cookie = 150` trong `items.json` & `recipes.json`, bỏ `cookie` |
| Bốn món cá/trà/trứng bị đúp ID (`item_*` vs không `item_*`) | `data/items.json` vs `data/recipes.json` | `items.json` khai báo đúp cả `item_fish_pie` & `fish_pie` (55), `item_grilled_fish` & `grilled_fish` (52), `item_herbal_tea` & `herbal_tea` (140), `item_bacon_eggs` & `bacon_eggs` (150) | Chỉ giữ 1 ID chuẩn trùng `recipes.json` (bỏ `item_*` hoặc bỏ tên ngắn tùy chọn, ưu tiên thống nhất dùng tên ngắn không `item_` hoặc giữ `item_*` nếu đã gắn sprite) |
| Cá (`fish_bass`, `fish_golden_koi` vs `fishes.json`) | `data/items.json` vs `data/fishes.json` | `items.json` có `fish_bass = 35`, `fish_golden_koi = 150`; nhưng `fishes.json` chỉ có `smallmouth_bass = 28`, `lake_trout = 45`, `salmon = 75`, `catfish = 110`, `golden_trout = 240`, `fish_carp = 25`, `fish = 25` | Xóa `fish_carp`, `fish_bass`, `fish_golden_koi`, `fish` khỏi `items.json`; bổ sung `fish_bass`/`fish_golden_koi` hoặc chuẩn hóa thẳng trong `fishes.json` |
| Ô Ruộng (`field_plot`) | `data/buildings.json` vs `UIHud` | `buildings.json: cost_gold = 1` *(đang dùng ở `DragActionManager`)*; `UIHud.open_build_modal(): cost = 10` | `cost_gold = 10` ở `buildings.json` *(UIHud đọc từ `DataManager`)* |
| Máy Nghiền Cám (`feed_mill`) | `data/buildings.json` vs `UIHud` | `buildings.json: cost_gold = 10`; `UIHud: 80 + 2 plank + 1 bolt` | `cost_gold = 80`, `build_materials = {"mat_plank": 2, "mat_bolt": 1}` trong `buildings.json` |
| Lò Bánh Mì (`bakery`) | `data/buildings.json` vs `UIHud` | `buildings.json: cost_gold = 20`; `UIHud: 120 + 2 brick + 2 plank` | `cost_gold = 120`, `build_materials = {"mat_brick": 2, "mat_plank": 2}` trong `buildings.json` |
| Đồng Cỏ Bò (`cow_pasture` / `cow_pen`) | `data/buildings.json` vs `UIHud` | `buildings.json: cost_gold = 50`; `UIHud: 100 + 3 plank + 1 bolt` | Thống nhất ID `cow_pasture`, `cost_gold = 100`, `build_materials = {"mat_plank": 3, "mat_bolt": 1}` |
| Quầy Nước Pha Chế (`juice_stand`) | `data/buildings.json` vs `UIHud` | `buildings.json: cost_gold = 60`; `UIHud: 150 + 2 plank + 2 bolt + 2 brick` | `cost_gold = 150`, `build_materials = {"mat_plank": 2, "mat_bolt": 2, "mat_brick": 2}` |
| Lò Bánh Ngọt (`cake_oven`) | `data/buildings.json` vs `UIHud` | `buildings.json: cost_gold = 120`; `UIHud: 200 + 3 brick + 3 plank` | `cost_gold = 200`, `build_materials = {"mat_brick": 3, "mat_plank": 3}` |
| Decor có 2 loại tiền (`flower_bed`, `wooden_bench`, `fountain`, `mini_zoo`, `decor_picnic_table`, `duck_pond`, `windmill`) | `data/buildings.json` | Khai báo song song cả `cost_gold` và `cost_coins` (ví dụ `fountain`: `cost_gold: 150, cost_coins: 80`) trong khi chỉ có 1 nút mua | Chỉ định 1 loại chi phí rõ ràng (`cost_gold` hoặc `cost_coins`) cho từng hạng mục trong `buildings.json` |

---

### 2.3. Độ lệch Mốc Level Mở Khóa (`unlock_level`) & Lỗ hổng Phụ Thuộc

| Tên | File | Giá trị hiện tại | Giá trị đề xuất |
| :--- | :--- | :--- | :--- |
| Cám Gà (`chicken_feed`) | `data/recipes.json` & `data/items.json` | `unlock_level = 1`, nhưng nguyên liệu gồm `corn` (`unlock_level = 2`) | Hoặc đổi công thức thành `{"wheat": 3}` ở **Lv 1**, hoặc mở `corn` ở **Lv 1** / `chicken_feed` ở **Lv 2** *(đề xuất công thức Lv 1 chỉ dùng `wheat`)* |
| Nước Mía Đá (`sugarcane_juice`) | `data/recipes.json` & `data/items.json` | `unlock_level = 6` (`juice_stand = Lv 6`), nhưng nguyên liệu `sugarcane` lại mở ở `unlock_level = 7` | Đưa `sugarcane` về **`unlock_level = 6`** (đồng bộ với `LevelProgressionManager` Lv 6!) |
| Cà Chua (`tomato`) | `crops.json`/`items.json` vs `LevelProgressionManager` | JSON: `2` \| `LevelProgressionManager`: `8` | `4` *(để sau Cà Rốt Lv 3, tránh chồng chéo Ngô Lv 2)* |
| Cà Rốt (`carrot`) | `crops.json`/`items.json` vs `LevelProgressionManager` | JSON: `3` \| `LevelProgressionManager`: `3` | `3` (giữ nguyên) |
| Dâu Tây (`strawberry`) | `crops.json`/`items.json` vs `LevelProgressionManager` | JSON: `3` \| `LevelProgressionManager`: `10` | `8` *(khớp ngay trước `cake_oven` & `cream_cake` Lv 9!)* |
| Bí Đỏ (`pumpkin`) | `crops.json`/`items.json` vs `LevelProgressionManager` | JSON: `4` \| `LevelProgressionManager`: `16` | `5` *(hoặc `10`; cần khớp cả JSON và `LevelProgressionManager`)* |
| Đậu Nành (`soybean`) | `crops.json`/`items.json` vs `LevelProgressionManager` | JSON: `5` \| `LevelProgressionManager`: `4` | `4` *(mở trước `cow_pasture`/`cow_feed` Lv 6)* |
| Mía Đường (`sugarcane`) | `crops.json`/`items.json` vs `LevelProgressionManager` | JSON: `7` \| `LevelProgressionManager`: `6` | `6` *(mở cùng `juice_stand` & `sugarcane_juice`)* |
| Hoa Hướng Dương (`sunflower`) | `crops.json`/`items.json` vs `LevelProgressionManager` | JSON: `2` \| `LevelProgressionManager`: `7` | `7` |
| Hoa Hồng Đỏ (`rose`) | `crops.json`/`items.json` vs `LevelProgressionManager` | JSON: `3` \| `LevelProgressionManager`: `20` | `6` *(bắt buộc $\le 6$ vì `item_herbal_tea` dùng `rose` mở ở Lv 6!)* |
| Hoa Oải Hương (`lavender`) | `crops.json`/`items.json` vs `LevelProgressionManager` | JSON: `4` \| `LevelProgressionManager`: `14` | `14` |
| Táo Đỏ (`apple`) & Hạt Giống (`apple_seed`) | `crops.json`/`items.json` vs `LevelProgressionManager` | JSON: `1` \| `LevelProgressionManager`: `12` (`apple_tree`) | `5` hoặc `6` *(phải $\le 6$ vì `apple_juice` mở ở Lv 6! Hoặc dời `apple_juice` lên Lv 12)* |
| Xoài Chín (`mango`) & Hạt Giống (`mango_seed`) | `crops.json`/`items.json` vs `LevelProgressionManager` | JSON: `1` \| `LevelProgressionManager`: `22` (`mango_tree`) | `6` *(nếu `mango_smoothie` giữ ở Lv 6; nếu để `mango_tree` ở Lv 22 thì phải nâng `mango_smoothie` lên Lv 22)* |
| Trà Thảo Mộc (`item_herbal_tea`) | `data/recipes.json` & `data/items.json` | `unlock_level = 6`, cần `rose` | Đảm bảo `rose.unlock_level <= 6` và `beehive_tree` (sinh `honey`) mở tại $\le$ Lv 6 |
| Lò Bánh Mì (`bakery`) | `data/buildings.json` vs `LevelProgressionManager` & `UIHud` | `buildings.json: 2` (`bread = 2`) \| `LevelProgressionManager: 3` \| `UIHud: 3` | **`2`** (hoặc thống nhất **`3`** cho cả `bakery`, `bread`, `LevelProgressionManager`, `UIHud`) |
| Bãi Câu Cá (`fishing_spot`) & Cá (`fishes.json`, `items.json`) | `buildings.json`, `fishes.json`, `items.json` vs `LevelProgressionManager` | `buildings.json: 4`, `fishes.json: 4`, `recipes (item_fish_pie/grilled_fish): 4` \| `LevelProgressionManager: 10` | **`4`** (hoặc nâng cả cụm lên Lv 10 nếu muốn; Lv 4 hợp lý để mở câu cá sớm và dùng cá làm `item_fish_pie`) |
| Bàn Chế Tạo Mồi Câu (`lure_workbench`) | `data/buildings.json`, `data/recipes.json` | `buildings.json: 4`, có công thức nhưng thiếu trên `map_layout.json` & `UIHud` | `unlock_level = 4` (cùng cấp `fishing_spot`), đưa vào `open_build_modal()` |
| Đồng Cỏ Bò (`cow_pasture` / `cow_pen`) | `buildings.json`, `animals.json`, `recipes.json` vs `LevelProgressionManager` & `UIHud` | `animals.json: 6`, `buildings.json: 6`, `milk/cow_feed: 6` \| `LevelProgressionManager: 5` \| `UIHud: 3` | **`6`** thống nhất cho tất cả (`cow`, `cow_pasture`, `milk`, `cow_feed`, `dairy`, `butter`) |
| Xưởng Sữa (`dairy`) | `data/buildings.json`, `data/recipes.json` vs `UIHud` | `buildings.json: 6` (có `butter=6`, `cheese=8`), thiếu trong `UIHud` & `map_layout.json` | `unlock_level = 6`, đưa vào `open_build_modal()` |
| Kem Tươi (`cream`) | `data/items.json` vs `data/recipes.json` | `items.json: unlock_level = 6` (`base_price = 45`), **không có công thức** trong `recipes.json` | Bổ sung công thức `cream` vào `recipes.json` (`building_id: "dairy"`, `unlock_level: 6`, 1 `milk` -> 1 `cream`) |
| Quầy Nước Pha Chế (`juice_stand`) | `data/buildings.json` vs `LevelProgressionManager` & `UIHud` | `buildings.json: 6` \| `UIHud: 5` \| `LevelProgressionManager: 13` | **`6`** thống nhất trên toàn hệ thống |
| Lò Bánh Ngọt (`cake_oven`) | `data/buildings.json`, `recipes.json` vs `LevelProgressionManager` & `UIHud` | `buildings.json: 9`, `cream_cake: 9` \| `LevelProgressionManager: 8` \| `UIHud: 6` | **`9`** thống nhất trên toàn hệ thống |
| Chuồng Heo (`pig_pen`) | `buildings.json`, `animals.json` vs `LevelProgressionManager` & `UIHud` | `buildings.json: 10`, `animals.json: 10`, `bacon/pig_feed: 10` \| `LevelProgressionManager: 9` \| `UIHud`: thiếu | **`10`** thống nhất, đưa vào `open_build_modal()` |
| Chuồng Cừu (`sheep_pasture`) & Cám Cừu (`sheep_feed`) | `animals.json`, `items.json`, `buildings.json`, `recipes.json` | `animals.json` & `items.json` để `Lv 16`; `buildings.json` **thiếu `sheep_pasture`**; `recipes.json` **thiếu `sheep_feed`** | Bổ sung `sheep_pasture` (`unlock_level = 16`) vào `buildings.json` và công thức `sheep_feed` vào `recipes.json` |

---

### 2.4. Bất nhất Trong `scripts/core/data_manager.gd`

| Thành phần / Hàm | File | Hiện trạng hiện tại | Đề xuất xử lý |
| :--- | :--- | :--- | :--- |
| `get_item_base_price(item_id)` | `scripts/core/data_manager.gd` (dòng 186–197) | Kiểm tra `items.json` **trước**, che lấp `crops.json`, `recipes.json`, `fishes.json` | Mỗi ID chỉ tồn tại ở **1 file nguồn chuẩn**; hàm tra `crops` $\rightarrow$ `fishes` $\rightarrow$ `recipes` $\rightarrow$ `items` theo ranh giới không trùng lặp |
| `get_item_storage_type(item_id)` | `scripts/core/data_manager.gd` (dòng 94–107) | Kiểm tra `items.json` trước, lặp qua `recipes` thay vì tra theo key/index | Quy ước rõ `crops.json` = `"silo"`, `fishes.json`/`items.json` = `"barn"` (hỗ trợ override nếu có trường) |
| `get_building_name(building_id)` | `scripts/core/data_manager.gd` (dòng 199–213) | Hardcode chuỗi fallback (ví dụ `"juice_stand" -> "Quầy Nước"`, trong khi `buildings.json` là `"Quầy Nước Pha Chế"`) | Đưa `building_barn`, `building_silo`, `farmhouse`, `truck` vào `buildings.json`; xóa bảng `match` hardcode |
| `get_item_name(item_id)` | `scripts/core/data_manager.gd` (dòng 109–184) | Hardcode `match` thủ công 40+ dòng ưu tiên sau `items.json` | Đưa toàn bộ tên tiếng Việt chuẩn vào file JSON nguồn; `DataManager` chỉ xử lý alias chuyển tiếp (nếu cần tương thích save cũ) |
| Thiếu API `unlock_level` & chi phí xây dựng | `scripts/core/data_manager.gd` | Không có hàm `get_unlock_level()` hoặc `get_building_cost()`; `UIHud` & `LevelProgressionManager` tự hardcode | Thêm API chuẩn trên `DataManager` để toàn bộ UI, xây dựng và lên cấp đọc cùng một nguồn dữ liệu |

---

## 3. KIẾN TRÚC NGUỒN CHUẨN DUY NHẤT (SINGLE SOURCE OF TRUTH) ĐỀ XUẤT

Mỗi loại dữ liệu chỉ được định nghĩa **tại đúng 1 file**, tuyệt đối không nhân bản `growth_time_seconds`, `base_price` hay `unlock_level` qua file thứ hai:

| Loại dữ liệu | Nguồn chuẩn duy nhất (SSOT) | Các trường sở hữu độc quyền | Quy tắc dọn trùng lặp |
| :--- | :--- | :--- | :--- |
| **Cây trồng, Hoa & Cây ăn quả** | `data/crops.json` | `id`, `name`, `growth_time_seconds`, `harvest_yield`, `xp_reward`, `base_price`, `unlock_level`, `storage_type` (`"silo"`), `can_sell` | **Xóa** toàn bộ cây trồng, hoa và hạt giống khỏi `data/items.json` |
| **Vật nuôi chuồng trại** | `data/animals.json` | `id`, `name`, `pen_building_id`, `feed_item_id`, `produce_item_id`, `produce_time_seconds`, `produce_count`, `xp_reward`, `unlock_level`, `capacity`, `locked` | **Xóa** `base_price` và `storage_type` khỏi `animals.json` (vì sản phẩm thuộc `items.json`) |
| **Công trình, Xưởng, Chuồng & Decor** | `data/buildings.json` | `id`, `name`, `type`, `size`, `cost_gold`, `cost_coins`, `build_materials`, `build_time_seconds`, `unlock_level`, `attraction_score`, `queue_slots`, `is_walkable` | **Xóa** catalog hardcode trong `UIHud.open_build_modal()` và khớp `LevelProgressionManager` đọc từ `DataManager` |
| **Công thức chế biến** | `data/recipes.json` | `id`, `building_id`, `ingredients`, `produce_item_id`, `produce_count`, `craft_time_seconds`, `xp_reward`, `unlock_level` | **Xóa** `base_price`, `storage_type`, `name` trùng lặp với `items.json` khỏi `recipes.json` (lấy thông tin hàng hóa từ `items.json` qua `produce_item_id`) |
| **Cá & Tài nguyên thủy sản** | `data/fishes.json` | `id`, `name`, `required_lure_id`, `ring_difficulty`, `shrink_speed`, `wobble_speed`, `catch_time_window`, `weight_min_kg`, `weight_max_kg`, `xp_reward`, `base_price`, `cooldown_seconds`, `unlock_level`, `storage_type` (`"barn"`) | **Xóa** `fish`, `fish_carp`, `fish_bass`, `fish_golden_koi` khỏi `data/items.json` |
| **Vật phẩm nông sản chế biến, Cám, Mồi câu & Vật liệu** | `data/items.json` | `id`, `name`, `category`, `base_price`, `unlock_level`, `storage_type` (`"barn"`), `description` | Chỉ chứa: sản phẩm động vật (`egg`, `milk`, `bacon`, `wool`, `honey`), cám (`*_feed`, `sanctuary_feed`), đồ chế biến (`bread`, `butter`, ...), mồi câu (`*_lure`), vật liệu (`mat_*`), `puzzle_piece`. **Xóa sạch các bản sao cây, cá và alias trùng (`cookie`, `bait_*`, tên ngắn/dài đúp)** |
| **Tầng truy vấn trung tâm** | `scripts/core/data_manager.gd` | API thống nhất: `get_crop()`, `get_animal()`, `get_building()`, `get_recipe()`, `get_fish()`, `get_item()`, `get_item_base_price()`, `get_unlock_level()` | Bỏ mọi dữ liệu hardcode; bổ sung `ID_ALIASES` để chuyển đổi save cũ (`bait_red` $\rightarrow$ `red_lure`, `cookie` $\rightarrow$ `butter_cookie`) mà không tạo item rác |

