extends Control
## Side-view habitat: colored placeholders until pixel art (D-010).
## Water motion: Rapier Fluid2D; logic water cells baked from particles (D-009).

const WireActorScript := preload("res://scenes/ui/wire_actor.gd")
const WaterGravity := preload("res://scenes/ui/water_gravity.gd")
const WaterFluidLayerScript := preload("res://scenes/ui/water_fluid_layer.gd")
const AccessTags := preload("res://scenes/ui/access_tags.gd")
const CELL_CM := 1.0
const DISPLAY_EVERY_CM := 5.0
const WALL_EDGE_ROWS := 2
## Outer glass/frame rim; content (grid + fluid) stays inset so paint cells stay clickable.
const ENCLOSURE_FRAME_PX := 12.0

const COL_BG := Color(0.14, 0.16, 0.14)
## Black terrarium/cabinet rim (overrides wire-UI greens in habitat).
const COL_FRAME := Color(0.08, 0.08, 0.09)
const COL_FRAME_INNER := Color(0.72, 0.78, 0.82, 0.28)
const COL_FRAME_BASE := Color(0.04, 0.04, 0.05)
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

## Selected tool: {kind, id, access?, access_limits?, display_name?}
var selected_tool: Dictionary = {}

var _terrain: Dictionary = {}
## Per-cell layers: { "wall": bool, "ground": ""|"floor"|"water"|"water_half" }
## wall may stack with floor or water; floor and water are mutually exclusive.
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
	_fluid_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# stretch=false so viewport size == host size (physics tank matches grid px).
	_fluid_host.stretch = false
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


func _content_rect() -> Rect2:
	var f := ENCLOSURE_FRAME_PX
	return Rect2(Vector2(f, f), Vector2(
		maxf(1.0, size.x - f * 2.0),
		maxf(1.0, size.y - f * 2.0)
	))


func _draw() -> void:
	var outer := Rect2(Vector2.ZERO, size)
	draw_rect(outer, COL_BG, true)

	var inner := _content_rect()
	draw_rect(inner, Color(0.11, 0.13, 0.11), true)

	_draw_terrain_fills()
	_draw_placements()
	_draw_enclosure_frame()

	if is_tend and show_display_grid:
		_draw_display_grid()

	if is_tend and _rect_dragging:
		_draw_rect_preview()


func _draw_enclosure_frame() -> void:
	## Black cabinet rim outside the inset grid (fluid host); paint cells stay clear.
	var f := ENCLOSURE_FRAME_PX
	var outer := Rect2(Vector2.ZERO, size)
	var inner := _content_rect()

	draw_rect(Rect2(0, 0, size.x, f), COL_FRAME_BASE, true)
	draw_rect(Rect2(0, size.y - f, size.x, f), COL_FRAME_BASE, true)
	draw_rect(Rect2(0, f, f, size.y - 2.0 * f), COL_FRAME_BASE, true)
	draw_rect(Rect2(size.x - f, f, f, size.y - 2.0 * f), COL_FRAME_BASE, true)

	# Outer lip + thin glass highlight on the inner edge.
	draw_rect(outer, COL_FRAME, false, 1.5)
	draw_rect(inner, COL_FRAME_INNER, false, 1.0)

	var sill_h := f * 0.4
	draw_line(
		Vector2(f * 0.2, size.y - sill_h),
		Vector2(size.x - f * 0.2, size.y - sill_h),
		Color(0.12, 0.12, 0.13),
		1.25
	)

	var c := f * 0.65
	var corners: Array[Vector2] = [
		Vector2(0, 0),
		Vector2(size.x, 0),
		Vector2(0, size.y),
		Vector2(size.x, size.y),
	]
	for p in corners:
		var sx := 1.0 if p.x == 0.0 else -1.0
		var sy := 1.0 if p.y == 0.0 else -1.0
		draw_line(p + Vector2(sx * 2, sy * 2), p + Vector2(sx * c, sy * 2), COL_FRAME, 1.5)
		draw_line(p + Vector2(sx * 2, sy * 2), p + Vector2(sx * 2, sy * c), COL_FRAME, 1.5)


func _display_every_cells() -> int:
	return maxi(1, int(round(DISPLAY_EVERY_CM / CELL_CM)))


