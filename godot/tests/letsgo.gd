extends SceneTree

const Rules = preload("res://core/letsgo_run.gd")
const Store = preload("res://core/kanto_store.gd")
const Indicators = preload("res://ui/unit_indicators.gd")
var rules: RefCounted = Rules.new()
var assertions: int = 0
var failures: Array = []
var directory: String = ""

func check(value: bool, reason: String) -> void:
	assertions += 1
	if not value: failures.append(reason)

func fixture(species_id: int = 25, target_id: int = 19) -> Dictionary:
	var run: Dictionary = rules.create("lgpe-fixture",species_id if species_id in [1,4,7] else 1)
	var state: Dictionary = rules.engine.encounter(run,rules.locations[0])
	var a: Dictionary = rules.engine.member_unit(rules.progression.create_member(1,species_id,"QA",50),{"x":4,"y":4})
	var b: Dictionary = rules.engine.member_unit(rules.progression.create_member(2,target_id,"QA",50),{"x":5,"y":4})
	b.team = "enemy"
	b.facing = 2
	a.tp = 5
	a.maxHp = 10000
	a.hp = 5000
	b.maxHp = 10000
	b.hp = 5000
	a.lastDamage = 20
	state.units = [a,b]
	state.queue = [1,2]
	state.initiative = [{"id":1,"score":10},{"id":2,"score":1}]
	state.completed = []
	state.acted = false
	state.moved = false
	return state

