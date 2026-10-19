extends "res://core/scale_battle.gd"

const ExpandedStudy = preload("res://core/expedition_study.gd")
const ExpandedActions = preload("res://core/expedition_actions.gd")
const ExpandedMaps = preload("res://core/expedition_maps.gd")

func _init() -> void:
	super()
	progression = ExpandedStudy.new()
	catalog = progression.data
	var chart: Dictionary = profiles[1].library.basic.chart
	profiles.clear()
	for record: Dictionary in catalog.species:
		var pokemon: RefCounted = Profile.new(record,chart,progression)
		pokemon.library.basic = ExpandedActions.create(progression.BASIC,chart)
		for identity: String in catalog.moves: pokemon.library[identity] = ExpandedActions.create(catalog.moves[identity],chart)
		profiles[int(record.id)] = pokemon
	data.species = catalog.species

func new_round(state: Dictionary) -> void:
	super.new_round(state)
	state.combatEdition = 13

func encounter(run: Dictionary, location: Dictionary) -> Dictionary:
	encounter_seed = run.seed+"/"+location.id
	var map: Dictionary = ExpandedMaps.layout(location.get("biome","route"),int(run.mapSize))
	var units: Array = []
	for member: Dictionary in run.party:
		if member.hp>0: units.append(member_unit(member,map.allies[units.size()]))
	var team: Array = location.get("team",[]).duplicate(true)
	if location.has("rivalTeams"): team = location.rivalTeams[{1:2,4:0,7:1}[int(run.starter)]].duplicate(true)
	if team.is_empty():
		var generation: Dictionary = {"rng":Rng.hash_seed(encounter_seed+"/lgpe-wild")}
		var pool: Array = catalog.encounters[location.captureTable].filter(func(e):return not e.special)
		for index: int in int(location.get("count",3)):
			var entry: Dictionary = pool[int(floor(Rng.next(generation)*pool.size()))]
			team.append({"speciesId":entry.speciesId,"level":int(entry.minLevel)+int(floor(Rng.next(generation)*(entry.maxLevel-entry.minLevel+1)))})
	for index: int in team.size():
		var member: Dictionary = progression.create_member(10000+int(run.stage)*10+index,int(team[index].speciesId),location.name,int(team[index].level))
		var enemy: Dictionary = member_unit(member,map.enemies[index])
		enemy.team = "enemy"
		enemy.facing = 0
		enemy.dormant = (location.id=="forest" and index==2) or (index>=4 and not location.get("leader",false) and not location.get("finale",false))
		units.append(enemy)
	encounter_seed = ""
	var state: Dictionary = {"seed":run.seed+"/"+location.id,"rng":Rng.hash_seed(run.seed+"/"+location.id),"variance":0.05,"composition":"kanto","round":0,"board":map.board,"heights":map.heights,"mapSize":run.mapSize,"fields":[],"units":units,"initiative":[],"queue":[],"completed":[],"moved":false,"acted":false,"outcome":"playing","log":[],"biome":location.get("biome","route"),"abilityEvents":[]}
	new_round(state)
	for unit: Dictionary in living(state):
		if unit.get("ability")=="intimidate":
			for other: Dictionary in living(state):
				if other.team!=unit.team and Movement.distance(unit,other)<=6 and other.get("ability") not in ["clear-body","hyper-cutter"]: _change(other,{"stat":"attack","stages":-1})
			_ability(state,unit,"Intimidación: −1 Ataque a rivales a seis casillas, temporal")
	return state

func _precision(actor: Dictionary, target: Dictionary, definition: Dictionary) -> int:
	if actor.get("ability")=="no-guard" or target.get("ability")=="no-guard": return 100
	return super._precision(actor,target,definition)

func _forecast(actor: Dictionary, target: Dictionary, action: RefCounted, side: String) -> Dictionary:
	var defender: Dictionary = target.duplicate(true)
	if actor.get("ability")=="mold-breaker": defender.ability = ""
	var hit: Dictionary = super._forecast(actor,defender,action,side)
	if target.get("ability") in ["battle-armor","shell-armor"] and actor.get("ability")!="mold-breaker":
		hit.criticalChance = 0.0
		hit.damageMin = mini(target.hp,int(hit.normalMin))
		hit.damageMax = mini(target.hp,int(hit.normalMax))
	return hit

func attack_plan(state: Dictionary, target_id: int, origin: Dictionary = {}, action_id: String = "basic") -> Dictionary:
	var plan: Dictionary = super.attack_plan(state,target_id,origin,action_id)
	if not plan.ok: return plan
	var actor: Dictionary = active(state)
	var definition: Dictionary = profile(actor).action(actor,action_id).definition
	if action_id=="rest" and actor.get("ability") in ["insomnia","vital-spirit"]: return {"ok":false,"reason":"Su habilidad impide dormirse; Descanso no se puede usar."}
	if definition.get("selfKO",false) and living(state).any(func(u):return u.get("ability")=="damp"): return {"ok":false,"reason":"Humedad impide la autodestrucción."}
	if action_id=="dream-eater" and (unit_by_id(state,target_id).status==null or unit_by_id(state,target_id).status.kind!="sleep"): return {"ok":false,"reason":"Come Sueños requiere un objetivo dormido."}
	if definition.target=="enemy" and unit_by_id(state,target_id).get("ability")=="pressure":
		plan.cost = mini(5,int(plan.cost)+1)
		if actor.tp<plan.cost: return {"ok":false,"reason":"Presión aumenta el coste a %d PT." % plan.cost}
	return plan

