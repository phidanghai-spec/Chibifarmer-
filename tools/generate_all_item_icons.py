"""
generate_all_item_icons.py
Vẽ toàn bộ icon Chibi 2.5D cho tất cả mặt hàng Kho Barn & Kho Silo và Nhà Kho (building_barn.png).
Chuẩn 128x128 RGBA, nền trong suốt (0,0,0,0), viền ấm áp, màu sắc tươi sáng chuẩn Hay Day.
"""

import os
import math
from PIL import Image, ImageDraw

SPRITES_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets", "sprites")
os.makedirs(SPRITES_DIR, exist_ok=True)

def create_canvas(size=(128, 128)):
    return Image.new("RGBA", size, (0, 0, 0, 0)), ImageDraw.Draw(Image.new("RGBA", size, (0, 0, 0, 0)))

def save_icon(img, filenames):
    for fn in filenames:
        out_path = os.path.join(SPRITES_DIR, fn)
        img.save(out_path, "PNG")
        print(f"Saved: {out_path}")

# --- BREAD (Ổ Bánh Mì Nóng) ---
def draw_bread():
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Shadow
    d.ellipse([24, 88, 104, 114], fill=(60, 35, 15, 60))
    # Crust outline
    d.ellipse([20, 36, 108, 98], fill=(130, 65, 15, 255))
    # Crust base
    d.ellipse([23, 39, 105, 95], fill=(215, 130, 40, 255))
    # Top highlight
    d.ellipse([28, 42, 100, 80], fill=(245, 175, 70, 255))
    # Golden top dome
    d.ellipse([34, 45, 94, 72], fill=(255, 205, 110, 255))
    # 3 diagonal cuts
    for ox in [44, 64, 84]:
        d.line([(ox - 6, 50), (ox + 6, 74)], fill=(120, 55, 10, 255), width=4)
        d.line([(ox - 5, 52), (ox + 5, 72)], fill=(255, 240, 190, 255), width=2)
    # Specular shine
    d.ellipse([46, 46, 62, 54], fill=(255, 255, 230, 160))
    return img

# --- BACON / PORK (Thịt Xông Khói) ---
def draw_bacon():
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Shadow
    d.ellipse([20, 95, 108, 118], fill=(60, 35, 15, 60))
    
    # Slice 1 (background)
    pts1 = [(25, 45), (45, 38), (65, 48), (85, 38), (105, 45),
            (102, 70), (82, 62), (62, 72), (42, 62), (22, 70)]
    d.polygon(pts1, fill=(160, 45, 40, 255))
    # Fat stripe 1
    fat1 = [(24, 52), (44, 45), (64, 55), (84, 45), (103, 52),
            (103, 60), (83, 53), (63, 63), (43, 53), (23, 60)]
    d.polygon(fat1, fill=(250, 230, 215, 255))

    # Slice 2 (foreground)
    pts2 = [(22, 65), (42, 56), (64, 68), (86, 56), (108, 65),
            (105, 95), (83, 84), (61, 96), (39, 84), (19, 95)]
    d.polygon(pts2, fill=(195, 55, 50, 255))
    # Meat border outline
    d.line(pts2 + [pts2[0]], fill=(110, 30, 25, 255), width=2)
    # Fat stripes 2
    fat2_a = [(21, 72), (41, 63), (63, 75), (85, 63), (107, 72),
              (106, 79), (84, 70), (62, 82), (40, 70), (20, 79)]
    d.polygon(fat2_a, fill=(255, 240, 230, 255))
    fat2_b = [(20, 84), (40, 74), (62, 86), (84, 74), (106, 84),
              (105, 89), (83, 79), (61, 91), (39, 79), (19, 89)]
    d.polygon(fat2_b, fill=(255, 240, 230, 230))
    return img

