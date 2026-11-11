# THIẾT KẾ PHASE 2B (BƯỚC 1) — LẤP KHOẢNG CHỜ ĐẦU GAME & KHAY VIỆC NHỎ (TASK TRAY)

- **Dự án:** HayDay Offline (Chibi Farm) — Godot 4.7.2 Standard (`GL Compatibility`), GDScript 2.0 (100% Static Typing)
- **Tham chiếu:** `docs/HANDOVER.md` (Mục 3, Mục 8), `docs/decision_timing.md`, `GEMINI.md`
- **Trạng thái:** **BƯỚC 1 — TÀI LIỆU THIẾT KẾ (Chưa sửa code gameplay)** — Chờ chủ dự án / người nhận bàn giao xác nhận trước khi chuyển sang Bước 2.

---

## 1. MỤC TIÊU & NGUYÊN TẮC BẤT BIẾN

### 1.1. Bối cảnh vấn đề
Theo Quyết định thiết kế **D1 (`docs/decision_timing.md`)**, dự án đã chốt **Phương án B**: giữ nhịp thời gian chờ (idle) dài theo đúng dữ liệu JSON gốc (`data/crops.json`: 3–30 phút, `data/animals.json`: 20 phút–6 giờ, `data/recipes.json`: 5 phút–3 giờ).
Tuy nhiên, ở giai đoạn **Cấp 1 (Lv 1)** ngay sau khi hoàn tất 3 bước hướng dẫn (`OnboardingDirector`), khi người chơi gieo hết lúa mì (`wheat`: `180s` = 3 phút) hoặc ngô (`corn`: `480s` = 8 phút), người chơi sẽ rơi vào khoảng trống **3–8 phút không có việc gì để tương tác**. Đây là rủi ro lớn nhất đối với tỷ lệ giữ chân người chơi (Rủi ro **R4** trong `docs/HANDOVER.md`).

### 1.2. Nguyên tắc bất biến của Phase 2B
1. **KHÔNG rút ngắn timer gốc:** Tuyệt đối giữ nguyên thời gian sinh trưởng/sản xuất trong `data/crops.json`, `data/animals.json`, `data/recipes.json` theo Quyết định **D1** và **D2**.
2. **KHÔNG thêm timer chờ mới:** Không tạo thêm các công trình hay cơ chế buộc người chơi phải ngồi đợi một chu kỳ đếm ngược dài mới.
3. **Chỉ thêm hoạt động ngắn (1–3 phút), chủ động, chạy song song:** Tận dụng tối đa các thực thể sẵn có trên bản đồ (`InteractiveTree`, `FishingSpot`, `PetPoodle`, `BeehiveTree`, `RoadsideShop`, `QuestManager`) để gợi ý chuỗi việc ngắn mang tính tương tác trực tiếp trong lúc đợi cây chín/thú đẻ trứng.
4. **Hoạt động hoàn toàn tự nguyện & không chặn màn hình:** Mọi gợi ý nằm gọn trong **Khay việc nhỏ (Task Tray)** ở góc màn hình; người chơi có thể thu gọn hoặc bỏ qua bất cứ lúc nào mà không bị khóa thao tác camera hay thao tác ruộng đất.
5. **Giao tiếp lỏng qua `EventBus`:** Tuyệt đối không nối cứng (hard-reference) giữa `TaskTray` và từng thực thể trên bản đồ; mọi sự kiện hoàn thành hoạt động đều phát qua `scripts/core/event_bus.gd`.

---

## 2. CHI TIẾT 6 HOẠT ĐỘNG LẤP KHOẢNG CHỜ (MỤC 8.3)

Bảng tổng hợp nhanh 6 hoạt động chủ động dựa trên các hệ thống đã có trong codebase:

| # | Tên hoạt động | File thực thể / Hệ thống | Thời gian thực hiện | Phần thưởng mỗi lượt / mốc | Nhóm triển khai |
| :---: | :--- | :--- | :---: | :--- | :---: |
| **1** | **Chặt / Dời cây tự nhiên** | `scripts/entities/interactive_tree.gd` | 10–30 giây (1–3 cây) | `+15 Vàng`, `+5 XP`, đề xuất thêm `+1 mat_plank` (Ván Gỗ) | **Ưu tiên Bước 2** |
| **2** | **Thu mật ong rừng** | `scripts/entities/beehive_tree.gd` | Chu kỳ ngắn `20s` (`HONEY_CYCLE_SEC`) | `+2 honey`, `+90 Vàng`, `+45 XP`, `+25 Xu` | **Ưu tiên Bước 2** |
| **3** | **Câu cá bờ sông** | `scripts/entities/fishing_spot.gd`<br>`scripts/systems/fishing_minigame.gd` | 15–45 giây (hồi `7s` mỗi lượt) | `+1 fish_carp`/`fish_bass`, `+20~35 Vàng`, `+5~10 XP` | Bước mở rộng |
| **4** | **Nhặt rương kho báu Poodle** | `scripts/entities/pet_poodle.gd` | ~5 giây tương tác (`1.1s` anim) | `+80 XP`, `+120 Vàng`, `+35 Xu` (+ xác suất Mảnh ghép/Kim cương) | Bước mở rộng |
| **5** | **Đơn hàng sạp nhanh** | `scripts/visitors/roadside_shop.gd` | 1–2 phút (`AutoBuyerTimer` 15–25s/món) | Tiền bán nông sản (`×1.2` giá gốc) + Thưởng mốc Task `+25 XP, +50 Vàng` | Bước mở rộng |
| **6** | **Nhiệm vụ ngày ngắn** | `scripts/systems/quest_manager.gd` | 2–3 phút | `+120~160 Vàng`, `+40~60 XP`, `+1 Vật liệu`, `+25 Điểm Năng Động` | Bước mở rộng |

