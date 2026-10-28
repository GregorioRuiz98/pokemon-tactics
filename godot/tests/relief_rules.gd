extends SceneTree

const Game = preload("res://core/relief_run.gd")
const Previous = preload("res://core/closing_run.gd")
const Ledger = preload("res://core/relief_store.gd")
const Share = preload("res://core/relief_challenge.gd")
const Maps = preload("res://core/relief_maps.gd")
const Flat = preload("res://core/movement.gd")
var checks: int = 0
var failures: Array = []
var gallery: Array = []
var directory: String = ""

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="): directory = argument.trim_prefix("--save-dir=")
	call_deferred("review")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label); print("RELIEF_FAILED "+label)

func review() -> void:
	if directory.is_empty(): quit(2); return
	DirAccess.make_dir_recursive_absolute(directory)
	var game: RefCounted = Game.new()
	var old: RefCounted = Previous.new()
	var fresh: Dictionary = game.create("relief-checks",1)
	check(fresh.edition==30 and fresh.startEdition==30,"New campaign edition30")
	check(game.locations==old.locations and game.engine.catalog.moves==old.engine.catalog.moves,"Encounter teams, rewards and numerical moves unchanged")
	for width: int in [16,24]:
		for index: int in game.locations.size():
			var run: Dictionary = game.create("relief-checks",1)
			run.stage = index; run.mapSize = width; run.party = []
			for species: int in [3,6,9,26,65,68]: run.party.append(game.progression.create_member(run.party.size()+1,species,"Geometry fixture",40))
			var original: Dictionary = run.duplicate(true)
			var state: Dictionary = game.engine.encounter(run,game.locations[index])
			var name: String = game.locations[index].id+"/"+str(width)
			check(Ledger.equivalent(original,run),name+" encounter leaves adventure and RNG untouched")
			check(Ledger.equivalent(state,game.engine.encounter(run,game.locations[index])),name+" deterministic geometry and initial abilities")
			check(state.combatEdition==25 and state.relief.id==game.locations[index].id,name+" actual engine and map")
			var reached: Dictionary = Maps.flood(state,state.units[0])
			var occupied: Dictionary = {}
			for unit: Dictionary in state.units:
				check(not occupied.has(Flat.key(unit)),name+" unique spawn "+str(unit.id)); occupied[Flat.key(unit)] = true
				check(reached.has(Flat.key(unit)),name+" ground access to spawn "+str(unit.id))
			for point: Dictionary in state.arena.deployment+state.get("mission",{}).get("points",[]): check(reached.has(Flat.key(point)),name+" ground access to deployment/objective "+Flat.key(point))
			for pair: Array in state.arena.portals:
				for point: Dictionary in pair: check(reached.has(Flat.key(point)),name+" portal connected")
			var tiers: Dictionary = {}; var flat_shelves: int = 0
			for y: int in state.heights.size():
				for x: int in state.heights[y].size():
					tiers[int(state.heights[y][x])] = true
					if x+1<width and y+1<width and state.heights[y][x]>0 and state.heights[y][x]==state.heights[y][x+1] and state.heights[y][x]==state.heights[y+1][x] and state.heights[y][x]==state.heights[y+1][x+1]: flat_shelves += 1
			check(tiers.size()>=3 and flat_shelves>=12,name+" broad elevated shelves")
			check(state.landscape.props.size()>=4,name+" thematic obstacles")
			var before: Dictionary = state.duplicate(true)
			game.engine.start_battle(state)
			for step: int in 3:
				if state.outcome!="playing": break
				var unchanged: Dictionary = state.duplicate(true)
				var command: Dictionary = game.engine.choose_command(state)
				check(Ledger.equivalent(unchanged,state),name+" planner does not consume RNG")
				var result: Dictionary = game.engine.apply_command(state,command)
				check(result.ok,name+" legal AI command "+str(command))
				if not result.ok: break
				state = result.state
			gallery.append({"id":game.locations[index].id,"mapSize":width,"tiers":tiers.size(),"shelves":flat_shelves,"reachable":reached.size(),"props":before.landscape.props.size(),"repairs":before.relief.repairs,"hash":JSON.stringify(before,"",true,true).sha256_text()})
			if index%4==0: await process_frame
	for edition: int in [13,16,18,29,30]:
		var rules: RefCounted = Ledger.new(directory.path_join("probe.json"))._rules(edition)
		var initial: Dictionary = rules.create("relief-save",4)
		var path: String = directory.path_join("edition-%d.json"%edition)
		var store: RefCounted = Ledger.new(path); store.prime(rules)
		check(store.save(initial,[],"current").ok,"Save edition "+str(edition))
		if FileAccess.file_exists(path+".verified"): DirAccess.remove_absolute(path+".verified")
		var loaded: Dictionary = Ledger.new(path).load_campaign(game)
		check(loaded.ok and Ledger.equivalent(initial,loaded.get("state",{})),"Cold replay edition "+str(edition))
	var prior: Dictionary = old.create("relief-mixed",4)
	var order: Dictionary = {"kind":"upgrade","edition":30,"at":prior.revision}
	var upgrade: Dictionary = game.transact(prior,order)
	check(upgrade.ok and upgrade.state.rng==prior.rng and upgrade.state.party==prior.party,"Upgrade preserves party and RNG")
	var mixed_path: String = directory.path_join("mixed.json")
	var mixed: RefCounted = Ledger.new(mixed_path); mixed.prime(game)
	check(mixed.save(upgrade.state,[order],"current").ok,"Mixed upgrade saved")
	if FileAccess.file_exists(mixed_path+".verified"): DirAccess.remove_absolute(mixed_path+".verified")
	var restored: Dictionary = Ledger.new(mixed_path).load_campaign(game)
	check(restored.ok and Ledger.equivalent(restored.get("state",{}),upgrade.state),"Mixed edition cold replay")
	prior.phase = "battle"
	check(not game.transact(prior,order).ok,"Cannot upgrade in battle")
	var frozen: Dictionary = Game.new(33).create("frozen-relief",1)
	check(Ledger.equivalent(Game.new(33).engine.encounter(frozen,old.locations[0]),old.engine.encounter(frozen,old.locations[0])),"Previous encounter remains byte-equivalent")
	for species: int in [1,25,133,145,150]:
		var challenge: Dictionary = Share.decode(Share.encode(game.create("relief-share",species)))
		check(challenge.get("edition")==30 and challenge.get("starter")==species,"KT40 starter "+str(species))
	check(Share.decode("KT40:garbage").is_empty() and Share.decode("KT40:").is_empty(),"Invalid share code rejected")
	var report: Dictionary = {"checks":checks,"failures":failures,"edition":30,"gallery":gallery,"mapCatalogHash":FileAccess.get_file_as_string("res://data/relief-maps.json").sha256_text(),"scope":"Synthetic terrain/AI fixtures for all58 locations at16/24; cold replay compatibility; not a natural campaign or human playtest."}
	FileAccess.open(directory.path_join("relief-rules.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print(JSON.stringify({"checks":checks,"failures":failures,"layouts":gallery.size()})); quit(0 if failures.is_empty() else 1)