# --- CHICKEN FEED (Cám Gà) ---
def draw_chicken_feed():
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Shadow
    d.ellipse([26, 92, 102, 118], fill=(60, 35, 15, 60))
    # Sack body outline
    d.ellipse([28, 38, 100, 106], fill=(130, 95, 45, 255))
    d.ellipse([31, 41, 97, 103], fill=(225, 185, 115, 255))
    # Sack neck gather
    d.polygon([(46, 32), (82, 32), (76, 44), (52, 44)], fill=(205, 165, 95, 255))
    # Tie rope
    d.line([(48, 42), (80, 42)], fill=(120, 50, 20, 255), width=4)
    # Top ruffle
    d.polygon([(42, 22), (86, 22), (80, 34), (48, 34)], fill=(235, 195, 125, 255))
    d.line([(42, 22), (86, 22)], fill=(130, 95, 45, 255), width=2)
    # Corn/Wheat emblem on sack
    d.ellipse([50, 58, 78, 86], fill=(245, 210, 140, 255), outline=(150, 105, 50, 255), width=2)
    # Golden corn cob inside emblem
    d.ellipse([58, 62, 70, 82], fill=(255, 200, 30, 255))
    d.polygon([(56, 76), (64, 84), (64, 76)], fill=(90, 170, 50, 255))
    d.polygon([(72, 76), (64, 84), (64, 76)], fill=(90, 170, 50, 255))
    return img

# --- COW FEED / ANIMAL FEED (Cám Bò / Cám Gia Súc) ---
def draw_cow_feed():
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Shadow
    d.ellipse([26, 92, 102, 118], fill=(40, 50, 30, 60))
    # Greenish burlap sack outline
    d.ellipse([28, 38, 100, 106], fill=(85, 105, 55, 255))
    d.ellipse([31, 41, 97, 103], fill=(145, 175, 105, 255))
    # Sack neck
    d.polygon([(46, 32), (82, 32), (76, 44), (52, 44)], fill=(125, 155, 85, 255))
    # Rope
    d.line([(48, 42), (80, 42)], fill=(90, 60, 20, 255), width=4)
    # Top ruffle
    d.polygon([(42, 22), (86, 22), (80, 34), (48, 34)], fill=(165, 195, 120, 255))
    # Clover / Grass emblem
    d.ellipse([50, 58, 78, 86], fill=(230, 240, 215, 255), outline=(95, 125, 65, 255), width=2)
    # 3 green clover leaves
    d.ellipse([58, 64, 66, 72], fill=(50, 160, 60, 255))
    d.ellipse([64, 64, 72, 72], fill=(50, 160, 60, 255))
    d.ellipse([61, 70, 69, 78], fill=(50, 160, 60, 255))
    d.line([(65, 74), (65, 82)], fill=(40, 130, 50, 255), width=2)
    return img

# --- EGG (Rổ Trứng Gà) ---
def draw_egg():
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Shadow
    d.ellipse([22, 90, 106, 116], fill=(60, 35, 15, 60))
    
    # 3 eggs (2 behind, 1 in front)
    # Left egg
    d.ellipse([36, 42, 64, 78], fill=(180, 130, 100, 255))
    d.ellipse([38, 44, 62, 76], fill=(250, 215, 195, 255))
    d.ellipse([42, 48, 52, 60], fill=(255, 245, 240, 220))
    
    # Right egg
    d.ellipse([64, 42, 92, 78], fill=(180, 130, 100, 255))
    d.ellipse([66, 44, 90, 76], fill=(250, 215, 195, 255))
    d.ellipse([70, 48, 80, 60], fill=(255, 245, 240, 220))
    
    # Center egg
    d.ellipse([48, 46, 80, 86], fill=(180, 120, 85, 255))
    d.ellipse([50, 48, 78, 84], fill=(255, 225, 205, 255))
    d.ellipse([54, 52, 66, 66], fill=(255, 255, 245, 240))
    
    # Wicker basket base
    d.chord([26, 62, 102, 106], 0, 180, fill=(135, 80, 35, 255), outline=(90, 45, 15, 255), width=2)
    d.chord([29, 65, 99, 103], 0, 180, fill=(195, 135, 75, 255))
    # Wicker weave lines
    for x in range(36, 96, 10):
        d.line([(x, 70), (x - 4, 100)], fill=(145, 90, 40, 255), width=2)
    d.line([(28, 76), (100, 76)], fill=(125, 70, 25, 255), width=2)
    d.line([(32, 88), (96, 88)], fill=(125, 70, 25, 255), width=2)
    return img

