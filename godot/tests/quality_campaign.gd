extends SceneTree

const Game = preload("res://core/tactics_quality_run.gd")
const Store = preload("res://core/tactics_quality_store.gd")
const Policy = preload("res://ui/qa_quality_policy.gd")
var directory: String = ""
var campaign_seed: String = "release-33-kanto"
var starter: int = 1
var state: Dictionary = {}
var journal: Array = []
var encounters: Array = []
var failures: Array = []
var game: RefCounted
var policy: RefCounted
var store: RefCounted
var started: int = 0
var prefix_path: String = ""

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="): directory = argument.trim_prefix("--save-dir=")
		if argument.begins_with("--seed="): campaign_seed = argument.trim_prefix("--seed=")
		if argument.begins_with("--starter="): starter = int(argument.trim_prefix("--starter="))
		if argument.begins_with("--prefix="): prefix_path = argument.trim_prefix("--prefix=")
	call_deferred("review")

func record() -> void:
	var progress: Dictionary = {"seed":campaign_seed,"starter":starter,"edition":state.edition,"phase":state.phase,"orders":journal.size(),"cleared":state.cleared,"medals":state.medals,"encounters":encounters,"failures":failures,"seconds":(Time.get_ticks_msec()-started)/1000.0,"scope":"Natural legal-command campaign; automated player, not a human or external hardware test."}
	FileAccess.open(directory.path_join("campaign-review.json"),FileAccess.WRITE).store_string(JSON.stringify(progress,"  "))
	FileAccess.open(directory.path_join("campaign-journal.json"),FileAccess.WRITE).store_string(JSON.stringify({"seed":campaign_seed,"starter":starter,"commands":journal}))

func checkpoint(replay: bool = false) -> void:
	var saved: Dictionary = store.save(state,journal,"current")
	if not saved.ok: failures.append("Save: "+saved.get("reason",""))
	if replay and saved.ok:
		var loaded: Dictionary = Store.new(store.file_path).load_campaign(game)
		if not loaded.ok or not Store.equivalent(loaded.get("state",{}),state): failures.append("Replay: "+loaded.get("reason","state mismatch"))
		else: state = loaded.state
	record()

func review() -> void:
	if directory.is_empty(): quit(2); return
	DirAccess.make_dir_recursive_absolute(directory)
	game = Game.new(); policy = Policy.new(); started = Time.get_ticks_msec()
	store = Store.new(directory.path_join("natural-save.json"))
	state = game.create(campaign_seed,starter)
	if not prefix_path.is_empty():
		var prefix: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(prefix_path))
		for command: Dictionary in prefix.commands:
			var replayed: Dictionary = game.transact(state,command)
			if not replayed.ok: failures.append("Prefix rejected: "+replayed.get("reason","")); break
			journal.append(command); state = replayed.state
		encounters = []
		for entry: Dictionary in prefix.encounters:
			if int(entry.startedOrder)>=journal.size(): continue
			encounters = encounters.filter(func(e):return e.location!=entry.location)
			encounters.append(entry.duplicate(true))
	for step_index: int in 30000:
		if state.phase in ["defeat","ending"] or not failures.is_empty(): break
		var command: Dictionary = policy.choose(game,state)
		if command.is_empty(): failures.append("No legal continuation at "+str(state.stage)); break
		if command.kind=="enter":
			encounters.append({"location":game.locations[int(state.stage)].id,"entryMoney":state.money,"entryLevels":state.party.map(func(m):return m.level),"cap":game.level_cap(state),"startedOrder":journal.size(),"startedMs":Time.get_ticks_msec()})
			print("REVIEW_ENTER "+str(encounters[-1].location)+" · "+str(encounters[-1].entryLevels))
		var previous: Dictionary = state
		var result: Dictionary = game.transact(state,command)
		if not result.ok: failures.append(str(command)+": "+result.get("reason","")); break
		journal.append(command); state = result.state
		if state.cleared.size()>previous.cleared.size():
			encounters[-1].rounds = previous.get("battle",{}).get("round",0)
			encounters[-1].endMoney = state.money
			encounters[-1].reward = state.reward.get("speciesId",0)
			encounters[-1].orders = journal.size()-int(encounters[-1].startedOrder)
			encounters[-1].seconds = (Time.get_ticks_msec()-int(encounters[-1].startedMs))/1000.0
			print("REVIEW_CLEAR "+JSON.stringify(encounters[-1]))
			checkpoint(state.medals.size()!=previous.medals.size())
		elif step_index==20: checkpoint(true)
		elif step_index%100==0: checkpoint()
		if state.phase=="battle" and state.battle.round>70:
			failures.append("Stalled battle: "+str(game.locations[int(state.stage)].id)); break
		if step_index%8==0: await process_frame
	checkpoint(true)
	print("REVIEW_DONE "+JSON.stringify({"phase":state.phase,"cleared":state.cleared.size(),"failures":failures}))
	quit(0 if failures.is_empty() else 1)
