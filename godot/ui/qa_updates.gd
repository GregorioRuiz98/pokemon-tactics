extends "res://ui/qa_context.gd"

func run(app: Control, directory: String) -> void:
	app.get_window().gui_embed_subwindows = true
	app.input_profile = Profile.new(directory.path_join("updates-controls-%d.json" % Time.get_ticks_usec()))
	app.board.input_profile = app.input_profile
	app.controls_dialog.profile = app.input_profile
	await fixture(app,directory)
	var before: Dictionary = app.run.duplicate(true)
	await key(app,KEY_I)
	check(app.tactical_reader.visible and app.tactical_reader.body.text.contains("PS"),"Keyboard opens persistent inspection")
	for i: int in 100: app.tactical_reader.show_unit(1)
	check(Store.equivalent(before,app.run) and app.transactions.is_empty(),"One hundred inspections preserve full state, journal and RNG")
	await key(app,KEY_ESCAPE,app.tactical_reader)
	check(not app.tactical_reader.visible and focus_is(app,app.board),"Inspection restores board focus")
	app._menu_selected(10)
	check(app.tactical_reader.visible,"Visible menu provides same inspection")
	await key(app,KEY_ESCAPE,app.tactical_reader)
	await key(app,KEY_1)
	await key(app,KEY_E)
	var plan: Dictionary = app.rules.attack_plan(app.state,10000,{},"basic")
	check(app.target_info.text.contains("%d–%d" % [plan.damageMin,plan.damageMax]),"Compact forecast uses exact normal damage band")
	await key(app,KEY_ENTER)
	await key(app,KEY_L)
	check(app.tactical_reader.body.text.contains("PS reales"),"Persistent result exposes real receipt after attack")
	await key(app,KEY_ESCAPE,app.tactical_reader)
	await capture(app,directory,"tactical-info")
	await additional(app,directory)
	await practice_checks(app,directory)
	var output: Dictionary = {"assertions":assertions,"failures":failures,"screenshots":screenshots,"scope":"Native synthetic events and explicitly synthetic interaction fixtures; isolated saves"}
	FileAccess.open(directory.path_join("updates-ui-result.json"),FileAccess.WRITE).store_string(JSON.stringify(output,"\t"))
	print("UPDATES_QA "+JSON.stringify(output))
	app.get_tree().quit(0 if failures.is_empty() else 1)

func additional(app: Control, directory: String) -> void:
	var before: Dictionary = app.run.duplicate(true)
	var full_matrix: bool = int(str(ProjectSettings.get_setting("application/config/version")).get_slice(".",2)) in [5,10]
	for dimensions: Vector2i in ([Vector2i(1024,720),Vector2i(1280,900),Vector2i(1920,1080)] if full_matrix else [Vector2i(1280,900)]):
		app.get_window().size = dimensions
		await settle(app)
		for scale_value: int in ([100,125,150] if full_matrix else [150]):
			check(app.input_profile.set_preference("textScale",scale_value),"Text scale persisted")
			app._apply_preferences()
			await settle(app)
			check(app.actor_info.get_theme_font_size("font_size")>=18,"HUD compensates physical shrink and enlarges text")
			check(app.board.play_area().size.x>0 and app.board.play_area().size.y>0,"Positive board with enlarged HUD")
			await capture(app,directory,"text-%d-%d" % [dimensions.x,scale_value])
	check(Store.equivalent(before,app.run),"Presentation settings and window changes preserve complete campaign and RNG")
	check(app.input_profile.set_preference("muted",true) and app.input_profile.set_preference("reducedMotion",true),"Silence and reduced motion save")
	var reloaded: RefCounted = Profile.new(app.input_profile.path)
	check(reloaded.preferences.muted and reloaded.preferences.reducedMotion and reloaded.preferences.textScale==150,"Fresh profile restores presentation settings")
	app.input_profile.install()
	app._open_presentation()
	await key(app,KEY_F12,app.presentation_dialog)
	check(not app.presentation_dialog.visible and app.input_profile.preferences.textScale==100,"F12 recovers readability from modal")
	app.get_window().size = Vector2i(1280,900)
	app._apply_preferences()
	if int(str(ProjectSettings.get_setting("application/config/version")).get_slice(".",2))>=6: await shop_checks(app,directory)

