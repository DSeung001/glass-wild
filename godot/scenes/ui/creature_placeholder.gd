extends ColorRect
## Optional Step 6: move the paint-box "creature" with arrow keys.

const SPEED := 120.0


func _process(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		dir.x -= 1.0
	if Input.is_action_pressed("ui_right"):
		dir.x += 1.0
	if Input.is_action_pressed("ui_up"):
		dir.y -= 1.0
	if Input.is_action_pressed("ui_down"):
		dir.y += 1.0
	if dir != Vector2.ZERO:
		position += dir.normalized() * SPEED * delta
