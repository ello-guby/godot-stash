@tool
class_name Grid extends Control
## A [Control] node to display grid.
##
## This node utilize a built-in [Line2D] node to create grids.

## Amount of grids.
@export var grid: int = 3:
	set(v): grid = v; _repopulate()
## Grid's line size / thickness / boldness.
@export var line_width: float = 10.0:
	set(v): line_width = v; _repopulate()
## Whether to have a border.
@export var border: bool = true:
	set(v): border = v; _repopulate()
## Border's line size / thickness / boldness.
@export var border_width: float = 10.0:
	set(v): border_width = v; _repopulate()

var _border: Line2D
var _h_lines: Array[Line2D]
var _v_lines: Array[Line2D]

func _ready() -> void:
	_repopulate()

func _process(delta: float) -> void:
	var center := Vector2(size / 2)
	
	var gcount := 0
	var h_split := size.y / (grid + 1)
	for line in _h_lines:
		var split = h_split + (h_split * gcount)
		line.points[0] = Vector2(0, split)
		line.points[1] = Vector2(size.x, split)
		gcount += 1
	gcount = 0
	var v_split := size.x / (grid + 1)
	for line in _v_lines:
		var split = v_split + (v_split * gcount)
		line.points[0] = Vector2(split, 0)
		line.points[1] = Vector2(split, size.y)
		gcount += 1
	
	if border and _border:
		_border.points[0] = Vector2(0, 0)
		_border.points[1] = Vector2(size.x, 0)
		_border.points[2] = size
		_border.points[3] = Vector2(0, size.y)

func _repopulate() -> void:
	for lines in [_h_lines, _v_lines]:
		for line in lines:
			if line: line.queue_free()
		lines.clear()
		
		for i in range(grid):
			var l := Line2D.new()
			l.add_point(Vector2.ZERO)
			l.add_point(Vector2.ZERO)
			l.width = line_width
			add_child(l)
			lines.append(l)
	
	if border:
		if not _border:
			_border = Line2D.new()
			_border.width = border_width
			_border.closed = true
			for i in range(4): _border.add_point(Vector2.ZERO)
			add_child(_border)
		else:
			_border.width = border_width
	else:
		if _border: _border.queue_free()
