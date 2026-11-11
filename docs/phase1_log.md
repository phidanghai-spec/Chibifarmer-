# NHẬT KÝ TRIỂN KHAI & KIỂM CHỨNG PHASE 1 (`phase1_log.md`)

- **Dự án:** HayDay Offline (`D:\HayDayOffline`) — Godot 4.7.2 Standard, GDScript 2.0 (100% Static Typing)
- **Tham chiếu thiết kế:** `docs/HANDOVER.md` (mục 3, 4, 5.1) và `docs/decision_timing.md` (Quyết định D1–D5: Phương án B — giữ nhịp Idle theo JSON gốc)
- **Trạng thái dữ liệu:** Không chỉnh sửa bất kỳ file `data/*.json` nào và không sửa trực tiếp `GEMINI.md`.

---

## 1. BẢNG TỔNG HỢP TỪNG BƯỚC TRIỂN KHAI (BƯỚC 0 $\rightarrow$ BƯỚC 4)

| Bước | Hạng mục công việc | File chỉnh sửa | Dòng thay đổi / Tổng số dòng | Chi tiết kỹ thuật đã thực hiện |
| :---: | :--- | :--- | :---: | :--- |
| **Bước 0** | Sửa test baseline (`is_exempt` cho ảnh Keyart) | `tests/unit/test_farm_logic_and_visuals.gd` | Dòng `63` / Tổng `180` dòng | Bổ sung `"keyart" in file_name.to_lower() or file_name == "boot_splash_keyart.png" or file_name == "title_screen_keyart.png"` vào biến `is_exempt` trong `test_all_sprites_valid_and_corners_transparent()`. Giữ nguyên ngưỡng kiểm tra `alpha <= 0.05` cho toàn bộ sprite khác. |
| **Bước 1** | Bỏ hardcode `15s` trong `AnimalPen` | `scripts/entities/animal_pen.gd` | Dòng `356–365`, `418`, `437–439`, `466–468` / Tổng `496` dòng | Trong `feed()`, xóa `var duration: int = 15`, thay bằng `var duration: int = int(a_data.get("produce_time_seconds", 1200))` đọc trực tiếp từ `data/animals.json` qua `DataManager.get_animal(animal_id)`. Bổ sung kiểm tra an toàn `_timer_label != null`. |
| **Bước 2** | Bỏ trần `60s` và dùng đúng `produce_count`, `xp_reward` trong `ProductionMachine` | `scripts/entities/production_machine.gd` | Dòng `13`, `175–188`, `228–231`, `263–274`, `359`, `380–398` / Tổng `403` dòng | 1. Bỏ `mini(..., 60)` tại cả 3 vị trí (`_on_second_ticked` dòng `187`, `speed_up_current_job` dòng `274`, `start_recipe` dòng `359`), thay bằng `var craft_time: int = int(rec.get("craft_time_seconds", 30))`.<br>2. Khi hoàn thành công việc (`_on_second_ticked` & `speed_up_current_job`), lặp `produce_count = maxi(1, int(current_job.get("produce_count", 1)))` lần để thêm đủ số lượng thành phẩm vào `completed_items: Array[String]`.<br>3. Lưu mảng song song `_completed_xp_rewards: Array[int]` và cập nhật `collect_all()` cộng đúng `xp_reward` của công thức thay vì hardcode `3`. |
| **Bước 3** | Guard `dev_speed_multiplier` trong `TickManager` & Reset sau test | `scripts/core/tick_manager.gd`<br>`tests/unit/test_farm_logic_and_visuals.gd` | `tick_manager.gd`: Dòng `4–21`, `32–39` / Tổng `67` dòng<br>`test_farm_logic_and_visuals.gd`: Dòng `4–5` / Tổng `180` dòng | 1. Thêm hàm `_is_test_environment()` kiểm tra `SaveManager != null and (SaveManager.is_test_mode or SaveManager._detect_test_mode())`.<br>2. Ép `dev_speed_multiplier = 1.0` cả trong setter và đầu hàm `calculate_finish_timestamp()` nếu không ở môi trường test.<br>3. Thêm `after_test() -> void:` trong `TestFarmLogicAndVisuals` luôn reset `TickManager.dev_speed_multiplier = 1.0`.<br>4. Kiểm tra `scripts/core/save_manager.gd` (`860` dòng): xác nhận `dev_speed_multiplier` không được lưu vào bất kỳ file save nào. |
| **Bước 4** | Viết unit test vòng đời `60x` & chạy kiểm thử `gdUnit4` | `tests/unit/test_farm_logic_and_visuals.gd` | Dòng `118–180` / Tổng `180` dòng | Thêm test case `test_phase1_timing_and_dev_speed_multiplier()` kiểm chứng:<br>- `TickManager.calculate_finish_timestamp(1200)` ở `1x` (~`1200s`) và `60x` (~`20s`).<br>- `AnimalPen` (`chicken`) đọc đúng `produce_time_seconds = 1200` từ `animals.json` (ở `1x` là `~1200s`, ở `60x` là `~20s`).<br>- `ProductionMachine` (`feed_mill`, công thức `chicken_feed`) đọc đúng `craft_time_seconds = 300` (không bị cap `60s`), trả đủ `produce_count = 3` bao cám và cộng đúng `xp_reward = 1` khi `collect_all()`. |

---

## 2. KẾT QUẢ CHẠY KIỂM THỬ `gdUnit4` THỰC TẾ (VỚI CỜ `-c`)

### Lệnh thực thi
```powershell
& "D:\Gotdot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --path . --headless -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit -a res://tests/playtest -c --ignoreHeadlessMode
```

