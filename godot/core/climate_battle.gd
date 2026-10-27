extends "res://core/sleep_battle.gd"

const Climate = preload("res://core/climate_context.gd")
const ClimateActions = preload("res://core/climate_actions.gd")
const ClimatePaths = preload("res://core/climate_movement.gd")

func _init() -> void:
	super()
	progression = preload("res://core/climate_study.gd").new(); catalog = progression.data
	var chart: Dictionary = profiles[1].library.basic.chart
	profiles.clear()
	for record: Dictionary in catalog.species:
		var pokemon: RefCounted = Profile.new(record,chart,progression)
		var basic: Dictionary = progression.BASIC.duplicate(true)
		basic.merge(progression.spatial_data.moves.basic,true)
		basic.loadoutCost = 0; basic.permanentStages = true
		pokemon.library.basic = ClimateActions.create(basic,chart)
		for identity: String in catalog.moves: pokemon.library[identity] = ClimateActions.create(catalog.moves[identity],chart)
		profiles[int(record.id)] = pokemon

func member_unit(member: Dictionary, point: Dictionary = {"x":0,"y":0}) -> Dictionary:
	var unit: Dictionary = super.member_unit(member,point)
	unit.gender = member.get("gender",Climate.gender(encounter_seed,member,progression.climate.genderRates))
	unit.nativeAbility = unit.ability
	unit.climate = {"entry":false,"forewarn":"","charmMarks":{},"reactions":{}}
	unit.combatEdition = 22
	return unit

func encounter(run: Dictionary, location: Dictionary) -> Dictionary:
	var state: Dictionary = super.encounter(run,location)
	for unit: Dictionary in state.units:
		if unit.team!="enemy" or unit.level<15: continue
		var identity: String = "sunny-day" if unit.ability in ["chlorophyll","leaf-guard"] else "rain-dance" if unit.ability in ["swift-swim","hydration","dry-skin"] else "sandstorm" if unit.ability=="sand-veil" else ""
		if identity!="" and int(unit.speciesId) in progression.climate.compatible[identity]:
			var kit: Array = [identity]+unit.moves.filter(func(m):return m!=identity).slice(0,3)
			unit.moves = Points.fit(kit,unit.level,catalog.moves)
	state.weather = {"kind":progression.climate.encounters.get(location.id,"clear"),"expires":4}
	state.round = 0; state.spatialClock = 0; state.rng = Rng.hash_seed(state.seed)
	state.log = []; state.abilityEvents = []
	state.climateActions = 0
	new_round(state)
	Climate.restore(state)
	return state

func _nearest(state: Dictionary, unit: Dictionary) -> Dictionary:
	var others: Array = living(state).filter(func(u):return u.team!=unit.team)
	others.sort_custom(func(a,b):return Movement.distance(unit,a)<Movement.distance(unit,b) if Movement.distance(unit,a)!=Movement.distance(unit,b) else a.id<b.id)
	return others[0] if not others.is_empty() else {}

func _set_ability(unit: Dictionary, identity: String) -> void:
	unit.nativeAbility = identity; unit.ability = identity
	unit.abilityName = progression.traits.abilities[identity].name
	unit.abilityDescription = progression.traits.abilities[identity].description

func entry_preview(state: Dictionary) -> Array:
	var result: Array = []
	for unit: Dictionary in living(state):
		if Climate.ability(state,unit)!="trace": continue
		var target: Dictionary = _trace_target(state,unit)
		if not target.is_empty(): result.append({"id":unit.id,"name":unit.name,"ability":progression.traits.abilities[Climate.native(target)].name})
	return result

func _trace_target(state: Dictionary, unit: Dictionary) -> Dictionary:
	var targets: Array = living(state).filter(func(u):return u.team!=unit.team and Climate.native(u) not in ["trace","neutralizing-gas"] and not u.climate.get("traced",false))
	targets.sort_custom(func(a,b):return Movement.distance(unit,a)<Movement.distance(unit,b) if Movement.distance(unit,a)!=Movement.distance(unit,b) else a.id<b.id)
	return targets[0] if not targets.is_empty() else {}

