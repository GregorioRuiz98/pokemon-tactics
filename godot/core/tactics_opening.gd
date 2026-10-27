extends RefCounted

const Move = preload("res://core/movement.gd")
static var designs: Dictionary = {}

static func design(identity: String) -> Dictionary:
	if designs.is_empty(): designs = JSON.parse_string(FileAccess.get_file_as_string("res://data/tactics-opening.json"))
	return designs.get(identity,{})

static func apply(state: Dictionary, identity: String) -> void:
	var layout: Dictionary = design(identity)
	if layout.is_empty(): return
	var offset: int = int((int(state.mapSize)-16)/2.0)
	var authored: bool = layout.get("mode","")=="authored"
	if authored:
		for y: int in range(2,13):
			for x: int in range(2,14):
				state.board[y+offset][x+offset] = 0
				state.heights[y+offset][x+offset] = 0
				state.landscape.props.erase("%d,%d"%[x+offset,y+offset])
	var protected: Array = state.arena.deployment+state.units+state.get("mission",{}).get("points",[])
	for pair: Array in state.arena.portals: protected.append_array(pair)
	var origin: Dictionary = state.units.filter(func(u):return u.team=="ally")[0]
	var baseline: Dictionary = reachable(state,origin)
	for kind: String in ["walls","rough","high"]:
		for cell: Array in layout[kind]:
			var x: int = int(cell[0])+offset; var y: int = int(cell[1])+offset
			var point: Dictionary = {"x":x,"y":y}
			if protected.any(func(p):return Move.same(p,point)) or (not authored and state.board[y][x] not in [0,1]): continue
			var previous: int = int(state.board[y][x]); var height: int = int(state.heights[y][x])
			if kind=="high": state.heights[y][x] = int(cell[2]) if cell.size()>2 else 1
			else: state.board[y][x] = 2 if kind=="walls" else 1
			if not authored:
				var after: Dictionary = reachable(state,origin)
				if protected.any(func(p):return baseline.has(Move.key(p)) and not after.has(Move.key(p))):
					state.board[y][x] = previous; state.heights[y][x] = height; continue
			if kind=="walls": state.landscape.props[Move.key(point)] = layout.get("prop","rock" if identity=="brock" else "oak")
	var enemies: Array = state.units.filter(func(u):return u.team=="enemy")
	if authored:
		for index: int in enemies.size():
			var spawn: Array = layout.spawns[index]
			enemies[index].x = int(spawn[0])+offset; enemies[index].y = int(spawn[1])+offset
	for cell: Dictionary in state.arena.deployment+state.units:
		state.board[int(cell.y)][int(cell.x)] = 0
		state.landscape.props.erase(Move.key(cell))
	state.arena.title = layout.title
	state.landscape.title = layout.title
	state.arena.description = layout.plan
	state.briefing = {"speaker":layout.speaker,"line":layout.line,"plan":layout.plan}
	state.tacticalDesign = identity
	state.teamStrategy = layout.get("style","wild")
	if layout.has("objective"):
		var candidates: Dictionary = reachable(state,origin)
		var points: Array = []
		for cell: Array in layout.objective.points:
			var desired: Dictionary = {"x":int(cell[0])+offset,"y":int(cell[1])+offset}
			var choices: Array = candidates.values().filter(func(p):return not points.any(func(q):return Move.same(p,q)) and not state.arena.deployment.any(func(q):return Move.same(p,q)))
			choices.sort_custom(func(a,b):return Move.distance(a,desired)<Move.distance(b,desired) if Move.distance(a,desired)!=Move.distance(b,desired) else Move.key(a)<Move.key(b))
			if not choices.is_empty(): points.append(choices[0])
		if points.size()==layout.objective.points.size(): state.mission = {"kind":"secure","captured":[],"health":4,"untilRound":4,"points":points}

static func reachable(state: Dictionary, origin: Dictionary) -> Dictionary:
	var visited: Dictionary = {Move.key(origin):{"x":int(origin.x),"y":int(origin.y)}}
	var pending: Array = [visited[Move.key(origin)]]
	var index: int = 0
	while index<pending.size():
		var cell: Dictionary = pending[index]; index += 1
		for vector: Vector2i in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
			var point: Dictionary = {"x":cell.x+vector.x,"y":cell.y+vector.y}
			var key: String = Move.key(point)
			if visited.has(key) or is_inf(Move.tile_cost(state.board,point)): continue
			if absi(int(state.heights[int(cell.y)][int(cell.x)])-int(state.heights[int(point.y)][int(point.x)]))>1: continue
			visited[key] = point; pending.append(point)
	return visited
