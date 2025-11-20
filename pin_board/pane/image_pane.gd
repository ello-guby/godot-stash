@tool class_name ImagePane extends EditablePane
## Custom [Pane] for displaying image.

## The image's file path to display.
@export_file("*.png", "*.jpeg", "*.jpg", "*.svg", "*.webp") var file_path: String = "":
	set(v): file_path = v; _update()

## Keep the aspect ratio.
@export var keep_aspect_ratio: bool = false
## What kind of expanding to apply.
@export var expand_mode: TextureRect.ExpandMode = TextureRect.EXPAND_KEEP_SIZE:
	set(v): expand_mode = v; if _img: _img.expand_mode = v
## What kind of stretching to apply.
@export var stretch_mode: TextureRect.StretchMode = TextureRect.STRETCH_SCALE:
	set(v): stretch_mode = v; if _img: _img.stretch_mode = v

var _errlabel := Label.new()
var _img := TextureRect.new()

## Create a new [ImagePane].
func _init():
	super()
	editable_properties = [
		"file_path global_file *.png *.svg *.jpg *.jpeg *.webp",
		"expand_mode enum Keep Ignore FitWidth FitWidthProp FitHeight FitHeightProp",
		"stretch_mode enum Scale Tile Keep Centered KeepAspect KeepAspectCentered KeepAspectCovered",
		"keep_aspect_ratio",
	]
	_errlabel.modulate = Color(0.634, 0.634, 0.634, 1.0)
	_errlabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_err("No image.\n\n[Right Click] to edit.")

func _process(delta: float) -> void:
	super(delta)
	if keep_aspect_ratio and _img.texture:
		var img_size := _img.texture.get_size()
		var mpos := get_local_mouse_position()
		if mpos.x >= mpos.y:
			var ratio := img_size.y / img_size.x
			size.y = size.x * ratio
		else:
			var ratio := img_size.x / img_size.y
			size.x = size.y * ratio
	
	for child in _ui.get_children():
		if child is Control: child.position = Vector2.ZERO; child.size = size


## Return a [ImagePane]'s [TextureRect].
func get_texrect() -> TextureRect:
	return _img

## Make [ImagePane] rematching image size.
func refit() -> void:
	if _img.texture: size = _img.texture.get_size()

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
	ctxm.add_item("Refit")
	ctxm.index_pressed.connect(
		func(idx: int): if ctxm.get_item_text(idx) == "Refit": refit()
	); return ctxm

# Update [_img] if [file_path] is a ok.
func _update() -> void:
	if not file_path: return
	if not FileAccess.file_exists(file_path): _err("Cannot find '%s' in '%s'." % [file_path.get_file(), file_path.get_base_dir()]); return
	var img = Image.load_from_file(file_path); if not img: _err("Error loading '%s'" % [file_path]); return
	var tex = ImageTexture.create_from_image(img)
	_display(tex)
# Display image.
func _display(tex: Texture2D) -> void:
	if not is_node_ready(): await ready
	if _errlabel.get_parent() == get_ui(): get_ui().remove_child(_errlabel)
	if _img.get_parent() != get_ui(): get_ui().add_child(_img)
	_img.texture = tex
# Display error [msg] instead of image.
func _err(msg: String) -> void:
	if not is_node_ready(): await ready
	if _img.get_parent() == get_ui(): get_ui().remove_child(_img)
	if _errlabel.get_parent() != get_ui(): get_ui().add_child(_errlabel)
	_errlabel.text = msg
