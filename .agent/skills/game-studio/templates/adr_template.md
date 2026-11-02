# 🏛️ Architecture Decision Record (ADR Template)

- **ADR ID:** `ADR-[XXX]`
- **Title:** `[Tên quyết định kiến trúc]`
- **Date:** `[YYYY-MM-DD]`
- **Status:** `[PROPOSED | ACCEPTED | DEPRECATED | SUPERSEDED]`
- **Decider(s):** `technical-director`, `lead-programmer`

---

## 1. Context & Problem Statement
*Mô tả bài toán kỹ thuật cần giải quyết và các hạn chế (ví dụ: máy cấu hình nhẹ, GL Compatibility, tránh giật lag khi có 100 thực thể trên màn hình).*

---

## 2. Considered Options
1. **Phương án A:** `[Mô tả phương án & ưu nhược điểm]`
2. **Phương án B:** `[Mô tả phương án & ưu nhược điểm]`

---

## 3. Decision Outcome
- **Phương án lựa chọn:** `[Phương án được chọn]`
- **Lý do lựa chọn:**
- **Quy tắc bắt buộc khi triển khai:**
  - 100% Static Typing trong GDScript 2.0.
  - Sử dụng tín hiệu `signal` thông qua `EventBus` để tránh coupling cứng.
  - Xử lý tọa độ thế giới thông qua `get_global_mouse_position()`.

---

## 4. Consequences & Impact
- **Mặt tích cực:** Tốc độ render mượt mà 60 FPS, không crash khi reload cảnh.
- **Rủi ro & Cách khắc phục:** Cách kiểm thử để đảm bảo không phát sinh regression bug.

