extends "res://tests/climate.gd"

func _initialize() -> void:
	engine = preload("res://core/review_battle.gd").new()
	super._initialize()

func more_checks(rules: RefCounted) -> void:
	super.more_checks(rules)
	var state: Dictionary = fixture()
	state.units[0].moves = ["growth"]
	engine._change(state.units[0],{"stat":"attack","stages":2})
	engine._change(state.units[0],{"stat":"specialAttack","stages":2})
	var plan: Dictionary = engine.cast_plan(state,state.units[0],"growth")
	check(not plan.ok and engine.action_score(state,state.units[0],plan)==0,"Capped boosts remain rejected by the existing rules")
	engine._change(state.units[0],{"stat":"specialAttack","stages":-1})
	plan = engine.cast_plan(state,state.units[0],"growth")
	check(plan.ok and engine.action_score(state,state.units[0],plan)==4,"Partially capped boosts only score the actual available stage")
	state.units[0].stages = {}
	plan = engine.cast_plan(state,state.units[0],"growth")
	check(engine.action_score(state,state.units[0],plan)>0,"Useful boosts remain available to AI")
	state = fixture(); state.units[0].moves = ["recover"]; state.units[0].hp = 1800
	var counters: Dictionary = state.units[0].recoveryPP.duplicate(true)
	for index: int in 8:
		state.units[0].hp = 1000
		var healed: Dictionary = engine.cast(state,state.units[0],"recover")
		check(healed.ok,"Recovery stays unlimited: "+str(index))
		if not healed.ok: break
		state = healed.state; state.acted = false
	check(state.units[0].recoveryPP==counters and state.units[0].hp==state.units[0].maxHp,"Heals never exceed max HP or spend old counters")
	var current: RefCounted = preload("res://core/review_run.gd").new()
	var old: RefCounted = preload("res://core/climate_run.gd").new()
	var previous: Dictionary = old.create("review-migration",1)
	var transition: Dictionary = {"kind":"upgrade","edition":26,"at":0}
	var upgraded: Dictionary = current.transact(previous,transition)
	check(upgraded.ok and upgraded.state.party==previous.party and upgraded.state.rng==previous.rng,"Revision upgrade preserves party and RNG")
	var ledger: RefCounted = preload("res://core/review_store.gd").new(directory.path_join("review-mixed-save-%d.json"%Time.get_ticks_usec()))
	check(ledger.save(upgraded.state,[transition],"current").ok,"Review mixed journal saves")
	var loaded: Dictionary = ledger.load_campaign(current)
	check(loaded.ok and Store.equivalent(loaded.get("state",{}),upgraded.state),"Review mixed journal reloads")
	var challenge: String = preload("res://core/review_challenge.gd").encode(current.create("review-code",7))
	check(preload("res://core/review_challenge.gd").decode(challenge).edition==26,"KT33 round trip")
	check(current.engine.catalog.moves==old.engine.catalog.moves,"No change to move power, cost, precision or effects")
	check(current.progression.data.species==old.progression.data.species,"No change to Pokemon numerical balance")
