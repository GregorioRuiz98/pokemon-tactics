extends SceneTree

const Journey = preload("res://core/journey_run.gd")
const Store = preload("res://core/journey_store.gd")
const Legacy = preload("res://core/roster_run.gd")
const Policy = preload("res://ui/qa_journey_policy.gd")
var checks: int = 0
var failures: Array[String] = []
var policy: RefCounted = Policy.new()

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var game: RefCounted = Journey.new(chapter_number())
	var fresh: Dictionary = game.create("tactics-1",1)
	var fixture: Dictionary = fresh.duplicate(true)
	fixture.phase = "shop"
	fixture.party.append(game.progression.create_member(2,133,"Evolution fixture",10))
	game.progression.assign(fixture.party[1],fixture.seed)
	fixture.party[1].hp -= 9
	fixture.bag["fire-stone"] = 1
	var hp: int = fixture.party[1].hp
	var evolved: Dictionary = game.transact(fixture,{"kind":"use-evolution","member":2,"species":136,"item":"fire-stone","at":fixture.revision})
	check(evolved.ok and evolved.state.party[1].speciesId==136 and evolved.state.party[1].hp==hp,"Eevee chooses Fire Stone without healing")
	check(evolved.ok and evolved.state.bag["fire-stone"]==0 and fixture.bag["fire-stone"]==1,"Evolution is immutable and consumes once")
	check(not game.transact(fixture,{"kind":"use-evolution","member":2,"species":134,"item":"fire-stone","at":fixture.revision}).ok,"Wrong stone/destination rejected")
	check(game.level_cap(fresh)==14,"Brock cap")
	fixture.cleared = ["brock"]
	check(game.level_cap(fixture)==21,"Misty cap after Brock")
	fixture.cleared.append("misty")
	check(game.level_cap(fixture)==24,"Surge cap after Misty")
	var ship: int = game.locations.find(game.locations.filter(func(n):return n.id=="ss-anne")[0])
	fixture = fresh.duplicate(true)
	fixture.stage = ship
	fixture.cleared = ["route-6"]
	var untouched: Dictionary = fixture.duplicate(true)
	check(not game.transact(fixture,{"kind":"enter","at":fixture.revision}).ok and Store.equivalent(fixture,untouched),"Ship needs Bill ticket; rejection preserves RNG and state")
	fixture.flags.append("ss-ticket")
	check(game.transact(fixture,{"kind":"enter","at":fixture.revision}).ok,"Bill ticket enables ship")
	if chapter_number()>=18:
		fixture = fresh.duplicate(true)
		fixture.stage = game.locations.find(game.locations.filter(func(n):return n.id=="pokemon-tower")[0])
		fixture.cleared = ["tower-rival"]
		check(not game.transact(fixture,{"kind":"enter","at":fixture.revision}).ok,"Tower ghosts require Scope")
		fixture.flags.append("silph-scope")
		check(game.transact(fixture,{"kind":"enter","at":fixture.revision}).ok,"Scope enables tower encounter")
		fixture.cleared.append("pokemon-tower")
		check(not game.transact(fixture,{"kind":"enter","at":fixture.revision}).ok,"Cleared encounter cannot be farmed")
	var report: Dictionary = journey(game,fresh,[])
	if chapter_number()==17:
		var legacy_game: RefCounted = Legacy.new()
		var old: Dictionary = legacy_game.create("tactics-1",1)
		var commands: Array = []
		for index: int in 1000:
			if old.phase in ["defeat","complete"]: break
			var order: Dictionary = {"at":old.revision}
			match old.phase:
				"map": order.kind = "enter"
				"capture": order.kind = "capture"
				"battle": order.merge({"kind":"battle","order":legacy_game.engine.choose_command(old.battle)})
				"shop":
					order.kind = "continue"
					for member: Dictionary in old.party:
						if member.hp>0 and member.hp<legacy_game.progression.member_stats(member).maxHp-10:
							if old.bag.potion>0: order.merge({"kind":"heal","item":"potion","member":member.id},true)
							elif old.money>=40: order.merge({"kind":"buy","item":"potion"},true)
							break
			var step: Dictionary = legacy_game.transact(old,order)
			check(step.ok,"Legacy natural transaction")
			if not step.ok: break
			old = step.state
			commands.append(order)
		check(old.phase=="complete","Legacy12 sample completes")
		var upgrade: Dictionary = {"kind":"upgrade","edition":13,"at":old.revision}
		var changed: Dictionary = game.transact(old,upgrade)
		check(changed.ok and Store.equivalent(changed.state.party,old.party) and changed.state.money==old.money,"Upgrade12 preserves team, HP, moves, traits and money")
		if changed.ok:
			commands.append(upgrade)
			var store: RefCounted = Store.new(output_dir().path_join("journey-upgraded.json"))
			check(store.save(changed.state,commands,"journey").ok,"Save adopted12 campaign")
			var restored: Dictionary = store.load_campaign(game)
			check(restored.ok and Store.equivalent(restored.state,changed.state),"Replay changes engine exactly at upgrade")
			check(changed.state.phase=="map" and game.locations[int(changed.state.stage)].id=="route-3","Continue after Brock without new campaign")
			report.adoptedJourney = journey(game,changed.state,commands)
	else:
		var prior_path: String = output_dir().get_base_dir().path_join("qa-sprint-%d/journey-full.json" % (chapter_number()-1))
		check(FileAccess.file_exists(prior_path),"Previous delivered campaign exists for continuity test")
		if FileAccess.file_exists(prior_path):
			var prior_store: RefCounted = Store.new(prior_path)
			var previous: Dictionary = prior_store.load_campaign(game)
			check(previous.ok,"Previous chapter replays with its frozen edition: "+str(previous.get("reason","")))
			if previous.ok:
				var upgrade: Dictionary = {"kind":"upgrade","edition":chapter_number()-4,"at":previous.state.revision}
				var upgraded: Dictionary = game.transact(previous.state,upgrade)
				check(upgraded.ok and Store.equivalent(upgraded.state.party,previous.state.party) and upgraded.state.money==previous.state.money,"Next chapter preserves owned team/HP/money")
				if upgraded.ok:
					previous.commands.append(upgrade)
					report.adoptedJourney = journey(game,upgraded.state,previous.commands)
	var combined: Dictionary = {"chapter":chapter_number(),"checks":checks,"failures":failures,"journey":report}
	FileAccess.open(output_dir().path_join("journey-core-result.json"),FileAccess.WRITE).store_string(JSON.stringify(combined,"\t"))
	print(JSON.stringify(combined))
	quit(0 if failures.is_empty() else 1)

