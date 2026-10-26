extends "res://ui/qa_context.gd"

const FixedStore = preload("res://core/sleep_store.gd")

func layout(app: Control) -> void:
	for frame: int in 6: await app.get_tree().process_frame

func run(app: Control, directory: String) -> void:
	app.get_window().gui_embed_subwindows = true
	app.input_profile = Profile.new(directory.path_join("sleep-controls-%d.json"%Time.get_ticks_usec()))
	app.board.input_profile = app.input_profile; app.controls_dialog.profile = app.input_profile
	app.store = FixedStore.new(directory.path_join("sleep-ui-%d.json"%Time.get_ticks_usec()))
	await click(app,app.title_screen.controls.new)
	app.journey_seed.text = "sleep-ui"
	await click(app,app.travel_buttons.starter4)
	check(app.run.edition==24,"New game uses correction")
	# Exercise normal loading of the previous release, including automatic backup.
	var old: RefCounted = preload("res://core/power_run.gd").new()
	check(app.store.save(old.create("sleep-ui",4),[],"current").ok,"Previous release save fixture")
	app._load_game(); await layout(app)
	check(app.run.edition==24 and app.transactions.size()==1,"Loading23 applies correction automatically")
	check(Array(DirAccess.get_files_at(directory)).any(func(name):return name.begins_with(app.store.file_path.get_file()+".before-new-")),"Old save backed up")
	await click(app,app.travel_buttons.enter); await click(app,app.adventure.start_button)
	var original: Dictionary = app.run.duplicate(true)
	var sleeper: Dictionary = app.rules.active(app.state)
	sleeper.status = {"kind":"sleep","remaining":2}
	app._refresh(); await layout(app)
	var before: Dictionary = app.run.duplicate(true)
	check(app.board.available.is_empty(),"No movement squares while asleep")
	check("Dormido" in app.actor_info.text,"HUD explains blocked movement")
	var destination: Dictionary = {"x":sleeper.x+1,"y":sleeper.y}
	await tile(app,destination)
	check(FixedStore.equivalent(before,app.run),"Mouse cannot move sleeper")
	app.board.cursor = Vector2i(destination.x,destination.y); app.board.grab_focus()
	await key(app,KEY_ENTER)
	check(FixedStore.equivalent(before,app.run),"Keyboard cannot move sleeper")
	app._commit({"kind":"move","destination":destination}); await layout(app)
	check(FixedStore.equivalent(before,app.run),"Rejected command spends nothing and consumes no RNG")
	await capture(app,directory,"sleep-blocked")
	sleeper.status = null; app._refresh(); await layout(app)
	check(not app.board.available.is_empty(),"Movement squares return on wake")
	await capture(app,directory,"awake")
	# Restore the explicit status fixture before continuing the real journal.
	app.run = original; app.state = app.run.battle; app._refresh()
	for step: int in 200:
		if app.run.phase!="battle": break
		app._event({"kind":"battle","order":app.rules.choose_command(app.state),"at":app.run.revision})
	check(app.run.phase=="capture","Natural opening reaches capture")
	if app.run.phase=="capture": await click(app,app.travel_buttons.capture)
	before = app.run.duplicate(true)
	app._load_game(); await layout(app)
	check(FixedStore.equivalent(before,app.run),"Patched history loads exactly")
	app._glossary(); await layout(app)
	check("no puedes moverte ni actuar" in app.action_review.content.text,"Optional rules explain sleep")
	await key(app,KEY_ESCAPE,app.action_review)
	var report: Dictionary = {"assertions":assertions,"failures":failures,"screenshots":screenshots,"campaignEdition":app.run.edition,"stateHash":JSON.stringify(app.run,"",true,true).sha256_text(),"scope":"Explicit sleeping UI fixture restored before natural campaign replay; mouse, keyboard, command rejection, wake, automatic23→24 backup and load."}
	FileAccess.open(directory.path_join("sleep-ui-result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("QA sleep "+JSON.stringify({"assertions":assertions,"failures":failures})); app.get_tree().quit(0 if failures.is_empty() else 1)
