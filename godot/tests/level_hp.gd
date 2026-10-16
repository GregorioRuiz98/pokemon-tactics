extends SceneTree

const Current = preload("res://core/vitality_run.gd")
const Store = preload("res://core/kanto_store.gd")
var rules: RefCounted = Current.new()
var checks: int = 0
var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)

func growth_cases() -> void:
	var study: RefCounted = rules.progression
	check(rules.engine.progression==study,"Campaign and combat share the new progression")
	for profile: RefCounted in rules.engine.profiles.values(): check(profile.progression==study,"Every profile shares the same progression")
	for identity: int in study.species:
		for level: int in [5,6,9,15,19,35,99]:
			for missing: int in [0,7,9999]:
				for by_candy: bool in [false,true]:
					var member: Dictionary = study.create_member(1,identity,"QA",level)
					var previous_max: int = study.stats(identity,level).maxHp
					member.hp = maxi(1,previous_max-missing)
					member.xp = 17
					member.heldItem = "life-orb"
					var hp: int = member.hp
					var receipt: Dictionary = study.candy(member) if by_candy else study.award(member,study.next_xp(level)-17)
					var maximum: int = study.stats(int(member.speciesId),int(member.level)).maxHp
					var gain: int = maxi(0,maximum-previous_max)
					check(member.level==level+1 and member.hp==mini(maximum,hp+gain),"Living member gains exactly the max-HP increase")
					check(maximum-member.hp==previous_max-hp and member.hp>0,"Missing HP is conserved, including automatic evolution")
					check(receipt.hpGain==member.hp-hp and member.heldItem=="life-orb" and member.moves.size()<=4,"Receipt, equipment and four prepared moves remain correct")
					check(member.xp==(17 if by_candy and member.level<100 else 0),"Partial EXP follows existing candy/cap rules")
	var multiple: Dictionary = study.create_member(1,10,"QA",5)
	multiple.hp = 13
	var old_max: int = study.stats(10,5).maxHp
	var receipt: Dictionary = study.award(multiple,550)
	check(multiple.level==10 and multiple.speciesId==12 and receipt.evolutions.size()==2,"Multiple XP levels retain both automatic evolutions")
	check(multiple.hp==13+study.stats(12,10).maxHp-old_max,"Multiple levels and evolutions recover the total HP gain only once")
	var idle: Dictionary = study.create_member(1,4,"QA",5)
	idle.hp = 1
	check(study.award(idle,1).hpGain==0 and idle.hp==1 and idle.level==5,"XP without a level does not heal")
	for dead: bool in [false,true]:
		var member: Dictionary = study.create_member(1,4,"QA",5 if dead else 100)
		member.hp = 0 if dead else 1
		var before: Dictionary = member.duplicate(true)
		check(study.candy(member).hpGain==0 and Store.equivalent(before,member),"Dead or capped members cannot heal through candy")
		check(study.award(member,10000).hpGain==0 and member.hp==before.hp,"Dead or capped members cannot heal through EXP")
		if dead: check(Store.equivalent(before,member),"Fallen members gain no XP or evolution")

