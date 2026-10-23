import os
import sys
import urllib.request
import urllib.parse
from PIL import Image
import numpy as np
import scipy.ndimage as ndi

sys.stdout.reconfigure(encoding='utf-8')
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

PROMPTS = {
    "apple": "cute single red apple with small leaf, cozy chibi kawaii hay day style, white background, soft brown outline",
    "strawberry": "cute single ripe red strawberry with green top leaves, cozy chibi kawaii hay day style, white background, soft brown outline",
    "tomato": "cute single plump red tomato with green star calyx, cozy chibi kawaii hay day style, white background, soft brown outline",
    "pumpkin": "cute round orange pumpkin with green stem, cozy chibi kawaii hay day style, white background, soft brown outline",
    "soybean": "cute green soybean edamame pods with beans, cozy chibi kawaii hay day style, white background, soft brown outline",
    "sugarcane": "cute bundle of green sugarcane stalks tied, cozy chibi kawaii hay day style, white background, soft brown outline",
    "sugarcane_juice": "cute glass of fresh iced green sugarcane juice with straw, cozy chibi kawaii hay day style, white background",
    "apple_juice": "cute glass of fresh red apple juice with straw, cozy chibi kawaii hay day style, white background",
    "mango_smoothie": "cute glass of fresh yellow mango smoothie with straw, cozy chibi kawaii hay day style, white background",
    "cheese": "cute yellow cheese wedge with holes, cozy chibi kawaii hay day style, white background, soft brown outline",
}

def fetch_and_save(item_id: str, prompt: str):
    enc_prompt = urllib.parse.quote(prompt)
    url = f"https://image.pollinations.ai/prompt/{enc_prompt}?width=128&height=128&nologo=true"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'})
    try:
        with urllib.request.urlopen(req, timeout=12) as resp:
            data = resp.read()
            raw_path = os.path.join(SPRITES_DIR, f"temp_{item_id}.png")
            with open(raw_path, 'wb') as f:
                f.write(data)
            
            with Image.open(raw_path) as im:
                trans = fast_border_transparent(im, tolerance=32)
                cropped = auto_crop_alpha(trans, padding=3)
                
                out1 = os.path.join(SPRITES_DIR, f"{item_id}.png")
                out2 = os.path.join(SPRITES_DIR, f"item_{item_id}.png")
                cropped.save(out1)
                cropped.save(out2)
                print(f"[Success] Fetched & Transparent: {item_id}.png & item_{item_id}.png ({cropped.size})")
            
            if os.path.exists(raw_path):
                os.remove(raw_path)
    except Exception as e:
        print(f"[Error] Failed {item_id}: {e}")

def main():
    for item_id, prompt in PROMPTS.items():
        fetch_and_save(item_id, prompt)

if __name__ == "__main__":
    main()
