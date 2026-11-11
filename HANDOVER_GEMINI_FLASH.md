# 📋 BẢN BÀN GIAO KỸ THUẬT & TỔNG KẾT TOÀN DIỆN (HAY DAY OFFLINE)
**Dự án:** Hay Day Offline - Chibi Farm & Tourism Management (`d:\HayDayOffline`)  
**Engine:** Godot 4.7.2 Standard (`GL Compatibility`) — **100% Static Typing GDScript 2.0**  
**Trạng thái:** Toàn bộ 8/8 yêu cầu của người chơi đã hoàn thành xuất sắc, biên dịch 0 lỗi, kiểm thử thị giác đạt chuẩn 2.5D Chibi Cozy Farm.

---

## 1. TỔNG KẾT CÁC TÍNH NĂNG ĐÃ HOÀN THÀNH

### 1.1. Sửa Lỗi Nhân Vật Cầm Dụng Cụ Trong `CharacterCreator`
- **Trước đây:** Liềm (`tool_sickle_chibi.png`) và Cần câu (`tool_fishing_rod_chibi.png`) là nét vẽ mảnh, bay lơ lửng cách người 40px trong không trung (`x = 42, y = -68`), trong khi tay nhân vật còn dính bông lúa mì vẽ sẵn.
- **Hiện tại:**
  - Đã vẽ lại Liềm và Cần câu chuẩn 2.5D Chibi rực rỡ (`tool_sickle_chibi.png` với lưỡi thép bóng loáng, cán gỗ ấm; `tool_fishing_rod_chibi.png` bằng thân tre, ổ cước đồng và phao câu đỏ trắng).
  - Tách bỏ hoàn toàn bông lúa trên tay nhân vật gốc.
  - Neo trực tiếp tâm cán dụng cụ (`tool_layer.position = Vector2(-29, -70)`) vào đúng lòng bàn tay nhân vật với góc vung liềm / quăng cần tự nhiên.

### 1.2. Hệ Thống Trang Phục Chibi Đồng Bộ Tuyệt Đối Theo Giới Tính
- **Trước đây:** Chọn Nông Dân Nữ (`Mai`) rồi bấm `Thợ Mộc` thì nhân vật bị biến thành nam giới (`npc_barista.png`).
- **Hiện tại:**
  - Đã tạo riêng bộ **8 Sprite 2.5D Chibi độc lập**:
    - **4 Bộ Trang Phục Nam (`Minh`):** `avatar_male_overalls` (Yếm Jean), `avatar_male_floral` (Áo Đồng Nội), `avatar_male_baker` (Đầu Bếp), `avatar_male_carpenter` (Thợ Mộc).
    - **4 Bộ Trang Phục Nữ (`Mai`):** `avatar_female_overalls` (Yếm Jean Nữ), `avatar_female_dress` (Váy Hoa Nắng), `avatar_female_baker` (Thợ Bánh Ngọt), `avatar_female_carpenter` (Thợ Mộc Nữ).
  - Nhân vật Nữ Mai luôn giữ trọn vẹn khuôn mặt chibi nữ tính, đôi mắt to long lanh, má hồng và tóc bím đáng yêu; chuyển đổi giữa bất kỳ bộ đồ nào vẫn là Nữ 100%!

