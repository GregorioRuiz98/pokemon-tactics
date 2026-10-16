extends SceneTree

const Current = preload("res://core/revive_run.gd")
const Store = preload("res://core/kanto_store.gd")
var checks: int = 0
var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)

func transaction_cases() -> void:
	var rules: RefCounted = Current.new()
	var run: Dictionary = rules.create("revive-price",4)
	check(run.edition==9 and run.bag.revive==0 and rules.consumables.revive.price==150,"New edition offers Revivir at 150 with an empty bag")
	run.phase = "shop"
	run.money = 149
	var before: Dictionary = run.duplicate(true)
	check(not rules.transact(run,{"kind":"buy","item":"revive","at":run.revision}).ok and Store.equivalent(before,run),"149 cannot buy a revive or mutate the input")
	run.money = 150
	before = run.duplicate(true)
	var result: Dictionary = rules.transact(run,{"kind":"buy","item":"revive","at":run.revision})
	check(result.ok and result.state.money==0 and result.state.bag.revive==1 and result.state.revision==run.revision+1,"Exactly 150 buys one revive")
	check(Store.equivalent(before,run) and result.state.rng==run.rng and Store.equivalent(run.shopRandom,result.state.shopRandom),"Buying does not change the input or either RNG")
	for identity: int in rules.progression.species:
		for level: int in [5,14]:
			run = rules.create("revive-matrix",4)
			run.phase = "shop"
			run.bag.revive = 1
			var member: Dictionary = rules.progression.create_member(2,identity,"QA",level)
			member.hp = 0
			member.xp = 37 if level<14 else 0
			member.heldItem = null
			run.party.append(member)
			run.nextId = 3
			before = run.duplicate(true)
			result = rules.transact(run,{"kind":"revive","member":2,"at":run.revision})
			var expected: Dictionary = member.duplicate(true)
			expected.hp = int(floor(rules.progression.stats(identity,level).maxHp/2.0))
			check(result.ok and Store.equivalent(result.state.party[1],expected),"All species return at half HP with identity, level, EXP and moves intact")
			check(result.state.bag.revive==0 and result.state.money==run.money and result.state.nextId==3 and result.state.party.size()==2,"One use consumes exactly one item and never duplicates members")
			check(Store.equivalent(run,before) and result.state.rng==run.rng and Store.equivalent(run.shopRandom,result.state.shopRandom),"Reviving is immutable and consumes no RNG")
			var healthy: Dictionary = result.state
			check(not rules.transact(healthy,{"kind":"revive","member":2,"at":healthy.revision}).ok,"An already living member cannot consume another revive")
	for phase: String in ["map","battle","capture","complete","defeat"]:
		run.phase = phase
		before = run.duplicate(true)
		for command: Dictionary in [{"kind":"buy","item":"revive","at":run.revision},{"kind":"revive","member":2,"at":run.revision}]:
			check(not rules.transact(run,command).ok and Store.equivalent(before,run),"No revive purchase or use outside the shop: "+phase)
	run.phase = "shop"
	run.bag.revive = 1
	for identity: Variant in [null,"2",2.5,-1,9999]:
		check(not rules.transact(run,{"kind":"revive","member":identity,"at":run.revision}).ok,"Invalid revive target rejected")
	check(not rules.transact(run,{"kind":"revive","member":2,"at":run.revision-1}).ok,"Stale revive callback rejected")
	run.bag.revive = 0
	check(not rules.transact(run,{"kind":"revive","member":2,"at":run.revision}).ok,"Empty bag rejected")
	check(not rules.transact(run,{"kind":"heal","item":"revive","member":2,"at":run.revision}).ok,"Revive cannot bypass the potion command's restrictions")

