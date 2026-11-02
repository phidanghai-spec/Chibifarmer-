# scripts/entities/river_steamboat.gd
# Chibi River Steamboat & Wooden River Dock with State Machine, Crates & Departures
class_name RiverSteamboat
extends Node2D

signal steamboat_state_changed(new_state: int)
signal crates_updated()

enum BoatState {
	ARRIVING,
	DOCKED,
	DEPARTING,
	COOLDOWN
}

const DOCK_BOAT_OFFSET: Vector2 = Vector2(92.0, 0.0)
const COOLDOWN_TIME: float = 15.0

var state: BoatState = BoatState.DOCKED
var crates: Array[Dictionary] = []

var _dock_sprite: Sprite2D = null
var _boat_sprite: Sprite2D = null
var _dock_base_scale: Vector2 = Vector2.ONE
var _boat_base_scale: Vector2 = Vector2.ONE

var _pill_status: PanelContainer = null
var _lbl_status: Label = null
var _lbl_name: Label = null

var _wave_time: float = 0.0
var _cooldown_timer: float = 0.0

const CARGO_CATALOG: Array[Dictionary] = [
	{ "id": "wheat", "name": "Lúa Mì", "storage": "silo", "base_price": 3 },
	{ "id": "corn", "name": "Bắp Ngô", "storage": "silo", "base_price": 7 },
	{ "id": "carrot", "name": "Cà Rốt", "storage": "silo", "base_price": 8 },
	{ "id": "honey", "name": "Mật ong rừng", "storage": "barn", "base_price": 68 },
	{ "id": "bread", "name": "Bánh Mì Nóng", "storage": "barn", "base_price": 21 },
	{ "id": "egg", "name": "Trứng gà", "storage": "barn", "base_price": 16 },
	{ "id": "milk", "name": "Sữa bò tươi", "storage": "barn", "base_price": 24 },
	{ "id": "apple", "name": "Táo đỏ", "storage": "silo", "base_price": 16 },
	{ "id": "fish_carp", "name": "Cá chép sông", "storage": "barn", "base_price": 35 }
]

func _ready() -> void:
	add_to_group("interactable")
	y_sort_enabled = true
	z_index = 5
	_setup_visuals()
	_load_or_generate_crates()
	_update_status_pill()

func _setup_visuals() -> void:
	# 1. Wooden River Dock Sprite (fixed at (0, 0), display size 72x72)
	_dock_sprite = Sprite2D.new()
	_dock_sprite.centered = true
	_dock_sprite.name = "DockSprite"
	if SpriteAtlasManager.has_texture("river_dock"):
		_dock_sprite.texture = SpriteAtlasManager.get_texture("river_dock")
	SpriteAtlasManager.set_sprite_pixel_size(_dock_sprite, Vector2(72.0, 72.0))
	_dock_base_scale = _dock_sprite.scale
	_dock_sprite.position = Vector2(0.0, 0.0)
	add_child(_dock_sprite)

	# 2. Chibi Steamboat Sprite (parked on water at DOCK_BOAT_OFFSET, display size 84x84)
	_boat_sprite = Sprite2D.new()
	_boat_sprite.centered = true
	_boat_sprite.name = "BoatSprite"
	if SpriteAtlasManager.has_texture("steamboat_chibi"):
		_boat_sprite.texture = SpriteAtlasManager.get_texture("steamboat_chibi")
	SpriteAtlasManager.set_sprite_pixel_size(_boat_sprite, Vector2(84.0, 84.0))
	_boat_base_scale = _boat_sprite.scale
	_boat_sprite.position = DOCK_BOAT_OFFSET
	add_child(_boat_sprite)

	# 3. Overhead Banners & Status Pill
	_lbl_name = Label.new()
	_lbl_name.text = "🚢 Bến Tàu Du Lịch"
	_lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lbl_name.position = Vector2(-60.0, -50.0)
	_lbl_name.custom_minimum_size = Vector2(120.0, 18.0)
	_lbl_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lbl_name.add_theme_font_size_override("font_size", 9)
	_lbl_name.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	_lbl_name.add_theme_color_override("font_outline_color", Color(0.18, 0.12, 0.05))
	_lbl_name.add_theme_constant_override("outline_size", 3)
	add_child(_lbl_name)

	# Status Pill Container (Cream wood style centered over steamboat)
	_pill_status = PanelContainer.new()
	_pill_status.position = Vector2(DOCK_BOAT_OFFSET.x - 36.0, -48.0)
	_pill_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var psb: StyleBoxFlat = StyleBoxFlat.new()
	psb.bg_color = Color(1.0, 0.98, 0.92, 0.92)
	psb.border_color = Color(0.70, 0.50, 0.30, 0.85)
	psb.set_border_width_all(1)
	psb.set_corner_radius_all(8)
	psb.content_margin_left = 6
	psb.content_margin_right = 6
	psb.content_margin_top = 2
	psb.content_margin_bottom = 2
	_pill_status.add_theme_stylebox_override("panel", psb)

	_lbl_status = Label.new()
	_lbl_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lbl_status.add_theme_font_size_override("font_size", 9)
	_lbl_status.add_theme_color_override("font_color", Color(0.35, 0.18, 0.05))
	_pill_status.add_child(_lbl_status)
	add_child(_pill_status)

	# 4. Generous Hitbox Button for 1-Click Tap
	var btn_hitbox: Button = Button.new()
	btn_hitbox.flat = true
	btn_hitbox.position = Vector2(-45.0, -50.0)
	btn_hitbox.custom_minimum_size = Vector2(175.0, 110.0)
	btn_hitbox.pressed.connect(handle_steamboat_click)
	add_child(btn_hitbox)

