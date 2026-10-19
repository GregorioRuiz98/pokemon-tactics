extends SceneTree

const Run = preload("res://core/roster_run.gd")
const Save = preload("res://core/kanto_store.gd")
var checks: int = 0
var failures: Array[String] = []

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)

func command(game: RefCounted, state: Dictionary, order: Dictionary) -> Dictionary:
	order.at = state.revision
	var result: Dictionary = game.transact(state,order)
	check(result.ok,"Accepted: "+str(order.kind)+" "+str(result.get("reason","")))
	return result.state if result.ok else state

func rejected(game: RefCounted, state: Dictionary, order: Dictionary, label: String) -> void:
	var before: Dictionary = state.duplicate(true)
	order.at = state.revision
	check(not game.transact(state,order).ok,label)
	check(Save.equivalent(state,before),"Rejected order preserves all state: "+label)

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var game: RefCounted = Run.new()
	var fresh: Dictionary = game.create("roster-16",1)
	check(fresh.edition==12 and fresh.reserve.is_empty() and fresh.party.size()==1,"New edition with empty PC")
	rejected(game,fresh,{"kind":"deposit","member":1},"Cannot deposit last living member")
	var fixture: Dictionary = fresh.duplicate(true)
	for index: int in range(2,7): fixture.party.append(game.progression.create_member(index,4,"Controlled roster fixture",5))
	fixture.phase = "capture"
	fixture.nextId = 7
	fixture.reward = game.progression.create_member(7,25,"Controlled reward",5)
	fixture.reward.hp -= 9
	fixture.reward.heldItem = "leftovers"
	fixture.money = 10000
	var reward: Dictionary = fixture.reward.duplicate(true)
	var captured: Dictionary = command(game,fixture,{"kind":"capture"})
	check(captured.party.size()==6 and captured.reserve.size()==1 and captured.nextId==8,"Seventh capture goes to PC once")
	check(Save.equivalent(captured.reserve[0],reward),"Overflow keeps original member and HP")
	rejected(game,captured,{"kind":"capture"},"Cannot claim capture twice")
	rejected(game,captured,{"kind":"withdraw","member":7},"Six occupied slots even with PC member")
	captured.party[1].hp = 0
	rejected(game,captured,{"kind":"withdraw","member":7},"A fainted team member still occupies a slot")
	var swapped: Dictionary = command(game,captured,{"kind":"swap","member":2,"reserve":7})
	check(swapped.party[1].id==7 and swapped.reserve[0].id==2,"Direct swap preserves slot and identity")
	check(Save.equivalent(swapped.party[1],reward) and swapped.reserve[0].hp==0,"Swap neither heals nor revives")
	check(swapped.money==captured.money and Save.equivalent(swapped.bag,captured.bag),"Swap is free and equipment remains attached")
	for key: String in ["rng","shopRandom","stock"]: check(Save.equivalent({"value":swapped[key]},{"value":captured[key]}),"Swap preserves "+key)
	var deposited: Dictionary = command(game,swapped,{"kind":"deposit","member":7})
	check(deposited.party.size()==5 and Save.equivalent(deposited.reserve[1],reward),"Deposit preserves complete record")
	var withdrawn: Dictionary = command(game,deposited,{"kind":"withdraw","member":7})
	check(withdrawn.party.size()==6 and Save.equivalent(withdrawn.party.back(),reward),"Withdraw preserves complete record")
	for bad: Variant in [null,"1",true,1.5,-1,999]:
		rejected(game,deposited,{"kind":"deposit","member":bad},"Reject malformed/missing active identity "+str(bad))
		rejected(game,deposited,{"kind":"withdraw","member":bad},"Reject malformed/missing reserve identity "+str(bad))
	for phase: String in ["battle","capture","defeat"]:
		var blocked: Dictionary = deposited.duplicate(true)
		blocked.phase = phase
		for kind: String in ["deposit","withdraw","swap"]:
			rejected(game,blocked,{"kind":kind,"member":1,"reserve":2},"PC locked during "+phase)
	check(not game.transact(deposited,{"kind":"withdraw","member":7,"at":-1}).ok,"Stale transaction rejected")
	var last: Dictionary = game.create("last-live",1)
	var fainted: Dictionary = game.progression.create_member(2,4,"Fixture",5)
	fainted.hp = 0
	last.reserve.append(fainted)
	rejected(game,last,{"kind":"swap","member":1,"reserve":2},"Cannot exchange last survivor for fainted member")
	last.party.append(game.progression.create_member(3,7,"Fixture",5))
	last = command(game,last,{"kind":"swap","member":1,"reserve":2})
	check(last.party[0].hp==0 and last.reserve[0].hp>0,"Fainted reserve can occupy slot with another survivor")
	# Prepared moves, consumables, cap, traits and MT work on reserves through shared target().
	var prepared: Dictionary = deposited.duplicate(true)
	prepared.bag["rare-candy"] = 1
	var reserve_before: Dictionary = game.target(prepared,7).duplicate(true)
	prepared = command(game,prepared,{"kind":"level-up","member":7})
	var grown: Dictionary = game.target(prepared,7)
	check(grown.level==reserve_before.level+1 and grown.hp-reserve_before.hp==game.progression.member_stats(grown).maxHp-game.progression.member_stats(reserve_before).maxHp,"Reserve candy keeps HP growth rule")
	prepared = command(game,prepared,{"kind":"loadout","member":7,"moves":[]})
	check(game.target(prepared,7).moves.is_empty(),"Reserve loadout supports four plus mandatory basic")
	prepared.bag.revive = 1
	prepared = command(game,prepared,{"kind":"revive","member":2})
	check(game.target(prepared,2).hp==maxi(1,int(floor(game.progression.member_stats(game.target(prepared,2)).maxHp/2.0))),"Reserve revive restores exactly half HP")
	prepared.bag["mint-adamant"] = 1
	prepared = command(game,prepared,{"kind":"mint","member":7,"nature":"adamant"})
	check(game.target(prepared,7).mint=="adamant" and prepared.bag["mint-adamant"]==0,"Reserve mint applied once")
	prepared.bag["ability-capsule"] = 1
	var rat: Dictionary = game.progression.create_member(8,19,"Two normal abilities fixture",5)
	game.progression.assign(rat,prepared.seed)
	prepared.reserve.append(rat)
	var previous_slot: int = rat.abilitySlot
	prepared = command(game,prepared,{"kind":"capsule","member":8})
	check(game.target(prepared,8).abilitySlot!=previous_slot and prepared.bag["ability-capsule"]==0,"Reserve capsule changes normal ability")
	prepared.bag["tm-brick-break"] = 1
	prepared = command(game,prepared,{"kind":"teach","member":7,"item":"tm-brick-break"})
	check("brick-break" in game.target(prepared,7).knownMoves and prepared.bag["tm-brick-break"]==0,"Reserve learns compatible MT once")
	prepared = command(game,prepared,{"kind":"equip","member":7,"item":""})
	check(game.target(prepared,7).heldItem==null and prepared.bag.leftovers==1,"Reserve unequip returns object once")
	var deployed: Dictionary = withdrawn.duplicate(true)
	deployed.phase = "map"
	for member_data: Dictionary in deployed.party: member_data.hp = game.progression.member_stats(member_data).maxHp
	deployed = command(game,deployed,{"kind":"enter"})
	var positions: Dictionary = {}
	for unit: Dictionary in deployed.battle.units:
		if unit.team=="ally": positions["%d,%d" % [unit.x,unit.y]] = true
	check(positions.size()==6,"Six active members deploy to distinct cells")
	# Check a large PC does not leak units into battle or award reserve EXP.
	var large: Dictionary = game.create("large-pc",1)
	for index: int in range(2,102): large.reserve.append(game.progression.create_member(index,4,"Large PC fixture",5))
	large.nextId = 102
	large = command(game,large,{"kind":"enter"})
	check(large.battle.units.filter(func(u):return u.team=="ally").size()==1,"100 reserves are not deployed")
	var unchanged: Array = large.reserve.duplicate(true)
	for index: int in 500:
		if large.phase!="battle": break
		large = command(game,large,{"kind":"battle","order":game.engine.choose_command(large.battle)})
	check(large.phase=="capture" and Save.equivalent({"reserve":large.reserve},{"reserve":unchanged}),"Victory does not award reserve EXP or HP")
	# A living PC cannot rescue an already lost battle.
	var lost: Dictionary = game.create("wipe-with-reserve",1)
	lost.reserve.append(game.progression.create_member(2,7,"Living reserve",5))
	lost = command(game,lost,{"kind":"enter"})
	for unit: Dictionary in lost.battle.units:
		if unit.team=="ally": unit.hp = 1; unit.defense = 1; unit.specialDefense = 1
	lost.battle.queue = [lost.battle.units[1].id,1]
	var enemy: Dictionary = game.engine.active(lost.battle)
	var ally: Dictionary = game.engine.unit_by_id(lost.battle,1)
	for row: Array in lost.battle.board: row.fill(0)
	for row: Array in lost.battle.heights: row.fill(0)
	enemy.x = 6; enemy.y = 8; enemy.remaining = 6
	ally.x = 5; ally.y = 8
	lost = command(game,lost,{"kind":"battle","order":{"kind":"attack","target":1,"actionId":"basic"}})
	check(lost.phase=="defeat" and lost.reserve[0].hp>0,"Active wipe ends campaign despite living reserve")
	var journey_report: Dictionary = journey(game)
	var report: Dictionary = {"checks":checks,"failures":failures,"journey":journey_report,"overflowFixture":true,"largePcFixture":100}
	FileAccess.open(output_dir().path_join("roster-core-result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)

func output_dir() -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--save-dir="): return arg.trim_prefix("--save-dir=")
	return OS.get_user_data_dir()

func journey(game: RefCounted) -> Dictionary:
	var state: Dictionary = game.create("tactics-1",1)
	var journal: Array = []
	var used_pc: bool = false
	for index: int in 1000:
		if state.phase in ["complete","defeat"]: break
		var order: Dictionary = {"at":state.revision}
		match state.phase:
			"map": order.kind = "enter"
			"capture": order.kind = "capture"
			"shop":
				order.kind = "continue"
				if not used_pc and state.party.size()>1:
					var identity: int = state.party.back().id
					var pc_orders: Array = [{"kind":"deposit","member":identity},{"kind":"swap","member":1,"reserve":identity},{"kind":"swap","member":identity,"reserve":1},{"kind":"withdraw","member":identity}]
					for pc_order: Dictionary in pc_orders:
						pc_order.at = state.revision
						state = command(game,state,pc_order)
						journal.append(pc_order)
						var checkpoint: RefCounted = Save.new(output_dir().path_join("roster-checkpoint.json"))
						check(checkpoint.save(state,journal,"roster").ok,"Save PC checkpoint")
						var replay: Dictionary = checkpoint.load_campaign(game)
						check(replay.ok and Save.equivalent(replay.state,state),"PC checkpoint replays deposit/swap/withdraw exactly")
					used_pc = true
					order.at = state.revision
				for member_data: Dictionary in state.party:
					if member_data.hp>0 and member_data.hp<game.progression.member_stats(member_data).maxHp-10:
						if state.bag.potion>0: order.merge({"kind":"heal","item":"potion","member":member_data.id},true)
						elif state.money>=40: order.merge({"kind":"buy","item":"potion"},true)
						break
			"battle": order.merge({"kind":"battle","order":game.engine.choose_command(state.battle)},true)
		state = command(game,state,order)
		journal.append(order)
	check(state.phase=="complete" and state.cleared.size()==4 and used_pc,"Four-zone natural campaign with PC use completes")
	var store: RefCounted = Save.new(output_dir().path_join("roster-journey.json"))
	check(store.save(state,journal,"roster").ok,"Save roster journal")
	var restored: Dictionary = store.load_campaign(game)
	check(restored.ok and Save.equivalent(restored.state,state),"Roster journal reload is exact")
	# Every earlier edition remains loadable with its own rules and no PC migration.
	for edition: int in range(1,12):
		var modules: Array = ["kanto","progression","shop","growth","letsgo","tactics","vitality","gym","revive","traits","scale"]
		var module_path: String = "res://core/%s_run.gd" % modules[edition-1]
		var old_rules: RefCounted = load(module_path).new()
		var old: Dictionary = old_rules.create("old-edition",1)
		var old_store: RefCounted = Save.new(output_dir().path_join("roster-classic-%d.json" % edition))
		check(old_store.save(old,[],"classic").ok,"Save classic "+str(edition))
		var reloaded: Dictionary = old_store.load_campaign(game)
		check(reloaded.ok and Save.equivalent(reloaded.state,old) and not reloaded.state.has("reserve"),"Classic edition preserved "+str(edition))
	return {"phase":state.phase,"cleared":state.cleared.size(),"transactions":journal.size(),"pcUsed":used_pc}
