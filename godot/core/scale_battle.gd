extends "res://core/traits_battle.gd"

const Terrain = preload("res://core/terrain_movement.gd")
const Maps = preload("res://core/scale_maps.gd")

func encounter(run: Dictionary, location: Dictionary) -> Dictionary:
	var state: Dictionary = super.encounter(run,location)
	var map: Dictionary = Maps.layout(location.id,int(run.get("mapSize",16)))
	state.board = map.board
	state.heights = map.heights
	state.mapSize = state.board.size()
	var ally: int = 0
	var enemy: int = 0
	for unit: Dictionary in state.units:
		unit.tp = 2
		if unit.team=="ally":
			unit.merge(map.allies[ally],true)
			ally += 1
		else:
			unit.merge(map.enemies[enemy],true)
			unit.dormant = location.id=="forest" and enemy==2
			enemy += 1
	state.round = 0
	state.rng = Rng.hash_seed(state.seed)
	state.log = []
	new_round(state)
	return state

func new_round(state: Dictionary) -> void:
	state.round += 1
	state.combatEdition = 11
	state.fields = state.fields.filter(func(field):return field.expires>state.round)
	var units: Array = living(state)
	for unit: Dictionary in units:
		if not unit.get("dormant",false): continue
		if state.round>=3 or unit.hp<unit.maxHp or units.any(func(other):return other.team!=unit.team and Movement.distance(other,unit)<=6):
			unit.dormant = false
			note(state,"%s se incorpora a la siguiente cola." % unit.name)
	units = units.filter(func(unit):return not unit.get("dormant",false))
	units.sort_custom(func(a,b):return a.id<b.id)
	state.initiative = []
	for unit: Dictionary in units:
		state.initiative.append({"id":unit.id,"score":unit.speed*(1+(Rng.next(state)*2-1)*state.variance),"tie":Rng.next(state)})
	state.initiative.sort_custom(func(a,b):return a.score>b.score if a.score!=b.score else (a.tie<b.tie if a.tie!=b.tie else a.id<b.id))
	state.queue = state.initiative.map(func(entry):return entry.id)
	state.completed = []
	for unit: Dictionary in units: unit.remaining = budget(unit)
	note(state,"Ronda %d: nueva cola de iniciativa." % state.round)
	begin_activation(state)

func movement_routes(state: Dictionary, actor: Dictionary, maximum: float = INF) -> Dictionary:
	return Terrain.routes(state,actor,maximum)

func move(state: Dictionary, destination: Dictionary) -> Dictionary:
	var actor: Dictionary = active(state)
	if actor.is_empty() or state.moved: return {"ok":false,"reason":"No queda movimiento en esta activación."}
	var route: Variant = movement_routes(state,actor,actor.remaining).get(Movement.key(destination))
	if route==null or route.cost<=0: return {"ok":false,"reason":"Destino ocupado, desnivel infranqueable o fuera del movimiento restante."}
	var next: Dictionary = state.duplicate(true)
	var moved: Dictionary = unit_by_id(next,int(actor.id))
	moved.x = int(destination.x)
	moved.y = int(destination.y)
	moved.remaining -= route.cost
	moved.facing = Movement.facing_from(route.path[-2],destination)
	next.moved = true
	note(next,"%s se mueve a %s · altura %d (%d puntos)." % [actor.name,coordinate(destination),Terrain.height_at(state,destination),route.cost])
	return {"ok":true,"state":next,"route":route}

func _approach(state: Dictionary, actor: Dictionary, target: Dictionary, maximum: int) -> Dictionary:
	if maximum<=0: return {}
	var routes: Dictionary = movement_routes(state,actor,mini(maximum,actor.remaining))
	var options: Array = []
	for vector: Vector2i in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
		var point: Dictionary = {"x":target.x+vector.x,"y":target.y+vector.y}
		var route: Variant = routes.get(Movement.key(point))
		if route!=null and absi(Terrain.height_at(state,point)-Terrain.height_at(state,target))<=1:
			options.append({"destination":point,"path":route.path,"cost":route.cost})
	options.sort_custom(func(a,b):return a.cost<b.cost if a.cost!=b.cost else Movement.key(a.destination)<Movement.key(b.destination))
	return options[0] if not options.is_empty() else {}

