extends SceneTree

const Run = preload("res://core/scale_run.gd")
const Terrain = preload("res://core/terrain_movement.gd")
const Flat = preload("res://core/movement.gd")
const Save = preload("res://core/kanto_store.gd")
const Revision = preload("res://core/movement_revision.gd")
const Iso = preload("res://ui/isometric_board.gd")
var checks: int = 0
var failures: Array[String] = []

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var game: RefCounted = Run.new()
	var campaign: Dictionary = game.create("scale-15",1)
	check(campaign.edition==11 and campaign.mapSize==16,"New rules and default scale")
	check(not game.transact(campaign,{"kind":"map-size","size":17,"at":0}).ok,"Invalid scale rejected")
	var enlarged: Dictionary = game.transact(campaign,{"kind":"map-size","size":24,"at":0})
	check(enlarged.ok and enlarged.state.mapSize==24 and campaign.mapSize==16,"Choice is immutable transaction")
	var battle: Dictionary = game.engine.encounter(campaign,game.locations[0])
	var actor: Dictionary = game.engine.active(battle)
	actor.profile = "ground"
	actor.x = 5
	actor.y = 10
	actor.remaining = 8
	battle.heights[10][5] = 0
	battle.heights[10][6] = 1
	battle.heights[10][7] = 3
	check(Terrain.step_cost(battle,actor,actor,{"x":6,"y":10})==2,"Uphill adds one")
	check(is_inf(Terrain.step_cost(battle,actor,{"x":6,"y":10},{"x":7,"y":10})),"Cannot cross two height levels")
	actor.profile = "fly"
	check(Terrain.step_cost(battle,actor,{"x":6,"y":10},{"x":7,"y":10})==1,"Flying crosses cliffs")
	actor.profile = "ground"
	var state_before: String = JSON.stringify(battle)
	var routes: Dictionary = game.engine.movement_routes(battle,actor,actor.remaining)
	check(JSON.stringify(battle)==state_before,"Path preview is pure")
	for route: Dictionary in routes.values():
		var cost: float = 0
		for i: int in range(1,route.path.size()): cost += Terrain.step_cost(battle,actor,route.path[i-1],route.path[i])
		check(cost==route.cost and cost<=actor.remaining,"Returned paths and costs are legal")
	var move: Dictionary = game.engine.move(battle,{"x":6,"y":10})
	check(move.ok and game.engine.active(move.state).remaining==6,"Move charges elevation")
	if move.ok:
		var undone: Dictionary = Revision.rectify(move.state,[{"kind":"move","destination":{"x":6,"y":10}}],"current",game.engine,battle)
		check(undone.ok and Save.equivalent(undone.state,battle),"Rectify restores only movement on elevations")
	var friend: Dictionary = actor.duplicate(true)
	friend.id = 42
	friend.x = 6
	friend.y = 10
	battle.units.append(friend)
	routes = game.engine.movement_routes(battle,actor,8)
	check(not routes.has("6,10") and routes.has("6,11"),"Occupied ally cannot be destination")
	# Corridor forces the path through the allied cell.
	for row: Array in battle.board: row.fill(2)
	for x: int in [5,6,7]:
		battle.board[10][x] = 0
		battle.heights[10][x] = 0
	routes = game.engine.movement_routes(battle,actor,8)
	check(routes.has("7,10") and routes["7,10"].path.size()==3,"Allies can be crossed")
	friend.team = "enemy"
	check(not game.engine.movement_routes(battle,actor,8).has("7,10"),"Enemies block paths")
	# Height/LOS/approach/push share the same planner used by the resolver and AI.
	var arena: Dictionary = game.engine.encounter(game.create("height-fixture",1),game.locations[0])
	var fighter: Dictionary = arena.units[0]
	var victim: Dictionary = arena.units[1]
	arena.queue = [fighter.id,victim.id]
	arena.moved = false
	arena.acted = false
	for row: Array in arena.board: row.fill(0)
	for row: Array in arena.heights: row.fill(0)
	fighter.x = 5
	fighter.y = 8
	fighter.tp = 5
	fighter.remaining = 8
	fighter.moves = ["vine-whip","headbutt","quick-attack"]
	victim.x = 6
	victim.y = 8
	arena.heights[8][6] = 2
	check(not game.engine.attack_plan(arena,int(victim.id),{},"basic").ok,"Melee cannot hit across a two-level cliff")
	arena.heights[8][6] = 1
	check(game.engine.attack_plan(arena,int(victim.id),{},"basic").ok,"Melee can hit across one height level")
	victim.x = 7
	arena.heights[8][6] = 0
	arena.heights[8][7] = 0
	check(Terrain.clear_line(arena,fighter,victim),"Open line of sight")
	arena.heights[8][6] = 2
	check(not Terrain.clear_line(arena,fighter,victim),"High terrain blocks line of sight")
	arena.heights[8][6] = 0
	arena.board[8][6] = 2
	check(not Terrain.clear_line(arena,fighter,victim),"Rock blocks line of sight")
	arena.board[8][6] = 0
	var approach: Dictionary = game.engine.attack_plan(arena,int(victim.id),{},"quick-attack")
	check(approach.ok and not approach.approach.is_empty(),"Approach finds a height-aware path")
	if approach.ok:
		var hit: Dictionary = game.engine.attack(arena,int(victim.id),"quick-attack")
		check(hit.ok and game.engine.unit_by_id(hit.state,int(fighter.id)).remaining==fighter.remaining-approach.approach.cost,"Approach resolver pays forecast movement")
	victim.x = 6
	arena.heights[8][7] = 2
	var push: Dictionary = game.engine.attack_plan(arena,int(victim.id),{},"headbutt")
	check(push.ok and push.push==null and push.pushReason!=null,"Push cannot cross a two-level cliff")
	arena.heights[8][7] = 0
	push = game.engine.attack_plan(arena,int(victim.id),{},"headbutt")
	check(push.ok and push.push=={"x":7,"y":8},"Push can use a legal destination")
	var trials: Array = []
	var encounters: Array = []
	for width: int in [16,24]:
		for location: Dictionary in game.locations:
			campaign.mapSize = width
			campaign.stage = game.locations.find(location)
			campaign.party = []
			for i: int in 6: campaign.party.append(game.progression.create_member(i+1,1,"Deployment fixture",5))
			var encounter: Dictionary = game.engine.encounter(campaign,location)
			check(encounter.board.size()==width and encounter.heights.size()==width,"Map size and heights")
			for unit: Dictionary in encounter.units:
				check(not is_inf(Flat.tile_cost(encounter.board,unit,unit.profile)),"Legal deployment: "+location.id)
				check(encounter.units.filter(func(other):return other.hp>0 and Flat.same(unit,other)).size()==1,"Unique deployment square")
			var view: Control = Iso.new()
			view.size = Vector2(1280,900)
			view.state = encounter
			view.fit_map()
			for unit: Dictionary in encounter.units:
				check(view.pick(view.center(unit))=={"x":unit.x,"y":unit.y},"Isometric top-face picking: "+location.id)
			var snapshot: Dictionary = encounter.duplicate(true)
			view.change_zoom(1.3)
			view.pan(Vector2(80,-30))
			view.focus_active()
			check(Save.equivalent(encounter,snapshot),"Camera never mutates combat/RNG")
			check(view.pick(Vector2.ZERO).is_empty(),"HUD margin is not selectable")
			view.free()
			encounters.append(benchmark(game,width,game.locations.find(location)))
			if location.id=="forest":
				var guard: Dictionary = encounter.units[-1]
				check(guard.dormant and guard.id not in encounter.queue,"Guard excluded from initial queue")
				game.engine.new_round(encounter)
				game.engine.new_round(encounter)
				check(not guard.dormant and guard.id in encounter.queue,"Guard joins by round three; no indefinite waiting")
		trials.append(journey(game,width))
	# Published editions continue reconstructing their original journals.
	for edition: int in range(1,12):
		var path: String = ["kanto_run","progression_run","shop_run","growth_run","letsgo_run","tactics_run","vitality_run","gym_run","revive_run","traits_run","scale_run"][edition-1]
		var legacy: RefCounted = load("res://core/"+path+".gd").new()
		var state: Dictionary = legacy.create("scale-compat",1)
		var command: Dictionary = {"kind":"enter","at":state.revision}
		var entered: Dictionary = legacy.transact(state,command)
		var directory: String = output_dir()
		var store: RefCounted = Save.new(directory.path_join("compat-%d.json" % edition))
		check(store.save(entered.state,[command],"scale").ok,"Save edition %d" % edition)
		var loaded: Dictionary = store.load_campaign(legacy)
		check(loaded.ok and Save.equivalent(loaded.state,entered.state),"Replay edition %d" % edition)
	var report: Dictionary = {"checks":checks,"failures":failures,"trials":trials,"encounterFixtures":encounters}
	FileAccess.open(output_dir().path_join("scale-result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)

func output_dir() -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--save-dir="): return arg.trim_prefix("--save-dir=")
	return OS.get_user_data_dir()

func journey(game: RefCounted, width: int) -> Dictionary:
	var campaign: Dictionary = game.create("tactics-1",1)
	var commands: Array = []
	if width==24:
		var select: Dictionary = {"kind":"map-size","size":24,"at":0}
		campaign = game.transact(campaign,select).state
		commands.append(select)
	var metrics: Dictionary = {"size":width,"moves":0,"attacks":0,"emptyActivations":0,"firstContactRound":0,"orders":0}
	for i: int in 1000:
		if campaign.phase in ["complete","defeat"]: break
		var order: Dictionary = {"at":campaign.revision}
		match campaign.phase:
			"map": order.kind = "enter"
			"capture": order.kind = "capture"
			"shop":
				order.kind = "continue"
				for member: Dictionary in campaign.party:
					if member.hp>0 and member.hp<game.progression.member_stats(member).maxHp-10:
						if campaign.bag.potion>0: order.merge({"kind":"heal","item":"potion","member":member.id},true)
						elif campaign.money>=40: order.merge({"kind":"buy","item":"potion"},true)
						break
			"battle":
				var before: Dictionary = campaign.battle.duplicate(true)
				var tactical: Dictionary = game.engine.choose_command(campaign.battle)
				check(Save.equivalent(before,campaign.battle),"AI decision is pure")
				order.merge({"kind":"battle","order":tactical},true)
				metrics.orders += 1
				if tactical.kind=="move": metrics.moves += 1
				if tactical.kind=="attack":
					metrics.attacks += 1
					if metrics.firstContactRound==0: metrics.firstContactRound = campaign.battle.round
				if tactical.kind=="finish" and not before.acted: metrics.emptyActivations += 1
		var step: Dictionary = game.transact(campaign,order)
		check(step.ok,"Accepted journey order: "+str(step.get("reason","")))
		if not step.ok: break
		campaign = step.state
		commands.append(order)
	check(campaign.phase in ["complete","defeat"],"Journey terminates; no defensive loop")
	check(metrics.firstContactRound>0 and metrics.firstContactRound<=3,"Contact by round three at both sizes")
	var store: RefCounted = Save.new(output_dir().path_join("journey-%d.json" % width))
	check(store.save(campaign,commands,"scale").ok,"Save full scale journey")
	var replay: Dictionary = store.load_campaign(game)
	check(replay.ok and Save.equivalent(replay.state,campaign),"Full journey replays exactly")
	metrics.phase = campaign.phase
	metrics.cleared = campaign.cleared.size()
	return metrics

func benchmark(game: RefCounted, width: int, stage: int) -> Dictionary:
	# Fixed level12 squads evaluate pathfinding/termination, never campaign win rates.
	var campaign: Dictionary = game.create("scale-fixture",1)
	campaign.stage = stage
	campaign.mapSize = width
	campaign.party = []
	for species: int in [1,4,7]: campaign.party.append(game.progression.create_member(campaign.party.size()+1,species,"QA fixture",12))
	var state: Dictionary = game.engine.encounter(campaign,game.locations[stage])
	var orders: int = 0
	var empty: int = 0
	for i: int in 700:
		if state.outcome!="playing": break
		var command: Dictionary = game.engine.choose_command(state)
		if command.kind=="finish" and not state.acted: empty += 1
		var step: Dictionary = game.engine.apply_command(state,command)
		check(step.ok,"Legal benchmark order: "+str(step.get("reason","")))
		if not step.ok: break
		state = step.state
		orders += 1
	check(state.outcome!="playing","Every biome terminates at both scales")
	return {"size":width,"biome":game.locations[stage].id,"outcome":state.outcome,"orders":orders,"rounds":state.round,"emptyActivations":empty}
