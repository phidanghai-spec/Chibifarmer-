#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Modular Chibi Avatar Outfits & Held Tools Composer (tools/build_modular_avatar_outfits.py)
------------------------------------------------------------------------------------------
Generates:
1. 4 Male (Minh) 2.5D Chibi Outfit Sprites (256x256 RGBA, wheat removed from hand):
   - avatar_male_overalls.png
   - avatar_male_floral.png
   - avatar_male_baker.png
   - avatar_male_carpenter.png
2. 4 Female (Mai) 2.5D Chibi Outfit Sprites (256x256 RGBA, twin braids, eyelashes, A-line dresses):
   - avatar_female_overalls.png
   - avatar_female_dress.png
   - avatar_female_baker.png
   - avatar_female_carpenter.png
3. 2 Crisp 2.5D Chibi Held Tools (128x128 RGBA, grip-aligned):
   - tool_sickle_chibi.png
   - tool_fishing_rod_chibi.png
4. 3 Construction Material Icons (128x128 RGBA):
   - mat_plank.png
   - mat_bolt.png
   - mat_brick.png
"""

import os
import math
import numpy as np
from PIL import Image, ImageDraw

ROOT_DIR = os.path.normpath(os.path.join(os.path.dirname(__file__), ".."))
SPRITES_DIR = os.path.join(ROOT_DIR, "assets", "sprites")
BACKUP_DIR = os.path.join(ROOT_DIR, "assets", "_sprite_backups")

OUTLINE_BROWN = (74, 42, 24, 255)


def load_clean_male_base() -> Image.Image:
    """Loads the original 2.5D painted avatar_male_overalls and cleanly removes the wheat stalk."""
    orig_path = os.path.join(BACKUP_DIR, "avatar_male_overalls_orig.png")
    if not os.path.exists(orig_path):
        orig_path = os.path.join(SPRITES_DIR, "avatar_male_overalls.png")

    img = Image.open(orig_path).convert("RGBA")
    arr = np.array(img)

    # 1. Remove upper wheat ear & stem above the raised right fist (y=88..129, x=54..82)
    for y in range(88, 130):
        for x in range(54, 83):
            arr[y, x] = (0, 0, 0, 0)

    # Restore clean dark-brown outline at top of fist where stem exited (y=130..131, x=73..77)
    for x in range(73, 78):
        arr[130, x] = (68, 34, 18, 255)
        arr[131, x] = (92, 50, 28, 255)

    # 2. Remove lower wheat stem sticking out below the closed fist (y=150..162, x=76..81)
    for y in range(150, 163):
        x_limit = 81 if y <= 156 else 82
        for x in range(76, x_limit):
            r, g, b, a = arr[y, x]
            if a > 0:
                if x <= 80 or (int(r) > int(g) and int(b) < 85):
                    arr[y, x] = (0, 0, 0, 0)

    # 3. Clean any yellow stem sliver inside bottom-right of fist (y=144..151, x=76..81)
    for y in range(144, 152):
        for x in range(76, 82):
            r, g, b, a = arr[y, x]
            if a > 80 and (int(g) - int(b)) > 52:
                if y >= 149 or x >= 79:
                    arr[y, x] = (74, 36, 20, 255)
                else:
                    arr[y, x] = (246, 194, 162, 255)

    # Restore clean bottom outline of fist at y=150, x=75..78
    for x in range(75, 79):
        if arr[149, x, 3] > 100:
            arr[150, x] = (68, 34, 18, 255)

    return Image.fromarray(arr, mode="RGBA")


def recolor_masked_region(
    arr: np.ndarray,
    mask: np.ndarray,
    target_rgb: tuple,
    contrast: float = 1.0,
    brightness_offset: float = 0.0
) -> None:
    """Recolors a boolean mask in-place while preserving 2.5D hand-painted shading & luminance."""
    if not np.any(mask):
        return
    r = arr[:, :, 0].astype(np.float32)
    g = arr[:, :, 1].astype(np.float32)
    b = arr[:, :, 2].astype(np.float32)

    lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
    mean_lum = float(np.mean(lum[mask]))
    if mean_lum < 0.05:
        mean_lum = 0.5

    shade = 1.0 + (lum - mean_lum) * contrast * 1.45 + brightness_offset
    shade = np.clip(shade, 0.35, 1.45)

    arr[mask, 0] = np.clip(target_rgb[0] * shade[mask], 0, 255).astype(np.uint8)
    arr[mask, 1] = np.clip(target_rgb[1] * shade[mask], 0, 255).astype(np.uint8)
    arr[mask, 2] = np.clip(target_rgb[2] * shade[mask], 0, 255).astype(np.uint8)


def get_clothing_masks(arr: np.ndarray) -> dict:
    """Extracts clean boolean masks for denim overalls, shirt sleeves, hat band, hat crown, socks, and boots."""
    r = arr[:, :, 0].astype(np.float32)
    g = arr[:, :, 1].astype(np.float32)
    b = arr[:, :, 2].astype(np.float32)
    a = arr[:, :, 3]
    opaque = a > 60

    yy, xx = np.mgrid[0:256, 0:256]

    # 1. Blue denim overalls (y=118..216, blue dominant)
    denim = opaque & (yy >= 118) & (yy <= 216) & (b > r + 8) & (b >= g - 4)

    bib = denim & (yy <= 172)
    pants = denim & (yy > 172)
    ankles = denim & (yy >= 203) & (yy <= 216)

    # 2. Yellow shirt (y=118..165, strictly high yellow chroma (g - b) > 62 so it NEVER touches neck/arm skin!)
    shirt = opaque & (yy >= 118) & (yy <= 165) & (xx >= 84) & ((g - b) > 62) & (~denim)

    # 3. Curved Hat ribbon band (follows exact parabolic arc of hat band y = 35.5 + 0.0065*(x-130)^2)
    band_arc_y = 35.5 + 0.0065 * ((xx - 130.0) ** 2)
    hat_band = (
        opaque
        & (xx >= 98)
        & (xx <= 173)
        & (np.abs(yy - band_arc_y) <= 5.2)
        & (r >= 105)
        & (r <= 190)
        & (g >= 55)
        & (g <= 120)
        & ((r - g) > 32)
    )

    # 4. Upper hat dome above band
    hat_dome = opaque & (yy >= 15) & (yy < band_arc_y - 4.0) & (xx >= 98) & (xx <= 172) & ((r - b) > 45)

    # 5. Boots (y=213..248)
    boots = opaque & (yy >= 213) & (r > 95) & (g > 50) & (b > 25) & (~denim)

    return {
        "denim": denim,
        "bib": bib,
        "pants": pants,
        "ankles": ankles,
        "shirt": shirt,
        "hat_band": hat_band,
        "hat_dome": hat_dome,
        "boots": boots,
    }


def draw_flower_blossom(
    draw: ImageDraw.ImageDraw,
    cx: float,
    cy: float,
    radius: float,
    petal_col: tuple,
    center_col: tuple = (255, 215, 70, 255)
) -> None:
    """Draws a cute 5-petal 2.5D Chibi flower with soft brown outline."""
    for i in range(5):
        angle = i * (2.0 * math.pi / 5.0) - math.pi / 2.0
        px = cx + math.cos(angle) * (radius * 0.68)
        py = cy + math.sin(angle) * (radius * 0.68)
        pr = radius * 0.55
        draw.ellipse([px - pr - 1.2, py - pr - 1.2, px + pr + 1.2, py + pr + 1.2], fill=OUTLINE_BROWN)
    for i in range(5):
        angle = i * (2.0 * math.pi / 5.0) - math.pi / 2.0
        px = cx + math.cos(angle) * (radius * 0.68)
        py = cy + math.sin(angle) * (radius * 0.68)
        pr = radius * 0.48
        draw.ellipse([px - pr, py - pr, px + pr, py + pr], fill=petal_col)
    cr = radius * 0.36
    draw.ellipse([cx - cr, cy - cr, cx + cr, cy + cr], fill=center_col)


def overlay_supersampled(base_img: Image.Image, draw_fn) -> Image.Image:
    """Runs draw_fn on a 4x supersampled (1024x1024) canvas and composites onto base_img (256x256)."""
    ss = 4
    w, h = base_img.size
    layer = Image.new("RGBA", (w * ss, h * ss), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw_fn(draw, ss)
    layer_small = layer.resize((w, h), Image.Resampling.LANCZOS)
    return Image.alpha_composite(base_img, layer_small)


def build_male_outfits(clean_base: Image.Image) -> None:
    # 1. avatar_male_overalls.png (Classic Blue Denim Overalls + Yellow Shirt + Straw Hat)
    out_overalls = os.path.join(SPRITES_DIR, "avatar_male_overalls.png")
    clean_base.save(out_overalls, "PNG")
    print("[Composer] Saved avatar_male_overalls.png")

    # 2. avatar_male_floral.png (Festive Meadow Vest + Cream Tunic + Floral Garland Hat)
    arr_floral = np.array(clean_base).copy()
    masks = get_clothing_masks(arr_floral)
    recolor_masked_region(arr_floral, masks["shirt"], (252, 240, 210), contrast=0.9, brightness_offset=0.06)
    recolor_masked_region(arr_floral, masks["bib"], (212, 88, 72), contrast=1.05, brightness_offset=0.02)
    recolor_masked_region(arr_floral, masks["pants"], (96, 134, 92), contrast=1.0, brightness_offset=0.0)
    recolor_masked_region(arr_floral, masks["hat_band"], (198, 68, 62), contrast=1.0, brightness_offset=0.04)
    img_floral = Image.fromarray(arr_floral, "RGBA")

    def draw_male_floral_details(draw: ImageDraw.ImageDraw, s: int) -> None:
        leaves = [(108, 41), (124, 38), (142, 38), (158, 42)]
        for lx, ly in leaves:
            draw.ellipse([(lx - 5) * s, (ly - 3) * s, (lx + 5) * s, (ly + 3) * s], fill=(106, 176, 88, 255), outline=OUTLINE_BROWN, width=s)
        draw_flower_blossom(draw, 115 * s, 39 * s, 6.5 * s, (255, 245, 248, 255))
        draw_flower_blossom(draw, 133 * s, 37 * s, 7.5 * s, (255, 182, 198, 255))
        draw_flower_blossom(draw, 151 * s, 40 * s, 6.5 * s, (255, 238, 150, 255))
        draw_flower_blossom(draw, 126 * s, 151 * s, 5.5 * s, (255, 242, 200, 255))

    img_floral = overlay_supersampled(img_floral, draw_male_floral_details)
    img_floral.save(os.path.join(SPRITES_DIR, "avatar_male_floral.png"), "PNG")
    print("[Composer] Saved avatar_male_floral.png")

    # 3. avatar_male_baker.png (Cozy Artisan Baker: Cream Chef Apron + Red Neckerchief + White Chef Toque)
    arr_baker = np.array(clean_base).copy()
    masks = get_clothing_masks(arr_baker)
    recolor_masked_region(arr_baker, masks["shirt"], (252, 246, 238), contrast=0.85, brightness_offset=0.08)
    recolor_masked_region(arr_baker, masks["bib"], (248, 238, 222), contrast=0.85, brightness_offset=0.12)
    recolor_masked_region(arr_baker, masks["pants"], (112, 84, 68), contrast=1.0, brightness_offset=-0.04)
    recolor_masked_region(arr_baker, masks["hat_dome"], (252, 248, 242), contrast=0.80, brightness_offset=0.14)
    recolor_masked_region(arr_baker, masks["hat_band"], (214, 72, 64), contrast=1.0, brightness_offset=0.05)
    img_baker = Image.fromarray(arr_baker, "RGBA")

    def draw_male_baker_details(draw: ImageDraw.ImageDraw, s: int) -> None:
        # Puffy Chef Toque cloud crown on top of hat dome (x=96..170, y=8..40)
        puffs = [
            (108, 27, 15),
            (122, 19, 18),
            (140, 19, 18),
            (154, 27, 15),
            (131, 25, 17),
        ]
        for px, py, pr in puffs:
            draw.ellipse([(px - pr - 2) * s, (py - pr - 2) * s, (px + pr + 2) * s, (py + pr + 2) * s], fill=OUTLINE_BROWN)
        for px, py, pr in puffs:
            draw.ellipse([(px - pr) * s, (py - pr) * s, (px + pr) * s, (py + pr) * s], fill=(252, 248, 242, 255))
            hr = pr * 0.62
            draw.ellipse([(px - hr) * s, (py - pr * 0.78) * s, (px + hr) * s, (py - pr * 0.1) * s], fill=(255, 253, 250, 255))
        # Red Baker Neckerchief at collar (x=114..144, y=118..136)
        draw.polygon(
            [(115 * s, 120 * s), (143 * s, 120 * s), (135 * s, 134 * s), (123 * s, 134 * s)],
            fill=(218, 66, 56, 255),
            outline=OUTLINE_BROWN,
            width=int(1.8 * s),
        )
        draw.polygon([(124 * s, 130 * s), (129 * s, 130 * s), (126 * s, 141 * s), (120 * s, 139 * s)], fill=(200, 52, 44, 255), outline=OUTLINE_BROWN, width=int(1.5 * s))
        draw.polygon([(129 * s, 130 * s), (134 * s, 130 * s), (138 * s, 139 * s), (132 * s, 141 * s)], fill=(228, 76, 66, 255), outline=OUTLINE_BROWN, width=int(1.5 * s))
        # White Baker Apron Skirt (x=102..159, y=165..197)
        draw.rounded_rectangle(
            [102 * s, 165 * s, 159 * s, 197 * s],
            radius=6 * s,
            fill=(250, 243, 230, 255),
            outline=OUTLINE_BROWN,
            width=int(2.0 * s),
        )
        draw.line([(102 * s, 167 * s), (159 * s, 167 * s)], fill=OUTLINE_BROWN, width=int(2.0 * s))
        # Golden mini bread loaf icon on apron pocket
        draw.ellipse([121 * s, 175 * s, 140 * s, 187 * s], fill=(238, 168, 72, 255), outline=OUTLINE_BROWN, width=int(1.5 * s))
        draw.line([(126 * s, 178 * s), (128 * s, 184 * s)], fill=OUTLINE_BROWN, width=s)
        draw.line([(132 * s, 178 * s), (134 * s, 184 * s)], fill=OUTLINE_BROWN, width=s)

    img_baker = overlay_supersampled(img_baker, draw_male_baker_details)
    img_baker.save(os.path.join(SPRITES_DIR, "avatar_male_baker.png"), "PNG")
    print("[Composer] Saved avatar_male_baker.png")

    # 4. avatar_male_carpenter.png (Master Carpenter: Leather Tool Apron + Olive Shirt + Carpenter Cap)
    arr_carp = np.array(clean_base).copy()
    masks = get_clothing_masks(arr_carp)
    recolor_masked_region(arr_carp, masks["shirt"], (118, 156, 94), contrast=1.0, brightness_offset=0.0)
    recolor_masked_region(arr_carp, masks["bib"], (182, 112, 62), contrast=1.05, brightness_offset=0.02)
    recolor_masked_region(arr_carp, masks["pants"], (72, 92, 118), contrast=1.0, brightness_offset=-0.04)
    recolor_masked_region(arr_carp, masks["hat_band"], (112, 64, 36), contrast=1.0, brightness_offset=-0.02)
    img_carp = Image.fromarray(arr_carp, "RGBA")

    def draw_male_carpenter_details(draw: ImageDraw.ImageDraw, s: int) -> None:
        draw.rounded_rectangle(
            [100 * s, 164 * s, 161 * s, 174 * s],
            radius=3 * s,
            fill=(122, 68, 34, 255),
            outline=OUTLINE_BROWN,
            width=int(1.8 * s),
        )
        draw.rounded_rectangle(
            [125 * s, 163 * s, 136 * s, 175 * s],
            radius=2 * s,
            fill=(245, 196, 78, 255),
            outline=OUTLINE_BROWN,
            width=int(1.6 * s),
        )
        draw.rounded_rectangle(
            [105 * s, 173 * s, 156 * s, 194 * s],
            radius=5 * s,
            fill=(176, 106, 56, 255),
            outline=OUTLINE_BROWN,
            width=int(1.8 * s),
        )
        draw.rectangle([114 * s, 168 * s, 121 * s, 182 * s], fill=(248, 204, 82, 255), outline=OUTLINE_BROWN, width=int(1.4 * s))
        draw.rectangle([140 * s, 167 * s, 149 * s, 174 * s], fill=(168, 178, 192, 255), outline=OUTLINE_BROWN, width=int(1.4 * s))
        draw.ellipse([125 * s, 33 * s, 137 * s, 45 * s], fill=(245, 198, 80, 255), outline=OUTLINE_BROWN, width=int(1.6 * s))

    img_carp = overlay_supersampled(img_carp, draw_male_carpenter_details)
    img_carp.save(os.path.join(SPRITES_DIR, "avatar_male_carpenter.png"), "PNG")
    print("[Composer] Saved avatar_male_carpenter.png")


def add_female_braids_and_features(
    base_img: Image.Image,
    ribbon_color: tuple,
    skirt_color: tuple,
    skirt_trim_color: tuple,
    has_floral_pattern: bool = False,
    apron_style: str = "none",
    hat_style: str = "ribbon",
) -> Image.Image:
    """
    Transforms the 2.5D character into Mai (Female) with:
    - Long twin chestnut braids + cute ribbons behind shoulders
    - Expressive feminine curved eyelashes, rosy blush, and berry smile
    - Flared A-line skirt/dress with natural white ankle socks & Mary Jane shoes
    """
    w, h = base_img.size
    ss = 4

    # 1. Under-layer for Twin Chestnut Braids (behind arms/hands so hands stay 100% clear)
    braid_layer = Image.new("RGBA", (w * ss, h * ss), (0, 0, 0, 0))
    bdraw = ImageDraw.Draw(braid_layer)

    chestnut_main = (168, 104, 58, 255)
    chestnut_hi = (198, 132, 80, 255)
    chestnut_sh = (132, 78, 42, 255)

    left_nodes = [
        (93, 95, 9.5),
        (90, 105, 9.0),
        (88, 115, 8.5),
        (87, 125, 8.0),
        (86, 135, 7.5),
        (85, 145, 6.5),
    ]
    right_nodes = [
        (162, 95, 9.5),
        (166, 105, 9.0),
        (169, 115, 8.5),
        (172, 125, 8.0),
        (174, 135, 7.5),
        (176, 145, 6.5),
    ]

    for nodes, tip_x in [(left_nodes, 84), (right_nodes, 178)]:
        for bx, by, br in nodes:
            bdraw.ellipse(
                [(bx - br - 2.2) * ss, (by - br - 2.2) * ss, (bx + br + 2.2) * ss, (by + br + 2.2) * ss],
                fill=OUTLINE_BROWN,
            )
        tx, ty = tip_x, 157
        bdraw.ellipse([(tx - 7.5) * ss, (ty - 8.5) * ss, (tx + 7.5) * ss, (ty + 8.5) * ss], fill=OUTLINE_BROWN)
        bdraw.ellipse([(tx - 5.5) * ss, (ty - 6.5) * ss, (tx + 5.5) * ss, (ty + 6.5) * ss], fill=chestnut_main)

        for i, (bx, by, br) in enumerate(nodes):
            bdraw.ellipse(
                [(bx - br) * ss, (by - br) * ss, (bx + br) * ss, (by + br) * ss],
                fill=chestnut_main if i % 2 == 0 else chestnut_sh,
            )
            hr = br * 0.55
            bdraw.ellipse(
                [(bx - hr) * ss, (by - br * 0.65) * ss, (bx + hr) * ss, (by) * ss],
                fill=chestnut_hi,
            )
            bdraw.arc(
                [(bx - br) * ss, (by - br) * ss, (bx + br) * ss, (by + br) * ss],
                start=20,
                end=160,
                fill=OUTLINE_BROWN,
                width=int(1.6 * ss),
            )

        rx, ry = tip_x, 148
        bdraw.ellipse([(rx - 7) * ss, (ry - 4.5) * ss, (rx - 1) * ss, (ry + 4.5) * ss], fill=ribbon_color, outline=OUTLINE_BROWN, width=int(1.5 * ss))
        bdraw.ellipse([(rx + 1) * ss, (ry - 4.5) * ss, (rx + 7) * ss, (ry + 4.5) * ss], fill=ribbon_color, outline=OUTLINE_BROWN, width=int(1.5 * ss))
        bdraw.ellipse([(rx - 2.5) * ss, (ry - 2.5) * ss, (rx + 2.5) * ss, (ry + 2.5) * ss], fill=ribbon_color, outline=OUTLINE_BROWN, width=int(1.4 * ss))

    braid_small = braid_layer.resize((w, h), Image.Resampling.LANCZOS)
    composed = Image.alpha_composite(braid_small, base_img)

    # 2. Over-layer for Feminine Eyelashes, Rosy Blush, A-Line Skirt/Dress & Hat Accessories
    over_layer = Image.new("RGBA", (w * ss, h * ss), (0, 0, 0, 0))
    odraw = ImageDraw.Draw(over_layer)

    # A. Cute Feminine Eyelashes on Left Eye (x=96, y=83) and Right Eye (x=161, y=83)
    odraw.line([(97 * ss, 83 * ss), (91 * ss, 79 * ss)], fill=OUTLINE_BROWN, width=int(2.4 * ss))
    odraw.line([(96 * ss, 88 * ss), (90 * ss, 86 * ss)], fill=OUTLINE_BROWN, width=int(2.0 * ss))
    odraw.line([(159 * ss, 83 * ss), (165 * ss, 79 * ss)], fill=OUTLINE_BROWN, width=int(2.4 * ss))
    odraw.line([(160 * ss, 88 * ss), (166 * ss, 86 * ss)], fill=OUTLINE_BROWN, width=int(2.0 * ss))

    # Soft pink cheek glow + rosy smile
    odraw.ellipse([89 * ss, 98 * ss, 106 * ss, 108 * ss], fill=(255, 145, 155, 95))
    odraw.ellipse([148 * ss, 98 * ss, 165 * ss, 108 * ss], fill=(255, 145, 155, 95))
    odraw.arc([118 * ss, 97 * ss, 138 * ss, 109 * ss], start=25, end=155, fill=(215, 82, 88, 220), width=int(2.2 * ss))

    # B. White Peter Pan Collar at neckline (x=114..144, y=118..128)
    odraw.chord([113 * ss, 115 * ss, 130 * ss, 129 * ss], start=10, end=175, fill=(255, 250, 244, 255), outline=OUTLINE_BROWN, width=int(1.6 * ss))
    odraw.chord([128 * ss, 115 * ss, 145 * ss, 129 * ss], start=5, end=170, fill=(255, 250, 244, 255), outline=OUTLINE_BROWN, width=int(1.6 * ss))

    # C. Flared A-Line Skirt / Dress (y=162..205, x=94..166)
    skirt_poly = [
        (102 * ss, 162 * ss),
        (158 * ss, 162 * ss),
        (166 * ss, 204 * ss),
        (94 * ss, 204 * ss),
    ]
    odraw.polygon(skirt_poly, fill=skirt_color, outline=OUTLINE_BROWN, width=int(2.2 * ss))

    center_panel = [
        (114 * ss, 164 * ss),
        (146 * ss, 164 * ss),
        (150 * ss, 202 * ss),
        (110 * ss, 202 * ss),
    ]
    hi_col = (
        min(255, skirt_color[0] + 15),
        min(255, skirt_color[1] + 15),
        min(255, skirt_color[2] + 15),
        255,
    )
    odraw.polygon(center_panel, fill=hi_col)

    for sx in range(98, 164, 8):
        odraw.ellipse(
            [(sx - 4.5) * ss, 200 * ss, (sx + 4.5) * ss, 207 * ss],
            fill=skirt_trim_color,
            outline=OUTLINE_BROWN,
            width=int(1.5 * ss),
        )
    odraw.line([(102 * ss, 162 * ss), (94 * ss, 204 * ss)], fill=OUTLINE_BROWN, width=int(2.2 * ss))
    odraw.line([(158 * ss, 162 * ss), (166 * ss, 204 * ss)], fill=OUTLINE_BROWN, width=int(2.2 * ss))
    odraw.line([(102 * ss, 162 * ss), (158 * ss, 162 * ss)], fill=OUTLINE_BROWN, width=int(2.0 * ss))

    odraw.line([(116 * ss, 168 * ss), (112 * ss, 199 * ss)], fill=(OUTLINE_BROWN[0], OUTLINE_BROWN[1], OUTLINE_BROWN[2], 140), width=int(1.4 * ss))
    odraw.line([(144 * ss, 168 * ss), (148 * ss, 199 * ss)], fill=(OUTLINE_BROWN[0], OUTLINE_BROWN[1], OUTLINE_BROWN[2], 140), width=int(1.4 * ss))

    if has_floral_pattern:
        blossoms = [
            (108, 177, 4.8, (255, 168, 188, 255)),
            (128, 173, 5.2, (255, 152, 178, 255)),
            (148, 178, 4.8, (255, 168, 188, 255)),
            (116, 191, 5.0, (255, 152, 178, 255)),
            (139, 192, 5.0, (255, 168, 188, 255)),
            (103, 193, 4.2, (255, 210, 140, 255)),
            (155, 192, 4.2, (255, 210, 140, 255)),
        ]
        for bx, by, br, bcol in blossoms:
            odraw.ellipse([(bx + 2) * ss, (by - 4) * ss, (bx + 7) * ss, (by) * ss], fill=(118, 186, 102, 255))
            draw_flower_blossom(odraw, bx * ss, by * ss, br * ss, bcol)

    if apron_style == "white_pinafore":
        odraw.rounded_rectangle(
            [110 * ss, 162 * ss, 150 * ss, 195 * ss],
            radius=8 * ss,
            fill=(255, 252, 246, 245),
            outline=OUTLINE_BROWN,
            width=int(1.8 * ss),
        )
        draw_flower_blossom(odraw, 130 * ss, 178 * ss, 5.5 * ss, (255, 168, 192, 255))
    elif apron_style == "pastry_pink":
        odraw.rounded_rectangle(
            [106 * ss, 162 * ss, 154 * ss, 196 * ss],
            radius=8 * ss,
            fill=(255, 248, 244, 255),
            outline=OUTLINE_BROWN,
            width=int(1.8 * ss),
        )
        hx, hy = 130 * ss, 179 * ss
        odraw.polygon(
            [(hx, hy + 7 * ss), (hx - 8 * ss, hy - 1 * ss), (hx - 4 * ss, hy - 6 * ss), (hx, hy - 2 * ss), (hx + 4 * ss, hy - 6 * ss), (hx + 8 * ss, hy - 1 * ss)],
            fill=(255, 142, 168, 255),
            outline=OUTLINE_BROWN,
            width=int(1.5 * ss),
        )
    elif apron_style == "carpenter_leather":
        odraw.rounded_rectangle(
            [101 * ss, 161 * ss, 159 * ss, 171 * ss],
            radius=3 * ss,
            fill=(128, 72, 38, 255),
            outline=OUTLINE_BROWN,
            width=int(1.8 * ss),
        )
        odraw.rounded_rectangle(
            [125 * ss, 160 * ss, 135 * ss, 172 * ss],
            radius=2 * ss,
            fill=(248, 202, 82, 255),
            outline=OUTLINE_BROWN,
            width=int(1.5 * ss),
        )
        odraw.rounded_rectangle(
            [108 * ss, 171 * ss, 152 * ss, 193 * ss],
            radius=5 * ss,
            fill=(196, 122, 68, 255),
            outline=OUTLINE_BROWN,
            width=int(1.8 * ss),
        )
        odraw.rectangle([116 * ss, 167 * ss, 123 * ss, 180 * ss], fill=(250, 208, 88, 255), outline=OUTLINE_BROWN, width=int(1.4 * ss))
        odraw.rectangle([138 * ss, 166 * ss, 145 * ss, 180 * ss], fill=(122, 188, 168, 255), outline=OUTLINE_BROWN, width=int(1.4 * ss))

    # D. Hat Accessories for Mai
    if hat_style == "ribbon_daisy":
        draw_flower_blossom(odraw, 152 * ss, 41 * ss, 7.5 * ss, (255, 248, 252, 255))
    elif hat_style == "floral_bonnet":
        odraw.ellipse([146 * ss, 34 * ss, 160 * ss, 45 * ss], fill=ribbon_color, outline=OUTLINE_BROWN, width=int(1.6 * ss))
        odraw.ellipse([160 * ss, 36 * ss, 172 * ss, 47 * ss], fill=ribbon_color, outline=OUTLINE_BROWN, width=int(1.6 * ss))
        draw_flower_blossom(odraw, 114 * ss, 39 * ss, 6.8 * ss, (255, 185, 204, 255))
        draw_flower_blossom(odraw, 132 * ss, 37 * ss, 7.8 * ss, (255, 248, 250, 255))
        draw_flower_blossom(odraw, 156 * ss, 41 * ss, 6.8 * ss, (255, 225, 145, 255))
    elif hat_style == "pastry_toque":
        puffs = [
            (108, 27, 15),
            (122, 19, 18),
            (140, 19, 18),
            (154, 27, 15),
            (131, 25, 17),
        ]
        for px, py, pr in puffs:
            odraw.ellipse([(px - pr - 2) * ss, (py - pr - 2) * ss, (px + pr + 2) * ss, (py + pr + 2) * ss], fill=OUTLINE_BROWN)
        for px, py, pr in puffs:
            odraw.ellipse([(px - pr) * ss, (py - pr) * ss, (px + pr) * ss, (py + pr) * ss], fill=(255, 250, 248, 255))
        draw_flower_blossom(odraw, 150 * ss, 40 * ss, 6.5 * ss, (255, 162, 188, 255))
    elif hat_style == "artisan_badge":
        odraw.ellipse([124 * ss, 33 * ss, 138 * ss, 45 * ss], fill=(255, 208, 92, 255), outline=OUTLINE_BROWN, width=int(1.6 * ss))
        draw_flower_blossom(odraw, 152 * ss, 41 * ss, 6.5 * ss, (255, 190, 145, 255))

    over_small = over_layer.resize((w, h), Image.Resampling.LANCZOS)
    return Image.alpha_composite(composed, over_small)


def build_female_outfits(clean_base: Image.Image) -> None:
    # 1. avatar_female_overalls.png
    arr_f_ov = np.array(clean_base).copy()
    masks = get_clothing_masks(arr_f_ov)
    recolor_masked_region(arr_f_ov, masks["shirt"], (255, 232, 148), contrast=0.9, brightness_offset=0.06)
    recolor_masked_region(arr_f_ov, masks["bib"], (102, 156, 208), contrast=1.0, brightness_offset=0.05)
    recolor_masked_region(arr_f_ov, masks["ankles"], (252, 248, 244), contrast=0.8, brightness_offset=0.15)
    recolor_masked_region(arr_f_ov, masks["hat_band"], (238, 118, 148), contrast=1.0, brightness_offset=0.06)
    recolor_masked_region(arr_f_ov, masks["boots"], (182, 96, 78), contrast=1.0, brightness_offset=0.02)
    img_f_ov = Image.fromarray(arr_f_ov, "RGBA")
    img_f_ov = add_female_braids_and_features(
        img_f_ov,
        ribbon_color=(242, 118, 148, 255),
        skirt_color=(96, 148, 198, 255),
        skirt_trim_color=(245, 248, 255, 255),
        has_floral_pattern=False,
        apron_style="none",
        hat_style="ribbon_daisy",
    )
    img_f_ov.save(os.path.join(SPRITES_DIR, "avatar_female_overalls.png"), "PNG")
    print("[Composer] Saved avatar_female_overalls.png")

    # 2. avatar_female_dress.png
    arr_f_dr = np.array(clean_base).copy()
    masks = get_clothing_masks(arr_f_dr)
    recolor_masked_region(arr_f_dr, masks["shirt"], (255, 224, 232), contrast=0.88, brightness_offset=0.08)
    recolor_masked_region(arr_f_dr, masks["bib"], (244, 142, 166), contrast=0.95, brightness_offset=0.06)
    recolor_masked_region(arr_f_dr, masks["ankles"], (252, 248, 244), contrast=0.8, brightness_offset=0.15)
    recolor_masked_region(arr_f_dr, masks["hat_band"], (238, 108, 138), contrast=1.0, brightness_offset=0.06)
    recolor_masked_region(arr_f_dr, masks["boots"], (188, 78, 86), contrast=1.0, brightness_offset=0.02)
    img_f_dr = Image.fromarray(arr_f_dr, "RGBA")
    img_f_dr = add_female_braids_and_features(
        img_f_dr,
        ribbon_color=(244, 108, 138, 255),
        skirt_color=(255, 236, 220, 255),
        skirt_trim_color=(255, 252, 248, 255),
        has_floral_pattern=True,
        apron_style="white_pinafore",
        hat_style="floral_bonnet",
    )
    img_f_dr.save(os.path.join(SPRITES_DIR, "avatar_female_dress.png"), "PNG")
    print("[Composer] Saved avatar_female_dress.png")

    # 3. avatar_female_baker.png
    arr_f_bk = np.array(clean_base).copy()
    masks = get_clothing_masks(arr_f_bk)
    recolor_masked_region(arr_f_bk, masks["shirt"], (222, 246, 236), contrast=0.88, brightness_offset=0.08)
    recolor_masked_region(arr_f_bk, masks["bib"], (255, 182, 198), contrast=0.92, brightness_offset=0.08)
    recolor_masked_region(arr_f_bk, masks["ankles"], (252, 248, 244), contrast=0.8, brightness_offset=0.15)
    recolor_masked_region(arr_f_bk, masks["hat_dome"], (252, 248, 244), contrast=0.80, brightness_offset=0.14)
    recolor_masked_region(arr_f_bk, masks["hat_band"], (242, 126, 154), contrast=1.0, brightness_offset=0.06)
    recolor_masked_region(arr_f_bk, masks["boots"], (156, 92, 82), contrast=1.0, brightness_offset=0.0)
    img_f_bk = Image.fromarray(arr_f_bk, "RGBA")
    img_f_bk = add_female_braids_and_features(
        img_f_bk,
        ribbon_color=(245, 128, 158, 255),
        skirt_color=(252, 178, 196, 255),
        skirt_trim_color=(255, 250, 246, 255),
        has_floral_pattern=False,
        apron_style="pastry_pink",
        hat_style="pastry_toque",
    )
    img_f_bk.save(os.path.join(SPRITES_DIR, "avatar_female_baker.png"), "PNG")
    print("[Composer] Saved avatar_female_baker.png")

    # 4. avatar_female_carpenter.png
    arr_f_cp = np.array(clean_base).copy()
    masks = get_clothing_masks(arr_f_cp)
    recolor_masked_region(arr_f_cp, masks["shirt"], (244, 156, 118), contrast=0.95, brightness_offset=0.04)
    recolor_masked_region(arr_f_cp, masks["bib"], (192, 118, 66), contrast=1.02, brightness_offset=0.02)
    recolor_masked_region(arr_f_cp, masks["ankles"], (252, 248, 244), contrast=0.8, brightness_offset=0.15)
    recolor_masked_region(arr_f_cp, masks["hat_band"], (198, 86, 64), contrast=1.0, brightness_offset=0.02)
    recolor_masked_region(arr_f_cp, masks["boots"], (142, 82, 48), contrast=1.0, brightness_offset=0.0)
    img_f_cp = Image.fromarray(arr_f_cp, "RGBA")
    img_f_cp = add_female_braids_and_features(
        img_f_cp,
        ribbon_color=(212, 92, 68, 255),
        skirt_color=(88, 132, 168, 255),
        skirt_trim_color=(238, 214, 182, 255),
        has_floral_pattern=False,
        apron_style="carpenter_leather",
        hat_style="artisan_badge",
    )
    img_f_cp.save(os.path.join(SPRITES_DIR, "avatar_female_carpenter.png"), "PNG")
    print("[Composer] Saved avatar_female_carpenter.png")


def build_held_tools() -> None:
    """Generates crisp 128x128 2.5D Chibi hand-held tools: tool_sickle_chibi & tool_fishing_rod_chibi."""
    sickle_src_path = os.path.join(SPRITES_DIR, "tool_sickle.png")
    if os.path.exists(sickle_src_path):
        src = Image.open(sickle_src_path).convert("RGBA").resize((128, 128), Image.Resampling.LANCZOS)
        ss = 4
        sparkle = Image.new("RGBA", (128 * ss, 128 * ss), (0, 0, 0, 0))
        sdraw = ImageDraw.Draw(sparkle)
        cx, cy = 32 * ss, 18 * ss
        sdraw.polygon(
            [(cx, cy - 10 * ss), (cx + 3 * ss, cy - 3 * ss), (cx + 10 * ss, cy), (cx + 3 * ss, cy + 3 * ss),
             (cx, cy + 10 * ss), (cx - 3 * ss, cy + 3 * ss), (cx - 10 * ss, cy), (cx - 3 * ss, cy - 3 * ss)],
            fill=(255, 232, 110, 255),
            outline=OUTLINE_BROWN,
            width=int(1.2 * ss),
        )
        out_sickle = Image.alpha_composite(src, sparkle.resize((128, 128), Image.Resampling.LANCZOS))
        out_sickle.save(os.path.join(SPRITES_DIR, "tool_sickle_chibi.png"), "PNG")
        print("[Composer] Saved high-detail 2.5D tool_sickle_chibi.png")

    ss = 4
    rod_canvas = Image.new("RGBA", (128 * ss, 128 * ss), (0, 0, 0, 0))
    rdraw = ImageDraw.Draw(rod_canvas)

    rdraw.line([(16 * ss, 14 * ss), (16 * ss, 94 * ss)], fill=(235, 245, 255, 230), width=int(1.6 * ss))
    rdraw.line([(15 * ss, 14 * ss), (15 * ss, 94 * ss)], fill=(90, 110, 130, 160), width=int(1.0 * ss))

    rdraw.arc([10 * ss, 90 * ss, 22 * ss, 104 * ss], start=0, end=210, fill=OUTLINE_BROWN, width=int(3.2 * ss))
    rdraw.arc([11 * ss, 91 * ss, 21 * ss, 103 * ss], start=0, end=210, fill=(245, 200, 75, 255), width=int(1.8 * ss))

    rdraw.line([(104 * ss, 110 * ss), (16 * ss, 14 * ss)], fill=OUTLINE_BROWN, width=int(9.5 * ss))
    rdraw.line([(104 * ss, 110 * ss), (16 * ss, 14 * ss)], fill=(218, 162, 78, 255), width=int(5.5 * ss))
    rdraw.line([(103 * ss, 109 * ss), (15 * ss, 13 * ss)], fill=(246, 202, 112, 255), width=int(2.2 * ss))

    for t in [0.28, 0.52, 0.76]:
        nx = int((104 * (1 - t) + 16 * t) * ss)
        ny = int((110 * (1 - t) + 14 * t) * ss)
        rdraw.ellipse([nx - 4 * ss, ny - 4 * ss, nx + 4 * ss, ny + 4 * ss], fill=(162, 104, 46, 255), outline=OUTLINE_BROWN, width=int(1.4 * ss))

    rdraw.line([(106 * ss, 112 * ss), (84 * ss, 88 * ss)], fill=OUTLINE_BROWN, width=int(13.0 * ss))
    rdraw.line([(106 * ss, 112 * ss), (84 * ss, 88 * ss)], fill=(168, 98, 52, 255), width=int(8.5 * ss))
    rdraw.line([(105 * ss, 111 * ss), (83 * ss, 87 * ss)], fill=(208, 132, 78, 255), width=int(3.5 * ss))

    rdraw.ellipse([68 * ss, 82 * ss, 88 * ss, 102 * ss], fill=(245, 194, 72, 255), outline=OUTLINE_BROWN, width=int(2.2 * ss))
    rdraw.ellipse([72 * ss, 86 * ss, 84 * ss, 98 * ss], fill=(255, 226, 128, 255), outline=OUTLINE_BROWN, width=int(1.5 * ss))
    rdraw.ellipse([76 * ss, 90 * ss, 80 * ss, 94 * ss], fill=OUTLINE_BROWN)

    bx, by, br = 16 * ss, 70 * ss, 11 * ss
    rdraw.ellipse([bx - br, by - br, bx + br, by + br], fill=(255, 248, 242, 255), outline=OUTLINE_BROWN, width=int(2.4 * ss))
    rdraw.chord([bx - br, by - br, bx + br, by + br], start=180, end=360, fill=(238, 68, 58, 255), outline=OUTLINE_BROWN, width=int(2.4 * ss))
    rdraw.ellipse([bx - 6 * ss, by - 7 * ss, bx - 1 * ss, by - 3 * ss], fill=(255, 255, 255, 230))
    rdraw.rectangle([bx - 3 * ss, by - br - 4 * ss, bx + 3 * ss, by - br + 1 * ss], fill=(245, 198, 76, 255), outline=OUTLINE_BROWN, width=int(1.5 * ss))

    rod_img = rod_canvas.resize((128, 128), Image.Resampling.LANCZOS)
    rod_img.save(os.path.join(SPRITES_DIR, "tool_fishing_rod_chibi.png"), "PNG")
    print("[Composer] Saved high-detail 2.5D tool_fishing_rod_chibi.png")


def build_material_icons() -> None:
    """Generates 3 cute 128x128 2.5D Chibi construction material icons: mat_plank, mat_bolt, mat_brick."""
    ss = 4

    c1 = Image.new("RGBA", (128 * ss, 128 * ss), (0, 0, 0, 0))
    d1 = ImageDraw.Draw(c1)
    planks = [
        (20, 68, 108, 92, (206, 138, 74, 255), (232, 168, 98, 255)),
        (16, 48, 104, 72, (218, 152, 84, 255), (242, 182, 112, 255)),
        (22, 28, 110, 52, (228, 164, 94, 255), (250, 196, 126, 255)),
    ]
    for x0, y0, x1, y1, col_main, col_hi in planks:
        d1.rounded_rectangle([x0 * ss, y0 * ss, x1 * ss, y1 * ss], radius=6 * ss, fill=col_main, outline=OUTLINE_BROWN, width=int(2.6 * ss))
        d1.rounded_rectangle([(x0 + 3) * ss, (y0 + 3) * ss, (x1 - 3) * ss, (y0 + 11) * ss], radius=4 * ss, fill=col_hi)
        d1.line([(x0 + 12) * ss, (y0 + 14) * ss, (x1 - 16) * ss, (y0 + 14) * ss], fill=(168, 104, 48, 255), width=int(1.8 * ss))
    d1.rounded_rectangle([57 * ss, 25 * ss, 71 * ss, 95 * ss], radius=4 * ss, fill=(235, 202, 142, 255), outline=OUTLINE_BROWN, width=int(2.4 * ss))
    d1.line([57 * ss, 48 * ss, 71 * ss, 52 * ss], fill=OUTLINE_BROWN, width=int(2.0 * ss))
    d1.line([57 * ss, 70 * ss, 71 * ss, 74 * ss], fill=OUTLINE_BROWN, width=int(2.0 * ss))
    d1.ellipse([82 * ss, 14 * ss, 98 * ss, 28 * ss], fill=(116, 196, 88, 255), outline=OUTLINE_BROWN, width=int(2.2 * ss))
    c1.resize((128, 128), Image.Resampling.LANCZOS).save(os.path.join(SPRITES_DIR, "mat_plank.png"), "PNG")

    c2 = Image.new("RGBA", (128 * ss, 128 * ss), (0, 0, 0, 0))
    d2 = ImageDraw.Draw(c2)
    d2.rounded_rectangle([50 * ss, 44 * ss, 78 * ss, 106 * ss], radius=6 * ss, fill=(168, 184, 204, 255), outline=OUTLINE_BROWN, width=int(2.8 * ss))
    for ty in range(56, 98, 12):
        d2.line([50 * ss, ty * ss, 78 * ss, (ty + 5) * ss], fill=OUTLINE_BROWN, width=int(2.2 * ss))
    hex_pts = [(30 * ss, 35 * ss), (44 * ss, 20 * ss), (84 * ss, 20 * ss), (98 * ss, 35 * ss), (84 * ss, 50 * ss), (44 * ss, 50 * ss)]
    d2.polygon(hex_pts, fill=(198, 212, 228, 255), outline=OUTLINE_BROWN, width=int(2.8 * ss))
    d2.ellipse([46 * ss, 25 * ss, 82 * ss, 43 * ss], fill=(232, 242, 252, 255), outline=OUTLINE_BROWN, width=int(2.0 * ss))
    d2.ellipse([72 * ss, 68 * ss, 112 * ss, 106 * ss], fill=(208, 220, 236, 255), outline=OUTLINE_BROWN, width=int(2.6 * ss))
    d2.ellipse([84 * ss, 80 * ss, 100 * ss, 94 * ss], fill=(112, 126, 144, 255), outline=OUTLINE_BROWN, width=int(2.2 * ss))
    c2.resize((128, 128), Image.Resampling.LANCZOS).save(os.path.join(SPRITES_DIR, "mat_bolt.png"), "PNG")

    c3 = Image.new("RGBA", (128 * ss, 128 * ss), (0, 0, 0, 0))
    d3 = ImageDraw.Draw(c3)
    bricks = [
        (14, 66, 68, 98, (204, 84, 62, 255), (228, 108, 84, 255)),
        (60, 66, 114, 98, (196, 78, 56, 255), (222, 102, 78, 255)),
        (34, 34, 94, 68, (216, 92, 68, 255), (242, 120, 94, 255)),
    ]
    for x0, y0, x1, y1, b_main, b_hi in bricks:
        d3.rounded_rectangle([x0 * ss, y0 * ss, x1 * ss, y1 * ss], radius=5 * ss, fill=b_main, outline=OUTLINE_BROWN, width=int(2.6 * ss))
        d3.rounded_rectangle([(x0 + 3) * ss, (y0 + 3) * ss, (x1 - 3) * ss, (y0 + 12) * ss], radius=3 * ss, fill=b_hi)
        cx1 = (x0 + x1) // 2 - 9
        cx2 = (x0 + x1) // 2 + 9
        cy_b = (y0 + y1) // 2 + 2
        d3.ellipse([(cx1 - 4) * ss, (cy_b - 4) * ss, (cx1 + 4) * ss, (cy_b + 4) * ss], fill=(148, 52, 36, 255), outline=OUTLINE_BROWN, width=int(1.6 * ss))
        d3.ellipse([(cx2 - 4) * ss, (cy_b - 4) * ss, (cx2 + 4) * ss, (cy_b + 4) * ss], fill=(148, 52, 36, 255), outline=OUTLINE_BROWN, width=int(1.6 * ss))
    c3.resize((128, 128), Image.Resampling.LANCZOS).save(os.path.join(SPRITES_DIR, "mat_brick.png"), "PNG")
    print("[Composer] Saved mat_plank.png, mat_bolt.png, mat_brick.png")


def main() -> None:
    os.makedirs(SPRITES_DIR, exist_ok=True)
    os.makedirs(BACKUP_DIR, exist_ok=True)
    clean_base = load_clean_male_base()
    build_male_outfits(clean_base)
    build_female_outfits(clean_base)
    build_held_tools()
    build_material_icons()
    print("[Composer] All 8 modular outfit sprites, 2 held tools, and 3 material icons built successfully!")


if __name__ == "__main__":
    main()
