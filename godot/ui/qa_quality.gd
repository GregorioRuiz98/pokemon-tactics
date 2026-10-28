extends "res://ui/qa_context.gd"

const Ledger = preload("res://core/closing_store.gd")

func layout(app: Control) -> void:
	for frame: int in 8: await app.get_tree().process_frame

func run(app: Control, directory: String) -> void:
	app.get_window().gui_embed_subwindows = true
	app.input_profile = Profile.new(directory.path_join("quality-controls.json"))
	app.board.input_profile = app.input_profile; app.controls_dialog.profile = app.input_profile
	app.store = Ledger.new(directory.path_join("quality-natural-%d.json"%Time.get_ticks_usec()))
	await click(app,app.title_screen.controls.new)
	app.journey_seed.text = "quality-kanto"
	await click(app,app.travel_buttons.starter1)
	await click(app,app.travel_buttons.enter); await layout(app)
	var natural: Dictionary = app.run.duplicate(true)
	var journal: Array = app.transactions.duplicate(true)
	check(app.run.edition==app.CURRENT_CHAPTER-4,"Current campaign starts in current edition")
	check(app.encounter_preview.briefing.visible,"Encounter context appears automatically")
	await capture(app,directory,"oak-route-1")
	var coverage: Array = []
	for index: int in app.campaign.locations.size():
		var location: Dictionary = app.campaign.locations[index]
		app.run = natural.duplicate(true); app.run.stage = index
		app.run.battle = app.rules.encounter(app.run,location); app.state = app.run.battle
		app._prepare_campaign_assets(); app._refresh(); await layout(app)
		check(app.encounter_preview.briefing.text.contains(app.state.briefing.speaker),"Context displayed: "+location.id)
		check(app.encounter_preview.heading.tooltip_text==app.state.briefing.plan,"Terrain plan available: "+location.id)
		check(not app.encounter_preview.panel.get_global_rect().intersects(app.adventure.start_button.get_global_rect()),"Start unobstructed: "+location.id)
		coverage.append(location.id)
		if location.get("leader",false) or location.id in ["forest","mt-moon","silph-giovanni","champion","legendary-birds","legendary-origin"]: await capture(app,directory,location.id)
	app.run = natural; app.state = app.run.battle; app.transactions = journal
	app._prepare_campaign_assets(); app._refresh(); await layout(app)
	await click(app,app.adventure.start_button)
	var before: Dictionary = app.run.duplicate(true)
	var route: Dictionary = app.board.available.values()[0]
	app._hover_tile(route.path[-1])
	check(not app.hint.text.contains("Alcance potencial"),"Movement does not expose removed threats")
	check(Ledger.equivalent(before,app.run),"Tactical lens consumes no state or RNG")
	app._open_presentation(); await layout(app)
	check(app.presentation_dialog.widgets.has("battleSpeed"),"Combat speed exposed in options")
	app.presentation_dialog.change("battleSpeed",200)
	check(app.combat_feedback.attack_effect.playback_speed==2.0,"Double speed applies to effects")
	check(Profile.new(app.input_profile.path).preferences.battleSpeed==200,"Combat speed persists")
	await capture(app,directory,"combat-options")
	await key(app,KEY_ESCAPE,app.presentation_dialog)
	await app._load_game(); await layout(app)
	check(app.store.last_load.cached,"Real UI save is certified for fast load")
	check(app.last_load_msec<2000,"Opening certified reload under two seconds")
	var timing: Dictionary = await long_save(app,directory)
	var report: Dictionary = {"assertions":assertions,"failures":failures,"screenshots":screenshots,"campaignEdition":app.run.edition,"stateHash":JSON.stringify(app.run,"",true,true).sha256_text(),"encounters":coverage,"reloadMsec":app.last_load_msec,"longSave":timing,"scope":"Natural entry/save, all58 presentation fixtures, tactical lens, configurable speed, existing7838-order save load; no external human claim."}
	FileAccess.open(directory.path_join("quality-ui-result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("QA quality "+JSON.stringify({"assertions":assertions,"failures":failures})); app.get_tree().quit(0 if failures.is_empty() else 1)

func long_save(app: Control, directory: String) -> Dictionary:
	var path: String = ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--load-journal="): path = argument.trim_prefix("--load-journal=")
	if path.is_empty(): check(false,"Long-save input supplied"); return {}
	var journal: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var source: RefCounted = Ledger.new(directory.path_join("long-save-%d.json"%Time.get_ticks_usec()))
	check(source.save(journal.expectedState,journal.commands,"current").ok,"Long historical save copied into isolated profile")
	var counter: Dictionary = {"frames":0,"callbacks":0}
	var listener: Callable = func(): counter.frames += 1
	app.get_tree().process_frame.connect(listener)
	var started: int = Time.get_ticks_msec()
	var cold: Dictionary = await source.load_campaign_async(app.campaign,app.get_tree(),func(_done: int,_total: int): counter.callbacks += 1)
	var cold_msec: int = Time.get_ticks_msec()-started
	app.get_tree().process_frame.disconnect(listener)
	check(cold.ok and Ledger.equivalent(cold.get("state",{}),journal.expectedState),"Full old journal reconstructs canonical state")
	check(counter.frames>10 and counter.callbacks>10,"Uncertified long load yields responsive UI frames")
	var receiver: RefCounted = Ledger.new(source.file_path)
	started = Time.get_ticks_msec()
	var fast: Dictionary = receiver.load_campaign(app.campaign)
	var fast_msec: int = Time.get_ticks_msec()-started
	check(fast.ok and receiver.last_load.cached and fast.state==cold.state,"Certified long load preserves exact canonical state and RNG")
	check(fast_msec<2000 and fast_msec*5<cold_msec,"Long certified load under two seconds and at least5x faster")
	return {"orders":journal.commands.size(),"coldMsec":cold_msec,"cachedMsec":fast_msec,"responsiveFrames":counter.frames,"progressCallbacks":counter.callbacks}