---

### 2.1. Hoạt động 1: Chặt / Dời cây tự nhiên (`InteractiveTree`)
- **File liên quan:** `scripts/entities/interactive_tree.gd`, `scripts/core/event_bus.gd`, `scripts/core/storage_manager.gd`, `scripts/core/grid_manager.gd`.
- **Hiện trạng trong code:**
  - Mỗi cây cảnh tương tác thuộc group `"interactable_trees"`, có `Area2D` (`TreeClickArea`) bắt sự kiện click chuột trái qua `_on_area_input_event()` $\rightarrow$ `handle_tree_click()`.
  - Người chơi có thể chọn công cụ `DragActionManager.ToolType.DISMANTLE` để chặt ngay hoặc bấm mở menu nổi `_show_mini_menu()` gồm 2 nút: `"🔄 Di Chuyển"` (`_start_moving_mode()` $\rightarrow$ `_commit_move()`) và `"🪓 Chặt Cây"` (`chop_tree()`).
  - Hàm `chop_tree()` (dòng 190–209) hiện tại đặt `_is_chopped = true`, giải phóng ô lưới `_update_grid_solid(false)`, cộng `xp_reward = 5`, `gold_reward = 15`, phát `EventBus.gold_changed.emit(StorageManager.gold, gold_reward)` và chạy tween thu nhỏ `0.2s` trước khi `queue_free()`.
- **Điều kiện kích hoạt:**
  - Kích hoạt từ Cấp 1 ngay khi trên bản đồ còn thực thể trong group `"interactable_trees"` và đang có ít nhất 1 ô ruộng `FieldPlot` ở trạng thái `GROWING`.
  - Mục tiêu trong Khay việc nhỏ: *"Dọn dẹp hoặc quy hoạch 2 cây tự nhiên quanh nông trại (0/2)"*.
- **Thời gian ước tính:** **20–45 giây** (người chơi dạo quanh bản đồ tìm cây vướng đường, chọn dời vị trí hoặc chặt dọn).
- **Phần thưởng:**
  - **Thưởng trực tiếp mỗi lần chặt (`chop_tree()`):** `+15 Vàng`, `+5 XP`, và **bổ sung `+1 mat_plank` (Ván Gỗ Thông)** nếu kho Barn còn chỗ (`StorageManager.can_store_item("mat_plank", 1)`), đúng theo định hướng Mục 8.3 của `HANDOVER.md`.
  - **Thưởng hoàn thành việc trên Khay việc nhỏ (Task Tray):** `+40 Vàng`, `+15 XP`.
- **Chống nhận thưởng 2 lần / Chống exploit:**
  1. Trong `InteractiveTree.chop_tree()`: hiện tại biến `_is_chopped` được gán `true` ở dòng 191 nhưng **chưa có lệnh `if _is_chopped: return` ở đầu hàm**. Trong quá trình tween `0.2s` trước khi `queue_free()`, nếu người chơi click đúp liên tục vào nút `"🪓 Chặt Cây"` hoặc dùng công cụ `DISMANTLE` quét qua, hàm `chop_tree()` sẽ bị gọi nhiều lần!
     $\rightarrow$ **Bắt buộc thêm guard:** `if _is_chopped: return` ở dòng đầu tiên của `chop_tree()`, đồng thời vô hiệu hóa `_area.input_pickable = false` và xóa `_mini_menu` ngay lập tức.
  2. Đối với thao tác **Di chuyển cây (`_commit_move()`)**: không thưởng vàng/gỗ trực tiếp mỗi lần đặt để tránh exploit nhấc lên đặt xuống cùng 1 cây liên tục lấy thưởng; chỉ tính hoàn thành 1 lượt quy hoạch vào Task Tray tối đa **1 lần duy nhất trên mỗi `instance_id` cây**.
- **Hàm & Signal cụ thể:**
  - Hàm hiện có: `InteractiveTree.handle_tree_click()`, `InteractiveTree.chop_tree()`, `InteractiveTree._commit_move()`.
  - Signal đề xuất thêm vào `EventBus`:
    - `signal tree_chopped(tree_id: int, sprite_id: String, world_pos: Vector2)`
    - `signal tree_relocated(tree_id: int, new_grid_pos: Vector2i)`

