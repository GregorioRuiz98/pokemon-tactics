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
	if app.run.get("edition",1) >= 2:
		for entry: Dictionary in app.run.party:
			if entry.hp <= 0: continue
			app._select_member(int(entry.id))
			var requirement: Dictionary = app.campaign.progression.evolution(entry)
			if app.run.get("edition",1)>=4:
				check(not app.travel_buttons.has("evolve"),"No manual evolution button in new rules")
				var goal: int = entry.level
				if app.run.stage==2 and int(entry.speciesId) in [10,11,13,14]: goal = 10
				if app.run.stage==2 and entry.speciesId==25: goal = 7
				var current: Dictionary = app.campaign.target(app.run,int(entry.id))
				while current.level<goal and (app.run.bag["rare-candy"]>0 or app.run.money>=25):
					if app.run.bag["rare-candy"]==0:
						var balance: int = app.run.money
						check("25" in app.travel_buttons["buy_rare-candy"].text,"Candy displays cheaper price")
						button(app,"buy_rare-candy")
						check(app.run.money==balance-25,"Candy charges exactly 25")
					var hp: int = current.hp
					var xp: int = current.xp
					var level: int = current.level
					button(app,"level-up")
					current = app.campaign.target(app.run,int(entry.id))
					check(current.level==level+1 and current.hp==hp and current.xp==xp,"UI candy grants one level without healing or discarding partial EXP")
				if int(current.speciesId) in [12,15]:
					var coverage: String = "mega-drain" if current.speciesId==12 else "brick-break"
					check(coverage in current.knownMoves,"Evolution coverage is learned through real candy UI")
					captured.growth = true
			elif not requirement.is_empty() and entry.level >= requirement.level:
				if app.run.bag["rare-candy"] == 0 and app.run.money >= 100: button(app,"buy_rare-candy")
				if app.run.bag["rare-candy"] > 0:
					var hp: int = app.campaign.target(app.run,int(entry.id)).hp
					var level: int = entry.level
					button(app,"evolve")
					check(app.campaign.target(app.run,int(entry.id)).hp == hp and app.campaign.target(app.run,int(entry.id)).level == level,"Candy respects level gate and does not heal or add levels")
			var member: Dictionary = app.campaign.target(app.run,int(entry.id))
			if member.moves.size() == 4 and member.knownMoves.size() > 4 and not captured.has("loadout"):
				var extra: String = member.knownMoves.filter(func(id):return id not in member.moves)[0]
				check(app.travel_buttons["move_"+extra].disabled,"Fifth optional move cannot be selected")
				var old: String = member.moves[0]
				var money: int = app.run.money
				app.travel_buttons["move_"+old].toggled.emit(false)
				check(not app.travel_buttons["move_"+extra].disabled,"Removing one unlocks a free slot")
				app.travel_buttons["move_"+extra].toggled.emit(true)
				check(app.campaign.target(app.run,int(entry.id)).moves.size()==4 and app.run.money==money,"Four freely mixed moves cost no money")
				captured.loadout = true
		app._select_member(1)
		return
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
					if app.rules.profile(app.rules.active(app.state)).actions_for(app.rules.active(app.state)).size() == 5 and not captured.has("five"):
						var rng: Variant = app.state.rng
						app.buttons.actions.pressed.emit()
						check(app.action_buttons.size()==5,"Basic plus four moves shown in battle menu")
						await capture(app,directory,"03-five-actions")
						DisplayServer.window_set_size(Vector2i(1024,720))
						await app.get_tree().process_frame
						await app.get_tree().process_frame
						await capture(app,directory,"03-five-small")
						DisplayServer.window_set_size(Vector2i(1280,900))
						await app.get_tree().process_frame
						await app.get_tree().process_frame
						var fifth: Dictionary = app.rules.profile(app.rules.active(app.state)).actions_for(app.rules.active(app.state))[4].definition
						if fifth.target != "self":
							var key: InputEventKey = InputEventKey.new()
							key.keycode = KEY_5
							key.pressed = true
							app.get_viewport().push_input(key)
							await app.get_tree().process_frame
							check(app.selected_action==fifth.id,"Fifth movement is reachable with keyboard 5")
						app._cancel()
						check(app.state.rng==rng,"Opening/cancelling five actions consumes no RNG")
						captured.five = true
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
				if command.kind == "attack" and app.run.phase == "battle" and "miss" in app.combat_feedback.last_kinds:
					if app.combat_feedback.last_sound == "miss": check(app.last_sound_requested == "miss","A failed attack requests miss audio, never hit audio")
					if not captured.has("miss"):
						await capture(app,directory,"04-miss")
						captured.miss = true
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
				if starter==4 and app.run.stage==0:
					check(app.run.stock.size()==3 and app.run.stock[0].item=="tm-brick-break","Charmander's first shop offers Demolición")
					button(app,"stock_0")
					check(app.travel_buttons.stock_0.disabled,"Purchased offer visibly sold out")
					button(app,"use_tm-brick-break")
					check("brick-break" in app.run.party[0].knownMoves and app.run.bag["tm-brick-break"]==0,"UI teaches and consumes compatible MT")
				if starter==7 and app.run.stage==3: await _shop_controls(app,directory)
				if not captured.has("shop"):
					app.message = ""
					app._refresh()
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
				if captured.has("growth") and not captured.has("growth_image"):
					for member: Dictionary in app.run.party:
						if member.hp>0 and int(member.speciesId) in [12,15]:
							app._select_member(int(member.id))
							break
					await capture(app,directory,"12-automatic-evolution")
					captured.growth_image = true
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
	check(captured.has("miss"),"Natural attack failure displayed with dedicated image/audio")
	check(captured.has("five"),"Five action menu exercised")
	check(captured.has("loadout"),"Real UI swaps a learned move without exceeding four slots")
	check(captured.has("growth"),"Real UI reaches bug evolution with learned coverage before Brock")
	await _immune_preview(app,directory)
	await _orb_preview(app,directory)
	await _legacy_preview(app,directory)
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

