extends Control
## Side-view habitat: colored placeholders until pixel art (D-010).
## Water motion: Rapier Fluid2D; logic water cells baked from particles (D-009).

const WireActorScript := preload("res://scenes/ui/wire_actor.gd")
const WaterGravity := preload("res://scenes/ui/water_gravity.gd")
const WaterFluidLayerScript := preload("res://scenes/ui/water_fluid_layer.gd")
const CELL_CM := 1.0
const DISPLAY_EVERY_CM := 5.0
const WALL_EDGE_ROWS := 2

const COL_BG := Color(0.14, 0.16, 0.14)
const COL_FRAME := Color(0.55, 0.58, 0.52)
const COL_FLOOR := Color(0.45, 0.32, 0.18)
const COL_WALL := Color(0.42, 0.40, 0.36)
const COL_WATER := Color(0.22, 0.48, 0.68)
const COL_PLANT := Color(0.28, 0.62, 0.32)
const COL_ANIMAL := Color(0.88, 0.72, 0.28)
const COL_GRID := Color(1, 1, 1, 0.22)
const COL_PREVIEW := Color(1, 0.92, 0.4, 0.35)

signal mode_changed(is_tend: bool)

var width_cm: int = 60
var depth_cm: int = 45
var height_cm: int = 45
var is_tend: bool = false
var show_display_grid: bool = true
## "dot" | "rect" — terrain only
var terrain_place_mode: String = "dot"

## Selected tool: {kind, id, surfaces?, display_name?}
var selected_tool: Dictionary = {}

var _terrain: Dictionary = {}
var _placements: Array[Dictionary] = []
var _actors: Array[Control] = []

var _rect_dragging: bool = false
var _rect_start: Vector2i = Vector2i(-1, -1)
var _rect_end: Vector2i = Vector2i(-1, -1)

var _fluid_host: SubViewportContainer
var _fluid_viewport: SubViewport
var _fluid_layer: Node2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_setup_fluid_viewport()
	resized.connect(_on_resized)
	call_deferred("_on_resized")
	call_deferred("_boot_observe")


func _setup_fluid_viewport() -> void:
	_fluid_host = SubViewportContainer.new()
	_fluid_host.name = "WaterFluidHost"
	_fluid_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fluid_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fluid_host.stretch = true
	add_child(_fluid_host)

	_fluid_viewport = SubViewport.new()
	_fluid_viewport.name = "WaterFluidViewport"
	_fluid_viewport.transparent_bg = true
	_fluid_viewport.handle_input_locally = false
	_fluid_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_fluid_viewport.physics_object_picking = false
	_fluid_host.add_child(_fluid_viewport)

	_fluid_layer = Node2D.new()
	_fluid_layer.set_script(WaterFluidLayerScript)
	_fluid_layer.name = "WaterFluidLayer"
	_fluid_viewport.add_child(_fluid_layer)
	if _fluid_layer.has_signal("baked"):
		_fluid_layer.baked.connect(_on_water_baked)


func _boot_observe() -> void:
	if not is_tend:
		set_tend_mode(false)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, COL_BG, true)

	_draw_terrain_fills()
	_draw_placements()

	draw_rect(r, COL_FRAME, false, 2.0)

	if is_tend and show_display_grid:
		_draw_display_grid()

	if is_tend and _rect_dragging:
		_draw_rect_preview()


func _display_every_cells() -> int:
	return maxi(1, int(round(DISPLAY_EVERY_CM / CELL_CM)))


func _draw_display_grid() -> void:
	var gc := grid_cols()
	var gr := grid_rows()
	if gc < 1 or gr < 1:
		return
	var step := _display_every_cells()
	var cs := cell_size_px()
	for i in range(step, gc, step):
		var x := float(i) * cs.x
		draw_line(Vector2(x, 0), Vector2(x, size.y), COL_GRID, 1.0)
	for j in range(step, gr, step):
		var y := float(j) * cs.y
		draw_line(Vector2(0, y), Vector2(size.x, y), COL_GRID, 1.0)


func _terrain_color(kind: String) -> Color:
	match kind:
		"floor":
			return COL_FLOOR
		"wall":
			return COL_WALL
		"water", "water_half":
			return COL_WATER
		_:
			return Color.WHITE


func _draw_terrain_fills() -> void:
	var cs := cell_size_px()
	for key in _terrain.keys():
		var cell := _parse_key(key)
		var kind: String = String(_terrain[key])
		# Water is drawn by Fluid2DRenderer; only solids here.
		if WaterGravity.is_water(kind):
			continue
		var rect := Rect2(Vector2(cell) * cs, cs)
		draw_rect(rect, _terrain_color(kind), true)


func _draw_placements() -> void:
	var cs := cell_size_px()
	for p in _placements:
		if p["kind"] == "animal":
			continue
		var origin := Vector2(p["x"], p["y"]) * cs
		var rect := Rect2(origin + cs * 0.1, cs * 0.8)
		if p["kind"] == "plant":
			draw_rect(rect, COL_PLANT, true)
		else:
			draw_rect(rect, Color.WHITE, false, 1.5)


