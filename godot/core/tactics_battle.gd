extends "res://core/letsgo_battle.gd"

const TacticalStudy = preload("res://core/tactics_study.gd")
const TacticalActions = preload("res://core/tactics_actions.gd")

func _init() -> void:
	super()
	progression = TacticalStudy.new()
	catalog = progression.data
	var chart: Dictionary = profiles[1].library.basic.chart
	profiles.clear()
	for record: Dictionary in catalog.species:
		var pokemon: RefCounted = Profile.new(record,chart,progression)
		pokemon.library.basic = TacticalActions.create(progression.BASIC,chart)
		for identity: String in catalog.moves: pokemon.library[identity] = TacticalActions.create(catalog.moves[identity],chart)
		profiles[int(record.id)] = pokemon
	data.species = catalog.species

func member_unit(member: Dictionary, point: Dictionary = {"x":0,"y":0}) -> Dictionary:
	var unit: Dictionary = super.member_unit(member,point)
	unit.stageTurns = {}
	unit.combatEdition = 6
	return unit

func new_round(state: Dictionary) -> void:
	state.round += 1
	state.combatEdition = 6
	state.fields = state.fields.filter(func(field):return field.expires>state.round)
	var units: Array = living(state)
	units.sort_custom(func(a,b):return a.id<b.id)
	state.initiative = []
	for unit: Dictionary in units:
		# Paralysis affects the movement budget only, never initiative or action.
		state.initiative.append({"id":unit.id,"score":unit.speed*(1+(Rng.next(state)*2-1)*state.variance),"tie":Rng.next(state)})
	state.initiative.sort_custom(func(a,b):
		if a.score!=b.score: return a.score>b.score
		if a.tie!=b.tie: return a.tie<b.tie
		return a.id<b.id)
	state.queue = state.initiative.map(func(entry):return entry.id)
	state.completed = []
	for unit: Dictionary in units: unit.remaining = budget(unit)
	note(state,"Ronda %d: nueva cola de iniciativa." % state.round)
	begin_activation(state)

static func damage_band(low: int, high: int, side: String) -> Dictionary:
	var middle: int = int(floor((low+high)/2.0))
	match side:
		"front": return {"min":low,"max":middle}
		"flank": return {"min":middle,"max":high}
	return {"min":high,"max":high}

func _approach(state: Dictionary, actor: Dictionary, target: Dictionary, maximum: int) -> Dictionary:
	if maximum<=0: return {}
	var blocked: Dictionary = {}
	var units: Array = living(state)
	for unit: Dictionary in units:
		if unit.team!=actor.team: blocked[Movement.key(unit)] = true
	var options: Array = []
	for vector: Vector2i in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
		var destination: Dictionary = {"x":target.x+vector.x,"y":target.y+vector.y}
		if is_inf(Movement.tile_cost(state.board,destination,actor.profile)): continue
		if units.any(func(u):return u.id!=actor.id and Movement.same(u,destination)): continue
		var path: Array = Movement._path(state.board,actor,destination,blocked)
		if path.is_empty(): continue
		var cost: int = 0
		for step: Dictionary in path.slice(1): cost += int(Movement.tile_cost(state.board,step,actor.profile))
		if cost>maximum or cost>actor.remaining: continue
		options.append({"destination":destination,"path":path,"cost":cost})
	options.sort_custom(func(a,b):
		if a.cost!=b.cost: return a.cost<b.cost
		return Movement.key(a.destination)<Movement.key(b.destination))
	return options[0] if not options.is_empty() else {}

func _precision(actor: Dictionary, target: Dictionary, definition: Dictionary) -> int:
	if definition.get("neverMiss",false) or definition.target=="self": return 100
	var stage: int = clampi(int(actor.stages.get("accuracy",0))-int(target.stages.get("evasion",0)),-6,6)
	var factor: float = (3.0+stage)/3.0 if stage>=0 else 3.0/(3.0-stage)
	# Confusion retains the disclosed tactical effect from edition5.
	return clampi(int(floor(definition.accuracy*factor))-(25 if actor.get("volatile",{}).has("confusion") else 0),0,100)

