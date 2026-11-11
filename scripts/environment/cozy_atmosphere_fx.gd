class_name CozyAtmosphereFX
extends Node2D

## CozyAtmosphereFX
## Hệ thống nâng cấp đồ họa & bầu không khí 2.5D Cozy Storybook (Godot 4.3+ GL Compatibility).
## Quản lý 5 lớp hiệu ứng thị giác thời gian thực nhẹ nhàng (60 FPS):
## 1. RiverShimmer & FloatingPetals: Mặt nước sông lấp lánh ánh bạc/vàng & cánh hoa trôi theo dòng chảy.
## 2. SunMotes & GoldenSunbeams: Hạt nắng lơ lửng và tia nắng chéo Golden-Hour đổi màu theo 4 buổi.
## 3. SakuraBreezeParticles: Cánh hoa anh đào hồng phấn bay theo gió qua Rừng Anh Đào & Sở Thú.
## 4. FireflyParticles & LanternHalos: Đom đóm đêm sinh thái & quầng sáng đèn lồng ấm áp nhấp nháy.
## 5. RainRipplesParticles: Vòng gợn nước mưa mềm mại khi thời tiết là COZY_RAIN.
## 100% Static Typing GDScript 2.0.

var _time_accum: float = 0.0
var _current_phase_key: String = "noon"
var _current_weather_key: String = "sunny_breeze"

# Roots phân lớp Z-Index độc lập (z_as_relative = false) để không bị lệ thuộc z_index của parent
var _river_fx_root: Node2D = null
var _air_fx_root: Node2D = null
var _sunbeam_root: Node2D = null
var _lantern_halos_root: Node2D = null

# Hệ thống CPUParticles2D
var _river_shimmer_north: CPUParticles2D = null
var _river_shimmer_south: CPUParticles2D = null
var _floating_petals: CPUParticles2D = null
var _rain_ripples: CPUParticles2D = null

var _sun_motes_west: CPUParticles2D = null
var _sun_motes_east: CPUParticles2D = null
var _sakura_breeze_north: CPUParticles2D = null
var _sakura_breeze_east: CPUParticles2D = null
var _fireflies_west: CPUParticles2D = null
var _fireflies_east: CPUParticles2D = null

# Danh sách các tia nắng & quầng sáng đèn lồng để điều khiển nhịp thở/chuyển màu
var _sunbeam_sprites: Array[Sprite2D] = []
var _lantern_halo_sprites: Array[Sprite2D] = []

# Bộ nhớ đệm Texture & Material dùng chung
var _soft_circle_tex: GradientTexture2D = null
var _shimmer_ellipse_tex: GradientTexture2D = null
var _petal_ellipse_tex: GradientTexture2D = null
var _halo_radial_tex: GradientTexture2D = null
var _ripple_ring_tex: GradientTexture2D = null
var _additive_mat: CanvasItemMaterial = null

func _ready() -> void:
	_init_shared_resources()
	_build_river_fx_layer()
	_build_sunbeams_layer()
	_build_air_particles_layer()
	call_deferred("_setup_lantern_halos")
	apply_atmosphere_state("noon", "sunny_breeze")

func _process(delta: float) -> void:
	_time_accum += delta
	_animate_lantern_halos()
	_animate_sunbeams()

