class_name ChibiSceneryBuilder
extends RefCounted

const InteractiveTreeClass = preload("res://scripts/entities/interactive_tree.gd")

## ChibiSceneryBuilder - 2.5D Cozy Chibi Storybook Scenery System
## Generates layered, non-intrusive landscape elements:
## - Layer 1: Background Horizon (Mountains, hills, floating clouds, z_index = -14..-10)
## - Layer 2: Border Scenery (Framing clusters: Big trees, flower bushes, hedges, rocks)
## - Layer 3: Garden & Riverside Details (Pathside florals, bridge accents, riverbank bushes)
## - Layer 4: Ground Shadows (Semi-transparent soft ellipse shadows anchoring objects)

var enable_ambient_sway: bool = true

# Shadow color conforming to 2.5D cozy palette
const SHADOW_COLOR: Color = Color(0.12, 0.22, 0.10, 0.26)

var _foliage_wind_shader: Shader = null
var _cloud_drift_shader: Shader = null
var _tree_wind_material: ShaderMaterial = null
var _bush_wind_material: ShaderMaterial = null
var _cloud_drift_material: ShaderMaterial = null

func _get_foliage_wind_shader() -> Shader:
	if _foliage_wind_shader == null:
		_foliage_wind_shader = Shader.new()
		_foliage_wind_shader.code = """
shader_type canvas_item;

uniform float sway_speed = 1.65;
uniform float sway_strength = 3.2;

void vertex() {
	float canopy_mask = clamp(1.0 - UV.y, 0.0, 1.0);
	float bend = canopy_mask * canopy_mask;
	vec2 world_p = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	float auto_phase = world_p.x * 0.018 + world_p.y * 0.012;
	VERTEX.x += sin(TIME * sway_speed + auto_phase) * sway_strength * bend;
	VERTEX.y += cos(TIME * sway_speed * 1.35 + auto_phase) * (sway_strength * 0.16) * bend;
}
"""
	return _foliage_wind_shader

func _get_cloud_drift_shader() -> Shader:
	if _cloud_drift_shader == null:
		_cloud_drift_shader = Shader.new()
		_cloud_drift_shader.code = """
shader_type canvas_item;

uniform float drift_speed = 0.32;
uniform float drift_distance = 7.5;

void vertex() {
	vec2 world_p = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	float auto_phase = world_p.x * 0.012 + world_p.y * 0.02;
	VERTEX.x += sin(TIME * drift_speed + auto_phase) * drift_distance;
	VERTEX.y += cos(TIME * drift_speed * 1.5 + auto_phase) * 1.8;
}
"""
	return _cloud_drift_shader

