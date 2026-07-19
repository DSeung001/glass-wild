extends Node2D
## Rapier Fluid2D world for habitat water (D-009).
## Physics truth = particles; gameplay water cells are baked from density.

signal baked(terrain_water: Dictionary)

const BAKE_INTERVAL := 0.1
const KIND_WATER := "water"
const KIND_WATER_HALF := "water_half"
## Particle counts along cell axes when painting one cell (small blob).
const INJECT_W := 2
const INJECT_H := 2
## Visual scale vs cell size (Fluid2DRenderer mesh).
const MESH_SCALE_FRAC := 0.12
## Full-cell bake if particle count >= this; half if >= HALF.
const BAKE_FULL_COUNT := 3
const BAKE_HALF_COUNT := 1

var _fluid: Fluid2D
var _renderer: Fluid2DRenderer
var _solids_root: Node2D
var _bounds_body: StaticBody2D

var _cell_size: Vector2 = Vector2(10, 10)
var _cols: int = 1
var _rows: int = 1
var _bake_accum: float = 0.0
var _max_particles: int = 4000


func _ready() -> void:
	_solids_root = Node2D.new()
	_solids_root.name = "Solids"
	add_child(_solids_root)

	_bounds_body = StaticBody2D.new()
	_bounds_body.name = "TankBounds"
	add_child(_bounds_body)

	_fluid = Fluid2D.new()
	_fluid.name = "Fluid2D"
	_fluid.density = 1000.0
	_fluid.debug_draw = false
	_try_add_fluid_effects(_fluid)
	add_child(_fluid)

	_renderer = Fluid2DRenderer.new()
	_renderer.name = "Fluid2DRenderer"
	_renderer.fluid = _fluid
	_renderer.color = Color(0.22, 0.55, 0.78, 0.85)
	_renderer.mesh_scale = Vector2(2.0, 2.0)
	add_child(_renderer)

	set_physics_process(true)


func _physics_process(delta: float) -> void:
	_bake_accum += delta
	if _bake_accum < BAKE_INTERVAL:
		return
	_bake_accum = 0.0
	baked.emit(bake_water_cells())


func configure(cols: int, rows: int, cell_size: Vector2) -> void:
	_cols = maxi(cols, 1)
	_rows = maxi(rows, 1)
	_cell_size = cell_size
	if _cell_size.x < 1.0:
		_cell_size.x = 1.0
	if _cell_size.y < 1.0:
		_cell_size.y = 1.0
	_rebuild_tank_bounds()
	if _renderer:
		var s: float = minf(_cell_size.x, _cell_size.y) * MESH_SCALE_FRAC
		_renderer.mesh_scale = Vector2(s, s)


func sync_solids(terrain: Dictionary) -> void:
	for c in _solids_root.get_children():
		c.queue_free()
	for key in terrain.keys():
		var kind := String(terrain[key])
		if kind != "floor" and kind != "wall":
			continue
		var cell := _parse_key(String(key))
		if cell.x < 0:
			continue
		_add_solid_rect(_cell_rect(cell))


func inject_water_cell(cell: Vector2i) -> void:
	if _fluid == null or not _in_grid(cell):
		return
	if _fluid.points.size() >= _max_particles:
		return
	var local_pts: PackedVector2Array = _fluid.create_rectangle_points(INJECT_W, INJECT_H)
	if local_pts.is_empty():
		local_pts = _fallback_cell_points()
	# Center the small blob inside the painted cell.
	var centroid := Vector2.ZERO
	for p in local_pts:
		centroid += p
	centroid /= float(local_pts.size())
	var center := Vector2(cell) * _cell_size + _cell_size * 0.5
	var shifted := PackedVector2Array()
	shifted.resize(local_pts.size())
	for i in local_pts.size():
		shifted[i] = local_pts[i] - centroid + center
	var vels := PackedVector2Array()
	vels.resize(shifted.size())
	vels.fill(Vector2(0, 40))
	_fluid.add_points_and_velocities(shifted, vels)


