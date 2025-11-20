@tool class_name EditPane extends Pane
## A [Pane] to edit an [EditablePane]

## Emitted after a value has been edited.
signal edited(property_name: String, value: Variant)

## An [EditablePane] to get edited.
@export var host: EditablePane

var _props := VBoxContainer.new()

## Create a [EditPane] with [param hoster] as [member host]
func _init(hoster: EditablePane = null) -> void:
	super()
	host = hoster
	size = Vector2(400, 200)
	
	get_ui().add_child(_props)
	_repop()

func _process(delta: float) -> void:
	super(delta)
	_props.size = get_ui().size

func _repop() -> void: if host: # populate settings
	for c in _props.get_children(): c.queue_free()
	
	var edit := Label.new(); edit.text = "Edit"; edit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_props.add_child(edit)
	
	for prop in host.editable_properties:
		var ws := prop.split(" ", false) # 0: name, 1: export option, ...: export opt arguements
		var l := Label.new(); l.text = ws[0]
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cont := HBoxContainer.new()
		cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sett := func(vall: Variant, propp: String = ws[0]): ## Set wrap
			host.set(propp, vall); edited.emit(propp, vall)
		var val = host.get(ws[0])
		match typeof(val):
			TYPE_BOOL:
				var cb := CheckBox.new()
				cb.text = "On"
				cb.button_pressed = val
				cb.pressed.connect(func(): sett.call(cb.button_pressed))
				cont.add_child(cb)
			TYPE_INT, TYPE_FLOAT: match ws[1].to_lower():
				"enum":
					var ob := OptionButton.new()
					ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					ob.item_selected.connect(func(idx: int): sett.call(idx))
					for opt in ws.slice(2):
						ob.add_item(opt)
					ob.selected = val
					cont.add_child(ob)
				"range":
					var le := SpinBox.new()
					var sl := HSlider.new()
					sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					le.value = val
					le.value_changed.connect(func(v: float): sl.value = v; sett.call(v))
					sl.value = val
					sl.min_value = ws[2].to_float()
					sl.max_value = ws[3].to_float()
					if ws[4].to_float(): sl.step = ws[4].to_float()
					sl.value_changed.connect(func(v: float): le.value = v; sett.call(v))
					cont.add_child(sl); cont.add_child(le)
				_:
					var sb := SpinBox.new()
					sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					sb.value = val
					sb.value_changed.connect(func(v: float): sett.call(v))
					cont.add_child(sb)
			TYPE_STRING:
				match ws[1]: # property export annotation. like "file" or "global_file", without the @export_.
					"multiline":
						var te := TextEdit.new()
						te.text = val
						te.size_flags_horizontal = Control.SIZE_EXPAND_FILL
						te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
						te.text_changed.connect(func(): sett.call(te.text))
						cont.add_child(te)
					"file", "global_file":
						var le := LineEdit.new()
						le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
						le.text = val
						le.text_submitted.connect(func(t: String): sett.call(t))
						cont.add_child(le)
						var bu := Button.new()
						bu.text = "Open"
						bu.pressed.connect(func():
							var fd := FileDialog.new()
							fd.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
							if ws[1] == "file": fd.access = FileDialog.ACCESS_RESOURCES
							else: fd.access = FileDialog.ACCESS_FILESYSTEM
							fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
							var filt := ""; for w in ws.slice(2): filt += w + ", "
							fd.add_filter(filt.substr(0, filt.length()), "Supported")
							if FileAccess.file_exists(host.file_path): fd.current_dir = host.file_path.get_base_dir()
							else: fd.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
							fd.file_selected.connect(func(f: String): sett.call(f); le.text = f)
							fd.visibility_changed.connect(func(): if not fd.visible: fd.queue_free())
							get_tree().root.add_child(fd)
							fd.show()
						)
						cont.add_child(bu)
					_:
						var le := LineEdit.new()
						le.text = val
						le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
						le.text_submitted.connect(func(t: String): sett.call(t))
						cont.add_child(le)
			TYPE_CALLABLE:
				var bu := Button.new()
				bu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				bu.text = ws[0]
				bu.pressed.connect(val)
				cont.add_child(bu)
		var c := HBoxContainer.new()
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
		c.add_child(l)
		c.add_child(cont)
		_props.add_child(c)
