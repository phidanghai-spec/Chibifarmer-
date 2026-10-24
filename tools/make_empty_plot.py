import os
import sys
from PIL import Image

if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

PROJECT = r"D:\HayDayOffline"
DEFAULT_SRC = os.path.join(PROJECT, "assets", "sprites", "plots_raw", "plot_patch_02.png")
OUT = os.path.join(PROJECT, "assets", "sprites", "plots_raw", "plot_block_empty.png")
RADIUS = 5


def is_dirt(r: int, g: int, b: int) -> bool:
    return (130 <= r <= 235 and 95 <= g <= 190 and 60 <= b <= 165
            and 15 <= r - g <= 70 and g - b >= 8)


def is_grass(r: int, g: int, b: int) -> bool:
    return g >= r


def main() -> None:
    src = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_SRC
    img = Image.open(src).convert("RGB")
    w, h = img.size
    px = img.load()

    # 0 = đất, 1 = cỏ, 2 = cây/vật cần xóa
    kind = [[0] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            if is_dirt(r, g, b):
                kind[y][x] = 0
            elif is_grass(r, g, b):
                kind[y][x] = 1
            else:
                kind[y][x] = 2

    out = img.copy()
    op = out.load()
    removed = 0
    for y in range(h):
        for x in range(w):
            if kind[y][x] != 2:
                continue
            sr = sg = sb = n = 0
            for dy in range(-RADIUS, RADIUS + 1):
                for dx in range(-RADIUS, RADIUS + 1):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and kind[ny][nx] == 0:
                        r, g, b = px[nx, ny]
                        sr += r
                        sg += g
                        sb += b
                        n += 1
            if n:
                op[x, y] = (sr // n, sg // n, sb // n)
                removed += 1

    out.save(OUT)
    print(f"Đã xóa {removed} pixel cây/vật trên khối đất.")
    print(f"Lưu tại: {OUT}")


if __name__ == "__main__":
    main()
