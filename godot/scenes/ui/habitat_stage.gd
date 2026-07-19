extends Control
## Side-view habitat: logic cells 0.5cm, display grid N=4, paint/place (D-010).

const WireActorScript := preload("res://scenes/ui/wire_actor.gd")
const CELL_CM := 0.5
const DISPLAY_EVERY := 4
const WALL_EDGE_ROWS := 3

signal mode_changed(is_edit: bool)

var width_cm: int = 60
var depth_cm: int = 45
var height_cm: int = 45
var is_edit: bool = false
var water_ratio: float = 0.33

## Selected tool from palette: {kind, id, surfaces?}
var selected_tool: Dictionary = {}

## cell key "x,y" -> "floor" | "wall" | "water"
var _terrain: Dictionary = {}
## Array of {kind, id, x, y}
var _placements: Array[Dictionary] = []

var _actors: Array[Control] = []
var _painting: bool = false
var _last_paint_cell: Vector2i = Vector2i(-1, -1)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_on_resized)
	call_deferred("_on_resized")
	call_deferred("_boot_observe")


func _boot_observe() -> void:
	if not is_edit:
		set_edit_mode(false)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color.WHITE, false, 2.0)

	var water_y := size.y * (1.0 - water_ratio)
	draw_line(Vector2(0, water_y), Vector2(size.x, water_y), Color.WHITE, 1.0)

	_draw_terrain_fills()
	_draw_placements()

	if is_edit:
		_draw_display_grid()


func _draw_display_grid() -> void:
	var gc := grid_cols()
	var gr := grid_rows()
	if gc < 1 or gr < 1:
		return
	var cs := cell_size_px()
	for i in range(DISPLAY_EVERY, gc, DISPLAY_EVERY):
		var x := float(i) * cs.x
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color(1, 1, 1, 0.35), 1.0)
	for j in range(DISPLAY_EVERY, gr, DISPLAY_EVERY):
		var y := float(j) * cs.y
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(1, 1, 1, 0.35), 1.0)


func _draw_terrain_fills() -> void:
	var cs := cell_size_px()
	for key in _terrain.keys():
		var cell := _parse_key(key)
		var kind: String = _terrain[key]
		var rect := Rect2(Vector2(cell) * cs, cs)
		match kind:
			"floor":
				draw_rect(rect, Color(1, 1, 1, 0.12), true)
				draw_rect(rect, Color.WHITE, false, 1.0)
			"wall":
				draw_rect(rect, Color(1, 1, 1, 0.06), true)
				draw_rect(rect, Color(1, 1, 1, 0.7), false, 1.0)
			"water":
				draw_rect(rect, Color(1, 1, 1, 0.18), true)


func _draw_placements() -> void:
	var cs := cell_size_px()
	for p in _placements:
		var origin := Vector2(p["x"], p["y"]) * cs
		var rect := Rect2(origin + cs * 0.15, cs * 0.7)
		draw_rect(rect, Color.WHITE, false, 1.5)
		# Tiny mark: plant vs animal
		if p["kind"] == "plant":
			draw_line(origin + Vector2(cs.x * 0.5, cs.y * 0.2), origin + Vector2(cs.x * 0.5, cs.y * 0.8), Color.WHITE, 1.0)
		elif p["kind"] == "animal":
			draw_circle(origin + cs * 0.5, min(cs.x, cs.y) * 0.15, Color.WHITE)


func grid_cols() -> int:
	return int(round(float(width_cm) / CELL_CM))


func grid_rows() -> int:
	return int(round(float(height_cm) / CELL_CM))


func cell_size_px() -> Vector2:
	var gc := grid_cols()
	var gr := grid_rows()
	if gc < 1 or gr < 1 or size.x < 1 or size.y < 1:
		return Vector2.ONE
	return Vector2(size.x / float(gc), size.y / float(gr))


func set_preset(w: int, d: int, h: int) -> void:
	width_cm = w
	depth_cm = d
	height_cm = h
	_terrain.clear()
	_placements.clear()
	_clear_actors()
	queue_redraw()
	_on_resized()


func set_edit_mode(edit: bool) -> void:
	is_edit = edit
	_painting = false
	for actor in _actors:
		if actor.has_method("set_wander_enabled"):
			actor.set_wander_enabled(not edit)
	queue_redraw()
	mode_changed.emit(edit)


