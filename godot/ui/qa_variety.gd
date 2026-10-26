extends "res://ui/qa_context.gd"

const CurrentStore = preload("res://core/profile_campaign_store.gd")
const Tactics = preload("res://ui/tactical_loadouts.gd")
var natural_hash: String = ""

func layout(app: Control) -> void:
	for frame: int in 6: await app.get_tree().process_frame

func run(app: Control, directory: String) -> void:
	app.get_window().gui_embed_subwindows = true
	app.input_profile = Profile.new(directory.path_join("variety-controls-%d.json" % Time.get_ticks_usec()))
	app.board.input_profile = app.input_profile; app.controls_dialog.profile = app.input_profile
	app.store = CurrentStore.new(directory.path_join("variety-natural-%d.json" % Time.get_ticks_usec()))
	app._show_oak(); app.journey_seed.text = "kecleon-ui"
	await click(app,app.travel_buttons.starter4)
	app._set_hub_mode("team"); app._set_member_view("moves"); await layout(app)
	check(app.travel_buttons.has("role_0") and app.travel_buttons.has("role_1"),"Both contextual roles appear beside prepared slots")
	var before: Dictionary = app.run.duplicate(true)
	var journal: Array = app.transactions.duplicate(true)
	for mode: int in 2:
		app.travel_buttons["role_"+str(mode)].grab_focus(); await key(app,KEY_ENTER)
		check(app.action_review.visible and app.action_review.callback.is_valid(),"Keyboard opens an actionable role comparison")
		check(app.action_review.content.text.contains("NUEVO:") and app.action_review.content.text.contains("El básico se conserva"),"Comparison includes current/new kit and the neutral basic")
		await key(app,KEY_ESCAPE,app.action_review)
		check(CurrentStore.equivalent(before,app.run) and app.transactions==journal,"Cancel role proposal preserves all state and journal")
	await click(app,app.travel_buttons.role_1)
	var proposal: Dictionary = Tactics.propose(app.campaign.progression,app.run.party[0],1)
	var expected: Dictionary = app.campaign.transact(before,{"kind":"loadout","member":1,"moves":proposal.moves,"at":before.revision})
	await click(app,app.action_review.get_ok_button())
	check(expected.ok and CurrentStore.equivalent(expected.state,app.run),"Confirm saves exactly the existing atomic loadout order")
	check(app.run.rng==before.rng and app.run.money==before.money and app.run.party[0].hp==before.party[0].hp,"Applying a role is free and preserves RNG and HP")
	check(app.transactions.size()==journal.size()+1,"Exactly one order is recorded for a whole kit")
	var loaded: Dictionary = CurrentStore.new(app.store.file_path).load_campaign(app.campaign)
	check(loaded.ok and CurrentStore.equivalent(loaded.state,app.run),"Role proposal is replayable with the original edition")
	await click(app,app.travel_buttons.role_0)
	var stale_callback: Callable = app.action_review.callback
	app.action_review.hide()
	app._event({"kind":"loadout","member":1,"moves":app.run.party[0].moves,"at":app.run.revision})
	before = app.run.duplicate(true)
	stale_callback.call(); await layout(app)
	check(CurrentStore.equivalent(before,app.run),"A stale reviewed proposal cannot overwrite a newer order")
	await click(app,app.travel_buttons.team_tools)
	check(app.action_review.visible and not app.action_review.callback.is_valid(),"Team tools is a read-only dialog")
	check(app.action_review.content.text.contains("Sin preparar:") and app.action_review.content.text.contains("Charmander"),"Team report uses actual prepared moves and identifies missing tools")
	await capture(app,directory,"variety-team-tools")
	await key(app,KEY_ESCAPE,app.action_review)
	check(CurrentStore.equivalent(before,app.run),"Inspecting team tools does not change the campaign")
	for dimensions: Vector2i in [Vector2i(1024,720),Vector2i(1280,900)]:
		app.get_window().size = dimensions
		for scale_value: int in [100,125,150]:
			app.input_profile.set_preference("textScale",scale_value); app._apply_preferences(); await layout(app)
			for mode: int in 2:
				var button: Button = app.travel_buttons["role_"+str(mode)]
				button.grab_focus(); await layout(app)
				check(button.has_focus() and button.is_visible_in_tree(),"Role proposal is focusable at %d/%d/%d" % [dimensions.x,scale_value,mode])
				check(button.get_global_rect().position.x>=0 and button.get_global_rect().end.x<=app.size.x,"Role label fits panel width")
			if scale_value==150: await capture(app,directory,"variety-roles-%d-150" % dimensions.x)
	app.get_window().size = Vector2i(1280,900); app.input_profile.set_preference("textScale",100); app._apply_preferences(); await layout(app)
	for filter: int in 6:
		var option: OptionButton = app.travel_buttons.move_tactics
		option.select(filter); option.item_selected.emit(filter); await layout(app)
		var wanted: int = 0; var actual: int = 0
		for identity: String in app.run.party[0].knownMoves:
			var match_filter: bool = Tactics.matches(app.campaign.progression.data.moves[identity],filter)
			if match_filter: wanted += 1
			if app.travel_buttons.has("move_"+identity): actual += 1
			check(app.travel_buttons.has("move_"+identity)==match_filter,"Tactical filter shows actual learned functionality")
		check(wanted==actual,"Filtered library has exact count")
		check(CurrentStore.equivalent(before,app.run),"Tactical filtering is read-only")
	app.move_library.tactical_filter = 0; app._refresh(); await layout(app)
	app._set_hub_mode("overview"); await layout(app)
	await click(app,app.travel_buttons.enter); await click(app,app.adventure.start_button)
	for step: int in 250:
		if app.run.phase!="battle": break
		app._event({"kind":"battle","order":app.rules.choose_command(app.state),"at":app.run.revision})
	check(app.run.phase=="capture","Natural battle with a player-selected role reaches capture")
	if app.run.phase!="capture": finish(app,directory); return
	await click(app,app.travel_buttons.capture); await layout(app)
	check(app.kecleon.using_scene(app),"Kecleon remains integrated after the role-enabled opening")
	before = app.run.duplicate(true)
	app.kecleon.select(app,0)
	check(app.kecleon.detail.text.contains("Charmander:") and app.kecleon.detail.text.contains("Añade"),"Compatible MT explains a concrete new tool or coverage")
	await capture(app,directory,"variety-shop-advice")
	check(CurrentStore.equivalent(before,app.run),"TM advice does not buy, teach or consume RNG")
	natural_hash = JSON.stringify(app.run,"",true,true).sha256_text()
	app._load_game(); await layout(app)
	check(CurrentStore.equivalent(before,app.run),"Natural run and loadout survive reload")
	finish(app,directory)

func finish(app: Control, directory: String) -> void:
	var result: Dictionary = {"assertions":assertions,"failures":failures,"screenshots":screenshots,"stateHash":JSON.stringify(app.run,"",true,true).sha256_text(),"naturalStateHash":natural_hash,"campaignEdition":app.run.get("edition",0),"scope":"Natural starter, role comparison/cancel/confirm/stale revision, tactical filters, team tools, keyboard/scales100/125/150, Route1/capture/Kecleon advice and replay. Existing edition and learnsets."}
	FileAccess.open(directory.path_join("variety-ui-result.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("QA variety "+JSON.stringify({"assertions":assertions,"failures":failures})); app.get_tree().quit(0 if failures.is_empty() else 1)