## Khởi tạo các GradientTexture2D mềm mại và CanvasItemMaterial cộng sáng (Additive)
func _init_shared_resources() -> void:
	_additive_mat = CanvasItemMaterial.new()
	_additive_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	# 1. Hạt tròn mềm (dùng cho hạt nắng SunMotes & Đom Đóm Fireflies)
	var circle_grad: Gradient = Gradient.new()
	circle_grad.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	circle_grad.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 0.98, 0.88, 0.55),
		Color(1.0, 0.95, 0.80, 0.0)
	])
	_soft_circle_tex = GradientTexture2D.new()
	_soft_circle_tex.gradient = circle_grad
	_soft_circle_tex.width = 24
	_soft_circle_tex.height = 24
	_soft_circle_tex.fill = GradientTexture2D.FILL_RADIAL
	_soft_circle_tex.fill_from = Vector2(0.5, 0.5)
	_soft_circle_tex.fill_to = Vector2(0.5, 0.0)

	# 2. Hạt elip ngang lấp lánh mặt nước (River Shimmer)
	var shimmer_grad: Gradient = Gradient.new()
	shimmer_grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	shimmer_grad.colors = PackedColorArray([
		Color(1.0, 1.0, 0.95, 0.95),
		Color(0.85, 0.96, 1.0, 0.45),
		Color(0.75, 0.92, 1.0, 0.0)
	])
	_shimmer_ellipse_tex = GradientTexture2D.new()
	_shimmer_ellipse_tex.gradient = shimmer_grad
	_shimmer_ellipse_tex.width = 28
	_shimmer_ellipse_tex.height = 10
	_shimmer_ellipse_tex.fill = GradientTexture2D.FILL_RADIAL
	_shimmer_ellipse_tex.fill_from = Vector2(0.5, 0.5)
	_shimmer_ellipse_tex.fill_to = Vector2(0.5, 0.0)

	# 3. Cánh hoa anh đào mềm (Sakura Petal)
	var petal_grad: Gradient = Gradient.new()
	petal_grad.offsets = PackedFloat32Array([0.0, 0.65, 1.0])
	petal_grad.colors = PackedColorArray([
		Color(1.0, 0.92, 0.95, 1.0),
		Color(1.0, 0.76, 0.86, 0.85),
		Color(0.98, 0.68, 0.80, 0.0)
	])
	_petal_ellipse_tex = GradientTexture2D.new()
	_petal_ellipse_tex.gradient = petal_grad
	_petal_ellipse_tex.width = 16
	_petal_ellipse_tex.height = 10
	_petal_ellipse_tex.fill = GradientTexture2D.FILL_RADIAL
	_petal_ellipse_tex.fill_from = Vector2(0.5, 0.5)
	_petal_ellipse_tex.fill_to = Vector2(0.5, 0.0)

	# 4. Quầng sáng đèn lồng (Lantern Halo Radial Glow)
	var halo_grad: Gradient = Gradient.new()
	halo_grad.offsets = PackedFloat32Array([0.0, 0.35, 0.75, 1.0])
	halo_grad.colors = PackedColorArray([
		Color(1.0, 0.92, 0.68, 0.85),
		Color(1.0, 0.76, 0.38, 0.42),
		Color(0.98, 0.58, 0.22, 0.12),
		Color(0.95, 0.45, 0.15, 0.0)
	])
	_halo_radial_tex = GradientTexture2D.new()
	_halo_radial_tex.gradient = halo_grad
	_halo_radial_tex.width = 160
	_halo_radial_tex.height = 160
	_halo_radial_tex.fill = GradientTexture2D.FILL_RADIAL
	_halo_radial_tex.fill_from = Vector2(0.5, 0.5)
	_halo_radial_tex.fill_to = Vector2(0.5, 0.0)

	# 5. Vòng gợn nước mưa (Rain Ripple Ring)
	var ripple_grad: Gradient = Gradient.new()
	ripple_grad.offsets = PackedFloat32Array([0.0, 0.55, 0.78, 1.0])
	ripple_grad.colors = PackedColorArray([
		Color(0.85, 0.95, 1.0, 0.0),
		Color(0.85, 0.95, 1.0, 0.08),
		Color(0.90, 0.97, 1.0, 0.55),
		Color(0.85, 0.95, 1.0, 0.0)
	])
	_ripple_ring_tex = GradientTexture2D.new()
	_ripple_ring_tex.gradient = ripple_grad
	_ripple_ring_tex.width = 28
	_ripple_ring_tex.height = 16
	_ripple_ring_tex.fill = GradientTexture2D.FILL_RADIAL
	_ripple_ring_tex.fill_from = Vector2(0.5, 0.5)
	_ripple_ring_tex.fill_to = Vector2(0.5, 0.0)

