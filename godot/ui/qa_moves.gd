extends "res://ui/qa_spatial.gd"

var layouts: Array[Dictionary] = []

func ready_layout(app: Control) -> void:
	for frame: int in 6: await app.get_tree().process_frame

func assert_slots(app: Control, member: Dictionary, label: String) -> void:
	var previous: Array[Rect2] = []
	for index: int in 4:
		var slot: Button = app.travel_buttons["move_slot_"+str(index)]
		var name_text: String = app.campaign.progression.data.moves[member.moves[index]].name if index<member.moves.size() else "Vacía"
		var rect: Rect2 = slot.get_global_rect()
		var box: StyleBox = slot.get_theme_stylebox("normal")
		var available: Vector2 = slot.size-box.get_minimum_size()
		var text_size: Vector2 = slot.get_theme_font("font").get_multiline_string_size(slot.text,HORIZONTAL_ALIGNMENT_LEFT,available.x,slot.get_theme_font_size("font_size"),-1,TextServer.BREAK_MANDATORY|TextServer.BREAK_WORD_BOUND|TextServer.BREAK_ADAPTIVE)
		check(slot.is_visible_in_tree() and slot.text=="%d · %s" % [index+1,name_text],label+" correct equipped name/empty slot "+str(index))
		check(available.x>=180 and text_size.x<=available.x+1 and text_size.y<=available.y+1,label+" complete text fits slot "+str(index))
		check(slot.disabled==(index>member.moves.size()),label+" consecutive-slot rule "+str(index))
		check(previous.all(func(other):return not other.intersects(rect)),label+" slots do not overlap "+str(index))
		check(rect.position.x>=app.hub_parts.details.get_global_rect().position.x and rect.end.x<=app.hub_parts.details.get_global_rect().end.x+1,label+" slot inside detail width "+str(index))
		previous.append(rect)
		layouts.append({"case":label,"slot":index,"name":name_text,"width":slot.size.x,"height":slot.size.y,"textWidth":text_size.x,"textHeight":text_size.y})

func run(app: Control, directory: String) -> void:
	app.get_window().gui_embed_subwindows = true
	app.input_profile = Profile.new(directory.path_join("moves-controls.json"))
	app.board.input_profile = app.input_profile
	app.controls_dialog.profile = app.input_profile
	app.title_visible = false
	app.campaign = SpatialRun.new()
	app.rules = app.campaign.engine
	app.run = app.campaign.create("moves-ui-fixture",4)
	# Synthetic levelled member, exercising long legitimate names and four slots.
	var member: Dictionary = app.campaign.progression.create_member(1,6,"Fixture",60)
	var candidates: Array = member.knownMoves.duplicate()
	candidates.sort_custom(func(a,b):return app.campaign.progression.data.moves[a].name.length()>app.campaign.progression.data.moves[b].name.length())
	member.moves = candidates.slice(0,4)
	app.run.party = [member]
	app.selected_member = 1
	app._prepare_campaign_assets()
	app._refresh()
	await ready_layout(app)
	app._set_hub_mode("team")
	await ready_layout(app)
	app._set_member_view("moves")
	await ready_layout(app)
	var before: Dictionary = app.run.duplicate(true)
	var journal: Array = app.transactions.duplicate(true)
	for dimensions: Vector2i in [Vector2i(1024,720),Vector2i(1280,900),Vector2i(1920,1080)]:
		app.get_window().size = dimensions
		await ready_layout(app)
		for scale_value: int in [100,125,150]:
			app.input_profile.set_preference("textScale",scale_value)
			app._apply_preferences()
			await ready_layout(app)
			var label: String = "%d-%d" % [dimensions.x,scale_value]
			assert_slots(app,member,label)
			var first: Button = app.travel_buttons.move_slot_0
			first.grab_focus()
			app.hub_parts.details.ensure_control_visible(first)
			await ready_layout(app)
			check(app.hub_parts.details.get_global_rect().encloses(first.get_global_rect()),label+" focus scroll reveals equipped slot")
			await capture(app,directory,"equipped-"+label)
	check(Store.equivalent(before,app.run) and app.transactions==journal,"All presentation changes preserve complete campaign, journal and RNG")
	app.get_window().size = Vector2i(1280,900)
	app.input_profile.set_preference("textScale",100)
	app._apply_preferences()
	await ready_layout(app)
	await click(app,app.travel_buttons.move_slot_1)
	await ready_layout(app)
	check(app.move_library.selected_slot==1 and app.travel_buttons.move_slot_1.button_pressed,"Mouse selects second slot after rebuilding")
	app.travel_buttons.move_slot_3.grab_focus()
	await key(app,KEY_ENTER)
	await ready_layout(app)
	check(app.move_library.selected_slot==3 and app.travel_buttons.move_slot_3.button_pressed,"Keyboard selects fourth slot after rebuilding")
	var replacement: String = candidates.filter(func(id):return id not in member.moves)[0]
	await click(app,app.travel_buttons["move_"+replacement])
	check(app.action_review.visible and app.action_review.content.text.contains(app.campaign.progression.data.moves[replacement].name),"Replacement opens correct comparison")
	await key(app,KEY_ESCAPE,app.action_review)
	await ready_layout(app)
	check(Store.equivalent(before,app.run) and app.transactions==journal,"Selecting and cancelling changes neither equipped moves nor saved orders")
	for count: int in [0,1,3]:
		member.moves = candidates.slice(0,count)
		app._refresh()
		await ready_layout(app)
		assert_slots(app,member,"prepared-"+str(count))
	member.moves = candidates.slice(0,4)
	app.run.phase = "shop"
	app._refresh()
	await ready_layout(app)
	app._set_hub_mode("team")
	await ready_layout(app)
	app._set_member_view("moves")
	await ready_layout(app)
	assert_slots(app,member,"shop")
	app.input_profile.set_preference("highContrast",true)
	app._apply_preferences()
	await ready_layout(app)
	assert_slots(app,member,"high-contrast")
	app.travel_buttons.move_slot_0.grab_focus()
	app.hub_parts.details.ensure_control_visible(app.travel_buttons.move_slot_0)
	await capture(app,directory,"shop-high-contrast")
	var result: Dictionary = {"assertions":assertions,"failures":failures,"screenshots":screenshots,"layouts":layouts,"scope":"Synthetic team/loadout UI; isolated saves; source and executable; no balance changes"}
	FileAccess.open(directory.path_join("moves-ui-result.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("MOVES_QA "+JSON.stringify({"assertions":assertions,"failures":failures,"layouts":layouts.size()}))
	app.get_tree().quit(0 if failures.is_empty() else 1)
