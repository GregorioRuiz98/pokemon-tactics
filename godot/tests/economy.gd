extends SceneTree

const Game = preload("res://core/economy_run.gd")
const Store = preload("res://core/economy_store.gd")
var checks: int = 0
var failures: Array[String] = []
var game: RefCounted

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition: failures.append(label); print("ECONOMY_FAILED "+label)

func _initialize() -> void:
	call_deferred("test_all")

func test_all() -> void:
	game = Game.new()
	var run: Dictionary = game.create("economy-test",4)
	check(run.edition==20 and run.chapter==24,"Current edition")
	for item: String in game.RETIRED:
		check(not game.consumables.has(item) and run.bag[item]==0,"Retired "+item)
		check(not game.transact(run,{"kind":"buy","item":item,"at":run.revision}).ok,"Cannot buy "+item)
	for identity: int in range(1,152):
		var probe: Dictionary = game.progression.create_member(identity,identity,"Test",5)
		check(game.progression.member_next_xp(probe)>0,"Species curve "+str(identity))
	for curve: Array in game.progression.economy.curves.values():
		for level: int in range(2,101): check(curve[level]>curve[level-1],"Monotone growth "+str(level))
	# Even spending every earned dollar cannot cap a healthy starter before Brock.
	for starter_id: int in [1,4,7]:
		var projection: Dictionary = game.create("no-early-cap",starter_id)
		game.progression.gym_cap = 14
		var curve: Array = game.progression.economy.curves[str(int(game.progression.economy.growthGroups[str(starter_id)]))]
		for stage: int in 3:
			game.progression.award(projection.party[0],int(game.locations[stage].xp))
			projection.money += int(game.locations[stage].money)
			var missing: int = int(curve[14])-int(curve[int(projection.party[0].level)])-int(projection.party[0].xp)
			check(missing>projection.money,"No first-route instant cap even with all money and no healing "+str(starter_id)+"/"+str(stage))
	run.phase = "shop"
	run.money = 10000
	var member: Dictionary = run.party[0]
	var total: int = game.progression.member_next_xp(member)
	var full: Dictionary = game.training_quote(run,member)
	member.xp = total-1
	var one: Dictionary = game.training_quote(run,member)
	check(full.price==total and one.price==1 and one.points==1,"Price is exactly remaining EXP")
	var before: Dictionary = run.duplicate(true)
	var trained: Dictionary = game.transact(run,{"kind":"train-xp","member":1,"price":one.price,"points":one.points,"at":run.revision})
	check(trained.ok and trained.state.party[0].level==6 and trained.state.party[0].xp==0 and trained.state.money==9999,"One-point topup grants exactly one level")
	check(Store.equivalent(run,before),"Training input immutable")
	var poor: Dictionary = run.duplicate(true);poor.money = 0
	check(not game.transact(poor,{"kind":"train-xp","member":1,"price":one.price,"points":one.points,"at":poor.revision}).ok,"No training without funds")
	check(not game.transact(run,{"kind":"train-xp","member":1,"price":0,"points":1,"at":run.revision}).ok,"Reject forged quote")
	member.level = 14; member.xp = 0
	check(not game.training_quote(run,member).ok,"Gym cap cannot be bought past")
	member.level = 5;member.hp = 0
	check(not game.training_quote(run,member).ok,"No training fainted member")
	member.hp = 20; member.xp = 0
	var old_max: int = game.progression.member_stats(member).maxHp
	one = game.training_quote(run,member)
	trained = game.transact(run,{"kind":"train-xp","member":1,"price":one.price,"points":one.points,"at":run.revision})
	check(trained.state.party[0].hp==20+game.progression.member_stats(trained.state.party[0]).maxHp-old_max,"Level-up restores only gained max HP")
	for identity: String in game.progression.economy.freeEvolutions:
		for option: Array in game.progression.economy.freeEvolutions[identity]:
			var specimen: Dictionary = game.progression.create_member(50,int(identity),"Evolution",int(option[1])-1)
			run.reserve = [specimen]
			check(not game.transact(run,{"kind":"evolve-free","member":50,"species":option[0],"at":run.revision}).ok,"Evolution lower bound "+identity)
			specimen.level = int(option[1]); specimen.hp = 1
			var evolved: Dictionary = game.transact(run,{"kind":"evolve-free","member":50,"species":option[0],"at":run.revision})
			check(evolved.ok and evolved.state.reserve[0].speciesId==option[0] and evolved.state.reserve[0].hp==1 and evolved.state.money==run.money,"Free chosen evolution "+identity)
	run.phase = "capture"; run.stage = 1; run.reward = game.progression.create_member(2,16,"Route",5)
	run.reserve = []
	before = run.duplicate(true)
	for i: int in 12: game.capture_options(run); game.capture_price(run)
	check(Store.equivalent(run,before),"Reroll previews preserve RNG")
	poor = run.duplicate(true);poor.money = 0
	check(not game.transact(poor,{"kind":"reroll-capture","at":poor.revision}).ok,"No reroll without funds")
	for i: int in 5:
		var cost: int = game.capture_price(run)
		var first: Dictionary = game.transact(run,{"kind":"reroll-capture","at":run.revision})
		var again: Dictionary = game.transact(run,{"kind":"reroll-capture","at":run.revision})
		check(first.ok and Store.equivalent(first.state,again.state) and first.state.reward.speciesId!=run.reward.speciesId,"Deterministic different local species")
		check(first.state.money==run.money-cost and first.state.reward.level==run.reward.level and first.state.nextId==run.nextId,"Reroll price, identity and level")
		run = first.state
		check(game.capture_price(run)==cost+60,"Increasing reroll cost")
	run.stage = 3
	check(game.capture_options(run).is_empty() and not game.transact(run,{"kind":"reroll-capture","at":run.revision}).ok,"Gym ace cannot reroll")
	for width: int in [16,24]:
		run = game.create("gym-spawns",1); run.mapSize = width
		for i: int in game.locations.size():
			var location: Dictionary = game.locations[i]
			if not location.get("leader",false): continue
			run.stage = i
			var state: Dictionary = game.engine.encounter(run,location)
			var foes: Array = state.units.filter(func(u):return u.team=="enemy")
			check(foes.size()==location.team.size() and foes.size()>=4 and foes.size()<=6,"Expanded gym spawns "+location.id)
			var places: Array = []
			for foe: Dictionary in foes:
				var point: String = "%d,%d" % [foe.x,foe.y]
				check(point not in places and foe.x>=0 and foe.x<width and foe.y>=0 and foe.y<width and foe.moves.size()<=4,"Legal gym unit "+location.id)
				places.append(point)
	var legacy: RefCounted = load("res://core/spatial_run.gd").new()
	run = legacy.create("migration-economy",4);run.phase = "shop";run.party[0].xp = 45;run.bag["rare-candy"] = 2;run.bag["fire-stone"] = 1
	var upgraded: Dictionary = game.transact(run,{"kind":"upgrade","edition":20,"at":run.revision})
	check(upgraded.ok and upgraded.state.economyRefund==130 and upgraded.state.money==run.money+130,"Upgrade refunds obsolete stock")
	check(upgraded.state.party[0].xp==int(game.progression.member_next_xp(run.party[0])*0.5) and upgraded.state.party[0].hp==run.party[0].hp,"Upgrade retains partial bar proportion and HP")
	var directory: String = "user://"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--save-dir="): directory = arg.get_slice("=",1)
	DirAccess.make_dir_recursive_absolute(directory)
	# Natural legacy19 journal, including an actual battle, purchases and upgrade.
	var historical: Dictionary = legacy.create("economy-1",1)
	var journal: Array = []
	for i: int in 300:
		if historical.phase=="shop": break
		var command: Dictionary = {"kind":"enter","at":historical.revision}
		if historical.phase=="battle": command = {"kind":"battle","order":legacy.engine.choose_command(historical.battle),"at":historical.revision}
		elif historical.phase=="capture": command.kind = "capture"
		var step: Dictionary = legacy.transact(historical,command)
		check(step.ok,"Historical opening order")
		if not step.ok: break
		journal.append(command);historical = step.state
		if historical.phase=="defeat": break
	check(historical.phase=="shop","Historical natural opening reaches shop")
	if historical.phase=="shop":
		for item: String in ["rare-candy","rare-candy","fire-stone"]:
			var purchase: Dictionary = {"kind":"buy","item":item,"at":historical.revision}
			var step: Dictionary = legacy.transact(historical,purchase)
			check(step.ok,"Historical purchase")
			if step.ok: historical = step.state;journal.append(purchase)
		var transition: Dictionary = {"kind":"upgrade","edition":20,"at":historical.revision}
		var migrated: Dictionary = game.transact(historical,transition)
		check(migrated.ok,"Natural upgrade")
		if migrated.ok:
			journal.append(transition)
			var file: RefCounted = Store.new(directory.path_join("natural-migrated.json"))
			check(file.save(migrated.state,journal,"journey").ok,"Persist upgraded historical journal")
			var replayed: Dictionary = Store.new(file.file_path).load_campaign(game)
			check(replayed.ok and Store.equivalent(replayed.get("state",{}),migrated.state),"Cold replay crosses19 to20 with retained journal")
	var result: Dictionary = {"checks":checks,"failures":failures}
	FileAccess.open(directory.path_join("economy-result.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print(JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
