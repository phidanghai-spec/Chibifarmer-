#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
tools/rebuild_chibi_barn.py
---------------------------
Tạo lại tòa NHÀ KHO (building_barn.png & chibi_barn_red.png) chuẩn 2.5D Chibi Cozy Farm
và nâng cấp toàn bộ Icon nông sản trong Kho Silo:
apple, pumpkin, strawberry, tomato, sugarcane, wheat, soybean, carrot, corn.
Sử dụng bộ kết xuất 2.5D Supersampling (512x512 downscale về 256x256 bằng LANCZOS).
"""

import os
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SPRITES_DIR = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "assets", "sprites"))

OUTLINE_COLOR = (72, 40, 22, 255)      # #482816
CREAM_TRIM    = (255, 243, 214, 255)   # #FFF3D6
SHADOW_COLOR  = (35, 65, 30, 85)       # rgba(35, 65, 30, 85)
STRAW_YELLOW  = (245, 194, 66, 255)    # #F5C242
STRAW_DARK    = (214, 158, 38, 255)

def draw_supersampled_barn(size=512) -> Image.Image:
    """Vẽ Nhà Kho Chibi 2.5D ở độ phân giải 512x512."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2

    # 1. Bóng đổ elip mềm mại phía dưới đáy nhà kho
    # rgba(35, 65, 30, 85)
    shadow_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow_img)
    s_draw.ellipse([cx - 180, cy + 130, cx + 180, cy + 215], fill=SHADOW_COLOR)
    shadow_img = shadow_img.filter(ImageFilter.GaussianBlur(radius=10))
    img = Image.alpha_composite(img, shadow_img)
    draw = ImageDraw.Draw(img)

    # 2. Thân nhà kho (Barn Main Body)
    # Tường gỗ đỏ ấm: #C83E32 chuyển sắc xuống #9E2820
    b_left = cx - 145
    b_right = cx + 145
    b_top = cy - 20
    b_bottom = cy + 175
    b_width = b_right - b_left
    b_height = b_bottom - b_top

    # Viền ngoài thân nhà kho
    draw.rectangle([b_left - 6, b_top - 6, b_right + 6, b_bottom + 6], fill=OUTLINE_COLOR)

    # Gradient đỏ ấm cho thân tường
    for y in range(b_top, b_bottom + 1):
        t = (y - b_top) / float(b_height)
        r = int(200 * (1 - t) + 158 * t)
        g = int(62 * (1 - t) + 40 * t)
        b = int(50 * (1 - t) + 32 * t)
        draw.line([(b_left, y), (b_right, y)], fill=(r, g, b, 255))

    # Vân ván gỗ dọc song song
    num_planks = 14
    plank_w = b_width / num_planks
    for i in range(1, num_planks):
        px = int(b_left + i * plank_w)
        # Đường kẻ tối giữa các ván gỗ
        draw.line([(px, b_top), (px, b_bottom)], fill=(120, 28, 22, 220), width=3)
        # Highlight mép ván gỗ
        draw.line([(px + 1, b_top), (px + 1, b_bottom)], fill=(225, 80, 70, 110), width=1)

    # Nền móng gạch đá xám chân tường
    draw.rectangle([b_left - 4, b_bottom - 16, b_right + 4, b_bottom + 4], fill=(130, 125, 120, 255), outline=OUTLINE_COLOR, width=4)
    draw.rectangle([b_left, b_bottom - 12, b_right, b_bottom], fill=(160, 155, 150, 255))
    for fx in range(b_left + 24, b_right, 32):
        draw.line([(fx, b_bottom - 12), (fx, b_bottom)], fill=(110, 105, 100, 255), width=2)

    # 3. Mái ngói vòm đôi kiểu Barn cổ điển (Gambrel Roof)
    # Gambrel roof profile:
    # Đỉnh: (cx, cy - 200)
    # Khúc gãy giữa hai dốc: (cx - 130, cy - 110), (cx + 130, cy - 110)
    # Mép dưới mái: (cx - 170, cy - 10), (cx + 170, cy - 10)
    
    # Mái viền ngoài dày nâu đậm
    outer_roof_poly = [
        (cx, cy - 212),
        (cx + 140, cy - 116),
        (cx + 180, cy - 8),
        (cx - 180, cy - 8),
        (cx - 140, cy - 116),
    ]
    draw.polygon(outer_roof_poly, fill=OUTLINE_COLOR)

    # Mái nền màu đỏ tươi hơn tường một chút
    roof_poly = [
        (cx, cy - 200),
        (cx + 130, cy - 110),
        (cx + 168, cy - 12),
        (cx - 168, cy - 12),
        (cx - 130, cy - 110),
    ]
    draw.polygon(roof_poly, fill=(215, 68, 55, 255))

    # Từng lớp ván ngói uốn cong mềm mại với vệt highlight
    # 4 dải ngói cong
    shingle_levels = [
        (cy - 180, cy - 150, 0.4),
        (cy - 148, cy - 110, 0.65),
        (cy - 108, cy - 65, 0.85),
        (cy - 63, cy - 16, 1.0)
    ]
    for s_top, s_bot, factor in shingle_levels:
        half_w = int(165 * factor)
        # Đường kẻ ngói
        draw.line([(cx - half_w, s_bot), (cx + half_w, s_bot)], fill=(145, 35, 25, 255), width=4)
        draw.line([(cx - half_w, s_bot - 2), (cx + half_w, s_bot - 2)], fill=(245, 110, 95, 180), width=2)
        # Các mối ghép ngói dọc
        step = max(18, int(30 * factor))
        for sx in range(cx - half_w + 12, cx + half_w - 6, step):
            draw.line([(sx, s_top), (sx, s_bot)], fill=(155, 38, 28, 200), width=2)
            draw.line([(sx + 1, s_top), (sx + 1, s_bot)], fill=(255, 120, 105, 150), width=1)

    # Viền gỗ kem ấm (#FFF3D6) bo viền mái trước
    fascia_poly_right = [
        (cx, cy - 202),
        (cx + 132, cy - 112),
        (cx + 170, cy - 12),
        (cx + 158, cy - 12),
        (cx + 122, cy - 110),
        (cx, cy - 196)
    ]
    draw.polygon(fascia_poly_right, fill=CREAM_TRIM)
    draw.line([(cx, cy - 202), (cx + 132, cy - 112)], fill=OUTLINE_COLOR, width=4)
    draw.line([(cx + 132, cy - 112), (cx + 170, cy - 12)], fill=OUTLINE_COLOR, width=4)
    draw.line([(cx + 158, cy - 12), (cx + 122, cy - 110)], fill=OUTLINE_COLOR, width=2)
    draw.line([(cx + 122, cy - 110), (cx, cy - 196)], fill=OUTLINE_COLOR, width=2)

    fascia_poly_left = [
        (cx, cy - 202),
        (cx - 132, cy - 112),
        (cx - 170, cy - 12),
        (cx - 158, cy - 12),
        (cx - 122, cy - 110),
        (cx, cy - 196)
    ]
    draw.polygon(fascia_poly_left, fill=CREAM_TRIM)
    draw.line([(cx, cy - 202), (cx - 132, cy - 112)], fill=OUTLINE_COLOR, width=4)
    draw.line([(cx - 132, cy - 112), (cx - 170, cy - 12)], fill=OUTLINE_COLOR, width=4)
    draw.line([(cx - 158, cy - 12), (cx - 122, cy - 110)], fill=OUTLINE_COLOR, width=2)
    draw.line([(cx - 122, cy - 110), (cx, cy - 196)], fill=OUTLINE_COLOR, width=2)

    # Đỉnh mái trang trí quả cầu gỗ tròn hoặc chóp nhọn
    draw.polygon([(cx - 12, cy - 202), (cx + 12, cy - 202), (cx, cy - 224)], fill=CREAM_TRIM, outline=OUTLINE_COLOR, width=3)
    draw.ellipse([cx - 8, cy - 232, cx + 8, cy - 216], fill=STRAW_YELLOW, outline=OUTLINE_COLOR, width=3)

    # 4. Tầng áp mái (Attic): Cửa sổ tròn có rơm vàng (#F5C242) thò ra ngoài
    attic_cy = cy - 70
    attic_r = 38
    # Vành ngoài gỗ kem
    draw.ellipse([cx - attic_r - 8, attic_cy - attic_r - 8, cx + attic_r + 8, attic_cy + attic_r + 8], fill=OUTLINE_COLOR)
    draw.ellipse([cx - attic_r - 4, attic_cy - attic_r - 4, cx + attic_r + 4, attic_cy + attic_r + 4], fill=CREAM_TRIM)
    draw.ellipse([cx - attic_r, attic_cy - attic_r, cx + attic_r, attic_cy + attic_r], fill=(55, 30, 20, 255))

    # Đống rơm vàng thò nhô ra ngoài
    # Cọng rơm tua tủa
    straw_pts = [
        (cx - 24, attic_cy + 5), (cx - 32, attic_cy + 25), (cx - 18, attic_cy + 32),
        (cx - 6, attic_cy + 36), (cx + 8, attic_cy + 35), (cx + 22, attic_cy + 30),
        (cx + 30, attic_cy + 22), (cx + 24, attic_cy + 5)
    ]
    draw.polygon(straw_pts, fill=STRAW_YELLOW, outline=OUTLINE_COLOR, width=3)
    # Các sợi rơm điểm xuyết chi tiết
    for sx, sy, ex, ey in [
        (cx - 16, attic_cy + 10, cx - 28, attic_cy + 28),
        (cx - 4, attic_cy + 12, cx - 8, attic_cy + 36),
        (cx + 6, attic_cy + 10, cx + 12, attic_cy + 35),
        (cx + 14, attic_cy + 8, cx + 26, attic_cy + 26),
    ]:
        draw.line([(sx, sy), (ex, ey)], fill=(255, 230, 110, 255), width=3)
        draw.line([(sx + 1, sy), (ex + 1, ey)], fill=STRAW_DARK, width=1)

    # Thanh đỡ cửa sổ tầng gác
    draw.line([(cx - attic_r, attic_cy), (cx + attic_r, attic_cy)], fill=OUTLINE_COLOR, width=3)
    draw.line([(cx, attic_cy - attic_r), (cx, attic_cy + 8)], fill=OUTLINE_COLOR, width=3)

    # 5. Cửa gỗ đôi chữ X màu nâu kem (Double Barn Door)
    d_w = 58
    d_h = 96
    d_top = cy + 62
    d_bot = cy + 158
    
    # Cửa trái
    dl_x0 = cx - d_w - 2
    dl_x1 = cx - 2
    # Cửa phải
    dr_x0 = cx + 2
    dr_x1 = cx + d_w + 2

    for (x0, x1) in [(dl_x0, dl_x1), (dr_x0, dr_x1)]:
        # Viền khung cửa
        draw.rectangle([x0 - 4, d_top - 4, x1 + 4, d_bot + 4], fill=OUTLINE_COLOR)
        # Nền cánh cửa màu kem nâu
        draw.rectangle([x0, d_top, x1, d_bot], fill=(238, 224, 198, 255))
        # Khung viền trong
        draw.rectangle([x0 + 4, d_top + 4, x1 - 4, d_bot - 4], fill=(218, 198, 168, 255), outline=OUTLINE_COLOR, width=3)
        
        # Chữ X bắt chéo
        mid_y = (d_top + d_bot) // 2
        # Ô trên
        draw.line([(x0 + 6, d_top + 6), (x1 - 6, mid_y - 2)], fill=OUTLINE_COLOR, width=6)
        draw.line([(x1 - 6, d_top + 6), (x0 + 6, mid_y - 2)], fill=OUTLINE_COLOR, width=6)
        draw.line([(x0 + 6, d_top + 6), (x1 - 6, mid_y - 2)], fill=CREAM_TRIM, width=3)
        draw.line([(x1 - 6, d_top + 6), (x0 + 6, mid_y - 2)], fill=CREAM_TRIM, width=3)
        # Ô dưới
        draw.line([(x0 + 6, mid_y + 2), (x1 - 6, d_bot - 6)], fill=OUTLINE_COLOR, width=6)
        draw.line([(x1 - 6, mid_y + 2), (x0 + 6, d_bot - 6)], fill=OUTLINE_COLOR, width=6)
        draw.line([(x0 + 6, mid_y + 2), (x1 - 6, d_bot - 6)], fill=CREAM_TRIM, width=3)
        draw.line([(x1 - 6, mid_y + 2), (x0 + 6, d_bot - 6)], fill=CREAM_TRIM, width=3)

        # Bản lề sắt xám đen
        for hy in [d_top + 14, d_bot - 16]:
            hx = x0 if x0 == dl_x0 else x1 - 14
            draw.rectangle([hx, hy, hx + 14, hy + 8], fill=(60, 60, 60, 255), outline=OUTLINE_COLOR, width=2)
            draw.ellipse([hx + 4, hy + 2, hx + 8, hy + 6], fill=(120, 120, 120, 255))

    # Tay nắm cửa đôi
    draw.ellipse([cx - 10, cy + 106, cx - 4, cy + 116], fill=(45, 45, 45, 255), outline=OUTLINE_COLOR, width=2)
    draw.ellipse([cx + 4, cy + 106, cx + 10, cy + 116], fill=(45, 45, 45, 255), outline=OUTLINE_COLOR, width=2)

    # 6. Chi tiết phụ kiện chân nhà:
    # A. Bên trái: 2 kiện rơm vàng buộc dây thừng
    def draw_straw_bale(bx, by, bw=48, bh=32):
        # Khối rơm 2.5D
        draw.rectangle([bx - 3, by - 3, bx + bw + 3, by + bh + 3], fill=OUTLINE_COLOR)
        draw.rectangle([bx, by, bx + bw, by + bh], fill=STRAW_YELLOW)
        # Texture sợi rơm
        for line_y in range(by + 4, by + bh, 6):
            draw.line([(bx + 2, line_y), (bx + bw - 2, line_y)], fill=(255, 220, 95, 200), width=2)
            draw.line([(bx + 2, line_y + 2), (bx + bw - 2, line_y + 2)], fill=STRAW_DARK, width=1)
        # 2 dây thừng nâu buộc
        for rx in [bx + bw // 3, bx + 2 * bw // 3]:
            draw.line([(rx, by - 1), (rx, by + bh + 1)], fill=(110, 65, 30, 255), width=3)
            draw.line([(rx, by), (rx, by + bh)], fill=(160, 105, 55, 255), width=1)

    # Kiện 1 dưới
    draw_straw_bale(b_left - 30, b_bottom - 28, bw=52, bh=34)
    # Kiện 2 chồng lên lệch một chút
    draw_straw_bale(b_left - 20, b_bottom - 56, bw=46, bh=30)

    # B. Bên phải: 1 thùng gỗ nhỏ (wooden crate) & Bụi cỏ hoa cúc Chibi (daisies)
    crate_x = b_right - 18
    crate_y = b_bottom - 32
    cw, ch = 38, 36
    # Thùng gỗ
    draw.rectangle([crate_x - 3, crate_y - 3, crate_x + cw + 3, crate_y + ch + 3], fill=OUTLINE_COLOR)
    draw.rectangle([crate_x, crate_y, crate_x + cw, crate_y + ch], fill=(185, 130, 75, 255))
    # Nan gỗ
    draw.line([(crate_x, crate_y + ch // 2), (crate_x + cw, crate_y + ch // 2)], fill=OUTLINE_COLOR, width=3)
    # Chữ X nẹp thùng
    draw.line([(crate_x + 3, crate_y + 3), (crate_x + cw - 3, crate_y + ch - 3)], fill=(145, 95, 48, 255), width=3)
    draw.line([(crate_x + cw - 3, crate_y + 3), (crate_x + 3, crate_y + ch - 3)], fill=(145, 95, 48, 255), width=3)

    # Bụi cỏ hoa cúc Chibi cạnh thùng gỗ
    bush_x = b_right + 16
    bush_y = b_bottom + 6
    # Tán cỏ xanh tròn
    draw.ellipse([bush_x - 18, bush_y - 14, bush_x + 22, bush_y + 14], fill=(95, 175, 80, 255), outline=OUTLINE_COLOR, width=3)
    draw.ellipse([bush_x - 12, bush_y - 12, bush_x + 16, bush_y + 6], fill=(135, 215, 105, 255))
    
    # 3 bông hoa cúc trắng nhụy vàng
    for fx, fy in [(bush_x - 8, bush_y - 4), (bush_x + 8, bush_y - 6), (bush_x + 2, bush_y + 4)]:
        draw.ellipse([fx - 6, fy - 6, fx + 6, fy + 6], fill=(255, 255, 255, 255), outline=OUTLINE_COLOR, width=2)
        draw.ellipse([fx - 3, fy - 3, fx + 3, fy + 3], fill=(250, 195, 45, 255))

    return img

def render_chibi_barn():
    """Tạo file building_barn.png và chibi_barn_red.png chuẩn 2.5D Chibi."""
    os.makedirs(SPRITES_DIR, exist_ok=True)
    print("[BarnForge] Generating high-resolution 512x512 Barn...")
    big_barn = draw_supersampled_barn(512)

    # Downscale bằng LANCZOS về kích thước chuẩn 256x256 (hoặc 160x160 với canvas 256)
    # Barn trong game hiển thị 96x96 trong tile, canvas 256x256 giúp chi tiết siêu nét và mượt mà
    final_barn_256 = big_barn.resize((256, 256), Image.Resampling.LANCZOS)

    barn_path1 = os.path.join(SPRITES_DIR, "building_barn.png")
    barn_path2 = os.path.join(SPRITES_DIR, "chibi_barn_red.png")

    final_barn_256.save(barn_path1, "PNG")
    final_barn_256.save(barn_path2, "PNG")
    print(f"[BarnForge] Saved authentic 2.5D Chibi Barn to: {barn_path1} and {barn_path2}")

# ==============================================================================
# BỘ NÂNG CẤP ICON NÔNG SẢN TRONG KHO SILO CHUẨN 2.5D CHIBI (Supersampling 256 -> 64)
# apple, pumpkin, strawberry, tomato, sugarcane, wheat, soybean, carrot, corn
# ==============================================================================

def create_crop_icon(crop_name: str, size: int = 256) -> Image.Image:
    """Tạo icon nông sản 2.5D Chibi khối cầu với viền nâu ấm #482816."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2

    # Bóng đổ mềm phía dưới
    s_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(s_img)
    s_draw.ellipse([cx - 75, cy + 65, cx + 75, cy + 105], fill=SHADOW_COLOR)
    s_img = s_img.filter(ImageFilter.GaussianBlur(radius=8))
    img = Image.alpha_composite(img, s_img)
    draw = ImageDraw.Draw(img)

    if crop_name == "apple":
        # Quả táo đỏ mọng Chibi
        r = 82
        draw.ellipse([cx - r - 6, cy - r + 8, cx + r + 6, cy + r + 14], fill=OUTLINE_COLOR)
        draw.ellipse([cx - r, cy - r + 12, cx + r, cy + r + 10], fill=(225, 45, 45, 255))
        # Gradient bóng khối
        draw.ellipse([cx - r + 10, cy - r + 24, cx + r - 10, cy + r - 2], fill=(245, 75, 60, 255))
        # Highlight ánh sáng trắng mềm
        draw.ellipse([cx - 50, cy - 45, cx - 15, cy - 15], fill=(255, 205, 200, 240))
        draw.ellipse([cx - 42, cy - 38, cx - 22, cy - 22], fill=(255, 255, 255, 250))
        # Cuống nâu cong
        draw.arc([cx - 25, cy - 110, cx + 25, cy - 50], start=190, end=350, fill=OUTLINE_COLOR, width=12)
        draw.arc([cx - 23, cy - 108, cx + 23, cy - 52], start=190, end=350, fill=(130, 80, 45, 255), width=7)
        # Lá xanh tươi
        draw.polygon([(cx + 4, cy - 80), (cx + 52, cy - 105), (cx + 68, cy - 82), (cx + 20, cy - 68)], fill=OUTLINE_COLOR)
        draw.polygon([(cx + 8, cy - 80), (cx + 48, cy - 102), (cx + 62, cy - 84), (cx + 22, cy - 70)], fill=(110, 205, 70, 255))
        draw.line([(cx + 12, cy - 78), (cx + 54, cy - 94)], fill=(165, 235, 115, 255), width=3)

    elif crop_name == "pumpkin":
        # Bí ngô cam căng tròn 3 múi
        # Múi sau
        draw.ellipse([cx - 96, cy - 65, cx - 10, cy + 75], fill=OUTLINE_COLOR)
        draw.ellipse([cx - 90, cy - 60, cx - 16, cy + 70], fill=(220, 110, 25, 255))
        draw.ellipse([cx + 10, cy - 65, cx + 96, cy + 75], fill=OUTLINE_COLOR)
        draw.ellipse([cx + 16, cy - 60, cx + 90, cy + 70], fill=(220, 110, 25, 255))
        # Múi giữa lớn
        draw.ellipse([cx - 62, cy - 75, cx + 62, cy + 82], fill=OUTLINE_COLOR)
        draw.ellipse([cx - 56, cy - 70, cx + 56, cy + 76], fill=(250, 145, 35, 255))
        # Highlight múi giữa
        draw.ellipse([cx - 36, cy - 55, cx + 15, cy + 20], fill=(255, 185, 75, 220))
        draw.ellipse([cx - 26, cy - 45, cx - 6, cy - 15], fill=(255, 220, 140, 250))
        # Cuống bí xanh cong
        draw.polygon([(cx - 16, cy - 70), (cx - 24, cy - 110), (cx + 8, cy - 112), (cx + 16, cy - 70)], fill=OUTLINE_COLOR)
        draw.polygon([(cx - 12, cy - 72), (cx - 20, cy - 106), (cx + 4, cy - 108), (cx + 12, cy - 72)], fill=(75, 145, 60, 255))

    elif crop_name == "strawberry":
        # Dâu tây trái tim căng mọng
        draw.polygon([(cx, cy + 90), (cx - 84, cy - 25), (cx - 55, cy - 72), (cx, cy - 45), (cx + 55, cy - 72), (cx + 84, cy - 25)], fill=OUTLINE_COLOR)
        pts = [(cx, cy + 82), (cx - 76, cy - 22), (cx - 48, cy - 64), (cx, cy - 38), (cx + 48, cy - 64), (cx + 76, cy - 22)]
        draw.polygon(pts, fill=(235, 45, 65, 255))
        # Highlight
        draw.ellipse([cx - 45, cy - 35, cx - 12, cy + 5], fill=(255, 140, 155, 220))
        # Hạt dâu vàng
        seeds = [
            (cx - 35, cy - 10), (cx - 15, cy - 18), (cx + 12, cy - 15), (cx + 38, cy - 5),
            (cx - 25, cy + 18), (cx, cy + 12), (cx + 25, cy + 16),
            (cx - 12, cy + 42), (cx + 12, cy + 40), (cx, cy + 62)
        ]
        for sx, sy in seeds:
            draw.ellipse([sx - 3, sy - 4, sx + 3, sy + 4], fill=OUTLINE_COLOR)
            draw.ellipse([sx - 2, sy - 3, sx + 2, sy + 3], fill=(255, 240, 110, 255))
        # Tai lá xanh
        draw.polygon([(cx - 70, cy - 65), (cx, cy - 40), (cx - 25, cy - 85)], fill=(85, 185, 65, 255), outline=OUTLINE_COLOR, width=4)
        draw.polygon([(cx + 70, cy - 65), (cx, cy - 40), (cx + 25, cy - 85)], fill=(85, 185, 65, 255), outline=OUTLINE_COLOR, width=4)
        draw.polygon([(cx, cy - 40), (cx - 12, cy - 95), (cx + 12, cy - 95)], fill=(110, 210, 85, 255), outline=OUTLINE_COLOR, width=4)

    elif crop_name == "tomato":
        # Cà chua đỏ bóng
        r = 78
        draw.ellipse([cx - r - 6, cy - r + 4, cx + r + 6, cy + r + 14], fill=OUTLINE_COLOR)
        draw.ellipse([cx - r, cy - r + 8, cx + r, cy + r + 10], fill=(235, 48, 38, 255))
        draw.ellipse([cx - r + 12, cy - r + 20, cx + r - 12, cy + r], fill=(250, 75, 55, 255))
        # Highlight tròn bóng loáng
        draw.ellipse([cx - 48, cy - 42, cx - 16, cy - 14], fill=(255, 210, 205, 230))
        draw.ellipse([cx - 40, cy - 35, cx - 22, cy - 20], fill=(255, 255, 255, 255))
        # Cuống sao xanh 5 cánh
        star_pts = [
            (cx, cy - 68), (cx - 24, cy - 90), (cx - 10, cy - 64),
            (cx - 52, cy - 68), (cx - 14, cy - 54), (cx - 32, cy - 42),
            (cx, cy - 50), (cx + 32, cy - 42), (cx + 14, cy - 54),
            (cx + 52, cy - 68), (cx + 10, cy - 64), (cx + 24, cy - 90)
        ]
        draw.polygon(star_pts, fill=(90, 195, 65, 255), outline=OUTLINE_COLOR, width=3)

    elif crop_name == "sugarcane":
        # Mía đường 3 gióng màu xanh vàng óng
        for offset_x in [-28, 0, 28]:
            bx = cx + offset_x
            draw.rectangle([bx - 14, cy - 95, bx + 14, cy + 85], fill=OUTLINE_COLOR)
            draw.rectangle([bx - 10, cy - 90, bx + 10, cy + 80], fill=(160, 215, 75, 255))
            # Khớp đốt mía
            for ny in [cy - 40, cy + 10, cy + 55]:
                draw.line([(bx - 10, ny), (bx + 10, ny)], fill=OUTLINE_COLOR, width=4)
                draw.line([(bx - 10, ny + 2), (bx + 10, ny + 2)], fill=(245, 240, 160, 255), width=2)
            # Highlight dọc
            draw.line([(bx - 4, cy - 85), (bx - 4, cy + 75)], fill=(205, 245, 120, 200), width=4)

    elif crop_name == "wheat":
        # Bó lúa mì vàng óng
        draw.line([(cx, cy + 90), (cx - 25, cy - 40)], fill=OUTLINE_COLOR, width=8)
        draw.line([(cx, cy + 90), (cx + 25, cy - 40)], fill=OUTLINE_COLOR, width=8)
        draw.line([(cx, cy + 90), (cx, cy - 70)], fill=OUTLINE_COLOR, width=9)
        # Các hạt lúa vàng
        grain_y_list = [cy - 65, cy - 45, cy - 25, cy - 5, cy + 15]
        for gy in grain_y_list:
            for gx, angle in [(cx - 24, -25), (cx + 24, 25), (cx, 0)]:
                draw.ellipse([gx - 14, gy - 10, gx + 14, gy + 10], fill=OUTLINE_COLOR)
                draw.ellipse([gx - 11, gy - 8, gx + 11, gy + 8], fill=STRAW_YELLOW)
                draw.ellipse([gx - 7, gy - 5, gx + 3, gy + 3], fill=(255, 235, 130, 255))
        # Dây nơ đỏ buộc bó lúa
        draw.rectangle([cx - 20, cy + 40, cx + 20, cy + 54], fill=(225, 45, 45, 255), outline=OUTLINE_COLOR, width=3)
        draw.polygon([(cx - 24, cy + 50), (cx - 38, cy + 72), (cx - 16, cy + 62)], fill=(225, 45, 45, 255), outline=OUTLINE_COLOR, width=2)
        draw.polygon([(cx + 24, cy + 50), (cx + 38, cy + 72), (cx + 16, cy + 62)], fill=(225, 45, 45, 255), outline=OUTLINE_COLOR, width=2)

    elif crop_name == "soybean":
        # Đậu nành vỏ quả mở lộ 3 hạt tròn
        # Quả đậu cong xanh mướt
        draw.ellipse([cx - 95, cy - 45, cx + 95, cy + 55], fill=OUTLINE_COLOR)
        draw.ellipse([cx - 88, cy - 38, cx + 88, cy + 48], fill=(130, 205, 80, 255))
        # 3 hạt đậu xanh nõn tròn
        for hx in [cx - 48, cx, cx + 48]:
            draw.ellipse([hx - 24, cy - 18, hx + 24, cy + 28], fill=OUTLINE_COLOR)
            draw.ellipse([hx - 20, cy - 14, hx + 20, cy + 24], fill=(175, 235, 105, 255))
            draw.ellipse([hx - 12, cy - 8, hx, cy + 4], fill=(225, 255, 170, 240))

    elif crop_name == "carrot":
        # Cà rốt cam hình nón
        c_poly_out = [(cx - 36, cy - 65), (cx + 36, cy - 65), (cx + 6, cy + 88), (cx - 6, cy + 88)]
        draw.polygon(c_poly_out, fill=OUTLINE_COLOR)
        c_poly = [(cx - 30, cy - 60), (cx + 30, cy - 60), (cx + 4, cy + 82), (cx - 4, cy + 82)]
        draw.polygon(c_poly, fill=(245, 125, 30, 255))
        # Highlight dọc
        draw.line([(cx - 12, cy - 50), (cx - 2, cy + 70)], fill=(255, 180, 85, 220), width=8)
        # Các khấc ngang
        for ky in [cy - 30, cy, cy + 30, cy + 55]:
            draw.line([(cx - 18, ky), (cx + 14, ky)], fill=(210, 95, 20, 255), width=3)
        # Chùm lá xanh xòe trên
        draw.polygon([(cx - 6, cy - 62), (cx - 38, cy - 110), (cx - 16, cy - 75)], fill=(95, 195, 70, 255), outline=OUTLINE_COLOR, width=3)
        draw.polygon([(cx, cy - 62), (cx, cy - 118), (cx + 8, cy - 75)], fill=(115, 215, 85, 255), outline=OUTLINE_COLOR, width=3)
        draw.polygon([(cx + 6, cy - 62), (cx + 38, cy - 110), (cx + 16, cy - 75)], fill=(95, 195, 70, 255), outline=OUTLINE_COLOR, width=3)

    elif crop_name == "corn":
        # Bắp ngô vàng với lá bao xanh
        draw.ellipse([cx - 40, cy - 85, cx + 40, cy + 75], fill=OUTLINE_COLOR)
        draw.ellipse([cx - 34, cy - 80, cx + 34, cy + 70], fill=STRAW_YELLOW)
        # Các hàng hạt ngô
        for ry in range(cy - 65, cy + 55, 18):
            for rx in range(cx - 22, cx + 25, 14):
                draw.ellipse([rx - 6, ry - 7, rx + 6, ry + 7], fill=OUTLINE_COLOR)
                draw.ellipse([rx - 4, ry - 5, rx + 4, ry + 5], fill=(255, 225, 80, 255))
                draw.ellipse([rx - 2, ry - 3, rx + 1, ry], fill=(255, 255, 180, 240))
        # Lá bẹ ngô xanh ôm hai bên
        draw.polygon([(cx - 36, cy + 65), (cx - 52, cy - 15), (cx - 18, cy + 75)], fill=(105, 195, 75, 255), outline=OUTLINE_COLOR, width=3)
        draw.polygon([(cx + 36, cy + 65), (cx + 52, cy - 15), (cx + 18, cy + 75)], fill=(105, 195, 75, 255), outline=OUTLINE_COLOR, width=3)

    return img

def render_crop_icons():
    """Tạo lại toàn bộ icon nông sản Silo chuẩn 2.5D Chibi."""
    crops = ["apple", "pumpkin", "strawberry", "tomato", "sugarcane", "wheat", "soybean", "carrot", "corn"]
    for c in crops:
        big_icon = create_crop_icon(c, size=256)
        # Lưu file 128x128 hoặc 96x96
        icon_out = big_icon.resize((128, 128), Image.Resampling.LANCZOS)
        
        path_plain = os.path.join(SPRITES_DIR, f"{c}.png")
        path_item = os.path.join(SPRITES_DIR, f"item_{c}.png")
        
        icon_out.save(path_plain, "PNG")
        icon_out.save(path_item, "PNG")
        print(f"[CropForge] Rendered 2.5D Chibi icon for '{c}' -> {path_plain} & {path_item}")

def main():
    print("==================================================")
    print("  REBUILD CHIBI BARN & CROP ICONS (2.5D COZY FARM)")
    print("==================================================")
    render_chibi_barn()
    render_crop_icons()
    print("[Rebuild] All Barn & Silo assets successfully generated!")

if __name__ == "__main__":
    main()
