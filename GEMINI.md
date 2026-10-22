# GEMINI.md - QUY ƯỚC KIẾN TRÚC & ĐỒ HỌA: HAY DAY OFFLINE + FARM TOURISM

Bạn là Kỹ sư Kiến trúc Game & Technical Artist chính của dự án. Bạn làm việc trên máy cấu hình nhẹ, sử dụng **Godot 4.3+ Standard (GDScript 2.0)**, chế độ **GL Compatibility**. Bạn BẮT BUỘC tuân thủ các quy tắc dưới đây.

---

## 1. TẦM NHÌN & 6 TRỤ CỘT GAMEPLAY
- **Thể loại:** Game Quản lý Nông trại 2D Offline kết hợp Khách Tham Quan (`VisitorSystem`).
- **Điều khiển:** Điều khiển `Camera2D` (Pan/Zoom), chọn công cụ ở thanh HUD dưới đáy (Xem, Lúa Mì, Ngô, Liềm, Ruộng, Đường, Sạp Hàng, Xe Tải) và **Click hoặc Kéo-Lướt (Drag-and-Swipe)** trực tiếp lên các thực thể trên bản đồ.
- **6 Trụ cột:**
  1. **Trồng trọt (`FieldPlot`):** Ô đất trống (`EMPTY`) -> Chọn hạt giống (Lúa Mì/Ngô) chạm/lướt vào để gieo (`GROWING`) -> Đếm ngược nhanh (Lúa mì: 10 giây, Ngô: 20 giây để dễ test) -> Chín (`READY`) -> Dùng `Liềm` thu hoạch nhận x2 nông sản + XP, trả ô đất về `EMPTY`.
  2. **Chăn nuôi (`AnimalPen`):** Hiển thị đúng Sprite con vật (Gà, Bò, Heo), cho ăn và thu hoạch trứng/sữa.
  3. **Xây dựng & Trang trí (`ProductionMachine`, `Decor`, `PathTile`):** Đặt trên lưới, tăng `AttractionScore`.
  4. **Câu cá (`FishingSpot`):** Hồ câu tự nhiên với minigame.
  5. **Kinh tế (`StorageManager`, `RoadsideShop`, `TruckOrder`):** Kho Silo & Barn.
  6. **Du khách (`VisitorSystem`):** Object Pool 15 NPC đi trên đường gạch (`AStarGrid2D`), ngắm cảnh và rơi tiền Tip.

---

## 2. QUY TẮC ĐỒ HỌA & SỬ DỤNG PLUGIN `agent-sprite-forge` (BẮT BUỘC)
Máy đã cài sẵn plugin toàn cục tại `C:\Users\Phi\.gemini\config\plugins\agent-sprite-forge\` (gồm các skill `generate2dsprite`, `generate2dmap`, `generate2dmedia`, `codeart2d`).
1. **CẤM vẽ môi trường/cây cối/hồ nước sơ sài bằng `Polygon2D` hoặc `ColorRect`:**
   - Khi thiếu hình ảnh Nhân vật (Du khách), Con vật (Gà, Bò, Heo, Cừu) hoặc Khung cảnh (Núi đồi, Cây cổ thụ, Cây ăn quả, Bụi hoa, Đá tảng, Bờ hồ), bạn PHẢI dùng skill `generate2dsprite` / `generate2dmedia` kết hợp ảnh mẫu `res://assets/sprites/chibi_sheet_1.png` để tạo Sprite Sheet mới đúng phong cách **2.5D Cozy Chibi Pastel Storybook, nét viền nâu mảnh, nền trắng tinh `#FFFFFF` không có khung kẻ ô đen**.
2. **Chống gán nhầm Sprite (Bắt buộc kiểm tra bằng Vision):**
   - Trước khi gán tọa độ cắt ô (Hàng, Cột) trong `sprite_atlas_manager.gd`, bạn PHẢI dùng công cụ xem ảnh mở file ảnh lên quan sát từng ô.
   - Tuyệt đối không gán hình Người Chibi vào `AnimalPen` (chuồng thú) và không gán hình Chó/Mèo làm `VisitorNPC` (Du khách).
3. **Loại bỏ viền đen chữ L khi cắt Sprite Sheet:**
   - Mọi thao tác cắt ô lưới trong `sprite_atlas_manager.gd` phải thu hẹp vùng cắt vào trong (`inset_margin = 8` pixel mỗi cạnh) trước khi chạy Flood-fill xóa nền trắng để không dính đường kẻ khung màu đen.

---

## 3. TIÊU CHUẨN KỸ THUẬT & KIỂM THỬ THỊ GIÁC (VISUAL VERIFICATION)
1. **100% Static Typing GDScript 2.0:** Giữ code đơn giản, trực diện, không lạm dụng mẫu thiết kế phức tạp làm đứt gãy sự kiện Click/Drag.
2. **Quy tắc Tương tác Chuột (Chống liệt nút Trồng lúa/Ngô):**
   - Trong `ui_hud.tscn`, mọi `Control` / `Container` không phải là nút bấm phải đặt `mouse_filter = Control.MOUSE_FILTER_IGNORE` (số 2) để không chặn click xuống bản đồ.
   - Trong `drag_action_manager.gd` và `field_plot.gd`, luôn dùng `get_global_mouse_position()` để kiểm tra va chạm với ô ruộng (tính cả độ dịch chuyển của `Camera2D`).
