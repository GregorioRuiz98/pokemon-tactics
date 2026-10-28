extends SceneTree

const QA = preload("res://ui/qa_context.gd")
var directory: String = ""
var mode: String = "profile"
var tester: RefCounted = QA.new()

func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--beta-dir="): directory = arg.trim_prefix("--beta-dir=")
		if arg.begins_with("--beta-mode="): mode = arg.trim_prefix("--beta-mode=")
	call_deferred("run_ui")

func layout() -> void:
	for frame: int in 8: await process_frame

func run_ui() -> void:
	if directory.is_empty() or not OS.get_user_data_dir().replace("\\","/").contains("beta-rc2-2026-10-28"):
		print("BETA_ISOLATION_REQUIRED"); quit(2); return
	DirAccess.make_dir_recursive_absolute(directory)
	root.gui_embed_subwindows = true
	var app: Control = load("res://scenes/campaign.tscn").instantiate()
	root.add_child(app); await layout(); app.qa_running = true
	app.input_profile.set_preference("muted",true)
	if mode=="corrupt-load": await corrupt_load(app); return
	if mode in ["seeds","shop"]: await seed_controls(app); return
	app.trainer.model = app.trainer.Model.new()
	# Complete collection/cosmetics fixture, not earned progress or campaign wins.
	for species: int in range(1,152): app.trainer.model.register_species(species)
	for flag: String in app.trainer.model.ACHIEVEMENTS: app.trainer.model.unlock(flag,"beta-ui-fixture")
	app.trainer.model.customize("M".repeat(24),25,"Campeón de Kanto","champion")
	tester.check(app.trainer.persist(),"Full isolated cosmetic fixture saves")
	if mode=="portrait": await portrait_input(app); return
	if mode=="cycles": await menu_cycles(app); return
	var original: String = JSON.stringify(app.trainer.model.data,"",true,true)
	var disk: String = FileAccess.get_file_as_string(app.trainer.persistence.file_path)
	app._open_title(); await layout(); await tester.click(app,app.title_screen.controls.trainer); await layout()
	var panel: AcceptDialog = app.trainer.dialog
	panel.change_page("card"); await layout()
	tester.check(panel.controls.portrait.item_count==151,"All151 portrait choices are available")
	await tester.click(app,panel.controls.portrait); await layout()
	var popup: PopupMenu = panel.controls.portrait.get_popup()
	tester.check(popup.visible,"Portrait chooser opens with full collection")
	await tester.key(app,KEY_END,popup); await tester.key(app,KEY_ENTER,popup); await layout()
	tester.check(panel.controls.portrait.get_selected_id()==151 and panel.preview_notice.text=="Sin guardar","Keyboard can select the last of151 portraits")
	tester.check(JSON.stringify(app.trainer.model.data,"",true,true)==original,"Portrait chooser never commits preview")
	await tester.key(app,KEY_ESCAPE,panel); await layout()
	tester.check(not panel.visible,"Escape closes parent after portrait selection")
	app.trainer.open(app); panel.change_page("dex"); await layout()
	var browser: VBoxContainer = panel.dex_browser
	var visited: Array = []
	for page: int in 19:
		for species: Variant in browser.controls:
			if species is int: visited.append(species)
		tester.check(browser.page==page,"Pokédex page order "+str(page))
		if page<18: await tester.click(app,browser.controls.next); await layout()
	tester.check(visited==range(1,152) and browser.controls.next.disabled,"All151 entries paginated exactly once")
	await tester.click(app,browser.controls[151]); await layout()
	tester.check(app.action_review.visible and app.action_review.title.contains("Mew"),"Last Pokédex entry opens correct details")
	await tester.key(app,KEY_ESCAPE,app.action_review); await layout()
	tester.check(panel.visible,"Escape returns to parent profile from species detail")
	for needle: String in ["#025","nidoran","áéíóú","999","mew","   "]:
		browser.query.text = needle; browser.query.text_changed.emit(needle); await layout()
		tester.check(browser.page==0 and browser.controls.has("next"),"Search resets pagination safely: "+needle)
	var page_sizes: Array = []
	for dimensions: Vector2i in [Vector2i(1920,1080),Vector2i(1024,720),Vector2i(1280,900)]:
		root.size = dimensions
		app.input_profile.set_preference("textScale",150); app.input_profile.set_preference("highContrast",true)
		app._apply_preferences(); panel.change_page("card"); await layout()
		tester.check(panel.visible and panel.size.x<=dimensions.x and panel.size.y<=dimensions.y,"Open profile resizes within "+str(dimensions))
		tester.check(panel.trainer_name.autowrap_mode==TextServer.AUTOWRAP_OFF,"Long name remains one line after resize")
		page_sizes.append({"window":[dimensions.x,dimensions.y],"dialog":[panel.size.x,panel.size.y]})
		if dimensions.x==1024: await tester.capture(app,directory,"full-profile-1024-150")
	tester.check(FileAccess.get_file_as_string(app.trainer.persistence.file_path)==disk,"All paging, inspection and resize operations preserve profile bytes")
	panel.controls.name_field.grab_focus(); await layout()
	await tester.key(app,KEY_A,panel); await tester.key(app,KEY_F,panel); await tester.key(app,KEY_R,panel)
	tester.check(panel.visible and app.run.is_empty(),"Typing game hotkeys in name field never starts gameplay")
	await tester.key(app,KEY_F12,panel); await layout()
	tester.check(not panel.visible and app.input_profile.preferences.textScale==100,"F12 recovers readability and closes dialogs")
	tester.check(FileAccess.get_file_as_string(app.trainer.persistence.file_path)==disk,"Readability recovery never saves cosmetic edits")
	tester.check(not app.input_profile.set_preference("textScale",200),"Unsupported text scale is rejected")
	tester.check(not app.input_profile.set_preference("battleSpeed",0),"Invalid battle speed is rejected")
	var report: Dictionary = {"assertions":tester.assertions,"failures":tester.failures,"screenshots":tester.screenshots,"sizes":page_sizes,"scope":"Additional live UI edge cases with a full synthetic profile; no real achievements or human playtest claimed."}
	FileAccess.open(directory.path_join("beta-ui.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("QA beta-ui "+JSON.stringify({"assertions":tester.assertions,"failures":tester.failures}))
	quit(0 if tester.failures.is_empty() else 1)

func corrupt_load(app: Control) -> void:
	var path: String = directory.path_join("malformed-campaign.dat")
	var store: RefCounted = app.CampaignStore.new(path)
	var state: Dictionary = app.campaign.create("beta-corrupt-ui",1)
	tester.check(store.save(state,[],"current").ok,"Corrupt-load fixture starts as a valid campaign")
	var outer: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var payload: Dictionary = JSON.parse_string(outer.payload)
	payload.commands = [{"kind":[],"at":0}]
	outer.payload = JSON.stringify(payload,"",true,true); outer.checksum = outer.payload.sha256_text()
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(outer))
	var original: String = FileAccess.get_sha256(path)
	app.store = app.CampaignStore.new(path); app._open_title(); await layout()
	await tester.click(app,app.title_screen.controls["continue"]); await layout()
	tester.check(FileAccess.get_sha256(path)==original,"Malformed campaign remains untouched after real Continue")
	tester.check(not app.title_loading,"Loading flag released on malformed command")
	tester.check(not app.title_screen.controls.new.disabled,"New adventure remains accessible after rejected save")
	tester.check(not app.save_warning.is_empty(),"Rejected save explains the failure to the player")
	await tester.capture(app,directory,"malformed-continue")
	await tester.key(app,KEY_F12); await layout()
	tester.check(not app.title_screen.controls.new.disabled,"F12 can recover title controls")
	tester.check(FileAccess.get_sha256(path)==original,"Readability recovery also preserves the original")
	var report: Dictionary = {"assertions":tester.assertions,"failures":tester.failures,"screenshots":tester.screenshots,"loading":app.title_loading,"scope":"Malformed checksum-valid fixture with kind array, exercised using real Continue. No spontaneous save corruption claimed."}
	FileAccess.open(directory.path_join("beta-corrupt-ui.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("QA beta-corrupt-ui "+JSON.stringify({"assertions":tester.assertions,"failures":tester.failures}))
	quit(0 if tester.failures.is_empty() else 1)

func save_report(filename: String, details: Dictionary) -> void:
	var report: Dictionary = {"assertions":tester.assertions,"failures":tester.failures,"screenshots":tester.screenshots,"details":details,"scope":"Additional source UI probe with an isolated full-profile fixture."}
	FileAccess.open(directory.path_join(filename+".json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("QA "+filename+" "+JSON.stringify({"assertions":tester.assertions,"failures":tester.failures}))
	quit(0 if tester.failures.is_empty() else 1)

func native_key(code: int) -> void:
	for down: bool in [true,false]:
		var event: InputEventKey = InputEventKey.new()
		event.keycode = code as Key; event.pressed = down
		event.window_id = root.get_window_id()
		Input.parse_input_event(event)
		await process_frame; await process_frame

func portrait_input(app: Control) -> void:
	app._open_title(); app.trainer.open(app); app.trainer.dialog.change_page("card"); await layout()
	var panel: AcceptDialog = app.trainer.dialog
	var choice: OptionButton = panel.controls.portrait
	choice.grab_focus(); await layout()
	var focused: bool = panel.gui_get_focus_owner()==choice
	await tester.key(app,KEY_ENTER,panel); await layout()
	var popup: PopupMenu = choice.get_popup()
	var keyboard_open: bool = popup.visible
	var end_key_reaches_last: bool = false
	tester.check(focused and keyboard_open,"Keyboard opens151-choice portrait menu")
	if popup.visible:
		popup.grab_focus(); await layout()
		await native_key(KEY_END)
		end_key_reaches_last = popup.get_focused_item()==choice.item_count-1
		for index: int in choice.item_count:
			if popup.get_focused_item()==choice.item_count-1: break
			await native_key(KEY_DOWN)
		await native_key(KEY_ENTER); await layout()
	tester.check(choice.get_selected_id()==choice.get_item_id(choice.item_count-1),"Arrow keys reach last portrait")
	panel.change_page("card"); await layout(); choice = panel.controls.portrait
	var ancestor: Node = choice.get_parent()
	while ancestor!=null:
		if ancestor is ScrollContainer: ancestor.ensure_control_visible(choice)
		ancestor = ancestor.get_parent()
	await layout()
	var point: Vector2 = choice.get_global_rect().get_center()+Vector2(panel.position)
	var motion: InputEventMouseMotion = InputEventMouseMotion.new(); motion.position = point
	Input.parse_input_event(motion); await process_frame
	for down: bool in [true,false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.position = point; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = down
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		Input.parse_input_event(event); await process_frame
	await layout(); popup = choice.get_popup()
	var mouse_open: bool = popup.visible
	tester.check(mouse_open,"Input singleton mouse events open portrait menu")
	await tester.capture(app,directory,"portrait-input")
	if popup.visible: await tester.key(app,KEY_ESCAPE,popup)
	save_report("beta-portrait-ui",{"keyboardOpen":keyboard_open,"mouseOpen":mouse_open,"focused":focused,"choices":choice.item_count,"endKeyReachesLast":end_key_reaches_last})

func menu_cycles(app: Control) -> void:
	app._open_title(); app.trainer.open(app); await layout()
	var panel: AcceptDialog = app.trainer.dialog
	for page: String in ["card","achievements","dex","history","card"]:
		panel.change_page(page); await layout()
	var original: String = FileAccess.get_file_as_string(app.trainer.persistence.file_path)
	var nodes: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var orphans: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var samples: Array = []
	for index: int in 40:
		panel.change_page(["card","achievements","dex","history"][index%4]); await layout()
		panel.hide(); app.trainer.open(app); await layout()
		if index%10==0: samples.append({"cycle":index,"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"orphans":Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)})
	panel.change_page("card"); await layout()
	var after_nodes: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var after_orphans: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	tester.check(after_nodes<=nodes+4,"Forty profile cycles do not accumulate UI nodes")
	tester.check(after_orphans<=orphans+1,"Forty profile cycles do not accumulate orphan nodes")
	tester.check(FileAccess.get_file_as_string(app.trainer.persistence.file_path)==original,"Menu stress never writes profile")
	save_report("beta-cycles-ui",{"beforeNodes":nodes,"afterNodes":after_nodes,"beforeOrphans":orphans,"afterOrphans":after_orphans,"samples":samples})

func seed_controls(app: Control) -> void:
	var rewards: Array = []
	app._open_title(); await layout()
	tester.check(app.title_screen.controls["new"].accessibility_name=="Nueva aventura","Title exposes the current accessible button name")
	for attempt: int in 2:
		app.store = app.CampaignStore.new(directory.path_join("seed-ui-%d.dat" % attempt))
		app._show_oak(); await layout()
		var original: String = app.journey_seed.text
		tester.check(original.begins_with("kanto-") and not app.seed_options_open,"Fresh Oak uses automatic seed with options collapsed")
		await tester.click(app,app.travel_buttons.seed_options); await layout()
		tester.check(app.travel_buttons.seed_panel.is_visible_in_tree(),"Seed options open before exercising their controls")
		await tester.click(app,app.travel_buttons.random_seed); await layout()
		tester.check(app.journey_seed.text!=original and app.run.is_empty() and app.transactions.is_empty(),"Visible Generate changes only unstarted seed")
		for dimensions: Vector2i in [Vector2i(1024,720),Vector2i(1280,900)]:
			root.size = dimensions; await layout()
			tester.check(app.travel_buttons.random_seed.get_global_rect().end.x<=app.size.x and app.journey_seed.size.x>100,"Expanded seed controls fit "+str(dimensions))
		app.journey_seed.text = "  tactics-1  "
		await tester.click(app,app.travel_buttons.starter1); await layout()
		tester.check(app.run.seed=="tactics-1" and app.run.phase=="map","Manual seed is normalized when starting the campaign")
		app._event({"kind":"enter","at":app.run.revision}); await layout()
		app._event({"kind":"start-battle","at":app.run.revision}); await layout()
		for index: int in 220:
			if app.run.phase!="battle": break
			app._event({"kind":"battle","order":app.rules.choose_command(app.state),"at":app.run.revision})
			if index%8==0: await process_frame
		tester.check(app.run.phase=="capture","Current native opening reaches pending capture")
		if app.run.phase!="capture": break
		rewards.append(app.run.reward.duplicate(true))
		var before: Dictionary = app.run.duplicate(true)
		app._load_game(); await layout()
		tester.check(app.CampaignStore.equivalent(before,app.run),"Native reload preserves pending capture and RNG")
	tester.check(rewards.size()==2 and app.CampaignStore.equivalent(rewards[0],rewards[1]),"Two real current UI openings reproduce the same reward")
	if mode=="shop": await current_shop(app); return
	save_report("beta-seeds-ui",{"completedOpenings":rewards.size(),"clipboardVerified":false,"note":"Clipboard access unavailable in the sandbox. This replacement opens the current collapsed options and starts deployment explicitly."})

func current_shop(app: Control) -> void:
	if app.run.phase!="capture": save_report("beta-shop-ui",{"openingFailed":true}); return
	await tester.click(app,app.travel_buttons.capture); await layout()
	if app.action_review!=null and app.action_review.visible: await tester.key(app,KEY_ESCAPE,app.action_review)
	tester.check(app.run.phase=="shop" and app.kecleon.cards.size()==3,"Current natural shop has three products")
	tester.check(not app.travel_buttons.has("shop_evolution"),"Removed training shop is absent")
	var before: Dictionary = app.run.duplicate(true)
	for frame: int in 70: await process_frame
	tester.check(app.CampaignStore.equivalent(before,app.run),"Shop idle animation preserves campaign and RNG")
	for dimensions: Vector2i in [Vector2i(1024,720),Vector2i(1280,900)]:
		root.size = dimensions
		for scale_value: int in [100,150]:
			app.input_profile.set_preference("textScale",scale_value); app._apply_preferences(); await layout()
			for slot: int in 3:
				var card: Button = app.travel_buttons["stock_"+str(slot)]
				tester.check(card.is_visible_in_tree() and card.get_global_rect().end.x<=app.size.x,"Current product fits "+str(dimensions)+"/"+str(scale_value))
	app.input_profile.set_preference("textScale",100); app._apply_preferences(); await layout()
	await tester.click(app,app.travel_buttons.stock_detail_0); await layout()
	tester.check(app.action_review.visible and not app.action_review.content.text.is_empty(),"Current product detail opens")
	await tester.key(app,KEY_ESCAPE,app.action_review); await layout()
	tester.check(app.CampaignStore.equivalent(before,app.run),"Product inspection spends no money or RNG")
	if not app.travel_buttons.stock_0.disabled:
		var price: int = app.campaign.shop_data.items[app.run.stock[0].item].price
		await tester.click(app,app.travel_buttons.stock_0); await layout()
		tester.check(app.run.stock[0].sold and app.run.money==before.money-price,"Current stock purchase charges exactly once")
	for index: int in 2:
		if app.travel_buttons.reroll.disabled: break
		var cost: int = app.campaign.reroll_price(app.run)
		before = app.run.duplicate(true)
		await tester.click(app,app.travel_buttons.reroll); await layout()
		tester.check(app.run.money==before.money-cost and app.run.revision==before.revision+1,"Current reroll charges once")
		tester.check(app.campaign.reroll_price(app.run)>cost and app.run.stock.size()==3,"Reroll price increases and keeps three offers")
	await tester.click(app,app.travel_buttons.shop_supplies); await layout()
	tester.check(app.travel_buttons.has("buy_potion") and app.travel_buttons.has("buy_revive"),"Current medicine service is available")
	if not app.travel_buttons.buy_potion.disabled:
		before = app.run.duplicate(true)
		await tester.click(app,app.travel_buttons.buy_potion); await layout()
		tester.check(app.run.bag.potion==before.bag.potion+1,"Medicine purchase reaches bag")
	await tester.click(app,app.travel_buttons.shop_traits); await layout()
	tester.check(app.travel_buttons.has("buy_mint") and app.travel_buttons.has("buy_ability-capsule"),"Current traits service has mints and capsules")
	app._shop_page("gear"); await layout()
	app.input_profile.set_preference("reducedMotion",true); app._apply_preferences(); await layout()
	var merchant: Control = app.kecleon.actor
	merchant.react(); await layout()
	var draws: int = merchant.draw_count
	for frame: int in 20: await process_frame
	tester.check(merchant.frame==0 and merchant.reaction==0 and merchant.draw_count==draws,"Reduced motion stops current merchant redraws")
	before = app.run.duplicate(true)
	app._load_game(); await layout()
	tester.check(app.CampaignStore.equivalent(before,app.run) and app.save_warning.is_empty(),"Current shop actions replay exactly")
	await tester.capture(app,directory,"current-shop")
	save_report("beta-shop-ui",{"revision":app.run.revision,"scope":"Natural current shop; purchases only when affordable; no forced money or obsolete training service."})
