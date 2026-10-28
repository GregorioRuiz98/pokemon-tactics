extends "res://ui/qa_context.gd"

const Ledger = preload("res://core/closing_store.gd")

func run(app: Control, directory: String) -> void:
	app.get_window().gui_embed_subwindows = true
	app.input_profile = Profile.new(directory.path_join("usability-%d.json"%Time.get_ticks_usec()))
	app.board.input_profile = app.input_profile; app.controls_dialog.profile = app.input_profile
	app.input_profile.set_preference("reducedMotion",true); app._apply_preferences()
	app.store = Ledger.new(directory.path_join("usability-save-%d.json"%Time.get_ticks_usec()))
	await click(app,app.title_screen.controls.new)
	app._glossary(); await settle(app)
	check(app.action_review.content.text.contains("PP al equipar") and not app.action_review.content.text.contains("0 PT"),"Help before starting uses current rules")
	await key(app,KEY_ESCAPE,app.action_review)
	await click(app,app.travel_buttons.collection)
	var browser: VBoxContainer = app.trainer.dialog.dex_browser
	browser.query.grab_focus()
	for code: int in [KEY_M,KEY_E,KEY_W,KEY_T,KEY_W,KEY_O]: await key(app,code,app.trainer.dialog)
	check(browser.query.text=="mewtwo" and browser.matches==[150],"Real keyboard typing filters Pokédex")
	await key(app,KEY_ESCAPE,app.trainer.dialog)
	check(not app.trainer.dialog.visible,"Escape returns from collection")
	app.journey_seed.text = "release-33-kanto"
	await click(app,app.travel_buttons.starter1)
	await click(app,app.travel_buttons.enter); await click(app,app.adventure.start_button)
	for step: int in 40:
		if app._player_turn(): break
		app._event({"kind":"battle","order":app.rules.choose_command(app.state),"at":app.run.revision})
	check(app._player_turn(),"Natural battle reaches allied input")
	var before: Dictionary = app.run.duplicate(true)
	await key(app,KEY_A)
	check(app.action_page and app.get_viewport().gui_get_focus_owner()==app.action_buttons.basic,"Keyboard opens commands with useful focus")
	await key(app,KEY_ESCAPE)
	check(not app.action_page and Ledger.equivalent(app.run,before),"Cancel commands is pure")
	await key(app,KEY_F2)
	check(app.controls_dialog.visible,"Keyboard reaches remappable controls")
	await key(app,KEY_ESCAPE,app.controls_dialog)
	check(not app.controls_dialog.visible and app.get_viewport().gui_get_focus_owner()==app.board,"Controls restore board focus")
	var actor: Dictionary = app.rules.active(app.state)
	var origin: Vector2i = Vector2i(actor.x,actor.y)
	var routes: Array = app.rules.movement_routes(app.state,actor,actor.remaining).values()
	var direction: Dictionary = {}
	for entry: Array in [[KEY_RIGHT,1,0],[KEY_LEFT,-1,0],[KEY_UP,0,-1],[KEY_DOWN,0,1]]:
		var point: Dictionary = {"x":origin.x+entry[1],"y":origin.y+entry[2]}
		if routes.any(func(route):return route.path[-1].x==point.x and route.path[-1].y==point.y): direction = {"key":entry[0],"point":point}; break
	check(not direction.is_empty(),"Natural allied unit has adjacent legal move")
	if direction.is_empty(): finish(app,directory); return
	app.board.cursor = origin; app.board.focus_point(actor); app.board.grab_focus(); await settle(app)
	await key(app,int(direction.key)); await key(app,KEY_ENTER)
	check(app.run.revision==before.revision+1 and app.state.moved,"Arrow and Enter execute movement directly")
	await key(app,KEY_R)
	actor = app.rules.active(app.state)
	check(Vector2i(actor.x,actor.y)==origin and not app.state.moved and app.state.rng==before.battle.rng,"Keyboard rectification restores only movement without RNG")
	await tile(app,direction.point)
	check(app.state.moved,"Mouse executes legal tile movement")
	await click(app,app.buttons.undo)
	check(not app.state.moved and app.rules.active(app.state).hp==before.battle.units.filter(func(unit):return unit.id==actor.id)[0].hp,"Mouse rectification preserves HP")
	before = app.run.duplicate(true)
	app.board.grab_focus(); await key(app,KEY_F); await key(app,KEY_UP)
	check(Ledger.equivalent(app.run,before),"Facing preview does not submit a turn")
	var facing: int = int(app.facing_choice)
	var expected: Dictionary = app.campaign.transact(before,{"kind":"battle","order":{"kind":"finish","facing":facing},"at":before.revision})
	await key(app,KEY_ENTER)
	check(expected.ok and Ledger.equivalent(app.run,expected.state),"Keyboard finishes with selected facing")
	for step: int in 260:
		if app.run.phase!="battle": break
		app._event({"kind":"battle","order":app.rules.choose_command(app.state),"at":app.run.revision})
	check(app.run.phase=="capture","Natural controls scenario wins opening")
	if app.run.phase!="capture": finish(app,directory); return
	await click(app,app.travel_buttons.capture)
	var offers: Array = app.campaign.collection_offers(app.run)
	await click(app,app.travel_buttons.shop_recruitment)
	check(offers.size()==3 and offers.all(func(offer):return app.travel_buttons.has("adopt_"+str(offer.speciesId))),"Recruitment presents three visible quotes")
	await click(app,app.travel_buttons.shop_team)
	await click(app,app.travel_buttons.detail_profile)
	check(not app.travel_buttons.has("move_slot_0"),"Hidden move library is not constructed on profile page")
	if app.travel_buttons.has("train-xp") and not app.travel_buttons["train-xp"].disabled:
		var level: int = int(app.run.party[0].level)
		await click(app,app.travel_buttons["train-xp"]); await click(app,app.action_review.get_ok_button())
		check(app.run.party[0].level==level+1,"Training through team profile still works")
	check(app.campaign.collection_offers(app.run)==offers,"Visible shop quotes survive actual training")
	await click(app,app.travel_buttons.detail_moves)
	for slot: int in 4: check(app.travel_buttons.has("move_slot_"+str(slot)),"Active moves retain prepared slot "+str(slot))
	await click(app,app.travel_buttons.detail_traits)
	check(app.hub_parts.traits.visible,"Traits tab builds its content on demand")
	app.get_window().size = Vector2i(1024,720)
	app.input_profile.set_preference("textScale",150); app.input_profile.set_preference("highContrast",true); app._apply_preferences(); app._refresh(); await settle(app)
	await capture(app,directory,"team-traits-1024-150")
	check(app.travel_buttons.detail_moves.get_global_rect().end.x<=app.size.x,"Team tabs fit small window and large text")
	await click(app,app.travel_buttons.detail_moves); await capture(app,directory,"team-moves-1024-150")
	check(app.travel_buttons.move_slot_0.visible,"Equipped moves remain visible at150percent")
	var saved: Dictionary = app.run.duplicate(true)
	app._set_hub_mode("overview"); app.shop_tab = "gear"; app.run.stock = []; app._refresh(); await settle(app)
	check(app.kecleon.cards.is_empty(),"Explicit empty-stock presentation does not index -1")
	app.run = saved; await app._load_game(); await settle(app)
	check(Ledger.equivalent(app.run,saved) and app.save_warning.is_empty(),"Presentation and accessibility changes never replace natural save")
	check(not app.loading_overlay.visible and not app.title_loading,"Loading overlay closes after successful load")
	finish(app,directory)

func finish(app: Control, directory: String) -> void:
	var report: Dictionary = {"assertions":assertions,"failures":failures,"screenshots":screenshots,"campaignEdition":app.run.get("edition",0),"stateHash":JSON.stringify(app.run,"",true,true).sha256_text(),"scope":"Real keyboard/mouse movement, rectification, facing, opening victory, shop/team training, persistent quotes and1024x720/150percent. Empty-stock case is an explicit unsaved presentation fixture. No human/external hardware claim."}
	FileAccess.open(directory.path_join("closing-usability.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("QA closing-usability "+JSON.stringify({"assertions":assertions,"failures":failures})); app.get_tree().quit(0 if failures.is_empty() else 1)
