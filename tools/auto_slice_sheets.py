"""
auto_slice_sheets.py
Tự động quét toàn bộ assets/ và cắt rời các nhân vật / vật phẩm từ các tấm ảnh tổng hợp
bằng PIL và scipy.ndimage (Connected Components / Bounding Boxes).
"""

import os
import sys
import glob
import numpy as np
from PIL import Image
import scipy.ndimage as ndi

if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

BASE_DIR = os.path.dirname(os.path.dirname(__file__))
ASSETS_DIR = os.path.join(BASE_DIR, "assets")
SPRITES_DIR = os.path.join(ASSETS_DIR, "sprites")

def list_asset_files():
    patterns = ["*.png", "*.jpg", "*.jpeg", "*.webp"]
    all_files = []
    for root, _, files in os.walk(ASSETS_DIR):
        for f in files:
            ext = os.path.splitext(f)[1].lower()
            if ext in [".png", ".jpg", ".jpeg", ".webp"] and not f.endswith(".import"):
                all_files.append(os.path.join(root, f))
    return sorted(all_files)

def slice_connected_components(image_path, prefix="slice", min_size=24, max_slices=20):
    try:
        im = Image.open(image_path).convert("RGBA")
    except Exception as e:
        print(f"Error opening {image_path}: {e}")
        return []

    w, h = im.size
    arr = np.array(im)
    r, g, b, a = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2], arr[:, :, 3]

    # Non-background mask (white bg or transparent bg)
    is_white = (r > 240) & (g > 240) & (b > 240)
    is_transparent = a < 25
    foreground = (~is_white) & (~is_transparent)

    # Clean noise with morphological opening
    foreground = ndi.binary_opening(foreground, structure=np.ones((3, 3)))

    labeled, num_features = ndi.label(foreground)
    if num_features == 0:
        return []

    slices = ndi.find_objects(labeled)
    saved_paths = []
    count = 1

    for s in slices:
        sy, sx = s
        ymin, ymax = sy.start, sy.stop
        xmin, xmax = sx.start, sx.stop
        box_w = xmax - xmin
        box_h = ymax - ymin

        # Filter out tiny noise or huge background plates
        if box_w < min_size or box_h < min_size:
            continue
        if box_w > (w * 0.9) and box_h > (h * 0.9):
            continue

        # Extract region with margin
        pad = 4
        x0 = max(0, xmin - pad)
        y0 = max(0, ymin - pad)
        x1 = min(w, xmax + pad)
        y1 = min(h, ymax + pad)

        cropped = im.crop((x0, y0, x1, y1))
        # Mask out anything that is not foreground or white
        cr_arr = np.array(cropped)
        c_r, c_g, c_b, c_a = cr_arr[:, :, 0], cr_arr[:, :, 1], cr_arr[:, :, 2], cr_arr[:, :, 3]
        c_white = (c_r > 238) & (c_g > 238) & (c_b > 238)
        cr_arr[c_white, 3] = 0
        cleaned_crop = Image.fromarray(cr_arr)

        out_name = f"{prefix}_{count:02d}.png"
        out_path = os.path.join(SPRITES_DIR, out_name)
        cleaned_crop.save(out_path, "PNG")
        saved_paths.append(out_path)
        count += 1
        if count > max_slices:
            break

    return saved_paths

def main():
    print("=== BƯỚC 1: QUÉT TẤT CẢ FILE HÌNH ẢNH TRONG ASSETS/ ===")
    asset_files = list_asset_files()
    print(f"Tổng số file hình ảnh tìm thấy: {len(asset_files)}")
    for f in asset_files[:15]:
        print(" -", os.path.relpath(f, BASE_DIR))
    if len(asset_files) > 15:
        print(f" ... và {len(asset_files) - 15} file khác.")

    print("\n=== TIẾN HÀNH CẮT CÁC SHEET NHÂN VẬT & MÓN ĂN TỔNG HỢP ===")
    # 1. Nhân vật từ raw_refs
    char_sheet_candidates = [
        os.path.join(ASSETS_DIR, "raw_refs", "script nhân vật.png"),
        os.path.join(ASSETS_DIR, "raw_refs", "script nhân vật+2.jpg"),
        os.path.join(SPRITES_DIR, "sheet_animals_visitors.png"),
        os.path.join(SPRITES_DIR, "chibi_sheet_1.png")
    ]
    
    for candidate in char_sheet_candidates:
        if os.path.exists(candidate):
            print(f"Đang phân tích và cắt: {os.path.basename(candidate)}...")
            res = slice_connected_components(candidate, prefix="npc_char", min_size=32, max_slices=8)
            print(f" -> Đã cắt được {len(res)} nhân vật!")
            if len(res) >= 4:
                break

    # 2. Món ăn / rau củ từ raw_refs nếu có
    food_sheet = os.path.join(ASSETS_DIR, "raw_refs", "script món ăn.jpg")
    if os.path.exists(food_sheet):
        print(f"Đang phân tích và cắt: {os.path.basename(food_sheet)}...")
        res_food = slice_connected_components(food_sheet, prefix="food_crop", min_size=24, max_slices=6)
        print(f" -> Đã cắt được {len(res_food)} món ăn/rau củ!")

    print("\n=== HOÀN TẤT BƯỚC 1 ===")

if __name__ == "__main__":
    main()
