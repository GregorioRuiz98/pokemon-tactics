extends RefCounted

const Flat = preload("res://core/movement.gd")

static func height_at(state: Dictionary, point: Dictionary) -> int:
	return int(state.heights[int(point.y)][int(point.x)]) if state.has("heights") else 0

static func step_cost(state: Dictionary, actor: Dictionary, origin: Dictionary, destination: Dictionary) -> float:
	var cost: float = Flat.tile_cost(state.board,destination,actor.profile)
	if is_inf(cost): return INF
	var delta: int = height_at(state,destination)-height_at(state,origin)
	if actor.profile=="fly": return cost
	if absi(delta)>1: return INF
	return cost+maxi(0,delta)

# One Dijkstra traversal per unit instead of an A* search for every destination.
# Occupied allied cells remain in the graph, but cannot be destinations.
static func routes(state: Dictionary, actor: Dictionary, maximum: float = INF) -> Dictionary:
	var occupied: Dictionary = {}
	var blocked: Dictionary = {}
	for unit: Dictionary in state.units:
		if unit.hp<=0 or unit.id==actor.id: continue
		occupied[Flat.key(unit)] = true
		if unit.team!=actor.team: blocked[Flat.key(unit)] = true
	var start: Dictionary = {"x":actor.x,"y":actor.y,"cost":0.0,"estimate":0,"parent":null}
	var nodes: Dictionary = {Flat.key(actor):start}
	var heap: Array = [start]
	var closed: Dictionary = {}
	while not heap.is_empty():
		var last: Dictionary = heap.pop_back()
		var current: Dictionary = last
		if not heap.is_empty():
			current = heap[0]
			heap[0] = last
			Flat._up(heap,0)
		var identity: String = Flat.key(current)
		if closed.has(identity): continue
		closed[identity] = true
		for vector: Vector2i in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
			var point: Dictionary = {"x":current.x+vector.x,"y":current.y+vector.y}
			var key: String = Flat.key(point)
			if blocked.has(key): continue
			var cost: float = current.cost+step_cost(state,actor,current,point)
			if is_inf(cost) or cost>maximum: continue
			if nodes.has(key) and nodes[key].cost<=cost: continue
			var node: Dictionary = {"x":point.x,"y":point.y,"cost":cost,"estimate":0,"parent":current}
			nodes[key] = node
			heap.append(node)
			Flat._down(heap,0,heap.size()-1)
	var result: Dictionary = {}
	for key: String in nodes:
		if occupied.has(key): continue
		var node: Dictionary = nodes[key]
		var path: Array = []
		var current: Variant = node
		while current!=null:
			path.push_front({"x":current.x,"y":current.y})
			current = current.parent
		result[key] = {"path":path,"cost":int(node.cost)}
	return result

static func clear_line(state: Dictionary, actor: Dictionary, target: Dictionary) -> bool:
	var dx: int = int(target.x-actor.x)
	var dy: int = int(target.y-actor.y)
	var count: int = maxi(absi(dx),absi(dy))*2
	if count<=1: return true
	var checked: Dictionary = {}
	for i: int in range(1,count):
		var t: float = float(i)/count
		var point: Dictionary = {"x":roundi(actor.x+dx*t),"y":roundi(actor.y+dy*t)}
		if Flat.same(point,actor) or Flat.same(point,target) or checked.has(Flat.key(point)): continue
		checked[Flat.key(point)] = true
		var eye: float = lerpf(height_at(state,actor)+1.0,height_at(state,target)+1.0,t)
		if height_at(state,point)+(2 if state.board[int(point.y)][int(point.x)]==2 else 0)>=eye: return false
		for unit: Dictionary in state.units:
			if unit.hp>0 and Flat.same(point,unit) and height_at(state,point)+1>=eye: return false
	return true
