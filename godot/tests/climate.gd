extends SceneTree

const Battle = preload("res://core/climate_battle.gd")
const Journey = preload("res://core/climate_run.gd")
const Store = preload("res://core/climate_store.gd")
const Context = preload("res://core/climate_context.gd")
var engine: RefCounted = Battle.new()
var checks: int = 0
var failures: Array[String] = []
var directory: String = ""
var fixture_base: Dictionary = {}

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition: failures.append(label); print("CHECK_FAILED: "+label)

func fixture(a: String = "", b: String = "", species_a: int = 4, species_b: int = 1) -> Dictionary:
	var state: Dictionary = {"seed":"climate-fixture","rng":100,"variance":0.05,"round":1,"log":[],"spatialClock":0,"spatialZones":0,"initiative":[],"abilityEvents":[],"zoneEvents":[],"tacticalEvents":[],"arena":{},"biome":"route-1","combatEdition":22}
	state.board = []; state.heights = []
	for row: int in 8: state.board.append([0,0,0,0,0,0,0,0]); state.heights.append([0,0,0,0,0,0,0,0])
	state.fields = []; state.restorativeTiles = []; state.deployment = false; state.mission = {"kind":"defeat"}
	var actor: Dictionary = engine.member_unit(engine.progression.create_member(1,species_a,"Fixture",30),{"x":2,"y":4})
	var target: Dictionary = engine.member_unit(engine.progression.create_member(10000,species_b,"Fixture",30),{"x":3,"y":4})
	target.team = "enemy"; target.facing = 4
	for unit: Dictionary in [actor,target]:
		unit.nativeAbility = a if unit.id==1 else b; unit.ability = unit.nativeAbility
		unit.abilityName = unit.ability; unit.hp = 2000; unit.maxHp = 2000; unit.remaining = 6; unit.budget = 6
		unit.gender = "male"; unit.moves = ["ember","growl","rain-dance","sunny-day"]
	state.units = [actor,target]; state.queue = [1,10000]; state.completed = []; state.outcome = "playing"; state.moved = false; state.acted = false
	state.weather = {"kind":"clear","expires":0}; state.round = 1; state.rng = 100; state.climateActions = 0
	return state

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="): directory = argument.trim_prefix("--save-dir=")
	call_deferred("run_checks")

