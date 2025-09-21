extends Node

@onready var center: Node2D = $Center
@onready var center_algo: Label = $CenterAlgo
@onready var line: Line2D = $Line

var _points: Array[Node2D] = []

func _input(event: InputEvent) -> void:
	if event.is_action("show_line"):
		line.visible = event.is_action_pressed("show_line")
	if event.is_action_pressed("add_point"):
		var p = preload("res://centre_points/point.tscn").instantiate()
		p.position = get_viewport().get_mouse_position()
		_points.append(p)
		add_child(p)
	if event.is_action_pressed("reset"):
		for node in _points:
			if node: node.queue_free()
		_points.clear()

func _process(delta: float) -> void:
	var sum := Vector2.ZERO
	var count := 0
	
	var line_start_pos := Vector2.ZERO
	line.clear_points()
	
	center_algo.text = ""
	
	for node in _points:
		if node:
			sum += node.position
			count += 1
			line.add_point(node.position)
			
			node.name = "P%d" % count
			center_algo.text += "%s %s\n+ " % [node.name, node.position]
	
	center.position = sum  / count
	
	center_algo.text = center_algo.text.substr(0,center_algo.text.length() - 3)
	center_algo.text += "\n/ %d" % count
	center_algo.text += "\n----------------"
	center_algo.text += "\n= %s (%.2f, %.2f)" % [center.name, center.position.x, center.position.y]
