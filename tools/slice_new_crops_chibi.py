import os
from collections import deque
from PIL import Image

PROJECT = r"D:\HayDayOffline"
SRC = os.path.join(PROJECT, "assets", "raw_refs", "new_crops_chibi.png")
OUT_DIR = os.path.join(PROJECT, "assets", "sprites")

crop_names = ["wheat", "corn", "carrot", "sugarcane"]

def floodfill_transparent(im_crop, threshold=240):
    img = im_crop.convert("RGBA")
    w, h = img.size
    pixels = img.load()

    visited = [[False] * h for _ in range(w)]
    queue = deque()

    def is_bg(x, y):
        r, g, b, a = pixels[x, y]
        return r >= threshold and g >= threshold and b >= threshold

    # Seed from 4 edges
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

    # Bounding box
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)

    # Pad to square 64x64 or target 64x64
    max_dim = max(img.width, img.height)
    square = Image.new("RGBA", (max_dim, max_dim), (0, 0, 0, 0))
    # Align bottom-center so plant roots sit naturally on the soil
    offset_x = (max_dim - img.width) // 2
    offset_y = max_dim - img.height
    square.paste(img, (offset_x, offset_y), img)
    square = square.resize((64, 64), Image.Resampling.LANCZOS)
    return square

def main():
    if not os.path.exists(SRC):
        print(f"Error: {SRC} not found!")
        return

    full_img = Image.open(SRC)
    width, height = full_img.size
    print(f"Loaded image {SRC} with size {width}x{height}")

    num_cols = 4
    num_rows = 4

    cell_w = width / float(num_cols)
    cell_h = height / float(num_rows)

    os.makedirs(OUT_DIR, exist_ok=True)

    for r in range(num_rows):
        crop_id = crop_names[r]
        for c in range(num_cols):
            x0 = int(c * cell_w)
            y0 = int(r * cell_h)
            x1 = int((c + 1) * cell_w)
            y1 = int((r + 1) * cell_h)

            cell = full_img.crop((x0, y0, x1, y1))
            cleaned = floodfill_transparent(cell, threshold=238)

            filename = f"crop_{crop_id}_{c}.png"
            out_path = os.path.join(OUT_DIR, filename)
            cleaned.save(out_path)
            print(f"Saved: {filename} ({cleaned.size})")

            # Also save stage 3 as crop_<id>.png and crop_<id>_ready.png for backward compatibility
            if c == 3:
                cleaned.save(os.path.join(OUT_DIR, f"crop_{crop_id}.png"))
                cleaned.save(os.path.join(OUT_DIR, f"crop_{crop_id}_ready.png"))
                cleaned.save(os.path.join(OUT_DIR, f"crop_{crop_id}_stage_2.png"))
            elif c == 1:
                cleaned.save(os.path.join(OUT_DIR, f"crop_{crop_id}_stage_0.png"))
            elif c == 2:
                cleaned.save(os.path.join(OUT_DIR, f"crop_{crop_id}_stage_1.png"))

    print("Successfully processed all 16 crop stage sprites!")

if __name__ == "__main__":
    main()
