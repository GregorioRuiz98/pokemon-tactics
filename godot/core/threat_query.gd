extends RefCounted

# Geometric coverage only: never forecasts damage, rolls or an enemy intention.
const Movement = preload("res://core/movement.gd")
const Geometry = preload("res://core/spatial_geometry.gd")
var cells: Dictionary = {}
var queue: Array = []
var engine: RefCounted
var snapshot: Dictionary = {}
var enemy_index: int = 0
var origins: Array = []
var origin_index: int = 0
var actions: Array = []
var action_index: int = 0
var points: Array = []
var point_index: int = 0
var query: Dictionary = {}
var complete: bool = false
var phase: String = "enemy"
var use_cache: bool = true
var masks: Dictionary = {}

func start(rules: RefCounted, state: Dictionary, identity: int = 0, cached: bool = true) -> void:
	engine = rules; snapshot = state
	use_cache = cached; masks = {}
	queue = rules.living(state).filter(func(u):return u.team=="enemy" and (identity==0 or u.id==identity))
	cells = {}; origins = []; actions = []; points = []; query = {}
	enemy_index = 0; origin_index = 0; action_index = 0; point_index = 0
	complete = false; phase = "enemy"

func advance(budget_usec: int = 1500) -> bool:
	var deadline: int = Time.get_ticks_usec()+maxi(1,budget_usec)
	while not complete:
		step()
		if Time.get_ticks_usec()>=deadline: break
	return complete

func step() -> void:
	if phase=="enemy":
		if enemy_index>=queue.size(): complete = true; return
		var enemy: Dictionary = queue[enemy_index]
		masks = {}
		origins = [{"x":enemy.x,"y":enemy.y}]
		if enemy.status==null or enemy.status.kind not in ["sleep","freeze"]:
			for route: Dictionary in engine.movement_routes(snapshot,enemy,engine.budget(enemy)).values():
				if route.cost<=0: continue
				var endpoint: Dictionary = route.path[-1]
				for pair: Array in snapshot.get("arena",{}).get("portals",[]):
					if Movement.same(endpoint,pair[0]) and not engine._occupied(snapshot,pair[1]): endpoint = pair[1]; break
					if Movement.same(endpoint,pair[1]) and not engine._occupied(snapshot,pair[0]): endpoint = pair[0]; break
				origins.append(endpoint)
		else: enemy_index += 1; return
		var tp: int = enemy.tp if engine.active(snapshot).get("id")==enemy.id else mini(enemy.maxTp,enemy.tp+1)
		actions = engine.profile(enemy).actions_for(enemy).filter(func(a):return (a.definition.category!="status" or a.definition.target=="enemy") and a.definition.cost<=tp)
		origin_index = 0; phase = "origin"
	elif phase=="origin":
		if origin_index>=origins.size(): enemy_index += 1; phase = "enemy"; return
		var enemy: Dictionary = queue[enemy_index]
		query = snapshot.duplicate()
		query.units = snapshot.units.duplicate()
		var index: int = query.units.find(enemy)
		var placed: Dictionary = enemy.duplicate()
		placed.merge(origins[origin_index],true)
		query.units[index] = placed; query.queue = [enemy.id]
		action_index = 0; phase = "action"
	elif phase=="action":
		if action_index>=actions.size(): origin_index += 1; phase = "origin"; return
		points = engine.aim_points(query,actions[action_index].definition.id)
		point_index = 0; phase = "point"
	else:
		if point_index>=points.size(): action_index += 1; phase = "action"; return
		var aim: Dictionary = points[point_index]; point_index += 1
		var actor: Dictionary = engine.active(query)
		var definition: Dictionary = actions[action_index].definition
		var shape: String = definition.get("shape","S1")
		if use_cache and shape in ["S1","S2","S3"] and actor.id in cells.get(Movement.key(aim),[]): return
		var mask_key: String = ""
		if use_cache and shape in ["U","C0","R1","D2","L2","L3","L4","F0","K2","T4","W6","X5","DAI7"]:
			var facing: int = actor.facing if Movement.same(actor,aim) else Movement.facing_from(actor,aim)
			mask_key = "%s/%s/%d/%s/%s" % [Movement.key(actor),shape,facing,definition.get("type","")=="ground",definition.get("includeUser",false)]
			if masks.has(mask_key): return
		if not Geometry.visible(query,actor,aim): return
		if not mask_key.is_empty(): masks[mask_key] = true
		for cell: Dictionary in Geometry.tiles(query,actor,aim,definition):
			var key: String = Movement.key(cell)
			if not cells.has(key): cells[key] = []
			if actor.id not in cells[key]: cells[key].append(actor.id)
