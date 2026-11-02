---
name: game-studio
description: Full-lifecycle game development studio framework adapted from Claude Code Game Studios for Godot 4. Orchestrates 49 specialized game dev roles across 3 tiers (Directors, Department Leads, Specialists), structured workflows (/feature-design, /dev-story, /art-forge, /qa-gate, /economy-balance), GDScript 2.0 static typing quality gates, and automated asset-to-engine pipelines.
---

# 🎮 Game Studio Skill (Godot 4 & Hay Day Offline)

Khung làm việc chuẩn Studio Game chuyên nghiệp được chuyển giao và tinh chỉnh từ **Claude Code Game Studios**, tối ưu hóa riêng cho **Godot Engine 4.3+ / 4.7+ Standard (GL Compatibility)** và dự án **Hay Day Offline + Farm Tourism**.

---

## 1. MÔ HÌNH PHÂN CẤP STUDIO 3 TẦNG (49 ROLES)

Mỗi khi người chơi yêu cầu một tác vụ game, hãy tự động kích hoạt hoặc phối hợp các chuyên gia tương ứng:

```mermaid
graph TD
    subgraph Tier 1: Directors (Chiến Lược & Phạm Vi)
        CD["creative-director<br/>(Bảo vệ tầm nhìn & cảm xúc)"]
        TD["technical-director<br/>(Kiến trúc & Ngân sách hiệu năng)"]
        PD["producer<br/>(Lộ trình & Chống vỡ tiến độ)"]
    end

    subgraph Tier 2: Department Leads (Trưởng Bộ Phận)
        GD["game-designer<br/>(Cơ chế & GDD)"]
        LP["lead-programmer<br/>(Chuẩn code & Signal Bus)"]
        AD["art-director<br/>(Mỹ thuật 2.5D Chibi)"]
        QD["qa-lead<br/>(Cổng kiểm thử)"]
    end

    subgraph Tier 3: Specialists (Thực Thi Trực Tiếp)
        GDS["godot-gdscript-specialist"]
        TA["technical-artist"]
        ED["economy-designer"]
        SYD["systems-designer"]
        QAT["qa-tester"]
    end

    CD & TD & PD --> GD & LP & AD & QD
    GD & LP & AD & QD --> GDS & TA & ED & SYD & QAT
```

