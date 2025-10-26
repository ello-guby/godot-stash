class_name Chess extends Resource
## Object to do chessing
##
## [b]Notation[/b]:[br]
## Mostly like the standard long algebraic without piece name initial ([code]"c1e3"[/code]: a piece at c1 move to e3) but:[br]
## - Capture notation ([code]"x"[/code]) are implicit, notations such as [code]"c2xc3"[/code] are invalid.

# rank(num) : column
# file(char): row

## Emmited after [method move] right before returning success.
## Come with the [param from] and [param to] pieces.
signal moved(from: Piece, to: Piece, notation: String)
## Emmited when a [Piece] just got captured.
## Come with the [param captured] piece.
## [param new_field] is the [param captured] replacement.
signal piece_captured(captured: Piece, new_field: Piece, notation: String)

## Place where it all happen.
## Getting a piece via [Array] accessor ([code][#][/code]) will be [code]board[RANK][FILE][/code]
## and ofcource will need to be index.[br]
## Generated after [method _init] aka [method new].
var board: Array[Array] = []
## History of moves
var history: Array[String] = []
## Captured [Piece]s
var captures: Array[Piece] = []
## Which team is making move.
var moving: Piece.Team = Piece.Team.WHITE:
	set(v):
		if v == Piece.Team.NATURAL:
			printerr("Piece.Team.NATURAL is not for Chess.moving")
			return
		moving = v

## Files
enum File {
	A = 1, B,
	C, D, E,
	F, G, H,
}

func _init() -> void:
	var gen_rank = func(type: Piece.Type, team: Piece.Team, rank: int) -> Array:
		var a := []
		for file in files():
			var t = type
			if type != Piece.Type.PAWN and type != Piece.Type.FIELD:
				match file:
					"a", "h": t = Piece.Type.ROOK
					"b", "g": t = Piece.Type.NIGHT
					"c", "f": t = Piece.Type.BISHOP
					"d": t = Piece.Type.QUEEN
					"e": t = Piece.Type.KING
			a.append(Piece.new(self, t, team, "%s%d" % [file, rank]))
		return a
	
	for rank in ranks():
		match rank:
			1: board.append(gen_rank.call(Piece.Type.KING, Piece.Team.WHITE, rank))
			2: board.append(gen_rank.call(Piece.Type.PAWN, Piece.Team.WHITE, rank))
			3, 4, 5, 6:
				board.append(gen_rank.call(Piece.Type.FIELD, Piece.Team.NATURAL, rank))
			7: board.append(gen_rank.call(Piece.Type.PAWN, Piece.Team.BLACK, rank))
			8: board.append(gen_rank.call(Piece.Type.KING, Piece.Team.BLACK, rank))

## Print the board with the size of 16x8 of chars.
## Example:[codeblock lang=text]
## #R#N#B#Q#K#B#N#R
## #P#P#P#P#P#P#P#P
##
##
##
##
## @P@P@P@P@P@P@P@P
## @R@N@B@Q@K@B@N@R
## [/codeblock]
## [param rich] will display in colour,
## [param with_move_highlight_of] will display the move highlight only work when [param rich] is [code]true[/code].
func print_board(rich: bool = false, with_move_hightlight_of: String = ""):
	# rich
	var bgc := ["sienna", "saddle_brown"]
	var suf := ""
	var pre := ""
	var iter := 0
	
	# highlight
	var mov := ["gold", "goldenrod"]
	var cap := ["salmon", "tomato"]
	var mvs := get_moves_of(with_move_hightlight_of)
	
	var s := ""
	board.reverse()
	for rank in board:
		for piece in rank as Array[Piece]:
			var col := ""
			# rich
			if rich:
				col = bgc[iter % 2]
				# highlight
				if with_move_hightlight_of:
					for mv in mvs:
						if piece.position == mv.substr(2, 2):
							col = mov[iter % 2]
							if piece.opposed(get_piece(posit(mv))):
								col = cap[iter % 2]
				suf = "[bgcolor=%s] " % col
				pre = "[/bgcolor]"
			s += suf + piece.get_codename(rich) + pre
			iter += 1
		s += "\n"
		iter -= 1
	board.reverse()
	print_rich(s)