---

### 2.2. Hoạt động 2: Thu mật ong rừng (`BeehiveTree`)
- **File liên quan:** `scripts/entities/beehive_tree.gd`, `scripts/core/event_bus.gd`, `scripts/core/storage_manager.gd`.
- **Hiện trạng trong code:**
  - `BeehiveTree` có 2 trạng thái `HiveState.GATHERING` và `HiveState.READY`, chu kỳ hút mật ngắn `const HONEY_CYCLE_SEC: float = 20.0` (dòng 14).
  - Khi `_timer >= HONEY_CYCLE_SEC`, cây chuyển sang `HiveState.READY`, hiện bong bóng `"🍯 Sẵn Sàng!"` và phát local signal `beehive_state_changed.emit(state)`.
  - Khi người chơi click (`handle_beehive_click()` $\rightarrow$ `harvest_honey()` dòng 175–209): kiểm tra `if state != HiveState.READY: return`, sau đó cộng `honey_yield = 2` (`"honey"`), `gold_reward = 90`, `xp_reward = 45`, `coins_reward = 25`, phát `EventBus.loot_collected.emit("honey", honey_yield, ...)` và local signal `honey_harvested.emit(honey_yield)`, rồi đặt lại `state = HiveState.GATHERING`, `_timer = 0.0`.
- **Điều kiện kích hoạt:**
  - Có sẵn từ Cấp 1 khi `BeehiveTree` hiện diện trên bản đồ.
  - Mục tiêu trong Khay việc nhỏ: *"Thu hoạch 2 mẻ Mật Ong Rừng (0/2)"*.
- **Thời gian ước tính:** **40–60 giây** (2 chu kỳ × 20 giây, vừa khít khoảng chờ 3 phút của Lúa Mì).
- **Phần thưởng:**
  - **Thưởng trực tiếp mỗi lần thu (`harvest_honey()`):** `+2 honey`, `+90 Vàng`, `+45 XP`, `+25 Xu`. *(Lưu ý: cần kiểm tra sức chứa kho Barn trước hoặc thông báo nếu kho đầy).*
  - **Thưởng hoàn thành việc trên Khay việc nhỏ:** `+50 Vàng`, `+20 XP`, `+1 mat_bolt` (Đinh Tán).
- **Chống nhận thưởng 2 lần / Chống exploit:**
  1. Hàm `harvest_honey()` đã có guard `if state != HiveState.READY: return` ở dòng 176. Tuy nhiên để tuyệt đối an toàn trước các sự kiện click đồng thời trong cùng 1 frame, cần đổi thứ tự: **gán `state = HiveState.GATHERING` và `_timer = 0.0` ngay đầu hàm `harvest_honey()`** (ngay sau câu lệnh `if state != HiveState.READY: return`) trước khi cộng thưởng và phát signal.
  2. Trong `handle_beehive_click()` (dòng 161–170): hiện tại khi `state == HiveState.GATHERING`, nếu người chơi bấm vào tổ ong và có `>= 20` Vàng, code tự động trừ `20` Vàng để thúc chín sớm (`state = HiveState.READY`) mà không hỏi xác nhận, sau đó bấm thêm lần nữa lại nhận `+90` Vàng (lãi ròng `+70` Vàng chỉ bằng 2 cú click!).
     $\rightarrow$ **Chặn exploit trong Bước 2:** Khi `state == HiveState.GATHERING`, bấm vào tổ ong chỉ hiện thông báo `"🐝 Đàn ong đang hút mật hoa (còn %ds)..."` (bỏ cơ chế tự trừ 20 vàng thúc chín tức thì để tuân thủ nguyên tắc không trả vàng bỏ qua timer gây lạm phát).
- **Hàm & Signal cụ thể:**
  - Hàm hiện có: `BeehiveTree.handle_beehive_click()`, `BeehiveTree.harvest_honey()`, local signal `honey_harvested(amount: int)`, `beehive_state_changed(new_state: int)`.
  - Signal đề xuất thêm vào `EventBus`:
    - `signal beehive_honey_harvested(amount: int, world_pos: Vector2)`
    - `signal beehive_ready(world_pos: Vector2)`

---

