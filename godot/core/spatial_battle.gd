extends "res://core/finale_battle.gd"

const SpatialStudy = preload("res://core/spatial_study.gd")
const SpatialActions = preload("res://core/spatial_actions.gd")
const Geometry = preload("res://core/spatial_geometry.gd")
const Paths = preload("res://core/spatial_movement.gd")

func _init() -> void:
	super()
	progression = SpatialStudy.new()
	catalog = progression.data
	var chart: Dictionary = profiles[1].library.basic.chart
	profiles.clear()
	for record: Dictionary in catalog.species:
		var pokemon: RefCounted = Profile.new(record,chart,progression)
		var basic: Dictionary = progression.BASIC.duplicate(true)
		basic.merge(progression.spatial_data.moves.basic,true)
		pokemon.library.basic = SpatialActions.create(basic,chart)
		for identity: String in catalog.moves: pokemon.library[identity] = SpatialActions.create(catalog.moves[identity],chart)
		profiles[int(record.id)] = pokemon
	data.species = catalog.species

func member_unit(member: Dictionary, point: Dictionary = {"x":0,"y":0}) -> Dictionary:
	var unit: Dictionary = super.member_unit(member,point)
	unit.spatial = {"effects":{},"zoneMarks":{},"lastMove":"","lastAttacker":0,"lastPhysical":0,"lastSpecial":0,"attacks":0}
	unit.combatEdition = 18
	return unit

func new_round(state: Dictionary) -> void:
	super.new_round(state)
	state.combatEdition = 18

func begin_activation(state: Dictionary) -> void:
	state.spatialClock = int(state.get("spatialClock",0))+1
	state.movementLocked = false
	super.begin_activation(state)
	var actor: Dictionary = active(state)
	if actor.is_empty(): return
	actor.spatial.zoneMarks = {}
	_zone_entry(state,actor,actor)
	if actor.hp<=0: _advance_after_casualties(state)

func movement_routes(state: Dictionary, actor: Dictionary, maximum: float = INF) -> Dictionary:
	return Paths.routes(state,actor,maximum)

func move(state: Dictionary, destination: Dictionary) -> Dictionary:
	var actor: Dictionary = active(state)
	if actor.is_empty() or state.moved: return {"ok":false,"reason":"No queda movimiento en esta activación."}
	var route: Variant = movement_routes(state,actor,actor.remaining).get(Movement.key(destination))
	if route==null or route.cost<=0: return {"ok":false,"reason":"Destino ocupado, bloqueado o fuera de tu movimiento."}
	var next: Dictionary = state.duplicate(true)
	next.zoneEvents = []
	var moved: Dictionary = unit_by_id(next,int(actor.id))
	for point: Dictionary in route.path.slice(1):
		moved.merge(point,true)
		if _zone_entry(next,moved,point): next.movementLocked = true
		if moved.hp<=0: break
	moved.remaining -= route.cost
	if moved.hp>0: moved.facing = Movement.facing_from(route.path[-2],destination)
	next.moved = true
	note(next,"%s se mueve a %s (%d puntos)." % [actor.name,coordinate(moved),route.cost])
	_advance_after_casualties(next)
	return {"ok":true,"state":next,"route":route,"irreversible":next.movementLocked}

func _definition(actor: Dictionary, identity: String) -> Dictionary:
	var action: RefCounted = profile(actor).action(actor,identity)
	if action==null: return {}
	var definition: Dictionary = action.definition.duplicate(true)
	var effects: Dictionary = actor.spatial.effects
	if identity=="bide" and effects.has("bide") and effects.bide.get("ready",false): definition.shape = "S3"; definition.target = "enemy"; definition.bideRelease = true
	if identity=="mirror-move":
		var source: Dictionary = effects.get("mirror",{})
		if not source.is_empty() and catalog.moves.has(source.move):
			var copied: Dictionary = catalog.moves[source.move].duplicate(true)
			copied.cost = definition.cost
			copied.copiedBy = identity
			return copied
	return definition

func aim_points(state: Dictionary, identity: String) -> Array:
	var actor: Dictionary = active(state)
	if actor.is_empty(): return []
	var definition: Dictionary = _definition(actor,identity)
	if definition.is_empty(): return []
	if definition.shape=="U": return [{"x":actor.x,"y":actor.y}]
	var result: Array = []
	var reach: int = int(definition.range)
	for y: int in range(maxi(0,actor.y-reach),mini(state.board.size(),actor.y+reach+1)):
		for x: int in range(maxi(0,actor.x-reach),mini(state.board[0].size(),actor.x+reach+1)):
			var point: Dictionary = {"x":x,"y":y}
			if Movement.distance(actor,point)<=reach and (not Geometry.wall_at(state,point) or (definition.get("breakScreen",false) and state.fields.any(func(f):return f.kind=="wall" and Movement.same(f,point)))): result.append(point)
	return result

func attack_plan(state: Dictionary, target_id: int, origin: Dictionary = {}, action_id: String = "basic") -> Dictionary:
	var target: Dictionary = unit_by_id(state,target_id)
	if target.is_empty(): return {"ok":false,"reason":"Elige una casilla de objetivo."}
	return cast_plan(state,{"x":target.x,"y":target.y},action_id,origin)

