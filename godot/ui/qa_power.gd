extends "res://ui/qa_context.gd"

const CurrentStore = preload("res://core/power_store.gd")
const Points = preload("res://core/power_points.gd")
const Info = preload("res://ui/move_info.gd")

func layout(app: Control) -> void:
	for frame: int in 6: await app.get_tree().process_frame

func run(app: Control, directory: String) -> void:
	app.get_window().gui_embed_subwindows = true
	app.input_profile = Profile.new(directory.path_join("power-controls-%d.json"%Time.get_ticks_usec()))
	app.board.input_profile = app.input_profile; app.controls_dialog.profile = app.input_profile
	app.store = CurrentStore.new(directory.path_join("power-natural-%d.json"%Time.get_ticks_usec()))
	await click(app,app.title_screen.controls.new)
	app.journey_seed.text = "power-ui"
	await click(app,app.travel_buttons.starter4)
	check(app.run.edition==23,"New game uses PP edition")
	for definition: Dictionary in app.campaign.progression.data.moves.values():
		check("Equipar:" in Info.summary(definition) and " PT" not in Info.details(definition),"Equipment cost visible without old PT: "+definition.id)
	app._set_hub_mode("team"); app._set_member_view("moves"); await layout(app)
	check(app.hub_parts.details.get_child_count()>0,"Move library open")
	await click(app,app.travel_buttons.move_slot_0)
	check(app.move_library.selected_slot==0,"Mouse selects equipment slot")
	app.travel_buttons.move_slot_1.grab_focus(); await key(app,KEY_ENTER)
	check(app.move_library.selected_slot==1,"Keyboard selects equipment slot")
	check("PP equipados:" in preload("res://ui/qa_copy.gd").new().visible_text(app.hub_parts.details),"Equipment budget remains visible")
	check("PT" not in Info.details(app.rules.profiles[4].library.basic.definition),"Basic contains no legacy resource instructions")
	await capture(app,directory,"equipment")
	app.input_profile.set_preference("textScale",150); app._apply_preferences(); await layout(app)
	await capture(app,directory,"equipment-150")
	app.input_profile.set_preference("textScale",100); app._apply_preferences()
	app._set_hub_mode("overview"); await layout(app)
	await click(app,app.travel_buttons.enter)
	check(app.state.restorativeTiles.size()==2,"Restorative tiles installed")
	check(not app.actor_tp.visible and "PT" not in app.actor_info.text,"No consumable bar in deployment")
	app._hover_tile(app.state.restorativeTiles[0]); await layout(app)
	check("Manantial" in app.hint.text,"Mouse hover explains cure")
	await capture(app,directory,"restorative-tiles")
	await click(app,app.adventure.start_button)
	check(not app.actor_tp.visible and "PT" not in app.actor_info.text,"No consumable bar in combat")
	for button: Button in app.action_buttons.values(): check("PT" not in button.text and "usos" not in button.text,"Actions show no execution cost or recovery counter")
	await capture(app,directory,"combat")
	for step: int in 200:
		if app.run.phase!="battle": break
		app._event({"kind":"battle","order":app.rules.choose_command(app.state),"at":app.run.revision})
	check(app.run.phase=="capture","Natural encounter still reaches capture")
	if app.run.phase=="capture":
		await click(app,app.travel_buttons.capture); await layout(app)
		await capture(app,directory,"kecleon")
	var before: Dictionary = app.run.duplicate(true)
	app._glossary(); await layout(app)
	check("limitados por PP al equipar" in app.action_review.content.text and "atributos durante el combate" in app.action_review.content.text,"Optional rules describe PP and stat persistence")
	await key(app,KEY_ESCAPE,app.action_review)
	app._load_game(); await layout(app)
	check(CurrentStore.equivalent(before,app.run),"UI save/reload preserves all new rules")
	var code: String = preload("res://core/power_challenge.gd").encode(app.run)
	check(code.begins_with("KT31:") and preload("res://core/power_challenge.gd").decode(code).edition==23,"Challenge carries new edition")
	var result: Dictionary = {"assertions":assertions,"failures":failures,"screenshots":screenshots,"campaignEdition":app.run.edition,"stateHash":JSON.stringify(app.run,"",true,true).sha256_text()}
	FileAccess.open(directory.path_join("power-ui-result.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("QA power "+JSON.stringify({"assertions":assertions,"failures":failures})); app.get_tree().quit(0 if failures.is_empty() else 1)
