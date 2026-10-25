extends RefCounted

const Movement = preload("res://core/movement.gd")
const ALLIES: Array[Vector2i] = [Vector2i(5,8),Vector2i(4,8),Vector2i(5,9),Vector2i(3,8),Vector2i(4,9),Vector2i(3,9)]
const ENEMIES: Array[Vector2i] = [Vector2i(8,6),Vector2i(9,5),Vector2i(10,4),Vector2i(10,6),Vector2i(11,5),Vector2i(11,3)]

static func point(x: int, y: int, offset: int) -> Dictionary:
	return {"x":x+offset,"y":y+offset}

static func decorate(state: Dictionary, location: Dictionary, setup: Dictionary) -> void:
	var offset: int = int((int(state.mapSize)-16)/2.0)
	state.arena = {"title":setup.get("title","Encuentro de ruta"),"description":setup.get("description","Aprovecha los flancos y la cobertura."),"deployment":[],"portals":[]}
	if location.get("leader",false):
		for y: int in range(2,14):
			for x: int in range(2,14): state.board[y+offset][x+offset] = 0; state.heights[y+offset][x+offset] = 0
	for key: String in ["walls","water","rough","high"]:
		for cell: Array in setup.get(key,[]):
			var x: int = int(cell[0])+offset; var y: int = int(cell[1])+offset
			if key=="high": state.heights[y][x] = 1
			else: state.board[y][x] = {"walls":2,"water":3,"rough":1}[key]
	for y: int in range(8,11):
		for x: int in range(2,6):
			state.arena.deployment.append(point(x,y,offset))
	var ally_index: int = 0; var enemy_index: int = 0
	for unit: Dictionary in state.units:
		var vector: Vector2i = ALLIES[ally_index] if unit.team=="ally" else ENEMIES[enemy_index]
		if unit.team=="ally": ally_index += 1
		else: enemy_index += 1
		unit.x = vector.x+offset; unit.y = vector.y+offset
		unit.dormant = false
		unit.aiRole = "wild" if location.get("team",[]).is_empty() and not location.has("rivalTeams") else ("leader" if location.get("leader",false) else "trainer")
	for cell: Dictionary in state.arena.deployment+state.units:
		state.board[int(cell.y)][int(cell.x)] = 0; state.heights[int(cell.y)][int(cell.x)] = 0
	state.fields = []
	for entry: Array in setup.get("fields",[]):
		state.fields.append({"kind":entry[0],"x":int(entry[1])+offset,"y":int(entry[2])+offset,"expires":999,"source":0,"chance":100,"zone":0})
	for pair: Array in setup.get("portals",[]):
		var first: Dictionary = point(int(pair[0]),int(pair[1]),offset)
		var second: Dictionary = point(int(pair[2]),int(pair[3]),offset)
		state.arena.portals.append([first,second])
		for cell: Dictionary in [first,second]: state.board[int(cell.y)][int(cell.x)] = 0; state.heights[int(cell.y)][int(cell.x)] = 0
	var mission: String = setup.get("mission","defeat")
	state.mission = {"kind":mission,"captured":[],"health":4,"untilRound":4,"points":[]}
	for cell: Array in setup.get("points",[]): state.mission.points.append(point(int(cell[0]),int(cell[1]),offset))
	state.deployment = true
