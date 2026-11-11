# BÀN GIAO DỰ ÁN — HayDay Offline (Chibi Farm)

> Lưu tài liệu này thành `docs/HANDOVER.md` trong repo, thay thế bản cũ.
> Ký hiệu: **[ĐÃ XÁC NHẬN]** = đã kiểm chứng bằng chạy thực tế trên bản sao sạch. **[CHƯA XÁC NHẬN]** = cần người nhận bàn giao kiểm tra trước khi dựa vào.
> Cập nhật lần cuối: 11/11/2026.

---

## 0. Tình trạng hiện tại (tóm tắt)

| Hạng mục | Trạng thái | Ghi chú |
|---|---|---|
| Gameplay 6 trụ cột (Sprint 1–6 + hotfix) | Đã làm, **chưa commit** | Xem mục 9 |
| Kiểm toán dữ liệu JSON (`docs/data_audit.md`) | Đã làm | Có số liệu sai, đã đính chính ở mục 6 |
| Quyết định nhịp thời gian | **Đã chốt: Phương án B** | `docs/decision_timing.md` |
| Phase 1 (đổi code theo Phương án B) | **[ĐÃ XÁC NHẬN]** trên bản sao sạch | gdUnit 6/6 PASSED ở cả 2 lệnh, exit 0 |
| Phase 2A — công cụ kinh tế | **[ĐÃ XÁC NHẬN]** chạy được | `tools/economy_report.py`, xuất CSV và MD |
| Phase 2A — cân đối giá trị | **Chưa làm** | Cần người chơi thử để chốt khoảng mục tiêu |
| Phase 2B — lấp khoảng chờ | Đã có thiết kế, **chưa code** | `docs/design_phase2b_tasks.md` |
| Lỗ hổng double-click (`interactive_tree.gd`, `beehive_tree.gd`, `pet_poodle.gd`) | **Chưa sửa** | Phải sửa trước khi làm Phase 2B |
| Đồ họa 2.5D Cozy (`cozy_atmosphere_fx.gd`, shader gió) | Đã làm, **chưa commit** | Chi phí FPS rất nhỏ (xem mục 4) |
| Hiệu năng tổng thể | **Chưa đạt** | ~1.250 draw calls/khung, 22–35 FPS trên Intel HD 620 |
| Soak test 15 phút | **Chưa làm** | Chỉ có benchmark 18 giây |
| Git | **Rất bẩn, chưa commit** | 592 thay đổi so với `HEAD` (`fa96a58`) |

**Việc đầu tiên của người nhận bàn giao:** clone repo vào thư mục sạch, chạy lại test (mục 1), đối chiếu với mục 0, rồi làm theo thứ tự ở mục 10.

---

## 1. Thông tin kỹ thuật

- **Engine:** Godot 4.7.2 Standard, renderer GL Compatibility
- **Ngôn ngữ:** GDScript 2.0, static typing
- **Độ phân giải:** 1152×648, mục tiêu 60 FPS
- **Godot (máy hiện tại):** `D:\Gotdot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`
- **Thư mục dự án:** `D:\HayDayOffline`
- **Repo GitHub:** `https://github.com/phidanghai-spec/Chibifarmer-` **[ĐÃ XÁC NHẬN]** khớp với `origin` và commit `HEAD` của `D:\HayDayOffline`.
- **Máy đo hiệu năng:** Intel HD Graphics 620, ANGLE OpenGL ES 3.0 (Direct3D11).

### Lệnh chạy test

```powershell
# Lệnh 1: mặc định, dừng khi fail đầu tiên
& "D:\Gotdot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --path . --headless -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit -a res://tests/playtest --ignoreHeadlessMode

# Lệnh 2: chạy hết mọi test case
& "D:\Gotdot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --path . --headless -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit -a res://tests/playtest -c --ignoreHeadlessMode
```

Kết quả hiện tại: **6/6 PASSED** ở cả hai lệnh (5 unit + 1 playtest 200 bước), exit code 0, trên bản sao sạch không có thư mục `.godot/` cũ.

Lưu ý: bản sao sạch phải chạy `--import` trước khi test. Thư mục `reports/`, `.godot/` và `debug_*.png` không đưa vào git.

---

## 2. Những gì đã làm