func transactions() -> void:
	var run: Dictionary = rules.create("hp-transaction",4)
	run.phase = "shop"
	run.party[0].hp = 11
	run.party[0].xp = 37
	run.bag["rare-candy"] = 1
	var before: Dictionary = run.duplicate(true)
	var result: Dictionary = rules.transact(run,{"kind":"level-up","member":1,"at":run.revision})
	var gain: int = rules.progression.stats(4,6).maxHp-rules.progression.stats(4,5).maxHp
	check(result.ok and result.state.party[0].hp==11+gain and result.state.party[0].xp==37,"Real candy transaction restores only the max-HP gain")
	check(result.state.bag["rare-candy"]==0 and result.state.lastProgress[0].hpGain==gain and Store.equivalent(before,run),"One candy, exact receipt and immutable input")
	for variant: String in ["dead","capped","empty","battle","stale"]:
		var invalid: Dictionary = before.duplicate(true)
		if variant=="dead": invalid.party[0].hp = 0
		if variant=="capped": invalid.party[0].level = 100
		if variant=="empty": invalid.bag["rare-candy"] = 0
		if variant=="battle": invalid.phase = "battle"
		var snapshot: Dictionary = invalid.duplicate(true)
		var command: Dictionary = {"kind":"level-up","member":1,"at":invalid.revision-(1 if variant=="stale" else 0)}
		check(not rules.transact(invalid,command).ok and Store.equivalent(snapshot,invalid),"Rejected candy cannot heal, consume resources or mutate input: "+variant)
	# Stone evolution alone is outside this level-up rule.
	run.party[0] = rules.progression.create_member(1,44,"QA",21)
	run.party[0].hp = 11
	run.bag["leaf-stone"] = 1
	result = rules.transact(run,{"kind":"stone","member":1,"at":run.revision})
	check(result.ok and result.state.party[0].speciesId==45 and result.state.party[0].hp==11,"A stone without leveling still preserves current HP")
	# A real victory dispatches EXP through the same progression as candy.
	run = rules.transact(rules.create("hp-victory",4),{"kind":"enter","at":0}).state
	var actor: Dictionary = run.battle.units[0]
	var enemy: Dictionary = run.battle.units[1]
	for unit: Dictionary in run.battle.units:
		if unit.team=="enemy": unit.hp = 0
	actor.hp = 11
	actor.x = 2
	actor.y = 7
	enemy.hp = 1
	enemy.x = 3
	enemy.y = 7
	run.battle.queue = [actor.id,enemy.id]
	result = rules.transact(run,{"kind":"battle","order":{"kind":"attack","target":enemy.id,"actionId":"basic"},"at":run.revision})
	check(result.ok and result.state.phase=="capture","Victory reaches the normal EXP reward")
	if result.ok and result.state.phase=="capture":
		var member: Dictionary = result.state.party[0]
		gain = rules.progression.stats(int(member.speciesId),int(member.level)).maxHp-rules.progression.stats(4,5).maxHp
		check(member.level>5 and member.hp==11+gain and result.state.lastProgress[0].hpGain==gain,"Victory applies growth to surviving current HP")

func replay_cases(directory: String) -> void:
	for script: String in ["kanto_run","progression_run","shop_run","growth_run","letsgo_run","tactics_run","vitality_run"]:
		var edition: RefCounted = load("res://core/"+script+".gd").new()
		var order: Dictionary = {"kind":"enter","at":0}
		var state: Dictionary = edition.transact(edition.create("hp-replay",4),order).state
		var store: RefCounted = Store.new(directory.path_join("hp-replay-"+script+".json"))
		check(store.save(state,[order],"").ok,"Save each published edition")
		var loaded: Dictionary = store.load_campaign(rules)
		check(loaded.ok and Store.equivalent(loaded.state,state),"Replay selects the exact edition's rules")
		if script in ["growth_run","letsgo_run","tactics_run","vitality_run"] and loaded.ok:
			var member: Dictionary = loaded.rules.progression.create_member(1,4,"QA",5)
			member.hp = 11
			loaded.rules.progression.candy(member)
			check((member.hp>11)==(script=="vitality_run"),"Only the new edition heals on leveling")
	var previous: RefCounted = load("res://core/tactics_run.gd").new()
	var old: Dictionary = previous.transact(previous.create("hp-combat",4),{"kind":"enter","at":0}).state.battle
	var current: Dictionary = rules.transact(rules.create("hp-combat",4),{"kind":"enter","at":0}).state.battle
	check(Store.equivalent(old,current),"The HP growth change does not modify combat or initial RNG")

func _initialize() -> void:
	var directory: String = ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="): directory = argument.trim_prefix("--save-dir=")
	if directory.is_empty(): quit(1); return
	growth_cases()
	transactions()
	replay_cases(directory)
	var output: Dictionary = {"checks":checks,"failures":failures}
	var file: FileAccess = FileAccess.open(directory.path_join("level-hp-result.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(output,"  "))
	file.close()
	print(JSON.stringify(output))
	quit(0 if failures.is_empty() else 1)
