# Tài Liệu Kiến Trúc Nâng Cấp Đồ Họa 2.5D Cozy Storybook (`HayDay Offline`)

Tài liệu này mô tả chi tiết hệ thống đồ họa và bầu không khí **2.5D Cozy Chibi Pastel Storybook** đã được nâng cấp cho dự án **HayDay Offline** trên **Godot 4.3+ (chế độ `gl_compatibility`)**, đồng thời giải đáp câu hỏi về việc sử dụng công cụ nội tại so với kết nối thêm các **MCP (Model Context Protocol) bên ngoài**.

---

## 1. Tổng Quan Kiến Trúc Đồ Họa 5 Lớp (`CozyAtmosphereFX` & `ChibiSceneryBuilder`)

Hệ thống nâng cấp đồ họa được thiết kế hoàn toàn bằng **100% Static Typing GDScript 2.0**, tối ưu hóa cho GPU tích hợp (giữ vững **60 FPS**) và **không chặn bất kỳ sự kiện chuột nào** xuống bản đồ nông trại.

```text
EnvironmentDirector (WeatherAndDayNightManager)
├── DayNightModulate (CanvasModulate - Chuyển màu mượt 4 buổi: Dawn, Noon, Sunset, Night)
├── CozyRainParticles (CPUParticles2D - Mưa ấm toàn bản đồ Bờ Tây & Bờ Đông)
├── LanternGlowRoot (Node2D - Bật lúc Hoàng Hôn & Ban Đêm)
│   └── WarmLanternHalos (Quầng sáng Radial Gradient BLEND_MODE_ADD nhấp nháy 60 FPS)
└── CozyAtmosphereFX (scripts/environment/cozy_atmosphere_fx.gd)
    ├── RiverFXRoot (z_index = 2, z_as_relative = false)
    │   ├── RiverShimmerNorth & RiverShimmerSouth (Ánh nước sông lấp lánh Additive)
    │   ├── RiverFloatingPetals (Cánh hoa anh đào trôi dọc dòng sông)
    │   └── RiverRainRipples (Vòng gợn nước mưa nở rộng khi trời mưa)
    ├── GoldenSunbeamsRoot (z_index = 22, z_as_relative = false)
    │   └── 5x Sunbeam Rays (Shader gl_compatibility cộng sáng nghiêng góc -0.42 rad)
    └── AirAtmosphereParticlesRoot (z_index = 24, z_as_relative = false)
        ├── SunMotesWest & SunMotesEast (Hạt nắng vàng ấm lơ lửng ban ngày)
        ├── SakuraBreezeNorth & SakuraBreezeEast (Cánh hoa anh đào bay theo gió)
        └── FirefliesWest & FirefliesEast (Đom đóm sinh thái nhấp nháy ban đêm)
```

### 1.1. Hiệu Ứng Mặt Nước Sông Lấp Lánh & Cánh Hoa Trôi (`RiverFXRoot`, `z_index = 2`)
- **Ánh nước lấp lánh (`RiverShimmerNorth` & `RiverShimmerSouth`):** Sử dụng `CPUParticles2D` với `GradientTexture2D` hình elip ngang mềm và `CanvasItemMaterial.BLEND_MODE_ADD`. Sắc độ ánh nước tự động chuyển theo buổi:
  - Bình minh (`DAWN`): Hồng cam dịu (`Color(1.0, 0.86, 0.78, 0.80)`).
  - Buổi trưa (`NOON`): Trắng vàng lấp lánh (`Color(1.0, 0.98, 0.88, 0.80)`).
  - Hoàng hôn (`SUNSET`): Vàng cam rực rỡ (`Color(1.0, 0.78, 0.55, 0.85)`).
  - Ban đêm (`NIGHT`): Ánh trăng xanh bạc (`Color(0.68, 0.85, 1.0, 0.55)`).
- **Cánh hoa trôi sông (`RiverFloatingPetals`):** Những cánh hoa anh đào hồng phấn rơi từ rừng cây bờ Bắc và bờ Đông trôi chầm chậm từ Bắc xuống Nam dọc theo dòng chảy (`x = 885`).
- **Gợn nước mưa (`RiverRainRipples`):** Tự động kích hoạt khi thời tiết chuyển sang `COZY_RAIN`, tạo các vòng sóng tròn đồng tâm lan tỏa trên mặt sông.

