#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import sys
from collections import deque
from PIL import Image, ImageDraw, ImageFilter

SPRITES_DIR = os.path.normpath(r"D:\HayDayOffline\assets\sprites")
RAW_REFS_DIR = os.path.normpath(r"D:\HayDayOffline\assets\raw_refs")

def floodfill_transparent(im_crop, threshold=238, align="center", target_size=(160, 160), pad=6):
    img = im_crop.convert("RGBA")
    w, h = img.size
    pixels = img.load()

    visited = [[False] * h for _ in range(w)]
    queue = deque()

    def is_bg(x, y):
        r, g, b, a = pixels[x, y]
        return r >= threshold and g >= threshold and b >= threshold

    # Seed strictly from perimeter borders
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

    tw, th = target_size
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

def slice_homezoo():
    sheet_path = os.path.join(RAW_REFS_DIR, "sheet_homezoo.png")
    if not os.path.exists(sheet_path):
        print("Missing sheet_homezoo.png")
        return

    im = Image.open(sheet_path)
    # 2 rows x 4 cols, each 384 x 512
    cell_w = 384
    cell_h = 512

    enclosure_map = {
        (0, 0): "zoo_entrance.png",
        (0, 1): "zoo_enclosure_rabbit.png",
        (0, 2): "zoo_enclosure_penguin.png", # Vách đá hồ nước
        (0, 3): "zoo_enclosure_barn.png",
        (1, 0): "zoo_enclosure_capybara.png", # Hồ sen đá nước trong
        (1, 1): "zoo_enclosure_giraffe.png",  # Thảo nguyên hàng rào gỗ mùa thu
        (1, 2): "zoo_enclosure_panda.png",    # Vòm tre nhiệt đới
        (1, 3): "zoo_feed_shop.png",
    }

    for (r, c), filename in enclosure_map.items():
        box = (c * cell_w, r * cell_h, (c + 1) * cell_w, (r + 1) * cell_h)
        crop = im.crop(box)
        t_sz = (128, 128) if filename == "zoo_feed_shop.png" else (160, 160)
        processed = floodfill_transparent(crop, threshold=240, align="bottom", target_size=t_sz, pad=4)
        out_path = os.path.join(SPRITES_DIR, filename)
        processed.save(out_path)
        print(f"[+] Sliced {filename}")

def slice_zoo_products():
    sheet_path = os.path.join(RAW_REFS_DIR, "sheet_zoo_products.png")
    if not os.path.exists(sheet_path):
        print("Missing sheet_zoo_products.png")
        return

    im = Image.open(sheet_path)
    # 2 rows x 4 cols, each 384 x 512
    cell_w = 384
    cell_h = 512

    prod_map = {
        (1, 0): ("sanctuary_feed.png", ["item_sanctuary_feed.png"]), # Túi/bó thức ăn
        (1, 3): ("zoo_ticket.png", ["item_zoo_ticket.png"]),         # Vé sở thú
    }

    for (r, c), (filename, aliases) in prod_map.items():
        box = (c * cell_w, r * cell_h, (c + 1) * cell_w, (r + 1) * cell_h)
        crop = im.crop(box)
        processed = floodfill_transparent(crop, threshold=240, align="center", target_size=(64, 64), pad=4)
        out_path = os.path.join(SPRITES_DIR, filename)
        processed.save(out_path)
        print(f"[+] Sliced {filename}")
        for alias in aliases:
            processed.save(os.path.join(SPRITES_DIR, alias))