## Kiểm tra tọa độ an toàn tuyệt đối tránh đè lên công trình, đường gạch, ruộng, HUD và lòng sông
static func is_position_safe_for_scenery(pos: Vector2) -> bool:
	# 1. Vùng HUD góc trên bên trái
	if pos.x < 330.0 and pos.y < 260.0:
		return false

	# 2. Vùng Lòng sông & Bờ cát (cách tâm sông tối thiểu 115px)
	var river_cx: float = GridManager.get_river_center_x(pos.y)
	if absf(pos.x - river_cx) < 115.0:
		return false

	# 3. Cây Cầu Gỗ bắc qua sông (Row 20, y = 620..700, x = 760..990)
	if Rect2(760.0, 620.0, 230.0, 80.0).has_point(pos):
		return false

	# 4. Bến Câu Cá & Nhà Câu Cá bờ Tây (x = 730..860, y = 690..800)
	if Rect2(730.0, 690.0, 130.0, 110.0).has_point(pos):
		return false

	# 5. Sạp Hàng Ven Đường (Roadside Shop tại 192, 544) & Xe Tải Đỏ (tại 435, 660)
	if pos.distance_to(Vector2(192.0, 544.0)) < 60.0:
		return false
	if pos.distance_to(Vector2(435.0, 660.0)) < 60.0:
		return false

	# 6. Vùng Cụm Ruộng tập trung (Field Plots: cells [12..15, 17..19])
	if Rect2(360.0, 520.0, 180.0, 140.0).has_point(pos):
		return false

	# 7. Vùng Vườn Cây Ăn Quả (Orchard: x = 160..300, y = 680..880)
	if Rect2(160.0, 680.0, 140.0, 200.0).has_point(pos):
		return false

	# 8. Kiểm tra an toàn bán kính 48px với mọi ô lưới có Đường gạch hoặc Công trình/Chuồng trại
	var cell: Vector2i = GridManager.world_to_grid(pos)
	for dx: int in range(-2, 3):
		for dy: int in range(-2, 3):
			var check_c: Vector2i = cell + Vector2i(dx, dy)
			if GridManager.path_cells.has(check_c) or GridManager.occupied_cells.has(check_c):
				var cell_center: Vector2 = (Vector2(check_c) + Vector2(0.5, 0.5)) * 32.0
				if pos.distance_to(cell_center) < 48.0:
					return false

	# 9. Vùng 4 Chuồng Thú & Khinh Khí Cầu / Quầy Phục Vụ Bờ Đông (Vùng cấm tuyệt đối x: 1100..1860, y: 95..615)
	if pos.x >= 1100.0 and pos.x <= 1860.0 and pos.y >= 95.0 and pos.y <= 615.0:
		return false

	return true

