extends SceneTree

const Current = preload("res://core/gym_run.gd")
const Store = preload("res://core/kanto_store.gd")
var checks: int = 0
var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)

func progression_cases() -> void:
	var rules: RefCounted = Current.new()
	var study: RefCounted = rules.progression
	var run: Dictionary = rules.create("gym-cap",4)
	check(run.edition==8 and rules.gym_limit(run)=={"level":14,"leader":rules.locations[3].name,"speciesId":95},"The next gym's real ace determines the cap")
	check(study==rules.engine.progression,"Combat and campaign share capped progression")
	for identity: int in study.species:
		var member: Dictionary = study.create_member(1,identity,"QA",5)
		member.hp = 11
		member.xp = 37
		member.heldItem = "life-orb"
		var maximum: int = study.stats(identity,5).maxHp
		var remaining: int = -37
		for level: int in range(5,14): remaining += study.next_xp(level)
		var receipt: Dictionary = study.award(member,100000)
		check(member.level==14 and member.xp==0 and receipt.xp==remaining and receipt.xpDiscarded==100000-remaining,"Huge EXP reaches 14 exactly without banking excess")
		check(member.hp==11+study.stats(int(member.speciesId),14).maxHp-maximum and member.heldItem=="life-orb" and member.moves.size()<=4,"HP growth, evolution, equipment and loadout survive capping")
		var before: Dictionary = member.duplicate(true)
		check(study.award(member,650).xp==0 and Store.equivalent(member,before),"No XP, healing or growth at the cap")
		check(study.candy(member).hpGain==0 and Store.equivalent(member,before),"Direct candy growth also respects the cap")
	var near: Dictionary = study.create_member(1,4,"QA",13)
	near.xp = study.next_xp(13)-1
	near.hp = 11
	var receipt: Dictionary = study.award(near,2)
	check(near.level==14 and near.xp==0 and receipt.xp==1 and receipt.xpDiscarded==1 and near.speciesId==4,"Last point reaches the cap; no premature Charmeleon")
	near = study.create_member(1,4,"QA",13)
	near.xp = 99
	study.candy(near)
	check(near.level==14 and near.xp==0,"Candy discards partial EXP when it reaches the cap")
	var dead: Dictionary = study.create_member(1,4,"QA",13)
	dead.hp = 0
	dead.xp = 99
	var dead_before: Dictionary = dead.duplicate(true)
	study.award(dead,100000)
	study.candy(dead)
	check(Store.equivalent(dead,dead_before),"No posthumous XP, evolution or healing")

func transaction_cases() -> void:
	var rules: RefCounted = Current.new()
	var run: Dictionary = rules.create("gym-candy",4)
	run.phase = "shop"
	run.bag["rare-candy"] = 2
	run.party[0] = rules.progression.create_member(1,4,"Oak",13)
	run.party[0].hp = 11
	var before: Dictionary = run.duplicate(true)
	var result: Dictionary = rules.transact(run,{"kind":"level-up","member":1,"at":run.revision})
	check(result.ok and result.state.party[0].level==14 and result.state.bag["rare-candy"]==1,"Real candy transaction stops at 14")
	check(Store.equivalent(before,run) and result.state.party[0].hp>11,"Input remains immutable and last legal level recovers HP")
	run = result.state
	before = run.duplicate(true)
	result = rules.transact(run,{"kind":"level-up","member":1,"at":run.revision})
	check(not result.ok and "14" in result.reason and Store.equivalent(before,run),"At the cap, candy is rejected without consuming bag/revision/RNG")
	for stage: int in rules.locations.size():
		run.stage = stage
		check(rules.level_cap(run)==14,"Routes and gym share Brock's cap")
	run.cleared = rules.locations.map(func(location):return location.id)
	run.stage = rules.locations.size()
	run.phase = "complete"
	check(rules.level_cap(run)==14,"The completed demo keeps its last implemented gym's cap")

