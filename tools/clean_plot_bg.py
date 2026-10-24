import os
import sys
from collections import deque
from PIL import Image

if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

PROJECT = r"D:\HayDayOffline"
SRC = os.path.join(PROJECT, "assets", "sprites", "plots_raw", "plot_block_empty_.png")
OUT = os.path.join(PROJECT, "assets", "sprites", "plots_raw", "plot_block_clean.png")
MAX_CH = 60      # kênh màu tối hơn ngưỡng này mới coi là nền
MAX_SPREAD = 25  # nền xám: chênh lệch R,G,B nhỏ


def is_bg(r: int, g: int, b: int) -> bool:
    hi, lo = max(r, g, b), min(r, g, b)
    return hi <= MAX_CH and (hi - lo) <= MAX_SPREAD


def main() -> None:
    src = sys.argv[1] if len(sys.argv) > 1 else SRC
    if not os.path.exists(src):
        # Fallback
        src = os.path.join(PROJECT, "assets", "sprites", "plots_raw", "plot_block_empty.png")
    img = Image.open(src).convert("RGBA")
    w, h = img.size
    px = img.load()

    seen = bytearray(w * h)
    q = deque()
    for x in range(w):
        q.append((x, 0))
        q.append((x, h - 1))
    for y in range(h):
        q.append((0, y))
        q.append((w - 1, y))

    cleared = 0
    while q:
        x, y = q.popleft()
        i = y * w + x
        if seen[i]:
            continue
        seen[i] = 1
        r, g, b, a = px[x, y]
        if a == 0:
            # Vùng đã trong suốt, tiếp tục loang ra các pixel lân cận
            for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if 0 <= nx < w and 0 <= ny < h and not seen[ny * w + nx]:
                    q.append((nx, ny))
            continue
        if not is_bg(r, g, b):
            continue
        px[x, y] = (r, g, b, 0)
        cleared += 1
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not seen[ny * w + nx]:
                q.append((nx, ny))

    img.save(OUT)
    print(f"Đã làm trong suốt {cleared} pixel nền. Lưu tại: {OUT}")


if __name__ == "__main__":
    main()