### 2.3. Hoạt động 3: Câu cá bờ sông (`FishingSpot` & `FishingMinigame`)
- **File liên quan:** `scripts/entities/fishing_spot.gd`, `scripts/systems/fishing_minigame.gd`, `scripts/core/event_bus.gd`.
- **Hiện trạng trong code:**
  - `FishingSpot` có 2 trạng thái `SpotState.READY` và `SpotState.COOLDOWN`. Vùng click `fishing_rect = Rect2(Vector2(730.0, 675.0), Vector2(140.0, 115.0))`.
  - Khi gọi `handle_fishing_click()` (dòng 208): nếu `state == SpotState.READY`, mở minigame `_minigame.open_minigame(target_fish, Vector2(768.0, 750.0))`.
  - Trong `FishingMinigame`: kim dao động (`_needle_val`), người chơi bấm `"🪝 GIẬT CẦN CÂU!"` (`pull_rod()`). Nếu trúng vùng thắng (`0.22..0.78`, vùng hoàn hảo `0.42..0.58`), gọi `_process_success_catch(is_perfect)`: cộng `+1` cá (`fish_carp` hoặc `fish_bass` khi mưa `COZY_RAIN`), `+20` Vàng (`+35` nếu Perfect), `+5` XP (`+10` nếu Perfect), rồi phát `minigame_finished.emit(true, reward_fish)`.
  - `FishingSpot._on_minigame_finished()` nhận kết quả, phát `EventBus.fish_caught.emit(instance_id, catch_id, 1.5)` và gọi `_start_cooldown()` đặt thời gian hồi **7 giây** (`TickManager.calculate_finish_timestamp(7)`).
- **Điều kiện kích hoạt:**
  - Kích hoạt khi `FishingSpot.state == SpotState.READY` và kho Barn còn trống ít nhất 1 chỗ.
  - Mục tiêu trong Khay việc nhỏ: *"Câu 2 con cá tươi tại Nhà Câu Cá bờ sông (0/2)"*.
- **Thời gian ước tính:** **30–60 giây** (2 lượt minigame + 7 giây hồi giữa 2 lượt).
- **Phần thưởng:**
  - **Thưởng trực tiếp mỗi lượt câu trúng:** `+1 fish_carp` (hoặc `fish_bass`), `+20~35 Vàng`, `+5~10 XP`.
  - **Thưởng hoàn thành việc trên Khay việc nhỏ:** `+50 Vàng`, `+25 XP`.
- **Chống nhận thưởng 2 lần / Chống exploit:**
  - `FishingMinigame.pull_rod()` (dòng 136) đã có guard `if not is_active: return` và đặt ngay `is_active = false`, `_btn_catch.disabled = true`.
  - Cần bổ sung guard trong `FishingSpot.handle_fishing_click()`: nếu `_minigame != null and _minigame.is_active: return false` để ngăn người chơi click liên tục vào nhà câu cá mở đè minigame khi tween đóng chưa chạy xong.
- **Hàm & Signal cụ thể:**
  - Hàm hiện có: `FishingSpot.handle_fishing_click()`, `FishingSpot._on_minigame_finished()`, `FishingMinigame.open_minigame()`, `FishingMinigame.pull_rod()`.
  - Signal hiện có trên `EventBus`: `EventBus.fish_caught(spot_id: int, fish_id: String, weight_kg: float)`, `EventBus.fishing_failed(spot_id: int)`.

---

### 2.4. Hoạt động 4: Nhặt rương kho báu Poodle (`PetPoodle`)
- **File liên quan:** `scripts/entities/pet_poodle.gd`, `scripts/core/save_manager.gd`, `scripts/core/event_bus.gd`.
- **Hiện trạng trong code:**
  - `PetPoodle` đi theo nhân vật chính (`_player_target`) và có nút tương tác gọi hàm `feed_and_dig_treasure()` (dòng 192–272).
  - Kiểm tra điều kiện: cần `1 milk` (`StorageManager.has_item("milk", 1)`) hoặc `40 Vàng` (`StorageManager.has_gold(40)`). Ở Lv 1 mới tạo game (`SaveManager.reset_to_level_1()`), kho Barn có sẵn `StorageManager.barn_items["milk"] = 2`.
  - Sau khi nhảy vui mừng và đào đất (`await get_tree().create_timer(0.60).timeout` + tween lắc 4 nhịp), Poodle thưởng `xp_reward = 80`, `gold_reward = 120`, `coins_reward = 35`, cộng `SaveManager.poodle_affinity += 10`, `SaveManager.poodle_feed_count += 1`, phát `SaveManager.poodle_updated.emit()`, và có xác suất 20% rơi `+1` Mảnh ghép Sở Thú hoặc 15% rơi `+1` Kim cương.
- **Điều kiện kích hoạt:**
  - Người chơi có sẵn ít nhất `1 milk` trong kho Barn (hoặc `>= 40` Vàng) và Poodle chưa trong thời gian nghỉ.
  - Mục tiêu trong Khay việc nhỏ: *"Cho Poodle Bông ăn và đào kho báu 1 lần (0/1)"*.
- **Thời gian ước tính:** **15–30 giây** (tìm chú chó Poodle đang chạy quanh nhân vật và tương tác).
- **Phần thưởng:**
  - **Thưởng trực tiếp (`feed_and_dig_treasure()`):** `+80 XP`, `+120 Vàng`, `+35 Xu` (+ cơ hội nhận Mảnh ghép / Kim cương).
  - **Thưởng hoàn thành việc trên Khay việc nhỏ:** `+30 Vàng`, `+15 XP`, `+1 mat_brick` (Gạch Nung).