func _load_or_generate_crates() -> void:
	if SaveManager.steamboat_data.has("crates") and not (SaveManager.steamboat_data["crates"] as Array).is_empty():
		var saved_arr: Array = SaveManager.steamboat_data["crates"] as Array
		crates.clear()
		for c_val: Variant in saved_arr:
			crates.append(c_val as Dictionary)
	else:
		_generate_new_crates()

func _generate_new_crates() -> void:
	crates.clear()
	var candidates: Array = CARGO_CATALOG.duplicate()
	candidates.shuffle()

	for i: int in range(3):
		var item: Dictionary = candidates[i] as Dictionary
		var qty: int = randi_range(2, 4)
		var base_p: int = int(item["base_price"])
		var gold_r: int = int(float(base_p * qty) * 1.5)
		var xp_r: int = randi_range(25, 45)

		crates.append({
			"crate_idx": i,
			"item_id": String(item["id"]),
			"item_name": String(item["name"]),
			"storage": String(item["storage"]),
			"qty": qty,
			"gold_reward": gold_r,
			"xp_reward": xp_r,
			"filled": false
		})

	SaveManager.steamboat_data["crates"] = crates.duplicate(true)
	SaveManager.save_game()
	crates_updated.emit()

func _process(delta: float) -> void:
	# Strict clamp: _boat_sprite scale must never balloon
	if _boat_sprite != null and _boat_sprite.scale.x > _boat_base_scale.x * 1.3:
		_boat_sprite.scale = _boat_base_scale

	match state:
		BoatState.DOCKED:
			_wave_time += delta
			_boat_sprite.position.y = DOCK_BOAT_OFFSET.y + sin(_wave_time * 2.4) * 2.5
			_boat_sprite.rotation = sin(_wave_time * 1.6) * 0.025
		BoatState.COOLDOWN:
			_cooldown_timer -= delta
			if _lbl_status != null:
				_lbl_status.text = "⏳ Tàu mới sau: %ds" % maxi(0, int(ceil(_cooldown_timer)))
			if _cooldown_timer <= 0.0:
				arrive_steamboat()

func _update_status_pill() -> void:
	if _lbl_status == null:
		return

	if state == BoatState.COOLDOWN:
		_lbl_status.text = "⏳ Tàu mới sau: %ds" % maxi(0, int(ceil(_cooldown_timer)))
		return

	var filled_count: int = get_filled_crates_count()
	if filled_count >= 3:
		_lbl_status.text = "🎁 Đủ 3/3 Kiện!"
		_lbl_status.add_theme_color_override("font_color", Color(0.12, 0.65, 0.28))
	else:
		_lbl_status.text = "🚢 Kiện hàng: %d/3" % filled_count
		_lbl_status.add_theme_color_override("font_color", Color(0.35, 0.18, 0.05))

func get_filled_crates_count() -> int:
	var count: int = 0
	for c: Dictionary in crates:
		if bool(c.get("filled", false)):
			count += 1
	return count

func are_all_crates_filled() -> bool:
	return get_filled_crates_count() >= 3

