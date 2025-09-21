extends StaticBody2D

@export var coord_display: Label

var _hover := false
var _grab := false

func _ready() -> void:
	mouse_entered.connect(func(): _hover = true)
	mouse_exited.connect(func(): _hover = false)
	if not coord_display and $CoordDisplay is Label: coord_display = $CoordDisplay

func _input(event: InputEvent) -> void:
	if _hover and event.is_action_pressed("remove_point"): queue_free()
	if _grab and event is InputEventMouseMotion:
		position += event.relative
	else:
		_grab = _hover and event.is_action_pressed("move_point")

func _process(delta: float) -> void:
	# piss control nodes
	if coord_display: coord_display.position.x = -(coord_display.size.x * coord_display.scale.x) / 2
	display_coord()

func display_coord() -> void:
	if coord_display: coord_display.text = "%s (%0.2f, %0.2f)" % [name, position.x, position.y]
