extends RefCounted

const Flat = preload("res://core/movement.gd")
const Terrain = preload("res://core/terrain_movement.gd")
const Geometry = preload("res://core/spatial_geometry.gd")

static func step_cost(state: Dictionary, actor: Dictionary, origin: Dictionary, destination: Dictionary) -> float:
	if Geometry.wall_at(state,destination): return INF
	var cost: float = Terrain.step_cost(state,actor,origin,destination)
	if is_inf(cost): return cost
	if actor.profile!="fly" and actor.get("ability")!="levitate":
		if state.get("fields",[]).any(func(f):return f.kind in ["mud","web","fire"] and Flat.same(f,destination)): cost += 1
	var bound: Dictionary = actor.get("spatial",{}).get("effects",{}).get("bound",{})
	if not bound.is_empty():
		for unit: Dictionary in state.units:
			if unit.id==bound.source and unit.hp>0 and Flat.distance(unit,destination)>Flat.distance(unit,origin): cost += 1
	return cost

static func routes(state: Dictionary, actor: Dictionary, maximum: float = INF) -> Dictionary:
	var occupied: Dictionary = {}
	var blocked: Dictionary = {}
	for unit: Dictionary in state.units:
		if unit.hp<=0 or unit.id==actor.id: continue
		occupied[Flat.key(unit)] = true
		if unit.team!=actor.team: blocked[Flat.key(unit)] = true
	var start: Dictionary = {"x":actor.x,"y":actor.y,"cost":0.0,"parent":null}
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
		var cursor: Variant = node
		while cursor!=null:
			path.push_front({"x":cursor.x,"y":cursor.y})
			cursor = cursor.parent
		result[key] = {"path":path,"cost":int(node.cost)}
	return result