### Tóm tắt kết quả
- **Exit code:** `0` (**PASSED**)
- **Tổng hợp:** `6 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans`
- **Test Suites đã chạy:** `2/2` (`res://tests/unit/test_farm_logic_and_visuals.gd` và `res://tests/playtest/random_bot_test.gd`)
- **Tổng thời gian thực thi:** `15s 882ms`
- **Báo cáo lưu tại:** `reports/report_5/results.xml` và `reports/report_5/index.html`

### Bảng kết quả chi tiết từng Test Case

| STT | Test Suite | Test Case | Trạng thái | Thời gian | Ghi chú kiểm chứng |
| :---: | :--- | :--- | :---: | :---: | :--- |
| 1 | `tests/unit/test_farm_logic_and_visuals.gd` | `test_economy_and_inventory_never_negative` | **PASSED** | `4ms` | Tiền và kho không bao giờ âm |
| 2 | `tests/unit/test_farm_logic_and_visuals.gd` | `test_crop_growth_stage_bounds` | **PASSED** | `5ms` | Giai đoạn cây trồng nằm trong `[0, 3]` |
| 3 | `tests/unit/test_farm_logic_and_visuals.gd` | `test_all_sprites_valid_and_corners_transparent` | **PASSED** | `8s 503ms` | Đã miễn trừ `boot_splash_keyart.png` & `title_screen_keyart.png`, giữ nguyên ngưỡng `alpha <= 0.05` cho các sprite khác (`0 failures`) |
| 4 | `tests/unit/test_farm_logic_and_visuals.gd` | `test_sprite_atlas_item_icons_not_mismatched` | **PASSED** | `3ms` | Icon `bread` và `vinegar` tách biệt |
| 5 | `tests/unit/test_farm_logic_and_visuals.gd` | `test_phase1_timing_and_dev_speed_multiplier` | **PASSED** | `4ms` | Kiểm chứng `1200s -> 20s` ở `60x`, `AnimalPen` đọc `1200s`, `ProductionMachine` đọc `300s` & trả `produce_count = 3`, `xp_reward = 1` |
| 6 | `tests/playtest/random_bot_test.gd` | `test_random_bot_200_steps_visual_and_logic_invariants` | **PASSED** | `7s 275ms` | Vượt qua 200 bước tương tác ngẫu nhiên với `FIXED_SEED = 20261102` (`0 errors`, `0 failures`) |

---

## 3. CHECKLIST KIỂM CHỨNG MỤC 4 TRONG `docs/HANDOVER.md`

- [x] `docs/phase1_log.md` tồn tại và có bảng từng bước (`Bước 0` $\rightarrow$ `Bước 4`).
- [x] `AnimalPen` không còn `var duration: int = 15` (đã thay bằng `var duration: int = int(a_data.get("produce_time_seconds", 1200))` tại `scripts/entities/animal_pen.gd` dòng `418`).
- [x] `ProductionMachine` không còn `mini(craft_time_seconds, 60)` tại cả 3 vị trí (dòng `187`, `274`, `359` trong `scripts/entities/production_machine.gd`) và dùng đúng `produce_count`, `xp_reward`.
- [x] `TickManager` có guard `_is_test_environment()` ép `dev_speed_multiplier = 1.0` ngoài môi trường test (`scripts/core/tick_manager.gd` dòng `4–12`, `32–35`), và `dev_speed_multiplier` được reset về `1.0` trong `after_test()` (`tests/unit/test_farm_logic_and_visuals.gd` dòng `4–5`).
- [x] Unit + playtest: **PASSED 100% (`6/6 test cases`, gồm 5 test cũ + 1 test mới của Phase 1, `0 errors`, `0 failures`)** khi chạy với cờ `-c`.
- [x] Không có save file nào bị lưu `dev_speed_multiplier` (đã kiểm chứng `scripts/core/save_manager.gd` dòng `450–557`).
- [x] Đã đọc `GEMINI.md` và ghi đề xuất sửa dòng 11 bên dưới theo quyết định D1 & D5.

---

## 4. ĐỀ XUẤT SỬA DÒNG 11 CỦA `GEMINI.md` (THEO QUYẾT ĐỊNH D1 & D5)

### Nội dung hiện tại tại dòng 11 của `GEMINI.md`
```markdown
  1. **Trồng trọt (`FieldPlot`):** Ô đất trống (`EMPTY`) -> Chọn hạt giống (Lúa Mì/Ngô) chạm/lướt vào để gieo (`GROWING`) -> Đếm ngược nhanh (Lúa mì: 10 giây, Ngô: 20 giây để dễ test) -> Chín (`READY`) -> Dùng `Liềm` thu hoạch nhận x2 nông sản + XP, trả ô đất về `EMPTY`.
```

### Nội dung đề xuất thay thế (Đồng bộ với Quyết định D1 — Phương án B & D3 `dev_speed_multiplier`)
```markdown
  1. **Trồng trọt (`FieldPlot`):** Ô đất trống (`EMPTY`) -> Chọn hạt giống (Lúa Mì/Ngô) chạm/lướt vào để gieo (`GROWING`) -> Đếm ngược theo dữ liệu chuẩn `data/crops.json` (ví dụ Lúa mì: 180 giây, Ngô: 480 giây; khi chạy automated test có thể bật `TickManager.dev_speed_multiplier` trong test mode để rút ngắn thời gian kiểm thử) -> Chín (`READY`) -> Dùng `Liềm` thu hoạch nhận x2 nông sản + XP, trả ô đất về `EMPTY`.
```