def generate_chibi_animals():
    # 1. Capybara (Cute Brown Capybara with Orange/Yuzu on head)
    im_capy = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(im_capy)
    # Body
    d.ellipse([26, 44, 102, 116], fill="#C4925A", outline="#4A2C18", width=3)
    # Belly highlight
    d.ellipse([38, 62, 90, 112], fill="#E5BC82")
    # Head
    d.ellipse([34, 20, 94, 76], fill="#C4925A", outline="#4A2C18", width=3)
    # Ears
    d.ellipse([24, 24, 38, 42], fill="#9E6936", outline="#4A2C18", width=2)
    d.ellipse([90, 24, 104, 42], fill="#9E6936", outline="#4A2C18", width=2)
    # Cute closed sleepy eyes
    d.arc([46, 40, 58, 50], start=180, end=360, fill="#3A1E0B", width=3)
    d.arc([70, 40, 82, 50], start=180, end=360, fill="#3A1E0B", width=3)
    # Pink cheeks
    d.ellipse([40, 48, 52, 56], fill="#F4978E")
    d.ellipse([76, 48, 88, 56], fill="#F4978E")
    # Snout & Nose
    d.ellipse([54, 46, 74, 64], fill="#9E6936")
    d.ellipse([60, 48, 68, 54], fill="#2B1506")
    d.line([64, 54, 64, 60], fill="#2B1506", width=2)
    d.line([59, 60, 69, 60], fill="#2B1506", width=2)
    # Little feet
    d.ellipse([34, 108, 54, 122], fill="#9E6936", outline="#4A2C18", width=2)
    d.ellipse([74, 108, 94, 122], fill="#9E6936", outline="#4A2C18", width=2)
    # Cute Yuzu / Orange on Head
    d.ellipse([52, 6, 76, 28], fill="#FFA200", outline="#4A2C18", width=2)
    # Leaf on orange
    d.polygon([(64, 6), (72, 1), (68, 7)], fill="#4CAF50")
    im_capy.save(os.path.join(SPRITES_DIR, "zoo_capybara.png"))
    print("[+] Generated zoo_capybara.png")

    # 2. Panda (Chibi Giant Panda holding Bamboo)
    im_panda = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(im_panda)
    # Ears
    d.ellipse([22, 14, 46, 38], fill="#222224", outline="#111112", width=3)
    d.ellipse([82, 14, 106, 38], fill="#222224", outline="#111112", width=3)
    # Body
    d.ellipse([28, 48, 100, 116], fill="#FFFFFF", outline="#303034", width=3)
    # Black chest band
    d.ellipse([28, 50, 100, 84], fill="#28282B")
    # Head
    d.ellipse([30, 20, 98, 76], fill="#FFFFFF", outline="#303034", width=3)
    # Black eye patches
    d.ellipse([38, 34, 56, 54], fill="#28282B")
    d.ellipse([72, 34, 90, 54], fill="#28282B")
    # Cute sparkling white eyes
    d.ellipse([44, 40, 50, 48], fill="#FFFFFF")
    d.ellipse([78, 40, 84, 48], fill="#FFFFFF")
    # Cheeks
    d.ellipse([34, 54, 46, 62], fill="#FFB7B2")
    d.ellipse([82, 54, 94, 62], fill="#FFB7B2")
    # Nose
    d.ellipse([60, 48, 68, 54], fill="#222224")
    d.line([64, 54, 64, 59], fill="#222224", width=2)
    # Arms holding bamboo
    d.ellipse([24, 64, 46, 86], fill="#28282B", outline="#111112", width=2)
    d.ellipse([82, 64, 104, 86], fill="#28282B", outline="#111112", width=2)
    # Bamboo stalk
    d.line([60, 56, 72, 98], fill="#43A047", width=6)
    d.polygon([(72, 70), (84, 64), (74, 76)], fill="#66BB6A")
    # Feet
    d.ellipse([34, 104, 56, 122], fill="#28282B", outline="#111112", width=2)
    d.ellipse([72, 104, 94, 122], fill="#28282B", outline="#111112", width=2)
    im_panda.save(os.path.join(SPRITES_DIR, "zoo_panda.png"))
    print("[+] Generated zoo_panda.png")

    # 3. Penguin (Chibi Emperor Penguin with cozy blue scarf)
    im_pen = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(im_pen)
    # Body
    d.ellipse([30, 26, 98, 114], fill="#1E272C", outline="#10171B", width=3)
    # White belly
    d.ellipse([42, 44, 86, 110], fill="#FFFFFF")
    # Yellow cheeks / crest
    d.ellipse([36, 36, 48, 50], fill="#FFD54F")
    d.ellipse([80, 36, 92, 50], fill="#FFD54F")
    # Big sparkling eyes
    d.ellipse([46, 38, 56, 48], fill="#1E272C")
    d.ellipse([72, 38, 82, 48], fill="#1E272C")
    d.ellipse([48, 40, 52, 44], fill="#FFFFFF")
    d.ellipse([74, 40, 78, 44], fill="#FFFFFF")
    # Orange beak
    d.polygon([(64, 44), (56, 52), (72, 52)], fill="#FF9800", outline="#E65100")
    # Flippers
    d.ellipse([22, 52, 38, 88], fill="#1E272C", outline="#10171B", width=2)
    d.ellipse([90, 52, 106, 88], fill="#1E272C", outline="#10171B", width=2)
    # Cozy Scarf
    d.rectangle([40, 56, 88, 66], fill="#00BCD4", outline="#00838F", width=2)
    d.rectangle([70, 66, 82, 86], fill="#00BCD4", outline="#00838F", width=2)
    # Orange webbed feet
    d.ellipse([40, 110, 58, 122], fill="#FFA726", outline="#E65100", width=2)
    d.ellipse([70, 110, 88, 122], fill="#FFA726", outline="#E65100", width=2)
    im_pen.save(os.path.join(SPRITES_DIR, "zoo_penguin.png"))
    print("[+] Generated zoo_penguin.png")

    # 4. Giraffe (Chibi Baby Giraffe with cute spots)
    im_gir = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(im_gir)
    # Body
    d.ellipse([36, 68, 92, 116], fill="#FFCA28", outline="#8D6E63", width=3)
    # Long cute neck
    d.rectangle([54, 40, 74, 76], fill="#FFCA28", outline="#8D6E63", width=2)
    # Head
    d.ellipse([42, 18, 86, 52], fill="#FFCA28", outline="#8D6E63", width=3)
    # Horns (Ossicones)
    d.line([52, 10, 52, 20], fill="#6D4C41", width=3)
    d.ellipse([49, 6, 55, 12], fill="#4E342E")
    d.line([76, 10, 76, 20], fill="#6D4C41", width=3)
    d.ellipse([73, 6, 79, 12], fill="#4E342E")
    # Ears
    d.ellipse([32, 22, 44, 32], fill="#FFD54F", outline="#6D4C41", width=2)
    d.ellipse([84, 22, 96, 32], fill="#FFD54F", outline="#6D4C41", width=2)
    # Snout
    d.ellipse([50, 36, 78, 52], fill="#FFE082", outline="#8D6E63", width=2)
    d.ellipse([58, 42, 62, 46], fill="#6D4C41")
    d.ellipse([66, 42, 70, 46], fill="#6D4C41")
    # Big sparkling eyes
    d.ellipse([50, 26, 58, 36], fill="#3E2723")
    d.ellipse([70, 26, 78, 36], fill="#3E2723")
    d.ellipse([52, 28, 55, 31], fill="#FFFFFF")
    d.ellipse([72, 28, 75, 31], fill="#FFFFFF")
    # Brown Giraffe Spots
    spots = [(60, 48), (62, 62), (48, 80), (74, 82), (58, 96), (82, 98)]
    for sx, sy in spots:
        d.ellipse([sx-5, sy-4, sx+5, sy+4], fill="#A16207")
    # Little legs
    d.rectangle([44, 108, 52, 122], fill="#FFCA28", outline="#8D6E63", width=2)
    d.rectangle([76, 108, 84, 122], fill="#FFCA28", outline="#8D6E63", width=2)
    im_gir.save(os.path.join(SPRITES_DIR, "zoo_giraffe.png"))
    print("[+] Generated zoo_giraffe.png")

    # 5. Puzzle Piece 🧩
    im_puz = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(im_puz)
    # Rounded puzzle base
    d.rounded_rectangle([12, 12, 52, 52], radius=6, fill="#3B82F6", outline="#1D4ED8", width=3)
    # Top knob
    d.ellipse([26, 4, 38, 18], fill="#3B82F6", outline="#1D4ED8", width=2)
    d.rectangle([27, 10, 37, 15], fill="#3B82F6")
    # Right knob
    d.ellipse([46, 26, 60, 38], fill="#3B82F6", outline="#1D4ED8", width=2)
    d.rectangle([50, 27, 54, 37], fill="#3B82F6")
    # Bottom indentation
    d.ellipse([26, 46, 38, 58], fill="#00000000")
    # Left indentation
    d.ellipse([6, 26, 18, 38], fill="#00000000")
    # Gloss highlight
    d.line([16, 16, 48, 16], fill="#93C5FD", width=2)
    im_puz.save(os.path.join(SPRITES_DIR, "puzzle_piece.png"))
    print("[+] Generated puzzle_piece.png")

if __name__ == "__main__":
    slice_homezoo()
    slice_zoo_products()
    generate_chibi_animals()
    print("Done slicing and generating zoo assets!")