func shop_checks(app: Control, directory: String) -> void:
	app.input_profile.set_preference("textScale",100)
	app._apply_preferences()
	app.store = Store.new(directory.path_join("shop-natural-%d.json" % Time.get_ticks_usec()))
	app._show_oak()
	app.journey_seed.text = "tactics-1"
	app.travel_buttons.starter1.pressed.emit()
	app.travel_buttons.enter.pressed.emit()
	for i: int in 220:
		if app.run.phase!="battle": break
		app._event({"kind":"battle","order":app.rules.choose_command(app.state),"at":app.run.revision})
	if app.run.phase=="capture": app._event({"kind":"capture","at":app.run.revision})
	await settle(app)
	check(app.run.phase=="shop","Natural encounter prepares a real shop")
	if app.run.phase!="shop": return
	var before: Dictionary = app.run.duplicate(true)
	await click(app,app.travel_buttons.batch)
	app.shop_batch.quantity.value = 5
	app.shop_batch.preview()
	check(app.shop_batch.plan.ok and app.shop_batch.summary.text.contains("125"),"Five candies show exact purchase cost without using")
	await key(app,KEY_ESCAPE,app.shop_batch)
	check(Store.equivalent(before,app.run),"Cancel quantity preview is pure")
	await click(app,app.travel_buttons.batch)
	var expected: Dictionary = app.shop_batch.plan.state.duplicate(true)
	await click(app,app.shop_batch.get_ok_button())
	for i: int in 30:
		if not app.batch_busy: break
		await app.get_tree().process_frame
	check(Store.equivalent(expected,app.run) and app.shop_batch.persisted==5,"Native confirmation saves exactly five original purchase orders")
	var good: Dictionary = app.run.duplicate(true)
	app._load_game()
	check(Store.equivalent(good,app.run),"Natural purchase batch replays exactly after load")
	var real_store: RefCounted = app.store
	var blocked: String = directory.path_join("blocked-parent")
	var file: FileAccess = FileAccess.open(blocked,FileAccess.WRITE)
	file.store_string("QA persistence failure fixture")
	file.close()
	app.store = Store.new(blocked.path_join("save.json"))
	app._open_batch()
	app.shop_batch.preview()
	await click(app,app.shop_batch.get_ok_button())
	for i: int in 30:
		if not app.batch_busy: break
		await app.get_tree().process_frame
	check(app.shop_batch.accepted==1 and app.shop_batch.persisted==0 and not app.save_warning.is_empty(),"Persistence failure stops after the first unpersisted order")
	app.store = real_store
	app._load_game()
	check(Store.equivalent(good,app.run),"Reload never repeats an interrupted batch")
	await capture(app,directory,"quantity-shop")
	if int(str(ProjectSettings.get_setting("application/config/version")).get_slice(".",2))>=7: await roster_checks(app,directory)

func roster_checks(app: Control, directory: String) -> void:
	var natural: Dictionary = app.run.duplicate(true)
	for count: int in [0,1,6,7,30,100]:
		app.run.reserve = []
		for index: int in count:
			var member: Dictionary = natural.party[0].duplicate(true)
			member.id = 500+index
			member.origin = "Fixture sintético · %d" % index
			if index%3==0: member.hp = 0
			app.run.reserve.append(member)
		app.roster_panel.filters.clear()
		app._roster_page("pc",0)
		await settle(app)
		var before: Dictionary = app.run.duplicate(true)
		check(app.travel_buttons.has("pc_search"),"PC search remains available with "+str(count)+" entries")
		app.travel_buttons.pc_search.grab_focus()
		await key(app,KEY_Z)
		check(app.roster_panel.filters.query=="z" and not app.travel_buttons.has("member_500"),"Native typing filters duplicates without activating shortcuts")
		check(Store.equivalent(before,app.run),"Filtering PC preserves full fixture and RNG for "+str(count))
	app.run = natural
	app.state = app.run.battle
	app.roster_panel.filters.clear()
	app._roster_page("team",0)
	if app.run.party.size()>1:
		var incoming: int = int(app.run.party[1].id)
		app._event({"kind":"deposit","member":incoming,"at":app.run.revision})
		app._roster_page("pc",0)
		app.selected_member = incoming
		app.roster_swap = int(app.run.party[0].id)
		app._refresh()
		await settle(app)
		var before: Dictionary = app.run.duplicate(true)
		await click(app,app.travel_buttons.swap)
		check(app.action_review.visible and app.action_review.content.text.contains("SALE"),"Swap opens full before/after comparison")
		await key(app,KEY_ESCAPE,app.action_review)
		check(Store.equivalent(before,app.run),"Cancelling swap preserves all members")
		await click(app,app.travel_buttons.swap)
		var expected: Dictionary = app.campaign.transact(before,{"kind":"swap","member":app.roster_swap,"reserve":incoming,"at":before.revision})
		await click(app,app.action_review.get_ok_button())
		check(expected.ok and Store.equivalent(app.run,expected.state),"Native swap matches complete authoritative state")
	app._roster_page("pc",0)
	app.selected_member = 1
	app._refresh()
	var selected: Dictionary = app.campaign.target(app.run,1)
	var missing: int = maxi(0,app.campaign.level_cap(app.run)-int(selected.level))
	for i: int in maxi(0,missing-int(app.run.bag["rare-candy"])): app._event({"kind":"buy","item":"rare-candy","at":app.run.revision})
	for i: int in missing: app._event({"kind":"level-up","member":1,"at":app.run.revision})
	selected = app.campaign.target(app.run,1)
	var extras: Array = selected.knownMoves.filter(func(id):return id not in selected.moves)
	check(not extras.is_empty(),"Natural level progression prepares a library replacement case")
	if not extras.is_empty():
		var before: Dictionary = app.run.duplicate(true)
		var move: String = extras[0]
		app.move_library.selected_slot = 0
		app._refresh()
		await settle(app)
		var button: Button = app.travel_buttons["move_"+move]
		button.grab_focus()
		await key(app,KEY_ENTER)
		check(app.action_review.visible,"Slot replacement opens comparison before any order")
		var moves: Array = selected.moves.duplicate()
		moves[0] = move
		var expected: Dictionary = app.campaign.transact(before,{"kind":"loadout","member":1,"moves":moves,"at":before.revision})
		await key(app,KEY_ENTER,app.action_review)
		check(expected.ok and Store.equivalent(app.run,expected.state),"Single accepted replacement preserves four-slot contract")
	await capture(app,directory,"filtered-pc-library")

