extends SceneTree

const Campaign = preload("res://core/progression_run.gd")
const Legacy = preload("res://core/kanto_run.gd")
const Store = preload("res://core/kanto_store.gd")
var rules: Campaign = Campaign.new()
var failures: Array[String] = []
var checks: int = 0
var run: Dictionary = {}
var journal: Array = []

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)

func act(command: Dictionary) -> bool:
	command.at = run.revision
	var before: Dictionary = run.duplicate(true)
	var result: Dictionary = rules.transact(run,command)
	check(Store.equivalent(before,run),"Input remains immutable")
	if not result.ok: return false
	run = result.state
	journal.append(command.duplicate(true))
	return true

func controlled_tests() -> void:
	var study: RefCounted = rules.progression
	check(study.species.size()==26 and study.data.families.size()==10,"All 26 species belong to ten two-role families")
	for family: Dictionary in study.data.families:
		check(family.roles.size()==2 and family.roles[0]!=family.roles[1],"Two distinct roles: "+family.id)
		for entry: Dictionary in family.learnset: check(study.data.moves.has(entry.id),"Role references an existing move")
	var actor: Dictionary = rules.engine.member_unit(study.create_member(1,4,"Oak",5))
	var target: Dictionary = rules.engine.member_unit(study.create_member(2,1,"Test",5))
	var ember: RefCounted = rules.engine.profile(actor).action(actor,"ember")
	var normal: Dictionary = actor.duplicate(true)
	normal.types = ["normal"]
	check(ember.preview(actor,target).stab==1.5 and ember.preview(normal,target).stab==1,"STAB exactly 1.5 only on matching type")
	target.types = ["grass","bug"]
	check(ember.preview(actor,target).multiplier==4,"Double weaknesses multiply")
	var basic: RefCounted = rules.engine.profile(actor).action(actor,"basic")
	for types: Array in [["ghost"],["rock","steel"],["normal"],["water","ground"]]:
		target.types = types
		var preview: Dictionary = basic.preview(actor,target)
		check(preview.multiplier==1 and preview.stab==1 and preview.damage>0,"Neutral basic ignores types, immunity and STAB")
	var member: Dictionary = study.create_member(1,1,"Oak",5)
	member.hp = 17
	var original: Dictionary = study.stats(1,5)
	study.award(member,1000)
	var grown: Dictionary = study.stats(1,int(member.level))
	check(member.level>5 and member.hp==17,"Levels grow without healing")
	for key: String in ["maxHp","attack","defense","specialAttack","specialDefense","speed"]: check(grown[key]>original[key],"Stat grows by level: "+key)
	check("poison-powder" in member.knownMoves and member.moves.size()==4,"Learning records moves and never equips a fifth")
	run = rules.create("controls",1)
	run.phase = "shop"
	run.money = 1000
	run.bag["rare-candy"] = 2
	check(not act({"kind":"evolve","member":1}),"Evolution below required level rejected")
	check(run.bag["rare-candy"]==2,"Rejected evolution does not consume candy")
	run.party[0] = study.create_member(1,1,"Oak",40)
	run.party[0].hp = 13
	var all_moves: Array = run.party[0].knownMoves
	check(all_moves.size()>4,"Available library exceeds four slots")
	check(not act({"kind":"loadout","member":1,"moves":all_moves}),"Five equipped moves rejected")
	check(not act({"kind":"loadout","member":1,"moves":["vine-whip","vine-whip"]}),"Duplicate equipped move rejected")
	check(not act({"kind":"loadout","member":1,"moves":["flamethrower"]}),"Unknown move rejected")
	check(act({"kind":"loadout","member":1,"moves":all_moves.slice(1,5)}),"Free four-move mixture accepted")
	check(run.money==1000,"Preparing moves never costs money")
	check(rules.engine.profile(rules.engine.member_unit(run.party[0])).actions_for(rules.engine.member_unit(run.party[0])).size()==5,"Four prepared moves plus mandatory basic")
	check(not rules.transact(run,{"kind":17,"at":run.revision}).ok,"Malformed command rejected without a runtime exception")
	check(not rules.transact(run,{"kind":"buy","item":[],"at":run.revision}).ok,"Malformed item rejected")
	check(not act({"kind":"train","member":1,"stat":"attack"}),"No money-based stat training in edition 2")
	check(act({"kind":"evolve","member":1}),"Evolution at sufficient level accepted")
	check(run.party[0].speciesId==2 and run.party[0].hp==13 and run.party[0].level==40 and run.bag["rare-candy"]==1,"Candy evolves once without levels or healing")
	check(run.party[0].moves.size()<=4,"Evolution keeps loadout limit")
	run.party[0].hp = 0
	for kind: String in ["evolve","loadout","heal"]: check(not act({"kind":kind,"member":1,"moves":[],"item":"potion"}),"Dead member blocked: "+kind)
	var fixture: Dictionary = rules.engine.encounter(rules.create("debuff",1),rules.locations[0])
	fixture.queue = [1,10000]
	fixture.units[0].x = 2
	fixture.units[0].y = 7
	fixture.units[1].x = 3
	fixture.units[1].y = 7
	fixture.units[1].facing = 2
	var attack_before: int = fixture.units[1].attack
	var reduced: Dictionary = rules.engine.apply_command(fixture,{"kind":"attack","target":10000,"actionId":"growl"})
	check(reduced.ok and reduced.state.units[1].attack < attack_before and reduced.state.units[1].stages.attack==-1,"Growl lowers attack by one bounded stage")
	check(fixture.units[1].attack==attack_before,"Debuff leaves source immutable")
	var fresh: Dictionary = rules.engine.encounter(rules.create("debuff",1),rules.locations[0])
	check(fresh.units[1].stages.is_empty(),"Stages reset in a new battle")

