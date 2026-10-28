extends "res://ui/qa_context.gd"

const Current = preload("res://core/relief_run.gd")
const Ledger = preload("res://core/relief_store.gd")
var gallery: Array = []
var natural_hash: String = ""

func layout(app: Control) -> void:
	for frame: int in 2: await app.get_tree().process_frame

func run(app: Control, directory: String) -> void:
	app.get_window().gui_embed_subwindows = true
	app.store = Ledger.new(directory.path_join("natural-%d.json"%Time.get_ticks_usec()))
	await click(app,app.title_screen.controls.new)
	app.journey_seed.text = "relief-ui"
	await click(app,app.travel_buttons.starter4)
	check(app.run.edition==30,"Oak starts new terrain edition")
	await click(app,app.travel_buttons.enter)
	check(app.state.combatEdition==25 and app.state.relief.id=="route-1","Native deployment uses new terrain")
	await capture(app,directory,"route-1-deployment")
	app.adventure.start_button.grab_focus(); await key(app,KEY_ENTER)
	check(not app.state.deployment,"Keyboard confirms deployment")
	for step: int in 500:
		if app.run.phase!="battle": break
		app._event({"kind":"battle","order":app.rules.choose_command(app.state),"at":app.run.revision})
	check(app.run.phase=="capture","Natural Route1 reaches capture")
	if app.run.phase=="capture":
		await click(app,app.travel_buttons.capture)
		var original: Dictionary = app.run.duplicate(true)
		natural_hash = JSON.stringify(original,"",true,true).sha256_text()
		await app._load_game(); await layout(app)
		check(Ledger.equivalent(original,app.run),"Natural capture/shop journal replays")
	app.combat_feedback.clear(); app.pending = {}; app.trainer.pending.clear(); app.trainer.notice.hide()
	# Rendering fixtures do not claim campaign victories or modify the natural save.
	for width: int in [16,24]:
		for index: int in app.campaign.locations.size():
			app.run = app.campaign.create("relief-gallery",1); app.run.mapSize = width; app.run.stage = index; app.run.phase = "battle"; app.run.party = []
			for species: int in [3,6,9,26,65,68]: app.run.party.append(app.campaign.progression.create_member(app.run.party.size()+1,species,"Rendering fixture",40))
			app.run.battle = app.rules.encounter(app.run,app.campaign.locations[index])
			app.state = app.run.battle; app._prepare_campaign_assets(); app._refresh(); app.board.fit_map(); await layout(app)
			app.adventure.toast_remaining = 0; app.adventure.toast.hide(); app.trainer.notice.hide()
			var identity: String = app.state.relief.id
			var original: Dictionary = app.run.duplicate(true)
			check(app.board.elevation_lift()==20,"Elevation projection "+identity+str(width))
			check(not app.board.prop_cache.is_empty(),"Thematic obstacles rendered "+identity+str(width))
			var rebuilds: int = app.board.terrain_rebuilds
			for redraw: int in 3: app.board.queue_redraw(); await app.get_tree().process_frame
			check(app.board.terrain_rebuilds==rebuilds,"Idle cache retained "+identity)
			for unit: Dictionary in app.state.units:
				var screen: Vector2 = app.board.center(unit)
				if app.board.play_area().has_point(screen): check(app.board.Movement.same(app.board.pick(screen),unit),"Raised unit picking "+identity+str(unit.id))
			if not app.board.prop_cache.is_empty():
				var prop: Dictionary = app.board.prop_cache[0]
				app.board.cursor = Vector2i(prop.x,prop.y); app.board.queue_redraw(); await layout(app)
				check(app.board.faded_props>0,"Cursor canopy transparency "+identity)
			check(Ledger.equivalent(original,app.run),"Drawing/selection consumes no state or RNG "+identity)
			gallery.append({"id":identity,"mapSize":width,"props":app.board.prop_cache.size()})
			if width==16 and identity in ["forest","brock","mt-moon","route-24","misty","ss-anne","rock-tunnel","pokemon-tower","silph-giovanni","sabrina","victory-road","legendary-birds","legendary-origin"]: await capture(app,directory,identity)
	app.get_window().size = Vector2i(1024,720); app.input_profile.set_preference("textScale",150); app._apply_preferences(); app.board.fit_map(); await layout(app)
	check(app.adventure.start_button.get_global_rect().end.x<=app.size.x and app.adventure.start_button.get_global_rect().end.y<=app.size.y,"Start button fits at1024/150%")
	await capture(app,directory,"small-150")
	var report: Dictionary = {"assertions":assertions,"failures":failures,"screenshots":screenshots,"gallery":gallery,"campaignEdition":app.run.edition,"naturalStateHash":natural_hash,"mapCatalogHash":FileAccess.get_file_as_string("res://data/relief-maps.json").sha256_text(),"scope":"Natural Route1/capture/shop/reload; native rendered fixtures for all58 maps at16/24, picking, cache, occlusion and1024/150%. Not a complete human campaign."}
	FileAccess.open(directory.path_join("relief-ui.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("QA relief "+JSON.stringify({"assertions":assertions,"failures":failures,"layouts":gallery.size()})); app.get_tree().quit(0 if failures.is_empty() else 1)
