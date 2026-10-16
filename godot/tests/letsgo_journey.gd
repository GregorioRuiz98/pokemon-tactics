extends "res://tests/growth.gd"

func _initialize() -> void:
	rules = load("res://core/letsgo_run.gd").new()
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="): directory = argument.trim_prefix("--save-dir=")
	var outcomes: Array = []
	for starter: int in [1,4,7]:
		for seed_number: int in range(12):
			var seed: String = "kanto-14" if seed_number==0 else "lgpe-%d" % seed_number
			run = rules.create(seed,starter)
			journal = []
			for step: int in 1400:
				if run.phase in ["complete","defeat"]: break
				match run.phase:
					"map": check(act({"kind":"enter"}),"Enter LGPE route")
					"battle": check(act({"kind":"battle","order":rules.engine.choose_command(run.battle)}),"Legal LGPE command")
					"capture": check(act({"kind":"capture"}),"Claim LGPE capture")
					"shop":
						if starter==4 and run.stage==0:
							check(act({"kind":"buy-stock","slot":0}) and act({"kind":"teach","member":1,"item":"tm-brick-break"}),"LGPE TM13")
						improve_team()
						check(act({"kind":"continue"}),"Continue LGPE route")
			outcomes.append({"seed":seed,"starter":starter,"phase":run.phase,"cleared":run.cleared.size(),"commands":journal.size()})
			print(JSON.stringify(outcomes[-1]))
			if run.phase=="complete": break
	var file: FileAccess = FileAccess.open(directory.path_join("letsgo-journeys.json"),FileAccess.WRITE)
	if file==null: push_error("A writable absolute save directory is required."); quit(1); return
	file.store_string(JSON.stringify(outcomes,"\t"))
	print(JSON.stringify({"journeys":outcomes,"failures":failures,"checks":checks}))
	quit(0 if failures.is_empty() else 1)