## Lớp 1: Mặt nước sông lấp lánh, cánh hoa trôi trên sông & gợn sóng mưa
func _build_river_fx_layer() -> void:
	_river_fx_root = Node2D.new()
	_river_fx_root.name = "RiverFXRoot"
	_river_fx_root.z_as_relative = false
	_river_fx_root.z_index = 2
	add_child(_river_fx_root)

	var shimmer_ramp: Gradient = Gradient.new()
	shimmer_ramp.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	shimmer_ramp.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 0.0),
		Color(1.0, 0.98, 0.86, 0.75),
		Color(0.82, 0.96, 1.0, 0.75),
		Color(1.0, 1.0, 1.0, 0.0)
	])

	# Nhánh sông phía Bắc cầu gỗ (x = 880, y = 120..580)
	_river_shimmer_north = CPUParticles2D.new()
	_river_shimmer_north.name = "RiverShimmerNorth"
	_river_shimmer_north.position = Vector2(880.0, 350.0)
	_river_shimmer_north.material = _additive_mat
	_river_shimmer_north.texture = _shimmer_ellipse_tex
	_river_shimmer_north.amount = 28
	_river_shimmer_north.lifetime = 2.6
	_river_shimmer_north.preprocess = 1.5
	_river_shimmer_north.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_river_shimmer_north.emission_rect_extents = Vector2(46.0, 220.0)
	_river_shimmer_north.direction = Vector2(0.0, 1.0)
	_river_shimmer_north.spread = 15.0
	_river_shimmer_north.gravity = Vector2.ZERO
	_river_shimmer_north.initial_velocity_min = 4.0
	_river_shimmer_north.initial_velocity_max = 10.0
	_river_shimmer_north.scale_amount_min = 0.45
	_river_shimmer_north.scale_amount_max = 1.05
	_river_shimmer_north.color_ramp = shimmer_ramp
	_river_fx_root.add_child(_river_shimmer_north)

	# Nhánh sông phía Nam cầu gỗ (x = 890, y = 710..960)
	_river_shimmer_south = CPUParticles2D.new()
	_river_shimmer_south.name = "RiverShimmerSouth"
	_river_shimmer_south.position = Vector2(890.0, 835.0)
	_river_shimmer_south.material = _additive_mat
	_river_shimmer_south.texture = _shimmer_ellipse_tex
	_river_shimmer_south.amount = 18
	_river_shimmer_south.lifetime = 2.6
	_river_shimmer_south.preprocess = 1.5
	_river_shimmer_south.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_river_shimmer_south.emission_rect_extents = Vector2(48.0, 125.0)
	_river_shimmer_south.direction = Vector2(0.0, 1.0)
	_river_shimmer_south.spread = 15.0
	_river_shimmer_south.gravity = Vector2.ZERO
	_river_shimmer_south.initial_velocity_min = 4.0
	_river_shimmer_south.initial_velocity_max = 10.0
	_river_shimmer_south.scale_amount_min = 0.45
	_river_shimmer_south.scale_amount_max = 1.05
	_river_shimmer_south.color_ramp = shimmer_ramp
	_river_fx_root.add_child(_river_shimmer_south)

	# Cánh hoa anh đào trôi nhẹ dọc dòng sông
	var petal_ramp: Gradient = Gradient.new()
	petal_ramp.offsets = PackedFloat32Array([0.0, 0.15, 0.85, 1.0])
	petal_ramp.colors = PackedColorArray([
		Color(1.0, 0.82, 0.88, 0.0),
		Color(1.0, 0.85, 0.90, 0.82),
		Color(1.0, 0.80, 0.88, 0.82),
		Color(1.0, 0.82, 0.88, 0.0)
	])

	_floating_petals = CPUParticles2D.new()
	_floating_petals.name = "RiverFloatingPetals"
	_floating_petals.position = Vector2(885.0, 480.0)
	_floating_petals.texture = _petal_ellipse_tex
	_floating_petals.amount = 16
	_floating_petals.lifetime = 6.5
	_floating_petals.preprocess = 3.0
	_floating_petals.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_floating_petals.emission_rect_extents = Vector2(36.0, 360.0)
	_floating_petals.direction = Vector2(0.08, 1.0)
	_floating_petals.spread = 12.0
	_floating_petals.gravity = Vector2(1.5, 4.0)
	_floating_petals.initial_velocity_min = 12.0
	_floating_petals.initial_velocity_max = 22.0
	_floating_petals.angular_velocity_min = -25.0
	_floating_petals.angular_velocity_max = 25.0
	_floating_petals.scale_amount_min = 0.55
	_floating_petals.scale_amount_max = 0.95
	_floating_petals.color_ramp = petal_ramp
	_river_fx_root.add_child(_floating_petals)

	# Gợn nước mưa trên mặt sông (chỉ bật khi COZY_RAIN)
	_rain_ripples = CPUParticles2D.new()
	_rain_ripples.name = "RiverRainRipples"
	_rain_ripples.position = Vector2(885.0, 500.0)
	_rain_ripples.texture = _ripple_ring_tex
	_rain_ripples.emitting = false
	_rain_ripples.amount = 26
	_rain_ripples.lifetime = 0.95
	_rain_ripples.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_rain_ripples.emission_rect_extents = Vector2(48.0, 380.0)
	_rain_ripples.gravity = Vector2.ZERO
	_rain_ripples.initial_velocity_min = 0.0
	_rain_ripples.initial_velocity_max = 0.0
	_rain_ripples.scale_amount_min = 0.35
	_rain_ripples.scale_amount_max = 1.25
	_rain_ripples.color_ramp = shimmer_ramp
	_river_fx_root.add_child(_rain_ripples)