func inject_water_rect(a: Vector2i, b: Vector2i) -> void:
	var x0 := mini(a.x, b.x)
	var y0 := mini(a.y, b.y)
	var x1 := maxi(a.x, b.x)
	var y1 := maxi(a.y, b.y)
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			inject_water_cell(Vector2i(x, y))


func remove_particles_in_cells(cells: Array) -> void:
	if _fluid == null or cells.is_empty():
		return
	var drop: Dictionary = {}
	for cell in cells:
		if cell is Vector2i:
			var c: Vector2i = cell
			drop["%d,%d" % [c.x, c.y]] = true
	if drop.is_empty():
		return
	var pts: PackedVector2Array = _fluid.points
	if pts.is_empty():
		return
	var keep := PackedVector2Array()
	for p in pts:
		var cx := int(floor(p.x / _cell_size.x))
		var cy := int(floor(p.y / _cell_size.y))
		var key := "%d,%d" % [cx, cy]
		if not drop.has(key):
			keep.append(p)
	_fluid.points = keep


func clear_all_particles() -> void:
	if _fluid:
		_fluid.points = PackedVector2Array()


## Returns map of "x,y" -> "water"|"water_half" for cells with enough particles.
func bake_water_cells() -> Dictionary:
	var counts: Dictionary = {}
	if _fluid == null:
		return counts
	for p in _fluid.points:
		var cx := int(floor(p.x / _cell_size.x))
		var cy := int(floor(p.y / _cell_size.y))
		if cx < 0 or cy < 0 or cx >= _cols or cy >= _rows:
			continue
		var key := "%d,%d" % [cx, cy]
		counts[key] = int(counts.get(key, 0)) + 1
	var out: Dictionary = {}
	for key in counts.keys():
		var n: int = int(counts[key])
		if n >= BAKE_FULL_COUNT:
			out[key] = KIND_WATER
		elif n >= BAKE_HALF_COUNT:
			out[key] = KIND_WATER_HALF
	return out


func _try_add_fluid_effects(fluid: Fluid2D) -> void:
	var effects: Array = []
	for cname in [
		"FluidEffect2DSurfaceTensionAKINCI",
		"FluidEffect2DViscosityXSPH",
	]:
		if ClassDB.class_exists(cname):
			var e: Variant = ClassDB.instantiate(cname)
			if e != null:
				effects.append(e)
	if not effects.is_empty():
		fluid.set("effects", effects)


func _rebuild_tank_bounds() -> void:
	for c in _bounds_body.get_children():
		c.queue_free()
	var w := float(_cols) * _cell_size.x
	var h := float(_rows) * _cell_size.y
	var t := 8.0
	# Bottom, top, left, right walls so fluid stays in the tank.
	_add_bound_segment(Rect2(0, h, w, t))
	_add_bound_segment(Rect2(0, -t, w, t))
	_add_bound_segment(Rect2(-t, 0, t, h))
	_add_bound_segment(Rect2(w, 0, t, h))


func _add_bound_segment(rect: Rect2) -> void:
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.position = rect.position + rect.size * 0.5
	_bounds_body.add_child(shape)


func _add_solid_rect(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.position = rect.size * 0.5
	body.position = rect.position
	body.add_child(shape)
	_solids_root.add_child(body)


func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(Vector2(cell) * _cell_size, _cell_size)


func _fallback_cell_points() -> PackedVector2Array:
	var pts := PackedVector2Array()
	var step := _cell_size * 0.25
	for j in range(INJECT_H):
		for i in range(INJECT_W):
			pts.append(Vector2((i + 0.5) * step.x, (j + 0.5) * step.y))
	return pts


func _in_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < _cols and cell.y < _rows


func _parse_key(key: String) -> Vector2i:
	var parts := key.split(",")
	if parts.size() != 2:
		return Vector2i(-1, -1)
	return Vector2i(int(parts[0]), int(parts[1]))
