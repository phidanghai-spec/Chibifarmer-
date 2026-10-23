import os
import sys
import glob
from PIL import Image, ImageDraw, ImageFont
import numpy as np
import scipy.ndimage as ndi

sys.stdout.reconfigure(encoding='utf-8')

OUTPUT_DIR = r"D:\HayDayOffline\assets\sprites\extracted"
ASSETS_DIR = r"D:\HayDayOffline\assets"
os.makedirs(OUTPUT_DIR, exist_ok=True)

def fast_border_transparent(pil_img: Image.Image, tolerance: int = 35) -> Image.Image:
    """Tách nền từ các viền bằng SciPy C-accelerated connected components (cực nhanh < 5ms)."""
    rgba = pil_img.convert("RGBA")
    arr = np.array(rgba)
    h, w = arr.shape[:2]
    
    rgb = arr[:, :, :3].astype(int)
    
    # Mẫu màu 4 góc
    corner_samples = np.array([
        rgb[0, 0], rgb[0, -1], rgb[-1, 0], rgb[-1, -1],
        rgb[0, w // 2], rgb[-1, w // 2], rgb[h // 2, 0], rgb[h // 2, -1]
    ])
    bg_color = np.median(corner_samples, axis=0)

    # Pixel gần màu nền hoặc gần trắng
    diff = np.max(np.abs(rgb - bg_color), axis=2)
    is_candidate_bg = (diff <= tolerance) | (np.all(rgb >= 238, axis=2) & (np.std(rgb, axis=2) < 12))
    
    # Nền phải nối liền với 4 viền ngoài
    labeled_bg, num_bg = ndi.label(is_candidate_bg)
    border_labels = np.unique(np.concatenate([
        labeled_bg[0, :], labeled_bg[-1, :], labeled_bg[:, 0], labeled_bg[:, -1]
    ]))
    border_labels = border_labels[border_labels > 0]
    
    bg_mask = np.isin(labeled_bg, border_labels)
    arr[bg_mask, 3] = 0
    return Image.fromarray(arr)

def auto_crop_alpha(img: Image.Image, padding: int = 4) -> Image.Image:
    """Cắt sát bounding box của vật thể."""
    bbox = img.getbbox()
    if not bbox:
        return img
    w, h = img.size
    x0 = max(0, bbox[0] - padding)
    y0 = max(0, bbox[1] - padding)
    x1 = min(w, bbox[2] + padding)
    y1 = min(h, bbox[3] + padding)
    return img.crop((x0, y0, x1, y1))

def process_grid_sheet(img_path: str, sheet_name: str, cols: int, rows: int, extracted_list: list):
    """Cắt ảnh dạng lưới đều (4x3, 6x6)."""
    with Image.open(img_path) as im:
        im = im.convert("RGBA")
        sw, sh = im.size
        cw = sw // cols
        ch = sh // rows
        
        for r in range(rows):
            for c in range(cols):
                box = (c * cw, r * ch, (c + 1) * cw, (r + 1) * ch)
                cell = im.crop(box)
                cell_trans = fast_border_transparent(cell, tolerance=32)
                cropped = auto_crop_alpha(cell_trans, padding=4)
                
                if cropped.width >= 24 and cropped.height >= 24:
                    out_name = f"{sheet_name}_r{r+1}_c{c+1}.png"
                    out_path = os.path.join(OUTPUT_DIR, out_name)
                    cropped.save(out_path)
                    extracted_list.append((out_name, out_path, cropped))

def process_general_sheet(img_path: str, sheet_name: str, extracted_list: list):
    """Cắt ảnh tự do dùng connected components."""
    with Image.open(img_path) as im:
        im_trans = fast_border_transparent(im, tolerance=30)
        alpha = np.array(im_trans)[:, :, 3]
        
        binary = alpha > 20
        struct = np.ones((5, 5), dtype=bool)
        closed = ndi.binary_closing(binary, structure=struct)
        
        labels, num_features = ndi.label(closed)
        objects = ndi.find_objects(labels)
        
        for idx, loc in enumerate(objects, 1):
            sy, sx = loc
            h_obj = sy.stop - sy.start
            w_obj = sx.stop - sx.start
            
            if w_obj >= 32 and h_obj >= 32 and w_obj < im.width * 0.95 and h_obj < im.height * 0.95:
                sub_img = im_trans.crop((sx.start, sy.start, sx.stop, sy.stop))
                cropped = auto_crop_alpha(sub_img, padding=4)
                if cropped.width >= 28 and cropped.height >= 28:
                    out_name = f"{sheet_name}_cc_{idx}.png"
                    out_path = os.path.join(OUTPUT_DIR, out_name)
                    cropped.save(out_path)
                    extracted_list.append((out_name, out_path, cropped))

def create_catalog_preview(extracted_list: list):
    """Xếp toàn bộ ảnh đã cắt thành CATALOG_PREVIEW.png có chú thích."""
    if not extracted_list:
        print("[Catalog] Không có ảnh nào để tạo danh mục!")
        return

    CARD_W = 140
    CARD_H = 150
    COLS = 8
    total = len(extracted_list)
    rows = (total + COLS - 1) // COLS

    canvas_w = COLS * CARD_W + 40
    canvas_h = rows * CARD_H + 60
    catalog = Image.new("RGBA", (canvas_w, canvas_h), (250, 248, 242, 255))
    draw = ImageDraw.Draw(catalog)

    draw.text((canvas_w // 2 - 200, 15), f"CHIBI ASSET CATALOG PREVIEW ({total} items)", fill=(60, 40, 25, 255))

    for idx, (name, path, img) in enumerate(extracted_list):
        c = idx % COLS
        r = idx // COLS
        x = 20 + c * CARD_W
        y = 50 + r * CARD_H

        draw.rounded_rectangle([x + 4, y + 4, x + CARD_W - 4, y + CARD_H - 4], radius=8, fill=(255, 255, 255, 230), outline=(210, 195, 175, 255), width=1)

        thumb = img.copy()
        thumb.thumbnail((86, 86), Image.Resampling.LANCZOS)
        tx = x + (CARD_W - thumb.width) // 2
        ty = y + 10 + (86 - thumb.height) // 2
        catalog.paste(thumb, (tx, ty), thumb)

        label_num = f"#{idx+1}"
        short_name = name.replace(".png", "")
        if len(short_name) > 16:
            short_name = short_name[:15] + ".."
        draw.text((x + 8, y + 102), label_num, fill=(200, 80, 40, 255))
        draw.text((x + 8, y + 120), short_name, fill=(70, 50, 40, 255))

    out_cat = os.path.join(OUTPUT_DIR, "CATALOG_PREVIEW.png")
    catalog.save(out_cat)
    print(f"[Catalog] Saved {total} items to CATALOG_PREVIEW.png (Size: {canvas_w}x{canvas_h})")

def main():
    extracted = []
    
    # 1. Các sheet lưới chuẩn
    grid_sheets = [
        ("script thực phẩm.png", "food_sheet", 4, 3),
        ("chibi_sheet_1.png", "chibi1_sheet", 4, 3),
        ("chibi_sheet_2_characters.png", "char_sheet", 4, 3),
        ("chibi_sheet_3_buildings.png", "bldg_sheet", 4, 3),
        ("script nhà cửa.png", "house_sheet", 4, 3),
        ("script món ăn.jpg", "dishes_sheet", 6, 6),
        ("sprites_animals_visitors.jpg", "anim_vis_sheet", 4, 3),
        ("sprites_buildings_crops.jpg", "bldg_crop_sheet", 4, 3),
    ]

    for fname, sheet_name, cols, rows in grid_sheets:
        full_p = os.path.join(r"D:\HayDayOffline\assets\sprites", fname)
        if os.path.exists(full_p):
            print(f"[Extractor] Đang cắt lưới {cols}x{rows}: {fname}...")
            process_grid_sheet(full_p, sheet_name, cols, rows, extracted)

    # 2. Quét thêm thư mục pinterest/ nếu có ảnh
    pinterest_dir = os.path.join(ASSETS_DIR, "pinterest")
    if os.path.exists(pinterest_dir):
        for pf in glob.glob(os.path.join(pinterest_dir, "*.*")):
            if pf.lower().endswith(('.png', '.jpg', '.jpeg', '.webp')):
                base = os.path.splitext(os.path.basename(pf))[0]
                print(f"[Extractor] Đang trích xuất từ Pinterest: {base}...")
                process_general_sheet(pf, f"pin_{base}", extracted)

    # 3. Tạo bảng CATALOG_PREVIEW.png
    create_catalog_preview(extracted)
    print(f"[Extractor] Hoàn tất trích xuất tổng cộng {len(extracted)} assets!")

if __name__ == "__main__":
    main()
