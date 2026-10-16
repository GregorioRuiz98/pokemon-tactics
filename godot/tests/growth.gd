extends "res://tests/shop.gd"

const Current = preload("res://core/growth_run.gd")

func growth_controls() -> void:
	run = rules.create("growth-controls",4)
	run.phase = "shop"
	run.money = 200
	check(act({"kind":"buy","item":"rare-candy"}) and run.money==175 and run.bag["rare-candy"]==1,"Candy costs 25, not 100")
	run.party[0].hp = 11
	run.party[0].xp = 37
	check(act({"kind":"level-up","member":1}),"Use one candy")
	check(run.party[0].level==6 and run.party[0].hp==11 and run.party[0].xp==37 and run.bag["rare-candy"]==0,"Candy adds one level, preserving HP and partial EXP")
	check(not act({"kind":"level-up","member":1}),"No candy cannot grant a level")
	check(not act({"kind":"evolve","member":1}),"Manual candy evolution removed")
	for bad: Dictionary in [{"kind":17},{"kind":"buy","item":{}},{"kind":"level-up","member":1.5},{"kind":"level-up","member":[]}]: check(not act(bad),"Malformed growth command rejected")
	for initial: int in [1,4,7]:
		var member: Dictionary = rules.progression.create_member(1,initial,"QA",15)
		member.hp = 9
		member.heldItem = "leftovers"
		var receipt: Dictionary = rules.progression.candy(member)
		check(member.speciesId==initial+1 and member.level==16 and member.hp==9 and member.heldItem=="leftovers" and receipt.evolutions.size()==1,"Starter evolves automatically at 16 without healing or losing equipment")
	for entry: Array in [[10,12,"mega-drain"],[13,15,"brick-break"]]:
		var member: Dictionary = rules.progression.create_member(1,int(entry[0]),"QA",5)
		member.hp = 17
		var steps: Array = []
		for i: int in 5: steps.append(rules.progression.candy(member))
		check(member.speciesId==entry[1] and member.level==10 and member.hp==17,"Bug line evolves at 7 and 10 without healing")
		check(steps[1].evolutions[0].level==7 and steps[4].evolutions[0].level==10,"Both exact evolution thresholds respected")
		check(entry[2] in member.knownMoves and entry[2] in member.moves and entry[2] in steps[4].learned,"Evolution coverage learned and prepared immediately when space exists")
		var exp_member: Dictionary = rules.progression.create_member(1,int(entry[0]),"QA",5)
		exp_member.hp = 13
		var receipt: Dictionary = rules.progression.award(exp_member,550)
		check(exp_member.level==10 and exp_member.speciesId==entry[1] and exp_member.hp==13 and receipt.evolutions.size()==2 and entry[2] in receipt.learned,"Multi-level victory EXP evolves both stages and teaches coverage")
	var full: Dictionary = rules.progression.create_member(1,14,"QA",9)
	full.knownMoves = ["poison-sting","string-shot","harden","protect"]
	full.moves = full.knownMoves.duplicate()
	rules.progression.candy(full)
	check(full.speciesId==15 and full.moves.size()==4 and "brick-break" in full.knownMoves and "brick-break" not in full.moves,"Full loadout keeps four while learning evolution move in library")
	var pika: Dictionary = rules.progression.create_member(1,25,"QA",6)
	check("iron-tail" not in pika.knownMoves,"Pikachu does not learn Iron Tail before 7")
	rules.progression.candy(pika)
	check(pika.level==7 and "iron-tail" in pika.knownMoves and "iron-tail" in pika.moves,"Pikachu learns Iron Tail at level 7")
	var unit: Dictionary = rules.engine.member_unit(pika)
	check(rules.engine.profile(unit).action(unit,"iron-tail")!=null,"New Pikachu move is executable through shared battle profile")
	for entry: Array in [[25,19,26],[75,35,76],[16,17,17],[19,19,20]]:
		var member: Dictionary = rules.progression.create_member(1,int(entry[0]),"QA",int(entry[1]))
		rules.progression.candy(member)
		check(member.speciesId==entry[2],"Automatic evolution reaches configured threshold")
	run.party[0].level = 99
	run.party[0].xp = 300
	run.bag["rare-candy"] = 2
	check(act({"kind":"level-up","member":1}) and run.party[0].level==100 and run.party[0].xp==0,"Level 100 cap clears unusable EXP")
	var before: Dictionary = run.duplicate(true)
	check(not act({"kind":"level-up","member":1}) and Store.equivalent(before,run),"Cap does not consume another candy or change revision")
	run.party[0].hp = 0
	check(not act({"kind":"level-up","member":1}),"Candy cannot revive a fallen member")
	var dead: Dictionary = run.party[0].duplicate(true)
	rules.progression.award(run.party[0],10000)
	check(Store.equivalent(dead,run.party[0]),"No posthumous XP, evolution or learning")
	run.phase = "battle"
	check(not act({"kind":"level-up","member":1}),"No candy in battle")
	run.phase = "shop"
	run.money = 24
	check(not act({"kind":"buy","item":"rare-candy"}),"Insufficient candy funds rejected")
	check(not rules.transact(run,{"kind":"buy","item":"rare-candy","at":run.revision-1}).ok,"Stale candy purchase callback cannot charge again")

