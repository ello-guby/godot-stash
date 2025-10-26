class_name Piece2D extends Area2D
## [Chess.Piece] but for displaying in 2d

signal pressed(notation: String)
signal moved(notation: String)

## [Sprite2D] to display piece
@export var sprite: Sprite2D
## Board as [Grid] to display self position at
@export var board: Grid
## Link to piece.
@export var piece: Piece:
	set(v): piece = v; _update()

## Chess sprite img resource, accessed via [code]SPRITE[<team>][<type>][/code].
const SPRITE: Array = [ # SPRITE[team][type]
	[ # white
		preload("uid://dbmqg1dlebiqo"),
		preload("uid://3ex60uwl54ap"),
		preload("uid://dhmhmcni4xwfj"),
		preload("uid://bkrqup88xk7go"),
		preload("uid://dshqtliqh8bp"),
		preload("uid://h34v3sr3vvyi"),
	], [ # black
		preload("uid://dp04eqv876x72"),
		preload("uid://clsil6ocaobi6"),
		preload("uid://dclgsguxnpsep"),
		preload("uid://bsy60h2m6bi4n"),
		preload("uid://dh5xdr3xaww2"),
		preload("uid://b8da1hjvsh354"),
	],
]
const FIELD_SPRITE := preload("uid://d0i25f2avrta0")

var _hover := false
var _press := false

func _ready() -> void:
	mouse_entered.connect(func(): _hover = true)
	mouse_exited.connect(func(): _hover = false)
	
	if board:
		var space = board.size / (board.grid + 1)
		position = board.position + (space * Vector2(piece.file(), piece.rank())) - (space / 2)

func _process(_delta: float) -> void:
	if not board: return
	var space = board.size / (board.grid + 1)
	if not _hover:
		position = position.lerp(board.position + (space * Vector2(piece.file(), piece.rank())) - (space / 2), 0.5)
	
	if not _hover and piece.board.captures.has(piece):
		position.x = board.position.x + board.size.x / 2 + ((board.size.x / 2 + space.x) * sign(piece.team - 0.5))
		var titer := 0 ## Team iter
		for p in piece.board.captures:
			if p.team == piece.team: titer += 1
			if p == piece: 
				position.y = board.position.y + space.y * titer
				break

func _input(event: InputEvent) -> void:
	if _hover and event.is_action_pressed("add_point"):
		_press = true; pressed.emit(piece.position)
	if event.is_action_released("add_point"):
		if _hover and _press:
			for area in get_overlapping_areas():
				if area is Piece2D: moved.emit(piece.position + area.piece.position)
				break
		_press = false; _hover = false
	if _hover and _press and event is InputEventMouseMotion:
		position += event.relative

func _update() -> void:
	if piece.is_field(): sprite.texture = FIELD_SPRITE
	else: sprite.texture = SPRITE[piece.team][piece.type]