func cast_plan(state: Dictionary, aim: Dictionary, identity: String = "basic", origin: Dictionary = {}) -> Dictionary:
	var current: Dictionary = active(state)
	if current.is_empty() or state.acted: return {"ok":false,"reason":"No queda acción en esta activación."}
	if not _valid_point(state,aim): return {"ok":false,"reason":"Casilla no válida."}
	if current.status!=null and current.status.kind in ["sleep","freeze"]: return {"ok":false,"reason":"No puede actuar mientras duerme o está congelado."}
	var definition: Dictionary = _definition(current,identity)
	if definition.is_empty(): return {"ok":false,"reason":"No conoce ese movimiento."}
	var actor: Dictionary = current.duplicate(true)
	actor.merge(origin,true)
	var effects: Dictionary = actor.spatial.effects
	if effects.has("flinch"): return {"ok":false,"reason":"Sorpresa impide esta acción; puedes moverte y orientar para terminar."}
	if effects.has("disable") and effects.disable.move==identity: return {"ok":false,"reason":"Movimiento anulado durante esta activación; el básico sigue disponible."}
	if effects.has("taunt") and definition.category=="status": return {"ok":false,"reason":"Mofa impide usar apoyo; puedes atacar y moverte."}
	if effects.has("encore") and identity not in ["basic",effects.encore.move]: return {"ok":false,"reason":"Otra Vez: elige el último movimiento o el básico."}
	if actor.get("heldItem")=="assault-vest" and definition.category=="status": return {"ok":false,"reason":"Chaleco Asalto impide acciones de apoyo."}
	if identity in RECOVERY and int(actor.recoveryPP.get(identity,0))<=0: return {"ok":false,"reason":"No quedan usos de recuperación."}
	if identity=="rest" and actor.get("ability") in ["insomnia","vital-spirit"]: return {"ok":false,"reason":"Su habilidad impide dormirse."}
	if definition.get("selfKO",false) and living(state).any(func(u):return u.get("ability")=="damp"): return {"ok":false,"reason":"Humedad impide la autodestrucción."}
	if identity=="fake-out" and int(actor.spatial.attacks)>0: return {"ok":false,"reason":"Sorpresa solo se usa como primera acción ofensiva del combate."}
	if identity=="mirror-move" and not definition.has("copiedBy"): return {"ok":false,"reason":"Todavía no ha recibido un movimiento que pueda repetir."}
	if definition.shape=="U" and not Movement.same(actor,aim): return {"ok":false,"reason":"Se aplica al propio usuario."}
	var special: String = definition.get("special","")
	var break_wall: bool = definition.get("breakScreen",false) and state.fields.any(func(f):return f.kind=="wall" and Movement.same(f,aim))
	var visibility: Dictionary = state
	if break_wall:
		visibility = state.duplicate()
		visibility.fields = state.fields.filter(func(f):return f.kind!="wall")
		definition.breakWall = true
	if special=="throw": definition.throwFacing = int(aim.get("throwFacing",FACINGS.find(actor.facing)))
	if special=="teleport":
		if Movement.same(actor,aim) or _occupied(state,aim) or Geometry.wall_at(state,aim) or Movement.distance(actor,aim)>definition.range or is_inf(Movement.tile_cost(state.board,aim,actor.profile)) or not Geometry.visible(state,actor,aim): return {"ok":false,"reason":"Elige un destino libre, visible y transitable dentro del alcance."}
	var approach: Dictionary = {}
	var target: Dictionary = _at(state,aim)
	if special=="metronome" and (target.is_empty() or target.team==actor.team): return {"ok":false,"reason":"Metrónomo necesita un rival visible dentro del alcance."}
	var distance: int = Movement.distance(actor,aim)
	if distance>int(definition.get("contactRange",definition.range)):
		if distance>definition.range: return {"ok":false,"reason":"Fuera del alcance del movimiento."}
		if not target.is_empty(): approach = _jump_approach(state,actor,target,definition) if definition.get("jump",false) else _approach(state,actor,target,int(definition.get("approach",0)))
		if approach.is_empty(): return {"ok":false,"reason":"No hay una aproximación legal con el movimiento restante."}
		actor.merge(approach.destination,true)
	if distance>definition.range: return {"ok":false,"reason":"Fuera del alcance del movimiento."}
	if definition.get("field","")!="wall" and not Geometry.visible(visibility,actor,aim,not definition.get("spatialArea",false) and definition.category!="status"): return {"ok":false,"reason":"Un obstáculo, altura o unidad bloquea el objetivo."}
	var tiles: Array = [aim.duplicate()] if break_wall else Geometry.tiles(state,actor,aim,definition)
	if tiles.is_empty(): return {"ok":false,"reason":"El área queda bloqueada por el terreno."}
	if definition.get("field","")=="wall" and tiles.any(func(p):return _occupied(state,p)): return {"ok":false,"reason":"Una barrera solo se coloca en casillas libres."}
	if definition.get("field","")=="wall" and not _wall_has_exit(state,tiles): return {"ok":false,"reason":"Esa barrera dejaría una unidad sin salida."}
	var selected: Array = []
	var area: bool = definition.get("spatialArea",false)
	for unit: Dictionary in living(state):
		if not tiles.any(func(p):return Movement.same(p,unit)): continue
		if area and unit.id==actor.id and not definition.get("includeUser",false): continue
		if not area:
			if definition.target=="enemy" and unit.team==actor.team: continue
			if definition.target=="friendly" and unit.team!=actor.team: continue
		selected.append(unit)
	var ground: bool = break_wall or special in ["field","teleport","metronome"] or definition.get("field","")!=""
	if selected.is_empty() and not ground and not area: return {"ok":false,"reason":"Necesita un objetivo válido en esa casilla."}
	if identity=="dream-eater" and (target.is_empty() or target.status==null or target.status.kind!="sleep"): return {"ok":false,"reason":"Comesueños requiere un objetivo dormido."}
	if special=="mimic" and (target.is_empty() or target.spatial.lastMove=="" or target.spatial.lastMove in ["mimic","metronome","mirror-move","transform","basic"]): return {"ok":false,"reason":"El objetivo no ha usado una técnica que puedas copiar."}
	if special in ["disable","encore"] and (target.is_empty() or target.spatial.lastMove in ["","basic"]): return {"ok":false,"reason":"El objetivo aún no tiene un último movimiento válido."}
	if special in ["disable","taunt","encore","bound"] and not target.is_empty() and target.spatial.effects.has(special): return {"ok":false,"reason":"Ese efecto ya está activo."}
	if special=="yawn" and (target.is_empty() or not _can_status(target,"sleep") or target.spatial.effects.has("yawn") or target.spatial.effects.has("immunity")): return {"ok":false,"reason":"Ese objetivo no puede recibir somnolencia ahora."}
	if special=="substitute" and (actor.hp<=maxi(1,int(actor.maxHp/4.0)) or effects.has("substitute")): return {"ok":false,"reason":"Necesita más de un cuarto de PS y no tener un Sustituto activo."}
	if special=="rage" and effects.has("rage"): return {"ok":false,"reason":"Furia ya está preparada."}
	if special=="help" and not target.is_empty() and target.spatial.effects.has("help"): return {"ok":false,"reason":"Ese aliado ya tiene Refuerzo preparado."}
	var cost: int = int(definition.cost)
	if identity!="basic" and selected.any(func(u):return u.team!=actor.team and u.get("ability")=="pressure"): cost = mini(5,cost+1)
	if current.tp<cost: return {"ok":false,"reason":"Necesita %d PT; quedan %d." % [cost,current.tp]}
	selected.sort_custom(func(a,b):return Movement.distance(actor,a)>Movement.distance(actor,b) if Movement.distance(actor,a)!=Movement.distance(actor,b) else a.id<b.id)
	if definition.get("sharedDamageBudget",false): definition.areaScale = float(definition.get("areaScale",1.0))/maxi(1,selected.size())
	var hits: Array = []
	for unit: Dictionary in selected:
		if special=="field": continue
		var per_target: Dictionary = definition
		if definition.get("pushFirst",false):
			var nearer: bool = selected.any(func(other):return other.team!=actor.team and (Movement.distance(actor,other)<Movement.distance(actor,unit) or (Movement.distance(actor,other)==Movement.distance(actor,unit) and other.id<unit.id)))
			if nearer or unit.team==actor.team: per_target = definition.duplicate(true); per_target.erase("pushDistance")
		var hit: Dictionary = _spatial_forecast(state,actor,unit,per_target,identity)
		if not hit.get("valid",true):
			if not area: return {"ok":false,"reason":hit.reason}
			continue
		hits.append(hit)
	var primary: Dictionary = hits[0].duplicate(true) if not hits.is_empty() else _empty_hit(definition)
	if not target.is_empty():
		for hit: Dictionary in hits:
			if hit.targetId==target.id: primary = hit.duplicate(true)
	primary.merge({"ok":true,"name":definition.name,"cost":cost,"actionId":identity,"definition":definition,"aim":aim.duplicate(),"hits":hits,"tiles":tiles,"embers":[],"approach":approach,"recoil":0,"field":definition.get("field",""),"shape":definition.shape},true)
	var maximum: int = 0
	for hit: Dictionary in hits: maximum += maxi(int(hit.damageMax),int(hit.criticalMax))
	primary.recoil = int(floor(maximum*definition.get("recoil",0)/100.0)) if current.get("ability")!="rock-head" else 0
	if current.get("heldItem")=="life-orb" and maximum>0: primary.recoil += maxi(1,int(current.maxHp/10.0))
	if definition.get("selfKO",false): primary.recoil = current.hp
	if special=="substitute": primary.recoil = maxi(1,int(current.maxHp/4.0))
	primary.hazardRisk = definition.get("field","") in ["fire","poison","rocks","web","mud","smoke"] and living(state).any(func(u):return u.team==actor.team and tiles.any(func(p):return Movement.same(u,p)))
	if special=="metronome":
		var low: int = 2147483647
		var high: int = 0
		var planning: Dictionary = state.duplicate(true)
		for chosen: String in progression.spatial_data.metronomePool:
			active(planning).moves = [chosen]
			var option: Dictionary = cast_plan(planning,aim,chosen,origin)
			if not option.ok: return {"ok":false,"reason":"Metrónomo necesita un rival visible dentro del alcance."}
			low = mini(low,int(option.damageMin)); high = maxi(high,int(option.damageMax))
		primary.damageMin = low; primary.damageMax = high
		primary.randomTechnique = true
	return primary

