# BÁO CÁO KỸ THUẬT TỔNG HỢP & BÀN GIAO DỰ ÁN
## Hay Day Offline - Cozy Farm & Tourism Management (Chibifarmer-)

---

## 1. Hồ Sơ Kỹ Thuật & Kiến Trúc Cốt Lõi (Technical Baseline)
Dự án được xây dựng theo mô hình **Event-Driven Architecture (Kiến trúc hướng sự kiện)** kết hợp **Data-Driven Design**, tách biệt hoàn toàn tầng hiển thị và tầng dữ liệu để đảm bảo hiệu năng tối ưu trên các thiết bị cấu hình văn phòng.

* **Nền tảng Engine:** Godot Engine 4.7.2 Standard (GL Compatibility), độ phân giải chuẩn **1152x648 @ 60 FPS**.
* **Tiêu chuẩn mã nguồn:** **100% GDScript 2.0 Static Typing**, đảm bảo không phát sinh lỗi biên dịch hoặc cảnh báo kiểu dữ liệu.
* **Phong cách mỹ thuật:** 2.5D Cozy Chibi Storybook với nét viền nâu ấm (`#4A2C18`), hoàn toàn không có viền đen, ứng dụng giải thuật lọc nền BFS từ 4 góc và khử răng cưa viền 1px.
* **Hệ thống Autoload trung tâm (11 Singletons):** 
  * `EventBus`, `DataManager`, `TickManager`, `StorageManager`, `GridManager`, `SpriteAtlasManager`, `SaveManager`, `AudioManager`, `DailyNewspaper`, `TruckOrderSystem`, `RoadsideShop`, cùng hệ thống nhiệm vụ `QuestManager`.

---

## 2. Tiến Độ Hoàn Thiện Qua 6 Sprints & Bộ Kiểm Thử Tự Động

Quy trình phát triển đã triển khai qua 6 giai đoạn trọng tâm, kết hợp bộ kiểm thử tự động (`gdUnit4 v6.2.3`, Visual Audit quét độ trong suốt 4 góc ảnh, `test_scenery_builder`, `test_sprint4_5`, `test_overnight_master` và Random Bot 200 bước) đạt kết quả nghiệm thu tuyệt đối:

1. **Sprint 1 — Khởi Động & Ô Lưu (Boot & Save System):** 
   * Xây dựng màn hình `BootSplash` với hoạt ảnh cối xay gió và bó lúa mì 60 FPS.
   * Xây dựng màn hình chính `TitleScreen` với cảnh panorama động (khinh khí cầu, tàu hơi nước, đàn vịt, thỏ nhảy) và hệ thống quản lý 3 ô lưu (`SaveSlotService`) đồng bộ Unix Timestamp.
2. **Sprint 2 — Tạo Nhân Vật & Trang Phục Đa Lớp (Character Creator & Paper-Doll):** 
   * Lập trình thực thể `ModularChibiAvatar` tích hợp công thức chuyển động toán học 60 FPS: *Idle Breathing*, *Walk Bounce*, và *Dynamic Shadow*.
   * Xây dựng màn hình chọn nhân vật Nam/Nữ phối sẵn trang phục đồng bộ.
3. **Sprint 3 — Cốt Truyện Mở Đầu & Hướng Dẫn Tân Thủ (Intro & Onboarding):** 
   * Tái hiện hoạt cảnh tàu hơi nước cập bến cảng sông, chú chó Poodle đón chủ bên cầu gỗ.
   * Kịch bản hướng dẫn tương tác 3 bước (Gặt/gieo lúa mì, Máy xay cám, Lát đường đá sỏi).
   * Hộp thoại tổng hợp lợi nhuận vắng nhà (`OfflineSimulator`) tính thu nhập từ Vườn Thú Bờ Đông.
4. **Sprint 4 — Thời Tiết Sinh Thái & Du Lịch 5 Sao (Weather & Tourism):** 
   * Quản lý chu kỳ ngày-đêm (4 khung giờ ánh sáng qua `CanvasModulate`) và thời tiết (Nắng gió, Mưa ấm tăng 25% tốc độ cây, Lễ hội khinh khí cầu).
   * Hệ thống tính điểm `AttractionScore` quy đổi cấp 1–5 Sao Du Lịch và quầy check-in chụp ảnh tại vườn thú (`ZooPhotoBooth`).
5. **Sprint 5 — Bách Khoa Nông Trại Almanac & Kiểm Toán Tự Động:** 
   * Hoàn thiện sổ tay Almanac 4 nhóm sưu tập (Cây trồng, Thú nuôi & Zoo, Ẩm thực, Du khách) kèm phần thưởng Vàng khám phá.
   * Vận hành bộ kiểm thử đơn vị và Bot 200 bước đảm bảo không rò rỉ bộ nhớ (`0 orphans`).
