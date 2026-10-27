extends SceneTree

const Game = preload("res://core/tactics_quality_run.gd")
const Ledger = preload("res://core/tactics_quality_store.gd")
const Layouts = preload("res://core/tactics_opening.gd")
var checks: int = 0
var failures: Array = []
var directory: String = ""

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition: failures.append(label); print("QUALITY_FAILED: "+label)

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="): directory = argument.trim_prefix("--save-dir=")
	call_deferred("run_checks")

func run_checks() -> void:
	var game: RefCounted = Game.new()
	var old: RefCounted = preload("res://core/review_run.gd").new()
	check(game.engine.catalog.moves==old.engine.catalog.moves,"Move balance unchanged")
	check(game.progression.data.species==old.progression.data.species,"Species numerical balance unchanged")
	var initial: Dictionary = game.create("quality-kanto",1)
	check(initial.edition==27,"Current edition27")
	var levels: Array = [16,24]
	for width: int in levels:
		for index: int in game.locations.size():
			var scenario: Dictionary = initial.duplicate(true); scenario.mapSize = width; scenario.stage = index
			var battle: Dictionary = game.engine.encounter(scenario,game.locations[index])
			var legacy: Dictionary = old.engine.encounter(scenario,game.locations[index])
			var identity: String = game.locations[index].id+"/"+str(width)
			check(battle.tacticalDesign==game.locations[index].id and battle.briefing.line!="","Authored context: "+identity)
			check(battle.units.size()==legacy.units.size(),"Enemy count unchanged: "+identity)
			var reach: Dictionary = Layouts.reachable(battle,battle.units[0])
			for position: int in battle.units.size():
				var unit: Dictionary = battle.units[position]
				check(reach.has(game.engine.Movement.key(unit)),"Ground connection to deployed unit: "+identity+"/"+str(unit.id))
				for field: String in ["hp","maxHp","attack","defense","specialAttack","specialDefense","speed","moves","ability"]:
					check(unit[field]==legacy.units[position][field],"Numerical unit preserved: "+identity+"/"+field)
			for point: Dictionary in battle.mission.get("points",[])+battle.restorativeTiles:
				check(reach.has(game.engine.Movement.key(point)),"Objective/spring reachable: "+identity)
			var before: Dictionary = battle.duplicate(true)
			game.engine.movement_routes(battle,battle.units[0],4)
			check(Ledger.equivalent(before,battle),"Movement query pure: "+identity)
			if index%8==0: await process_frame
	var original: Dictionary = old.create("quality-upgrade",4)
	var transition: Dictionary = {"kind":"upgrade","edition":27,"at":original.revision}
	var upgraded: Dictionary = game.transact(original,transition)
	check(upgraded.ok and upgraded.state.party==original.party and upgraded.state.rng==original.rng,"Upgrade preserves party and RNG")
	var store: RefCounted = Ledger.new(directory.path_join("quality-save-%d.json"%Time.get_ticks_usec()))
	var state: Dictionary = game.create("quality-save",7)
	var commands: Array = []
	check(store.save(state,commands,"current").ok,"Initial save validates and signs")
	var loaded: Dictionary = Ledger.new(store.file_path).load_campaign(game)
	check(loaded.ok and loaded.state==state,"Certified load preserves exact binary numeric state")
	var order: Dictionary = {"kind":"enter","at":state.revision}
	var entered: Dictionary = game.transact(state,order)
	check(entered.ok,"Natural encounter entry")
	commands.append(order); state = entered.state
	check(store.save(state,commands,"current").ok,"Incremental journal validation saves")
	var receiver: RefCounted = Ledger.new(store.file_path)
	loaded = receiver.load_campaign(game)
	check(loaded.ok and receiver.last_load.cached and loaded.state==state,"New process can recover signed canonical state")
	var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(store.file_path))
	var payload: Dictionary = JSON.parse_string(envelope.payload); payload.state.money += 1
	envelope.payload = JSON.stringify(payload,"",true,true); envelope.checksum = envelope.payload.sha256_text()
	FileAccess.open(store.file_path,FileAccess.WRITE).store_string(JSON.stringify(envelope))
	check(not Ledger.new(store.file_path).load_campaign(game).ok,"Valid JSON checksum cannot bypass journal validation with stale receipt")
	var code: String = preload("res://core/tactics_quality_challenge.gd").encode(initial)
	check(preload("res://core/tactics_quality_challenge.gd").decode(code).edition==27,"KT34 round trip")
	var arena: Dictionary = game.engine.encounter(initial,game.locations[3])
	check(arena.tacticalMemory.recoveryStall=={"ally":0,"enemy":0},"Encounter setup never counts as stalled combat rounds")
	var foe: Dictionary = arena.units.filter(func(u):return u.team=="enemy")[0]
	var victim: Dictionary = arena.units[0]
	foe.x = victim.x+1; foe.y = victim.y; foe.remaining = 0
	arena.queue = [foe.id]; arena.moved = false; arena.acted = false
	var plan: Dictionary = game.engine.cast_plan(arena,victim,"basic")
	var healthy_score: float = game.engine.action_score(arena,victim,plan)
	victim.hp = maxi(1,int(victim.maxHp/2))
	check(game.engine.action_score(arena,victim,game.engine.cast_plan(arena,victim,"basic"))>healthy_score,"Trainer focuses a weakened opponent")
	var frozen: Dictionary = arena.duplicate(true)
	game.engine.choose_command(arena)
	check(Ledger.equivalent(frozen,arena),"Coordinated planner is a pure query")
	var nurse: Dictionary = game.engine.progression.create_member(19000,113,"Fixture",75)
	nurse.moves = ["soft-boiled"]
	var healer: Dictionary = game.engine.member_unit(nurse,{"x":int(foe.x),"y":int(foe.y)})
	healer.team = "enemy"; healer.aiRole = "trainer"; healer.hp = maxi(1,int(healer.maxHp/4))
	arena.units = [victim,healer]; arena.queue = [healer.id]
	plan = game.engine.cast_plan(arena,healer,"soft-boiled")
	check(plan.ok and game.engine.action_score(arena,healer,plan)>0,"Useful healing considered normally")
	arena.tacticalMemory = {"stalled":3}
	check(game.engine.action_score(arena,healer,plan)==0,"Stalled trainer seeks another plan instead of repeating recovery")
	check(game.engine.cast_plan(arena,healer,"soft-boiled").ok,"Anti-stall decision never forbids a player's recovery move")
	arena.tacticalMemory = {}; healer.hp = 100
	game.engine.new_round(arena)
	for index: int in 4:
		healer.hp = 150+index%2; healer.x = 6+index%2
		game.engine.new_round(arena)
	check(game.engine.recovery_stalled(arena,healer),"Recovery/movement cycle without a lower team HP is recognized")
	victim.hp = maxi(1,int(victim.hp)-1)
	game.engine.new_round(arena)
	check(game.engine.recovery_stalled(arena,healer),"Damage to the other side does not hide a recovery cycle")
	healer.hp = 50; game.engine.new_round(arena)
	check(not game.engine.recovery_stalled(arena,healer),"New own-team health loss restores a useful healing decision")
	var replay_state: Dictionary = game.create("quality-coordinate-replay",7)
	var replay_commands: Array = [{"kind":"enter","at":0},{"kind":"deploy","member":1,"destination":{"x":2,"y":10},"at":1},{"kind":"start-battle","at":2}]
	for replay_command: Dictionary in replay_commands:
		var step: Dictionary = game.transact(replay_state,replay_command)
		check(step.ok,"Legal deployment replay fixture")
		replay_state = step.state
	while replay_state.battle.round<2:
		var replay_command: Dictionary = {"kind":"battle","order":{"kind":"finish","facing":0},"at":replay_state.revision}
		var step: Dictionary = game.transact(replay_state,replay_command)
		if not step.ok: check(false,"Replay round advances"); break
		replay_commands.append(replay_command); replay_state = step.state
	var replay_store: RefCounted = Ledger.new(directory.path_join("quality-coordinate-%d.json"%Time.get_ticks_usec()))
	check(replay_store.save(replay_state,replay_commands,"current").ok,"Uncertified deployment journal saves")
	var replayed: Dictionary = Ledger.new(replay_store.file_path).load_campaign(game)
	check(replayed.ok and Ledger.equivalent(replayed.get("state",{}),replay_state),"Integer/JSON decimal coordinates reconstruct identical AI memory")
	for identity: String in ["mt-moon","rocket-hideout","silph-giovanni","pokemon-mansion","power-plant"]:
		var location: Dictionary = game.locations.filter(func(l):return l.id==identity)[0]
		var control: Dictionary = game.engine.encounter(initial,location)
		check(control.mission.kind=="secure","Control objective installed: "+identity)
		control.deployment = false
		var ally: Dictionary = control.units[0]
		var points: Array = control.mission.points.duplicate(true)
		for point: Dictionary in points:
			ally = game.engine.unit_by_id(control,int(ally.id)); ally.x = point.x; ally.y = point.y
			control.queue = [ally.id]; control.moved = false; control.acted = false
			var step: Dictionary = game.engine.apply_command(control,{"kind":"finish","facing":0})
			check(step.ok,"End turn secures mechanism: "+identity)
			if not step.ok: break
			control = step.state
		check(control.outcome=="victory" and control.units.any(func(u):return u.team=="enemy" and u.hp>0),"Control wins without clearing opponents: "+identity)
	FileAccess.open(directory.path_join("quality-result.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"  "))
	print("QA quality core "+JSON.stringify({"checks":checks,"failures":failures})); quit(0 if failures.is_empty() else 1)
