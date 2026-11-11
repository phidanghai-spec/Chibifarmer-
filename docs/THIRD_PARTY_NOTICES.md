# THIRD-PARTY NOTICES & ATTRIBUTION (GHI NHẬN BẢN QUYỀN BÊN THỨ BA)

Tài liệu này ghi nhận bản quyền của Engine, công cụ kiểm thử, các kho mã nguồn mở (Open-Source Repositories) có giấy phép **MIT / CC0** được tham khảo kiến trúc, cũng như quy chuẩn ghi công bắt buộc khi phát hành dự án **HayDay Offline (Chibi Farm)**.

> **Lưu ý quan trọng:** Trong giai đoạn hiện tại (Phase 1 – Phase 2B), dự án **chưa sao chép trực tiếp bất kỳ tệp mã nguồn nào** từ các kho lưu trữ tham khảo bên ngoài. Việc liệt kê đầy đủ giấy phép MIT dưới đây nhằm đảm bảo tuân thủ bản quyền chủ động ngay từ bước thiết kế và sẵn sàng cho các giai đoạn mở rộng sau Phase 2A.

---

## 1. ENGINE & CÔNG CỤ TÍCH HỢP TRỰC TIẾP TRONG DỰ ÁN

### 1.1. Godot Engine (v4.7.2 Standard)
- **Trang chủ / Nguồn:** https://godotengine.org
- **Giấy phép:** MIT License
- **Bản quyền:**
  ```text
  Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md).
  Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
  ```

### 1.2. gdUnit4 — Godot Unit Testing Framework (`res://addons/gdUnit4`)
- **Kho lưu trữ:** https://github.com/MikeSchulze/gdUnit4
- **Giấy phép:** MIT License
- **Bản quyền:** `Copyright (c) 2023 Mike Schulze`

---

## 2. CÁC REPO THAM KHẢO KIẾN TRÚC CÓ GIẤY PHÉP MIT (MỤC 10.1 & 10.4)

### 2.1. `nilold/farmer-game`
- **Kho lưu trữ:** https://github.com/nilold/farmer-game
- **Phạm vi tham khảo:** Mô hình toán học sinh trưởng cây trồng phản ứng với độ ẩm đất, khoáng chất/phân bón và thời tiết (`crop/Crop.gd`, `Substract.gd`, `docs/crop-model-coffe.md`), được thiết kế lại thành `CropQualityService` cho Godot 4.7.2 (xem `docs/reference_crop_model.md`).
- **Giấy phép:** MIT License (`LICENSE.md`)
- **Nội dung giấy phép gốc:**
  ```text
  The MIT License (MIT)

  Copyright (c) 2016 Christian Fisch.

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.
  ```

### 2.2. `mrtheduts/My Cozy Garden of Hyper Evolved Plants` (`GoGodotJam3`)
- **Kho lưu trữ GitHub:** https://github.com/mrtheduts/GoGodotJam3
- **Trang dự án Itch.io:** https://mrtheduts.itch.io/my-cozy-garden-of-hyper-evolved-plants
- **Phạm vi tham khảo:** Thiết kế hệ thống lai giống cây trồng (plant cross-breeding) và biến thể cây trồng (dự kiến sau Phase 2A).
- **Giấy phép:** MIT License (`LICENSE`)
- **Nội dung giấy phép gốc:**
  ```text
  MIT License

  Copyright (c) 2022 Eduardo Moreira Freitas de Souza

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
  ```

### 2.3. `Kenny-Haworth/Harvest-Moon-2.0`
- **Kho lưu trữ:** https://github.com/Kenny-Haworth/Harvest-Moon-2.0
- **Phạm vi tham khảo:** Đối chiếu cấu trúc lưu trữ trạng thái nông trại (Save/Load dictionary) và quản lý vật cản tự nhiên trên đồng ruộng.
- **Giấy phép:** MIT License (`LICENSE`)
- **Nội dung giấy phép gốc:**
  ```text
  MIT License

  Copyright (c) 2020 Kendall Haworth

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
  ```

