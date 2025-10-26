class_name Piece extends Resource
## A [Piece] of [Chess].

## Possible value of [member Piece.type].
enum Type {
	PAWN,   ## The pawn piece, move forward slowly, capture diagonal slowly.
	ROOK,   ## The rook piece, move and capture horizontaly or verticaly.
	NIGHT,  ## The knight piece, named night due to initial conflict with king. move and capture horizontal or vertical 3x and opposite 1x.
	BISHOP, ## The bishop piece, move and capture diagonaly.
	QUEEN,  ## The queen piece, move and capture horizontaly, verticaly or diagonaly.
	KING,   ## The king piece, move slowly and captured.
	FIELD,  ## The void piece, used for empty spaces.
}
## Possible value of [member Piece.team].
enum Team {
	WHITE, ## White team.
	BLACK, ## Black team.
	NATURAL, ## Natural team, Used for [constant Piece.Type.FIELD].
}
## The [enum Team] of piece
@export var team: Team = Team.NATURAL
## The [enum Type] of piece
@export var type: Type = Type.FIELD
## The position in [b]chess notation[/b], Handled by [Chess] board.
@export var position: String = "a1":
	set(v):
		if Chess.is_valid_notation(v): position = Chess.posit(v)
		else: printerr("Position '%s' is invalid" % v)
## The [Chess] board owning this [Piece].
var board: Chess
## Create a new [Piece] with [param owner] = [member board], [param t] = [member type],
## [param group] = [member team] and at "[param pos]" ([member position]).
func _init(owner: Chess, t: Type = Type.FIELD, group: Team = Team.NATURAL, pos: String = "a1"):
	board = owner; type = t; team = group; position = pos
func _to_string() -> String: return get_codename()
## Return double char of the [member team] ([code]"@"[/code] White, [code]"#"[/code] Black) and the [member type]
## [param for_pretty_print] will return the [member type] as bbcode colors.
func get_codename(for_pretty_print: bool = false) -> String:
	var n = type_str(type).substr(0, 1)
	match n:
		"F": n = " "
	var p = " " ## prefix
	var s = "" ## suffix
	match team:
		Team.WHITE: p = "@"
		Team.BLACK: p = "#"
		_: p = " "
	
	if for_pretty_print:
		s = "[/color]"
		match team:
			Team.WHITE: p = "[color=white]"
			Team.BLACK: p = "[color=black]"
			Team.NATURAL: p = ""; s = ""
	
	return p + n + s 
## Get file position. Return [constant Chess.File.A] if position somehow wrong.
func file() -> Chess.File:
	for _file in Chess.File.keys() as Array[String]:
		if _file.to_lower() == position.substr(0, 1): return Chess.File.get(_file)
	return Chess.File.A
## Get rank position.
func rank() -> int: return int(position.substr(1, 1))
## Get position as [Vector2i] where [member Vector2i.x] is file and [member Vector2i.y] is rank
func vec() -> Vector2i: return Vector2i(file(), rank())
## Return [code]true[/code] if [param p] is an opposing team. [constant Chess.Piece.Team.NATURAL] return [code]false[/code].
func opposed(p: Piece) -> bool:
	return (
		((team == Team.WHITE) and (p.team == Team.BLACK)) or
		((team == Team.BLACK) and (p.team == Team.WHITE))
	)
## Return [code]true[/code] if [param p] is the same team. [constant Chess.Piece.Team.NATURAL] return [code]false[/code].
func friended(p: Piece) -> bool:
	return (
		((team == Team.WHITE) and (p.team == Team.WHITE)) or
		((team == Team.BLACK) and (p.team == Team.BLACK))
	)
## Return [code]true[/code] if [member type] is [constant Chess.Piece.Type.FIELD].
func is_field() -> bool: return type == Type.FIELD
## Return the type as string.
static func type_str(t: Type) -> String:
	for nom in Type.keys(): if Type.get(nom) == t: return nom
	return "UNKNOWN"
