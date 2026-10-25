extends "res://core/economy_battle.gd"

const Arenas = preload("res://core/adventure_maps.gd")
const Planner = preload("res://core/tactical_planner.gd")
var scenarios: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/adventure.json"))

func _init() -> void:
	super()
	progression = load("res://core/adventure_study.gd").new()
	catalog = progression.data
	for identity: int in profiles: profiles[identity].progression = progression

func encounter(run: Dictionary, location: Dictionary) -> Dictionary:
	var state: Dictionary = super.encounter(run,location)
	Arenas.decorate(state,location,scenarios.arenas.get(location.id,{}))
	for unit: Dictionary in state.units:
		for stat: String in unit.baseCombatStats: unit[stat] = unit.baseCombatStats[stat]
		unit.stages = {}; unit.stageTurns = {}; unit.tp = 2
		unit.combatEdition = 19
		if location.id=="route-1" and unit.team=="enemy": unit.moves = []
		var definitions: Array = profile(unit).actions_for(unit).map(func(a):return a.definition)
		unit.aiStyle = "support" if definitions.any(func(d):return d.kind=="heal") else ("skirmisher" if budget(unit)>=5 else "vanguard")
	state.round = 0; state.spatialClock = 0; state.rng = Rng.hash_seed(state.seed)
	state.log = []; state.abilityEvents = []; state.tacticalEvents = []
	new_round(state)
	return state

func new_round(state: Dictionary) -> void:
	super.new_round(state)
	state.combatEdition = 19

func start_battle(state: Dictionary) -> void:
	state.deployment = false
	for unit: Dictionary in living(state):
		if unit.get("ability")=="intimidate":
			for other: Dictionary in living(state):
				if other.team!=unit.team and Movement.distance(unit,other)<=6 and other.get("ability") not in ["clear-body","hyper-cutter"]: _change(other,{"stat":"attack","stages":-1})
			_ability(state,unit,"Intimidación: −1 Ataque a rivales cercanos")

func apply_command(state: Dictionary, command: Dictionary) -> Dictionary:
	if state.get("deployment",false): return {"ok":false,"reason":"Confirma primero el despliegue."}
	var acting: Dictionary = active(state)
	var result: Dictionary = super.apply_command(state,command)
	if not result.ok: return result
	var next: Dictionary = result.state
	if command.get("kind")=="move" and next.outcome=="playing":
		var moved: Dictionary = unit_by_id(next,int(acting.id))
		for pair: Array in next.get("arena",{}).get("portals",[]):
			var destination: Dictionary = pair[1] if Movement.same(moved,pair[0]) else pair[0] if Movement.same(moved,pair[1]) else {}
			if destination.is_empty() or _occupied(next,destination): continue
			moved.x = destination.x; moved.y = destination.y
			next.movementLocked = true; result.irreversible = true
			note(next,moved.name+" atraviesa el transportador.")
			break
	if command.get("kind")=="finish" and next.outcome=="playing":
		var unit: Dictionary = unit_by_id(next,int(acting.id))
		var mission: Dictionary = next.get("mission",{})
		if unit.team=="ally" and unit.hp>0 and mission.get("kind")=="secure":
			for point: Dictionary in mission.points:
				var key: String = Movement.key(point)
				if Movement.same(unit,point) and key not in mission.captured:
					mission.captured.append(key); note(next,"Terminal desactivado: %d / %d." % [mission.captured.size(),mission.points.size()])
		if unit.team=="enemy" and unit.hp>0 and mission.get("kind")=="protect" and mission.points.any(func(p):return Movement.distance(unit,p)<=1):
			mission.health = maxi(0,int(mission.health)-1)
			if mission.health==0: next.outcome = "defeat"; note(next,"La persona protegida ha caído.")
	_mission_result(next)
	return result

func _mission_result(state: Dictionary) -> void:
	if state.outcome!="playing" or state.get("deployment",true): return
	var mission: Dictionary = state.get("mission",{})
	var allies: Array = living(state).filter(func(u):return u.team=="ally")
	if allies.is_empty(): state.outcome = "defeat"; return
	var win: bool = false
	if mission.get("kind")=="secure": win = not mission.points.is_empty() and mission.captured.size()==mission.points.size()
	if mission.get("kind")=="protect": win = mission.health>0 and state.round>=mission.untilRound
	if mission.get("kind")=="escape": win = not mission.points.is_empty() and allies.all(func(u):return mission.points.any(func(p):return Movement.same(u,p)))
	if win: state.outcome = "victory"; note(state,"Objetivo del encuentro completado.")