# --- MILK (Bình Sữa Bò Tươi) ---
def draw_milk():
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Shadow
    d.ellipse([34, 100, 94, 118], fill=(40, 50, 70, 50))
    
    # Bottle glass outline
    d.rounded_rectangle([42, 38, 86, 108], radius=16, fill=(150, 180, 210, 255))
    # Milk inside
    d.rounded_rectangle([45, 48, 83, 105], radius=13, fill=(255, 255, 255, 255))
    # Milk top meniscus
    d.ellipse([45, 44, 83, 54], fill=(245, 250, 255, 255))
    # Bottle neck
    d.rectangle([54, 22, 74, 38], fill=(160, 190, 215, 255))
    d.rectangle([56, 24, 72, 38], fill=(240, 248, 255, 255))
    # Bottle rim cap
    d.ellipse([52, 18, 76, 26], fill=(120, 160, 195, 255))
    d.ellipse([54, 20, 74, 24], fill=(255, 255, 255, 255))
    
    # Red ribbon bow around neck
    d.line([(48, 36), (80, 36)], fill=(225, 45, 50, 255), width=4)
    d.polygon([(64, 36), (56, 46), (62, 46)], fill=(220, 40, 45, 255))
    d.polygon([(64, 36), (72, 46), (66, 46)], fill=(220, 40, 45, 255))
    
    # Blue cow / milk drop icon on belly
    d.ellipse([56, 68, 72, 86], fill=(230, 242, 255, 255))
    # Milk drop shape
    d.polygon([(64, 70), (58, 80), (70, 80)], fill=(70, 140, 225, 255))
    d.ellipse([58, 74, 70, 82], fill=(70, 140, 225, 255))
    # Specular shine
    d.line([(48, 54), (48, 98)], fill=(255, 255, 255, 180), width=2)
    return img

# --- BUTTER (Bơ Sữa) ---
def draw_butter():
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Shadow
    d.ellipse([22, 85, 106, 115], fill=(60, 45, 20, 60))
    # Plate
    d.ellipse([24, 78, 104, 106], fill=(220, 230, 235, 255), outline=(170, 185, 195, 255), width=2)
    d.ellipse([32, 82, 96, 102], fill=(245, 250, 255, 255))
    # Butter block 3D
    # Front face
    d.polygon([(40, 60), (84, 60), (84, 82), (40, 82)], fill=(255, 210, 40, 255))
    # Right face
    d.polygon([(84, 60), (96, 50), (96, 72), (84, 82)], fill=(230, 180, 25, 255))
    # Top face
    d.polygon([(40, 60), (52, 50), (96, 50), (84, 60)], fill=(255, 235, 90, 255))
    # Outline
    d.line([(40, 60), (84, 60), (84, 82), (40, 82), (40, 60)], fill=(160, 120, 20, 255), width=2)
    d.line([(84, 60), (96, 50), (96, 72), (84, 82)], fill=(160, 120, 20, 255), width=2)
    d.line([(40, 60), (52, 50), (96, 50)], fill=(160, 120, 20, 255), width=2)
    return img

# --- CHEESE (Phô Mai) ---
def draw_cheese():
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Shadow
    d.ellipse([22, 88, 106, 114], fill=(60, 45, 20, 60))
    # Wedge top face
    d.polygon([(26, 80), (98, 48), (88, 78)], fill=(255, 220, 60, 255))
    # Side face
    d.polygon([(26, 80), (88, 78), (88, 98), (26, 98)], fill=(240, 180, 30, 255))
    # Back-right curve
    d.polygon([(88, 78), (98, 48), (98, 68), (88, 98)], fill=(215, 155, 20, 255))
    # Outline
    d.polygon([(26, 80), (98, 48), (98, 68), (88, 98), (26, 98)], outline=(150, 100, 15, 255), width=2)
    # Holes
    d.ellipse([42, 84, 52, 92], fill=(190, 140, 20, 255))
    d.ellipse([64, 82, 76, 92], fill=(190, 140, 20, 255))
    d.ellipse([54, 68, 68, 76], fill=(225, 185, 35, 255))
    d.ellipse([78, 62, 86, 70], fill=(225, 185, 35, 255))
    return img

