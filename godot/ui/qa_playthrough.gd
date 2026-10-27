extends "res://ui/qa_context.gd"

const ReviewStore = preload("res://core/review_store.gd")

func run(app: Control, directory: String) -> void:
	var journal_path: String = app.review_journal_path
	var journal: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(journal_path))
	var expected: Dictionary = journal.get("expectedState",{})
	if expected.is_empty():
		var source_path: String = journal_path.get_base_dir().path_join("natural-save.json")
		var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(source_path))
		expected = JSON.parse_string(envelope.payload).state
	app.get_window().gui_embed_subwindows = true
	app.input_profile = Profile.new(directory.path_join("playthrough-controls.json"))
	app.board.input_profile = app.input_profile; app.controls_dialog.profile = app.input_profile
	app.input_profile.set_preference("reducedMotion",true); app.input_profile.set_preference("muted",true)
	app._apply_preferences()
	app.store = ReviewStore.new(directory.path_join("playthrough-save-%d.json"%Time.get_ticks_usec()))
	await click(app,app.title_screen.controls.new)
	app.journey_seed.text = journal.seed
	await click(app,app.travel_buttons["starter"+str(int(journal.starter))])
	var visited: Array = []
	var started: int = Time.get_ticks_msec()
	for index: int in journal.commands.size():
		var command: Dictionary = journal.commands[index]
		var previous: Dictionary = app.run
		check(int(command.at)==int(app.run.revision),"Journal revision "+str(index))
		if command.kind=="battle": app._commit(command.order)
		else: app._event(command)
		check(app.run.revision==previous.revision+1 and app.save_warning.is_empty(),"UI accepts and saves order "+str(index))
		if app.run.revision!=previous.revision+1 or not app.save_warning.is_empty(): break
		if command.kind=="enter":
			var location: Dictionary = app.campaign.locations[int(app.run.stage)]
			visited.append(location.id)
			if location.get("leader",false) or location.id in ["lorelei","champion","legendary-birds","legendary-origin"]: await capture(app,directory,location.id)
			print("PLAYTHROUGH "+str(index)+" "+str(location.id))
			FileAccess.open(directory.path_join("playthrough-progress.json"),FileAccess.WRITE).store_string(JSON.stringify({"orders":index,"visited":visited,"failures":failures,"seconds":(Time.get_ticks_msec()-started)/1000.0}))
		if index%24==0: await app.get_tree().process_frame
	check(app.run.phase=="ending" and app.run.cleared.size()==58,"All58 natural locations and both legendary encounters completed")
	check(ReviewStore.equivalent(app.run,expected),"Executable/UI final state matches complete natural journal")
	var before_load: Dictionary = app.run.duplicate(true)
	app._load_game(); await settle(app)
	check(ReviewStore.equivalent(app.run,before_load),"Complete UI campaign reloads with identical outcome and RNG")
	check(app.run.medals.size()==8,"All eight medals retained")
	await capture(app,directory,"complete-kanto")
	var report: Dictionary = {"assertions":assertions,"failures":failures,"screenshots":screenshots,"campaignEdition":app.run.edition,"stateHash":JSON.stringify(app.run,"",true,true).sha256_text(),"visited":visited,"orders":app.transactions.size(),"medals":app.run.medals.size(),"reloadMsec":app.last_load_msec,"seconds":(Time.get_ticks_msec()-started)/1000.0,"scope":"Complete natural legal journal replayed through native UI with per-order persistence, final reload and real rendering; automated, not external human testing."}
	FileAccess.open(directory.path_join("playthrough-ui-result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("QA playthrough "+JSON.stringify({"assertions":assertions,"failures":failures})); app.get_tree().quit(0 if failures.is_empty() else 1)
