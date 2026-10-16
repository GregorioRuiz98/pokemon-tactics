extends "res://tests/letsgo.gd"

const Tactical = preload("res://core/tactics_run.gd")
const Revision = preload("res://core/movement_revision.gd")

func open_fixture() -> Dictionary:
	var state: Dictionary = fixture()
	for row: Array in state.board:
		for i: int in row.size(): row[i] = 0
	return state

func _initialize() -> void:
	rules = Tactical.new()
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="): directory = argument.trim_prefix("--save-dir=")
	if directory.is_empty(): quit(1); return
	for move: String in rules.progression.data.moves:
		var sample: Dictionary = open_fixture()
		sample.units[0].moves = [move]
		var target_id: int = 1 if rules.progression.data.moves[move].target=="self" else 2
		var unchanged: Dictionary = sample.duplicate(true)
		var advertised: Dictionary = rules.engine.attack_plan(sample,target_id,{},move)
		check(advertised.ok and advertised.has("damageMin"),"Every imported move has a tactical preview: "+move)
		check(Store.equivalent(unchanged,sample),"Pure preview: "+move)
		check(rules.engine.attack(sample,target_id,move).ok,"Every imported move remains executable: "+move)
	for side: String in ["front","flank","rear"]:
		var band: Dictionary = rules.engine.damage_band(40,50,side)
		check(band.min==40 and band.max==45 if side=="front" else (band.min==45 and band.max==50 if side=="flank" else band.min==50 and band.max==50),"Exact requested 40-50 directional split "+side)
		for i: int in 200:
			var context: Dictionary = {"rng":i}
			var rolled: int = rules.engine._roll(context,band.min,band.max)
			check(rolled>=band.min and rolled<=band.max,"Roll stays inside directional band")
	for facing: int in [6,0,2]:
		var state: Dictionary = open_fixture()
		state.units[1].facing = facing
		var before: Dictionary = state.duplicate(true)
		var plan: Dictionary = rules.engine.attack_plan(state,2,{},"basic")
		check(plan.ok and plan.accuracy==100,"No directional accuracy penalty")
		check(plan.criticalStages==(1 if facing==2 else 0),"Only rear adds a critical stage")
		check(is_equal_approx(plan.criticalChance,0.125 if facing==2 else 1.0/24),"Modern critical chance table")
		check(Store.equivalent(state,before),"Inspection does not consume damage/critical RNG")
		if facing==2: check(plan.normalMin==plan.normalMax,"Rear always rolls maximum normal damage")
	for i: int in 100:
		var state: Dictionary = open_fixture()
		state.rng = i
		state.units[1].facing = 6
		var plan: Dictionary = rules.engine.attack_plan(state,2,{},"basic")
		var result: Dictionary = rules.engine.attack(state,2,"basic")
		check(result.ok and result.hit,"100% move cannot miss from front")
		var hit: Dictionary = result.hits[0]
		check(hit.damage>= (plan.criticalMin if hit.critical else plan.normalMin) and hit.damage<= (plan.criticalMax if hit.critical else plan.normalMax),"Resolved damage agrees with advertised range")
	var accurate: Dictionary = open_fixture()
	rules.engine._change(accurate.units[0],{"stat":"accuracy","stages":1})
	rules.engine._change(accurate.units[1],{"stat":"evasion","stages":1})
	check(rules.engine.attack_plan(accurate,2,{},"basic").accuracy==100,"Equal accuracy/evasion stages cancel exactly")
	rules.engine._change(accurate.units[0],{"stat":"accuracy","stages":-2})
	check(rules.engine.attack_plan(accurate,2,{},"basic").accuracy==60,"Combined -2 precision stage uses 3/5, not two independent rounded factors")
	var assured: Dictionary = open_fixture()
	assured.units[0].moves = ["clear-smog"]
	rules.engine._change(assured.units[0],{"stat":"accuracy","stages":-2})
	rules.engine._change(assured.units[1],{"stat":"evasion","stages":2})
	check(rules.engine.attack_plan(assured,2,{},"clear-smog").accuracy==100,"Never-miss move ignores accuracy/evasion")
	for move: String in ["slash","hyper-fang"]:
		var landed: int = 0
		for i: int in 40:
			var state: Dictionary = open_fixture()
			state.rng = i
			state.units[0].moves = [move]
			var result: Dictionary = rules.engine.attack(state,2,move)
			check(result.ok,"Always-critical move is executable")
			if result.hit:
				landed += 1
				check(result.hits[0].critical,"Guaranteed critical on every successful hit")
		check(landed>0 and (landed<40 if move=="hyper-fang" else landed==40),"Guaranteed critical preserves the move's own accuracy")
	var neutral: Dictionary = open_fixture()
	neutral.units[0].moves = ["scratch"]
	var adjusted: Dictionary = neutral.duplicate(true)
	rules.engine._change(adjusted.units[0],{"stat":"attack","stages":-2})
	rules.engine._change(adjusted.units[1],{"stat":"defense","stages":2})
	var first: Dictionary = rules.engine.attack_plan(neutral,2,{},"scratch")
	var second: Dictionary = rules.engine.attack_plan(adjusted,2,{},"scratch")
	check(first.criticalMax==second.criticalMax and first.normalMax>second.normalMax,"Critical ignores negative offense and positive defense, normal hit does not")
	var fixed: Dictionary = use_move(open_fixture(),"dragon-rage")
	check(fixed.ok and fixed.damage==40 and not fixed.hits[0].critical,"Fixed damage is not randomized or made critical")
	var focus: Dictionary = use_move(open_fixture(),"focus-energy",true)
	check(focus.ok and focus.state.units[0].tp==2 and focus.state.units[0].volatile.has("focus") and not focus.state.units[0].stages.has("accuracy"),"Focus Energy costs 3 and raises critical chance rather than accuracy")
	focus.state.acted = false
	focus.state.units[0].moves = []
	check(rules.engine.attack_plan(focus.state,2,{},"basic").criticalChance==1,"Rear plus Focus Energy reaches guaranteed critical tier")
	for tuple: Array in [["harden",2],["agility",3],["growth",3],["quiver-dance",4]]: check(rules.progression.data.moves[tuple[0]].cost==tuple[1],"Raised boost cost "+tuple[0])
	var buffed: Dictionary = use_move(open_fixture(),"agility",true)
	check(buffed.ok and buffed.state.units[0].stageTurns.speed==3,"Boost starts with three owner activations")
	var buff_state: Dictionary = buffed.state
	for turn: int in range(1,4):
		buff_state.queue = [1,2]
		var ended: Dictionary = rules.engine.finish(buff_state,2)
		buff_state = ended.state
		check(ended.ok and (buff_state.units[0].stageTurns.speed==3-turn if turn<3 else buff_state.units[0].stages.is_empty() and buff_state.units[0].speed==buff_state.units[0].baseCombatStats.speed),"Boost expires after exactly three owner activations")
	var bad: Dictionary = open_fixture()
	bad.units[0].tp = 1
	var before_bad: Dictionary = bad.duplicate(true)
	check(not use_move(bad,"quiver-dance",true).ok and bad.rng==before_bad.rng and bad.units[0].tp==1,"Unaffordable boost consumes neither PT nor RNG")
	var normal_round: Dictionary = open_fixture()
	normal_round.units[0].speed = 100
	normal_round.units[0].budget = 5
	normal_round.units[1].speed = 1
	var paralyzed_round: Dictionary = normal_round.duplicate(true)
	paralyzed_round.units[0].status = {"kind":"paralysis","remaining":3}
	rules.engine.new_round(normal_round)
	rules.engine.new_round(paralyzed_round)
	check(Store.equivalent(normal_round.initiative,paralyzed_round.initiative),"Paralysis never lowers initiative score")
	check(paralyzed_round.units[0].remaining==2 and paralyzed_round.units[0].speed==100 and rules.engine.attack_plan(paralyzed_round,2,{},"basic").ok,"Paralysis halves movement only, without blocking actions")
	var dash: Dictionary = open_fixture()
	dash.units[1].x = 7
	dash.units[0].moves = ["quick-attack"]
	var before_dash: Dictionary = dash.duplicate(true)
	var approach: Dictionary = rules.engine.attack_plan(dash,2,{},"quick-attack")
	check(approach.ok and approach.approach.destination.x==6 and approach.approach.cost==2 and Store.equivalent(dash,before_dash),"Approach previews a legal landing/path without mutation")
	var charged: Dictionary = rules.engine.attack(dash,2,"quick-attack")
	check(charged.ok and charged.state.units[0].x==6 and charged.state.units[0].remaining==dash.units[0].remaining-2 and charged.state.acted and charged.state.moved,"Gap closer spends movement and action")
	check(not Revision.available(charged.state,[{"kind":"attack"}]),"Approach attack cannot be rectified")
	var blocker: Dictionary = dash.units[1].duplicate(true)
	blocker.id = 3
	blocker.x = 5
	dash.units.append(blocker)
	check(not rules.engine.attack_plan(dash,2,{},"quick-attack").ok,"Approach never crosses enemies")
	dash.units[-1].team = "ally"
	check(rules.engine.attack_plan(dash,2,{},"quick-attack").ok,"Approach can cross allies")
	dash.units[-1].x = 6
	check(not rules.engine.attack_plan(dash,2,{},"quick-attack").ok,"Approach cannot land on an occupied tile")
	var missed_dash: bool = false
	for seed_number: int in 30:
		var uncertain: Dictionary = open_fixture()
		uncertain.units[0].moves = ["quick-attack"]
		uncertain.units[1].x = 7
		uncertain.rng = seed_number
		rules.engine._change(uncertain.units[0],{"stat":"accuracy","stages":-2})
		var missed: Dictionary = rules.engine.attack(uncertain,2,"quick-attack")
		if missed.ok and not missed.hit:
			missed_dash = true
			check(missed.state.units[0].x==6 and missed.state.units[0].tp==3 and missed.state.units[1].hp==uncertain.units[1].hp,"A missed gap closer still spends movement/PT and lands safely")
			break
	check(missed_dash,"Genuine RNG miss exercised for gap closer")
	var pushed: Dictionary = use_move(open_fixture(),"headbutt")
	check(pushed.ok and pushed.state.units[1].x==6,"Headbutt pushes one tile on hit")
	var wall: Dictionary = open_fixture()
	wall.board[4][6] = 2
	var blocked: Dictionary = use_move(wall,"headbutt")
	check(blocked.ok and blocked.state.units[1].x==5 and blocked.damage==pushed.damage,"Blocked push adds no collision damage and stays in bounds")
	var low_hp: Dictionary = open_fixture()
	low_hp.units[1].hp = 1
	var lethal: Dictionary = rules.engine.attack_plan(low_hp,2,{},"basic")
	check(lethal.damageMin==1 and lethal.normalMin>1,"HP clipping cannot shrink the underlying damage roll")
	var draining: Dictionary = use_move(open_fixture(),"mega-drain")
	check(draining.ok and draining.hits[0].heal==int(draining.damage/2.0) and draining.state.units[0].hp==5000+int(draining.damage/2.0),"Drain heals from actual rolled damage, including a critical")
	var negative: Dictionary = use_move(open_fixture(),"tail-whip")
	check(negative.ok and negative.state.units[1].stageTurns.defense==3,"Debuff receives the same temporary duration")
	var restored_state: Dictionary = negative.state
	for turn: int in 3:
		restored_state.queue = [2,1]
		restored_state = rules.engine.finish(restored_state,2).state
	check(restored_state.units[1].stages.is_empty() and restored_state.units[1].defense==restored_state.units[1].baseCombatStats.defense,"Debuff expires and restores base defense")
	var smart: Dictionary = open_fixture()
	smart.units[1].facing = 6
	var smart_before: Dictionary = smart.duplicate(true)
	var decision: Dictionary = rules.engine.choose_command(smart)
	check(Store.equivalent(smart,smart_before) and rules.engine.apply_command(smart,decision).ok,"Flanking AI reads pure forecasts and issues a legal command")
	var badge_unit: Dictionary = charged.state.units[0]
	rules.engine._change(badge_unit,{"stat":"defense","stages":-2})
	var badges: Array = Indicators.entries(badge_unit)
	check(badges.size()==1 and badges[0].stage==-2 and "3 activaciones" in badges[0].hint,"Badges expose signed stage and remaining duration")
	for script: String in ["kanto_run","progression_run","shop_run","growth_run","letsgo_run","tactics_run"]:
		var original: RefCounted = load("res://core/"+script+".gd").new()
		var initial: Dictionary = original.create("compat-tactics",4)
		var journal: Array = [{"kind":"enter","at":0}]
		var current: Dictionary = original.transact(initial,journal[0]).state
		if script=="tactics_run":
			for i: int in 30:
				if current.phase!="battle": break
				var command: Dictionary = {"kind":"battle","order":original.engine.choose_command(current.battle),"at":current.revision}
				var step: Dictionary = original.transact(current,command)
				check(step.ok,"Shared AI issues legal tactical commands")
				current = step.state
				journal.append(command)
		var archive: Store = Store.new(directory.path_join("tactics-"+script+".json"))
		check(archive.save(current,journal,"").ok,"Archive "+script)
		var restored: Dictionary = archive.load_campaign(rules)
		check(restored.ok and Store.equivalent(restored.state,current),"Exact old/new replay including damage RNG and timers "+script)
	var report: Dictionary = {"assertions":assertions,"failures":failures,"edition":6}
	var file: FileAccess = FileAccess.open(directory.path_join("tactics-result.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
