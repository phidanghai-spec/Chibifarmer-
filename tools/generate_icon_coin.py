import os
from PIL import Image, ImageDraw

PROJECT = r"D:\HayDayOffline"
OUT_PATH = os.path.join(PROJECT, "assets", "sprites", "icon_coin.png")

def create_coin_icon():
    size = (64, 64)
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Soft Shadow
    draw.ellipse([8, 12, 56, 60], fill=(70, 45, 20, 90))

    # 2. Outer Dark Brown Outline
    draw.ellipse([6, 6, 58, 58], fill=(74, 46, 18, 255))

    # 3. Outer Gold Rim
    draw.ellipse([8, 8, 56, 56], fill=(230, 150, 0, 255))

    # 4. Main Coin Face
    draw.ellipse([11, 11, 53, 53], fill=(255, 215, 0, 255))

    # 5. Inner Inset Ring
    draw.ellipse([15, 15, 49, 49], outline=(218, 140, 0, 255), width=2)

    # 6. Center Star / Diamond Highlight
    # Star vertices
    pts = [
        (32, 20), (35, 28), (43, 29), (37, 34),
        (39, 43), (32, 38), (25, 43), (27, 34),
        (21, 29), (29, 28)
    ]
    draw.polygon(pts, fill=(255, 245, 180, 255), outline=(200, 130, 0, 255))

    # 7. Shiny Arc Highlight (Top Left)
    draw.arc([13, 13, 51, 51], start=190, end=300, fill=(255, 255, 230, 220), width=3)

    img = img.resize((32, 32), Image.Resampling.LANCZOS)
    img.save(OUT_PATH)
    print(f"Generated clean Chibi coin icon: {OUT_PATH}")

if __name__ == "__main__":
    create_coin_icon()