6. **Sprint 6 — Tối Ưu Hóa Backlog, Game Juice UI/UX & Chuỗi Giá Trị Nông Trại Du Lịch:**
   * Hoàn thành 100% 5 hạng mục Backlog kỹ thuật (`[P0]` Cô lập file lưu khi test, `[P0]` Atomic Save `.tmp`, `[P1]` `VisibleOnScreenNotifier2D`, `[P1]` Hàng đợi `AStarGrid2D` 3 yêu cầu/frame, `[P2]` Dọn dẹp chu kỳ xử lý & rò rỉ ô lưới `InteractiveTree`).
   * Nâng cấp hệ thống hoạt ảnh **Game Juice** (Tween mở/đóng 9 Modal, thanh tiến trình kho 3 màu, nảy mầm/chín trên ô ruộng, khói ống khói `CPUParticles2D`, bong bóng Chibi trên chuồng thú, nghiêng con trỏ khi kéo-lướt).
   * Bổ sung 6 Sprite Chibi mới (`item_fish_pie`, `item_grilled_fish`, `item_herbal_tea`, `item_bacon_eggs`, `decor_picnic_table`, `visitor_photographer`) và kết nối chuỗi giá trị Hồ Câu Cá – Vườn Hoa/Mật Ong – Lò Chế Biến – Sở Thú Bờ Đông (Chim Cánh Cụt ăn cá tươi thưởng +50% Tip Du Lịch).

---

## 3. Tổng Hợp Các Lỗi Thực Tế Đã Khắc Phục Triệt Để

| Hạng Mục Lỗi | Nguyên Nhân Gốc Rễ | Giải Pháp Kỹ Thuật Đã Áp Dụng |
| :--- | :--- | :--- |
| **Màn hình đen khi mở game** | Lỗi thứ tự thẻ tài nguyên `ext_resource` trong file `.tscn` | Chuẩn hóa lại cú pháp scene và chạy lệnh reimport asset trên Godot Editor. |
| **Thỏ & Tim Poodle che màn hình** | Gán đè tỷ lệ scale = 1.0 và hiển thị texture kích thước gốc | Khóa tỷ lệ render trái tim tối đa 28x28 px; lưu `_base_scale` cho các sprite panorama. |
| **Tàu thủy chạy trên đất liền** | Đặt nhầm tọa độ bến cảng lên bãi cỏ phía sau kho | Dời bến tàu ra sát mép sông `(875, 310)`, thân tàu di chuyển dọc lòng sông sâu `(967, 310)`. |
| **Cây cối đè lên luống ruộng** | Cây cảnh tĩnh chưa gắn vùng cản và thiếu tương tác | Chuyển thành `InteractiveTree` cho phép người chơi kéo di chuyển hoặc chặt bỏ; tự động dịch chuyển cây đè ruộng khi nạp map. |
| **Icon Bánh mì trỏ nhầm Chai giấm** | Ánh xạ vùng cắt `Rect2` trong `SpriteAtlasManager` bị lệch | Trỏ ID `bread` về đúng file ảnh bánh mì đã cắt sẵn trong thư mục `assets/`. |
| **Rò rỉ ô lưới khi tái tạo cảnh quan** | `InteractiveTree` bị `queue_free()` nhưng không xóa ô trong `GridManager.occupied_cells` | Bổ sung `_exit_tree()` gọi `_update_grid_solid(false)`, giúp `test_scenery_builder` đạt 100% PASS. |
| **Đứt kết nối Signal Câu Cá & Almanac** | Thiếu emit `EventBus.fish_caught` và `EventBus.visitor_spawned` | Phát đầy đủ signal tại `fishing_spot.gd` và `visitor_manager.gd`, nối `weather_state_changed` vào `field_plot.gd`. |

---

## 4. Onboarding Checklist Cho Godot Engineer

Khi tiếp nhận mã nguồn tại kho chứa `phidanghai-spec/Chibifarmer-`, kỹ sư cần thực hiện các bước sau:

1. **Kiểm tra môi trường:** Mở `project.godot` bằng đúng phiên bản **Godot 4.7.2 Standard (GL Compatibility)**.
2. **Xác nhận Autoload & Plugin:** Đảm bảo 11 Autoload cốt lõi đã bật trong Project Settings và plugin `gdUnit4` đã kích hoạt trong thư mục `addons/`.
3. **Chạy script kiểm toán tài nguyên:**
   ```bash
   python tools/asset_audit.py
   ```
4. **Thực thi bộ kiểm thử cục bộ:**
   ```bash
   addons/gdUnit4/runtest.cmd --godot_binary "<đường_dẫn_godot_console.exe>" -a res://tests/unit -a res://tests/playtest --ignoreHeadlessMode
   ```

---

## 5. Trạng Thái Backlog Kỹ Thuật (Đã Nghiệm Thu 100%)

- [x] **[P0] Tẩy uế/Cô lập tệp lưu khi chạy Test:** Tự động chuyển hướng `SaveManager` sang `user://test_bot_temp_save.json` khi chạy test trong `res://tests/`, không ghi đè dữ liệu chơi thật của người dùng.
- [x] **[P0] Cơ chế ghi tệp lưu nguyên tử (Atomic Save):** Ghi qua tệp tạm `.tmp` rồi thực hiện `DirAccess.rename_absolute()` phòng chống hỏng tệp JSON khi đóng đột ngột.
- [x] **[P1] Tắt tính toán ngoài khung nhìn:** Đã gắn `VisibleOnScreenNotifier2D` cho `VisitorNPC`, `AnimalPen` và `ZooEnclosure` để tạm dừng hàm lượng giác khi nằm ngoài camera, giữ vững 60 FPS.
- [x] **[P1] Hàng đợi tìm đường `AStarGrid2D`:** Giới hạn tối đa 3 yêu cầu tìm đường mỗi khung hình kết hợp bộ nhớ đệm `_path_cache` và hàng đợi `_pending_path_queue`.
- [x] **[P2] Tối ưu chu kỳ xử lý & Gộp hiển thị:** Đã loại bỏ hàm `_process` / `_draw` rỗng trên các thực thể tĩnh và đồng bộ giải phóng ô lưới.