**Nền tảng**
- 11 Autoload: `EventBus`, `DataManager`, `TickManager`, `StorageManager`, `GridManager`, `RoadsideShop`, `TruckOrderSystem`, `SpriteAtlasManager`, `SaveManager` (atomic save `.tmp`), `AudioManager`, `DailyNewspaper`.
- Dữ liệu tách theo file trong `data/`: `crops`, `items`, `animals`, `buildings`, `recipes`, `fishes`, `visitors`, `map_layout`, `avatar_catalog`, `truck_orders`.

**Gameplay**
1. Khởi động & nhân vật: `BootSplash`, `TitleScreen` (3 ô lưu), `CharacterCreator` + `ModularChibiAvatar`, `OnboardingDirector`, `OfflineSimulator` + `OfflineReportModal`.
2. Trồng trọt: `FieldPlot`, `DragActionManager` (click hoặc vuốt), lưới 32×32, `COZY_RAIN` tăng tốc 25%.
3. Chăn nuôi & thú cưng: `AnimalPen`, `PetPoodle` (đào kho báu), `BeehiveTree`.
4. Sản xuất & xây dựng: `ProductionMachine` (feed_mill, bakery, juice_stand, cake_oven), `MapBuilder`, `ChibiSceneryBuilder`, `InteractiveTree`.
5. Câu cá & giao thương: `FishingSpot`, `FishingMinigame`, `RiverSteamboat`, `RoadsideShop`, `TruckOrderSystem`, `DailyNewspaper` (làm mới mỗi 180s).
6. Du lịch & môi trường: `ZooManager` (Sở Thú Bờ Đông), `TourismStarDirector`, `VisitorManager`, `WeatherAndDayNightManager`, `QuestManager`, `FarmAlmanacModal`.
7. Đồ họa 2.5D: `CozyAtmosphereFX` (mặt nước, tia nắng, hạt nắng, đom đóm, quầng đèn), shader gió trong `ChibiSceneryBuilder`.

**Phase 1 (đã xác nhận)**
- `AnimalPen` đọc `produce_time_seconds` từ JSON, bỏ hardcode 15s.
- `ProductionMachine` bỏ cap `mini(craft_time, 60)` ở cả 3 vị trí, trả đủ `produce_count`, cộng đúng `xp_reward`.
- `TickManager`: `dev_speed_multiplier` bị ép về 1.0 ngoài môi trường test, không lưu vào save.
- Test: thêm miễn trừ `is_exempt` cho 2 ảnh keyart, thêm reset multiplier trong `after_test()`, thêm test Phase 1.

**Phase 2A (đã làm một phần)**
- `tools/economy_report.py` xuất `docs/economy_report.csv` (47 dòng) và `docs/economy_report.md`.
- Đã sửa `sanctuary_feed.craft_time_seconds` từ 12 thành 1200 trong `recipes.json`.

---

## 3. Quyết định thiết kế đã chốt

| # | Quyết định | Lý do | Nơi ghi nhận |
|---|---|---|---|
| D1 | **Phương án B:** giữ nhịp idle dài theo JSON gốc (cây 3–30 phút, vật nuôi 20 phút–6 giờ, chế biến 5 phút–3 giờ) | Đúng cấu trúc offline/Hay Day, giữ giá trị cho `OfflineSimulator` và nút tăng tốc | `docs/decision_timing.md` |
| D2 | Đọc thời gian từ JSON, không hardcode trong code | Test và production cùng logic | Phase 1 (đã xác nhận) |
| D3 | `dev_speed_multiplier` chỉ dành cho test | Người chơi không tự tăng tốc được | `tick_manager.gd` |
| D4 | Mỗi thực thể dữ liệu chỉ có một nguồn chuẩn (SSOT) | Ngăn lệch giá và lệch level | `docs/data_audit.md` mục 3 |
| D5 | Sửa `GEMINI.md` dòng 11 (lúa mì 10s, ngô 20s "để test") theo D1 | Tài liệu không được mâu thuẫn với code | **Chưa làm**, xem mục 10 |

---

## 4. Hiệu năng (đã đo, chưa đạt mục tiêu)

**Đo trên Intel HD 620, cửa sổ GL Compatibility:**

| Phép đo | FPS trung bình | Draw calls/khung | Ghi chú |
|---|---|---|---|
| Benchmark 18s, di chuyển qua nhiều khu và thời tiết | 22.2 (min 18, max 25) | ~1.252 | Frame time trung bình 45 ms, p95 57 ms |
| A/B đứng yên 6s, tắt hiệu ứng mới | 35.6 | 1.260 | |
| A/B đứng yên 6s, bật hiệu ứng mới | 35.2 | 1.259 | Chi phí hiệu ứng mới ~0.4 FPS |

