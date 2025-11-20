@tool class_name TextPane extends EditablePane
## An [EditablePane] to display formatted [member text].
## 
## Support text formatting, such as:[codeblock lang=text]
##
## _Italic_
## __Bold__
##
## *Also Italic*
## **Also Bold**
##
## ~~Strikethrough~~
##
## # Header
## ## Sub-Header
##
## Also Header
## ================
## Also Sub-Header
## ---------------------
##
## - Bullet List
##   - Sub-Bullet List
## + Also Bullet List
##   + Also Sub-Bullet List
## * And Also Bullet List
##   * And Also Sub-Bullet List
##
## 1. Numbered List
## 	1. Sub-Numbered List
## 2. Another Numbered List
##
## A. Character List
## 	A. Sub-Character List
## B. Another Character List
##
## I. Roman Numeral List
## 	I. Sub-Roman Numeral List
## II. Another Roman Numeral List
## 
## [b][rainbow]BBcode also supported[/rainbow][/b]
## [/codeblock]

## The text to be formatted and display.
@export_multiline var text: String = "**Right Click** to ***Edit***":
	set(v): text = v; _fmt()
## Add a [String] examples of possible markup.
@export_tool_button("Add Markup Examples", "Add") var add_markup_examples: Callable = func():
	text += """
_Italic_
__Bold__

*Also Italic*
**Also Bold**

~~Strikethrough~~

# Header
## Sub-Header

Also Header
================
Also Sub-Header
---------------------

- Bullet List
	- Sub-Bullet List

+ Also Bullet List
	+ Also Sub-Bullet List

* And Also Bullet List
	* And Also Sub-Bullet List

1. Numbered List
	1. Sub-Numbered List
2. Another Numbered List

A. Character List
	a. Sub-Character List
B. Another Character List

I. Roman Numeral List
	i. Sub-Roman Numeral List
II. Another Roman Numeral List

[b][rainbow]BBcode also supported[/rainbow][/b]
"""

var _text := RichTextLabel.new()

func _init():
	super()
	_text.mouse_filter = Control.MOUSE_FILTER_PASS
	_text.bbcode_enabled = true
	_text.tab_size = 2
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	get_ui().add_child(_text)
	
	editable_properties = [
		"text multiline",
		"add_markup_examples",
	]
	_fmt()

func _process(delta: float) -> void:
	super(delta)
	for child in get_ui().get_children(): if child is Control:
		child.position = Vector2.ZERO
		child.size = size

func _fmt() -> void:
	_text.text = markdown_to_bbcode(text, _text.get_theme_font_size("font_size"), _text.tab_size)

## Parse basic Markdown [param text] to BBcode.[br][br]
## [param default_font_size] is used to make header bigger, supply it with
## [method Control.get_theme_font_size] or wrap return with
## [code]"[font_size={default_font_size}]...[/font_size]"[/code].[br]
## [param tab_size] is used to indenting list.
@warning_ignore("shadowed_variable")
static func markdown_to_bbcode(text: String, default_font_size: int = 10, tab_size: int = 2) -> String:
	# Stolen from: https://gitlab.gnome.org/World/apostrophe/-/blob/c1fc61e5c04bae7ab7fd1557970d7231d175854c/apostrophe/markup_regex.py
	var t := text
	# lists # due to very different style `- a\n- b\n- c` vs `[ul]\na\nb\nc[/ul]` we need loop aproach
	var space_tab := ""; for _i in range(tab_size): space_tab += " "
	var list := func(og_t: String, regex: RegEx, else_handle: Callable, tag: String = "rainbow", param_handle: Callable = func(_rem): return "") -> String:
		while true:
			var re_matches := regex.search_all(og_t)
			if re_matches.size() == 0: return og_t
			for rem in re_matches:
				var unindented_string := ""
				for line in rem.strings[0].split("\n"):
					unindented_string += "\n"
					if line.begins_with(space_tab): unindented_string += line.substr(tab_size)
					elif line.begins_with("\t"): unindented_string += line.substr(1)
					else: unindented_string += else_handle.call(line)
				og_t = og_t.replace(rem.strings[0], "[%s%s]%s\n[/%s]" % [tag, param_handle.call(rem), unindented_string, tag])
		return og_t # damn ok
	t = list.call(t,
		RegEx.create_from_string(r"(?<=\n|^)([-+\*])(?!\1) [\s\S]*?(?=\n[^-+\*\t {%d}]|$)" % tab_size),
		func(l: String) -> String: return l.substr(1).strip_edges(), # remove - and strip whites
		"ul"
	)
	t = list.call(t,
		RegEx.create_from_string(r"(?<=\n|^)(?<index>.)\. [\s\S]*?(?=\n(?!.*?\.| {%d})|$)" % tab_size),
		func(l: String) -> String: return l.substr(l.find(".") + 1).strip_edges(), # remove #. and strip whites
		"ol", func(rem: RegExMatch) -> String: return " " + rem.get_string("index")
	)
	# simple wrap
	var wrapre := r"(?<!\\)%s(?<text>[\s\S]+?)(?<!\\)%s"
	t = RegEx.create_from_string(wrapre % [r"((\*\*|__)([*_])|([*_])(\*\*|__))", r"(\5\4|\3\2)"]).sub(t, "[b][i]${text}[/i][/b]", true)
	t = RegEx.create_from_string(wrapre % [r"(\*\*|__)", r"\1"]).sub(t, "[b]${text}[/b]", true)
	t = RegEx.create_from_string(wrapre % [r"(\*|_)", r"\1"]).sub(t, "[i]${text}[/i]", true)
	t = RegEx.create_from_string(wrapre % ["(~~)", r"\1"]).sub(t, "[s]${text}[/s]", true)
	t = RegEx.create_from_string(wrapre % ["(`)", r"\1"]).sub(t, "[code]${text}[/code]", true)
	# headers
	var head := func(size_mult: float): return "[b][font_size=%d]${text}[/font_size][/b][hr]" % (default_font_size * size_mult)
	t = RegEx.create_from_string(r"(?<!\N)## ?(?<text>.*)").sub(t, head.call(1.2), true) # hash head
	t = RegEx.create_from_string(r"(?<!\N)# ?(?<text>.*)").sub(t, head.call(1.4), true)
	t = RegEx.create_from_string(r"(?<!\N)(?<text>.*?)\n-{2,}").sub(t, head.call(1.2), true) # hr head
	t = RegEx.create_from_string(r"(?<!\N)(?<text>.*?)\n={2,}").sub(t, head.call(1.4), true)
	return t