### 1.2. Tia Nắng Ấm Golden-Hour (`GoldenSunbeamsRoot`, `z_index = 22`)
- Sử dụng `ShaderMaterial` (`shader_type canvas_item; render_mode blend_add;`) tương thích 100% với `gl_compatibility`.
- Tạo 5 dải nắng chéo mềm mại xuyên qua tán cây tại Nông Trại Bờ Tây, Cầu Gỗ và Công Viên Sở Thú Bờ Đông.
- Cường độ và màu sắc tia nắng tự động đổi theo khung giờ (`DAWN` hồng đào, `NOON` vàng kem dịu, `SUNSET` cam mật ong ấm áp) và tự động tắt khi trời mưa hoặc ban đêm.

### 1.3. Hạt Nắng, Gió Hoa Anh Đào & Đom Đóm Đêm (`AirAtmosphereParticlesRoot`, `z_index = 24`)
- **Hạt nắng ấm (`SunMotesWest` & `SunMotesEast`):** Các hạt bụi nắng tròn mờ (`BLEND_MODE_ADD`) bay lơ lửng nhẹ nhàng vào ban ngày.
- **Làn gió hoa anh đào (`SakuraBreezeNorth` & `SakuraBreezeEast`):** Cánh hoa anh đào bay chéo có gia tốc tiếp tuyến (`tangential_accel`) và xoay nhẹ tự nhiên. Khi có sự kiện `BALLOON_FESTIVAL`, tốc độ gió hoa anh đào tăng thêm `25%` tạo không khí lễ hội sôi động.
- **Đàn đom đóm đêm (`FirefliesWest` & `FirefliesEast`):** Tự động bật vào lúc `SUNSET` và `NIGHT` (khi không mưa), phát sáng vàng-xanh lục nhấp nháy theo `color_ramp` đa điểm.

### 1.4. Quầng Sáng Đèn Lồng Ấm Áp (`WarmLanternHalos`)
- Tự động quét các đèn lồng trong `LanternGlowRoot` và bổ sung thêm các điểm sáng ấm dọc 2 đầu Cầu Gỗ và Cổng Sở Thú.
- Mỗi quầng sáng dùng `GradientTexture2D` Radial 4 nấc màu cam-vàng ấm kết hợp `BLEND_MODE_ADD`, co giãn nhịp thở lệch pha (`sin(t * 2.8 + phase)`) ở 60 FPS.

### 1.5. Chuyển Động Gió Đung Đưa Trên GPU (`ChibiSceneryBuilder`)
- Trong `scripts/map/chibi_scenery_builder.gd`, cờ `enable_ambient_sway = true` đã được kích hoạt cùng 2 Vertex Shader siêu nhẹ:
  - **Foliage Wind Sway Shader:** Giữ cố định 100% gốc cây tại `UV.y = 1.0` (`canopy_mask = clamp(1.0 - UV.y, 0.0, 1.0)`), chỉ uốn nhẹ vòm lá phía trên theo hàm sóng `sin(TIME * sway_speed + sway_phase)`. Nhờ đó gốc cây luôn bám chặt vào bóng đổ mặt đất và không làm lệch vùng chọn click hay va chạm.
  - **Cloud Drift Shader:** Giúp các đám mây Chibi ở đường chân trời phía Bắc (`z_index = -12`) bồng bềnh trôi nhẹ trên bầu trời mà không tốn CPU cập nhật tọa độ từng khung hình.

---

## 2. Giải Đáp: Khi Nào Dùng Công Cụ Nội Tại vs. Khi Nào Cần Kết Nối Thêm MCP Ngoài?

