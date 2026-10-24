import os
import csv
from PIL import Image, ImageDraw

PROJECT = r"D:\HayDayOffline"
ASSETS = os.path.join(PROJECT, "assets")
CODE_DIRS = ["scripts", "scenes", "data"]
OUT_DIR = os.path.join(PROJECT, "_asset_audit")
IMG_EXTS = (".png", ".jpg", ".jpeg", ".webp")
CODE_EXTS = (".gd", ".tscn", ".tres", ".json", ".cfg")


def collect_code_text() -> dict:
    texts = {}
    for d in CODE_DIRS:
        base = os.path.join(PROJECT, d)
        for root, _, files in os.walk(base):
            for f in files:
                if f.endswith(CODE_EXTS):
                    p = os.path.join(root, f)
                    with open(p, encoding="utf-8", errors="ignore") as fh:
                        texts[os.path.relpath(p, PROJECT)] = fh.read()
    return texts


def audit(code: dict) -> list:
    rows = []
    for root, _, files in os.walk(ASSETS):
        for f in files:
            if not f.lower().endswith(IMG_EXTS):
                continue
            path = os.path.join(root, f)
            stem = os.path.splitext(f)[0]
            users = [k for k, t in code.items() if f in t]
            if users:
                status = "DÙNG (tên file)"
            elif any(stem in t for t in code.values()):
                status = "CÓ THỂ DÙNG (tên trùng id)"
            else:
                status = "KHÔNG THẤY TRONG CODE"
            try:
                w, h = Image.open(path).size
            except Exception:
                w, h = 0, 0
            rows.append({
                "name": f,
                "folder": os.path.relpath(root, ASSETS),
                "size": f"{w}x{h}",
                "status": status,
                "used_by": "; ".join(users[:3]),
                "path": path,
            })
    rows.sort(key=lambda r: (r["status"], r["folder"], r["name"]))
    return rows


def write_csv(rows: list) -> None:
    out = os.path.join(OUT_DIR, "asset_audit.csv")
    with open(out, "w", newline="", encoding="utf-8-sig") as fh:
        w = csv.DictWriter(fh, fieldnames=["name", "folder", "size", "status", "used_by", "path"])
        w.writeheader()
        w.writerows(rows)
    print("CSV:", out)


def write_contact_sheets(rows: list, thumb: int = 128, cols: int = 6, per_sheet: int = 36) -> None:
    cell_w, cell_h = thumb + 10, thumb + 34
    for i in range(0, len(rows), per_sheet):
        chunk = rows[i:i + per_sheet]
        rows_n = (len(chunk) + cols - 1) // cols
        sheet = Image.new("RGB", (cols * cell_w, rows_n * cell_h), (245, 245, 245))
        draw = ImageDraw.Draw(sheet)
        for idx, r in enumerate(chunk):
            x = (idx % cols) * cell_w + 5
            y = (idx // cols) * cell_h + 5
            try:
                im = Image.open(r["path"]).convert("RGBA")
                im.thumbnail((thumb, thumb))
                bg = Image.new("RGBA", (thumb, thumb), (200, 200, 200, 255))
                bg.paste(im, ((thumb - im.width) // 2, (thumb - im.height) // 2), im)
                sheet.paste(bg.convert("RGB"), (x, y))
            except Exception:
                draw.rectangle([x, y, x + thumb, y + thumb], outline=(255, 0, 0))
            if r["status"].startswith("DÙNG"):
                color = (0, 120, 0)
            elif r["status"].startswith("CÓ THỂ"):
                color = (200, 120, 0)
            else:
                color = (200, 0, 0)
            draw.text((x, y + thumb + 2), r["name"][:24], fill=(0, 0, 0))
            draw.text((x, y + thumb + 16), r["status"][:26], fill=color)
        out = os.path.join(OUT_DIR, f"contact_sheet_{i // per_sheet + 1:02d}.png")
        sheet.save(out)
        print("Contact sheet:", out)


def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    code = collect_code_text()
    rows = audit(code)
    write_csv(rows)
    write_contact_sheets(rows)
    counts = {}
    for r in rows:
        counts[r["status"]] = counts.get(r["status"], 0) + 1
    print("=" * 60)
    print("Tổng số ảnh:", len(rows))
    for k, v in counts.items():
        print(f"  {k}: {v}")
    print("Không có file nào bị di chuyển hay xóa.")


if __name__ == "__main__":
    main()