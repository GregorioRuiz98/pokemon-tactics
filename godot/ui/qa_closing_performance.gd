extends "res://ui/qa_performance.gd"

const CurrentRun = preload("res://core/closing_run.gd")
const CurrentStore = preload("res://core/closing_store.gd")
const Planner = preload("res://ui/turn_planner.gd")
var parity_cases: int = 0
var planner_samples: Array = []
var decisions: Array = []

func compare_plan(rules: RefCounted, state: Dictionary, label: String) -> Dictionary:
	var before: Dictionary = state.duplicate(true)
	var started: int = Time.get_ticks_usec()
	var expected: Dictionary = rules.choose_command(state)
	var original_ms: float = (Time.get_ticks_usec()-started)/1000.0
	var planner: RefCounted = Planner.new()
	planner.start(rules,state)
	var slices: int = 0
	var maximum: float = 0
	var total: float = 0
	while not planner.complete and slices<10000:
		started = Time.get_ticks_usec()
		planner.advance()
		var elapsed_ms: float = (Time.get_ticks_usec()-started)/1000.0
		maximum = maxf(maximum,elapsed_ms); total += elapsed_ms; slices += 1
	check(planner.complete and Store.equivalent(expected,planner.decision),"Same AI command, including tie order: "+label)
	check(Store.equivalent(before,state),"Planner never mutates state or RNG: "+label)
	planner_samples.append({"case":label,"originalMs":original_ms,"scheduledMs":total,"maxSliceMs":maximum,"slices":slices,"dangerEvaluations":planner.danger_evaluations})
	decisions.append(planner.decision.duplicate(true))
	parity_cases += 1
	return planner.decision

