extends HBoxContainer

@onready var grid: Grid = $CurveGrid
@onready var curve: Line2D = $CurveGrid/Curve
@onready var meta: VBoxContainer = $Meta
@onready var code: CodeEdit = $Meta/CodeEdit
@onready var err_label: Label = $Meta/ErrLabel
@onready var res_spin_box: SpinBox = $Meta/Resolution/Counter

var _exported: Array[CanvasItem] = []
var _t = 0.0

func _ready() -> void:
	code.text_changed.connect(func(): _t = 0.0; _calcu())
	res_spin_box.value_changed.connect(func(v): _t = 0.0; _update(v))
	_update(res_spin_box.value)

func _process(delta: float) -> void:
	if code.get_text().find("TIME") != -1:
		_t += delta;
		_calcu()

func _get_assign(line: String) -> String:
	var ass := line.substr(0, line.find("=") + 1)
	if ass.is_empty(): err("Expected 'var=...' at line '%s'." % line); return ""
	ass = ass.substr(0, ass.length() - 1)
	ass = ass.strip_edges()
	if not ass.is_valid_identifier():
		err("'%s' at line '%d' is not a valid identifier." % [ass, line]); return ""
	return ass
		
func _calcu() -> void:
	var code_lines := code.text.split("\n")
	
	# End line must be assignment to X or Y
	var target: String = _get_assign(code_lines.get(code_lines.size() - 1))
	if target != "X" and target != "Y": err("Expected 'X=...' or 'Y=...' at the end of the code."); return
	var target_oppo := "X"
	if target == "X": target_oppo = "Y"
	var split = 1.0 / (res_spin_box.value / 2)
	for i in range(res_spin_box.value):
		var bank: Dictionary[String, float] = {
			target_oppo: -1.0 + (split * i),
			"RESO": res_spin_box.value,
			"TIME": _t,
		}
		
		for line in code_lines:
			var ass = _get_assign(line)
			
			# Ready expression result up
			var expr = line.substr(line.find("=") + 1).strip_edges()
			var result
			if expr == "export":
				_create_export(ass)
				result = _get_export(ass)
			else:
				var exprc = Expression.new()
				var err = exprc.parse(expr, bank.keys())
				if err != OK: err(exprc.get_error_text()); return
				result = exprc.execute(bank.values(), RefCounted.new())
				if exprc.has_execute_failed(): err(exprc.get_error_text()); return
			
			# Bank value.
			bank[ass] = float(result)
		
		var grid_half = grid.size / 2
		curve.points[i] = Vector2(bank["X"], bank["Y"]) * grid_half + grid_half
	
	_clear_export()
	err("All is good.")

func err(text) -> void:
	err_label.text = text

func _create_export(varie: String) -> void:
	if varie.is_empty(): return
	# if _exported.has(name == "name"):
	for export in _exported:
		if export.name == varie: return
	
	var export = preload("res://expr_curve/exported.tscn").instantiate()
	export.name = varie
	export.find_child("Label").text = varie
	meta.add_child(export)
	_exported.append(export)

func _get_export(varie: String) -> float:
	for export in _exported:
		if export.name == varie:
			return export.find_child("Counter").value
	return 0.0

func _clear_export() -> void:
	var hold_exported: PackedStringArray = []
	for line in code.get_text().split("\n"):
		if line.substr(line.find("=") + 1).strip_edges() == "export":
			hold_exported.append(_get_assign(line))
	for export in _exported:
		if not hold_exported.has(export.name):
			_exported.erase(export)
			export.queue_free()

func _update(v) -> void:
	curve.points = []
	for i in range(v):
		curve.add_point(Vector2.ZERO)
	_calcu()