## Move a [Chess.Piece] with notation. Return [code]bool[/code] of success.
func move(notation: String) -> bool:
	if not is_valid_notation(notation): return false
	var p = get_piece(notation)
	if p.team != moving: printerr("that piece cant move right now"); return false
	for _move in get_moves_of(notation):
		if _move == notation:
			_swap(_move, true)
			if moving == Piece.Team.WHITE: moving = Piece.Team.BLACK
			else: moving = Piece.Team.WHITE
			history.append(notation)
			moved.emit(p, get_piece(movit(notation)), notation)
			return true
	return false

## Return [code]true[/code] if this chess board

# Make a "kinda" illegal move.
func _swap(notation: String, capturing: bool = false):
	if not is_valid_notation(notation): return
	var a_vec := corec(notation).position
	var b_vec := corec(notation).size
	var a := get_piece(posit(notation))
	var b := get_piece(notation.substr(2, 2))
	if not b: return
	if capturing and b.type != Piece.Type.FIELD:
		captures.append(b)
		var cap := b
		b = Piece.new(self, Piece.Type.FIELD, Piece.Team.NATURAL, algeb(a_vec.x, a_vec.y))
		piece_captured.emit(cap, b, notation)
	board[a_vec.y - 1][a_vec.x - 1] = b
	b.position = algeb(a_vec.x, a_vec.y)
	board[b_vec.y - 1][b_vec.x - 1] = a
	a.position = algeb(b_vec.x, b_vec.y)

## Get the piece on notation's position. return [code]null[/code] if position not good.
func get_piece(notation: String) -> Piece:
	if not is_valid_notation(notation): return null
	var p: Piece = null
	for rank in board:
		for piece in rank as Array[Piece]:
			if piece.position == posit(notation): p = piece
	return p

## Get moves of notation's position piece.
## Return [code][""][/code] if something is wrong.[br]
## Code to check wrong:
## [codeblock]
## if get_move_of(...)[0].is_empty(): # ...handle
## [/codeblock]
func get_moves_of(notation: String) -> Array[String]:
	var p = get_piece(notation)
	if not p: return [""]
	var moves: Array[String] = []
	
	# for the not very special moves...
	var points: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	var diagonal_points := points.duplicate()
	diagonal_points.push_front(diagonal_points.pop_back())
	for i in range(4):
		diagonal_points[i] += points[i]
	var spread_moves = func(pts: Array[Vector2i], for_the_king: bool = false):
		for point in pts:
			for iter in ranks():
				var pos: Vector2i = corec(p.position).position + (point * iter)
				var mv = algeb(pos.x, pos.y)
				if not is_valid_notation(mv): break
				var obstruction := get_piece(mv)
				if obstruction and obstruction.friended(p): break
				moves.append(posit(notation) + mv)
				if obstruction and obstruction.opposed(p): break
				iter += 1
				if for_the_king: break
	
	match p.type:
		Piece.Type.PAWN:
			# TODO: impl en-passant # oh shit, this hard. need history.
			var mv := 0
			var is_start := false
			var en_passantable := false
			match p.team:
				Piece.Team.WHITE:
					mv = -Vector2i.UP.y # negative cus computer up is down
					match p.rank():
						2: is_start = true
						5: en_passantable = true
				Piece.Team.BLACK:
					mv = -Vector2i.DOWN.y
					match p.rank():
						7: is_start = true
						4: en_passantable = true
				_: printerr("Pawn piece is not on white or black team. Dunno where to go."); return [""]
			var pos := corec(p.position).position
			var mk_mv := func(posx: int, posy: int, capturing: bool = false) -> bool:
				var target = get_piece(algeb(posx, posy))
				if target and (capturing and p.opposed(target)) or \
				(not capturing and target.type == Piece.Type.FIELD):
					moves.append(p.position + target.position)
					return true
				return false
			if mk_mv.call(pos.x, pos.y + mv) and is_start:
				mk_mv.call(pos.x, pos.y + (mv * 2))
			for side in [Vector2i.LEFT, Vector2i.RIGHT]:
				mk_mv.call(pos.x + side.x, pos.y + mv, true)
		Piece.Type.ROOK:
			spread_moves.call(points)
		Piece.Type.NIGHT:
			for point in points:
				var oppos = [Vector2i.UP, Vector2i.DOWN]
				if point.y: oppos = [Vector2i.LEFT, Vector2i.RIGHT]
				for oppo in oppos:
					var pos = corec(p.position).position + (point * 2) + oppo
					var note = algeb(pos.x, pos.y)
					if is_valid_notation(note):
						var obstructor = get_piece(note)
						if obstructor and obstructor.friended(p): continue
						moves.append(posit(notation) + note)
						
		Piece.Type.BISHOP:
			spread_moves.call(diagonal_points)
		Piece.Type.QUEEN:
			spread_moves.call(points)
			spread_moves.call(diagonal_points)
		Piece.Type.KING:
			spread_moves.call(points, true)
			spread_moves.call(diagonal_points, true)
	return moves