func start_battle(state: Dictionary) -> void:
	state.deployment = false
	var units: Array = living(state); units.sort_custom(func(a,b):return a.id<b.id)
	# Resolve Trace from the original roster: no copy chains or re-entry triggers.
	var traces: Array = []
	for unit: Dictionary in units:
		if unit.climate.entry or Climate.ability(state,unit)!="trace": continue
		var source: Dictionary = _trace_target(state,unit)
		if not source.is_empty(): traces.append({"unit":unit,"ability":Climate.native(source)})
	for choice: Dictionary in traces:
		_set_ability(choice.unit,choice.ability); choice.unit.climate.traced = true
		_ability(state,choice.unit,"Calco: "+choice.unit.abilityName)
	Climate.materialize(state)
	for unit: Dictionary in units:
		if unit.climate.entry: continue
		unit.climate.entry = true
		if unit.ability=="intimidate":
			for target: Dictionary in units:
				if target.team!=unit.team and Movement.distance(unit,target)<=6 and target.ability not in ["clear-body","hyper-cutter","inner-focus","oblivious"]: _enemy_changes(state,unit,target,[{"stat":"attack","stages":-1}])
			_ability(state,unit,"Intimidación")
		if unit.ability=="download":
			var nearest: Dictionary = _nearest(state,unit)
			if not nearest.is_empty(): _change(unit,{"stat":"attack" if nearest.defense<nearest.specialDefense else "specialAttack","stages":1}); _ability(state,unit,"Descarga")
		if unit.ability=="forewarn":
			var strongest: Dictionary = {}; var maximum: int = -1
			for enemy: Dictionary in units:
				if enemy.team==unit.team: continue
				for technique: RefCounted in profile(enemy).actions_for(enemy):
					var definition: Dictionary = technique.definition
					if definition.category!="status" and int(definition.get("power",0))>maximum: maximum = int(definition.get("power",0)); strongest = definition
			if not strongest.is_empty(): unit.climate.forewarn = strongest.id; _ability(state,unit,"Alerta: "+strongest.name+" · daño −25 %")
	# Entry bonuses affect the first queue, with exactly the same seeded variance.
	state.round = 0; state.spatialClock = 0; state.rng = Rng.hash_seed(state.seed)
	new_round(state)
	Climate.restore(state)

func new_round(state: Dictionary) -> void:
	state.round += 1; state.combatEdition = 22
	if state.has("weather") and state.round>=int(state.weather.expires): state.weather = {"kind":"clear","expires":0}; note(state,"El clima vuelve a despejado.")
	state.fields = state.fields.filter(func(f):return f.expires>state.round)
	var units: Array = living(state)
	for unit: Dictionary in units:
		if unit.get("dormant",false) and (state.round>=3 or unit.hp<unit.maxHp or units.any(func(u):return u.team!=unit.team and Movement.distance(u,unit)<=6)): unit.dormant = false
	units = units.filter(func(u):return not u.get("dormant",false))
	units.sort_custom(func(a,b):return a.id<b.id)
	state.initiative = []
	for unit: Dictionary in units:
		var weather_kind: String = Climate.weather(state,unit)
		var ability: String = Climate.ability(state,unit)
		var factor: int = 2 if (ability=="chlorophyll" and weather_kind=="sun") or (ability=="swift-swim" and weather_kind=="rain") else 1
		state.initiative.append({"id":unit.id,"score":unit.speed*factor*(1+(Rng.next(state)*2-1)*state.variance),"tie":Rng.next(state)})
	state.initiative.sort_custom(func(a,b):return a.score>b.score if a.score!=b.score else a.tie<b.tie if a.tie!=b.tie else a.id<b.id)
	state.queue = state.initiative.map(func(e):return e.id); state.completed = []
	for unit: Dictionary in units: unit.remaining = budget(unit)
	note(state,"Ronda %d: nueva cola de iniciativa."%state.round)
	begin_activation(state)

func begin_activation(state: Dictionary) -> void:
	Climate.materialize(state)
	var actor: Dictionary = active(state)
	super.begin_activation(state)
	if not actor.is_empty() and actor.hp>0 and active(state).get("id",0)==actor.id:
		var pressured: bool = living(state).any(func(u):return u.team!=actor.team and Climate.ability(state,u)=="pressure" and Climate.near(state,u,actor,2))
		if pressured: actor.remaining = maxi(1,int(actor.remaining)-1)
	Climate.restore(state)

