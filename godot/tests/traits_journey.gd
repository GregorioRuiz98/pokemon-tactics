extends "res://tests/growth.gd"

func _initialize() -> void:
	rules = load("res://core/traits_run.gd").new()
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="): directory = argument.trim_prefix("--save-dir=")
	var outcomes: Array = []
	var shop_seed: String = ""
	for index: int in 50:
		var seed: String = "trait-ui-"+str(index)
		var probe: Dictionary = rules.create(seed,1)
		var reward: int = rules.pick(probe,rules.locations[0].captureTable)
		if rules.progression.abilities(reward).size()==2:
			shop_seed = seed
			break
	for starter: int in [1,4,7]:
		for seed: String in ["tactics-1","tactics-4",shop_seed,"lgpe-9","lgpe-1","kanto-14","tactics-2","tactics-3"]:
			run = rules.create(seed,starter)
			journal = []
			for step: int in 1000:
				if run.phase in ["complete","defeat"]: break
				match run.phase:
					"map": check(act({"kind":"enter"}),"Enter trait encounter")
					"battle": check(act({"kind":"battle","order":rules.engine.choose_command(run.battle)}),"Legal trait command")
					"capture": check(act({"kind":"capture"}),"Claim fixed local traits")
					"shop":
						if starter==4 and run.stage==0: check(act({"kind":"buy-stock","slot":0}) and act({"kind":"teach","member":1,"item":"tm-brick-break"}),"Early coverage retained")
						improve_team()
						check(act({"kind":"continue"}),"Continue trait journey")
			var result: Dictionary = {"seed":seed,"starter":starter,"phase":run.phase,"cleared":run.cleared.size(),"commands":journal.size()}
			outcomes.append(result)
			print(JSON.stringify(result))
			var archive: Store = Store.new(directory.path_join("traits-journey-%d.json" % starter))
			check(archive.save(run,journal,"").ok,"Save full trait journey")
			var restored: Dictionary = archive.load_campaign(rules)
			check(restored.ok and Store.equivalent(run,restored.state),"Full replay preserves all traits, critical rolls and passive activations")
			if run.phase=="complete": break
	var output: Dictionary = {"shopSeed":shop_seed,"runs":outcomes,"checks":checks,"failures":failures}
	var file: FileAccess = FileAccess.open(directory.path_join("traits-journeys.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(output,"  "))
	file.close()
	print(JSON.stringify({"shopSeed":shop_seed,"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