## Return an array of files as char, [code]"a"[/code], [code]"b"[/code]...
static func files() -> Array:
	return File.keys().map(func(f: String): return f.to_lower())

## Return an array of ranks as int, [code]1[/code], [code]2[/code]...
static func ranks() -> Array:
	return File.values()

## Return the file char. Might not understand, return [code]"a"[/code].
static func file_char(f: File) -> String:
	for _char in File.keys() as Array[String]:
		if File.get(_char) == f: return _char.to_lower()
	return "?"

## Return [code]true[/code] if [param notation] can be feeded to other functions.
static func is_valid_notation(notation: String) -> bool:
	if notation.length() != 2 and notation.length() != 4: return false
	var chck = func(chck_char: String, itering_file: bool = false) -> bool:
		var iters := Chess.ranks()
		if itering_file: iters = Chess.files()
		for iter in iters:
			if chck_char == "%s" % iter: return true
		return false
	var good_xy = chck.call(notation.substr(0, 1), true) and chck.call(notation.substr(1, 1), false)
	var good_ab = true
	if notation.length() == 4:
		good_ab = chck.call(notation.substr(2, 1), true) and chck.call(notation.substr(3, 1), false)
	return good_xy and good_ab

## Return [param notation] with move-to notation dropped.
## Error prone due to alias of [code]String.substr(0, 2)[/code], check with [method is_valid_notation]
static func posit(notation: String) -> String: return notation.substr(0, 2)
## Return [param notation] with position notation dropped.
## Error prone due to alias of [code]String.substr(2, 2)[/code], check with [method is_valid_notation]
static func movit(notation: String) -> String: return notation.substr(2, 2)

## Turn [code](2, 4, 6, 8)[/code] to [code]"b4f8"[/code]. [b]No value check[/b], will return bad notation.
static func algeb(x: int, y: int, a: int = 0, b: int = 0) -> String:
	var n =  "%s%d" % [file_char(x), y]
	if a:
		if not b: printerr("algeb(...b == 0): b is 0, returning position notation"); return n
		n += "%s%d" % [file_char(a), b]
	return n

## "Convert to rect", Turn [code]"h3e8"[/code] to [code]Rect2i(8, 3, 5, 8)[/code].
## Return [code]Rect2i(0...)[/code] if notation invalid.
static func corec(notation: String) -> Rect2i:
	if not is_valid_notation(notation): return Rect2i()
	var r = Rect2i()
	r.position = Vector2i(
		File.get(notation.substr(0, 1).to_upper(), 1),
		int(notation.substr(1, 1)),
	)
	if notation.length() == 4:
		r.size = Vector2i(
			File.get(notation.substr(2, 1).to_upper(), 1),
			int(notation.substr(3, 1))
		)
	return r