# --- CREAM (Kem Sữa) ---
def draw_cream():
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Shadow
    d.ellipse([30, 96, 98, 116], fill=(50, 40, 30, 50))
    # Glass pot
    d.ellipse([34, 46, 94, 106], fill=(230, 240, 245, 255), outline=(150, 175, 190, 255), width=2)
    # Whipped cream swirls inside
    d.ellipse([38, 42, 90, 88], fill=(255, 255, 255, 255))
    d.ellipse([46, 32, 82, 60], fill=(255, 255, 255, 255))
    d.ellipse([54, 24, 74, 42], fill=(255, 255, 255, 255))
    # Strawberry on top of cream
    d.polygon([(64, 22), (58, 30), (70, 30)], fill=(235, 45, 50, 255))
    d.ellipse([58, 26, 70, 32], fill=(235, 45, 50, 255))
    d.ellipse([62, 20, 66, 24], fill=(70, 170, 50, 255))
    # Pot label
    d.rectangle([44, 74, 84, 90], fill=(250, 240, 220, 255), outline=(180, 150, 110, 255), width=1)
    d.line([(48, 82), (80, 82)], fill=(120, 150, 180, 255), width=2)
    return img

# --- FISH CARP (Cá Chép) ---
def draw_fish_carp():
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Shadow
    d.ellipse([22, 92, 106, 114], fill=(20, 50, 80, 50))
    # Tail fin
    d.polygon([(24, 48), (44, 64), (24, 80)], fill=(255, 120, 40, 255), outline=(170, 60, 15, 255), width=2)
    # Dorsal fin
    d.polygon([(56, 36), (78, 32), (72, 48)], fill=(255, 140, 50, 255), outline=(170, 60, 15, 255), width=2)
    # Body
    d.ellipse([36, 42, 102, 86], fill=(255, 140, 30, 255), outline=(170, 60, 15, 255), width=2)
    # Belly highlight
    d.ellipse([46, 56, 94, 84], fill=(255, 215, 110, 255))
    # Scales pattern
    for sx in [54, 66, 78]:
        d.arc([sx, 52, sx + 12, 66], 0, 180, fill=(220, 95, 20, 255), width=2)
        d.arc([sx - 6, 62, sx + 6, 76], 0, 180, fill=(220, 95, 20, 255), width=2)
    # Eye
    d.ellipse([86, 52, 96, 62], fill=(255, 255, 255, 255), outline=(120, 40, 10, 255), width=2)
    d.ellipse([90, 54, 94, 58], fill=(20, 20, 20, 255))
    # Whiskers
    d.line([(98, 64), (106, 68)], fill=(200, 80, 20, 255), width=2)
    return img

# --- CARROT (Củ Cà Rốt Tươi - THAY THẾ HÌNH Ô ĐẤT CŨ) ---
def draw_carrot():
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Shadow
    d.ellipse([30, 96, 98, 116], fill=(60, 35, 15, 60))
    # Green leafy tops
    d.line([(64, 46), (46, 20)], fill=(65, 175, 45, 255), width=5)
    d.line([(64, 46), (64, 16)], fill=(80, 195, 55, 255), width=6)
    d.line([(64, 46), (82, 20)], fill=(65, 175, 45, 255), width=5)
    # Leaves fluff
    for lx, ly in [(44, 20), (64, 14), (84, 20)]:
        d.ellipse([lx - 8, ly - 6, lx + 8, ly + 6], fill=(95, 210, 65, 255))
    
    # Carrot body (cone shape)
    pts = [(44, 46), (84, 46), (72, 88), (64, 106), (56, 88)]
    d.polygon(pts, fill=(255, 120, 20, 255))
    d.polygon(pts, outline=(160, 55, 10, 255), width=2)
    # Carrot top dome
    d.ellipse([44, 40, 84, 52], fill=(245, 110, 15, 255), outline=(160, 55, 10, 255), width=2)
    # Horizontal ridges
    for ry in [54, 66, 78, 90]:
        rw = int(14 * (1.0 - (ry - 50) / 60.0))
        d.line([(64 - rw, ry), (64 + rw, ry)], fill=(200, 80, 10, 255), width=2)
    # Specular highlight
    d.line([(52, 50), (58, 86)], fill=(255, 185, 90, 180), width=3)
    return img