func journey(game: RefCounted, start: Dictionary, journal: Array) -> Dictionary:
	var state: Dictionary = start
	var encounters: Array = []
	for index: int in 20000:
		var order: Dictionary = policy.choose(game,state)
		if order.is_empty(): break
		var result: Dictionary = game.transact(state,order)
		check(result.ok,"Journey order "+str(order.kind)+" "+str(result.get("reason","")))
		if not result.ok: break
		state = result.state
		journal.append(order)
		if order.kind=="enter": encounters.append(game.locations[int(state.stage)].id)
		if order.kind=="capture":
			check(state.party.size()<=6,"At most six team slots")
			for member: Dictionary in game.members(state):
				var record: Dictionary = game.progression.species[int(member.speciesId)]
				check(not record.legendary and not record.mythical,"Legendary never recruited")
		if state.phase in ["defeat","ending"]: break
	check(state.phase in ["complete","ending"],"Natural journey completes instead of defeat/stall")
	if chapter_number()>=18 and state.phase in ["complete","ending"]:
		for flag: String in ["ss-ticket","cut","silph-scope","marowak-rest","poke-flute","fresh-water"]: check(flag in state.flags,"Story milestone persisted "+flag)
	var store: RefCounted = Store.new(output_dir().path_join("journey-full.json"))
	check(store.save(state,journal,"journey").ok,"Save full journey")
	var restored: Dictionary = store.load_campaign(game)
	check(restored.ok and Store.equivalent(restored.state,state),"Full expanded campaign replays")
	return {"phase":state.phase,"cleared":state.cleared,"medals":state.medals,"transactions":journal.size(),"encountered":encounters,"money":state.money,"party":state.party.map(func(m):return {"id":m.id,"species":m.speciesId,"level":m.level,"hp":m.hp}),"reserves":state.reserve.size()}

func chapter_number() -> int:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--chapter="): return int(arg.trim_prefix("--chapter="))
	return 17

func output_dir() -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--save-dir="): return arg.trim_prefix("--save-dir=")
	return OS.get_user_data_dir()
