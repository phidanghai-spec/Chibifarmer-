#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Phase 2A — Kiểm toán & Báo cáo Kinh tế theo phút (HayDayOffline)
Đọc dữ liệu từ data/*.json, tính toán lợi nhuận/phút cho Recipes, Crops, Animals, Fishes,
phát hiện các giá trị bất thường và lệch SSOT giữa các file JSON, và xuất ra docs/economy_report.csv.
Chỉ sử dụng thư viện chuẩn Python 3. Không sửa bất kỳ file JSON hay code gameplay nào.
"""

import csv
import json
from pathlib import Path
from typing import Any, Dict, List, Tuple

ROOT_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = ROOT_DIR / "data"
DOCS_DIR = ROOT_DIR / "docs"
CSV_OUTPUT_PATH = DOCS_DIR / "economy_report.csv"


def load_json(filename: str) -> Dict[str, Any]:
    path = DATA_DIR / filename
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def fmt_num(val: Any, decimals: int = 2) -> str:
    if val is None or val == "":
        return ""
    if isinstance(val, float):
        return f"{val:.{decimals}f}"
    return str(val)


def main() -> None:
    items = load_json("items.json")
    crops = load_json("crops.json")
    recipes = load_json("recipes.json")
    animals = load_json("animals.json")
    buildings = load_json("buildings.json")
    fishes = load_json("fishes.json")

    # 1. Kiểm tra lệch dữ liệu (Cross-file SSOT Mismatches) trên cùng ID
    all_files: Dict[str, Dict[str, Any]] = {
        "items.json": items,
        "crops.json": crops,
        "recipes.json": recipes,
        "animals.json": animals,
        "buildings.json": buildings,
        "fishes.json": fishes,
    }

    id_occurrences: Dict[str, Dict[str, Dict[str, Any]]] = {}
    for fname, data in all_files.items():
        for key, entry in data.items():
            if not isinstance(entry, dict):
                continue
            id_occurrences.setdefault(key, {})[fname] = entry

    cross_file_mismatches: Dict[str, List[str]] = {}
    fields_to_compare = ["base_price", "growth_time_seconds", "unlock_level", "xp_reward", "storage_type"]

    for entity_id, file_map in id_occurrences.items():
        if len(file_map) > 1:
            diffs: List[str] = []
            for field in fields_to_compare:
                vals = {
                    fname: entry.get(field)
                    for fname, entry in file_map.items()
                    if field in entry
                }
                unique_vals = set(vals.values())
                if len(unique_vals) > 1:
                    detail = ", ".join(f"{fn}={v}" for fn, v in vals.items())
                    diffs.append(f"LỆCH_{field.upper()}({detail})")
            if diffs:
                cross_file_mismatches[entity_id] = diffs

    # Hàm lấy giá nguyên liệu theo items.json (hành vi hiện tại của DataManager.get_item_base_price)
    def get_price_items_first(item_id: str) -> int:
        if item_id in items and "base_price" in items[item_id]:
            return int(items[item_id]["base_price"])
        if item_id in crops and "base_price" in crops[item_id]:
            return int(crops[item_id]["base_price"])
        if item_id in recipes and "base_price" in recipes[item_id]:
            return int(recipes[item_id]["base_price"])
        if item_id in fishes and "base_price" in fishes[item_id]:
            return int(fishes[item_id]["base_price"])
        return 0

    # Hàm lấy giá nguyên liệu theo nguồn gốc SSOT (crops.json -> fishes.json -> recipes.json -> items.json)
    def get_price_ssot(item_id: str) -> int:
        if item_id in crops and "base_price" in crops[item_id]:
            return int(crops[item_id]["base_price"])
        if item_id in fishes and "base_price" in fishes[item_id]:
            return int(fishes[item_id]["base_price"])
        if item_id in recipes and "base_price" in recipes[item_id]:
            return int(recipes[item_id]["base_price"])
        if item_id in items and "base_price" in items[item_id]:
            return int(items[item_id]["base_price"])
        return 0

    csv_rows: List[Dict[str, Any]] = []
    anomaly_count = 0

    # ==========================================
    # A. CHUỖI CHẾ BIẾN (RECIPES)
    # ==========================================
    feed_craft_costs: Dict[str, Tuple[float, float]] = {}

    for rec_id, rec in recipes.items():
        name = rec.get("name", rec_id)
        building_id = rec.get("building_id", "")
        unlock_level = int(rec.get("unlock_level", 1))
        produce_count = int(rec.get("produce_count", 1))
        craft_time_s = int(rec.get("craft_time_seconds", 0))
        craft_time_m = craft_time_s / 60.0 if craft_time_s > 0 else 0.0
        base_price = int(rec.get("base_price", get_price_items_first(rec_id)))
        ings: Dict[str, int] = rec.get("ingredients", {}) or {}

        cost_items = sum(get_price_items_first(k) * int(v) for k, v in ings.items())
        cost_ssot = sum(get_price_ssot(k) * int(v) for k, v in ings.items())

        if rec_id in ("chicken_feed", "cow_feed", "pig_feed", "sheep_feed") and produce_count > 0:
            feed_craft_costs[rec_id] = (cost_items / produce_count, cost_ssot / produce_count)

        rev_full = base_price * produce_count
        rev_single = base_price * 1

        profit_full_items = rev_full - cost_items
        profit_full_ssot = rev_full - cost_ssot
        profit_single_items = rev_single - cost_items
        profit_single_ssot = rev_single - cost_ssot

        ppm_full_items = profit_full_items / craft_time_m if craft_time_m > 0 else 0.0
        ppm_full_ssot = profit_full_ssot / craft_time_m if craft_time_m > 0 else 0.0
        ppm_single_items = profit_single_items / craft_time_m if craft_time_m > 0 else 0.0
        ppm_single_ssot = profit_single_ssot / craft_time_m if craft_time_m > 0 else 0.0

        flags: List[str] = []
        if ppm_full_items > 5.0 or ppm_full_ssot > 5.0:
            flags.append("LÃI_PHÚT_CAO(>5.0)")
        if ppm_full_items < 0.1 or ppm_full_ssot < 0.1:
            flags.append("LÃI_PHÚT_THẤP(<0.1)")
        if craft_time_s < 60:
            flags.append(f"CRAFT_TIME_NGẮN({craft_time_s}s<60s)")
        if len(ings) == 0 and rev_full > 0:
            flags.append("NGUYÊN_LIỆU_RỖNG_CÓ_DOANH_THU")
        if cost_items != cost_ssot:
            flags.append(f"LỆCH_VỐN_NGUYÊN_LIỆU(items={cost_items} vs crops={cost_ssot})")
        if rec_id not in items:
            flags.append("THIẾU_TRONG_ITEMS_JSON")
        if rec_id in cross_file_mismatches:
            flags.extend(cross_file_mismatches[rec_id])

        ing_str = "; ".join(f"{k}x{v}" for k, v in ings.items()) if ings else "(RỖNG)"
        if flags:
            anomaly_count += 1

        csv_rows.append({
            "category": "recipe",
            "id": rec_id,
            "name": name,
            "source_building_or_pen": building_id,
            "unlock_level": unlock_level,
            "time_seconds_ssot": craft_time_s,
            "time_seconds_items": items.get(rec_id, {}).get("growth_time_seconds", ""),
            "time_minutes_ssot": fmt_num(craft_time_m, 2),
            "yield_or_produce_count": produce_count,
            "unit_price_ssot": base_price,
            "unit_price_items": items.get(rec_id, {}).get("base_price", ""),
            "cost_items_json": fmt_num(cost_items, 2),
            "cost_ssot_json": fmt_num(cost_ssot, 2),
            "revenue_full": fmt_num(rev_full, 2),
            "revenue_alt_or_1item_bug": fmt_num(rev_single, 2),
            "profit_full_items": fmt_num(profit_full_items, 2),
            "profit_full_ssot": fmt_num(profit_full_ssot, 2),
            "profit_alt_or_1item_bug": fmt_num(profit_single_items, 2),
            "profit_per_min_items": fmt_num(ppm_full_items, 2),
            "profit_per_min_ssot": fmt_num(ppm_full_ssot, 2),
            "profit_per_min_alt_or_x2": fmt_num(ppm_single_items, 2),
            "ingredients_or_feed": ing_str,
            "missing_data_note": "" if rec_id in items else "Không có ID trùng khớp trong items.json (items.json dùng bait_red/bait_blue/bait_gold)",
            "anomalies": " | ".join(flags) if flags else "OK",
        })

    # ==========================================
    # B. CÂY TRỒNG (CROPS)
    # ==========================================
    for crop_id, crop in crops.items():
        name = crop.get("name", crop_id)
        unlock_level = int(crop.get("unlock_level", 1))
        growth_s_crops = int(crop.get("growth_time_seconds", 0))
        growth_m_crops = growth_s_crops / 60.0 if growth_s_crops > 0 else 0.0

        item_entry = items.get(crop_id, {})
        growth_s_items = int(item_entry.get("growth_time_seconds", 0)) if "growth_time_seconds" in item_entry else 0

        has_yield_field = "harvest_yield" in crop
        has_seed_cost_field = "seed_cost" in crop
        harvest_yield = int(crop.get("harvest_yield", 2))

        price_crops = int(crop.get("base_price", 0))
        price_items = int(item_entry.get("base_price", price_crops))

        # Chi phí hạt giống:
        # Trong JSON không có trường seed_cost -> nếu xét doanh thu gộp (seed_cost=0):
        # Doanh thu x1 harvest_yield (đúng theo FieldPlot.harvest() hiện tại cộng harvest_yield):
        rev_gross_x1_crops = harvest_yield * price_crops
        rev_gross_x1_items = harvest_yield * price_items

        # Nếu tính chi phí cơ hội giữ lại 1 nông sản làm hạt giống cho vụ sau (seed_cost = 1 * base_price):
        seed_replant_cost_crops = 1 * price_crops
        seed_replant_cost_items = 1 * price_items
        profit_net_replant_crops = (harvest_yield - 1) * price_crops
        profit_net_replant_items = (harvest_yield - 1) * price_items

        # Nếu giả định nhân thêm hệ số x2 chồng lên harvest_yield (như câu hỏi mục 7.2 HANDOVER.md):
        rev_gross_x2_mult_crops = (harvest_yield * 2) * price_crops

        # Lợi nhuận/phút theo thời gian chuẩn của crops.json:
        # - Cột profit_per_min_items: Gross theo giá items.json (harvest_yield * price_items / growth_m_crops)
        # - Cột profit_per_min_ssot: Gross theo giá crops.json (harvest_yield * price_crops / growth_m_crops)
        # - Cột profit_per_min_alt_or_x2: Net trừ 1 hạt giống tái canh ((harvest_yield - 1) * price_crops / growth_m_crops)
        ppm_gross_items = rev_gross_x1_items / growth_m_crops if growth_m_crops > 0 else 0.0
        ppm_gross_crops = rev_gross_x1_crops / growth_m_crops if growth_m_crops > 0 else 0.0
        ppm_net_replant_crops = profit_net_replant_crops / growth_m_crops if growth_m_crops > 0 else 0.0
        ppm_double_mult_crops = rev_gross_x2_mult_crops / growth_m_crops if growth_m_crops > 0 else 0.0

        flags = []
        if ppm_gross_crops > 5.0 or ppm_net_replant_crops > 5.0:
            flags.append("LÃI_PHÚT_CAO(>5.0)")
        if ppm_gross_crops < 0.1 or ppm_net_replant_crops < 0.1:
            flags.append("LÃI_PHÚT_THẤP(<0.1)")
        if growth_s_crops < 60:
            flags.append(f"GROWTH_TIME_NGẮN({growth_s_crops}s<60s)")
        if crop_id in cross_file_mismatches:
            flags.extend(cross_file_mismatches[crop_id])

        missing_notes: List[str] = []
        if not has_yield_field:
            missing_notes.append("THIẾU DỮ LIỆU harvest_yield (Code FieldPlot đang thu hoạch x2)")
        else:
            missing_notes.append(f"Có harvest_yield={harvest_yield} trong JSON; FieldPlot.harvest() cộng trực tiếp harvest_yield (không nhân chồng x2)")
        if not has_seed_cost_field:
            missing_notes.append("THIẾU DỮ LIỆU seed_cost trong JSON (FieldPlot.plant() trừ 1 hạt từ Silo hoặc cấp free Anti-Softlock cho wheat/corn)")

        if flags:
            anomaly_count += 1

        csv_rows.append({
            "category": "crop",
            "id": crop_id,
            "name": name,
            "source_building_or_pen": "field_plot",
            "unlock_level": unlock_level,
            "time_seconds_ssot": growth_s_crops,
            "time_seconds_items": growth_s_items,
            "time_minutes_ssot": fmt_num(growth_m_crops, 2),
            "yield_or_produce_count": harvest_yield,
            "unit_price_ssot": price_crops,
            "unit_price_items": price_items,
            "cost_items_json": f"0 (Replant={seed_replant_cost_items})",
            "cost_ssot_json": f"0 (Replant={seed_replant_cost_crops})",
            "revenue_full": fmt_num(rev_gross_x1_crops, 2),
            "revenue_alt_or_1item_bug": f"x2_mult={rev_gross_x2_mult_crops}",
            "profit_full_items": fmt_num(rev_gross_x1_items, 2),
            "profit_full_ssot": fmt_num(rev_gross_x1_crops, 2),
            "profit_alt_or_1item_bug": f"Net(-1hạt)={profit_net_replant_crops}",
            "profit_per_min_items": fmt_num(ppm_gross_items, 2),
            "profit_per_min_ssot": fmt_num(ppm_gross_crops, 2),
            "profit_per_min_alt_or_x2": f"Net={ppm_net_replant_crops:.2f} | x2Mult={ppm_double_mult_crops:.2f}",
            "ingredients_or_feed": f"1x {crop_id} (từ kho Silo)",
            "missing_data_note": "; ".join(missing_notes),
            "anomalies": " | ".join(flags) if flags else "OK",
        })

    # ==========================================
    # C. VẬT NUÔI (ANIMALS)
    # ==========================================
    for anim_id, anim in animals.items():
        name = anim.get("name", anim_id)
        pen_id = anim.get("pen_building_id", "")
        feed_id = anim.get("feed_item_id", "")
        prod_id = anim.get("produce_item_id", "")
        unlock_level = int(anim.get("unlock_level", 1))
        produce_time_s = int(anim.get("produce_time_seconds", 0))
        produce_time_m = produce_time_s / 60.0 if produce_time_s > 0 else 0.0
        produce_count = int(anim.get("produce_count", 1))

        # Giá sản phẩm trong items.json (egg=12, milk=28, bacon=65, wool=90) vs base_price trong animals.json (10, 30, 80, 120)
        prod_price_items = int(items.get(prod_id, {}).get("base_price", 0))
        anim_base_price = int(anim.get("base_price", 0))

        # Chi phí 1 bao cám khi mua/bán trực tiếp theo base_price trong items.json
        feed_market_price = int(items.get(feed_id, {}).get("base_price", 0))

        # Chi phí tự xay 1 bao cám (tổng vốn nguyên liệu / 3 bao)
        milled_tuple = feed_craft_costs.get(feed_id)
        has_feed_recipe = milled_tuple is not None
        feed_milled_items = milled_tuple[0] if milled_tuple else feed_market_price
        feed_milled_ssot = milled_tuple[1] if milled_tuple else feed_market_price

        # Doanh thu 1 con (produce_count = 1) vs cả chuồng 3 con (theo code AnimalPen.gd: animal_count = 3, chỉ tốn 1 cám)
        rev_1head_items = produce_count * prod_price_items
        rev_3head_pen_items = (produce_count * 3) * prod_price_items

        # Lợi nhuận 1 con:
        profit_1head_market_feed = rev_1head_items - feed_market_price
        profit_1head_milled_items = rev_1head_items - feed_milled_items
        profit_1head_milled_ssot = rev_1head_items - feed_milled_ssot

        # Lợi nhuận cả chuồng 3 con (1 bao cám cho 3 con trong AnimalPen.gd):
        profit_3head_market_feed = rev_3head_pen_items - feed_market_price

        ppm_1head_market = profit_1head_market_feed / produce_time_m if produce_time_m > 0 else 0.0
        ppm_1head_milled_items = profit_1head_milled_items / produce_time_m if produce_time_m > 0 else 0.0
        ppm_1head_milled_ssot = profit_1head_milled_ssot / produce_time_m if produce_time_m > 0 else 0.0
        ppm_3head_pen = profit_3head_market_feed / produce_time_m if produce_time_m > 0 else 0.0

        flags = []
        if ppm_1head_market > 5.0 or ppm_1head_milled_items > 5.0:
            flags.append("LÃI_PHÚT_CAO(>5.0)")
        if ppm_1head_market < 0.1 or ppm_1head_milled_items < 0.1:
            flags.append("LÃI_PHÚT_THẤP(<0.1)")
        if prod_price_items != anim_base_price:
            flags.append(f"LỆCH_GIÁ_SẢN_PHẨM(items.{prod_id}={prod_price_items} vs animals.{anim_id}.base_price={anim_base_price})")
        if not has_feed_recipe:
            flags.append(f"THIẾU_CÔNG_THỨC_CÁM({feed_id})")
        if pen_id not in buildings:
            flags.append(f"THIẾU_CHUỒNG_TRONG_BUILDINGS({pen_id})")

        missing_notes = []
        if not has_feed_recipe:
            missing_notes.append(f"THIẾU DỮ LIỆU: {feed_id} không có công thức trong recipes.json")
        if pen_id not in buildings:
            missing_notes.append(f"THIẾU DỮ LIỆU: {pen_id} không có trong buildings.json")
        missing_notes.append("Code AnimalPen.gd hiện vẫn hardcode duration=15s và thu 3 con (animal_count=3) chỉ tốn 1 bao cám")

        if flags:
            anomaly_count += 1

        csv_rows.append({
            "category": "animal",
            "id": anim_id,
            "name": f"{name} -> {prod_id}",
            "source_building_or_pen": pen_id,
            "unlock_level": unlock_level,
            "time_seconds_ssot": produce_time_s,
            "time_seconds_items": "15 (hardcode AnimalPen.gd)",
            "time_minutes_ssot": fmt_num(produce_time_m, 2),
            "yield_or_produce_count": f"{produce_count} (Pen=3)",
            "unit_price_ssot": anim_base_price,
            "unit_price_items": prod_price_items,
            "cost_items_json": f"Mua={feed_market_price} | Xay(items)={feed_milled_items:.2f}",
            "cost_ssot_json": f"Mua={feed_market_price} | Xay(crops)={feed_milled_ssot:.2f}",
            "revenue_full": fmt_num(rev_1head_items, 2),
            "revenue_alt_or_1item_bug": f"Pen3={rev_3head_pen_items}",
            "profit_full_items": fmt_num(profit_1head_market_feed, 2),
            "profit_full_ssot": fmt_num(profit_1head_milled_ssot, 2),
            "profit_alt_or_1item_bug": f"Xay(items)={profit_1head_milled_items:.2f} | Pen3={profit_3head_market_feed}",
            "profit_per_min_items": fmt_num(ppm_1head_market, 2),
            "profit_per_min_ssot": fmt_num(ppm_1head_milled_ssot, 2),
            "profit_per_min_alt_or_x2": f"Xay(items)={ppm_1head_milled_items:.2f} | Pen3={ppm_3head_pen:.2f}",
            "ingredients_or_feed": f"1x {feed_id}",
            "missing_data_note": "; ".join(missing_notes),
            "anomalies": " | ".join(flags) if flags else "OK",
        })

    # ==========================================
    # D. CÁ & CÂU CÁ (FISHES)
    # ==========================================
    for fish_id, fish in fishes.items():
        name = fish.get("name", fish_id)
        lure_id = fish.get("required_lure_id", "")
        unlock_level = int(fish.get("unlock_level", 1))
        cooldown_s = int(fish.get("cooldown_seconds", 0))
        cooldown_m = cooldown_s / 60.0 if cooldown_s > 0 else 0.0
        price_fish = int(fish.get("base_price", 0))
        price_items = items.get(fish_id, {}).get("base_price", "")

        # Chi phí mồi câu: nguyên liệu mồi trong recipes.json đang rỗng (vốn = 0), nhưng giá bán mồi là 20/35/60
        lure_recipe_price = int(recipes.get(lure_id, {}).get("base_price", 0))
        profit_free_lure = price_fish - 0
        profit_opportunity_lure = price_fish - lure_recipe_price

        ppm_free_lure = profit_free_lure / cooldown_m if cooldown_m > 0 else 0.0
        ppm_opp_lure = profit_opportunity_lure / cooldown_m if cooldown_m > 0 else 0.0

        flags = []
        if ppm_free_lure > 5.0:
            flags.append("LÃI_PHÚT_CAO(>5.0)")
        if ppm_free_lure < 0.1:
            flags.append("LÃI_PHÚT_THẤP(<0.1)")
        if cooldown_s < 60:
            flags.append(f"COOLDOWN_NGẮN({cooldown_s}s<60s)")
        if fish_id not in items:
            flags.append("THIẾU_TRONG_ITEMS_JSON")
        if fish_id in cross_file_mismatches:
            flags.extend(cross_file_mismatches[fish_id])

        if flags:
            anomaly_count += 1

        csv_rows.append({
            "category": "fish",
            "id": fish_id,
            "name": name,
            "source_building_or_pen": "fishing_spot",
            "unlock_level": unlock_level,
            "time_seconds_ssot": cooldown_s,
            "time_seconds_items": "",
            "time_minutes_ssot": fmt_num(cooldown_m, 2),
            "yield_or_produce_count": 1,
            "unit_price_ssot": price_fish,
            "unit_price_items": price_items,
            "cost_items_json": "0 (Mồi free)",
            "cost_ssot_json": f"Cơ hội mồi={lure_recipe_price}",
            "revenue_full": fmt_num(price_fish, 2),
            "revenue_alt_or_1item_bug": fmt_num(price_fish, 2),
            "profit_full_items": fmt_num(profit_free_lure, 2),
            "profit_full_ssot": fmt_num(profit_opportunity_lure, 2),
            "profit_alt_or_1item_bug": fmt_num(profit_opportunity_lure, 2),
            "profit_per_min_items": fmt_num(ppm_free_lure, 2),
            "profit_per_min_ssot": fmt_num(ppm_opp_lure, 2),
            "profit_per_min_alt_or_x2": fmt_num(ppm_opp_lure, 2),
            "ingredients_or_feed": f"1x {lure_id}",
            "missing_data_note": "" if fish_id in items else "Có trong fishes.json nhưng thiếu trong items.json",
            "anomalies": " | ".join(flags) if flags else "OK",
        })

    # Ghi ra CSV
    DOCS_DIR.mkdir(parents=True, exist_ok=True)
    fieldnames = [
        "category",
        "id",
        "name",
        "source_building_or_pen",
        "unlock_level",
        "time_seconds_ssot",
        "time_seconds_items",
        "time_minutes_ssot",
        "yield_or_produce_count",
        "unit_price_ssot",
        "unit_price_items",
        "cost_items_json",
        "cost_ssot_json",
        "revenue_full",
        "revenue_alt_or_1item_bug",
        "profit_full_items",
        "profit_full_ssot",
        "profit_alt_or_1item_bug",
        "profit_per_min_items",
        "profit_per_min_ssot",
        "profit_per_min_alt_or_x2",
        "ingredients_or_feed",
        "missing_data_note",
        "anomalies",
    ]

    with CSV_OUTPUT_PATH.open("w", encoding="utf-8-sig", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(csv_rows)

    print(f"[OK] Đã xuất báo cáo CSV: {CSV_OUTPUT_PATH}")
    print(f" - Tổng số dòng dữ liệu (không tính header): {len(csv_rows)} ( tính cả header: {len(csv_rows) + 1} )")
    print(f" - Số mục có cờ bất thường (anomalies != OK): {anomaly_count}")
    print(f" - Số ID trùng lặp có giá trị lệch giữa các file JSON: {len(cross_file_mismatches)}")


if __name__ == "__main__":
    main()
