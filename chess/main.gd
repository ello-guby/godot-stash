@tool
extends Control

var chess := Chess.new()
@export var grid: Grid
@onready var line_edit: LineEdit = $LineEdit
var highlighters: Array[Piece2DMoveHighlight] = []

var _board: Array[Piece2D] = [] ## board for imgs.

func _ready() -> void:
	line_edit.text_submitted.connect(request_move)
	line_edit.text_changed.connect(highlight)
	chess.piece_captured.connect(func(_cap: Piece, field: Piece, _note: String):
		var piece2d = preload("uid://d0u1fjodjry2h").instantiate() as Piece2D
		piece2d.board = grid
		piece2d.piece = field
		piece2d.pressed.connect(highlight)
		piece2d.moved.connect(request_move)
		add_child(piece2d)
		_board.append(piece2d)
	)
	for rank in chess.board:
		for piece in rank as Array[Piece]:
			var piece2d = preload("uid://d0u1fjodjry2h").instantiate() as Piece2D
			piece2d.board = grid
			piece2d.piece = piece
			piece2d.pressed.connect(highlight)
			piece2d.moved.connect(request_move)
			add_child(piece2d)
			_board.append(piece2d)

func highlight(t: String):
	if Chess.is_valid_notation(Chess.posit(t)):
		for highlighter in highlighters: highlighter.queue_free()
		highlighters.clear()
		for mv in chess.get_moves_of(Chess.posit(t)):
			var h = Piece2DMoveHighlight.new( ## Highlighter
				Chess.movit(mv),
				grid,
				chess.get_piece(Chess.movit(mv)).opposed(chess.get_piece(mv))
			)
			h.scale *= 0.5
			add_child(h)
			highlighters.append(h)

func request_move(t: String):
	for highlighter in highlighters: highlighter.queue_free()
	highlighters.clear()
	if not chess.move(t): print("not good")
	#chess.print_board(true)
	prints(chess.captures)