func improve_team() -> void:
	for entry: Dictionary in run.party:
		if entry.hp<=0: continue
		var goal: int = entry.level
		if int(entry.speciesId) in [10,11,13,14] and run.stage==2: goal = 10
		if entry.speciesId==25 and run.stage==2: goal = 7
		var member: Dictionary = rules.target(run,int(entry.id))
		while member.level<goal and (run.bag["rare-candy"]>0 or run.money>=25):
			if run.bag["rare-candy"]==0: check(act({"kind":"buy","item":"rare-candy"}),"Buy cheaper level")
			check(act({"kind":"level-up","member":member.id}),"Use candy and resolve automatic growth")
			member = rules.target(run,int(entry.id))
	heal_team()

func _initialize() -> void:
	rules = Current.new()
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="): directory = argument.trim_prefix("--save-dir=")
	if directory.is_empty(): quit(1); return
	controls()
	combat_controls()
	growth_controls()
	# Every published campaign edition still selects its own engine.
	for script: String in ["kanto_run","progression_run","shop_run"]:
		var old_rules: RefCounted = load("res://core/"+script+".gd").new()
		var order: Dictionary = {"kind":"enter","at":0}
		var old: Dictionary = old_rules.transact(old_rules.create("legacy-growth",4),order)
		var archive: Store = Store.new(directory.path_join("growth-legacy-"+script+".json"))
		check(archive.save(old.state,[order],"").ok,"Archive old edition")
		var loaded: Dictionary = archive.load_campaign(rules)
		check(loaded.ok and Store.equivalent(loaded.state,old.state),"Old edition keeps battle, RNG and economy")
	var outcomes: Array = []
	var bug_before_brock: bool = false
	for starter: int in [1,4,7]:
		run = rules.create("kanto-14",starter)
		journal = []
		var archive: Store = Store.new(directory.path_join("growth-%d.json" % starter))
		for step: int in 1500:
			if run.phase in ["complete","defeat"]: break
			match run.phase:
				"map": check(act({"kind":"enter"}),"Enter growth encounter")
				"battle": check(act({"kind":"battle","order":rules.engine.choose_command(run.battle)}),"Legal shared engine command")
				"capture":
					if run.stage==3: check(run.reward.speciesId==95 and run.reward.level==14,"Onix ace reward retained")
					check(act({"kind":"capture"}),"Claim current reward")
				"shop":
					if starter==4 and run.stage==0:
						check(act({"kind":"buy-stock","slot":0}) and act({"kind":"teach","member":1,"item":"tm-brick-break"}),"Early coverage offer retained")
					improve_team()
					if run.stage==2:
						for member: Dictionary in run.party:
							if member.hp>0 and member.speciesId==15 and "brick-break" in member.knownMoves: bug_before_brock = true
					check(archive.save(run,journal,"").ok,"Save purchased levels, automatic forms and learned coverage")
					var loaded: Dictionary = archive.load_campaign(rules)
					check(loaded.ok and Store.equivalent(loaded.state,run),"Exact edition-4 replay after growth and evolution")
					check(act({"kind":"continue"}),"Continue after preparing levels")
		check(run.phase in ["complete","defeat"],"Growth campaign terminates")
		outcomes.append({"starter":starter,"phase":run.phase,"cleared":run.cleared.size(),"transactions":journal.size(),"money":run.money,"party":run.party.map(func(m):return {"speciesId":m.speciesId,"level":m.level,"hp":m.hp,"moves":m.moves})})
	check(bug_before_brock,"Affordable candy actually enables Beedrill with coverage before Brock")
	check(outcomes.any(func(outcome):return outcome.phase=="complete"),"At least one complete new-rules journey")
	var output: Dictionary = {"checks":checks,"probe":probe,"bugBeforeBrock":bug_before_brock,"runs":outcomes,"failures":failures}
	var file: FileAccess = FileAccess.open(directory.path_join("growth-result.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(output,"  "))
	file.close()
	print(JSON.stringify(output))
	quit(0 if failures.is_empty() else 1)
