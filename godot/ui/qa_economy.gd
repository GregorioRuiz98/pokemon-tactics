extends "res://ui/qa_spatial.gd"

const EconomyRun = preload("res://core/economy_run.gd")
const EconomyStore = preload("res://core/economy_store.gd")

func layout(app: Control) -> void:
	for frame: int in 6: await app.get_tree().process_frame

func run(app: Control, directory: String) -> void:
	app.get_window().gui_embed_subwindows = true
	app.input_profile = Profile.new(directory.path_join("economy-controls.json"))
	app.board.input_profile = app.input_profile
	app.controls_dialog.profile = app.input_profile
	app.store = EconomyStore.new(directory.path_join("natural-campaign.json"))
	app.run = {}; app.transactions = []; app.title_visible = false
	app._show_oak()
	app.journey_seed.text = "economy-1"
	await click(app,app.travel_buttons.starter1)
	check(app.run.edition==20,"Oak starts new progression")
	await click(app,app.travel_buttons.enter)
	for i: int in 180:
		if app.run.phase!="battle": break
		var revision: int = app.run.revision
		app._commit(app.rules.choose_command(app.state))
		check(app.run.revision==revision+1,"Accepted natural opening order "+str(i))
		app.combat_feedback.clear()
	check(app.run.phase=="capture","Natural first battle won")
	if app.run.phase!="capture": finish(app,directory); return
	check(app.travel_buttons.has("reroll_capture"),"Local capture offers paid reroll")
	var before: Dictionary = app.run.duplicate(true)
	await click(app,app.travel_buttons.reroll_capture)
	check(app.action_review.visible and app.action_review.content.text.contains("60"),"Reroll reviews exact price")
	await key(app,KEY_ESCAPE,app.action_review)
	check(Store.equivalent(before,app.run),"Cancelled reroll preserves offer, cash and RNG")
	await click(app,app.travel_buttons.reroll_capture)
	var expected: Dictionary = app.campaign.transact(before,{"kind":"reroll-capture","at":before.revision})
	await key(app,KEY_ENTER,app.action_review)
	await layout(app)
	check(expected.ok and Store.equivalent(expected.state,app.run),"Keyboard reroll equals authoritative result")
	check(app.run.reward.speciesId!=before.reward.speciesId and app.run.money==before.money-60 and app.travel_buttons.reroll_capture.text.contains("120"),"Another species and increasing visible price")
	await capture(app,directory,"local-reroll")
	await click(app,app.travel_buttons.capture)
	app._shop_page("evolution")
	await layout(app)
	check(app.travel_buttons.shop_evolution.text=="Entrenar" and app.travel_buttons.has("shop_train_xp"),"Training category replaces evolution purchases")
	for item: String in app.campaign.RETIRED: check(not app.travel_buttons.has("buy_"+item),"No retired purchase "+item)
	var quote: Dictionary = app.campaign.training_quote(app.run,app.campaign.target(app.run,1))
	check(quote.ok and quote.points==11 and quote.price==11,"Earned EXP reduces price to eleven")
	before = app.run.duplicate(true)
	await click(app,app.travel_buttons.shop_train_xp)
	check(app.action_review.visible and app.action_review.content.text.contains("11 EXP"),"Training review shows remaining EXP")
	await key(app,KEY_ESCAPE,app.action_review)
	check(Store.equivalent(before,app.run),"Cancelled training preserves complete state")
	await click(app,app.travel_buttons.shop_train_xp)
	expected = app.campaign.transact(before,{"kind":"train-xp","member":1,"price":quote.price,"points":quote.points,"at":before.revision})
	await click(app,app.action_review.get_ok_button())
	await layout(app)
	check(expected.ok and Store.equivalent(expected.state,app.run),"Mouse accepts exactly quoted training")
	var loaded: Dictionary = EconomyStore.new(app.store.file_path).load_campaign(app.campaign)
	check(loaded.ok and Store.equivalent(loaded.get("state",{}),app.run),"Cold replay preserves natural capture, paid reroll and training")
	await capture(app,directory,"training-shop")
	app._set_hub_mode("team")
	await layout(app)
	app._set_member_view("moves")
	await layout(app)
	check(not app.travel_buttons.has("level-up"),"No Candy use button")
	check(app.hub_parts.moves.get_child(0).text.contains("%d / %d" % [app.run.party[0].xp,app.campaign.progression.member_next_xp(app.run.party[0])]),"Library uses species EXP curve")
	# Explicit synthetic fixture for branching evolutions and presentation boundaries.
	app.campaign = EconomyRun.new(); app.rules = app.campaign.engine
	app.store = EconomyStore.new(directory.path_join("synthetic-evolution.json"))
	app.run = app.campaign.create("evolution-ui-fixture",1)
	app.run.phase = "shop"; app.run.money = 500
	app.run.party = [app.campaign.progression.create_member(1,133,"Fixture",25)]
	app.selected_member = 1; app.transactions = []
	app._prepare_campaign_assets(); app._refresh()
	await layout(app)
	app._set_hub_mode("team")
	await layout(app)
	app._set_member_view("profile")
	await layout(app)
	for identity: int in [134,135,136]: check(app.travel_buttons.has("evolution_"+str(identity)) and not app.travel_buttons["evolution_"+str(identity)].disabled,"Free Eevee branch "+str(identity))
	before = app.run.duplicate(true)
	await click(app,app.travel_buttons.evolution_135)
	await key(app,KEY_ESCAPE,app.action_review)
	check(Store.equivalent(before,app.run),"Cancel evolution retains Eevee and all branches")
	await click(app,app.travel_buttons.evolution_135)
	expected = app.campaign.transact(before,{"kind":"evolve-free","member":1,"species":135,"at":before.revision})
	await key(app,KEY_ENTER,app.action_review)
	check(expected.ok and Store.equivalent(expected.state,app.run) and app.run.money==500,"Chosen Jolteon costs nothing")
	for dimensions: Vector2i in [Vector2i(1024,720),Vector2i(1280,900)]:
		app.get_window().size = dimensions
		for scale_value: int in [100,125,150]:
			app.input_profile.set_preference("textScale",scale_value)
			app._apply_preferences(); app._refresh()
			await layout(app)
			check(app.hub_parts.details.size.x>400,"Positive detail width %d/%d" % [dimensions.x,scale_value])
			check(app.hub_parts.team.get_global_rect().end.y<=app.size.y,"Training layout inside screen %d/%d" % [dimensions.x,scale_value])
			await capture(app,directory,"training-%d-%d" % [dimensions.x,scale_value])
	finish(app,directory)

func finish(app: Control, directory: String) -> void:
	var result: Dictionary = {"assertions":assertions,"failures":failures,"screenshots":screenshots,"naturalReplay":"natural-campaign.json; synthetic Eevee fixture stored separately","campaignEdition":20,"combatEdition":18,"journeyHash":FileAccess.get_file_as_string("res://data/journey-24.json").sha256_text(),"curveHash":FileAccess.get_file_as_string("res://data/economy.json").sha256_text()}
	FileAccess.open(directory.path_join("economy-ui-result.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("ECONOMY_UI "+JSON.stringify(result))
	app.get_tree().quit(0 if failures.is_empty() else 1)