func movement_routes(state: Dictionary, actor: Dictionary, maximum: float = INF) -> Dictionary:
	if asleep(actor): return {}
	return ClimatePaths.routes(state,actor,maximum)

func move(state: Dictionary, destination: Dictionary) -> Dictionary:
	var result: Dictionary = super.move(Climate.planning(state),destination)
	if result.ok: Climate.restore(result.state)
	return result

func _forecast(actor: Dictionary, target: Dictionary, action: RefCounted, side: String) -> Dictionary:
	return super._forecast(actor,target,ClimateActions.create(action.definition,profiles[1].library.basic.chart),side)

func cast_plan(state: Dictionary, aim: Dictionary, identity: String = "basic", origin: Dictionary = {}) -> Dictionary:
	var planning: Dictionary = Climate.planning(state,origin)
	var result: Dictionary = super.cast_plan(planning,aim,identity)
	if not result.ok: return result
	var actor: Dictionary = active(planning)
	if actor.ability=="magic-guard" and actor.heldItem=="life-orb" and not result.definition.get("selfKO",false): result.recoil = maxi(0,int(result.recoil)-maxi(1,int(actor.maxHp/10.0)))
	if result.definition.has("weather"):
		result.weather = result.definition.weather
		result.weatherUntil = state.round+3
		if state.get("weather",{}).get("kind","")==result.weather: return {"ok":false,"reason":"Ese clima ya está activo."}
	return result

func _spatial_forecast(state: Dictionary, actor: Dictionary, target: Dictionary, definition: Dictionary, identity: String) -> Dictionary:
	state = Climate.planning(state,actor)
	actor = unit_by_id(state,int(actor.id)); target = unit_by_id(state,int(target.id))
	var attacker: Dictionary = actor.duplicate(true)
	var defender: Dictionary = target.duplicate(true)
	if defender.get("climateWeather","")=="sand" and "rock" in defender.types and definition.category=="special":
		defender.specialDefense = maxi(1,int(floor(defender.specialDefense*1.5)))
		defender.baseCombatStats.specialDefense = maxi(1,int(floor(defender.baseCombatStats.specialDefense*1.5)))
	var hit: Dictionary = super._spatial_forecast(state,attacker,defender,definition,identity)
	if not hit.get("valid",true): return hit
	if (target.ability=="inner-focus" and definition.get("special","")=="fake-out") or (target.ability=="oblivious" and definition.get("special","")=="taunt"):
		return {"valid":false,"reason":target.abilityName+" impide ese efecto."}
	if actor.get("climateLight",false) and hit.accuracyHints.any(func(h):return h.begins_with("Humo:")):
		hit.accuracy = _precision(actor,target,definition)
		hit.accuracyHints = hit.accuracyHints.filter(func(h):return not h.begins_with("Humo:"))
		hit.accuracyHints.append("Iluminación: sin penalización de humo")
	var factor: float = 1.0
	var climate: String = actor.get("climateWeather","clear") if target.get("climateWeather","clear")!="clear" else "clear"
	if definition.category!="status" and definition.get("fixedMode","")=="" and definition.get("special","") not in ["counter","bide"]:
		if definition.type=="fire": factor *= 1.5 if climate=="sun" else .5 if climate=="rain" else 1.0
		if definition.type=="water": factor *= .5 if climate=="sun" else 1.5 if climate=="rain" else 1.0
		if target.ability=="sand-veil" and target.get("climateWeather","")=="sand" and Movement.distance(actor,target)>1 and actor.ability!="mold-breaker": factor *= .8; hit.abilityHints.append(target.abilityName)
		if target.ability=="forewarn" and target.climate.forewarn==definition.id and actor.ability!="mold-breaker": factor *= .75; hit.abilityHints.append(target.abilityName)
		var charm: Dictionary = actor.spatial.effects.get("charm",{})
		if charm.get("source",0)==target.id: factor *= .8; hit.abilityHints.append("Encanto: daño −20 %")
	for key: String in ["damage","damageMin","damageMax","normalMin","normalMax","criticalMin","criticalMax","rollNormalMin","rollNormalMax","rollCriticalMin","rollCriticalMax"]:
		if hit.get(key,0)>0: hit[key] = maxi(1,int(floor(hit[key]*factor)))
	if factor!=1: hit.abilityHints.append("Clima y habilidades: ×%.2f"%factor)
	if identity=="thunder" and climate in ["sun","rain"] and actor.ability!="no-guard" and target.ability!="no-guard": hit.accuracy = 100 if climate=="rain" else 50
	if hit.status!=null and target.ability=="leaf-guard" and target.get("climateWeather","")=="sun" and actor.ability!="mold-breaker":
		hit.status = null; hit.statusReason = "Defensa Hoja impide el estado bajo el sol."
		if definition.category=="status": return {"valid":false,"reason":hit.statusReason}
	if definition.kind=="drain":
		hit.heal = mini(actor.maxHp-actor.hp,int(hit.damage/2.0))
		if target.ability=="liquid-ooze" and actor.ability!="mold-breaker":
			hit.heal = -mini(actor.hp,int(hit.heal)); hit.abilityHints.append("Lodo Líquido: el drenaje causa daño")
	return hit

