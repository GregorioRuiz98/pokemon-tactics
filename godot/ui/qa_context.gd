extends "res://ui/qa_input.gd"

const Journey = preload("res://core/journey_run.gd")
var screenshots: Array[String] = []
var fixture_serial: int = 0

func capture(app: Control, directory: String, name: String) -> void:
	await settle(app)
	RenderingServer.force_draw()
	check(app.get_viewport().get_texture().get_image().save_png(directory.path_join(name+".png"))==OK,"Rendered "+name)
	screenshots.append(name+".png")

func pointer(app: Control, point: Vector2, down: bool, button: int = MOUSE_BUTTON_LEFT) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.position = point
	event.button_index = button as MouseButton
	event.pressed = down
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if down and button==MOUSE_BUTTON_LEFT else (MOUSE_BUTTON_MASK_MIDDLE if down and button==MOUSE_BUTTON_MIDDLE else 0)
	app.get_viewport().push_input(event,true)
	await settle(app)

func tile(app: Control, point: Dictionary) -> void:
	app.board.focus_point(point)
	await settle(app)
	var screen: Vector2 = app.board.center(point)
	await pointer(app,screen,true)
	await pointer(app,screen,false)

func motion(app: Control, point: Vector2, delta: Vector2 = Vector2.ZERO, mask: int = 0) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = point
	event.relative = delta
	event.button_mask = mask as MouseButtonMask
	app.get_viewport().push_input(event,true)
	await settle(app)

func alt_key(app: Control, code: int) -> void:
	for down: bool in [true,false]:
		var event: InputEventKey = InputEventKey.new()
		event.keycode = code as Key
		event.pressed = down
		event.alt_pressed = true
		app.get_viewport().push_input(event,true)
		await settle(app)

func expect_order(app: Control, before: Dictionary, order: Dictionary, label: String) -> void:
	var expected: Dictionary = app.campaign.transact(before,{"kind":"battle","order":order,"at":before.revision})
	check(expected.ok and Store.equivalent(app.run,expected.get("state",{})),label)
	check(app.save_warning.is_empty(),label+" saved before feedback")

func fixture(app: Control, directory: String, move: String = "defense-curl", width: int = 16) -> void:
	# Explicit synthetic interaction fixtures, never presented as natural victories/replays.
	fixture_serial += 1
	app.campaign = Journey.new(22)
	app.rules = app.campaign.engine
	app.run = app.campaign.create("context-fixture",1)
	app.run.mapSize = width
	app.run.phase = "battle"
	app.run.battle = app.rules.encounter(app.run,app.campaign.locations[0])
	var actor: Dictionary = app.rules.member_unit(app.campaign.progression.create_member(1,1,"Fixture",30),{"x":5,"y":8})
	var ally: Dictionary = app.rules.member_unit(app.campaign.progression.create_member(2,7,"Fixture",30),{"x":6,"y":9})
	var enemy: Dictionary = app.rules.member_unit(app.campaign.progression.create_member(10000,134,"Fixture",30),{"x":6,"y":8})
	var other: Dictionary = enemy.duplicate(true)
	other.id = 10001
	other.x = 7
	actor.moves = [move]
	actor.tp = 5
	actor.knownMoves = [move]
	actor.ability = "overgrow"
	enemy.ability = "run-away"
	other.ability = "run-away"
	enemy.team = "enemy"
	other.team = "enemy"
	app.state = app.run.battle
	app.state.units = [actor,ally,enemy,other]
	app.state.queue = [1,10000,2,10001]
	app.state.completed = []
	app.state.moved = false
	app.state.acted = false
	for row: Array in app.state.board: row.fill(0)
	for row: Array in app.state.heights: row.fill(0)
	app.run.battleInitial = app.state.duplicate(true)
	app.transactions = []
	app.history = []
	app.store = Store.new(directory.path_join("synthetic-%d.json" % fixture_serial))
	app.title_visible = false
	app.combat_feedback.clear()
	app.pending = {}
	app.selecting = "auto"
	app.action_page = false
	app.selected_action = "basic"
	app.board.camera_mode = false
	app.board.encounter_key = ""
	app._prepare_campaign_assets()
	app._refresh()
	app.board.cursor = Vector2i(5,8)
	app.board.grab_focus()
	await settle(app)