func run(app: Control, directory: String) -> void:
	DirAccess.make_dir_recursive_absolute(directory)
	app.get_window().gui_embed_subwindows = true
	var serial: String = str(Time.get_ticks_usec())
	app.input_profile = Profile.new(directory.path_join("fluency-controls-"+serial+".json"))
	app.board.input_profile = app.input_profile
	app.controls_dialog.profile = app.input_profile
	app.campaign = CurrentRun.new()
	app.rules = app.campaign.engine
	app.run = app.campaign.create("fluency-24",1)
	app.run.mapSize = 24
	app.run.party = []
	for species: int in [3,6,9,26,65,68]:
		app.run.party.append(app.campaign.progression.create_member(app.run.party.size()+1,species,"Synthetic performance fixture",40))
	app.run.stage = app.campaign.locations.find(app.campaign.locations.filter(func(l):return l.id=="koga")[0])
	app.run.phase = "battle"
	app.state = app.rules.encounter(app.run,app.campaign.locations[app.run.stage])
	app.state.deployment = false
	app.state.queue = [1]
	app.rules.begin_activation(app.state)
	app.run.battle = app.state
	app.run.battleInitial = app.state.duplicate(true)
	app.transactions = []
	app.title_visible = false
	app.store = CurrentStore.new(directory.path_join("synthetic-performance-"+serial+".json"))
	app._prepare_campaign_assets()
	app._refresh()
	app.board.focus_point(app.state.units[0])
	await settle(app)
	var before: Dictionary = app.run.duplicate(true)
	measure("refresh-current-12",15,app._refresh)
	measure("save-current-12",8,app._save)
	check(app.save_warning.is_empty(),"Save benchmark writes successfully with conflict protection")
	measure("pick-current-24",200,func():app.board.pick(app.board.play_area().get_center()))
	app.selected_action = "petal-dance"; app.selecting = "attack"
	measure("area-select-current-12",10,app._refresh)
	measure("area-hover-current-12",50,func():
		app.hover_context.clear()
		app._hover_tile({"x":app.state.units[0].x+1,"y":app.state.units[0].y}))
	app.selecting = "auto"; app.selected_action = "basic"
	app._refresh()
	measure("ai-plan-current-12",5,func():app.rules.choose_command(app.state))
	check(Store.equivalent(before,app.run) and app.transactions.is_empty(),"Profiling preserves current state, journal and RNG")
	var cache_aim: Dictionary = {"x":app.state.units[0].x+1,"y":app.state.units[0].y,"axis":0,"throwFacing":0}
	app._spatial_plan(cache_aim,"petal-dance")
	var cache_size: int = app.spatial_plans.size()
	for i: int in 50: app._spatial_plan(cache_aim,"petal-dance")
	check(app.spatial_plans.size()==cache_size,"Fifty repeated previews reuse one cached query")
	app._spatial_plan({"x":cache_aim.x,"y":cache_aim.y,"axis":1,"throwFacing":0},"petal-dance")
	app._spatial_plan({"x":cache_aim.x,"y":cache_aim.y,"axis":0,"throwFacing":2},"petal-dance")
	check(app.spatial_plans.size()==cache_size+2,"Orientation and throw direction have separate cached plans")
	app._refresh()
	check(app.spatial_plans.is_empty(),"State refresh invalidates cached queries")
	var baseline: Dictionary = app.state.duplicate(true)
	for unit: Dictionary in baseline.units:
		for mode: String in ["normal","moved","acted","flinch"]:
			var sample: Dictionary = baseline.duplicate(true)
			sample.queue = [unit.id]
			sample.moved = mode=="moved"; sample.acted = mode=="acted"
			if mode=="flinch": app.rules.active(sample).spatial.effects.flinch = {"turns":1}
			compare_plan(app.rules,sample,str(unit.speciesId)+"/"+mode)
	for moves: Array in [["smokescreen","reflect","teleport","surf"],["explosion","earthquake","mimic","seismic-toss"]]:
		var sample: Dictionary = baseline.duplicate(true)
		for index: int in sample.units.size():
			var unit: Dictionary = sample.units[index]
			unit.x = 5+index%4; unit.y = 5+int(index/4.0)
			unit.moves = moves; unit.tp = 5
			sample.board[int(unit.y)][int(unit.x)] = 0; sample.heights[int(unit.y)][int(unit.x)] = 0
			sample.fields.append({"kind":["smoke","fire","wall"][index%3],"x":unit.x,"y":unit.y+1,"expires":sample.round+3,"source":1,"chance":100,"zone":1})
		for unit: Dictionary in sample.units:
			sample.queue = [unit.id]
			compare_plan(app.rules,sample,"zones/"+str(unit.id)+"/"+moves[0])
	# Advance a real battle through both implementations, retaining every command.
	var natural: Dictionary = app.campaign.create("fluency-natural",4)
	natural = app.campaign.transact(natural,{"kind":"enter","at":natural.revision}).state
	var journal: Array = [{"kind":"enter","at":0}]
	var start_order: Dictionary = {"kind":"start-battle","at":natural.revision}
	natural = app.campaign.transact(natural,start_order).state; journal.append(start_order)
	for i: int in 100:
		if natural.phase!="battle": break
		var order: Dictionary = compare_plan(app.rules,natural.battle,"natural/"+str(i))
		var command: Dictionary = {"kind":"battle","order":order,"at":natural.revision}
		var result: Dictionary = app.campaign.transact(natural,command)
		check(result.ok,"Natural planner command accepted "+str(i))
		if not result.ok: break
		natural = result.state; journal.append(command)
	var replay_store: RefCounted = CurrentStore.new(directory.path_join("natural-planner-"+serial+".json"))
	check(replay_store.save(natural,journal,"journey").ok,"Natural planner trace saved")
	var replay: Dictionary = CurrentStore.new(replay_store.file_path).load_campaign(app.campaign)
	check(replay.ok and Store.equivalent(replay.get("state",{}),natural),"Cold replay of planner trace matches exactly")
	measurements.planner = {"cases":parity_cases,"samples":planner_samples}
	measurements.equivalence = {"cases":parity_cases,"decisionsHash":JSON.stringify(decisions,"",true,true).sha256_text(),"naturalStateHash":JSON.stringify(natural,"",true,true).sha256_text(),"journalHash":JSON.stringify(journal,"",true,true).sha256_text()}
	check(planner_samples.any(func(s):return s.slices>1),"Large planning jobs yield between frames")
	# Actual UI scheduler: pause, invalidate stale work, then commit one decision.
	app.state.queue = [app.state.units[6].id]
	app.rules.begin_activation(app.state)
	app.run.battle = app.state
	app._refresh(); app.ai_clock = 0
	app.qa_running = false
	app._process(.001)
	app.qa_running = true
	check(app.run.revision==before.revision and app.turn_planner.phase!="idle","Enemy planning starts without premature commit")
	var progress: String = app.turn_planner.phase
	app.controls_dialog.popup_centered()
	app.qa_running = false; app._process(1); app.qa_running = true
	check(app.turn_planner.phase==progress and app.run.revision==before.revision,"Modal pauses planning and committing")
	app.controls_dialog.hide()
	app._refresh()
	check(app.turn_planner.phase=="idle","Refresh discards unfinished enemy work")
	var expected_order: Dictionary = app.rules.choose_command(app.state)
	var expected_result: Dictionary = app.campaign.transact(app.run,{"kind":"battle","order":expected_order,"at":app.run.revision})
	for i: int in 200:
		app.qa_running = false; app._process(.02); app.qa_running = true
		if app.run.revision!=before.revision: break
	check(expected_result.ok and Store.equivalent(expected_result.state,app.run),"UI scheduler commits exactly one authoritative decision")
	app.combat_feedback.clear()
	app.run = before.duplicate(true); app.state = app.run.battle; app.transactions = []
	app._refresh()
	var draw_samples: Array[float] = []
	app.board.set_meta("draw_samples",draw_samples)
	var intervals: Array[float] = []
	for frame: int in 120:
		var started: int = Time.get_ticks_usec()
		await app.get_tree().process_frame
		intervals.append((Time.get_ticks_usec()-started)/1000.0)
	app.board.remove_meta("draw_samples")
	draw_samples.sort(); intervals.sort()
	if not draw_samples.is_empty(): measurements.drawCurrent = {"count":draw_samples.size(),"medianMs":draw_samples[int(draw_samples.size()*.5)],"p95Ms":draw_samples[int(draw_samples.size()*.95)]}
	measurements.framesCurrent = {"count":120,"medianMs":intervals[60],"p95Ms":intervals[114]}
	await capture(app,directory,"current-12-units")
	await measure_hub(app,directory)
	write_result(app,directory)

