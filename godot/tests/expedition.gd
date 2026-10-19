extends SceneTree

const Journey = preload("res://core/journey_run.gd")
const Store = preload("res://core/journey_store.gd")
var checks: int = 0
var failures: Array[String] = []

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var game: RefCounted = Journey.new(chapter_number())
	var state: Dictionary = game.create("tactics-1",1)
	check(state.edition==chapter_number()-4,"Chapter edition")
	check(game.progression.species.size()==151,"Complete Kanto catalog")
	for record: Dictionary in game.progression.data.species:
		check(game.progression.families.has(int(record.id)),"Family "+str(record.id))
		check(FileAccess.file_exists("res://"+record.face),"Portrait "+str(record.id))
		check(FileAccess.file_exists("res://"+record.animations.Idle.path),"Original sprite "+str(record.id))
		var member_data: Dictionary = game.progression.create_member(1,int(record.id),"QA catalog",50)
		game.progression.assign(member_data,"catalog")
		check(member_data.moves.size()<=4 and not member_data.knownMoves.is_empty(),"Learnset "+str(record.id))
		check(game.progression.member_stats(member_data).maxHp>0,"Stats "+str(record.id))
	for table: String in game.progression.expansion.encounters:
		for entry: Dictionary in game.progression.expansion.encounters[table]:
			var record: Dictionary = game.progression.species[int(entry.speciesId)]
			check(not record.legendary and not record.mythical and "flying" not in entry.method,"Safe local capture table "+table)
	var ids: Array = game.locations.map(func(n):return n.id)
	var flags: Array = []
	for location: Dictionary in game.locations: flags.append_array(location.get("grants",[]))
	for location: Dictionary in game.locations:
		for requirement: String in location.requires: check(requirement in ids or requirement in flags,"Known story requirement: "+requirement)
		if location.get("kind","")!="story" and not location.get("finale",false): check(game.progression.data.encounters.has(location.captureTable),"Reward table exists "+location.id)
	check(not game.transact(state,{"kind":"travel","location":"surge","at":0}).ok,"Locked destination cannot be skipped")
	var journal: Array = []
	var entering: Dictionary = {"kind":"enter","at":state.revision}
	var entered: Dictionary = game.transact(state,entering)
	check(entered.ok,"First encounter enters")
	if entered.ok:
		state = entered.state
		journal.append(entering)
		for index: int in 350:
			if state.phase!="battle": break
			var order: Dictionary = {"kind":"battle","order":game.engine.choose_command(state.battle),"at":state.revision}
			var result: Dictionary = game.transact(state,order)
			check(result.ok,"Legal first-battle order: "+str(result.get("reason","")))
			if not result.ok: break
			state = result.state
			journal.append(order)
		check(state.phase=="capture","Natural first encounter wins")
		var store: RefCounted = Store.new(output_dir().path_join("expedition-first.json"))
		check(store.save(state,journal,"journey").ok,"Save expanded first encounter")
		var replay: Dictionary = store.load_campaign(game)
		check(replay.ok and Store.equivalent(replay.state,state),"Expanded history replays")
	var report: Dictionary = {"checks":checks,"failures":failures,"chapter":chapter_number(),"locations":game.locations.size(),"species":game.progression.species.size(),"moves":game.progression.data.moves.size(),"normalAbilities":game.progression.traits.abilities.size(),"enabledAbilities":game.progression.traits.abilities.values().filter(func(a):return a.get("available",a.get("implemented",false))).size()}
	FileAccess.open(output_dir().path_join("expedition-core-result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)

func chapter_number() -> int:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--chapter="): return int(arg.trim_prefix("--chapter="))
	return 17

func output_dir() -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--save-dir="): return arg.trim_prefix("--save-dir=")
	return OS.get_user_data_dir()