## Lớp 2: Tia nắng chéo Golden-Hour (Shader gl_compatibility nhẹ nhàng)
func _build_sunbeams_layer() -> void:
	_sunbeam_root = Node2D.new()
	_sunbeam_root.name = "GoldenSunbeamsRoot"
	_sunbeam_root.z_as_relative = false
	_sunbeam_root.z_index = 22
	add_child(_sunbeam_root)

	var ray_shader: Shader = Shader.new()
	ray_shader.code = """
shader_type canvas_item;
render_mode blend_add;

uniform vec4 ray_color : source_color = vec4(1.0, 0.92, 0.72, 0.16);
uniform float pulse_offset = 0.0;

void fragment() {
	float edge_x = sin(UV.x * 3.14159265);
	float fade_y = pow(clamp(1.0 - UV.y, 0.0, 1.0), 1.35);
	float shimmer = 0.82 + 0.18 * sin(TIME * 0.9 + pulse_offset + UV.x * 4.5);
	float alpha = edge_x * edge_x * fade_y * ray_color.a * shimmer;
	COLOR = vec4(ray_color.rgb, alpha);
}
"""
	var beam_tex: GradientTexture2D = GradientTexture2D.new()
	var g: Gradient = Gradient.new()
	g.colors = PackedColorArray([Color.WHITE, Color.WHITE])
	beam_tex.gradient = g
	beam_tex.width = 64
	beam_tex.height = 64

	var beam_configs: Array[Dictionary] = [
		{"pos": Vector2(280.0, 220.0), "scale": Vector2(3.2, 9.5), "rot": -0.42, "phase": 0.0},
		{"pos": Vector2(560.0, 260.0), "scale": Vector2(3.8, 10.5), "rot": -0.42, "phase": 1.6},
		{"pos": Vector2(880.0, 240.0), "scale": Vector2(3.0, 9.2), "rot": -0.42, "phase": 3.1},
		{"pos": Vector2(1260.0, 230.0), "scale": Vector2(3.6, 10.0), "rot": -0.42, "phase": 4.5},
		{"pos": Vector2(1580.0, 250.0), "scale": Vector2(3.2, 9.5), "rot": -0.42, "phase": 5.8}
	]

	for cfg: Dictionary in beam_configs:
		var sp: Sprite2D = Sprite2D.new()
		sp.name = "SkySunbeamBackdrop_" + str(_sunbeam_sprites.size())
		sp.texture = beam_tex
		sp.position = cfg["pos"] as Vector2
		sp.scale = cfg["scale"] as Vector2
		sp.rotation = float(cfg["rot"])
		var mat: ShaderMaterial = ShaderMaterial.new()
		mat.shader = ray_shader
		mat.set_shader_parameter("pulse_offset", float(cfg["phase"]))
		sp.material = mat
		_sunbeam_root.add_child(sp)
		_sunbeam_sprites.append(sp)

