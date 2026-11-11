class_name FarmAlmanacModal
extends PanelContainer

## FarmAlmanacModal
## Sổ tay Bách Khoa Toàn Thư Nông Trại Chibi (Sprint 5)
## Hiển thị bộ sưu tập 4 nhóm: Cây Trồng, Thú Nuôi & Zoo, Ẩm Thực, Du Khách
## Tự động mở khóa khi canh tác và thưởng tiền vàng khám phá.
## 100% Static Typing GDScript 2.0.

const CATEGORY_KEYS: Array[String] = ["crops", "animals", "recipes", "visitors"]

@onready var almanac_tabs: TabBar = $AlmanacVBox/AlmanacTabs
@onready var entry_grid: GridContainer = $AlmanacVBox/EntryGridScroll/EntryCardsGrid
@onready var detail_label: Label = $AlmanacVBox/DetailInspectorPanel/DetailTextLabel
@onready var btn_close: Button = get_node_or_null("AlmanacVBox/HeaderHBox/BtnCloseAlmanac") as Button

var unlocked_ids: Dictionary = {
	"wheat": true,
	"corn": true,
	"zoo_capybara": true,
	"cow_dairy": true,
	"bread_baguette": true,
	"visitor_backpacker": true
}

var _almanac_db: Dictionary = {}

func _ready() -> void:
	visible = false
	_init_almanac_database()
	_setup_tabs()
	if btn_close != null:
		btn_close.pressed.connect(func() -> void: toggle_modal(false))
		
	# Lắng nghe sự kiện để tự động mở khóa
	EventBus.crop_harvested.connect(func(crop_id: String, _pos: Vector2i) -> void:
		unlock_entry("crops", crop_id)
	)
	EventBus.field_harvested.connect(func(_inst_id: int, crop_id: String) -> void:
		unlock_entry("crops", crop_id)
	)
	EventBus.animal_fed.connect(func(_pen_id: Variant, animal_id: Variant, _f: Variant = 0) -> void:
		unlock_entry("animals", str(animal_id))
	)
	EventBus.zoo_enclosure_unlocked.connect(func(animal_id: String) -> void:
		unlock_entry("animals", animal_id)
	)
	EventBus.production_collected.connect(func(_mach_id: int, product_id: String) -> void:
		unlock_entry("recipes", product_id)
	)
	EventBus.visitor_spawned.connect(func(_vis_id: int, visitor_type: String) -> void:
		unlock_entry("visitors", visitor_type)
	)

func open_modal() -> void:
	toggle_modal(true)

func close_modal() -> void:
	toggle_modal(false)

func toggle_modal(open_state: bool) -> void:
	visible = open_state
	z_index = 100
	if open_state:
		AudioManager.play_sfx("page_flip")
		scale = Vector2(0.9, 0.9)
		var center_pivot: Vector2 = size * 0.5
		if center_pivot.is_zero_approx():
			center_pivot = custom_minimum_size * 0.5 if not custom_minimum_size.is_zero_approx() else Vector2(390.0, 260.0)
		pivot_offset = center_pivot
		var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2.ONE, 0.24)
		_populate_tab(almanac_tabs.current_tab if almanac_tabs != null else 0)
	EventBus.almanac_modal_toggled.emit(open_state)

func unlock_entry(category: String, item_id: String) -> void:
	if unlocked_ids.has(item_id):
		return
	unlocked_ids[item_id] = true
	var reward_gold: int = 25
	if has_node("/root/StorageManager"):
		var sm: Node = get_node("/root/StorageManager")
		if sm.has_method("add_gold"):
			sm.call("add_gold", reward_gold)
	EventBus.almanac_entry_unlocked.emit(category, item_id, reward_gold)