func attack_plan(state: Dictionary, target_id: int, origin: Dictionary = {}, action_id: String = "basic") -> Dictionary:
	var current: Dictionary = active(state)
	var target: Dictionary = unit_by_id(state,target_id)
	if current.is_empty(): return {"ok":false,"reason":"El combate ha terminado."}
	if state.acted: return {"ok":false,"reason":"Ya has usado la acción de esta activación."}
	if current.status!=null and current.status.kind in ["sleep","freeze"]: return {"ok":false,"reason":"No puede actuar mientras duerme o está congelado; puede moverse."}
	var action: RefCounted = profile(current).action(current,action_id)
	if action==null: return {"ok":false,"reason":"Este Pokémon no conoce esa habilidad."}
	var definition: Dictionary = action.definition
	if current.tp<definition.cost: return {"ok":false,"reason":"Necesita %d PT; quedan %d." % [definition.cost,current.tp]}
	if action_id=="counter" and current.lastDamage<=0: return {"ok":false,"reason":"Contraataque necesita daño recibido desde la anterior acción."}
	if target.is_empty() or target.hp<=0: return {"ok":false,"reason":"El objetivo ya no está en combate."}
	if definition.target=="enemy" and target.team==current.team: return {"ok":false,"reason":"Esta acción requiere un enemigo."}
	if definition.target=="self" and target.id!=current.id: return {"ok":false,"reason":"Esta acción solo se aplica a sí mismo."}
	var actor: Dictionary = current.duplicate(true)
	actor.merge(origin,true)
	var approach: Dictionary = {}
	var delta_height: int = Terrain.height_at(state,target)-Terrain.height_at(state,actor)
	var distance: int = Movement.distance(actor,target)+maxi(0,delta_height)
	if definition.range==1 and absi(delta_height)>1: return {"ok":false,"reason":"El desnivel supera el alcance cuerpo a cuerpo (máximo 1)."}
	if definition.range==1: distance = Movement.distance(actor,target)
	if distance>int(definition.get("contactRange",definition.range)):
		if distance>definition.range: return {"ok":false,"reason":"Fuera de alcance: %d casillas." % definition.range}
		approach = _approach(state,actor,target,int(definition.get("approach",0)))
		if approach.is_empty(): return {"ok":false,"reason":"No hay un acercamiento libre dentro del movimiento restante."}
		actor.merge(approach.destination,true)
	if not Terrain.clear_line(state,actor,target): return {"ok":false,"reason":"El terreno u otra unidad bloquea el disparo."}
	var effect: Dictionary = action.preview(actor,target)
	if definition.category=="status":
		if actor.get("heldItem")=="assault-vest": return {"ok":false,"reason":"Chaleco Asalto impide acciones de estado y apoyo."}
		if effect.statusReason!=null: return {"ok":false,"reason":effect.statusReason}
	if effect.guard and target.guarded: return {"ok":false,"reason":"El objetivo ya está protegido."}
	var tiles: Array = [{"x":target.x,"y":target.y}]
	if definition.kind in ["area-damage","area-status"]:
		for vector: Vector2i in [Vector2i.RIGHT,Vector2i.LEFT,Vector2i.DOWN,Vector2i.UP]: tiles.append({"x":target.x+vector.x,"y":target.y+vector.y})
	tiles = tiles.filter(func(point):return not blocks_sight(state.board,point))
	var units: Array = living(state)
	units.sort_custom(func(a,b):return a.id<b.id)
	var hits: Array = []
	for unit: Dictionary in units:
		if tiles.size()>1 and unit.id==actor.id: continue
		if not tiles.any(func(point):return Movement.same(point,unit)): continue
		var side: String = attack_side(actor,unit) if definition.target=="enemy" else "front"
		var hit: Dictionary = _forecast(actor,unit,action,side)
		hit.targetId = unit.id
		if definition.get("pushDistance",0)>0 and hit.multiplier!=0:
			var vector: Vector2i = VECTORS[Movement.facing_from(actor,unit)]
			var destination: Dictionary = {"x":unit.x+vector.x,"y":unit.y+vector.y}
			if is_inf(Terrain.step_cost(state,unit,unit,destination)): hit.pushReason = "Terreno o borde bloquea el empuje."
			elif units.any(func(u):return Movement.same(actor if u.id==actor.id else u,destination)): hit.pushReason = "Una unidad bloquea el empuje."
			else: hit.push = destination
		hits.append(hit)
	var primary: Dictionary = hits.filter(func(hit):return hit.targetId==target_id)[0]
	var plan: Dictionary = primary.duplicate(true)
	plan.merge({"ok":true,"actionId":action_id,"name":definition.name,"cost":definition.cost,"hits":hits,"tiles":tiles,"embers":[],"approach":approach},true)
	var damage: int = 0
	for hit: Dictionary in hits: damage += maxi(hit.damageMax,mini(unit_by_id(state,int(hit.targetId)).hp,hit.criticalMax))
	plan.recoil = int(floor(damage*definition.get("recoil",0)/100.0))
	if current.get("heldItem")=="life-orb" and damage>0: plan.recoil += maxi(1,int(current.maxHp/10.0))
	if definition.get("selfKO",false): plan.recoil = current.hp
	plan.heightDifference = Terrain.height_at(state,target)-Terrain.height_at(state,actor)
	if actor.get("ability")=="rock-head" and not definition.get("selfKO",false): plan.recoil = maxi(0,int(plan.recoil)-int(floor(damage*definition.get("recoil",0)/100.0)))
	return plan

