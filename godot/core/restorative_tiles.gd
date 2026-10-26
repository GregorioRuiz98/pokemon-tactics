extends RefCounted

const Movement = preload("res://core/movement.gd")

static func place(state: Dictionary, engine: RefCounted) -> void:
	state.restorativeTiles = []
	var anchors: Array = []
	var reachable: Array = []
	for team: String in ["ally","enemy"]:
		var units: Array = state.units.filter(func(u):return u.team==team and u.hp>0)
		if units.is_empty(): return
		var walker: Dictionary = units[0].duplicate(true)
		walker.profile = "ground"
		anchors.append(walker)
		reachable.append(engine.movement_routes(state,walker))
	var candidates: Array = []
	for y: int in state.board.size():
		for x: int in state.board[y].size():
			var point: Dictionary = {"x":x,"y":y}
			var key: String = Movement.key(point)
			if state.board[y][x]!=0 or not reachable[0].has(key) or not reachable[1].has(key): continue
			if state.units.any(func(u):return Movement.same(u,point)): continue
			if state.arena.deployment.any(func(p):return Movement.same(p,point)): continue
			if state.get("mission",{}).get("points",[]).any(func(p):return Movement.same(p,point)): continue
			if state.arena.portals.any(func(pair):return pair.any(func(p):return Movement.same(p,point))): continue
			if state.fields.any(func(f):return Movement.same(f,point)): continue
			candidates.append(point)
	for anchor: Dictionary in anchors:
		candidates.sort_custom(func(a,b):
			var first: int = Movement.distance(a,anchor)
			var second: int = Movement.distance(b,anchor)
			return first<second if first!=second else (a.y<b.y if a.y!=b.y else a.x<b.x))
		if candidates.is_empty(): return
		var selected: Dictionary = candidates[0]
		state.restorativeTiles.append(selected)
		candidates = candidates.filter(func(p):return Movement.distance(p,selected)>=3)

static func contains(state: Dictionary, unit: Dictionary) -> bool:
	return state.get("restorativeTiles",[]).any(func(p):return Movement.same(p,unit))

static func cure(state: Dictionary, unit: Dictionary) -> bool:
	if unit.hp<=0 or not contains(state,unit): return false
	var changed: bool = unit.status!=null or unit.volatile.has("confusion")
	unit.status = null
	unit.volatile.erase("confusion")
	return changed
