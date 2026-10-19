extends RefCounted

const Driver = preload("res://ui/qa_driver.gd")
const Store = preload("res://core/journey_store.gd")
const Policy = preload("res://ui/qa_journey_policy.gd")
var driver: RefCounted = Driver.new()
var policy: RefCounted = Policy.new()
var assertions: int = 0
var failures: Array[String] = []
var screenshots: Array[String] = []

func check(value: bool, message: String) -> void:
	assertions += 1
	if not value: failures.append(message)

func capture(app: Control, directory: String, name: String) -> void:
	await app.get_tree().process_frame
	await RenderingServer.frame_post_draw
	check(app.get_viewport().get_texture().get_image().save_png(directory.path_join(name+".png"))==OK,"Rendered "+name)
	screenshots.append(name+".png")

func run(app: Control, directory: String) -> void:
	app._show_oak()
	app.journey_seed.text = "tactics-1"
	app.travel_buttons.starter1.pressed.emit()
	check(app.run.edition==app.CURRENT_CHAPTER-4,"Current journey edition selected")
	var encountered: Array = []
	for index: int in 16000:
		var command: Dictionary = policy.choose(app.campaign,app.run)
		if command.is_empty(): break
		var expected: Dictionary = app.campaign.transact(app.run,command)
		check(expected.ok,"Accepted real UI order "+str(command.kind)+" "+str(expected.get("reason","")))
		if not expected.ok: break
		if command.kind=="battle" and app.rules.active(app.state).team=="ally":
			var tactical: Dictionary = command.order
			if tactical.kind=="move": app.board.focus_point(tactical.destination); driver.click(app,tactical.destination)
			elif tactical.kind=="attack":
				driver.choose_action(app,tactical.actionId)
				var target: Dictionary = app.rules.unit_by_id(app.state,int(tactical.target))
				app.board.focus_point(target)
				driver.hover(app,target)
				driver.click(app,target)
				if not app.pending.is_empty(): app.buttons.confirm.pressed.emit()
			else: app.buttons.finish.pressed.emit(); app.direction_buttons[int(tactical.facing)].pressed.emit()
		elif command.kind in ["enter","capture","continue"]: app.travel_buttons[command.kind].pressed.emit()
		elif command.kind=="travel": app.travel_buttons["travel_"+command.location].pressed.emit()
		elif command.kind=="destiny": app.travel_buttons["destiny_"+command.path].pressed.emit()
		elif command.kind=="buy": app.travel_buttons["buy_"+command.item].pressed.emit()
		elif command.kind=="level-up" or command.kind=="revive" or command.kind=="heal":
			app._roster_page("team",0)
			app._select_member(int(command.member))
			app.travel_buttons["heal_"+command.item if command.kind=="heal" else command.kind].pressed.emit()
		else: app._event(command)
		var matching: bool = Store.equivalent(app.run,expected.state)
		check(matching,"UI matches authoritative journey result: "+str(command))
		if not matching: break
		if command.kind=="enter" and app.campaign.locations[int(app.run.stage)].get("kind","")=="story":
			check(app.run.phase=="shop" and "surf" in app.run.flags,"Safari narrative enters shop without fake combat")
			await capture(app,directory,"safari")
		if command.kind=="enter" and app.run.phase=="battle":
			var identity: String = app.campaign.locations[int(app.run.stage)].id
			encountered.append(identity)
			if app.campaign.locations[int(app.run.stage)].get("leader",false) or encountered.size()==1: await capture(app,directory,identity)
			if identity=="erika":
				app.get_window().size = Vector2i(1024,720)
				await capture(app,directory,"erika-1024")
				check(app.timeline.get_parent() is ScrollContainer,"Large initiative queue can scroll")
				check(app.timeline.get_parent().get_global_rect().end.x<=app.size.x,"Queue stays inside minimum viewport")
				app.get_window().size = Vector2i(1280,900)
		if app.run.phase in ["defeat","ending"]: break
	check(app.run.phase in ["complete","ending"],"Natural journey completes")
	var snapshot: Dictionary = app.run.duplicate(true)
	app._load_game()
	check(Store.equivalent(app.run,snapshot),"Full journey reloads exactly")
	await capture(app,directory,"journey-result")
	var report: Dictionary = {"assertions":assertions,"failures":failures,"chapter":app.CURRENT_CHAPTER,"phase":app.run.phase,"cleared":app.run.cleared,"medals":app.run.medals,"transactions":app.transactions.size(),"encountered":encountered,"screenshots":screenshots}
	FileAccess.open(directory.path_join("journey-ui-result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	app.get_tree().quit(0 if failures.is_empty() else 1)