**Kết luận:**
- Hiệu ứng mới **không phải nguyên nhân** chính gây tụt FPS.
- Nguyên nhân chính là **số draw call quá cao sẵn có** (~1.250/khung) trên GPU tích hợp yếu.
- Mục tiêu 60 FPS trên HD 620 **có thể không thực tế**. Cần chọn cấu hình tham chiếu trước (mục 10).

**Chưa làm:** soak test 15 phút, đo bộ nhớ theo thời gian, đo trên máy yếu hơn hoặc trên web/mobile.

---

## 5. Lỗi đã biết

### 5.1. Đã xử lý
- 4 assertion fail trên `boot_splash_keyart.png` và `title_screen_keyart.png` → đã thêm vào `is_exempt`.
- `sanctuary_feed` craft 12s → đã sửa thành 1200s **[CHƯA XÁC NHẬN ý đồ thiết kế]**. Nếu ý đồ khác, sửa lại và chạy lại `economy_report.py`.

### 5.2. Chưa xử lý — lỗi dữ liệu kinh tế

| Vấn đề | Nơi | Hướng xử lý |
|---|---|---|
| `wheat` 180s trong `crops.json`, 10s trong `items.json`. `DataManager.get_item_base_price()` ưu tiên `items.json` | `data/`, `data_manager.gd` | Đưa về SSOT (D4) |
| Giá ngô 9 (`crops.json`) và 7 (`items.json`) | Như trên | Quyết định theo bảng kinh tế, không theo file đang ghi đè |
| Mốc mở khóa lệch giữa JSON, `LevelProgressionManager`, `UIHud` | 3 nơi | Đưa về `buildings.json` / `crops.json` |
| `dairy`, `lure_workbench` có công thức nhưng không xây được | `map_layout.json`, `UIHud.open_build_modal()` | Thêm vào menu xây dựng |
| `sheep_pasture` thiếu trong `buildings.json`, `sheep_feed` thiếu công thức | `buildings.json`, `recipes.json` | Bổ sung hoặc ẩn |
| Silo/Barn trừ vàng nhưng không dùng `mat_plank`, `mat_bolt`, `mat_brick` | `ui_hud.gd` | Phase 2 |
| `MapBuilder.build_farm()` spawn toàn bộ công trình kể cả Lv 1 | `map_builder.gd` | Gate theo level |
| `red_lure`, `green_lure`, `gold_lure` có `ingredients = {}` (miễn phí) và lệch ID với `bait_*` trong `items.json` | `recipes.json`, `items.json` | Xác nhận cách dùng, rồi gộp ID |
| `cookie` hardcode giá 45 trong `daily_newspaper.gd`, JSON là 150 (15/17 mặt hàng báo ngày bị hardcode lệch) | `daily_newspaper.gd` | Bỏ hardcode, đọc từ JSON |
| `sanctuary_feed` chưa được kiểm tra có trả đủ `produce_count = 2` trong `ProductionMachine` | `production_machine.gd` | Kiểm tra lại sau Phase 1 |
| Lệch giá `corn` (7 vs 9) làm `sanctuary_feed` lệch vốn 31 vs 35 | `items.json`, `crops.json` | Chốt giá ngô (mục 10) |

### 5.3. Lỗi khác
- `ui_hud.gd` ~4.400 dòng, gánh hầu hết modal → tách dần, không gấp.
- Hai file scene chính `MainFarm.tscn` và `main_farm.tscn` → xác định file đang dùng, xóa file còn lại.
- `MAX_OFFLINE_SECONDS` = 28800 (`SaveManager`) vs `MAX_OFFLINE_CAP_SECONDS` = 86400 (`OfflineSimulator`) → thống nhất một giá trị.
- Chuỗi "Vườn Thú Bờ Tây" trong `TourismStarDirector`, `OfflineSimulator` → sửa thành "Bờ Đông".
- ~290 ảnh chưa được tham chiếu → chạy `asset_audit.py`, dọn sau.
- `Learn_RAG_From_Scratch/` sinh ~40 file `.import` khi Godot scan → thêm `.gdignore` hoặc chuyển ra khỏi dự án.
- Lỗ hổng double-click/exploit ở `interactive_tree.gd`, `beehive_tree.gd`, `pet_poodle.gd` → **phải sửa trước Phase 2B**.

---

## 6. Đính chính số liệu báo cáo kiểm toán

