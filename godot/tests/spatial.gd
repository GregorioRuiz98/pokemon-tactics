extends SceneTree

const Run = preload("res://core/spatial_run.gd")
const Save = preload("res://core/spatial_store.gd")
var game: RefCounted
var checks: int = 0
var failures: Array[String] = []
var resolved: Array[String] = []
var conditional: Array[String] = []

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label); push_warning(label)

func _initialize() -> void:
	call_deferred("run_tests")

func arena(identity: String) -> Dictionary:
	var state: Dictionary = game.engine.encounter(game.create("spatial",1),game.locations[0])
	var actor: Dictionary = game.engine.member_unit(game.progression.create_member(1,1,"Fixture",30),{"x":5,"y":8})
	var target: Dictionary = game.engine.member_unit(game.progression.create_member(10000,134,"Fixture",30),{"x":6,"y":8})
	actor.moves = [identity]
	actor.tp = 5
	actor.ability = "none"
	target.ability = "none"
	target.team = "enemy"
	target.facing = 2
	state.units = [actor,target]
	state.queue = [1,10000]
	state.completed = []
	state.moved = false
	state.acted = false
	for row: Array in state.board: row.fill(0)
	for row: Array in state.heights: row.fill(0)
	return state

func run_tests() -> void:
	game = Run.new()
	check(game.create("new",4).edition==19,"New campaign edition19")
	check(game.engine.catalog.moves.size()==211 and game.progression.spatial_data.moves.size()==212,"All current moves plus basic covered")
	for identity: String in game.engine.catalog.moves:
		var state: Dictionary = arena(identity)
		var before: Dictionary = state.duplicate(true)
		var found: bool = false
		for point: Dictionary in game.engine.aim_points(state,identity):
			var plan: Dictionary = game.engine.cast_plan(state,point,identity)
			if plan.ok:
				var result: Dictionary = game.engine.cast(state,point,identity)
				check(result.ok,identity+" resolves: "+str(result.get("reason","")))
				resolved.append(identity)
				found = true
				break
		if not found: conditional.append(identity)
		check(Save.equivalent(state,before),identity+" preview/resolve preserve source")
	geometry_tests()
	zone_tests()
	movement_tests()
	special_tests()
	conditional_tests()
	replay_tests()
	var report: Dictionary = {"checks":checks,"failures":failures,"resolved":resolved,"conditional":conditional}
	var directory: String = ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="): directory = argument.trim_prefix("--save-dir=")
	if directory!="":
		DirAccess.make_dir_recursive_absolute(directory)
		var file: FileAccess = FileAccess.open(directory.path_join("spatial-result.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify(report,"\t")); file.close()
	print(JSON.stringify({"checks":checks,"failures":failures,"resolved":resolved.size(),"conditional":conditional}))
	quit(0 if failures.is_empty() else 1)

func field(state: Dictionary, kind: String, x: int, y: int, expires: int = 4) -> void:
	state.fields.append({"kind":kind,"x":x,"y":y,"expires":expires,"source":1,"chance":100,"zone":1})

func geometry_tests() -> void:
	var templates: Dictionary = {"flamethrower":3,"hyper-beam":4,"surf":6,"earthquake":12,"explosion":12,"self-destruct":8,"spore":4,"psychic":5,"x-scissor":5,"fire-blast":7,"razor-leaf":4,"reflect":3}
	for identity: String in templates:
		var shape_state: Dictionary = arena(identity)
		shape_state.units[1].x = 10
		var shape_plan: Dictionary = game.engine.cast_plan(shape_state,{"x":6,"y":8},identity)
		check(shape_plan.ok and shape_plan.tiles.size()==templates[identity],"Exact open-board shape "+identity+": "+str(shape_plan.get("reason",shape_plan.get("tiles",[]))))
	var state: Dictionary = arena("hyper-beam")
	state.units[1].x = 7
	var enemy: Dictionary = state.units[1].duplicate(true)
	enemy.id = 10001; enemy.x = 9; state.units.append(enemy)
	var ally: Dictionary = state.units[0].duplicate(true)
	ally.id = 2; ally.x = 8; state.units.append(ally)
	var plan: Dictionary = game.engine.cast_plan(state,{"x":9,"y":8},"hyper-beam")
	check(plan.ok and plan.hits.size()==3,"Piercing beam includes units and friendly fire")
	state.board[8][8] = 2
	plan = game.engine.cast_plan(state,{"x":7,"y":8},"hyper-beam")
	check(plan.ok and plan.tiles.size()==2 and plan.hits.size()==1,"Solid wall truncates beam and protects units behind")
	state = arena("fissure"); state.heights[8][7] = 3
	plan = game.engine.cast_plan(state,{"x":6,"y":8},"fissure")
	check(plan.ok and not plan.tiles.any(func(p):return p.x==7),"Ground wave cannot hit a cliff top")
	state = arena("smokescreen")
	plan = game.engine.cast_plan(state,{"x":8,"y":8},"smokescreen")
	check(plan.ok and plan.hits.is_empty(),"Empty ground accepts zone target")
	check(not game.engine.cast_plan(state,{"x":8.2,"y":8},"smokescreen").ok,"Fractional aim rejected")
	check(not game.engine.apply_command(state,{"kind":"attack","aim":"bad","actionId":"smokescreen"}).ok,"Malformed aim rejected")

func zone_tests() -> void:
	var state: Dictionary = arena("water-gun"); state.units[1].x = 7
	var plain: Dictionary = game.engine.attack_plan(state,10000,{},"water-gun")
	field(state,"smoke",6,8); field(state,"smoke",7,8)
	var plan: Dictionary = game.engine.attack_plan(state,10000,{},"water-gun")
	check(plan.ok and plan.accuracy==int(plain.accuracy*.75),"Crossing two smoke tiles applies one penalty")
	state.units[0].ability = "keen-eye"
	check(game.engine.attack_plan(state,10000,{},"water-gun").accuracy==plain.accuracy,"Keen Eye ignores smoke")
	state.units[0].ability = "no-guard"
	check(game.engine.attack_plan(state,10000,{},"water-gun").accuracy==100,"No Guard bypasses smoke")
	state = arena("swift"); field(state,"smoke",5,8)
	check(game.engine.attack_plan(state,10000,{},"swift").accuracy==100,"Never-miss remains never-miss in smoke")
	state = arena("hyper-beam"); field(state,"light-screen",6,8)
	plan = game.engine.attack_plan(state,10000,{},"hyper-beam")
	state.fields = []
	plain = game.engine.attack_plan(state,10000,{},"hyper-beam")
	check(plan.damageMax==maxi(1,int(plain.damageMax*.75)),"Special screen reduces crossed damage once")
	state = arena("growl"); field(state,"mist",6,8)
	plan = game.engine.attack_plan(state,10000,{},"growl")
	check(plan.ok and plan.hits[0].get("changes",[]).is_empty(),"Mist blocks hostile stat reductions")
	state = arena("smokescreen")
	var result: Dictionary = game.engine.cast(state,{"x":8,"y":8},"smokescreen")
	check(result.ok and result.state.fields.size()==5,"Zone creates five explicit fields")
	state = result.state
	var expiry: int = state.round+3
	check(state.fields[0].expires==expiry,"Zone expires after two full subsequent rounds")
	game.engine.new_round(state); game.engine.new_round(state)
	check(state.fields.size()==5,"Zone lasts two full rounds")
	game.engine.new_round(state)
	check(state.fields.is_empty(),"Zone expires at next round start")
	state = arena("water-gun"); field(state,"fire",6,8)
	result = game.engine.attack(state,10000,"water-gun")
	check(result.ok and result.state.fields.is_empty(),"Water extinguishes traversed fire")
	state = arena("gust"); field(state,"smoke",6,8)
	result = game.engine.attack(state,10000,"gust")
	check(result.ok and result.state.fields.is_empty(),"Gust disperses smoke")

func movement_tests() -> void:
	var state: Dictionary = arena("tackle")
	var pure: Dictionary = game.engine.apply_command(state,{"kind":"move","destination":{"x":5,"y":7}})
	var revision: Dictionary = load("res://core/movement_revision.gd").rectify(pure.state,[{"kind":"move","destination":{"x":5,"y":7}}],"current",game.engine,state)
	check(revision.ok and Save.equivalent(revision.get("state",{}),state),"First pure movement can be rectified with exact state and RNG")
	state.zoneEvents = [{"targetId":1,"name":"earlier field feedback"}]
	state.abilityEvents = [{"targetId":1,"name":"earlier ability feedback"}]
	pure = game.engine.apply_command(state,{"kind":"move","destination":{"x":5,"y":7}})
	revision = load("res://core/movement_revision.gd").rectify(pure.state,[{"kind":"move","destination":{"x":5,"y":7}}],"current",game.engine,state)
	check(revision.ok and Save.equivalent(revision.get("state",{}),state),"Earlier feedback never prevents rectifying a later pure movement")
	state.units[1].x = 12
	var ally: Dictionary = state.units[0].duplicate(true)
	ally.id = 2; ally.x = 6; state.units.append(ally)
	var routes: Dictionary = game.engine.movement_routes(state,state.units[0],4)
	check(routes.has("7,8") and not routes.has("6,8"),"Allies traversable but not valid destinations")
	state.units.pop_back()
	field(state,"web",6,8)
	routes = game.engine.movement_routes(state,state.units[0],4)
	check(routes.get("6,8",{}).get("cost")==2,"Web increases ground movement cost")
	state.units[0].profile = "fly"
	check(game.engine.movement_routes(state,state.units[0],4).get("6,8",{}).get("cost")==1,"Flying unit ignores web cost")
	state.units[0].profile = "walk"; state.fields = []
	field(state,"wall",6,8)
	check(not game.engine.movement_routes(state,state.units[0],1).has("6,8"),"Temporary wall blocks movement")
	state.fields = []; field(state,"rocks",6,8); field(state,"rocks",7,8)
	var hp: int = state.units[0].hp
	var result: Dictionary = game.engine.move(state,{"x":7,"y":8})
	check(result.ok and result.state.units[0].hp==hp-maxi(1,int(state.units[0].maxHp/12.0)),"Multiple rock cells apply one hazard per activation")
	check(result.state.movementLocked,"Hazard movement locks rectification")
	state = arena("vine-whip"); state.units[1].x = 7
	result = game.engine.attack(state,10000,"vine-whip")
	check(result.ok and result.state.units[1].x==6,"Vine Whip pulls to an empty tile")
	state.board[8][6] = 2
	check(not game.engine.attack_plan(state,10000,{},"vine-whip").ok,"Wall blocks whip")
	state = arena("strength"); state.units[1].maxHp = 1000; state.units[1].hp = 1000
	field(state,"rocks",7,8)
	result = game.engine.attack(state,10000,"strength")
	check(result.ok and result.state.units[1].x==7 and result.state.fields.is_empty(),"Push triggers and consumes rock trap")
	state = arena("seismic-toss"); state.units[1].maxHp = 1000; state.units[1].hp = 1000
	plan_throw(state)

func plan_throw(state: Dictionary) -> void:
	var result: Dictionary = game.engine.cast(state,{"x":6,"y":8,"throwFacing":0},"seismic-toss")
	check(result.ok and result.state.units[1].x==5 and result.state.units[1].y==6,"Throw uses chosen free landing direction")
	state.units[1].ability = "suction-cups"
	var plan: Dictionary = game.engine.attack_plan(state,10000,{},"seismic-toss")
	check(plan.ok and plan.push==null,"Suction Cups prevents forced movement")

func special_tests() -> void:
	var state: Dictionary = arena("roar")
	var result: Dictionary = game.engine.attack(state,10000,"roar")
	check(result.ok and not result.state.units[0].guarded and result.state.units[1].x==7,"Roar pushes instead of granting guard")
	state = arena("splash")
	result = game.engine.cast(state,{"x":5,"y":7},"splash")
	check(result.ok and result.state.units[0].y==7 and not result.state.units[0].guarded,"Splash hops without guard")
	state = arena("teleport")
	result = game.engine.cast(state,{"x":5,"y":5},"teleport")
	check(result.ok and result.state.acted and not result.state.moved,"Teleport spends action while preserving movement")
	state = arena("barrier")
	var plan: Dictionary = game.engine.cast_plan(state,{"x":8,"y":8,"axis":1},"barrier")
	check(plan.ok and plan.tiles.all(func(p):return p.y==8),"Wall can rotate")
	result = game.engine.cast(state,{"x":8,"y":8},"barrier")
	check(result.ok and result.state.fields.size()==3 and result.state.units[0].stages.is_empty(),"Barrier creates wall without Defense boost")
	state = arena("brick-break"); state.units[1].x = 9; field(state,"wall",6,8)
	result = game.engine.cast(state,{"x":6,"y":8},"brick-break")
	check(result.ok and result.state.fields.is_empty(),"Brick Break destroys an empty adjacent wall tile")
	state = arena("substitute")
	var hp: int = state.units[0].hp
	result = game.engine.attack(state,1,"substitute")
	check(result.ok and result.state.units[0].hp==hp-maxi(1,int(hp/4.0)) and result.state.units[0].spatial.effects.has("substitute"),"Substitute pays quarter HP and creates separate shield")
	state = arena("metronome")
	var before: Dictionary = state.duplicate(true)
	plan = game.engine.attack_plan(state,10000,{},"metronome")
	check(plan.ok and plan.randomTechnique and Save.equivalent(state,before),"Metronome envelope preview never rolls")
	result = game.engine.attack(state,10000,"metronome")
	check(result.ok and result.visualDefinition.id in game.progression.spatial_data.metronomePool and result.state.units[0].moves==["metronome"],"Metronome rolls once without permanently learning selected move")
	state = arena("disable"); state.units[1].spatial.lastMove = "surf"
	result = game.engine.attack(state,10000,"disable")
	check(result.ok and result.state.units[1].spatial.effects.has("disable"),"Disable has a real temporary effect")
	state = result.state; state.queue = [10000,1]; state.acted = false; state.units[1].moves = ["surf"]
	check(not game.engine.attack_plan(state,1,{},"surf").ok and game.engine.attack_plan(state,1,{},"basic").ok,"Disabled move rejects while basic remains available")
	state = arena("sleep-powder")
	result = game.engine.attack(state,10000,"sleep-powder")
	check(result.ok,"Sleep area resolves")
	state.units[0].ability = "no-guard"
	result = game.engine.attack(state,10000,"sleep-powder")
	check(result.state.units[1].status.remaining==1,"Area sleep lasts one affected activation")
	state = result.state; state.queue = [10000,1]; state.acted = false
	result = game.engine.finish(state)
	check(result.ok and result.state.units[1].status==null and result.state.units[1].spatial.effects.has("immunity"),"Sleep expiry grants a response window")
	state = arena("self-destruct"); state.units[1].ability = "damp"
	check(not game.engine.attack_plan(state,10000,{},"self-destruct").ok,"Damp prevents area self-KO")
	state = arena("soft-boiled"); state.units[1].team = "ally"; state.units[1].hp -= 30
	result = game.engine.attack(state,10000,"soft-boiled")
	check(result.ok and result.state.units[1].hp==state.units[1].maxHp,"Soft-Boiled heals selected ally")

func replay_tests() -> void:
	var rules: RefCounted = Run.new()
	var run: Dictionary = rules.create("spatial-replay",4)
	var orders: Array = [{"kind":"enter","at":0}]
	var step: Dictionary = rules.transact(run,orders[0])
	check(step.ok,"New campaign enters combat")
	run = step.state
	var timings: Array = []
	for i: int in 45:
		if run.phase!="battle": break
		var prior: Dictionary = run.duplicate(true)
		var started: int = Time.get_ticks_usec()
		var command: Dictionary = rules.engine.choose_command(run.battle)
		timings.append(Time.get_ticks_usec()-started)
		check(Save.equivalent(run,prior),"AI is read-only %d" % i)
		var event: Dictionary = {"kind":"battle","order":command,"at":run.revision}
		step = rules.transact(run,event)
		check(step.ok,"AI generates legal spatial command %d: %s" % [i,step.get("reason","")])
		if not step.ok: break
		run = step.state; orders.append(event)
	var path: String = "user://spatial-test-%d.json" % Time.get_ticks_usec()
	var store: RefCounted = Save.new(path)
	check(store.save(run,orders,"current").ok,"Save spatial campaign")
	var loaded: Dictionary = Save.new(path).load_campaign(rules)
	check(loaded.ok and Save.equivalent(run,loaded.get("state",{})),"Edition19 replay preserves complete state and RNG: "+str(loaded.get("reason","")))
	var old: RefCounted = Run.new(22)
	var old_state: Dictionary = old.create("upgrade",1)
	step = rules.transact(old_state,{"kind":"upgrade","edition":19,"at":0})
	check(step.ok and step.state.startEdition==18 and step.state.edition==19,"Explicit upgrade preserves original edition")
	print("Spatial AI max microseconds: "+str(timings.max()))

func conditional_tests() -> void:
	var state: Dictionary = {}
	var result: Dictionary = {}
	for identity: String in ["recover","roost","rest","soft-boiled"]:
		state = arena(identity)
		state.units[0].hp = 20
		result = game.engine.attack(state,1,identity)
		check(result.ok and result.state.units[0].hp>20 and result.state.units[0].recoveryPP[identity]==4,"Conditional recovery resolves and spends one PP: "+identity)
	for identity: String in ["disable","encore","mimic"]:
		state = arena(identity)
		state.units[1].spatial.lastMove = "tackle"
		result = game.engine.attack(state,10000,identity)
		check(result.ok,"Conditional control/copy resolves: "+identity)
		if identity=="mimic": check(result.state.units[0].moves==["tackle"],"Mimic replaces its temporary combat slot")
	for identity: String in ["counter","mirror-coat"]:
		state = arena(identity)
		state.units[0].spatial.lastAttacker = 10000
		state.units[0].spatial["lastPhysical" if identity=="counter" else "lastSpecial"] = 10
		result = game.engine.attack(state,10000,identity)
		check(result.ok and result.hits[0].damage==20,"Counter responds with twice received matching damage: "+identity)
	state = arena("mirror-move")
	state.units[0].spatial.effects.mirror = {"move":"tackle","remaining":3}
	result = game.engine.attack(state,10000,"mirror-move")
	check(result.ok and result.visualDefinition.id=="tackle","Mirror Move executes received technique")
	state = arena("dream-eater")
	state.units[1].status = {"kind":"sleep","remaining":3}
	result = game.engine.attack(state,10000,"dream-eater")
	check(result.ok and result.hits[0].damage>0,"Dream Eater resolves against sleeping target")
	state = arena("substitute")
	result = game.engine.attack(state,1,"substitute")
	state = result.state
	state.queue = [10000,1]; state.acted = false; state.units[1].moves = ["tackle"]
	var hp: int = state.units[0].hp
	result = game.engine.attack(state,1,"tackle")
	check(result.ok and result.hits[0].shielded and result.state.units[0].hp==hp,"Substitute absorbs damage into its own HP")
	state = arena("taunt")
	result = game.engine.attack(state,10000,"taunt")
	state = result.state; state.queue = [10000,1]; state.acted = false; state.units[1].moves = ["growl"]
	check(not game.engine.attack_plan(state,1,{},"growl").ok and game.engine.attack_plan(state,1,{},"basic").ok,"Taunt blocks support while preserving basic")
	state = arena("yawn")
	result = game.engine.attack(state,10000,"yawn")
	state = result.state; state.queue = [10000,1]; state.acted = false
	check(state.units[1].status==null and state.units[1].spatial.effects.has("yawn"),"Yawn announces delayed sleep")
	result = game.engine.finish(state)
	check(result.ok and result.state.units[1].status.kind=="sleep","Yawn sleeps at affected activation end")
	state = arena("bide")
	result = game.engine.attack(state,1,"bide")
	state = result.state; state.units[0].spatial.effects.bide.damage = 10
	state.units[0].spatial.effects.bide.ready = true; state.acted = false; state.units[0].tp = 5
	result = game.engine.attack(state,10000,"bide")
	check(result.ok and result.hits[0].damage==20 and not result.state.units[0].spatial.effects.has("bide"),"Bide releases capped accumulated damage once")
	state = arena("bonemerang")
	state.units[1].hp = 1000; state.units[1].maxHp = 1000
	var solo: Dictionary = game.engine.attack_plan(state,10000,{},"bonemerang")
	var extra: Dictionary = state.units[1].duplicate(true)
	extra.id = 10001; extra.x = 7; state.units.append(extra)
	var multiple: Dictionary = game.engine.attack_plan(state,10000,{},"bonemerang")
	check(multiple.ok and multiple.hits.size()==2 and multiple.hits[0].damageMax+multiple.hits[1].damageMax<=solo.damageMax+1,"Salvo shares a total damage budget across its line")
	state = arena("tackle")
	state.units[0].status = {"kind":"poison","remaining":3}
	state.units[0].ability = "shed-skin"
	var cured: bool = false
	for i: int in 20:
		state.rng = game.engine.Rng.hash_seed("shed"+str(i))
		result = game.engine.finish(state)
		if result.state.units[0].status==null: cured = true; break
	check(cured,"Shed Skin remains active in new end-turn resolver")
	var observed: Dictionary = {}
	for i: int in 120:
		state = arena("tri-attack")
		state.units[1].hp = 1000; state.units[1].maxHp = 1000
		state.rng = game.engine.Rng.hash_seed("triad-"+str(i))
		result = game.engine.attack(state,10000,"tri-attack")
		if result.state.units[1].status!=null: observed[result.state.units[1].status.kind] = true
	check(observed.size()==3 and observed.has("burn") and observed.has("freeze") and observed.has("paralysis"),"Tri Attack selects one of three statuses only on resolution")
	state = arena("tri-attack"); state.units[0].ability = "serene-grace"
	check(game.engine.attack_plan(state,10000,{},"tri-attack").hits[0].randomStatus.chance==40,"Serene Grace doubles Tri Attack secondary chance")
