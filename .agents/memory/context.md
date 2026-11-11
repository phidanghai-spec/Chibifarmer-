# Hay Day Offline (Chibifarmer-) — Project Memory & Context

## 1. Kiến trúc & Quy chuẩn Cốt lõi
- **Engine:** Godot 4.7.2 Standard (GL Compatibility), 1152x648 @ 60 FPS, 100% GDScript 2.0 Static Typing.
- **Phong cách mỹ thuật:** 2.5D Cozy Chibi Pastel Storybook, nét viền nâu ấm (`#4A2C18`), nền trong suốt RGBA qua giải thuật BFS Floodfill 4 góc (`tools/chibi_asset_forge.py`).
- **Tương tác chuột:** Mọi `Control`/`Container` không phải nút bấm phải giữ `mouse_filter = Control.MOUSE_FILTER_IGNORE` (số 2).

## 2. Trạng thái Hoàn thiện (Sprint 6)
- **Backlog Kỹ thuật (5/5 DONE):**
  1. `SaveManager` tự động cô lập file lưu sang `user://test_bot_temp_save.json` khi chạy test trong `res://tests/`.
  2. `SaveManager` ghi file nguyên tử (Atomic Save qua `.tmp` + `DirAccess.rename_absolute`).
  3. `VisitorNPC`, `AnimalPen`, `ZooEnclosure` tích hợp `VisibleOnScreenNotifier2D` tắt phép tính lượng giác khi nằm ngoài camera.
  4. `GridManager` giới hạn tối đa 3 truy vấn `AStarGrid2D`/frame kèm `_path_cache` và hàng đợi `_pending_path_queue`.
  5. `InteractiveTree` giải phóng ô lưới trong `_exit_tree()`, vượt qua 100% `test_scenery_builder.tscn`.
- **UI/UX & Game Juice:**
  - `UIHud` hỗ trợ `animate_modal_open()` / `animate_modal_close()` cho toàn bộ 9 Modal (có nhánh bypass cho headless test).
  - Thanh tiến trình `ProgressSilo` và `ProgressBarn` hiển thị trực quan với 3 mức màu (Xanh, Vàng cam, Đỏ cam).
  - `TourismStarHUD` đặt ở hàng thứ 2 góc trên phải (`offset_top = 60`), không đè lên `TopRightHUD`.
  - `FieldPlot` có hiệu ứng nảy mầm/chín và lắng nghe thời tiết mưa (`COZY_RAIN` +25% tốc độ); `ProductionMachine` có hạt khói `CPUParticles2D`; `AnimalPen` dùng bong bóng thoại Chibi; `ZooEnclosure` cho phép Chim Cánh Cụt ăn cá tươi (+50% Tip).
- **6 Sprite Chibi & Chuỗi Giá Trị Mới:**
  - `item_fish_pie`, `item_grilled_fish`, `item_herbal_tea`, `item_bacon_eggs`, `decor_picnic_table`, `visitor_photographer`.
