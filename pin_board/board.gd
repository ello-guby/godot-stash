class_name Board extends Node2D

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("open_context_menu") and not get_viewport().gui_get_focus_owner():
		var menu := PopupMenu.new()
		menu.add_item("New Empty Pane")
		menu.add_item("New Image Pane")
		menu.add_item("New Text Pane")
		menu.add_item("Quit")
		menu.index_pressed.connect(func(idx):
			var new_pane: Pane
			match idx:
				0: new_pane = Pane.new()
				1: new_pane = ImagePane.new()
				2: new_pane = TextPane.new()
				3: get_tree().quit()
			if new_pane:
				new_pane.position = get_viewport().get_camera_2d().get_global_mouse_position() - new_pane.size / 2
				add_child(new_pane)
		)
		menu.visibility_changed.connect(func(): if not menu.visible: menu.queue_free())
		menu.position = get_viewport().get_mouse_position()
		add_child(menu)
		menu.show()
