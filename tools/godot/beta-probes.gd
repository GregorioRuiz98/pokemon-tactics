extends SceneTree

const Game = preload("res://core/closing_run.gd")
const Ledger = preload("res://core/closing_store.gd")
const Trainer = preload("res://core/collection_profile.gd")
const Profiles = preload("res://core/collection_profile_store.gd")
const Catalog = preload("res://core/collection_catalog.gd")
const Share = preload("res://core/closing_challenge.gd")
var directory: String = ""
var selected_case: String = "matrix"
var checks: int = 0
var failures: Array[String] = []
var samples: Array = []

func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--beta-dir="): directory = arg.trim_prefix("--beta-dir=")
		if arg.begins_with("--beta-case="): selected_case = arg.trim_prefix("--beta-case=")
	call_deferred("run_probe")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); print("BETA_PROBE_FAILED: "+label)

func write(path: String, value: String) -> void:
	FileAccess.open(path,FileAccess.WRITE).store_string(value)

func envelope(payload: Variant) -> String:
	var text: String = JSON.stringify(payload,"",true,true)
	return JSON.stringify({"payload":text,"checksum":text.sha256_text()})

func finish() -> void:
	var report: Dictionary = {"case":selected_case,"checks":checks,"failures":failures,"samples":samples,"edition":29,"scope":"Isolated current-engine edge probes. Explicit synthetic fixtures are not natural campaign victories."}
	write(directory.path_join(selected_case+".json"),JSON.stringify(report,"  "))
	print("QA beta-probe "+JSON.stringify({"case":selected_case,"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)

func run_probe() -> void:
	if directory.is_empty(): quit(2); return
	DirAccess.make_dir_recursive_absolute(directory)
	var game: RefCounted = Game.new()
	if selected_case.begins_with("save-"):
		malformed_save(game); finish(); return
	if selected_case=="profiles": profile_edges(); finish(); return
	if selected_case=="migrations": migrations(game); finish(); return
	if selected_case=="legacy-load": legacy_loads(game); finish(); return
	if selected_case=="legacy-forecast": await legacy_forecast(); finish(); return
	if selected_case=="openings": await openings(game); finish(); return
	seed_matrix(game); finish()

func seed_matrix(game: RefCounted) -> void:
	var signatures: Dictionary = {}
	for starter: int in [1,4,7,25,133,144,150,151]:
		for index: int in 16:
			var seed_text: String = "beta-%d-%d" % [starter,index]
			var state: Dictionary = game.create(seed_text,starter)
			var second: Dictionary = game.create(seed_text,starter)
			check(not state.is_empty() and Ledger.equivalent(state,second),"Deterministic create "+seed_text)
			check(state.party.size()==1 and state.party[0].level==5 and state.reserve.is_empty(),"Fresh starter rules "+seed_text)
			var original: Dictionary = state.duplicate(true)
			var first: Dictionary = game.transact(state,{"kind":"enter","at":state.revision})
			check(first.ok and Ledger.equivalent(state,original),"Encounter entry preserves input "+seed_text)
			if not first.ok: continue
			var battle: Dictionary = first.state.battle
			signatures[JSON.stringify(battle.rng)] = true
			var before: Dictionary = battle.duplicate(true)
			var order: Dictionary = game.engine.choose_command(battle)
			check(not order.is_empty() and Ledger.equivalent(before,battle),"AI query is pure "+seed_text)
			check(Share.decode(Share.encode(state)).get("starter")==starter,"Share starter roundtrip "+seed_text)
			for command: Dictionary in [{"kind":"capture","at":state.revision},{"kind":"finish","at":state.revision},{"kind":"enter","at":state.revision-1}]:
				check(not game.transact(state,command).ok and Ledger.equivalent(state,original),"Wrong phase/stale command is pure "+seed_text)
	check(signatures.size()>100,"Seed matrix varies encounter RNG across128 starts")
	samples.append({"starts":128,"distinctRng":signatures.size(),"starters":[1,4,7,25,133,144,150,151]})
	for length: int in [1,64]:
		var state: Dictionary = game.create("á".repeat(length),1)
		check(not state.is_empty() and not Share.decode(Share.encode(state)).is_empty(),"Unicode seed roundtrip length "+str(length))

func malformed_save(game: RefCounted) -> void:
	var path: String = directory.path_join(selected_case+"-campaign.dat")
	var state: Dictionary = game.create("beta-corrupt",1)
	var store: RefCounted = Ledger.new(path); store.prime(game)
	check(store.save(state,[],"current").ok,"Initial save for "+selected_case)
	var outer: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var payload: Dictionary = JSON.parse_string(outer.payload)
	match selected_case:
		"save-truncated": write(path,"{\"payload\":")
		"save-checksum": outer.checksum = "invalid"; write(path,JSON.stringify(outer))
		"save-array": write(path,envelope([]))
		"save-future": payload.version = 99; write(path,envelope(payload))
		"save-seed-long": payload.seed = "a".repeat(65); write(path,envelope(payload))
		"save-state-array": payload.state = []; write(path,envelope(payload))
		"save-command-null": payload.commands = [null]; write(path,envelope(payload))
		"save-command-array": payload.commands = [[]]; write(path,envelope(payload))
		"save-kind-array": payload.commands = [{"kind":[],"at":0}]; write(path,envelope(payload))
		"save-order-null": payload.commands = [{"kind":"enter","at":0},{"kind":"battle","order":null,"at":1}]; write(path,envelope(payload))
		"save-money-edit": payload.state.money += 1; write(path,envelope(payload))
		"save-size": write(path," ".repeat(17*1024*1024))
	var original: String = FileAccess.get_sha256(path)
	var loaded: Dictionary = Ledger.new(path).load_campaign(game)
	check(not loaded.get("ok",false),"Malformed campaign rejected: "+selected_case)
	check(FileAccess.get_sha256(path)==original,"Malformed campaign original retained: "+selected_case)
	samples.append({"result":loaded.get("reason",""),"preserved":FileAccess.get_sha256(path)==original})

func profile_edges() -> void:
	var path: String = directory.path_join("perfil Álex con espacios.json")
	var a: RefCounted = Profiles.new(path); a.load_profile()
	var profile: RefCounted = Trainer.new()
	check(a.save(profile.data).ok,"Unicode/spaces profile path saves")
	var b: RefCounted = Profiles.new(path); b.load_profile()
	profile.customize("Álex",25,"Entrenador","amber")
	check(a.save(profile.data).ok,"First writer commits")
	var original: String = FileAccess.get_sha256(path)
	check(not b.save(Trainer.new().data).ok and FileAccess.get_sha256(path)==original,"Stale second writer cannot overwrite profile")
	var broken: Dictionary = profile.data.duplicate(true); broken.version = 99
	write(path,envelope(broken)); original = FileAccess.get_sha256(path)
	var future: RefCounted = Profiles.new(path)
	check(not future.load_profile().ok,"Future profile blocks automatic loading")
	check(not future.save(profile.data).ok and FileAccess.get_sha256(path)==original,"Future profile cannot be overwritten")
	write(path,"broken profile"); original = FileAccess.get_sha256(path)
	var recovering: RefCounted = Profiles.new(path)
	var recovery: Dictionary = recovering.load_profile()
	check(not recovery.ok and not recovering.recovery.is_empty(),"Corrupt profile offers backup")
	check(not recovering.save(profile.data).ok and FileAccess.get_sha256(path)==original,"Recovery is explicit")
	check(recovering.save(profile.data,true).ok and Profiles.new(path).load_profile().ok,"Explicit recovery restores valid profile")
	var preserved: bool = false
	for name_text: String in DirAccess.get_files_at(directory):
		if name_text.begins_with("perfil Álex con espacios.json.damaged-"): preserved = true
	check(preserved,"Damaged original is preserved separately")

func migrations(game: RefCounted) -> void:
	for edition: int in range(12,29):
		var started: int = Time.get_ticks_msec()
		write(directory.path_join("progress.json"),JSON.stringify({"edition":edition,"stage":"upgrade","completed":samples}))
		var path: String = directory.path_join("migration-%d.dat" % edition)
		var reader: RefCounted = Ledger.new(path)
		var old_game: RefCounted = reader._rules(edition)
		var state: Dictionary = old_game.create("beta-migrate-"+str(edition),1)
		check(int(state.edition)==edition,"Correct legacy factory "+str(edition))
		var before: Dictionary = state.duplicate(true)
		var command: Dictionary = {"kind":"upgrade","edition":29,"at":state.revision}
		var upgraded: Dictionary = game.transact(state,command)
		check(upgraded.ok and Ledger.equivalent(before,state),"Explicit upgrade does not mutate original "+str(edition))
		if not upgraded.ok: continue
		check(upgraded.state.edition==29 and upgraded.state.rng==state.rng and upgraded.state.revision==state.revision+1,"Upgrade edition/RNG/revision "+str(edition))
		var upgrade_ms: int = Time.get_ticks_msec()-started
		write(directory.path_join("progress.json"),JSON.stringify({"edition":edition,"stage":"save","upgradeMs":upgrade_ms,"completed":samples}))
		check(reader.save(upgraded.state,[command],"current").ok,"Mixed edition journal saves "+str(edition))
		DirAccess.remove_absolute(path+".verified")
		var load_started: int = Time.get_ticks_msec()
		var loaded: Dictionary = Ledger.new(path).load_campaign(game)
		check(loaded.get("ok",false) and Ledger.equivalent(loaded.get("state",{}),upgraded.state),"Cold mixed-edition replay "+str(edition))
		samples.append({"fromEdition":edition,"toEdition":29,"loaded":loaded.get("ok",false),"upgradeMs":upgrade_ms,"coldLoadMs":Time.get_ticks_msec()-load_started,"totalMs":Time.get_ticks_msec()-started})
		write(directory.path_join("progress.json"),JSON.stringify({"edition":edition,"stage":"complete","completed":samples}))

func legacy_loads(game: RefCounted) -> void:
	for edition: int in range(12,30):
		var path: String = directory.path_join("legacy-%d.dat" % edition)
		var store: RefCounted = Ledger.new(path)
		var old_game: RefCounted = store._rules(edition)
		var state: Dictionary = old_game.create("beta-legacy-"+str(edition),1)
		check(state.edition==edition and store.save(state,[],"current").ok,"Old-edition fixture saves "+str(edition))
		var original: String = FileAccess.get_sha256(path)
		var loaded: Dictionary = Ledger.new(path).load_campaign(game)
		check(loaded.get("ok",false) and Ledger.equivalent(loaded.get("state",{}),state),"Current reader loads legacy "+str(edition))
		check(FileAccess.get_sha256(path)==original,"Legacy load preserves original "+str(edition))
		samples.append({"edition":edition,"loaded":loaded.get("ok",false),"reason":loaded.get("reason","")})
		write(directory.path_join("progress.json"),JSON.stringify({"completed":samples}))

func openings(game: RefCounted) -> void:
	var captures: Dictionary = {}
	for starter: int in [1,4,7]:
		for index: int in 8:
			var state: Dictionary = game.create("beta-opening-%d-%d" % [starter,index],starter)
			var entered: Dictionary = game.transact(state,{"kind":"enter","at":state.revision})
			check(entered.ok,"Natural opening entry")
			if not entered.ok: continue
			state = entered.state
			var deployed: Dictionary = game.transact(state,{"kind":"start-battle","at":state.revision})
			check(deployed.ok,"Natural opening deployment completes")
			if not deployed.ok: continue
			state = deployed.state
			var orders: int = 0
			while state.phase=="battle" and orders<500:
				var before: Dictionary = state.duplicate(true)
				var command: Dictionary = game.engine.choose_command(state.battle)
				check(Ledger.equivalent(state,before),"Opening planner preserves RNG")
				var result: Dictionary = game.transact(state,{"kind":"battle","order":command,"at":state.revision})
				check(result.ok,"Opening AI order is legal")
				if not result.ok: break
				state = result.state; orders += 1
				check(state.money>=0 and state.revision==before.revision+1,"Opening economy/revision invariant")
				for unit: Dictionary in state.battle.units:
					check(unit.hp>=0 and unit.hp<=unit.maxHp,"HP within bounds")
				if orders%16==0: await process_frame
			check(state.phase!="battle","Opening terminates without artificial state edits")
			var recruited: int = int(state.get("reward",{}).get("speciesId",0))
			check(state.phase=="capture" and recruited>0,"Natural opening produces an actual local reward")
			captures[recruited] = true
			samples.append({"starter":starter,"seed":state.seed,"orders":orders,"phase":state.phase,"rewardSpecies":recruited,"rounds":state.battle.get("round",0)})
	check(captures.size()>1,"Different current seeds vary actual natural rewards")

func legacy_forecast() -> void:
	for edition: int in [12,18,19,29]:
		var store: RefCounted = Ledger.new(directory.path_join("forecast-%d.dat" % edition))
		var game: RefCounted = store._rules(edition)
		var state: Dictionary = game.create("beta-forecast",4)
		var entered: Dictionary = game.transact(state,{"kind":"enter","at":state.revision})
		check(entered.ok,"Forecast encounter enters "+str(edition))
		if not entered.ok: continue
		state = entered.state
		var deployed: Dictionary = game.transact(state,{"kind":"start-battle","at":state.revision})
		if deployed.ok: state = deployed.state
		var inspected: bool = false
		for index: int in 220:
			if state.phase!="battle": break
			var actor: Dictionary = game.engine.active(state.battle)
			for move: String in ["basic"]+actor.get("moves",[]):
				for target: Dictionary in game.engine.living(state.battle):
					var plan: Dictionary = game.engine.attack_plan(state.battle,int(target.id),{},move)
					if not plan.get("ok",false): continue
					var before: Dictionary = state.duplicate(true)
					var text: String = preload("res://ui/tactical_info.gd").forecast(target,plan)
					check(not text.is_empty() and Ledger.equivalent(before,state),"Valid forecast renders without mutation "+str(edition))
					samples.append({"edition":edition,"legalOrdersBeforePreview":index,"planHasDefinition":plan.has("definition"),"forecastNonempty":not text.is_empty()})
					inspected = true; break
				if inspected: break
			if inspected: break
			var command: Dictionary = game.engine.choose_command(state.battle)
			var step: Dictionary = game.transact(state,{"kind":"battle","order":command,"at":state.revision})
			if not step.ok: break
			state = step.state
			if index%8==0: await process_frame
		check(inspected,"Natural battle produces a valid inspection plan "+str(edition))
