# 🧠 Context & Architecture Memory: HayDayOffline (D:\HayDayOffline)
Cập nhật: 2026-10-22
Tiêu chuẩn: Godot 4.7.2 Standard (GL Compatibility, 1152x648, GDScript 2.0 Static Typing, 0 Errors, 0 Warnings).

---

## 1. Tổng Quan Kiến Trúc & Các Autoloads Toàn Cục
1. **EventBus (`scripts/core/event_bus.gd`)**:
   - Khai báo `@warning_ignore("unused_signal")` ở dòng đầu tiên.
   - Quản lý các signal kinh tế, kho bãi, tick thời gian, thu hoạch loot: `loot_collected(item_id, count, pos)`.
2. **StorageManager (`scripts/core/storage_manager.gd`)**:
   - Quản lý kho Silo (nông sản, cây quả, hạt giống) & Barn (sữa, trứng, bánh mì, thức ăn gia súc, cá chép, v.v.).
   - Biến tiền tệ: `gold`, `diamonds`, `current_xp`, `current_level`.
   - **QUY TẮC BẮT BUỘC**: Luôn truy cập trực tiếp `StorageManager.gold`, KHÔNG được gọi `StorageManager.get_gold()` (dù đã có fallback).
   - Tự động cung cấp hạt giống mặc định: `wheat`, `corn`, `apple_seed`, `mango_seed`.
3. **DataManager (`scripts/core/data_manager.gd`)**:
   - Nạp cấu hình từ `res://data/` (`crops.json`, `items.json`, `buildings.json`, `recipes.json`).
   - Đã đăng ký đầy đủ vật phẩm: `apple`, `mango`, `apple_seed`, `mango_seed`, `fish_carp`.
4. **TickManager (`scripts/core/tick_manager.gd`)**:
   - Quản lý thời gian thực Unix timestamp.
   - Các phép chia được ép kiểu float chuẩn `int(float(...) / 3600.0)` để triệt tiêu cảnh báo debugger.
5. **GridManager (`scripts/core/grid_manager.gd`)**:
   - Quản lý bản đồ ô 32x32, AStar2D đường đi du khách, điểm du lịch `total_attraction_score`.
6. **SpriteAtlasManager (`scripts/core/sprite_atlas_manager.gd`)**:
   - Tích hợp chuẩn **`agent-sprite-forge`** (`https://github.com/phidanghai-spec/agent-sprite-forge` & `d:\asf-work`).
   - Tự động nhận diện texture đơn lẫn SpriteSheet đa khung hình (`hframes`/`vframes`).
7. **SaveManager (`scripts/core/save_manager.gd`)**:
   - Lưu tại `user://hayday_save.json`. Tự động khôi phục hạt giống cây gỗ nếu file save cũ chưa có.

---

## 2. Các Thực Thể & Cơ Chế Đã Hoàn Thiện
1. **Cây Ăn Quả (Táo & Xoài) (`scripts/entities/movable_decor.gd`)**:
   - Hái quả mượt mà bằng cả **tay không (`ToolType.NONE`)** lẫn **cầm Liềm (`ToolType.SICKLE`)**.
   - Khi hái Cây Táo: +2 apple, +1 hạt giống (apple_seed hoặc mango_seed), +3 Sao Du Lịch.
   - Khi hái Cây Xoài: +2 mango, +1 hạt giống, +4 Sao Du Lịch.
   - Trồng cây mới từ HUD "🌱 Hạt Giống" trải qua 3 giai đoạn: Mầm Non (`scale = 0.55`, 15s) -> Đang Lớn (`scale = 0.8`, 15s) -> Chín Rực Rỡ (`scale = 1.0`).
