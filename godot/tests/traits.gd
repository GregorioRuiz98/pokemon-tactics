extends SceneTree

const Current = preload("res://core/traits_run.gd")
const Store = preload("res://core/kanto_store.gd")
var rules: RefCounted = Current.new()
var checks: int = 0
var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)

func force(unit: Dictionary, identity: String) -> void:
	unit.ability = identity
	unit.abilityName = rules.progression.traits.abilities[identity].name if identity!="" else "Sin habilidad"

func arena(first: int = 4, second: int = 7) -> Dictionary:
	var state: Dictionary = rules.engine.encounter(rules.create("trait-arena",4),rules.locations[0])
	state.units = [rules.engine.member_unit(rules.progression.create_member(1,first,"QA",13),{"x":2,"y":7}),rules.engine.member_unit(rules.progression.create_member(10000,second,"QA",13),{"x":3,"y":7})]
	state.units[1].team = "enemy"
	state.units[1].facing = 2
	for unit: Dictionary in state.units: unit.tp = 5; force(unit,"")
	# Controlled engine fixture: explicitly prepare the moves under inspection.
	state.units[0].moves = ["vine-whip","ember","water-gun","twineedle","sleep-powder","bubble-beam","string-shot","sand-attack","dragon-rage","take-down"]
	state.queue = [1,10000]
	state.acted = false
	state.moved = false
	state.abilityEvents = []
	return state

func nature_cases() -> void:
	var study: RefCounted = rules.progression
	check(study.traits.natures.size()==25 and study.mintable().size()==21,"25 natures and 21 real mint effects, including neutral Serious")
	check(study.traits.natures.adamant.up=="attack" and study.traits.natures.adamant.down=="specialAttack","Adamant uses the correct PokéAPI stat mapping")
	check(study.traits.natures.timid.up=="speed" and study.traits.natures.modest.up=="specialAttack","Speed and special attack are not confused in CSV stat IDs")
	for species: int in study.species:
		var member: Dictionary = study.create_member(1,species,"QA",13)
		var base: Dictionary = study.stats(species,13)
		for nature: String in study.traits.natures:
			member.nature = nature
			member.mint = null
			var actual: Dictionary = study.member_stats(member)
			var profile: Dictionary = rules.engine.member_unit(member)
			check(actual.maxHp==base.maxHp and profile.maxHp==base.maxHp,"Natures never change HP, including every evolved profile")
			for stat: String in study.STAT_KEYS:
				var definition: Dictionary = study.traits.natures[nature]
				var factor: float = 1.1 if stat==definition.up else (0.9 if stat==definition.down else 1.0)
				check(actual[stat]==maxi(1,int(floor(base[stat]*factor))) and profile[stat]==actual[stat] and profile.baseCombatStats[stat]==actual[stat],"Nature stats reach the combat unit and its stage baseline")
	var before: Dictionary = rules.create("assigned",4)
	var duplicate: Dictionary = rules.create("assigned",4)
	check(Store.equivalent(before,duplicate) and before.party[0].has("nature"),"Same seed fixes nature and ability before saving")
	var previous: RefCounted = load("res://core/revive_run.gd").new()
	var legacy: Dictionary = previous.create("assigned",4)
	check(before.rng==legacy.rng and Store.equivalent(before.shopRandom,legacy.shopRandom),"Traits never consume route/shop RNG")
	study.gym_cap = 100
	var bug: Dictionary = study.create_member(1,10,"QA",6)
	study.assign(bug,"evolve")
	bug.mint = "adamant"
	var nature: String = bug.nature
	var slot: int = bug.abilitySlot
	study.candy(bug)
	check(bug.speciesId==11 and study.ability(bug)=="shed-skin" and bug.nature==nature and bug.mint=="adamant" and bug.abilitySlot==slot,"Evolution preserves nature/mint/slot and changes the species' passive")
	study.candy(bug); study.candy(bug); study.candy(bug)
	check(bug.speciesId==12 and study.ability(bug)=="compound-eyes","Next evolution resolves the same slot to Compound Eyes")

