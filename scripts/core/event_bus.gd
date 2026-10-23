@warning_ignore("unused_signal")
extends Node

# --- Real-Time Clocks & Ticks ---
signal second_ticked(current_unix_time: int)

# --- Economy & Progression ---
signal coins_changed(new_coins: int, delta: int)
signal gold_changed(new_gold: int, delta: int)
signal diamonds_changed(new_diamonds: int, delta: int)
signal xp_changed(current_xp: int, target_xp: int, current_level: int)
signal leveled_up(new_level: int)
signal storage_updated(storage_type: String, current_used: int, max_capacity: int)
signal item_added(item_id: String, count: int, storage_type: String)
signal item_removed(item_id: String, count: int, storage_type: String)

# --- Grid, Construction & Tourism Score ---
signal building_placed(instance_id: int, building_id: String, grid_pos: Vector2i)
signal building_moved(instance_id: int, new_grid_pos: Vector2i)
signal building_removed(instance_id: int, grid_pos: Vector2i)
signal path_tile_changed(grid_pos: Vector2i, is_path: bool)
signal attraction_score_changed(new_score: int)

# --- Farming (Field Plots) ---
signal field_planted(plot_id: int, crop_id: String, finish_time: int)
signal field_harvested(plot_id: int, crop_id: String)

# --- Animals & Pens ---
signal animal_fed(pen_id: int, animal_id: String, finish_time: int)
signal animal_collected(pen_id: int, product_id: String)

# --- Production Machines ---
signal production_started(machine_id: int, recipe_id: String, finish_time: int)
signal production_finished(machine_id: int, recipe_id: String)
signal production_collected(machine_id: int, product_id: String)

# --- Fishing Spot ---
signal fishing_started(spot_id: int, lure_id: String)
signal fish_caught(spot_id: int, fish_id: String, weight_kg: float)
signal fishing_failed(spot_id: int)

# --- Visitors & Tourism System ---
signal visitor_spawned(visitor_id: int, visitor_type: String)
signal visitor_despawned(visitor_id: int)
signal visitor_action_completed(visitor_id: int, action_type: String, reward_gold: int, reward_xp: int)
signal tourist_tipped(visitor_id: int, amount_gold: int, amount_xp: int, world_pos: Vector2)
signal loot_collected(item_id: String, amount: int, world_pos: Vector2)

# --- Commercial & Orders ---
signal truck_order_completed(order_id: String, reward_gold: int, reward_xp: int)
signal roadside_shop_item_sold(slot_index: int, item_id: String, count: int, price: int)