func _draw_display_grid() -> void:
	var gc := grid_cols()
	var gr := grid_rows()
	if gc < 1 or gr < 1:
		return
	var step := _display_every_cells()
	var cs := cell_size_px()
	var origin := _content_rect().position
	var inner := _content_rect()
	for i in range(step, gc, step):
		var x := origin.x + float(i) * cs.x
		draw_line(Vector2(x, origin.y), Vector2(x, origin.y + inner.size.y), COL_GRID, 1.0)
	for j in range(step, gr, step):
		var y := origin.y + float(j) * cs.y
		draw_line(Vector2(origin.x, y), Vector2(origin.x + inner.size.x, y), COL_GRID, 1.0)


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
	var origin := _content_rect().position
	# Back: wall_face, then floor (water is Fluid2D).
	for key in _terrain.keys():
		var cell := _parse_key(key)
		var layer: Dictionary = _cell_layer(key)
		var rect := Rect2(origin + Vector2(cell) * cs, cs)
		if bool(layer.get("wall", false)):
			draw_rect(rect, COL_WALL, true)
		var ground := String(layer.get("ground", ""))
		if ground == "floor":
			# Slightly inset so wall behind still reads when stacked.
			var inset := rect.grow(-1.0) if bool(layer.get("wall", false)) else rect
			draw_rect(inset, COL_FLOOR, true)


func _draw_placements() -> void:
	var cs := cell_size_px()
	var origin := _content_rect().position
	for p in _placements:
		if p["kind"] == "animal":
			continue
		var cell_origin := origin + Vector2(p["x"], p["y"]) * cs
		var rect := Rect2(cell_origin + cs * 0.1, cs * 0.8)
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
	var origin := _content_rect().position
	var rect := Rect2(origin + Vector2(x0, y0) * cs, Vector2(x1 - x0, y1 - y0) * cs)
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
	var inner := _content_rect()
	if gc < 1 or gr < 1 or inner.size.x < 1 or inner.size.y < 1:
		return Vector2.ONE
	return Vector2(inner.size.x / float(gc), inner.size.y / float(gr))


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
	var clear_water_cells: Array[Vector2i] = []
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var cell := Vector2i(x, y)
			match tid:
				"wall":
					_set_wall(cell, true)
				"floor":
					_set_ground(cell, "floor")
					clear_water_cells.append(cell)
				"water":
					_set_ground(cell, "")
					water_cells.append(cell)
				_:
					pass
	if not water_cells.is_empty() and _fluid_layer and _fluid_layer.has_method("inject_water_rect"):
		_fluid_layer.inject_water_rect(a, b)
	if not clear_water_cells.is_empty() and _fluid_layer and _fluid_layer.has_method("remove_particles_in_cells"):
		_fluid_layer.remove_particles_in_cells(clear_water_cells)
	_sync_fluid_solids()
	_refresh_actor_wander()
	queue_redraw()


func _apply_terrain_cell(cell: Vector2i, tid: String) -> void:
	match tid:
		"wall":
			_set_wall(cell, true)
		"floor":
			_set_ground(cell, "floor")
			if _fluid_layer and _fluid_layer.has_method("remove_particles_in_cells"):
				_fluid_layer.remove_particles_in_cells([cell])
		"water":
			_set_ground(cell, "")
			if _fluid_layer and _fluid_layer.has_method("inject_water_cell"):
				_fluid_layer.inject_water_cell(cell)
		_:
			pass


func _cell_layer(key: String) -> Dictionary:
	var raw: Variant = _terrain.get(key, null)
	if raw is Dictionary:
		return raw
	# Legacy single-kind string → layered.
	if raw is String:
		var kind := String(raw)
		var layer := {"wall": false, "ground": ""}
		if kind == "wall":
			layer["wall"] = true
		elif kind == "floor":
			layer["ground"] = "floor"
		elif WaterGravity.is_water(kind):
			layer["ground"] = kind
		_terrain[key] = layer
		return layer
	# Missing cell: return empty layers without writing (read-safe).
	return {"wall": false, "ground": ""}


func _set_wall(cell: Vector2i, on: bool) -> void:
	var key := _key(cell)
	var layer := _cell_layer(key).duplicate()
	layer["wall"] = on
	_terrain[key] = layer
	_prune_empty_cell(key)


func _set_ground(cell: Vector2i, ground: String) -> void:
	var key := _key(cell)
	var layer := _cell_layer(key).duplicate()
	# floor ↔ water mutually exclusive (wall may remain).
	layer["ground"] = ground
	_terrain[key] = layer
	_prune_empty_cell(key)


func _prune_empty_cell(key: String) -> void:
	var layer: Dictionary = _terrain.get(key, {})
	if not bool(layer.get("wall", false)) and String(layer.get("ground", "")) == "":
		_terrain.erase(key)


func _has_wall(cell: Vector2i) -> bool:
	return bool(_cell_layer(_key(cell)).get("wall", false))


func _ground_of(cell: Vector2i) -> String:
	return String(_cell_layer(_key(cell)).get("ground", ""))


func _sync_fluid_solids() -> void:
	if _fluid_layer and _fluid_layer.has_method("sync_solids"):
		_fluid_layer.sync_solids(_terrain)


