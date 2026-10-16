extends RefCounted

const Store = preload("res://core/kanto_store.gd")
var failures: Array[String] = []
var assertions: int = 0
var captures: Array[String] = []
var captured: Dictionary = {}
var player_orders: int = 0

func check(value: bool, message: String) -> void:
	assertions += 1
	if not value: failures.append(message)

func capture(app: Control, directory: String, name: String) -> void:
	await app.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = app.get_viewport().get_texture().get_image()
	check(image.save_png(directory.path_join(name+".png")) == OK,"Capture " + name)
	_bounds(app,app,app.get_global_rect().grow(2))
	captures.append(name+".png")

func button(app: Control, key: String) -> void:
	check(app.travel_buttons.has(key) and app.travel_buttons[key].is_visible_in_tree(),"Visible travel control " + key)
	check(not app.travel_buttons[key].disabled,"Enabled travel control " + key)
	app.travel_buttons[key].pressed.emit()

func shop(app: Control) -> void:
	for entry: Dictionary in app.run.party:
		if entry.hp <= 0: continue
		app._select_member(int(entry.id))
		var member: Dictionary = app.campaign.target(app.run,int(entry.id))
		while member.hp < app.rules.member_unit(member).maxHp - 10:
			if app.run.bag.potion == 0 and app.run.money >= 40: button(app,"buy_potion")
			if app.run.bag.potion == 0: break
			button(app,"heal_potion")
			member = app.campaign.target(app.run,int(entry.id))
	app._select_member(1)
	if app.run.money >= 100 and app.campaign.EVOLUTIONS.has(int(app.run.party[0].speciesId)) and app.run.party[0].hp > 0:
		button(app,"buy_rare-candy")
		var hp: int = app.run.party[0].hp
		button(app,"evolve")
		check(app.run.party[0].hp == hp,"Evolution keeps current HP")
	var count: int = 0
	for amount: Variant in app.run.party[0].training.values(): count += int(amount)
	if app.run.money >= 80 and app.run.party[0].hp > 0 and count < 2:
		app.training_choice.select(0)
		var hp: int = app.run.party[0].hp
		button(app,"train")
		check(app.run.party[0].hp == hp,"Training maximum HP does not heal")

func run(app: Control, directory: String) -> void:
	app._show_oak()
	await capture(app,directory,"01-oak")
	var completed: Array = []
	for starter: int in [1,4,7]:
		app._show_oak()
		app.journey_seed.text = "kanto-14"
		button(app,"starter"+str(starter))
		check(app.run.party.size() == 1 and app.run.party[0].speciesId == starter,"Single chosen Oak starter")
		for step: int in 1000:
			if app.run.phase in ["complete","defeat"]: break
			var phase: String = app.run.phase
			if phase == "map":
				if not captured.has("map"):
					await capture(app,directory,"02-journey")
					captured.map = true
				button(app,"enter")
			elif phase == "battle":
				var command: Dictionary = app.rules.choose_command(app.state)
				var before_order: Dictionary = app.state.duplicate(true)
				var expected: Dictionary = app.rules.apply_command(app.state,command)
				if app.rules.active(app.state).team == "enemy": app._commit(command)
				else:
					player_orders += 1
					if not captured.has("battle"):
						await capture(app,directory,"03-battle")
						captured.battle = true
					if command.kind == "move":
						app.board.tile_hovered.emit(command.destination)
						app.board.tile_selected.emit(command.destination)
						if not captured.has("rectify") and not before_order.acted and app.run.phase == "battle":
							app.buttons.undo.pressed.emit()
							check(Store.equivalent(app.state,before_order),"Campaign HUD rectifies only movement")
							app._load_game()
							check(app.save_warning.is_empty() and Store.equivalent(app.state,before_order),"Revised campaign reloads exactly")
							app.board.tile_selected.emit(command.destination)
							captured.rectify = true
					elif command.kind == "attack":
						var definition: Dictionary = app.rules.profile(app.rules.active(app.state)).action(app.rules.active(app.state),command.actionId).definition
						if command.actionId != "basic":
							app.buttons.actions.pressed.emit()
							app.action_buttons[command.actionId].pressed.emit()
						if definition.target != "self": app.board.tile_selected.emit(app.rules.unit_by_id(app.state,int(command.target)))
						if not app.pending.is_empty(): app.buttons.confirm.pressed.emit()
					else:
						if app.selecting != "finish": app.buttons.finish.pressed.emit()
						app.direction_buttons[int(command.facing)].pressed.emit()
				check(Store.equivalent(app.state,expected.state),"GUI uses shared campaign combat result")
				check(app.save_warning.is_empty(),"Battle command saved")
			elif phase == "capture":
				var reward: Dictionary = app.run.reward.duplicate(true)
				app._load_game()
				check(app.save_warning.is_empty(),"Continue validates campaign journal")
				check(Store.equivalent(app.run.reward,reward),"Pending capture survives Continue")
				if not captured.has("capture"):
					await capture(app,directory,"04-capture")
					captured.capture = true
				var previous: Button = app.travel_buttons.capture
				button(app,"capture")
				var before: Dictionary = app.run.duplicate(true)
				previous.pressed.emit()
				check(Store.equivalent(app.run,before),"Stale capture button cannot duplicate reward")
			elif phase == "shop":
				if not captured.has("shop"):
					await capture(app,directory,"05-shop")
					DisplayServer.window_set_size(Vector2i(1024,720))
					await app.get_tree().process_frame
					await app.get_tree().process_frame
					await capture(app,directory,"05-shop-small")
					DisplayServer.window_set_size(Vector2i(1280,900))
					await app.get_tree().process_frame
					await app.get_tree().process_frame
					captured.shop = true
				shop(app)
				var before: Dictionary = app.run.duplicate(true)
				app._load_game()
				check(app.save_warning.is_empty(),"Continue validates campaign journal")
				check(Store.equivalent(app.run,before),"Shop and evolution replay exactly")
				button(app,"continue")
			await app.get_tree().process_frame
		check(app.run.phase in ["complete","defeat"],"UI run terminates")
		completed.append({"starter":starter,"phase":app.run.phase,"cleared":app.run.cleared.size(),"transactions":app.transactions.size()})
	check(completed.any(func(entry):return entry.phase == "complete"),"Full UI journey reaches Brock")
	await capture(app,directory,"06-result")
	for dimensions: Vector2i in [Vector2i(1024,720),Vector2i(1440,1000)]:
		DisplayServer.window_set_size(dimensions)
		await app.get_tree().process_frame
		await app.get_tree().process_frame
		await capture(app,directory,"07-%dx%d" % [dimensions.x,dimensions.y])
		_bounds(app,app,app.get_global_rect().grow(2))
	var output: Dictionary = {"assertions":assertions,"completed":completed,"playerOrders":player_orders,"screenshots":captures,"failures":failures}
	var file: FileAccess = FileAccess.open(directory.path_join("campaign-ui-result.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(output,"  "))
	file.close()
	print(JSON.stringify(output))
	app.get_tree().quit(0 if failures.is_empty() else 1)

func _bounds(node: Node, app: Control, viewport: Rect2) -> void:
	if node is Window: return
	if node is Control and node.is_visible_in_tree(): check(viewport.encloses(node.get_global_rect()),"Control fits: " + str(node.get_path()))
	if node is ScrollContainer: return
	for child: Node in node.get_children(): _bounds(child,app,viewport)