func set_selected_tool(tool: Dictionary) -> void:
	selected_tool = tool


func _gui_input(event: InputEvent) -> void:
	if not is_edit or selected_tool.is_empty():
		return

	var kind: String = selected_tool.get("kind", "")
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var cell := _cell_at(event.position)
		if not _in_grid(cell):
			return
		if event.pressed:
			if kind == "terrain":
				_painting = true
				_last_paint_cell = Vector2i(-1, -1)
				_paint_cell(cell)
			elif kind == "animal" or kind == "plant":
				_place_click(cell)
			accept_event()
		else:
			_painting = false
			accept_event()
	elif event is InputEventMouseMotion and _painting and kind == "terrain":
		var cell := _cell_at(event.position)
		if _in_grid(cell):
			_paint_cell(cell)
		accept_event()


func _paint_cell(cell: Vector2i) -> void:
	if cell == _last_paint_cell:
		return
	_last_paint_cell = cell
	var tid: String = selected_tool.get("id", "")
	_terrain[_key(cell)] = tid
	queue_redraw()


func _place_click(cell: Vector2i) -> void:
	var kind: String = selected_tool.get("kind", "")
	var id: String = selected_tool.get("id", "")
	if kind == "plant":
		var surfaces: Array = selected_tool.get("surfaces", [])
		if not _surface_allows(cell, surfaces):
			return
	var next: Array[Dictionary] = []
	for p in _placements:
		if int(p["x"]) == cell.x and int(p["y"]) == cell.y and String(p["kind"]) == kind:
			continue
		next.append(p)
	next.append({"kind": kind, "id": id, "x": cell.x, "y": cell.y})
	_placements = next
	if kind == "animal":
		_sync_animal_actors()
	queue_redraw()


func _surface_allows(cell: Vector2i, surfaces: Array) -> bool:
	var tags := _cell_surface_tags(cell)
	for s in surfaces:
		if tags.has(String(s)):
			return true
	return false


func _cell_surface_tags(cell: Vector2i) -> Array[String]:
	var tags: Array[String] = []
	var terrain: String = String(_terrain.get(_key(cell), ""))
	var water_row_start := int(float(grid_rows()) * (1.0 - water_ratio))
	var zone := "water" if cell.y >= water_row_start else "air"
	var is_wall := terrain == "wall" or cell.y < WALL_EDGE_ROWS
	var is_floor := (
		terrain == "floor"
		or terrain == "water"
		or cell.y >= grid_rows() - WALL_EDGE_ROWS
	)
	if is_wall:
		tags.append("wall_%s" % zone)
	if is_floor:
		tags.append("floor_%s" % zone)
	return tags


func _sync_animal_actors() -> void:
	_clear_actors()
	var cs := cell_size_px()
	for p in _placements:
		if p["kind"] != "animal":
			continue
		var actor := Control.new()
		actor.set_script(WireActorScript)
		add_child(actor)
		_actors.append(actor)
		actor.position = Vector2(p["x"], p["y"]) * cs
		var tag := Label.new()
		tag.text = String(p["id"])
		tag.add_theme_font_size_override("font_size", 10)
		tag.add_theme_color_override("font_color", Color.WHITE)
		tag.position = Vector2(0, -14)
		actor.add_child(tag)
		if actor.has_method("set_bounds"):
			actor.set_bounds(Rect2(Vector2.ZERO, size))
		if actor.has_method("set_wander_enabled"):
			actor.set_wander_enabled(not is_edit)


func _clear_actors() -> void:
	for a in _actors:
		a.queue_free()
	_actors.clear()


func _cell_at(local_pos: Vector2) -> Vector2i:
	var cs := cell_size_px()
	if cs.x < 0.001 or cs.y < 0.001:
		return Vector2i(-1, -1)
	return Vector2i(int(local_pos.x / cs.x), int(local_pos.y / cs.y))


func _in_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_cols() and cell.y < grid_rows()


func _key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


func _parse_key(key: String) -> Vector2i:
	var parts := key.split(",")
	return Vector2i(int(parts[0]), int(parts[1]))


func _on_resized() -> void:
	queue_redraw()
	var bounds := Rect2(Vector2.ZERO, size)
	for actor in _actors:
		if actor.has_method("set_bounds"):
			actor.set_bounds(bounds)
