extends "res://ui/qa_context.gd"

const CurrentRun = preload("res://core/adventure_run.gd")
const CurrentStore = preload("res://core/adventure_store.gd")
const Challenge = preload("res://core/journey_challenge.gd")

func layout(app: Control) -> void:
	for frame: int in 6: await app.get_tree().process_frame

func run(app: Control, directory: String) -> void:
	app.get_window().gui_embed_subwindows = true
	app.input_profile = Profile.new(directory.path_join("adventure-controls-%d.json" % Time.get_ticks_usec()))
	app.board.input_profile = app.input_profile; app.controls_dialog.profile = app.input_profile
	app.store = CurrentStore.new(directory.path_join("natural-%d.json" % Time.get_ticks_usec()))
	app._show_oak()
	app.journey_seed.text = Challenge.encode({"seed":"adventure-ui","starter":7,"mapSize":24})
	await click(app,app.travel_buttons.starter1)
	check(app.run.edition==21 and app.run.starter==7 and app.run.mapSize==24,"Challenge restores initial, map and edition through Oak")
	await click(app,app.travel_buttons.enter)
	check(app.state.deployment and app.adventure.deploy_panel.visible and not app.command_panel.visible,"Integrated preparation replaces orders")
	await layout(app)
	var before: Dictionary = app.run.duplicate(true)
	await tile(app,app.state.arena.deployment[0])
	check(app.run.revision==before.revision+1 and app.state.rng==before.battle.rng,"Mouse deployment saves without spending RNG")
	await click(app,app.adventure.auto_button)
	check(app.state.units[0].x==9 and app.state.units[0].y==12,"Default formation restored for 24 map")
	app.board.grab_focus()
	await key(app,KEY_T)
	for frame: int in 2000:
		if app.adventure.threat_job==null: break
		app.adventure.tick(app,.016)
		await app.get_tree().process_frame
	check(not app.board.threat_cells.is_empty(),"Keyboard threat toggle calculates coverage")
	check(app.run.battle.rng==before.battle.rng,"Threat overlay preserves combat RNG")
	await capture(app,directory,"preparation-threats")
	await key(app,KEY_B)
	check(not app.state.deployment and not app.adventure.deploy_panel.visible,"Keyboard begins battle")
	for index: int in 180:
		if app.run.phase!="battle": break
		var revision: int = app.run.revision
		app._commit(app.rules.choose_command(app.state))
		check(app.run.revision==revision+1,"Natural authoritative order "+str(index))
		app.combat_feedback.clear()
	check(app.run.phase=="capture","Natural opening wins with new rules")
	if app.run.phase=="capture":
		check(app.adventure.toast.visible,"Capture has a brief presentation")
		before = app.run.duplicate(true)
		await key(app,KEY_ESCAPE)
		check(not app.adventure.toast.visible and Store.equivalent(before,app.run),"Skip presentation preserves state")
		await click(app,app.travel_buttons.capture)
		await key(app,KEY_ESCAPE)
	var replay: Dictionary = CurrentStore.new(app.store.file_path).load_campaign(app.campaign)
	check(replay.ok and Store.equivalent(replay.get("state",{}),app.run),"Cold replay includes deployment, combat and reward")
	var natural_hash: String = JSON.stringify(app.run,"",true,true).sha256_text()
	var journal_hash: String = JSON.stringify(app.transactions,"",true,true).sha256_text()
	if app.run.phase=="shop":
		check(app.travel_buttons.has("share_journey"),"Share action integrated in hub")
		await app.adventure.export_card(app,directory.path_join("journey-card.png"),false)
		check(FileAccess.file_exists(directory.path_join("journey-card.png")),"Portable result card exported")
		await key(app,KEY_ESCAPE,app.action_review)
		check(app.run.phase=="shop","Export never changes adventure")
	# Explicit synthetic full-team fixture for scale, gym visuals and dragging.
	app.combat_feedback.clear()
	app.campaign = CurrentRun.new(); app.rules = app.campaign.engine
	app.run = app.campaign.create("arena-ui-fixture",1); app.run.party = []
	for species: int in [3,6,9,26,65,68]: app.run.party.append(app.campaign.progression.create_member(app.run.party.size()+1,species,"Synthetic UI fixture",40))
	app.run.phase = "battle"
	app.store = CurrentStore.new(directory.path_join("arena-fixture-%d.json" % Time.get_ticks_usec()))
	app.transactions = []
	for dimensions: Vector2i in [Vector2i(1024,720),Vector2i(1280,900)]:
		app.get_window().size = dimensions
		for scale_value: int in [100,125,150]:
			app.run.stage = 3
			app.state = app.rules.encounter(app.run,app.campaign.locations[3]); app.run.battle = app.state
			app._prepare_campaign_assets()
			app.input_profile.set_preference("textScale",scale_value)
			app._apply_preferences(); app._refresh()
			await layout(app)
			check(app.adventure.deploy_panel.get_global_rect().end.y<=app.size.y,"Preparation inside viewport %d/%d" % [dimensions.x,scale_value])
			check(app.adventure.start_button.size.x>160 and app.adventure.start_button.size.y>32,"Readable begin control %d/%d" % [dimensions.x,scale_value])
			check(app.board.play_area().size.x>200,"Board remains usable %d/%d" % [dimensions.x,scale_value])
			await capture(app,directory,"deploy-%d-%d" % [dimensions.x,scale_value])
			app.rules.start_battle(app.state)
			app.state.queue = [app.state.units[0].id]
			app._refresh(); app.board.grab_focus()
			await key(app,KEY_A)
			await layout(app)
			check(app.command_panel.visible and app.action_page,"Abilities remain keyboard accessible %d/%d" % [dimensions.x,scale_value])
			check(app.command_panel.get_global_rect().end.y<=app.size.y,"Ability menu inside viewport %d/%d" % [dimensions.x,scale_value])
			if scale_value==150: await capture(app,directory,"abilities-%d-%d" % [dimensions.x,scale_value])
	app.get_window().size = Vector2i(1280,900)
	app.input_profile.set_preference("textScale",100); app._apply_preferences()
	app.run.stage = 3
	app.state = app.rules.encounter(app.run,app.campaign.locations[3]); app.run.battle = app.state
	app.adventure.scope = 0
	app._refresh(); app.board.frame_combat()
	await layout(app)
	var from: Dictionary = app.state.units[0]
	var destination: Dictionary = {"x":app.state.units[1].x,"y":app.state.units[1].y}
	var expected: Dictionary = app.campaign.transact(app.run,{"kind":"deploy","member":from.id,"destination":destination,"at":app.run.revision})
	await pointer(app,app.board.center(from),true)
	await motion(app,app.board.center(destination),Vector2(-40,-20),MOUSE_BUTTON_MASK_LEFT)
	await pointer(app,app.board.center(destination),false)
	check(expected.ok and Store.equivalent(expected.state,app.run),"Native drag swaps allies with authoritative result")
	app.input_profile.set_preference("highContrast",true)
	app.input_profile.set_preference("reducedMotion",true)
	app.input_profile.set_preference("accessibleMode",true)
	app._apply_preferences(); app._refresh()
	await layout(app)
	check(app.board.accessibility_name.contains("Preparación"),"Accessible board describes preparation instead of enemy turn")
	app.input_profile.set_preference("accessibleMode",false); app._apply_preferences()
	await capture(app,directory,"deployment-contrast")
	app.input_profile.set_preference("highContrast",false); app.input_profile.set_preference("reducedMotion",false); app._apply_preferences()
	app.rules.start_battle(app.state)
	var caster: Dictionary = app.state.units[1]
	caster.moves = ["ember"]; caster.tp = 5
	var target: Dictionary = app.state.units.filter(func(u):return u.team=="enemy")[0]
	target.x = caster.x; target.y = caster.y-1
	app.state.board[int(target.y)][int(target.x)] = 0; app.state.heights[int(target.y)][int(target.x)] = 0
	app.state.fields = [{"kind":"web","x":target.x,"y":target.y,"source":0,"expires":99,"chance":100,"zone":1}]
	app.state.queue = [caster.id]
	app._refresh(); app._select_action("ember"); app._hover_tile(target)
	check(app.target_info.text.contains("Seda → fuego"),"Forecast describes terrain reaction")
	app._commit({"kind":"attack","actionId":"ember","target":target.id,"aim":{"x":target.x,"y":target.y}})
	check(app.combat_feedback.marks.any(func(m):return m.kind=="terrain" and m.text=="Seda ardiendo"),"Terrain reaction has its own visual feedback")
	app.combat_feedback.attack_effect._process(.4)
	await capture(app,directory,"terrain-reaction")
	app.combat_feedback.clear()
	var arena_count: int = 0
	for index: int in app.campaign.locations.size():
		var location: Dictionary = app.campaign.locations[index]
		if not location.get("leader",false): continue
		app.run.stage = index
		app.state = app.rules.encounter(app.run,location); app.run.battle = app.state
		app.adventure.scope = 0; app.adventure.last_revision = -1
		app._prepare_campaign_assets(); app._refresh()
		app.board.frame_combat()
		await layout(app)
		check(app.state.arena.title!="Encuentro de ruta","Themed gym "+location.id)
		await capture(app,directory,location.id)
		arena_count += 1
	app.adventure.scope = 2; app.adventure.request_threat(app)
	var slices: int = 0; var total_ms: float = 0; var max_slice_ms: float = 0
	before = app.run.duplicate(true)
	for frame: int in 10000:
		if app.adventure.threat_job==null: break
		var started: int = Time.get_ticks_usec()
		app.adventure.tick(app,.016)
		var elapsed_ms: float = (Time.get_ticks_usec()-started)/1000.0
		total_ms += elapsed_ms; max_slice_ms = maxf(max_slice_ms,elapsed_ms); slices += 1
		await app.get_tree().process_frame
	check(app.adventure.threat_job==null and not app.board.threat_cells.is_empty(),"All-enemy threat overlay completes for twelve-unit gym")
	check(Store.equivalent(before,app.run),"Full gym coverage preserves all state and RNG")
	var draw_samples: Array[float] = []
	app.board.set_meta("adventure_draw_samples",draw_samples)
	for frame: int in 120: await app.get_tree().process_frame
	app.board.remove_meta("adventure_draw_samples"); draw_samples.sort()
	await capture(app,directory,"all-threats")
	var performance: Dictionary = {"slices":slices,"queryCpuMs":total_ms,"maxSliceMs":max_slice_ms,"drawSamples":draw_samples.size(),"medianBoardDrawMs":draw_samples[int(draw_samples.size()*.5)] if not draw_samples.is_empty() else 0.0}
	var report: Dictionary = {"assertions":assertions,"failures":failures,"screenshots":screenshots,"naturalStateHash":natural_hash,"journalHash":journal_hash,"gyms":arena_count,"edition":21,"combatEdition":19,"syntheticGymFixtures":true,"fullCampaignPlayed":false,"performance":performance}
	FileAccess.open(directory.path_join("adventure-ui-result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("QA adventure "+JSON.stringify(report)); app.get_tree().quit(0 if failures.is_empty() else 1)