# --- SOYBEAN (Đậu Nành) ---
def draw_soybean():
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Shadow
    d.ellipse([26, 92, 102, 114], fill=(40, 60, 30, 50))
    
    # Back green pod
    d.ellipse([36, 42, 92, 78], fill=(90, 165, 55, 255), outline=(50, 110, 30, 255), width=2)
    # Front pod curved
    d.ellipse([44, 56, 96, 92], fill=(115, 195, 65, 255), outline=(55, 125, 30, 255), width=2)
    
    # 3 golden beans showing inside
    d.ellipse([48, 62, 62, 78], fill=(250, 220, 110, 255), outline=(140, 110, 35, 255), width=2)
    d.ellipse([62, 64, 76, 80], fill=(250, 220, 110, 255), outline=(140, 110, 35, 255), width=2)
    d.ellipse([76, 68, 90, 84], fill=(250, 220, 110, 255), outline=(140, 110, 35, 255), width=2)
    # Bean highlights
    d.ellipse([51, 64, 56, 70], fill=(255, 245, 190, 255))
    d.ellipse([65, 66, 70, 72], fill=(255, 245, 190, 255))
    d.ellipse([79, 70, 84, 76], fill=(255, 245, 190, 255))
    
    # Leaf on stem
    d.polygon([(36, 40), (22, 28), (38, 22), (48, 34)], fill=(75, 160, 45, 255), outline=(40, 100, 25, 255), width=2)
    return img

# --- SUGARCANE (Mía Đường) ---
def draw_sugarcane():
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Shadow
    d.ellipse([26, 96, 102, 116], fill=(40, 50, 30, 50))
    
    # 3 stalks
    for cx in [44, 64, 84]:
        # Stalk body
        d.rounded_rectangle([cx - 7, 34, cx + 7, 104], radius=4, fill=(150, 205, 75, 255), outline=(80, 135, 35, 255), width=2)
        # Joints/nodes
        for jy in [50, 68, 86]:
            d.line([(cx - 7, jy), (cx + 7, jy)], fill=(100, 65, 25, 255), width=3)
            d.line([(cx - 6, jy - 1), (cx + 6, jy - 1)], fill=(225, 245, 155, 255), width=1)
        # Cane leaves at top
        d.line([(cx, 34), (cx - 14, 16)], fill=(65, 165, 45, 255), width=4)
        d.line([(cx, 34), (cx + 14, 16)], fill=(65, 165, 45, 255), width=4)
        
    # Tied ribbon around bundle
    d.line([(34, 72), (94, 72)], fill=(210, 45, 40, 255), width=5)
    return img

# --- WHEAT (Bó Lúa Mì) ---
def draw_wheat():
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Shadow
    d.ellipse([28, 98, 100, 116], fill=(60, 45, 20, 50))
    # Stalks
    for ox in [-12, 0, 12]:
        d.line([(64, 100), (64 + ox * 1.5, 35)], fill=(195, 150, 45, 255), width=4)
        # Grain heads
        gy = 35
        for i in range(5):
            d.ellipse([64 + ox * 1.5 - 8, gy + i * 8, 64 + ox * 1.5, gy + i * 8 + 7], fill=(255, 215, 60, 255), outline=(170, 120, 25, 255), width=1)
            d.ellipse([64 + ox * 1.5, gy + i * 8, 64 + ox * 1.5 + 8, gy + i * 8 + 7], fill=(255, 215, 60, 255), outline=(170, 120, 25, 255), width=1)
    # Red ribbon tie
    d.line([(52, 76), (76, 76)], fill=(215, 40, 40, 255), width=5)
    d.polygon([(64, 76), (58, 86), (62, 86)], fill=(215, 40, 40, 255))
    d.polygon([(64, 76), (70, 86), (66, 86)], fill=(215, 40, 40, 255))
    return img

# --- CORN (Bắp Ngô) ---
def draw_corn():
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Shadow
    d.ellipse([30, 95, 98, 115], fill=(50, 45, 25, 50))
    # Green husk leaves
    d.polygon([(64, 102), (32, 60), (46, 92)], fill=(85, 175, 50, 255), outline=(45, 115, 25, 255), width=2)
    d.polygon([(64, 102), (96, 60), (82, 92)], fill=(85, 175, 50, 255), outline=(45, 115, 25, 255), width=2)
    # Yellow ear
    d.ellipse([46, 26, 82, 96], fill=(255, 210, 30, 255), outline=(180, 130, 20, 255), width=2)
    # Kernels grid
    for ky in range(34, 88, 9):
        for kx in range(50, 78, 8):
            d.ellipse([kx, ky, kx + 6, ky + 7], fill=(255, 235, 90, 255), outline=(210, 155, 25, 255), width=1)
    return img

