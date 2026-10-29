extends "res://ui/qa_context.gd"

const Ledger = preload("res://core/relief_store.gd")

func layout(app: Control) -> void:
	for frame: int in 5: await app.get_tree().process_frame

func run(app: Control, directory: String) -> void:
	app.get_window().gui_embed_subwindows = true
	app.store = Ledger.new(directory.path_join("dex-natural-%d.json"%Time.get_ticks_usec()))
	await click(app,app.title_screen.controls.new)
	app.journey_seed.text = "dex-dialog-regression"
	await click(app,app.travel_buttons.starter1)
	await click(app,app.travel_buttons.enter)
	await click(app,app.adventure.start_button)
	var original: Dictionary = app.run.duplicate(true)
	var journal: Array = app.transactions.duplicate(true)
	for dimensions: Vector2i in [Vector2i(1280,900),Vector2i(1024,720)]:
		app.get_window().size = dimensions
		app.input_profile.set_preference("textScale",150 if dimensions.x==1024 else 100)
		app._apply_preferences()
		app._open_collection(); await layout(app)
		var trainer: AcceptDialog = app.trainer.dialog
		var browser: VBoxContainer = trainer.dex_browser
		for species: int in [1,25,151]:
			browser.query.text = str(species); browser.render(); await layout(app)
			var button: Button = browser.controls[species]
			button.grab_focus(); await key(app,KEY_ENTER,trainer); await layout(app)
			var detail: ConfirmationDialog = trainer.species_detail
			check(detail!=null and detail.visible and trainer.visible,"Nested species detail visible "+str(species))
			if detail==null: continue
			check(detail.get_parent()==trainer,"Exclusive detail belongs to trainer window")
			check(app.action_review==null or not app.action_review.visible,"Global action dialog stays closed")
			check(not detail.callback.is_valid(),"Species inspection cannot mutate campaign")
			check(detail.title.begins_with("#%03d"%species),"Correct species title")
			check(detail.size.x<=app.get_window().size.x and detail.size.y<=app.get_window().size.y,"Detail fits screen "+str(dimensions))
			check(detail.get_ok_button().get_global_rect().end.y<=detail.size.y,"Close control stays reachable")
			if species==151: await capture(app,directory,"dex-detail-%d"%dimensions.x)
			await key(app,KEY_ESCAPE,detail); await layout(app)
			check(not detail.visible and trainer.visible,"Escape closes only detail")
			check(trainer.gui_get_focus_owner()==button,"Focus returns to selected species")
			check(browser.query.text==str(species) and browser.matches==[species],"Search remains intact")
		# Mouse close and parent hide must not strand an exclusive child window.
		await click(app,browser.controls[151]); await layout(app)
		await click(app,trainer.species_detail.get_ok_button()); await layout(app)
		check(not trainer.species_detail.visible and trainer.visible,"Mouse returns to Pokédex")
		await click(app,browser.controls[151]); await layout(app)
		trainer.hide(); await layout(app)
		check(not trainer.species_detail.visible,"Closing parent also hides child")
		check(Ledger.equivalent(original,app.run) and app.transactions==journal,"Inspection preserves battle, RNG and journal")
		app._open_collection(); await layout(app)
		await key(app,KEY_ESCAPE,trainer); await layout(app)
		check(not trainer.visible and not app._modal_open(),"Escape returns to battle")
		check(app.get_viewport().gui_get_focus_owner()==app.board,"Battle focus restored")
	var report: Dictionary = {"assertions":assertions,"failures":failures,"screenshots":screenshots,"campaignEdition":app.run.edition,"stateHash":JSON.stringify(app.run,"",true,true).sha256_text(),"scope":"Natural battle plus read-only Pokédex inspection: nested modal, keyboard/mouse, focus, search, parent closure,1280/100% and1024/150%. Automated same-PC test."}
	FileAccess.open(directory.path_join("dex-dialog.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("QA dex-dialog "+JSON.stringify({"assertions":assertions,"failures":failures})); app.get_tree().quit(0 if failures.is_empty() else 1)