func _can_status(unit: Dictionary, kind: String) -> bool:
	if unit.get("ability")=="leaf-guard" and unit.get("climateWeather","")=="sun": return false
	return super._can_status(unit,kind)

func _give_status(unit: Dictionary, kind: String) -> void:
	if _can_status(unit,kind): super._give_status(unit,kind)

func _apply_status(unit: Dictionary, kind: String, source: Dictionary) -> void:
	var susceptible: Dictionary = unit.duplicate()
	if source.get("ability")=="mold-breaker": susceptible.ability = ""
	if _can_status(susceptible,kind): super._give_status(unit,kind)

func _displacement(state: Dictionary, actor: Dictionary, target: Dictionary, definition: Dictionary) -> Dictionary:
	if target.get("ability")=="sticky-hold" and actor.get("ability")!="mold-breaker": return {"reason":"Viscosidad impide desplazarlo."}
	return super._displacement(state,actor,target,definition)

func _zone_entry(state: Dictionary, unit: Dictionary, point: Dictionary) -> bool:
	if not state.get("climateResolving",false): Climate.materialize(state)
	if unit.ability!="magic-guard": return super._zone_entry(state,unit,point)
	var protected: Dictionary = state.duplicate()
	protected.fields = state.fields.filter(func(f):return f.kind not in ["fire","rocks"])
	var changed: bool = super._zone_entry(protected,unit,point)
	state.rng = protected.rng
	if protected.has("zoneEvents"): state.zoneEvents = protected.zoneEvents
	return changed

func _enemy_changes(state: Dictionary, source: Dictionary, target: Dictionary, changes: Array) -> void:
	var decreased: bool = false
	for change: Dictionary in changes:
		var before: int = int(target.stages.get(change.stat,0))
		_change(target,change)
		decreased = decreased or target.stages.get(change.stat,0)<before
	if decreased and source.team!=target.team and target.ability=="competitive" and target.hp>0:
		_change(target,{"stat":"specialAttack","stages":2}); _ability(state,target,"Tenacidad: +2 Ataque especial")

func _extra_hit(state: Dictionary, actor: Dictionary, target: Dictionary, definition: Dictionary, forecast: Dictionary, damage: int, critical: bool) -> void:
	super._extra_hit(state,actor,target,definition,forecast,damage,critical)
	if definition.id=="transform" and actor.id!=target.id:
		actor.nativeAbility = target.nativeAbility

