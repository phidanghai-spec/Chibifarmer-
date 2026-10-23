import os
import glob
import shutil
from collections import deque
from PIL import Image

def corner_floodfill_transparency(img: Image.Image, threshold: int = 235) -> Image.Image:
    """Corner floodfill from 4 outer borders to remove white background without touching interior white details."""
    img = img.convert("RGBA")
    w, h = img.size
    pixels = img.load()
    
    queue = deque()
    visited = set()
    
    # Push all 4 outer border pixels
    for x in range(w):
        queue.append((x, 0))
        queue.append((x, h - 1))
    for y in range(h):
        queue.append((0, y))
        queue.append((w - 1, y))
        
    while queue:
        x, y = queue.popleft()
        if (x, y) in visited:
            continue
        visited.add((x, y))
        
        r, g, b, a = pixels[x, y]
        if r >= threshold and g >= threshold and b >= threshold:
            pixels[x, y] = (r, g, b, 0)
            for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in visited:
                    queue.append((nx, ny))
                    
    # Tight crop with padding 4px
    bbox = img.getbbox()
    if bbox:
        pad = 4
        crop_box = (max(0, bbox[0] - pad), max(0, bbox[1] - pad), min(w, bbox[2] + pad), min(h, bbox[3] + pad))
        img = img.crop(crop_box)
        
    # Standardize height to 128px preserving aspect ratio
    target_h = 128
    target_w = max(1, int(round(img.width * (target_h / float(img.height)))))
    img = img.resize((target_w, target_h), Image.Resampling.LANCZOS)
    return img

def main():
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    sprites_dir = os.path.join(base_dir, "assets", "sprites")
    extracted_dir = os.path.join(sprites_dir, "extracted")
    
    print("[1/5] Removing legacy flawed character sprites...")
    for old_file in glob.glob(os.path.join(extracted_dir, "char_sheet_*.png*")):
        try:
            os.remove(old_file)
            print(f" -> Removed: {os.path.basename(old_file)}")
        except Exception as e:
            print(f" -> Warning removing {old_file}: {e}")
            
    for f in ["visitor_adventurer.png", "visitor_adventurer.png.import"]:
        p = os.path.join(sprites_dir, f)
        if os.path.exists(p):
            try:
                os.remove(p)
                print(f" -> Removed legacy: {f}")
            except Exception as e:
                pass

    print("\n[2/5] Locating Chibi Character Master Sheet...")
    master_path = os.path.join(sprites_dir, "chibi_characters_master.png")
    if not os.path.exists(master_path):
        candidates = [
            os.path.join(sprites_dir, "Chibi-character-master.jpg"),
            os.path.join(sprites_dir, "chibi_characters_master.jpg"),
            os.path.join(base_dir, "assets", "pinterest", "Chibi-character-master.jpg"),
        ]
        for c in candidates:
            if os.path.exists(c):
                shutil.copyfile(c, master_path)
                print(f" -> Copied master sheet from {os.path.basename(c)} to chibi_characters_master.png")
                break
                
    if not os.path.exists(master_path):
        # Search anywhere in assets
        for root, dirs, files in os.walk(os.path.join(base_dir, "assets")):
            for f in files:
                if "chibi" in f.lower() and "character" in f.lower() and f.lower().endswith((".jpg", ".png")):
                    shutil.copyfile(os.path.join(root, f), master_path)
                    print(f" -> Found and copied {f} to chibi_characters_master.png")
                    break
            if os.path.exists(master_path):
                break

    if not os.path.exists(master_path):
        raise FileNotFoundError("Could not find chibi character master image in assets!")

    master_img = Image.open(master_path)
    mw, mh = master_img.size
    print(f" -> Master Image Loaded: {mw}x{mh}")

    # Precise crop regions avoiding text labels below feet
    # Row 1 (Staff): top = 0.02, bottom = 0.475 (Y=11 to Y=272)
    # Row 2 (Visitors): top = 0.53, bottom = 0.93 (Y=303 to Y=532)
    char_defs = [
        # Row 1: 5 Functional Staff
        {"name": "npc_baker.png", "title": "Thợ Bánh Mì", "box": (0.02, 0.02, 0.22, 0.475)},
        {"name": "npc_pastry.png", "title": "Thợ Bánh Ngọt", "box": (0.22, 0.02, 0.40, 0.475)},
        {"name": "npc_barista.png", "title": "Pha Chế", "box": (0.41, 0.02, 0.57, 0.475)},
        {"name": "npc_rancher.png", "title": "Người Chăn Nuôi", "box": (0.58, 0.02, 0.77, 0.475)},
        {"name": "npc_fisher.png", "title": "Người Câu Cá", "box": (0.78, 0.02, 0.98, 0.475)},
        # Row 2: 3 Visitors
        {"name": "visitor_buyer.png", "title": "Khách Mua Tận Nhà", "box": (0.16, 0.53, 0.35, 0.93)},
        {"name": "visitor_shopper.png", "title": "Khách Sạp Hàng", "box": (0.41, 0.53, 0.59, 0.93)},
        {"name": "visitor_tourist.png", "title": "Du Khách", "box": (0.64, 0.53, 0.84, 0.93)},
    ]

    print("\n[3/5] Cropping, floodfilling transparency and normalizing 8 characters...")
    created_files = {}
    for c in char_defs:
        l = int(mw * c["box"][0])
        t = int(mh * c["box"][1])
        r = int(mw * c["box"][2])
        b = int(mh * c["box"][3])
        
        crop = master_img.crop((l, t, r, b))
        final_img = corner_floodfill_transparency(crop, threshold=235)
        
        out_path = os.path.join(sprites_dir, c["name"])
        final_img.save(out_path, format="PNG")
        created_files[c["name"]] = out_path
        print(f" -> Processed & Saved: {c['name']} [Size: {final_img.size}]")

    print("\n[4/5] Synchronizing and overwriting legacy visitor & NPC textures...")
    # Overwrite legacy files directly
    sync_map = {
        # visitor_buyer
        "visitor_buyer.png": ["visitor_1.png", "npc_girl.png", "visitor_farmer.png"],
        # visitor_shopper
        "visitor_shopper.png": ["visitor_2.png", "visitor_miner.png", "visitor_florist.png"],
        # visitor_tourist
        "visitor_tourist.png": ["visitor_3.png", "visitor_4.png", "visitor_adventurer.png", "visitor_postman.png", "visitor_chef.png", "visitor_ranger.png", "visitor_gardener.png"],
        # Functional NPCs
        "npc_baker.png": ["npc_char_01.png"],
        "npc_pastry.png": ["npc_char_02.png"],
        "npc_barista.png": ["npc_char_03.png"],
        "npc_rancher.png": ["npc_char_04.png"],
        "npc_fisher.png": ["npc_char_05.png", "visitor_fisherman.png"],
    }
    
    for src_name, targets in sync_map.items():
        src_p = created_files.get(src_name)
        if src_p and os.path.exists(src_p):
            for tgt in targets:
                tgt_p = os.path.join(sprites_dir, tgt)
                shutil.copyfile(src_p, tgt_p)
                print(f"   -> Overwritten {tgt} with {src_name}")

    print("\n[5/5] All 8 Chibi characters successfully replaced and synchronized!")

if __name__ == "__main__":
    main()
