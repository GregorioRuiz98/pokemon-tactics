extends "res://ui/qa_context.gd"

func trace(game: RefCounted, value: String) -> Array:
	var sample: Dictionary = game.create(value,1)
	var result: Array = []
	for stage: int in 3:
		sample.stage = stage
		var species_id: int = game.pick(sample,"")
		var pool: Array = game.progression.data.encounters[game.locations[stage].captureTable]
		check(pool.any(func(entry):return int(entry.speciesId)==species_id),"Seeded capture belongs to its local table")
		check(not game.progression.species[species_id].legendary and not game.progression.species[species_id].mythical,"Seeded route reward excludes legendary Pokemon")
		result.append([species_id,int(sample.captureLevel)])
	return result

func run(app: Control, directory: String) -> void:
	DirAccess.make_dir_recursive_absolute(directory)
	app.get_window().gui_embed_subwindows = true
	app.store = Store.new(directory.path_join("oak-only.json"))
	app._show_oak()
	await settle(app)
	var original: String = app.journey_seed.text
	check(original.begins_with("kanto-") and original.length()<=64,"Oak generates a usable seed automatically")
	var generated: Dictionary = {}
	for index: int in 64: generated[app._generate_seed()] = true
	check(generated.size()==64,"Sixty-four generated seeds are different")
	app._refresh()
	await settle(app)
	check(app.journey_seed.text==original,"Presentation refresh preserves the chosen seed")
	await click(app,app.travel_buttons.random_seed)
	check(app.journey_seed.text!=original and app.run.is_empty() and app.transactions.is_empty(),"Generate another changes only the unstarted seed")
	var clipboard: String = DisplayServer.clipboard_get()
	app.journey_seed.text = "  Equipo-Ñ-42  "
	await click(app,app.travel_buttons.copy_seed)
	check(DisplayServer.clipboard_get()=="Equipo-Ñ-42","Copy exposes the normalized manual seed")
	DisplayServer.clipboard_set(clipboard)
	app._refresh()
	await settle(app)
	check(app.journey_seed.text=="  Equipo-Ñ-42  ","Editing survives UI refresh without silently changing the seed")
	for size: Vector2i in [Vector2i(1024,720),Vector2i(1280,900)]:
		app.get_window().size = size
		await settle(app)
		check(app.travel_buttons.random_seed.get_global_rect().end.x<=app.size.x and app.journey_seed.size.x>100,"Seed controls fit the window")
		check(app.travel_buttons.starter7.get_global_rect().end.y<=app.size.y,"Starter choices remain inside the window")
		await capture(app,directory,"oak-seed-"+str(size.x))
	app.journey_seed.text = "   "
	await click(app,app.travel_buttons.starter1)
	check(app.run.seed.begins_with("kanto-") and app.run.seed!="kanto-14","Empty manual seed generates fresh randomness instead of the old fixed fallback")
	var before: Dictionary = app.run.duplicate(true)
	clipboard = DisplayServer.clipboard_get()
	app._menu_selected(15)
	check(DisplayServer.clipboard_get()==app.run.seed and Store.equivalent(before,app.run) and app.transactions.is_empty(),"Campaign menu copies the persisted seed without changing state or PRNG")
	DisplayServer.clipboard_set(clipboard)
	app._show_oak()
	check(app.journey_seed.text!=before.seed,"Another visit for a new game receives a fresh seed")
	app._open_title()
	check(Store.equivalent(before,app.run),"Cancelling Oak restores the existing campaign exactly")
	var game: RefCounted = Journey.new(22)
	var traces: Dictionary = {}
	var route_species: Dictionary = {}
	for index: int in 64:
		var value: String = "seed-capture-%02d" % index
		var sequence: Array = trace(game,value)
		check(sequence==trace(game,value),"Same seed repeats the three local draws")
		traces[JSON.stringify(sequence)] = true
		route_species[int(sequence[0][0])] = true
		var gym: Dictionary = game.create(value,1)
		gym.stage = 3
		check(game.pick(gym,"")==95,"Brock keeps his guaranteed Onix reward")
	check(traces.size()>1 and route_species.size()>1,"Different fixed seeds vary capture sequences and Route 1 species")
	var rewards: Array = []
	for attempt: int in 2:
		app.store = Store.new(directory.path_join("natural-%d.json" % attempt))
		app._show_oak()
		app.journey_seed.text = "tactics-1"
		await click(app,app.travel_buttons.starter1)
		check(app.run.seed=="tactics-1","Oak uses the exact explicit seed")
		app.travel_buttons.enter.pressed.emit()
		for order: int in 220:
			if app.run.phase!="battle": break
			app._event({"kind":"battle","order":app.rules.choose_command(app.state),"at":app.run.revision})
		check(app.run.phase=="capture","Natural first encounter reaches its saved capture")
		if app.run.phase!="capture": break
		rewards.append(app.run.reward.duplicate(true))
		before = app.run.duplicate(true)
		app._load_game()
		check(Store.equivalent(before,app.run),"Reload preserves complete pending capture and PRNG")
	check(rewards.size()==2 and Store.equivalent(rewards[0],rewards[1]),"Same seed and orders reproduce the natural captured Pokemon")
	var report: Dictionary = {"assertions":assertions,"failures":failures,"seedProbes":64,"distinctCaptureTraces":traces.size(),"route1Species":route_species.keys().size(),"naturalCaptures":rewards.map(func(reward):return int(reward.speciesId)),"scope":"64 isolated local-table probes plus two actual Route 1 battles; generated seed values and clipboard contents are not logged","screenshots":screenshots}
	FileAccess.open(directory.path_join("seeds-ui-result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("QA seeds "+JSON.stringify(report))
	app.get_tree().quit(0 if failures.is_empty() else 1)
