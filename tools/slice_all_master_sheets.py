import os
import shutil
from collections import deque
from PIL import Image

PROJECT = r"D:\HayDayOffline"
SPRITES_DIR = os.path.join(PROJECT, "assets", "sprites")
BACKUP_DIR = os.path.join(PROJECT, "assets", "_sprite_backups")

RAW_SEARCH_DIRS = [
    os.path.join(PROJECT, "assets", "sprites", "raw_refs"),
    os.path.join(PROJECT, "assets", "raw_refs")
]

def find_raw_file(filename):
    for d in RAW_SEARCH_DIRS:
        p = os.path.join(d, filename)
        if os.path.exists(p):
            return p
    return None

def floodfill_transparent(im_crop, threshold=238, align="center", target_size=(64, 64)):
    img = im_crop.convert("RGBA")
    w, h = img.size
    pixels = img.load()

    visited = [[False] * h for _ in range(w)]
    queue = deque()

    def is_bg(x, y):
        r, g, b, a = pixels[x, y]
        return r >= threshold and g >= threshold and b >= threshold

    # Seed strictly from 4 outer perimeter borders
    for x in range(w):
        if is_bg(x, 0):
            queue.append((x, 0))
            visited[x][0] = True
        if is_bg(x, h - 1):
            queue.append((x, h - 1))
            visited[x][h - 1] = True

    for y in range(h):
        if is_bg(0, y):
            queue.append((0, y))
            visited[0][y] = True
        if is_bg(w - 1, y):
            queue.append((w - 1, y))
            visited[w - 1][y] = True

    while queue:
        cx, cy = queue.popleft()
        pixels[cx, cy] = (0, 0, 0, 0)
        for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            nx, ny = cx + dx, cy + dy
            if 0 <= nx < w and 0 <= ny < h and not visited[nx][ny]:
                if is_bg(nx, ny):
                    visited[nx][ny] = True
                    queue.append((nx, ny))

    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)

    # Pad with transparent margin into square canvas
    tw, th = target_size
    pad = 4
    avail_w = max(1, tw - pad * 2)
    avail_h = max(1, th - pad * 2)

    scale_f = min(float(avail_w) / img.width, float(avail_h) / img.height)
    new_w = max(1, int(img.width * scale_f))
    new_h = max(1, int(img.height * scale_f))
    resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (tw, th), (0, 0, 0, 0))
    offset_x = (tw - new_w) // 2
    if align == "bottom":
        offset_y = th - new_h - pad // 2
    else:
        offset_y = (th - new_h) // 2

    canvas.paste(resized, (offset_x, offset_y), resized)
    return canvas

def save_with_aliases(img, primary_name, aliases=[]):
    primary_path = os.path.join(SPRITES_DIR, primary_name)
    img.save(primary_path)
    print(f"  [+] Saved {primary_name}")

    for a in aliases:
        a_path = os.path.join(SPRITES_DIR, a)
        img.save(a_path)
        print(f"      alias: {a}")

def process_grid(sheet_file, num_rows, num_cols, mapping, default_target_size=(64, 64), default_align="center"):
    raw_path = find_raw_file(sheet_file)
    if not raw_path:
        print(f"[!] Sheet not found: {sheet_file} (skipping)")
        return

    print(f"\n=== Processing Sheet: {sheet_file} from {raw_path} ===")
    im = Image.open(raw_path)
    sw, sh = im.size
    cw = sw / float(num_cols)
    ch = sh / float(num_rows)

    for (r, c), info in mapping.items():
        if r >= num_rows or c >= num_cols:
            continue
        
        x0 = int(c * cw)
        y0 = int(r * ch)
        x1 = int((c + 1) * cw)
        y1 = int((r + 1) * ch)

        cell = im.crop((x0, y0, x1, y1))
        
        primary_name = info["name"]
        aliases = info.get("aliases", [])
        align = info.get("align", default_align)
        tsize = info.get("size", default_target_size)
        thresh = info.get("threshold", 238)

        cleaned = floodfill_transparent(cell, threshold=thresh, align=align, target_size=tsize)
        save_with_aliases(cleaned, primary_name, aliases)