- **Chống nhận thưởng 2 lần / Chống exploit:**
  1. Hàm `feed_and_dig_treasure()` đã có biến khóa `_is_interacting = true` (dòng 193 & 208) chặn click đúp trong lúc đang chạy animation `await`.
  2. **Chặn exploit spam vô hạn bằng 40 Vàng:** Hiện tại người chơi có thể bỏ `40 Vàng` cho Poodle ăn và nhận ngay `120 Vàng` (`+80 Vàng` lãi ròng + `80 XP` mỗi `1.1` giây) không giới hạn số lần!
     $\rightarrow$ Khi tích hợp vào Phase 2B, cần thêm biến `poodle_next_dig_timestamp: int` (hoặc giới hạn tối đa 1 lần đào mỗi chu kỳ / chỉ cho phép đào khi có `milk` hoặc giới hạn theo lượt nhiệm vụ) để người chơi không thể click spam Poodle làm hỏng cân bằng kinh tế Phase 2A.
- **Hàm & Signal cụ thể:**
  - Hàm hiện có: `PetPoodle.feed_and_dig_treasure()`, signal `SaveManager.poodle_updated()`.
  - Signal đề xuất thêm vào `EventBus`: `signal poodle_treasure_dug(feed_count: int, reward_gold: int, world_pos: Vector2)`.

---

### 2.5. Hoạt động 5: Đơn hàng sạp nhanh (`RoadsideShop`)
- **File liên quan:** `scripts/visitors/roadside_shop.gd`, `scripts/core/event_bus.gd`, `scripts/core/storage_manager.gd`.
- **Hiện trạng trong code:**
  - `RoadsideShop` (Autoload) quản lý `TOTAL_SLOTS = 6` ô bày bán. Khi khởi tạo (`_init_slots()`), có sẵn Slot 0 (`5 egg`, giá `90`), Slot 1 (`10 wheat`, giá `36`, `is_sold = true` chờ thu tiền), Slot 2 (`2 bread`, giá `42`).
  - Có `AutoBuyerTimer` (`_buyer_timer`) tự động kích hoạt mỗi `15.0..25.0` giây (`_on_buyer_timer_timeout()` $\rightarrow$ `buy_random_available_slot()` $\rightarrow$ `buy_slot_by_shopper(picked)`), mua ngẫu nhiên 1 ô đang bày bán và phát `EventBus.roadside_shop_item_sold.emit(slot_index, item_id, count, price)`.
  - Người chơi đăng bán qua `list_item(slot_index, item_id, count, price)` và thu tiền qua `collect_coins(slot_index)`.
- **Điều kiện kích hoạt:**
  - Kích hoạt ngay từ Cấp 1 (Sạp hàng có sẵn 1 ô đã bán chờ thu tiền và các ô trống/đang bán).
  - Mục tiêu trong Khay việc nhỏ: *"Treo bán hoặc thu tiền 3 kiện hàng tại Sạp Hàng Bên Đường (0/3)"*.
- **Thời gian ước tính:** **1–2 phút** (thu tiền ô có sẵn, treo thêm nông sản từ kho và đợi khách mua tự động sau 15–25s/món).
- **Phần thưởng:**
  - **Thưởng trực tiếp:** Tiền vàng bán hàng từ các ô sạp (`collect_coins()`).
  - **Thưởng hoàn thành việc trên Khay việc nhỏ:** `+50 Vàng`, `+30 XP`.
- **Chống nhận thưởng 2 lần / Chống exploit:**
  - Trong `RoadsideShop.collect_coins(slot_index)` (dòng 96–116): kiểm tra `if not bool(slot.get("is_sold", false)): return false`, sau khi cộng vàng lập tức xóa sạch `slot["item_id"] = ""`, `slot["price"] = 0`, `slot["is_sold"] = false` nên không thể thu tiền 2 lần trên cùng 1 ô.
  - Trong `RoadsideShop.list_item()`: trừ vật phẩm khỏi `StorageManager` trước khi ghi vào slot (`if not StorageManager.remove_item(item_id, count): return false`).
- **Hàm & Signal cụ thể:**
  - Hàm hiện có: `RoadsideShop.list_item()`, `RoadsideShop.collect_coins()`, `RoadsideShop.buy_slot_by_shopper()`.
  - Signal hiện có: `RoadsideShop.shop_updated()`, `EventBus.roadside_shop_item_sold(slot_index: int, item_id: String, count: int, price: int)`.
  - Signal đề xuất thêm vào `EventBus`: `signal roadside_shop_coins_collected(slot_index: int, amount_gold: int)`.

---