func _empty_hit(definition: Dictionary) -> Dictionary:
	return {"damage":0,"damageMin":0,"damageMax":0,"normalMin":0,"normalMax":0,"criticalMin":0,"criticalMax":0,"criticalChance":0.0,"criticalStages":0,"accuracy":100,"side":null,"heal":0,"multiplier":1,"stab":1,"category":definition.category,"guard":false,"status":null,"statusReason":null,"push":null,"pushReason":null}

func _spatial_forecast(state: Dictionary, actor: Dictionary, target: Dictionary, definition: Dictionary, identity: String) -> Dictionary:
	var hit: Dictionary = _forecast(actor,target,SpatialActions.create(definition,profiles[1].library.basic.chart),attack_side(actor,target))
	hit.targetId = target.id
	if definition.category=="status" and hit.statusReason!=null and definition.get("special","")=="": return {"valid":false,"reason":hit.statusReason}
	var special: String = definition.get("special","")
	if special=="counter" or (special=="bide" and actor.spatial.effects.has("bide") and actor.spatial.effects.bide.get("ready",false)):
		var amount: int = int(actor.spatial.get("lastPhysical" if identity=="counter" else "lastSpecial",0))*2 if special=="counter" else mini(int(actor.maxHp),int(actor.spatial.effects.bide.get("damage",0))*2)
		var source: int = int(actor.spatial.get("lastPhysicalSource" if identity=="counter" else "lastSpecialSource",actor.spatial.lastAttacker))
		if amount<=0 or (special=="counter" and source!=target.id): return {"valid":false,"reason":"Necesita daño del tipo correspondiente y responder a su fuente."}
		if hit.multiplier==0: amount = 0
		for key: String in ["damage","damageMin","damageMax","normalMin","normalMax","criticalMin","criticalMax","rollNormalMin","rollNormalMax","rollCriticalMin","rollCriticalMax"]: hit[key] = mini(target.hp,amount)
		hit.criticalChance = 0.0
	var factor: float = float(definition.get("areaScale",1.0)) if definition.category!="status" else 1.0
	var optical: bool = definition.id not in ["growl","roar","sing","screech","supersonic","sonic-boom","bug-buzz"] and definition.type!="ground"
	if optical and not definition.get("neverMiss",false) and definition.target!="self" and actor.get("ability") not in ["no-guard","keen-eye"] and target.get("ability")!="no-guard" and Geometry.crosses(state,actor,target,["smoke"]):
		hit.accuracy = maxi(1,int(floor(hit.accuracy*0.75)))
		hit.accuracyHints.append("Humo: una sola penalización local ×0,75")
	if definition.category!="status" and Geometry.crosses(state,actor,target,["reflect" if definition.category=="physical" else "light-screen"]) and not definition.get("breakScreen",false):
		factor *= 0.75
		hit.abilityHints.append("Pantalla: daño ×0,75")
	if target.spatial.effects.has("substitute") and actor.id!=target.id and definition.id not in ["growl","roar","sing","screech","supersonic","sonic-boom","bug-buzz"]:
		hit.substitute = true
		hit.status = null
		hit.changes = []
		hit.erase("volatile")
	if target.spatial.effects.has("immunity") and hit.status!=null and hit.status.kind in ["sleep","freeze"]: hit.status = null
	if actor.team!=target.team and Geometry.crosses(state,target,target,["mist"]) and not hit.get("changesSelf",false): hit.changes = hit.get("changes",[]).filter(func(c):return c.stages>=0)
	if hit.status!=null: hit.status.duration = int(definition.get("statusDuration",3))
	if definition.get("randomStatusChance",0)>0 and hit.multiplier!=0 and not hit.get("substitute",false): hit.randomStatus = {"chance":int(definition.randomStatusChance)*(2 if actor.get("ability")=="serene-grace" else 1),"kinds":["burn","freeze","paralysis"]}
	for key: String in ["damage","damageMin","damageMax","normalMin","normalMax","criticalMin","criticalMax","rollNormalMin","rollNormalMax","rollCriticalMin","rollCriticalMax"]:
		if hit.get(key,0)>0: hit[key] = maxi(1,int(floor(hit[key]*factor)))
	if definition.get("healTarget",false): hit.heal = mini(target.maxHp-target.hp,maxi(1,int(target.maxHp/2.0)))
	if hit.multiplier!=0 and (definition.get("pullDistance",0)>0 or definition.get("pushDistance",0)>0):
		var displacement: Dictionary = _displacement(state,actor,target,definition)
		hit.push = displacement.get("destination")
		hit.pushReason = displacement.get("reason")
	return hit

