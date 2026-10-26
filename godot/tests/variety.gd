extends SceneTree

const Game = preload("res://core/adventure_run.gd")
const Store = preload("res://core/profile_campaign_store.gd")
const Tactics = preload("res://ui/tactical_loadouts.gd")
var checks: int = 0
var failures: Array[String] = []
var directory: String = ""

func _initialize() -> void:
	call_deferred("run_all")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition: failures.append(label); print("VARIETY_FAIL "+label)

func run_all() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="): directory = argument.trim_prefix("--save-dir=")
	if directory.is_empty(): quit(2); return
	DirAccess.make_dir_recursive_absolute(directory)
	var game: RefCounted = Game.new()
	var study: RefCounted = game.progression
	var counts: Dictionary = {}
	var catalogue: FileAccess = FileAccess.open(directory.path_join("variety-moves.csv"),FileAccess.WRITE)
	catalogue.store_csv_line(["id","nombre","tipo","categoria","potencia","precision","PT","alcance","forma","herramientas","familias"])
	for identity: String in study.data.moves:
		var move: Dictionary = study.data.moves[identity]
		var before: Dictionary = move.duplicate(true)
		var features: Array[String] = Tactics.tags(move)
		for feature: String in features: counts[feature] = int(counts.get(feature,0))+1
		var owners: Array[String] = []
		for family: Dictionary in study.data.families:
			if family.learnset.any(func(e):return e.id==identity): owners.append(family.id)
		catalogue.store_csv_line([identity,move.name,move.type,move.category,str(move.power),str(move.accuracy),str(move.cost),str(move.range),move.get("shapeName","individual")," / ".join(features)," / ".join(owners)])
		check(Store.equivalent(move,before),"Classification is read-only "+identity)
	catalogue.close()
	var builds: int = 0
	for species_id: int in study.species:
		for level: int in [5,14,30,60]:
			var member: Dictionary = study.create_member(1,species_id,"Read-only role fixture",level)
			var before: Dictionary = member.duplicate(true)
			for mode: int in 2:
				var kit: Dictionary = Tactics.propose(study,member,mode)
				check(kit.moves.size()<=4 and kit.moves.all(func(id):return id in member.knownMoves and id!="basic"),"Only learned moves "+str(species_id)+"/"+str(level))
				var unique: Dictionary = {}; for id: String in kit.moves: unique[id] = true
				check(unique.size()==kit.moves.size(),"No duplicate prepared moves")
				check(kit.moves.all(func(id):return not study.data.moves[id].get("selfKO",false)),"No automatic self-KO suggestion")
				check(kit==Tactics.propose(study,member,mode),"Deterministic proposals")
				builds += 1
			var future: Array = Tactics.learning(study,member,14)
			check(future.size()<=3,"Bounded learning preview")
			for entry: Dictionary in future: check(entry.level>member.level and entry.id not in member.knownMoves and entry.lockedByCap==(entry.level>14),"Actual future learning and cap")
			check(member==before,"Roles and learning preserve member")
	check("Zona" in Tactics.tags(study.data.moves.smokescreen) and "Control" not in Tactics.tags(study.data.moves.smokescreen),"Smoke is a local zone, not a permanent stat debuff")
	check("Disipa" in Tactics.tags(study.data.moves.gust) and "Empuje" in Tactics.tags(study.data.moves.gust),"Gust has actual push and dispel")
	check("Atracción" in Tactics.tags(study.data.moves["vine-whip"]),"Vine Whip actually pulls")
	var charmander: Dictionary = study.create_member(1,4,"Learning fixture",14)
	var charmander_future: Array = Tactics.learning(study,charmander,14)
	check(charmander_future.size()==3 and charmander_future[0].id=="fury-swipes" and charmander_future[0].level==18 and charmander_future[0].lockedByCap,"Charmander previews its actual next level18 move beyond Brock cap")
	check(charmander_future[1].id=="dragon-rage" and charmander_future[2].id=="fire-spin","Learning plan is ordered by level for the current form")
	check("Curación" in Tactics.tags(study.data.moves["leech-seed"]),"Leech Seed advertises actual draining recovery")
	check(Tactics.matches(study.data.moves.smokescreen,1) and Tactics.matches(study.data.moves.smokescreen,2) and not Tactics.matches(study.data.moves.smokescreen,3),"Smoke filters as area/zone, not displacement")
	check(Tactics.matches(study.data.moves.gust,1) and Tactics.matches(study.data.moves.gust,3) and Tactics.matches(study.data.moves.gust,5),"Gust filters as line, push and clearing support")
	check(not Tactics.matches(study.data.moves.scratch,1) and not Tactics.matches(study.data.moves.scratch,4),"Scratch is neither area nor control")
	check(Tactics.matches(study.data.moves.bubble,1) and not Tactics.matches(study.data.moves.bubble,2),"Bubble is an instant cone, not a persistent zone")
	check(Tactics.matches(study.data.moves["vine-whip"],3) and not Tactics.matches(study.data.moves["vine-whip"],1),"Vine Whip pulls one target rather than an area")
	check(Tactics.matches(study.data.moves["leech-seed"],4) and Tactics.matches(study.data.moves["leech-seed"],5),"Leech Seed is both status and draining support")
	check(Tactics.matches(study.data.moves["quick-attack"],3) and not Tactics.matches(study.data.moves["quick-attack"],2),"Quick Attack closes distance without creating a field")
	check(Tactics.matches(study.data.moves.growl,1) and Tactics.matches(study.data.moves.growl,4),"Growl combines a cone with a stat reduction")
	var run: Dictionary = game.create("variety-orders",4)
	var proposal: Dictionary = Tactics.propose(study,run.party[0],1)
	var command: Dictionary = {"kind":"loadout","member":1,"moves":proposal.moves,"at":run.revision}
	var accepted: Dictionary = game.transact(run,command)
	check(accepted.ok and accepted.state.rng==run.rng and accepted.state.money==run.money and accepted.state.party[0].hp==run.party[0].hp,"Existing loadout is free and RNG/HP preserving")
	var destination: String = directory.path_join("variety-replay-%d.json" % Time.get_ticks_usec())
	var store: RefCounted = Store.new(destination)
	check(store.save(accepted.state,[command],"journey").ok,"Suggested kit saves with existing journal format")
	var replay: Dictionary = Store.new(destination).load_campaign(game)
	check(replay.ok and Store.equivalent(replay.state,accepted.state),"Suggested kit replays on unchanged edition21")
	check(not game.transact(accepted.state,command).ok,"Stale proposal cannot overwrite a newer order")
	var entering: Dictionary = game.transact(accepted.state,{"kind":"enter","at":accepted.state.revision})
	command.at = entering.state.revision
	check(not game.transact(entering.state,command).ok,"No loadout during deployment or combat")
	opening_audit(game)
	var report: Dictionary = {"checks":checks,"failures":failures,"moves":study.data.moves.size(),"species":study.species.size(),"families":study.data.families.size(),"proposals":builds,"features":counts,"campaignEdition":21,"combatEdition":19,"rulesChanged":false}
	FileAccess.open(directory.path_join("variety-result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print(JSON.stringify(report)); quit(0 if failures.is_empty() else 1)

func opening_audit(game: RefCounted) -> void:
	var study: RefCounted = game.progression
	var pool: Dictionary = {1:"Inicial",4:"Inicial",7:"Inicial"}
	for location: Dictionary in game.locations.slice(0,3):
		for entry: Dictionary in study.data.encounters[location.captureTable]:
			if entry.special: continue
			var capture_id: int = int(entry.speciesId)
			if not pool.has(capture_id): pool[capture_id] = location.name
			elif location.name not in pool[capture_id]: pool[capture_id] += " / "+location.name
	var csv: FileAccess = FileAccess.open(directory.path_join("variety-opening.csv"),FileAccess.WRITE)
	csv.store_csv_line(["especie_inicial","especie_al_14","origen","rol_1","movimientos_1","rol_2","movimientos_2","mismas_opciones","siguiente_movimiento"])
	for species_id: int in pool:
		var member: Dictionary = study.create_member(1,species_id,"Opening-level fixture",5)
		study.gym_cap = 14
		study.award(member,100000)
		var first: Dictionary = Tactics.propose(study,member,0); var second: Dictionary = Tactics.propose(study,member,1)
		var left: Array = first.moves.duplicate(); var right: Array = second.moves.duplicate(); left.sort(); right.sort()
		var later: Array = Tactics.learning(study,member,14)
		check(member.level==14,"Opening audit respects Brock cap")
		csv.store_csv_line([study.species[species_id].name,study.species[int(member.speciesId)].name,pool[species_id],first.name,", ".join(first.moves.map(func(id):return study.data.moves[id].name)),second.name,", ".join(second.moves.map(func(id):return study.data.moves[id].name)),str(left==right)," / ".join(later.map(func(e):return study.data.moves[e.id].name+" Nv."+str(e.level)))])
	csv.close()