func run_checks() -> void:
	print("CLIMATE_STEP: initializing campaign")
	var rules: RefCounted = Journey.new()
	fixture_base = rules.create("climate-fixture",4)
	print("CLIMATE_STEP: catalog and fixtures")
	check(engine.catalog.moves.size()==214,"211 existing techniques plus three weather moves")
	var historical_study: RefCounted = preload("res://core/power_study.gd").new()
	for index: int in engine.catalog.families.size():
		var retained: Array = engine.catalog.families[index].learnset.filter(func(entry):return not engine.progression.climate.moves.has(entry.id))
		check(Store.equivalent(retained,historical_study.data.families[index].learnset),"Original learnset order preserved: "+str(index))
	var weather_member: Dictionary = engine.progression.create_member(400,43,"Weather",15)
	engine.progression.assign(weather_member,"weather-learning")
	engine.progression.learn(weather_member)
	check("sunny-day" in weather_member.knownMoves,"Weather ability family learns its climate at level15")
	weather_member.moves = ["sunny-day"]
	check(engine.progression.roles(weather_member)=="","Weather loadouts have no legacy role requirement")
	for identity: String in engine.progression.traits.abilities:
		var entry: Dictionary = engine.progression.traits.abilities[identity]
		check(entry.get("implemented",entry.get("available",false)),"Applicable ability: "+identity)
	for dex: int in range(1,152):
		var member: Dictionary = engine.progression.create_member(dex,dex,"Fixture",10)
		engine.progression.assign(member,"gender")
		check(member.gender in ["male","female",""] and member.gender==Context.gender("gender",member,engine.progression.climate.genderRates),"Persistent species gender: "+str(dex))
	var state: Dictionary = fixture()
	var initial: Dictionary = state.duplicate(true)
	var clear: Dictionary = engine.cast_plan(state,state.units[1],"ember")
	check(clear.ok,"Basic forecast works")
	state.weather = {"kind":"sun","expires":5}
	var sun: Dictionary = engine.cast_plan(state,state.units[1],"ember")
	state.weather.kind = "rain"
	var rain: Dictionary = engine.cast_plan(state,state.units[1],"ember")
	check(sun.damage>clear.damage and rain.damage<clear.damage,"Sun/rain affect Fire")
	state = initial.duplicate(true)
	var result: Dictionary = engine.cast(state,state.units[0],"rain-dance")
	check(result.ok and result.state.weather.kind=="rain" and result.state.weather.expires==5,"Weather move creates three complete rounds")
	check(Context.label(result.state).contains("Lluvia"),"Weather UI label")
	check(Store.equivalent(initial,state),"Forecast/cast input remains unchanged")
	state = fixture("chlorophyll")
	state.weather = {"kind":"sun","expires":4}; state.round = 0
	engine.new_round(state)
	var score: float = state.initiative.filter(func(e):return e.id==1)[0].score
	check(score>state.units[0].speed*1.8,"Chlorophyll doubles next initiative")
	check(state.queue.size()==2,"No extra activations from weather")
	state.round = 3; engine.new_round(state)
	check(state.weather.kind=="clear","Weather expires on full-round boundary")
	for ability: String in ["magic-guard","hydration","natural-cure","early-bird","dry-skin","sand-veil"]:
		state = fixture(ability)
		state.units[0].status = {"kind":"sleep" if ability=="early-bird" else "poison","remaining":3}
		if ability=="dry-skin": state.units[0].status = null
		state.units[0].hp = 1000
		state.weather = {"kind":"rain" if ability in ["hydration","dry-skin"] else "sand","expires":4}
		result = engine.finish(state)
		check(result.ok,"Finish with "+ability)
		var actor: Dictionary = Battle.unit_by_id(result.state,1)
		if ability in ["hydration","natural-cure"]: check(actor.status==null,"Status cured by "+ability)
		if ability=="early-bird": check(actor.status.remaining==1,"Early Bird advances sleep twice")
		if ability=="magic-guard": check(actor.hp==1000,"Magic Guard prevents poison and sand")
		if ability=="dry-skin": check(actor.hp>1000,"Dry Skin restores in rain")
	state = fixture("","leaf-guard"); state.weather = {"kind":"sun","expires":4}
	var working: Dictionary = Context.planning(state)
	check(not engine._can_status(working.units[1],"sleep"),"Leaf Guard prevents a new status")
	state = fixture("","cloud-nine"); state.weather = {"kind":"sun","expires":4}
	check(Context.weather(state,state.units[0])=="clear","Cloud Nine suppresses nearby weather")
	state.units[1].x = 7
	check(Context.weather(state,state.units[0])=="sun","Weather returns outside Cloud Nine")
	state = fixture("sniper")
	var sniper: Dictionary = engine.cast_plan(state,state.units[1],"ember")
	state.units[0].nativeAbility = ""; state.units[0].ability = ""
	clear = engine.cast_plan(state,state.units[1],"ember")
	check(sniper.criticalMax>clear.criticalMax and sniper.normalMax==clear.normalMax,"Sniper affects only critical damage")
	state = fixture("scrappy","",4,92)
	check(engine.cast_plan(state,state.units[1],"basic").multiplier==1,"Typeless basic preserved")
	state.units[0].moves.append("tackle")
	check(engine.cast_plan(state,state.units[1],"tackle").multiplier>0,"Scrappy hits Ghost")
	state = fixture("","competitive")
	result = engine.cast(state,state.units[1],"growl")
	check(result.ok and result.state.units[1].stages.get("specialAttack",0)==2,"Competitive responds to hostile decrease")
	state = fixture("","sticky-hold")
	check(not engine._displacement(state,state.units[0],state.units[1],{"pushDistance":1}).has("destination"),"Sticky Hold prevents displacement")
	state = fixture("","neutralizing-gas")
	state.units[0].nativeAbility = "sniper"
	check(Context.ability(state,state.units[0])=="","Gas suppresses ability")
	state.units[1].x = 7
	check(Context.ability(state,state.units[0])=="sniper","Gas suppression is reversible")
	state = fixture("run-away"); state.units[1].x = 3
	var paths: Dictionary = engine.movement_routes(state,state.units[0],4)
	check(paths.has("4,4") and not paths.has("3,4"),"Run Away traverses enemy without occupying destination")
	state = fixture("","pressure")
	engine.begin_activation(state)
	check(state.units[0].remaining==5,"Pressure subtracts one movement")
	state = fixture("","arena-trap")
	paths = engine.movement_routes(state,state.units[0],2)
	check(paths.get("1,4",{}).get("cost",0)==2,"Arena Trap adds movement cost")
	state = fixture("","magnet-pull",81)
	paths = engine.movement_routes(state,state.units[0],2)
	check(paths.get("2,3",{}).get("cost",0)==2,"Magnet Pull affects Steel")
	state = fixture("trace","sniper")
	check(engine.entry_preview(state)[0].ability==engine.progression.traits.abilities.sniper.name,"Trace preview before deployment")
	engine.start_battle(state)
	check(state.units[0].nativeAbility=="sniper","Trace copies nearest eligible ability")
	state = fixture("download")
	engine.start_battle(state)
	var stages: Dictionary = state.units[0].stages.duplicate()
	engine.start_battle(state)
	check(stages==state.units[0].stages and stages.size()==1,"Download only once per battle")
	state = fixture("forewarn")
	engine.start_battle(state)
	check(state.units[0].climate.forewarn=="ember","Forewarn marks strongest move")
	var campaign: Dictionary = rules.create("climate-ledger",4)
	check(campaign.edition==25 and campaign.party[0].has("gender"),"New campaign edition/gender")
	var old: RefCounted = preload("res://core/sleep_run.gd").new()
	var previous: Dictionary = old.create("old-climate",4)
	result = rules.transact(previous,{"kind":"upgrade","edition":25,"at":previous.revision})
	check(result.ok and result.state.party[0].hp==previous.party[0].hp and result.state.rng==previous.rng,"Upgrade preserves HP and RNG")
	var store: RefCounted = Store.new(directory.path_join("climate-core-%d.json"%Time.get_ticks_usec()))
	check(store.save(result.state,[{"kind":"upgrade","edition":25,"at":0}],"current").ok,"Mixed journal saved")
	var loaded: Dictionary = store.load_campaign(rules)
	check(loaded.ok and Store.equivalent(loaded.state,result.state),"Mixed edition24→25 replay")
	var challenge: String = preload("res://core/climate_challenge.gd").encode(campaign)
	check(preload("res://core/climate_challenge.gd").decode(challenge).edition==25,"Challenge round trip")
	more_checks(rules)
	var journey: Dictionary = rules.create("undo-weather",4)
	var step: Dictionary = rules.transact(journey,{"kind":"enter","at":journey.revision})
	check(step.ok,"Real encounter generated")
	journey = step.state
	step = rules.transact(journey,{"kind":"start-battle","at":journey.revision})
	check(step.ok,"Real deployment confirmed")
	journey = step.state
	var untouched: Dictionary = journey.battle.duplicate(true)
	var acting: Dictionary = engine.active(journey.battle)
	var route_options: Array = rules.engine.movement_routes(journey.battle,acting,acting.remaining).values().filter(func(r):return r.cost>0)
	check(not route_options.is_empty(),"Current activation has legal movement")
	if not route_options.is_empty():
		step = rules.transact(journey,{"kind":"battle","order":{"kind":"move","destination":route_options[0].path[-1]},"at":journey.revision})
		check(step.ok,"Movement accepted by new campaign")
		if step.ok:
			step = rules.transact(step.state,{"kind":"rectify","at":step.state.revision})
			check(step.ok and Store.equivalent(step.state.battle,untouched),"Movement-only undo preserves abilities, RNG and initiative")
	var historical: Dictionary = old.create("ongoing-weather",4)
	historical = old.transact(historical,{"kind":"enter","at":0}).state
	check(not rules.transact(historical,{"kind":"upgrade","edition":25,"at":historical.revision}).ok,"An active historical encounter cannot be upgraded")
	var report: Dictionary = {"checks":checks,"failures":failures}
	FileAccess.open(directory.path_join("climate-result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print(JSON.stringify(report)); quit(0 if failures.is_empty() else 1)

func more_checks(rules: RefCounted) -> void:
	var state: Dictionary = fixture("rivalry")
	var same: Dictionary = engine.cast_plan(state,state.units[1],"ember")
	state.units[1].gender = "female"
	var opposite: Dictionary = engine.cast_plan(state,state.units[1],"ember")
	state.units[1].gender = ""
	var neutral: Dictionary = engine.cast_plan(state,state.units[1],"ember")
	check(same.damage>neutral.damage and neutral.damage>opposite.damage,"Rivalry same/opposite/genderless")
	state = fixture("","liquid-ooze",4,7); state.units[0].hp = 1000; state.units[0].moves = ["absorb"]
	var plan: Dictionary = engine.cast_plan(state,state.units[1],"absorb")
	var result: Dictionary = engine.cast(state,state.units[1],"absorb")
	check(plan.heal<0 and result.ok and result.state.units[0].hp<1000,"Liquid Ooze matches drain forecast")
	state = fixture("magic-guard"); state.units[0].heldItem = "life-orb"
	plan = engine.cast_plan(state,state.units[1],"ember")
	result = engine.cast(state,state.units[1],"ember")
	check(plan.recoil==0 and result.state.units[0].hp==state.units[0].hp,"Magic Guard prevents Life Orb recoil with power intact")
	state = fixture("","inner-focus"); state.units[0].moves = ["fake-out"]
	check(not engine.cast_plan(state,state.units[1],"fake-out").ok,"Inner Focus forecast blocks flinch")
	state = fixture("","oblivious"); state.units[0].moves = ["taunt"]
	check(not engine.cast_plan(state,state.units[1],"taunt").ok,"Oblivious forecast blocks Taunt")
	state = fixture("mold-breaker","leaf-guard"); state.units[0].moves = ["spore"]; state.weather = {"kind":"sun","expires":4}
	result = engine.cast(state,state.units[1],"spore")
	check(result.ok and result.state.units[1].status!=null,"Mold Breaker bypasses Leaf Guard consistently")
	state = fixture("","sand-veil"); state.units[1].x = 4; state.weather = {"kind":"sand","expires":4}
	plan = engine.cast_plan(state,state.units[1],"ember")
	state.units[1].nativeAbility = ""; state.units[1].ability = ""
	check(plan.damage<engine.cast_plan(state,state.units[1],"ember").damage,"Sand Veil reduces ranged damage without accuracy penalty")
	state = fixture("sniper")
	var light: Dictionary = state.units[0].duplicate(true); light.id = 2; light.x = 2; light.y = 5; light.nativeAbility = "illuminate"; light.ability = "illuminate"
	state.fields = [{"x":2,"y":4,"kind":"smoke","expires":4,"zone":1,"chance":100}]
	var smoke: Dictionary = engine.cast_plan(state,state.units[1],"ember")
	state.units.append(light)
	plan = engine.cast_plan(state,state.units[1],"ember")
	check(plan.accuracy>smoke.accuracy and plan.criticalMax==smoke.criticalMax,"Illuminate removes only smoke, preserving Sniper")
	state = fixture("run-away","neutralizing-gas")
	var paths: Dictionary = engine.movement_routes(state,state.units[0],2)
	check(not paths.has("4,4"),"Gas prevents Run Away crossing the suppressor")
	state = fixture("","pressure"); state.units[0].status = {"kind":"paralysis","remaining":3}; state.units[0].budget = 2
	engine.begin_activation(state)
	check(state.units[0].remaining==1,"Pressure/paralysis preserve one movement")
	var body_count: int = 0; var charm_count: int = 0; var stench_count: int = 0
	for trial: int in 40:
		state = fixture("","cursed-body"); state.rng = Battle.Rng.hash_seed("reaction-%d"%trial); state.climateActions = 1
		engine._reactions(state,state.units[0],state.units[1],engine.catalog.moves.ember,10,false)
		var triggered: bool = state.units[0].spatial.effects.has("disable")
		body_count += int(triggered)
		var previous_rng: int = state.rng
		engine._reactions(state,state.units[0],state.units[1],engine.catalog.moves.ember,10,false)
		check(state.rng==previous_rng,"Cursed Body one roll per action: %d"%trial)
		if triggered:
			check(not engine.cast_plan(state,state.units[1],"ember").ok and engine.cast_plan(state,state.units[1],"basic").ok,"Cursed Body leaves basic available")
			result = engine.finish(state)
			check(result.state.units[0].spatial.effects.disable.remaining==1,"Disable survives current activation")
		state = fixture("","cute-charm"); state.units[1].gender = "female"; state.rng = Battle.Rng.hash_seed("charm-%d"%trial); state.climateActions = 1
		engine._reactions(state,state.units[0],state.units[1],engine.catalog.moves.scratch,10,false)
		if state.units[0].spatial.effects.has("charm"):
			charm_count += 1
			plan = engine.cast_plan(state,state.units[1],"ember")
			state.units[0].spatial.effects.erase("charm")
			check(plan.damage<engine.cast_plan(state,state.units[1],"ember").damage,"Charm reduces damage only toward source")
		state = fixture("stench"); state.rng = Battle.Rng.hash_seed("stench-%d"%trial); state.climateActions = 1
		engine._reactions(state,state.units[0],state.units[1],engine.catalog.moves.scratch,10,false)
		stench_count += int(state.units[1].x!=3)
	check(body_count>0 and charm_count>0 and stench_count>0,"All three probabilistic reactions exercised")
	var pickup_count: int = 0
	for trial: int in 16:
		var input: Dictionary = rules.create("pickup-%d"%trial,4)
		var collector: Dictionary = rules.progression.create_member(1,52,"Fixture",10)
		rules.progression.assign(collector,input.seed); collector.abilitySlot = 1
		input.party = [collector]; input.phase = "battle"
		input.battle = fixture("pickup","",52); input.battle.units[1].hp = 0
		input.battleInitial = input.battle.duplicate(true)
		var command: Dictionary = {"kind":"battle","order":{"kind":"finish","facing":4},"at":input.revision}
		result = rules.transact(input,command)
		if not result.ok: print("PICKUP_REASON: "+result.reason); check(false,"Pickup victory fixture accepted"); continue
		check(result.state.phase=="capture","Pickup victory fixture accepted")
		if result.state.get("pickupReward","")=="potion": pickup_count += 1; check(result.state.bag.potion==input.bag.potion+1,"Pickup gives exactly one potion")
		check(not rules.transact(result.state,command).ok,"Stale victory cannot repeat loot")
	check(pickup_count>0 and pickup_count<16,"Seeded loot exercises both results")
	state = fixture("run-away")
	var initial: Dictionary = state.duplicate(true)
	for probe: int in 12:
		engine.cast_plan(state,state.units[1],"ember"); engine.movement_routes(state,state.units[0],5); engine.entry_preview(state)
	check(Store.equivalent(state,initial),"Repeated ability/weather/path inspections consume no RNG or state")