def main():
    os.makedirs(SPRITES_DIR, exist_ok=True)
    os.makedirs(BACKUP_DIR, exist_ok=True)

    # 1. sheet_crops_1.png (4x4)
    crops_1_map = {
        (0, 0): {"name": "seed_wheat.png", "aliases": ["item_seed_wheat.png"]},
        (0, 1): {"name": "crop_wheat_sprout.png", "aliases": ["crop_wheat_0.png", "crop_wheat_stage_0.png"], "align": "bottom"},
        (0, 2): {"name": "crop_wheat_ripe.png", "aliases": ["crop_wheat_3.png", "crop_wheat_ready.png"], "align": "bottom"},
        (0, 3): {"name": "wheat.png", "aliases": ["item_wheat.png", "crop_wheat.png"]},

        (1, 0): {"name": "seed_corn.png", "aliases": ["item_seed_corn.png"]},
        (1, 1): {"name": "crop_corn_sprout.png", "aliases": ["crop_corn_0.png", "crop_corn_stage_0.png"], "align": "bottom"},
        (1, 2): {"name": "crop_corn_ripe.png", "aliases": ["crop_corn_3.png", "crop_corn_ready.png"], "align": "bottom"},
        (1, 3): {"name": "corn.png", "aliases": ["item_corn.png", "crop_corn.png"]},

        (2, 0): {"name": "seed_carrot.png", "aliases": ["item_seed_carrot.png"]},
        (2, 1): {"name": "crop_carrot_sprout.png", "aliases": ["crop_carrot_0.png", "crop_carrot_stage_0.png"], "align": "bottom"},
        (2, 2): {"name": "crop_carrot_ripe.png", "aliases": ["crop_carrot_3.png", "crop_carrot_ready.png"], "align": "bottom"},
        (2, 3): {"name": "carrot.png", "aliases": ["item_carrot.png", "crop_carrot.png"]},

        (3, 0): {"name": "seed_tomato.png", "aliases": ["item_seed_tomato.png"]},
        (3, 1): {"name": "crop_tomato_sprout.png", "aliases": ["crop_tomato_0.png", "crop_tomato_stage_0.png"], "align": "bottom"},
        (3, 2): {"name": "crop_tomato_ripe.png", "aliases": ["crop_tomato_3.png", "crop_tomato_ready.png"], "align": "bottom"},
        (3, 3): {"name": "tomato.png", "aliases": ["item_tomato.png", "crop_tomato.png"]},
    }
    process_grid("sheet_crops_1.png", 4, 4, crops_1_map, default_target_size=(64, 64))

    # 2. sheet_crops_2.png (4x4)
    crops_2_map = {
        (0, 0): {"name": "seed_strawberry.png", "aliases": ["item_seed_strawberry.png"]},
        (0, 1): {"name": "crop_strawberry_sprout.png", "aliases": ["crop_strawberry_0.png"], "align": "bottom"},
        (0, 2): {"name": "crop_strawberry_ripe.png", "aliases": ["crop_strawberry_ready.png"], "align": "bottom"},
        (0, 3): {"name": "strawberry.png", "aliases": ["item_strawberry.png", "crop_strawberry.png"]},

        (1, 0): {"name": "seed_pumpkin.png", "aliases": ["item_seed_pumpkin.png"]},
        (1, 1): {"name": "crop_pumpkin_sprout.png", "aliases": ["crop_pumpkin_0.png"], "align": "bottom"},
        (1, 2): {"name": "crop_pumpkin_ripe.png", "aliases": ["crop_pumpkin_ready.png"], "align": "bottom"},
        (1, 3): {"name": "pumpkin.png", "aliases": ["item_pumpkin.png", "crop_pumpkin.png"]},

        (2, 0): {"name": "seed_soybean.png", "aliases": ["item_seed_soybean.png"]},
        (2, 1): {"name": "crop_soybean_sprout.png", "aliases": ["crop_soybean_0.png"], "align": "bottom"},
        (2, 2): {"name": "crop_soybean_ripe.png", "aliases": ["crop_soybean_ready.png"], "align": "bottom"},
        (2, 3): {"name": "soybean.png", "aliases": ["item_soybean.png", "crop_soybean.png"]},

        (3, 0): {"name": "seed_sugarcane.png", "aliases": ["item_seed_sugarcane.png"]},
        (3, 1): {"name": "crop_sugarcane_sprout.png", "aliases": ["crop_sugarcane_0.png"], "align": "bottom"},
        (3, 2): {"name": "crop_sugarcane_ripe.png", "aliases": ["crop_sugarcane_3.png", "crop_sugarcane_ready.png"], "align": "bottom"},
        (3, 3): {"name": "sugarcane.png", "aliases": ["item_sugarcane.png", "crop_sugarcane.png"]},
    }
    process_grid("sheet_crops_2.png", 4, 4, crops_2_map, default_target_size=(64, 64))

    # 3. sheet_flowers_soil.png (4x4)
    flowers_soil_map = {
        (0, 0): {"name": "seed_sunflower.png", "aliases": ["item_seed_sunflower.png"]},
        (0, 1): {"name": "crop_sunflower_sprout.png", "aliases": ["crop_sunflower_0.png"], "align": "bottom"},
        (0, 2): {"name": "crop_sunflower_ripe.png", "aliases": ["crop_sunflower_ready.png"], "align": "bottom"},
        (0, 3): {"name": "sunflower.png", "aliases": ["item_sunflower.png", "crop_sunflower.png"]},

        (1, 0): {"name": "seed_rose.png", "aliases": ["item_seed_rose.png"]},
        (1, 1): {"name": "crop_rose_sprout.png", "aliases": ["crop_rose_0.png"], "align": "bottom"},
        (1, 2): {"name": "crop_rose_ripe.png", "aliases": ["crop_rose_ready.png"], "align": "bottom"},
        (1, 3): {"name": "rose.png", "aliases": ["item_rose.png", "crop_rose.png"]},

        (2, 0): {"name": "seed_lavender.png", "aliases": ["item_seed_lavender.png"]},
        (2, 1): {"name": "crop_lavender_sprout.png", "aliases": ["crop_lavender_0.png"], "align": "bottom"},
        (2, 2): {"name": "crop_lavender_ripe.png", "aliases": ["crop_lavender_ready.png"], "align": "bottom"},
        (2, 3): {"name": "lavender.png", "aliases": ["item_lavender.png", "crop_lavender.png"]},

        (3, 0): {"name": "plot_soil_empty.png", "aliases": ["plot_soil_empty_tile.png"], "size": (64, 64)},
        (3, 1): {"name": "plot_soil.png", "aliases": ["plot_soil_tile.png"], "size": (64, 64)},
    }
    process_grid("sheet_flowers_soil.png", 4, 4, flowers_soil_map, default_target_size=(64, 64))

    # 4. sheet_trees_fruits.png (3x3 - if exists)
    trees_fruits_map = {
        (0, 0): {"name": "apple_seed.png", "aliases": ["item_apple_seed.png"]},
        (0, 1): {"name": "mango_seed.png", "aliases": ["item_mango_seed.png"]},
        (0, 2): {"name": "tree_sapling.png", "size": (96, 96), "align": "bottom"},

        (1, 0): {"name": "tree_fruitless.png", "size": (96, 96), "align": "bottom"},
        (1, 1): {"name": "tree_apple_ripe.png", "size": (96, 96), "align": "bottom"},
        (1, 2): {"name": "tree_mango_ripe.png", "size": (96, 96), "align": "bottom"},

        (2, 0): {"name": "tree_withered.png", "size": (96, 96), "align": "bottom"},
        (2, 1): {"name": "apple.png", "aliases": ["item_apple.png"]},
        (2, 2): {"name": "mango.png", "aliases": ["item_mango.png"]},
    }
    process_grid("sheet_trees_fruits.png", 3, 3, trees_fruits_map, default_target_size=(64, 64))

    # 5. sheet_animals_products.png (4 rows x 3 cols)
    animals_products_map = {
        (0, 0): {"name": "animal_chicken.png", "size": (96, 96), "align": "bottom"},
        (0, 1): {"name": "animal_cow.png", "size": (96, 96), "align": "bottom"},
        (0, 2): {"name": "animal_pig.png", "size": (96, 96), "align": "bottom"},

        (1, 0): {"name": "animal_sheep.png", "size": (96, 96), "align": "bottom"},
        (1, 1): {"name": "animal_horse.png", "size": (96, 96), "align": "bottom"},
        (1, 2): {"name": "animal_donkey.png", "size": (96, 96), "align": "bottom"},

        (2, 0): {"name": "egg.png", "aliases": ["item_egg.png"]},
        (2, 1): {"name": "milk.png", "aliases": ["item_milk.png"]},
        (2, 2): {"name": "bacon.png", "aliases": ["item_bacon.png", "pork.png"]},

        (3, 0): {"name": "wool.png", "aliases": ["item_wool.png"]},
        (3, 1): {"name": "cow_feed.png", "aliases": ["item_cow_feed.png"]},
        (3, 2): {"name": "pig_feed.png", "aliases": ["item_pig_feed.png"]},
    }
    process_grid("sheet_animals_products.png", 4, 3, animals_products_map, default_target_size=(64, 64))

    # 6. new_items_chibi.png (3x3)
    new_items_map = {
        (0, 0): {"name": "chicken_feed.png", "aliases": ["item_chicken_feed.png"]},
        (0, 1): {"name": "cow_feed.png", "aliases": ["item_cow_feed.png"]},
        (0, 2): {"name": "pig_feed.png", "aliases": ["item_pig_feed.png"]},

        (1, 0): {"name": "butter.png", "aliases": ["item_butter.png"]},
        (1, 1): {"name": "corn_bread.png", "aliases": ["item_corn_bread.png"]},
        (1, 2): {"name": "butter_cookie.png", "aliases": ["item_butter_cookie.png", "cookie.png", "item_cookie.png"]},

        (2, 0): {"name": "sugarcane_juice.png", "aliases": ["item_sugarcane_juice.png"]},
        (2, 1): {"name": "apple_juice.png", "aliases": ["item_apple_juice.png"]},
        (2, 2): {"name": "mango_smoothie.png", "aliases": ["item_mango_smoothie.png"]},
    }
    process_grid("new_items_chibi.png", 3, 3, new_items_map, default_target_size=(64, 64))

    # sheet_bakery_dairy.png (3x3 - if exists)
    bakery_dairy_map = {
        (0, 0): {"name": "bread.png", "aliases": ["item_bread.png"]},
        (0, 1): {"name": "corn_bread.png", "aliases": ["item_corn_bread.png"]},
        (0, 2): {"name": "butter_cookie.png", "aliases": ["item_butter_cookie.png", "cookie.png"]},

        (1, 0): {"name": "butter.png", "aliases": ["item_butter.png"]},
        (1, 1): {"name": "cheese.png", "aliases": ["item_cheese.png"]},
        (1, 2): {"name": "cream.png", "aliases": ["item_cream.png"]},

        (2, 0): {"name": "cream_cake.png", "aliases": ["item_cream_cake.png"]},
        (2, 1): {"name": "sheep_feed.png", "aliases": ["item_sheep_feed.png"]},
        (2, 2): {"name": "chicken_feed.png", "aliases": ["item_chicken_feed.png"]},
    }
    process_grid("sheet_bakery_dairy.png", 3, 3, bakery_dairy_map, default_target_size=(64, 64))

    # 7. sheet_fishing.png (2 rows x 3 cols)
    fishing_map = {
        (0, 0): {"name": "bait_red.png", "aliases": ["item_bait_red.png"]},
        (0, 1): {"name": "bait_blue.png", "aliases": ["item_bait_blue.png"]},
        (0, 2): {"name": "bait_gold.png", "aliases": ["item_bait_gold.png"]},

        (1, 0): {"name": "fish_carp.png", "aliases": ["item_fish_carp.png"]},
        (1, 1): {"name": "fish_bass.png", "aliases": ["item_fish_bass.png"]},
        (1, 2): {"name": "fish_golden_koi.png", "aliases": ["item_fish_golden_koi.png"]},
    }
    process_grid("sheet_fishing.png", 2, 3, fishing_map, default_target_size=(64, 64))

    # Dọn dẹp các file cũ bị lỗi dính chữ tiếng Anh ("china stew.png", "miktea.png", v.v.) vào _sprite_backups
    junk_files = ["china stew.png", "china stew.png.import", "miktea.png", "miktea.png.import"]
    for jf in junk_files:
        p = os.path.join(SPRITES_DIR, jf)
        if os.path.exists(p):
            dst = os.path.join(BACKUP_DIR, jf)
            shutil.move(p, dst)
            print(f"[Backup] Moved obsolete junk file {jf} -> _sprite_backups/")

    print("\n[SUCCESS] Completed slicing all available master sheets!")

if __name__ == "__main__":
    main()
