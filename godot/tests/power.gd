extends SceneTree

const Run = preload("res://core/power_run.gd")
const Store = preload("res://core/power_store.gd")
const Points = preload("res://core/power_points.gd")
const Tiles = preload("res://core/restorative_tiles.gd")
var game: RefCounted
var checks: int = 0
var failures: Array[String] = []
var directory: String = ""
var sample: Dictionary
var resolved: int = 0

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label); push_warning(label)

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="): directory = argument.trim_prefix("--save-dir=")
	call_deferred("run_tests")

func arena(identity: String) -> Dictionary:
	var state: Dictionary = sample.duplicate(true)
	var actor: Dictionary = game.engine.member_unit(game.progression.create_member(1,1,"Fixture",30),{"x":5,"y":8})
	var target: Dictionary = game.engine.member_unit(game.progression.create_member(10000,134,"Fixture",30),{"x":6,"y":8})
	actor.moves = [identity]; actor.ability = "none"; target.ability = "none"
	target.team = "enemy"; target.facing = 2
	state.units = [actor,target]; state.queue = [1,10000]; state.completed = []
	state.moved = false; state.acted = false; state.deployment = false; state.restorativeTiles = []
	for row: Array in state.board: row.fill(0)
	for row: Array in state.heights: row.fill(0)
	return state

