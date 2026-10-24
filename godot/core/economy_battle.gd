extends "res://core/spatial_battle.gd"

func _init() -> void:
	super()
	progression = load("res://core/economy_study.gd").new()
	catalog = progression.data
	for identity: int in profiles: profiles[identity].progression = progression

func encounter(run: Dictionary, location: Dictionary) -> Dictionary:
	var tuned: Dictionary = location.duplicate(true)
	if tuned.get("team",[]).is_empty() and not tuned.has("rivalTeams"):
		var generation: Dictionary = {"rng":Rng.hash_seed(run.seed+"/"+tuned.id+"/lgpe-wild")}
		var pool: Array = catalog.encounters[tuned.captureTable].filter(func(e):return not e.special)
		tuned.team = []
		for index: int in int(tuned.get("count",3)):
			var entry: Dictionary = pool[int(floor(Rng.next(generation)*pool.size()))]
			var level: int = clampi(int(tuned.wildLevel)+int(floor(Rng.next(generation)*3))-1,2,100)
			tuned.team.append({"speciesId":entry.speciesId,"level":level})
	encounter_seed = run.seed+"/"+tuned.id
	var map: Dictionary = ExpandedMaps.layout(tuned.get("biome","route"),int(run.mapSize))
	var team: Array = tuned.get("team",[]).duplicate(true)
	if tuned.has("rivalTeams"): team = tuned.rivalTeams[{1:2,4:0,7:1}[int(run.starter)]].duplicate(true)
	var offset: int = int((int(run.mapSize)-16)/2.0)
	for point: Vector2i in [Vector2i(10,8),Vector2i(10,6),Vector2i(11,9),Vector2i(12,8),Vector2i(12,6),Vector2i(9,9)]:
		if map.enemies.size()>=team.size(): break
		var spawn: Dictionary = {"x":point.x+offset,"y":point.y+offset}
		if map.enemies.any(func(e):return Movement.same(e,spawn)): continue
		map.enemies.append(spawn)
		map.board[int(spawn.y)][int(spawn.x)] = 0
		map.heights[int(spawn.y)][int(spawn.x)] = mini(1,int(map.heights[int(spawn.y)][int(spawn.x)]))
	var units: Array = []
	for member: Dictionary in run.party:
		if member.hp>0: units.append(member_unit(member,map.allies[units.size()]))
	for index: int in team.size():
		var member: Dictionary = progression.create_member(10000+int(run.stage)*10+index,int(team[index].speciesId),tuned.name,int(team[index].level))
		var enemy: Dictionary = member_unit(member,map.enemies[index])
		enemy.team = "enemy"; enemy.facing = 0
		enemy.dormant = (tuned.id=="forest" and index==2) or (index>=4 and not tuned.get("leader",false) and not tuned.get("finale",false))
		units.append(enemy)
	encounter_seed = ""
	var state: Dictionary = {"seed":run.seed+"/"+tuned.id,"rng":Rng.hash_seed(run.seed+"/"+tuned.id),"variance":0.05,"composition":"kanto","round":0,"board":map.board,"heights":map.heights,"mapSize":run.mapSize,"fields":[],"units":units,"initiative":[],"queue":[],"completed":[],"moved":false,"acted":false,"outcome":"playing","log":[],"biome":tuned.get("biome","route"),"abilityEvents":[]}
	new_round(state)
	for unit: Dictionary in living(state):
		if unit.get("ability")=="intimidate":
			for other: Dictionary in living(state):
				if other.team!=unit.team and Movement.distance(unit,other)<=6 and other.get("ability") not in ["clear-body","hyper-cutter"]: _change(other,{"stat":"attack","stages":-1})
			_ability(state,unit,"Intimidación: −1 Ataque a rivales a seis casillas, temporal")
	if tuned.get("finale",false):
		var kits: Dictionary = {144:["ice-beam","gust","reflect","roost"],145:["thunderbolt","drill-peck","light-screen","roost"],146:["flamethrower","air-slash","solar-beam","roost"],150:["psychic","swift","recover","amnesia"],151:["confusion","mega-punch","amnesia","barrier"]}
		for unit: Dictionary in state.units:
			if unit.team!="enemy": continue
			var known: Array = progression.create_member(int(unit.id),int(unit.speciesId),tuned.name,int(unit.level)).knownMoves
			unit.moves = kits[int(unit.speciesId)].filter(func(identity):return identity in known)
	for unit: Dictionary in state.units:
		if unit.team!="enemy" or tuned.get("finale",false) or not tuned.get("leader",false): continue
		var known: Array = progression.create_member(int(unit.id),int(unit.speciesId),tuned.name,int(unit.level)).knownMoves
		known = known.filter(func(id):return not catalog.moves[id].get("selfKO",false))
		known.sort_custom(func(a,b):return kit_score(unit,a)>kit_score(unit,b))
		var kit: Array = []
		var types: Array = []
		for identity: String in known:
			var definition: Dictionary = catalog.moves[identity]
			if definition.category=="status" or definition.type in types: continue
			kit.append(identity); types.append(definition.type)
			if kit.size()==3: break
		for identity: String in known:
			if kit.size()==4: break
			if identity not in kit: kit.append(identity)
		unit.moves = kit
	return state

func kit_score(unit: Dictionary, identity: String) -> float:
	var definition: Dictionary = catalog.moves[identity]
	if definition.kind=="heal": return 35
	if definition.category=="status": return 18 if definition.kind=="status" else 8
	return float(definition.power)*(1.5 if definition.type in unit.types else 1.0)/(1.0+float(definition.cost)*0.4)+float(definition.range)
