extends Node2D
class_name VisitorManager

const POOL_SIZE: int = 15
var _pool: Array[VisitorNPC] = []
var _spawn_timer: float = 2.0

const VISITOR_TYPES: Array[String] = [
	"visitor_buyer",
	"visitor_shopper",
	"visitor_tourist"
]

# Separate waiting queue slots for Roadside Shop and Farmhouse (spaced 48px apart)
var shop_slots_occupied: Array[bool] = [false, false, false]
var shop_slot_positions: Array[Vector2] = [
	Vector2(160, 608),
	Vector2(208, 608),
	Vector2(256, 608)
]

var farmhouse_slots_occupied: Array[bool] = [false, false, false]
var farmhouse_slot_positions: Array[Vector2] = [
	Vector2(608, 448),
	Vector2(656, 448),
	Vector2(704, 448)
]

func _ready() -> void:
	y_sort_enabled = true
	_init_pool()

func _init_pool() -> void:
	for i: int in range(POOL_SIZE):
		var npc: VisitorNPC = VisitorNPC.new()
		npc.manager = self
		npc.deactivate()
		add_child(npc)
		_pool.append(npc)
	print("[VisitorManager] Pre-allocated Object Pool with ", POOL_SIZE, " NPC visitors.")

func get_active_visitors() -> Array[VisitorNPC]:
	var result: Array[VisitorNPC] = []
	for npc: VisitorNPC in _pool:
		if npc.state != VisitorNPC.VisitorState.INACTIVE:
			result.append(npc)
	return result

func claim_shop_slot() -> int:
	for i: int in range(shop_slots_occupied.size()):
		if not shop_slots_occupied[i]:
			shop_slots_occupied[i] = true
			return i
	return -1

func release_shop_slot(idx: int) -> void:
	if idx >= 0 and idx < shop_slots_occupied.size():
		shop_slots_occupied[idx] = false

func claim_farmhouse_slot() -> int:
	for i: int in range(farmhouse_slots_occupied.size()):
		if not farmhouse_slots_occupied[i]:
			farmhouse_slots_occupied[i] = true
			return i
	return -1

func release_farmhouse_slot(idx: int) -> void:
	if idx >= 0 and idx < farmhouse_slots_occupied.size():
		farmhouse_slots_occupied[idx] = false

func _process(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		var attraction: int = GridManager.total_attraction_score
		var min_wait: float = maxf(3.5, 8.0 - float(attraction) * 0.05)
		var max_wait: float = maxf(6.0, 14.0 - float(attraction) * 0.08)
		_spawn_timer = randf_range(min_wait, max_wait)
		spawn_random_visitor()

func spawn_random_visitor() -> VisitorNPC:
	var attraction: int = GridManager.total_attraction_score
	var max_active: int = 3
	if attraction >= 80:
		max_active = 5
	elif attraction >= 40:
		max_active = 4
	if get_active_visitors().size() >= max_active:
		return null

	var available_npc: VisitorNPC = null
	for npc: VisitorNPC in _pool:
		if npc.state == VisitorNPC.VisitorState.INACTIVE:
			available_npc = npc
			break
	
	if available_npc == null:
		return null
	
	var v_type: String = VISITOR_TYPES.pick_random()
	var start_pos: Vector2 = GridManager.grid_to_world(GridManager.ENTRANCE_CELL)
	
	var target_pos: Vector2
	var dest_type: String = "sightseeing"
	var slot_idx: int = -1
	
	if v_type == "visitor_shopper":
		# Try to claim an individual queue slot in front of Roadside Shop
		slot_idx = claim_shop_slot()
		if slot_idx >= 0:
			target_pos = shop_slot_positions[slot_idx]
			dest_type = "shop"
		else:
			target_pos = _get_sightseeing_position()
	elif v_type == "visitor_buyer":
		# Buyer visits farmhouse doorstep queue slots
		slot_idx = claim_farmhouse_slot()
		if slot_idx >= 0:
			target_pos = farmhouse_slot_positions[slot_idx]
			dest_type = "farmhouse"
		else:
			target_pos = _get_sightseeing_position()
	else:
		# visitor_tourist sightseeing at diverse points around the farm
		target_pos = _get_sightseeing_position()
	
	available_npc.activate(v_type, start_pos, target_pos, dest_type, slot_idx)
	print("[VisitorManager] Spawned ", v_type, " heading toward ", target_pos, " (queue: ", dest_type, ")")
	return available_npc

func summon_zoo_visitors(count: int = 2) -> int:
	var spawned: int = 0
	var zoo_spots: Array[Vector2] = [
		Vector2(1290.0, 195.0), # Capybara
		Vector2(1450.0, 195.0), # Panda
		Vector2(1290.0, 395.0), # Penguin
		Vector2(1450.0, 395.0), # Giraffe
		Vector2(1185.0, 440.0)  # Sanctuary Entrance
	]
	var start_pos: Vector2 = GridManager.grid_to_world(GridManager.ENTRANCE_CELL)
	for npc: VisitorNPC in _pool:
		if npc.state == VisitorNPC.VisitorState.INACTIVE:
			var target_pos: Vector2 = zoo_spots.pick_random() + Vector2(randf_range(-14.0, 14.0), randf_range(-14.0, 14.0))
			var v_type: String = VISITOR_TYPES.pick_random()
			npc.activate(v_type, start_pos, target_pos, "zoo", -1)
			spawned += 1
			if spawned >= count:
				break
	print("[VisitorManager] Summoned %d visitors to Zoo Sanctuary!" % spawned)
	return spawned

func _get_sightseeing_position() -> Vector2:
	var candidates: Array[Vector2] = [
		Vector2(528, 560), # Chibi Scarecrow near the crop fields
		Vector2(620, 460), # Chibi Easel (Sunflower painting)
		Vector2(750, 460), # Chibi Telescope on the hill
		Vector2(480, 608), # Southern Fields promenade
		Vector2(680, 620), # Bakery & FeedMill alley
		Vector2(760, 750)  # Near the lake wooden pier
	]
	var base_pos: Vector2 = candidates.pick_random()
	return base_pos + Vector2(randf_range(-14, 14), randf_range(-14, 14))
