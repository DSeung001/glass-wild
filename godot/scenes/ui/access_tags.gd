extends RefCounted
## Access tags for plant/animal placement and wander (D-009 surfaces + swim).
## Entity declares `access: Array[String]` and optional `access_limits: { tag: cm }`.

const FLOOR_AIR := "floor_air"
const WALL_AIR := "wall_air"
const FLOOR_WATER := "floor_water"
const WALL_WATER := "wall_water"
const SWIM := "swim"

const ALL := [FLOOR_AIR, WALL_AIR, FLOOR_WATER, WALL_WATER, SWIM]


static func has_tag(access: Array, tag: String) -> bool:
	for t in access:
		if String(t) == tag:
			return true
	return false


## True if any entity access tag is on the cell, respecting wall_air cm limits.
## `from_floor_cm` = cells above tank bottom (same as habitat_stage).
## Limit: omit or < 0 = unlimited; else require from_floor_cm < limit (legacy).
static func allows(
	cell_tags: Array,
	access: Array,
	limits: Dictionary = {},
	from_floor_cm: int = 0
) -> bool:
	if access.is_empty():
		return false
	var cell_set: Dictionary = {}
	for t in cell_tags:
		cell_set[String(t)] = true
	for raw in access:
		var tag := String(raw)
		if not cell_set.has(tag):
			continue
		if tag == WALL_AIR and limits.has(WALL_AIR):
			var lim: int = int(limits[WALL_AIR])
			if lim >= 0 and from_floor_cm >= lim:
				continue
		return true
	return false
