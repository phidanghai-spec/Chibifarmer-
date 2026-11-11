# RÀ SOÁT CODE & DANH SÁCH CẢI THIỆN — 11/11/2026

Mục tiêu: sửa lỗi còn tồn đọng, giảm lãng phí (CPU, log, token khi đọc output test), không đổi cân bằng kinh tế (Phase 2A chưa duyệt).

| # | Vấn đề | File | Tác động | Nhóm |
|---|---|---|---|---|
| 1 | `SpriteAtlasManager` in ~400 dòng "Loaded authentic standalone texture" mỗi lần chạy | `sprite_atlas_manager.gd` | Log rác, tốn token khi đọc output test/CI | A |
| 2 | `SaveManager` in "Game state saved..." mỗi lần lưu (10–20 lần/phiên) | `save_manager.gd` | Log rác | A |
| 3 | Không có script chạy test chỉ in tóm tắt | `tools/run_tests.ps1` (mới) | Mỗi lần kiểm thử phải đọc ~1.000 dòng log | A |
| 4 | CI dùng `godot-version: '4.3'` trong khi dự án là 4.7 (`config/features` "4.7") | `.github/workflows/test.yml` | CI có thể fail hoặc test sai engine | A |
| 5 | `MAX_OFFLINE_SECONDS` 28800 (`SaveManager`) vs `MAX_OFFLINE_CAP_SECONDS` 86400 (`OfflineSimulator`) | `offline_simulator.gd` | Báo cáo vắng nhà hiển thị 24h nhưng save chỉ tính 8h | B |
| 6 | Chuỗi "Vườn Thú Bờ Tây" (đúng là Bờ Đông) | `offline_simulator.gd`, `tourism_star_director.gd` | Sai nội dung UI | B |
| 7 | `DailyNewspaper` hardcode giá 15/17 món (`cookie` 45 vs 150, `cream_cake` 80 vs 260) | `daily_newspaper.gd` | Exploit mua rẻ bán đắt | B |
| 8 | `FishingSpot.handle_fishing_click()` không chặn khi minigame đang mở | `fishing_spot.gd` | Click đúp mở đè minigame | C |
| 9 | Bóng elip tạo bằng vòng lặp `set_pixel` cho từng công trình/chuồng | `main_farm.gd`, `animal_pen.gd` | Tốn CPU lúc load, trùng code | C |
| 10 | Hai scene chính trùng nhau `scenes/main_farm.tscn` và `scenes/main/MainFarm.tscn` | `scenes/` | Dễ sửa nhầm (R8) | C |

## Ngoài phạm vi lần này (cần chủ dự án quyết định)
- SSOT `items.json` vs `crops.json`, giá ngô 7/9, mồi câu miễn phí → Phase 2A.
- `AnimalPen.feed()` cho ăn miễn phí khi hết cám và vàng < 2 (chống kẹt, nhưng có thể khai thác).
- `SaveManager.load_game()` xóa save khi version cũ hơn → rủi ro R5, cần migration thay vì reset.
- `MapBuilder.build_farm()` chưa gate công trình theo level.

## Kết quả thực thi (Đã hoàn tất & Kiểm chứng)
- **Nhóm A (Log & Tooling — Subagent `cb2d94cc`):**
  1. `scripts/core/sprite_atlas_manager.gd`: Thêm `const VERBOSE_LOG: bool = false`, ẩn ~400 dòng log nạp từng texture, chỉ in 1 dòng tóm tắt `SpriteAtlasManager: Loaded 403 textures.` khi khởi động.
  2. `scripts/core/save_manager.gd`: Thêm `const VERBOSE_LOG: bool = false`, ẩn các dòng log lưu/tải định kỳ (`push_error` vẫn giữ nguyên).
  3. `tools/run_tests.ps1`: Tạo script chạy kiểm thử tự động loại bỏ mã màu ANSI và lọc tóm tắt, rút gọn output từ ~1.000 dòng xuống **17 dòng** (tiết kiệm >95% token khi đọc kết quả test).
  4. `.github/workflows/test.yml`: Đồng bộ `godot-version: '4.7.2'` khớp với cấu hình Godot 4.7 của dự án.
- **Nhóm B (Data Consistency — Subagent `8114ad84`):**
  5. `scripts/core/offline_simulator.gd`: Đồng bộ `MAX_OFFLINE_CAP_SECONDS = 28800` (8 giờ) khớp với `SaveManager.MAX_OFFLINE_SECONDS`.
  6. `scripts/core/offline_simulator.gd`, `scripts/systems/tourism_star_director.gd`: Sửa chuỗi `"Vườn Thú Bờ Tây"` thành `"Vườn Thú Bờ Đông"`.
  7. `scripts/systems/daily_newspaper.gd`: Đồng bộ bảng `GOODS_CATALOG` và tra cứu động `DataManager.get_item_base_price(item_id)` khi sinh báo, triệt tiêu lỗ hổng mua rẻ bán đắt (`cookie` 150 vàng, `cream_cake` 260 vàng).
- **Nhóm C (Runtime Robustness — Subagent `7d974d7f`):**
  8. `scripts/entities/fishing_spot.gd`: Thêm chốt chặn `if _minigame != null and _minigame.is_active: return true` trong `handle_fishing_click()`, ngăn click đúp mở chồng minigame câu cá.
  9. `scripts/core/main_farm.gd`, `scripts/entities/animal_pen.gd`: Thêm bộ nhớ đệm `static var _shadow_texture_cache: Dictionary = {}` theo kích thước `Vector2i`, chỉ tính toán `ImageTexture` bóng elip 1 lần cho mỗi kích thước thay vì lặp `set_pixel` từng thực thể.
  10. Xóa scene trùng lặp `scenes/main_farm.tscn` và cập nhật toàn bộ 8 script test trong `tests/` trỏ về scene chuẩn `res://scenes/main/MainFarm.tscn`.
- **Kiểm thử (`tests/unit/test_exploit_guards.gd`):**
  - Bổ sung test `test_newspaper_prices_offline_cap_and_fishing_double_click`.
  - Kết quả chạy `tools/run_tests.ps1`: **10/10 test cases PASSED** (`0 errors | 0 failures`, `Exit code: 0`).


