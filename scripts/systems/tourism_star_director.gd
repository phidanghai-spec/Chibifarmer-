class_name TourismStarDirector
extends Node

## TourismStarDirector
## Tính toán Xếp hạng Du Lịch 1-5 Sao từ AttractionScore & các chuồng thú Vườn Thú Bờ Tây
## Điều phối Quầy Check-in Du Lịch (ZooPhotoBooth) và chụp ảnh lưu niệm.
## 100% Static Typing GDScript 2.0.

const STAR_THRESHOLDS: Array[int] = [0, 30, 80, 160, 280, 450]

@export var photo_booth_area: Area2D
@export var camera_flash_light: PointLight2D
@export var star_icons_hbox: HBoxContainer
@export var attraction_label: Label

var total_attraction_score: int = 20
var current_star_rating: int = 1
var unlocked_zoo_species: Array[String] = ["zoo_capybara"]

func _ready() -> void:
	if camera_flash_light != null:
		camera_flash_light.enabled = false
		
	if GridManager != null:
		total_attraction_score = maxi(total_attraction_score, GridManager.total_attraction_score)
		
	# Đồng bộ danh sách thú từ SaveManager nếu có
	if SaveManager != null and SaveManager.zoo_data != null:
		for z_id: String in SaveManager.zoo_data:
			var z_info: Dictionary = SaveManager.zoo_data[z_id] as Dictionary
			if z_info.get("unlocked", false) and not unlocked_zoo_species.has(z_id):
				unlocked_zoo_species.append(z_id)
				
	EventBus.decor_placed.connect(_on_decor_placed)
	EventBus.attraction_score_changed.connect(_on_attraction_score_changed)
	EventBus.zoo_enclosure_unlocked.connect(func(animal_id: String) -> void:
		register_zoo_enclosure(animal_id, 35)
	)
	_recalculate_stars()

func register_zoo_enclosure(species_id: String, bonus_attraction: int) -> void:
	if not unlocked_zoo_species.has(species_id):
		unlocked_zoo_species.append(species_id)
	total_attraction_score += bonus_attraction
	_recalculate_stars()

func trigger_visitor_photo_checkin(visitor_id: String) -> void:
	if unlocked_zoo_species.is_empty():
		return
	var featured_animal: String = unlocked_zoo_species[randi() % unlocked_zoo_species.size()]
	var base_tip: int = 15 + (current_star_rating * 10)
	
	_play_camera_flash()
	AudioManager.play_sfx("camera_shutter")
	
	if has_node("/root/StorageManager"):
		var sm: Node = get_node("/root/StorageManager")
		if sm.has_method("add_gold"):
			sm.call("add_gold", base_tip)
			
	EventBus.zoo_photo_checkin_completed.emit(visitor_id, featured_animal, base_tip)

func _on_decor_placed(_decor_id: String, attraction_delta: int) -> void:
	total_attraction_score = maxi(0, total_attraction_score + attraction_delta)
	_recalculate_stars()

func _on_attraction_score_changed(new_score: int) -> void:
	total_attraction_score = maxi(total_attraction_score, new_score)
	_recalculate_stars()

func _recalculate_stars() -> void:
	var new_stars: int = 1
	for i: int in range(1, STAR_THRESHOLDS.size()):
		if total_attraction_score >= STAR_THRESHOLDS[i]:
			new_stars = i
	current_star_rating = clampi(new_stars, 1, 5)
	
	if attraction_label != null:
		attraction_label.text = "%d Sao (%d Điểm Thu Hút)" % [current_star_rating, total_attraction_score]
	EventBus.tourism_star_rating_updated.emit(current_star_rating, total_attraction_score)

func _play_camera_flash() -> void:
	if camera_flash_light == null:
		return
	camera_flash_light.enabled = true
	camera_flash_light.energy = 2.2
	var tween: Tween = create_tween()
	tween.tween_property(camera_flash_light, "energy", 0.0, 0.25)
	tween.tween_callback(func() -> void: camera_flash_light.enabled = false)