## Tạo bóng đổ elip mềm mại màu xanh đen bán trong suốt
static func create_ellipse_shadow(radius_x: float, radius_y: float) -> Polygon2D:
	var shadow: Polygon2D = Polygon2D.new()
	shadow.name = "GroundShadow"
	shadow.color = SHADOW_COLOR
	var points: PackedVector2Array = PackedVector2Array()
	var segments: int = 16
	for i: int in range(segments):
		var angle: float = float(i) * TAU / float(segments)
		points.append(Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	shadow.polygon = points
	shadow.z_index = -1
	return shadow

## Xây dựng toàn bộ cảnh quan theo 4 nhóm phân lớp
func build_scenery(
	horizon_container: Node2D,
	scenery_container: Node2D,
	scenic_elements_list: Array[Node2D]
) -> void:
	if horizon_container == null or scenery_container == null:
		push_error("[ChibiSceneryBuilder] Containers cannot be null!")
		return

	# 1. Chống tạo trùng tuyệt đối: Dọn sạch node cũ trong cả 2 container ngay lập tức
	for child: Node in horizon_container.get_children():
		horizon_container.remove_child(child)
		child.queue_free()
	for child: Node in scenery_container.get_children():
		scenery_container.remove_child(child)
		child.queue_free()
	scenic_elements_list.clear()

	# 2. Nhóm 1 — Background Horizon (Hậu cảnh đường chân trời & Mây, z_index = -14..-11)
	_build_horizon_layer(horizon_container, scenic_elements_list)

	# 3. Nhóm 2 — Border Scenery (Khung viền rìa nông trại: Cây lớn, bụi hoa, tảng đá)
	_build_border_scenery(scenery_container, scenic_elements_list)

	# 4. Nhóm 3 — Garden & Riverside Details (Tiểu cảnh ven đường & bờ sông)
	_build_garden_and_riverside_details(scenery_container, scenic_elements_list)

	# 5. Nhóm 5 — Zoo East Park (Công viên sinh thái dải cỏ phía Đông & Đông Nam Sở Thú)
	_build_zoo_east_park(scenery_container, scenic_elements_list)

	print("[ChibiSceneryBuilder] Successfully generated %d cozy 2.5D scenery elements!" % scenic_elements_list.size())

## Nhóm 1: Mây bồng bềnh phía Bắc (z_index = -12, không có vách núi chặn để mở rộng thế giới)
func _build_horizon_layer(container: Node2D, list: Array[Node2D]) -> void:
	# Mây Chibi bồng bềnh ở bầu trời cao (Y: 12..35, z_index = -12)
	var cloud_defs: Array[Dictionary] = [
		{"id": "chibi_cloud_1", "pos": Vector2(220.0, 18.0), "size": Vector2(115.0, 55.0)},
		{"id": "chibi_cloud_2", "pos": Vector2(580.0, 14.0), "size": Vector2(125.0, 60.0)},
		{"id": "chibi_cloud_3", "pos": Vector2(820.0, 32.0), "size": Vector2(100.0, 50.0)},
		{"id": "chibi_cloud_4", "pos": Vector2(1080.0, 16.0), "size": Vector2(115.0, 55.0)},
		{"id": "chibi_cloud_1", "pos": Vector2(1380.0, 20.0), "size": Vector2(120.0, 58.0)}
	]

	for c: Dictionary in cloud_defs:
		var node: Node2D = _create_scenery_node(
			String(c["id"]),
			Vector2(c["pos"]),
			Vector2(c["size"]),
			-12,
			false
		)
		if node != null:
			container.add_child(node)
			list.append(node)

## Nhóm 2: Khung viền rìa nông trại (Cây lớn, Bụi hoa, Hàng rào)
func _build_border_scenery(container: Node2D, list: Array[Node2D]) -> void:
	# 1. Hàng cây Bắc che chắn sau xưởng chế biến (Y: 95..110) - Không có đá/núi chặn
	var north_clusters: Array[Dictionary] = [
		{"id": "env_cherry_tree", "pos": Vector2(385.0, 95.0), "size": Vector2(88.0, 92.0), "shadow": Vector2(36.0, 15.0)},
		{"id": "chibi_flower_bush_1", "pos": Vector2(430.0, 112.0), "size": Vector2(40.0, 36.0), "shadow": Vector2(16.0, 8.0)},

		{"id": "env_lush_green_tree", "pos": Vector2(520.0, 100.0), "size": Vector2(90.0, 95.0), "shadow": Vector2(38.0, 16.0)},
		{"id": "chibi_flower_bush_3", "pos": Vector2(565.0, 114.0), "size": Vector2(40.0, 36.0), "shadow": Vector2(16.0, 8.0)},
		{"id": "chibi_hedge_1", "pos": Vector2(475.0, 108.0), "size": Vector2(36.0, 28.0), "shadow": Vector2(15.0, 7.0)},

		{"id": "env_cherry_tree", "pos": Vector2(700.0, 95.0), "size": Vector2(88.0, 92.0), "shadow": Vector2(36.0, 15.0)},
		{"id": "chibi_flower_bush_5", "pos": Vector2(745.0, 112.0), "size": Vector2(40.0, 36.0), "shadow": Vector2(16.0, 8.0)},

		{"id": "env_lush_green_tree", "pos": Vector2(880.0, 100.0), "size": Vector2(90.0, 95.0), "shadow": Vector2(38.0, 16.0)},
		{"id": "chibi_flower_bush_7", "pos": Vector2(840.0, 115.0), "size": Vector2(40.0, 36.0), "shadow": Vector2(16.0, 8.0)}
	]

	for d: Dictionary in north_clusters:
		_add_element_if_safe(container, list, d)

	# 2. Rìa Tây (X: 70..100, Y: 320..640)
	var west_clusters: Array[Dictionary] = [
		{"id": "chibi_tree_oak", "pos": Vector2(85.0, 340.0), "size": Vector2(84.0, 90.0), "shadow": Vector2(35.0, 15.0)},
		{"id": "chibi_flower_bush_2", "pos": Vector2(118.0, 362.0), "size": Vector2(40.0, 36.0), "shadow": Vector2(16.0, 8.0)},
		{"id": "chibi_rock_3", "pos": Vector2(62.0, 365.0), "size": Vector2(30.0, 24.0), "shadow": Vector2(12.0, 6.0)},

		{"id": "chibi_special_peach_tree", "pos": Vector2(80.0, 480.0), "size": Vector2(86.0, 92.0), "shadow": Vector2(36.0, 15.0)},
		{"id": "chibi_hedge_2", "pos": Vector2(112.0, 508.0), "size": Vector2(36.0, 28.0), "shadow": Vector2(15.0, 7.0)},
		{"id": "sunflower", "pos": Vector2(125.0, 450.0), "size": Vector2(34.0, 42.0), "shadow": Vector2(14.0, 7.0)},
		{"id": "decor_hay_bale", "pos": Vector2(125.0, 545.0), "size": Vector2(36.0, 34.0), "shadow": Vector2(15.0, 8.0)},

		{"id": "chibi_tree_tall", "pos": Vector2(75.0, 620.0), "size": Vector2(84.0, 96.0), "shadow": Vector2(34.0, 14.0)},
		{"id": "chibi_flower_bush_4", "pos": Vector2(110.0, 642.0), "size": Vector2(40.0, 36.0), "shadow": Vector2(16.0, 8.0)}
	]

	for d: Dictionary in west_clusters:
		_add_element_if_safe(container, list, d)

	# 3. Rìa Nam (X: 180..680, Y: 940..980)
	var south_clusters: Array[Dictionary] = [
		{"id": "env_lush_green_tree", "pos": Vector2(180.0, 950.0), "size": Vector2(90.0, 95.0), "shadow": Vector2(38.0, 16.0)},
		{"id": "chibi_flower_bush_6", "pos": Vector2(228.0, 968.0), "size": Vector2(40.0, 36.0), "shadow": Vector2(16.0, 8.0)},
		{"id": "chibi_rock_4", "pos": Vector2(142.0, 962.0), "size": Vector2(32.0, 24.0), "shadow": Vector2(13.0, 6.0)},

		{"id": "chibi_tree_cypress", "pos": Vector2(450.0, 960.0), "size": Vector2(80.0, 98.0), "shadow": Vector2(32.0, 14.0)},
		{"id": "chibi_flower_bush_8", "pos": Vector2(495.0, 974.0), "size": Vector2(40.0, 36.0), "shadow": Vector2(16.0, 8.0)},

		{"id": "env_cherry_tree", "pos": Vector2(620.0, 955.0), "size": Vector2(88.0, 92.0), "shadow": Vector2(36.0, 15.0)},
		{"id": "chibi_rock_5", "pos": Vector2(665.0, 970.0), "size": Vector2(32.0, 24.0), "shadow": Vector2(13.0, 6.0)}
	]

	for d: Dictionary in south_clusters:
		_add_element_if_safe(container, list, d)

	# 4. Công viên Rừng Anh Đào Bờ Đông (X: 1110..1280, Y: 190..920)
	var east_bank_clusters: Array[Dictionary] = [
		# Phía Bắc Cầu Gỗ (Bờ Đông)
		{"id": "env_cherry_tree", "pos": Vector2(1120.0, 210.0), "size": Vector2(88.0, 92.0), "shadow": Vector2(36.0, 15.0)},
		{"id": "env_river_bush", "pos": Vector2(1145.0, 260.0), "size": Vector2(40.0, 36.0), "shadow": Vector2(16.0, 8.0)},
		{"id": "env_lush_green_tree", "pos": Vector2(1240.0, 240.0), "size": Vector2(90.0, 95.0), "shadow": Vector2(38.0, 16.0)},
		{"id": "chibi_floral_1", "pos": Vector2(1160.0, 310.0), "size": Vector2(36.0, 28.0), "shadow": Vector2(14.0, 7.0)},

		{"id": "env_lush_green_tree", "pos": Vector2(1135.0, 380.0), "size": Vector2(90.0, 95.0), "shadow": Vector2(38.0, 16.0)},
		{"id": "env_river_bush", "pos": Vector2(1150.0, 440.0), "size": Vector2(40.0, 36.0), "shadow": Vector2(16.0, 8.0)},
		{"id": "env_cherry_tree", "pos": Vector2(1240.0, 400.0), "size": Vector2(88.0, 92.0), "shadow": Vector2(36.0, 15.0)},
		{"id": "chibi_tree_oak_2", "pos": Vector2(1250.0, 490.0), "size": Vector2(88.0, 92.0), "shadow": Vector2(36.0, 15.0)},
		{"id": "chibi_floral_2", "pos": Vector2(1165.0, 490.0), "size": Vector2(36.0, 28.0), "shadow": Vector2(14.0, 7.0)},

		{"id": "env_cherry_tree", "pos": Vector2(1120.0, 560.0), "size": Vector2(88.0, 92.0), "shadow": Vector2(36.0, 15.0)},
		{"id": "env_river_bush", "pos": Vector2(1155.0, 610.0), "size": Vector2(40.0, 36.0), "shadow": Vector2(16.0, 8.0)},
		{"id": "chibi_floral_3", "pos": Vector2(1240.0, 580.0), "size": Vector2(36.0, 28.0), "shadow": Vector2(14.0, 7.0)},

		# Phía Nam Cầu Gỗ (Bờ Đông)
		{"id": "env_lush_green_tree", "pos": Vector2(1125.0, 720.0), "size": Vector2(90.0, 95.0), "shadow": Vector2(38.0, 16.0)},
		{"id": "env_river_bush", "pos": Vector2(1145.0, 770.0), "size": Vector2(40.0, 36.0), "shadow": Vector2(16.0, 8.0)},
		{"id": "env_cherry_tree", "pos": Vector2(1240.0, 740.0), "size": Vector2(88.0, 92.0), "shadow": Vector2(36.0, 15.0)},
		{"id": "chibi_floral_4", "pos": Vector2(1165.0, 810.0), "size": Vector2(36.0, 28.0), "shadow": Vector2(14.0, 7.0)},

		{"id": "env_cherry_tree", "pos": Vector2(1130.0, 860.0), "size": Vector2(88.0, 92.0), "shadow": Vector2(36.0, 15.0)},
		{"id": "env_river_bush", "pos": Vector2(1150.0, 910.0), "size": Vector2(40.0, 36.0), "shadow": Vector2(16.0, 8.0)},
		{"id": "env_lush_green_tree", "pos": Vector2(1240.0, 880.0), "size": Vector2(90.0, 95.0), "shadow": Vector2(38.0, 16.0)}
	]

	for d: Dictionary in east_bank_clusters:
		_add_element_if_safe(container, list, d)

## Nhóm 3: Tiểu cảnh ven đường & bờ sông (Đường dẫn thị giác)
func _build_garden_and_riverside_details(container: Node2D, list: Array[Node2D]) -> void:
	var path_and_river_details: Array[Dictionary] = [
		# Bờ Tây ven sông (an toàn cách mép nước > 40px)
		{"id": "env_river_bush", "pos": Vector2(765.0, 380.0), "size": Vector2(42.0, 38.0), "shadow": Vector2(16.0, 8.0)},
		{"id": "chibi_floral_5", "pos": Vector2(755.0, 550.0), "size": Vector2(36.0, 28.0), "shadow": Vector2(14.0, 7.0)},
		{"id": "chibi_rock_6", "pos": Vector2(770.0, 480.0), "size": Vector2(32.0, 24.0), "shadow": Vector2(13.0, 6.0)},
		{"id": "env_river_bush", "pos": Vector2(760.0, 820.0), "size": Vector2(40.0, 36.0), "shadow": Vector2(16.0, 8.0)},

		# Lối đi & đầu cầu gỗ (Visual leading lines)
		{"id": "chibi_floral_6", "pos": Vector2(120.0, 615.0), "size": Vector2(32.0, 26.0), "shadow": Vector2(13.0, 6.0)},
		{"id": "decor_wooden_bench", "pos": Vector2(160.0, 615.0), "size": Vector2(38.0, 36.0), "shadow": Vector2(16.0, 8.0)},
		{"id": "flowerbed_daisies", "pos": Vector2(235.0, 615.0), "size": Vector2(36.0, 30.0), "shadow": Vector2(15.0, 8.0)},
		{"id": "chibi_floral_1", "pos": Vector2(280.0, 615.0), "size": Vector2(32.0, 26.0), "shadow": Vector2(13.0, 6.0)},
		{"id": "decor_hay_bale", "pos": Vector2(335.0, 610.0), "size": Vector2(36.0, 34.0), "shadow": Vector2(15.0, 8.0)},
		{"id": "sunflower", "pos": Vector2(375.0, 615.0), "size": Vector2(34.0, 42.0), "shadow": Vector2(14.0, 7.0)},
		{"id": "flowerbed_roses", "pos": Vector2(530.0, 615.0), "size": Vector2(36.0, 30.0), "shadow": Vector2(15.0, 8.0)},
		{"id": "decor_wooden_bench", "pos": Vector2(575.0, 615.0), "size": Vector2(38.0, 36.0), "shadow": Vector2(16.0, 8.0)},
		{"id": "decor_hay_bale", "pos": Vector2(625.0, 610.0), "size": Vector2(36.0, 34.0), "shadow": Vector2(15.0, 8.0)},
		{"id": "flowerbed_lavender", "pos": Vector2(675.0, 615.0), "size": Vector2(36.0, 30.0), "shadow": Vector2(15.0, 8.0)},
		{"id": "chibi_bush_green", "pos": Vector2(745.0, 605.0), "size": Vector2(34.0, 28.0), "shadow": Vector2(14.0, 7.0)},
		{"id": "chibi_bush_green", "pos": Vector2(1020.0, 605.0), "size": Vector2(34.0, 28.0), "shadow": Vector2(14.0, 7.0)}
	]

	for d: Dictionary in path_and_river_details:
		_add_element_if_safe(container, list, d)

## Nhóm 5: Công viên sinh thái bao quanh rìa ngoài Sở Thú (y < 90, y > 615 hoặc x > 1860)
func _build_zoo_east_park(container: Node2D, list: Array[Node2D]) -> void:
	var zoo_forbidden: Rect2 = Rect2(1100.0, 95.0, 760.0, 520.0)
	var zoo_park_props: Array[Dictionary] = [
		# 1. Rìa ngoài phía Bắc Sở Thú (y = 78..84, không bị thanh HUD che)
		{"id": "env_cherry_tree", "pos": Vector2(1230.0, 80.0), "size": Vector2(80.0, 84.0), "shadow": Vector2(34.0, 14.0)},
		{"id": "chibi_tree_oak", "pos": Vector2(1420.0, 78.0), "size": Vector2(84.0, 88.0), "shadow": Vector2(35.0, 15.0)},
		{"id": "env_cherry_tree", "pos": Vector2(1600.0, 80.0), "size": Vector2(80.0, 84.0), "shadow": Vector2(34.0, 14.0)},
		{"id": "chibi_tree_tall", "pos": Vector2(1780.0, 78.0), "size": Vector2(78.0, 88.0), "shadow": Vector2(32.0, 14.0)},
		{"id": "flowerbed_daisies", "pos": Vector2(1330.0, 84.0), "size": Vector2(38.0, 32.0), "shadow": Vector2(16.0, 8.0)},
		{"id": "sunflower", "pos": Vector2(1510.0, 84.0), "size": Vector2(36.0, 44.0), "shadow": Vector2(15.0, 8.0)},
		{"id": "flowerbed_roses", "pos": Vector2(1690.0, 84.0), "size": Vector2(38.0, 32.0), "shadow": Vector2(16.0, 8.0)},
		{"id": "decor_wooden_bench", "pos": Vector2(1460.0, 84.0), "size": Vector2(40.0, 36.0), "shadow": Vector2(16.0, 8.0)},
		
		# 2. Rìa ngoài phía Nam đường đi Sở Thú (y > 615)
		{"id": "env_cherry_tree", "pos": Vector2(1220.0, 645.0), "size": Vector2(88.0, 92.0), "shadow": Vector2(36.0, 15.0)},
		{"id": "chibi_tree_oak", "pos": Vector2(1400.0, 660.0), "size": Vector2(92.0, 96.0), "shadow": Vector2(38.0, 16.0)},
		{"id": "env_cherry_tree", "pos": Vector2(1580.0, 650.0), "size": Vector2(88.0, 92.0), "shadow": Vector2(36.0, 15.0)},
		{"id": "chibi_tree_oak", "pos": Vector2(1760.0, 655.0), "size": Vector2(92.0, 96.0), "shadow": Vector2(38.0, 16.0)},
		{"id": "decor_wooden_bench", "pos": Vector2(1310.0, 635.0), "size": Vector2(40.0, 36.0), "shadow": Vector2(16.0, 8.0)},
		{"id": "decor_hay_bale", "pos": Vector2(1490.0, 638.0), "size": Vector2(38.0, 34.0), "shadow": Vector2(15.0, 8.0)},
		{"id": "flowerbed_lavender", "pos": Vector2(1670.0, 640.0), "size": Vector2(38.0, 32.0), "shadow": Vector2(16.0, 8.0)},
		{"id": "sunflower", "pos": Vector2(1820.0, 635.0), "size": Vector2(36.0, 44.0), "shadow": Vector2(15.0, 8.0)},
		{"id": "decor_wooden_bench", "pos": Vector2(1850.0, 650.0), "size": Vector2(40.0, 36.0), "shadow": Vector2(16.0, 8.0)},
		
		# 3. Rìa cực Đông ngoài hàng rào Chuồng Thú (x > 1860)
		{"id": "env_cherry_tree", "pos": Vector2(1920.0, 130.0), "size": Vector2(88.0, 92.0), "shadow": Vector2(36.0, 15.0)},
		{"id": "chibi_tree_tall", "pos": Vector2(1910.0, 260.0), "size": Vector2(84.0, 98.0), "shadow": Vector2(35.0, 15.0)},
		{"id": "env_lush_green_tree", "pos": Vector2(1925.0, 380.0), "size": Vector2(90.0, 95.0), "shadow": Vector2(38.0, 16.0)},
		{"id": "env_cherry_tree", "pos": Vector2(1915.0, 500.0), "size": Vector2(88.0, 92.0), "shadow": Vector2(36.0, 15.0)},
		{"id": "decor_wooden_bench", "pos": Vector2(1890.0, 200.0), "size": Vector2(40.0, 36.0), "shadow": Vector2(16.0, 8.0)},
		{"id": "flowerbed_roses", "pos": Vector2(1895.0, 320.0), "size": Vector2(38.0, 32.0), "shadow": Vector2(16.0, 8.0)},
		{"id": "decor_hay_bale", "pos": Vector2(1890.0, 440.0), "size": Vector2(38.0, 34.0), "shadow": Vector2(15.0, 8.0)},
		{"id": "chibi_floral_1", "pos": Vector2(1890.0, 560.0), "size": Vector2(34.0, 28.0), "shadow": Vector2(14.0, 7.0)}
	]
	
	for d: Dictionary in zoo_park_props:
		var p: Vector2 = d.get("pos", Vector2.ZERO) as Vector2
		if zoo_forbidden.has_point(p):
			continue
		_add_element_if_safe(container, list, d)

## Thêm vật thể nếu vượt qua kiểm tra an toàn vùng cấm
func _add_element_if_safe(container: Node2D, list: Array[Node2D], d: Dictionary) -> void:
	var pos: Vector2 = Vector2(d["pos"])
	if not is_position_safe_for_scenery(pos):
		return

	var sprite_id: String = String(d["id"])
	var size: Vector2 = Vector2(d["size"])
	var shadow_sz: Vector2 = Vector2(d.get("shadow", Vector2(size.x * 0.38, size.x * 0.16)))

	var node: Node2D = _create_scenery_node(
		sprite_id,
		pos,
		size,
		0, # Y-Sort props default z_index = 0
		true,
		shadow_sz
	)
	if node != null:
		container.add_child(node)
		list.append(node)

## Tạo node cảnh quan chuẩn Y-Sort kèm bóng đổ chân gốc
func _create_scenery_node(
	sprite_id: String,
	pos: Vector2,
	target_size: Vector2,
	z_idx: int = 0,
	with_shadow: bool = true,
	shadow_size: Vector2 = Vector2.ZERO
) -> Node2D:
	if not SpriteAtlasManager.has_texture(sprite_id):
		push_warning("[ChibiSceneryBuilder] Missing texture: " + sprite_id)
		return null

	var sp: Sprite2D = SpriteAtlasManager.create_sized_sprite(sprite_id, target_size)
	if sp == null:
		return null

	var node: Node2D = null
	if "tree" in sprite_id or "flower" in sprite_id or "sunflower" in sprite_id or "bench" in sprite_id or "rock" in sprite_id:
		var tree_node: Node2D = InteractiveTreeClass.new()
		tree_node.setup(sprite_id, pos, target_size)
		node = tree_node
	else:
		node = Node2D.new()
	node.name = "Scenery_" + sprite_id
	node.position = pos
	node.y_sort_enabled = true
	node.z_index = z_idx

	# Y-Sort Anchor Point Standard: Chân gốc đặt tại (0, 0), sprite offset lên trên
	sp.position = Vector2(0.0, -target_size.y * 0.42)
	if enable_ambient_sway:
		_apply_ambient_sway_shader(sp, sprite_id, pos)
	node.add_child(sp)

	# Nhóm 4 — Ground Shadows: Bóng đổ chân gốc elip mềm mại
	if with_shadow:
		var sx: float = shadow_size.x if shadow_size.x > 0.0 else target_size.x * 0.38
		var sy: float = shadow_size.y if shadow_size.y > 0.0 else target_size.x * 0.16
		var shadow: Polygon2D = create_ellipse_shadow(sx, sy)
		shadow.position = Vector2.ZERO
		node.add_child(shadow)
		node.move_child(shadow, 0) # Đảm bảo bóng nằm dưới sprite

	return node

## Gán Shader đung đưa theo gió (Foliage Wind Sway) hoặc mây trôi (Cloud Drift) 60 FPS trên GPU
## Dùng chung 3 ShaderMaterial toàn cục thay vì cấp phát riêng cho từng node để giữ Batching tốt
func _apply_ambient_sway_shader(sp: Sprite2D, sprite_id: String, _pos: Vector2) -> void:
	if "cloud" in sprite_id:
		if _cloud_drift_material == null:
			_cloud_drift_material = ShaderMaterial.new()
			_cloud_drift_material.shader = _get_cloud_drift_shader()
			_cloud_drift_material.set_shader_parameter("drift_speed", 0.32)
			_cloud_drift_material.set_shader_parameter("drift_distance", 7.5)
		sp.material = _cloud_drift_material
	elif "tree" in sprite_id:
		if _tree_wind_material == null:
			_tree_wind_material = ShaderMaterial.new()
			_tree_wind_material.shader = _get_foliage_wind_shader()
			_tree_wind_material.set_shader_parameter("sway_speed", 1.55)
			_tree_wind_material.set_shader_parameter("sway_strength", 3.2)
		sp.material = _tree_wind_material
	elif "bush" in sprite_id or "hedge" in sprite_id or "flower" in sprite_id or "floral" in sprite_id or "sunflower" in sprite_id:
		if _bush_wind_material == null:
			_bush_wind_material = ShaderMaterial.new()
			_bush_wind_material.shader = _get_foliage_wind_shader()
			_bush_wind_material.set_shader_parameter("sway_speed", 2.05)
			_bush_wind_material.set_shader_parameter("sway_strength", 1.8)
		sp.material = _bush_wind_material
