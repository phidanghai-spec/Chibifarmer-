import os
import shutil
from PIL import Image
import numpy as np
import scipy.ndimage as ndi

EXTRACTED_DIR = r"D:\HayDayOffline\assets\sprites\extracted"
SPRITES_DIR = r"D:\HayDayOffline\assets\sprites"

def fast_border_transparent(pil_img: Image.Image, tolerance: int = 35) -> Image.Image:
    rgba = pil_img.convert("RGBA")
    arr = np.array(rgba)
    h, w = arr.shape[:2]
    rgb = arr[:, :, :3].astype(int)
    
    corner_samples = np.array([
        rgb[0, 0], rgb[0, -1], rgb[-1, 0], rgb[-1, -1],
        rgb[0, w // 2], rgb[-1, w // 2], rgb[h // 2, 0], rgb[h // 2, -1]
    ])
    bg_color = np.median(corner_samples, axis=0)

    diff = np.max(np.abs(rgb - bg_color), axis=2)
    is_candidate_bg = (diff <= tolerance) | (np.all(rgb >= 238, axis=2) & (np.std(rgb, axis=2) < 12))
    
    labeled_bg, _ = ndi.label(is_candidate_bg)
    border_labels = np.unique(np.concatenate([
        labeled_bg[0, :], labeled_bg[-1, :], labeled_bg[:, 0], labeled_bg[:, -1]
    ]))
    border_labels = border_labels[border_labels > 0]
    
    bg_mask = np.isin(labeled_bg, border_labels)
    arr[bg_mask, 3] = 0
    return Image.fromarray(arr)

def auto_crop_alpha(img: Image.Image, padding: int = 4) -> Image.Image:
    bbox = img.getbbox()
    if not bbox:
        return img
    w, h = img.size
    x0 = max(0, bbox[0] - padding)
    y0 = max(0, bbox[1] - padding)
    x1 = min(w, bbox[2] + padding)
    y1 = min(h, bbox[3] + padding)
    return img.crop((x0, y0, x1, y1))

def copy_extracted(src_name: str, target_names: list, target_size: tuple = None):
    src_p = os.path.join(EXTRACTED_DIR, src_name)
    if not os.path.exists(src_p):
        print(f"[Warning] Not found {src_name}")
        return
    
    with Image.open(src_p) as im:
        im = fast_border_transparent(im, tolerance=32)
        im = auto_crop_alpha(im, padding=3)
        if target_size:
            im = im.resize(target_size, Image.Resampling.LANCZOS)
        
        for tgt in target_names:
            out_p = os.path.join(SPRITES_DIR, tgt)
            im.save(out_p)
            print(f"Deployed {src_name} -> {tgt} ({im.size})")

def main():
    print("=== DEPLOYING AUTHENTIC EXTRACTED CHIBI ASSETS ===")
    
    # 1. Cây trồng & Nông sản & Thực phẩm
    # Carrot (Cà rốt): dishes_sheet_r5_c3.png
    copy_extracted("dishes_sheet_r5_c3.png", ["carrot.png", "item_carrot.png"])

    # Corn (Ngô): dishes_sheet_r6_c2.png
    copy_extracted("dishes_sheet_r6_c2.png", ["corn.png", "item_corn.png"])

    # Bread (Bánh mì): dishes_sheet_r4_c1.png
    copy_extracted("dishes_sheet_r4_c1.png", ["bread.png", "item_bread.png"])

    # Butter (Bơ): dishes_sheet_r4_c2.png
    copy_extracted("dishes_sheet_r4_c2.png", ["butter.png", "item_butter.png"])

    # Milk (Sữa): dishes_sheet_r5_c6.png
    copy_extracted("dishes_sheet_r5_c6.png", ["milk.png", "item_milk.png"])

    # Egg (Trứng gà): food_sheet_r1_c2.png
    copy_extracted("food_sheet_r1_c2.png", ["egg.png", "item_egg.png"])

    # Cookies (Bánh quy bơ): dishes_sheet_r1_c3.png
    copy_extracted("dishes_sheet_r1_c3.png", ["butter_cookie.png", "item_butter_cookie.png"])

    # Cream Cake (Bánh kem dâu): dishes_sheet_r3_c3.png
    copy_extracted("dishes_sheet_r3_c3.png", ["cream_cake.png", "item_cream_cake.png"])

    # Corn bread / Cupcake (Bánh ngô): dishes_sheet_r3_c5.png
    copy_extracted("dishes_sheet_r3_c5.png", ["corn_bread.png", "item_corn_bread.png"])

    # Wheat (Lúa mì): crop_wheat.png
    shutil.copyfile(os.path.join(SPRITES_DIR, "crop_wheat.png"), os.path.join(SPRITES_DIR, "wheat.png"))
    shutil.copyfile(os.path.join(SPRITES_DIR, "crop_wheat.png"), os.path.join(SPRITES_DIR, "item_wheat.png"))
    print("Deployed crop_wheat.png -> wheat.png & item_wheat.png")

    # 2. Động vật mới: Ngựa, Lừa, Dê, Chó
    # Horse (Ngựa): anim_vis_sheet_r2_c1.png
    copy_extracted("anim_vis_sheet_r2_c1.png", ["animal_horse.png", "critter_horse.png"])

    # Donkey (Lừa): anim_vis_sheet_r2_c4.png
    copy_extracted("anim_vis_sheet_r2_c4.png", ["animal_donkey.png", "critter_donkey.png"])

    # Goat (Dê): anim_vis_sheet_r2_c2.png
    copy_extracted("anim_vis_sheet_r2_c2.png", ["animal_goat.png"])

    # Dog (Chó): anim_vis_sheet_r2_c3.png
    copy_extracted("anim_vis_sheet_r2_c3.png", ["animal_dog.png"])

    # 3. Công trình Chibi chuẩn
    # Barn (Nhà Kho Chibi xịn): anim_vis_sheet_r3_c1.png (Nhà gỗ mái hiên đồng hồ)
    copy_extracted("anim_vis_sheet_r3_c1.png", ["building_barn.png", "chibi_barn_red.png"])

    # Juice Stand (Quầy nước): anim_vis_sheet_r3_c3.png (Sạp nước mái sọc thùng hoa quả)
    copy_extracted("anim_vis_sheet_r3_c3.png", ["building_juice_stand.png"])

    # Cake Oven (Lò bánh ngọt): anim_vis_sheet_r3_c4.png (Lò đá ống khói lửa)
    copy_extracted("anim_vis_sheet_r3_c4.png", ["building_cake_oven.png"])

    # Feed Mill: bldg_sheet_r1_c1.png (Máy nghiền có cối xay nước)
    copy_extracted("bldg_sheet_r1_c1.png", ["building_feed_mill.png"])

    # Mini Zoo / Khu sở thú: bldg_crop_sheet_r2_c1.png (Carousel ngựa quay xinh xắn)
    copy_extracted("bldg_crop_sheet_r2_c1.png", ["building_mini_zoo.png", "decor_carousel.png"])

    print("=== ASSET DEPLOYMENT COMPLETE! ===")

if __name__ == "__main__":
    main()