3. **Kiểm thử Kép (CLI + Screenshot Test):**
   - Bước 1: Chạy kiểm tra biên dịch:
     `& "D:\Gotdot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --path . --headless --quit`
   - Bước 2: Để kiểm tra lỗi hình ảnh, hãy chạy game cửa sổ trong 3 giây với cờ tự chụp màn hình lưu ra `res://debug_preview.png`, sau đó dùng công cụ xem ảnh mở `res://debug_preview.png` lên tự kiểm tra xem: (a) Chuồng thú đã đúng hình con vật chưa, (b) Du khách đã đúng hình người chưa, (c) Công trình còn viền đen không, (d) Khung cảnh cây cối/núi đồi đã đẹp chưa.

---

## 4. CẤU TRÚC THƯ MỤC CHUẨN
```text
res://
├── GEMINI.md
├── project.godot
├── assets/
│   └── sprites/            # Nơi chứa toàn bộ ảnh PNG/JPG (buildings, crops, animals, visitors, environment)
├── data/                   # crops.json, animals.json, buildings.json, recipes.json, fishes.json, visitors.json
├── scripts/
│   ├── core/               # event_bus.gd, data_manager.gd, tick_manager.gd, storage_manager.gd, grid_manager.gd, save_manager.gd, sprite_atlas_manager.gd
│   ├── interaction/        # camera_controller.gd, drag_action_manager.gd
│   ├── entities/           # field_plot.gd, animal_pen.gd, production_machine.gd, fishing_spot.gd
│   ├── visitors/           # visitor_manager.gd, visitor_npc.gd, roadside_shop.gd
│   └── systems/            # truck_order_system.gd, fishing_minigame.gd
└── scenes/
    ├── main_farm.tscn
    └── ui_hud.tscn
---

## 5. QUY ƯỚC PIPELINE SPRITE & ANIMATION (AGENT-SPRITE-FORGE)
- **Chuẩn hóa SpriteSheet & Atlas:**
  Toàn bộ Sprite cho Nhân vật (Du khách, Bưu tá, Nông dân), Động vật (Bò, Gà, Heo, Thỏ, Vịt, Chim, Bướm) và Cây trồng/Công trình được chuẩn hóa từ pipeline [agent-sprite-forge](https://github.com/phidanghai-spec/agent-sprite-forge) (hoặc thư mục local `d:\asf-work`).
- **Nhận diện tự động trong `SpriteAtlasManager`:**
  + Tự động nhận diện cả ảnh đơn (Single Frame) và SpriteSheet đa khung hình (`hframes`/`vframes`).
  + Hỗ trợ các trạng thái hoạt họa chuẩn: `IDLE`, `WALK`, `EAT`, `SWIM`, `HAPPY`.
- **Hệ thống Procedural Motion 60 FPS:**
  + **Nhân vật (Du khách):** Di chuyển bằng vận tốc nội suy mượt mà (`_current_velocity.lerp(desired, delta * 8.0)`), nhịp nhún bước chân (`abs(sin(phase)) * 4.5`), độ nghiêng người (`sin(phase) * 0.055`), nhịp thở tự nhiên khi đứng yên (`Idle Breathing`), và bóng đổ động co giãn theo bước nhảy.
  + **Động vật nhỏ (Critters):**
    * Thỏ (`critter_bunny`): Di chuyển bằng nhịp nhảy parabol (`hop arc`) co giãn đàn hồi squash & stretch.
    * Gà & Chim: Mổ thóc nhịp nhàng khi dừng (`pecking`) và chạy lạch bạch mượt mà khi di chuyển.
    * Vịt bơi: Lướt nước êm có quán tính, nghiêng góc rẽ mượt kèm vòng sóng nước elip lan tỏa tự nhiên.
    * Bò trong chuồng (`animal_pen.gd`): Nhai cỏ và hít thở đàn hồi tự nhiên, đi lại thong thả trong hàng rào gỗ.

---

## 6. QUY TRÌNH TỰ ĐỘNG TẠO ASSET ĐỒ HỌA QUA API (CHIBI ASSET FORGE)
- **Công cụ cốt lõi:** `python D:/HayDayOffline/tools/chibi_asset_forge.py --id <sprite_id> --prompt "<mo_ta_tieng_anh>" --width 256 --height 256`
- **Quy tắc bắt buộc:**
  1. **Không bắt người chơi tìm ảnh:** Bất cứ khi nào người chơi yêu cầu thêm cây trồng mới (lúa mì, dâu tây, cà rốt...), món ăn (bánh mì, phô mai, bánh quy...), con vật (cừu, thỏ, vịt...), công trình (chuồng trại, máy sản xuất...) hay trang trí cảnh quan (cây hoa anh đào, bụi cây, tảng đá...), Agent **BẮT BUỘC** gọi `chibi_asset_forge.py` để tự động sinh ảnh qua Public API (Pollinations.ai / DiceBear) hoặc chạy procedural Chibi generator.
  2. **Tách nền thông minh 100%:** Công cụ tự động dùng Corner Floodfill (BFS từ 4 viền ngoài) bảo vệ nguyên vẹn các chi tiết trắng/sáng bên trong vật thể, khử viền mờ (de-fringe 1px) và crop sát viền (padding 4px).
  3. **Tự động đăng ký Texture:** Tự động chèn lệnh `_load_standalone_texture("<sprite_id>", "res://assets/sprites/<sprite_id>.png")` vào `scripts/core/sprite_atlas_manager.gd`, không cần can thiệp thủ công.
  4. **Cấm tuyệt đối hình vẽ thô sơ:** Tuyệt đối không vẽ đa giác `Polygon2D` hay `ColorRect` thay thế sprite vật thể thật. Mọi asset phải đạt chuẩn 2.5D Chibi Cozy Farm, mềm mại, ấm áp và đồng nhất phong cách Hay Day.
