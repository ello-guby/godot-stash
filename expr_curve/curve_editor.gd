extends HBoxContainer

@onready var grid: Grid = $CurveGrid
@onready var curve: Line2D = $CurveGrid/Curve
@onready var code: CodeEdit = $Meta/CodeEdit
@onready var err_label: Label = $Meta/ErrLabel
@onready var res_spin_box: SpinBox = $Meta/Resolution/SpinBox

var _t = 0.0

func _ready() -> void:
	code.text_changed.connect(func(): _t = 0.0; _calcu())
	res_spin_box.value_changed.connect(func(v): _t = 0.0; _update(v))
	_update(res_spin_box.value)

func _process(delta: float) -> void: _t += delta; _calcu()

func _get_assign(line: String) -> String:
	var ass := line.substr(0, line.find("=") + 1)
	if ass.is_empty(): err("Expected 'var=...' at line '%s'." % line); return ""
	ass = ass.substr(0, ass.length() - 1)
	ass = ass.strip_edges()
	if not ass.is_valid_identifier():
		err("'%s' at line '%d' is not a valid identifier." % [ass, line]); return ""
	return ass
		
func _calcu() -> void:
	var code_lines := Array(code.text.split("\n"))
	
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
			
			# Ready expression up
			var expr = Expression.new()
			var err = expr.parse(line.substr(line.find("=") + 1), bank.keys())
			if err != OK: err(expr.get_error_text()); return
			
			# Bank value.
			var result = expr.execute(bank.values(), RefCounted.new())
			if expr.has_execute_failed(): err(expr.get_error_text()); return
			bank[ass] = float(result)
		
		var grid_half = grid.size / 2
		curve.points[i] = Vector2(bank["X"], bank["Y"]) * grid_half + grid_half
	err("All is good.")

func err(text) -> void:
	err_label.text = text

func _update(v) -> void:
	curve.points = []
	for i in range(v):
		curve.add_point(Vector2.ZERO)
	_calcu()