func _displacement(state: Dictionary, actor: Dictionary, target: Dictionary, definition: Dictionary) -> Dictionary:
	var steps: int = int(definition.get("pullDistance",definition.get("pushDistance",0)))
	if actor.id==target.id or steps<=0: return {}
	if target.get("ability")=="suction-cups": return {"reason":"Ventosas impide el desplazamiento."}
	if definition.get("special","")=="throw":
		var throw_vector: Vector2i = VECTORS[FACINGS[int(definition.get("throwFacing",0))]]
		for distance: int in [2,1]:
			var drop: Dictionary = {"x":actor.x+throw_vector.x*distance,"y":actor.y+throw_vector.y*distance}
			if _occupied(state,drop) or Geometry.wall_at(state,drop) or is_inf(Movement.tile_cost(state.board,drop,target.profile)): continue
			if absi(Terrain.height_at(state,target)-Terrain.height_at(state,drop))>1 or not Geometry.visible(state,target,drop): continue
			return {"destination":drop}
		return {"reason":"No hay aterrizaje libre en esa dirección; Q/E cambia la proyección."}
	var direction: Vector2i = VECTORS[Movement.facing_from(actor,target)]
	if definition.get("pullDistance",0)>0: direction *= -1
	var current: Dictionary = {"x":target.x,"y":target.y}
	for index: int in steps:
		var point: Dictionary = {"x":current.x+direction.x,"y":current.y+direction.y}
		if _occupied(state,point) or is_inf(Paths.step_cost(state,target,current,point)): break
		current = point
	return {"reason":"No hay una casilla libre y transitable para desplazarlo."} if Movement.same(current,target) else {"destination":current}

func _jump_approach(state: Dictionary, actor: Dictionary, target: Dictionary, definition: Dictionary) -> Dictionary:
	var options: Array = []
	for vector: Vector2i in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
		var point: Dictionary = {"x":target.x+vector.x,"y":target.y+vector.y}
		var distance: int = Movement.distance(actor,point)
		if not Geometry.inside(state,point) or Geometry.wall_at(state,point) or _occupied(state,point) or distance>mini(int(definition.approach),int(actor.remaining)): continue
		if is_inf(Movement.tile_cost(state.board,point,actor.profile)) or absi(Terrain.height_at(state,point)-Terrain.height_at(state,target))>1: continue
		if definition.get("underground",false) and Geometry.segment(actor,point).any(func(p):return Geometry.wall_at(state,p) or state.board[int(p.y)][int(p.x)]==3): continue
		if not Geometry.visible(state,actor,point): continue
		options.append({"destination":point,"cost":distance,"path":[{"x":actor.x,"y":actor.y},point]})
	options.sort_custom(func(a,b):return a.cost<b.cost if a.cost!=b.cost else Movement.key(a.destination)<Movement.key(b.destination))
	return {} if options.is_empty() else options[0]

func _valid_point(state: Dictionary, point: Dictionary) -> bool:
	for key: String in ["x","y"]:
		if not (point.get(key) is int or point.get(key) is float) or point[key]!=int(point[key]): return false
	if point.has("axis") and (not (point.axis is int or point.axis is float) or point.axis!=int(point.axis) or int(point.axis) not in [0,1]): return false
	if point.has("throwFacing") and (not (point.throwFacing is int or point.throwFacing is float) or point.throwFacing!=int(point.throwFacing) or int(point.throwFacing) not in [0,1,2,3]): return false
	return Geometry.inside(state,point)

