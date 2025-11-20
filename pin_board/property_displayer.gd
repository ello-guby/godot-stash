class_name PropertyDisplayer extends Label
## A [Label] that display [member master]'s properties.

## A [Node] to get info from.
@export var master: Node
## A [PackedStringArray] of property names to display.[br][br]
## Can be [Expression] processed, by having [code]&[/code] within a property. the
## [code]&[/code] will be replaced with [member master]. Example:[codeblock]
## &.position.normalize() # Gonna be "master.position.normalize()".
## [/codeblock]
## And might also want to rename to something make sense. For that, just rename with
## the comment character [code]#[/code]:[codeblock]
## &.size.x # width
## [/codeblock]
@export var properties: PackedStringArray
## A [String] to put between each property. Multiline cus u might want to put newline.
@export_multiline var properties_split: String = "\n"
## A [String] to put between property name and property value. Multiline cus u might
## want to put newline.
@export_multiline var property_split: String = ": "

func _process(_delta: float) -> void:
	var s := ""
	for prop in properties:
		var val
		var nom := prop
		if prop.find("&") != -1:
			var com := prop.find("#")
			if com < 0: com = -1
			else: nom = prop.substr(com + 1).strip_edges()
			var expr := prop.substr(0, com).replace("&", "master")
			var exprc := Expression.new() ## expr class
			exprc.parse(expr, ["master"])
			val = exprc.execute([master])
			if exprc.has_execute_failed(): print(exprc.get_error_text())
		else:
			val = master.get(prop)
		s += "%s%s%s%s" % [nom, property_split, val, properties_split]
	text = s.substr(0, s.length() - properties_split.length()) # remove trailing props split.
