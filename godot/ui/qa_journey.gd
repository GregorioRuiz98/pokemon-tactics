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
	var final_path: String = "birds"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--journey-final="): final_path = argument.trim_prefix("--journey-final=")
	var origin: String = "fresh"
	if app.CURRENT_CHAPTER>=22:
		if final_path=="birds":
			var delivered: String = directory.get_base_dir().get_base_dir().path_join("qa-sprint-21/journey-full.json")
			check(DirAccess.copy_absolute(delivered,app.store.file_path)==OK,"Copy delivered completed ending")
			app._load_game()
			var previous: Dictionary = app.run.duplicate(true)
			check(app.travel_buttons.has("upgrade"),"Finished campaign offers safe update")
			app.travel_buttons.upgrade.pressed.emit()
			check(app.run.phase=="ending" and app.run.finalPath==previous.finalPath and Store.equivalent(app.run.party,previous.party),"Update preserves completed ending and team")
			await capture(app,directory,"updated-ending")
		var checkpoint: String = directory.get_base_dir().get_base_dir().path_join("qa-sprint-20/journey-source/campaign-save.json")
		origin = "continued-delivered-champion16"
		var large: String = directory.get_base_dir().path_join("balance-champion-24.json")
		if final_path=="psychic" and FileAccess.file_exists(large): checkpoint = large; origin = "natural-current-champion24"
		check(DirAccess.copy_absolute(checkpoint,app.store.file_path)==OK,"Copy natural champion checkpoint")
		app._load_game()
		if app.run.edition<app.CURRENT_CHAPTER-4: app.travel_buttons.upgrade.pressed.emit()
	elif app.CURRENT_CHAPTER==20:
		var current: String = directory.get_base_dir().path_join("journey-fresh-before-league.json")
		check(DirAccess.copy_absolute(current,app.store.file_path)==OK,"Copy natural current-edition League checkpoint")
		app._load_game()
	elif app.CURRENT_CHAPTER==21:
		var previous: String = directory.get_base_dir().get_base_dir().path_join("qa-sprint-%d/journey-source/campaign-save.json" % (app.CURRENT_CHAPTER-1))
		check(DirAccess.copy_absolute(previous,app.store.file_path)==OK,"Copy previous delivered UI checkpoint")
		app._load_game()
		check(app.run.get("edition",0)==app.CURRENT_CHAPTER-5,"Previous campaign opened with frozen rules")
		app.travel_buttons.upgrade.pressed.emit()
	else:
		app._show_oak()
		app.journey_seed.text = "tactics-1"
		app.travel_buttons.starter1.pressed.emit()
	check(app.run.edition==app.CURRENT_CHAPTER-4,"Current journey edition selected")
	var encountered: Array = []
	for index: int in 16000:
		var command: Dictionary = policy.choose(app.campaign,app.run,final_path)
		if command.is_empty(): break
		var expected: Dictionary = app.campaign.transact(app.run,command)
		check(expected.ok,"Accepted real UI order "+str(command.kind)+" "+str(expected.get("reason","")))
		if not expected.ok: break
		if command.kind=="battle" and app.rules.active(app.state).team=="ally":
			var tactical: Dictionary = command.order
			if tactical.kind=="move": app.board.focus_point(tactical.destination); driver.click(app,tactical.destination)
			elif tactical.kind=="attack":
				var actor: Dictionary = app.rules.active(app.state)
				if actor.get("recoveryPP",{}).has(tactical.actionId) and "recovery-menu.png" not in screenshots:
					app.buttons.actions.pressed.emit()
					check(app.action_buttons[tactical.actionId].text.contains("%d/5" % actor.recoveryPP[tactical.actionId]),"Recovery uses visible in integrated action menu")
					await capture(app,directory,"recovery-menu")
					app.action_page = false
					app._refresh()
				driver.choose_action(app,tactical.actionId)
				var target: Dictionary = app.rules.unit_by_id(app.state,int(tactical.target))
				app.board.focus_point(target)
				driver.hover(app,target)
				driver.click(app,target)
				if not app.pending.is_empty(): app.buttons.confirm.pressed.emit()
			else: app.buttons.finish.pressed.emit(); app.direction_buttons[int(tactical.facing)].pressed.emit()
		elif command.kind in ["enter","capture","continue"]: app.travel_buttons[command.kind].pressed.emit()
		elif command.kind=="travel": app.travel_buttons["travel_"+command.location].pressed.emit()
		elif command.kind=="destiny":
			app.travel_buttons["destiny_"+command.path].pressed.emit()
			if app.action_review!=null and app.action_review.visible: app.action_review.confirmed.emit()
		elif command.kind=="buy": app.travel_buttons["buy_"+command.item].pressed.emit()
		elif command.kind=="level-up" or command.kind=="revive" or command.kind=="heal":
			var reserve_index: int = -1
			for position: int in app.run.reserve.size():
				if app.run.reserve[position].id==command.member: reserve_index = position
			app.travel_buttons["roster_pc" if reserve_index>=0 else "roster_team"].pressed.emit()
			if reserve_index>=0:
				for _page: int in int(reserve_index/6.0): app.travel_buttons.pc_next.pressed.emit()
			app.travel_buttons["member_"+str(int(command.member))].pressed.emit()
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
			if app.campaign.locations[int(app.run.stage)].get("leader",false) or encountered.size()==1 or identity in ["champion","legendary-birds","legendary-origin"]: await capture(app,directory,identity)
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
	var report: Dictionary = {"assertions":assertions,"failures":failures,"chapter":app.CURRENT_CHAPTER,"origin":origin if app.CURRENT_CHAPTER>=22 else ("natural-current-before-league" if app.CURRENT_CHAPTER==20 else ("continued-previous" if app.CURRENT_CHAPTER==21 else "fresh")),"mapSize":app.run.mapSize,"phase":app.run.phase,"finalPath":app.run.get("finalPath",""),"cleared":app.run.cleared,"medals":app.run.medals,"transactions":app.transactions.size(),"encountered":encountered,"screenshots":screenshots}
	FileAccess.open(directory.path_join("journey-ui-result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	app.get_tree().quit(0 if failures.is_empty() else 1)