func cast(state: Dictionary, aim: Dictionary, identity: String) -> Dictionary:
	var plan: Dictionary = cast_plan(state,aim,identity)
	var result: Dictionary = super.cast(state,aim,identity)
	if not result.ok: return result
	var next: Dictionary = result.state
	next.tacticalEvents = []
	for field: Dictionary in state.fields:
		if not plan.tiles.any(func(p):return Movement.same(p,field)): continue
		var replacement: String = ""
		if field.kind=="web" and plan.definition.get("type")=="fire": replacement = "fire"
		if field.kind=="fire" and plan.definition.get("extinguish",false): replacement = "mud"
		if replacement!="":
			next.fields = next.fields.filter(func(f):return not (f.kind==field.kind and Movement.same(f,field)))
			if not next.fields.any(func(f):return f.kind==replacement and Movement.same(f,field)):
				next.fields.append({"x":field.x,"y":field.y,"kind":replacement,"expires":next.round+2,"source":active(state).id,"chance":100,"zone":int(next.get("spatialZones",0))+1})
			next.tacticalEvents.append({"x":field.x,"y":field.y,"text":"Seda ardiendo" if replacement=="fire" else "Lodo"})
		elif field.kind in ["smoke","poison"] and plan.definition.get("dispel",false): next.tacticalEvents.append({"x":field.x,"y":field.y,"text":"Dispersado"})
	return result

func action_score(state: Dictionary, target: Dictionary, plan: Dictionary) -> float:
	var score: float = super.action_score(state,target,plan)
	if not plan.ok: return score
	var actor: Dictionary = active(state)
	if actor.get("aiRole","wild")=="wild": return score
	for hit: Dictionary in plan.hits:
		var victim: Dictionary = unit_by_id(state,int(hit.targetId))
		if victim.team==actor.team and (hit.damage>0 or hit.status!=null): score -= 50+hit.damage*2
		if victim.team!=actor.team and hit.damage>=victim.hp and hit.accuracy>0: score += 12
		if victim.team==actor.team and hit.heal>0: score += mini(hit.heal,victim.maxHp-victim.hp)*.2
		for change: Dictionary in hit.get("changes",[]):
			var existing: int = int(victim.get("stages",{}).get(change.stat,0))
			if (existing>=2 and change.stages>0) or (existing<=-2 and change.stages<0): score -= 20
	if actor.get("aiRole")=="leader" and plan.get("field","")!="":
		if state.fields.any(func(f):return f.kind==plan.field and plan.tiles.any(func(p):return Movement.same(p,f))): score -= 12
		else: score += 2
	if plan.recoil>=actor.hp: score -= 100
	return score

func movement_value(state: Dictionary, actor: Dictionary, point: Dictionary, enemy: Dictionary, danger: float) -> float:
	var endpoint: Dictionary = point
	for pair: Array in state.get("arena",{}).get("portals",[]):
		if Movement.same(point,pair[0]) and not _occupied(state,pair[1]): endpoint = pair[1]
		elif Movement.same(point,pair[1]) and not _occupied(state,pair[0]): endpoint = pair[0]
	var value: float = Movement.distance(endpoint,enemy)+danger
	if actor.get("aiRole","wild")=="wild": return value
	value += danger*3
	if actor.get("aiStyle")=="support":
		for ally: Dictionary in living(state):
			if ally.team==actor.team and ally.id!=actor.id and ally.hp<ally.maxHp*.7: value = minf(value,Movement.distance(endpoint,ally)+danger*4)
	elif actor.get("aiStyle")=="vanguard":
		for ally: Dictionary in living(state):
			if ally.team==actor.team and ally.id!=actor.id and ally.get("aiStyle")=="support": value += maxi(0,Movement.distance(endpoint,ally)-3)*.35
	var mission: Dictionary = state.get("mission",{})
	if mission.get("kind")=="protect" and not mission.points.is_empty(): value = minf(value,Movement.distance(point,mission.points[0])+danger)
	if actor.get("aiRole")=="leader" and state.units.any(func(u):return u.hp>0 and u.team==actor.team and u.id!=actor.id and Movement.distance(u,point)<=1): value += .5
	return value

func choose_command(state: Dictionary) -> Dictionary:
	var planner: RefCounted = Planner.new()
	planner.start(self,state)
	while not planner.complete: planner.advance(1000000)
	return planner.decision
