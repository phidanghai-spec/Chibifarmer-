#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
tools/generate_paperdoll_layers.py
Tạo các lớp trang phục Paper-Doll chuẩn 128x128 (RGBA) cho Sprint 2
Tất cả các lớp khớp 100% tâm Pivot chân ở (64, 120).
"""

import os
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SPRITES_DIR = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "assets", "sprites"))
ATLAS_PATH = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "scripts", "core", "sprite_atlas_manager.gd"))

OUTLINE = (74, 44, 24, 255) # #4A2C18 warm brown

def create_canvas():
    return Image.new("RGBA", (128, 128), (0, 0, 0, 0))

# -------------------------------------------------------------
# 1. BODIES
# -------------------------------------------------------------
def make_body(tone_color, blush_color):
    img = create_canvas()
    d = ImageDraw.Draw(img)
    # Head: centered at (64, 52), radius ~26
    # Body: (52, 74) to (76, 102)
    # Legs/Feet: (50, 100) to (78, 120)
    
    # 1. Feet & Shoes
    d.ellipse([50, 110, 62, 121], fill=(130, 80, 45, 255), outline=OUTLINE, width=2)
    d.ellipse([66, 110, 78, 121], fill=(130, 80, 45, 255), outline=OUTLINE, width=2)
    
    # 2. Legs
    d.rectangle([52, 94, 60, 112], fill=tone_color, outline=OUTLINE, width=2)
    d.rectangle([68, 94, 76, 112], fill=tone_color, outline=OUTLINE, width=2)
    
    # 3. Torso
    d.rounded_rectangle([52, 72, 76, 98], radius=8, fill=tone_color, outline=OUTLINE, width=2)
    
    # 4. Arms & Hands
    d.ellipse([42, 76, 54, 94], fill=tone_color, outline=OUTLINE, width=2)
    d.ellipse([74, 76, 86, 94], fill=tone_color, outline=OUTLINE, width=2)
    
    # 5. Head
    d.ellipse([38, 26, 90, 78], fill=tone_color, outline=OUTLINE, width=3)
    
    # 6. Cheeks (Blush)
    d.ellipse([44, 58, 54, 66], fill=blush_color)
    d.ellipse([74, 58, 84, 66], fill=blush_color)
    
    # Cute smile line
    d.arc([59, 58, 69, 68], start=20, end=160, fill=OUTLINE, width=2)
    
    return img

# -------------------------------------------------------------
# 2. EYES
# -------------------------------------------------------------
def make_eyes(iris_color, eye_type="sparkle"):
    img = create_canvas()
    d = ImageDraw.Draw(img)
    
    if eye_type == "happy_arc":
        # Smiling eyes ^_^
        d.arc([46, 46, 58, 58], start=190, end=350, fill=OUTLINE, width=3)
        d.arc([70, 46, 82, 58], start=190, end=350, fill=OUTLINE, width=3)
    else:
        # Left eye sclera + iris
        d.ellipse([46, 44, 58, 58], fill=(255, 255, 255, 255), outline=OUTLINE, width=2)
        d.ellipse([48, 45, 57, 57], fill=iris_color)
        d.ellipse([49, 46, 52, 49], fill=(255, 255, 255, 255)) # Sparkle 1
        d.ellipse([54, 52, 56, 54], fill=(255, 255, 255, 220)) # Sparkle 2
        
        # Right eye sclera + iris
        d.ellipse([70, 44, 82, 58], fill=(255, 255, 255, 255), outline=OUTLINE, width=2)
        d.ellipse([71, 45, 80, 57], fill=iris_color)
        d.ellipse([72, 46, 75, 49], fill=(255, 255, 255, 255))
        d.ellipse([77, 52, 79, 54], fill=(255, 255, 255, 220))
        
        # Eyebrows
        d.arc([46, 36, 58, 44], start=200, end=340, fill=OUTLINE, width=2)
        d.arc([70, 36, 82, 44], start=200, end=340, fill=OUTLINE, width=2)
        
    return img

# -------------------------------------------------------------
# 3. HAIR
# -------------------------------------------------------------
def make_hair(hair_color, style="braid"):
    img = create_canvas()
    d = ImageDraw.Draw(img)
    
    if style == "braid":
        # Back volume
        d.ellipse([34, 20, 94, 75], fill=hair_color, outline=OUTLINE, width=2)
        # Bangs
        d.polygon([(40, 36), (54, 46), (64, 38), (74, 46), (88, 36), (64, 22)], fill=hair_color, outline=OUTLINE)
        # Left braid
        d.rounded_rectangle([32, 60, 44, 95], radius=6, fill=hair_color, outline=OUTLINE, width=2)
        d.ellipse([32, 90, 44, 102], fill=(220, 70, 60, 255), outline=OUTLINE, width=2) # Ribbon
        # Right braid
        d.rounded_rectangle([84, 60, 96, 95], radius=6, fill=hair_color, outline=OUTLINE, width=2)
        d.ellipse([84, 90, 96, 102], fill=(220, 70, 60, 255), outline=OUTLINE, width=2)
    elif style == "short":
        # Spiky / wavy short cute hair
        d.ellipse([36, 18, 92, 68], fill=hair_color, outline=OUTLINE, width=3)
        d.polygon([(36, 42), (48, 48), (56, 38), (68, 46), (78, 38), (92, 42), (64, 20)], fill=hair_color, outline=OUTLINE)
        d.ellipse([32, 38, 42, 62], fill=hair_color, outline=OUTLINE, width=2)
        d.ellipse([86, 38, 96, 62], fill=hair_color, outline=OUTLINE, width=2)
    elif style == "bun":
        # Top bun
        d.ellipse([50, 10, 78, 36], fill=hair_color, outline=OUTLINE, width=3)
        d.ellipse([35, 22, 93, 70], fill=hair_color, outline=OUTLINE, width=3)
        d.polygon([(38, 40), (52, 46), (64, 40), (76, 46), (90, 40), (64, 24)], fill=hair_color, outline=OUTLINE)
    elif style == "curly":
        # Fluffy curls
        d.ellipse([32, 18, 96, 75], fill=hair_color, outline=OUTLINE, width=3)
        for cx, cy in [(32, 45), (30, 60), (32, 75), (94, 45), (96, 60), (94, 75), (45, 18), (64, 14), (83, 18)]:
            d.ellipse([cx-10, cy-10, cx+10, cy+10], fill=hair_color, outline=OUTLINE, width=2)
        d.polygon([(40, 38), (54, 46), (64, 39), (74, 46), (88, 38), (64, 22)], fill=hair_color, outline=OUTLINE)
        
    return img

# -------------------------------------------------------------
# 4. OUTFITS
# -------------------------------------------------------------
def make_outfit(style):
    img = create_canvas()
    d = ImageDraw.Draw(img)
    
    if style == "denim":
        # White shirt sleeves
        d.ellipse([46, 74, 56, 88], fill=(255, 255, 255, 255), outline=OUTLINE, width=2)
        d.ellipse([72, 74, 82, 88], fill=(255, 255, 255, 255), outline=OUTLINE, width=2)
        # Blue Denim Overalls
        denim_blue = (65, 110, 160, 255)
        d.rounded_rectangle([52, 76, 76, 108], radius=6, fill=denim_blue, outline=OUTLINE, width=2)
        # Straps
        d.rectangle([54, 72, 59, 86], fill=denim_blue, outline=OUTLINE, width=1)
        d.rectangle([69, 72, 74, 86], fill=denim_blue, outline=OUTLINE, width=1)
        # Brass buttons
        d.ellipse([55, 84, 58, 87], fill=(220, 170, 50, 255))
        d.ellipse([70, 84, 73, 87], fill=(220, 170, 50, 255))
        # Front pocket
        d.rectangle([59, 88, 69, 96], fill=(55, 95, 145, 255), outline=OUTLINE, width=1)
    elif style == "floral":
        dress_pink = (245, 145, 165, 255)
        d.rounded_rectangle([50, 74, 78, 106], radius=6, fill=dress_pink, outline=OUTLINE, width=2)
        # White lace collar
        d.arc([56, 72, 72, 82], start=0, end=180, fill=(255, 255, 255, 255), width=3)
        # Frills
        for fx in range(51, 77, 6):
            d.ellipse([fx, 102, fx+6, 108], fill=(255, 255, 255, 255), outline=OUTLINE, width=1)
    elif style == "baker":
        # Red shirt + pure white apron
        d.ellipse([46, 74, 56, 88], fill=(215, 65, 55, 255), outline=OUTLINE, width=2)
        d.ellipse([72, 74, 82, 88], fill=(215, 65, 55, 255), outline=OUTLINE, width=2)
        d.rounded_rectangle([53, 76, 75, 108], radius=5, fill=(250, 250, 250, 255), outline=OUTLINE, width=2)
        # Apron pocket
        d.rectangle([58, 90, 70, 98], fill=(230, 230, 230, 255), outline=OUTLINE, width=1)
    elif style == "carpenter":
        # Green plaid + leather vest
        d.rounded_rectangle([52, 74, 76, 108], radius=6, fill=(160, 100, 60, 255), outline=OUTLINE, width=2)
        d.rectangle([59, 74, 69, 108], fill=(80, 140, 90, 255))
        d.rectangle([54, 92, 60, 100], fill=(130, 80, 45, 255), outline=OUTLINE, width=1)
        d.rectangle([68, 92, 74, 100], fill=(130, 80, 45, 255), outline=OUTLINE, width=1)
        
    return img

# -------------------------------------------------------------
# 5. HATS
# -------------------------------------------------------------
def make_hat(style):
    img = create_canvas()
    d = ImageDraw.Draw(img)
    
    if style == "straw":
        # Straw hat
        d.ellipse([26, 24, 102, 44], fill=(240, 210, 120, 255), outline=OUTLINE, width=2)
        d.ellipse([46, 12, 82, 34], fill=(230, 195, 105, 255), outline=OUTLINE, width=2)
        # Red ribbon band
        d.rectangle([48, 26, 80, 31], fill=(225, 55, 55, 255))
    elif style == "chef":
        # Chef toque
        d.ellipse([42, 6, 86, 32], fill=(255, 255, 255, 255), outline=OUTLINE, width=2)
        for cx in [48, 64, 80]:
            d.ellipse([cx-12, 4, cx+12, 26], fill=(255, 255, 255, 255), outline=OUTLINE, width=2)
        d.rectangle([48, 24, 80, 36], fill=(245, 245, 245, 255), outline=OUTLINE, width=2)
    elif style == "postman":
        # Royal blue peaked cap
        d.ellipse([42, 16, 86, 38], fill=(45, 90, 175, 255), outline=OUTLINE, width=2)
        d.polygon([(38, 34), (90, 34), (84, 40), (44, 40)], fill=(30, 30, 40, 255), outline=OUTLINE)
        # Gold badge
        d.ellipse([61, 24, 67, 30], fill=(245, 200, 60, 255))
    elif style == "none":
        pass # Empty transparent
        
    return img

# -------------------------------------------------------------
# 6. TOOLS
# -------------------------------------------------------------
def make_tool(style):
    img = create_canvas()
    d = ImageDraw.Draw(img)
    
    if style == "sickle":
        # Handle at hand (80, 85)
        d.rectangle([80, 80, 86, 102], fill=(150, 95, 50, 255), outline=OUTLINE, width=2)
        # Curved silver blade
        d.arc([75, 56, 105, 86], start=180, end=350, fill=(210, 220, 230, 255), width=6)
        d.arc([75, 56, 105, 86], start=180, end=350, fill=OUTLINE, width=2)
    elif style == "rod":
        # Slender rod
        d.line([(80, 96), (110, 35)], fill=(180, 130, 70, 255), width=3)
        # Line & Bobber
        d.line([(110, 35), (116, 85)], fill=(230, 230, 240, 200), width=1)
        d.ellipse([113, 80, 119, 86], fill=(235, 60, 50, 255), outline=OUTLINE, width=1)
        
    return img

# -------------------------------------------------------------
# 7. POODLE VARIANTS
# -------------------------------------------------------------
def make_poodle(fur_color, scarf_color):
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    
    # Body centered around (64, 76)
    # Puffy legs
    for px, py in [(46, 92), (58, 94), (70, 94), (82, 92)]:
        d.ellipse([px-8, py-8, px+8, py+8], fill=fur_color, outline=OUTLINE, width=2)
    # Body puff
    d.ellipse([44, 58, 84, 90], fill=fur_color, outline=OUTLINE, width=2)
    # Scarf
    d.polygon([(52, 66), (76, 66), (72, 74), (56, 74)], fill=scarf_color, outline=OUTLINE)
    d.polygon([(68, 72), (76, 72), (78, 86), (70, 84)], fill=scarf_color, outline=OUTLINE)
    # Head puff
    d.ellipse([50, 34, 78, 62], fill=fur_color, outline=OUTLINE, width=2)
    # Top puff (fluffy hair)
    d.ellipse([54, 24, 74, 44], fill=fur_color, outline=OUTLINE, width=2)
    # Ears
    d.ellipse([42, 38, 54, 60], fill=fur_color, outline=OUTLINE, width=2)
    d.ellipse([74, 38, 86, 60], fill=fur_color, outline=OUTLINE, width=2)
    # Face: Eyes & Nose
    d.ellipse([56, 44, 60, 48], fill=OUTLINE)
    d.ellipse([68, 44, 72, 48], fill=OUTLINE)
    d.ellipse([62, 50, 66, 54], fill=(30, 20, 15, 255))
    # Tail puff
    d.ellipse([82, 60, 94, 72], fill=fur_color, outline=OUTLINE, width=2)
    
    return img

def save_and_register(sprite_id, img):
    path = os.path.join(SPRITES_DIR, f"{sprite_id}.png")
    img.save(path, "PNG")
    print(f"[PaperDoll] Saved: {path} ({img.size[0]}x{img.size[1]})")

def main():
    print("==================================================")
    print("  GENERATING 128x128 PAPER-DOLL ASSETS (SPRINT 2)")
    print("==================================================")
    os.makedirs(SPRITES_DIR, exist_ok=True)
    
    # 1. Bodies
    save_and_register("body_warm_ivory", make_body((255, 240, 225, 255), (255, 180, 165, 180)))
    save_and_register("body_peach_sunny", make_body((255, 215, 190, 255), (255, 155, 140, 180)))
    save_and_register("body_honey_tan", make_body((225, 168, 115, 255), (200, 120, 80, 180)))
    save_and_register("body_cocoa_warm", make_body((165, 112, 75, 255), (135, 80, 50, 180)))
    
    # 2. Eyes
    save_and_register("eyes_sparkle_brown", make_eyes((110, 60, 30, 255), "sparkle"))
    save_and_register("eyes_emerald_gentle", make_eyes((45, 145, 95, 255), "sparkle"))
    save_and_register("eyes_happy_arc", make_eyes((74, 44, 24, 255), "happy_arc"))
    save_and_register("eyes_sky_bright", make_eyes((50, 130, 210, 255), "sparkle"))
    
    # 3. Hair
    save_and_register("hair_braid_chestnut", make_hair((120, 65, 35, 255), "braid"))
    save_and_register("hair_short_sunny", make_hair((240, 195, 80, 255), "short"))
    save_and_register("hair_curly_berry", make_hair((175, 55, 65, 255), "curly"))
    save_and_register("hair_bun_baker", make_hair((70, 45, 35, 255), "bun"))
    
    # 4. Outfits
    save_and_register("outfit_denim_overalls", make_outfit("denim"))
    save_and_register("outfit_floral_dress", make_outfit("floral"))
    save_and_register("outfit_baker_apron", make_outfit("baker"))
    save_and_register("outfit_carpenter_vest", make_outfit("carpenter"))
    
    # 5. Hats
    save_and_register("hat_straw_ribbon", make_hat("straw"))
    save_and_register("hat_chef_toque", make_hat("chef"))
    save_and_register("hat_postman_cap", make_hat("postman"))
    save_and_register("hat_none", make_hat("none"))
    
    # 6. Tools
    save_and_register("tool_sickle_chibi", make_tool("sickle"))
    save_and_register("tool_fishing_rod_chibi", make_tool("rod"))
    
    # 7. Poodles
    save_and_register("poodle_apricot_red", make_poodle((245, 195, 115, 255), (230, 50, 45, 255)))
    save_and_register("poodle_cream_blue", make_poodle((252, 248, 238, 255), (60, 130, 215, 255)))
    save_and_register("poodle_choco_yellow", make_poodle((135, 85, 50, 255), (245, 205, 55, 255)))
    
    print("[PaperDoll] All 23 modular layer assets created successfully!")

if __name__ == "__main__":
    main()
