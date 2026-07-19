extends Control
## Outline-only rectangle for B/W wireframes.

@export var line_color: Color = Color.WHITE
@export var line_width: float = 1.5


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, line_color, false, line_width)
