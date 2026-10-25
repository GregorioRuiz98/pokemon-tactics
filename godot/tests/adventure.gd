extends SceneTree

const Game = preload("res://core/adventure_run.gd")
const Store = preload("res://core/adventure_store.gd")
const Challenge = preload("res://core/journey_challenge.gd")
const Threat = preload("res://core/threat_query.gd")
var game: RefCounted
var checks: int = 0
var failures: Array[String] = []
var directory: String = ""

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition: failures.append(label); print("ADVENTURE_FAIL "+label)

func _initialize() -> void:
	call_deferred("test_all")

func test_all() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--save-dir="): directory = arg.trim_prefix("--save-dir=")
	if directory.is_empty(): quit(2); return
	DirAccess.make_dir_recursive_absolute(directory)
	game = Game.new()
	var run: Dictionary = game.create("adventure-test",1)
	check(run.edition==21 and run.chapter==25,"New campaign edition")
	var journal: Array = []
	var command: Dictionary = {"kind":"enter","at":run.revision}
	run = game.transact(run,command).state; journal.append(command)
	check(run.phase=="battle" and run.battle.deployment and run.battle.combatEdition==19,"Preparation before activation")
	check(not game.transact(run,{"kind":"battle","order":{"kind":"finish","facing":0},"at":run.revision}).ok,"No premature order")
	var rng: int = int(run.battle.rng)
	command = {"kind":"deploy","member":1,"destination":run.battle.arena.deployment[0],"at":run.revision}
	run = game.transact(run,command).state; journal.append(command)
	check(run.battle.rng==rng,"Deployment consumes no initiative or combat RNG")
	check(not game.transact(run,{"kind":"deploy","member":1.5,"destination":{"x":1,"y":1},"at":run.revision}).ok,"Fractional IDs rejected")
	check(not game.transact(run,{"kind":"deploy","member":1,"destination":{"x":12,"y":12},"at":run.revision}).ok,"Outside deployment rejected")
	command = {"kind":"start-battle","at":run.revision}
	run = game.transact(run,command).state; journal.append(command)
	check(not run.battle.deployment and run.battle.rng==rng,"Begin preserves initiative and RNG")
	var store: RefCounted = Store.new(directory.path_join("deployment-%d.json" % Time.get_ticks_usec()))
	check(store.save(run,journal,"journey").ok,"Save prepared and started battle")
	var replay: Dictionary = Store.new(store.file_path).load_campaign(game)
	check(replay.ok and Store.equivalent(replay.get("state",{}),run),"Replay preparation and begin")
	check(Challenge.decode(Challenge.encode(run)).seed==run.seed,"Challenge round trip")
	check(Challenge.decode("KT25:bad").is_empty() and Challenge.decode("not-a-code").is_empty(),"Bad challenge rejected")
	var old_game: RefCounted = load("res://core/economy_run.gd").new()
	var old: Dictionary = old_game.create("upgrade-20",4)
	old.party[0].xp = 13
	var converted: Dictionary = game.transact(old,{"kind":"upgrade","edition":21,"at":old.revision})
	check(converted.ok and converted.state.party==old.party and converted.state.money==old.money and converted.state.rng==old.rng,"Upgrade20 preserves exact partial EXP, HP and RNG")
	var before: Dictionary = run.battle.duplicate(true)
	var query: RefCounted = Threat.new(); query.start(game.engine,run.battle)
	var slices: int = 0
	while not query.complete and slices<20000: query.advance(); slices += 1
	check(query.complete and not query.cells.is_empty(),"Threat geometry completes cooperatively")
	check(Store.equivalent(before,run.battle),"Threat query never mutates state or RNG")
	check(slices>1,"Threat query yields")
	for index: int in game.locations.size():
		var location: Dictionary = game.locations[index]
		if not location.get("leader",false): continue
		var fixture: Dictionary = game.create("arena-check",1); fixture.stage = index
		var battle: Dictionary = game.engine.encounter(fixture,location)
		check(battle.arena.title!="Encuentro de ruta","Authored arena "+location.id)
		var ally: Dictionary = battle.units[0]
		check(not game.engine.movement_routes(battle,ally,INF).is_empty(),"Arena has reachable terrain "+location.id)
		for unit: Dictionary in battle.units:
			check(battle.units.filter(func(u):return game.engine.Movement.same(unit,u)).size()==1,"Unique spawn "+location.id+"/"+str(unit.id))
	mission_checks()
	portal_checks()
	compatibility_checks()
	recovery_checks()
	terrain_checks()
	threat_cache_checks()
	var report: Dictionary = {"checks":checks,"failures":failures,"threatSlices":slices}
	FileAccess.open(directory.path_join("adventure-result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report)); quit(0 if failures.is_empty() else 1)

func mission_checks() -> void:
	for identity: String in ["rocket-hideout","fuji-rescue","victory-road"]:
		var fixture: Dictionary = game.create("mission-check",1)
		fixture.stage = game.locations.find(game.locations.filter(func(l):return l.id==identity)[0])
		var state: Dictionary = game.engine.encounter(fixture,game.locations[fixture.stage])
		game.engine.start_battle(state)
		if identity=="rocket-hideout":
			state.mission.captured = state.mission.points.map(func(p):return game.engine.Movement.key(p))
		elif identity=="fuji-rescue": state.round = 4
		else: state.units[0].x = state.mission.points[0].x; state.units[0].y = state.mission.points[0].y
		game.engine._mission_result(state)
		check(state.outcome=="victory","Alternative mission win "+identity)
	var mission_run: Dictionary = game.create("mission-transactions",1)
	mission_run.stage = game.locations.find(game.locations.filter(func(l):return l.id=="rocket-hideout")[0])
	mission_run.phase = "battle"; mission_run.battle = game.engine.encounter(mission_run,game.locations[mission_run.stage])
	game.engine.start_battle(mission_run.battle)
	var actor: Dictionary = mission_run.battle.units[0]
	actor.merge(mission_run.battle.mission.points[1],true)
	mission_run.battle.mission.captured = [game.engine.Movement.key(mission_run.battle.mission.points[0])]
	mission_run.battle.queue = [actor.id,mission_run.battle.units[1].id]
	var victory: Dictionary = game.transact(mission_run,{"kind":"battle","order":{"kind":"finish","facing":0},"at":mission_run.revision})
	check(victory.ok and victory.state.phase=="capture" and "rocket-hideout" in victory.state.cleared,"Mission victory grants normal campaign reward")
	mission_run.stage = game.locations.find(game.locations.filter(func(l):return l.id=="fuji-rescue")[0])
	mission_run.battle = game.engine.encounter(mission_run,game.locations[mission_run.stage]); game.engine.start_battle(mission_run.battle)
	var enemy: Dictionary = mission_run.battle.units[1]
	enemy.x = mission_run.battle.mission.points[0].x+1; enemy.y = mission_run.battle.mission.points[0].y
	mission_run.battle.queue = [enemy.id,mission_run.battle.units[0].id]; mission_run.battle.mission.health = 1
	var defeat: Dictionary = game.transact(mission_run,{"kind":"battle","order":{"kind":"finish","facing":0},"at":mission_run.revision})
	check(defeat.ok and defeat.state.phase=="defeat","Failed protection ends campaign with allies still alive")

func portal_checks() -> void:
	var fixture: Dictionary = game.create("portal-check",1)
	fixture.stage = game.locations.find(game.locations.filter(func(l):return l.id=="sabrina")[0])
	var state: Dictionary = game.engine.encounter(fixture,game.locations[fixture.stage])
	game.engine.start_battle(state)
	var actor: Dictionary = state.units[0]
	var pair: Array = state.arena.portals[1]
	actor.x = pair[0].x-1; actor.y = pair[0].y
	actor.remaining = 5; state.queue = [actor.id]; state.moved = false
	state.board[int(actor.y)][int(actor.x)] = 0; state.heights[int(actor.y)][int(actor.x)] = 0
	var result: Dictionary = game.engine.apply_command(state,{"kind":"move","destination":pair[0]})
	check(result.ok and game.engine.Movement.same(result.state.units[0],pair[1]),"Entering portal resolves at its free partner")
	if result.ok:
		check(result.state.movementLocked,"Portal consequence blocks movement undo")
		fixture.phase = "battle"; fixture.battle = result.state
		check(not game.transact(fixture,{"kind":"rectify","at":fixture.revision}).ok,"Campaign rejects portal undo")

func recovery_checks() -> void:
	var run: Dictionary = game.create("recovery-fixture",1)
	run.party = [game.progression.create_member(1,1,"Fixture",12),game.progression.create_member(2,7,"Fixture",5)]
	var quote: Dictionary = game.training_quote(run.merged({"phase":"shop"},true),run.party[1])
	check(quote.ok and quote.discount==25,"Training discount for lagging member")
	run.battle = game.engine.encounter(run,game.locations[0]); run.phase = "battle"
	game.engine.start_battle(run.battle)
	var actor: Dictionary = run.battle.units[0]
	run.battle.units[1].hp = 0
	var enemy: Dictionary = run.battle.units[2]
	enemy.hp = 1; enemy.x = actor.x+1; enemy.y = actor.y
	run.battle.board[int(enemy.y)][int(enemy.x)] = 0; run.battle.heights[int(enemy.y)][int(enemy.x)] = 0
	for index: int in range(3,run.battle.units.size()): run.battle.units[index].hp = 0
	run.battle.queue = [actor.id]; run.battle.acted = false; actor.tp = 5
	var result: Dictionary = game.transact(run,{"kind":"battle","order":{"kind":"attack","target":enemy.id,"actionId":"basic","aim":{"x":enemy.x,"y":enemy.y}},"at":run.revision})
	check(result.ok and result.state.phase=="capture","Recovery fixture wins")
	if result.ok and result.state.phase=="capture":
		check(result.state.party[1].hp==0 and result.state.party[1].xp>0,"Fallen participant gains partial EXP without revival")
		check(result.state.lastProgress.any(func(p):return p.get("reason","").contains("debilitado")),"Recovery receipt explains grant")

func compatibility_checks() -> void:
	var legacy: RefCounted = load("res://core/economy_run.gd").new()
	var state: Dictionary = legacy.create("economy-1",1)
	var journal: Array = [{"kind":"enter","at":0}]
	state = legacy.transact(state,journal[0]).state
	for index: int in 120:
		if state.phase!="battle": break
		var command: Dictionary = {"kind":"battle","order":legacy.engine.choose_command(state.battle),"at":state.revision}
		var result: Dictionary = legacy.transact(state,command)
		if not result.ok: break
		state = result.state; journal.append(command)
	check(state.phase=="capture","Legacy natural opening reaches upgrade checkpoint")
	if state.phase!="capture": return
	var capture_command: Dictionary = {"kind":"capture","at":state.revision}
	state = legacy.transact(state,capture_command).state; journal.append(capture_command)
	var previous: Dictionary = state.duplicate(true)
	var upgrade: Dictionary = {"kind":"upgrade","edition":21,"at":state.revision}
	state = game.transact(state,upgrade).state; journal.append(upgrade)
	check(state.party==previous.party and state.money==previous.money and state.rng==previous.rng,"Natural20 upgrade preserves exact roster and economy")
	var store: RefCounted = Store.new(directory.path_join("compatibility-%d.json" % Time.get_ticks_usec()))
	check(store.save(state,journal,"journey").ok,"Mixed20/21 trace saved")
	var loaded: Dictionary = Store.new(store.file_path).load_campaign(game)
	check(loaded.ok and Store.equivalent(loaded.get("state",{}),state),"Mixed edition replay reconstructs both historical engines")

func terrain_checks() -> void:
	var run: Dictionary = game.create("terrain-fixture",4)
	var initial: Dictionary = game.engine.encounter(run,game.locations[0])
	game.engine.start_battle(initial)
	initial.queue = [initial.units[0].id]
	var actor: Dictionary = initial.units[0]
	actor.moves = ["ember","surf"]; actor.tp = 5
	var target: Dictionary = initial.units[1]
	target.x = actor.x+1; target.y = actor.y
	initial.board[int(target.y)][int(target.x)] = 0; initial.heights[int(target.y)][int(target.x)] = 0
	for identity: String in ["ember","surf"]:
		var state: Dictionary = initial.duplicate(true)
		var field: Dictionary = {"x":target.x,"y":target.y,"kind":"web" if identity=="ember" else "fire","source":0,"zone":1,"chance":100,"expires":99}
		state.fields = [field]
		var result: Dictionary = game.engine.cast(state,{"x":target.x,"y":target.y},identity)
		check(result.ok,"Terrain cast "+identity)
		if result.ok: check(result.state.fields.any(func(f):return f.kind==("fire" if identity=="ember" else "mud")),"Terrain reaction "+identity)

func threat_cache_checks() -> void:
	for identity: String in ["brock","misty","sabrina","giovanni-gym"]:
		var fixture: Dictionary = game.create("threat-equivalence",1)
		fixture.party = []
		for species: int in [3,6,9,26,65,68]: fixture.party.append(game.progression.create_member(fixture.party.size()+1,species,"Synthetic threat fixture",40))
		fixture.stage = game.locations.find(game.locations.filter(func(l):return l.id==identity)[0])
		var state: Dictionary = game.engine.encounter(fixture,game.locations[fixture.stage])
		var cached: RefCounted = Threat.new(); cached.start(game.engine,state)
		var reference: RefCounted = Threat.new(); reference.start(game.engine,state,0,false)
		while not cached.complete: cached.advance(1000000)
		while not reference.complete: reference.advance(1000000)
		check(Store.equivalent(cached.cells,reference.cells),"Cached threat coverage equals uncached geometry: "+identity)