func run_tests() -> void:
	game = Run.new()
	var fresh: Dictionary = game.create("power",4)
	check(fresh.edition==23 and fresh.startEdition==23,"New edition23")
	sample = game.engine.encounter(fresh,game.locations[0])
	check(Points.capacity(5)==10 and Points.capacity(10)==11 and Points.capacity(100)==20,"Generous capacity grows every five levels, capped20")
	var rows: Array[String] = ["id,nombre,pp,potencia,forma,alcance"]
	for identity: String in game.progression.data.moves:
		var definition: Dictionary = game.progression.data.moves[identity]
		check(definition.cost==0 and definition.loadoutCost>=1 and definition.loadoutCost<=5,"Equipment-only price: "+identity)
		rows.append('%s,"%s",%d,%d,%s,%d' % [identity,definition.name,definition.loadoutCost,definition.power,definition.shape,definition.range])
		var query_state: Dictionary = arena(identity)
		var before: Dictionary = query_state.duplicate(true)
		for point: Dictionary in game.engine.aim_points(query_state,identity):
			var plan: Dictionary = game.engine.cast_plan(query_state,point,identity)
			if not plan.ok: continue
			check(plan.cost==0,"No action resource: "+identity)
			var result: Dictionary = game.engine.cast(query_state,point,identity)
			check(result.ok and game.engine.unit_by_id(result.state,1).tp==0,"Zero-PT actor can resolve: "+identity)
			resolved += 1
			break
		check(Store.equivalent(query_state,before),"Preview and resolution never mutate input: "+identity)
	check(resolved>160,"Most moves resolve without conditional fixtures")
	var member: Dictionary = game.progression.create_member(1,4,"Test",5)
	member.knownMoves = game.progression.data.moves.keys()
	fresh.party[0] = member.duplicate(true)
	var expensive: Array = game.progression.data.moves.keys().filter(func(id):return game.progression.data.moves[id].loadoutCost>=4).slice(0,4)
	check(expensive.size()==4,"Four high-cost moves available for fixture")
	var rejected: Dictionary = game.transact(fresh,{"kind":"loadout","member":1,"moves":expensive,"at":fresh.revision})
	check(not rejected.ok and "PP" in rejected.reason,"Equip over budget rejected atomically")
	var accepted: Dictionary = game.transact(fresh,{"kind":"loadout","member":1,"moves":["ember","scratch","growl"],"at":fresh.revision})
	check(accepted.ok and accepted.state.party[0].moves.size()==3,"Affordable mixed set allowed")
	check(Store.equivalent(fresh.party[0],member),"Reject does not change learned or equipped moves")
	var state: Dictionary = arena("swords-dance")
	var boost: Dictionary = game.engine.cast(state,{"x":5,"y":8},"swords-dance")
	check(boost.ok and boost.state.units[0].stages.get("attack")==2,"Boost applied")
	state = boost.state
	for turn: int in 8:
		state.queue = [1,10000]; state.outcome = "playing"
		state = game.engine.finish(state).state
	check(state.units[0].stages.get("attack")==2 and state.units[0].stageTurns.is_empty(),"Boost survives eight own turns")
	game.engine._change(state.units[0],{"stat":"defense","stages":-1})
	state.queue = [1,10000]; state = game.engine.finish(state).state
	check(state.units[0].stages.get("defense")==-1,"Debuff permanent until battle ends or cleared")
	state.units[0].status = {"kind":"paralysis","remaining":1}
	state.queue = [1,10000]; state = game.engine.finish(state).state
	check(state.units[0].status==null and state.units[0].stages.get("attack")==2,"Status expires independently of stats")
	state = arena("focus-energy")
	state = game.engine.cast(state,{"x":5,"y":8},"focus-energy").state
	for turn: int in 5:
		state.queue = [1,10000]; state = game.engine.finish(state).state
	check(state.units[0].volatile.has("focus"),"Critical stage boost survives five activations")
	state = arena("ember"); state.units[0].hp = state.units[0].maxHp*10
	state.units[1].hp = state.units[1].maxHp*10
	for turn: int in 4:
		state.queue = [1,10000]; state.acted = false; state.units[0].tp = 0
		var repeated: Dictionary = game.engine.cast(state,{"x":6,"y":8},"ember")
		check(repeated.ok and repeated.state.units[0].tp==0,"Repeated equipped attack needs no points: "+str(turn))
		state = repeated.state
	state = arena("roost"); state.units[0].hp -= 10; state.units[0].recoveryPP.roost = 0
	var recovery: Dictionary = game.engine.cast(state,{"x":5,"y":8},"roost")
	check(recovery.ok and recovery.state.units[0].hp>state.units[0].hp and recovery.state.units[0].recoveryPP.roost==0,"Recovery uses no hidden old resource")
	state = arena("ember"); state.units[1].ability = "pressure"
	check(game.engine.cast_plan(state,{"x":6,"y":8},"ember").cost==0,"Pressure cannot restore old PT cost")
	var tm_run: Dictionary = game.create("power-tm",4)
	tm_run.party[0].knownMoves = ["scratch","growl"]
	var machine: String = ""
	for item: String in game.shop_data.items:
		if game.compatible(tm_run.party[0],item) and game.shop_data.items[item].move=="flamethrower": machine = item; break
	check(machine!="","Compatible flamethrower MT fixture exists")
	if machine!="":
		tm_run.bag[machine] = 1
		var taught: Dictionary = game.transact(tm_run,{"kind":"teach","item":machine,"member":1,"at":tm_run.revision})
		check(taught.ok and "flamethrower" in taught.state.party[0].knownMoves and Points.used(taught.state.party[0].moves,game.progression.data.moves)<=10,"MT respects equipment budget and preserves knowledge")
	for team: String in ["ally","enemy"]:
		state = arena("growl"); state.units[0].team = team
		state.restorativeTiles = [{"x":5,"y":8}]
		state.units[0].hp -= 9; var hp: int = state.units[0].hp
		state.units[0].status = {"kind":"burn","remaining":3}; state.units[0].volatile.confusion = {"remaining":3,"source":10000}
		game.engine._change(state.units[0],{"stat":"attack","stages":-1})
		state = game.engine.finish(state).state
		check(state.units[0].status==null and not state.units[0].volatile.has("confusion") and state.units[0].hp==hp,"Manantial cures before status damage, no HP healing: "+team)
		check(state.units[0].stages.get("attack")==-1,"Manantial preserves attribute changes: "+team)
	for width: int in [16,24]:
		for location: Dictionary in game.locations:
			fresh = game.create("power-maps",1); fresh.mapSize = width
			state = game.engine.encounter(fresh,location)
			check(state.restorativeTiles.size()==2,"Two accessible springs: %s/%d"%[location.id,width])
			for unit: Dictionary in state.units:
				check(Points.used(unit.moves,game.progression.data.moves)<=Points.capacity(unit.level),"Both teams obey budget: "+location.id)
	natural_and_replay()
	DirAccess.make_dir_recursive_absolute(directory)
	FileAccess.open(directory.path_join("power-prices.csv"),FileAccess.WRITE).store_string("\n".join(rows)+"\n")
	FileAccess.open(directory.path_join("power-result.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"resolved":resolved},"  "))
	print(JSON.stringify({"checks":checks,"failures":failures,"resolved":resolved}))
	quit(0 if failures.is_empty() else 1)

func natural_and_replay() -> void:
	for starter: int in [1,4,7]:
		var run: Dictionary = game.create("power-natural",starter)
		var commands: Array = []
		for kind: String in ["enter","start-battle"]:
			var command: Dictionary = {"kind":kind,"at":run.revision}
			run = game.transact(run,command).state; commands.append(command)
		for step: int in 200:
			if run.phase!="battle": break
			var command: Dictionary = {"kind":"battle","order":game.engine.choose_command(run.battle),"at":run.revision}
			var result: Dictionary = game.transact(run,command)
			if not result.ok: check(false,result.reason); break
			run = result.state; commands.append(command)
		check(run.phase=="capture","Natural opening reaches capture: "+str(starter))
		var store: RefCounted = Store.new(directory.path_join("power-%d.json"%starter))
		check(store.save(run,commands,"current").ok,"Save edition23")
		var restored: Dictionary = store.load_campaign(game)
		check(restored.ok and Store.equivalent(run,restored.state),"Replay matches natural opening: "+str(starter))
	var old: RefCounted = preload("res://core/kanto_journey.gd").new()
	var legacy: Dictionary = old.create("legacy-pp",4)
	var transition: Dictionary = {"kind":"upgrade","edition":23,"at":legacy.revision}
	var upgraded: Dictionary = game.transact(legacy,transition).state
	var mixed_store: RefCounted = Store.new(directory.path_join("power-mixed.json"))
	check(mixed_store.save(upgraded,[transition],"current").ok,"Save mixed22→23 diary")
	var mixed: Dictionary = mixed_store.load_campaign(game)
	check(mixed.ok and Store.equivalent(upgraded,mixed.state),"Mixed replay preserves previous edition")
	check(old.create("unchanged",4).edition==22 and old.progression.data.moves.ember.cost>0,"Published rules remain intact")
