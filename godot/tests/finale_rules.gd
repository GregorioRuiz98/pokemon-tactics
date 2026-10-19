extends SceneTree

const Journey = preload("res://core/journey_run.gd")
const Store = preload("res://core/journey_store.gd")
var checks: int = 0
var failures: Array[String] = []

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var game: RefCounted = Journey.new(21)
	var original: Dictionary = game.create("finale",1)
	check(not game.transact(original,{"kind":"destiny","path":"birds","at":0}).ok,"Final locked before champion")
	var fixture: Dictionary = original.duplicate(true)
	fixture.mainComplete = true
	fixture.phase = "complete"
	fixture.flags = ["champion"]
	fixture.cleared = game.locations.filter(func(n):return not n.get("finale",false)).map(func(n):return n.id)
	var boards: Array = []
	for path: String in ["birds","psychic"]:
		var choice: Dictionary = game.transact(fixture,{"kind":"destiny","path":path,"at":0})
		check(choice.ok and choice.state.phase=="shop" and choice.state.finalPath==path,"Choice allows paid preparation "+path)
		check(choice.ok and choice.state.money==fixture.money and choice.state.party[0].hp==fixture.party[0].hp,"Choice grants no money or heal")
		if not choice.ok: continue
		check(not game.transact(choice.state,{"kind":"destiny","path":"psychic" if path=="birds" else "birds","at":choice.state.revision}).ok,"Final choice cannot change")
		var continued: Dictionary = game.transact(choice.state,{"kind":"continue","at":choice.state.revision})
		check(continued.ok and continued.state.phase=="map","Shop leads to selected final")
		if not continued.ok: continue
		check(not game.transact(continued.state,{"kind":"travel","location":"legendary-origin" if path=="birds" else "legendary-birds","at":continued.state.revision}).ok,"Other final cannot be reached")
		var entered: Dictionary = game.transact(continued.state,{"kind":"enter","at":continued.state.revision})
		check(entered.ok and entered.state.phase=="battle","Selected arena enters")
		if not entered.ok: continue
		var state: Dictionary = entered.state.battle
		boards.append(JSON.stringify([state.board,state.heights]))
		var enemies: Array = state.units.filter(func(u):return u.team=="enemy")
		check(enemies.size()==(3 if path=="birds" else 2),"Boss composition")
		for enemy: Dictionary in enemies:
			var known: Array = game.progression.create_member(int(enemy.id),int(enemy.speciesId),"QA",int(enemy.level)).knownMoves
			check(enemy.moves.size()==4 and enemy.moves.all(func(m):return m in known),"Four legal level moves "+str(enemy.speciesId))
		var actor: Dictionary = state.units[0]
		var target: Dictionary = enemies[0]
		actor.x = 5; actor.y = 8; actor.tp = 0
		target.x = 6; target.y = 8; target.ability = "pressure"
		state.units = [actor,target]
		state.queue = [actor.id,target.id]
		state.acted = false; state.moved = false
		for row: Array in state.board: row.fill(0)
		for row: Array in state.heights: row.fill(0)
		var before: Dictionary = state.duplicate(true)
		var preview: Dictionary = game.engine.attack_plan(state,int(target.id),{},"basic")
		check(preview.ok and preview.cost==0,"Neutral basic works at zero PT under Pressure")
		check(Store.equivalent(before,state),"Final preview preserves state/RNG")
		var result: Dictionary = game.engine.attack(state,int(target.id),"basic")
		check(result.ok and result.state.units[0].tp==0,"Resolved basic remains free")
		actor.tp = 5; actor.moves = ["vine-whip"]
		preview = game.engine.attack_plan(state,int(target.id),{},"vine-whip")
		check(preview.ok and preview.cost==int(game.progression.data.moves["vine-whip"].cost)+1,"Prepared move still pays Pressure")
		actor.moves = ["recover"]
		for remaining: int in range(4,-1,-1):
			state.acted = false
			actor.tp = 5
			actor.hp = actor.maxHp-10
			result = game.engine.attack(state,int(actor.id),"recover")
			check(result.ok and result.state.units[0].recoveryPP.recover==remaining,"Recovery consumes one use on resolution")
			if not result.ok: break
			state = result.state
			actor = state.units[0]
		state.acted = false; actor.tp = 5; actor.hp -= 10
		before = state.duplicate(true)
		check(not game.engine.attack_plan(state,int(actor.id),{},"recover").ok,"Sixth recovery rejected even with PT")
		check(Store.equivalent(state,before),"Exhausted preview preserves state and RNG")
		game.engine.new_round(state)
		check(actor.recoveryPP.recover==0,"A new round does not refill recovery uses")
	check(boards.size()==2 and boards[0]!=boards[1],"Distinct themed arena geometry")
	var report: Dictionary = {"checks":checks,"failures":failures}
	var directory: String = OS.get_user_data_dir()
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="): directory = argument.trim_prefix("--save-dir=")
	FileAccess.open(directory.path_join("finale-core-result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