# --- STRAWBERRY (Dâu Tây) ---
def draw_strawberry():
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Shadow
    d.ellipse([28, 94, 100, 116], fill=(60, 25, 25, 50))
    # Berry heart shape
    d.polygon([(64, 102), (34, 52), (48, 38), (64, 46), (80, 38), (94, 52)], fill=(235, 40, 45, 255))
    d.polygon([(64, 102), (34, 52), (48, 38), (64, 46), (80, 38), (94, 52)], outline=(145, 20, 25, 255), width=2)
    d.ellipse([36, 40, 92, 70], fill=(245, 50, 55, 255))
    # Yellow seeds
    for sy in [52, 64, 76, 88]:
        for sx in [48, 60, 72, 80]:
            if (sx + sy) % 3 == 0:
                d.ellipse([sx, sy, sx + 3, sy + 4], fill=(255, 235, 100, 255))
    # Green calyx leaves
    for lx in [44, 54, 64, 74, 84]:
        d.polygon([(64, 38), (lx, 26), (lx + 4, 34)], fill=(65, 180, 45, 255), outline=(35, 115, 25, 255), width=1)
    d.line([(64, 38), (64, 20)], fill=(45, 135, 30, 255), width=4)
    return img

# --- TOMATO (Cà Chua) ---
def draw_tomato():
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Shadow
    d.ellipse([26, 90, 102, 115], fill=(60, 25, 25, 50))
    # Tomato round body
    d.ellipse([30, 38, 98, 102], fill=(240, 45, 40, 255), outline=(150, 25, 20, 255), width=2)
    # Specular shine
    d.ellipse([42, 46, 58, 60], fill=(255, 200, 195, 200))
    # Star stem calyx
    d.line([(64, 42), (64, 24)], fill=(40, 130, 30, 255), width=4)
    for ang in [0, 60, 120, 180, 240, 300]:
        rad = math.radians(ang)
        ex = 64 + int(math.cos(rad) * 16)
        ey = 42 + int(math.sin(rad) * 12)
        d.polygon([(64, 42), (ex, ey), (ex - 2, ey + 4)], fill=(65, 180, 45, 255))
    return img

# --- PUMPKIN (Bí Đỏ) ---
def draw_pumpkin():
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Shadow
    d.ellipse([24, 92, 104, 116], fill=(50, 35, 15, 60))
    # Outer lobes
    d.ellipse([24, 44, 68, 100], fill=(230, 105, 15, 255), outline=(145, 60, 10, 255), width=2)
    d.ellipse([60, 44, 104, 100], fill=(230, 105, 15, 255), outline=(145, 60, 10, 255), width=2)
    # Middle lobes
    d.ellipse([34, 42, 80, 102], fill=(245, 125, 20, 255), outline=(155, 65, 10, 255), width=2)
    d.ellipse([48, 42, 94, 102], fill=(245, 125, 20, 255), outline=(155, 65, 10, 255), width=2)
    # Center lobe
    d.ellipse([44, 40, 84, 104], fill=(255, 145, 30, 255), outline=(165, 75, 15, 255), width=2)
    # Green stalk
    d.polygon([(60, 42), (58, 22), (68, 20), (66, 42)], fill=(75, 150, 45, 255), outline=(40, 95, 25, 255), width=2)
    return img

