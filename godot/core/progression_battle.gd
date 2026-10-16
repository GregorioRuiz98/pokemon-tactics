extends "res://core/kanto_battle.gd"

const Study = preload("res://core/progression.gd")
const Profile = preload("res://core/progression_pokemon.gd")
var progression: Study = Study.new()

func _init() -> void:
	super()
	catalog = progression.data
	var chart: Dictionary = {"typeless":{}}
	for a: int in data.types.size():
		chart[data.types[a]] = {}
		chart.typeless[data.types[a]] = 1
		for b: int in data.types.size(): chart[data.types[a]][data.types[b]] = data.typeChart[a][b]
	for record: Dictionary in catalog.species: profiles[int(record.id)] = Profile.new(record,chart,progression)
	data.species = catalog.species

func member_unit(member: Dictionary, point: Dictionary = {"x":0,"y":0}) -> Dictionary:
	var unit: Dictionary = profiles[int(member.speciesId)].create_unit(int(member.id),"ally",point,"current")
	unit.merge(progression.stats(int(member.speciesId),int(member.level)),true)
	unit.level = member.level
	unit.hp = mini(member.hp,unit.maxHp)
	unit.moves = member.moves.duplicate()
	for key: String in progression.STAT_KEYS: unit.baseCombatStats[key] = unit[key]
	return unit

func encounter(run: Dictionary, location: Dictionary) -> Dictionary:
	var units: Array = []
	var starts: Array = [{"x":2,"y":7},{"x":1,"y":8},{"x":3,"y":8},{"x":1,"y":7},{"x":3,"y":7},{"x":2,"y":8}]
	for member: Dictionary in run.party:
		if member.hp > 0: units.append(member_unit(member,starts[units.size()]))
	for i: int in location.enemies.size():
		var level: int = catalog.enemyLevels[int(run.stage)][i]
		var member: Dictionary = progression.create_member(10000 + int(run.stage)*10+i,int(location.enemies[i]),"",level)
		var enemy: Dictionary = member_unit(member,{"x":7+(i%2)*2,"y":2+(i>>1)})
		enemy.team = "enemy"
		enemy.facing = 0
		# A free neutral basic plus the moves unlocked at that level, same rules as allies.
		units.append(enemy)
	var battle: Dictionary = {"seed":run.seed+"/"+location.id,"rng":Rng.hash_seed(run.seed+"/"+location.id),"variance":0.05,"composition":"kanto","round":0,"board":location.board.duplicate(true),"fields":[],"units":units,"initiative":[],"queue":[],"completed":[],"moved":false,"acted":false,"outcome":"playing","log":[],"biome":location.id}
	new_round(battle)
	return battle

func attack(state: Dictionary, target_id: int, action_id: String = "basic") -> Dictionary:
	var plan: Dictionary = attack_plan(state,target_id,{},action_id)
	var result: Dictionary = super.attack(state,target_id,action_id)
	if not result.ok: return result
	for receipt: Dictionary in result.hits:
		if not receipt.hit: continue
		var target: Dictionary = unit_by_id(result.state,int(receipt.targetId))
		if target.hp <= 0: continue
		for forecast: Dictionary in plan.hits:
			if forecast.targetId != receipt.targetId or not forecast.has("statChange"): continue
			var change: Dictionary = forecast.statChange
			var stage: int = clampi(int(target.stages.get(change.stat,0)) + int(change.stages),-2,2)
			target.stages[change.stat] = stage
			var multiplier: float = (2.0 + stage)/2.0 if stage >= 0 else 2.0/(2.0-stage)
			target[change.stat] = maxi(1,int(floor(target.baseCombatStats[change.stat]*multiplier)))
			note(result.state,"%s: %s %s%d." % [target.name,progression.STAT_NAMES.get(change.stat,change.stat),"+" if change.stages>0 else "",change.stages])
	return result

func action_score(state: Dictionary, target: Dictionary, plan: Dictionary) -> float:
	var result: float = super.action_score(state,target,plan)
	if not plan.ok: return result
	for forecast: Dictionary in plan.hits:
		if forecast.has("statChange"):
			var affected: Dictionary = unit_by_id(state,int(forecast.targetId))
			var change: Dictionary = forecast.statChange
			var current: int = affected.get("stages",{}).get(change.stat,0)
			if current != clampi(current + int(change.stages),-2,2):
				var nearby: bool = living(state).any(func(u):return u.team != affected.team and Movement.distance(u,affected)<=3)
				if nearby: result += 5 * abs(change.stages) * forecast.accuracy / 100.0
	return result