func victory(rules: RefCounted) -> Dictionary:
	var run: Dictionary = rules.create("gym-victory",4)
	run.stage = 3
	run.cleared = rules.locations.slice(0,3).map(func(location):return location.id)
	run.party[0] = rules.progression.create_member(1,4,"Oak",13)
	run.party[0].hp = 11
	run.party[0].xp = rules.progression.next_xp(13)-1
	run = rules.transact(run,{"kind":"enter","at":0}).state
	var actor: Dictionary = run.battle.units[0]
	var enemy: Dictionary = run.battle.units[1]
	for unit: Dictionary in run.battle.units:
		if unit.team=="enemy": unit.hp = 0
	actor.x = 2
	actor.y = 7
	enemy.hp = 1
	enemy.x = 3
	enemy.y = 7
	run.battle.queue = [actor.id,enemy.id]
	var result: Dictionary = rules.transact(run,{"kind":"battle","order":{"kind":"attack","target":enemy.id,"actionId":"basic"},"at":run.revision})
	check(result.ok and result.state.phase=="capture","Normal victory pipeline awards EXP and capture")
	return result.state

func unlock_cases() -> void:
	var rules: RefCounted = Current.new()
	var run: Dictionary = victory(rules)
	check(run.party[0].level==14 and run.party[0].xp==0 and run.lastProgress[0].xpDiscarded>0,"Current Brock reward still cannot exceed 14")
	check(run.reward.speciesId==95 and run.reward.level==14,"Brock still recruits his Onix at the cap")
	# A data-only future gym proves routing; it is not added to the shipped demo.
	var future: Dictionary = rules.locations[3].duplicate(true)
	future.id = "qa-next-gym"
	future.name = "Líder de prueba"
	rules.locations.append(future)
	rules.progression.data.enemyLevels.append([18,21])
	run = rules.create("unlock",4)
	check(rules.level_cap(run)==14,"A later leader cannot unlock its cap early")
	run.cleared = ["brock"]
	check(rules.level_cap(run)==21,"Beating Brock unlocks the next leader's ace level from data")
	run = victory(rules)
	check(run.party[0].level>14 and rules.level_cap(run)==21 and rules.progression.gym_cap==21,"Leader victory EXP uses the newly unlocked next-gym cap")
	check(run.lastProgress[0].hpGain>0 and run.party[0].hp==11+run.lastProgress[0].hpGain,"Unlocking retains exact HP growth")

func replay_cases(directory: String) -> void:
	var latest: RefCounted = Current.new()
	for script: String in ["kanto_run","progression_run","shop_run","growth_run","letsgo_run","tactics_run","vitality_run","gym_run"]:
		var rules: RefCounted = load("res://core/"+script+".gd").new()
		var order: Dictionary = {"kind":"enter","at":0}
		var state: Dictionary = rules.transact(rules.create("cap-replay",4),order).state
		var store: RefCounted = Store.new(directory.path_join("cap-replay-"+script+".json"))
		check(store.save(state,[order],"").ok,"Save edition: "+script)
		var loaded: Dictionary = store.load_campaign(latest)
		check(loaded.ok and Store.equivalent(state,loaded.state),"Replay selects original rules: "+script)
		if script in ["vitality_run","gym_run"] and loaded.ok:
			var member: Dictionary = loaded.rules.progression.create_member(1,4,"QA",14)
			loaded.rules.progression.candy(member)
			check(member.level==(14 if script=="gym_run" else 15),"Old edition7 keeps its original uncapped progression")

func _initialize() -> void:
	var directory: String = ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="): directory = argument.trim_prefix("--save-dir=")
	if directory.is_empty(): quit(1); return
	progression_cases()
	transaction_cases()
	unlock_cases()
	replay_cases(directory)
	var output: Dictionary = {"checks":checks,"failures":failures}
	var file: FileAccess = FileAccess.open(directory.path_join("gym-caps-result.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(output,"  "))
	file.close()
	print(JSON.stringify(output))
	quit(0 if failures.is_empty() else 1)
