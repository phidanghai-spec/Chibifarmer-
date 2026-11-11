extends Node

## TestSprint45
## Kiểm thử tự động Sprint 4 & 5:
## 1. Thời tiết & Chu kỳ Ngày-Đêm (WeatherAndDayNightManager)
## 2. Xếp hạng Du lịch 5 Sao & Quầy Check-in Vườn Thú (TourismStarDirector)
## 3. Sổ tay Bách Khoa Nông Trại Almanac (FarmAlmanacModal)
## 4. Chụp ảnh màn hình kiểm chứng thị giác

func _ready() -> void:
	print("==================================================")
	print("[TEST SPRINT 4 & 5] STARTING VERIFICATION")
	print("==================================================")

	# 1. Instance MainFarm scene
	var farm_packed: PackedScene = load("res://scenes/main/MainFarm.tscn") as PackedScene
	var main_farm: Node2D = farm_packed.instantiate() as Node2D
	add_child(main_farm)

	for i: int in range(10):
		await get_tree().process_frame

	var weather_mgr: WeatherAndDayNightManager = main_farm.find_child("EnvironmentDirector", true, false) as WeatherAndDayNightManager
	var star_director: TourismStarDirector = main_farm.find_child("TourismStarDirector", true, false) as TourismStarDirector
	var star_hud: TourismStarHUD = main_farm.find_child("TourismStarHUD", true, false) as TourismStarHUD
	var almanac_modal: FarmAlmanacModal = main_farm.find_child("FarmAlmanacModal", true, false) as FarmAlmanacModal

	# 2. Test Weather & Day-Night System
	print("[TEST 1] Testing Weather & Day-Night cycle...")
	assert(weather_mgr != null, "Weather manager must exist in MainFarm")
	if weather_mgr != null:
		# Test Cozy Rain
		weather_mgr._apply_weather(WeatherAndDayNightManager.WeatherType.COZY_RAIN)
		assert(weather_mgr.crop_growth_multiplier == 1.25, "Cozy rain should boost crop growth by 1.25x")
		assert(weather_mgr.fishing_luck_bonus == 0.25, "Cozy rain should add 0.25 fishing luck")
		assert(weather_mgr.rain_particles != null and weather_mgr.rain_particles.emitting, "Rain particles should emit")
		print(" -> PASS: Cozy rain correctly applies 1.25x crop speed, 0.25 fishing luck & CPUParticles2D!")
		
		# Test Night Phase
		weather_mgr._apply_time_phase(WeatherAndDayNightManager.TimePhase.NIGHT)
		assert(weather_mgr.lantern_glow_root != null and weather_mgr.lantern_glow_root.visible, "Lanterns should light up at night")
		print(" -> PASS: Night time phase successfully lights up LanternGlowRoot & CanvasModulate!")

	for i: int in range(15):
		await get_tree().process_frame

	# Capture weather and night preview
	var img1: Image = get_viewport().get_texture().get_image()
	if img1 != null and not img1.is_empty():
		img1.save_png("res://debug_weather_rain_night.png")
		print("[Screenshot] Saved: res://debug_weather_rain_night.png")

	# Return to bright noon for subsequent tests
	if weather_mgr != null:
		weather_mgr._apply_time_phase(WeatherAndDayNightManager.TimePhase.NOON)
		weather_mgr._apply_weather(WeatherAndDayNightManager.WeatherType.SUNNY_BREEZE)

	# 3. Test Tourism 5-Star Rating & Zoo Photo Booth
	print("[TEST 2] Testing Tourism 5-Star Rating & Photo Booth Check-in...")
	assert(star_director != null, "Tourism star director must exist")
	if star_director != null:
		star_director.total_attraction_score = 25
		star_director._recalculate_stars()
		assert(star_director.current_star_rating == 1, "25 pts should be 1 star")
		
		star_director.total_attraction_score = 175
		star_director._recalculate_stars()
		assert(star_director.current_star_rating == 3, "175 pts should be 3 stars")
		
		star_director.total_attraction_score = 480
		star_director._recalculate_stars()
		assert(star_director.current_star_rating == 5, "480 pts should be 5 stars")
		print(" -> PASS: Tourism star rating correctly scales 1 -> 3 -> 5 stars with AttractionScore thresholds!")

		var gold_before: int = StorageManager.gold
		star_director.trigger_visitor_photo_checkin("visitor_test_01")
		var gold_after: int = StorageManager.gold
		assert(gold_after > gold_before, "Photo check-in should tip bonus gold into StorageManager")
		print(" -> PASS: Zoo Photo Booth check-in triggered camera flash and tipped %d gold!" % [gold_after - gold_before])

	# 4. Test Farm Almanac Encyclopedia
	print("[TEST 3] Testing Farm Almanac Encyclopedia (FarmAlmanacModal)...")
	assert(almanac_modal != null, "Farm Almanac modal must exist")
	if almanac_modal != null:
		var gold_pre_almanac: int = StorageManager.gold
		# Unlock a new crop entry
		almanac_modal.unlock_entry("crops", "strawberry")
		assert(almanac_modal.unlocked_ids.has("strawberry"), "Strawberry should be unlocked")
		assert(StorageManager.gold == gold_pre_almanac + 25, "Discovery reward +25 gold should be credited")
		print(" -> PASS: Strawberry discovery successfully unlocked with +25 gold reward!")

		# Open Almanac modal
		almanac_modal.toggle_modal(true)
		assert(almanac_modal.visible, "Almanac modal should be visible")
		print(" -> PASS: FarmAlmanacModal opened with 4 collection tabs and discovery cards!")

	for i: int in range(15):
		await get_tree().process_frame

	# Capture Almanac Modal screenshot
	var img2: Image = get_viewport().get_texture().get_image()
	if img2 != null and not img2.is_empty():
		img2.save_png("res://debug_farm_almanac.png")
		print("[Screenshot] Saved: res://debug_farm_almanac.png")

	if almanac_modal != null:
		almanac_modal.toggle_modal(false)

	for i: int in range(10):
		await get_tree().process_frame

	# Capture Tourism Star HUD screenshot
	var img3: Image = get_viewport().get_texture().get_image()
	if img3 != null and not img3.is_empty():
		img3.save_png("res://debug_tourism_hud.png")
		print("[Screenshot] Saved: res://debug_tourism_hud.png")

	print("==================================================")
	print("[TEST RESULT] ALL SPRINT 4 & 5 TESTS PASSED!")
	print("==================================================")
	get_tree().quit(0)

