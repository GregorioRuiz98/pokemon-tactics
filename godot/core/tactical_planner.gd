extends RefCounted

# Presentation-side scheduler for the published spatial AI. Candidate order,
# scores and strict tie comparisons remain identical to choose_command().
const Movement = preload("res://core/movement.gd")
var rules: RefCounted
var snapshot: Dictionary = {}
var actor: Dictionary = {}
var enemies: Array = []
var actions: Array = []
var candidates: Array = []
var routes: Array = []
var decision: Dictionary = {}
var ending: Dictionary = {}
var best: float = 0
var nearest: float = INF
var destination: Dictionary = {}
var action_index: int = 0
var point_index: int = 0
var route_index: int = 0
var phase: String = "idle"
var complete: bool = false
var danger_evaluations: int = 0

func clear() -> void:
	rules = null
	snapshot = {}; actor = {}; enemies = []; actions = []; candidates = []; routes = []
	decision = {}; ending = {}; destination = {}
	best = 0; nearest = INF
	action_index = 0; point_index = 0; route_index = 0; danger_evaluations = 0
	complete = false; phase = "idle"

func start(engine: RefCounted, state: Dictionary) -> void:
	clear()
	rules = engine
	# Borrowed read-only until the UI invalidates this job on every state refresh.
	snapshot = state
	actor = rules.active(state)
	phase = "begin"

func finish(order: Dictionary) -> void:
	decision = order
	complete = true
	phase = "done"

func advance(budget_usec: int = 3000) -> bool:
	if phase=="idle" or complete: return complete
	var deadline: int = Time.get_ticks_usec()+maxi(1,budget_usec)
	while not complete:
		step()
		if Time.get_ticks_usec()>=deadline: break
	return complete

func step() -> void:
	match phase:
		"begin":
			if actor.is_empty(): finish({"kind":"finish"}); return
			ending = {"kind":"finish","facing":rules.choose_facing(snapshot,actor)}
			decision = ending
			if snapshot.acted or actor.spatial.effects.has("flinch"): finish(ending); return
			enemies = rules.living(snapshot).filter(func(u):return u.team!=actor.team)
			actions = rules.profile(actor).actions_for(actor)
			phase = "action"
		"action":
			if action_index>=actions.size():
				if best>0 or snapshot.moved: finish(decision); return
				phase = "routes"
				return
			var definition: Dictionary = actions[action_index].definition
			if actor.tp<definition.cost: action_index += 1; return
			candidates = rules.aim_points(snapshot,definition.id)
			point_index = 0
			phase = "point"
		"point":
			if point_index>=candidates.size(): action_index += 1; phase = "action"; return
			var definition: Dictionary = actions[action_index].definition
			var point: Dictionary = candidates[point_index]
			point_index += 1
			point.axis = 0
			point.throwFacing = rules.FACINGS.find(actor.facing)
			if definition.category!="status" and not enemies.any(func(u):return Movement.distance(u,point)<=2): return
			var plan: Dictionary = rules.cast_plan(snapshot,point,definition.id)
			var score: float = rules.action_score(snapshot,actor,plan)
			if score>best:
				best = score
				decision = {"kind":"attack","aim":point,"target":rules._at(snapshot,point).get("id",0),"actionId":definition.id}
		"routes":
			routes = rules.movement_routes(snapshot,actor,actor.remaining).values()
			phase = "route"
		"route":
			if route_index>=routes.size():
				finish({"kind":"move","destination":destination} if not destination.is_empty() else ending)
				return
			var route: Dictionary = routes[route_index]
			route_index += 1
			if route.cost<=0 or enemies.is_empty(): return
			var point: Dictionary = route.path[-1]
			# The exposure depends on the square, not on which enemy is considered.
			var danger: float = rules.danger_at(snapshot,actor,point)*0.01
			danger_evaluations += 1
			for enemy: Dictionary in enemies:
				var value: float = rules.movement_value(snapshot,actor,point,enemy,danger) if rules.has_method("movement_value") else Movement.distance(point,enemy)+danger
				if value<nearest: nearest = value; destination = point
