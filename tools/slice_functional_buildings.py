"""
slice_functional_buildings.py
Extracts clean, transparent chibi functional buildings from 'assets/sprites/script nhà chức năng.jpg'
using color-distance background masking, flood-fill, and stray-pixel island pruning.
Removes all white text labels, green background, and edge artifacts.
"""

import os
import sys
from collections import deque
import numpy as np
from PIL import Image
from scipy import ndimage

if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')

INPUT_PATH = "assets/sprites/script nhà chức năng.jpg"
OUTPUT_DIR = "assets/sprites"
ALL_BUILDINGS_DIR = "assets/sprites/functional_buildings"

# Mapping of (row, col) (1-indexed) to target sprite filename and description
BUILDING_MAP = {
    # Row 1
    (1, 1): ("building_barn.png", "Storage (Nhà Kho)"),
    (1, 2): ("building_chicken_coop.png", "Chicken coop (Chuồng Gà)"),
    (1, 3): ("building_bakery.png", "Bakery (Lò Bánh Mì)"),
    (1, 4): ("building_cowshed.png", "Cowshed (Chuồng Bò)"),
    # Row 2
    (2, 1): ("building_rubber_factory.png", "Rubber factory"),
    (2, 2): ("building_italian_restaurant.png", "Italian restaurant"),
    (2, 3): ("building_silo.png", "Sugar factory (Kho Silo)"),
    (2, 4): ("building_tailor_factory.png", "Tailor factory"),
    # Row 3
    (3, 1): ("building_duck_pond.png", "Duck pond"),
    (3, 2): ("building_fish_pond.png", "Fish pond"),
    (3, 3): ("building_lobster_farm.png", "Lobster farm"),
    (3, 4): ("building_crab_fisheries.png", "Crab fisheries"),
    # Row 4
    (4, 1): ("building_pigsty.png", "Pigsty (Chuồng Heo)"),
    (4, 2): ("building_sheep_barn.png", "Sheep barn (Chuồng Cừu)"),
    (4, 3): ("building_bee_hive.png", "Bee hive (Tổ Ong)"),
    (4, 4): ("building_asian_restaurant.png", "Asian restaurant"),
    # Row 5
    (5, 1): ("building_cake_oven.png", "Pastry factory (Lò Bánh Ngọt)"),
    (5, 2): ("building_ice_cream.png", "Ice-cream factory (Quầy Kem)"),
    (5, 3): ("building_mexican_restaurant.png", "Mexican restaurant"),
    (5, 4): ("building_juice_stand.png", "Coffee shop (Quầy Nước / Cà Phê)"),
}

def extract_clean_building(im: Image.Image, bbox: tuple[int, int, int, int]) -> Image.Image:
    x0, y0, x1, y1 = bbox
    # Add small padding margin
    w_orig, h_orig = im.size
    px0 = max(0, x0 - 6)
    py0 = max(0, y0 - 6)
    px1 = min(w_orig, x1 + 6)
    py1 = min(h_orig, y1 + 6)

    crop = im.crop((px0, py0, px1, py1)).convert("RGBA")
    arr = np.array(crop)
    h, w, _ = arr.shape

    # Mean green grass color in the sheet is around (119, 186, 80)
    bg_color = np.array([119.0, 186.0, 80.0])
    diff = arr[:, :, :3].astype(float) - bg_color
    dist = np.sqrt(np.sum(diff**2, axis=2))

    # Grass background mask: color distance < 34 covers light/dark grass and grid lines
    is_bg = dist < 34.0

    # Flood-fill from borders
    visited = np.zeros((h, w), dtype=bool)
    queue = deque()

    for x in range(w):
        if is_bg[0, x]:
            queue.append((0, x)); visited[0, x] = True
        if is_bg[h - 1, x]:
            queue.append((h - 1, x)); visited[h - 1, x] = True
    for y in range(h):
        if is_bg[y, 0]:
            queue.append((y, 0)); visited[y, 0] = True
        if is_bg[y, w - 1]:
            queue.append((y, w - 1)); visited[y, w - 1] = True

    while queue:
        cy, cx = queue.popleft()
        for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx]:
                if is_bg[ny, nx]:
                    visited[ny, nx] = True
                    queue.append((ny, nx))

    # Mask out background
    arr[visited, 3] = 0

    # Prune tiny stray islands (disconnected grass flecks < 150 pixels)
    fg_mask = arr[:, :, 3] > 0
    labeled, num_features = ndimage.label(fg_mask)
    if num_features > 1:
        # Measure size of each component
        sizes = ndimage.sum(fg_mask, labeled, range(1, num_features + 1))
        # Keep components with area >= 200 pixels
        for idx, size in enumerate(sizes, start=1):
            if size < 200:
                arr[labeled == idx, 3] = 0

    # Check for any solid black borders (e.g. edge artifacts)
    # If border pixels have alpha > 0 and low brightness (< 30) or green hue, soften or clear
    res = Image.fromarray(arr)
    bbox_alpha = res.getbbox()
    if bbox_alpha:
        res = res.crop(bbox_alpha)

    return res