func _reactions(state: Dictionary, actor: Dictionary, target: Dictionary, definition: Dictionary, damage: int, shielded: bool) -> void:
	if damage<=0 or shielded or actor.hp<=0: return
	var serial: int = int(state.get("climateActions",0))
	var contact: bool = definition.id in progression.traits.contact
	if target.ability=="cursed-body" and definition.id!="basic" and not actor.spatial.effects.has("body-ward") and actor.climate.reactions.get("cursed-body",-1)!=serial:
		actor.climate.reactions["cursed-body"] = serial
		if Rng.next(state)<.3:
			actor.spatial.effects.disable = {"move":definition.get("copiedBy",definition.id),"remaining":2}
			actor.spatial.effects["body-ward"] = {"remaining":4}
			_ability(state,target,"Cuerpo Maldito: "+definition.name+" anulado en la próxima activación")
	if contact and target.hp>0 and target.ability=="cute-charm" and actor.ability!="oblivious" and actor.get("gender","")!="" and target.get("gender","")!="" and actor.gender!=target.gender and actor.climate.reactions.get("cute-charm",-1)!=serial:
		actor.climate.reactions["cute-charm"] = serial
		if Rng.next(state)<.3:
			actor.spatial.effects.charm = {"source":target.id,"remaining":3}
			_ability(state,target,"Encanto: daño hacia el poseedor −20 % por dos activaciones")
	if contact and target.hp>0 and actor.ability=="stench" and target.ability not in ["inner-focus","sticky-hold"] and actor.climate.reactions.get("stench",-1)!=serial:
		actor.climate.reactions.stench = serial
		if Rng.next(state)<.1:
			var push: Dictionary = _displacement(state,actor,target,{"pushDistance":1})
			if push.has("destination"):
				target.merge(push.destination,true); _zone_entry(state,target,target)
				_ability(state,actor,"Hedor: empuje de una casilla")

func _special_hit(state: Dictionary, actor: Dictionary, target: Dictionary, definition: Dictionary) -> void:
	var special: String = definition.get("special","")
	if target.get("ability")=="inner-focus" and special=="fake-out": return
	if target.get("ability")=="oblivious" and special=="taunt": return
	super._special_hit(state,actor,target,definition)

func _self_special(state: Dictionary, actor: Dictionary, definition: Dictionary) -> void:
	super._self_special(state,actor,definition)
	if definition.has("weather"):
		state.weather = {"kind":definition.weather,"expires":state.round+4}
		actor.climate.lastWeatherRound = state.round
		note(state,actor.name+": "+Climate.label(state))
		Climate.materialize(state)

func action_score(state: Dictionary, target: Dictionary, plan: Dictionary) -> float:
	if plan.ok and plan.definition.has("weather"):
		if state.round-int(active(state).climate.get("lastWeatherRound",-100))<3: return 0
		var desired: String = plan.definition.weather
		var value: float = 0
		for unit: Dictionary in living(state):
			var ability: String = Climate.ability(state,unit)
			var sign_value: int = 1 if unit.team==active(state).team else -1
			if ability in (["chlorophyll","leaf-guard"] if desired=="sun" else ["swift-swim","hydration","dry-skin"] if desired=="rain" else ["sand-veil"]): value += 12*sign_value
			for action: RefCounted in profile(unit).actions_for(unit):
				if action.definition.category!="status" and action.definition.type==("fire" if desired=="sun" else "water" if desired=="rain" else "rock"): value += 3*sign_value
		return value
	return super.action_score(state,target,plan)