func _forecast(actor: Dictionary, target: Dictionary, action: RefCounted, side: String) -> Dictionary:
	var hit: Dictionary = action.preview(actor,target)
	var definition: Dictionary = action.definition
	var maximum: int = hit.get("maximumDamage",hit.damage)
	var fixed: bool = definition.get("fixedMode","")!=""
	var band: Dictionary = {"min":maximum,"max":maximum} if fixed or maximum==0 else damage_band(maxi(1,int(floor(maximum*0.85))),maximum,side)
	var critical: Dictionary = band.duplicate()
	var chance: float = 0
	var stage: int = 0
	if maximum>0 and not fixed and definition.category!="status":
		stage = int(definition.get("criticalStages",0))+(1 if side=="rear" else 0)+(2 if actor.get("volatile",{}).has("focus") else 0)
		chance = 1.0 if definition.get("alwaysCritical",false) else float(progression.tactical.criticalChances[clampi(stage,0,3)])
		var critical_maximum: int = hit.criticalMaximum
		critical = damage_band(maxi(1,int(floor(critical_maximum*0.85))),critical_maximum,side)
	hit.merge({"damageMin":mini(target.hp,critical.min if chance==1 else band.min),"damageMax":mini(target.hp,critical.max if chance==1 else band.max),"normalMin":band.min,"normalMax":band.max,"criticalMin":critical.min,"criticalMax":critical.max,"criticalChance":chance,"criticalStages":stage,"accuracy":_precision(actor,target,definition),"side":side if definition.target=="enemy" else null,"push":null,"pushReason":null},true)
	var expected: float = (band.min+band.max)*0.5*(1-chance)+(critical.min+critical.max)*0.5*chance
	hit.damage = mini(target.hp,int(floor(expected+0.5)))
	if definition.kind=="drain": hit.heal = mini(actor.maxHp-actor.hp,int(floor(hit.damage/2.0)))
	return hit

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
	var distance: int = Movement.distance(actor,target)
	if distance>int(definition.get("contactRange",definition.range)):
		if distance>definition.range: return {"ok":false,"reason":"Fuera de alcance: %d casillas." % definition.range}
		approach = _approach(state,actor,target,int(definition.get("approach",0)))
		if approach.is_empty(): return {"ok":false,"reason":"No hay un acercamiento libre dentro del movimiento restante."}
		actor.merge(approach.destination,true)
	if not clear_shot(state,actor,target): return {"ok":false,"reason":"El terreno u otra unidad bloquea el disparo."}
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
			if is_inf(Movement.tile_cost(state.board,destination,unit.profile)): hit.pushReason = "Terreno o borde bloquea el empuje."
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
	return plan

func _change(unit: Dictionary, change: Dictionary) -> void:
	super._change(unit,change)
	if not unit.has("stageTurns"): unit.stageTurns = {}
	if unit.stages.get(change.stat,0)==0: unit.stageTurns.erase(change.stat)
	else: unit.stageTurns[change.stat] = 3

func _roll(state: Dictionary, low: int, high: int) -> int:
	return low if low==high else low+int(floor(Rng.next(state)*(high-low+1)))

func attack(state: Dictionary, target_id: int, action_id: String = "basic") -> Dictionary:
	var plan: Dictionary = attack_plan(state,target_id,{},action_id)
	if not plan.ok: return plan
	var next: Dictionary = state.duplicate(true)
	var actor: Dictionary = active(next)
	var definition: Dictionary = profile(actor).action(actor,action_id).definition
	actor.tp -= plan.cost
	actor.lastDamage = 0
	next.acted = true
	if not plan.approach.is_empty():
		actor.merge(plan.approach.destination,true)
		actor.remaining -= plan.approach.cost
		next.moved = true
	if actor.id!=target_id: actor.facing = Movement.facing_from(actor,unit_by_id(next,target_id))
	note(next,"%s usa %s (%d PT)." % [actor.name,plan.name,plan.cost])
	var hits: Array = []
	var total_damage: int = 0
	for forecast: Dictionary in plan.hits:
		var target: Dictionary = unit_by_id(next,int(forecast.targetId))
		var landed: bool = forecast.accuracy==100 or (forecast.accuracy>0 and Rng.next(next)*100<forecast.accuracy)
		if not landed:
			hits.append({"targetId":target.id,"hit":false,"damage":0})
			note(next,"%s: el ataque falla (%d %%)." % [target.name,forecast.accuracy])
			continue
		var critical: bool = forecast.criticalChance==1 or (forecast.criticalChance>0 and Rng.next(next)<forecast.criticalChance)
		var damage: int = _roll(next,forecast.criticalMin if critical else forecast.normalMin,forecast.criticalMax if critical else forecast.normalMax)
		damage = mini(target.hp,damage)
		target.hp -= damage
		total_damage += damage
		if damage>0: target.lastDamage = damage
		var heal: int = mini(actor.maxHp-actor.hp,int(damage/2.0)) if definition.kind=="drain" else int(forecast.heal)
		actor.hp = mini(actor.maxHp,actor.hp+heal)
		if forecast.guard: target.guarded = true
		if forecast.get("focus",false): actor.volatile.focus = {"remaining":3,"source":actor.id}
		if target.hp>0:
			if forecast.status!=null and (forecast.status.chance==100 or Rng.next(next)*100<forecast.status.chance): target.status = {"kind":forecast.status.kind,"remaining":3}
			if forecast.get("clearStages",false):
				target.stages.clear()
				target.stageTurns.clear()
				for key: String in target.baseCombatStats: target[key] = target.baseCombatStats[key]
			if forecast.has("volatile"):
				var effect: Dictionary = forecast.volatile
				if effect.chance==100 or Rng.next(next)*100<effect.chance: target.volatile[effect.kind] = {"remaining":3,"source":actor.id}
			if forecast.push!=null: target.merge(forecast.push,true)
		var affected: Dictionary = actor if forecast.get("changesSelf",false) else target
		if affected.hp>0 and not forecast.get("changes",[]).is_empty() and (definition.changeChance==100 or Rng.next(next)*100<definition.changeChance):
			for change: Dictionary in forecast.changes: _change(affected,change)
		var receipt: Dictionary = {"targetId":target.id,"hit":true,"damage":damage,"heal":heal,"critical":critical}
		if forecast.push!=null and target.hp>0: receipt.push = forecast.push
		hits.append(receipt)
		note(next,"%s: %d PS%s%s." % [target.name,damage," · CRÍTICO" if critical else "",", fuera de combate" if target.hp<=0 else ""])
	var move_recoil: int = int(floor(total_damage*definition.get("recoil",0)/100.0))
	if definition.get("selfKO",false): move_recoil = actor.hp
	var orb: int = maxi(1,int(actor.maxHp/10.0)) if actor.get("heldItem")=="life-orb" and total_damage>0 else 0
	for cost: Dictionary in [{"amount":move_recoil,"moveRecoil":true},{"amount":orb,"moveRecoil":false}]:
		var amount: int = mini(actor.hp,int(cost.amount))
		if amount<=0: continue
		actor.hp -= amount
		hits.append({"targetId":actor.id,"hit":true,"damage":amount,"recoil":true,"moveRecoil":cost.moveRecoil})
	resolve_casualties(next)
	if actor.hp<=0 and next.outcome=="playing":
		next.completed.append(actor.id)
		if next.queue.is_empty(): new_round(next)
		else: begin_activation(next)
	var primary: Dictionary = hits.filter(func(hit):return hit.targetId==target_id)[0]
	return {"ok":true,"state":next,"damage":primary.damage,"hit":primary.hit,"hits":hits}