func shop() -> void:
	for entry: Dictionary in run.party:
		if entry.hp<=0: continue
		var member: Dictionary = rules.target(run,int(entry.id))
		while member.hp < rules.engine.member_unit(member).maxHp-10:
			if run.bag.potion==0 and run.money>=40: act({"kind":"buy","item":"potion"})
			if run.bag.potion==0: break
			act({"kind":"heal","member":member.id,"item":"potion"})
			member = rules.target(run,int(entry.id))
		var evolution: Dictionary = rules.progression.evolution(member)
		if not evolution.is_empty() and member.level>=evolution.level:
			if run.bag["rare-candy"]==0 and run.money>=100: act({"kind":"buy","item":"rare-candy"})
			if run.bag["rare-candy"]>0: act({"kind":"evolve","member":member.id})

func _initialize() -> void:
	var directory: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--save-dir="): directory = arg.trim_prefix("--save-dir=")
	if directory.is_empty(): quit(1); return
	controlled_tests()
	var outcomes: Array = []
	for starter: int in [1,4,7]:
		run = rules.create("kanto-14",starter)
		journal = []
		var save: Store = Store.new(directory.path_join("progression-%d.json" % starter))
		for index: int in 1500:
			if run.phase in ["complete","defeat"]: break
			match run.phase:
				"map": check(act({"kind":"enter"}),"Enter with current level/loadout")
				"battle":
					var command: Dictionary = rules.engine.choose_command(run.battle)
					check(act({"kind":"battle","order":command}),"Shared AI produces legal move")
				"capture":
					var reward: Dictionary = run.reward.duplicate(true)
					var state: Dictionary = run.duplicate(true)
					check(save.save(run,journal,"").ok,"Save pending capture and earned EXP")
					var loaded: Dictionary = save.load_campaign(rules)
					check(loaded.ok and Store.equivalent(loaded.state,state),"Replay exact levels/EXP/reward without reroll")
					check(reward.level>=2 and reward.level<=5,"Capture uses original route slot level")
					var stale: Dictionary = {"kind":"capture","at":run.revision}
					check(act({"kind":"capture"}),"Claim once")
					check(not rules.transact(run,stale).ok,"Stale reward cannot award duplicate EXP or capture")
				"shop": shop(); check(act({"kind":"continue"}),"Continue route")
		check(run.phase in ["complete","defeat"],"Run terminates within budget")
		check(save.save(run,journal,"").ok,"Save result")
		var loaded: Dictionary = save.load_campaign(rules)
		check(loaded.ok and Store.equivalent(loaded.state,run),"Full canonical progression replay")
		outcomes.append({"starter":starter,"phase":run.phase,"cleared":run.cleared.size(),"orders":journal.size(),"party":run.party.map(func(m):return {"speciesId":m.speciesId,"level":m.level,"hp":m.hp})})
	# The unchanged edition-1 diary still replays using edition-1 rules.
	var legacy: Legacy = Legacy.new()
	var old: Dictionary = legacy.create("legacy",7)
	var step: Dictionary = legacy.transact(old,{"kind":"enter","at":0})
	var archive: Store = Store.new(directory.path_join("legacy-compat.json"))
	check(archive.save(step.state,[{"kind":"enter","at":0}],"").ok,"Save old edition")
	var continued: Dictionary = archive.load_campaign(rules)
	check(continued.ok and Store.equivalent(continued.state,step.state) and not continued.state.has("edition"),"Old edition continues without converting battle or RNG")
	var output: Dictionary = {"checks":checks,"runs":outcomes,"failures":failures}
	var file: FileAccess = FileAccess.open(directory.path_join("progression-result.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(output,"  "))
	file.close()
	print(JSON.stringify(output))
	quit(0 if failures.is_empty() else 1)