func _init_almanac_database() -> void:
	_almanac_db = {
		"crops": [
			{"id": "wheat", "name": "🌾 Lúa Mì Vàng", "desc": "Cây lương thực cơ bản cho Máy Xay Cám và Lò Bánh Mì."},
			{"id": "corn", "name": "🌽 Ngô Ngọt", "desc": "Nguyên liệu chính làm cám gà và nướng bánh mì ngô."},
			{"id": "carrot", "name": "🥕 Cà Rốt Giòn", "desc": "Món ăn yêu thích của đàn thỏ rừng và du khách tham quan."},
			{"id": "strawberry", "name": "🍓 Dâu Tây Đỏ", "desc": "Quả mọng ngọt ngào dùng cho Quầy Nước Ép và Lò Bánh Ngọt."},
			{"id": "sunflower", "name": "🌻 Hoa Hướng Dương", "desc": "Hoa mặt trời rực rỡ tăng điểm thu hút du khách bờ Đông."},
			{"id": "rose", "name": "🌹 Hoa Hồng Đỏ", "desc": "Hoa thơm ngát tăng điểm thu hút và làm đẹp cảnh quan."},
			{"id": "lavender", "name": "🪻 Hoa Oải Hương", "desc": "Màu tím lãng mạn xua muỗi và làm tinh dầu thơm."},
			{"id": "apple", "name": "🍎 Cây Táo Lâu Năm", "desc": "Sinh trưởng qua 3 giai đoạn, trĩu quả đỏ mọng mỗi mùa."},
			{"id": "mango", "name": "🥭 Cây Xoài Nhiệt Đới", "desc": "Cây ăn quả lâu năm cho bóng mát và xoài chín thơm lừng."}
		],
		"animals": [
			{"id": "cow", "name": "🐄 Bò Sữa Chibi", "desc": "Nhai cỏ thong thả trong chuồng gỗ, cho sữa tươi mỗi ngày."},
			{"id": "cow_dairy", "name": "🐄 Bò Sữa Chibi", "desc": "Nhai cỏ thong thả trong chuồng gỗ, cho sữa tươi mỗi ngày."},
			{"id": "chicken", "name": "🐔 Gà Đẻ Trứng", "desc": "Mổ thóc nhịp nhàng, cung cấp trứng gà tươi nguyên chất."},
			{"id": "pig", "name": "🐖 Heo Rừng Chibi", "desc": "Tắm bùn vui vẻ, thích ăn ngô ngọt và cám tươi."},
			{"id": "zoo_capybara", "name": "🤎 Chuột Lang Capybara", "desc": "Ngôi sao thân thiện nhất tại Khu Bảo Tồn Bờ Tây."},
			{"id": "zoo_panda", "name": "🐼 Gấu Trúc Panda", "desc": "Thú quý hiếm thích ăn trúc non, thu hút đông đảo du khách."},
			{"id": "zoo_giraffe", "name": "🦒 Hươu Cao Cổ", "desc": "Vươn cổ ngắm nhìn toàn cảnh nông trại từ bờ Tây sông."},
			{"id": "zoo_penguin", "name": "🐧 Chim Cánh Cụt", "desc": "Lạch bạch đáng yêu bên hồ nước mát trong khu bảo tồn."}
		],
		"recipes": [
			{"id": "bread", "name": "🥖 Bánh Mì Que", "desc": "Ra lò nóng hổi thơm nức mũi từ Lò Bánh Mì."},
			{"id": "bread_baguette", "name": "🥖 Bánh Mì Que", "desc": "Ra lò nóng hổi thơm nức mũi từ Lò Bánh Mì."},
			{"id": "corn_bread", "name": "🍞 Bánh Mì Ngô", "desc": "Bánh vàng ươm kết hợp ngô ngọt và trứng gà tươi."},
			{"id": "cookie", "name": "🍪 Bánh Quy Bơ", "desc": "Bánh giòn tan dùng bơ nguyên chất từ Xưởng Bơ Sữa."},
			{"id": "butter_cookie", "name": "🍪 Bánh Quy Bơ", "desc": "Bánh giòn tan dùng bơ nguyên chất từ Xưởng Bơ Sữa."},
			{"id": "cheese", "name": "🧀 Phô Mai Thơm Lừng", "desc": "Ủ từ sữa bò tươi nguyên chất, giá trị thương mại cao."},
			{"id": "honey", "name": "🍯 Hũ Mật Ong Rừng", "desc": "Thu hoạch từ Cây Tổ Ong Mật tại vườn hoa Tây."},
			{"id": "carrot_juice", "name": "🥤 Nước Ép Cà Rốt", "desc": "Nước uống bổ dưỡng từ Quầy Nước Ép Hoa Quả."}
		],
		"visitors": [
			{"id": "visitor_backpacker", "name": "🎒 Du Khách Ba Lô", "desc": "Đam mê chụp ảnh check-in bên Vườn Thú Bờ Tây."},
			{"id": "visitor_flower_girl", "name": "👒 Cô Gái Hái Hoa", "desc": "Thường mua hoa hồng, hướng dương và oải hương giá hời."},
			{"id": "visitor_chef", "name": "👨‍🍳 Đầu Bếp Thượng Lưu", "desc": "Khách VIP chuyên đặt mua cá tầm, mật ong và phô mai."},
			{"id": "visitor_carpenter", "name": "🪵 Bác Thợ Mộc", "desc": "Yêu thích các công trình gỗ và cảnh quan trang trại."},
			{"id": "visitor_shopper", "name": "🛍️ Khách Mua Sắm", "desc": "Thích ghé Sạp Hàng Ven Đường mua nông sản tươi."},
			{"id": "visitor_photographer", "name": "📸 Nhiếp Ảnh Gia", "desc": "Chuyên săn ảnh độc lạ tại Quầy Check-in Vườn Thú."}
		]
	}