### 2.4. `angle-mad/farm-game`
- **Kho lưu trữ:** https://github.com/angle-mad/farm-game
- **Phạm vi tham khảo:** Đối chiếu cách tổ chức ô lưới và chuyển đổi công cụ canh tác cơ bản trong Godot 4.5.
- **Giấy phép:** MIT License (`LICENSE`)
- **Nội dung giấy phép gốc:**
  ```text
  MIT License

  Copyright (c) 2026 Angel Madrigal

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
  ```

---

## 3. TÀI NGUYÊN ĐỒ HỌA & ÂM THANH CÔNG CỘNG (CC0 1.0 UNIVERSAL)

### 3.1. Kenney.nl Game Assets
- **Trang chủ / Nguồn:** https://kenney.nl
- **Giấy phép:** **CC0 1.0 Universal (Public Domain Dedication)** — https://creativecommons.org/publicdomain/zero/1.0/
- **Quyền sử dụng:** Tự do sao chép, chỉnh sửa, phân phối và sử dụng cho cả mục đích cá nhân lẫn thương mại mà không bắt buộc phải xin phép.
- **Ghi công khuyến nghị (Voluntary Credit):** *"Selected UI icons / sound effects courtesy of Kenney.nl (CC0 1.0)"*.

---

## 4. QUY CHUẨN GHI CÔNG & TUÂN THỦ BẢN QUYỀN (COMPLIANCE RULES)

Khi bổ sung tính năng, mã nguồn hoặc tài nguyên mới vào `HayDayOffline`, mọi thành viên và AI Agent phải tuân thủ nghiêm ngặt 4 quy tắc sau:

1. **Quy chuẩn với Giấy phép MIT / BSD / Apache-2.0:**
   - Nếu sao chép hoặc chuyển đổi trực tiếp một thuật toán/module từ repo MIT (ví dụ `mrtheduts/GoGodotJam3` hoặc `nilold/farmer-game`), phải giữ nguyên dòng `Copyright (c) <Năm> <Tên tác giả>` và toàn văn giấy phép MIT trong tệp `docs/THIRD_PARTY_NOTICES.md` này, đồng thời ghi chú ngắn ở đầu file `.gd` tương ứng:
     ```gdscript
     # Inspired by / Adapted from <repo_name> (MIT License, Copyright (c) <Year> <Author>)
     ```
2. **Quy chuẩn với Giấy phép CC0 (Public Domain):**
   - Kiểm tra kỹ trang gốc (như Kenney.nl hoặc gói itch.io) để xác nhận đúng giấy phép `CC0 1.0`. Ghi lại tên gói và URL vào mục 3 của tài liệu này để dễ kiểm toán nguồn gốc asset.
3. **Quy chuẩn với Giấy phép CC-BY 4.0 (ví dụ `studio-miroro/littlefamer`):**
   - Nếu sử dụng bất kỳ tài liệu hay thành phần nào theo `CC-BY-4.0`, bắt buộc ghi rõ: Tên tác phẩm, Tên tác giả, Liên kết tới giấy phép `CC-BY-4.0`, và nêu rõ có chỉnh sửa hay không. Dự án hiện **không sao chép** code hay asset từ nguồn này.
4. **Danh sách CẤM SAO CHÉP (Copyleft GPL-3.0 / CC-BY-SA 3.0):**
   - Các repo `joshmitcho/Serfdom` (**GPL-3.0**) và `Terkwood/PLOWMAN` (**GPL-3.0 / LPC CC-BY-SA 3.0**) có điều khoản Copyleft bắt buộc mọi sản phẩm phái sinh phải mở toàn bộ mã nguồn theo cùng giấy phép.
   - **TUYỆT ĐỐI KHÔNG copy bất kỳ dòng code, script, shader hay hình ảnh nào** từ các repo mang giấy phép `GPL` hoặc `CC-BY-SA` vào `HayDayOffline`.
