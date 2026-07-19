extends Node2D
## Rapier Fluid2D world for habitat water (D-009).
## Physics truth = particles; gameplay water cells are baked from density.

signal baked(terrain_water: Dictionary)

const BAKE_INTERVAL := 0.1
const KIND_WATER := "water"
const KIND_WATER_HALF := "water_half"
## Max particles along cell axes when the cell is large enough (edge-aligned, in-cell only).
const INJECT_W := 2
const INJECT_H := 2
## Visual scale vs cell size (Fluid2DRenderer mesh); overlap softens the “dot cloud”.
const MESH_SCALE_FRAC := 0.42
## Full-cell bake if particle count >= this; half if >= HALF (spill / thin).
const BAKE_FULL_COUNT := 1
const BAKE_HALF_COUNT := 1
## Must match StaticBody2D defaults so fluid ↔ tank walls collide.
## Fluid2D defaults layer/mask to 0 (no solid contact) — that was the leak.
const PHYSICS_LAYER := 1
## Wall thickness ≥ ~2× particle radius (project: fluid_particle_radius_2d=5).
const TANK_WALL_MIN_PX := 16.0
## Water-like cohesion / damping (addon defaults are 1.0 / 1.0 — weak surface, thick goo).
const SURFACE_TENSION := 25.0
const SURFACE_BOUNDARY_ADHESION := 0.2
const VISCOSITY_XSPH := 0.45
const VISCOSITY_BOUNDARY_ADHESION := 0.15

var _fluid: Fluid2D
var _renderer: Fluid2DRenderer
var _solids_root: Node2D
var _bounds_body: StaticBody2D

var _cell_size: Vector2 = Vector2(10, 10)
var _cols: int = 1
var _rows: int = 1
var _bake_accum: float = 0.0


func _ready() -> void:
	_solids_root = Node2D.new()
	_solids_root.name = "Solids"
	add_child(_solids_root)

	_bounds_body = StaticBody2D.new()
	_bounds_body.name = "TankBounds"
	_bounds_body.collision_layer = PHYSICS_LAYER
	_bounds_body.collision_mask = PHYSICS_LAYER
	add_child(_bounds_body)

	_fluid = Fluid2D.new()
	_fluid.name = "Fluid2D"
	_fluid.density = 1000.0
	_fluid.debug_draw = false
	_fluid.collision_layer = PHYSICS_LAYER
	_fluid.collision_mask = PHYSICS_LAYER
	_try_add_fluid_effects(_fluid)
	add_child(_fluid)

	_renderer = Fluid2DRenderer.new()
	_renderer.name = "Fluid2DRenderer"
	_renderer.fluid = _fluid
	# Lower alpha so overlapping radial meshes read as a sheet, not opaque beads.
	_renderer.color = Color(0.16, 0.50, 0.78, 0.55)
	_renderer.mesh_scale = Vector2(2.0, 2.0)
	add_child(_renderer)

	set_physics_process(true)


func _physics_process(delta: float) -> void:
	_bake_accum += delta
	if _bake_accum < BAKE_INTERVAL:
		return
	_bake_accum = 0.0
	_cull_escaped_particles()
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
	_clear_children_immediate(_solids_root)
	for key in terrain.keys():
		if not _is_solid_cell(terrain[key]):
			continue
		var cell := _parse_key(String(key))
		if cell.x < 0:
			continue
		_add_solid_rect(_cell_rect(cell))


## Solid if wall OR ground==floor. Water ground alone is not solid.
## Supports layered Dictionary and legacy single-kind string.
func _is_solid_cell(raw: Variant) -> bool:
	if raw is Dictionary:
		var layer: Dictionary = raw
		if bool(layer.get("wall", false)):
			return true
		return String(layer.get("ground", "")) == "floor"
	if raw is String:
		var kind := String(raw)
		return kind == "floor" or kind == "wall"
	return false


func inject_water_cell(cell: Vector2i) -> void:
	if _fluid == null or not _in_grid(cell):
		return
	# Edge-aligned in-cell grid (not create_rectangle_points): stays in one cell,
	# but adjacent painted cells form a ~2×radius lattice so SPH can merge.
	var shifted: PackedVector2Array = _points_in_cell(cell)
	if shifted.is_empty():
		return
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
	var effects: Array[Resource] = []
	for cname in [
		"FluidEffect2DSurfaceTensionAKINCI",
		"FluidEffect2DViscosityXSPH",
	]:
		if ClassDB.class_exists(cname):
			var e: Variant = ClassDB.instantiate(cname)
			if e is Resource:
				_configure_fluid_effect(e as Object, cname)
				effects.append(e as Resource)
	if not effects.is_empty():
		fluid.effects = effects