func measure_hub(app: Control, directory: String) -> void:
	app.run.phase = "shop"; app.run.battle = {}; app.state = {}
	app.run.party[0] = app.campaign.progression.create_member(1,34,"Explicit menu fixture",75)
	app.campaign.progression.assign(app.run.party[0],app.run.seed)
	for item: Dictionary in app.campaign.shop_data.items.values():
		if item.kind=="tm" and item.get("species",[]).any(func(value):return int(value)==34) and item.move not in app.run.party[0].knownMoves: app.run.party[0].knownMoves.append(item.move)
	app.hub_mode = "team"; app.selected_member = 1; app.member_view = "profile"
	app.campaign.roll_stock(app.run,true)
	app._prepare_campaign_assets(); app._refresh(); app._set_hub_mode("team"); app._set_member_view("profile"); await settle(app)
	measure("team-profile-large-library",12,app._refresh)
	app.member_view = "moves"; app._refresh(); await settle(app)
	measure("team-moves-large-library",12,app._refresh)
	for slot: int in 4: check(app.travel_buttons.has("move_slot_"+str(slot)),"Full active moves panel preserves slot "+str(slot))
	await capture(app,directory,"team-moves-current")

func write_result(app: Control, directory: String) -> void:
	var report: Dictionary = {"assertions":assertions,"failures":failures,"measurements":measurements,"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"screenshots":screenshots,"scope":"Current edition29, explicit 12-unit/24x24 and full-library fixtures; real first-battle planner trace. Local timings, not universal FPS or another computer."}
	FileAccess.open(directory.path_join("closing-performance.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("QA closing-performance "+JSON.stringify({"assertions":assertions,"failures":failures}))
	app.get_tree().quit(0 if failures.is_empty() else 1)