func cast(state: Dictionary, aim: Dictionary, identity: String) -> Dictionary:
	var plan: Dictionary = cast_plan(state,aim,identity)
	if not plan.ok: return plan
	var next: Dictionary = state.duplicate(true)
	Climate.materialize(next)
	next.climateActions = int(next.get("climateActions",0))+1
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
	note(next,"%s usa %s." % [actor.name,definition.name])
	var hits: Array = []
	var total_damage: int = 0
	if definition.get("breakScreen",false): _clear_fields(next,Geometry.segment(actor,aim),["reflect","light-screen","wall"])
	if actor.hp>0:
		next.climateResolving = true
		for forecast: Dictionary in plan.hits:
			if actor.hp<=0: break
			var receipt: Dictionary = _resolve_hit(next,actor,forecast,definition)
			hits.append(receipt)
			total_damage += int(receipt.damage)
			if receipt.hit and not receipt.get("shielded",false) and forecast.multiplier!=0: _special_hit(next,actor,unit_by_id(next,int(receipt.targetId)),definition)
		next.climateResolving = false
		if definition.get("special","")=="teleport":
			actor.merge({"x":aim.x,"y":aim.y},true)
			_zone_entry(next,actor,actor)
		if definition.get("field","")!="": _place_field(next,actor,plan)
		if definition.get("dispel",false): _clear_fields(next,plan.tiles,["smoke","poison"])
		if definition.get("extinguish",false): _clear_fields(next,plan.tiles,["fire"])
		if definition.get("retreat",false): _retreat(next,actor)
		if definition.get("special","")=="pay-day" and not next.get("payDay",false): next.payDay = true
		_self_special(next,actor,definition)
	actor.tp = 0; actor.maxTp = 0
	var recoil: int = int(floor(total_damage*definition.get("recoil",0)/100.0)) if actor.get("ability")!="rock-head" else 0
	if definition.get("selfKO",false): recoil = actor.hp
	if actor.get("heldItem")=="life-orb" and actor.get("ability")!="magic-guard" and total_damage>0: recoil += maxi(1,int(actor.maxHp/10.0))
	if recoil>0:
		recoil = mini(actor.hp,recoil)
		actor.hp -= recoil
		hits.append({"targetId":actor.id,"hit":true,"damage":recoil,"recoil":true,"moveRecoil":true})
	actor.spatial.lastMove = definition.id
	if definition.category!="status": actor.spatial.attacks += 1
	actor.spatial.lastPhysical = 0
	actor.spatial.lastSpecial = 0
	actor.spatial.effects.erase("help")
	# Preserve the existing fire/web/water terrain reactions.
	for field: Dictionary in state.fields:
		if not plan.tiles.any(func(p):return Movement.same(p,field)): continue
		var replacement: String = "fire" if field.kind=="web" and definition.type=="fire" else "mud" if field.kind=="fire" and definition.get("extinguish",false) else ""
		if replacement!="":
			next.fields = next.fields.filter(func(f):return not (f.kind==field.kind and Movement.same(f,field)))
			if not next.fields.any(func(f):return f.kind==replacement and Movement.same(f,field)): next.fields.append({"x":field.x,"y":field.y,"kind":replacement,"expires":next.round+2,"source":actor.id,"chance":100,"zone":int(next.get("spatialZones",0))+1})
	_advance_after_casualties(next)
	next.erase("climateResolving")
	Climate.restore(next)
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
	if definition.kind=="drain" and target.ability=="liquid-ooze" and actor.ability!="mold-breaker":
		heal = -mini(healed.hp,heal)
	if healed.hp>0: healed.hp = clampi(healed.hp+heal,0,int(healed.maxHp))
	if forecast.guard: target.guarded = true
	if forecast.get("focus",false): actor.volatile.focus = {"remaining":3,"source":actor.id}
	if target.hp>0 and not shielded:
		if forecast.status!=null and (forecast.status.chance==100 or Rng.next(state)*100<forecast.status.chance): _apply_status(target,forecast.status.kind,actor)
		if forecast.status!=null and target.status!=null: target.status.remaining = int(definition.get("statusDuration",3))
		if forecast.has("randomStatus") and target.status==null and Rng.next(state)*100<forecast.randomStatus.chance:
			var kinds: Array = forecast.randomStatus.kinds
			var kind: String = kinds[int(floor(Rng.next(state)*kinds.size()))]
			var susceptible: Dictionary = target.duplicate(true)
			if actor.get("ability")=="mold-breaker": susceptible.ability = ""
			if _can_status(susceptible,kind) and not (kind=="freeze" and target.spatial.effects.has("immunity")):
				_apply_status(target,kind,actor)
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
			_enemy_changes(state,actor,affected,forecast.get("changes",[]))
	if amount>0 and forecast.staticChance>0 and actor.hp>0 and actor.status==null and Rng.next(state)<forecast.staticChance: _give_status(actor,"paralysis")
	_extra_hit(state,actor,target,definition,forecast,amount,critical)
	var reaction_origin: Dictionary = {"x":target.x,"y":target.y}
	_reactions(state,actor,target,definition,amount,shielded)
	var receipt: Dictionary = {"targetId":target.id,"hit":true,"damage":amount,"heal":heal,"critical":critical,"shielded":shielded}
	if forecast.push!=null or not Movement.same(reaction_origin,target): receipt.push = {"x":target.x,"y":target.y}
	note(state,"%s: %d PS%s." % [target.name,amount," · CRÍTICO" if critical else ""])
	return receipt