| Mục | Báo cáo gốc ghi | Số đúng |
|---|---|---|
| `cow_feed` vốn | 27~35 | 27 (items) / 29 (crops). Số 35 là lẫn từ giá đề xuất |
| `pig_feed` vốn | 26~34 | 26 (cả hai). Số 34 là lẫn từ giá đề xuất |
| `chicken_feed` vốn | 13 | 13 (items) / 15 (crops) |
| `mango_smoothie` lãi | Không xét | +38 (items), +10 (crops), +22 (nếu mango=30) |
| `sugarcane_juice` nếu sugarcane=16 | Không xét | Lãi giảm từ +10 xuống +6 |
| `sanctuary_feed` | Không phân tích | Sau khi sửa 1200s: lãi +39, 1.95 vàng/phút |

---

## 7. PHASE 2A — Cân đối kinh tế theo phút

### 7.1. Mục tiêu
Mỗi chuỗi sản xuất có lợi nhuận/phút nằm trong khoảng mục tiêu để người chơi thấy rõ chuỗi nào đáng làm hơn.

### 7.2. Công thức (đã đính chính)
- **Chế biến:** lợi nhuận/phút = (giá bán × `produce_count` − tổng giá nguyên liệu) ÷ (`craft_time_seconds` ÷ 60)
- **Cây trồng:** lợi nhuận/phút = (`harvest_yield` × giá nông sản − chi phí hạt) ÷ (`growth_time_seconds` ÷ 60).
  **Đính chính:** `harvest_yield = 2` đã có sẵn trong `crops.json` và `FieldPlot.harvest()` cộng trực tiếp giá trị này. **Không nhân thêm hệ số ×2.** [ĐÃ XÁC NHẬN]
- **Vật nuôi:** lợi nhuận/phút = (`produce_count` × giá sản phẩm − chi phí cám) ÷ (`produce_time_seconds` ÷ 60)

### 7.3. Bảng chuỗi chế biến (items.json, craft time hiện tại)

| Công thức | Lợi nhuận | Craft | Lãi/phút | Nhận xét |
|---|---|---|---|---|
| `bread` | +12 | 300s | 2.40 | Hiệu quả nhất nhóm đầu |
| `cream_cake` | +184 | 5400s | 2.04 | Mở khóa muộn |
| `item_herbal_tea` | +56 | 1800s | 1.87 | Tốt |
| `butter_cookie` | +106 | 3600s | 1.77 | Tốt |
| `corn_bread` | +52 | 1800s | 1.73 | Tốt |
| `item_grilled_fish` | +20 | 900s | 1.33 | Cần kiểm chứng thêm |
| `chicken_feed` | +8 (1 bao) / +21 doanh thu (3 bao) | 300s | 1.60 | Phase 1 đã trả đủ `produce_count`, cần tính lại |
| `cheese` | +96 | 3600s | 1.60 | Ổn |
| `item_bacon_eggs` | +61 | 2400s | 1.52 | Ổn |
| `cow_feed` | +15 | 600s | 1.50 | Ổn |
| `item_fish_pie` | +24 | 1200s | 1.20 | Ổn |
| `butter` | +22 | 1200s | 1.10 | Ổn |
| `sanctuary_feed` | +39 | 1200s | 1.95 | **Đã sửa craft từ 12s**, chờ xác nhận |
| `apple_juice` | +35 | 2400s | 0.88 | Hơi thấp |
| `pig_feed` | +16 | 1200s | 0.80 | Hơi thấp |
| `mango_smoothie` | +38 | 3000s | 0.76 | Thấp vì craft lâu |
| `sugarcane_juice` | +10 | 1800s | 0.33 | **Quá thấp** |
| `red_lure` | +20 | 5400s | 0.22 | **Quá thấp** và miễn phí |
| `green_lure` | +35 | 7200s | 0.29 | **Quá thấp** |
| `gold_lure` | +60 | 10800s | 0.33 | **Quá thấp** |

**Khoảng mục tiêu đề xuất (cần người chơi thử để chốt):**
- Chuỗi nhập môn (Lv 1–4): 1.5–2.5 vàng/phút
- Chuỗi trung cấp (Lv 5–9): 1.2–2.0 vàng/phút
- Chuỗi cao cấp (Lv 10+): 1.0–2.0 vàng/phút, phải có lợi thế khác (XP, đơn hàng, sao)

**Hệ quả:** `sugarcane_juice` và các mồi câu đang thấp hơn nhiều so với khoảng này. Cần tăng giá bán, giảm craft, hoặc thêm lợi ích phụ (ví dụ mồi câu cho cá hiếm).