# --- RED BARN BUILDING (Nhà Kho Gỗ Mái Đỏ Chuẩn Hay Day 256x256) ---
def draw_building_barn():
    img = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    
    # Ground shadow
    d.ellipse([20, 195, 236, 245], fill=(40, 30, 20, 70))
    
    # Main barn walls (Red Wood)
    d.rectangle([44, 110, 212, 218], fill=(185, 45, 40, 255), outline=(95, 20, 18, 255), width=3)
    # Vertical wood planks
    for px in range(56, 208, 14):
        d.line([(px, 110), (px, 218)], fill=(150, 32, 28, 255), width=2)
        
    # Stone foundation
    d.rectangle([40, 216, 216, 226], fill=(130, 125, 120, 255), outline=(75, 70, 68, 255), width=2)
    for sx in range(54, 210, 22):
        d.line([(sx, 216), (sx, 226)], fill=(85, 80, 78, 255), width=2)

    # Double Barn Doors with X braces
    d.rectangle([94, 140, 162, 216], fill=(245, 240, 230, 255), outline=(95, 20, 18, 255), width=3)
    # Left door
    d.rectangle([96, 142, 126, 214], fill=(165, 38, 32, 255))
    d.line([(98, 144), (124, 212)], fill=(245, 240, 230, 255), width=3)
    d.line([(98, 212), (124, 144)], fill=(245, 240, 230, 255), width=3)
    # Right door
    d.rectangle([130, 142, 160, 214], fill=(165, 38, 32, 255))
    d.line([(132, 144), (158, 212)], fill=(245, 240, 230, 255), width=3)
    d.line([(132, 212), (158, 144)], fill=(245, 240, 230, 255), width=3)
    # Door trim
    d.line([(128, 140), (128, 216)], fill=(95, 20, 18, 255), width=3)

    # Hay loft upper door / window
    d.chord([110, 94, 146, 134], 180, 360, fill=(245, 240, 230, 255), outline=(95, 20, 18, 255), width=2)
    d.rectangle([110, 114, 146, 134], fill=(245, 240, 230, 255), outline=(95, 20, 18, 255), width=2)
    # Golden straw spilling out
    d.ellipse([112, 126, 144, 138], fill=(255, 215, 60, 255))
    d.line([(114, 132), (142, 132)], fill=(215, 165, 30, 255), width=2)

    # Gambrel Roof (Classic Barn Roof)
    # Upper roof peak
    pts_roof = [
        (128, 34),
        (196, 68),
        (224, 114),
        (32, 114),
        (60, 68)
    ]
    d.polygon(pts_roof, fill=(160, 35, 30, 255), outline=(85, 15, 12, 255), width=3)
    # Roof highlight panels
    pts_hi = [
        (128, 38),
        (190, 70),
        (216, 110),
        (40, 110),
        (66, 70)
    ]
    d.polygon(pts_hi, fill=(205, 55, 48, 255))
    # Roof center ridge & eaves
    d.line([(128, 34), (128, 114)], fill=(125, 22, 18, 255), width=2)
    d.line([(28, 114), (228, 114)], fill=(245, 240, 230, 255), width=5)

    # Weather vane on roof peak
    d.line([(128, 34), (128, 14)], fill=(60, 50, 45, 255), width=3)
    d.polygon([(120, 18), (136, 18), (128, 10)], fill=(255, 210, 40, 255), outline=(130, 95, 20, 255), width=1)
    
    return img

def main():
    print("--- GENERATING COMPLETE 128x128 CHIBI ICONS FOR BARN & SILO ---")
    
    # 1. Barn goods
    save_icon(draw_bread(), ["item_bread.png", "bread.png"])
    save_icon(draw_bacon(), ["item_bacon.png", "bacon.png", "pork.png"])
    save_icon(draw_chicken_feed(), ["item_chicken_feed.png", "chicken_feed.png"])
    save_icon(draw_cow_feed(), ["item_cow_feed.png", "cow_feed.png", "animal_feed.png", "pig_feed.png"])
    save_icon(draw_egg(), ["item_egg.png", "egg.png"])
    save_icon(draw_milk(), ["item_milk.png", "milk.png"])
    save_icon(draw_butter(), ["item_butter.png", "butter.png"])
    save_icon(draw_cheese(), ["item_cheese.png", "cheese.png"])
    save_icon(draw_cream(), ["item_cream.png", "cream.png"])
    save_icon(draw_fish_carp(), ["item_fish_carp.png", "fish_carp.png"])

    # 2. Silo crops
    save_icon(draw_carrot(), ["item_carrot.png", "carrot.png"])
    save_icon(draw_soybean(), ["item_soybean.png", "soybean.png"])
    save_icon(draw_sugarcane(), ["item_sugarcane.png", "sugarcane.png"])
    save_icon(draw_wheat(), ["item_wheat.png", "wheat.png"])
    save_icon(draw_corn(), ["item_corn.png", "corn.png"])
    save_icon(draw_strawberry(), ["item_strawberry.png", "strawberry.png"])
    save_icon(draw_tomato(), ["item_tomato.png", "tomato.png"])
    save_icon(draw_pumpkin(), ["item_pumpkin.png", "pumpkin.png"])

    # 3. Building Barn
    save_icon(draw_building_barn(), ["building_barn.png", "chibi_barn_red.png"])

    print("ALL ICONS SUCCESSFULLY GENERATED!")

if __name__ == "__main__":
    main()
