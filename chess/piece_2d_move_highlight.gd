class_name Piece2DMoveHighlight extends Sprite2D

@export var notation: String = "a1":
	set(v): if Chess.is_valid_notation(v): notation = v
@export var board: Grid

func _init(note: String, grid: Grid, capture: bool = false) -> void:
	notation = note; board = grid
	texture = preload("uid://bh6vkxaedllcd")
	if capture: texture = preload("uid://cecjav8k40b1h")

func _process(_delta: float) -> void:
	var space = board.size / (board.grid + 1)
	position = board.position + (space * Vector2(Chess.corec(notation).position)) - (space / 2)
