@tool class_name EditablePane extends Pane
## A [Pane] that can be edited with [EditPane]
##
## It will come with additional context menu labeled [code]"Edit"[/code] which will open it's [EditPane]

## An [EditPane] used to edit this [EditablePane].
var setting: EditPane

## A [PackedStringArray] containing property that can be edited.
## A string can be formatted like:[codeblock]
## "name" # Will let [member setting] "export" the property "name" to be edited.
## [/codeblock]
## Annotations are limitedly supported like:[codeblock]
## "img_path file *.png *.svg *.jpg"
## [/codeblock]
## Where [code]img_path[/code] is the property name. [code]file[/code] is the
## [code]@export_file[/code] annotation, no need for [code]@export_[/code].
## And the rest are the annotation arguments.
## Supported annotation are:[codeblock]
## "num enum a b c"        # like @export_enum but only for int or float.
## "num range 10 20 0.5"   # like @export_range.
## "str file *.ext"        # like @export_file.
## "str global_file *.ext" # like @export_global_file.
## "clb"                   # Callable type. Will be a button calling it when pressed. like @export_tool_button
## [/codeblock]
## [b]NOTE[/b]: This only work on [bool], [int], [float], [String] and [Callable]
## typed properties for now...
@export var editable_properties: PackedStringArray = []

func _exit_tree() -> void:
	if setting: setting.queue_free()

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
	var ctxm := super()
	ctxm.add_item("Edit")
	ctxm.index_pressed.connect(func(idx: int): if ctxm.get_item_text(idx) == "Edit":
		if not setting: setting = EditPane.new(self)
		setting.position = get_viewport().get_camera_2d().get_global_mouse_position() - setting.size / 2
		if not setting.is_inside_tree(): $/root/Board.add_child(setting)
		else: setting.move_to_front()
	); return ctxm