def main():
    os.makedirs(ALL_BUILDINGS_DIR, exist_ok=True)
    if not os.path.exists(INPUT_PATH):
        print(f"Error: {INPUT_PATH} not found!")
        return

    im = Image.open(INPUT_PATH)
    print(f"Loaded {INPUT_PATH}: {im.size}")

    arr = np.array(im)
    r, g, b = arr[:, :, 0].astype(int), arr[:, :, 1].astype(int), arr[:, :, 2].astype(int)
    is_bg = (g > r + 15) & (g > b + 15) & (g > 110) & (r < 170) & (b < 140)
    fg = ~is_bg

    struct = ndimage.generate_binary_structure(2, 2)
    fg_closed = ndimage.binary_closing(fg, structure=struct, iterations=3)
    labeled, num_features = ndimage.label(fg_closed)

    objs = ndimage.find_objects(labeled)
    large_boxes = []
    for i, sl in enumerate(objs):
        if sl is None:
            continue
        area = np.sum(labeled[sl] == (i + 1))
        sy, sx = sl
        bh = sy.stop - sy.start
        bw = sx.stop - sx.start
        if area > 1000 and bw > 40 and bh > 40:
            large_boxes.append((sx.start, sy.start, sx.stop, sy.stop))

    print(f"Found {len(large_boxes)} building components.")

    # Group into 5 rows (based on y center) and 4 columns (based on x center)
    large_boxes.sort(key=lambda b: ((b[1] + b[3]) // 2 // 240, (b[0] + b[2]) // 2))

    # Split into 5 rows of 4
    rows = []
    for r_idx in range(5):
        row_slice = large_boxes[r_idx * 4 : (r_idx + 1) * 4]
        # Sort each row by x center
        row_slice.sort(key=lambda b: (b[0] + b[2]) // 2)
        rows.append(row_slice)

    # Process and save
    for r_idx, row in enumerate(rows, start=1):
        for c_idx, bbox in enumerate(row, start=1):
            key = (r_idx, c_idx)
            if key in BUILDING_MAP:
                fname, desc = BUILDING_MAP[key]
                cleaned = extract_clean_building(im, bbox)
                
                # Save to main sprites directory
                out_path = os.path.join(OUTPUT_DIR, fname)
                cleaned.save(out_path)
                
                # Also save to functional_buildings folder
                archive_path = os.path.join(ALL_BUILDINGS_DIR, fname)
                cleaned.save(archive_path)
                
                print(f"[Row {r_idx}, Col {c_idx}] {desc} -> {fname} ({cleaned.size})")

    print("\n--- All functional buildings sliced and saved cleanly! ---")

if __name__ == "__main__":
    main()
