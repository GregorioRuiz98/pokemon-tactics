extends SceneTree

var app: Control
var observations: Array = []
var directory: String = ""

func _initialize() -> void:
	call_deferred("run")

func settle() -> void:
	await process_frame
	await process_frame

func focused() -> Dictionary:
	var control: Control = root.gui_get_focus_owner()
	if control==null: return {"owner":null}
	return {"owner":str(control.get_path()),"class":control.get_class(),"text":control.get("text"),"visible":control.is_visible_in_tree()}

func key(code: int, repeated: bool = false) -> void:
	for down: bool in [true,false]:
		var event: InputEventKey = InputEventKey.new()
		event.keycode = code
		event.pressed = down
		event.echo = repeated and down
		root.push_input(event,true)
	await settle()

func note(label: String, data: Dictionary) -> void:
	observations.append({"test":label,"data":data})
	print(label+": "+JSON.stringify(data))

func run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--audit-dir="): directory = argument.trim_prefix("--audit-dir=")
	if directory.is_empty(): quit(2); return
	DirAccess.make_dir_recursive_absolute(directory)
	app = load("res://scenes/campaign.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.qa_running = true
	app.store = load("res://core/journey_store.gd").new(directory.path_join("probe-save.json"))
	note("title_initial_focus",focused())
	await key(KEY_ENTER)
	note("title_enter_to_oak",{"oak":not app.title_visible and app.run.is_empty(),"focus":focused()})
	app.journey_seed.text = "tactics-1"
	app.travel_buttons.starter1.grab_focus()
	await key(KEY_ENTER)
	note("starter_keyboard_activation",{"phase":app.run.get("phase"),"focus":focused()})
	app.travel_buttons["member_1"].grab_focus()
	note("member_focus_before",focused())
	await key(KEY_ENTER)
	note("member_focus_after",focused())
	app.travel_buttons.enter.grab_focus()
	await key(KEY_ENTER)
	note("battle_entry_focus",focused())
	root.size = Vector2i(1024,720)
	await settle()
	note("minimum_window_layout",{"window":str(root.size),"app":str(app.size),"contentScale":str(root.content_scale_size),"actorFont":app.actor_info.get_theme_font_size("font_size"),"targetFont":app.target_info.get_theme_font_size("font_size"),"boardSize":str(app.board.size)})
	var cursor: Vector2i = app.board.cursor
	var before: Vector2 = app.board.center({"x":cursor.x,"y":cursor.y})
	await key(KEY_RIGHT)
	var after: Vector2 = app.board.center({"x":app.board.cursor.x,"y":app.board.cursor.y})
	note("cursor_right_screen_direction",{"before":str(cursor),"after":str(app.board.cursor),"screenDelta":str(after-before)})
	cursor = app.board.cursor
	await key(KEY_RIGHT,true)
	note("cursor_held_repeat",{"before":str(cursor),"after":str(app.board.cursor)})
	await key(KEY_A)
	note("abilities_open_hotkey",{"open":app.action_page,"focus":focused()})
	await key(KEY_TAB)
	note("abilities_first_tab",focused())
	app._cancel()
	app.buttons.actions.grab_focus()
	await key(KEY_ENTER)
	note("abilities_open_keyboard_button",{"open":app.action_page,"focus":focused()})
	await key(KEY_ESCAPE)
	note("abilities_cancel",{"open":app.action_page,"focus":focused()})
	# Pure engine decisions prepare a shop fixture; this is not a keyboard-only playthrough.
	var turns: int = 0
	while app.run.phase=="battle" and turns<220:
		app._event({"kind":"battle","order":app.rules.choose_command(app.state),"at":app.run.revision})
		turns += 1
	if app.run.phase=="capture": app._event({"kind":"capture","at":app.run.revision})
	note("shop_fixture",{"phase":app.run.phase,"orders":turns})
	if app.run.phase=="shop":
		app.travel_buttons.buy_potion.grab_focus()
		note("purchase_focus_before",focused())
		var count: int = app.run.bag.potion
		await key(KEY_ENTER)
		note("purchase_focus_after",{"bagBefore":count,"bagAfter":app.run.bag.potion,"focus":focused()})
		app.travel_buttons.shop_gear.grab_focus()
		await key(KEY_ENTER)
		note("shop_tab_focus_after",focused())
		app.travel_buttons.roster_pc.grab_focus()
		await key(KEY_ENTER)
		note("pc_tab_focus_after",focused())
	app._open_title()
	await settle()
	app._title_options()
	await settle()
	app.options_buttons["Sonidos"].button_pressed = false
	app.options_buttons["Animaciones"].button_pressed = false
	note("settings_toggled",{"muted":app.muted,"reducedMotion":app.reduced_motion})
	app.queue_free()
	await settle()
	app = load("res://scenes/campaign.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.qa_running = true
	note("settings_fresh_scene",{"muted":app.muted,"reducedMotion":app.reduced_motion})
	var report: FileAccess = FileAccess.open(directory.path_join("observations.json"),FileAccess.WRITE)
	report.store_string(JSON.stringify({"version":"0.22.1","engine":Engine.get_version_info(),"method":"Synthetic native viewport keyboard events; pure engine preparation for shop; no human save","observations":observations},"  "))
	report.close()
	quit(0)
