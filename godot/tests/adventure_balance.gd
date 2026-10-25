extends SceneTree

const Game = preload("res://core/adventure_run.gd")
const Policy = preload("res://ui/qa_adventure_policy.gd")
const Store = preload("res://core/adventure_store.gd")
var results: Array = []
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run_all")

func run_all() -> void:
	var directory: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--save-dir="): directory = arg.trim_prefix("--save-dir=")
	if directory.is_empty(): quit(2); return
	var game: RefCounted = Game.new()
	var policy: RefCounted = Policy.new()
	for starter: int in [1,4,7]:
		for sample: int in 2:
			var state: Dictionary = game.create("economy-"+str(sample),starter)
			var journal: Array = []
			var row: Dictionary = {"starter":starter,"seed":state.seed,"fights":[],"spentTraining":0,"spentMedicine":0}
			for index: int in 6000:
				if "brock" in state.cleared or state.phase in ["defeat","ending"]: break
				var command: Dictionary = policy.choose(game,state)
				if command.is_empty(): failures.append("Policy stopped early"); break
				if command.kind=="enter": row.fights.append({"location":game.locations[int(state.stage)].id,"money":state.money,"levels":state.party.map(func(m):return m.level)})
				var step: Dictionary = game.transact(state,command)
				if not step.ok: failures.append(str(step.get("reason"))); break
				if command.kind=="train-xp": row.spentTraining += command.price
				if command.kind=="buy" and game.consumables.has(command.item): row.spentMedicine += game.consumables[command.item].price
				journal.append(command); state = step.state
				if state.phase=="battle" and state.battle.round>50: row.stalled = true; break
			row.phase = state.phase; row.medals = state.medals.size(); row.lastLocation = game.locations[int(state.stage)].id
			row.stats = state.tacticalStats; row.money = state.money
			row.party = state.party.map(func(m):return {"species":m.speciesId,"level":m.level,"hp":m.hp,"xp":m.xp})
			var path: String = directory.path_join("sample-%d-%d-%d.json" % [starter,sample,Time.get_ticks_usec()])
			var store: RefCounted = Store.new(path)
			var saved: Dictionary = store.save(state,journal,"journey")
			var loaded: Dictionary = Store.new(path).load_campaign(game) if saved.ok else {}
			row.replay = loaded.get("ok",false) and Store.equivalent(loaded.get("state",{}),state)
			if not row.replay: failures.append("Natural replay failed")
			results.append(row)
			print("ADVENTURE_SAMPLE "+JSON.stringify(row))
			FileAccess.open(directory.path_join("adventure-balance.json"),FileAccess.WRITE).store_string(JSON.stringify({"results":results,"failures":failures,"policy":"Automated AI with default deployment; existing economy policy for free evolutions, diverse learned moves and paid healing/training; no capture rerolls or TM purchases. Six fixed opening samples; defeats retained, no claim of human balance or complete Kanto."},"\t"))
	print(JSON.stringify({"runs":results.size(),"failures":failures})); quit(0 if failures.is_empty() else 1)