func _at(state: Dictionary, point: Dictionary) -> Dictionary:
	for unit: Dictionary in living(state):
		if Movement.same(unit,point): return unit
	return {}

func _occupied(state: Dictionary, point: Dictionary) -> bool:
	return not _at(state,point).is_empty()

func _wall_has_exit(state: Dictionary, tiles: Array) -> bool:
	for unit: Dictionary in living(state):
		var exits: int = 0
		for vector: Vector2i in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
			var point: Dictionary = {"x":unit.x+vector.x,"y":unit.y+vector.y}
			if not tiles.any(func(p):return Movement.same(p,point)) and not is_inf(Paths.step_cost(state,unit,unit,point)): exits += 1
		if exits==0: return false
	return true

func attack(state: Dictionary, target_id: int, action_id: String = "basic") -> Dictionary:
	var target: Dictionary = unit_by_id(state,target_id)
	return cast(state,{"x":target.x,"y":target.y},action_id) if not target.is_empty() else {"ok":false,"reason":"Objetivo no válido."}

func cast(state: Dictionary, aim: Dictionary, identity: String) -> Dictionary:
	var plan: Dictionary = cast_plan(state,aim,identity)
	if not plan.ok: return plan
	var next: Dictionary = state.duplicate(true)
	next.zoneEvents = []
	next.abilityEvents = []
	var actor: Dictionary = active(next)
	var definition: Dictionary = plan.definition
	if definition.get("special","")=="metronome":
		var pool: Array = progression.spatial_data.metronomePool
		var chosen: String = pool[int(floor(Rng.next(next)*pool.size()))]
		var planning: Dictionary = next.duplicate(true)
		var planning_actor: Dictionary = active(planning)
		planning_actor.moves[planning_actor.moves.find(identity)] = chosen
		var chosen_plan: Dictionary = cast_plan(planning,aim,chosen)
		if not chosen_plan.ok: return {"ok":false,"reason":"Metrónomo necesita un rival visible dentro del alcance."}
		chosen_plan.cost = plan.cost
		plan = chosen_plan
		definition = plan.definition
		note(next,"Metrónomo elige "+definition.name+".")
	actor.tp -= plan.cost
	actor.lastDamage = 0
	next.acted = true
	if not plan.approach.is_empty():
		for point: Dictionary in plan.approach.path.slice(1):
			actor.merge(point,true)
			_zone_entry(next,actor,point)
			if actor.hp<=0: break
		actor.remaining -= plan.approach.cost
		next.moved = true
	if not Movement.same(actor,aim): actor.facing = Movement.facing_from(actor,aim)
	note(next,"%s usa %s (%d PT)." % [actor.name,definition.name,plan.cost])
	var hits: Array = []
	var total_damage: int = 0
	if definition.get("breakScreen",false): _clear_fields(next,Geometry.segment(actor,aim),["reflect","light-screen","wall"])
	if actor.hp>0:
		for forecast: Dictionary in plan.hits:
			var receipt: Dictionary = _resolve_hit(next,actor,forecast,definition)
			hits.append(receipt)
			total_damage += int(receipt.damage)
			if receipt.hit and not receipt.get("shielded",false) and forecast.multiplier!=0: _special_hit(next,actor,unit_by_id(next,int(receipt.targetId)),definition)
		if definition.get("special","")=="teleport":
			actor.merge({"x":aim.x,"y":aim.y},true)
			_zone_entry(next,actor,actor)
		if definition.get("field","")!="": _place_field(next,actor,plan)
		if definition.get("dispel",false): _clear_fields(next,plan.tiles,["smoke","poison"])
		if definition.get("extinguish",false): _clear_fields(next,plan.tiles,["fire"])
		if definition.get("retreat",false): _retreat(next,actor)
		if definition.get("special","")=="pay-day" and not next.get("payDay",false): next.payDay = true
		_self_special(next,actor,definition)
	if identity in RECOVERY: actor.recoveryPP[identity] -= 1
	var recoil: int = int(floor(total_damage*definition.get("recoil",0)/100.0)) if actor.get("ability")!="rock-head" else 0
	if definition.get("selfKO",false): recoil = actor.hp
	if actor.get("heldItem")=="life-orb" and total_damage>0: recoil += maxi(1,int(actor.maxHp/10.0))
	if recoil>0:
		recoil = mini(actor.hp,recoil)
		actor.hp -= recoil
		hits.append({"targetId":actor.id,"hit":true,"damage":recoil,"recoil":true,"moveRecoil":true})
	actor.spatial.lastMove = definition.id
	if definition.category!="status": actor.spatial.attacks += 1
	actor.spatial.lastPhysical = 0
	actor.spatial.lastSpecial = 0
	actor.spatial.effects.erase("help")
	_advance_after_casualties(next)
	return {"ok":true,"state":next,"damage":0 if hits.is_empty() else hits[0].damage,"hit":true if hits.is_empty() else hits[0].hit,"hits":hits,"visualDefinition":definition,"aim":aim}

