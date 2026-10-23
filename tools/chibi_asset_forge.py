#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Chibi Asset Forge (tools/chibi_asset_forge.py)
------------------------------------------------
Hệ thống tự động sinh ảnh & tách nền Chibi thông minh qua Public API cho dự án Hay Day Offline.
Tích hợp:
1. Pollinations AI (Prompt -> 2.5D Chibi Cozy Farm Game Sprite)
2. DiceBear API (Avatar/NPC generation từ public-apis catalog)
3. Smart Corner Floodfill Background Removal (scipy.ndimage + PIL) với de-fringe 1px & bounding box crop
4. High-Quality Procedural Chibi Generator Fallback
5. Auto-registration vào scripts/core/sprite_atlas_manager.gd
"""

import os
import sys
import time
import random
import argparse
import urllib.request
import urllib.parse
import io
import re
from collections import deque
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

try:
    import scipy.ndimage as ndimage
    HAS_SCIPY = True
except ImportError:
    HAS_SCIPY = False

try:
    from google import genai
    HAS_GENAI = True
except ImportError:
    HAS_GENAI = False

SPRITES_DIR = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "assets", "sprites"))
ATLAS_MANAGER_PATH = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "scripts", "core", "sprite_atlas_manager.gd"))
ENV_PATH = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".env"))

def load_env_api_key() -> str:
    """Đọc GEMINI_API_KEY từ file .env hoặc biến môi trường."""
    if os.path.exists(ENV_PATH):
        try:
            with open(ENV_PATH, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if line.startswith("GEMINI_API_KEY="):
                        return line.split("=", 1)[1].strip()
        except Exception as e:
            print(f"[Forge] Error reading .env: {e}")
    return os.environ.get("GEMINI_API_KEY", "")


def remove_background_corner_floodfill(img: Image.Image) -> Image.Image:
    """
    Tách nền trắng/sáng thông minh bằng BFS Floodfill xuất phát từ 4 cạnh viền ngoài.
    Giữ nguyên vẹn 100% các chi tiết trắng/sáng bên trong nội thất vật thể.
    Áp dụng de-fringe và auto-crop bounding box với padding 4px.
    """
    img_rgba = img.convert("RGBA")
    arr = np.array(img_rgba)
    h, w, c = arr.shape
    r = arr[:, :, 0].astype(np.float32)
    g = arr[:, :, 1].astype(np.float32)
    b = arr[:, :, 2].astype(np.float32)
    alpha = arr[:, :, 3].copy()

    # 1. Đo màu tại 4 góc và các mép biên
    corner_samples = [
        arr[0, 0, :3], arr[0, w - 1, :3],
        arr[h - 1, 0, :3], arr[h - 1, w - 1, :3],
        arr[0, w // 2, :3], arr[h - 1, w // 2, :3]
    ]
    corner_bg = np.median(corner_samples, axis=0)

    # 2. Tạo mặt nạ ứng viên nền (Background Candidate Mask)
    dist_to_bg = np.sqrt((r - corner_bg[0])**2 + (g - corner_bg[1])**2 + (b - corner_bg[2])**2)
    is_bright = (r > 228) & (g > 228) & (b > 228)
    is_close_corner = dist_to_bg < 28.0
    bg_candidate = is_bright | is_close_corner

    # 3. Floodfill từ toàn bộ 4 cạnh ngoài viền
    visited = np.zeros((h, w), dtype=bool)
    queue = deque()

    for x in range(w):
        if bg_candidate[0, x]:
            visited[0, x] = True
            queue.append((0, x))
        if bg_candidate[h - 1, x]:
            visited[h - 1, x] = True
            queue.append((h - 1, x))
    for y in range(h):
        if bg_candidate[y, 0] and not visited[y, 0]:
            visited[y, 0] = True
            queue.append((y, 0))
        if bg_candidate[y, w - 1] and not visited[y, w - 1]:
            visited[y, w - 1] = True
            queue.append((y, w - 1))

    directions = [(-1, 0), (1, 0), (0, -1), (0, 1)]
    while queue:
        cy, cx = queue.popleft()
        for dy, dx in directions:
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < h and 0 <= nx < w:
                if not visited[ny, nx] and bg_candidate[ny, nx]:
                    visited[ny, nx] = True
                    queue.append((ny, nx))

    bg_mask = visited
    alpha[bg_mask] = 0

    # 4. De-fringe khử viền trắng 1px ở ranh giới
    border_kernel = np.array([[0, 1, 0], [1, 0, 1], [0, 1, 0]], dtype=bool)
    if HAS_SCIPY:
        is_edge = ndimage.binary_dilation(bg_mask, structure=border_kernel) & (~bg_mask)
    else:
        is_edge = np.zeros((h, w), dtype=bool)
        for y in range(1, h - 1):
            for x in range(1, w - 1):
                if not bg_mask[y, x] and (bg_mask[y-1, x] or bg_mask[y+1, x] or bg_mask[y, x-1] or bg_mask[y, x+1]):
                    is_edge[y, x] = True

    for y, x in zip(*np.where(is_edge)):
        brightness = (r[y, x] + g[y, x] + b[y, x]) / 3.0
        if brightness > 220.0:
            factor = max(0.0, min(1.0, (255.0 - brightness) / 35.0))
            alpha[y, x] = int(255 * factor)

    arr[:, :, 3] = alpha
    result_img = Image.fromarray(arr, mode="RGBA")

    # 5. Xóa watermark góc dưới nếu có (loại bỏ chữ text nhỏ tách biệt ở đáy)
    # Nếu có mảng pixel nhỏ ở 15% đáy không gắn kết với thân chính
    bottom_cut = int(h * 0.85)
    bottom_strip = arr[bottom_cut:, :, 3]
    if np.any(bottom_strip > 0):
        # Kiểm tra xem có khoảng trống trong suốt giữa phần trên và phần đáy không
        mid_strip = arr[int(h * 0.80):bottom_cut, :, 3]
        if np.mean(mid_strip > 0) < 0.05 and np.sum(bottom_strip > 0) < (w * h * 0.05):
            arr[bottom_cut:, :, 3] = 0
            result_img = Image.fromarray(arr, mode="RGBA")

    # 6. Tự động Crop Bounding Box với padding 4px
    bbox = result_img.getbbox()
    if bbox:
        pad = 4
        x0 = max(0, bbox[0] - pad)
        y0 = max(0, bbox[1] - pad)
        x1 = min(w, bbox[2] + pad)
        y1 = min(h, bbox[3] + pad)
        result_img = result_img.crop((x0, y0, x1, y1))

    return result_img

def generate_procedural_chibi(sprite_id: str, prompt: str, width: int = 128, height: int = 128) -> Image.Image:
    """Fallback tạo sprite Chibi ấm áp đồng bộ nét vẽ chuẩn Hay Day bằng PIL."""
    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = width // 2, height // 2

    # A. Bụi cây tròn (Bush / Hedge)
    if any(k in sprite_id.lower() or k in prompt.lower() for k in ["bush", "hedge", "shrub"]):
        # Bóng đổ mờ
        draw.ellipse([cx - 40, cy + 32, cx + 40, cy + 54], fill=(40, 80, 45, 75))
        # Tán lá nền xanh đậm
        draw.ellipse([cx - 44, cy - 16, cx + 44, cy + 42], fill=(95, 165, 75, 255))
        # Tán lá tầng giữa xanh tươi
        draw.ellipse([cx - 38, cy - 24, cx + 14, cy + 28], fill=(125, 195, 90, 255))
        draw.ellipse([cx - 10, cy - 22, cx + 38, cy + 30], fill=(130, 200, 95, 255))
        draw.ellipse([cx - 30, cy - 36, cx + 30, cy + 18], fill=(145, 215, 105, 255))
        # Highlight ánh sáng vàng chanh
        draw.ellipse([cx - 22, cy - 32, cx + 14, cy + 4], fill=(168, 230, 125, 255))
        draw.ellipse([cx, cy - 18, cx + 28, cy + 12], fill=(160, 225, 120, 255))
        # Hoa nhỏ pastel
        flowers = [
            (cx - 16, cy - 19, (255, 255, 255)),
            (cx + 10, cy - 12, (255, 245, 160)),
            (cx - 4, cy + 4, (255, 255, 255)),
            (cx - 26, cy + 6, (255, 210, 230)),
            (cx + 24, cy - 2, (255, 255, 255)),
            (cx + 14, cy + 18, (255, 240, 140)),
            (cx - 19, cy + 22, (255, 255, 255)),
        ]
        for fx, fy, fcol in flowers:
            pr = 3.5
            draw.ellipse([fx - pr - 1, fy - pr, fx + pr + 1, fy + pr], fill=fcol + (255,))
            draw.ellipse([fx - 1.5, fy - 1.5, fx + 1.5, fy + 1.5], fill=(245, 180, 40, 255))
        return img

    # B. Cây Cổ Thụ Xanh (Lush Green Tree)
    if "lush" in sprite_id.lower() or "green_tree" in sprite_id.lower():
        # Thân gỗ nâu
        draw.polygon([(cx - 14, cy + 10), (cx + 14, cy + 10), (cx + 20, cy + 54), (cx - 20, cy + 54)], fill=(120, 80, 48, 255))
        draw.ellipse([cx - 30, cy + 48, cx + 30, cy + 58], fill=(40, 70, 35, 70))
        # Tán lá tròn
        draw.ellipse([cx - 46, cy - 46, cx + 46, cy + 18], fill=(90, 165, 70, 255))
        draw.ellipse([cx - 40, cy - 40, cx + 20, cy + 10], fill=(115, 195, 85, 255))
        draw.ellipse([cx - 20, cy - 42, cx + 40, cy + 8], fill=(130, 205, 95, 255))
        draw.ellipse([cx - 25, cy - 45, cx + 15, cy - 5], fill=(160, 225, 120, 255))
        return img

    # C. Cây Sakura Hoa Anh Đào (Cherry Tree)
    if "cherry" in sprite_id.lower() or "sakura" in sprite_id.lower() or "peach" in sprite_id.lower():
        draw.polygon([(cx - 12, cy + 12), (cx + 12, cy + 12), (cx + 18, cy + 54), (cx - 18, cy + 54)], fill=(130, 85, 52, 255))
        draw.ellipse([cx - 30, cy + 48, cx + 30, cy + 58], fill=(50, 40, 60, 60))
        # Tán hoa hồng pastel
        draw.ellipse([cx - 46, cy - 46, cx + 46, cy + 18], fill=(255, 175, 200, 255))
        draw.ellipse([cx - 38, cy - 40, cx + 22, cy + 10], fill=(255, 195, 215, 255))
        draw.ellipse([cx - 18, cy - 42, cx + 42, cy + 8], fill=(255, 210, 225, 255))
        draw.ellipse([cx - 25, cy - 44, cx + 15, cy - 6], fill=(255, 235, 242, 255))
        return img

    # D. Biểu tượng / Vật phẩm Chibi chung
    draw.ellipse([cx - 45, cy - 45, cx + 45, cy + 45], fill=(255, 200, 160, 255), outline=(160, 100, 60, 255), width=3)
    draw.ellipse([cx - 20, cy - 15, cx - 8, cy - 3], fill=(80, 50, 30, 255))
    draw.ellipse([cx + 8, cy - 15, cx + 20, cy - 3], fill=(80, 50, 30, 255))
    draw.arc([cx - 15, cy - 5, cx + 15, cy + 20], start=20, end=160, fill=(180, 60, 60, 255), width=3)
    return img

def fetch_image_from_gemini(sprite_id: str, prompt: str, ref_image_path: str = None) -> Image.Image:
    """Gọi Gemini API kết hợp ảnh mẫu Style Reference Image để sinh sprite Chibi 2.5D."""
    if not HAS_GENAI:
        return None
    api_key = load_env_api_key()
    if not api_key:
        return None

    try:
        print(f"[Forge] Initializing Gemini API Client with key from .env...")
        client = genai.Client(api_key=api_key)
        
        contents = []
        style_prompt = "2.5D Chibi Cozy Farm game sprite, warm brown outline (#4A2C18, 3px), soft volume shading, hand-painted cozy pastel illustration, isolated on pure solid white background, no text, no watermark"
        
        if ref_image_path and os.path.exists(ref_image_path):
            try:
                ref_img = Image.open(ref_image_path).convert("RGBA")
                contents.append(ref_img)
                print(f"[Forge] Loaded style reference image: {ref_image_path} ({ref_img.size[0]}x{ref_img.size[1]})")
                user_content = f"Create a new chibi farm sprite for '{sprite_id}'. Description: {prompt}. Strictly follow the art style, warm brown outlines, soft ambient shadows, and cozy colors of the provided reference image. {style_prompt}."
            except Exception as e_ref:
                print(f"[Forge] Could not load reference image: {e_ref}")
                user_content = f"{prompt}. {style_prompt}."
        else:
            user_content = f"{prompt}. {style_prompt}."

        contents.append(user_content)
        print(f"[Forge] Calling Gemini API (gemini-2.5-flash-image)...")
        response = client.models.generate_content(
            model='gemini-2.5-flash-image',
            contents=contents
        )
        if response and response.candidates:
            for part in response.candidates[0].content.parts:
                if hasattr(part, "inline_data") and part.inline_data:
                    raw_bytes = part.inline_data.data
                    raw_img = Image.open(io.BytesIO(raw_bytes))
                    print(f"[Forge] Received image from Gemini API ({len(raw_bytes)} bytes)!")
                    return remove_background_corner_floodfill(raw_img)
    except Exception as e:
        print(f"[Forge] Gemini API notice (quota/network): {e}")
        print("[Forge] Falling back cleanly to Public API / Procedural Engine...")

    return None

def fetch_image_from_api(sprite_id: str, prompt: str, width: int, height: int, gen_type: str = "sprite", ref_image_path: str = None, retries: int = 3) -> Image.Image:
    """Gọi Gemini API, Pollinations.ai hoặc DiceBear để tạo ảnh Chibi."""
    # 1. Thử qua Gemini API trước nếu có API Key
    gemini_img = fetch_image_from_gemini(sprite_id, prompt, ref_image_path)
    if gemini_img is not None:
        return gemini_img

    # 2. Avatar/NPC generator từ DiceBear
    if gen_type == "avatar":
        url = f"https://api.dicebear.com/9.x/adventurer/png?seed={urllib.parse.quote(sprite_id)}&width={width}&height={height}"
        print(f"[Forge] Calling DiceBear Avatar API: {url}")
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=12) as resp:
                data = resp.read()
                raw_img = Image.open(io.BytesIO(data))
                return raw_img
        except Exception as e:
            print(f"[Forge] DiceBear API request failed: {e}")
            return generate_procedural_chibi(sprite_id, prompt, width, height)

    # 3. Pollinations API
    full_prompt = f"{prompt}, cute 2.5d chibi cozy farm game sprite, Hay Day style, warm brown outline #4A2C18, soft volume shading, hand-painted illustration, isolated on pure solid white background, no text, no watermark"
    print(f"[Forge] Full Prompt: {full_prompt}")

    for attempt in range(1, retries + 1):
        seed = random.randint(1000, 999999)
        encoded_prompt = urllib.parse.quote(full_prompt)
        url = f"https://image.pollinations.ai/prompt/{encoded_prompt}?width={width}&height={height}&nologo=true&seed={seed}"
        print(f"[Forge] Attempt {attempt}/{retries} via Pollinations (seed={seed})...")
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=18) as resp:
                data = resp.read()
                if len(data) > 100:
                    raw_img = Image.open(io.BytesIO(data))
                    print(f"[Forge] Successfully received image from Pollinations ({len(data)} bytes)!")
                    processed_img = remove_background_corner_floodfill(raw_img)
                    return processed_img
        except Exception as e:
            print(f"[Forge] Attempt {attempt} failed: {e}")
            time.sleep(1.0)

    print("[Forge] All API attempts failed or rate-limited. Falling back to high-quality procedural generator...")
    return generate_procedural_chibi(sprite_id, prompt, width, height)

def auto_register_in_sprite_atlas(sprite_id: str, png_filename: str) -> bool:
    """Tự động chèn _load_standalone_texture vào scripts/core/sprite_atlas_manager.gd nếu chưa có."""
    if not os.path.exists(ATLAS_MANAGER_PATH):
        print(f"[Forge] Warning: Atlas manager file not found at {ATLAS_MANAGER_PATH}")
        return False

    with open(ATLAS_MANAGER_PATH, "r", encoding="utf-8") as f:
        content = f.read()

    pattern = f'_load_standalone_texture\\("{re.escape(sprite_id)}"'
    if re.search(pattern, content):
        print(f"[Forge] Sprite '{sprite_id}' is already registered in sprite_atlas_manager.gd.")
        return True

    res_path = f"res://assets/sprites/{png_filename}"
    new_line = f'\t_load_standalone_texture("{sprite_id}", "{res_path}")\n'

    target_func = "func _load_standalone_texture("
    func_idx = content.find(target_func)
    if func_idx != -1:
        updated_content = content[:func_idx] + new_line + content[func_idx:]
        with open(ATLAS_MANAGER_PATH, "w", encoding="utf-8") as f:
            f.write(updated_content)
        print(f"[Forge] Auto-registered '{sprite_id}' ({res_path}) into sprite_atlas_manager.gd!")
        return True

    print("[Forge] Could not find anchor in sprite_atlas_manager.gd to insert texture load call.")
    return False

def forge_asset(sprite_id: str, prompt: str, width: int = 256, height: int = 256, gen_type: str = "sprite", ref_image: str = None, auto_reg: bool = True) -> str:
    """Pipeline hoàn chỉnh: Gọi API (Gemini/Pollinations) -> Tách nền -> Lưu file -> Đăng ký Atlas."""
    os.makedirs(SPRITES_DIR, exist_ok=True)
    out_filename = f"{sprite_id}.png"
    out_filepath = os.path.join(SPRITES_DIR, out_filename)

    print(f"==================================================")
    print(f"  CHIBI ASSET FORGE: Generating '{sprite_id}'")
    print(f"==================================================")
    img = fetch_image_from_api(sprite_id, prompt, width, height, gen_type, ref_image)

    if img.mode != "RGBA":
        img = img.convert("RGBA")

    img.save(out_filepath, format="PNG")
    print(f"[Forge] Saved transparent Chibi sprite to: {out_filepath} ({img.size[0]}x{img.size[1]})")

    if auto_reg:
        auto_register_in_sprite_atlas(sprite_id, out_filename)

    print(f"[Forge] Done! Sprite '{sprite_id}' is ready for game usage.")
    return out_filepath

def main():
    parser = argparse.ArgumentParser(description="Chibi Asset Forge - Auto generation & background removal via Gemini & Public APIs")
    parser.add_argument("--id", required=True, help="Unique sprite ID (e.g. env_river_bush)")
    parser.add_argument("--prompt", default="", help="English description of the object")
    parser.add_argument("--width", type=int, default=256, help="Target width (default: 256)")
    parser.add_argument("--height", type=int, default=256, help="Target height (default: 256)")
    parser.add_argument("--type", choices=["sprite", "avatar"], default="sprite", help="Type of generation")
    parser.add_argument("--ref", default=None, help="Path to style reference image (e.g. assets/sprites/silo.png)")
    parser.add_argument("--no-register", action="store_true", help="Skip auto-registering into sprite_atlas_manager.gd")

    args = parser.parse_args()

    prompt = args.prompt
    if not prompt:
        prompt = args.id.replace("_", " ")

    forge_asset(
        sprite_id=args.id,
        prompt=prompt,
        width=args.width,
        height=args.height,
        gen_type=args.type,
        ref_image=args.ref,
        auto_reg=not args.no_register
    )

if __name__ == "__main__":
    main()