func _extra_hit(state: Dictionary, actor: Dictionary, target: Dictionary, definition: Dictionary, forecast: Dictionary, damage: int, critical: bool) -> void:
	var absorbed: String = forecast.get("absorb","")
	if absorbed in ["water-absorb","dry-skin","volt-absorb"]: target.hp = mini(target.maxHp,target.hp+maxi(1,int(target.maxHp/4.0)))
	if absorbed=="lightning-rod": _change(target,{"stat":"specialAttack","stages":1})
	if absorbed=="flash-fire": _change(target,{"stat":"specialAttack","stages":1})
	if definition.id=="rest" and actor.hp>0: actor.status = {"kind":"sleep","remaining":3}
	if definition.id=="transform" and actor.id!=target.id:
		for key: String in ["speciesId","types","attack","defense","specialAttack","specialDefense","speed","baseCombatStats","ability","abilityName","abilityDescription","profile","moves"]: actor[key] = target[key].duplicate(true) if target[key] is Array or target[key] is Dictionary else target[key]
		_ability(state,actor,"Transformación hasta finalizar el combate; PS originales")
	if damage>0 and actor.hp>0 and target.hp>0 and definition.id in progression.traits.contact:
		var effects: Dictionary = {"poison-point":"poison","flame-body":"burn","effect-spore":"sleep"}
		var kind: String = effects.get(target.get("ability",""),"")
		if kind!="" and _can_status(actor,kind) and Rng.next(state)<0.3: _give_status(actor,kind)
	if damage>0 and target.get("ability")=="anger-point" and target.hp>0 and critical: _change(target,{"stat":"attack","stages":2})
	if forecast.status!=null and target.get("ability")=="synchronize" and actor.hp>0 and actor.status==null and target.status!=null and target.status.kind in ["poison","burn","paralysis"]:
		if _can_status(actor,target.status.kind): _give_status(actor,target.status.kind)

func _can_status(unit: Dictionary, kind: String) -> bool:
	if unit.status!=null: return false
	var immune_types: Dictionary = {"poison":["poison","steel"],"burn":["fire"],"freeze":["ice"],"paralysis":["electric"]}
	var immune_abilities: Dictionary = {"poison":["immunity"],"burn":["water-veil"],"freeze":["magma-armor"],"paralysis":["limber"],"sleep":["insomnia","vital-spirit"]}
	return not unit.types.any(func(t):return t in immune_types.get(kind,[])) and unit.get("ability","") not in immune_abilities.get(kind,[])

func _give_status(unit: Dictionary, kind: String) -> void:
	var spent: int = maxi(0,budget(unit)-int(unit.remaining))
	unit.status = {"kind":kind,"remaining":3}
	unit.remaining = maxi(0,budget(unit)-spent)


# Frozen-edition resolver reused, with expansion hooks before casualty resolution.
func attack(state: Dictionary, target_id: int, action_id: String = "basic") -> Dictionary:
	var plan: Dictionary = attack_plan(state,target_id,{},action_id)
	if not plan.ok: return plan
	var next: Dictionary = state.duplicate(true)
	next.abilityEvents = []
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
		_announce(next,actor,target,forecast.get("accuracyHints",[]))
		var landed: bool = forecast.accuracy==100 or (forecast.accuracy>0 and Rng.next(next)*100<forecast.accuracy)
		if not landed:
			hits.append({"targetId":target.id,"hit":false,"damage":0})
			note(next,"%s: el ataque falla (%d %%)." % [target.name,forecast.accuracy])
			continue
		_announce(next,actor,target,forecast.get("abilityHints",[]))
		var critical: bool = forecast.criticalChance==1 or (forecast.criticalChance>0 and Rng.next(next)<forecast.criticalChance)
		var damage: int = _roll(next,int(forecast["rollCriticalMin" if critical else "rollNormalMin"]),int(forecast["rollCriticalMax" if critical else "rollNormalMax"]))
		if target.get("ability")=="sturdy" and actor.get("ability")!="mold-breaker" and target.hp==target.maxHp and damage>=target.hp:
			damage = maxi(0,int(target.hp)-1)
			_ability(next,target,"resiste con 1 PS")
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
		if damage>0 and forecast.staticChance>0 and actor.hp>0 and actor.status==null and Rng.next(next)<forecast.staticChance:
			var spent: int = maxi(0,budget(actor)-int(actor.remaining))
			actor.status = {"kind":"paralysis","remaining":3}
			actor.remaining = maxi(0,budget(actor)-spent)
			_ability(next,target,"paraliza al atacante por contacto")
		_extra_hit(next,actor,target,definition,forecast,damage,critical)
		var receipt: Dictionary = {"targetId":target.id,"hit":true,"damage":damage,"heal":heal,"critical":critical}
		if forecast.push!=null and target.hp>0: receipt.push = forecast.push
		hits.append(receipt)
		note(next,"%s: %d PS%s%s." % [target.name,damage," · CRÍTICO" if critical else "",", fuera de combate" if target.hp<=0 else ""])
	var move_recoil: int = int(floor(total_damage*definition.get("recoil",0)/100.0))
	if actor.get("ability")=="rock-head" and move_recoil>0 and not definition.get("selfKO",false):
		move_recoil = 0
		_ability(next,actor,"evita el retroceso del movimiento")
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