func _resolve_hit(state: Dictionary, actor: Dictionary, forecast: Dictionary, definition: Dictionary) -> Dictionary:
	var target: Dictionary = unit_by_id(state,int(forecast.targetId))
	if target.hp<=0: return {"targetId":target.id,"hit":false,"damage":0}
	_announce(state,actor,target,forecast.get("accuracyHints",[]))
	var landed: bool = forecast.accuracy==100 or (forecast.accuracy>0 and Rng.next(state)*100<forecast.accuracy)
	if not landed: return {"targetId":target.id,"hit":false,"damage":0}
	_announce(state,actor,target,forecast.get("abilityHints",[]))
	var critical: bool = forecast.criticalChance==1 or (forecast.criticalChance>0 and Rng.next(state)<forecast.criticalChance)
	var amount: int = _roll(state,int(forecast["rollCriticalMin" if critical else "rollNormalMin"]),int(forecast["rollCriticalMax" if critical else "rollNormalMax"]))
	if target.get("ability")=="sturdy" and actor.get("ability")!="mold-breaker" and target.hp==target.maxHp: amount = mini(amount,maxi(0,int(target.hp)-1))
	var shielded: bool = forecast.get("substitute",false) and target.spatial.effects.has("substitute")
	if shielded:
		target.spatial.effects.substitute.hp -= amount
		if target.spatial.effects.substitute.hp<=0: target.spatial.effects.erase("substitute")
		amount = 0
	amount = mini(target.hp,amount)
	target.hp -= amount
	if amount>0:
		target.lastDamage = amount
		target.spatial.lastAttacker = actor.id
		target.spatial["lastPhysical" if definition.category=="physical" else "lastSpecial"] += amount
		target.spatial["lastPhysicalSource" if definition.category=="physical" else "lastSpecialSource"] = actor.id
		if target.spatial.effects.has("bide"): target.spatial.effects.bide.damage += amount
		if target.spatial.effects.has("rage"): _change(target,{"stat":"attack","stages":1}); target.spatial.effects.erase("rage")
		if definition.id not in ["mirror-move","metronome","mimic","transform"]: target.spatial.effects.mirror = {"move":definition.id,"remaining":3}
	var healed: Dictionary = target if definition.get("healTarget",false) else actor
	var heal: int = mini(healed.maxHp-healed.hp,int(amount/2.0)) if definition.kind=="drain" else int(forecast.heal)
	if healed.hp>0: healed.hp = mini(healed.maxHp,healed.hp+heal)
	if forecast.guard: target.guarded = true
	if forecast.get("focus",false): actor.volatile.focus = {"remaining":3,"source":actor.id}
	if target.hp>0 and not shielded:
		if forecast.status!=null and (forecast.status.chance==100 or Rng.next(state)*100<forecast.status.chance): _give_status(target,forecast.status.kind); target.status.remaining = int(definition.get("statusDuration",3))
		if forecast.has("randomStatus") and target.status==null and Rng.next(state)*100<forecast.randomStatus.chance:
			var kinds: Array = forecast.randomStatus.kinds
			var kind: String = kinds[int(floor(Rng.next(state)*kinds.size()))]
			var susceptible: Dictionary = target.duplicate(true)
			if actor.get("ability")=="mold-breaker": susceptible.ability = ""
			if _can_status(susceptible,kind) and not (kind=="freeze" and target.spatial.effects.has("immunity")):
				_give_status(target,kind)
				forecast.status = {"kind":kind,"chance":100,"duration":3}
		if forecast.get("clearStages",false):
			target.stages.clear()
			target.stageTurns.clear()
			for key: String in target.baseCombatStats: target[key] = target.baseCombatStats[key]
		if forecast.has("volatile"):
			var effect: Dictionary = forecast.volatile
			if effect.chance==100 or Rng.next(state)*100<effect.chance: target.volatile[effect.kind] = {"remaining":3,"source":actor.id}
		if forecast.push!=null and forecast.multiplier!=0:
			var displacement: Dictionary = _displacement(state,actor,target,definition)
			if displacement.has("destination"):
				var path: Array = [displacement.destination] if definition.get("special","")=="throw" else Geometry.segment(target,displacement.destination).slice(1)
				for point: Dictionary in path:
					target.merge(point,true)
					_zone_entry(state,target,point)
					if target.hp<=0: break
		var affected: Dictionary = actor if forecast.get("changesSelf",false) else target
		if affected.hp>0 and (definition.get("changeChance",100)==100 or Rng.next(state)*100<definition.changeChance):
			for change: Dictionary in forecast.get("changes",[]): _change(affected,change)
	if amount>0 and forecast.staticChance>0 and actor.hp>0 and actor.status==null and Rng.next(state)<forecast.staticChance: _give_status(actor,"paralysis")
	_extra_hit(state,actor,target,definition,forecast,amount,critical)
	var receipt: Dictionary = {"targetId":target.id,"hit":true,"damage":amount,"heal":heal,"critical":critical,"shielded":shielded}
	if forecast.push!=null: receipt.push = {"x":target.x,"y":target.y}
	note(state,"%s: %d PS%s." % [target.name,amount," · CRÍTICO" if critical else ""])
	return receipt

func _special_hit(state: Dictionary, actor: Dictionary, target: Dictionary, definition: Dictionary) -> void:
	if target.hp<=0: return
	var special: String = definition.get("special","")
	match special:
		"bound": target.spatial.effects.bound = {"source":actor.id,"remaining":1}
		"disable","encore": target.spatial.effects[special] = {"move":target.spatial.lastMove,"remaining":1}
		"taunt": target.spatial.effects.taunt = {"remaining":1}
		"yawn":
			if target.status==null: target.spatial.effects.yawn = {"remaining":1}
		"help": target.spatial.effects.help = {"remaining":1}
		"mimic":
			var index: int = actor.moves.find("mimic")
			if index>=0: actor.moves[index] = target.spatial.lastMove
		"fake-out": target.spatial.effects.flinch = {"remaining":1}
	if definition.get("special","")=="bide" and actor.spatial.effects.has("bide") and actor.spatial.effects.bide.get("ready",false): actor.spatial.effects.erase("bide")
	if definition.get("breakScreen",false): target.guarded = false
	if definition.get("copiedBy","")=="mirror-move": actor.spatial.effects.erase("mirror")
	if target.spatial.effects.has("substitute") and actor.id!=target.id: note(state,"Sustituto protege a "+target.name+".")

func _self_special(state: Dictionary, actor: Dictionary, definition: Dictionary) -> void:
	match definition.get("special",""):
		"substitute":
			var cost: int = maxi(1,int(actor.maxHp/4.0))
			actor.hp -= cost
			actor.spatial.effects.substitute = {"hp":cost,"remaining":3}
		"conversion":
			for identity: String in actor.moves:
				if catalog.moves[identity].category!="status": actor.types = [catalog.moves[identity].type]; break
		"bide":
			if not definition.get("bideRelease",false) and not actor.spatial.effects.has("bide"): actor.spatial.effects.bide = {"remaining":3,"ready":false,"damage":0}
		"rage": actor.spatial.effects.rage = {"remaining":3}
	if definition.get("special","")=="pay-day": note(state,"Día de Pago: como máximo una recompensa por encuentro.")

