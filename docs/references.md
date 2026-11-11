# TÀI LIỆU KHẢO SÁT & ĐỐI CHIẾU CÁC REPO THAM KHẢO (MỤC 10.4)

- **Dự án:** HayDay Offline (Chibi Farm) — Godot 4.7.2 Standard (`GL Compatibility`), GDScript 2.0
- **Tham chiếu:** `docs/HANDOVER.md` (Mục 10.1 – 10.4)
- **Ngày kiểm chứng:** 2026-11-11 (Xác minh trực tiếp qua GitHub REST API, file `LICENSE` và file `project.godot` của từng repository)

---

## 1. BẢNG TỔNG HỢP 8 REPO THAM KHẢO ĐÃ XÁC MINH

| # | Tên Repo | URL chính thức | Giấy phép (từ file `LICENSE`) | Phiên bản Godot (`project.godot`) | Commit / Push gần nhất | Học được gì cho dự án `HayDayOffline` | Quy tắc sử dụng an toàn bản quyền |
| :---: | :--- | :--- | :--- | :--- | :---: | :--- | :--- |
| **1** | **`nilold/farmer-game`** | [github.com/nilold/farmer-game](https://github.com/nilold/farmer-game) | **MIT License** (`LICENSE.md` — Christian Fisch, 2016) | **Godot 3.x** (`config_version=4`, GDScript 1.0) | **2020-10-06** (`master`) | Mô hình sinh trưởng cây (`crop/Crop.gd`, `Substract.gd`, `docs/crop-model-coffe.md`) phản ứng với độ ẩm đất, khoáng chất/phân bón, thời tiết (`world/weather.gd`) và sức khỏe cây ảnh hưởng tới năng suất/phẩm chất; cách tổ chức unit test nông nghiệp (`test/unit/test_crop.gd`). | **MIT** (đã ghi nhận vào `docs/THIRD_PARTY_NOTICES.md`). Vì code gốc là **Godot 3.x**, **không copy code**; chỉ trích xuất ý tưởng công thức và viết lại thành `CropQualityService` bằng GDScript 2.0 + SSOT `data/crops.json` (xem `docs/reference_crop_model.md`). |
| **2** | **`mrtheduts/My Cozy Garden of Hyper Evolved Plants`** *(Repo tên: `GoGodotJam3`)* | - GitHub: [github.com/mrtheduts/GoGodotJam3](https://github.com/mrtheduts/GoGodotJam3)<br>- Itch.io: [mrtheduts.itch.io/my-cozy-garden-of-hyper-evolved-plants](https://mrtheduts.itch.io/my-cozy-garden-of-hyper-evolved-plants) | **MIT License** (`LICENSE` — Eduardo Moreira Freitas de Souza, 2022) | **Godot 3.x** (`config_version=4`, `config/name="My Cozy Garden of Hyper Evolved Plants"`) | **2022-06-14** (`main`) | Cơ chế lai giống cây trồng (cross-breeding / mutation), bảng thuộc tính di truyền và hiệu ứng phản hồi thị giác ấm áp (Cozy feedback) khi thu hoạch biến thể cây hiếm (dùng cho tính năng Giống lai sau Phase 2A). | **MIT** (đã ghi nhận vào `docs/THIRD_PARTY_NOTICES.md`). Vì viết trên **Godot 3.x**, không copy trực tiếp script cũ sang Godot 4.7.2 mà thiết kế lại theo chuẩn Static Typing GDScript 2.0. |
| **3** | **`Kenny-Haworth/Harvest-Moon-2.0`** | [github.com/Kenny-Haworth/Harvest-Moon-2.0](https://github.com/Kenny-Haworth/Harvest-Moon-2.0) | **MIT License** (`LICENSE` — Kendall Haworth, 2020) | **Godot 3.0 / 3.1** (`config_version=3`, `Harvest Moon 2.0/project.godot`) | **2020-07-15** (`master`) | Cấu trúc lưu/nạp trạng thái game (Save/Load dictionary), cơ chế dọn vật cản tự nhiên trên ruộng (gỗ, đá, cỏ dại), vòng lặp ngày/thời tiết và quản lý túi đồ. | **MIT** (đã ghi nhận vào `docs/THIRD_PARTY_NOTICES.md`). Dùng **Godot 3 đời đầu (`config_version=3`)**, chỉ đọc đối chiếu với `SaveManager` hiện có, tuyệt đối không copy hay thay thế `SaveManager`. |
| **4** | **`joshmitcho/serfdom`** | [github.com/joshmitcho/Serfdom](https://github.com/joshmitcho/Serfdom) | **GNU GPL v3.0 (`GPL-3.0`)** (`LICENSE`) | **Godot 4.2** (`config_version=5`, `features=["4.2"]`) | **2023-12-04** (`main`) | Bố cục UX của menu chế tạo (Crafting UI), quản lý rương chứa đồ và cách tích hợp hội thoại/quan hệ NPC trong Godot 4. | **CẢNH BÁO GPL-3.0 (Copyleft mạnh):** **TUYỆT ĐỐI KHÔNG copy bất kỳ dòng code, script hay asset nào** vào dự án để tránh nhiễm giấy phép GPL-3.0. Chỉ quan sát luồng UX ở mức ý tưởng. |
| **5** | **`studio-miroro/littlefamer`** | [github.com/studio-miroro/littlefamer](https://github.com/studio-miroro/littlefamer) | **CC-BY-4.0** (`LICENSE-CCBY-4.0`) | **Godot 4.2** (`config_version=5`, `features=["4.2", "Forward Plus"]`) | **2026-11-10** (`farmer`) | Vòng lặp kinh tế nông trại tối giản (mua hạt giống $\rightarrow$ trồng $\rightarrow$ thu hoạch $\rightarrow$ bán) và tổ chức scene trong Godot 4.2. | Giấy phép **CC-BY-4.0** (thường dùng cho tài nguyên/tài liệu hơn là mã nguồn phần mềm, yêu cầu ghi công và nêu rõ thay đổi). **Không copy code hay asset**; chỉ đọc tham khảo cách tổ chức vòng lặp kinh tế nhỏ. |
| **6** | **`Terkwood/PLOWMAN`** | [github.com/Terkwood/PLOWMAN](https://github.com/Terkwood/PLOWMAN) | **GNU GPL v3.0 (`GPL-3.0`)** (`LICENSE`) + Asset theo **LPC (CC-BY-SA 3.0 / GPL-3.0)** | **Godot 3.1+** (`config_version=4`, `config/name="PLOWMAN"`) | **2019-04-14** (`unstable`) | Ý tưởng trao phần thưởng tức thì theo từng hành động nhỏ trên đồng ruộng và cách lập danh mục ghi nhận nguồn tài nguyên mở. | **CẢNH BÁO GPL-3.0 & CC-BY-SA:** **TUYỆT ĐỐI KHÔNG copy code hoặc asset LPC.** Ngoài rủi ro bản quyền Copyleft, đồ họa Pixel Art LPC cũng trái với quy chuẩn **2.5D Cozy Chibi Pastel Storybook** trong `GEMINI.md`. |
| **7** | **`angle-mad/farm-game`** | [github.com/angle-mad/farm-game](https://github.com/angle-mad/farm-game) | **MIT License** (`LICENSE` — Angel Madrigal, 2026) | **Godot 4.5** (`config_version=5`, `features=["4.5", "Forward Plus"]`) | **2026-04-07** (`main`) | Cách thiết lập ô lưới bản đồ và chuyển đổi công cụ canh tác cơ bản trên Godot 4.5+. | **MIT** (đã ghi nhận vào `docs/THIRD_PARTY_NOTICES.md`). Có thể tham khảo cách viết GDScript 2.0 trên Godot 4.5, nhưng `HayDayOffline` đã có `GridManager` và `DragActionManager` riêng nên chỉ dùng để đối chiếu. |
| **8** | **`phidanghai-spec/Chibifarmer-`** | [github.com/phidanghai-spec/Chibifarmer-](https://github.com/phidanghai-spec/Chibifarmer-) | **Chưa có file `LICENSE`** (Nội bộ dự án / All Rights Reserved) | **Godot 4.7.2** (`config_version=5`, `features=["4.7", "GL Compatibility"]`) | **2026-11-02** (`main`) | **Đây chính là repo remote `origin` của dự án `D:\HayDayOffline`** (khớp `.git/config` và commit `fa96a581b8c95cf6d6539d26796ce6f8c28e61fb`). Chứa đầy đủ `GEMINI.md`, `data/`, `scripts/`, `tests/`, `tools/`. | Repo gốc của chủ dự án (`phidanghai-spec`). Cần xác nhận giữ làm repo chuẩn duy nhất và bổ sung file `LICENSE` phù hợp trước khi phát hành. |

---

## 2. PHÂN LOẠI TRẠNG THÁI KIỂM CHỨNG & RỦI RO BẢN QUYỀN

### 2.1. Ghi chú xác minh đường dẫn (`mrtheduts/My Cozy Garden of Hyper Evolved Plants`)
- Khi truy vấn trực tiếp theo tên hiển thị `https://github.com/mrtheduts/my-cozy-garden-of-hyper-evolved-plants`, GitHub trả về `404 Not Found`.
- Qua kiểm tra danh sách repository của tác giả `@mrtheduts` (Eduardo Moreira Freitas de Souza), mã nguồn chính thức của trò chơi này được lưu tại repo **[`mrtheduts/GoGodotJam3`](https://github.com/mrtheduts/GoGodotJam3)** (tên đặt theo kỳ thi *GoGodotJam 3*).
- File `project.godot` tại nhánh `main` của `mrtheduts/GoGodotJam3` xác nhận:
  ```ini
  config_version=4
  config/name="My Cozy Garden of Hyper Evolved Plants"
  ```
- File `LICENSE` tại gốc repo xác nhận giấy phép **MIT License** (`Copyright (c) 2022 Eduardo Moreira Freitas de Souza`).

### 2.2. Danh sách Repo theo nhóm Giấy phép
1. **Nhóm Giấy phép MIT (An toàn để học thuật toán / tham khảo sâu, đã đưa vào `docs/THIRD_PARTY_NOTICES.md`):**
   - `nilold/farmer-game` (MIT — Christian Fisch, 2016)
   - `mrtheduts/GoGodotJam3` / *My Cozy Garden of Hyper Evolved Plants* (MIT — Eduardo Moreira Freitas de Souza, 2022)
   - `Kenny-Haworth/Harvest-Moon-2.0` (MIT — Kendall Haworth, 2020)
   - `angle-mad/farm-game` (MIT — Angel Madrigal, 2026)
2. **Nhóm Giấy phép Copyleft / Hạn chế (`GPL-3.0`, `CC-BY-4.0`) — CẤM SAO CHÉP CODE & ASSET:**
   - `joshmitcho/Serfdom` (**GPL-3.0**)
   - `Terkwood/PLOWMAN` (**GPL-3.0** + Asset LPC **CC-BY-SA 3.0**)
   - `studio-miroro/littlefamer` (**CC-BY-4.0**)
3. **Nhóm Chưa gắn `LICENSE` công khai:**
   - `phidanghai-spec/Chibifarmer-` (Repo chính của dự án `D:\HayDayOffline` — đã xác nhận qua `.git/config`).

### 2.3. Danh sách Repo theo Phiên bản Godot
- **Godot 3.x (`config_version=3` hoặc `config_version=4` — GDScript 1.0):**
  1. `Kenny-Haworth/Harvest-Moon-2.0` (`config_version=3` — Godot 3.0/3.1)
  2. `nilold/farmer-game` (`config_version=4` — Godot 3.2.x)
  3. `Terkwood/PLOWMAN` (`config_version=4` — Godot 3.1+)
  4. `mrtheduts/GoGodotJam3` (*My Cozy Garden of Hyper Evolved Plants*, `config_version=4` — Godot 3.x)
  > **Quy tắc bắt buộc với nhóm Godot 3.x:** Cú pháp GDScript 1.0 (`export var`, `onready var`, `setget`, `connect("signal", target, "method")`, `rand_range()`) không tương thích với Godot 4.7.2 và vi phạm tiêu chuẩn **100% Static Typing GDScript 2.0** của dự án. Chỉ đọc hiểu mô hình toán học / luồng dữ liệu rồi viết mới hoàn toàn.
- **Godot 4.x (`config_version=5` — GDScript 2.0):**
  1. `joshmitcho/Serfdom` (Godot 4.2)
  2. `studio-miroro/littlefamer` (Godot 4.2)
  3. `angle-mad/farm-game` (Godot 4.5)
  4. `phidanghai-spec/Chibifarmer-` (Godot 4.7 — Chính là dự án hiện tại)

---

## 3. QUY TẮC TÍCH HỢP AN TOÀN CHO ĐỘI NGŨ PHÁT TRIỂN

1. **Nguyên tắc Clean-Room Design (Đọc hiểu kiến trúc — Viết lại theo chuẩn dự án):**
   - Trong giai đoạn hiện tại, **TUYỆT ĐỐI KHÔNG copy bất kỳ đoạn code hay file tài nguyên nào** từ các repo bên ngoài vào `res://`.
   - Mọi tính năng học hỏi từ repo tham khảo (như `CropQualityService` từ `nilold/farmer-game` hay hệ thống giống lai từ `My Cozy Garden`) chỉ được triển khai **sau khi hoàn tất Phase 2A (Cân đối kinh tế) và Phase 2B (Lấp khoảng chờ đầu game)**.
2. **Tuân thủ Single Source of Truth (SSOT — Quyết định D4):**
   - Không dùng các biến `export var` rời rạc trên từng scene như cách làm của `nilold/farmer-game` hay `Harvest-Moon-2.0`. Toàn bộ thông số cây trồng phải đọc tập trung từ `data/crops.json` thông qua `DataManager`.
3. **Tuân thủ Phong cách Đồ họa Chibi (`GEMINI.md` Mục 2 & Mục 6):**
   - Không nhập các bộ tile hay sprite Pixel Art từ `Serfdom`, `PLOWMAN`, `littlefamer` hay `farm-game`. Mọi sprite mới phải tạo qua pipeline `tools/chibi_asset_forge.py` hoặc `agent-sprite-forge` theo phong cách **2.5D Cozy Chibi Pastel Storybook**.