func practice_checks(app: Control, directory: String) -> void:
	var before: Dictionary = app.run.duplicate(true)
	var journal: Array = app.transactions.duplicate(true)
	var real_store: RefCounted = app.store
	var bytes: String = FileAccess.get_file_as_string(real_store.file_path)
	for method: String in ["keyboard","mouse"]:
		print("PRACTICE_START "+method)
		app._open_title()
		await settle(app)
		if method=="keyboard": await key(app,KEY_F7)
		else: await click(app,app.title_screen.controls.practice)
		check(app.practice.active and app.practice.step==0,"Practice starts from title: "+method)
		if method=="keyboard":
			await key(app,KEY_RIGHT)
			await key(app,KEY_LEFT)
			await key(app,KEY_LEFT)
			await key(app,KEY_ENTER)
			await key(app,KEY_R)
			await key(app,KEY_4)
			await key(app,KEY_ESCAPE)
			await key(app,KEY_2)
			await key(app,KEY_ENTER)
			await key(app,KEY_F)
			await key(app,KEY_UP)
			await key(app,KEY_ENTER)
			await key(app,KEY_1)
			await key(app,KEY_E)
			await key(app,KEY_ENTER)
			await key(app,KEY_R)
			await key(app,KEY_I)
			await key(app,KEY_ESCAPE,app.tactical_reader)
			await key(app,KEY_F)
			await key(app,KEY_LEFT)
			await key(app,KEY_ENTER)
		else:
			await motion(app,app.board.center({"x":4,"y":8}))
			await tile(app,{"x":4,"y":8})
			await click(app,app.buttons.undo)
			await click(app,app.buttons.actions)
			await practice_action(app,"vine-whip")
			await pointer(app,app.board.center({"x":5,"y":8}),true,MOUSE_BUTTON_RIGHT)
			await pointer(app,app.board.center({"x":5,"y":8}),false,MOUSE_BUTTON_RIGHT)
			check(app.practice.step==5,"Mouse practice cancellation reaches growth step")
			await click(app,app.buttons.actions)
			await practice_action(app,"growth")
			check(app.practice.step==6,"Mouse selects Growth without action")
			await tile(app,{"x":5,"y":8})
			await click(app,app.buttons.finish)
			await click(app,app.direction_buttons[4])
			await click(app,app.buttons.actions)
			await practice_action(app,"basic")
			await tile(app,{"x":6,"y":9})
			await click(app,app.buttons.undo)
			app._menu_selected(10)
			await click(app,app.tactical_reader.get_ok_button())
			await click(app,app.buttons.finish)
			await click(app,app.direction_buttons[6])
		print("PRACTICE_STEP "+str(app.practice.step))
		check(app.practice.step==12,"Complete practice using "+method+"; step="+str(app.practice.step))
		await capture(app,directory,"practice-"+method)
		if method=="keyboard": await key(app,KEY_F7)
		else: app._menu_selected(8)
		check(not app.practice.active and Store.equivalent(app.run,before) and Store.equivalent(app.transactions,journal),"Practice restores complete real campaign and journal: "+method)
		check(app.store==real_store and FileAccess.get_file_as_string(real_store.file_path)==bytes,"Practice never writes real save: "+method)
	app._resume_title()

func practice_action(app: Control, identity: String) -> void:
	app.actions_scroll.ensure_control_visible(app.action_buttons[identity])
	await settle(app)
	await click(app,app.action_buttons[identity])