func _on_water_baked(water_map: Dictionary) -> void:
	# Refresh ground water only; keep wall_face; floor stays unless water claims cell.
	var keys: Array = _terrain.keys()
	for key in keys:
		var layer: Dictionary = _cell_layer(String(key)).duplicate()
		var g := String(layer.get("ground", ""))
		if WaterGravity.is_water(g) and not water_map.has(key):
			layer["ground"] = ""
			_terrain[key] = layer
			_prune_empty_cell(String(key))
	for key in water_map.keys():
		var layer := _cell_layer(String(key)).duplicate()
		# Water displaces floor (cannot stack); wall remains.
		layer["ground"] = String(water_map[key])
		_terrain[key] = layer
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
	if kind == "plant" or kind == "animal":
		var access: Array = selected_tool.get("access", [])
		var limits: Dictionary = selected_tool.get("access_limits", {})
		if not _access_allows(cell, access, limits):
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
		entry["access"] = selected_tool.get("access", [])
		entry["access_limits"] = selected_tool.get("access_limits", {})
	next.append(entry)
	_placements = next
	if kind == "animal":
		_sync_animal_actors()
	queue_redraw()


func _access_allows(cell: Vector2i, access: Array, limits: Dictionary = {}) -> bool:
	if not _in_grid(cell) or access.is_empty():
		return false
	var from_floor := grid_rows() - 1 - cell.y
	return AccessTags.allows(_cell_access_tags(cell), access, limits, from_floor)


func _cell_access_tags(cell: Vector2i) -> Array[String]:
	var tags: Array[String] = []
	var ground := _ground_of(cell)
	var painted_wall := _has_wall(cell)
	var in_water := WaterGravity.is_water(ground)
	var zone := "water" if in_water else "air"
	var is_wall := painted_wall or cell.y < WALL_EDGE_ROWS
	var is_floor := (
		ground == "floor"
		or in_water
		or cell.y >= grid_rows() - WALL_EDGE_ROWS
	)
	if is_wall:
		tags.append("wall_%s" % zone)
	if is_floor:
		tags.append("floor_%s" % zone)
	if in_water:
		tags.append(AccessTags.SWIM)
	# Painted wall_face next to water counts as wall_water (nerite etc.).
	if painted_wall and _adjacent_to_water(cell) and not tags.has(AccessTags.WALL_WATER):
		tags.append(AccessTags.WALL_WATER)
	return tags


func _adjacent_to_water(cell: Vector2i) -> bool:
	var dirs: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)
	]
	for d in dirs:
		var n: Vector2i = cell + d
		if _in_grid(n) and WaterGravity.is_water(_ground_of(n)):
			return true
	return false


func _allowed_cell_positions(access: Array, limits: Dictionary = {}) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var cs := cell_size_px()
	var origin := _content_rect().position
	var gc := grid_cols()
	var gr := grid_rows()
	for y in range(gr):
		for x in range(gc):
			var cell := Vector2i(x, y)
			if _access_allows(cell, access, limits):
				out.append(origin + Vector2(cell) * cs)
	return out


func _sync_animal_actors() -> void:
	_clear_actors()
	var cs := cell_size_px()
	var origin := _content_rect().position
	var inner := _content_rect()
	for p in _placements:
		if p["kind"] != "animal":
			continue
		var actor := Control.new()
		actor.set_script(WireActorScript)
		add_child(actor)
		_actors.append(actor)
		actor.set_meta("access", p.get("access", []))
		actor.set_meta("access_limits", p.get("access_limits", {}))
		actor.position = origin + Vector2(p["x"], p["y"]) * cs
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
			actor.set_bounds(inner)
	_refresh_actor_wander()


func _refresh_actor_wander() -> void:
	for actor in _actors:
		var access: Array = []
		var limits: Dictionary = {}
		if actor.has_meta("access"):
			access = actor.get_meta("access")
		if actor.has_meta("access_limits"):
			limits = actor.get_meta("access_limits")
		var positions := _allowed_cell_positions(access, limits)
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
	var origin := _content_rect().position
	var local := local_pos - origin
	if local.x < 0.0 or local.y < 0.0:
		return Vector2i(-1, -1)
	return Vector2i(int(local.x / cs.x), int(local.y / cs.y))


func _in_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_cols() and cell.y < grid_rows()


func _key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


func _parse_key(key: String) -> Vector2i:
	var parts := key.split(",")
	return Vector2i(int(parts[0]), int(parts[1]))


func _on_resized() -> void:
	queue_redraw()
	var inner := _content_rect()
	for actor in _actors:
		if actor.has_method("set_bounds"):
			actor.set_bounds(inner)
	_refresh_actor_wander()
	if _fluid_host:
		_fluid_host.position = inner.position
		_fluid_host.size = inner.size
	if _fluid_viewport:
		_fluid_viewport.size = Vector2i(
			maxi(1, int(round(inner.size.x))),
			maxi(1, int(round(inner.size.y)))
		)
	if _fluid_layer and _fluid_layer.has_method("configure"):
		_fluid_layer.configure(grid_cols(), grid_rows(), cell_size_px())
		_sync_fluid_solids()
