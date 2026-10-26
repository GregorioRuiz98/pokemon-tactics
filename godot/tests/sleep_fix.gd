extends "res://tests/power.gd"

const FixedRun = preload("res://core/sleep_run.gd")
const FixedStore = preload("res://core/sleep_store.gd")

func run_tests() -> void:
	game = FixedRun.new()
	var fresh: Dictionary = game.create("sleep-fix",4)
	sample = game.engine.encounter(fresh,game.locations[0])
	check(fresh.edition==24,"New game uses sleep correction")
	for team: String in ["ally","enemy"]:
		var test_state: Dictionary = arena("ember")
		test_state.units[0].team = team; test_state.units[1].team = "enemy" if team=="ally" else "ally"
		test_state.units[0].status = {"kind":"sleep","remaining":2}
		var before: Dictionary = test_state.duplicate(true)
		for maximum: float in [INF,0.0,4.0]: check(game.engine.movement_routes(test_state,test_state.units[0],maximum).is_empty(),"No routes asleep: "+team)
		var moved: Dictionary = game.engine.move(test_state,{"x":5,"y":9})
		check(not moved.ok and "dormido" in moved.reason,"Direct move rejected: "+team)
		check(not game.engine.cast_plan(test_state,{"x":6,"y":8},"ember").ok,"Sleep still blocks attacks: "+team)
		check(game.engine._approach(test_state,test_state.units[0],test_state.units[1],4).is_empty(),"No approach bypass: "+team)
		check(game.engine.choose_command(test_state).kind=="finish","AI ends sleeping activation: "+team)
		check(FixedStore.equivalent(test_state,before),"Queries/rejection preserve RNG and state: "+team)
		test_state = game.engine.finish(test_state).state
		check(test_state.units[0].status.remaining==1,"Finish counts one activation: "+team)
		test_state.queue = [1,10000]; test_state = game.engine.finish(test_state).state
		check(test_state.units[0].status==null,"Sleep expires normally: "+team)
		test_state.queue = [1,10000]; test_state.moved = false; test_state.acted = false
		check(game.engine.move(test_state,{"x":5,"y":9}).ok,"Movement returns awake: "+team)
	var state: Dictionary = arena("ember")
	state.units[0].status = {"kind":"paralysis","remaining":3}
	check(not game.engine.movement_routes(state,state.units[0]).is_empty(),"Paralysis still permits movement")
	state.units[0].status = {"kind":"sleep","remaining":3}
	state.restorativeTiles = [{"x":5,"y":8}]
	var hp: int = state.units[0].hp
	state = game.engine.finish(state).state
	check(state.units[0].status==null and state.units[0].hp==hp,"Sleeping on manantial can finish and recover without healing")
	state = arena("tackle"); state.units[0].status = {"kind":"sleep","remaining":2}
	state.queue = [10000,1]; state.units[1].moves = ["tackle"]
	var plan: Dictionary = game.engine.cast_plan(state,{"x":5,"y":8},"tackle")
	check(plan.ok,"Sleeping targets remain attackable")
	legacy_and_replay()
	FileAccess.open(directory.path_join("sleep-result.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"  "))
	print(JSON.stringify({"checks":checks,"failures":failures})); quit(0 if failures.is_empty() else 1)

func legacy_and_replay() -> void:
	var legacy: RefCounted = preload("res://core/power_run.gd").new()
	var run: Dictionary = legacy.create("sleep-history",1)
	var commands: Array = []
	for kind: String in ["enter","start-battle"]:
		var command: Dictionary = {"kind":kind,"at":run.revision}
		run = legacy.transact(run,command).state; commands.append(command)
	# Replay real accepted orders before the patch, then checkpoint in combat.
	var order: Dictionary = {"kind":"battle","order":legacy.engine.choose_command(run.battle),"at":run.revision}
	run = legacy.transact(run,order).state; commands.append(order)
	var before: Dictionary = run.duplicate(true)
	var transition: Dictionary = {"kind":"upgrade","edition":24,"at":run.revision}
	var migrated: Dictionary = game.transact(run,transition)
	check(migrated.ok and migrated.state.phase=="battle","Upgrade allowed during combat")
	var next: Dictionary = migrated.state
	check(next.battle.rng==before.battle.rng and next.battle.queue==before.battle.queue and next.battle.units==before.battle.units,"Upgrade preserves RNG, units and initiative")
	check(next.battle.board==before.battle.board and next.battle.restorativeTiles==before.battle.restorativeTiles and next.party==before.party,"Upgrade preserves map, springs and party")
	check(next.battleCommands.is_empty() and next.battleInitial==next.battle,"Movement undo starts at correction checkpoint")
	check(run==before,"Upgrade never mutates input")
	commands.append(transition)
	var saved: RefCounted = FixedStore.new(directory.path_join("sleep-mixed.json"))
	check(saved.save(next,commands,"current").ok,"Save mixed23→24 combat")
	var loaded: Dictionary = saved.load_campaign(game)
	check(loaded.ok and FixedStore.equivalent(next,loaded.state),"Mixed history reconstructs exactly")
	var old_state: Dictionary = sample.duplicate(true)
	old_state.units[0].status = {"kind":"sleep","remaining":3}
	check(not legacy.engine.movement_routes(old_state,old_state.units[0]).is_empty(),"Published historical movement kept for old diary replay")
	check(preload("res://core/sleep_challenge.gd").decode(preload("res://core/sleep_challenge.gd").encode(fresh_run())).edition==24,"Challenge carries correction")

func fresh_run() -> Dictionary:
	return game.create("sleep-code",4)
