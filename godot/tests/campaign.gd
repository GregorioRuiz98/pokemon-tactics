extends SceneTree

const Campaign = preload("res://core/kanto_run.gd")
const Store = preload("res://core/kanto_store.gd")
var rules: Campaign = Campaign.new()
var failures: Array[String] = []
var checks: int = 0
var run: Dictionary
var journal: Array = []

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)

func act(command: Dictionary) -> bool:
	command.at = run.revision
	var before: Dictionary = run.duplicate(true)
	var result: Dictionary = rules.transact(run,command)
	check(Store.equivalent(run,before),"Transactions leave input immutable")
	if not result.ok: return false
	run = result.state
	journal.append(command.duplicate(true))
	return true

func prepare_shop() -> void:
	for member: Dictionary in run.party:
		if member.hp <= 0: continue
		while member.hp < rules.engine.member_unit(member).maxHp - 10:
			if run.bag.potion == 0 and run.money >= 40: act({"kind":"buy","item":"potion"})
			if run.bag.potion == 0: break
			act({"kind":"heal","item":"potion","member":member.id})
			member = rules.target(run,int(member.id))
	if run.money >= 100 and rules.EVOLUTIONS.has(int(run.party[0].speciesId)) and run.party[0].hp > 0:
		act({"kind":"buy","item":"rare-candy"})
		var hp: int = run.party[0].hp
		act({"kind":"evolve","member":run.party[0].id})
		check(run.party[0].hp == hp,"Evolution does not heal")
	if run.money >= 80 and run.party[0].hp > 0 and run.party[0].training.values().reduce(func(a,b):return a+b,0) < 2:
		var hp: int = run.party[0].hp
		act({"kind":"train","member":run.party[0].id,"stat":"maxHp"})
		check(run.party[0].hp == hp,"Health training does not heal")

func _initialize() -> void:
	var directory: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--save-dir="): directory = arg.trim_prefix("--save-dir=")
	if directory.is_empty():
		push_error("La prueba requiere --save-dir para aislar sus archivos.")
		quit(1)
		return
	var results: Array = []
	for location: Dictionary in rules.locations:
		var test: Dictionary = rules.create("spawn",1)
		var battle: Dictionary = rules.engine.encounter(test,location)
		for unit: Dictionary in battle.units:
			check(not is_inf(rules.engine.Movement.tile_cost(battle.board,unit,unit.profile)),"Spawns occupy traversable terrain: " + location.id)
	for starter: int in [1,4,7]:
		for seed: String in ["kanto-14","paleta","rojo"]:
			run = rules.create(seed,starter)
			journal = []
			var store: Store = Store.new(directory.path_join("campaign-%d-%s.json" % [starter,seed]))
			var undo_seen: bool = false
			for step: int in 1100:
				if run.phase in ["complete","defeat"]: break
				if run.phase == "map": check(act({"kind":"enter"}),"Enter next route")
				elif run.phase == "battle":
					var command: Dictionary = rules.engine.choose_command(run.battle)
					var before: Dictionary = run.battle.duplicate(true)
					check(act({"kind":"battle","order":command}),"Legal tactical command")
					if not undo_seen and command.kind == "move" and run.phase == "battle" and run.battle.units.filter(func(u): return u.id == run.battle.queue[0])[0].team == "ally" and not run.battle.acted:
						check(act({"kind":"rectify"}),"Campaign movement-only revision")
						check(Store.equivalent(run.battle,before),"Revision preserves RNG and resources")
						check(act({"kind":"battle","order":command}),"Move again after revision")
						undo_seen = true
				elif run.phase == "capture":
					var reward: Dictionary = run.reward.duplicate(true)
					var pool: Array = []
					for entry: Dictionary in rules.engine.catalog.slots:
						if entry.id == rules.locations[int(run.stage)].captureTable: pool = entry.slots.map(func(slot):return int(slot.speciesId))
					check(reward.speciesId in pool,"Capture belongs to Red local table")
					check(store.save(run,journal,"kanto-14").ok,"Save pending capture")
					var loaded: Dictionary = store.load_campaign(rules)
					check(loaded.ok and Store.equivalent(loaded.state.reward,reward),"Reload cannot reroll capture")
					var stale: Dictionary = {"kind":"capture","at":run.revision}
					check(act({"kind":"capture"}),"Claim local capture")
					check(not rules.transact(run,stale).ok,"Duplicate receipt rejected")
				elif run.phase == "shop":
					prepare_shop()
					check(act({"kind":"continue"}),"Leave shop")
			check(run.phase in ["complete","defeat"],"Campaign terminates within budget")
			check(store.save(run,journal,"kanto-14").ok,"Save campaign outcome")
			var loaded: Dictionary = store.load_campaign(rules)
			check(loaded.ok and Store.equivalent(loaded.state,run),"Exact campaign replay")
			results.append({"starter":starter,"seed":seed,"phase":run.phase,"cleared":run.cleared.size(),"orders":journal.size(),"medals":run.medals})
	check(results.any(func(result):return result.phase == "complete"),"At least one full campaign reaches Brock")
	var output: Dictionary = {"checks":checks,"runs":results,"failures":failures}
	var file: FileAccess = FileAccess.open(directory.path_join("campaign-result.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(output,"  "))
	file.close()
	print(JSON.stringify(output))
	quit(0 if failures.is_empty() else 1)
