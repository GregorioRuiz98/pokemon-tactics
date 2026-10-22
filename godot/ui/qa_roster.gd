extends RefCounted

const Store = preload("res://core/kanto_store.gd")
const Driver = preload("res://ui/qa_driver.gd")
var driver: RefCounted = Driver.new()
var healing: RefCounted = preload("res://ui/qa_campaign.gd").new()
var failures: Array[String] = []
var assertions: int = 0
var screenshots: Array[String] = []

func check(value: bool, message: String) -> void:
	assertions += 1
	if not value: failures.append(message)

func press(app: Control, key: String) -> void:
	check(app.travel_buttons.has(key),"Control exists: "+key)
	if not app.travel_buttons.has(key): return
	var button: Button = app.travel_buttons[key]
	check(not button.disabled,"Control enabled: "+key)
	if not button.disabled: button.pressed.emit()
	if app.action_review!=null and app.action_review.visible: app.action_review.confirmed.emit()

func capture(app: Control, directory: String, filename: String) -> void:
	await app.get_tree().process_frame
	await RenderingServer.frame_post_draw
	if app._simple_hub() and filename.begins_with("pc") and app.travel_buttons.has("pc_filter_0"):
		check(app.travel_buttons.pc_filter_0.size.x>=280,"PC filters fill their column: "+filename)
	var image: Image = app.get_viewport().get_texture().get_image()
	check(not image.is_empty() and image.save_png(directory.path_join(filename+".png"))==OK,"Rendered "+filename)
	screenshots.append(filename+".png")

