extends "res://core/shop_battle.gd"

const LetsgoStudy = preload("res://core/letsgo_study.gd")
const LetsgoActions = preload("res://core/letsgo_actions.gd")

func _init() -> void:
	super()
	progression = LetsgoStudy.new()
	catalog = progression.data
	var chart: Dictionary = profiles[1].library.basic.chart
	profiles.clear()
	for record: Dictionary in catalog.species:
		var pokemon: RefCounted = Profile.new(record,chart,progression)
		pokemon.library.basic = LetsgoActions.create(progression.BASIC,chart)
		for identity: String in catalog.moves: pokemon.library[identity] = LetsgoActions.create(catalog.moves[identity],chart)
		profiles[int(record.id)] = pokemon
	data.species = catalog.species

func member_unit(member: Dictionary, point: Dictionary = {"x":0,"y":0}) -> Dictionary:
	var unit: Dictionary = super.member_unit(member,point)
	unit.accuracy = 100
	unit.evasion = 100
	unit.baseCombatStats.accuracy = 100
	unit.baseCombatStats.evasion = 100
	unit.volatile = {}
	unit.lastDamage = 0
	return unit

func encounter(run: Dictionary, location: Dictionary) -> Dictionary:
	if location.get("leader",false): return super.encounter(run,location)
	var generation: Dictionary = {"rng":Rng.hash_seed(run.seed+"/"+location.id+"/lgpe-wild")}
	var pool: Array = catalog.encounters[location.captureTable].filter(func(e):return not e.special)
	var units: Array = []
	var starts: Array = [{"x":2,"y":7},{"x":1,"y":8},{"x":3,"y":8},{"x":1,"y":7},{"x":3,"y":7},{"x":2,"y":8}]
	for member: Dictionary in run.party:
		if member.hp>0: units.append(member_unit(member,starts[units.size()]))
	for i: int in location.enemies.size():
		var entry: Dictionary = pool[int(floor(Rng.next(generation)*pool.size()))]
		var level: int = int(entry.minLevel)+int(floor(Rng.next(generation)*(entry.maxLevel-entry.minLevel+1)))
		var member: Dictionary = progression.create_member(10000+int(run.stage)*10+i,int(entry.speciesId),"",level)
		var enemy: Dictionary = member_unit(member,{"x":7+(i%2)*2,"y":2+(i>>1)})
		enemy.team = "enemy"
		enemy.facing = 0
		units.append(enemy)
	var battle: Dictionary = {"seed":run.seed+"/"+location.id,"rng":Rng.hash_seed(run.seed+"/"+location.id),"variance":0.05,"composition":"kanto","round":0,"board":location.board.duplicate(true),"fields":[],"units":units,"initiative":[],"queue":[],"completed":[],"moved":false,"acted":false,"outcome":"playing","log":[],"biome":location.id}
	new_round(battle)
	return battle

func attack_plan(state: Dictionary, target_id: int, origin: Dictionary = {}, action_id: String = "basic") -> Dictionary:
	var actor: Dictionary = active(state)
	if not actor.is_empty() and actor.status!=null and actor.status.kind in ["sleep","freeze"]: return {"ok":false,"reason":"No puede atacar mientras duerme o está congelado. Puede moverse y terminar el turno."}
	if action_id=="counter" and not actor.is_empty() and actor.get("lastDamage",0)<=0: return {"ok":false,"reason":"Contraataque necesita daño recibido desde la anterior acción."}
	var plan: Dictionary = super.attack_plan(state,target_id,origin,action_id)
	if not plan.ok: return plan
	var action: RefCounted = profile(actor).action(actor,action_id)
	var definition: Dictionary = action.definition
	for hit: Dictionary in plan.hits:
		var target: Dictionary = unit_by_id(state,int(hit.targetId))
		if definition.target=="enemy":
			hit.accuracy = clampi(int(floor(hit.accuracy*float(actor.get("accuracy",100))/float(target.get("evasion",100))))-(25 if actor.get("volatile",{}).has("confusion") else 0),5,100)
		if action_id=="whirlwind":
			var placed: Dictionary = actor.duplicate()
			placed.merge(origin,true)
			var vector: Vector2i = VECTORS[Movement.facing_from(placed,target)]
			var destination: Dictionary = {"x":target.x+vector.x,"y":target.y+vector.y}
			if not is_inf(Movement.tile_cost(state.board,destination,target.profile)) and not living(state).any(func(u):return Movement.same(u,destination)):
				hit.push = destination
				hit.pushReason = null
		if hit.targetId==target_id:
			for key: String in hit: plan[key] = hit[key]
	var damage: int = 0
	for hit: Dictionary in plan.hits: damage += hit.damage
	var recoil: int = int(floor(damage*definition.get("recoil",0)/100.0))
	if definition.get("selfKO",false): recoil = actor.hp
	if recoil>0: plan.recoil = int(plan.get("recoil",0))+recoil
	return plan