### 2.1. Những hạng mục KHÔNG cần cài thêm MCP (Đã có sẵn công cụ nội tại mạnh mẽ)
Dự án hiện đã được trang bị sẵn hệ sinh thái công cụ nội tại đầy đủ cho quy trình làm game 2D/2.5D:
1. **Tạo & Cắt Sprite 2.5D Chibi (`agent-sprite-forge` & `tools/chibi_asset_forge.py`):**
   - Máy đã cài sẵn plugin `agent-sprite-forge` (`generate2dsprite`, `generate2dmap`, `generate2dmedia`, `codeart2d`, `video2dsprite`) và công cụ `tools/chibi_asset_forge.py`.
   - Tự động sinh Sprite 2.5D Pastel Chibi, xóa nền thông minh bằng thuật toán **Corner Flood-Fill + De-fringe 1px**, tự động cắt viền (`inset_margin = 8`) và đăng ký thẳng vào `SpriteAtlasManager`.
2. **Hiệu ứng Ánh Sáng, Thời Tiết, Mặt Nước & Chuyển Động 60 FPS (Godot 4 Shaders & Particles):**
   - Toàn bộ hiệu ứng **Golden-Hour Sunbeams, River Shimmer, Sakura Petals, Fireflies, Lantern Glow, Foliage Wind Sway** đều được thực thi trực tiếp bằng `ShaderMaterial` (`gdshader`) và `CPUParticles2D` của Godot 4. Cách này nhẹ nhất, không phụ thuộc bên thứ ba và chạy mượt 60 FPS ở chế độ `GL Compatibility`.

### 2.2. Khi nào bạn NÊN kết nối thêm MCP bên ngoài (Tuỳ chọn nâng cao)?
Nếu trong tương lai bạn muốn mở rộng quy mô sản xuất mỹ thuật vượt ra ngoài pipeline tự động hiện tại, bạn có thể kết nối thêm một trong các MCP sau:

| Nhu cầu nâng cấp mỹ thuật | MCP / Plugin khuyên dùng | Lợi ích mang lại |
| :--- | :--- | :--- |
| **Render công trình 3D sang Sprite Isometric/2.5D chuẩn góc nghiêng tuyệt đối** | **Blender MCP** (`blender-mcp`) | Cho phép Agent dựng mô hình 3D nhà máy/chuồng thú trong Blender, đặt đèn Sun Light + Toon Outline cố định góc 35°, rồi render hàng loạt frame hoạt họa (xoay cánh quạt cối xay gió, khói lò bánh mì) ra PNG hoàn hảo 100% về phối cảnh. |
| **Vẽ & Tinh chỉnh Sprite Sheet từng Pixel / Frame-by-Frame** | **Aseprite MCP** | Hữu ích nếu bạn muốn chỉnh sửa tay từng khung hình (`IDLE`, `WALK`, `EAT`) hoặc tách lớp (Layers) của nhân vật trong file `.aseprite`. |
| **Thiết kế giao diện HUD / Menu phức tạp từ bản vẽ Vector** | **Figma MCP** (`antigravity-plugins-partners/plugin/figma`) | Chuyển đổi trực tiếp các bảng UI, nút bấm gỗ, huy hiệu ngôi sao từ file thiết kế Figma sang thông số `StyleBoxFlat` / Texture trong Godot. |
| **Sinh ảnh AI cục bộ không giới hạn với LoRA đồng nhất phong cách** | **ComfyUI / Stable Diffusion Local MCP** | Nếu bạn chạy card đồ họa rời và muốn dùng riêng một mô hình LoRA "Hay Day Cozy Watercolor" để sinh hàng trăm biến thể trang trí mà không phụ thuộc API mạng. |

---

## 3. Hướng Dẫn Tinh Chỉnh Nhanh Cho Nhà Phát Triển

- **Đổi nhanh thời gian & thời tiết trong code:**
  Gọi `environment_director._apply_time_phase(WeatherAndDayNightManager.TimePhase.SUNSET)` hoặc `environment_director._apply_weather(WeatherAndDayNightManager.WeatherType.BALLOON_FESTIVAL)`. `CozyAtmosphereFX` sẽ tự động đồng bộ toàn bộ hạt nắng, tia sáng, hoa anh đào, đom đóm và ánh nước sông.
- **Tắt/Bật gió đung đưa cảnh quan:**
  Trong `scripts/map/chibi_scenery_builder.gd`, biến `enable_ambient_sway` mặc định là `true`. Có thể chỉnh `sway_strength` trong `_apply_ambient_sway_shader()` để tăng/giảm biên độ gió.