func run(app: Control, directory: String) -> void:
	app._show_oak()
	app.journey_seed.text = "tactics-1"
	press(app,"starter1")
	check(app.run.edition==12 and app.run.reserve.is_empty(),"New campaign has PC")
	check(app.travel_buttons.deposit.disabled,"Last living member cannot be deposited")
	press(app,"roster_pc")
	check(app.selected_member==-1 and not app.travel_buttons.has("deposit"),"Empty PC has no invalid actions")
	press(app,"roster_team")
	var pc_used: bool = false
	for index: int in 1000:
		if app.run.phase in ["complete","defeat"]: break
		if app.run.phase=="map": press(app,"enter"); continue
		if app.run.phase=="capture": press(app,"capture"); continue
		if app.run.phase=="shop":
			if not pc_used:
				var identity: int = app.run.party.back().id
				press(app,"member_"+str(identity))
				var member_data: Dictionary = app.campaign.target(app.run,identity).duplicate(true)
				press(app,"deposit")
				check(app.run.reserve.size()==1 and app.run.reserve[0].id==identity,"Deposit through team control")
				press(app,"roster_pc")
				check(app.selected_member==identity,"PC selects owned member")
				await capture(app,directory,"pc-natural")
				var before: Dictionary = app.run.duplicate(true)
				app._load_game()
				check(Store.equivalent(app.run,before),"Nonempty PC reload preserves journal and all data")
				press(app,"roster_team")
				press(app,"roster_pc")
				check(Store.equivalent(app.run,before),"Browsing PC does not consume RNG or revisions")
				press(app,"withdraw")
				check(Store.equivalent(app.campaign.target(app.run,identity),member_data),"Withdraw through UI preserves HP and loadout")
				press(app,"roster_team")
				pc_used = true
			healing.heal(app)
			press(app,"continue")
			continue
		var command: Dictionary = app.rules.choose_command(app.state)
		var expected: Dictionary = app.rules.apply_command(app.state,command)
		check(expected.ok,"Legal tactical order")
		if app.rules.active(app.state).team=="enemy": app._commit(command)
		elif command.kind=="move":
			app.board.focus_point(command.destination)
			driver.click(app,command.destination)
		elif command.kind=="attack":
			driver.choose_action(app,command.actionId)
			var target: Dictionary = app.rules.unit_by_id(app.state,int(command.target))
			app.board.focus_point(target)
			driver.hover(app,target)
			driver.click(app,target)
			if not app.pending.is_empty(): app.buttons.confirm.pressed.emit()
		else:
			app.buttons.finish.pressed.emit()
			app.direction_buttons[int(command.facing)].pressed.emit()
		check(Store.equivalent(app.state,expected.state),"Player controls preserve resolver result")
	check(app.run.phase=="complete" and app.run.cleared.size()==4,"Natural campaign completes through controls")
	var natural: Dictionary = {"phase":app.run.phase,"cleared":app.run.cleared.size(),"transactions":app.transactions.size()}
	var natural_state: Dictionary = app.run.duplicate(true)
	app._load_game()
	check(Store.equivalent(app.run,natural_state),"Completed edition12 campaign reloads")
	# Explicit overflow/layout fixture: the four-zone sample naturally reaches only five members.
	app.store = Store.new(directory.path_join("controlled-fixture.json"))
	app.transactions = []
	app.run = app.campaign.create("pc-layout-fixture",1)
	for identity: int in range(2,19):
		var member_data: Dictionary = app.campaign.progression.create_member(identity,[4,7,10,13,16,19,25][(identity-2)%7],"Fixture de interfaz",5)
		app.campaign.progression.assign(member_data,app.run.seed)
		if identity<=6: app.run.party.append(member_data)
		else: app.run.reserve.append(member_data)
	app.run.nextId = 19
	app.run.phase = "capture"
	app.run.reward = app.campaign.progression.create_member(19,25,"Captura controlada",5)
	app.campaign.progression.assign(app.run.reward,app.run.seed)
	app.run.reward.hp -= 8
	app.roster_tab = "team"
	app.selected_member = 1
	app._refresh()
	check(app.travel_buttons.capture.text.begins_with("Enviar al PC"),"Capture labels automatic PC destination")
	press(app,"capture")
	check(app.run.party.size()==6 and app.run.reserve.size()==13 and app.run.reserve.back().id==19,"Overflow capture stays out of full team")
	var overflow_checked: bool = app.run.party.size()==6 and app.run.reserve.size()==13
	await capture(app,directory,"team-full")
	press(app,"roster_pc")
	check(app.travel_buttons.withdraw.disabled,"Full-team withdraw control disabled")
	press(app,"pc_next")
	check(app.roster_offset==1 and app.travel_buttons.has("member_13"),"PC next page displays correct members")
	press(app,"pc_next")
	press(app,"member_19")
	check(app.travel_buttons.pc_next.disabled,"Last PC page disables next")
	await capture(app,directory,"pc-paginated")
	var choice: OptionButton = app.travel_buttons.swap_choice
	choice.select(2)
	choice.item_selected.emit(2)
	check(app.roster_swap==3,"Swap picker chooses another occupied slot")
	var incoming: Dictionary = app.campaign.target(app.run,19).duplicate(true)
	var outgoing: Dictionary = app.campaign.target(app.run,3).duplicate(true)
	press(app,"swap")
	check(app.run.party[2].id==19 and app.roster_tab=="team","Direct swap uses selected team slot")
	check(Store.equivalent(app.run.party[2],incoming) and Store.equivalent(app.campaign.target(app.run,3),outgoing),"Swap preserves all member data")
	app.get_window().size = Vector2i(1024,720)
	await capture(app,directory,"team-1024")
	check(app.travel_buttons.roster_pc.get_global_rect().end.x<=app.size.x,"PC tabs fit minimum viewport")
	press(app,"roster_pc")
	await capture(app,directory,"pc-1024")
	app.run.phase = "map"
	app._refresh()
	press(app,"enter")
	check(app.state.units.filter(func(u):return u.team=="ally").size()==6,"UI encounter deploys six active members")
	check(not app.travel_root.visible and app.board.visible,"PC does not cover battle or allow midfight changes")
	await capture(app,directory,"combat-six")
	app.run.phase = "defeat"
	app._refresh()
	check(app.travel_buttons.withdraw.disabled and app.travel_buttons.swap.disabled,"PC remains viewable but locked after defeat")
	var report: Dictionary = {"assertions":assertions,"failures":failures,"pcUsed":pc_used,"overflowChecked":overflow_checked,"natural":natural,"layoutFixtureReserve":13,"screenshots":screenshots}
	FileAccess.open(directory.path_join("roster-ui-result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	app.get_tree().quit(0 if failures.is_empty() else 1)