func _immune_preview(app: Control, directory: String) -> void:
	var original: Dictionary = app.run
	var study: RefCounted = app.campaign.progression
	var actor: Dictionary = app.rules.member_unit(study.create_member(1,25,"QA",10),{"x":2,"y":7})
	var target: Dictionary = app.rules.member_unit(study.create_member(10000,95,"QA",10),{"x":3,"y":7})
	target.team = "enemy"
	target.facing = 2
	var fixture: Dictionary = app.rules.encounter(app.campaign.create("immune",7),app.campaign.locations[0])
	fixture.units = [actor,target]
	fixture.queue = [1,10000]
	var before_rng: Variant = fixture.rng
	var plan: Dictionary = app.rules.attack_plan(fixture,10000,{},"thunder-shock")
	var result: Dictionary = app.rules.apply_command(fixture,{"kind":"attack","target":10000,"actionId":"thunder-shock"})
	check(result.ok and result.hits[0].hit and result.hits[0].damage==0,"Immunity is distinct from accuracy failure")
	app.run = original.duplicate(true)
	app.run.phase = "battle"
	app.run.stage = 0
	app.run.battle = fixture
	app._refresh()

	app.combat_feedback.present(fixture,plan,result.hits)
	app._play(app.combat_feedback.last_sound)
	check(app.last_sound_requested=="immune" and "immune" in app.combat_feedback.last_kinds,"Immunity has a dedicated signal")
	check(fixture.rng==before_rng,"Showing feedback does not consume combat RNG")
	await capture(app,directory,"08-immune")
	app.run = original
	app.combat_feedback.clear()
	app._refresh()