func _place_field(state: Dictionary, actor: Dictionary, plan: Dictionary) -> void:
	state.spatialZones = int(state.get("spatialZones",0))+1
	for point: Dictionary in plan.tiles:
		state.fields = state.fields.filter(func(f):return f.kind!=plan.field or not Movement.same(f,point))
		state.fields.append({"x":point.x,"y":point.y,"kind":plan.field,"expires":state.round+3,"source":actor.id,"zone":state.spatialZones,"chance":int(plan.definition.accuracy)})
	note(state,"%s crea %s: dos rondas completas." % [actor.name,plan.definition.name])

func _clear_fields(state: Dictionary, points: Array, kinds: Array) -> void:
	state.fields = state.fields.filter(func(f):return f.kind not in kinds or not points.any(func(p):return Movement.same(f,p)))

func _zone_entry(state: Dictionary, unit: Dictionary, point: Dictionary) -> bool:
	var changed: bool = false
	var previous_rng: int = int(state.rng)
	for field: Dictionary in state.fields.duplicate():
		if not Movement.same(field,point) or field.kind not in ["poison","fire","rocks"]: continue
		if field.kind in ["fire","rocks"] and (unit.profile=="fly" or unit.get("ability")=="levitate" or unit.get("heldItem")=="heavy-duty-boots"): continue
		var key: String = field.kind+":"+str(state.get("spatialClock",0))
		if unit.spatial.zoneMarks.has(key): continue
		if field.kind=="poison" and not _can_status(unit,"poison"): continue
		if field.kind=="fire" and "fire" in unit.types: continue
		unit.spatial.zoneMarks[key] = true
		if field.kind=="poison":
			if _can_status(unit,"poison") and (field.get("chance",100)==100 or Rng.next(state)*100<field.chance): _give_status(unit,"poison"); changed = true
		else:
			if field.kind=="fire" and "fire" in unit.types: continue
			var amount: int = maxi(1,int(unit.maxHp/(16.0 if field.kind=="fire" else 12.0)))
			unit.hp = maxi(0,int(unit.hp)-amount)
			changed = true
			if field.kind=="rocks": state.fields.erase(field)
		if changed:
			if not state.has("zoneEvents"): state.zoneEvents = []
			state.zoneEvents.append({"targetId":unit.id,"name":field.kind,"effect":"Efecto de zona"})
			note(state,"%s: %s en %s." % [unit.name,field.kind,coordinate(point)])
	return changed or int(state.rng)!=previous_rng

func _retreat(state: Dictionary, actor: Dictionary) -> void:
	if actor.remaining<1: return
	var vector: Vector2i = -VECTORS[int(actor.facing)]
	var destination: Dictionary = {"x":actor.x+vector.x,"y":actor.y+vector.y}
	var cost: float = Paths.step_cost(state,actor,actor,destination)
	if _occupied(state,destination) or is_inf(cost) or cost>actor.remaining: return
	actor.merge(destination,true)
	actor.remaining -= int(cost)
	state.moved = true
	_zone_entry(state,actor,destination)

func _advance_after_casualties(state: Dictionary) -> void:
	var previous: int = int(state.queue[0]) if not state.queue.is_empty() else -1
	resolve_casualties(state)
	if state.outcome!="playing": return
	if state.queue.is_empty(): new_round(state)
	elif int(state.queue[0])!=previous: begin_activation(state)

func finish(state: Dictionary, facing: Variant = null) -> Dictionary:
	if active(state).is_empty(): return {"ok":false,"reason":"El combate ha terminado."}
	if facing!=null and (not (facing is int or facing is float) or facing!=int(facing) or int(facing) not in FACINGS): return {"ok":false,"reason":"Orientación no válida."}
	var next: Dictionary = state.duplicate(true)
	next.zoneEvents = []
	next.abilityEvents = []
	var actor: Dictionary = active(next)
	if facing!=null: actor.facing = int(facing)
	if actor.get("ability")=="shed-skin" and actor.status!=null and Rng.next(next)<1.0/3.0:
		actor.status = null
		_ability(next,actor,"cura su estado principal")
	var old_status: String = "" if actor.status==null else actor.status.kind
	if actor.status!=null:
		if actor.status.kind in ["burn","poison"]: actor.hp = maxi(0,int(actor.hp)-maxi(1,int(actor.maxHp/(8.0 if actor.status.kind=="poison" else 16.0))))
		actor.status.remaining -= 1
		if actor.status.remaining<=0: actor.status = null
	if old_status in ["sleep","freeze"] and actor.status==null: actor.spatial.effects.immunity = {"remaining":2}
	var seed_effect: Dictionary = actor.volatile.get("seed",{})
	if not seed_effect.is_empty():
		var lost: int = mini(actor.hp,maxi(1,int(actor.maxHp/8.0)))
		actor.hp -= lost
		var source: Dictionary = unit_by_id(next,int(seed_effect.source))
		if not source.is_empty() and source.hp>0: source.hp = mini(source.maxHp,source.hp+lost)
	for key: String in actor.volatile.keys():
		actor.volatile[key].remaining -= 1
		if actor.volatile[key].remaining<=0: actor.volatile.erase(key)
	for stat: String in actor.stageTurns.keys():
		actor.stageTurns[stat] -= 1
		if actor.stageTurns[stat]<=0:
			actor.stageTurns.erase(stat)
			actor.stages.erase(stat)
			if actor.baseCombatStats.has(stat): actor[stat] = actor.baseCombatStats[stat]
	for key: String in actor.spatial.effects.keys():
		var effect: Dictionary = actor.spatial.effects[key]
		if key=="bide": effect.ready = true
		effect.remaining -= 1
		if effect.remaining>0: continue
		if key=="yawn" and actor.hp>0 and _can_status(actor,"sleep") and not actor.spatial.effects.has("immunity"): _give_status(actor,"sleep")
		actor.spatial.effects.erase(key)
	if actor.hp>0 and actor.heldItem=="leftovers": actor.hp = mini(actor.maxHp,int(actor.hp)+maxi(1,int(actor.maxHp/16.0)))
	next.completed.append(actor.id)
	next.queue = next.queue.slice(1)
	next.moved = false
	next.acted = false
	resolve_casualties(next)
	if next.outcome=="playing":
		if next.queue.is_empty(): new_round(next)
		else: begin_activation(next)
	return {"ok":true,"state":next}