2. **Hồ Câu Cá & Minigame Canh Nhịp (`scripts/entities/fishing_spot.gd` & `scripts/systems/fishing_minigame.gd`)**:
   - Vùng click bao phủ cả Cầu Gỗ và Mặt Hồ: `Rect2(Vector2(560.0, 560.0), Vector2(540.0, 300.0))`.
   - Nhãn trạng thái nổi bật trên Cầu Gỗ tại `Vector2(-260, -35)`: `"🎣 BẤM CÂU CÁ"` (sẵn sàng) hoặc `"⏳ HỒI: 00:%02d"` (15s).
   - Popup Minigame nằm chính giữa màn hình `(376, 194)` trên `CanvasLayer` (layer 30), kim quét dao động êm, bấm `"🪝 GIẬT CẦN CÂU!"` nhận +1 cá chép, +20 vàng, +5 XP, hồ hồi 15s.
3. **Chuồng Bò & Gia Súc (`scripts/entities/animal_pen.gd`)**:
   - Bò có nhịp thở và nhai cỏ đàn hồi `(1.0 + chew, 1.0 - chew * 0.6)`, di chuyển thong thả trong hàng rào gỗ.
   - Cho ăn bằng cám bò, ngô hoặc lúa mì. Nếu thiếu nguyên liệu, trừ trực tiếp 2 Vàng (`StorageManager.gold >= 2`). Thu hoạch nhận +2 sữa bò.
4. **Máy Sản Xuất (`scripts/entities/production_machine.gd`)**:
   - Lò Bánh Mì và Máy Xay Thức Ăn: Click khi `"SẴN SÀNG"` sẽ 1-click thu hoạch về kho Barn và tự động chạy mẻ mới.
5. **Du Khách Tham Quan (`scripts/visitors/visitor_npc.gd`)**:
   - Nội suy vận tốc quán tính 60 FPS: `_current_velocity = _current_velocity.lerp(desired_velocity, delta * 8.0)`.
   - Nhịp nhún bước chân: `-absf(sin(_walk_phase)) * 4.5`, nghiêng người: `sin(_walk_phase) * 0.055`.
   - Nhịp thở khi đứng yên, bóng đổ co giãn theo độ cao bước nhảy.
   - Bong bóng nhu cầu: `"🛒 Cần: 1 🍎 (+35🪙)"`, v.v. Click vào để bán nhận Vàng + XP + Sao Du Lịch.
6. **Hệ Sinh Thái Động Vật Nhỏ (`scripts/core/main_farm.gd`)**:
   - Thỏ: Nhảy nhịp parabol (`hop arc`) kèm co giãn squash & stretch.
   - Gà & Chim: Động tác mổ thóc khi đứng và chạy lạch bạch khi di chuyển.
   - Vịt hồ: Bơi lướt có quán tính, nghiêng góc rẽ và sóng nước elip dưới bụng.
   - Bướm & Ong: Bay nhịp cánh flutter trên không, không kích hoạt trạng thái bơi.
7. **Thanh HUD (`scripts/interaction/ui_hud.gd`)**:
   - Menu Hạt Giống 4 nút: Lúa Mì, Ngô, Mầm Cây Táo, Mầm Cây Xoài.
   - Nút Xe Tải hiển thị chuẩn icon xe chở hàng chibi. Xe tải giao hàng đỗ tại `(435, 660)` trên đường gạch.

---

## 3. Thứ Tự Điều Phối Click Chuột Trong `main_farm.gd` (`simulate_click_at_world_pos`)
1. `MovableDecor` (Cây Ăn Quả, radius <= 60px)
2. `AnimalPen` (Chuồng Thú, radius <= 95px)
3. `ProductionMachine` (Lò Bánh Mì, Máy Xay, radius <= 75px)
4. `VisitorNPC` (Du Khách, radius <= 55px)
5. `FishingSpot` & Cầu Gỗ (`Rect2(560.0, 560.0), Vector2(540.0, 300.0)`)

---

## 4. Lệnh Chạy Kiểm Thử & Chụp Ảnh Nghiệm Thu
- Console Godot: `& "D:\Gotdot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"`
- Chạy test kiểm thử tự động: `--headless --path "D:\HayDayOffline" "res://tests/test_interactive_clicks.tscn"` (7/7 PASSED)
- Chụp ảnh màn hình: `--path "D:\HayDayOffline" "res://tests/capture_screenshot.tscn"` -> lưu ra `debug_preview.png`.