func item_cases() -> void:
	var run: Dictionary = rules.create("trait-shop",4)
	run.phase = "shop"
	run.money = 1000
	run.party.append(rules.progression.create_member(2,16,"QA",5))
	rules.progression.assign(run.party[1],"trait-shop")
	var member: Dictionary = run.party[1]
	var chosen: String = "modest" if rules.progression.effective_nature(member)=="adamant" else "adamant"
	var before: Dictionary = run.duplicate(true)
	var result: Dictionary = rules.transact(run,{"kind":"buy","item":"mint-"+chosen,"at":run.revision})
	check(result.ok and result.state.money==900 and result.state.bag["mint-"+chosen]==1 and Store.equivalent(run,before),"Buy one mint for 100 with immutable input")
	run = result.state
	var expected: Dictionary = run.party[1].duplicate(true)
	expected.mint = chosen
	result = rules.transact(run,{"kind":"mint","member":2,"nature":chosen,"at":run.revision})
	check(result.ok and Store.equivalent(result.state.party[1],expected) and result.state.bag["mint-"+chosen]==0,"Mint changes only its effective nature, never HP/EXP/original nature")
	run = result.state
	run.bag["mint-"+chosen] = 1
	before = run.duplicate(true)
	check(not rules.transact(run,{"kind":"mint","member":2,"nature":chosen,"at":run.revision}).ok and Store.equivalent(run,before),"Same mint effect cannot consume another item")
	result = rules.transact(run,{"kind":"buy","item":"ability-capsule","at":run.revision})
	check(result.ok and result.state.money==750 and result.state.bag["ability-capsule"]==1,"Capsule costs 150")
	run = result.state
	expected = run.party[1].duplicate(true)
	expected.abilitySlot = rules.progression.next_slot(expected)
	result = rules.transact(run,{"kind":"capsule","member":2,"at":run.revision})
	check(result.ok and Store.equivalent(result.state.party[1],expected) and result.state.bag["ability-capsule"]==0,"Capsule changes only the normal ability slot")
	run = result.state
	run.bag["ability-capsule"] = 1
	check(not rules.transact(run,{"kind":"capsule","member":1,"at":run.revision}).ok,"A single-ability starter cannot consume a capsule")
	for phase: String in ["battle","map","capture","defeat","complete"]:
		run.phase = phase
		for command: Dictionary in [{"kind":"capsule","member":2},{"kind":"mint","member":2,"nature":chosen},{"kind":"buy","item":"ability-capsule"},{"kind":"buy","item":"mint-adamant"}]:
			command.at = run.revision
			check(not rules.transact(run,command).ok,"No nature/ability changes outside the shop")
	run.phase = "shop"
	run.party[1].hp = 0
	check(not rules.transact(run,{"kind":"capsule","member":2,"at":run.revision}).ok,"Fallen Pokémon cannot change abilities")
	check(not rules.transact(run,{"kind":"mint","member":2,"nature":"timid","at":run.revision}).ok,"Fallen Pokémon cannot use mints")
	check(not rules.transact(run,{"kind":"buy","item":"mint-nonsense","at":run.revision}).ok,"Unknown mint rejected")
	check(not rules.transact(run,{"kind":"capsule","member":2,"at":run.revision-1}).ok,"Stale callback rejected")
	run.money = 99
	check(not rules.transact(run,{"kind":"buy","item":"mint-adamant","at":run.revision}).ok,"Insufficient mint funds rejected")
	run.money = 149
	check(not rules.transact(run,{"kind":"buy","item":"ability-capsule","at":run.revision}).ok,"Insufficient capsule funds rejected")

