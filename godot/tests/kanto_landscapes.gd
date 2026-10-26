extends SceneTree

const Game = preload("res://core/kanto_journey.gd")
const Store = preload("res://core/kanto_campaign_store.gd")
const Challenge = preload("res://core/kanto_challenge.gd")
const Terrain = preload("res://core/terrain_movement.gd")
var game: RefCounted
var checks: int = 0
var failures: Array[String] = []
var directory: String = ""
var openings: Array = []

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label); print("KANTO_FAIL "+label)

func _initialize() -> void:
	call_deferred("test_all")

func test_all() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="): directory = argument.trim_prefix("--save-dir=")
	if directory.is_empty(): quit(2); return
	DirAccess.make_dir_recursive_absolute(directory)
	game = Game.new()
	var run: Dictionary = game.create("landscape-replay",4)
	check(run.edition==22 and run.chapter==26,"New edition22")
	var legacy: RefCounted = load("res://core/adventure_run.gd").new()
	check(Store.equivalent(game.progression.data,legacy.progression.data),"All moves, statistics, learnsets, curves and rewards preserved")
	check(game.shop_data==legacy.shop_data and game.consumables==legacy.consumables,"Prices and items preserved")
	for index: int in game.locations.size():
		var location: Dictionary = game.locations[index].duplicate(true)
		for key: String in ["path","requires","optional","story"]: location.erase(key)
		var previous: Dictionary = legacy.locations[index].duplicate(true)
		for key: String in ["path","requires","optional","story"]: previous.erase(key)
		check(location==previous,"Encounter roster/reward preserved "+location.id)
	maps()
	var journal: Array = [{"kind":"enter","at":0}]
	run = game.transact(run,journal[0]).state
	check(run.battle.landscape.id=="route-1" and run.battle.deployment,"New encounter authored")
	var rng: int = int(run.battle.rng)
	for kind: String in ["auto-deploy","start-battle"]:
		var command: Dictionary = {"kind":kind,"at":run.revision}
		run = game.transact(run,command).state; journal.append(command)
	check(run.battle.rng==rng,"Deployment preserves RNG")
	var path: String = directory.path_join("kanto-%d.json" % Time.get_ticks_usec())
	var store: RefCounted = Store.new(path)
	store.new_binding("test-trainer")
	check(store.save(run,journal,"journey").ok,"Save22")
	var replay: Dictionary = Store.new(path).load_campaign(game)
	check(replay.ok and Store.equivalent(run,replay.get("state",{})),"Replay22 actual authored geometry")
	check(Challenge.decode(Challenge.encode(run)).edition==22,"KT30 edition22 roundtrip")
	check(Challenge.decode(load("res://core/journey_challenge.gd").encode(legacy.create("legacy-code",1))).edition==21,"KT25 preserves21")
	check(Challenge.decode("KT30:bad").is_empty() and Challenge.decode("KT30:!!!!!!!!").is_empty(),"Malformed codes rejected")
	var old: Dictionary = legacy.create("mixed-journal",1)
	var upgrade: Dictionary = {"kind":"upgrade","edition":22,"at":0}
	var converted: Dictionary = game.transact(old,upgrade).state
	check(converted.party==old.party and converted.money==old.money and converted.rng==old.rng,"Upgrade21 preserves exact roster, EXP, HP, money and RNG")
	var mixed: RefCounted = Store.new(directory.path_join("mixed-%d.json" % Time.get_ticks_usec()))
	check(mixed.save(converted,[upgrade],"journey").ok,"Mixed21/22 saved")
	replay = Store.new(mixed.file_path).load_campaign(game)
	check(replay.ok and Store.equivalent(converted,replay.get("state",{})),"Mixed21/22 replay")
	check(not game.transact(run,{"kind":"upgrade","edition":22,"at":run.revision}).ok,"Combat cannot change geometry")
	for edition: int in [12,19,20]:
		var source_rules: RefCounted = store._rules(edition)
		var original: Dictionary = source_rules.create("upgrade-matrix",1)
		var transition: Dictionary = {"kind":"upgrade","edition":22,"at":0}
		var upgraded: Dictionary = game.transact(original,transition)
		check(upgraded.ok and upgraded.state.edition==22,"Upgrade matrix "+str(edition))
		var reader: RefCounted = Store.new(directory.path_join("matrix-%d-%d.json"%[edition,Time.get_ticks_usec()]))
		check(reader.save(upgraded.state,[transition],"journey").ok,"Save mixed origin "+str(edition))
		var restored: Dictionary = Store.new(reader.file_path).load_campaign(game)
		check(restored.ok and Store.equivalent(restored.get("state",{}),upgraded.state),"Replay mixed origin "+str(edition))
	finals()
	natural_openings()
	FileAccess.open(directory.path_join("kanto-result.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"maps":116,"edition":22,"combatEdition":19,"openings":openings,"scope":"All authored layouts and geometry, synthetic sequential endings, replay and compatibility; natural opening with three starters, no full human campaign."},"  "))
	print(JSON.stringify({"checks":checks,"failures":failures})); quit(0 if failures.is_empty() else 1)

func maps() -> void:
	var shapes: Dictionary = {}
	for size_value: int in [16,24]:
		for index: int in game.locations.size():
			var location: Dictionary = game.locations[index]
			var fixture: Dictionary = game.create("maps-fixed",1); fixture.stage = index; fixture.mapSize = size_value
			var state: Dictionary = game.engine.encounter(fixture,location)
			check(state.board.size()==size_value and state.landscape.id==location.id,"Authored map "+location.id+str(size_value))
			var actor: Dictionary = state.units[0]
			# Connectivity uses the actual ground step cost, but ignores occupying units.
			var pending: Array = [{"x":actor.x,"y":actor.y}]
			var reached: Dictionary = {game.engine.Movement.key(actor):true}
			while not pending.is_empty():
				var point: Dictionary = pending.pop_front()
				for vector: Vector2i in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
					var other: Dictionary = {"x":int(point.x)+vector.x,"y":int(point.y)+vector.y}
					if other.x<0 or other.y<0 or other.x>=size_value or other.y>=size_value or reached.has(game.engine.Movement.key(other)): continue
					if Terrain.step_cost(state,{"profile":"ground"},point,other)==INF: continue
					reached[game.engine.Movement.key(other)] = true; pending.append(other)
			for point: Dictionary in state.units+state.arena.deployment+state.mission.points:
				check(reached.has(game.engine.Movement.key(point)),"Ground reachable spawn/deployment/objective "+location.id+str(size_value)+game.engine.Movement.key(point))
			for pair: Array in state.arena.portals:
				for point: Dictionary in pair: check(reached.has(game.engine.Movement.key(point)),"Portal reachable "+location.id)
			for key: String in state.landscape.props:
				var xy: PackedStringArray = key.split(",")
				check(int(state.board[int(xy[1])][int(xy[0])])==(1 if state.landscape.props[key]=="bush" else 2),"Visual prop matches its ground/solid rule "+location.id+key)
			var signature: String = JSON.stringify([state.board,state.heights]).sha256_text()
			check(not shapes.has(signature) or [location.id,shapes.get(signature)]==["league-rival","route-22"],"Distinct terrain per place "+location.id)
			shapes[signature] = location.id
			check(state.heights.any(func(row):return row.any(func(h):return h>0)),"Purposeful elevations "+location.id)
			check(state.units.all(func(u):return state.units.filter(func(v):return game.engine.Movement.same(u,v)).size()==1),"Unique spawns "+location.id)

func finals() -> void:
	var run: Dictionary = game.create("synthetic-finals",1)
	run.mainComplete = true; run.cleared = game.locations.filter(func(l):return not l.get("finale",false)).map(func(l):return l.id)
	run.phase = "shop"; run.stage = 55
	var first: Dictionary = game.transact(run,{"kind":"continue","at":run.revision})
	check(first.ok and first.state.phase=="map" and first.state.stage==56 and first.state.finalPath=="birds","Champion leads to birds")
	run = first.state
	check(not game.transact(run,{"kind":"travel","location":"legendary-origin","at":run.revision}).ok,"Psychic battle locked until birds win")
	check(not game.transact(run,{"kind":"destiny","path":"psychic","at":run.revision}).ok,"No exclusive shortcut")
	var profile_store: RefCounted = Store.new(directory.path_join("synthetic-final-metadata.json")); profile_store.new_binding("test")
	var profile: RefCounted = load("res://core/trainer_profile.gd").new()
	for stage: int in [56,57]:
		var prepared: Dictionary = game.transact(run,{"kind":"enter","at":run.revision})
		check(prepared.ok and prepared.state.stage==stage,"Actual legendary encounter opens in order")
		run = prepared.state
		var ids: Array = run.battle.units.filter(func(u):return u.team=="enemy").map(func(u):return int(u.speciesId)); ids.sort()
		check(ids==([144,145,146] if stage==56 else [150,151]),"Legendary boss roster")
		game.engine.start_battle(run.battle)
		var actor: Dictionary = run.battle.units[0]
		for unit: Dictionary in run.battle.units:
			if unit.team=="enemy": unit.hp = 0
		var enemy: Dictionary = run.battle.units.filter(func(u):return u.team=="enemy")[0]
		enemy.hp = 1; enemy.x = actor.x+1; enemy.y = actor.y
		run.battle.board[int(enemy.y)][int(enemy.x)] = 0; run.battle.heights[int(enemy.y)][int(enemy.x)] = Terrain.height_at(run.battle,actor)
		run.battle.queue = [actor.id]; run.battle.acted = false
		var before: Dictionary = run.duplicate(true)
		var command: Dictionary = {"kind":"battle","order":{"kind":"attack","actionId":"basic","target":enemy.id,"aim":{"x":enemy.x,"y":enemy.y}},"at":run.revision}
		var result: Dictionary = game.transact(run,command)
		check(result.ok,"Synthetic finishing blow accepted")
		if not result.ok: return
		run = result.state
		check(run.phase==("shop" if stage==56 else "ending"),"Shop after birds, final ending only after psychic")
		check(run.reward.is_empty() and run.party.all(func(m):return int(m.speciesId)<144),"No legendary recruitment")
		profile_store.record(game.engine,before,run,command,{}, {},game.locations[stage])
		profile.observe("sequential-test",run,profile_store.profile_events)
		check(profile.data.unlocked.has("birds"),"Bird achievement awarded before final completion")
		check(profile.data.runs["sequential-test"].status==("active" if stage==56 else "completed"),"Profile status follows whole adventure")
		if stage==56:
			check(not profile.data.unlocked.has("psychic"),"Psychic achievement not premature")
			run = game.transact(run,{"kind":"continue","at":run.revision}).state
			check(run.stage==57 and run.finalPath=="psychic","Bird shop continues to psychic")
	check(profile.data.unlocked.has("psychic"),"Both boss achievements retained")
	for path: String in ["birds","psychic"]:
		var old: Dictionary = load("res://core/adventure_run.gd").new().create("old-final",1)
		old.mainComplete = true; old.phase = "ending"; old.finalPath = path
		old.cleared = ["champion","legendary-birds" if path=="birds" else "legendary-origin"]
		var updated: Dictionary = game.transact(old,{"kind":"upgrade","edition":22,"at":old.revision})
		check(updated.ok and updated.state.phase=="shop" and updated.state.cleared==old.cleared,"Legacy ending upgrade retains real wins "+path)

func natural_openings() -> void:
	for species_id: int in [1,4,7]:
		var run: Dictionary = game.create("kecleon-ui",species_id)
		var journal: Array = []
		for kind: String in ["enter","start-battle"]:
			var command: Dictionary = {"kind":kind,"at":run.revision}
			run = game.transact(run,command).state; journal.append(command)
		var count: int = 0
		while run.phase=="battle" and count<400:
			var command: Dictionary = {"kind":"battle","order":game.engine.choose_command(run.battle),"at":run.revision}
			var result: Dictionary = game.transact(run,command)
			check(result.ok,"Natural opening legal order "+str(species_id))
			if not result.ok: break
			run = result.state; journal.append(command); count += 1
		check(run.phase in ["capture","defeat"],"Natural opening resolves without stalled path "+str(species_id))
		var reader: RefCounted = Store.new(directory.path_join("opening-%d-%d.json"%[species_id,Time.get_ticks_usec()]))
		check(reader.save(run,journal,"journey").ok,"Natural opening saved "+str(species_id))
		var replay: Dictionary = Store.new(reader.file_path).load_campaign(game)
		check(replay.ok and Store.equivalent(replay.get("state",{}),run),"Natural opening exact replay "+str(species_id))
		openings.append({"starter":species_id,"seed":run.seed,"orders":count,"phase":run.phase,"cleared":run.cleared,"hp":run.party[0].hp})
