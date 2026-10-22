---
name: chibi-character-forge
description: >-
  Use this skill to extend, generate, slice, and register new Chibi characters, visitors,
  and farm NPCs for Hay Day Offline with procedural motion (Idle Breathing + Walk Bounce).
---

# 🎨 Chibi Character Forge Skill (Hay Day Offline)

Kỹ năng tự động hóa việc mở rộng hệ thống Nhân vật, Du khách (`VisitorNPC`), Nông dân và Thú cưng theo chuẩn đồ họa **2.5D Cozy Chibi Storybook**.

## 1. Quy Trình Tạo & Mở Rộng Nhân Vật Mới

### Cách 1: Tách lẻ nhân vật từ SpriteSheet tổng hợp
Khi có ảnh nhiều nhân vật trong `assets/raw_refs/` hoặc file ảnh mới:
```bash
python tools/auto_slice_sheets.py
```
Hệ thống sử dụng Connected Components (`scipy.ndimage`) để phát hiện từng nhân vật độc lập, xóa nền trắng và lưu thành `npc_char_01.png`, `npc_char_02.png`...

### Cách 2: Sinh nhân vật mới qua script tự động
```bash
python tools/character_generator.py --id visitor_baker --prompt "Chibi female baker wearing cute chef hat with pink apron"
```
Script sẽ:
1. Tạo hoặc cắt ảnh nhân vật độ phân giải sắc nét với viền nâu ấm áp.
2. Xóa nền thông minh bằng Corner Floodfill (bảo vệ màu trắng của mắt và tạp dề).
3. Tự động chèn lệnh nạp vào `scripts/core/sprite_atlas_manager.gd`.

---

## 2. Tiêu Chuẩn Hoạt Họa Thủ Tục (Procedural Motion 60 FPS)

Mọi nhân vật `VisitorNPC` trong game được gắn chuyển động mượt mà không cần khung hoạt họa tay:
- **Idle Breathing (Thở khi đứng yên):**
  ```gdscript
  var breath: float = sin(time * 3.5) * 0.03
  _body_sprite.scale = Vector2(1.0 - breath * 0.5, 1.0 + breath)
  ```
- **Walk Bounce (Nhún bước đi):**
  ```gdscript
  var bounce_y: float = -absf(sin(_walk_phase * 6.0)) * 4.5
  var tilt: float = sin(_walk_phase * 3.0) * 0.055
  _body_sprite.position.y = bounce_y
  _body_sprite.rotation = tilt
  ```
- **Dynamic Shadow (Bóng đổ động co giãn):**
  ```gdscript
  _shadow_sprite.scale.x = 1.0 - absf(bounce_y) * 0.04
  ```

---

## 3. Đăng Ký Nhân Vật Vào Hệ Thống Khách Tham Quan (`data/visitors.json`)

Sau khi tạo sprite, thêm cấu hình vào `data/visitors.json`:
```json
"visitor_baker": {
  "id": "visitor_baker",
  "name": "Thợ Làm Bánh",
  "sprite_id": "visitor_baker",
  "move_speed": 45.0,
  "preferred_building": "bakery",
  "tip_multiplier": 1.5
}
```
Khách sẽ tự động được `VisitorManager` quản lý qua Object Pool (15 NPC) và đi tham quan nông trại.
