extends RefCounted

const Flat = preload("res://core/movement.gd")
const Terrain = preload("res://core/terrain_movement.gd")
const Rules = preload("res://core/battle.gd")

static func inside(state: Dictionary, point: Dictionary) -> bool:
	return point.has("x") and point.has("y") and point.x>=0 and point.y>=0 and point.y<state.board.size() and point.x<state.board[0].size()

static func wall_at(state: Dictionary, point: Dictionary) -> bool:
	return not inside(state,point) or int(state.board[int(point.y)][int(point.x)])==2 or state.get("fields",[]).any(func(f):return f.kind=="wall" and Flat.same(f,point))

static func segment(origin: Dictionary, target: Dictionary) -> Array:
	var points: Array = []
	var dx: int = int(target.x-origin.x)
	var dy: int = int(target.y-origin.y)
	var count: int = maxi(absi(dx),absi(dy))*4
	for i: int in range(count+1):
		var fraction: float = float(i)/maxi(1,count)
		var point: Dictionary = {"x":roundi(origin.x+dx*fraction),"y":roundi(origin.y+dy*fraction)}
		if not points.any(func(p):return Flat.same(p,point)): points.append(point)
	return points

static func visible(state: Dictionary, origin: Dictionary, target: Dictionary, units_block: bool = false) -> bool:
	if not inside(state,origin) or not inside(state,target) or wall_at(state,target): return false
	var points: Array = segment(origin,target)
	for index: int in range(1,points.size()-1):
		var point: Dictionary = points[index]
		if wall_at(state,point): return false
		var distance: float = maxf(1,Flat.distance(origin,target))
		var eye: float = lerpf(Terrain.height_at(state,origin)+1.0,Terrain.height_at(state,target)+1.0,Flat.distance(origin,point)/distance)
		if Terrain.height_at(state,point)>=eye: return false
		if units_block and state.units.any(func(u):return u.hp>0 and u.id!=origin.get("id",-1) and Flat.same(u,point)): return false
	return true

static func crosses(state: Dictionary, origin: Dictionary, target: Dictionary, kinds: Array) -> bool:
	var points: Array = segment(origin,target)
	return state.get("fields",[]).any(func(f):return f.kind in kinds and points.any(func(p):return Flat.same(f,p)))

static func tiles(state: Dictionary, actor: Dictionary, aim: Dictionary, definition: Dictionary) -> Array:
	var shape: String = definition.get("shape","S1")
	var facing: int = actor.facing if Flat.same(actor,aim) else Flat.facing_from(actor,aim)
	var forward: Vector2i = Rules.VECTORS[facing]
	var lateral: Vector2i = Vector2i(-forward.y,forward.x)
	var offsets: Array = []
	var center: Dictionary = actor
	match shape:
		"U": offsets = [Vector2i.ZERO]
		"C0": offsets = [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]
		"R1":
			for x: int in range(-1,2):
				for y: int in range(-1,2):
					if x!=0 or y!=0: offsets.append(Vector2i(x,y))
		"D2":
			for x: int in range(-2,3):
				for y: int in range(-2,3):
					if absi(x)+absi(y)<=2 and (x!=0 or y!=0 or definition.get("includeUser",false)): offsets.append(Vector2i(x,y))
		"L2","L3","L4":
			for x: int in range(1,int(shape.substr(1))+1): offsets.append(Vector2i(x,0))
		"F0": offsets = [Vector2i(1,-1),Vector2i(1,0),Vector2i(1,1)]
		"K2","T4": offsets = [Vector2i(1,0),Vector2i(2,-1),Vector2i(2,0),Vector2i(2,1)]
		"W6": offsets = [Vector2i(1,-1),Vector2i(1,0),Vector2i(1,1),Vector2i(2,-1),Vector2i(2,0),Vector2i(2,1)]
		"X5": offsets = [Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1),Vector2i(2,-1),Vector2i(2,1)]
		"DAI7": offsets = [Vector2i(0,-1),Vector2i(0,1),Vector2i(1,0),Vector2i(2,-1),Vector2i(2,0),Vector2i(2,1),Vector2i(3,0)]
		"C1": center = aim; offsets = [Vector2i.ZERO,Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]
		"F3": center = aim; offsets = [Vector2i(0,-1),Vector2i.ZERO,Vector2i(0,1)]
		"WALL3":
			center = aim
			forward = Vector2i.RIGHT if int(aim.get("axis",0))==0 else Vector2i.DOWN
			lateral = Vector2i(-forward.y,forward.x)
			offsets = [Vector2i(0,-1),Vector2i.ZERO,Vector2i(0,1)]
		_: center = aim; offsets = [Vector2i.ZERO]
	var result: Array = []
	for offset: Vector2i in offsets:
		var vector: Vector2i = forward*offset.x+lateral*offset.y
		var point: Dictionary = {"x":int(center.x)+vector.x,"y":int(center.y)+vector.y}
		if not inside(state,point) or wall_at(state,point): continue
		if not visible(state,actor,point): continue
		# Ground waves cannot climb a vertical cliff merely because their mask covers it.
		if definition.get("type","")=="ground" and absi(Terrain.height_at(state,point)-Terrain.height_at(state,actor))>1: continue
		result.append(point)
	return result