func finish(state: Dictionary, facing: Variant = null) -> Dictionary:
	if active(state).is_empty(): return {"ok":false,"reason":"El combate ha terminado."}
	if facing!=null and (not (facing is int or facing is float) or facing!=int(facing) or int(facing) not in FACINGS): return {"ok":false,"reason":"Orientación no válida."}
	var next: Dictionary = state.duplicate(true)
	next.zoneEvents = []
	next.abilityEvents = []
	Climate.materialize(next)
	var actor: Dictionary = active(next)
	actor.stageTurns.clear()
	preload("res://core/restorative_tiles.gd").cure(next,actor)
	var focus: Dictionary = actor.volatile.get("focus",{}).duplicate(true)
	actor.volatile.erase("focus")
	if facing!=null: actor.facing = int(facing)
	if actor.get("ability")=="shed-skin" and actor.status!=null and Rng.next(next)<1.0/3.0:
		actor.status = null
		_ability(next,actor,"cura su estado principal")
	if actor.hp>0 and ((actor.ability=="hydration" and actor.climateWeather=="rain") or (actor.ability=="natural-cure" and not state.acted)) and actor.status!=null:
		actor.status = null; _ability(next,actor,"cura su estado principal")
	var old_status: String = "" if actor.status==null else actor.status.kind
	if actor.status!=null:
		if actor.ability!="magic-guard" and actor.status.kind in ["burn","poison"]: actor.hp = maxi(0,int(actor.hp)-maxi(1,int(actor.maxHp/(8.0 if actor.status.kind=="poison" else 16.0))))
		actor.status.remaining -= 2 if actor.ability=="early-bird" and actor.status.kind=="sleep" else 1
		if actor.status.remaining<=0: actor.status = null
	if old_status in ["sleep","freeze"] and actor.status==null: actor.spatial.effects.immunity = {"remaining":2}
	var seed_effect: Dictionary = actor.volatile.get("seed",{})
	if not seed_effect.is_empty() and actor.ability!="magic-guard":
		var lost: int = mini(actor.hp,maxi(1,int(actor.maxHp/8.0)))
		actor.hp -= lost
		var beneficiary: Dictionary = unit_by_id(next,int(seed_effect.source))
		if not beneficiary.is_empty() and beneficiary.hp>0:
			var grant: int = mini(beneficiary.maxHp-beneficiary.hp,lost)
			if actor.ability=="liquid-ooze": beneficiary.hp = maxi(0,int(beneficiary.hp)-grant)
			else: beneficiary.hp += grant
	var local_weather: String = actor.climateWeather
	if actor.hp>0 and actor.ability=="dry-skin" and local_weather in ["sun","rain"]:
		var amount: int = maxi(1,int(actor.maxHp/8.0))
		actor.hp = mini(int(actor.maxHp),int(actor.hp)+amount) if local_weather=="rain" else maxi(0,int(actor.hp)-amount)
	if actor.hp>0 and local_weather=="sand" and actor.ability not in ["magic-guard","sand-veil"] and not actor.types.any(func(t):return t in ["rock","ground","steel"]): actor.hp = maxi(0,int(actor.hp)-maxi(1,int(actor.maxHp/16.0)))
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
	if not focus.is_empty(): actor.volatile.focus = focus
	next.completed.append(actor.id)
	next.queue = next.queue.slice(1)
	next.moved = false
	next.acted = false
	resolve_casualties(next)
	if next.outcome=="playing":
		if next.queue.is_empty(): new_round(next)
		else: begin_activation(next)
	Climate.restore(next)
	return {"ok":true,"state":next}


func _retreat(state: Dictionary, actor: Dictionary) -> void:
	if actor.remaining<1: return
	var vector: Vector2i = -VECTORS[int(actor.facing)]
	var destination: Dictionary = {"x":actor.x+vector.x,"y":actor.y+vector.y}
	var route: Dictionary = movement_routes(state,actor,actor.remaining).get(Movement.key(destination),{})
	if route.is_empty() or route.path.size()!=2: return
	actor.merge(destination,true); actor.remaining -= route.cost
	_zone_entry(state,actor,destination)
