@tool class_name Pane extends Container
## A custom [Window].
##
## To add/remove/change ui within [Pane], use [method get_ui] which will return a
## [Container] that contain the inner UIs.

# How near mouse need to be to trigger stuff in radius.
var _panel: Panel = Panel.new()
var _ui: Container = Container.new()
var _resize_radius: float = 10.0
var _grab := false
var _grab_corner := -1
var _grab_side := -1

## Return a presetted [Pane].
func _init():
	var vec2 := Vector2.ONE
	custom_minimum_size = vec2 * 50
	if not size: size = vec2 * 200
	focus_mode = Control.FOCUS_ALL
	theme = preload("uid://e2xs0l76mq3s")

func _ready() -> void:
	mouse_entered.connect(grab_focus)
	mouse_exited.connect(func(): if not _grab: release_focus())
	focus_entered.connect(func(): _panel.add_theme_stylebox_override("panel", get_theme_stylebox("focus", "Pane")))
	focus_exited.connect(func(): _panel.add_theme_stylebox_override("panel", get_theme_stylebox("panel", "Pane")))
	_panel.add_theme_stylebox_override("panel", get_theme_stylebox("panel", "Pane"))
	add_child(_panel)
	_ui.clip_contents = true
	add_child(_ui)

func _process(_delta: float) -> void:
	for child in get_children(): if child is Control:
		child.position = Vector2.ZERO
		child.size = size

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("grab"):
		_grab = true
		move_to_front()
		# edging
		var lmp := get_local_mouse_position()
		var corn := _nearest_corner(lmp)
		if _is_near_corner(lmp, corn): _grab_corner = corn; return
		var side := _nearest_side(lmp)
		if _is_near_side(lmp, side): _grab_side = side
	if event.is_action_released("grab"):
		_grab = false
		_grab_corner = -1
		_grab_side = -1
	if event is InputEventMouseMotion:
		var lmp := get_local_mouse_position()
		var nearcorn := _nearest_corner(lmp)
		if _grab: # resize
			var mot = event.relative
			if _grab_corner != -1: match _grab_corner:
				CORNER_TOP_LEFT: size -= mot; if size >= custom_minimum_size: position += mot
				CORNER_TOP_RIGHT: position.y += mot.y; size.y -= mot.y; size.x += mot.x
				CORNER_BOTTOM_RIGHT: size += mot
				CORNER_BOTTOM_LEFT: position.x += mot.x; size.y += mot.y; size.x -= mot.x
			elif _grab_side != -1: match _grab_side:
				SIDE_TOP: position.y += mot.y; size.y -= mot.y
				SIDE_BOTTOM: size.y += mot.y
				SIDE_LEFT: position.x += mot.x; size.x -= mot.x
				SIDE_RIGHT: size.x += mot.x
			else:
				position += event.relative
		else: # set mouse shape
			if _is_near_corner(lmp, nearcorn):
				match nearcorn:
					CORNER_TOP_LEFT, CORNER_BOTTOM_RIGHT:
						mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
					CORNER_TOP_RIGHT, CORNER_BOTTOM_LEFT:
						mouse_default_cursor_shape = Control.CURSOR_BDIAGSIZE
			else:
				var nearside := _nearest_side(lmp)
				if _is_near_side(lmp, nearside):
					match nearside:
						SIDE_TOP, SIDE_BOTTOM:
							mouse_default_cursor_shape = Control.CURSOR_VSIZE
						SIDE_LEFT, SIDE_RIGHT:
							mouse_default_cursor_shape = Control.CURSOR_HSIZE
				else:
					mouse_default_cursor_shape = Control.CURSOR_DRAG
	if event.is_action_pressed("open_context_menu"):
		var menu = context_menu()
		menu.add_item("Close")
		menu.index_pressed.connect(func(idx): if menu.get_item_text(idx) == "Close": queue_free())
		menu.visibility_changed.connect(func(): if not menu.visible: menu.queue_free())
		menu.position = get_viewport().get_mouse_position() 
		get_tree().root.add_child(menu)
		menu.show()

## Return a [Container] containing [Pane]'s inner UIs.
func get_ui() -> Container:
	return _ui

## A function to be overidden to generate context menu when
## [code]event.is_action_pressed("open_context_menu")[/code].[br][br]
## It best to be handled like:[codeblock]
## var ctxm := super()
## ctxm.add_item(...)
## ...
## ctxm.index_pressed.connect(func(idx: int):
##   match ctxm.get_item_text(idx):
##     ...:
##       ...
##     ...
## ); return ctxm
## [/codeblock]
## [b]NOTE[/b]: Item labeled "Close" will be appended.
func context_menu() -> PopupMenu:
	return PopupMenu.new()

# Get [Corner|Side] nearest to [param pos]. [param pos] is relative to [member position]
func _nearest_corner(pos: Vector2) -> Corner:
	var toppe = pos.y <= size.y / 2
	var lefte = pos.x <= size.x / 2
	if toppe:
		if lefte: return CORNER_TOP_LEFT
		else: return CORNER_TOP_RIGHT
	else:
		if lefte: return CORNER_BOTTOM_LEFT
		else: return CORNER_BOTTOM_RIGHT
func _nearest_side(pos: Vector2) -> Side:
	var midiff := (pos - size / 2) / (size / 2) ## middle diff normalized
	var toppe := midiff.y <= 0
	var lefte := midiff.x <= 0
	if toppe:
		if lefte:
			if -midiff.x <= -midiff.y: return SIDE_TOP
			else: return SIDE_LEFT
		else:
			if midiff.x <= -midiff.y: return SIDE_TOP
			else: return SIDE_RIGHT
	else:
		if lefte:
			if -midiff.x <= midiff.y: return SIDE_BOTTOM
			else: return SIDE_LEFT
		else:
			if midiff.x <= midiff.y: return SIDE_BOTTOM
			else: return SIDE_RIGHT
# Return [true] if [param pos] is near 2nd param. implcit param: [_resize_radius]
func _is_near_corner(pos: Vector2, corner: Corner) -> bool:
	var comp: Vector2 ## Compare value
	## The right form of `<=` for [Vector2]. Return [true] if [param left] less then or
	## equal to [param right].
	var le := func(left, right):
		if left.x <= right.x and left.y <= right.y: return true
		return false
	match corner:
		CORNER_TOP_LEFT: comp = pos
		CORNER_TOP_RIGHT: comp = pos - Vector2.RIGHT * size
		CORNER_BOTTOM_RIGHT: comp = pos - size
		CORNER_BOTTOM_LEFT: comp = pos - Vector2.DOWN * size
	return le.call(abs(comp), Vector2.ONE * _resize_radius)
func _is_near_side(pos: Vector2, side: Side) -> bool:
	var comp: float
	match side:
		SIDE_TOP: comp = pos.y
		SIDE_RIGHT: comp = pos.x - size.x
		SIDE_BOTTOM: comp = pos.y - size.y
		SIDE_LEFT: comp = pos.x
	return abs(comp) <= _resize_radius
