import os
import sys
from collections import deque
from PIL import Image, ImageDraw, ImageFilter

if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

PROJECT = r"D:\HayDayOffline"
DEFAULT_IN = os.path.join(PROJECT, "assets", "pinterest", "script đất.jpg")
OUT_DIR = os.path.join(PROJECT, "assets", "sprites", "plots_raw")
MIN_AREA = 8000  # bỏ qua vùng nhỏ (chữ, cỏ lẫn đất)


def is_dirt(r: int, g: int, b: int) -> bool:
    return (130 <= r <= 235 and 95 <= g <= 190 and 60 <= b <= 165
            and 15 <= r - g <= 70 and g - b >= 8)


def main() -> None:
    src = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_IN
    if not os.path.exists(src):
        # Fallback thử tên không dấu hoặc có gạch dưới nếu cần
        alt = os.path.join(PROJECT, "assets", "pinterest", "script_đất.jpg")
        if os.path.exists(alt):
            src = alt
    print(f"Reading source image: {src}")
    os.makedirs(OUT_DIR, exist_ok=True)
    img = Image.open(src).convert("RGB")
    w, h = img.size
    px = img.load()

    mask = Image.new("L", (w, h), 0)
    mp = mask.load()
    for y in range(h):
        for x in range(w):
            if is_dirt(*px[x, y]):
                mp[x, y] = 255
    # Nối các mảnh đất bị cây che thành một vùng liền
    mask = mask.filter(ImageFilter.MaxFilter(7))
    mp = mask.load()

    seen = bytearray(w * h)
    boxes = []
    for y0 in range(h):
        for x0 in range(w):
            i0 = y0 * w + x0
            if seen[i0] or mp[x0, y0] == 0:
                continue
            seen[i0] = 1
            q = deque([(x0, y0)])
            minx = maxx = x0
            miny = maxy = y0
            area = 0
            while q:
                x, y = q.popleft()
                area += 1
                minx, maxx = min(minx, x), max(maxx, x)
                miny, maxy = min(miny, y), max(maxy, y)
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= nx < w and 0 <= ny < h:
                        ni = ny * w + nx
                        if not seen[ni] and mp[nx, ny]:
                            seen[ni] = 1
                            q.append((nx, ny))
            if area >= MIN_AREA:
                boxes.append((minx, miny, maxx + 1, maxy + 1))

    boxes.sort(key=lambda b: (b[1] // 100, b[0]))
    debug = img.copy()
    draw = ImageDraw.Draw(debug)
    for i, box in enumerate(boxes, start=1):
        draw.rectangle(box, outline=(255, 0, 0), width=3)
        draw.text((box[0] + 4, box[1] + 4), str(i), fill=(255, 0, 0))
        out = os.path.join(OUT_DIR, f"plot_patch_{i:02d}.png")
        img.crop(box).save(out)
        print(f"plot_patch_{i:02d}: box={box} size={box[2]-box[0]}x{box[3]-box[1]}")

    debug_path = os.path.join(OUT_DIR, "debug_plot_boxes.png")
    debug.save(debug_path)
    print("=" * 60)
    print(f"Tìm thấy {len(boxes)} mảng đất. Xem khung đỏ tại: {debug_path}")


if __name__ == "__main__":
    main()