### 1.3. Khắc Phục Triệt Để Tiếng Rè Rè Khi Vào Game
- **Nguyên nhân:** Thuộc tính `loop_mode = LOOP_FORWARD` trong Godot 4 đối với file WAV có `loop_end == 0` đã khiến mixer lặp buffer 0 frame liên tục gây tiếng rè. Ngoài ra một số file âm thanh cũ dùng hàm tạo tạp âm trắng ngẫu nhiên (`random.uniform`).
- **Khắc phục:**
  - Chuyển `loop_mode = AudioStreamWAV.LOOP_DISABLED` trong [`audio_manager.gd`](file:///d:/HayDayOffline/scripts/core/audio_manager.gd), kết nối sự kiện `_bgm_player.finished` để lặp nhạc nền mượt mà.
  - Viết lại bộ tổng hợp âm thanh [`tools/generate_cozy_soundscape.py`](file:///d:/HayDayOffline/tools/generate_cozy_soundscape.py) với 100% sóng hài Sine/Triangle thuần khiết (tiếng chuông celesta, phím đàn marimba gỗ, âm nhạc hộp mộc mạc), **0% tạp âm trắng**.

### 1.4. Khắc Phục Lỗi Debugger & Cảnh Báo
- Sửa lỗi format string trong [`zoo_enclosure.gd:375`](file:///d:/HayDayOffline/scripts/entities/zoo_enclosure.gd): `+50%% Tip!`.
- Bổ sung `get_barn_capacity_left()` và `get_silo_capacity_left()` trong [`storage_manager.gd`](file:///d:/HayDayOffline/scripts/core/storage_manager.gd).
- Chuyển `static func` thành `func` trong [`grid_manager.gd`](file:///d:/HayDayOffline/scripts/core/grid_manager.gd) để không còn cảnh báo `STATIC_CALLED_ON_INSTANCE`.
- Thêm signal alias `level_up` trong [`event_bus.gd`](file:///d:/HayDayOffline/scripts/core/event_bus.gd).

### 1.5. Lối Chơi Cấp 1 Rõ Ràng & Hệ Thống Vật Liệu Xây Dựng
- **Cấp 1 Khởi Đầu Tinh Gọn:** Chỉ có Nhà Chính, Kho Silo, Nhà Kho, Sạp Hàng, Bảng Xe Tải, 6 Ô Ruộng và 1 Chuồng Gà. Toàn bộ các nhà máy và chuồng thú cấp cao (`FeedMill`, `Bakery`, `JuiceStand`, `CakeOven`, `CowPen`, `PigPen`, `SheepPen`, `BeehiveTree`, `PoodleHouse`) được ẩn gọn gàng, không bị đặt lộn xộn. (Chế độ Sandbox Cấp 33 vẫn kích hoạt đầy đủ để test nhanh).
- **3 Vật Liệu Xây Dựng Cốt Lõi:**
  - `mat_plank` (**Ván Gỗ Thông**), `mat_bolt` (**Đinh Tán Thép**), `mat_brick` (**Gạch Nung Đỏ**) lưu trong Barn.
  - Menu `🔨 Xây Dựng` hiển thị rõ yêu cầu cấp độ + chi phí Vàng và Vật liệu; kiểm tra kho trước khi cho phép đặt móng.

### 1.6. Bảng Nhiệm Vụ & Lộ Trình Cấp Độ Thân Thiện
- Bổ sung thẻ banner **"🌟 LỘ TRÌNH MỞ KHÓA: CẤP X ➔ CẤP X+1"** ở đầu bảng nhiệm vụ, liệt kê cụ thể các nông sản, công trình và tính năng mở khóa ở cấp tiếp theo.
- Thẻ nhiệm vụ hiển thị đầy đủ phần thưởng Vật Liệu Xây Dựng (`+1 Ván Gỗ`, `+1 Đinh Tán`, `+1 Gạch Đỏ`).

### 1.7. Quy Hoạch Bản Đồ Chuẩn Hay Day & Ẩn Nút `✥` Di Dời
- Tất cả các nút di dời `✥` (`RelocateBtn`) trên công trình được ẩn hoàn toàn khi chơi bình thường, triệt tiêu mọi cảm giác rối mắt.
- Nút `✥` chỉ xuất hiện khi người chơi chủ động bật chế độ **`Quy Hoạch`** ở thanh HUD dưới đáy.
- 5 phân khu nông trại được bố trí khoa học: Khu Nhà Chính & Kho (Bắc), Đại Lộ Xưởng Sản Xuất (Trung Tâm), Khu Ruộng Lúa (Tây Nam), Khu Giao Thương Xe Tải & Sạp Hàng (Trung Nam), Khu Chăn Nuôi Đồng Cỏ (Nam).

---

## 2. GỢI Ý CÁC HẠNG MỤC PHÁT TRIỂN NÂNG CAO TIẾP THEO
1. **Nâng Cấp Kho Silo/Barn Bằng Vật Liệu:** Thêm nút nâng cấp trong popup kho, tiêu tốn `Ván Gỗ + Đinh Tán + Gạch Đỏ` để tăng `+50` sức chứa mỗi lần.
2. **Kéo-Lướt (Drag-and-Swipe) Chuồng Thú:** Tích hợp thao tác giữ chuột lướt qua chuồng để rải cám và thu trứng/sữa đồng loạt tương tự gặt lúa.
3. **Sao Tinh Thông Máy Sản Xuất (Mastery Stars ★★★):** Đạt 10/30/60 mẻ sản phẩm để giảm thời gian chế biến và gắn huy hiệu sao vàng trên nóc xưởng.