> Chi tiết nhiệm vụ của toàn bộ 49 chuyên viên xem tại: [references/agent_roster.md](file:///d:/HayDayOffline/.agent/skills/game-studio/references/agent_roster.md)

---

## 2. NĂM WORKFLOW CỐT LÕI (STUDIO PIPELINES)

### 🚀 Pipeline 1: Thiết Kế Tính Năng Mới (`/feature-design`)
**Khi nào dùng:** Khi bắt đầu thêm một cơ chế mới (ví dụ: máy làm kem, minigame mới, loại thú nuôi mới).
1. `game-designer` phác thảo vòng lặp tương tác (Trigger $\to$ Process $\to$ Reward $\to$ Fail state) theo mẫu [templates/feature_spec_template.md](file:///d:/HayDayOffline/.agent/skills/game-studio/templates/feature_spec_template.md).
2. `economy-designer` xác định nguyên liệu đầu vào, thời gian đếm ngược, sản phẩm đầu ra và lượng vàng/XP.
3. `technical-director` & `lead-programmer` duyệt kiến trúc dữ liệu vào `data/*.json` và giải pháp tương tác chuột.

---

### 💻 Pipeline 2: Lập Trình & Triển Khai Code (`/dev-story`)
**Khi nào dùng:** Khi viết code cho thực thể hoặc hệ thống mới.
1. `godot-gdscript-specialist` đảm bảo **100% Static Typing**:
   ```gdscript
   # Chuẩn static typing bắt buộc:
   var current_level: int = 1
   var move_velocity: Vector2 = Vector2.ZERO
   func calculate_tip(base_amount: int, multiplier: float) -> int:
       return int(float(base_amount) * multiplier)
   ```
2. Kết nối phi tập trung qua `EventBus`: Không gọi chéo node cha-con phức tạp, phát tín hiệu:
   ```gdscript
   EventBus.loot_collected.emit("wheat", 2, global_position)
   ```
3. Truy cập kho bãi trực tiếp thuộc tính: `StorageManager.gold`, không gọi hàm getter cũ.
4. Đảm bảo an toàn tương tác chuột: Mọi `Control` hay `Container` nền phải đặt `mouse_filter = Control.MOUSE_FILTER_IGNORE` (số 2) để không chặn click xuống ruộng/chuồng thú.

---

### 🎨 Pipeline 3: Pipeline Đồ Họa Tự Động (`/art-forge`)
**Khi nào dùng:** Khi thiếu hình ảnh cây trồng, con vật, món ăn hoặc công trình.
1. `technical-artist` gọi công cụ tự động hóa không vẽ bằng tay:
   ```bash
   python D:/HayDayOffline/tools/chibi_asset_forge.py --id <sprite_id> --prompt "<detailed_chibi_prompt>" --width 256 --height 256
   ```
2. Công cụ tự động chạy **Corner Floodfill BFS 4 góc** để tách nền trắng mà không làm rách chi tiết màu sáng, khử viền mờ 1px và tự động đăng ký vào `scripts/core/sprite_atlas_manager.gd`.
3. Gán chuyển động thủ tục 60 FPS (*Idle Breathing* $\to$ nhịp thở đàn hồi, *Walk Bounce* $\to$ nhịp nhún bước chân).
4. **CẤM:** Không bao giờ vẽ tạm bợ bằng `Polygon2D` hay `ColorRect`. Mọi asset phải đúng chuẩn 2.5D Chibi Cozy Pastel viền nâu.

---

### 🧪 Pipeline 4: Kiểm Thử & Nghiệm Thu (`/qa-gate`)
**Khi nào dùng:** Trước khi bàn giao bất kỳ tính năng nào cho người chơi.
1. `qa-tester` chạy kiểm tra biên dịch headless qua CLI Godot:
   ```powershell
   & "D:\Gotdot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --path "D:\HayDayOffline" --headless --quit
   ```
   *Yêu cầu:* Thoát với mã lỗi 0, không có đỏ lỗi cú pháp, 0 cảnh báo type leak.
2. Chạy kịch bản test click tự động:
   ```powershell
   & "D:\Gotdot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --path "D:\HayDayOffline" --headless "res://tests/test_interactive_clicks.tscn"
   ```
3. Chụp ảnh màn hình nghiệm thu trực quan (`res://debug_preview.png`) và kiểm tra đối chiếu qua mẫu [templates/qa_checklist_template.md](file:///d:/HayDayOffline/.agent/skills/game-studio/templates/qa_checklist_template.md).

---

### ⚖️ Pipeline 5: Cân Bằng Kinh Tế (`/economy-balance`)
**Khi nào dùng:** Điều chỉnh độ khó, nhịp độ chơi và tỷ lệ giá cả nông sản.
1. `economy-designer` rà soát `data/crops.json`, `data/animals.json`, `data/recipes.json`.
2. Duy trì tỷ lệ hồi vốn hợp lý: Lúa mì (10s, x2 sản lượng) $\to$ Ngô (20s) $\to$ Cây ăn quả (chu kỳ dài hơn nhưng giá trị cao và cộng điểm du lịch).
3. Đảm bảo kho Silo & Barn có giới hạn tăng dần để kích thích người chơi bán hàng cho Du khách hoặc Xe tải.

---

## 3. BẢNG TIÊU CHUẨN KỸ THUẬT BẮT BUỘC (STUDIO RUBRIC)

| Tiêu Chuẩn | Quy Tắc Thực Hiện | Hậu Quả Nếu Vi Phạm |
| :--- | :--- | :--- |
| **Static Typing** | 100% biến, tham số và hàm phải có định kiểu (`var x: int = 0`) | Bị cảnh báo compiler, giảm tốc độ thực thi |
| **Mouse Filter** | `Control` không phải nút phải đặt `mouse_filter = 2` (IGNORE) | Liệt nút gieo hạt, không click được ruộng đất |
| **Camera Pos** | Dùng `get_global_mouse_position()` khi raycast/kiểm tra va chạm | Lệch tọa độ khi người chơi Pan hoặc Zoom camera |
| **Art Integrity** | Dùng `chibi_asset_forge.py`, tách nền BFS 4 góc, khử viền mờ 1px | Dính viền đen chữ L, rách texture |
| **Event Bus** | Dùng `EventBus` phát signal, không hard-reference node khác | Phá vỡ tính đóng gói, dễ crash khi reload scene |
| **Save Sync** | Lưu dữ liệu qua `SaveManager` (`user://hayday_save.json`) | Mất dữ liệu tiến trình khi người chơi tắt game |

