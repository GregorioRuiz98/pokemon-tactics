extends "res://core/review_battle.gd"

const Opening = preload("res://core/tactics_opening.gd")

func member_unit(member: Dictionary, point: Dictionary = {"x":0,"y":0}) -> Dictionary:
	var unit: Dictionary = super.member_unit(member,point)
	unit.combatEdition = 24
	return unit

func encounter(run: Dictionary, location: Dictionary) -> Dictionary:
	var state: Dictionary = super.encounter(run,location)
	Opening.apply(state,location.id)
	if state.has("tacticalDesign"): Restorative.place(state,self)
	state.combatEdition = 24
	return state

func new_round(state: Dictionary) -> void:
	if int(state.get("round",0))==0: state.erase("tacticalMemory")
	super.new_round(state)
	state.combatEdition = 24
	# No cap on healing: this memory only informs the opponent's decisions.
	var signature: Array = []
	for unit: Dictionary in state.units:
		var stages: Dictionary = {}
		for attribute: String in unit.get("stages",{}): stages[attribute] = int(unit.stages[attribute])
		signature.append([int(unit.id),int(unit.hp),int(unit.x),int(unit.y),stages])
	var fingerprint: String = JSON.stringify(signature,"",true,true)
	var memory: Dictionary = state.get("tacticalMemory",{})
	var lowest: Dictionary = memory.get("lowest",{}).duplicate()
	var progress: Dictionary = {"ally":false,"enemy":false}
	for unit: Dictionary in state.units:
		var key: String = str(int(unit.id))
		var previous: int = int(lowest.get(key,unit.hp))
		if int(unit.hp)<previous: progress[unit.team] = true
		lowest[key] = mini(previous,int(unit.hp))
	var recovery: Dictionary = {}
	for team: String in ["ally","enemy"]:
		recovery[team] = 0 if memory.is_empty() or progress[team] else int(memory.get("recoveryStall",{}).get(team,0))+1
	state.tacticalMemory = {"position":fingerprint,"lowest":lowest,"recoveryStall":recovery,"stalled":mini(recovery.ally,recovery.enemy)}

func recovery_stalled(state: Dictionary, actor: Dictionary) -> bool:
	var memory: Dictionary = state.get("tacticalMemory",{})
	return int(memory.get("recoveryStall",{}).get(actor.team,memory.get("stalled",0)))>=3

func action_score(state: Dictionary, target: Dictionary, plan: Dictionary) -> float:
	var value: float = super.action_score(state,target,plan)
	if not plan.ok: return value
	var actor: Dictionary = active(state)
	if actor.get("aiRole","wild")=="wild" and state.get("teamStrategy","wild")=="wild": return value
	var strategy: String = state.get("teamStrategy","")
	var offensive: bool = false
	var recovery: bool = false
	for hit: Dictionary in plan.hits:
		var victim: Dictionary = unit_by_id(state,int(hit.targetId))
		if victim.team!=actor.team and hit.damage>0:
			offensive = true
			# Focus exposed targets and exploit control already applied by a teammate.
			value += (1.0-float(victim.hp)/maxi(1,int(victim.maxHp)))*6.0
			if victim.status!=null: value += 2.0
			if strategy=="focus": value += (1.0-float(victim.hp)/maxi(1,int(victim.maxHp)))*3
		if hit.heal>0: recovery = true
		if strategy=="control" and victim.team!=actor.team and victim.status==null and hit.status!=null: value += 3
	if recovery and not offensive and recovery_stalled(state,actor): return 0.0
	return value

func movement_value(state: Dictionary, actor: Dictionary, point: Dictionary, enemy: Dictionary, danger: float) -> float:
	var value: float = super.movement_value(state,actor,point,enemy,danger)
	if actor.get("aiRole","wild")=="wild" and state.get("teamStrategy","wild")=="wild": return value
	var stalled: bool = recovery_stalled(state,actor)
	var fraction: float = float(actor.hp)/maxi(1,int(actor.maxHp))
	if not stalled and fraction<0.4: value += danger*5
	var strategy: String = state.get("teamStrategy","")
	if strategy in ["mobile","ranged"] and Movement.distance(point,enemy)<=1: value += danger+1.5
	if strategy=="formation":
		var partners: Array = living(state).filter(func(u):return u.team==actor.team and u.id!=actor.id)
		if not partners.is_empty():
			var closest: int = 999
			for partner: Dictionary in partners: closest = mini(closest,Movement.distance(point,partner))
			value += maxi(0,closest-3)*0.5
	# A companion on the opposite flank creates an approach worth considering.
	for ally: Dictionary in living(state):
		if ally.team!=actor.team or ally.id==actor.id: continue
		if Movement.distance(ally,enemy)<=2 and Movement.distance(point,enemy)<=2:
			var opposite: bool = (int(ally.x)-int(enemy.x))*(int(point.x)-int(enemy.x))<0 or (int(ally.y)-int(enemy.y))*(int(point.y)-int(enemy.y))<0
			if opposite: value -= 0.75
		if actor.get("aiStyle")=="support" and ally.hp<ally.maxHp*0.7:
			value = minf(value,Movement.distance(point,ally)+danger*4)
	return value
