extends SceneTree

func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/main/MainFarm.tscn") as PackedScene
	var mf: Node2D = packed.instantiate() as Node2D
	root.add_child(mf)
	current_scene = mf

	# Close OfflineReportModal if open so scene is steady
	for i: int in range(30):
		await process_frame
	var orm: Node = mf.find_child("OfflineReportModal", true, false)
	if orm != null and ("visible" in orm):
		orm.set("visible", false)
	await process_frame
	await process_frame

	var steady_dc: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	print("[DC_PROF2] Steady DrawCalls=", steady_dc, " Primitives=", int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))

	# Check BuildingsContainer children
	var bc: Node2D = mf.get_node_or_null("BuildingsContainer") as Node2D
	if bc != null:
		print("[DC_PROF2] BuildingsContainer children count=", bc.get_child_count())
		for ch: Node in bc.get_children():
			var sub_count: int = _count_descendants(ch)
			var prev: bool = bool(ch.get("visible")) if ("visible" in ch) else true
			if prev:
				ch.set("visible", false)
				await process_frame
				await process_frame
				var dc_after: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
				print("  Building child '", ch.name, "' (", ch.get_class(), ", desc=", sub_count, ") delta=", steady_dc - dc_after)
				ch.set("visible", true)
				await process_frame
				steady_dc = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))

	# Also check MainFarm._draw() vs children by hiding ALL children of MainFarm
	var children_vis: Array = []
	for ch: Node in mf.get_children():
		if "visible" in ch:
			children_vis.append([ch, ch.get("visible")])
			ch.set("visible", false)
	await process_frame
	await process_frame
	var self_draw_dc: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	print("[DC_PROF2] MainFarm ONLY (all children hidden) DrawCalls=", self_draw_dc)

	# Re-enable one by one from blank state to see exact incremental cost of each layer!
	for pair: Array in children_vis:
		var ch: Node = pair[0] as Node
		var orig: bool = bool(pair[1])
		if not orig:
			continue
		var before: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		ch.set("visible", true)
		await process_frame
		await process_frame
		var after: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		print("  Layer +'", ch.name, "' (", ch.get_class(), "): +", after - before, " draw calls (total=", after, ")")

	quit(0)

func _count_descendants(n: Node) -> int:
	var c: int = 1
	for ch: Node in n.get_children():
		c += _count_descendants(ch)
	return c
