extends RefCounted

const Profile = preload("res://ui/input_profile.gd")
const Store = preload("res://core/journey_store.gd")
var assertions: int = 0
var failures: Array[String] = []

func check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition: failures.append(label); print("INPUT_CHECK_FAILED: "+label)

func settle(app: Control) -> void:
	await app.get_tree().process_frame
	await app.get_tree().process_frame

func raw(app: Control, code: int, down: bool, echo: bool = false, viewport: Viewport = null, shift: bool = false) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code as Key
	event.pressed = down
	event.echo = echo
	event.shift_pressed = shift
	if code>=KEY_A and code<=KEY_Z: event.unicode = code if shift else code+32
	elif code>=KEY_0 and code<=KEY_9: event.unicode = code
	(viewport if viewport!=null else app.get_viewport()).push_input(event,true)
	await settle(app)

func key(app: Control, code: int, viewport: Viewport = null, shift: bool = false) -> void:
	await raw(app,code,true,false,viewport,shift)
	if viewport is Window and not viewport.visible:
		var parent: Node = viewport.get_parent()
		viewport = parent if parent is Window else app.get_viewport()
	await raw(app,code,false,false,viewport,shift)

func click(app: Control, control: Control) -> void:
	await settle(app)
	var viewport: Viewport = control.get_viewport()
	var point: Vector2 = control.get_global_rect().get_center()
	if viewport!=app.get_viewport() and viewport is Window and app.get_window().gui_embed_subwindows:
		point += Vector2(viewport.position)
		viewport = app.get_viewport()
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = point
	viewport.push_input(motion,true)
	for down: bool in [true,false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		viewport.push_input(event,true)
	await settle(app)

func focus_is(app: Control, control: Control) -> bool:
	return app.get_viewport().gui_get_focus_owner()==control

func run(app: Control, directory: String) -> void:
	app.get_window().gui_embed_subwindows = true
	app.store = Store.new(directory.path_join("input-session-%d.json" % Time.get_ticks_usec()))
	app._open_title()
	await settle(app)
	check(app.title_visible and focus_is(app,app.title_screen.controls["new"]),"New game has initial keyboard focus")
	await key(app,KEY_ENTER)
	check(app.run.is_empty() and focus_is(app,app.travel_buttons.starter1),"Oak restores focus after keyboard activation")
	await key(app,KEY_TAB)
	check(focus_is(app,app.travel_buttons.starter4),"Tab follows starter choices")
	await key(app,KEY_TAB,null,true)
	check(focus_is(app,app.travel_buttons.starter1),"Shift Tab returns to previous choice")
	await key(app,KEY_TAB,null,true)
	check(focus_is(app,app.journey_seed),"Seed is reachable backwards from starter")
	app.journey_seed.text = ""
	for code: int in [KEY_A,KEY_R,KEY_F,KEY_1,KEY_2,KEY_3]: await key(app,code)
	check(app.run.is_empty() and app.journey_seed.text=="arf123","Typing shortcut letters and digits edits text without gameplay orders")
	app.journey_seed.text = "tactics-1"
	await key(app,KEY_TAB)
	await key(app,KEY_ENTER)
	check(app.run.phase=="map" and focus_is(app,app.travel_buttons.enter),"Starter enters map with encounter focus")
	app.travel_buttons["member_1"].grab_focus()
	await key(app,KEY_ENTER)
	check(focus_is(app,app.travel_buttons["member_1"]),"Selecting a member retains its identity")
	var before: Dictionary = app.run.duplicate(true)
	await key(app,KEY_F6)
	check(focus_is(app,app.travel_buttons.roster_team),"Panel shortcut reaches team")
	await key(app,KEY_F6)
	check(focus_is(app,app.travel_buttons.enter),"Panel shortcut returns to encounter")
	await key(app,KEY_F6,null,true)
	check(focus_is(app,app.travel_buttons.roster_team),"Shift panel shortcut is available")
	await key(app,KEY_F6)
	check(Store.equivalent(before,app.run),"Panel navigation never mutates campaign")
	await key(app,KEY_ENTER)
	check(app.run.phase=="battle" and focus_is(app,app.board),"Battle receives keyboard focus")
	before = app.run.duplicate(true)
	var cursor: Vector2i = app.board.cursor
	await key(app,KEY_RIGHT)
	check(app.board.cursor.x==cursor.x+1,"Cursor uses configured direction")
	cursor = app.board.cursor
	await raw(app,KEY_RIGHT,true)
	await raw(app,KEY_RIGHT,true,true)
	await raw(app,KEY_RIGHT,false)
	check(app.board.cursor.x==cursor.x+2,"Only navigation can repeat")
	await key(app,KEY_F)
	await key(app,KEY_F6)
	check(app.direction_buttons.values().has(app.get_viewport().gui_get_focus_owner()),"Orientation panel shortcut only focuses visible directions")
	await key(app,KEY_ESCAPE)
	await key(app,KEY_A)
	check(app.action_page and focus_is(app,app.action_buttons.basic),"Ability menu focuses first available action")
	await key(app,KEY_ESCAPE)
	check(not app.action_page and focus_is(app,app.board),"Cancel returns to board")
	await click(app,app.buttons.actions)
	check(app.action_page and focus_is(app,app.action_buttons.basic),"Mouse menu also establishes keyboard focus")
	await key(app,KEY_ESCAPE)
	check(Store.equivalent(before,app.run),"Opening and cancelling abilities is pure")
	app._menu_selected(3)
	await settle(app)
	await key(app,KEY_F2)
	check(app.details_dialog.visible and not app.controls_dialog.visible,"An existing dialog contains the controls shortcut")
	await key(app,KEY_ESCAPE,app.details_dialog)
	check(not app.details_dialog.visible and focus_is(app,app.board),"Dialog cancellation restores original focus")
	await key(app,KEY_F2)
	check(app.controls_dialog.visible,"Controls open without leaving battle")
	var dialog: AcceptDialog = app.controls_dialog
	await settle(app)
	var dialog_before: Dictionary = app.run.duplicate(true)
	await key(app,KEY_TAB,dialog)
	await key(app,KEY_ENTER,dialog)
	await key(app,KEY_Z,dialog)
	check(app.input_profile.bindings.abilities.key==KEY_Z,"Native key capture saves new binding")
	check(app.buttons.actions.text.contains("Z"),"Visible shortcut follows remap")
	await key(app,KEY_ESCAPE,dialog)
	check(not dialog.visible and focus_is(app,app.board),"Closing controls restores original board focus")
	await key(app,KEY_Z)
	check(app.action_page,"New ability key works")
	await key(app,KEY_ESCAPE)
	await key(app,KEY_A)
	check(not app.action_page,"Previous ability key is no longer active")
	check(Store.equivalent(dialog_before,app.run),"Remap and navigation do not alter campaign or RNG")
	var loaded: RefCounted = Profile.new(app.input_profile.path)
	check(loaded.bindings.abilities.key==KEY_Z,"A fresh profile reloads persisted bindings")
	app.input_profile = loaded
	app.board.input_profile = loaded
	dialog.profile = loaded
	await key(app,KEY_F2)
	await click(app,dialog.bindings.abilities)
	await key(app,KEY_R,dialog)
	check(dialog.conflict_dialog.visible,"Conflicting binding asks before changing")
	check(app.input_profile.bindings.abilities.key==KEY_Z,"Conflict preview leaves bindings unchanged")
	await key(app,KEY_ESCAPE,dialog.conflict_dialog)
	check(not dialog.conflict_dialog.visible,"Conflict can be cancelled with keyboard")
	await click(app,dialog.bindings.abilities)
	await key(app,KEY_R,dialog)
	await key(app,KEY_ENTER,dialog.conflict_dialog)
	check(app.input_profile.bindings.abilities.key==KEY_R and app.input_profile.bindings.rectify.key==KEY_Z,"Explicit exchange preserves both actions")
	await key(app,KEY_ESCAPE,dialog)
	check(app.input_profile.reset_category("Combate"),"Category reset persists safely")
	app._input_labels()
	check(app.input_profile.bindings.abilities.key==KEY_A and app.input_profile.bindings.rectify.key==KEY_R,"Reset restores default battle bindings")
	check(not app.input_profile.rebind("abilities",{"key":KEY_ENTER}).ok,"Safety accept cannot be stolen")
	var turns: int = 0
	while app.run.phase=="battle" and turns<220:
		app._event({"kind":"battle","order":app.rules.choose_command(app.state),"at":app.run.revision})
		turns += 1
	if app.run.phase=="capture": app._event({"kind":"capture","at":app.run.revision})
	await settle(app)
	check(app.run.phase=="shop","Engine-only preparation reaches shop")
	if app.run.phase=="shop":
		app.travel_buttons.buy_potion.grab_focus()
		var quantity: int = app.run.bag.potion
		for index: int in 3:
			await key(app,KEY_ENTER)
			check(focus_is(app,app.travel_buttons.buy_potion) or app.travel_buttons.buy_potion.disabled,"Purchase retains logical focus or selects valid fallback")
		check(app.run.bag.potion==quantity+3,"Three fresh presses accept exactly three purchases")
		app.travel_buttons.buy_potion.grab_focus()
		quantity = app.run.bag.potion
		await raw(app,KEY_ENTER,true)
		for index: int in 4: await raw(app,KEY_ENTER,true,true)
		await raw(app,KEY_ENTER,false)
		check(app.run.bag.potion<=quantity+1,"Holding accept never repeats purchases")
		before = app.run.duplicate(true)
		await click(app,app.travel_buttons.roster_pc)
		check(focus_is(app,app.travel_buttons.roster_pc),"Empty PC tab retains keyboard focus")
		await key(app,KEY_TAB)
		check(app.get_viewport().gui_get_focus_owner()!=null,"Empty PC has an escape route by Tab")
		await click(app,app.travel_buttons.roster_team)
		check(Store.equivalent(before,app.run),"PC navigation is pure")
		var saved_run: Dictionary = app.run.duplicate(true)
		# Presentation-only fixtures; no fake campaign is ever saved or transacted.
		for count: int in [0,1,6,7,30]:
			app.run.reserve = []
			for index: int in count:
				var member: Dictionary = saved_run.party[0].duplicate(true)
				member.id = 500+index
				member.origin = "Fixture de navegación · %d" % index
				app.run.reserve.append(member)
			app._roster_page("pc",0)
			await settle(app)
			if count>0:
				app.travel_buttons.member_500.grab_focus()
				await key(app,KEY_ENTER)
				check(app.selected_member==500 and focus_is(app,app.travel_buttons.member_500),"Member identity survives selection in PC fixture %d" % count)
			else:
				app.travel_buttons.roster_pc.grab_focus()
				await key(app,KEY_ENTER)
				check(focus_is(app,app.travel_buttons.roster_pc),"Empty PC fixture remains navigable")
			if count>6:
				app.travel_buttons.pc_next.grab_focus()
				await key(app,KEY_ENTER)
				check(app.roster_offset==1 and focus_is(app,app.travel_buttons.pc_next) if count>12 else app.roster_offset==1 and app.get_viewport().gui_get_focus_owner()!=null,"Page transition preserves usable focus in fixture %d" % count)
				app.travel_buttons.pc_previous.grab_focus()
				await key(app,KEY_ENTER)
				check(app.roster_offset==0 and app.get_viewport().gui_get_focus_owner()!=null,"Previous PC page stays navigable")
		app.run = saved_run
		app._roster_page("team",0)
		await settle(app)
		await key(app,KEY_F2)
		await RenderingServer.frame_post_draw
		app.get_viewport().get_texture().get_image().save_png(directory.path_join("controls.png"))
		await key(app,KEY_ESCAPE,dialog)
	var invalid_path: String = directory.path_join("invalid-controls.json")
	var file: FileAccess = FileAccess.open(invalid_path,FileAccess.WRITE)
	file.store_string("{ broken")
	file.close()
	var invalid: RefCounted = Profile.new(invalid_path)
	check(not invalid.warning.is_empty() and invalid.bindings.accept.key==KEY_ENTER,"Invalid controls use safe defaults")
	check(FileAccess.get_file_as_string(invalid_path)=="{ broken","Invalid preferences are preserved on read")
	check(invalid.rebind("abilities",{"key":KEY_Z}).ok,"Valid change can replace preserved invalid preferences")
	var preserved: bool = false
	for name: String in DirAccess.get_files_at(directory):
		if name.begins_with("invalid-controls.json.invalid-"): preserved = true
	check(preserved,"Invalid original is copied before replacement")
	app.input_profile.install()
	var output: Dictionary = {"assertions":assertions,"failures":failures,"scope":"Native synthetic viewport keys and pointer; shop prepared by pure engine; no human saves"}
	var report: FileAccess = FileAccess.open(directory.path_join("input-ui-result.json"),FileAccess.WRITE)
	report.store_string(JSON.stringify(output,"\t"))
	report.close()
	print("INPUT_QA "+JSON.stringify(output))
	app.get_tree().quit(0 if failures.is_empty() else 1)