## Lớp 3: Hạt nắng ấm (SunMotes), Hoa anh đào bay (SakuraBreeze) & Đom đóm đêm (Fireflies)
func _build_air_particles_layer() -> void:
	_air_fx_root = Node2D.new()
	_air_fx_root.name = "AirAtmosphereParticlesRoot"
	_air_fx_root.z_as_relative = false
	_air_fx_root.z_index = 24
	add_child(_air_fx_root)

	# Ramp mượt cho hạt nắng & đom đóm
	var glow_ramp: Gradient = Gradient.new()
	glow_ramp.offsets = PackedFloat32Array([0.0, 0.25, 0.75, 1.0])
	glow_ramp.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 0.0),
		Color(1.0, 1.0, 1.0, 0.85),
		Color(1.0, 0.95, 0.80, 0.85),
		Color(1.0, 1.0, 1.0, 0.0)
	])

	# 1. Hạt nắng ấm Bờ Tây (Nông trại chính) & Bờ Đông (Sở thú)
	_sun_motes_west = _create_sun_motes_emitter("SunMotesWest", Vector2(440.0, 500.0), Vector2(380.0, 360.0), 28, glow_ramp)
	_sun_motes_east = _create_sun_motes_emitter("SunMotesEast", Vector2(1420.0, 420.0), Vector2(420.0, 320.0), 26, glow_ramp)
	_air_fx_root.add_child(_sun_motes_west)
	_air_fx_root.add_child(_sun_motes_east)

	# 2. Cánh hoa anh đào bay trong gió (Sakura Breeze)
	var sakura_ramp: Gradient = Gradient.new()
	sakura_ramp.offsets = PackedFloat32Array([0.0, 0.15, 0.85, 1.0])
	sakura_ramp.colors = PackedColorArray([
		Color(1.0, 0.84, 0.90, 0.0),
		Color(1.0, 0.86, 0.92, 0.90),
		Color(1.0, 0.78, 0.88, 0.88),
		Color(1.0, 0.84, 0.90, 0.0)
	])

	_sakura_breeze_north = _create_sakura_emitter("SakuraBreezeNorth", Vector2(540.0, 260.0), Vector2(360.0, 180.0), 18, sakura_ramp)
	_sakura_breeze_east = _create_sakura_emitter("SakuraBreezeEast", Vector2(1380.0, 440.0), Vector2(380.0, 340.0), 24, sakura_ramp)
	_air_fx_root.add_child(_sakura_breeze_north)
	_air_fx_root.add_child(_sakura_breeze_east)

	# 3. Đom đóm đêm sinh thái (Fireflies)
	var firefly_ramp: Gradient = Gradient.new()
	firefly_ramp.offsets = PackedFloat32Array([0.0, 0.2, 0.5, 0.8, 1.0])
	firefly_ramp.colors = PackedColorArray([
		Color(0.65, 1.0, 0.35, 0.0),
		Color(0.82, 1.0, 0.45, 0.95),
		Color(1.0, 0.96, 0.52, 0.35),
		Color(0.78, 1.0, 0.42, 0.95),
		Color(0.65, 1.0, 0.35, 0.0)
	])

	_fireflies_west = _create_firefly_emitter("FirefliesWest", Vector2(520.0, 560.0), Vector2(420.0, 340.0), 24, firefly_ramp)
	_fireflies_east = _create_firefly_emitter("FirefliesEast", Vector2(1320.0, 480.0), Vector2(420.0, 340.0), 24, firefly_ramp)
	_air_fx_root.add_child(_fireflies_west)
	_air_fx_root.add_child(_fireflies_east)

func _create_sun_motes_emitter(node_name: String, pos: Vector2, extents: Vector2, count: int, ramp: Gradient) -> CPUParticles2D:
	var p: CPUParticles2D = CPUParticles2D.new()
	p.name = node_name
	p.position = pos
	p.material = _additive_mat
	p.texture = _soft_circle_tex
	p.amount = count
	p.lifetime = 4.5
	p.preprocess = 2.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = extents
	p.direction = Vector2(0.6, -0.8)
	p.spread = 180.0
	p.gravity = Vector2(2.0, -3.5)
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 11.0
	p.scale_amount_min = 0.35
	p.scale_amount_max = 0.85
	p.color = Color(1.0, 0.95, 0.78, 0.55)
	p.color_ramp = ramp
	return p