func _change(unit: Dictionary, change: Dictionary) -> void:
	var stage: int = clampi(int(unit.stages.get(change.stat,0))+int(change.stages),-2,2)
	unit.stages[change.stat] = stage
	var multiplier: float = (2.0+stage)/2.0 if stage>=0 else 2.0/(2.0-stage)
	if change.stat in ["accuracy","evasion"]: multiplier = (3.0+stage)/3.0 if stage>=0 else 3.0/(3.0-stage)
	unit[change.stat] = maxi(1,int(floor(unit.baseCombatStats[change.stat]*multiplier)))

func attack(state: Dictionary, target_id: int, action_id: String = "basic") -> Dictionary:
	var actor: Dictionary = active(state)
	var plan: Dictionary = attack_plan(state,target_id,{},action_id)
	var result: Dictionary = super.attack(state,target_id,action_id)
	if not result.ok: return result
	var holder: Dictionary = unit_by_id(result.state,int(actor.id))
	var definition: Dictionary = profile(actor).action(actor,action_id).definition
	holder.lastDamage = 0
	var damage: int = 0
	for receipt: Dictionary in result.hits:
		if not receipt.hit or receipt.get("recoil",false): continue
		var target: Dictionary = unit_by_id(result.state,int(receipt.targetId))
		if receipt.damage>0: target.lastDamage = receipt.damage
		damage += receipt.damage
		if target.hp<=0: continue
		for forecast: Dictionary in plan.hits:
			if forecast.targetId!=receipt.targetId: continue
			if forecast.get("clearStages",false):
				target.stages.clear()
				for key: String in target.baseCombatStats: target[key] = target.baseCombatStats[key]
			var affected: Dictionary = holder if forecast.get("changesSelf",false) else target
			if affected.hp>0 and not forecast.get("changes",[]).is_empty() and (definition.changeChance==100 or Rng.next(result.state)*100<definition.changeChance):
				for change: Dictionary in forecast.changes: _change(affected,change)
			if forecast.has("volatile"):
				var effect: Dictionary = forecast.volatile
				if effect.chance==100 or Rng.next(result.state)*100<effect.chance: target.volatile[effect.kind] = {"remaining":effect.duration,"source":actor.id}
	var recoil: int = mini(holder.hp,int(floor(damage*definition.get("recoil",0)/100.0)))
	if definition.get("selfKO",false): recoil = holder.hp
	if recoil>0:
		holder.hp -= recoil
		result.hits.append({"targetId":holder.id,"hit":true,"damage":recoil,"recoil":true,"moveRecoil":true})
		note(result.state,"%s pierde %d PS por el coste del movimiento." % [holder.name,recoil])
		if result.state.outcome!="playing":
			result.state.log.erase("Victoria: zona despejada." if result.state.outcome=="victory" else "Derrota: el equipo ha caído.")
			result.state.outcome = "playing"
		resolve_casualties(result.state)
		if holder.hp<=0 and result.state.outcome=="playing" and not actor.id in result.state.completed:
			result.state.completed.append(actor.id)
			if result.state.queue.is_empty(): new_round(result.state)
			else: begin_activation(result.state)
	return result

func finish(state: Dictionary, facing = null) -> Dictionary:
	var next: Dictionary = state.duplicate(true)
	var actor: Dictionary = active(next)
	if actor.is_empty(): return super.finish(state,facing)
	var special: Variant = null
	if actor.status!=null and actor.status.kind in ["sleep","freeze"]:
		special = actor.status.duplicate(true)
		actor.status = null # These states do not inflict the old burn/poison tick.
	var seed: Dictionary = actor.get("volatile",{}).get("seed",{})
	if not seed.is_empty():
		var lost: int = mini(actor.hp,maxi(1,int(actor.maxHp/8.0)))
		actor.hp -= lost
		var source: Dictionary = unit_by_id(next,int(seed.source))
		if not source.is_empty() and source.hp>0: source.hp = mini(source.maxHp,source.hp+lost)
		note(next,"%s: Drenadoras, pierde %d PS." % [actor.name,lost])
	for key: String in actor.get("volatile",{}).keys():
		actor.volatile[key].remaining -= 1
		if actor.volatile[key].remaining<=0: actor.volatile.erase(key)
	var result: Dictionary = super.finish(next,facing)
	if result.ok and special!=null and special.remaining>1:
		unit_by_id(result.state,int(actor.id)).status = {"kind":special.kind,"remaining":special.remaining-1}
	return result

func action_score(state: Dictionary, target: Dictionary, plan: Dictionary) -> float:
	var value: float = super.action_score(state,target,plan)
	if not plan.ok: return value
	for hit: Dictionary in plan.hits:
		value += hit.get("changes",[]).size()*4*hit.accuracy/100.0
		if hit.has("volatile"): value += 8*hit.volatile.chance/100.0*hit.accuracy/100.0
	value -= float(plan.get("recoil",0))*0.8
	return value