func finish(state: Dictionary, facing: Variant = null) -> Dictionary:
	var next: Dictionary = state.duplicate(true)
	var actor: Dictionary = active(next)
	if actor.is_empty(): return super.finish(state,facing)
	for stat: String in actor.get("stageTurns",{}).keys():
		actor.stageTurns[stat] -= 1
		if actor.stageTurns[stat]<=0:
			actor.stageTurns.erase(stat)
			actor.stages.erase(stat)
			actor[stat] = actor.baseCombatStats[stat]
			note(next,"%s: termina el modificador de %s." % [actor.name,stat])
	return super.finish(next,facing)

func action_score(state: Dictionary, target: Dictionary, plan: Dictionary) -> float:
	var score: float = super.action_score(state,target,plan)
	if not plan.ok: return score
	if plan.get("focus",false): score += 5
	var actor: Dictionary = active(state)
	if plan.category=="status":
		if not living(state).any(func(u):return u.team!=actor.team and Movement.distance(u,actor)<=3): return 0
		score = maxf(0,score-plan.cost*1.5)
	return score

func choose_command(state: Dictionary) -> Dictionary:
	var command: Dictionary = super.choose_command(state)
	if command.kind!="attack" or state.moved or state.acted: return command
	var actor: Dictionary = active(state)
	var target: Dictionary = unit_by_id(state,int(command.target))
	var action: RefCounted = profile(actor).action(actor,command.actionId)
	if action.definition.target!="enemy" or target.team==actor.team: return command
	var baseline: float = action_score(state,target,attack_plan(state,int(target.id),{},command.actionId))
	var best: float = baseline*1.2
	var destination: Dictionary = {}
	var occupied: Array = living(state)
	var blocked: Dictionary = {}
	for unit: Dictionary in occupied:
		if unit.team!=actor.team: blocked[Movement.key(unit)] = true
	for vector: Vector2i in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
		var point: Dictionary = {"x":target.x+vector.x,"y":target.y+vector.y}
		if Movement.same(point,actor) or is_inf(Movement.tile_cost(state.board,point,actor.profile)): continue
		if occupied.any(func(u):return u.id!=actor.id and Movement.same(u,point)): continue
		var path: Array = Movement._path(state.board,actor,point,blocked)
		if path.is_empty(): continue
		var cost: int = 0
		for step: Dictionary in path.slice(1): cost += int(Movement.tile_cost(state.board,step,actor.profile))
		if cost>actor.remaining: continue
		var origin: Dictionary = {"x":point.x,"y":point.y,"remaining":actor.remaining-cost}
		var value: float = action_score(state,target,attack_plan(state,int(target.id),origin,command.actionId))-cost*0.25-maxf(0,danger_at(state,actor,point)-danger_at(state,actor,actor))*0.25
		if value>best:
			best = value
			destination = point
	return {"kind":"move","destination":destination} if not destination.is_empty() else command
