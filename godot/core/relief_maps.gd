extends RefCounted

const Move = preload("res://core/movement.gd")
static var catalogue: Dictionary = {}

static func design(identity: String) -> Dictionary:
	if catalogue.is_empty(): catalogue = JSON.parse_string(FileAccess.get_file_as_string("res://data/relief-maps.json"))
	return catalogue.get(identity,{})

static func point(cell: Array, offset: int) -> Dictionary:
	return {"x":int(cell[0])+offset,"y":int(cell[1])+offset}

static func flood(state: Dictionary, origin: Dictionary) -> Dictionary:
	var seen: Dictionary = {Move.key(origin):origin}
	var pending: Array = [origin]; var index: int = 0
	while index<pending.size():
		var cell: Dictionary = pending[index]; index += 1
		for vector: Vector2i in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
			var x: int = int(cell.x)+vector.x; var y: int = int(cell.y)+vector.y
			if x<0 or y<0 or y>=state.board.size() or x>=state.board[y].size(): continue
			var next: Dictionary = {"x":x,"y":y}; var key: String = Move.key(next)
			if seen.has(key) or state.board[y][x] in [2,3] or absi(int(state.heights[y][x])-int(state.heights[int(cell.y)][int(cell.x)]))>1: continue
			seen[key] = next; pending.append(next)
	return seen

static func connect_anchor(state: Dictionary, origin: Dictionary, target: Dictionary) -> void:
	# Repair only protected mission/portal endpoints. No RNG and no unit relocation.
	var reached: Dictionary = flood(state,origin)
	if reached.has(Move.key(target)): return
	var candidates: Array = reached.values()
	candidates.sort_custom(func(a,b):return Move.distance(a,target)<Move.distance(b,target) if Move.distance(a,target)!=Move.distance(b,target) else Move.key(a)<Move.key(b))
	var current: Dictionary = candidates[0].duplicate()
	while not Move.same(current,target):
		var previous: int = int(state.heights[int(current.y)][int(current.x)])
		if current.x!=target.x: current.x += 1 if target.x>current.x else -1
		else: current.y += 1 if target.y>current.y else -1
		state.board[int(current.y)][int(current.x)] = 0
		state.heights[int(current.y)][int(current.x)] = clampi(int(state.heights[int(current.y)][int(current.x)]),previous-1,previous+1)
		state.landscape.props.erase(Move.key(current))
		if Move.key(current) not in state.landscape.paths: state.landscape.paths.append(Move.key(current))
	state.relief.repairs += 1

static func apply(state: Dictionary, identity: String) -> void:
	var data: Dictionary = design(identity)
	if data.is_empty(): return
	var offset: int = int((int(state.mapSize)-16)/2.0)
	state.landscape.props = {}; state.landscape.paths = []
	state.landscape.material = data.material
	for y: int in state.board.size():
		for x: int in state.board[y].size():
			var local_x: int = clampi(x-offset,0,15); var local_y: int = clampi(y-offset,0,15)
			state.board[y][x] = int(data.board[local_y][local_x]) if x>=offset and y>=offset and x<offset+16 and y<offset+16 else 0
			state.heights[y][x] = int(data.heights[local_y][local_x])
	for key: String in data.props:
		var parts: PackedStringArray = key.split(",")
		state.landscape.props["%d,%d"%[int(parts[0])+offset,int(parts[1])+offset]] = data.props[key]
	for key: String in data.paths:
		var parts: PackedStringArray = key.split(",")
		state.landscape.paths.append("%d,%d"%[int(parts[0])+offset,int(parts[1])+offset])
	state.arena.deployment = data.deployment.map(func(cell):return point(cell,offset))
	var indexes: Dictionary = {"ally":0,"enemy":0}
	for unit: Dictionary in state.units:
		var cells: Array = data.allies if unit.team=="ally" else data.enemies
		var destination: Dictionary = point(cells[indexes[unit.team]],offset)
		unit.x = destination.x; unit.y = destination.y; indexes[unit.team] += 1
	state.relief = {"version":1,"id":identity,"landmark":data.landmark,"form":data.form,"motif":data.motif,"palette":data.palette,"landmarkCell":point(data.landmarkCell,offset),"repairs":0}
	var anchors: Array = state.arena.deployment+state.units+state.get("mission",{}).get("points",[])
	for pair: Array in state.arena.portals: anchors.append_array(pair)
	for anchor: Dictionary in anchors:
		state.board[int(anchor.y)][int(anchor.x)] = 0
		state.landscape.props.erase(Move.key(anchor))
	var origin: Dictionary = state.units.filter(func(unit):return unit.team=="ally")[0]
	for anchor: Dictionary in anchors: connect_anchor(state,origin,anchor)
	state.arena.title = data.landmark
	state.arena.description = data.plan
	state.briefing = {"speaker":data.speaker,"line":data.context,"plan":data.plan}
	state.tacticalDesign = "relief/"+identity
