extends RefCounted

const Store = preload("res://core/journey_store.gd")
const Policy = preload("res://ui/qa_journey_policy.gd")
var assertions: int = 0
var failures: Array[String] = []
var screenshots: Array[String] = []

func check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition: failures.append(label); print("UI_CHECK_FAILED: "+label)

func settle(app: Control) -> void:
	await app.get_tree().process_frame
	await app.get_tree().process_frame

func click(app: Control, button: Button) -> void:
	check(button.is_visible_in_tree() and not button.disabled,"Visible enabled control: "+button.text)
	await settle(app)
	if button.get_viewport()!=app.get_viewport():
		# Dialogs own a Window/viewport; use their native button signal there.
		if button.toggle_mode: button.button_pressed = not button.button_pressed
		else: button.pressed.emit()
		await settle(app)
		return
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = button.get_global_rect().get_center()
	button.get_viewport().push_input(motion,true)
	for pressed: bool in [true,false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.position = button.get_global_rect().get_center()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		button.get_viewport().push_input(event,true)
	await settle(app)

func capture(app: Control, directory: String, label: String) -> void:
	await settle(app)
	await RenderingServer.frame_post_draw
	check(app.get_viewport().get_texture().get_image().save_png(directory.path_join(label+".png"))==OK,"Rendered "+label)
	screenshots.append(label+".png")

func run(app: Control, directory: String) -> void:
	app.get_window().gui_embed_subwindows = true
	var path: String = directory.path_join("session-%d.json" % Time.get_ticks_usec())
	app.store = Store.new(path)
	app._open_title()
	await settle(app)
	check(app.title_visible and app.title_screen.visible,"Normal title is visible")
	check(app.title_screen.controls["continue"].disabled and not FileAccess.file_exists(path),"Empty title disables Continue and writes nothing")
	check(app.get_viewport().gui_get_focus_owner()==app.title_screen.controls["new"],"Keyboard starts on New game")
	await capture(app,directory,"title-1280")
	app.get_window().size = Vector2i(1024,720)
	await settle(app)
	check(app.title_screen.controls["quit"].get_global_rect().end.x<=app.size.x,"Title footer fits minimum width")
	check(app.title_screen.controls["new"].get_global_rect().end.y<app.size.y-60,"Title commands fit minimum height")
	await capture(app,directory,"title-1024")
	await click(app,app.title_screen.controls["new"])
	check(not app.title_visible and app.run.is_empty(),"New game opens Oak")
	app.journey_seed.text = "tactics-1"
	await click(app,app.travel_buttons.starter1)
	check(app.run.get("edition",0)==18 and FileAccess.file_exists(path),"Oak creates and saves unchanged rules18")
	var saved: Dictionary = app.run.duplicate(true)
	var bytes: String = FileAccess.get_file_as_string(path)
	await click(app,app.travel_buttons.home)
	check(app.title_visible and not app.title_screen.controls["continue"].disabled,"Home offers Continue after starting")
	await click(app,app.title_screen.controls["new"])
	check(app.campaign_confirm.visible,"Existing campaign asks before choosing a replacement")
	await click(app,app.campaign_confirm.get_cancel_button())
	check(FileAccess.get_file_as_string(path)==bytes and Store.equivalent(app.run,saved),"Cancelling New preserves file and in-memory campaign")
	await click(app,app.title_screen.controls["new"])
	await click(app,app.campaign_confirm.get_ok_button())
	check(app.run.is_empty(),"Confirmed New opens selection without overwriting save")
	await click(app,app.travel_buttons.home)
	check(Store.equivalent(app.run,saved) and FileAccess.get_file_as_string(path)==bytes,"Back from Oak restores previous campaign without reroll")
	await click(app,app.title_screen.controls["options"])
	await click(app,app.options_buttons["Sonidos"])
	check(app.muted,"Sound toggle applies from title")
	await click(app,app.options_buttons["Sonidos"])
	await click(app,app.options_buttons["Animaciones"])
	check(app.reduced_motion,"Reduced motion applies from title")
	await click(app,app.options_dialog.get_ok_button())
	await click(app,app.title_screen.controls["continue"])
	check(Store.equivalent(app.run,saved),"Warm Continue keeps exact state")
	await click(app,app.travel_buttons.enter)
	check(app.run.phase=="battle","Map enters actual battle")
	app._menu_selected(8)
	saved = app.run.duplicate(true)
	app.qa_running = false
	app._process(3)
	await settle(app)
	check(Store.equivalent(app.run,saved),"Title pauses rival processing and never advances battle")
	app.qa_running = true
	await click(app,app.title_screen.controls["continue"])
	var target: Dictionary = app.state.units.filter(func(u):return u.team=="enemy")[0]
	app._hover_tile(target)
	await settle(app)
	var actor_panel: Control = app.actor_portrait.get_parent().get_parent().get_parent()
	check(not actor_panel.get_global_rect().intersects(app.hint.get_parent().get_global_rect()),"Actor card and hint do not overlap at1024")
	check(not app.target_panel.get_global_rect().intersects(app.hint.get_parent().get_global_rect()),"Target card and hint do not overlap at1024")
	check(app.target_panel.get_global_rect().end.x<=app.size.x,"Target card stays in viewport")
	await capture(app,directory,"battle-1024")
	var policy: RefCounted = Policy.new()
	for _step: int in 150:
		if app.run.phase=="shop" or app.run.phase=="defeat": break
		var command: Dictionary = policy.choose(app.campaign,app.run)
		if command.is_empty(): break
		app._event(command)
	check(app.run.phase=="shop","Natural first encounter reaches shop")
	if app.run.phase=="shop":
		var before: Dictionary = app.run.duplicate(true)
		await click(app,app.travel_buttons.shop_gear)
		check(app.shop_sections.gear.is_visible_in_tree() and not app.shop_sections.supplies.is_visible_in_tree(),"Only selected shop category is visible")
		await click(app,app.travel_buttons.shop_traits)
		check(app.travel_buttons.buy_mint.is_visible_in_tree(),"Mints reachable in Traits")
		await click(app,app.travel_buttons.shop_supplies)
		check(Store.equivalent(app.run,before),"Shop navigation preserves full state and RNG")
		check(app.travel_buttons["continue"].get_global_rect().end.y<=app.size.y and app.travel_buttons["continue"].is_visible_in_tree(),"Continue remains visible outside the shop scroll")
		var expected: Dictionary = app.campaign.transact(app.run,{"kind":"buy","item":"potion","at":app.run.revision})
		await click(app,app.travel_buttons.buy_potion)
		check(expected.ok and Store.equivalent(app.run,expected.state),"Visible shop purchase matches unchanged domain")
		check(app.travel_buttons["member_1"].icon!=null,"Team cards reuse original portraits")
		await capture(app,directory,"shop-1024")
		app.get_window().size = Vector2i(1280,900)
		await capture(app,directory,"shop-1280")
		saved = app.run.duplicate(true)
		app.run = {}; app.state = {}; app.transactions = []
		app.store = Store.new(path)
		app._open_title()
		await click(app,app.title_screen.controls["continue"])
		check(Store.equivalent(app.run,saved),"Cold Continue replays saved purchases and party exactly")
	var broken: String = path+".broken"
	FileAccess.open(broken,FileAccess.WRITE).store_string("{broken")
	app.run = {}; app.state = {}; app.transactions = []
	app.store = Store.new(broken)
	app._open_title()
	await click(app,app.title_screen.controls["continue"])
	check(app.title_visible and not app.title_screen.notice.text.is_empty(),"Failed Continue keeps title and explains the error")
	check(FileAccess.get_file_as_string(broken)=="{broken","Failed Continue preserves corrupt bytes")
	await capture(app,directory,"title-invalid-save")
	var report: Dictionary = {"assertions":assertions,"failures":failures,"version":ProjectSettings.get_setting("application/config/version"),"screenshots":screenshots,"rulesEdition":18,"battlePaused":true,"savePreserved":true,"minimumViewport":"1024x720"}
	FileAccess.open(directory.path_join("interface-ui-result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	app.get_tree().quit(0 if failures.is_empty() else 1)