func _shop_controls(app: Control, directory: String) -> void:
	check(app.run.party[-1].speciesId==95 and app.run.party[-1].level==14,"Brock recruited Onix at ace level through real UI journey")
	app.message = ""
	app._select_member(1)
	await capture(app,directory,"10-three-offers")
	var old: Dictionary = app.run.duplicate(true)
	app._refresh()
	check(Store.equivalent(old,app.run),"Inspecting and refreshing shop consumes no RNG")
	for cost: int in [25,50]:
		var money: int = app.run.money
		check(app.campaign.reroll_price(app.run)==cost,"Reroll button has escalating cost")
		button(app,"reroll")
		check(app.run.money==money-cost,"Reroll charges exactly displayed cost")
	var offered: Dictionary = app.run.duplicate(true)
	app._load_game()
	check(app.save_warning.is_empty() and Store.equivalent(offered,app.run),"Continue preserves three offers, RNG and increasing reroll price")
	for i: int in app.run.stock.size():
		var identity: String = app.run.stock[i].item
		var item: Dictionary = app.campaign.shop_data.items[identity]
		if item.kind=="held" and app.run.money>=item.price:
			button(app,"stock_"+str(i))
			button(app,"use_"+identity)
			check(app.run.party[0].heldItem==identity and app.run.bag[identity]==0,"UI equips one held item from bag")
			button(app,"unequip")
			check(app.run.party[0].heldItem==null and app.run.bag[identity]==1,"UI returns unequipped item to bag")
			button(app,"use_"+identity)
			break
	check(app.run.party[0].get("heldItem")!=null,"Held item UI exercised with real purchases")
	await capture(app,directory,"10-equipped")
	DisplayServer.window_set_size(Vector2i(1024,720))
	await app.get_tree().process_frame
	await app.get_tree().process_frame
	await capture(app,directory,"10-shop-small")
	DisplayServer.window_set_size(Vector2i(1280,900))
	await app.get_tree().process_frame
	await app.get_tree().process_frame

func _orb_preview(app: Control, directory: String) -> void:
	var original: Dictionary = app.run
	var member: Dictionary = app.campaign.progression.create_member(1,4,"QA",13)
	member.heldItem = "life-orb"
	var fixture: Dictionary = app.rules.encounter(app.campaign.create("orb-ui",4),app.campaign.locations[0])
	fixture.units[0] = app.rules.member_unit(member,{"x":2,"y":7})
	fixture.units[1].x = 3
	fixture.units[1].y = 7
	fixture.units[1].facing = 2
	fixture.queue = [1,10000]
	var plan: Dictionary = app.rules.attack_plan(fixture,10000,{},"ember")
	var result: Dictionary = app.rules.attack(fixture,10000,"ember")
	check(result.ok and plan.recoil>0,"Life Orb UI fixture has real damaging resolution")
	app.run = original.duplicate(true)
	app.run.phase = "battle"
	app.run.stage = 0
	app.run.battle = result.state
	app._refresh()
	app._show_plan(result.state.units[1],plan)
	check("Vidaesfera" in app.target_info.text,"Prevision explicitly shows Life Orb's own HP cost")
	app.combat_feedback.present(fixture,plan,result.hits)
	check("recoil" in app.combat_feedback.last_kinds,"Real recoil receipt has visual feedback")
	await capture(app,directory,"11-life-orb")
	app.run = original
	app.combat_feedback.clear()
	app._refresh()

func _legacy_preview(app: Control, directory: String) -> void:
	var original: Dictionary = app.run
	var campaign: RefCounted = app.campaign
	var store: RefCounted = app.store
	var orders: Array = app.transactions
	var legacy: RefCounted = load("res://core/kanto_run.gd").new()
	var initial: Dictionary = legacy.create("legacy-ui",7)
	var command: Dictionary = {"kind":"enter","at":0}
	var entered: Dictionary = legacy.transact(initial,command)
	var archive: RefCounted = Store.new(directory.path_join("legacy-ui.json"))
	check(archive.save(entered.state,[command],"").ok,"Isolated edition-1 UI save prepared")
	app.store = archive
	app._load_game()
	check(not app.run.has("edition") and app.hint.text.begins_with("Clásica 0.14"),"Legacy battle UI clearly identifies its retained rules")
	check(Store.equivalent(app.state,entered.state.battle),"Legacy UI loads battle and RNG exactly")
	await capture(app,directory,"09-legacy")
	app.store = store
	app.campaign = campaign
	app.rules = campaign.engine
	app.run = original
	app.transactions = orders
	app._refresh()
