extends "res://ui/qa_context.gd"

const Ledger = preload("res://core/relief_store.gd")

func run(app: Control, directory: String) -> void:
	var strategy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(app.review_journal_path))
	app.get_window().gui_embed_subwindows = true
	app.input_profile = Profile.new(directory.path_join("closing-controls.json"))
	app.board.input_profile = app.input_profile; app.controls_dialog.profile = app.input_profile
	app.input_profile.set_preference("reducedMotion",true); app.input_profile.set_preference("muted",true); app._apply_preferences()
	app.trainer.persistence = app.trainer.Store.new(directory.path_join("trainer-fresh-%d.json"%Time.get_ticks_usec()))
	app.trainer.persistence.load_profile(); app.trainer.model = app.trainer.Model.new(); app.trainer.signature = ""; app.trainer.persist()
	app.store = Ledger.new(directory.path_join("closing-ui-%d.json"%Time.get_ticks_usec()))
	await click(app,app.title_screen.controls.new); app.journey_seed.text = strategy.seed
	await click(app,app.travel_buttons["starter"+str(int(strategy.starter))])
	var visited: Array = []
	var started: int = Time.get_ticks_msec()
	for index: int in strategy.commands.size():
		var command: Dictionary = strategy.commands[index]
		var previous: Dictionary = app.run
		check(command.at==app.run.revision,"Expected revision "+str(index))
		if command.kind=="battle": app._commit(command.order)
		else: app._event(command)
		check(app.run.revision==previous.revision+1 and app.save_warning.is_empty(),"Native UI accepts and saves order "+str(index))
		if app.run.revision!=previous.revision+1 or not app.save_warning.is_empty(): break
		if command.kind=="enter":
			var location: Dictionary = app.campaign.locations[int(app.run.stage)]
			visited.append(location.id)
			if location.get("leader",false) or location.id in ["champion","legendary-birds","legendary-origin"]: await capture(app,directory,location.id)
			print("CLOSING_UI "+str(index)+" "+str(location.id))
			FileAccess.open(directory.path_join("closing-ui-progress.json"),FileAccess.WRITE).store_string(JSON.stringify({"orders":index,"visited":visited,"failures":failures}))
		if index%24==0: await app.get_tree().process_frame
		if not failures.is_empty(): break
	check(app.run.phase=="ending" and visited.size()==58 and app.run.medals.size()==8,"Native complete current Kanto")
	check(Ledger.equivalent(app.run,strategy.expectedState),"Final native state equals freshly executed current campaign")
	check([145,150].all(func(species):return species in app.trainer.model.data.dex),"Both chosen legends recorded in profile")
	check(["champion","birds","psychic","legend-recruit"].all(func(badge):return app.trainer.model.data.unlocked.has(badge)),"Campaign and collection achievements retained")
	var final_state: Dictionary = app.run.duplicate(true)
	var cold_started: int = Time.get_ticks_msec()
	DirAccess.remove_absolute(app.store.file_path+".verified")
	app.trainer.persistence = app.trainer.Store.new(directory.path_join("trainer-fresh-%d.json"%Time.get_ticks_usec()))
	app.trainer.persistence.load_profile(); app.trainer.model = app.trainer.Model.new(); app.trainer.signature = ""; app.trainer.persist()
	app.store = Ledger.new(app.store.file_path)
	await app._load_game()
	check(Ledger.equivalent(app.run,final_state) and not app.store.last_load.cached,"Complete native cold replay preserves state")
	var full_cold_ms: int = Time.get_ticks_msec()-cold_started
	await capture(app,directory,"complete-current-kanto")
	app._show_oak(); app.journey_seed.text = "closing-next-adventure"
	await click(app,app.travel_buttons.other_starters)
	app.starter_browser.query.text = "Zapdos"; app.starter_browser.render(); await settle(app)
	await click(app,app.starter_browser.controls[145]); await settle(app)
	check(app.run.starter==145 and app.run.party[0].level==5 and app.run.party.size()==1,"Complete campaign unlock can start fresh through real picker")
	check(app.trainer.model.data.unlocked.has("psychic"),"New adventure retains completed campaign achievements")
	var next_state: Dictionary = app.run.duplicate(true)
	await app._load_game()
	check(Ledger.equivalent(app.run,next_state),"New unlocked starter save reloads")
	var report: Dictionary = {"assertions":assertions,"failures":failures,"screenshots":screenshots,"visited":visited,"orders":strategy.commands.size(),"campaignEdition":int(final_state.edition),"stateHash":JSON.stringify(final_state,"",true,true).sha256_text(),"nextStateHash":JSON.stringify(app.run,"",true,true).sha256_text(),"seconds":(Time.get_ticks_msec()-started)/1000.0,"fullCampaignColdLoadMs":full_cold_ms,"nextStarterLoadMs":app.last_load_msec,"mapCatalogHash":FileAccess.get_file_as_string("res://data/relief-maps.json").sha256_text(),"scope":"Complete current scripted legal campaign through native UI, per-order saves, cold replay, profile and next-run unlock. Automated, not a human or another physical PC."}
	FileAccess.open(directory.path_join("candidate-journey.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("QA candidate-journey "+JSON.stringify({"assertions":assertions,"failures":failures})); app.get_tree().quit(0 if failures.is_empty() else 1)