### 7.4. Các bước còn lại
1. Điền `harvest_yield`, `growth_time_seconds`, `produce_count`, `produce_time_seconds` cho cây và vật nuôi vào báo cáo.
2. Chốt giá ngô (7 hay 9) và cập nhật SSOT.
3. Chạy lại `economy_report.py` sau mỗi thay đổi, chỉ đổi một nhóm mỗi lần.
4. Kiểm tra sink (chỗ tiêu vàng): nâng cấp kho, mở công trình.
5. Cập nhật `docs/data_audit.md` với bảng đã chốt.

---

## 8. PHASE 2B — Lấp khoảng chờ đầu game

### 8.1. Nguyên tắc
- Không rút ngắn timer (D1).
- Thêm hoạt động ngắn, chủ động, chạy song song với timer.
- Mỗi hoạt động 1–3 phút, có thưởng rõ, không bắt buộc, không thêm timer chờ mới.

### 8.2. Hoạt động đề xuất

| Hoạt động | Hook trong code | Ý tưởng |
|---|---|---|
| Chặt/dời cây tự nhiên | `interactive_tree.gd` | Cho gỗ (`mat_plank`), XP nhỏ |
| Câu cá | `FishingSpot`, `fishing_minigame.gd` | Đã có, đưa vào gợi ý khi chờ |
| Đào kho báu | `PetPoodle` | Thưởng vàng hoặc vật liệu |
| Thu ong | `beehive_tree.gd` | Thu mật ong sau chu kỳ ngắn |
| Đơn hàng sạp | `RoadsideShop` | Bán 3 món trong 2 phút |
| Nhiệm vụ ngày | `quest_manager.gd` | Thêm nhiệm vụ 2–3 phút |

### 8.3. Khay việc nhỏ (TaskTray)
- Tối đa 3 hoạt động cùng lúc, góc màn hình, ẩn/hiện được.
- Dùng `MOUSE_FILTER_IGNORE` để không chặn chuột gameplay.
- Không chặn màn hình, mọi hoạt động có thể bỏ qua.

### 8.4. Thứ tự làm
1. **Trước tiên:** sửa lỗ hổng double-click ở ba script trên (mục 5.3), có test.
2. Làm `TaskTray` + chặt cây + thu ong (ít phụ thuộc nhất).
3. Playtest 15 phút ở Lv 1, ghi khoảng nào vẫn trống.
4. Làm tiếp các hoạt động còn lại.

---

## 9. Quy trình và trạng thái Git

### 9.1. Trạng thái Git hiện tại
- `HEAD` = `fa96a58` (trùng `origin/main`, 02/11/2026).
- **592 mục** chưa commit, gồm: Sprint 1–6, Phase 1, Phase 2A, Phase 2B (thiết kế), đồ họa, tài liệu, và các file tồn đọng từ trước.
- Ảnh debug `debug_*.png` đang ở trạng thái xóa trong index.
- Script đo (`fps_benchmark.gd`, `ab_fps_bench.gd`, `audit_git_scope.py`) là file tạm.

### 9.2. Việc cần làm trước khi commit
1. Thêm `debug_*.png` và `reports/` vào `.gitignore`.
2. Thêm `.gdignore` vào `Learn_RAG_From_Scratch/` hoặc chuyển thư mục đó ra ngoài.
3. Chuyển script đo vào `tools/bench/`, hoặc xóa sau khi dùng.
4. Chia commit theo nhóm: (a) Sprint 1–6 gameplay, (b) Phase 1, (c) Phase 2A, (d) đồ họa, (e) tài liệu.
5. Mỗi commit chạy lại gdUnit trước khi push.

### 9.3. Quy tắc làm việc
- Mỗi lần giao việc cho agent dùng prompt có sẵn, không viết prompt tự do.
- Mỗi bước là một commit riêng, message tiếng Anh ngắn.
- Sau mỗi bước: clone sạch → chạy test → đối chiếu với báo cáo agent → ghi `docs/*_log.md`.
- Không sửa JSON ngoài Phase 2A đã được duyệt.
- Không xóa save cũ khi đổi ID; dùng `ID_ALIASES`.
- Không copy code từ repo tham khảo khi chưa kiểm tra giấy phép.

---

## 10. Việc tiếp theo (theo thứ tự)