func use_move(state: Dictionary, move: String, self_target: bool = false) -> Dictionary:
	state.units[0].moves = [move]
	return rules.engine.attack(state,1 if self_target else 2,move)

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="): directory = argument.trim_prefix("--save-dir=")
	if directory.is_empty(): quit(1); return
	var study: RefCounted = rules.progression
	check(study.species.size()==32 and study.data.moves.size()==104,"Complete current catalog")
	for species_id: int in study.species:
		var member: Dictionary = study.create_member(1,species_id,"QA",100)
		check(member.moves.size()<=4 and not member.knownMoves.is_empty(),"LGPE learnset and four move maximum: %d" % species_id)
		for move: String in member.knownMoves: check(not move in study.data.excludedPartnerMoves,"No partner-exclusive move")
	var pika: Dictionary = study.create_member(1,25,"QA",8)
	check(not "double-kick" in pika.knownMoves and not "iron-tail" in pika.knownMoves,"No custom early Iron Tail or premature Double Kick")
	study.candy(pika)
	check("double-kick" in pika.knownMoves and not "iron-tail" in pika.knownMoves,"Pikachu Double Kick at canonical level 9")
	check(not "ember" in study.create_member(1,4,"QA",12).knownMoves and "ember" in study.create_member(1,4,"QA",13).knownMoves,"Charmander Ember at 13")
	for tuple: Array in [[10,12,"mega-drain","gust"],[13,15,"brick-break","twineedle"]]:
		var bug: Dictionary = study.create_member(1,int(tuple[0]),"QA",5)
		for i: int in 5: study.candy(bug)
		check(bug.speciesId==tuple[1] and tuple[3] in bug.knownMoves and not tuple[2] in bug.knownMoves,"Canonical evolution move, no former coverage exception")
	check(rules.compatible(pika,"tm-iron-tail") and rules.shop_data.items["tm-iron-tail"].name.begins_with("MT19"),"Pikachu Iron Tail through canonical MT19")
	check(not rules.shop_data.items.has("tm-water-pulse") and not rules.shop_data.items.has("tm-rock-tomb"),"No unavailable LGPE TMs")
	for table: String in ["Route1","Route2","ViridianForest"]:
		var found: Dictionary = {}
		var sample: Dictionary = rules.create("samples-"+table,1)
		for i: int in 1200:
			var species_id: int = rules.pick(sample,table)
			found[species_id] = true
			var entries: Array = study.data.encounters[table].filter(func(e):return e.speciesId==species_id)
			check(not entries.is_empty() and sample.captureLevel>=entries[0].minLevel and sample.captureLevel<=entries[0].maxLevel,"Only local species/levels in "+table)
		check(found.has(43) and found.has(69),"Both editions merged in "+table)
		if table=="ViridianForest": check(found.has(1) and found.has(12) and found.has(15),"Forest special spawn and version evolutions included")
	for move: String in study.data.moves:
		var definition: Dictionary = study.data.moves[move]
		var state: Dictionary = fixture()
		state.units[0].moves = [move]
		var identity: int = 1 if definition.target=="self" else 2
		var before: Dictionary = state.duplicate(true)
		var preview: Dictionary = rules.engine.attack_plan(state,identity,{},move)
		check(preview.ok,"Executable imported move: "+move)
		check(Store.equivalent(before,state),"No RNG or state mutation in preview: "+move)
		var result: Dictionary = rules.engine.attack(state,identity,move)
		check(result.ok and result.state.acted,"Accepted move consumes action: "+move)
	var up: Dictionary = use_move(fixture(),"agility",true)
	check(up.ok and up.state.units[0].stages.speed==2,"Agility applies +2 speed")
	var down: Dictionary = use_move(fixture(),"growl")
	check(down.ok and down.state.units[1].stages.attack==-1,"Growl applies attack down")
	var multi: Dictionary = use_move(fixture(),"quiver-dance",true)
	check(multi.ok and multi.state.units[0].stages.size()==3,"Quiver Dance applies three independent modifiers")
	var smoke: Dictionary = use_move(fixture(),"smokescreen")
	check(smoke.ok and smoke.state.units[1].accuracy==75,"Accuracy modifier uses its canonical 3-based stat stage")
	var sleep_state: Dictionary = fixture(12)
	var slept: Dictionary = use_move(sleep_state,"sleep-powder")
	# A seeded miss is legitimate; find an actual hit to exercise its duration.
	for seed: int in range(1,40):
		if slept.ok and slept.state.units[1].status!=null: break
		sleep_state.rng = seed
		slept = use_move(sleep_state,"sleep-powder")
	check(slept.state.units[1].status!=null and slept.state.units[1].status.kind=="sleep","Sleep Powder can inflict sleep")
	var sleeping: Dictionary = slept.state
	sleeping.queue = [2,1]
	sleeping.acted = false
	var hp: int = sleeping.units[1].hp
	check(not rules.engine.attack_plan(sleeping,1,{},"basic").ok,"Sleep blocks attacks")
	var finished: Dictionary = rules.engine.finish(sleeping,2)
	check(finished.ok and finished.state.units[1].hp==hp and finished.state.units[1].status.remaining==2,"Sleep expires by activations without burn damage")
	var stage_unit: Dictionary = up.state.units[0]
	stage_unit.status = {"kind":"poison","remaining":3}
	var badges: Array = Indicators.entries(stage_unit)
	check(badges.size()==2 and badges[0].key=="poison" and badges[1].key=="speed" and badges[1].stage==2,"Shared badges identify the condition and exact raised stat")
	check(Indicators.entries(down.state.units[1])[0].stage==-1 and Indicators.entries(fixture().units[0]).is_empty(),"Down arrow and reset remove stale indicators")
	var basic_state: Dictionary = fixture(25)
	var basic: Dictionary = rules.engine.attack_plan(basic_state,2,{},"basic")
	check(basic.ok and basic.stab==1 and basic.multiplier==1,"Mandatory basic remains typeless without STAB")
	basic_state.units[0].moves = ["thunder-shock"]
	var electric: Dictionary = rules.engine.attack_plan(basic_state,2,{},"thunder-shock")
	check(electric.stab==1.5,"Typed attack retains real STAB")
	var immune_state: Dictionary = fixture(25,95)
	immune_state.units[0].moves = ["thunder-shock"]
	var immune: Dictionary = rules.engine.attack_plan(immune_state,2,{},"thunder-shock")
	check(immune.ok and immune.multiplier==0 and immune.damage==0,"Ground immunity preserved")
	var fixed: Dictionary = use_move(fixture(4),"dragon-rage")
	check(fixed.ok and fixed.damage==40,"Dragon Rage really deals fixed 40 HP")
	var counter: Dictionary = use_move(fixture(19),"counter")
	check(counter.ok and counter.damage==40,"Counter uses previous damage")
	var none: Dictionary = fixture(19)
	none.units[0].lastDamage = 0
	check(not use_move(none,"counter").ok,"No free Counter damage without a prior hit")
	var explosive: Dictionary = fixture(74)
	var exploded: Dictionary = use_move(explosive,"explosion")
	check(exploded.ok and exploded.state.units[0].hp==0 and exploded.state.outcome=="defeat","Explosion resolves mandatory self KO and defeat")
	var seeded: Dictionary = fixture(1)
	var planted: Dictionary = use_move(seeded,"leech-seed")
	for seed_number: int in range(1,40):
		if planted.ok and planted.state.units[1].volatile.has("seed"): break
		seeded.rng = seed_number
		planted = use_move(seeded,"leech-seed")
	planted.state.queue = [2,1]
	var drain_hp: int = planted.state.units[1].hp
	var drain: Dictionary = rules.engine.finish(planted.state,2)
	check(drain.ok and drain.state.units[1].hp==drain_hp-1250 and drain.state.units[0].hp==6250,"Drenadoras ticks and heals the living source")
	var grass: Dictionary = use_move(fixture(1,43),"leech-seed")
	check(not grass.ok,"Grass immunity to Leech Seed")
	var evade_state: Dictionary = fixture(25)
	var evade: Dictionary = use_move(evade_state,"double-team",true)
	check(evade.ok and evade.state.units[0].evasion==133,"Evasion uses 3-based stages")
	var altered: Dictionary = fixture(71)
	rules.engine._change(altered.units[1],{"stat":"attack","stages":2})
	var cleansed: Dictionary = use_move(altered,"clear-smog")
	check(cleansed.ok and cleansed.state.units[1].stages.is_empty() and cleansed.state.units[1].attack==altered.units[1].baseCombatStats.attack,"Clear Smog actually resets stages and restores base stat")
	check(study.data.moves.outrage.secondary==null and study.data.moves["petal-dance"].secondary==null,"Rampage moves never confuse their target incorrectly")
	var stone_run: Dictionary = rules.create("stone",1)
	stone_run.phase = "shop"
	stone_run.party = [study.create_member(1,44,"QA",21)]
	stone_run.party[0].hp = 9
	stone_run.party[0].xp = 27
	var purchase: Dictionary = rules.transact(stone_run,{"kind":"buy-stone","at":0})
	check(purchase.ok,"Buy Leaf Stone")
	var evolved: Dictionary = rules.transact(purchase.state,{"kind":"stone","member":1,"at":1})
	check(evolved.ok and evolved.state.party[0].speciesId==45 and evolved.state.party[0].hp==9 and evolved.state.party[0].xp==27,"Canonical Leaf Stone evolution preserves HP and XP")
	# Save every published edition through its own rule selector, including a live fight.
	for script: String in ["kanto_run","progression_run","shop_run","growth_run","letsgo_run"]:
		var original: RefCounted = load("res://core/"+script+".gd").new()
		var order: Dictionary = {"kind":"enter","at":0}
		var state: Dictionary = original.transact(original.create("compat-lgpe",4),order).state
		var archive: Store = Store.new(directory.path_join("lgpe-"+script+".json"))
		check(archive.save(state,[order],"").ok,"Save "+script)
		var loaded: Dictionary = archive.load_campaign(rules)
		check(loaded.ok and Store.equivalent(loaded.state,state),"Preserve old/new battle and RNG "+script)
	var result: Dictionary = {"assertions":assertions,"failures":failures,"species":study.species.size(),"moves":study.data.moves.size()}
	var report: FileAccess = FileAccess.open(directory.path_join("letsgo-result.json"),FileAccess.WRITE)
	report.store_string(JSON.stringify(result,"\t"))
	print(JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
