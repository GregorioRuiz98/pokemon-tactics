extends "res://ui/qa_context.gd"

const CurrentRun = preload("res://core/adventure_run.gd")
const CurrentStore = preload("res://core/adventure_store.gd")
const Challenge = preload("res://core/journey_challenge.gd")
const Info = preload("res://ui/move_info.gd")
const Copy = preload("res://ui/player_copy.gd")
var layouts: Array = []

func layout(app: Control) -> void:
	for frame: int in 6: await app.get_tree().process_frame

func run(app: Control, directory: String) -> void:
	app.get_window().gui_embed_subwindows = true
	app.input_profile = Profile.new(directory.path_join("player-controls-%d.json" % Time.get_ticks_usec()))
	app.board.input_profile = app.input_profile; app.controls_dialog.profile = app.input_profile
	app.store = CurrentStore.new(directory.path_join("player-save-%d.json" % Time.get_ticks_usec()))
	await click(app,app.title_screen.controls.new)
	check(app.run.is_empty() and not app.title_visible,"New adventure opens Oak directly")
	var initial_seed: String = app.journey_seed.text
	check(initial_seed.begins_with("kanto-") and not app.journey_seed.is_visible_in_tree(),"Seed generated automatically and advanced controls hidden")
	var seeds: Dictionary = {}
	for index: int in 64: seeds[app._generate_seed()] = true
	check(seeds.size()==64,"Independent random generator returns 64 distinct seeds")
	for dimensions: Vector2i in [Vector2i(1024,720),Vector2i(1280,900)]:
		app.get_window().size = dimensions
		for scale_value: int in [100,125,150]:
			app.input_profile.set_preference("textScale",scale_value); app._apply_preferences()
			await layout(app)
			for id: int in [1,4,7]:
				var button: Button = app.travel_buttons["starter"+str(id)]
				check(button.is_visible_in_tree() and Rect2(Vector2.ZERO,app.size).encloses(button.get_global_rect()),"Starter fits at %d/%d/%d" % [dimensions.x,scale_value,id])
			layouts.append([dimensions.x,scale_value])
			if scale_value==150: await capture(app,directory,"oak-%d-150" % dimensions.x)
	app.get_window().size = Vector2i(1280,900)
	app.input_profile.set_preference("textScale",100); app._apply_preferences()
	await layout(app)
	app.travel_buttons.seed_options.grab_focus()
	await key(app,KEY_ENTER)
	check(app.journey_seed.is_visible_in_tree() and app.journey_seed.has_focus(),"Keyboard opens optional seed controls and focuses the field")
	await key(app,KEY_ESCAPE)
	check(not app.journey_seed.is_visible_in_tree() and app.travel_buttons.seed_options.has_focus(),"Escape closes advanced options without leaving Oak")
	app._refresh(); await layout(app)
	check(app.journey_seed.text==initial_seed,"Refreshing Oak preserves generated seed")
	await click(app,app.travel_buttons.starter1)
	check(app.run.seed==initial_seed and app.run.edition==21 and app.run.starter==1,"Default starter begins and saves installed rules with automatic seed")
	var before: Dictionary = app.run.duplicate(true)
	var journal: Array = app.transactions.duplicate(true)
	var saved_text: String = FileAccess.get_file_as_string(app.store.file_path)
	app._show_oak(); await layout(app)
	check(not app.seed_options_open and app.journey_seed.text!=initial_seed,"Next adventure gets another automatic seed")
	await click(app,app.travel_buttons.seed_options)
	app.journey_seed.text = "KT99:invalid"
	await click(app,app.travel_buttons.starter4)
	check(app.action_review.visible and app.action_review.title=="Código de reto no válido","Incompatible challenge has a useful error")
	check(FileAccess.get_file_as_string(app.store.file_path)==saved_text and app.run.is_empty(),"Invalid challenge does not replace saved campaign")
	await key(app,KEY_ESCAPE,app.action_review)
	app.journey_seed.text = "x".repeat(65)
	await click(app,app.travel_buttons.starter4)
	check(app.action_review.visible and app.action_review.title=="Semilla demasiado larga","Oversized manual seed rejected before backup or save")
	await key(app,KEY_ESCAPE,app.action_review)
	app._open_title(); await layout(app)
	check(CurrentStore.equivalent(before,app.run) and app.transactions==journal,"Cancelling new adventure restores the original campaign and journal")
	await click(app,app.title_screen.controls["continue"])
	check(CurrentStore.equivalent(before,app.run),"Continue preserves complete campaign and RNG")
	app._glossary(); await layout(app)
	check(app.action_review.content.text.contains("EXP que falta") and not app.action_review.content.text.contains("Caramelo compra"),"Current glossary explains paid EXP and free adapted evolution")
	check(Copy.glossary(4).contains("Caramelo Raro compra un nivel") and Copy.glossary(2).contains("caramelo no sube niveles"),"Historical campaigns retain correct progression explanations")
	await key(app,KEY_ESCAPE,app.action_review)
	app._show_oak(); await layout(app)
	await click(app,app.travel_buttons.seed_options)
	app.journey_seed.text = Challenge.encode({"seed":"player-sprint-26","starter":4,"mapSize":16})
	app.journey_seed.text_changed.emit(app.journey_seed.text)
	check(app.travel_buttons.seed_hint.text.contains("Charmander"),"Challenge identifies the encoded starter before starting")
	await click(app,app.travel_buttons.starter7)
	check(app.run.seed=="player-sprint-26" and app.run.starter==4 and app.run.mapSize==16,"Shared challenge preserves encoded choices")
	app._set_hub_mode("team"); app._set_member_view("moves"); await layout(app)
	before = app.run.duplicate(true); journal = app.transactions.duplicate(true)
	var member: Dictionary = app.run.party[0]
	for id: String in member.knownMoves:
		check(app.travel_buttons["move_"+id].text.contains("Potencia:") and app.travel_buttons["move_"+id].text.contains("Precisión:"),"Known move shows power and accuracy: "+id)
	for dimensions: Vector2i in [Vector2i(1024,720),Vector2i(1280,900)]:
		app.get_window().size = dimensions
		for scale_value: int in [100,125,150]:
			app.input_profile.set_preference("textScale",scale_value); app._apply_preferences(); await layout(app)
			for id: String in member.knownMoves:
				var button: Button = app.travel_buttons["move_"+id]
				var available: Vector2 = button.size-button.get_theme_stylebox("normal").get_minimum_size()
				var text_size: Vector2 = button.get_theme_font("font").get_multiline_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,available.x,button.get_theme_font_size("font_size"),-1,TextServer.BREAK_MANDATORY|TextServer.BREAK_WORD_BOUND|TextServer.BREAK_ADAPTIVE)
				check(text_size.x<=available.x+1 and text_size.y<=available.y+1,"Full move information fits at %d/%d/%s" % [dimensions.x,scale_value,id])
			if dimensions.x==1024 and scale_value==150: await capture(app,directory,"moves-1024-150")
	app.get_window().size = Vector2i(1280,900)
	app.input_profile.set_preference("textScale",100); app._apply_preferences(); await layout(app)
	app.move_library.selected_slot = -1
	await click(app,app.travel_buttons["move_"+member.knownMoves[0]])
	check(app.action_review.content.text.contains("Potencia:") and app.action_review.content.text.contains("Área:"),"Move detail exposes full data without preparing a move")
	check(app.action_review.diagram.visible and not app.action_review.diagram.mask.tiles.is_empty(),"Move detail includes geometry from shared engine")
	await capture(app,directory,"move-dialog")
	await key(app,KEY_ESCAPE,app.action_review)
	check(CurrentStore.equivalent(before,app.run) and app.transactions==journal,"Move inspection/cancel preserves state, journal and RNG")
	await capture(app,directory,"moves-details")
	var categories: Dictionary = {}
	for definition: Dictionary in app.campaign.progression.data.moves.values():
		categories[definition.category] = true
		var original: String = JSON.stringify(definition)
		var details: String = Info.details(definition)
		check(details.contains("Potencia:") and details.contains("Precisión:") and details.contains("Coste:") and details.contains("Área:"),"Complete shared move information: "+definition.id)
		check(JSON.stringify(definition)==original,"Move information leaves definition unchanged: "+definition.id)
		if definition.has("shape"): check(not Info.diagram(definition).tiles.is_empty(),"Shared geometry produces illustrative area: "+definition.id)
	check(categories.size()==3,"Real catalog covers physical, special and status moves")
	check(Info.power(app.campaign.progression.data.moves["growl"])=="—","Status move has no numerical power")
	check(Info.power(app.campaign.progression.data.moves["dragon-rage"])=="Fija","Fixed damage is not displayed as zero power")
	check(Info.power(app.campaign.progression.data.moves["counter"])=="Variable","Counter power follows conditional damage")
	check(Info.accuracy({"neverMiss":true,"accuracy":100})=="No falla por precisión","Always-hit wording does not promise to bypass immunity")
	check(Info.details(app.campaign.progression.data.moves["ember"]).contains("Quemadura: 10 %"),"Secondary effect appears in player-facing description")
	check(Info.details(app.campaign.progression.data.moves["growl"]).contains("Ataque -1"),"Attribute stages use translated names and signed values")
	await click(app,app.travel_buttons.home)
	await click(app,app.title_screen.controls["continue"])
	await click(app,app.travel_buttons.enter)
	await click(app,app.adventure.start_button)
	check(app.state.combatEdition==19,"Presentation release preserves combat rules")
	var opening: Dictionary = app.rules.choose_command(app.state)
	if opening.kind=="move": app._commit(opening); await layout(app)
	app._open_actions(); await layout(app)
	check(app.actions.visible,"Keyboard-accessible ability list is visible")
	for button: Button in app.action_buttons.values():
		check(button.is_visible_in_tree() and button.tooltip_text.contains("Precisión:"),"Combat ability has full accessible information")
	await capture(app,directory,"abilities-power")
	app.selected_action = "basic"; app.selecting = "attack"
	var target: Dictionary = app.state.units.filter(func(u):return u.team=="enemy")[0]
	app._hover_tile(target); await layout(app)
	for button: Button in app.action_buttons.values(): check(button.text.contains("Pot."),"Combat action shows base power")
	before = app.run.duplicate(true); journal = app.transactions.duplicate(true)
	app._hover_tile(target)
	check(CurrentStore.equivalent(before,app.run) and app.transactions==journal,"Combat inspection does not advance campaign RNG")
	await capture(app,directory,"combat-power")
	# A natural first encounter follows legal saved commands; no fabricated victory.
	for step: int in 350:
		if app.run.phase!="battle": break
		app._event({"kind":"battle","order":app.rules.choose_command(app.state),"at":app.run.revision})
	check(app.run.phase=="capture","Natural opening produces a reward")
	if app.run.phase=="capture":
		app._event({"kind":"capture","replace":0,"at":app.run.revision})
		await layout(app)
		check(app.run.phase=="shop","Natural capture enters shop")
		check(app.adventure.toast.size.y<160 and Rect2(Vector2.ZERO,app.size).encloses(app.adventure.toast.get_global_rect()),"Reward notice stays compact and within the viewport")
		await key(app,KEY_ESCAPE)
		app._shop_page("gear"); await layout(app)
		for i: int in app.run.stock.size():
			var item: Dictionary = app.campaign.shop_data.items[app.run.stock[i].item]
			if item.kind=="tm": check(app.travel_buttons["stock_"+str(i)].tooltip_text.contains("Potencia:"),"TM uses the same power information")
			if item.kind=="tm":
				before = app.run.duplicate(true)
				await click(app,app.travel_buttons["stock_detail_"+str(i)])
				check(app.action_review.visible and app.action_review.content.text.contains("Potencia:"),"TM details available without purchasing")
				await key(app,KEY_ESCAPE,app.action_review)
				check(CurrentStore.equivalent(before,app.run),"TM inspection preserves wallet, stock and RNG")
		await capture(app,directory,"shop-power")
	before = app.run.duplicate(true)
	app._load_game(); await layout(app)
	check(CurrentStore.equivalent(before,app.run),"Current adventure replays and reloads exactly")
	var report: Dictionary = {"assertions":assertions,"failures":failures,"screenshots":screenshots,"layouts":layouts,"catalog":app.campaign.progression.data.moves.size(),"campaignEdition":app.run.edition,"combatEdition":app.rules.progression.spatial_data.combatEdition+1,"naturalPhase":app.run.phase,"stateHash":JSON.stringify(app.run,"",true,true).sha256_text(),"scope":"Default and shared-code starts, isolated save/cancel/reload, complete move catalog queries, natural Route1 and accessibility layouts. No balance changes."}
	FileAccess.open(directory.path_join("player-ui-result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("QA player "+JSON.stringify({"assertions":assertions,"failures":failures,"catalog":report.catalog,"naturalPhase":app.run.phase}))
	app.get_tree().quit(0 if failures.is_empty() else 1)