func _configure_fluid_effect(effect: Object, cname: String) -> void:
	if cname == "FluidEffect2DSurfaceTensionAKINCI":
		_set_effect_prop(effect, "fluid_tension_coefficient", SURFACE_TENSION)
		_set_effect_prop(effect, "boundary_adhesion_coefficient", SURFACE_BOUNDARY_ADHESION)
	elif cname == "FluidEffect2DViscosityXSPH":
		_set_effect_prop(effect, "fluid_viscosity_coefficient", VISCOSITY_XSPH)
		_set_effect_prop(effect, "boundary_adhesion_coefficient", VISCOSITY_BOUNDARY_ADHESION)


func _set_effect_prop(effect: Object, prop: String, value: Variant) -> void:
	for p in effect.get_property_list():
		if String(p.name) == prop:
			effect.set(prop, value)
			return


func _rebuild_tank_bounds() -> void:
	_clear_children_immediate(_bounds_body)
	var w := float(_cols) * _cell_size.x
	var h := float(_rows) * _cell_size.y
	var t := maxf(TANK_WALL_MIN_PX, maxf(_cell_size.x, _cell_size.y) * 0.5)
	# Overlap corners so particles cannot slip through seams.
	_add_bound_segment(Rect2(-t, h, w + 2.0 * t, t))
	_add_bound_segment(Rect2(-t, -t, w + 2.0 * t, t))
	_add_bound_segment(Rect2(-t, -t, t, h + 2.0 * t))
	_add_bound_segment(Rect2(w, -t, t, h + 2.0 * t))


func _add_bound_segment(rect: Rect2) -> void:
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.position = rect.position + rect.size * 0.5
	_bounds_body.add_child(shape)


func _add_solid_rect(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = PHYSICS_LAYER
	body.collision_mask = PHYSICS_LAYER
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.position = rect.size * 0.5
	body.position = rect.position
	body.add_child(shape)
	_solids_root.add_child(body)


func _clear_children_immediate(parent: Node) -> void:
	## queue_free leaves a physics frame without walls; free now.
	var kids := parent.get_children()
	for c in kids:
		parent.remove_child(c)
		c.free()


func _cull_escaped_particles() -> void:
	if _fluid == null:
		return
	var pts: PackedVector2Array = _fluid.points
	if pts.is_empty():
		return
	var w := float(_cols) * _cell_size.x
	var h := float(_rows) * _cell_size.y
	var pad := maxf(_cell_size.x, _cell_size.y)
	var keep := PackedVector2Array()
	for p in pts:
		if p.x < -pad or p.y < -pad or p.x > w + pad or p.y > h + pad:
			continue
		keep.append(p)
	if keep.size() != pts.size():
		_fluid.points = keep


func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(Vector2(cell) * _cell_size, _cell_size)


## Particles stay inside the painted cell; 2×2 sits at ±radius from edges so
## neighboring cells’ particles sit ~2×radius apart (continuous fluid body).
func _points_in_cell(cell: Vector2i) -> PackedVector2Array:
	var r: float = float(
		ProjectSettings.get_setting("physics/rapier/fluid/fluid_particle_radius_2d", 5.0)
	)
	if r < 0.5:
		r = 0.5
	var origin := Vector2(cell) * _cell_size
	var xs: PackedFloat32Array = _axis_sample_coords(_cell_size.x, r, INJECT_W)
	var ys: PackedFloat32Array = _axis_sample_coords(_cell_size.y, r, INJECT_H)
	var pts := PackedVector2Array()
	pts.resize(xs.size() * ys.size())
	var i := 0
	for y in ys:
		for x in xs:
			pts[i] = origin + Vector2(x, y)
			i += 1
	return pts


func _axis_sample_coords(cell_len: float, radius: float, max_n: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	# Need room for an edge pair without centers leaving the cell.
	if max_n >= 2 and cell_len >= radius * 2.5:
		out.append(radius)
		out.append(cell_len - radius)
	else:
		out.append(cell_len * 0.5)
	return out


func _in_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < _cols and cell.y < _rows


func _parse_key(key: String) -> Vector2i:
	var parts := key.split(",")
	if parts.size() != 2:
		return Vector2i(-1, -1)
	return Vector2i(int(parts[0]), int(parts[1]))
