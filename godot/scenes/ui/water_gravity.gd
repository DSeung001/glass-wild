extends RefCounted
## Water cell helpers for Rapier bake / draw (D-009).
## Physics motion lives in water_fluid_layer.gd (Fluid2D).

const KIND_WATER := "water"
const KIND_WATER_HALF := "water_half"
const FILL_FULL := 1.0
const FILL_HALF := 0.5


static func is_water(kind: String) -> bool:
	return kind == KIND_WATER or kind == KIND_WATER_HALF


static func fill_of(kind: String) -> float:
	if kind == KIND_WATER:
		return FILL_FULL
	if kind == KIND_WATER_HALF:
		return FILL_HALF
	return 0.0


static func kind_for_fill(amount: float) -> String:
	if amount >= FILL_FULL - 0.001:
		return KIND_WATER
	if amount >= FILL_HALF - 0.001:
		return KIND_WATER_HALF
	return ""