func apply_command(state: Dictionary, command: Dictionary) -> Dictionary:
	if command.get("kind")=="attack" and command.has("aim"):
		if not command.aim is Dictionary: return {"ok":false,"reason":"Objetivo de suelo no válido."}
		return cast(state,command.aim,command.get("actionId","basic"))
	var result: Dictionary = super.apply_command(state,command)
	# Feedback history is not a movement consequence. Preserve it on a pure move
	# so the published movement-only comparator can still undo exactly that move.
	if command.get("kind")=="move" and result.ok and not result.get("irreversible",false):
		for key: String in ["zoneEvents","abilityEvents"]:
			if state.has(key): result.state[key] = state[key].duplicate(true)
			else: result.state.erase(key)
	return result

func danger_at(state: Dictionary, actor: Dictionary, point: Dictionary) -> float:
	var clean: Dictionary = state.duplicate()
	clean.fields = []
	var danger: float = super.danger_at(clean,actor,point)
	if actor.profile!="fly" and actor.get("heldItem")!="heavy-duty-boots":
		if state.fields.any(func(f):return f.kind in ["fire","rocks"] and Movement.same(f,point)): danger += 20
	return danger

func action_score(state: Dictionary, _target: Dictionary, plan: Dictionary) -> float:
	if not plan.ok: return 0
	var actor: Dictionary = active(state)
	var value: float = 0
	for hit: Dictionary in plan.hits:
		var unit: Dictionary = unit_by_id(state,int(hit.targetId))
		var team_weight: float = -2.5 if unit.team==actor.team else 1.0
		var friendly: bool = unit.team==actor.team
		value += (hit.damage+minf(12,hit.damage*0.25)+(7 if hit.status!=null else 0)+(4 if hit.push!=null else 0))*hit.accuracy/100.0*team_weight
		for change: Dictionary in hit.get("changes",[]): value += absi(int(change.stages))*4*(1 if (friendly and change.stages>0) or (not friendly and change.stages<0) else -2)
		var healing_self: bool = not plan.definition.get("healTarget",false)
		value += hit.heal*(0.7 if healing_self or friendly else -1.0)
		if hit.guard and unit.team==actor.team and unit.hp<unit.maxHp*0.8: value += 5
		var special: String = plan.definition.get("special","")
		if not friendly and hit.multiplier!=0 and special in ["disable","taunt","encore","yawn","bound","fake-out"]: value += 8*hit.accuracy/100.0
		if friendly and special=="help" and unit.id!=actor.id: value += 5
		if special=="haze":
			for stage: int in unit.stages.values(): value += absi(stage)*3*(1 if (friendly and stage<0) or (not friendly and stage>0) else -2)
		if friendly and special in ["rage","bide","substitute"] and unit.hp>unit.maxHp*.7: value += 3
	if plan.get("field","")!="":
		var supportive: bool = plan.field in ["mist","reflect","light-screen"]
		for unit: Dictionary in living(state):
			if plan.tiles.any(func(p):return Movement.distance(p,unit)<=1): value += (3 if unit.team==actor.team else -1) if supportive else (4 if unit.team!=actor.team else -2)
	value -= float(plan.recoil)*1.2
	if plan.definition.get("special","")=="teleport": value = maxf(0,danger_at(state,actor,actor)-danger_at(state,actor,plan.aim)-2)
	if plan.definition.get("breakWall",false): return 2
	if plan.hits.is_empty() and plan.get("field","")=="" and plan.definition.get("special","")!="teleport": return 0
	return value

func choose_command(state: Dictionary) -> Dictionary:
	var actor: Dictionary = active(state)
	if actor.is_empty(): return {"kind":"finish"}
	var ending: Dictionary = {"kind":"finish","facing":choose_facing(state,actor)}
	if state.acted: return ending
	if actor.spatial.effects.has("flinch"): return ending
	var best: float = 0
	var order: Dictionary = ending
	for action: RefCounted in profile(actor).actions_for(actor):
		var definition: Dictionary = action.definition
		if actor.tp<definition.cost: continue
		var candidates: Array = aim_points(state,definition.id)
		for point: Dictionary in candidates:
			point.axis = 0
			point.throwFacing = FACINGS.find(actor.facing)
			if definition.category!="status" and not living(state).any(func(u):return u.team!=actor.team and Movement.distance(u,point)<=2): continue
			var plan: Dictionary = cast_plan(state,point,definition.id)
			var score: float = action_score(state,actor,plan)
			if score>best:
				best = score
				order = {"kind":"attack","aim":point,"target":_at(state,point).get("id",0),"actionId":definition.id}
	if best>0: return order
	if state.moved: return ending
	var routes: Dictionary = movement_routes(state,actor,actor.remaining)
	var destination: Dictionary = {}
	var nearest: float = INF
	for route: Dictionary in routes.values():
		if route.cost<=0: continue
		var point: Dictionary = route.path[-1]
		for enemy: Dictionary in living(state):
			if enemy.team==actor.team: continue
			var value: float = Movement.distance(point,enemy)+danger_at(state,actor,point)*0.01
			if value<nearest: nearest = value; destination = point
	if not destination.is_empty(): return {"kind":"move","destination":destination}
	return ending