func fill_crate(crate_index: int, use_instant_gold: bool = false) -> Dictionary:
	if crate_index < 0 or crate_index >= crates.size():
		return { "success": false, "message": "Kiện hàng không hợp lệ!" }

	var crate: Dictionary = crates[crate_index]
	if bool(crate.get("filled", false)):
		return { "success": false, "message": "Kiện hàng này đã đóng rồi!" }

	var item_id: String = String(crate["item_id"])
	var qty: int = int(crate["qty"])
	var gold_r: int = int(crate["gold_reward"])
	var xp_r: int = int(crate["xp_reward"])

	if use_instant_gold:
		# Spend 80 Gold to fill instantly
		if not StorageManager.has_gold(80):
			return { "success": false, "message": "Cần 80 Vàng để đóng hộ kiện hàng!" }
		StorageManager.spend_gold(80)
		EventBus.gold_changed.emit(StorageManager.gold, -80)
	else:
		if not StorageManager.has_item(item_id, qty):
			return { "success": false, "message": "Không đủ %s trong kho! (Cần %d)" % [crate["item_name"], qty] }
		StorageManager.remove_item(item_id, qty)

	crate["filled"] = true
	StorageManager.add_gold(gold_r)
	StorageManager.add_xp(xp_r)
	StorageManager.add_coins(15) # +15 Tourism Coins bonus per crate

	SaveManager.steamboat_data["crates"] = crates.duplicate(true)
	SaveManager.save_game()
	SaveManager.steamboat_updated.emit()
	crates_updated.emit()
	_update_status_pill()

	# Notify Quest System
	var farm: Node = get_tree().current_scene
	if farm != null:
		var qm: Node = farm.find_child("QuestManager", true, false)
		if qm != null and qm.has_method("notify_delivery_or_shop"):
			qm.call("notify_delivery_or_shop")

	return {
		"success": true,
		"all_filled": are_all_crates_filled(),
		"message": "Đã đóng kiện thành công! (+%d Vàng, +%d XP, +15 Xu)" % [gold_r, xp_r]
	}

func claim_chest_and_depart() -> Dictionary:
	if not are_all_crates_filled():
		return { "success": false, "message": "Chưa đóng đủ 3/3 kiện hàng!" }

	# Grant Grand Boat Rewards
	var gold_bonus: int = 250
	var coins_bonus: int = 120
	var xp_bonus: int = 100

	StorageManager.add_gold(gold_bonus)
	StorageManager.add_coins(coins_bonus)
	StorageManager.add_xp(xp_bonus)
	SaveManager.add_puzzle_pieces(1) # +1 Puzzle piece 🧩
	StorageManager.diamonds += 2 # +2 Diamonds 💎
	EventBus.diamonds_changed.emit(StorageManager.diamonds, 2)

	AudioManager.play_sfx("fanfare")
	depart_and_schedule_next_boat()

	return {
		"success": true,
		"message": "🎉 Rương Bến Tàu: +250 Vàng, +120 Xu, +100 XP, +1 Mảnh Ghép 🧩 & +2 Kim Cương 💎!"
	}

func depart_and_schedule_next_boat() -> void:
	state = BoatState.DEPARTING
	steamboat_state_changed.emit(state)
	AudioManager.play_sfx("whistle")

	# Little horn pulse & glide north
	var tw: Tween = create_tween().set_parallel(false)
	tw.tween_property(_boat_sprite, "scale", _boat_base_scale * 1.08, 0.22)
	tw.tween_property(_boat_sprite, "scale", _boat_base_scale, 0.22)

	var tw_glide: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw_glide.tween_property(_boat_sprite, "position:y", -420.0, 2.5)
	tw_glide.tween_callback(func() -> void:
		_start_cooldown()
	)

func _start_cooldown() -> void:
	state = BoatState.COOLDOWN
	steamboat_state_changed.emit(state)
	_boat_sprite.visible = false
	_cooldown_timer = COOLDOWN_TIME
	_generate_new_crates()
	SaveManager.steamboat_next_arrival = TickManager.now() + int(COOLDOWN_TIME)
	SaveManager.save_game()
	_update_status_pill()

func arrive_steamboat() -> void:
	state = BoatState.ARRIVING
	steamboat_state_changed.emit(state)
	_boat_sprite.visible = true
	_boat_sprite.position = Vector2(DOCK_BOAT_OFFSET.x, -420.0)

	var tw: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_boat_sprite, "position", DOCK_BOAT_OFFSET, 2.2)
	tw.tween_callback(func() -> void:
		state = BoatState.DOCKED
		steamboat_state_changed.emit(state)
		AudioManager.play_sfx("whistle")
		_update_status_pill()
	)

func instant_summon_boat() -> void:
	if state == BoatState.COOLDOWN:
		_cooldown_timer = 0.0
		arrive_steamboat()

func handle_steamboat_click() -> void:
	AudioManager.play_sfx("click")
	var farm: Node = get_tree().current_scene
	var hud: UIHud = farm.find_child("UIHud", true, false) as UIHud if farm != null else null
	if hud != null:
		hud.open_steamboat_modal(self)

func on_player_interact(_player: Node2D = null) -> void:
	handle_steamboat_click()
