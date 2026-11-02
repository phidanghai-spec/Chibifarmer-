# 📋 Game Feature Specification (GDD Template)

## 1. Feature Identity
- **Feature Name:** `[Tên Tính Năng]`
- **Target Epic / Milestone:** `[Epic / Milestone liên quan]`
- **Lead Designer:** `game-designer`
- **Lead Implementer:** `godot-gdscript-specialist`
- **Status:** `[DRAFT | APPROVED | IN PROGRESS | IMPLEMENTED]`

---

## 2. Executive Summary & Player Fantasy
*Mô tả 2-3 câu về trải nghiệm của người chơi khi tương tác với tính năng này.*

---

## 3. Core Mechanics & Interaction Loop
1. **Trigger / Bắt đầu:** Người chơi chạm vào đâu hoặc điều kiện nào kích hoạt?
2. **Process / Quá trình:** Cơ chế điều khiển (Click, Drag, Wait timer, Minigame)?
3. **Reward / Thu hoạch:** Sản phẩm, điểm XP, Vàng, hoặc hiệu ứng sinh thái tạo ra?
4. **Failure / Edge Cases:** Điều gì xảy ra khi kho đầy, thiếu nguyên liệu hoặc hủy thao tác?

---

## 4. Systems Integration & Economy Impact
- **Kho bãi liên quan:** `StorageManager` (Silo hay Barn?)
- **Công thức chế biến / Giá tiền:**
  - Nguyên liệu đầu vào:
  - Thời gian sản xuất / đếm ngược:
  - Sản phẩm đầu ra & giá bán:
- **Tương tác Du khách & Vườn thú:** Điểm `AttractionScore` cộng thêm? Du khách có mua mặt hàng này không?

---

## 5. Visual, Audio & Animation Specs
- **Sprite / Atlas ID:** `[Tên sprite cần dùng hoặc sinh mới qua chibi_asset_forge]`
- **Hoạt họa (Procedural Motion):**
  - Trạng thái Idle (Nhịp thở, xoay nhẹ):
  - Trạng thái Hoạt động / Di chuyển:
  - Hiệu ứng thu hoạch / Hạt bay (Particles):
- **Sound FX:** `[Tên âm thanh SFX phát ra khi click / hoàn thành]`

---

## 6. Acceptance Criteria (QA Sign-off)
- [ ] Kịch bản 1: Thao tác bình thường hoàn thành không lỗi.
- [ ] Kịch bản 2: Không bị chặn click chuột (`mouse_filter` an toàn).
- [ ] Kịch bản 3: Dữ liệu được lưu trữ tự động vào `SaveManager` (`user://hayday_save.json`).
- [ ] Kịch bản 4: Chạy kiểm tra headless `--headless --quit` đạt 0 Errors, 0 Warnings.

