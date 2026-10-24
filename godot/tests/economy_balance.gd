extends SceneTree

const Game = preload("res://core/economy_run.gd")
const Policy = preload("res://ui/qa_economy_policy.gd")
const Store = preload("res://core/economy_store.gd")
var results: Array[Dictionary] = []
var failures: Array[String] = []
var directory: String = "user://"

func _initialize() -> void:
	call_deferred("run_samples")

func run_samples() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--save-dir="): directory = arg.get_slice("=",1)
	DirAccess.make_dir_recursive_absolute(directory)
	if "--gym-probes" in OS.get_cmdline_user_args():
		probe_gyms();return
	if "--full-only" not in OS.get_cmdline_user_args():
		for starter: int in [1,4,7]:
			for sample: int in 2:
				results.append(simulate(starter,"economy-%d" % sample,true))
				write_progress()
	if "--opening-only" not in OS.get_cmdline_user_args():
		for starter: int in [1,4,7]:
			results.append(simulate(starter,"economy-1",false))
			write_progress()
	print(JSON.stringify({"runs":results.size(),"failures":failures}))
	quit(0 if failures.is_empty() else 1)

func simulate(starter: int, seed_text: String, opening: bool) -> Dictionary:
	var game: RefCounted = Game.new()
	var policy: RefCounted = Policy.new()
	var state: Dictionary = game.create(seed_text,starter)
	var journal: Array = []
	var row: Dictionary = {"starter":starter,"seed":seed_text,"sample":"opening" if opening else "full","fights":[],"trainingSpent":0,"trainingLevels":0,"orders":0}
	for index: int in 20000:
		if opening and "brock" in state.cleared: break
		var command: Dictionary = policy.choose(game,state)
		if command.is_empty(): break
		if command.kind=="enter" and game.locations[int(state.stage)].get("kind","")!="story":
			row.fights.append({"location":game.locations[int(state.stage)].id,"levels":state.party.filter(func(m):return m.hp>0).map(func(m):return m.level),"cap":game.level_cap(state),"money":state.money})
		var step: Dictionary = game.transact(state,command)
		if not step.ok: failures.append(str(step.get("reason"))); break
		if command.kind=="train-xp": row.trainingLevels += 1; row.trainingSpent += command.price
		journal.append(command)
		state = step.state
		row.orders += 1
		if state.phase=="battle" and state.battle.round>50: row.stalled = true; break
		if state.phase in ["defeat","ending"]: break
	row.phase = state.phase; row.lastLocation = game.locations[int(state.stage)].id; row.medals = state.medals.size(); row.money = state.money
	row.party = state.party.map(func(m):return {"species":m.speciesId,"level":m.level,"hp":m.hp,"xp":m.xp})
	var filename: String = "sample-%d-%s-%s.json" % [starter,seed_text,row.sample]
	var store: RefCounted = Store.new(directory.path_join(filename))
	if not store.save(state,journal,"journey").ok: failures.append("Cannot save natural sample")
	var loaded: Dictionary = Store.new(store.file_path).load_campaign(game)
	row.replay = loaded.ok and Store.equivalent(loaded.state,state)
	if not row.replay: failures.append("Natural sample replay: "+str(loaded.get("reason")))
	print("ECONOMY_SAMPLE "+JSON.stringify(row))
	return row

func write_progress() -> void:
	FileAccess.open(directory.path_join("balance-economy-full.json" if "--full-only" in OS.get_cmdline_user_args() else "balance-economy.json"),FileAccess.WRITE).store_string(JSON.stringify({"results":results,"failures":failures,"policy":"Automated tactical AI; free evolutions, diverse loadouts, paid healing/revives; EXP training only to reference level while retaining120; no rerolls/MT purchases. Defeats retained. Synthetic unit tests are separate."},"\t"))

func probe_gyms() -> void:
	var game: RefCounted = Game.new()
	var policy: RefCounted = Policy.new()
	var probes: Array = []
	for index: int in game.locations.size():
		var location: Dictionary = game.locations[index]
		if not location.get("leader",false): continue
		var level: int = int(game.ace({"stage":index}).level)-2
		var run: Dictionary = game.create("gym-feasibility",1)
		run.stage = index;run.party = []
		game.progression.gym_cap = level
		for base: int in [1,4,7,16,25,43]:
			var member: Dictionary = game.progression.create_member(run.party.size()+1,base,"Synthetic gym probe",5)
			var curve: Array = game.progression.economy.curves[str(int(game.progression.economy.growthGroups[str(base)]))]
			game.progression.award(member,int(curve[level])-int(curve[5]))
			var options: Array = game.progression.free_evolutions(member).filter(func(e):return member.level>=int(e[1]))
			if not options.is_empty(): member.speciesId = int(options[0][0]);game.progression.learn(member)
			member.hp = game.progression.member_stats(member).maxHp
			member.moves = policy.moves(game,member)
			run.party.append(member)
		var state: Dictionary = game.engine.encounter(run,location)
		var orders: int = 0
		for turn: int in 1000:
			if state.outcome!="playing" or state.round>40: break
			var step: Dictionary = game.engine.apply_command(state,game.engine.choose_command(state))
			if not step.ok: failures.append("Gym probe rejected "+str(step.get("reason")));break
			state = step.state;orders += 1
		var row: Dictionary = {"gym":location.id,"playerLevel":level,"playerSpecies":run.party.map(func(m):return m.speciesId),"enemies":location.team.size(),"outcome":state.outcome,"rounds":state.round,"orders":orders,"scope":"Synthetic fixed six-member healthy roster two levels below ace; evolved only when eligible; no items or heals. Not a natural campaign win."}
		probes.append(row)
		print("GYM_PROBE "+JSON.stringify(row))
	FileAccess.open(directory.path_join("gym-probes.json"),FileAccess.WRITE).store_string(JSON.stringify({"results":probes,"failures":failures},"\t"))
	quit(0 if failures.is_empty() else 1)
