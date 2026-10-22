extends RefCounted
class_name SpriteSlicer

const INSET_MARGIN: int = 8

## Cắt ô lưới đều từ SpriteSheet với lề thụt vào INSET_MARGIN = 8 pixel
## để loại bỏ hoàn toàn viền đen chữ L ở mép ngoài ô
static func slice_grid(image: Image, rows: int = 3, cols: int = 4, inset_margin: int = INSET_MARGIN) -> Array[Image]:
	if image == null or image.is_empty():
		push_error("[SpriteSlicer] Image is null or empty.")
		return []

	var img: Image = image.duplicate()
	img.convert(Image.FORMAT_RGBA8)

	var img_w: int = img.get_width()
	var img_h: int = img.get_height()
	var cell_w: int = int(float(img_w) / float(cols))
	var cell_h: int = int(float(img_h) / float(rows))

	var slices: Array[Image] = []

	for row: int in range(rows):
		for col: int in range(cols):
			var start_x: int = col * cell_w
			var start_y: int = row * cell_h

			var inner_x: int = start_x + inset_margin
			var inner_y: int = start_y + inset_margin
			var inner_w: int = cell_w - (inset_margin * 2)
			var inner_h: int = cell_h - (inset_margin * 2)

			if inner_w <= 0 or inner_h <= 0:
				continue

			var cell_rect: Rect2i = Rect2i(inner_x, inner_y, inner_w, inner_h)
			var cell_img: Image = img.get_region(cell_rect)
			slices.append(cell_img)

	return slices

## Tự động crop sát viền nội dung hữu dụng bằng get_used_rect()
static func slice_auto(image: Image) -> Image:
	if image == null or image.is_empty():
		return image

	var img: Image = image.duplicate()
	img.convert(Image.FORMAT_RGBA8)

	var used_rect: Rect2i = img.get_used_rect()
	if used_rect.size.x <= 0 or used_rect.size.y <= 0:
		return img

	return img.get_region(used_rect)

## Loại bỏ nền trắng / viền sáng bằng Flood-fill BFS từ 4 góc viền
static func remove_background_floodfill(image: Image, bg_threshold: float = 0.88) -> Image:
	if image == null or image.is_empty():
		return image

	var img: Image = image.duplicate()
	img.convert(Image.FORMAT_RGBA8)
	var w: int = img.get_width()
	var h: int = img.get_height()
	var total_pixels: int = w * h
	var visited: PackedByteArray = PackedByteArray()
	visited.resize(total_pixels)
	visited.fill(0)

	var queue: Array[Vector2i] = []

	for x: int in range(w):
		_enqueue_seed(img, x, 0, w, bg_threshold, visited, queue)
		_enqueue_seed(img, x, h - 1, w, bg_threshold, visited, queue)

	for y: int in range(h):
		_enqueue_seed(img, 0, y, w, bg_threshold, visited, queue)
		_enqueue_seed(img, w - 1, y, w, bg_threshold, visited, queue)

	var head: int = 0
	var transparent_color: Color = Color(1.0, 1.0, 1.0, 0.0)

	while head < queue.size():
		var p: Vector2i = queue[head]
		head += 1
		img.set_pixel(p.x, p.y, transparent_color)

		var neighbors: Array[Vector2i] = [
			Vector2i(p.x + 1, p.y),
			Vector2i(p.x - 1, p.y),
			Vector2i(p.x, p.y + 1),
			Vector2i(p.x, p.y - 1)
		]

		for n: Vector2i in neighbors:
			if n.x >= 0 and n.x < w and n.y >= 0 and n.y < h:
				var idx: int = n.y * w + n.x
				if visited[idx] == 0:
					visited[idx] = 1
					var col: Color = img.get_pixel(n.x, n.y)
					if col.a > 0.05 and col.r >= bg_threshold and col.g >= bg_threshold and col.b >= bg_threshold:
						queue.append(n)

	return img

static func _enqueue_seed(img: Image, x: int, y: int, w: int, bg_threshold: float, visited: PackedByteArray, queue: Array[Vector2i]) -> void:
	var idx: int = y * w + x
	if visited[idx] == 0:
		visited[idx] = 1
		var col: Color = img.get_pixel(x, y)
		if col.a > 0.05 and col.r >= bg_threshold and col.g >= bg_threshold and col.b >= bg_threshold:
			queue.append(Vector2i(x, y))