func passive_cases() -> void:
	var engine: RefCounted = rules.engine
	for entry: Array in [[1,"overgrow","vine-whip"],[4,"blaze","ember"],[7,"torrent","water-gun"],[15,"swarm","twineedle"]]:
		var state: Dictionary = arena(int(entry[0]),95)
		var actor: Dictionary = state.units[0]
		force(actor,entry[1])
		actor.hp = int(actor.maxHp/3)
		var boosted: Dictionary = engine.attack_plan(state,10000,{},entry[2])
		force(actor,"")
		var normal: Dictionary = engine.attack_plan(state,10000,{},entry[2])
		check(boosted.ok and boosted.get("normalMax",0)>normal.get("normalMax",0),"Starter/Swarm threshold boosts its matching move: "+str(entry))
	var state: Dictionary = arena(19,7)
	var actor: Dictionary = state.units[0]
	actor.status = {"kind":"burn","remaining":3}
	force(actor,"guts")
	var guts: Dictionary = engine.attack_plan(state,10000,{},"basic")
	force(actor,"")
	var burned: Dictionary = engine.attack_plan(state,10000,{},"basic")
	actor.status = null
	var neutral: Dictionary = engine.attack_plan(state,10000,{},"basic")
	check(guts.normalMax>neutral.normalMax and neutral.normalMax>burned.normalMax,"Guts boosts Attack and bypasses the burn penalty")
	state = arena(12,7)
	force(state.units[0],"compound-eyes")
	check(engine.attack_plan(state,10000,{},"sleep-powder").accuracy==97,"Compound Eyes: Sleep Powder 75 becomes 97")
	force(state.units[0],"keen-eye")
	state.units[1].stages.evasion = 2
	check(engine.attack_plan(state,10000,{},"basic").accuracy==100,"Keen Eye ignores positive target evasion stages")
	force(state.units[1],"tangled-feet")
	state.units[1].stages.clear()
	state.units[1].volatile.confusion = {"remaining":3,"source":1}
	force(state.units[0],"")
	check(engine.attack_plan(state,10000,{},"basic").accuracy==50,"Tangled Feet halves accuracy while confused")
	state = arena(7,10)
	force(state.units[1],"shield-dust")
	var shielded: Dictionary = engine.attack_plan(state,10000,{},"bubble-beam")
	check(shielded.ok and shielded.changes.is_empty() and "Polvo Escudo" in shielded.abilityHints,"Shield Dust blocks damaging move secondary stat changes")
	check(engine.attack_plan(state,10000,{},"string-shot").changes.size()>0,"Shield Dust does not block pure status moves")
	force(state.units[1],"keen-eye")
	check(not engine.attack_plan(state,10000,{},"sand-attack").ok,"Keen Eye prevents a pure accuracy drop")
	state = arena(4,95)
	force(state.units[1],"sturdy")
	state.units[1].hp = 30
	state.units[1].maxHp = 30
	var snapshot: Dictionary = state.duplicate(true)
	var sturdy: Dictionary = engine.attack_plan(state,10000,{},"dragon-rage")
	check(sturdy.damageMax==29 and sturdy.sturdy and Store.equivalent(state,snapshot),"Sturdy preview shows one HP survival without RNG/mutation")
	var result: Dictionary = engine.attack(state,10000,"dragon-rage")
	check(result.ok and result.state.units[1].hp==1 and not result.state.abilityEvents.is_empty(),"Sturdy prevents a lethal fixed hit and announces activation")
	state.units[0].moves.append("mega-drain")
	state.units[0].hp = 1
	var drain: Dictionary = engine.attack_plan(state,10000,{},"mega-drain")
	check(drain.sturdy and drain.damageMax==29 and drain.heal==14,"Drain preview uses damage after Sturdy rather than uncapped damage")
	result = engine.attack(state,10000,"mega-drain")
	check(result.hit and result.state.units[0].hp==15,"Actual drain agrees with the Sturdy-limited heal preview")
	state.units[1].hp = 29
	result = engine.attack(state,10000,"dragon-rage")
	check(result.state.units[1].hp==0,"Sturdy cannot protect an injured target")
	state = arena(95,7)
	force(state.units[0],"rock-head")
	state.units[0].heldItem = "life-orb"
	var recoil: Dictionary = engine.attack_plan(state,10000,{},"take-down")
	check(recoil.ok and recoil.recoil==maxi(1,int(state.units[0].maxHp/10.0)),"Rock Head preview removes move recoil but retains Life Orb")
	result = engine.attack(state,10000,"take-down")
	if result.hit: check(state.units[0].hp-result.state.units[0].hp==maxi(1,int(state.units[0].maxHp/10.0)),"Rock Head resolution retains only Life Orb cost")
	var static_hits: int = 0
	var cures: int = 0
	for seed: int in 120:
		state = arena(74,25)
		state.rng = seed
		force(state.units[1],"static")
		result = engine.attack(state,10000,"basic")
		if result.state.units[0].status!=null: static_hits += 1
		check(Store.equivalent(engine.attack_plan(state,10000,{},"basic"),engine.attack_plan(state,10000,{},"basic")),"Repeated forecasts never consume Static's RNG")
		state = arena(11,7)
		state.rng = seed
		force(state.units[0],"shed-skin")
		state.units[0].status = {"kind":"poison","remaining":3}
		state.units[0].volatile.confusion = {"remaining":3,"source":10000}
		result = engine.finish(state,0)
		if result.state.units[0].status==null: cures += 1
		check(result.state.units[0].volatile.has("confusion"),"Shed Skin never cures a volatile condition")
	check(static_hits>15 and static_hits<60,"Static activates stochastically at contact, including Ground attackers")
	check(cures>15 and cures<65,"Shed Skin cures sometimes, not always")
	state = arena(7,25)
	force(state.units[1],"static")
	var unchanged: Dictionary = state.duplicate(true)
	engine.choose_command(state)
	engine.attack_plan(state,10000,{},"basic")
	check(Store.equivalent(state,unchanged),"AI and repeated previews consume no passive or combat RNG")
	check(engine.attack_plan(state,10000,{},"water-gun").staticChance==0,"Ranged non-contact attacks never trigger Static")
	state = arena(25,25)
	force(state.units[1],"static")
	check(engine.attack_plan(state,10000,{},"basic").staticChance==0,"Electric attackers remain immune to Static paralysis")

