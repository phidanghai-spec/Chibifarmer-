#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
tools/generate_steamboat_and_beehive_sprites.py
Creates 5 Chibi sprites with 100% transparent RGBA backgrounds:
1. river_dock.png (96x96)
2. steamboat_chibi.png (96x96)
3. beehive_tree.png (64x64)
4. bee_chibi.png (32x32)
5. item_honey.png (64x64)
"""

import math
from PIL import Image, ImageDraw, ImageFilter

def create_river_dock() -> Image.Image:
    img = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Soft water shadow
    draw.ellipse([8, 64, 88, 88], fill=(20, 50, 75, 75))

    # 2. Four heavy wooden pilings (posts) in water
    piling_col = (100, 68, 38, 255)
    piling_dark = (68, 44, 22, 255)
    piling_hi = (135, 95, 55, 255)
    pilings = [(14, 38, 22, 82), (36, 42, 44, 84), (58, 42, 66, 84), (78, 38, 86, 82)]
    for x0, y0, x1, y1 in pilings:
        draw.rectangle([x0, y0, x1, y1], fill=piling_col)
        draw.line([x0, y0, x0, y1], fill=piling_dark, width=1)
        draw.line([x1, y0, x1, y1], fill=piling_hi, width=1)
        # piling top cap
        draw.ellipse([x0, y0 - 3, x1, y0 + 3], fill=piling_hi, outline=piling_dark)

    # 3. Wooden deck planks (horizontal walkway with perspective)
    deck_wood = (195, 145, 95, 255)
    deck_wood_light = (220, 175, 120, 255)
    deck_wood_dark = (120, 80, 45, 255)
    
    # Outer pier base
    draw.rounded_rectangle([10, 28, 86, 56], radius=6, fill=deck_wood, outline=deck_wood_dark, width=2)

    # Individual horizontal planks
    for y in range(32, 54, 5):
        draw.line([12, y, 84, y], fill=deck_wood_dark, width=1)
        draw.line([12, y + 1, 84, y + 1], fill=deck_wood_light, width=1)

    # 4. Mooring bollards (cọc buộc dây) & Rope
    bollard_col = (75, 75, 80, 255)
    bollard_hi = (120, 120, 130, 255)
    draw.rounded_rectangle([20, 22, 28, 36], radius=3, fill=bollard_col, outline=(40, 40, 45, 255), width=1)
    draw.rounded_rectangle([68, 22, 76, 36], radius=3, fill=bollard_col, outline=(40, 40, 45, 255), width=1)

    # Ropes coiled around bollard
    rope_col = (210, 180, 120, 255)
    draw.arc([16, 26, 32, 38], 0, 360, fill=rope_col, width=2)
    draw.line([28, 30, 48, 38], fill=rope_col, width=2)

    # 5. Red-and-white Lifebuoy on left post
    buoy_cx, buoy_cy, buoy_r = 21, 60, 11
    draw.ellipse([buoy_cx - buoy_r, buoy_cy - buoy_r, buoy_cx + buoy_r, buoy_cy + buoy_r], fill=(235, 65, 50, 255), outline=(160, 30, 20, 255), width=2)
    # White quarters
    draw.chord([buoy_cx - buoy_r, buoy_cy - buoy_r, buoy_cx + buoy_r, buoy_cy + buoy_r], 45, 135, fill=(245, 245, 250, 255))
    draw.chord([buoy_cx - buoy_r, buoy_cy - buoy_r, buoy_cx + buoy_r, buoy_cy + buoy_r], 225, 315, fill=(245, 245, 250, 255))
    # Inner hole
    inner_r = 5
    draw.ellipse([buoy_cx - inner_r, buoy_cy - inner_r, buoy_cx + inner_r, buoy_cy + inner_r], fill=(20, 50, 75, 75), outline=(160, 30, 20, 255), width=1)

    return img

def create_steamboat_chibi() -> Image.Image:
    img = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Water shadow
    draw.ellipse([8, 68, 88, 86], fill=(15, 45, 70, 70))

    # 2. Hull (Wooden Boat Body)
    hull_white = (250, 245, 235, 255)
    hull_red = (220, 55, 45, 255)
    hull_dark = (100, 40, 30, 255)
    hull_gold = (235, 175, 45, 255)

    # Lower red hull
    hull_pts = [(14, 56), (82, 56), (74, 76), (22, 76)]
    draw.polygon(hull_pts, fill=hull_red, outline=hull_dark)

    # Upper white deck hull
    upper_hull_pts = [(10, 44), (86, 44), (82, 56), (14, 56)]
    draw.polygon(upper_hull_pts, fill=hull_white, outline=hull_dark)
    draw.line([(10, 44), (86, 44)], fill=hull_gold, width=2)

    # 3. Cabin (Nhà lái)
    cabin_wood = (230, 190, 140, 255)
    cabin_dark = (110, 75, 40, 255)
    draw.rounded_rectangle([24, 26, 72, 44], radius=4, fill=cabin_wood, outline=cabin_dark, width=2)

    # Round Porthole Windows
    for wx in [34, 48, 62]:
        draw.ellipse([wx - 4, 31, wx + 4, 39], fill=(130, 210, 245, 255), outline=hull_gold, width=2)
        draw.arc([wx - 3, 32, wx + 1, 36], 180, 270, fill=(255, 255, 255, 255), width=1)

    # 4. Striped Sun Canopy (Mái che vàng - trắng)
    canopy_yellow = (250, 195, 35, 255)
    canopy_white = (255, 255, 250, 255)
    draw.rounded_rectangle([18, 18, 78, 28], radius=3, fill=canopy_yellow, outline=(140, 95, 20, 255), width=1)
    # Stripes
    for sx in [26, 38, 50, 62]:
        draw.rectangle([sx, 18, sx + 5, 27], fill=canopy_white)
    # Scalloped valance fringe
    for fx in range(21, 76, 7):
        draw.chord([fx - 3, 26, fx + 4, 31], 0, 180, fill=canopy_yellow, outline=(140, 95, 20, 255))

    # 5. Smokestack (Ống khói hơi nước)
    stack_col = (55, 55, 60, 255)
    stack_rim = (225, 60, 45, 255)
    draw.rectangle([43, 6, 53, 19], fill=stack_col, outline=(30, 30, 35, 255), width=1)
    draw.rectangle([41, 5, 55, 9], fill=stack_rim, outline=(30, 30, 35, 255), width=1)

    # Puffs of white steam
    draw.ellipse([42, -2, 54, 6], fill=(250, 250, 255, 210))
    draw.ellipse([48, -7, 62, 3], fill=(250, 250, 255, 180))

    # 6. Side Paddle Wheel (Bánh guồng nước bên hông)
    wheel_cx, wheel_cy, wheel_r = 48, 62, 13
    draw.ellipse([wheel_cx - wheel_r, wheel_cy - wheel_r, wheel_cx + wheel_r, wheel_cy + wheel_r], fill=(160, 105, 55, 255), outline=(90, 50, 25, 255), width=2)
    # Spokes
    for a in range(0, 180, 45):
        rad = math.radians(a)
        dx, dy = int(math.cos(rad) * 11), int(math.sin(rad) * 11)
        draw.line([wheel_cx - dx, wheel_cy - dy, wheel_cx + dx, wheel_cy + dy], fill=(90, 50, 25, 255), width=2)
    # Hub
    draw.ellipse([wheel_cx - 4, wheel_cy - 4, wheel_cx + 4, wheel_cy + 4], fill=hull_gold, outline=(90, 50, 25, 255), width=1)

    # 7. Bow Anchor & Flag
    draw.polygon([(82, 16), (92, 20), (82, 24)], fill=hull_red, outline=hull_dark)

    return img

def create_beehive_tree() -> Image.Image:
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Soft shadow
    draw.ellipse([12, 52, 52, 62], fill=(20, 40, 15, 60))

    # 2. Tree Trunk & Branch
    trunk_col = (115, 75, 42, 255)
    trunk_dark = (75, 45, 22, 255)
    trunk_hi = (150, 105, 60, 255)
    # Trunk
    draw.polygon([(28, 38), (36, 38), (38, 56), (26, 56)], fill=trunk_col, outline=trunk_dark)
    # Sturdy right branch supporting beehive
    draw.polygon([(34, 38), (48, 32), (48, 36), (34, 42)], fill=trunk_col, outline=trunk_dark)

    # 3. Lush Green Canopy (cozy layered clouds)
    leaf_dark = (48, 120, 48, 255)
    leaf_mid = (76, 175, 65, 255)
    leaf_light = (120, 215, 80, 255)

    canopy_bubbles = [
        (32, 22, 22), (20, 26, 14), (44, 26, 14), (24, 16, 13), (40, 16, 13), (32, 12, 12)
    ]
    # Dark under-layer
    for cx, cy, r in canopy_bubbles:
        draw.ellipse([cx - r - 1, cy - r + 1, cx + r + 1, cy + r + 3], fill=leaf_dark)
    # Mid-layer
    for cx, cy, r in canopy_bubbles:
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=leaf_mid)
    # Highlights on top
    for cx, cy, r in canopy_bubbles:
        draw.ellipse([cx - r + 2, cy - r + 1, cx + r - 3, cy + r - 4], fill=leaf_light)

    # Small flowers on foliage
    flower_pts = [(18, 18), (30, 10), (44, 18), (26, 28)]
    for fx, fy in flower_pts:
        draw.ellipse([fx - 2, fy - 2, fx + 2, fy + 2], fill=(255, 240, 130, 255))
        draw.ellipse([fx - 1, fy - 1, fx + 1, fy + 1], fill=(255, 140, 40, 255))

    # 4. Honey Beehive hanging from right branch (Tổ ong vàng cam óng ánh)
    hive_cx, hive_cy = 44, 40
    hive_dark = (175, 95, 15, 255)
    hive_gold = (245, 175, 30, 255)
    hive_light = (255, 220, 80, 255)

    # Hanging string/stem
    draw.line([hive_cx, 34, hive_cx, 37], fill=trunk_dark, width=2)

    # Tiered oval hive layers
    tiers = [
        (hive_cy - 4, 4, 3),
        (hive_cy - 1, 6, 3),
        (hive_cy + 2, 7, 3),
        (hive_cy + 5, 5, 3),
        (hive_cy + 7, 3, 2),
    ]
    for ty, rx, ry in tiers:
        draw.ellipse([hive_cx - rx, ty - ry, hive_cx + rx, ty + ry], fill=hive_gold, outline=hive_dark, width=1)
        draw.arc([hive_cx - rx + 1, ty - ry + 1, hive_cx + rx - 2, ty + ry - 1], 180, 320, fill=hive_light, width=1)

    # Entrance hole
    draw.ellipse([hive_cx - 2, hive_cy + 2, hive_cx + 2, hive_cy + 5], fill=(60, 30, 10, 255))

    # Tiny golden honey drop dripping
    draw.ellipse([hive_cx - 1, hive_cy + 8, hive_cx + 1, hive_cy + 11], fill=(255, 205, 40, 255))

    return img

def create_bee_chibi() -> Image.Image:
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Soft shadow
    draw.ellipse([8, 23, 24, 29], fill=(25, 40, 20, 60))

    # 2. Translucent Wings (Flapping sky blue wings)
    wing_fill = (220, 245, 255, 190)
    wing_line = (140, 190, 230, 240)
    # Left wing
    draw.ellipse([9, 4, 17, 16], fill=wing_fill, outline=wing_line, width=1)
    # Right wing
    draw.ellipse([14, 3, 23, 15], fill=wing_fill, outline=wing_line, width=1)

    # 3. Chubby Oval Bee Body
    body_cx, body_cy = 16, 17
    draw.ellipse([7, 10, 25, 24], fill=(250, 195, 35, 255), outline=(90, 50, 15, 255), width=1)

    # Black stripes
    stripe_col = (45, 30, 20, 255)
    draw.rectangle([13, 11, 15, 23], fill=stripe_col)
    draw.rectangle([19, 12, 21, 22], fill=stripe_col)

    # Tiny stinger
    draw.polygon([(6, 17), (9, 15), (9, 19)], fill=stripe_col)

    # 4. Cute Chibi Face
    # Big eye
    draw.ellipse([21, 14, 24, 18], fill=(30, 20, 15, 255))
    draw.ellipse([22, 14, 23, 16], fill=(255, 255, 255, 255))
    # Rosy cheek
    draw.ellipse([20, 18, 23, 20], fill=(255, 130, 130, 190))

    # 5. Tiny curled antenna
    draw.line([(22, 11), (25, 8)], fill=stripe_col, width=1)
    draw.ellipse([24, 7, 26, 9], fill=stripe_col)

    return img

def create_item_honey() -> Image.Image:
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Shadow
    draw.ellipse([12, 50, 52, 60], fill=(30, 30, 30, 60))

    # 2. Glass Jar Body (Hũ thủy tinh chứa mật vàng)
    jar_gold = (245, 170, 25, 255)
    jar_gold_dark = (210, 130, 15, 255)
    jar_gold_light = (255, 225, 75, 255)
    glass_rim = (180, 215, 235, 255)

    # Honey filling inside
    draw.rounded_rectangle([16, 22, 48, 52], radius=10, fill=jar_gold, outline=jar_gold_dark, width=2)
    # Highlights and depth
    draw.rounded_rectangle([18, 24, 46, 50], radius=8, fill=None, outline=jar_gold_light, width=1)
    draw.ellipse([20, 24, 44, 32], fill=jar_gold_light)

    # Glass reflection streak on left
    draw.line([(20, 28), (20, 46)], fill=(255, 255, 255, 180), width=2)

    # 3. Cute Honeycomb Stamp on front
    draw.polygon([(32, 33), (37, 36), (37, 42), (32, 45), (27, 42), (27, 36)], fill=(255, 235, 130, 255), outline=jar_gold_dark, width=1)
    draw.text((30, 34), "🍯", fill=(100, 60, 20, 255))

    # 4. Red-and-White Checkered Cloth Lid (Nắp vải caro đỏ)
    cloth_red = (225, 55, 45, 255)
    cloth_white = (250, 245, 240, 255)
    draw.rounded_rectangle([14, 14, 50, 22], radius=4, fill=cloth_red, outline=(140, 30, 25, 255), width=1)
    # Checkered pattern
    for cx in range(16, 48, 6):
        draw.rectangle([cx, 15, cx + 3, 21], fill=cloth_white)
    # Scalloped skirt of cloth
    for sx in range(16, 48, 5):
        draw.chord([sx - 2, 20, sx + 4, 25], 0, 180, fill=cloth_red, outline=(140, 30, 25, 255))

    # Rustic Twine Ribbon (Dây thừng buộc nắp có nơ)
    twine_col = (190, 150, 95, 255)
    draw.line([(14, 21), (50, 21)], fill=twine_col, width=2)
    draw.ellipse([46, 19, 52, 24], fill=None, outline=twine_col, width=2)
    draw.ellipse([48, 22, 54, 27], fill=None, outline=twine_col, width=2)

    # 5. Wooden Honey Dipper (Que lấy mật bằng gỗ có giọt mật vàng)
    dipper_wood = (185, 130, 75, 255)
    dipper_dark = (115, 75, 35, 255)
    # Handle leaning at 45 degrees
    draw.line([(42, 45), (58, 20)], fill=dipper_wood, width=3)
    draw.line([(43, 44), (57, 21)], fill=dipper_dark, width=1)
    # Grooved spiral head
    for offset in [0, 3, 6]:
        hx, hy = 42 + offset, 45 - offset * 1.4
        draw.ellipse([hx - 3, hy - 3, hx + 3, hy + 3], fill=(235, 160, 30, 255), outline=dipper_dark, width=1)
    # Golden drop falling from dipper
    draw.ellipse([39, 48, 43, 53], fill=(255, 215, 45, 255), outline=jar_gold_dark, width=1)

    return img

def main():
    import os
    out_dir = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "assets", "sprites"))
    os.makedirs(out_dir, exist_ok=True)

    dock = create_river_dock()
    dock.save(os.path.join(out_dir, "river_dock.png"), "PNG")
    print(f"Created {dock.size} -> assets/sprites/river_dock.png")

    boat = create_steamboat_chibi()
    boat.save(os.path.join(out_dir, "steamboat_chibi.png"), "PNG")
    print(f"Created {boat.size} -> assets/sprites/steamboat_chibi.png")

    tree = create_beehive_tree()
    tree.save(os.path.join(out_dir, "beehive_tree.png"), "PNG")
    print(f"Created {tree.size} -> assets/sprites/beehive_tree.png")

    bee = create_bee_chibi()
    bee.save(os.path.join(out_dir, "bee_chibi.png"), "PNG")
    print(f"Created {bee.size} -> assets/sprites/bee_chibi.png")

    honey = create_item_honey()
    honey.save(os.path.join(out_dir, "item_honey.png"), "PNG")
    print(f"Created {honey.size} -> assets/sprites/item_honey.png")

if __name__ == "__main__":
    main()
