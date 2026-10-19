extends SceneTree

const Journey = preload("res://core/journey_run.gd")
const Policy = preload("res://ui/qa_journey_policy.gd")
const Store = preload("res://core/journey_store.gd")
var game: RefCounted
var policy: RefCounted = Policy.new()
var results: Array = []
var failures: Array = []

func _initialize() -> void:
	call_deferred("run_audit")

func run_audit() -> void:
	game = Journey.new(22)
	# Fixed samples, including losing starts: never discard unfavourable seeds.
	for starter: int in [1,4,7]:
		for index: int in 8:
			results.append(simulate("balance-kanto-%02d" % index,starter,16,"birds",true))
			write_progress()
	for starter: int in [1,4,7]:
		results.append(simulate("tactics-1",starter,16,"birds",false))
		write_progress()
	results.append(simulate("tactics-1",1,16,"psychic",false))
	write_progress()
	results.append(simulate("tactics-1",1,24,"psychic",false))
	write_progress()
	print(JSON.stringify({"runs":results.size(),"failures":failures}))
	quit(0 if failures.is_empty() else 1)

func simulate(seed_text: String, starter: int, width: int, path: String, opening: bool) -> Dictionary:
	var state: Dictionary = game.create(seed_text,starter)
	var journal: Array = []
	if width!=16:
		var resize: Dictionary = {"kind":"map-size","size":width,"at":0}
		state = game.transact(state,resize).state
		journal.append(resize)
	var row: Dictionary = {"seed":seed_text,"starter":starter,"mapSize":width,"path":path,"sample":"opening" if opening else "full","orders":0,"attacks":0,"hits":0,"misses":0,"critical":0,"basic":0,"allyAttacks":0,"allyBasic":0,"fullHpOneHitKO":0,"moveUses":{},"purchases":{},"spent":0,"earned":0,"candies":0,"revives":0,"knockedOut":0,"fights":[]}
	var fight: Dictionary = {}
	for index: int in 20000:
		if opening and "brock" in state.cleared: break
		if not opening and width==24 and state.phase=="complete" and state.mainComplete and state.finalPath=="":
			var checkpoint: RefCounted = Store.new(output_dir().path_join("balance-champion-24.json"))
			if not checkpoint.save(state,journal,"journey").ok: failures.append("Cannot save natural24 champion checkpoint")
		var command: Dictionary = policy.choose(game,state,path)
		if command.is_empty(): break
		var step: Dictionary = game.transact(state,command)
		if not step.ok:
			failures.append({"seed":seed_text,"starter":starter,"order":command,"reason":step.get("reason","")})
			break
		row.orders += 1
		journal.append(command)
		if command.kind=="enter" and step.state.phase=="battle":
			fight = {"id":game.locations[int(state.stage)].id,"orders":0,"rounds":0,"allyKO":0,"allyUnits":step.state.battle.units.filter(func(u):return u.team=="ally").size(),"enemyUnits":step.state.battle.units.filter(func(u):return u.team=="enemy").size(),"enemyHits":0,"enemyKO":0,"damage":0,"hp":0}
		if command.kind=="battle":
			fight.orders += 1
			fight.rounds = step.state.battle.round
			for unit: Dictionary in state.battle.units:
				var next: Dictionary = game.engine.unit_by_id(step.state.battle,int(unit.id))
				if unit.hp>0 and next.hp<=0:
					if unit.team=="ally": row.knockedOut += 1; fight.allyKO += 1
					else: fight.enemyKO += 1
			if command.order.kind=="attack":
				row.attacks += 1
				var action: String = command.order.get("actionId","basic")
				row.moveUses[action] = row.moveUses.get(action,0)+1
				if action=="basic": row.basic += 1
				var actor: Dictionary = game.engine.active(state.battle)
				if actor.team=="ally":
					row.allyAttacks += 1
					if action=="basic": row.allyBasic += 1
				for receipt: Dictionary in step.get("presentation",{}).get("hits",[]):
					if receipt.get("recoil",false): continue
					if action!="basic" and game.progression.data.moves[action].category=="status": continue
					if not receipt.get("hit",false): row.misses += 1; continue
					row.hits += 1
					if receipt.get("critical",false): row.critical += 1
					var target: Dictionary = game.engine.unit_by_id(state.battle,int(receipt.targetId))
					if actor.team=="ally" and target.team=="enemy" and receipt.get("damage",0)>0:
						fight.enemyHits += 1
						fight.damage += receipt.damage
						if receipt.damage>=target.hp and target.hp==target.maxHp: row.fullHpOneHitKO += 1
			if step.state.phase!="battle":
				fight.outcome = step.state.battle.outcome
				row.fights.append(fight)
		if command.kind=="buy": row.purchases[command.item] = row.purchases.get(command.item,0)+1
		if command.kind=="level-up": row.candies += 1
		if command.kind=="revive": row.revives += 1
		row.spent += maxi(0,int(state.money)-int(step.state.money))
		row.earned += maxi(0,int(step.state.money)-int(state.money))
		state = step.state
		if state.phase=="battle" and int(state.battle.round)>50:
			row.stalled = true
			fight.outcome = "stalled"
			row.fights.append(fight)
			break
		if state.phase in ["defeat","ending"]: break
	row.phase = state.phase
	row.cleared = state.cleared
	row.medals = state.medals.size()
	row.money = state.money
	row.reserves = state.reserve.size()
	row.lastLocation = game.locations[int(state.stage)].id
	row.party = state.party.map(func(m):return {"id":m.id,"speciesId":m.speciesId,"level":m.level,"hp":m.hp})
	if not opening and state.phase in ["ending","defeat"]:
		var store: RefCounted = Store.new(output_dir().path_join("balance-%d-%d-%s.json" % [starter,width,path]))
		var saved: Dictionary = store.save(state,journal,"journey")
		if not saved.ok: failures.append(saved.reason)
		else:
			var restored: Dictionary = store.load_campaign(game)
			if not restored.ok or not Store.equivalent(restored.state,state): failures.append("Balance journey replay mismatch")
	return row

func write_progress() -> void:
	var hashes: Dictionary = {}
	for file: String in ["core/journey_run.gd","core/finale_battle.gd","ui/qa_journey_policy.gd","tests/balance_native.gd","data/journey-21.json"]:
		hashes[file] = FileAccess.get_sha256("res://"+file)
	var report: Dictionary = {"chapter":22,"campaignEdition":18,"sourceSha256":hashes,"policy":"qa_journey_policy: four-move preparation, top-three training before League, six trained members and coverage roster for League/postgame, paid healing/revives and PC; same combat AI both sides. Stops a fight after50 rounds as a diagnostic stall. No MT or held-item purchases.","results":results,"failures":failures}
	var path: String = output_dir()
	DirAccess.make_dir_recursive_absolute(path)
	FileAccess.open(path.path_join("balance-native.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("BALANCE_PROGRESS "+str(results.size()))

func output_dir() -> String:
	var path: String = OS.get_user_data_dir()
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="): path = argument.trim_prefix("--save-dir=")
	return path
