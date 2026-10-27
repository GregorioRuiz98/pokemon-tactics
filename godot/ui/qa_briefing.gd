extends "res://ui/qa_context.gd"

const ReviewStore = preload("res://core/review_store.gd")

func layout(app: Control) -> void:
	for frame: int in 8: await app.get_tree().process_frame

func run(app: Control, directory: String) -> void:
	app.get_window().gui_embed_subwindows = true
	app.input_profile = Profile.new(directory.path_join("briefing-controls.json"))
	app.board.input_profile = app.input_profile; app.controls_dialog.profile = app.input_profile
	app.store = ReviewStore.new(directory.path_join("briefing-natural-%d.json"%Time.get_ticks_usec()))
	await capture(app,directory,"title-buttons")
	await click(app,app.title_screen.controls.new)
	app.journey_seed.text = "release-33-kanto"
	await click(app,app.travel_buttons.starter1)
	await click(app,app.travel_buttons.enter); await layout(app)
	var preview: RefCounted = app.encounter_preview
	var natural: Dictionary = app.run.duplicate(true)
	var journal: Array = app.transactions.duplicate(true)
	check(preview.panel.visible and app.state.deployment,"Rival roster appears automatically before first battle")
	check(preview.cards.size()==app.state.units.filter(func(u):return u.team=="enemy").size(),"One card per actual enemy")
	check(app.adventure.start_button.is_visible_in_tree(),"Start remains directly accessible without dismissing a modal")
	await capture(app,directory,"route-preview")
	await click(app,preview.cards[0]); await layout(app)
	check(preview.dialog.visible and app._modal_open(),"Mouse opens modal enemy details")
	check(preview.selected==app.state.units.filter(func(u):return u.team=="enemy")[0],"Details use exact generated stats and prepared moves")
	await capture(app,directory,"enemy-details")
	await key(app,KEY_ESCAPE,preview.dialog)
	check(not preview.dialog.visible and preview.cards[0].has_focus(),"Escape returns keyboard focus to enemy card")
	await key(app,KEY_ENTER); await layout(app)
	check(preview.dialog.visible,"Keyboard activates the same card")
	await key(app,KEY_ESCAPE,preview.dialog)
	check(ReviewStore.equivalent(app.run,natural),"Inspecting rivals consumes neither RNG nor transactions")
	app._load_game(); await layout(app)
	check(ReviewStore.equivalent(app.run,natural) and preview.panel.visible,"Reload preserves real opponents and prebattle preview")
	app.board.grab_focus(); await key(app,KEY_B); await layout(app)
	check(not app.state.deployment and not preview.panel.visible,"Start shortcut removes preview and begins battle")
	check(app.actor_portrait.get_parent().get_parent().get_parent().visible and app.hint.get_parent().visible,"Normal combat HUD restored")
	var saved_after_start: Dictionary = app.run.duplicate(true)
	# Presentation fixtures for every real encounter definition, not a played campaign.
	var covered: Array[String] = []
	for index: int in app.campaign.locations.size():
		var location: Dictionary = app.campaign.locations[index]
		app.run = natural.duplicate(true); app.run.stage = index
		app.run.battle = app.rules.encounter(app.run,location)
		app.run.battle.deployment = true; app.state = app.run.battle
		var before: Dictionary = app.run.duplicate(true)
		preview.refresh(app); await settle(app)
		var enemies: Array = app.state.units.filter(func(u):return u.team=="enemy")
		check(preview.cards.size()==enemies.size() and not enemies.is_empty(),"Preview covers all enemies: "+location.id)
		for position: int in enemies.size():
			check(preview.cards[position].text.contains(enemies[position].name) and preview.cards[position].text.contains("Nv. %d"%enemies[position].level),"Correct identity/level: "+location.id+"/"+str(position))
		check(ReviewStore.equivalent(app.run,before),"Pure preview: "+location.id)
		covered.append(location.id)
		if location.id.contains("brock") or index>=app.campaign.locations.size()-2:
			app._prepare_campaign_assets(); app._refresh(); await layout(app)
			await capture(app,directory,"encounter-"+location.id)
	# Small-window stress includes horizontal keyboard scrolling and a long details sheet.
	app.get_window().size = Vector2i(1024,768)
	app.input_profile.set_preference("textScale",150); app.input_profile.set_preference("highContrast",true)
	app._apply_preferences(); app._refresh(); await layout(app)
	preview.cards.back().grab_focus(); await layout(app)
	check(preview.scroll.scroll_horizontal>0 if preview.row.size.x>preview.scroll.size.x else true,"Focus scrolls overflowing enemy roster into view")
	check(preview.panel.get_global_rect().end.y<=app.size.y+1,"Large-text roster stays inside viewport")
	check(not preview.panel.get_global_rect().intersects(app.adventure.start_button.get_global_rect()),"Large-text preview never covers Start button")
	await capture(app,directory,"preview-1024-150")
	await key(app,KEY_ENTER); await layout(app)
	check(preview.dialog.visible,"Enemy sheet works at150 percent with keyboard")
	await capture(app,directory,"details-1024-150")
	await key(app,KEY_ESCAPE,preview.dialog)
	app.get_window().size = Vector2i(1280,900)
	app.input_profile.set_preference("textScale",100); app.input_profile.set_preference("highContrast",false)
	app._apply_preferences()
	app.run = natural; app.state = app.run.battle; app.transactions = journal
	app._prepare_campaign_assets(); app._refresh(); await layout(app)
	check(app.camera_bar.size.y<65,"Toolbar shrinks after restoring normal text size")
	await capture(app,directory,"preview-restored")
	app._load_game(); await layout(app)
	check(ReviewStore.equivalent(app.run,saved_after_start),"Synthetic encounter inspections never overwrite saved campaign")
	var report: Dictionary = {"assertions":assertions,"failures":failures,"screenshots":screenshots,"campaignEdition":app.run.edition,"stateHash":JSON.stringify(app.run,"",true,true).sha256_text(),"encounters":covered,"scope":"Native pointer/keyboard, natural prebattle save/reload, presentation fixtures for all encounters; no human or external hardware claim."}
	FileAccess.open(directory.path_join("briefing-ui-result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("QA briefing "+JSON.stringify({"assertions":assertions,"failures":failures})); app.get_tree().quit(0 if failures.is_empty() else 1)