### 2.6. Hoạt động 6: Nhiệm vụ ngày ngắn (`QuestManager`)
- **File liên quan:** `scripts/systems/quest_manager.gd`, `scripts/core/save_manager.gd`, `scripts/core/event_bus.gd`.
- **Hiện trạng trong code:**
  - `QuestManager` quản lý 12 nhiệm vụ cốt truyện (`story_quests`: `main_01`..`main_12`), 4 nhiệm vụ hàng ngày (`daily_quest_pool`: `daily_harvest`, `daily_feed_pen`, `daily_feed_zoo`, `daily_fish`), và 2 đơn khách VIP (`VIP_POOL`).
  - Lắng nghe `EventBus` qua `_connect_event_bus()` (dòng 415–428), cập nhật tiến độ qua `_add_progress_by_type(q_type, amount)` và phát `EventBus.quest_completed.emit(q_id)` khi `data["progress"] >= target`.
  - Nhận thưởng qua `claim_story_quest(quest_id)` (dòng 538) và `claim_daily_quest(quest_id)` (dòng 554).
- **Điều kiện kích hoạt:**
  - Kích hoạt ở Cấp 1 với các nhiệm vụ phù hợp cấp độ đầu game: `main_01` (*Thu hoạch 6 Lúa Mì*), `main_02` (*Cho Gà ăn & Thu 2 Trứng Gà*), `main_03` (*Hoàn thành 1 Đơn Xe Tải / Sạp Hàng*), `daily_fish` (*Câu 1 con cá*), `daily_feed_pen` (*Cho gia súc ăn 2 lần*).
  - Đề xuất bổ sung thêm 2 mẫu nhiệm vụ ngày ngắn (2–3 phút) dành riêng cho Lv 1–2 vào `daily_quest_pool` (khi sang phase triển khai hệ thống nhiệm vụ):
    - `daily_clear_trees`: *"Dọn Cỏ & Cây Rừng"* — Chặt hoặc dời 2 cây tự nhiên (`target = 2`, `type = "tree_action"`, thưởng `120 Vàng, 35 XP, 1 mat_plank`).
    - `daily_gather_honey`: *"Mật Ngọt Đầu Ngày"* — Thu hoạch mật ong 1 lần (`target = 1`, `type = "honey"`, thưởng `110 Vàng, 35 XP, 1 mat_bolt`).
- **Thời gian ước tính:** **2–3 phút** hoàn thành và bấm nhận thưởng.
- **Phần thưởng:**
  - Theo cấu hình nhiệm vụ (`120–220 Vàng`, `30–60 XP`, `+1 Vật liệu xây dựng`, `+1 Mảnh ghép Sở Thú`, và `+25 Điểm Năng Động` để mở rương mốc 50/100 điểm).
- **Chống nhận thưởng 2 lần / Chống exploit:**
  - `claim_story_quest()` và `claim_daily_quest()` đều kiểm tra `if bool(data.get("claimed", false)): return false` và gán `data["claimed"] = true` trước khi gọi `_apply_rewards(q)` và `SaveManager.save_game()`.
- **Hàm & Signal cụ thể:**
  - Hàm hiện có: `QuestManager.claim_story_quest(quest_id: String)`, `QuestManager.claim_daily_quest(quest_id: String)`, `QuestManager.get_unclaimed_count()`.
  - Signal hiện có: `QuestManager.quest_progress_changed(quest_id: String)`, `QuestManager.quest_claimed(quest_id: String)`, `EventBus.quest_completed(quest_id: String)`.

---

## 3. THIẾT KẾ GIAO DIỆN KHAY VIỆC NHỎ (TASK TRAY UI)

### 3.1. Bố cục & Vị trí trên màn hình (`1152×648`)
- **Số lượng tối đa:** Chỉ hiển thị tối đa **3 việc ngắn (active tasks)** cùng một thời điểm để giao diện thoáng mắt, đúng phong cách Cozy Chibi. Khi 1 việc được hoàn thành và nhận thưởng, khay tự động lấy việc tiếp theo trong hàng đợi (nếu còn).
- **Vị trí trên HUD (`scenes/ui_hud.tscn` / `scripts/ui/task_tray_panel.gd`):**
  - Đặt tại **cạnh trái màn hình, bên dưới cụm thông tin Cấp độ / Vàng / Kho** (`position = Vector2(14.0, 148.0)`), kích thước khi mở rộng tối đa `Vector2(248.0, 196.0)`, khi thu gọn chỉ còn một nút pill nhỏ `Vector2(118.0, 36.0)` (`"📋 Việc Nhỏ (3)"`).
  - **Không che khu vực tương tác ruộng (`FieldPlot`):** Khu vực ruộng đất trung tâm và thanh công cụ dưới đáy (`BottomHUD`) hoàn toàn thông thoáng; vị trí `x = 14..262, y = 148..344` nằm sát mép trái màn hình.
- **Tuân thủ nghiêm ngặt quy tắc Tương tác Chuột (`GEMINI.md` Mục 3.2):**
  - Mọi `Control`, `MarginContainer`, `VBoxContainer`, `HBoxContainer`, `Label`, `TextureRect` trang trí bên trong `TaskTray` **BẮT BUỘC đặt `mouse_filter = Control.MOUSE_FILTER_IGNORE` (giá trị `2`)** để không chặn sự kiện click hoặc kéo-lướt (`DragActionManager`) xuống bản đồ bên dưới.
  - Chỉ duy nhất các nút bấm thực sự (`btn_toggle_collapse`, `btn_focus_task`, `btn_claim_reward`) mới dùng `mouse_filter = Control.MOUSE_FILTER_STOP` (giá trị `0`).

