# BÁO CÁO KẾT QUẢ TEST BASELINE (`gdUnit4`)

- **Thời điểm đo baseline:** `2026-11-11 12:36–12:38 (+07:00)`
- **Môi trường:** `Godot Engine v4.7.2.stable.official.ed1daf0bf` (Windows Console Headless), `gdUnit4 v6.2.3`
- **Trạng thái mã nguồn:** Chưa chỉnh sửa bất kỳ code hay file JSON nào trước khi tái cấu trúc dữ liệu.

---

## 1. KẾT QUẢ CHẠY LỆNH MẶC ĐỊNH (`fail-fast` mặc định)

### Lệnh thực thi
```powershell
& "D:\Gotdot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --path . --headless -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit -a res://tests/playtest --ignoreHeadlessMode
```

### Tóm tắt kết quả
- **Exit code:** `100` (`FAILED`)
- **Tổng hợp:** `4 test cases | 0 errors | 4 failures | 0 flaky | 0 skipped | 0 orphans` *(tổng 5 test case được phát hiện nhưng suite `unit` dừng ngay sau ca thứ 3 bị fail nên ca thứ 4 là `test_sprite_atlas_item_icons_not_mismatched` không chạy ở lượt mặc định)*
- **Suites đã chạy:** `2/2`
- **Thời gian thực thi:** `27s 176ms`
- **Báo cáo chi tiết:** `reports/report_1/results.xml` và `reports/report_1/index.html`

---

## 2. KẾT QUẢ CHẠY ĐẦY ĐỦ VỚI CỜ `-c` (CONTINUE / CHẠY HẾT TẤT CẢ TEST CASE)

### Lệnh thực thi
```powershell
& "D:\Gotdot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --path . --headless -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit -a res://tests/playtest -c --ignoreHeadlessMode
```

### Tóm tắt kết quả
- **Exit code:** `100` (`FAILED`)
- **Tổng hợp:** `5 test cases | 0 errors | 4 failures | 0 flaky | 0 skipped | 0 orphans`
- **Suites đã chạy:** `2/2`
- **Thời gian thực thi:** `10s 818ms`
- **Báo cáo chi tiết:** `reports/report_2/results.xml` và `reports/report_2/index.html`

### Bảng chi tiết từng Test Case

| Test Suite | Test Case | Trạng thái | Thời gian | Ghi chú / Nguyên nhân |
| :--- | :--- | :---: | :---: | :--- |
| `tests/unit/test_farm_logic_and_visuals.gd` | `test_economy_and_inventory_never_negative` | **PASSED** | `3ms` | Kiểm tra `StorageManager.spend_gold` và `remove_item` không âm |
| `tests/unit/test_farm_logic_and_visuals.gd` | `test_crop_growth_stage_bounds` | **PASSED** | `2ms` | Kiểm tra chặn trần `max_stage = 3` |
| `tests/unit/test_farm_logic_and_visuals.gd` | `test_all_sprites_valid_and_corners_transparent` | **FAILED** *(4 failures)* | `2s 169ms` *(lượt 1: `14s 733ms`)* | **4 thất bại tại dòng 72 & 75** trên 2 ảnh toàn màn hình mới thêm: `boot_splash_keyart.png` và `title_screen_keyart.png` (góc dưới trái & phải không trong suốt; danh sách `is_exempt` ở dòng 60 chưa miễn trừ `"keyart"`) |
| `tests/unit/test_farm_logic_and_visuals.gd` | `test_sprite_atlas_item_icons_not_mismatched` | **PASSED** | `9ms` | Không chạy ở lượt default (do fail-fast); chạy và PASS ở lượt `-c` |
| `tests/playtest/random_bot_test.gd` | `test_random_bot_200_steps_visual_and_logic_invariants` | **PASSED** | `8s 561ms` *(lượt 1: `12s 359ms`)* | Chạy đủ 200 bước với `FIXED_SEED = 20261102`, `0 errors`, `0 failures` |

---

## 3. GHI CHÚ BASELINE TRƯỚC KHI CHUYỂN ĐỔI DỮ LIỆU

1. **Tất cả lỗi biên dịch & playtest 200 bước đều sạch:** `0 errors`, `0 orphans`, `random_bot_test` đi qua 200 bước an toàn trên `MainFarm.tscn`.
2. **Nguyên nhân fail duy nhất hiện tại (4 failures):** Chỉ do 2 ảnh keyart toàn cảnh mới được thêm vào thư mục `assets/sprites/` (`boot_splash_keyart.png` và `title_screen_keyart.png`) chưa được đưa vào ngoại lệ `is_exempt` của `test_all_sprites_valid_and_corners_transparent` (không phải lỗi logic hay vỡ asset sprite).
3. **Thiếu độ phủ test JSON/kinh tế hiện tại:** Bộ unit test hiện mới có 4 case cơ bản; chưa có test kiểm chứng giá trị trong `crops.json`, `items.json`, `recipes.json`, `animals.json`, `buildings.json` hay kiểm tra vòng lặp thu hoạch thực tế trên `FieldPlot`, `AnimalPen`, `ProductionMachine`.

