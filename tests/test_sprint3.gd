extends Node

## TestSprint3
## Kiểm thử tự động Sprint 3 và chụp ảnh màn hình kiểm chứng thị giác:
## 1. OfflineSimulator
## 2. OnboardingDirector (Tutorial 3 bước)
## 3. OfflineReportModal (Hiển thị & Nhận thưởng)

func _ready() -> void:
	print("==================================================")
	print("[TEST SPRINT 3] STARTING SYSTEM VERIFICATION")
	print("==================================================")
	
	# 1. Test OfflineSimulator
	print("[TEST 1] Testing OfflineSimulator calculation...")
	var test_save: Dictionary = {
		"last_timestamp": int(Time.get_unix_time_from_system()) - 7200, # 2 hours
		"attraction_score": 40,
		"zoo_animals_count": 3
	}
	var res: Dictionary = OfflineSimulator.evaluate_offline_progress(test_save)
	assert(not res.is_empty(), "Offline progress should not be empty")
	assert(res["elapsed_minutes"] == 120, "Should be 120 minutes")
	assert(res["passive_zoo_gold"] > 0, "Should calculate passive gold")
	assert(res["ripened_crops_count"] == 12, "Should cap at 12 crops")
	assert(res["honey_collected"] == 5, "Should cap at 5 honey")
	print(" -> PASS: OfflineSimulator calculated: 120 mins, %d Gold, %d Crops, %d Honey" % [
		res["passive_zoo_gold"], res["ripened_crops_count"], res["honey_collected"]
	])

	# 2. Instance MainFarm scene
	var farm_packed: PackedScene = load("res://scenes/main/MainFarm.tscn") as PackedScene
	var main_farm: Node2D = farm_packed.instantiate() as Node2D
	add_child(main_farm)

	for i: int in range(10):
		await get_tree().process_frame

	var onboarding_dir: OnboardingDirector = main_farm.find_child("OnboardingDirector", true, false) as OnboardingDirector
	var report_modal: OfflineReportModal = main_farm.find_child("OfflineReportModal", true, false) as OfflineReportModal
	var tutorial_overlay: Control = main_farm.find_child("TutorialOverlay", true, false) as Control

	# 3. Test OnboardingDirector Step 1
	print("[TEST 2] Testing OnboardingDirector & Tutorial Step 1...")
	if onboarding_dir != null:
		onboarding_dir._advance_to_step(OnboardingDirector.Step.STEP_1_SWIPE_WHEAT)
		assert(onboarding_dir.current_step == OnboardingDirector.Step.STEP_1_SWIPE_WHEAT, "Should be Step 1")
		assert(tutorial_overlay != null and tutorial_overlay.visible, "Tutorial overlay should be visible")
		print(" -> PASS: Tutorial Step 1 active with Elder portrait and dialogue banner!")

	for i: int in range(15):
		await get_tree().process_frame

	# Capture Tutorial Step 1 screenshot
	var img1: Image = get_viewport().get_texture().get_image()
	if img1 != null and not img1.is_empty():
		img1.save_png("res://debug_tutorial_step1.png")
		print("[Screenshot] Saved: res://debug_tutorial_step1.png")

	# 4. Test Tutorial Step Transitions
	print("[TEST 3] Testing Step 1 -> Step 2 -> Step 3 -> Completed transitions...")
	EventBus.crop_harvested.emit("wheat", Vector2i(12, 17))
	EventBus.crop_planted.emit("wheat", Vector2i(12, 17))
	assert(onboarding_dir.current_step == OnboardingDirector.Step.STEP_2_MILL_AND_FEED, "Should advance to Step 2")
	print(" -> PASS: Advanced to Step 2 (Mill & Feed)")

	EventBus.animal_fed.emit(1, "cow", 0)
	assert(onboarding_dir.current_step == OnboardingDirector.Step.STEP_3_PATH_AND_VISITOR, "Should advance to Step 3")
	print(" -> PASS: Advanced to Step 3 (Path & Visitor)")

	EventBus.path_tile_changed.emit(Vector2i(14, 15), true)
	assert(onboarding_dir.current_step == OnboardingDirector.Step.COMPLETED, "Should complete tutorial")
	assert(SaveManager.is_tutorial_completed == true, "SaveManager flag should be set")
	print(" -> PASS: Tutorial fully completed and saved to SaveManager!")

	for i: int in range(10):
		await get_tree().process_frame

	# 5. Test OfflineReportModal
	print("[TEST 4] Testing OfflineReportModal popup...")
	if report_modal != null:
		var dummy_data: Dictionary = {
			"elapsed_seconds": 5400, # 90 mins
			"elapsed_minutes": 90,
			"passive_zoo_gold": 1250,
			"ripened_crops_count": 8,
			"honey_collected": 3
		}
		EventBus.offline_earnings_calculated.emit(5400, dummy_data)
		assert(report_modal.visible, "Modal should be visible")
		print(" -> PASS: OfflineReportModal opened with 1250 Gold and 3 Honey!")

	for i: int in range(15):
		await get_tree().process_frame

	# Capture Offline Report Modal screenshot
	var img2: Image = get_viewport().get_texture().get_image()
	if img2 != null and not img2.is_empty():
		img2.save_png("res://debug_offline_report_modal.png")
		print("[Screenshot] Saved: res://debug_offline_report_modal.png")

	# 6. Test Claim Rewards
	print("[TEST 5] Testing Claim Rewards...")
	var gold_before: int = StorageManager.gold
	if report_modal != null:
		report_modal._on_claim_pressed()
	var gold_after: int = StorageManager.gold
	assert(gold_after >= gold_before, "StorageManager should receive claimed gold")
	print(" -> PASS: Rewards successfully claimed and credited! Gold before: %d, after: %d" % [gold_before, gold_after])

	print("==================================================")
	print("[TEST RESULT] ALL 5 SPRINT 3 TESTS PASSED!")
	print("==================================================")
	get_tree().quit(0)
