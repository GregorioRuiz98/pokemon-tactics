extends "res://ui/qa_context.gd"

const CurrentStore = preload("res://core/climate_store.gd")
const Context = preload("res://core/climate_context.gd")
const Mint = preload("res://ui/mint_info.gd")

func layout(app: Control) -> void:
	for frame: int in 8: await app.get_tree().process_frame

func run(app: Control, directory: String) -> void:
	app.get_window().gui_embed_subwindows = true
	app.input_profile = Profile.new(directory.path_join("climate-controls-%d.json"%Time.get_ticks_usec()))
	app.board.input_profile = app.input_profile; app.controls_dialog.profile = app.input_profile
	app.store = CurrentStore.new(directory.path_join("climate-natural-%d.json"%Time.get_ticks_usec()))
	await click(app,app.title_screen.controls.new)
	app.journey_seed.text = "power-ui"
	await click(app,app.travel_buttons.starter4)
	check(app.run.edition==25,"New game uses weather/ability edition")
	check(app.run.party[0].has("gender"),"Starter gender persists")
	for identity: String in app.campaign.progression.traits.abilities:
		var entry: Dictionary = app.campaign.progression.traits.abilities[identity]
		check("pendiente" not in entry.name and "sin efecto" not in entry.name,"Applicable ability label: "+identity)
	await click(app,app.travel_buttons.enter)
	check(app.heading.text.contains("Despejado"),"Weather visible before battle")
	await capture(app,directory,"deployment-weather")
	await click(app,app.adventure.start_button)
	for step: int in 200:
		if app.run.phase!="battle": break
		app._event({"kind":"battle","order":app.rules.choose_command(app.state),"at":app.run.revision})
	check(app.run.phase=="capture","Natural opening reaches capture")
	if app.run.phase=="capture": await click(app,app.travel_buttons.capture)
	await layout(app)
	check(app.run.phase=="shop","Natural capture reaches Kecleon")
	app.adventure.toast.hide(); app.adventure.toast_remaining = 0
	await click(app,app.travel_buttons.shop_traits)
	var text: String = preload("res://ui/qa_copy.gd").new().visible_text(app.travel_root)
	check("+10 %" in text and "−10 %" in text,"Mint modifiers visible before buying")
	check("Ataque" in text and "especial" in text,"Mint names both affected statistics")
	check("↑" in app.travel_buttons.mint_picker.get_item_text(0),"Selector includes labeled directions")
	check("Sin modificadores" in Mint.details(app.campaign.progression,"serious"),"Neutral mint explicit")
	await capture(app,directory,"mint-before-purchase")
	app.input_profile.set_preference("textScale",150); app._apply_preferences(); await layout(app)
	await capture(app,directory,"mint-before-purchase-150")
	app.input_profile.set_preference("textScale",100); app._apply_preferences(); await layout(app)
	var money: int = app.run.money
	await click(app,app.travel_buttons.buy_mint)
	check(app.run.money==money-app.campaign.progression.traits.mintPrice,"Mint purchase keeps price")
	app._set_hub_mode("team"); app._set_member_view("traits"); await layout(app)
	check(app.travel_buttons.has("use_mint_picker"),"Owned mint picker available")
	check("↑" in app.travel_buttons.use_mint_picker.get_item_text(0),"Owned mint also explains directions")
	await capture(app,directory,"mint-comparison")
	var original: Dictionary = app.run.duplicate(true)
	app._load_game(); await layout(app)
	check(CurrentStore.equivalent(original,app.run),"Edition25 journal reloads exactly")
	# Separate visual/input fixture; restore the real journal after taking screenshots.
	var original_store: RefCounted = app.store
	var original_transactions: Array = app.transactions.duplicate(true)
	app.run = original.duplicate(true); app.run.phase = "battle"
	app.run.battle = app.rules.encounter(app.run,app.campaign.locations[0])
	app.run.battle.deployment = false
	var actor: Dictionary = app.rules.active(app.run.battle)
	if actor.team!="ally":
		actor = app.run.battle.units.filter(func(u):return u.team=="ally")[0]
		app.run.battle.queue.erase(actor.id); app.run.battle.queue.push_front(actor.id)
	actor.moves = ["rain-dance","sunny-day","sandstorm","ember"]
	actor.nativeAbility = "illuminate"; actor.ability = "illuminate"; actor.abilityName = "Iluminación"
	actor.abilityDescription = app.campaign.progression.traits.abilities.illuminate.description
	app.run.battleInitial = app.run.battle.duplicate(true); app.run.battleCommands = []
	app.state = app.run.battle; app.transactions = []; app.history = []
	app.store = CurrentStore.new(directory.path_join("climate-input-fixture.json"))
	app.action_page = true; app.selecting = "auto"; app.pending = {}; app._refresh(); await layout(app)
	check(app.action_buttons.has("rain-dance"),"Weather technique in native command menu")
	check(app.action_buttons["rain-dance"].has_node("MoveSymbols"),"Weather command has type/category icons")
	var before: Dictionary = app.run.duplicate(true)
	await click(app,app.action_buttons["rain-dance"])
	check(not app.state.acted,"Selecting weather does not execute it")
	await key(app,KEY_ENTER); await layout(app)
	check(app.state.weather.kind=="rain" and app.state.acted,"Keyboard confirms weather and spends action")
	check(app.heading.text.contains("Lluvia"),"HUD follows weather change")
	check(before.battle.rng==app.state.rng,"Weather consumes no attack roll")
	app.board.cursor = Vector2i(actor.x,actor.y); app.board.queue_redraw()
	await capture(app,directory,"rain-and-light-aura")
	app.input_profile.set_preference("textScale",150); app._apply_preferences(); await layout(app)
	await capture(app,directory,"weather-150")
	app.input_profile.set_preference("textScale",100)
	app.run = original.duplicate(true); app.run.phase = "shop"; app.state = {}
	var learner: Dictionary = app.campaign.progression.create_member(900,43,"Weather fixture",15)
	app.campaign.progression.assign(learner,app.run.seed); learner.moves = ["sunny-day"]
	app.run.party.append(learner); app.selected_member = learner.id
	app._set_hub_mode("team"); app._set_member_view("moves"); await layout(app)
	check(app.travel_buttons.has("move_slot_0"),"New weather learner opens native equipment menu")
	check(app.travel_buttons.move_slot_0.is_visible_in_tree() and "Soleado" in app.travel_buttons.move_slot_0.text,"Equipped weather technique is readable")
	await capture(app,directory,"weather-loadout")
	app.selected_member = 1
	app.run = original; app.state = {}; app.store = original_store; app.transactions = original_transactions
	app._refresh(); app._load_game(); await layout(app)
	check(CurrentStore.equivalent(original,app.run),"Visual fixture never replaces natural campaign")
	var old: RefCounted = preload("res://core/sleep_run.gd").new()
	app.run = old.create("climate-upgrade-ui",4); app.campaign = old; app.rules = old.engine
	app.transactions = []; app.state = {}; app.store = CurrentStore.new(directory.path_join("climate-upgrade-fixture.json"))
	check(app.store.save(app.run,[],"current").ok,"Old campaign fixture saved")
	app._refresh(); await layout(app)
	check(app.travel_buttons.has("upgrade"),"Old campaign offers explicit upgrade")
	await click(app,app.travel_buttons.upgrade)
	check(app.run.edition==25 and app.save_warning.is_empty(),"Upgrade preserves and saves team")
	var upgraded: Dictionary = app.run.duplicate(true)
	app._load_game(); await layout(app)
	check(CurrentStore.equivalent(upgraded,app.run),"Mixed upgrade journal reloads")
	check(Array(DirAccess.get_files_at(directory)).any(func(n):return n.begins_with("climate-upgrade-fixture.json.before-new-")),"Upgrade creates backup")
	var report: Dictionary = {"assertions":assertions,"failures":failures,"screenshots":screenshots,"campaignEdition":app.run.edition,"stateHash":JSON.stringify(app.run,"",true,true).sha256_text(),"naturalStateHash":JSON.stringify(original,"",true,true).sha256_text(),"scope":"Natural opening/capture/shop/mint purchase/load; separate weather input and old-save upgrade fixtures; keyboard, icons, auras and150% text."}
	FileAccess.open(directory.path_join("climate-ui-result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("QA climate "+JSON.stringify({"assertions":assertions,"failures":failures})); app.get_tree().quit(0 if failures.is_empty() else 1)