func replay_cases(directory: String) -> void:
	for script: String in ["kanto_run","progression_run","shop_run","growth_run","letsgo_run","tactics_run","vitality_run","gym_run","revive_run","traits_run"]:
		var edition: RefCounted = load("res://core/"+script+".gd").new()
		var order: Dictionary = {"kind":"enter","at":0}
		var state: Dictionary = edition.transact(edition.create("trait-replay",4),order).state
		var store: RefCounted = Store.new(directory.path_join("trait-replay-"+script+".json"))
		check(store.save(state,[order],"").ok,"Save each edition")
		var restored: Dictionary = store.load_campaign(rules)
		check(restored.ok and Store.equivalent(state,restored.state),"Replay selects the original edition without rerolling traits")

func neutral_parity() -> void:
	var legacy: RefCounted = load("res://core/tactics_run.gd").new()
	for starter: int in [1,4,7]:
		var state: Dictionary = legacy.engine.encounter(legacy.create("neutral-passive-parity",starter),legacy.locations[0])
		for step: int in 120:
			if state.outcome!="playing": break
			var command: Dictionary = legacy.engine.choose_command(state)
			var old: Dictionary = legacy.engine.apply_command(state,command)
			var current: Dictionary = rules.engine.apply_command(state,command)
			check(old.ok and current.ok,"Both resolvers accept the same traitless command")
			current.state.erase("abilityEvents")
			current.state.combatEdition = old.state.combatEdition
			check(Store.equivalent(old.state,current.state),"Without traits the new resolver preserves damage, states, recoil, queues and RNG exactly")
			state = old.state

func _initialize() -> void:
	var directory: String = ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="): directory = argument.trim_prefix("--save-dir=")
	if directory.is_empty(): quit(1); return
	nature_cases()
	item_cases()
	passive_cases()
	neutral_parity()
	replay_cases(directory)
	var output: Dictionary = {"checks":checks,"failures":failures}
	var file: FileAccess = FileAccess.open(directory.path_join("traits-result.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(output,"  "))
	file.close()
	print(JSON.stringify(output))
	quit(0 if failures.is_empty() else 1)
