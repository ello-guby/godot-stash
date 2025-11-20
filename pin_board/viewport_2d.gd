class_name Viewport2D extends Camera2D
## A [Camera2D] that move like an editor viewport

var _drag := false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("drag"): _drag = true
	if event.is_action_released("drag"): _drag = false
	if event.is_action_pressed("zoom_in") and not get_viewport().gui_get_hovered_control():
		zoom += Vector2.ONE * 0.1 * zoom
	if event.is_action_pressed("zoom_out") and not get_viewport().gui_get_hovered_control():
		zoom -= Vector2.ONE * 0.1 * zoom
	if event is InputEventMouseMotion and _drag:
		position += -event.relative / zoom
