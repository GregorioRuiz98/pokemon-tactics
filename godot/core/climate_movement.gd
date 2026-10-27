extends RefCounted

const Flat = preload("res://core/movement.gd")
const Terrain = preload("res://core/terrain_movement.gd")
const Context = preload("res://core/climate_context.gd")
const Geometry = preload("res://core/spatial_geometry.gd")

static func step_cost(state: Dictionary, actor: Dictionary, origin: Dictionary, destination: Dictionary) -> float:
	var first_step: bool = Flat.same(origin,actor)
	actor = actor.duplicate(); actor.x = origin.x; actor.y = origin.y
	actor.ability = Context.ability(state,actor)
	var cost: float = preload("res://core/spatial_movement.gd").step_cost(state,actor,origin,destination)
	if is_inf(cost) or actor.get("ability")=="run-away": return cost
	var trap: bool = false; var magnet: bool = false
	for source: Dictionary in state.get("climateControls",[]):
		if source.team==actor.team: continue
		if source.ability=="arena-trap" and actor.profile!="fly" and actor.get("ability")!="levitate" and Context.near(state,source,origin,1) and Flat.distance(source,destination)>1: trap = true
		if source.ability=="magnet-pull" and "steel" in actor.types and Context.near(state,source,destination,2): magnet = true
	var extra: int = int(trap)+int(magnet)
	if extra>0 and first_step and cost<=actor.get("remaining",0): return minf(cost+extra,actor.remaining)
	return cost+extra

static func routes(state: Dictionary, actor: Dictionary, maximum: float = INF) -> Dictionary:
	state = state.duplicate()
	state.climateControls = []
	for unit: Dictionary in state.units:
		var identity: String = Context.ability(state,unit)
		if unit.hp>0 and identity in ["arena-trap","magnet-pull"]:
			var source: Dictionary = unit.duplicate(); source.ability = identity; state.climateControls.append(source)
	actor = actor.duplicate(); actor.ability = Context.ability(state,actor)
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
			if blocked.has(key):
				var crossing: Dictionary = actor.duplicate(); crossing.x = point.x; crossing.y = point.y
				if Context.ability(state,crossing)!="run-away": continue
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
