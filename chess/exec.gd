@tool
extends EditorScript

func _run() -> void:
	#var chess = Chess.new()
	#chess.move("b2b4")
	#print(chess.get_piece("b2").opposed(chess.get_piece("c3")))
	#chess._swap("b1b7", true)
	#chess.print_board(true, "b4")
	#print(chess.get_moves_of("b4"))
	#print(chess.captures)
	#if "":
		#print("ok")
	#else:
		#print("not_ok")
	
	var i = 10
	var ptr = weakref(i)
	ptr += 10
	print(i)
	print(ptr)