func _draw_rect_preview() -> void:
	var a := _rect_start
	var b := _rect_end
	if a.x < 0 or b.x < 0:
		return
	var x0 := mini(a.x, b.x)
	var y0 := mini(a.y, b.y)
	var x1 := maxi(a.x, b.x) + 1
	var y1 := maxi(a.y, b.y) + 1
	var cs := cell_size_px()
	var rect := Rect2(Vector2(x0, y0) * cs, Vector2(x1 - x0, y1 - y0) * cs)
	var fill := _terrain_color(String(selected_tool.get("id", "")))
	fill.a = 0.45
	draw_rect(rect, fill, true)
	draw_rect(rect, COL_PREVIEW, false, 2.0)


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
	_cancel_rect()
	if _fluid_layer and _fluid_layer.has_method("clear_all_particles"):
		_fluid_layer.clear_all_particles()
	queue_redraw()
	_on_resized()


func set_tend_mode(tend: bool) -> void:
	is_tend = tend
	_cancel_rect()
	_refresh_actor_wander()
	queue_redraw()
	mode_changed.emit(tend)


func set_show_display_grid(on: bool) -> void:
	show_display_grid = on
	queue_redraw()


func set_terrain_place_mode(mode: String) -> void:
	terrain_place_mode = mode
	_cancel_rect()


func set_selected_tool(tool: Dictionary) -> void:
	selected_tool = tool
	_cancel_rect()


func _gui_input(event: InputEvent) -> void:
	if not is_tend or selected_tool.is_empty():
		return

	var kind: String = selected_tool.get("kind", "")
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var cell := _cell_at(event.position)
		if not _in_grid(cell):
			if not event.pressed:
				_cancel_rect()
			return
		if event.pressed:
			if kind == "terrain":
				if terrain_place_mode == "rect":
					_rect_dragging = true
					_rect_start = cell
					_rect_end = cell
					queue_redraw()
				else:
					_paint_cell(cell)
			elif kind == "animal" or kind == "plant":
				_place_click(cell)
			accept_event()
		else:
			if kind == "terrain" and terrain_place_mode == "rect" and _rect_dragging:
				_rect_end = cell
				_fill_rect(_rect_start, _rect_end)
				_cancel_rect()
			accept_event()
	elif event is InputEventMouseMotion and _rect_dragging and kind == "terrain":
		var cell := _cell_at(event.position)
		if _in_grid(cell):
			_rect_end = cell
			queue_redraw()
		accept_event()


func _paint_cell(cell: Vector2i) -> void:
	var tid: String = selected_tool.get("id", "")
	_apply_terrain_cell(cell, tid)
	_sync_fluid_solids()
	_refresh_actor_wander()
	queue_redraw()


func _fill_rect(a: Vector2i, b: Vector2i) -> void:
	var tid: String = selected_tool.get("id", "")
	var x0 := mini(a.x, b.x)
	var y0 := mini(a.y, b.y)
	var x1 := maxi(a.x, b.x)
	var y1 := maxi(a.y, b.y)
	var water_cells: Array[Vector2i] = []
	var solid_cells: Array[Vector2i] = []
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var cell := Vector2i(x, y)
			if tid == "water":
				water_cells.append(cell)
				_terrain.erase(_key(cell))
			else:
				_terrain[_key(cell)] = tid
				solid_cells.append(cell)
	if not water_cells.is_empty() and _fluid_layer and _fluid_layer.has_method("inject_water_rect"):
		_fluid_layer.inject_water_rect(a, b)
	if not solid_cells.is_empty() and _fluid_layer and _fluid_layer.has_method("remove_particles_in_cells"):
		_fluid_layer.remove_particles_in_cells(solid_cells)
	_sync_fluid_solids()
	_refresh_actor_wander()
	queue_redraw()


func _apply_terrain_cell(cell: Vector2i, tid: String) -> void:
	if tid == "water":
		_terrain.erase(_key(cell))
		if _fluid_layer and _fluid_layer.has_method("inject_water_cell"):
			_fluid_layer.inject_water_cell(cell)
	else:
		_terrain[_key(cell)] = tid
		if _fluid_layer and _fluid_layer.has_method("remove_particles_in_cells"):
			_fluid_layer.remove_particles_in_cells([cell])


func _sync_fluid_solids() -> void:
	if _fluid_layer and _fluid_layer.has_method("sync_solids"):
		_fluid_layer.sync_solids(_terrain)


func _on_water_baked(water_map: Dictionary) -> void:
	# Drop previous baked water; keep floor/wall.
	var next: Dictionary = {}
	for key in _terrain.keys():
		var kind := String(_terrain[key])
		if not WaterGravity.is_water(kind):
			next[key] = kind
	for key in water_map.keys():
		# Do not overwrite solids.
		if next.has(key):
			continue
		next[key] = water_map[key]
	_terrain = next
	_refresh_actor_wander()
	queue_redraw()