func run(app: Control, directory: String) -> void:
	app.get_window().gui_embed_subwindows = true
	app.input_profile = Profile.new(directory.path_join("context-controls-%d.json" % Time.get_ticks_usec()))
	app.board.input_profile = app.input_profile
	app.controls_dialog.profile = app.input_profile
	app._input_labels()
	await fixture(app,directory)
	var before: Dictionary = app.run.duplicate(true)
	var journal: Array = app.transactions.duplicate(true)
	await key(app,KEY_2)
	check(app.selected_action=="defense-curl" and not app.state.acted,"Selecting own support only prepares it")
	check(app.target_panel.visible and app.target_info.text.contains("Defensa"),"Own support forecast is visible")
	await key(app,KEY_E)
	check(app.board.cursor==Vector2i(5,8),"Target cycling can select the actor for own support")
	await key(app,KEY_ESCAPE)
	check(Store.equivalent(before,app.run) and Store.equivalent(journal,app.transactions),"Cancel own support preserves complete campaign, journal and RNG")
	await click(app,app.buttons.actions)
	await click(app,app.action_buttons["defense-curl"])
	check(Store.equivalent(before,app.run),"Mouse ability menu also prepares without acting")
	await key(app,KEY_ENTER)
	expect_order(app,before,{"kind":"attack","target":1,"actionId":"defense-curl"},"Explicit own support acceptance matches resolver")
	check(app.transactions.size()==1,"Own support records one command")
	before = app.run.duplicate(true)
	await key(app,KEY_R)
	check(Store.equivalent(before,app.run),"Action cannot be rectified")
	await key(app,KEY_LEFT)
	await key(app,KEY_ENTER)
	expect_order(app,before,{"kind":"move","destination":{"x":4,"y":8}},"Act then move uses direct keyboard movement")
	check(app.interaction_context()=="facing","Move and action automatically open orientation")
	before = app.run.duplicate(true)
	await key(app,KEY_R)
	check(Store.equivalent(before,app.run),"Act then move never unlocks rectify")
	var cursor: Vector2i = app.board.cursor
	await key(app,KEY_UP)
	check(app.facing_choice==4 and app.board.cursor==cursor,"Facing arrows preview direction without moving cursor")
	await key(app,KEY_ESCAPE)
	check(Store.equivalent(before,app.run) and app.selecting=="auto","Cancel facing does not finish or restore movement")
	await key(app,KEY_F)
	await key(app,KEY_RIGHT)
	await raw(app,KEY_ENTER,true)
	expect_order(app,before,{"kind":"finish","facing":2},"Keyboard facing acceptance matches resolver")
	var finished: Dictionary = app.run.duplicate(true)
	await raw(app,KEY_ENTER,true,true)
	await raw(app,KEY_ENTER,false)
	check(Store.equivalent(finished,app.run),"Held accept does not cross into the next activation")
	await fixture(app,directory)
	before = app.run.duplicate(true)
	await key(app,KEY_UP)
	await key(app,KEY_RIGHT)
	await key(app,KEY_ENTER)
	expect_order(app,before,{"kind":"move","destination":{"x":6,"y":7}},"Direct keyboard movement matches resolver")
	var moved: Dictionary = app.run.duplicate(true)
	await key(app,KEY_R)
	var revised: Dictionary = app.campaign.transact(moved,{"kind":"rectify","at":moved.revision})
	check(revised.ok and Store.equivalent(app.run,revised.state) and Store.equivalent(app.state,before.battle),"R restores movement only, exact state and RNG")
	await tile(app,{"x":6,"y":7})
	check(Store.equivalent(app.state,moved.battle),"Mouse and keyboard movement have identical full battle results")
	before = app.run.duplicate(true)
	await key(app,KEY_1)
	await key(app,KEY_E)
	check(app.board.cursor==Vector2i(6,8) and app.target_info.text.contains("Vaporeon"),"E chooses first valid target with name and forecast")
	await key(app,KEY_Q)
	check(app.board.cursor==Vector2i(6,8),"Q uses the same stable legal target set")
	cursor = app.board.cursor
	await motion(app,app.board.center({"x":7,"y":8}))
	check(app.board.cursor==cursor and app.target_info.text.contains("Vaporeon"),"Hover cannot steal keyboard target or forecast")
	check(Store.equivalent(before,app.run),"Ability/target browsing consumes no commands or RNG")
	await key(app,KEY_ENTER)
	expect_order(app,before,{"kind":"attack","target":10000,"actionId":"basic"},"Keyboard target acceptance executes selected action")
	before = app.run.duplicate(true)
	await key(app,KEY_R)
	check(Store.equivalent(before,app.run),"Move then attack locks rectification")
	await capture(app,directory,"keyboard-facing")
	await fixture(app,directory)
	before = app.run.duplicate(true)
	await key(app,KEY_F)
	check(app.hint.text.contains("Movimiento sin usar") and app.hint.text.contains("Acción sin usar"),"Early finish shows unused movement and action")
	await pointer(app,Vector2(950,700),true)
	await pointer(app,Vector2(950,700),false)
	check(Store.equivalent(before,app.run),"Click outside tactical area never finishes")
	await key(app,KEY_ESCAPE)
	await key(app,KEY_F2)
	await settle(app)
	await click(app,app.controls_dialog.confirmation)
	check(app.input_profile.confirmation_mode=="safe","Safe mode can be chosen in native controls")
	check(Profile.new(app.input_profile.path).confirmation_mode=="safe","Safe mode persists independently of campaign")
	await capture(app,directory,"confirmation-preference")
	await key(app,KEY_ESCAPE,app.controls_dialog)
	await tile(app,{"x":6,"y":8})
	check(not app.pending.is_empty() and Store.equivalent(before,app.run),"Safe mode previews a legal attack without committing")
	await key(app,KEY_ESCAPE)
	check(app.pending.is_empty() and Store.equivalent(before,app.run),"Cancelling safe confirmation is pure")
	await tile(app,{"x":6,"y":8})
	await key(app,KEY_ENTER)
	expect_order(app,before,{"kind":"attack","target":10000,"actionId":"basic"},"Safe mode accepts exactly once")
	check(app.pending.is_empty() and app.transactions.size()==1,"Safe mode never requests duplicate confirmation")
	app.input_profile.confirmation_mode = "fast"
	check(app.input_profile.save(),"Restore fast preference")
	for mode: String in ["fast","safe"]:
		await fixture(app,directory,"self-destruct")
		app.input_profile.confirmation_mode = mode
		before = app.run.duplicate(true)
		await key(app,KEY_2)
		await key(app,KEY_E)
		await key(app,KEY_ENTER)
		check(not app.pending.is_empty() and Store.equivalent(before,app.run),"Risk requires confirmation in "+mode)
		check(app.hint.text.contains("coste propio"),"Lethal self cost explicitly named in "+mode)
		await capture(app,directory,"risk-"+mode)
		await key(app,KEY_ESCAPE)
		check(Store.equivalent(before,app.run),"Cancelling lethal/friendly attack is pure in "+mode)
		await fixture(app,directory,"earthquake")
		app.input_profile.confirmation_mode = mode
		before = app.run.duplicate(true)
		await key(app,KEY_2)
		await key(app,KEY_E)
		var target: int = app._unit_at({"x":app.board.cursor.x,"y":app.board.cursor.y}).get("id",-1)
		await key(app,KEY_ENTER)
		check(not app.pending.is_empty() and Store.equivalent(before,app.run),"Friendly area requires one confirmation in "+mode)
		check(app.hint.text.contains("aliados"),"Friendly area explicitly named in "+mode)
		await key(app,KEY_ENTER)
		expect_order(app,before,{"kind":"attack","target":target,"actionId":"earthquake"},"Friendly confirmation executes resolver once in "+mode)
	app.input_profile.confirmation_mode = "fast"
	await fixture(app,directory)
	before = app.run.duplicate(true)
	await tile(app,{"x":6,"y":9})
	check(Store.equivalent(before,app.run) and not app.hint.text.is_empty(),"Occupied ally cannot be a movement destination or basic enemy target")
	await key(app,KEY_1)
	await tile(app,{"x":7,"y":8})
	check(Store.equivalent(before,app.run) and not app.hint.text.is_empty(),"Out of range target rejects without cost")
	app.state.units[0].tp = 0
	before = app.run.duplicate(true)
	await key(app,KEY_2)
	check(Store.equivalent(before,app.run) and app.hint.text.contains("PT insuficientes"),"Zero PT gives visible reason without a command")
	app.state.units[0].tp = 5
	app.state.units[0].status = {"kind":"sleep","remaining":2}
	before = app.run.duplicate(true)
	await tile(app,{"x":6,"y":8})
	check(Store.equivalent(before,app.run) and app.hint.text.contains("duerme"),"Status restriction gives reason without spending an action")
	await fixture(app,directory,"growl")
	app.state.units[3].x = 5
	app.state.units[3].y = 7
	before = app.run.duplicate(true)
	await key(app,KEY_2)
	await key(app,KEY_E)
	check(app.board.cursor==Vector2i(6,8),"Stable target order starts with first legal ID")
	await key(app,KEY_E)
	check(app.board.cursor==Vector2i(5,7),"Next target skips allied units")
	await key(app,KEY_Q)
	check(app.board.cursor==Vector2i(6,8),"Previous target reverses stable ordering")
	await raw(app,KEY_E,true)
	await raw(app,KEY_E,true,true)
	await raw(app,KEY_E,false)
	check(app.board.cursor==Vector2i(5,7) and Store.equivalent(before,app.run),"Held target shortcut neither repeats nor acts")
	check(app.input_profile.rebind("next_target",{"key":KEY_T}).ok,"Target navigation is configurable")
	await key(app,KEY_T)
	check(app.board.cursor==Vector2i(6,8),"Remapped target key drives same selection")
	check(app.input_profile.reset_category("Combate"),"Restore primary combat controls")
	await fixture(app,directory)
	before = app.run.duplicate(true)
	app.board.grab_focus()
	await key(app,KEY_F6)
	cursor = app.board.cursor
	await key(app,KEY_E)
	check(app.board.cursor==cursor and Store.equivalent(before,app.run),"Target shortcuts are inactive in GUI controls")
	await key(app,KEY_F6)
	for width: int in [16,24]:
		await fixture(app,directory,"defense-curl",width)
		before = app.run.duplicate(true)
		cursor = app.board.cursor
		var anchor: Vector2 = app.board.anchor
		await alt_key(app,KEY_RIGHT)
		check(app.board.anchor!=anchor and app.board.cursor==cursor,"Alt arrow pans without cursor movement on "+str(width))
		anchor = app.board.anchor
		await key(app,KEY_P)
		await key(app,KEY_DOWN)
		check(app.board.camera_mode and app.board.anchor!=anchor and app.board.cursor==cursor,"P mode pans without holding modifier on "+str(width))
		await key(app,KEY_ENTER)
		check(Store.equivalent(before,app.run),"Accept in camera mode never issues an order")
		await key(app,KEY_P)
		anchor = app.board.anchor
		await click(app,app.camera_buttons.left)
		check(app.board.anchor!=anchor and focus_is(app,app.board),"Mouse cruciform pans and returns focus on "+str(width))
		await key(app,KEY_C)
		anchor = app.board.anchor
		check(not app.board.manual_camera,"Center restores active tracking")
		var screen: Vector2 = app.board.play_area().get_center()
		await pointer(app,screen,true,MOUSE_BUTTON_MIDDLE)
		await motion(app,screen+Vector2(60,0),Vector2(60,0),MOUSE_BUTTON_MASK_MIDDLE)
		await pointer(app,screen+Vector2(60,0),false,MOUSE_BUTTON_MIDDLE)
		check(app.board.anchor!=anchor and Store.equivalent(before,app.run),"Middle drag release never acts on "+str(width))
		await key(app,KEY_C)
		screen = app.board.center({"x":4,"y":8})
		await pointer(app,screen,true)
		await motion(app,screen+Vector2(30,0),Vector2(30,0),MOUSE_BUTTON_MASK_LEFT)
		await pointer(app,screen+Vector2(30,0),false)
		check(Store.equivalent(before,app.run),"Left drag threshold prevents accidental movement on "+str(width))
		var zoom: float = app.board.zoom
		await key(app,KEY_EQUAL)
		check(app.board.zoom>zoom,"Plus zooms camera independently of text on "+str(width))
		await key(app,KEY_MINUS)
		await key(app,KEY_F)
		await key(app,KEY_P)
		await key(app,KEY_RIGHT)
		await key(app,KEY_ENTER)
		check(app.board.camera_mode and Store.equivalent(before,app.run),"Camera mode takes priority over facing acceptance on "+str(width))
		await key(app,KEY_P)
		await key(app,KEY_UP)
		check(app.facing_choice==4,"Leaving camera restores facing keys on "+str(width))
		await key(app,KEY_ESCAPE)
		anchor = app.board.anchor
		cursor = app.board.cursor
		await key(app,KEY_F2)
		app.qa_running = false
		app._process(3.0)
		app.qa_running = true
		await key(app,KEY_ESCAPE,app.controls_dialog)
		check(app.board.anchor==anchor and app.board.cursor==cursor and Store.equivalent(before,app.run),"Modal preserves selection, camera and game state on "+str(width))
		await capture(app,directory,"camera-"+str(width))
	# Genuine campaign journal/replay, separate from the explicit fixtures above.
	app.store = Store.new(directory.path_join("natural-%d.json" % Time.get_ticks_usec()))
	app._show_oak()
	app.journey_seed.text = "tactics-1"
	app.travel_buttons.starter1.pressed.emit()
	app.travel_buttons.enter.pressed.emit()
	await settle(app)
	before = app.run.duplicate(true)
	var route: Dictionary = app.board.available.values()[0]
	var destination: Dictionary = route.path.back()
	await tile(app,destination)
	check(app.state.moved,"Natural encounter accepts native mouse movement")
	await key(app,KEY_R)
	check(Store.equivalent(before.battle,app.state),"Natural movement rectification restores original battle")
	var saved: Dictionary = app.run.duplicate(true)
	app._load_game()
	check(Store.equivalent(saved,app.run) and app.save_warning.is_empty(),"Natural journal reconstructs exact full campaign after native events")
	var output: Dictionary = {"assertions":assertions,"failures":failures,"screenshots":screenshots,"syntheticFixtures":true,"naturalReplay":true,"scope":"Native viewport key/pointer events; isolated saves; no human input or balance claims"}
	FileAccess.open(directory.path_join("context-ui-result.json"),FileAccess.WRITE).store_string(JSON.stringify(output,"\t"))
	print("CONTEXT_QA "+JSON.stringify(output))
	app.get_tree().quit(0 if failures.is_empty() else 1)
