extends "res://ui/qa_context.gd"

const Icons = preload("res://ui/move_symbols.gd")
const CurrentStore = preload("res://core/sleep_store.gd")

func layout(app: Control) -> void:
	for frame: int in 8: await app.get_tree().process_frame

func run(app: Control, directory: String) -> void:
	app.get_window().gui_embed_subwindows = true
	app.input_profile = Profile.new(directory.path_join("symbols-controls-%d.json"%Time.get_ticks_usec()))
	app.board.input_profile = app.input_profile; app.controls_dialog.profile = app.input_profile
	app.store = CurrentStore.new(directory.path_join("symbols-save-%d.json"%Time.get_ticks_usec()))
	for identity: String in Icons.Info.TYPES:
		check(Icons.texture("types",identity)!=null,"Local type sprite: "+identity)
	for identity: String in Icons.Info.CATEGORIES:
		check(Icons.texture("categories",identity)!=null,"Local category sprite: "+identity)
	await click(app,app.title_screen.controls.new)
	app.journey_seed.text = "power-ui"
	await click(app,app.travel_buttons.starter4)
	var before: Dictionary = app.run.duplicate(true)
	for definition: Dictionary in app.campaign.progression.data.moves.values():
		check(definition.type in Icons.Info.TYPES and definition.category in Icons.Info.CATEGORIES,"Catalog icon mapping: "+definition.id)
	app._set_hub_mode("team"); app._set_member_view("moves"); await layout(app)
	for index: int in app.run.party[0].moves.size():
		var slot: Button = app.travel_buttons["move_slot_"+str(index)]
		check(slot.has_node("MoveSymbols") and slot.has_meta("move_category"),"Equipped slot has icons")
		check(slot.tooltip_text.contains("Potencia:"),"Equipped slot retains numeric detail")
	check(CurrentStore.equivalent(before,app.run),"All inspection is pure")
	await click(app,app.travel_buttons.move_slot_0)
	check(app.move_library.selected_slot==0,"Mouse selects equipped slot")
	app.travel_buttons.move_slot_1.grab_focus(); await key(app,KEY_ENTER)
	check(app.move_library.selected_slot==1,"Keyboard selects equipped slot")
	await capture(app,directory,"moves-100")
	var types: OptionButton = app.travel_buttons.move_types
	check(types.get_popup().get_item_icon_max_width(1)==24,"Type picker sprites stay compact")
	types.grab_focus(); await key(app,KEY_SPACE); await layout(app)
	types = app.travel_buttons.move_types
	check(types.get_popup().visible,"Type picker opens by keyboard")
	await capture(app,directory,"type-filter")
	types.get_popup().hide()
	app.input_profile.set_preference("textScale",150); app._apply_preferences(); await layout(app)
	await capture(app,directory,"moves-150")
	app.input_profile.set_preference("textScale",100); app._apply_preferences()
	app._set_hub_mode("overview"); await layout(app)
	await click(app,app.travel_buttons.enter); await click(app,app.adventure.start_button)
	app.action_page = true; app._refresh(); await layout(app)
	for button: Button in app.action_buttons.values():
		check(button.has_node("MoveSymbols"),"Battle action has type/category icons")
	check(app.action_buttons.basic.get_meta("move_type")=="","Typeless basic is never marked Normal")
	await capture(app,directory,"combat-symbols")
	for step: int in 200:
		if app.run.phase!="battle": break
		app._event({"kind":"battle","order":app.rules.choose_command(app.state),"at":app.run.revision})
	check(app.run.phase=="capture","Natural opening reaches capture")
	if app.run.phase=="capture": await click(app,app.travel_buttons.capture)
	await layout(app)
	app.adventure.toast.hide(); app.adventure.toast_remaining = 0
	check(app.run.phase=="shop","Natural capture reaches shop")
	check(not app.travel_buttons.has("shop_evolution") and not app.travel_buttons.has("shop_train_xp"),"No duplicate Train tab or XP purchase")
	await capture(app,directory,"shop-symbols")
	app._shop_page("evolution"); await layout(app)
	check(app.shop_tab=="gear","Stale training page returns to offers")
	for index: int in app.run.stock.size():
		var item: Dictionary = app.campaign.shop_data.items[app.run.stock[index].item]
		if item.kind=="tm": check(app.travel_buttons["stock_"+str(index)].has_node("MoveSymbols"),"TM offer displays type/category icons")
	await click(app,app.travel_buttons.hub_team); await layout(app)
	check(app.member_view=="profile","Team opens directly at Pokemon profile")
	check(app.travel_buttons.has("train-xp") and app.travel_buttons["train-xp"].is_visible_in_tree(),"Level up next to XP in Team profile")
	var member: Dictionary = app.campaign.target(app.run,app.selected_member)
	var quote: Dictionary = app.campaign.training_quote(app.run,member)
	check(quote.ok and not app.travel_buttons["train-xp"].disabled,"Training affordable after natural opening")
	before = app.run.duplicate(true)
	await click(app,app.travel_buttons["train-xp"])
	check(app.action_review.visible and str(quote.price) in app.action_review.content.text,"Training preserves original quote/confirmation")
	await key(app,KEY_ESCAPE,app.action_review)
	check(CurrentStore.equivalent(before,app.run),"Cancel XP purchase changes nothing")
	app.travel_buttons["train-xp"].grab_focus(); await key(app,KEY_ENTER)
	await click(app,app.action_review.get_ok_button()); await layout(app)
	var trained: Dictionary = app.campaign.target(app.run,app.selected_member)
	check(trained.level==member.level+1 and app.run.money==before.money-quote.price,"Team training levels up at unchanged price")
	check(trained.hp-member.hp==app.rules.member_unit(trained).maxHp-app.rules.member_unit(member).maxHp,"Level increase also restores gained maximum HP")
	await capture(app,directory,"team-level-up")
	before = app.run.duplicate(true)
	app._load_game(); await layout(app)
	check(CurrentStore.equivalent(before,app.run),"Save/reload preserves training and campaign edition24")
	app._set_hub_mode("team"); app._set_member_view("moves"); await layout(app)
	var definition: Dictionary = app.campaign.progression.data.moves[trained.moves[0]]
	app._review_text(definition.name,Icons.Info.details(definition),definition); await layout(app)
	check(app.action_review.symbols.visible and app.action_review.symbols.get_child_count()==2,"Move detail has labeled type/category badges")
	await capture(app,directory,"move-details")
	await key(app,KEY_ESCAPE,app.action_review)
	app.get_window().size = Vector2i(1024,720)
	app.input_profile.set_preference("textScale",150)
	app.input_profile.set_preference("highContrast",true)
	app.input_profile.set_preference("reducedMotion",true)
	app._refresh(); await layout(app)
	var contrast_slot: Button = app.travel_buttons.move_slot_0
	check(contrast_slot.get_theme_stylebox("normal").bg_color==Color.BLACK and contrast_slot.get_theme_color("font_color")==Color.WHITE,"Decorated slots honor high contrast")
	var scroll: ScrollContainer = app.hub_parts.details
	scroll.ensure_control_visible(contrast_slot); await layout(app)
	await capture(app,directory,"moves-1024-150-contrast")
	check(app.travel_buttons.move_slot_0.size.x>150,"Slots retain usable width with enlarged text")
	var report: Dictionary = {"assertions":assertions,"failures":failures,"screenshots":screenshots,"campaignEdition":app.run.edition,"stateHash":JSON.stringify(app.run,"",true,true).sha256_text(),"scope":"Natural opening, local icons, mouse/keyboard equipment and XP purchase/cancel/load; enlarged text, contrast and reduced motion screenshots."}
	FileAccess.open(directory.path_join("symbols-ui-result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("QA symbols "+JSON.stringify({"assertions":assertions,"failures":failures})); app.get_tree().quit(0 if failures.is_empty() else 1)
