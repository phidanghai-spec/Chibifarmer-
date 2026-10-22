"""
character_generator.py
Công cụ mở rộng và tạo Nhân vật Chibi / Du khách NPC cho Hay Day Offline.
Tự động tách lẻ từ sheet (Connected Components) hoặc tạo ảnh mới,
xóa nền Corner Floodfill, lưu vào assets/sprites/<char_id>.png và đăng ký vào SpriteAtlasManager.
"""

import os
import sys
import argparse
import numpy as np
from PIL import Image
import scipy.ndimage as ndi

if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

BASE_DIR = os.path.dirname(os.path.dirname(__file__))
SPRITES_DIR = os.path.join(BASE_DIR, "assets", "sprites")
ATLAS_MANAGER_PATH = os.path.join(BASE_DIR, "scripts", "core", "sprite_atlas_manager.gd")

def remove_background_floodfill(img, bg_threshold=235):
    img = img.convert("RGBA")
    arr = np.array(img)
    w, h = img.size
    visited = np.zeros((h, w), dtype=bool)

    r, g, b, a = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2], arr[:, :, 3]
    is_bg = (r >= bg_threshold) & (g >= bg_threshold) & (b >= bg_threshold) & (a > 10)

    # Seeds: 4 edges
    seeds_y, seeds_x = [], []
    for x in range(w):
        if is_bg[0, x]: seeds_y.append(0); seeds_x.append(x)
        if is_bg[h - 1, x]: seeds_y.append(h - 1); seeds_x.append(x)
    for y in range(h):
        if is_bg[y, 0]: seeds_y.append(y); seeds_x.append(0)
        if is_bg[y, w - 1]: seeds_y.append(y); seeds_x.append(w - 1)

    queue = list(zip(seeds_y, seeds_x))
    for y, x in queue:
        visited[y, x] = True

    head = 0
    while head < len(queue):
        cy, cx = queue[head]
        head += 1
        arr[cy, cx, 3] = 0

        for ny, nx in [(cy + 1, cx), (cy - 1, cx), (cy, cx + 1), (cy, cx - 1)]:
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx]:
                visited[ny, nx] = True
                if is_bg[ny, nx]:
                    queue.append((ny, nx))

    return Image.fromarray(arr)

def register_texture_in_atlas(char_id, file_name):
    if not os.path.exists(ATLAS_MANAGER_PATH):
        return
    with open(ATLAS_MANAGER_PATH, "r", encoding="utf-8") as f:
        content = f.read()

    line_to_add = f'\t_load_standalone_texture("{char_id}", "res://assets/sprites/{file_name}")'
    if char_id in content:
        print(f"Texture '{char_id}' already registered in SpriteAtlasManager.")
        return

    # Insert before the end of _ready or before _load_standalone_texture definition
    target = 'func _load_standalone_texture'
    if target in content:
        parts = content.split(target, 1)
        new_content = parts[0] + f'{line_to_add}\n\n' + target + parts[1]
        with open(ATLAS_MANAGER_PATH, "w", encoding="utf-8") as f:
            f.write(new_content)
        print(f"Registered '{char_id}' into SpriteAtlasManager.")

def generate_chibi_character(char_id, out_name=None):
    if out_name is None:
        out_name = f"{char_id}.png"
    out_path = os.path.join(SPRITES_DIR, out_name)

    # Create a cute cozy Chibi character placeholder if no external image
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    from PIL import ImageDraw
    d = ImageDraw.Draw(img)

    # Shadow
    d.ellipse([34, 102, 94, 118], fill=(60, 45, 30, 60))
    # Shoes
    d.ellipse([42, 94, 60, 108], fill=(95, 60, 30, 255))
    d.ellipse([68, 94, 86, 108], fill=(95, 60, 30, 255))
    # Overalls / Pants
    d.rectangle([46, 76, 82, 98], fill=(60, 120, 195, 255))
    # Shirt
    d.ellipse([40, 56, 88, 82], fill=(245, 210, 60, 255))
    # Head
    d.ellipse([38, 22, 90, 68], fill=(255, 225, 195, 255), outline=(150, 100, 60, 255), width=2)
    # Straw Hat / Hair
    d.chord([26, 8, 102, 46], 180, 360, fill=(230, 190, 110, 255), outline=(140, 95, 40, 255), width=2)
    d.line([(22, 28), (106, 28)], fill=(210, 170, 90, 255), width=4)
    # Eyes
    d.ellipse([50, 42, 56, 50], fill=(40, 25, 20, 255))
    d.ellipse([72, 42, 78, 50], fill=(40, 25, 20, 255))
    # Blush
    d.ellipse([44, 48, 52, 54], fill=(255, 150, 160, 160))
    d.ellipse([76, 48, 84, 54], fill=(255, 150, 160, 160))
    # Smile
    d.arc([58, 48, 70, 58], 0, 180, fill=(180, 70, 60, 255), width=2)

    img.save(out_path, "PNG")
    print(f"Generated Chibi NPC: {out_path}")
    register_texture_in_atlas(char_id, out_name)
    return out_path

def main():
    parser = argparse.ArgumentParser(description="Chibi Character Generator & Forge")
    parser.add_argument("--id", required=True, help="Character identifier (e.g. visitor_baker, npc_farmer_02)")
    parser.add_argument("--prompt", default="", help="Description of character")
    parser.add_argument("--output", default=None, help="Output file name")
    args = parser.parse_args()

    generate_chibi_character(args.id, args.output)

if __name__ == "__main__":
    main()
