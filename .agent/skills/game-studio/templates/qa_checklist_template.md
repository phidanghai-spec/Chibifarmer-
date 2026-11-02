# 🧪 QA & Verification Checklist Template

## 1. Test Overview
- **Feature Tested:** `[Tên tính năng]`
- **QA Lead:** `qa-lead`
- **Date Tested:** `[YYYY-MM-DD]`
- **Godot Version:** `Godot 4.7.2 Standard (GL Compatibility)`

---

## 2. Automated Quality Gates

| Bước Kiểm Tra | Lệnh CLI | Kết Quả Mong Đợi | Trạng Thái |
| :--- | :--- | :--- | :---: |
| **1. Headless Compilation** | `& "D:\Gotdot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --path . --headless --quit` | `0 Errors, 0 Warnings` | [ ] PASS |
| **2. Interactive Unit Tests** | `& "D:\Gotdot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --path . --headless "res://tests/test_interactive_clicks.tscn"` | `All tests passed` | [ ] PASS |
| **3. Visual Screenshot Capture** | `& "D:\Gotdot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --path . "res://tests/capture_screenshot.tscn"` | Ảnh `debug_preview.png` sinh chuẩn | [ ] PASS |

---

## 3. Visual & Gameplay Inspections
- [ ] **Mouse Filter Check:** Không có `Control` hoặc `Container` nào chặn click chuột xuống bản đồ (`mouse_filter = 2` ngoại trừ nút bấm).
- [ ] **Sprite Fidelity:** Nhân vật đúng hình Chibi, con vật đúng chuồng thú, không viền đen chữ L, không bị vỡ ảnh.
- [ ] **Camera Translation:** Thao tác click và kéo chuột hoạt động chính xác cả khi camera đang zoom hoặc pan.
- [ ] **Economy Persistence:** Số vàng, kim cương và vật phẩm trong kho lưu đúng vào `user://hayday_save.json` sau khi thoát và vào lại game.