func _create_sakura_emitter(node_name: String, pos: Vector2, extents: Vector2, count: int, ramp: Gradient) -> CPUParticles2D:
	var p: CPUParticles2D = CPUParticles2D.new()
	p.name = node_name
	p.position = pos
	p.texture = _petal_ellipse_tex
	p.amount = count
	p.lifetime = 5.2
	p.preprocess = 2.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = extents
	p.direction = Vector2(0.75, 0.65)
	p.spread = 28.0
	p.gravity = Vector2(6.5, 11.0)
	p.initial_velocity_min = 18.0
	p.initial_velocity_max = 34.0
	p.angular_velocity_min = -65.0
	p.angular_velocity_max = 65.0
	p.tangential_accel_min = -8.0
	p.tangential_accel_max = 8.0
	p.scale_amount_min = 0.55
	p.scale_amount_max = 1.05
	p.color_ramp = ramp
	return p

func _create_firefly_emitter(node_name: String, pos: Vector2, extents: Vector2, count: int, ramp: Gradient) -> CPUParticles2D:
	var p: CPUParticles2D = CPUParticles2D.new()
	p.name = node_name
	p.position = pos
	p.material = _additive_mat
	p.texture = _soft_circle_tex
	p.emitting = false
	p.amount = count
	p.lifetime = 3.8
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = extents
	p.direction = Vector2(0.0, -1.0)
	p.spread = 180.0
	p.gravity = Vector2(0.0, -2.0)
	p.initial_velocity_min = 8.0
	p.initial_velocity_max = 18.0
	p.tangential_accel_min = -12.0
	p.tangential_accel_max = 12.0
	p.scale_amount_min = 0.45
	p.scale_amount_max = 0.95
	p.color_ramp = ramp
	return p

## Lớp 4: Quầng sáng ấm áp quanh các đèn lồng (LanternGlowRoot) & dọc cầu gỗ
func _setup_lantern_halos() -> void:
	var parent_node: Node = get_parent()
	if parent_node == null:
		return
	var lantern_root: Node2D = parent_node.get_node_or_null("LanternGlowRoot") as Node2D
	if lantern_root == null:
		return

	_lantern_halos_root = Node2D.new()
	_lantern_halos_root.name = "WarmLanternHalos"
	lantern_root.add_child(_lantern_halos_root)

	# Gắn quầng sáng cho các đèn lồng có sẵn trong scene
	for child: Node in lantern_root.get_children():
		if child is Sprite2D and child != _lantern_halos_root:
			var lantern_sp: Sprite2D = child as Sprite2D
			_add_halo_at_position(lantern_sp.position, 1.35)

	# Bổ sung quầng sáng ấm tại 2 đầu Cầu Gỗ và Cổng Sở Thú vào ban đêm
	var extra_lantern_positions: Array[Vector2] = [
		Vector2(780.0, 635.0),
		Vector2(980.0, 635.0),
		Vector2(1280.0, 585.0),
		Vector2(435.0, 635.0)
	]
	for pos: Vector2 in extra_lantern_positions:
		_add_halo_at_position(pos, 1.15)

func _add_halo_at_position(pos: Vector2, base_scale: float) -> void:
	if _lantern_halos_root == null:
		return
	var halo: Sprite2D = Sprite2D.new()
	halo.name = "SkyLanternHaloBackdrop_" + str(_lantern_halo_sprites.size())
	halo.texture = _halo_radial_tex
	halo.material = _additive_mat
	halo.position = pos
	halo.scale = Vector2(base_scale, base_scale)
	halo.set_meta("base_scale", base_scale)
	halo.set_meta("phase", float(_lantern_halo_sprites.size()) * 1.37)
	_lantern_halos_root.add_child(halo)
	_lantern_halo_sprites.append(halo)

func _animate_lantern_halos() -> void:
	if _lantern_halos_root == null or not _lantern_halos_root.is_visible_in_tree():
		return
	for halo: Sprite2D in _lantern_halo_sprites:
		if not is_instance_valid(halo):
			continue
		var base_s: float = float(halo.get_meta("base_scale", 1.2))
		var ph: float = float(halo.get_meta("phase", 0.0))
		var pulse: float = 1.0 + sin(_time_accum * 2.8 + ph) * 0.08 + cos(_time_accum * 5.3 + ph) * 0.03
		halo.scale = Vector2(base_s * pulse, base_s * pulse)
		halo.modulate.a = 0.82 + sin(_time_accum * 3.1 + ph) * 0.14

