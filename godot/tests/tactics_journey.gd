extends "res://tests/growth.gd"

func _initialize() -> void:
	rules = load("res://core/tactics_run.gd").new()
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="): directory = argument.trim_prefix("--save-dir=")
	var outcomes: Array = []
	for starter: int in [1,4,7]:
		for seed: String in ["lgpe-9","lgpe-1","kanto-14","tactics-1","tactics-2","tactics-3","tactics-4","tactics-5"]:
			run = rules.create(seed,starter)
			journal = []
			for step: int in 1000:
				if run.phase in ["complete","defeat"]: break
				match run.phase:
					"map": check(act({"kind":"enter"}),"Enter tactical route")
					"battle": check(act({"kind":"battle","order":rules.engine.choose_command(run.battle)}),"Legal tactical command")
					"capture": check(act({"kind":"capture"}),"Claim local capture")
					"shop":
						if starter==4 and run.stage==0: check(act({"kind":"buy-stock","slot":0}) and act({"kind":"teach","member":1,"item":"tm-brick-break"}),"Early coverage TM")
						improve_team()
						check(act({"kind":"continue"}),"Continue tactical route")
			var result: Dictionary = {"seed":seed,"starter":starter,"phase":run.phase,"cleared":run.cleared.size(),"commands":journal.size()}
			outcomes.append(result)
			print(JSON.stringify(result))
			if run.phase=="complete":
				var store: Store = Store.new(directory.path_join("tactics-complete-%d.json" % starter))
				check(store.save(run,journal,"").ok,"Save completed tactical campaign")
				var restored: Dictionary = store.load_campaign(rules)
				check(restored.ok and Store.equivalent(restored.state,run),"Full campaign replay preserves every critical/damage roll")
				break
	var file: FileAccess = FileAccess.open(directory.path_join("tactics-journeys.json"),FileAccess.WRITE)
	if file==null: push_error("A writable absolute save directory is required."); quit(1); return
	file.store_string(JSON.stringify({"runs":outcomes,"checks":checks,"failures":failures},"\t"))
	print(JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