### 3.2. Cơ chế Thu gọn / Ẩn hiện & Điều hướng thông minh
1. **Nút Thu gọn / Mở rộng (`btn_toggle_collapse`):**
   - Nằm ở góc trên của khay. Khi người chơi bấm thu gọn, danh sách 3 việc trượt êm (`Tween` `0.18s`) vào trong nút pill `"📋 Việc Nhỏ (N)"` (có chấm đỏ thông báo nếu có việc đã xong chờ nhận thưởng).
   - Người chơi có thể ẩn/thu gọn bất kỳ lúc nào.
2. **Nút Chỉ đường (`btn_focus_task`):**
   - Mỗi thẻ việc (Task Card) có biểu tượng kính lúp/mũi tên nhỏ; khi bấm vào sẽ di chuyển `Camera2D` mượt mà tới tọa độ thực thể tương ứng (ví dụ: Cây Tổ Ong, Nhà Câu Cá, Sạp Hàng, hoặc Cây Tự Nhiên gần nhất còn trên bản đồ) mà không tự ý thực hiện hành động thay người chơi.
3. **Thông báo gợi ý khi Timer đang chạy (Idle Waiting Prompt):**
   - Lắng nghe `EventBus.field_planted`, `EventBus.animal_fed`, `EventBus.production_started`.
   - Khi phát hiện tất cả các ô ruộng đang trồng đều ở trạng thái chờ (`time_left >= 60s`) và người chơi không thao tác trong `8 giây`, nếu `TaskTray` đang thu gọn hoặc có việc chưa làm, hiển thị một dòng gợi ý nhỏ tự tắt sau `4 giây` ở đầu khay:
     > *"💡 Trong lúc chờ lúa chín, bạn có thể thu mật ong hoặc dọn cây lấy gỗ!"*
   - Có thời gian nghỉ (cooldown `90 giây` giữa 2 lần nhắc) để không làm phiền người chơi.

### 3.3. Cấu trúc lưu trạng thái vào `SaveManager`
Để đảm bảo người chơi thoát game mở lại không bị mất tiến độ hoặc nhận thưởng 2 lần, trạng thái Khay việc nhỏ được lưu trong `SaveManager` (`scripts/core/save_manager.gd`) dưới khóa `"task_tray"`:

```gdscript
# Biến trong SaveManager (scripts/core/save_manager.gd):
var task_tray_data: Dictionary = {
	"is_collapsed": false,
	"tasks": {
		"tray_chop_tree": {
			"progress": 0,
			"target": 2,
			"claimed": false
		},
		"tray_harvest_honey": {
			"progress": 0,
			"target": 2,
			"claimed": false
		},
		"tray_catch_fish": {
			"progress": 0,
			"target": 2,
			"claimed": false
		},
		"tray_poodle_dig": {
			"progress": 0,
			"target": 1,
			"claimed": false
		},
		"tray_roadside_sale": {
			"progress": 0,
			"target": 3,
			"claimed": false
		},
		"tray_daily_step": {
			"progress": 0,
			"target": 1,
			"claimed": false
		}
	},
	"chopped_tree_positions": [] # Lưu tọa độ Vector2i các cây đã chặt để không spawn lại trùng
}
```

- **Khi `save_game()`:** Ghi `save_data["task_tray"] = task_tray_data.duplicate(true)` thông qua cơ chế ghi file tạm `.tmp` rồi `rename_absolute` sẵn có của `SaveManager`.
- **Khi `load_game()`:** Nếu file save có khóa `"task_tray"`, khôi phục đầy đủ `is_collapsed`, `tasks`, và `chopped_tree_positions`. Nếu nạp từ file save cũ chưa có `"task_tray"`, tự động khởi tạo giá trị mặc định an toàn (backward-compatible, không xóa save cũ theo quy tắc Mục 9.6).
- **Khi `reset_to_level_1()`:** Reset `task_tray_data` về trạng thái khởi đầu (`progress = 0`, `claimed = false`).

---

## 4. KẾ HOẠCH KIỂM THỬ (TEST PLAN CHO BƯỚC 2)

Theo đúng lộ trình tại **Mục 8.5 & 8.6** của `docs/HANDOVER.md`, sau khi thiết kế này được xác nhận, Bước 2 sẽ tập trung triển khai nhóm cốt lõi ít phụ thuộc nhất: **"Chặt cây (`InteractiveTree`) + Thu ong (`BeehiveTree`) + Khay việc nhỏ (`TaskTray`)"** và kiểm thử qua 2 tầng:

