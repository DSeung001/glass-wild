extends Control
## Colored placeholder rect; wanders in observe mode. Pixel art comes later.

const SPEED := 55.0
const ARRIVE := 4.0
const FILL := Color(0.88, 0.72, 0.28)
const OUTLINE := Color(0.25, 0.2, 0.08)

var wander_enabled: bool = false
var fill_color: Color = FILL
var _target := Vector2.ZERO
var _bounds := Rect2()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(28, 20)
	size = custom_minimum_size
	resized.connect(queue_redraw)
	set_process(false)
	_pick_target()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, fill_color, true)
	draw_rect(r, OUTLINE, false, 1.5)


func set_fill_color(c: Color) -> void:
	fill_color = c
	queue_redraw()


func set_wander_enabled(enabled: bool) -> void:
	wander_enabled = enabled
	set_process(enabled)
	if enabled:
		_pick_target()


func set_bounds(bounds: Rect2) -> void:
	_bounds = bounds
	position = position.clamp(_bounds.position, _bounds.end - size)
	if wander_enabled:
		_pick_target()


func _process(delta: float) -> void:
	if not wander_enabled or _bounds.size == Vector2.ZERO:
		return
	var to_target := _target - position
	if to_target.length() < ARRIVE:
		_pick_target()
		to_target = _target - position
	if to_target.length() > 0.001:
		position += to_target.normalized() * SPEED * delta
		position = position.clamp(_bounds.position, _bounds.end - size)


func _pick_target() -> void:
	if _bounds.size.x <= size.x or _bounds.size.y <= size.y:
		_target = position
		return
	_target = Vector2(
		randf_range(_bounds.position.x, _bounds.end.x - size.x),
		randf_range(_bounds.position.y, _bounds.end.y - size.y)
	)
