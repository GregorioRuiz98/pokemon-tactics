extends "res://ui/qa_context.gd"

const CurrentStore = preload("res://core/kanto_campaign_store.gd")
const Text = preload("res://ui/concise_copy.gd")
const Info = preload("res://ui/move_info.gd")

func layout(app: Control) -> void:
	for frame: int in 6: await app.get_tree().process_frame

func visible_text(node: Node) -> String:
	var result: String = ""
	if node is Label and node.is_visible_in_tree(): result = node.text+"\n"
	for child: Node in node.get_children(): result += visible_text(child)
	return result

func run(app: Control, directory: String) -> void:
	app.get_window().gui_embed_subwindows = true
	app.input_profile = Profile.new(directory.path_join("copy-controls-%d.json"%Time.get_ticks_usec()))
	app.board.input_profile = app.input_profile; app.controls_dialog.profile = app.input_profile
	app.store = CurrentStore.new(directory.path_join("copy-natural-%d.json"%Time.get_ticks_usec()))
	check(app.title_screen.caption.text.length()<50,"Concise title")
	await click(app,app.title_screen.controls.new)
	app.journey_seed.text = "kecleon-ui"
	await click(app,app.travel_buttons.starter4)
	var before: Dictionary = app.run.duplicate(true)
	var catalog: Dictionary = app.campaign.progression.data.duplicate(true)
	check(visible_text(app.travel_root).find("Un combate por ubicación")==-1,"No repeated encounter tutorial")
	for location: Dictionary in app.campaign.locations:
		var text: String = Text.destination(location)
		check(text.length()<110 and "muestra" not in text and "Let’s Go" not in text,"Player-facing destination "+location.id)
	for definition: Dictionary in app.campaign.progression.data.moves.values():
		var summary: String = Info.summary(definition)
		check(summary.contains("Potencia:") and summary.contains("Precisión:") and summary.contains("Coste: %d PT"%definition.cost) and summary.contains("Alcance: %d"%definition.range),"Decision numbers retained: "+definition.id)
		check(not Info.details(definition).contains("Potencia base y daño en PS son distintos"),"No basic damage lecture: "+definition.id)
	check(Info.details(app.campaign.progression.data.moves["smokescreen"]).contains("dos rondas"),"Smoke lifetime remains visible")
	check(Info.details(app.campaign.progression.data.moves["swords-dance"]).contains("+2"),"Boost stages remain visible")
	check(Info.details(app.campaign.progression.data.moves["vine-whip"]).contains("Atrae"),"Tactical displacement remains visible")
	check(CurrentStore.equivalent(catalog,app.campaign.progression.data) and CurrentStore.equivalent(before,app.run),"Copy queries preserve catalogue, state and RNG")
	var glossary: String = Text.tactical_rules(22)
	check(glossary.length()<1500 and glossary.contains("Rectificar") and glossary.contains("+1 etapa crítica") and glossary.contains("Parálisis"),"Optional rules cover tactical differences")
	check(glossary.contains("incluso con reservas") and glossary.contains("EXP sobrante"),"Permanent defeat and cap consequences retained")
	app._set_hub_mode("team"); app._set_member_view("moves"); await layout(app)
	app.travel_buttons.move_slot_0.grab_focus(); await key(app,KEY_ENTER)
	check(app.move_library.selected_slot==0,"Keyboard selects a prepared move slot")
	check(visible_text(app.hub_parts.details).contains("MOVIMIENTOS") and not visible_text(app.hub_parts.details).contains("cambiar es gratis"),"Move library shows capacity without repeated explanations")
	app.input_profile.set_preference("textScale",150); app._apply_preferences(); await layout(app)
	await capture(app,directory,"moves-150")
	app.input_profile.set_preference("textScale",100); app._apply_preferences()
	app._set_hub_mode("overview"); await layout(app)
	await capture(app,directory,"travel")
	await click(app,app.travel_buttons.enter)
	check(app.hint.text.length()<150 and app.hint.text.contains("casillas verdes"),"Deployment shows only placement and objective")
	await capture(app,directory,"deployment")
	await click(app,app.adventure.start_button)
	for step: int in 300:
		if app.run.phase!="battle": break
		app._event({"kind":"battle","order":app.rules.choose_command(app.state),"at":app.run.revision})
	check(app.run.phase=="capture","Natural opening still reaches capture")
	if app.run.phase!="capture": finish(app,directory); return
	before = app.run.duplicate(true)
	preload("res://ui/economy_menu.gd").review_capture(app); await layout(app)
	check(app.action_review.content.text.contains(str(app.campaign.capture_price(app.run))) and app.action_review.content.text.contains("No se puede deshacer"),"Capture reroll preserves cost and irreversible warning")
	await key(app,KEY_ESCAPE,app.action_review)
	check(CurrentStore.equivalent(before,app.run),"Cancel spends no money or RNG")
	await click(app,app.travel_buttons.capture); await layout(app)
	await capture(app,directory,"kecleon")
	app._shop_page("evolution"); await layout(app)
	await click(app,app.travel_buttons.shop_train_xp); await layout(app)
	check(app.action_review.content.text.contains("Saldo:") and app.action_review.content.text.contains("EXP pendientes"),"Training confirmation retains price, level and resulting balance")
	await capture(app,directory,"training-cost")
	await key(app,KEY_ESCAPE,app.action_review)
	app._glossary(); await layout(app)
	check(app.action_review.content.text==glossary,"Optional tactical reference is reachable")
	await capture(app,directory,"tactical-rules")
	await key(app,KEY_ESCAPE,app.action_review)
	before = app.run.duplicate(true)
	app._load_game(); await layout(app)
	check(CurrentStore.equivalent(before,app.run),"Edited UI replays the unmodified campaign")
	finish(app,directory)

func finish(app: Control, directory: String) -> void:
	var result: Dictionary = {"assertions":assertions,"failures":failures,"screenshots":screenshots,"campaignEdition":app.run.edition,"stateHash":JSON.stringify(app.run,"",true,true).sha256_text(),"scope":"211 move number summaries, concise destinations and optional tactical rules; keyboard, text150%, natural opening/capture/shop, price/irreversibility confirmations and replay. Pure presentation."}
	FileAccess.open(directory.path_join("copy-ui-result.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("QA copy "+JSON.stringify({"assertions":assertions,"failures":failures})); app.get_tree().quit(0 if failures.is_empty() else 1)