func recover_after_ko() -> void:
	var rules: RefCounted = Current.new()
	var run: Dictionary = rules.create("revive-ko",4)
	run.party.append(rules.progression.create_member(2,25,"QA",5))
	run.nextId = 3
	run.party[0].hp = 1
	run.party[0].xp = 37
	run.party[0].heldItem = "life-orb"
	run = rules.transact(run,{"kind":"enter","at":run.revision}).state
	var actor: Dictionary = run.battle.units[0]
	var enemy: Dictionary = run.battle.units[2]
	for unit: Dictionary in run.battle.units:
		if unit.team=="enemy": unit.hp = 0
	actor.x = 2
	actor.y = 7
	enemy.hp = 1
	enemy.x = 3
	enemy.y = 7
	run.battle.queue = [actor.id,enemy.id]
	var result: Dictionary = rules.transact(run,{"kind":"battle","order":{"kind":"attack","actionId":"basic","target":enemy.id},"at":run.revision})
	check(result.ok and result.state.phase=="capture","Victory remains possible with another survivor after recoil KO")
	run = result.state
	check(run.party[0].hp==0 and run.party[0].xp==37 and run.party[0].heldItem==null and run.bag["life-orb"]==1,"A real KO returns equipment and awards no posthumous XP")
	run = rules.transact(run,{"kind":"capture","at":run.revision}).state
	run = rules.transact(run,{"kind":"buy","item":"revive","at":run.revision}).state
	var fallen: Dictionary = run.party[0].duplicate(true)
	result = rules.transact(run,{"kind":"revive","member":1,"at":run.revision})
	run = result.state
	fallen.hp = int(floor(rules.engine.member_unit(fallen).maxHp/2.0))
	check(Store.equivalent(fallen,run.party[0]) and run.bag["life-orb"]==1,"Reviving does not duplicate or automatically re-equip the recovered item")
	check(run.party[0].level==5 and rules.level_cap(run)==14,"Reviving preserves level and the gym cap")
	var half_hp: int = run.party[0].hp
	result = rules.transact(run,{"kind":"heal","item":"potion","member":1,"at":run.revision})
	check(result.ok and result.state.party[0].hp>half_hp,"Normal potions can heal a revived living Pokémon")
	run = rules.transact(run,{"kind":"continue","at":run.revision}).state
	run = rules.transact(run,{"kind":"enter","at":run.revision}).state
	var deployed: Array = run.battle.units.filter(func(unit):return unit.team=="ally" and unit.id==1)
	check(deployed.size()==1 and deployed[0].hp==half_hp,"The revived member deploys once at its actual HP in the next battle")

func replay_cases(directory: String) -> void:
	var latest: RefCounted = Current.new()
	for script: String in ["kanto_run","progression_run","shop_run","growth_run","letsgo_run","tactics_run","vitality_run","gym_run","revive_run"]:
		var rules: RefCounted = load("res://core/"+script+".gd").new()
		var order: Dictionary = {"kind":"enter","at":0}
		var state: Dictionary = rules.transact(rules.create("revive-replay",4),order).state
		var store: RefCounted = Store.new(directory.path_join("revive-replay-"+script+".json"))
		check(store.save(state,[order],"").ok,"Save edition: "+script)
		var loaded: Dictionary = store.load_campaign(latest)
		check(loaded.ok and Store.equivalent(state,loaded.state),"Replay preserves edition: "+script)
		if script!="revive_run":
			state.phase = "shop"
			state.money = 1000
			check(not rules.transact(state,{"kind":"buy","item":"revive","at":state.revision}).ok,"Previous rules do not acquire revive retroactively")

func _initialize() -> void:
	var directory: String = ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="): directory = argument.trim_prefix("--save-dir=")
	if directory.is_empty(): quit(1); return
	transaction_cases()
	recover_after_ko()
	replay_cases(directory)
	var output: Dictionary = {"checks":checks,"failures":failures}
	var file: FileAccess = FileAccess.open(directory.path_join("revive-result.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(output,"  "))
	file.close()
	print(JSON.stringify(output))
	quit(0 if failures.is_empty() else 1)
