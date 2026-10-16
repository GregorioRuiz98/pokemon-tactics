extends "res://core/tactics_battle.gd"

const TraitStudy = preload("res://core/traits_study.gd")
const TraitActions = preload("res://core/traits_actions.gd")
var encounter_seed: String = ""

func _init() -> void:
	super()
	progression = TraitStudy.new()
	catalog = progression.data
	var chart: Dictionary = profiles[1].library.basic.chart
	profiles.clear()
	for record: Dictionary in catalog.species:
		var pokemon: RefCounted = Profile.new(record,chart,progression)
		pokemon.library.basic = TraitActions.create(progression.BASIC,chart)
		for identity: String in catalog.moves: pokemon.library[identity] = TraitActions.create(catalog.moves[identity],chart)
		profiles[int(record.id)] = pokemon
	data.species = catalog.species

func member_unit(member: Dictionary, point: Dictionary = {"x":0,"y":0}) -> Dictionary:
	var copy: Dictionary = member.duplicate(true)
	if int(copy.id)>=10000 and encounter_seed!="": progression.assign(copy,encounter_seed)
	var unit: Dictionary = super.member_unit(copy,point)
	unit.merge(progression.member_stats(copy),true)
	for key: String in progression.STAT_KEYS: unit.baseCombatStats[key] = unit[key]
	unit.nature = copy.get("nature","hardy")
	unit.mint = copy.get("mint")
	unit.abilitySlot = copy.get("abilitySlot",1)
	unit.ability = progression.ability(copy)
	unit.natureText = progression.nature_text(copy)
	unit.abilityName = progression.traits.abilities[unit.ability].name
	unit.abilityDescription = progression.traits.abilities[unit.ability].description
	unit.combatEdition = 10
	return unit

func encounter(run: Dictionary, location: Dictionary) -> Dictionary:
	encounter_seed = run.seed+"/"+location.id
	var state: Dictionary = super.encounter(run,location)
	encounter_seed = ""
	state.abilityEvents = []
	return state

func new_round(state: Dictionary) -> void:
	super.new_round(state)
	state.combatEdition = 10

func _precision(actor: Dictionary, target: Dictionary, definition: Dictionary) -> int:
	if definition.get("neverMiss",false) or definition.target=="self": return 100
	var evade: int = int(target.stages.get("evasion",0))
	if actor.get("ability")=="keen-eye": evade = mini(0,evade)
	var stage: int = clampi(int(actor.stages.get("accuracy",0))-evade,-6,6)
	var factor: float = (3.0+stage)/3.0 if stage>=0 else 3.0/(3.0-stage)
	if actor.get("ability")=="compound-eyes": factor *= 1.3
	if target.get("ability")=="tangled-feet" and target.get("volatile",{}).has("confusion"): factor *= 0.5
	return clampi(int(floor(definition.accuracy*factor))-(25 if actor.get("volatile",{}).has("confusion") else 0),0,100)

func _forecast(actor: Dictionary, target: Dictionary, action: RefCounted, side: String) -> Dictionary:
	var hit: Dictionary = super._forecast(actor,target,action,side)
	hit.accuracyHints = []
	if not action.definition.get("neverMiss",false) and action.definition.target!="self":
		if actor.get("ability")=="compound-eyes": hit.accuracyHints.append(actor.abilityName)
		if actor.get("ability")=="keen-eye" and target.stages.get("evasion",0)>0: hit.accuracyHints.append(actor.abilityName)
		if target.get("ability")=="tangled-feet" and target.volatile.has("confusion"): hit.accuracyHints.append(target.abilityName)
	for prefix: String in ["normal","critical"]:
		for suffix: String in ["Min","Max"]: hit["roll"+prefix.capitalize()+suffix] = hit[prefix+suffix]
	hit.sturdy = false
	if target.get("ability")=="sturdy" and target.hp==target.maxHp and maxi(hit.normalMax,hit.criticalMax)>=target.hp:
		hit.sturdy = true
		for key: String in ["normalMin","normalMax","criticalMin","criticalMax","damageMin","damageMax","damage"]: hit[key] = mini(int(hit[key]),maxi(0,int(target.hp)-1))
	if action.definition.kind=="drain": hit.heal = mini(actor.maxHp-actor.hp,int(hit.damage/2.0))
	hit.staticChance = 0.3 if target.get("ability")=="static" and action.definition.id in progression.traits.contact and actor.status==null and "electric" not in actor.types and hit.multiplier!=0 else 0.0
	return hit

func attack_plan(state: Dictionary, target_id: int, origin: Dictionary = {}, action_id: String = "basic") -> Dictionary:
	var plan: Dictionary = super.attack_plan(state,target_id,origin,action_id)
	if not plan.ok: return plan
	var actor: Dictionary = active(state)
	var definition: Dictionary = profile(actor).action(actor,action_id).definition
	if actor.get("ability")=="rock-head" and not definition.get("selfKO",false):
		var damage: int = 0
		for hit: Dictionary in plan.hits: damage += maxi(hit.damageMax,mini(unit_by_id(state,int(hit.targetId)).hp,hit.criticalMax))
		plan.recoil = maxi(0,int(plan.recoil)-int(floor(damage*definition.get("recoil",0)/100.0)))
	return plan

func _ability(state: Dictionary, unit: Dictionary, effect: String) -> void:
	if not state.has("abilityEvents"): state.abilityEvents = []
	var entry: Dictionary = {"targetId":unit.id,"name":unit.abilityName,"effect":effect}
	if state.abilityEvents.any(func(event):return event==entry): return
	state.abilityEvents.append(entry)
	note(state,"%s · %s: %s" % [unit.name,unit.abilityName,effect])

func _announce(state: Dictionary, actor: Dictionary, target: Dictionary, names: Array) -> void:
	for name: String in names:
		_ability(state,actor if actor.get("abilityName")==name else target,"modifica el movimiento")

# Edition10 owns the resolver: reactive abilities must occur before KO/queue resolution.
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
		if target.get("ability")=="sturdy" and target.hp==target.maxHp and damage>=target.hp:
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

func finish(state: Dictionary, facing: Variant = null) -> Dictionary:
	var next: Dictionary = state.duplicate(true)
	next.abilityEvents = []
	var actor: Dictionary = active(next)
	if not actor.is_empty() and actor.get("ability")=="shed-skin" and actor.status!=null and Rng.next(next)<1.0/3.0:
		actor.status = null
		_ability(next,actor,"cura su estado principal")
	return super.finish(next,facing)

func apply_command(state: Dictionary, command: Dictionary) -> Dictionary:
	var next: Dictionary = state.duplicate(true)
	next.abilityEvents = []
	return super.apply_command(next,command)