func choose_command(state: Dictionary) -> Dictionary:
	var actor: Dictionary = active(state)
	if actor.is_empty(): return {"kind":"finish"}
	var finish_order: Dictionary = {"kind":"finish","facing":choose_facing(state,actor)}
	if state.acted: return finish_order
	var targets: Array = living(state).filter(func(unit):return unit.team!=actor.team)
	targets.sort_custom(func(a,b):return a.id<b.id)
	var actions: Array = profile(actor).actions_for(actor)
	var best: float = 0
	var order: Dictionary = finish_order
	for target: Dictionary in living(state):
		for action: RefCounted in actions:
			var plan: Dictionary = attack_plan(state,int(target.id),{},action.definition.id)
			var value: float = action_score(state,target,plan)
			if value>best:
				best = value
				order = {"kind":"attack","target":target.id,"actionId":action.definition.id}
	if best>0: return order
	if state.moved: return finish_order
	var routes: Dictionary = movement_routes(state,actor)
	var nearest: Dictionary = {}
	var distance: int = 2147483647
	for route: Dictionary in routes.values():
		var point: Dictionary = route.path[-1]
		if route.cost>actor.remaining or route.cost<=0: continue
		for target: Dictionary in targets:
			for action: RefCounted in actions:
				if action.definition.target!="enemy": continue
				var origin: Dictionary = {"x":point.x,"y":point.y,"remaining":actor.remaining-route.cost}
				var value: float = action_score(state,target,attack_plan(state,int(target.id),origin,action.definition.id))/(1+route.cost*0.1)
				if value>best:
					best = value
					order = {"kind":"move","destination":point}
	if best>0: return order
	# Follow an actual path to a free neighbour of an opponent. No retreat loops.
	for target: Dictionary in targets:
		for vector: Vector2i in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
			var point: Dictionary = {"x":target.x+vector.x,"y":target.y+vector.y}
			var route: Variant = routes.get(Movement.key(point))
			if route==null or route.cost>=distance or route.cost<=0: continue
			var destination: Dictionary = {}
			for step: Dictionary in route.path.slice(1):
				var partial: Variant = routes.get(Movement.key(step))
				if partial!=null and partial.cost<=actor.remaining: destination = step
			if destination.is_empty(): continue
			distance = route.cost
			nearest = destination
	return {"kind":"move","destination":nearest} if not nearest.is_empty() else finish_order