func _setup_tabs() -> void:
	if almanac_tabs == null:
		return
	almanac_tabs.clear_tabs()
	almanac_tabs.add_tab("1. Cây Trồng (9)")
	almanac_tabs.add_tab("2. Thú Nuôi & Zoo (8)")
	almanac_tabs.add_tab("3. Ẩm Thực (8)")
	almanac_tabs.add_tab("4. Du Khách (6)")
	var tab_sel: StyleBoxFlat = StyleBoxFlat.new()
	tab_sel.bg_color = Color(0.96, 0.73, 0.19, 1.0)
	tab_sel.border_color = Color(0.48, 0.26, 0.12, 1.0)
	tab_sel.set_border_width_all(2)
	tab_sel.corner_radius_top_left = 10
	tab_sel.corner_radius_top_right = 10
	tab_sel.content_margin_left = 14
	tab_sel.content_margin_right = 14
	tab_sel.content_margin_top = 6
	tab_sel.content_margin_bottom = 6
	var tab_unsel: StyleBoxFlat = StyleBoxFlat.new()
	tab_unsel.bg_color = Color(0.93, 0.86, 0.74, 1.0)
	tab_unsel.border_color = Color(0.62, 0.42, 0.24, 1.0)
	tab_unsel.set_border_width_all(2)
	tab_unsel.corner_radius_top_left = 10
	tab_unsel.corner_radius_top_right = 10
	tab_unsel.content_margin_left = 14
	tab_unsel.content_margin_right = 14
	tab_unsel.content_margin_top = 6
	tab_unsel.content_margin_bottom = 6
	almanac_tabs.add_theme_stylebox_override("tab_selected", tab_sel)
	almanac_tabs.add_theme_stylebox_override("tab_unselected", tab_unsel)
	almanac_tabs.add_theme_stylebox_override("tab_hovered", tab_sel)
	almanac_tabs.add_theme_color_override("font_selected_color", Color(0.24, 0.11, 0.03, 1.0))
	almanac_tabs.add_theme_color_override("font_unselected_color", Color(0.42, 0.25, 0.12, 1.0))
	almanac_tabs.add_theme_color_override("font_hovered_color", Color(0.24, 0.11, 0.03, 1.0))
	almanac_tabs.tab_changed.connect(_populate_tab)

func _populate_tab(tab_idx: int) -> void:
	if entry_grid == null:
		return
	for child: Node in entry_grid.get_children():
		child.queue_free()
		
	var cat_key: String = CATEGORY_KEYS[clampi(tab_idx, 0, CATEGORY_KEYS.size() - 1)]
	var entries: Array = _almanac_db.get(cat_key, []) as Array
	
	if detail_label != null:
		detail_label.text = "Chọn một mục bên trên để xem chi tiết bách khoa nông trại."
	
	for entry_var: Variant in entries:
		if typeof(entry_var) == TYPE_DICTIONARY:
			var item: Dictionary = entry_var as Dictionary
			var item_id: String = str(item.get("id", ""))
			var is_discovered: bool = unlocked_ids.has(item_id)
			
			var btn: Button = Button.new()
			btn.custom_minimum_size = Vector2(165.0, 68.0)
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			
			var bstyle: StyleBoxFlat = StyleBoxFlat.new()
			bstyle.set_corner_radius_all(10)
			bstyle.border_width_left = 2
			bstyle.border_width_top = 2
			bstyle.border_width_right = 2
			bstyle.border_width_bottom = 3
			
			if is_discovered:
				bstyle.bg_color = Color(0.98, 0.94, 0.85, 1.0)
				bstyle.border_color = Color(0.65, 0.42, 0.20, 1.0)
				btn.add_theme_color_override("font_color", Color(0.35, 0.20, 0.10, 1.0))
				btn.text = str(item.get("name", ""))
			else:
				bstyle.bg_color = Color(0.85, 0.82, 0.78, 0.8)
				bstyle.border_color = Color(0.60, 0.55, 0.50, 1.0)
				btn.add_theme_color_override("font_color", Color(0.55, 0.50, 0.45, 1.0))
				btn.text = "❓ ??? (Chưa Mở)"
				
			btn.add_theme_stylebox_override("normal", bstyle)
			btn.add_theme_font_size_override("font_size", 13)
			
			btn.pressed.connect(func() -> void:
				AudioManager.play_sfx("ui_wood_click")
				if detail_label != null:
					if is_discovered:
						detail_label.text = "📖 %s:\n%s" % [str(item.get("name", "")), str(item.get("desc", ""))]
					else:
						detail_label.text = "🔒 Chưa Khám Phá:\nHãy tiếp tục mở rộng nông trại, canh tác và đón khách du lịch để mở khóa mục này!"
			)
			entry_grid.add_child(btn)