### 4.1. Unit Test mới: `tests/unit/test_task_tray.gd`
Viết bằng `gdUnit4`, kiểm tra tự động 5 kịch bản bắt buộc:
1. **`test_chop_tree_rewards_and_double_click_guard`:**
   - Khởi tạo `InteractiveTree`, gọi `chop_tree()` 2 lần liên tiếp trong cùng 1 frame.
   - Khẳng định (`assert_int`): Vàng chỉ tăng đúng `+15`, XP tăng đúng `+5`, vật liệu `mat_plank` tăng đúng `+1`, và tín hiệu `EventBus.tree_chopped` chỉ phát đúng **1 lần**.
2. **`test_beehive_harvest_and_no_gold_skip_exploit`:**
   - Khởi tạo `BeehiveTree` ở trạng thái `HiveState.READY`, gọi `harvest_honey()` 2 lần liên tiếp.
   - Khẳng định: Mật ong (`honey`) chỉ tăng `+2`, Vàng tăng `+90`, trạng thái chuyển ngay sang `HiveState.GATHERING`, lần gọi thứ 2 không cộng thêm thưởng.
   - Khi đang ở `HiveState.GATHERING`, gọi `handle_beehive_click()` không bị trừ 20 Vàng và không tự nhảy sang `READY`.
3. **`test_task_tray_progress_via_event_bus`:**
   - Phát tín hiệu `EventBus.tree_chopped` và `EventBus.beehive_honey_harvested`.
   - Khẳng định `TaskTray` cập nhật đúng `progress` từ `0 -> 1 -> 2` mà không cần giữ tham chiếu trực tiếp tới node cây hay tổ ong.
4. **`test_task_tray_claim_once_guard`:**
   - Khi `progress == target`, gọi `claim_task("tray_chop_tree")` 2 lần.
   - Khẳng định: Lần 1 trả về `true` và cộng thưởng; lần 2 trả về `false`, `claimed == true`, không cộng thưởng lần hai.
5. **`test_task_tray_save_and_load_persistence`:**
   - Bật `SaveManager.set_test_mode(true)`, cập nhật tiến độ `tray_chop_tree` (`progress = 1`), thu gọn khay (`is_collapsed = true`), gọi `SaveManager.save_game()`.
   - Reset biến trong bộ nhớ rồi gọi `SaveManager.load_game()`.
   - Khẳng định dữ liệu `task_tray_data` khôi phục chính xác 100%, đồng thời `mouse_filter` của container nền là `Control.MOUSE_FILTER_IGNORE`.

### 4.2. Kiểm thử Playtest tự động: `tests/playtest/random_bot_test.gd`
- Chạy bot 200 bước (`FIXED_SEED = 20261102`) cùng toàn bộ bộ test bằng cả 2 lệnh trong `docs/HANDOVER.md`:
  ```powershell
  & "D:\Gotdot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --path . --headless -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit -a res://tests/playtest -c --ignoreHeadlessMode
  ```
- Đảm bảo:
  - Không phát sinh orphan nodes, lỗi parse GDScript 2.0, hay vòng lặp vô hạn.
  - Khay việc nhỏ không chặn các cú click gieo hạt/thu hoạch của bot trên `FieldPlot`.

---

## 5. NHỮNG GÌ KHÔNG LÀM TRONG PHASE 2B

Để giữ phạm vi thay đổi chặt chẽ, an toàn và dễ kiểm chứng theo đúng quy trình bàn giao (`docs/HANDOVER.md` Mục 8 & Mục 9), Phase 2B **TUYỆT ĐỐI KHÔNG LÀM** các việc sau:
1. **Không sửa bất kỳ thời gian chờ (timer) nào trong `data/*.json`:** Không rút ngắn thời gian trồng lúa mì, ngô, nuôi gà hay chế biến bánh.
2. **Không tự ý thay đổi bảng giá kinh tế (`base_price`, `ingredients`):** Việc cân đối lợi nhuận/phút thuộc về **Phase 2A** (`tools/economy_report.py`).
3. **Không thêm công trình sản xuất mới hay hệ thống phức tạp ngoài 6 hoạt động đã có:** Không thêm máy mới, không thêm minigame mới, không thêm hệ thống thể lực (stamina/energy) làm giới hạn thao tác của người chơi.
4. **Không làm cả 6 hoạt động cùng một lúc trong Bước 2:** Theo đúng chỉ dẫn tại Mục 8.5 và Mục 8.6 của `docs/HANDOVER.md`, Bước 2 (sau khi được duyệt thiết kế này) chỉ triển khai trước cụm **"Chặt cây + Thu ong + Khay việc nhỏ"** để kiểm chứng kiến trúc `EventBus` + `SaveManager` + `test_task_tray.gd` hoàn chỉnh trước khi nối tiếp 4 hoạt động còn lại.
5. **Không dùng `Polygon2D` hoặc `ColorRect` thô sơ vẽ thay sprite thực thể:** Mọi biểu tượng trên `TaskTray` sử dụng texture chuẩn từ `SpriteAtlasManager`.
