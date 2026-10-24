#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
tools/slice_new_items_chibi.py
Cắt 9 icon món ăn Chibi từ assets/raw_refs/new_items_chibi.png (lưới 3x3)
Khử nền trắng bằng Corner Flood-Fill bảo vệ chi tiết trắng bên trong (đĩa bơ, đá lạnh, mắt bò/gà)
"""

import os
import sys
from collections import deque
import numpy as np
from PIL import Image

if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

PROJECT_DIR = r"D:\HayDayOffline"
SRC_PATH = os.path.join(PROJECT_DIR, "assets", "raw_refs", "new_items_chibi.png")
OUT_DIR = os.path.join(PROJECT_DIR, "assets", "sprites")

# Danh sách 9 món theo lưới (row, col)
ITEMS_GRID = {
    (0, 0): ["item_chicken_feed.png", "chicken_feed.png"],
    (0, 1): ["item_cow_feed.png", "cow_feed.png"],
    (0, 2): ["item_pig_feed.png", "pig_feed.png"],
    (1, 0): ["item_butter.png", "butter.png"],
    (1, 1): ["item_corn_bread.png", "corn_bread.png"],
    (1, 2): ["item_cookie.png", "cookie.png", "item_butter_cookie.png", "butter_cookie.png"],
    (2, 0): ["item_sugarcane_juice.png", "sugarcane_juice.png"],
    (2, 1): ["item_apple_juice.png", "apple_juice.png"],
    (2, 2): ["item_mango_smoothie.png", "mango_smoothie.png"],
}

def remove_bg_corner_floodfill(crop_img: Image.Image, tolerance: int = 240) -> Image.Image:
    """Corner floodfill loại bỏ nền trắng từ viền ngoài."""
    rgba = crop_img.convert("RGBA")
    arr = np.array(rgba)
    h, w = arr.shape[:2]
    
    rgb = arr[:, :, :3].astype(int)
    # Điều kiện là màu trắng hoặc gần trắng viền ngoài
    is_white = (rgb[:, :, 0] >= tolerance) & (rgb[:, :, 1] >= tolerance) & (rgb[:, :, 2] >= tolerance)
    
    seen = np.zeros((h, w), dtype=bool)
    q = deque()
    
    # Đẩy 4 cạnh vào queue
    for x in range(w):
        if is_white[0, x]:
            q.append((x, 0))
            seen[0, x] = True
        if is_white[h - 1, x]:
            q.append((x, h - 1))
            seen[h - 1, x] = True
    for y in range(h):
        if is_white[y, 0]:
            q.append((0, y))
            seen[y, 0] = True
        if is_white[y, w - 1]:
            q.append((w - 1, y))
            seen[y, w - 1] = True
            
    while q:
        x, y = q.popleft()
        arr[y, x, 3] = 0 # Transparent
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not seen[ny, nx]:
                seen[ny, nx] = True
                if is_white[ny, nx]:
                    q.append((nx, ny))
                    
    return Image.fromarray(arr)

def auto_crop_and_fit(img: Image.Image, target_size: int = 128, padding: int = 4) -> Image.Image:
    """Crop sát bounding box rồi pad thành hình vuông target_size x target_size."""
    bbox = img.getbbox()
    if bbox:
        x0 = max(0, bbox[0] - padding)
        y0 = max(0, bbox[1] - padding)
        x1 = min(img.width, bbox[2] + padding)
        y1 = min(img.height, bbox[3] + padding)
        img = img.crop((x0, y0, x1, y1))
        
    # Scale tỉ lệ giữ nguyên vào target_size x target_size
    ratio = min((target_size - 8) / float(img.width), (target_size - 8) / float(img.height))
    nw = max(1, int(img.width * ratio))
    nh = max(1, int(img.height * ratio))
    resized = img.resize((nw, nh), Image.Resampling.LANCZOS)
    
    # Đặt vào giữa canvas vuông
    canvas = Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))
    px = (target_size - nw) // 2
    py = (target_size - nh) // 2
    canvas.paste(resized, (px, py), resized)
    return canvas

def main():
    if not os.path.exists(SRC_PATH):
        print(f"[Error] Source file not found: {SRC_PATH}")
        return

    os.makedirs(OUT_DIR, exist_ok=True)
    src_img = Image.open(SRC_PATH)
    sw, sh = src_img.size
    # Ranh giới chính xác đo được từ khoảng trắng tự nhiên
    row_splits = [0, 440, 793, sh]
    col_splits = [0, 430, 820, sw]

    print(f"Loaded {SRC_PATH} ({sw}x{sh}). Using precise gap boundaries.")

    count = 0
    for (r, c), filenames in ITEMS_GRID.items():
        box = (col_splits[c], row_splits[r], col_splits[c+1], row_splits[r+1])
        cell = src_img.crop(box)
        cell_trans = remove_bg_corner_floodfill(cell, tolerance=242)
        final_icon = auto_crop_and_fit(cell_trans, target_size=128, padding=4)
        
        for fname in filenames:
            out_p = os.path.join(OUT_DIR, fname)
            final_icon.save(out_p, "PNG")
            print(f"Saved: {fname} (128x128)")
            count += 1

    print(f"Successfully sliced {count} item icons from {SRC_PATH}!")

if __name__ == "__main__":
    main()