func _cancel_rect() -> void:
	_rect_dragging = false
	_rect_start = Vector2i(-1, -1)
	_rect_end = Vector2i(-1, -1)
	queue_redraw()


func _place_click(cell: Vector2i) -> void:
	var kind: String = selected_tool.get("kind", "")
	var id: String = selected_tool.get("id", "")
	var display_name: String = String(selected_tool.get("display_name", id))
	if kind == "plant":
		var surfaces: Array = selected_tool.get("surfaces", [])
		if not _surface_allows(cell, surfaces):
			return
	elif kind == "animal":
		var loco: Dictionary = selected_tool.get("locomotion", {})
		if loco.is_empty() or not _cell_allows_locomotion(cell, loco):
			return
	var next: Array[Dictionary] = []
	for p in _placements:
		if int(p["x"]) == cell.x and int(p["y"]) == cell.y and String(p["kind"]) == kind:
			continue
		next.append(p)
	var entry := {
		"kind": kind,
		"id": id,
		"display_name": display_name,
		"x": cell.x,
		"y": cell.y,
	}
	if kind == "animal":
		if selected_tool.has("color"):
			entry["color"] = selected_tool["color"]
		if selected_tool.has("locomotion"):
			entry["locomotion"] = selected_tool["locomotion"]
	next.append(entry)
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
	var in_water := WaterGravity.is_water(terrain)
	var zone := "water" if in_water else "air"
	var is_wall := terrain == "wall" or cell.y < WALL_EDGE_ROWS
	var is_floor := (
		terrain == "floor"
		or in_water
		or cell.y >= grid_rows() - WALL_EDGE_ROWS
	)
	if is_wall:
		tags.append("wall_%s" % zone)
	if is_floor:
		tags.append("floor_%s" % zone)
	return tags


func _cell_allows_locomotion(cell: Vector2i, loco: Dictionary) -> bool:
	if not _in_grid(cell) or loco.is_empty():
		return false
	var terrain: String = String(_terrain.get(_key(cell), ""))
	var from_floor := grid_rows() - 1 - cell.y
	var in_water := WaterGravity.is_water(terrain)
	if bool(loco.get("swim", false)) and in_water:
		return true
	if bool(loco.get("floor_air", false)) and terrain == "floor":
		return true
	if bool(loco.get("floor_water", false)) and in_water:
		return true
	if bool(loco.get("wall_air", false)) and terrain == "wall":
		var max_cm: int = int(loco.get("wall_air_max_cm_from_floor", -1))
		if max_cm < 0 or from_floor < max_cm:
			return true
	if bool(loco.get("wall_water", false)) and terrain == "wall" and _adjacent_to_water(cell):
		return true
	return false


func _adjacent_to_water(cell: Vector2i) -> bool:
	var dirs: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)
	]
	for d in dirs:
		var n: Vector2i = cell + d
		if _in_grid(n) and WaterGravity.is_water(String(_terrain.get(_key(n), ""))):
			return true
	return false


func _allowed_cell_positions(loco: Dictionary) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var cs := cell_size_px()
	var gc := grid_cols()
	var gr := grid_rows()
	for y in range(gr):
		for x in range(gc):
			var cell := Vector2i(x, y)
			if _cell_allows_locomotion(cell, loco):
				out.append(Vector2(cell) * cs)
	return out


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
		actor.set_meta("locomotion", p.get("locomotion", {}))
		actor.position = Vector2(p["x"], p["y"]) * cs
		var tag := Label.new()
		tag.text = String(p.get("display_name", p["id"]))
		tag.add_theme_font_size_override("font_size", 10)
		tag.add_theme_color_override("font_color", Color(0.95, 0.95, 0.9))
		tag.position = Vector2(0, -14)
		actor.add_child(tag)
		if actor.has_method("set_fill_color"):
			var c: Color = COL_ANIMAL
			if p.has("color"):
				c = p["color"] as Color
			actor.call("set_fill_color", c)
		if actor.has_method("set_bounds"):
			actor.set_bounds(Rect2(Vector2.ZERO, size))
	_refresh_actor_wander()


func _refresh_actor_wander() -> void:
	for actor in _actors:
		var loco: Dictionary = {}
		if actor.has_meta("locomotion"):
			loco = actor.get_meta("locomotion")
		var positions := _allowed_cell_positions(loco)
		if actor.has_method("set_wander_positions"):
			actor.call("set_wander_positions", positions)
		if actor.has_method("set_wander_enabled"):
			actor.set_wander_enabled(not is_tend and not positions.is_empty())


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
	_refresh_actor_wander()
	if _fluid_viewport:
		_fluid_viewport.size = Vector2i(
			maxi(1, int(round(size.x))),
			maxi(1, int(round(size.y)))
		)
	if _fluid_layer and _fluid_layer.has_method("configure"):
		_fluid_layer.configure(grid_cols(), grid_rows(), cell_size_px())
		_sync_fluid_solids()