| # | Việc | Ai quyết định | Điều kiện hoàn thành |
|---|---|---|---|
| 1 | Chốt cấu hình tham chiếu để đo FPS (máy, độ phân giải, mục tiêu FPS) | Chủ dự án | Có văn bản ghi rõ trong `docs/performance_target.md` |
| 2 | Dọn git theo mục 9.2 | Người nhận bàn giao | `git status` sạch, commit đã chia nhóm |
| 3 | Xác nhận `sanctuary_feed` 1200s | Chủ dự án | Đã xác nhận hoặc đã sửa lại |
| 4 | Chốt giá ngô (7 hay 9) | Chủ dự án | `items.json` và `crops.json` khớp nhau |
| 5 | Sửa `GEMINI.md` dòng 11 | Chủ dự án | Không còn mâu thuẫn với Phương án B |
| 6 | Sửa double-click ở `interactive_tree.gd`, `beehive_tree.gd`, `pet_poodle.gd` | Agent + kiểm tra | Có test, gdUnit PASSED |
| 7 | Tối ưu draw call trên `MainFarm` (gom batch, `TileMapLayer`, dùng chung material) | Agent + kiểm tra | Benchmark trước/sau có số liệu |
| 8 | Soak test 15 phút trên cấu hình tham chiếu | Người nhận bàn giao | Log FPS, bộ nhớ, không có lỗi |
| 9 | Làm Phase 2A: cân đối vàng/phút, chốt khoảng mục tiêu | Chủ dự án + playtest | `economy_report.md` không còn cờ bất thường |
| 10 | Làm Phase 2B: TaskTray + hoạt động đầu tiên | Agent + kiểm tra | Theo `design_phase2b_tasks.md` |

---

## 11. Rủi ro và câu hỏi mở

| # | Rủi ro / câu hỏi | Trạng thái |
|---|---|---|
| R1 | Repo `Chibifarmer-` có phải nguồn chuẩn không? | **Đã đóng**: khớp `origin` và `HEAD` |
| R2 | `sanctuary_feed` 12s có phải typo? | **Đã sửa thành 1200s**, chờ xác nhận ý đồ |
| R3 | Mồi câu miễn phí có bị khai thác không? | Mở. Cần biết có bán được không |
| R4 | Phương án B có làm người chơi rời đi ở Lv 1? | Mở. Cần playtest và Phase 2B |
| R5 | Save cũ có tương thích khi đổi ID? | Mở. Cần thử với file save thật trước khi sửa |
| R6 | `COZY_RAIN` và `dev_speed_multiplier` có tương tác sai? | Mở. Cần test với hệ số 60x |
| R7 | Agent viết báo cáo mà không chạy test thật? | **Giảm rủi ro**: đã kiểm chứng trên bản sao sạch |
| R8 | Hai file scene `MainFarm.tscn` và `main_farm.tscn` | Mở. Cần xác định file đang dùng |
| R9 | Draw call ~1.250/khung làm FPS không đạt trên máy yếu | Mở. Cần mục 10 số 1 và 7 |
| R10 | Thay đổi chưa commit quá lớn, khó truy vết lỗi | Mở. Cần mục 9.2 |
| R11 | Giấy phép 8 repo tham khảo chưa được kiểm chứng đầy đủ | Mở. Cần kiểm tra ngẫu nhiên ít nhất 2 repo |

---

## 12. Checklist bàn giao

**Người bàn giao:**
- [ ] Đẩy `docs/HANDOVER.md` và toàn bộ `docs/` lên repo
- [ ] Trả lời mục 10 số 1, 3, 4, 5
- [ ] Gửi `docs/phase1_log.md` và kết quả gdUnit mới nhất
- [ ] Cung cấp file save mẫu (nếu có) để kiểm tra R5

**Người nhận bàn giao:**
- [ ] Clone repo sạch, cài Godot 4.7.2 đúng phiên bản
- [ ] Chạy `--import`, rồi chạy cả hai lệnh gdUnit trong mục 1 (kỳ vọng 6/6 PASSED)
- [ ] Đọc `GEMINI.md`, `docs/decision_timing.md`, `docs/data_audit.md`, `docs/economy_report.md`
- [ ] Làm theo mục 9.2 để dọn git
- [ ] Kiểm tra R2, R3 trong `recipes.json` và `items.json`
- [ ] Kiểm tra giấy phép ít nhất 2 repo trong `docs/references.md`
- [ ] Làm theo thứ tự mục 10

---

*Tài liệu này dựa trên kết quả chạy thực tế ngày 11/11/2026 và các báo cáo trong `docs/`. Mọi mục đánh dấu [CHƯA XÁC NHẬN] cần được kiểm tra lại trước khi dựa vào.*