func _animate_sunbeams() -> void:
	if _sunbeam_root == null or not _sunbeam_root.visible:
		return
	for i: int in range(_sunbeam_sprites.size()):
		var sp: Sprite2D = _sunbeam_sprites[i]
		if is_instance_valid(sp):
			sp.rotation = -0.42 + sin(_time_accum * 0.35 + float(i) * 0.9) * 0.025

## Cập nhật đồng bộ trạng thái bầu không khí theo Khung Giờ (Phase) và Thời Tiết (Weather)
func apply_atmosphere_state(phase_key: String, weather_key: String) -> void:
	_current_phase_key = phase_key
	_current_weather_key = weather_key

	var is_raining: bool = (weather_key == "cozy_rain")
	var is_night: bool = (phase_key == "night")
	var is_sunset: bool = (phase_key == "sunset")
	var is_dawn: bool = (phase_key == "dawn")

	# 1. Điều chỉnh Tia Nắng Golden-Hour (Sunbeams) & Hạt Nắng (SunMotes)
	if _sunbeam_root != null:
		_sunbeam_root.visible = (not is_raining) and (not is_night)
		var ray_col: Color = Color(1.0, 0.95, 0.78, 0.12)
		if is_dawn:
			ray_col = Color(1.0, 0.84, 0.70, 0.19)
		elif is_sunset:
			ray_col = Color(1.0, 0.72, 0.48, 0.22)
		for sp: Sprite2D in _sunbeam_sprites:
			if is_instance_valid(sp) and sp.material is ShaderMaterial:
				(sp.material as ShaderMaterial).set_shader_parameter("ray_color", ray_col)

	var show_sun_motes: bool = (not is_raining) and (not is_night)
	var mote_color: Color = Color(1.0, 0.96, 0.80, 0.48)
	if is_dawn:
		mote_color = Color(1.0, 0.84, 0.72, 0.58)
	elif is_sunset:
		mote_color = Color(1.0, 0.74, 0.50, 0.65)

	if _sun_motes_west != null:
		_sun_motes_west.emitting = show_sun_motes
		_sun_motes_west.color = mote_color
	if _sun_motes_east != null:
		_sun_motes_east.emitting = show_sun_motes
		_sun_motes_east.color = mote_color

	# 2. Điều chỉnh Hoa Anh Đào Bay (Sakura Breeze)
	var show_sakura: bool = not is_raining
	var sakura_speed_mult: float = 1.25 if weather_key == "balloon_festival" else 1.0
	if _sakura_breeze_north != null:
		_sakura_breeze_north.emitting = show_sakura
		_sakura_breeze_north.speed_scale = sakura_speed_mult
	if _sakura_breeze_east != null:
		_sakura_breeze_east.emitting = show_sakura
		_sakura_breeze_east.speed_scale = sakura_speed_mult

	# 3. Điều chỉnh Đom Đóm Đêm (Fireflies)
	var show_fireflies: bool = (is_night or is_sunset) and (not is_raining)
	if _fireflies_west != null:
		_fireflies_west.emitting = show_fireflies
	if _fireflies_east != null:
		_fireflies_east.emitting = show_fireflies

	# 4. Điều chỉnh Mặt Nước Sông Lấp Lánh & Gợn Sóng Mưa
	var shimmer_col: Color = Color(1.0, 0.98, 0.88, 0.80)
	if is_sunset:
		shimmer_col = Color(1.0, 0.78, 0.55, 0.85)
	elif is_night:
		shimmer_col = Color(0.68, 0.85, 1.0, 0.55)
	elif is_dawn:
		shimmer_col = Color(1.0, 0.86, 0.78, 0.80)

	if _river_shimmer_north != null:
		_river_shimmer_north.emitting = not is_raining
		_river_shimmer_north.color = shimmer_col
	if _river_shimmer_south != null:
		_river_shimmer_south.emitting = not is_raining
		_river_shimmer_south.color = shimmer_col
	if _rain_ripples != null:
		_rain_ripples.emitting = is_raining
	if _floating_petals != null:
		_floating_petals.emitting = true
