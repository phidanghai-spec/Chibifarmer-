# QUYẾT ĐỊNH NHỊP THỜI GIAN (TIMING PACING) & KIỂM CHỨNG SỐ LIỆU KINH TẾ

- **Dự án:** HayDay Offline (`D:\HayDayOffline`) — Godot 4.7.2, GDScript 2.0
- **Tham chiếu:** `GEMINI.md`, `docs/data_audit.md`, `data/crops.json`, `data/items.json`, `data/animals.json`, `data/recipes.json`
- **Trạng thái:** **CHƯA SỬA CODE HAY JSON** — Chờ quyết định chọn phương án từ chủ dự án.

---

## 1. TRÍCH NGUYÊN VĂN QUY ĐỊNH VỀ NHỊP THỜI GIAN TỪ `GEMINI.md`

Trong [`GEMINI.md`](file:///d:/HayDayOffline/GEMINI.md), phần **1. TẦM NHÌN & 6 TRỤ CỘT GAMEPLAY**, mục số 1 (dòng 11) quy định nguyên văn:

> `1. **Trồng trọt (\`FieldPlot\`):** Ô đất trống (\`EMPTY\`) -> Chọn hạt giống (Lúa Mì/Ngô) chạm/lướt vào để gieo (\`GROWING\`) -> Đếm ngược nhanh (Lúa mì: 10 giây, Ngô: 20 giây để dễ test) -> Chín (\`READY\`) -> Dùng \`Liềm\` thu hoạch nhận x2 nông sản + XP, trả ô đất về \`EMPTY\`.`

*Ghi chú đối chiếu:* `GEMINI.md` chỉ nêu mốc số giây cụ thể cho `FieldPlot` (Lúa mì `10s`, Ngô `20s`) với lý do *"Đếm ngược nhanh ... để dễ test"*; các mục `AnimalPen`, `ProductionMachine` và `FishingSpot` không ghi số giây cứng trong `GEMINI.md`.

---

## 2. HIỆN TRẠNG NHỊP THỜI GIAN TRONG CODE & JSON

| Hệ thống | File JSON hiện khai báo | Hành vi thực tế đang chạy trong code |
| :--- | :--- | :--- |
| **Cây trồng (`FieldPlot`)** | `data/crops.json`: `180s – 1800s` (Lúa mì `180s`, Ngô `480s`, Mía `1800s`; riêng `apple_seed`/`mango_seed` = `15s`)<br>`data/items.json`: `10s – 50s` (Lúa mì `10s`, Ngô `20s`...) | `FieldPlot` đọc **`crops.json`** (`DataManager.get_crop()`), nên người chơi thực tế đang phải chờ **3 phút** cho Lúa mì và **8 phút** cho Ngô (nhân thêm `TickManager.dev_speed_multiplier` mặc định `1.0`, và `×1.25` tốc độ khi trời mưa `COZY_RAIN`). |
| **Vật nuôi (`AnimalPen`)** | `data/animals.json`: `1200s – 21600s` (Gà 20 phút, Bò 1 giờ, Heo 2 giờ, Cừu 6 giờ) | `scripts/entities/animal_pen.gd` (dòng 416) **hardcode `var duration: int = 15`** giây, hoàn toàn bỏ qua `animals.json`. |
| **Máy chế biến (`ProductionMachine`)** | `data/recipes.json`: `300s – 10800s` (5 phút đến 3 giờ; riêng `sanctuary_feed` = `12s`) | `scripts/entities/production_machine.gd` (dòng 260 & 341) **ép trần `mini(craft_time_seconds, 60)`**, khiến mọi công thức từ `300s` trở lên đều chạy đúng **60 giây**. |
| **Bộ nhân tốc độ (`TickManager`)** | Không nằm trong JSON | `scripts/core/tick_manager.gd` có sẵn biến `var dev_speed_multiplier: float = 1.0`, chia `duration_seconds / dev_speed_multiplier` (tối thiểu `1s`) khi tính `finish_timestamp`. |

---

## 3. SO SÁNH 2 PHƯƠNG ÁN NHỊP THỜI GIAN

### Phương án A: Nhịp nhanh 10–60 giây (Tổng quát 10s–60s/90s cho cả Cây, Vật nuôi & Chế biến)

| Tiêu chí | Ưu điểm | Nhược điểm |
| :--- | :--- | :--- |
| **Test tự động (`gdUnit4`, Bot 200 bước, CI)** | - Toàn bộ vòng đời Gieo $\rightarrow$ Chín $\rightarrow$ Gặt $\rightarrow$ Chế biến $\rightarrow$ Thu hoạch test được **theo thời gian thực thực sự** chỉ trong vài giây đến 1 phút.<br>- Không cần hack `dev_speed_multiplier` hay bỏ qua timer khi viết integration test.<br>- Bot hoặc QA chạy tay dễ kiểm tra trực tiếp tutorial, Quest, và animation thu hoạch trên UI thật. | - Nếu test bot chỉ chờ ngắn (ví dụ 200 bước $\times$ 3 frame $\approx$ 10 giây) thì chỉ mới thấy cây `10s` (`wheat`) chín chứ các món `45s–60s` vẫn cần đợi thêm hoặc dùng `dev_speed_multiplier`. |
| **Cảm giác chơi (Gameplay Feel)** | - Đúng tinh thần game **Offline / Cozy Session ngắn** (chơi 5–15 phút mỗi lượt là trọn vẹn nhiều chu kỳ gieo–nấu–giao đơn xe tải/tàu hơi nước).<br>- Người chơi không bị "đứt mạch" ngồi nhìn màn hình chờ 30–60 phút vì game offline không có bạn bè online hay bang hội chat bù vào lúc chờ.<br>- Phản hồi tức thì, phù hợp cho cả chơi thư giãn lẫn test nhanh theo `GEMINI.md`. | - Dễ kiếm tiền/lên cấp quá nhanh nếu không cân đối lượng XP và giá trị đơn hàng.<br>- Tính năng **"Chờ qua đêm / Offline Earnings"** (`OfflineSimulator`, tăng tốc 1 diamond ở `ProductionMachine`, Bảng Tin giảm giá 180s) mất đi phần lớn lý do tồn tại nếu cái gì cũng xong sau 15–60 giây.<br>- Kho Silo/Barn mau đầy ứ nếu người chơi spam trồng lúa 10s liên tục. |

### Phương án B: Giữ nhịp Idle dài theo JSON gốc (3–30 phút cây trồng, 20 phút–6 giờ vật nuôi/máy; bỏ hardcode `15s` & cap `60s`)

| Tiêu chí | Ưu điểm | Nhược điểm |
| :--- | :--- | :--- |
| **Test tự động (`gdUnit4`, Bot 200 bước, CI)** | - Có thể vẫn pass nhanh **nếu và chỉ nếu** bộ test bật `TickManager.dev_speed_multiplier = 60.0` (hoặc mô phỏng timestamp qua `TickManager`).<br>- Phơi bày rõ các lỗi timeout/trạng thái pending dài hạn (như lưu timer vào SaveManager khi tắt mở lại game). | - Không test được vòng lặp hoàn chỉnh theo thời gian thực trong CI/bot 10–30 giây nếu quên chỉnh hệ số tốc độ.<br>- Rủi ro **sai khác hành vi giữa môi trường Test và Production**: nếu test dùng `dev_speed_multiplier = 100.0`, nhiều bug làm tròn số nguyên (`adjusted < 1 -> 1`) hoặc sai số tween/label sẽ không bị phát hiện giống lúc chơi thật.<br>- Đi ngược trực tiếp chỉ dẫn *"Lúa mì: 10 giây, Ngô: 20 giây để dễ test"* trong `GEMINI.md`. |
| **Cảm giác chơi (Gameplay Feel)** | - Đúng cấu trúc chiến lược **Hay Day gốc**: buộc người chơi tính toán trước khi đi ngủ/đi làm, tạo giá trị thực cho `OfflineSimulator` (lợi nhuận vắng nhà), nút **Đẩy nhanh bằng Kim Cương**, và Báo Nông Thôn (`180s`).<br>- Tạo nhịp nghỉ tự nhiên, kéo dài tuổi thọ nội dung Lv 1–33 (không bị phá đảo quá sớm). | - **Rất dễ gây chán trong game Offline thuần**: Cấp 1 trồng Ngô chờ 8 phút, Gà đẻ trứng chờ 20 phút, Mía chờ 30 phút, Bánh kem 90 phút — người chơi mới sẽ không có việc gì làm sau 2 phút đầu tiên (đặc biệt khi chơi từ Lv 1 bị khóa hết công trình cấp cao!).<br>- Cần hệ thống nhiệm vụ/săn cá/mini-game rất dày để lấp khoảng trống thời gian chờ, nếu không trải nghiệm sẽ bị khựng nặng. |

*(Ghi chú lựa chọn trung gian để tham khảo nếu bạn muốn cân nhắc thêm: giữ `crops.json` nhịp nhanh–vừa từ `10s` đến `180s` (Lúa mì `10s`, Ngô `20s`, cây trung cấp `45s–90s`, cây lâu năm `120s–180s`) và vật nuôi/máy từ `15s` đến `180s`, vừa khớp `GEMINI.md` ở đầu game vừa còn độ dốc chiến lược cho cấp cao — quyết định cuối cùng vẫn chờ bạn chọn A hoặc B hoặc biến thể).*

---

## 4. KIỂM CHỨNG TOÀN BỘ SỐ LIỆU KINH TẾ TRONG `docs/data_audit.md`

Đã viết script tính lại toàn bộ 20 công thức trong `data/recipes.json` kết hợp tra giá từng nguyên liệu từ `data/items.json` (nguồn `DataManager.get_item_base_price()` hiện ưu tiên) và đối chiếu thêm với `data/crops.json` và `data/animals.json`.

### 4.1. Danh sách các điểm KHÔNG KHỚP / THIẾU SÓT phát hiện trong `docs/data_audit.md`

| STT | Mục trong `docs/data_audit.md` | Giá trị `data_audit.md` đang ghi | Kết quả tính lại thực tế từ JSON | Kết luận |
| :---: | :--- | :--- | :--- | :--- |
| **1** | **Dòng 119 — `cow_feed` (`1 corn + 2 soybean`)** | Ghi tổng nguyên liệu là **`27~35`** ở cột *"Giá trị hiện tại"* | - Theo `items.json`: $1 \times 7 + 2 \times 10 = \mathbf{27}$<br>- Theo `crops.json`: $1 \times 9 + 2 \times 10 = \mathbf{29}$ | **KHÔNG KHỚP.** Số `35` không tồn tại ở file hiện tại (đó là giá nếu áp đề xuất `soybean=14`: $7 + 2 \times 14 = 35$, bị gộp nhầm vào cột *"Giá trị hiện tại"*). |
| **2** | **Dòng 120 — `pig_feed` (`2 carrot + 1 soybean`)** | Ghi tổng nguyên liệu là **`26~34`** ở cột *"Giá trị hiện tại"* | - Theo `items.json`: $2 \times 8 + 1 \times 10 = \mathbf{26}$<br>- Theo `crops.json`: $2 \times 8 + 1 \times 10 = \mathbf{26}$ | **KHÔNG KHỚP.** Hiện tại cả hai file đều bằng đúng **`26`**, số `34` là sai cho hiện trạng (bị gộp nhầm từ giá đề xuất `carrot=10, soybean=14`: $2 \times 10 + 14 = 34$). |
| **3** | **Dòng 118 — `chicken_feed` (`2 wheat + 1 corn`)** | Ghi tổng nguyên liệu là **`13`** | - Theo `items.json`: $2 \times 3 + 1 \times 7 = \mathbf{13}$ (Khớp)<br>- Theo `crops.json`: $2 \times 3 + 1 \times 9 = \mathbf{15}$ | **Thiếu ghi chú 2 nguồn:** Đúng `13` theo `items.json`, nhưng nếu dùng SSOT `crops.json` hiện tại thì chi phí là `15` (khi thu `1` bao giá `7` sẽ lỗ `-8`, còn thu `3` bao giá `21` lãi `+6`). |
| **4** | **Dòng 105 & `mango_smoothie` (`2 mango + 1 milk`)** | Đề xuất `mango = 30` (giảm từ `36` ở `crops.json`), nhưng **không kiểm tra** lãi của `mango_smoothie` (`base_price = 110`) | - Theo `items.json` (`mango=22, milk=28`): vốn `72`, bán `110` $\rightarrow$ lãi **`+38`**.<br>- Theo `crops.json` (`mango=36, milk=28`): vốn **`100`**, bán `110` $\rightarrow$ lãi chỉ **`+10`** (+10%).<br>- Với đề xuất `mango=30`: vốn **`88`**, bán `110` $\rightarrow$ lãi chỉ **`+22`**. | **Thiếu cân đối dây chuyền:** Đề xuất `mango=30` làm `mango_smoothie` lãi ít hơn cả `apple_juice` hiện tại theo `items.json` (`+35`) dù cần thêm `milk` và thời gian lâu hơn. Cần đặt `mango` quanh `22–24` hoặc nâng `mango_smoothie` lên `130–145`. |
| **5** | **Dòng 102 — Đề xuất tăng `sugarcane = 16`** | Đề xuất nâng `sugarcane` từ `14` $\rightarrow$ `16` để vượt `pumpkin`, nhưng **không xét** `sugarcane_juice` (`base_price = 38`) và `butter_cookie` (`150`) | - Với `sugarcane = 16`: vốn `sugarcane_juice` (`2 sugarcane`) tăng từ `28` $\rightarrow$ **`32`**, biên lãi rớt từ `+10` xuống chỉ còn **`+6`** (`+18.7%`).<br>- Vốn `butter_cookie` tăng nhẹ từ `44` $\rightarrow$ `46`. | **Thiếu cập nhật giá thành phẩm kèm theo:** Nếu tăng `sugarcane = 16` thì nên cân nhắc tăng `sugarcane_juice` lên `42–45` (hoặc giữ `sugarcane = 14`, `pumpkin = 12`). |
| **6** | **Mục `sanctuary_feed` (`3 wheat + 2 corn + 1 carrot`, `produce_count = 2`, `base_price = 35`)** | `data_audit.md` **chưa liệt kê** sự chênh lệch chi phí và lỗi hòa vốn runtime | - Theo `items.json`: $3 \times 3 + 2 \times 7 + 1 \times 8 = \mathbf{31}$<br>- Theo `crops.json`: $3 \times 3 + 2 \times 9 + 1 \times 8 = \mathbf{35}$<br>- Code hiện trả `1` bó = `35` $\rightarrow$ theo `crops.json` là **lãi `0` vàng**! | **Thiếu trong `data_audit.md`:** Cần bổ sung lưu ý sửa `collect_all()` nhận `produce_count = 2` (doanh thu `70`) cho `sanctuary_feed` tương tự nhóm thức ăn gia súc. |
| **7** | **Tương tác `daily_newspaper.gd` với `cookie`** | Dòng 121 ghi `daily_newspaper.gd` dùng `cookie`, đối chiếu với `cookie = 150` | Trong `scripts/systems/daily_newspaper.gd` dòng 41, `base_price` của `cookie` bị hardcode là **`45`** (không phải `150` như `items.json`), gần bằng giá gốc nguyên liệu `44` trước khi giảm giá `30–50%`! | **Bổ sung quan trọng:** Ngoài việc gộp `cookie` về `butter_cookie`, cần bỏ số `45` hardcode ở `DailyNewspaper` để tránh bán rẻ bánh quy còn `22–31` vàng. |

---

### 4.2. Bảng đối chiếu tính lại đầy đủ 20 công thức từ `recipes.json` & `items.json` (Xác nhận phần khớp & phần lệch)

| Công thức (`recipes.json`) | Nguyên liệu | Vốn (`items.json`) | Vốn (`crops.json` + `items.json`) | Giá SP (`recipes` / `items`) | SL (`produce_count`) | Doanh thu đủ SL / 1 món | Lãi theo `items.json` (đủ SL / hiện tại 1 món) | Trạng thái khớp với `data_audit.md` |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| `chicken_feed` | `2 wheat, 1 corn` | `13` | `15` | `7` / `7` | `3` | `21` / `7` | `+8` / `-6` | Khớp số `13` (`items.json`), thiếu ghi `15` (`crops.json`) |
| `bread` | `3 wheat` | `9` | `9` | `21` / `21` | `1` | `21` / `21` | `+12` / `+12` | Không có sai lệch |
| `cow_feed` | `1 corn, 2 soybean` | **`27`** | **`29`** | `14` / `14` | `3` | `42` / `14` | `+15` / `-13` | **SAI ở `data_audit.md`:** ghi `27~35` |
| `butter` | `1 milk` | `28` | `28` | `50` / `50` | `1` | `50` / `50` | `+22` / `+22` | Khớp (nhưng `animals.json` để `cow=30`) |
| `pig_feed` | `2 carrot, 1 soybean` | **`26`** | **`26`** | `14` / `14` | `3` | `42` / `14` | `+16` / `-12` | **SAI ở `data_audit.md`:** ghi `26~34` |
| `corn_bread` | `2 corn, 2 egg` | `38` | `42` | `90` / `90` | `1` | `90` / `90` | `+52` / `+52` | Không có sai lệch |
| `butter_cookie` | `2 wheat, 2 egg, 1 sugarcane` | `44` | `44` | `150` / `150` | `1` | `150` / `150` | `+106` / `+106` | Khớp (nhưng `DailyNewspaper` để `cookie=45`) |
| `cheese` | `3 milk` | `84` | `84` | `180` / `180` | `1` | `180` / `180` | `+96` / `+96` | Không có sai lệch |
| `cream_cake` | `2 strawberry, 2 egg, 1 milk` | `76` | `76` | `260` / `260` | `1` | `260` / `260` | `+184` / `+184` | Không có sai lệch |
| `sugarcane_juice` | `2 sugarcane` | `28` | `28` | `38` / `38` | `1` | `38` / `38` | `+10` / `+10` | Cảnh báo: đề xuất `sugarcane=16` sẽ giảm lãi còn `+6` |
| `apple_juice` | `2 apple` | `30` | `48` | `65` / `65` | `1` | `65` / `65` | `+35` / `+35` | Khớp (lãi theo `crops.json` là `+17`) |
| `mango_smoothie` | `2 mango, 1 milk` | `72` | **`100`** | `110` / `110` | `1` | `110` / `110` | `+38` / `+38` | Cảnh báo: theo `crops.json` lãi `+10`, đề xuất `mango=30` lãi `+22` |
| `red_lure` | `{}` | `0` | `0` | `20` / `N/A` (`bait_red=15`) | `1` | `20` | `+20` | Khớp bảng 2.2 (lệch ID & giá với `bait_red=15`) |
| `green_lure` | `{}` | `0` | `0` | `35` / `N/A` (`bait_blue=25`) | `1` | `35` | `+35` | Khớp bảng 2.2 (lệch ID & giá với `bait_blue=25`) |
| `gold_lure` | `{}` | `0` | `0` | `60` / `N/A` (`bait_gold=50`) | `1` | `60` | `+60` | Khớp bảng 2.2 (lệch ID & giá với `bait_gold=50`) |
| `sanctuary_feed` | `3 wheat, 2 corn, 1 carrot` | **`31`** | **`35`** | `35` / `35` | `2` | `70` / `35` | `+39` / `+4` | **Thiếu cảnh báo trong `data_audit.md`:** trả 1 món theo `crops.json` lãi `0` |
| `item_fish_pie` | `1 fish_carp, 2 wheat` | `31` | `31` | `55` / `55` | `1` | `55` / `55` | `+24` / `+24` | Khớp (bị đúp ID trong `items.json`) |
| `item_grilled_fish` | `1 fish_carp, 1 corn` | `32` | `34` | `52` / `52` | `1` | `52` / `52` | `+20` / `+20` | Khớp (bị đúp ID trong `items.json`) |
| `item_herbal_tea` | `1 rose, 1 honey` | `84` | `84` | `140` / `140` | `1` | `140` / `140` | `+56` / `+56` | Khớp (bị đúp ID trong `items.json`) |
| `item_bacon_eggs` | `2 egg, 1 bacon` | `89` | `89` | `150` / `150` | `1` | `150` / `150` | `+61` / `+61` | Khớp (bị đúp ID trong `items.json`) |

